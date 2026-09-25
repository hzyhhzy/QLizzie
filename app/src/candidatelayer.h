#pragma once

#include <QImage>
#include <QJSValue>
#include <QQuickItem>
#include <QThreadPool>
#include <QVariantList>
#include <QVariantMap>

#include <atomic>
#include <memory>

// Rasterize an immutable candidate frame away from the GUI/render threads.
// There is at most one running frame and one (replaceable) pending frame.
class CandidateLayer : public QQuickItem
{
    Q_OBJECT
    Q_PROPERTY(quint64 renderedRevision READ renderedRevision NOTIFY frameReady)

public:
    explicit CandidateLayer(QQuickItem *parent = nullptr);
    ~CandidateLayer() override;

    Q_INVOKABLE void submit(const QJSValue &markers, const QVariantMap &style,
                            const QString &positionKey);
    Q_INVOKABLE void clear();
    quint64 renderedRevision() const { return m_renderedRevision; }

signals:
    void frameReady();
    void repaintNeeded();

protected:
    QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) override;
    void itemChange(ItemChange change, const ItemChangeData &data) override;

private:
    struct Frame;
    static QImage render(const Frame &frame, const std::atomic<quint64> &generation);
    void startPendingFrame();

    QThreadPool m_pool;
    std::unique_ptr<Frame> m_pending;
    std::atomic<quint64> m_generation{0};
    QString m_positionKey;
    QImage m_image;
    quint64 m_revision = 0;
    quint64 m_renderedRevision = 0;
    bool m_running = false;
    bool m_textureDirty = false;
};
