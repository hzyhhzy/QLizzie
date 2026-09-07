#include "engineanalysis.h"

#include <QVariantMap>
#include <QVector>

#include <algorithm>
#include <cmath>

namespace {
struct ParsedCandidateInfo {
    int order = 0;
    QVariantMap item;
};

QStringView trimmedView(QStringView text)
{
    qsizetype first = 0;
    qsizetype last = text.size();
    while (first < last && text.at(first).isSpace())
        ++first;
    while (last > first && text.at(last - 1).isSpace())
        --last;
    return text.sliced(first, last - first);
}

QStringView nextToken(QStringView text, qsizetype &position)
{
    while (position < text.size() && text.at(position).isSpace())
        ++position;
    const qsizetype start = position;
    while (position < text.size() && !text.at(position).isSpace())
        ++position;
    return text.sliced(start, position - start);
}

QString nextMoveToken(QStringView text, qsizetype &position)
{
    while (position < text.size() && text.at(position).isSpace())
        ++position;
    const qsizetype start = position;
    if (start < text.size() && text.at(start) == QLatin1Char('(')) {
        while (position < text.size()) {
            const QChar ch = text.at(position++);
            if (ch == QLatin1Char(')'))
                break;
        }
        return trimmedView(text.sliced(start, position - start)).toString();
    }

    return nextToken(text, position).toString();
}

qsizetype nextInfoSeparator(QStringView text, qsizetype from)
{
    for (qsizetype i = from; i + 5 < text.size(); ++i) {
        if (!text.at(i).isSpace())
            continue;
        if (text.sliced(i + 1, 4) == QLatin1StringView("info") && text.at(i + 5).isSpace())
            return i;
    }
    return -1;
}

qsizetype standaloneTokenPosition(QStringView text, QLatin1StringView wanted, qsizetype from = 0)
{
    qsizetype position = from;
    while (position < text.size()) {
        while (position < text.size() && text.at(position).isSpace())
            ++position;
        const qsizetype tokenStart = position;
        const QStringView token = nextToken(text, position);
        if (token == wanted)
            return tokenStart;
    }
    return -1;
}

qsizetype firstAnalysisTrailerPosition(QStringView text)
{
    qsizetype position = 0;
    while (position < text.size()) {
        while (position < text.size() && text.at(position).isSpace())
            ++position;
        const qsizetype tokenStart = position;
        const QStringView token = nextToken(text, position);
        if (token == QLatin1StringView("rootInfo")
            || token == QLatin1StringView("ownership")
            || token == QLatin1StringView("ownershipStdev")) {
            return tokenStart;
        }
    }
    return -1;
}

QVariantList parsedOwnership(QStringView payload)
{
    const qsizetype ownershipPosition =
        standaloneTokenPosition(payload, QLatin1StringView("ownership"));
    if (ownershipPosition < 0)
        return {};

    qsizetype position = ownershipPosition + qsizetype(QLatin1StringView("ownership").size());
    QVariantList result;
    while (position < payload.size()) {
        const QStringView token = nextToken(payload, position);
        if (token.isEmpty())
            break;
        if (token == QLatin1StringView("info")
            || token == QLatin1StringView("rootInfo")
            || token == QLatin1StringView("ownershipStdev")) {
            break;
        }

        bool ok = false;
        const double value = token.toDouble(&ok);
        if (!ok || !std::isfinite(value))
            return {};
        result.append(value);
    }
    return result;
}

}

EngineAnalysis::Batch EngineAnalysis::parseInfoLine(QStringView line)
{
    QStringView payload(line);
    if (payload.startsWith(QLatin1StringView("info ")))
        payload = payload.sliced(5);
    payload = trimmedView(payload);
    const QVariantList ownership = parsedOwnership(payload);
    const qsizetype trailerPosition = firstAnalysisTrailerPosition(payload);
    const QStringView candidatePayload =
        trailerPosition >= 0 ? trimmedView(payload.first(trailerPosition)) : payload;

    QVector<ParsedCandidateInfo> parsedCandidates;
    int segmentIndex = 0;
    qsizetype segmentStart = 0;

    while (segmentStart < candidatePayload.size()) {
        const qsizetype separator = nextInfoSeparator(candidatePayload, segmentStart);
        const QStringView segment = trimmedView(separator >= 0
                                                ? candidatePayload.sliced(segmentStart,
                                                                          separator - segmentStart)
                                                : candidatePayload.sliced(segmentStart));
        if (segment.isEmpty()) {
            if (separator < 0)
                break;
            segmentStart = separator + 5;
            ++segmentIndex;
            continue;
        }

        QVariantMap item;
        int order = segmentIndex;
        qsizetype tokenPosition = 0;

        while (tokenPosition < segment.size()) {
            const QStringView key = nextToken(segment, tokenPosition);
            if (key.isEmpty())
                break;
            if (key == QLatin1StringView("pv")) {
                const qsizetype pvVisitsPosition =
                    standaloneTokenPosition(segment,
                                            QLatin1StringView("pvVisits"),
                                            tokenPosition);
                const QStringView pvText = trimmedView(
                    pvVisitsPosition >= 0
                        ? segment.sliced(tokenPosition,
                                         pvVisitsPosition - tokenPosition)
                        : segment.sliced(tokenPosition));
                if (!pvText.isEmpty())
                    item.insert(QStringLiteral("pvText"), pvText.toString());
                if (pvVisitsPosition >= 0) {
                    const qsizetype pvVisitsStart =
                        pvVisitsPosition
                        + qsizetype(QLatin1StringView("pvVisits").size());
                    const QStringView pvVisitsText =
                        trimmedView(segment.sliced(pvVisitsStart));
                    if (!pvVisitsText.isEmpty()) {
                        item.insert(QStringLiteral("pvVisitsText"),
                                    pvVisitsText.toString());
                    }
                }
                break;
            }

            if (key == QLatin1StringView("pvVisits")) {
                const QStringView pvVisitsText =
                    trimmedView(segment.sliced(tokenPosition));
                if (!pvVisitsText.isEmpty()) {
                    item.insert(QStringLiteral("pvVisitsText"),
                                pvVisitsText.toString());
                }
                break;
            }

            if (key == QLatin1StringView("move")) {
                const QString move = nextMoveToken(segment, tokenPosition);
                if (move.isEmpty())
                    break;
                item.insert(QStringLiteral("move"), move);
                continue;
            }

            const QStringView value = nextToken(segment, tokenPosition);
            if (value.isEmpty())
                break;

            bool ok = false;

            if (key == QLatin1StringView("order")) {
                const int parsedOrder = value.toInt(&ok);
                if (ok)
                    item.insert(QStringLiteral("order"), parsedOrder);
            } else if (key == QLatin1StringView("visits")) {
                const int visits = value.toInt(&ok);
                if (ok)
                    item.insert(QStringLiteral("visits"), visits);
            } else if (key == QLatin1StringView("isSymmetryOf")) {
                item.insert(QStringLiteral("isSymmetryOf"), value.toString());
            } else if (key == QLatin1StringView("winrate")) {
                const double winrate = value.toDouble(&ok);
                if (ok)
                    item.insert(QStringLiteral("winrate"), winrate);
            } else if (key == QLatin1StringView("lcb")) {
                const double lcb = value.toDouble(&ok);
                if (ok)
                    item.insert(QStringLiteral("lcb"), lcb);
            } else if (key == QLatin1StringView("prior")
                       || key == QLatin1StringView("policy")) {
                const double prior = value.toDouble(&ok);
                if (ok)
                    item.insert(QStringLiteral("prior"), prior);
            } else if (key == QLatin1StringView("scoreMean") || key == QLatin1StringView("scoreLead")) {
                const double scoreMean = value.toDouble(&ok);
                if (ok)
                    item.insert(QStringLiteral("scoreMean"), scoreMean);
            } else if (key == QLatin1StringView("scoreStdev")) {
                const double scoreStdev = value.toDouble(&ok);
                if (ok)
                    item.insert(QStringLiteral("scoreStdev"), scoreStdev);
            }
        }

        if (item.contains(QStringLiteral("move"))) {
            if (item.contains(QStringLiteral("order")))
                order = item.value(QStringLiteral("order")).toInt();
            item.insert(QStringLiteral("order"), order);
            parsedCandidates.append({ order, item });
        }
        ++segmentIndex;

        if (separator < 0)
            break;
        segmentStart = separator + 5;
        while (segmentStart < candidatePayload.size()
               && candidatePayload.at(segmentStart).isSpace()) {
            ++segmentStart;
        }
    }

    if (parsedCandidates.isEmpty())
        return { {}, ownership };

    std::sort(parsedCandidates.begin(), parsedCandidates.end(), [](const ParsedCandidateInfo &a, const ParsedCandidateInfo &b) {
        return a.order < b.order;
    });

    QVariantList candidateItems;
    candidateItems.reserve(parsedCandidates.size());
    for (const ParsedCandidateInfo &candidate : parsedCandidates)
        candidateItems.append(candidate.item);

    return { candidateItems, ownership };
}
