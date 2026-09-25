#include "candidatelayer.h"

#include <QFontMetricsF>
#include <QPainter>
#include <QQuickWindow>
#include <QSGSimpleTextureNode>

#include <algorithm>
#include <cmath>

namespace {
struct Label {
    QString text;
    QColor color;
    qreal size = 0;
    int kind = 0;
    bool bold = false;
};

struct Marker {
    QPointF center;
    QColor color;
    qreal opacity = 1;
    qreal outlineOpacity = 1;
    int rank = 0;
    int displayIndex = 0;
    bool first = false;
    bool ring = false;
    bool qualified = false;
    QList<Label> labels;
};

QFont labelFont(qreal size, bool bold, const QString &family = QStringLiteral("sans-serif"))
{
    QFont font(family);
    font.setStyleHint(QFont::SansSerif);
    font.setPixelSize(std::max(1, qRound(size)));
    font.setWeight(bold ? QFont::Bold : QFont::Normal);
    return font;
}

void centeredText(QPainter &painter, const QString &text, const QPointF &center,
                  const QFont &font, const QColor &color, qreal maximumWidth)
{
    const QFontMetricsF metrics(font);
    const qreal width = metrics.horizontalAdvance(text);
    painter.save();
    painter.setFont(font);
    painter.setPen(color);
    painter.translate(center);
    if (width > maximumWidth)
        painter.scale(maximumWidth / width, 1);
    painter.drawText(QPointF(-width / 2, (metrics.ascent() - metrics.descent()) / 2), text);
    painter.restore();
}
}

struct CandidateLayer::Frame {
    QList<Marker> markers;
    QSizeF size;
    qreal dpr = 1;
    qreal radius = 8;
    qreal stoneScale = 1;
    qreal ringWidth = 1;
    qreal offsets[3] = {};
    QColor firstLabelColor;
    QColor ringColor;
    QString coordinateFont;
    quint64 generation = 0;
    quint64 revision = 0;
};

CandidateLayer::CandidateLayer(QQuickItem *parent) : QQuickItem(parent)
{
    setFlag(ItemHasContents, true);
    m_pool.setMaxThreadCount(1);
}

CandidateLayer::~CandidateLayer()
{
    ++m_generation;
    m_pool.waitForDone();
}

void CandidateLayer::itemChange(ItemChange change, const ItemChangeData &data)
{
    QQuickItem::itemChange(change, data);
    if (change == ItemDevicePixelRatioHasChanged) {
        clear();
        emit repaintNeeded();
    }
}

void CandidateLayer::clear()
{
    ++m_generation;
    m_pending.reset();
    m_positionKey.clear();
    m_image = {};
    m_textureDirty = true;
    update();
}

void CandidateLayer::submit(const QJSValue &markers, const QVariantMap &style,
                            const QString &positionKey)
{
    const uint count = markers.property(QStringLiteral("length")).toUInt();
    if (!markers.isArray() || count == 0 || width() <= 0 || height() <= 0) {
        clear();
        return;
    }
    if (positionKey != m_positionKey) {
        clear();
        m_positionKey = positionKey;
    }
    auto frame = std::make_unique<Frame>();
    frame->size = size();
    frame->dpr = window() ? window()->effectiveDevicePixelRatio() : 1;
    frame->radius = style.value(QStringLiteral("radius")).toDouble();
    frame->stoneScale = style.value(QStringLiteral("stoneScale")).toDouble();
    frame->ringWidth = style.value(QStringLiteral("ringWidth")).toDouble();
    frame->firstLabelColor = QColor(style.value(QStringLiteral("firstLabelColor")).toString());
    frame->ringColor = QColor(style.value(QStringLiteral("ringColor")).toString());
    frame->coordinateFont = style.value(QStringLiteral("coordinateFont")).toString();
    const QVariantList offsets = style.value(QStringLiteral("offsets")).toList();
    for (int i = 0; i < 3 && i < offsets.size(); ++i)
        frame->offsets[i] = offsets[i].toDouble();
    frame->generation = m_generation.load();
    frame->revision = ++m_revision;
    frame->markers.reserve(count);
    for (uint i = 0; i < count; ++i) {
        const QJSValue data = markers.property(i);
        Marker marker;
        marker.center = QPointF(data.property(QStringLiteral("x")).toNumber(),
                                data.property(QStringLiteral("y")).toNumber());
        marker.color = QColor(data.property(QStringLiteral("color")).toString());
        marker.opacity = data.property(QStringLiteral("opacity")).toNumber();
        marker.outlineOpacity = data.property(QStringLiteral("outlineOpacity")).toNumber();
        marker.rank = data.property(QStringLiteral("rank")).toInt();
        marker.displayIndex = data.property(QStringLiteral("displayIndex")).toInt();
        marker.first = marker.displayIndex == 1;
        marker.ring = data.property(QStringLiteral("ring")).toBool();
        marker.qualified = data.property(QStringLiteral("qualified")).toBool();
        const QJSValue lines = data.property(QStringLiteral("lines"));
        const uint lineCount = lines.property(QStringLiteral("length")).toUInt();
        for (uint j = 0; j < lineCount; ++j) {
            const QJSValue line = lines.property(j);
            marker.labels.append({line.property(QStringLiteral("text")).toString(),
                                  QColor(line.property(QStringLiteral("color")).toString()),
                                  line.property(QStringLiteral("fontSize")).toNumber(),
                                  line.property(QStringLiteral("kind")).toInt(),
                                  line.property(QStringLiteral("bold")).toBool()});
        }
        frame->markers.append(std::move(marker));
    }
    m_pending = std::move(frame);
    startPendingFrame();
}

void CandidateLayer::startPendingFrame()
{
    if (m_running || !m_pending)
        return;
    m_running = true;
    const std::shared_ptr<Frame> frame(std::move(m_pending));
    m_pool.start([this, frame]() {
        const QImage image = render(*frame, m_generation);
        QMetaObject::invokeMethod(this, [this, frame, image]() {
            m_running = false;
            // A new position/geometry invalidates both queued and completed work.
            if (frame->generation == m_generation.load() && !image.isNull()) {
                m_image = image;
                m_renderedRevision = frame->revision;
                m_textureDirty = true;
                update();
                emit frameReady();
            }
            startPendingFrame();
        }, Qt::QueuedConnection);
    });
}

QImage CandidateLayer::render(const Frame &frame, const std::atomic<quint64> &generation)
{
    if (frame.generation != generation.load())
        return {};
    QImage image(QSize(qCeil(frame.size.width() * frame.dpr), qCeil(frame.size.height() * frame.dpr)),
                 QImage::Format_ARGB32_Premultiplied);
    if (image.isNull())
        return {};
    image.setDevicePixelRatio(frame.dpr);
    image.fill(Qt::transparent);
    QPainter painter(&image);
    painter.setRenderHint(QPainter::Antialiasing);
    painter.setRenderHint(QPainter::TextAntialiasing);
    const qreal radius = frame.radius;
    const qreal scale = std::max(qreal(0.12), radius * 2 / 151);
    const qreal maximumTextWidth = std::max(qreal(8), radius * 2 - 4);
    const QPen outline(Qt::black, std::max(qreal(1), radius / 26.5));
    const QPen ring(frame.ringColor, std::max(qreal(1), frame.ringWidth * scale));
    for (const Marker &marker : frame.markers) {
        if (frame.generation != generation.load())
            return {};
        painter.setOpacity(marker.opacity);
        painter.setPen(Qt::NoPen);
        painter.setBrush(marker.color);
        painter.drawEllipse(marker.center, radius, radius);
        painter.setBrush(Qt::NoBrush);
        if (!marker.first) {
            painter.setOpacity(marker.outlineOpacity);
            painter.setPen(outline);
            painter.drawEllipse(marker.center, radius, radius);
        }
        painter.setOpacity(1);
        if (marker.ring) {
            painter.setPen(ring);
            painter.drawEllipse(marker.center, radius * 1.02, radius * 1.02);
        }
        qreal totalHeight = std::max(qsizetype(0), marker.labels.size() - 1) * 2 * scale;
        for (const Label &label : marker.labels)
            totalHeight += std::max(qreal(16), label.size * 0.88) * scale;
        qreal y = marker.center.y() - totalHeight / 2;
        for (const Label &label : marker.labels) {
            const qreal lineHeight = std::max(qreal(16), label.size * 0.88) * scale;
            const qreal offset = frame.offsets[std::clamp(label.kind, 0, 2)] * scale;
            centeredText(painter, label.text, QPointF(marker.center.x(), y + lineHeight / 2 - offset),
                         labelFont(std::max(qreal(7), label.size * scale), label.bold),
                         marker.first ? frame.firstLabelColor : label.color, maximumTextWidth);
            y += lineHeight + 2 * scale;
        }
        if (marker.qualified && marker.labels.isEmpty()) {
            const qreal cell = radius * 2 / std::max(qreal(0.1), frame.stoneScale);
            centeredText(painter, QString::number(marker.displayIndex), marker.center,
                         labelFont(std::max(qreal(10), std::min(qreal(16), cell * 0.20)), true),
                         marker.first ? frame.firstLabelColor : QColor("#104f29"), maximumTextWidth);
        }
        if (marker.rank > 0 && marker.rank <= 9) {
            const QString text = QString::number(marker.rank);
            const qreal side = radius * 2 / std::max(qreal(0.1), frame.stoneScale);
            qreal fontSize = std::max(qreal(1), side * 0.36);
            QFont font = labelFont(fontSize, false, frame.coordinateFont);
            const qreal initialWidth = QFontMetricsF(font).horizontalAdvance(text);
            if (initialWidth > side * 0.39) {
                fontSize *= side * 0.39 / initialWidth;
                font = labelFont(fontSize, false, frame.coordinateFont);
            }
            const QFontMetricsF metrics(font);
            const qreal textWidth = std::max(qreal(1), metrics.horizontalAdvance(text));
            // Canvas's metrics only exposes width; preserve its ascent/descent fallback.
            const qreal textHeight = std::max(qreal(1), fontSize * 0.60);
            const QPointF anchor(marker.center.x() + side * 0.43 + (marker.rank == 1 ? 1 : 0),
                                 marker.center.y() - side * 0.358 - (marker.rank == 1 ? 1 : 0));
            const qreal x = anchor.x() - textWidth / 2;
            painter.fillRect(QRectF(x, anchor.y() - textHeight, textWidth,
                                    textHeight + std::max(qreal(1), textHeight / 12)), QColor("#ffa500"));
            painter.setFont(font);
            painter.setPen(QColor("#15191c"));
            painter.drawText(QPointF(x, anchor.y()), text);
        }
    }
    return image;
}

QSGNode *CandidateLayer::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *)
{
    auto *node = static_cast<QSGSimpleTextureNode *>(oldNode);
    if (m_image.isNull()) {
        delete node;
        return nullptr;
    }
    if (!node) {
        node = new QSGSimpleTextureNode;
        node->setOwnsTexture(true);
        m_textureDirty = true;
    }
    if (m_textureDirty) {
        QSGTexture *texture = window()->createTextureFromImage(m_image);
        if (!texture) {
            delete node;
            return nullptr;
        }
        // setTexture releases the previous texture when ownsTexture is true.
        node->setTexture(texture);
        m_textureDirty = false;
    }
    node->setRect(boundingRect());
    node->setFiltering(QSGTexture::Linear);
    return node;
}
