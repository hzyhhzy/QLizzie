#pragma once

#include <QQueue>
#include <QString>

class EngineProtocolState
{
public:
    enum class ResponseType {
        None,
        Success,
        Error
    };

    struct Response {
        ResponseType type = ResponseType::None;
        QString payload;
        QString rawLine;

        bool isResponse() const { return type != ResponseType::None; }
        bool isSuccess() const { return type == ResponseType::Success; }
    };

    enum class Event {
        None,
        HandshakeCompleted,
        AnalysisSyncCompleted,
        MovePreludeCompleted,
        MovePreludeFailed,
        MoveCompleted
    };

    enum class ResponseRole {
        Ignored,
        AnalysisSync,
        MovePrelude,
        MoveGenerate
    };

    struct Outcome {
        Event event = Event::None;
        bool handled = false;
        bool success = false;
        int requestId = 0;
        QString payload;
        QString rawLine;
        bool toleratedSyncError = false;
    };

    static Response parseResponse(const QString &line);

    void beginHandshake();
    void beginAnalysis(int syncResponseCount);
    void beginMove(int preludeResponseCount, int requestId);
    void expectResponse(ResponseRole role);
    void stopAcceptingCandidateInfo();

    Outcome consumeLine(const QString &line, bool ignoreErrorResponses = false);
    Outcome cancelMove(const QString &reason);

    void resetTransaction();
    void resetTransport();
    void reset();

    bool handshakePending() const;
    bool acceptsCandidateInfo() const;
    bool hasActiveMove() const;

private:
    enum class TransactionKind {
        None,
        Analysis,
        Move
    };

    struct ExpectedResponse {
        ResponseRole role = ResponseRole::Ignored;
        quint64 transactionId = 0;
    };

    void rememberFailure(const Response &response);

    bool m_handshakePending = false;
    TransactionKind m_transactionKind = TransactionKind::None;
    QQueue<ExpectedResponse> m_expectedResponses;
    quint64 m_nextTransactionId = 0;
    quint64 m_transactionId = 0;
    int m_responsesBeforeCompletion = 0;
    int m_moveRequestId = 0;
    bool m_transactionFailed = false;
    bool m_transactionHadToleratedSyncError = false;
    bool m_acceptCandidateInfo = false;
    QString m_firstFailureLine;
};
