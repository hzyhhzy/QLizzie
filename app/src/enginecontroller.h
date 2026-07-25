#pragma once

#include "engineprotocol.h"

#include <QList>
#include <QObject>
#include <QProcess>
#include <QStringList>
#include <QVariantList>

class CoreTests;

class EngineController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString command READ command WRITE setCommand NOTIFY commandChanged)
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)
    Q_PROPERTY(bool failed READ failed NOTIFY failedChanged)
    Q_PROPERTY(QString failureKind READ failureKind NOTIFY failureKindChanged)
    Q_PROPERTY(QString failureMessage READ failureMessage NOTIFY failureMessageChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusTextChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(bool ignoreGtpErrors READ ignoreGtpErrors WRITE setIgnoreGtpErrors
               NOTIFY ignoreGtpErrorsChanged)
    Q_PROPERTY(QVariantList candidates READ candidates NOTIFY candidatesChanged)
    Q_PROPERTY(QVariantList ownership READ ownership NOTIFY candidatesChanged)
    Q_PROPERTY(int candidateRevision READ candidateRevision NOTIFY candidatesChanged)

public:
    explicit EngineController(QObject *parent = nullptr);
    ~EngineController() override;

    QString command() const;
    void setCommand(const QString &command);

    bool running() const;
    bool ready() const;
    bool failed() const;
    QString failureKind() const;
    QString failureMessage() const;
    QString statusText() const;
    QString lastError() const;
    bool ignoreGtpErrors() const;
    void setIgnoreGtpErrors(bool ignore);
    QVariantList candidates() const;
    QVariantList ownership() const;
    int candidateRevision() const;

    Q_INVOKABLE void ensureStarted();
    Q_INVOKABLE void restart();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void shutdown();
    Q_INVOKABLE void sendCommand(const QString &command);
    Q_INVOKABLE void requestAnalysis(const QStringList &syncCommands,
                                     const QString &analyzeCommand,
                                     int syncRequestId);
    Q_INVOKABLE void requestMove(const QStringList &syncCommands,
                                 const QString &timeSettingsCommand,
                                 const QString &genmoveCommand,
                                 int requestId,
                                 int syncRequestId);
    Q_INVOKABLE bool canUseIncrementalSync() const;
    Q_INVOKABLE void clearCandidates();

signals:
    void commandChanged();
    void runningChanged();
    void readyChanged();
    void failedChanged();
    void failureKindChanged();
    void failureMessageChanged();
    void statusTextChanged();
    void lastErrorChanged();
    void ignoreGtpErrorsChanged();
    void candidatesChanged();
    void engineInput(const QString &line);
    void engineOutput(const QString &line);
    void engineErrorOutput(const QString &line);
    void gtpErrorResponse(const QString &line);
    void analysisCommandFailed(int analysisRequestId, const QString &line);
    void engineSynchronizationCompleted(int syncRequestId);
    void moveGenerated(int requestId, const QString &move, bool ok, const QString &rawLine);

private:
    friend class CoreTests;

    struct QueuedCommand {
        QString text;
        EngineProtocolState::ResponseRole responseRole = EngineProtocolState::ResponseRole::Ignored;
        bool expectsResponse = true;
    };

    static QStringList splitCommandLine(const QString &commandLine);
    void startProcess();
    void sendPendingCommands();
    void writeCommand(const QueuedCommand &command);
    void interruptCurrentCommand(const QueuedCommand &command, const QString &reason);
#ifdef Q_OS_WIN
    void attachProcessToJobObject();
    void closeProcessJobObject();
#endif
    void readStandardOutput();
    void readStandardError();
    void consumeLines(QByteArray &buffer, bool stderrStream);
    void handleStdoutLine(const QString &line);
    void handleStderrLine(const QString &line);
    void handleProtocolOutcome(const EngineProtocolState::Outcome &outcome);
    void failActiveMoveRequest(const QString &message);
    void failTransport(const QString &message);
    void resetProtocolState(bool clearPendingCommands = true);
    void parseInfoLine(const QString &line);
    void setRunning(bool running);
    void setReady(bool ready);
    void setFailed(bool failed, const QString &message = QString(), const QString &kind = QString());
    void setStatusText(const QString &text);
    void setLastError(const QString &text);

    QProcess m_process;
    QString m_command;
    bool m_running = false;
    bool m_ready = false;
    bool m_failed = false;
    bool m_stopping = false;
    bool m_restartPending = false;
    bool m_shutdownRequested = false;
    QString m_failureKind;
    QString m_failureMessage;
    QString m_statusText;
    QString m_lastError;
    bool m_ignoreGtpErrors = true;
    QVariantList m_candidates;
    QVariantList m_ownership;
    int m_candidateRevision = 0;
    QList<QueuedCommand> m_pendingCommands;
    int m_responsesPending = 0;
    int m_activeSyncRequestId = 0;
    int m_activeAnalysisRequestId = 0;
    EngineProtocolState m_protocolState;
    QByteArray m_stdoutBuffer;
    QByteArray m_stderrBuffer;
    QString m_transportFailureMessage;
    bool m_discardingOversizedStdoutLine = false;
    bool m_discardingOversizedStderrLine = false;
#ifdef Q_OS_WIN
    void *m_jobHandle = nullptr;
#endif
};
