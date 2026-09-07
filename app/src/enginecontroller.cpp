#include "enginecontroller.h"
#include "engineanalysis.h"

#include <QByteArrayView>
#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QStringView>
#include <QTimer>


#ifdef Q_OS_WIN
#include <qt_windows.h>
#endif

namespace {
constexpr qsizetype kMaximumEngineLineBytes = 262144;
constexpr qsizetype kMaximumAnalysisInfoLineBytes = 4 * 1024 * 1024;

QString portableRootPath()
{
    const QString environmentRoot = qEnvironmentVariable("QLIZZIE_PORTABLE_ROOT");
    if (!environmentRoot.trimmed().isEmpty())
        return QDir::cleanPath(environmentRoot);

    const QString appDirPath = QCoreApplication::applicationDirPath();
    const QFileInfo appDirInfo(appDirPath);
    if (appDirInfo.fileName().compare(QStringLiteral("bin"), Qt::CaseInsensitive) == 0)
        return QDir(appDirPath).absoluteFilePath(QStringLiteral(".."));

    return appDirPath;
}

QString resolvedProgramPath(const QString &program)
{
    const QFileInfo programInfo(program);
    if (programInfo.isAbsolute())
        return program;

    return QDir::cleanPath(QDir(portableRootPath()).absoluteFilePath(program));
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

bool isAsciiWhitespace(char ch)
{
    return ch == ' ' || ch == '\t' || ch == '\r'
        || ch == '\n' || ch == '\f' || ch == '\v';
}

QByteArrayView nextToken(QByteArrayView text, qsizetype &position)
{
    while (position < text.size() && isAsciiWhitespace(text.at(position)))
        ++position;
    const qsizetype start = position;
    while (position < text.size() && !isAsciiWhitespace(text.at(position)))
        ++position;
    return text.sliced(start, position - start);
}

bool communicationInfoLineFiltered(QStringView text)
{
    qsizetype position = 0;
    return nextToken(text, position) == QLatin1StringView("info")
        && nextToken(text, position) == QLatin1StringView("move");
}

bool communicationInfoLineFiltered(QByteArrayView text)
{
    qsizetype position = 0;
    return nextToken(text, position) == QByteArrayView("info", 4)
        && nextToken(text, position) == QByteArrayView("move", 4);
}

qsizetype maximumEngineLineBytes(QByteArrayView text, bool stderrStream)
{
    if (!stderrStream && communicationInfoLineFiltered(text))
        return kMaximumAnalysisInfoLineBytes;
    return kMaximumEngineLineBytes;
}

QStringList normalizedCommands(const QStringList &commands)
{
    QStringList result;
    result.reserve(commands.size());
    for (const QString &command : commands) {
        const QString trimmedCommand = command.trimmed();
        if (!trimmedCommand.isEmpty())
            result.append(trimmedCommand);
    }
    return result;
}

QString commandName(const QString &command)
{
    const QStringList tokens = command.simplified().split(QLatin1Char(' '), Qt::SkipEmptyParts);
    if (tokens.isEmpty())
        return {};

    int commandIndex = 0;
    bool hasCommandId = false;
    tokens.first().toInt(&hasCommandId);
    if (hasCommandId && tokens.size() > 1)
        commandIndex = 1;

    return tokens.at(commandIndex).toLower();
}

bool commandExpectsResponse(const QString &command)
{
    const QString name = commandName(command);
    return name != QStringLiteral("kata-analyze")
        && name != QStringLiteral("lz-analyze");
}

}

EngineController::EngineController(QObject *parent)
    : QObject(parent)
    , m_statusText(QStringLiteral("Engine not started"))
{
#ifdef Q_OS_WIN
    m_process.setCreateProcessArgumentsModifier([](QProcess::CreateProcessArguments *arguments) {
        arguments->flags |= CREATE_NO_WINDOW;
    });
#endif

    m_process.setProcessChannelMode(QProcess::SeparateChannels);

    connect(&m_process, &QProcess::started, this, [this]() {
#ifdef Q_OS_WIN
        attachProcessToJobObject();
#endif
        if (m_shutdownRequested) {
            m_process.kill();
            return;
        }
        setRunning(true);
        setReady(false);
        m_protocolState.beginHandshake();
        setStatusText(QStringLiteral("Engine starting"));
        writeCommand({ QStringLiteral("name"),
                       EngineProtocolState::ResponseRole::Ignored,
                       false });
        sendPendingCommands();
    });

    connect(&m_process, &QProcess::readyReadStandardOutput, this, &EngineController::readStandardOutput);
    connect(&m_process, &QProcess::readyReadStandardError, this, &EngineController::readStandardError);

    connect(&m_process, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        if (m_stopping)
            return;

        QString message;
        switch (error) {
        case QProcess::FailedToStart:
            message = QStringLiteral("Failed to start engine");
            break;
        case QProcess::Crashed:
            message = QStringLiteral("Engine crashed");
            break;
        case QProcess::Timedout:
            message = QStringLiteral("Engine timed out");
            break;
        case QProcess::WriteError:
            message = QStringLiteral("Engine write error");
            break;
        case QProcess::ReadError:
            message = QStringLiteral("Engine read error");
            break;
        case QProcess::UnknownError:
            message = QStringLiteral("Unknown engine error");
            break;
        }
        if (!m_process.errorString().isEmpty())
            message += QStringLiteral(": ") + m_process.errorString();
        failActiveMoveRequest(message);
        resetProtocolState();
        setReady(false);
        setRunning(false);
        setFailed(true, message, QStringLiteral("generic"));
        setLastError(message);
        setStatusText(message);
    });

    connect(&m_process,
            qOverload<int, QProcess::ExitStatus>(&QProcess::finished),
            this,
            [this](int exitCode, QProcess::ExitStatus exitStatus) {
                const bool intentionalStop = m_stopping;
                const bool restartPending = m_restartPending;
                const QString transportFailureMessage = m_transportFailureMessage;
                m_transportFailureMessage.clear();
#ifdef Q_OS_WIN
                closeProcessJobObject();
#endif
                m_stopping = false;
                m_restartPending = false;
                setRunning(false);
                setReady(false);

                if (restartPending && !m_shutdownRequested) {
                    m_protocolState.resetTransport();
                    setStatusText(QStringLiteral("Engine restarting"));
                    startProcess();
                    return;
                }

                if (!transportFailureMessage.isEmpty()) {
                    resetProtocolState();
                    setFailed(true, transportFailureMessage, QStringLiteral("protocol"));
                    setLastError(transportFailureMessage);
                    setStatusText(transportFailureMessage);
                    return;
                }

                if (intentionalStop) {
                    resetProtocolState();
                    setStatusText(QStringLiteral("Engine stopped"));
                    return;
                }

                QString message = exitStatus == QProcess::CrashExit
                                      ? QStringLiteral("Engine crashed")
                                      : QStringLiteral("Engine exited");
                message += QStringLiteral(" (%1)").arg(exitCode);
                failActiveMoveRequest(message);
                resetProtocolState();
                setFailed(true, message, QStringLiteral("generic"));
                setLastError(message);
                setStatusText(message);
            });
}

EngineController::~EngineController()
{
    shutdown();
}

QString EngineController::command() const
{
    return m_command;
}

void EngineController::setCommand(const QString &command)
{
    if (m_command == command)
        return;
    m_command = command;
    emit commandChanged();
}

bool EngineController::running() const
{
    return m_running;
}

bool EngineController::ready() const
{
    return m_ready;
}

bool EngineController::failed() const
{
    return m_failed;
}

QString EngineController::failureKind() const
{
    return m_failureKind;
}

QString EngineController::failureMessage() const
{
    return m_failureMessage;
}

QString EngineController::statusText() const
{
    return m_statusText;
}

QString EngineController::lastError() const
{
    return m_lastError;
}

bool EngineController::ignoreGtpErrors() const
{
    return m_ignoreGtpErrors;
}

void EngineController::setIgnoreGtpErrors(bool ignore)
{
    if (m_ignoreGtpErrors == ignore)
        return;
    m_ignoreGtpErrors = ignore;
    emit ignoreGtpErrorsChanged();
}

QVariantList EngineController::candidates() const
{
    return m_candidates;
}

QVariantList EngineController::ownership() const
{
    return m_ownership;
}

int EngineController::candidateCount() const
{
    return m_candidates.size();
}

int EngineController::candidateRevision() const
{
    return m_candidateRevision;
}

void EngineController::ensureStarted()
{
    if (m_shutdownRequested)
        return;
    if (m_process.state() != QProcess::NotRunning)
        return;
    startProcess();
}

void EngineController::restart()
{
    if (m_shutdownRequested)
        return;
    m_transportFailureMessage.clear();
    setFailed(false);
    setLastError(QString());
    failActiveMoveRequest(QStringLiteral("Engine restarting"));
    resetProtocolState();

    if (m_process.state() != QProcess::NotRunning) {
        m_stopping = true;
        m_restartPending = true;
        setStatusText(QStringLiteral("Engine restarting"));
        m_process.kill();
        return;
    }
    m_stopping = false;
    m_restartPending = false;
    setRunning(false);
    setReady(false);
    startProcess();
}

void EngineController::stop()
{
    m_transportFailureMessage.clear();
    setFailed(false);
    setLastError(QString());
    failActiveMoveRequest(QStringLiteral("Engine stopped"));
    resetProtocolState();

    if (m_process.state() == QProcess::NotRunning) {
        setRunning(false);
        setReady(false);
        setStatusText(QStringLiteral("Engine stopped"));
        return;
    }

    m_stopping = true;
    m_restartPending = false;
    emit engineInput(QStringLiteral("quit"));
    m_process.write(QByteArrayLiteral("quit\n"));
    m_process.closeWriteChannel();
    QTimer::singleShot(1000, this, [this]() {
        if (m_stopping && !m_restartPending && m_process.state() != QProcess::NotRunning)
            m_process.kill();
    });
}

void EngineController::shutdown()
{
    m_shutdownRequested = true;
    m_transportFailureMessage.clear();
    failActiveMoveRequest(QStringLiteral("Engine shutting down"));
    resetProtocolState();
    m_stopping = true;
    m_restartPending = false;

    if (m_process.state() == QProcess::NotRunning) {
#ifdef Q_OS_WIN
        closeProcessJobObject();
#endif
        return;
    }

    bool finished = false;

    if (m_process.state() == QProcess::Running) {
        emit engineInput(QStringLiteral("quit"));
        m_process.write(QByteArrayLiteral("quit\n"));
        m_process.closeWriteChannel();
        finished = m_process.waitForFinished(1200);
    }

    if (!finished) {
        m_process.terminate();
        finished = m_process.waitForFinished(500);
    }

    if (!finished) {
        m_process.kill();
        m_process.waitForFinished(1500);
    }

#ifdef Q_OS_WIN
    closeProcessJobObject();
    if (m_process.state() != QProcess::NotRunning)
        m_process.waitForFinished(500);
#endif
}

#ifdef Q_OS_WIN
void EngineController::attachProcessToJobObject()
{
    closeProcessJobObject();

    const qint64 processId = m_process.processId();
    if (processId <= 0)
        return;

    HANDLE job = CreateJobObjectW(nullptr, nullptr);
    if (!job)
        return;

    JOBOBJECT_EXTENDED_LIMIT_INFORMATION limits = {};
    limits.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
    if (!SetInformationJobObject(job, JobObjectExtendedLimitInformation, &limits, sizeof(limits))) {
        CloseHandle(job);
        return;
    }

    HANDLE process = OpenProcess(PROCESS_SET_QUOTA | PROCESS_TERMINATE, FALSE, static_cast<DWORD>(processId));
    if (!process) {
        CloseHandle(job);
        return;
    }

    const BOOL assigned = AssignProcessToJobObject(job, process);
    CloseHandle(process);
    if (!assigned) {
        CloseHandle(job);
        return;
    }

    m_jobHandle = job;
}

void EngineController::closeProcessJobObject()
{
    if (!m_jobHandle)
        return;
    CloseHandle(static_cast<HANDLE>(m_jobHandle));
    m_jobHandle = nullptr;
}
#endif

void EngineController::sendCommand(const QString &command)
{
    if (m_shutdownRequested)
        return;
    const QString trimmedCommand = command.trimmed();
    if (trimmedCommand.isEmpty())
        return;

    const QueuedCommand queuedCommand {
        trimmedCommand,
        EngineProtocolState::ResponseRole::Ignored,
        commandExpectsResponse(trimmedCommand)
    };

    if (commandName(trimmedCommand) == QStringLiteral("stop")) {
        interruptCurrentCommand(queuedCommand, QStringLiteral("Move request stopped"));
        return;
    }

    m_pendingCommands.append(queuedCommand);

    if (m_restartPending)
        return;

    if (m_process.state() == QProcess::NotRunning) {
        startProcess();
        return;
    }

    if (m_process.state() == QProcess::Starting)
        return;

    sendPendingCommands();
}

void EngineController::requestAnalysis(const QStringList &syncCommands,
                                       const QString &analyzeCommand,
                                       int syncRequestId)
{
    if (m_shutdownRequested)
        return;
    const QString supersededMessage = QStringLiteral("Move request superseded by analysis");
    if (m_responsesPending > 0) {
        interruptCurrentCommand({ QStringLiteral("stop"),
                                  EngineProtocolState::ResponseRole::Ignored,
                                  true },
                                supersededMessage);
    } else {
        failActiveMoveRequest(supersededMessage);
    }
    clearCandidates();
    m_pendingCommands.clear();
    const QStringList normalizedSyncCommands = normalizedCommands(syncCommands);
    for (const QString &command : normalizedSyncCommands) {
        m_pendingCommands.append({ command,
                                   EngineProtocolState::ResponseRole::AnalysisSync,
                                   true });
    }
    const int syncResponseCount = normalizedSyncCommands.size();
    const QString trimmedAnalyzeCommand = analyzeCommand.trimmed();
    if (!trimmedAnalyzeCommand.isEmpty())
        m_pendingCommands.append({ trimmedAnalyzeCommand,
                                   EngineProtocolState::ResponseRole::Ignored,
                                   false });
    m_activeSyncRequestId = syncRequestId;
    m_activeAnalysisRequestId = syncRequestId;
    m_protocolState.beginAnalysis(syncResponseCount);

    if (m_restartPending) {
        setStatusText(QStringLiteral("Engine restarting"));
        return;
    }

    if (m_process.state() == QProcess::Running) {
        sendPendingCommands();
    } else if (m_process.state() == QProcess::NotRunning) {
        startProcess();
    } else {
        setStatusText(QStringLiteral("Starting engine"));
    }
}

void EngineController::requestSynchronization(const QStringList &syncCommands,
                                              int syncRequestId)
{
    if (m_shutdownRequested)
        return;
    const QString supersededMessage =
        QStringLiteral("Move request superseded by board synchronization");
    if (m_responsesPending > 0) {
        interruptCurrentCommand({ QStringLiteral("stop"),
                                  EngineProtocolState::ResponseRole::Ignored,
                                  true },
                                supersededMessage);
    } else {
        failActiveMoveRequest(supersededMessage);
    }
    clearCandidates();
    m_pendingCommands.clear();
    const QStringList normalizedSyncCommands = normalizedCommands(syncCommands);
    for (const QString &command : normalizedSyncCommands) {
        m_pendingCommands.append({ command,
                                   EngineProtocolState::ResponseRole::AnalysisSync,
                                   true });
    }
    m_activeSyncRequestId = syncRequestId;
    m_activeAnalysisRequestId = 0;
    m_protocolState.beginSynchronization(normalizedSyncCommands.size());

    if (m_restartPending) {
        setStatusText(QStringLiteral("Engine restarting"));
        return;
    }

    if (m_process.state() == QProcess::Running) {
        sendPendingCommands();
    } else if (m_process.state() == QProcess::NotRunning) {
        startProcess();
    } else {
        setStatusText(QStringLiteral("Starting engine"));
    }
}

void EngineController::requestMove(const QStringList &syncCommands,
                                   const QString &timeSettingsCommand,
                                   const QString &genmoveCommand,
                                   int requestId,
                                   int syncRequestId)
{
    if (m_shutdownRequested)
        return;
    const QString supersededMessage = QStringLiteral("Move request superseded");
    if (m_responsesPending > 0) {
        interruptCurrentCommand({ QStringLiteral("stop"),
                                  EngineProtocolState::ResponseRole::Ignored,
                                  true },
                                supersededMessage);
    } else {
        failActiveMoveRequest(supersededMessage);
    }
    clearCandidates();
    m_pendingCommands.clear();
    const QStringList normalizedSyncCommands = normalizedCommands(syncCommands);
    for (const QString &command : normalizedSyncCommands) {
        m_pendingCommands.append({ command,
                                   EngineProtocolState::ResponseRole::MovePrelude,
                                   true });
    }
    const QString trimmedTimeSettings = timeSettingsCommand.trimmed();
    const QString trimmedGenmove = genmoveCommand.trimmed();
    if (!trimmedTimeSettings.isEmpty())
        m_pendingCommands.append({ trimmedTimeSettings,
                                   EngineProtocolState::ResponseRole::MovePrelude,
                                   true });
    if (!trimmedGenmove.isEmpty())
        m_pendingCommands.append({ trimmedGenmove,
                                   EngineProtocolState::ResponseRole::MoveGenerate,
                                   true });

    if (trimmedGenmove.isEmpty()) {
        m_activeSyncRequestId = 0;
        m_protocolState.resetTransaction();
    } else {
        const int preludeResponseCount = m_pendingCommands.size() - 1;
        m_activeSyncRequestId = syncRequestId;
        m_protocolState.beginMove(preludeResponseCount, requestId);
    }

    if (m_restartPending) {
        setStatusText(QStringLiteral("Engine restarting"));
        return;
    }

    if (m_process.state() == QProcess::Running) {
        sendPendingCommands();
    } else if (m_process.state() == QProcess::NotRunning) {
        startProcess();
    } else {
        setStatusText(QStringLiteral("Starting engine"));
    }
}

bool EngineController::canUseIncrementalSync() const
{
    return !m_shutdownRequested
        && m_process.state() == QProcess::Running
        && m_running
        && m_ready
        && !m_failed
        && !m_stopping
        && !m_restartPending
        && m_responsesPending == 0
        && m_pendingCommands.isEmpty();
}

void EngineController::clearCandidates()
{
    m_protocolState.stopAcceptingCandidateInfo();
    m_activeAnalysisRequestId = 0;
    if (m_candidates.isEmpty() && m_ownership.isEmpty())
        return;

    m_candidates.clear();
    m_ownership.clear();
    ++m_candidateRevision;
    emit candidatesChanged();
}

QStringList EngineController::splitCommandLine(const QString &commandLine)
{
    QStringList result;
    QString current;
    bool inSingleQuote = false;
    bool inDoubleQuote = false;
    bool justClosedQuote = false;

    for (const QChar ch : commandLine) {
        if (ch == QLatin1Char('\'') && !inDoubleQuote) {
            inSingleQuote = !inSingleQuote;
            justClosedQuote = !inSingleQuote;
            continue;
        }
        if (ch == QLatin1Char('"') && !inSingleQuote) {
            inDoubleQuote = !inDoubleQuote;
            justClosedQuote = !inDoubleQuote;
            continue;
        }
        if (ch.isSpace() && !inSingleQuote && !inDoubleQuote) {
            if (!current.isEmpty() || justClosedQuote) {
                result.append(current);
                current.clear();
                justClosedQuote = false;
            }
            continue;
        }

        current.append(ch);
        justClosedQuote = false;
    }

    if (!current.isEmpty() || justClosedQuote)
        result.append(current);
    return result;
}

void EngineController::startProcess()
{
    if (m_shutdownRequested)
        return;
    m_transportFailureMessage.clear();
    const QStringList parts = splitCommandLine(m_command);
    setFailed(false);
    setLastError(QString());

    if (parts.isEmpty() || parts.first().trimmed().isEmpty()) {
        const QString message = QStringLiteral("Engine command is empty");
        failActiveMoveRequest(message);
        resetProtocolState();
        setFailed(true, QString(), QStringLiteral("emptyCommand"));
        setLastError(QString());
        setStatusText(message);
        setRunning(false);
        setReady(false);
        return;
    }

    const QString programPath = resolvedProgramPath(parts.first());
    const QFileInfo programInfo(programPath);
    if (!programInfo.exists() || !programInfo.isFile()) {
        const QString message = QStringLiteral("Engine program path does not exist: %1").arg(programPath);
        failActiveMoveRequest(message);
        resetProtocolState();
        setFailed(true, QString(), QStringLiteral("missingProgram"));
        setLastError(programPath);
        setStatusText(QStringLiteral("Engine program path does not exist"));
        setRunning(false);
        setReady(false);
        return;
    }

    m_stopping = false;
    setStatusText(QStringLiteral("Starting engine"));
    setReady(false);
    if (m_pendingCommands.isEmpty())
        m_protocolState.resetTransaction();
    m_stdoutBuffer.clear();
    m_stderrBuffer.clear();
    m_discardingOversizedStdoutLine = false;
    m_discardingOversizedStderrLine = false;
    m_process.setWorkingDirectory(portableRootPath());
    m_process.start(programPath, parts.mid(1));
}

void EngineController::sendPendingCommands()
{
    if (m_shutdownRequested || m_process.state() != QProcess::Running
            || !m_ready || m_responsesPending > 0)
        return;

    while (!m_pendingCommands.isEmpty()) {
        const QueuedCommand command = m_pendingCommands.takeFirst();
        writeCommand(command);
        if (command.expectsResponse)
            return;
    }
}

void EngineController::writeCommand(const QueuedCommand &command)
{
    if (m_shutdownRequested)
        return;
    if (command.text.isEmpty())
        return;

    if (command.expectsResponse) {
        m_protocolState.expectResponse(command.responseRole);
        ++m_responsesPending;
    }
    emit engineInput(command.text);
    m_process.write(command.text.toUtf8() + '\n');
}

void EngineController::interruptCurrentCommand(const QueuedCommand &command, const QString &reason)
{
    failActiveMoveRequest(reason);
    m_pendingCommands.clear();
    m_protocolState.resetTransaction();
    m_activeSyncRequestId = 0;
    m_activeAnalysisRequestId = 0;
    if (m_process.state() == QProcess::Running && m_ready)
        writeCommand(command);
}

void EngineController::readStandardOutput()
{
    m_stdoutBuffer.append(m_process.readAllStandardOutput());
    consumeLines(m_stdoutBuffer, false);
}

void EngineController::readStandardError()
{
    m_stderrBuffer.append(m_process.readAllStandardError());
    consumeLines(m_stderrBuffer, true);
}

void EngineController::consumeLines(QByteArray &buffer, bool stderrStream)
{
    if (!stderrStream && !m_transportFailureMessage.isEmpty()) {
        buffer.clear();
        return;
    }

    bool &discardingOversizedLine = stderrStream
        ? m_discardingOversizedStderrLine
        : m_discardingOversizedStdoutLine;
    const auto reportOversizedLine = [this, stderrStream](qsizetype maximumBytes) {
        const QString marker = QStringLiteral(
            "... [engine %1 line exceeded %2 bytes; discarded] ...")
            .arg(stderrStream ? QStringLiteral("stderr")
                              : QStringLiteral("stdout"))
            .arg(maximumBytes);
        if (stderrStream)
            emit engineErrorOutput(marker);
        else
            emit engineOutput(marker);
        return marker;
    };

    if (discardingOversizedLine) {
        const qsizetype discardedLineEnd = buffer.indexOf('\n');
        if (discardedLineEnd < 0) {
            buffer.clear();
            return;
        }
        buffer.remove(0, discardedLineEnd + 1);
        discardingOversizedLine = false;
    }

    qsizetype newlineIndex = -1;
    while ((newlineIndex = buffer.indexOf('\n')) >= 0) {
        const qsizetype maximumBytes = maximumEngineLineBytes(
            QByteArrayView(buffer.constData(), newlineIndex), stderrStream);
        if (newlineIndex > maximumBytes) {
            buffer.remove(0, newlineIndex + 1);
            const QString marker = reportOversizedLine(maximumBytes);
            if (!stderrStream) {
                buffer.clear();
                failTransport(marker);
                return;
            }
            continue;
        }
        QByteArray rawLine = buffer.left(newlineIndex);
        buffer.remove(0, newlineIndex + 1);
        if (rawLine.endsWith('\r'))
            rawLine.chop(1);
        const QString line = QString::fromUtf8(rawLine);
        if (line.trimmed().isEmpty())
            continue;
        if (stderrStream)
            handleStderrLine(line);
        else
            handleStdoutLine(line);
    }

    const qsizetype maximumBytes = maximumEngineLineBytes(
        QByteArrayView(buffer.constData(), buffer.size()), stderrStream);
    if (buffer.size() > maximumBytes) {
        buffer.clear();
        const QString marker = reportOversizedLine(maximumBytes);
        if (!stderrStream) {
            failTransport(marker);
            return;
        }
        discardingOversizedLine = true;
    }
}

void EngineController::handleStdoutLine(const QString &line)
{
    const QString trimmedLine = line.trimmed();
    if (!communicationInfoLineFiltered(QStringView(trimmedLine)))
        emit engineOutput(line);

    if (trimmedLine.startsWith(QStringLiteral("info "))) {
        if (m_ready && m_protocolState.acceptsCandidateInfo())
            parseInfoLine(trimmedLine);
        return;
    }

    const EngineProtocolState::Response response = EngineProtocolState::parseResponse(line);
    const bool ignoredError = response.type == EngineProtocolState::ResponseType::Error
                           && m_ignoreGtpErrors;
    if (response.type == EngineProtocolState::ResponseType::Error)
        emit gtpErrorResponse(response.rawLine);
    if (!ignoredError)
        setStatusText(line);

    const EngineProtocolState::Outcome outcome =
        m_protocolState.consumeLine(line, m_ignoreGtpErrors);
    if (!outcome.handled) {
        if (response.type == EngineProtocolState::ResponseType::Error
            && m_activeAnalysisRequestId > 0
            && !m_ignoreGtpErrors
            && m_protocolState.acceptsCandidateInfo()) {
            const int analysisRequestId = m_activeAnalysisRequestId;
            m_activeAnalysisRequestId = 0;
            m_protocolState.stopAcceptingCandidateInfo();
            emit analysisCommandFailed(analysisRequestId, response.rawLine);
        }
        return;
    }

    if (m_responsesPending > 0)
        --m_responsesPending;
    const bool abortPendingCommands =
        (outcome.event == EngineProtocolState::Event::AnalysisSyncCompleted && !outcome.success)
        || outcome.event == EngineProtocolState::Event::MovePreludeFailed;
    handleProtocolOutcome(outcome);
    if (!abortPendingCommands)
        sendPendingCommands();
}

void EngineController::handleStderrLine(const QString &line)
{
    emit engineErrorOutput(line);
    setStatusText(line);
}

void EngineController::handleProtocolOutcome(const EngineProtocolState::Outcome &outcome)
{
    switch (outcome.event) {
    case EngineProtocolState::Event::None:
        return;
    case EngineProtocolState::Event::HandshakeCompleted:
        if (outcome.success) {
            setReady(true);
            return;
        }
        {
            QString message = QStringLiteral("Engine handshake failed");
            const QString detail = outcome.payload.isEmpty() ? outcome.rawLine : outcome.payload;
            if (!detail.isEmpty())
                message += QStringLiteral(": ") + detail;
            failActiveMoveRequest(message);
            m_pendingCommands.clear();
            m_protocolState.resetTransaction();
            m_activeSyncRequestId = 0;
            setReady(false);
            setFailed(true, message, QStringLiteral("protocol"));
            setLastError(message);
            setStatusText(message);
        }
        return;
    case EngineProtocolState::Event::AnalysisSyncCompleted:
        if (outcome.success) {
            emit engineSynchronizationCompleted(m_activeSyncRequestId);
            m_activeSyncRequestId = 0;
        } else {
            m_activeAnalysisRequestId = 0;
            m_pendingCommands.clear();
            QString message = QStringLiteral("Engine synchronization failed");
            if (!outcome.rawLine.isEmpty())
                message += QStringLiteral(": ") + outcome.rawLine;
            setFailed(true, message, QStringLiteral("protocol"));
            setLastError(message);
            setStatusText(message);
            m_activeSyncRequestId = 0;
        }
        return;
    case EngineProtocolState::Event::MovePreludeCompleted:
        emit engineSynchronizationCompleted(m_activeSyncRequestId);
        m_activeSyncRequestId = 0;
        return;
    case EngineProtocolState::Event::MovePreludeFailed:
        m_pendingCommands.clear();
        emit moveGenerated(outcome.requestId,
                           QString(),
                           false,
                           outcome.rawLine);
        {
            QString message = QStringLiteral("Engine move synchronization failed");
            if (!outcome.rawLine.isEmpty())
                message += QStringLiteral(": ") + outcome.rawLine;
            setFailed(true, message, QStringLiteral("protocol"));
            setLastError(message);
            setStatusText(message);
        }
        m_activeSyncRequestId = 0;
        return;
    case EngineProtocolState::Event::MoveCompleted:
        emit moveGenerated(outcome.requestId,
                           outcome.payload,
                           outcome.success,
                           outcome.rawLine);
        return;
    }
}

void EngineController::failActiveMoveRequest(const QString &message)
{
    handleProtocolOutcome(m_protocolState.cancelMove(message));
}

void EngineController::failTransport(const QString &message)
{
    if (m_shutdownRequested || m_stopping || !m_transportFailureMessage.isEmpty())
        return;

    m_transportFailureMessage = message;
    failActiveMoveRequest(message);
    resetProtocolState();
    setReady(false);
    setFailed(true, message, QStringLiteral("protocol"));
    setLastError(message);
    setStatusText(message);
    m_stopping = true;
    m_restartPending = false;
    if (m_process.state() != QProcess::NotRunning)
        m_process.kill();
}

void EngineController::resetProtocolState(bool clearPendingCommands)
{
    if (clearPendingCommands)
        m_pendingCommands.clear();
    m_responsesPending = 0;
    m_activeSyncRequestId = 0;
    m_activeAnalysisRequestId = 0;
    m_protocolState.reset();
}

void EngineController::parseInfoLine(const QString &line)
{
    const EngineAnalysis::Batch batch = EngineAnalysis::parseInfoLine(QStringView(line));
    if (batch.candidates.isEmpty())
        return;

    m_candidates = batch.candidates;
    m_ownership = batch.ownership;
    ++m_candidateRevision;
    emit candidatesChanged();
}

void EngineController::setRunning(bool running)
{
    if (m_running == running)
        return;
    m_running = running;
    emit runningChanged();
}

void EngineController::setReady(bool ready)
{
    if (m_ready == ready)
        return;
    m_ready = ready;
    emit readyChanged();
}

void EngineController::setFailed(bool failed, const QString &message, const QString &kind)
{
    const bool failedStateChanged = m_failed != failed;
    const QString nextKind = failed ? kind : QString();
    const bool kindChanged = m_failureKind != nextKind;
    const bool messageChanged = m_failureMessage != message;
    m_failed = failed;
    m_failureKind = nextKind;
    m_failureMessage = message;

    if (kindChanged)
        emit failureKindChanged();
    if (messageChanged)
        emit failureMessageChanged();
    if (failedStateChanged)
        emit failedChanged();
}

void EngineController::setStatusText(const QString &text)
{
    if (m_statusText == text)
        return;
    m_statusText = text;
    emit statusTextChanged();
}

void EngineController::setLastError(const QString &text)
{
    if (m_lastError == text)
        return;
    m_lastError = text;
    emit lastErrorChanged();
}
