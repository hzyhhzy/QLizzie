#include "engineprotocol.h"

#include <algorithm>

EngineProtocolState::Response EngineProtocolState::parseResponse(const QString &line)
{
    const QString trimmedLine = line.trimmed();
    if (trimmedLine.isEmpty())
        return {};

    Response response;
    response.rawLine = line;
    if (trimmedLine.startsWith(QLatin1Char('=')))
        response.type = ResponseType::Success;
    else if (trimmedLine.startsWith(QLatin1Char('?')))
        response.type = ResponseType::Error;
    else
        return {};

    response.payload = trimmedLine.mid(1).trimmed();
    return response;
}

void EngineProtocolState::beginHandshake()
{
    m_handshakePending = true;
}

void EngineProtocolState::beginAnalysis(int syncResponseCount)
{
    resetTransaction();
    m_transactionId = ++m_nextTransactionId;
    m_responsesBeforeCompletion = std::max(0, syncResponseCount);
    if (m_responsesBeforeCompletion == 0) {
        m_acceptCandidateInfo = true;
        return;
    }
    m_transactionKind = TransactionKind::Analysis;
}

void EngineProtocolState::beginMove(int preludeResponseCount, int requestId)
{
    resetTransaction();
    m_transactionId = ++m_nextTransactionId;
    m_transactionKind = TransactionKind::Move;
    m_responsesBeforeCompletion = std::max(0, preludeResponseCount);
    m_moveRequestId = requestId;
}

void EngineProtocolState::expectResponse(ResponseRole role)
{
    const quint64 transactionId = role == ResponseRole::Ignored ? 0 : m_transactionId;
    m_expectedResponses.enqueue({ role, transactionId });
}

void EngineProtocolState::stopAcceptingCandidateInfo()
{
    m_acceptCandidateInfo = false;
}

EngineProtocolState::Outcome EngineProtocolState::consumeLine(const QString &line,
                                                              bool ignoreErrorResponses)
{
    const Response response = parseResponse(line);
    if (!response.isResponse())
        return {};

    if (m_handshakePending) {
        m_handshakePending = false;
        return {
            Event::HandshakeCompleted,
            true,
            response.isSuccess() || ignoreErrorResponses,
            0,
            response.payload,
            response.rawLine
        };
    }

    if (m_expectedResponses.isEmpty())
        return {};

    const ExpectedResponse expected = m_expectedResponses.dequeue();
    if (expected.role == ResponseRole::Ignored)
        return { Event::None, true };
    if (expected.transactionId == 0 || expected.transactionId != m_transactionId)
        return { Event::None, true };

    if (expected.role == ResponseRole::AnalysisSync
            && m_transactionKind == TransactionKind::Analysis) {
        if (!response.isSuccess() && !ignoreErrorResponses) {
            const QString failureLine = response.rawLine;
            resetTransaction();
            return {
                Event::AnalysisSyncCompleted,
                true,
                false,
                0,
                QString(),
                failureLine
            };
        }
        --m_responsesBeforeCompletion;

        if (m_responsesBeforeCompletion > 0)
            return {
                Event::None,
                true,
                false,
                0,
                QString(),
                response.rawLine
            };

        resetTransaction();
        m_acceptCandidateInfo = true;
        return {
            Event::AnalysisSyncCompleted,
            true,
            true,
            0,
            QString(),
            response.rawLine
        };
    }

    if (expected.role == ResponseRole::MovePrelude
            && m_transactionKind == TransactionKind::Move) {
        if (!response.isSuccess() && !ignoreErrorResponses) {
            const int requestId = m_moveRequestId;
            const QString failureLine = response.rawLine;
            resetTransaction();
            return {
                Event::MovePreludeFailed,
                true,
                false,
                requestId,
                QString(),
                failureLine
            };
        }
        if (m_responsesBeforeCompletion > 0)
            --m_responsesBeforeCompletion;
        if (m_responsesBeforeCompletion == 0) {
            return {
                Event::MovePreludeCompleted,
                true,
                true,
                m_moveRequestId,
                QString(),
                response.rawLine
            };
        }
        return {
            Event::None,
            true,
            false,
            0,
            QString(),
            response.rawLine
        };
    }

    if (expected.role == ResponseRole::MoveGenerate
            && m_transactionKind == TransactionKind::Move) {
        if (!response.isSuccess())
            rememberFailure(response);

        const bool success = !m_transactionFailed;
        const int requestId = m_moveRequestId;
        QString payload = response.payload;
        if (success && payload.isEmpty())
            payload = QStringLiteral("pass");
        const QString rawLine = success ? response.rawLine : m_firstFailureLine;
        resetTransaction();
        return {
            Event::MoveCompleted,
            true,
            success,
            requestId,
            payload,
            rawLine
        };
    }

    return {};
}

EngineProtocolState::Outcome EngineProtocolState::cancelMove(const QString &reason)
{
    if (!hasActiveMove())
        return {};

    const int requestId = m_moveRequestId;
    resetTransaction();
    return {
        Event::MoveCompleted,
        true,
        false,
        requestId,
        QString(),
        reason
    };
}

void EngineProtocolState::resetTransaction()
{
    m_transactionKind = TransactionKind::None;
    m_transactionId = 0;
    m_responsesBeforeCompletion = 0;
    m_moveRequestId = 0;
    m_transactionFailed = false;
    m_acceptCandidateInfo = false;
    m_firstFailureLine.clear();
}

void EngineProtocolState::reset()
{
    resetTransport();
    resetTransaction();
}

void EngineProtocolState::resetTransport()
{
    m_handshakePending = false;
    m_expectedResponses.clear();
}

bool EngineProtocolState::handshakePending() const
{
    return m_handshakePending;
}

bool EngineProtocolState::acceptsCandidateInfo() const
{
    return m_acceptCandidateInfo;
}

bool EngineProtocolState::hasActiveMove() const
{
    return m_transactionKind == TransactionKind::Move;
}

void EngineProtocolState::rememberFailure(const Response &response)
{
    m_transactionFailed = true;
    if (m_firstFailureLine.isEmpty())
        m_firstFailureLine = response.rawLine;
}
