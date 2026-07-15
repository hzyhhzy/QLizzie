#include "enginecontroller.h"

#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QStringView>
#include <QTimer>
#include <QVariantMap>
#include <QVector>

#include <algorithm>

#ifdef Q_OS_WIN
#include <qt_windows.h>
#endif

namespace {
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
#ifdef Q_OS_WIN
                closeProcessJobObject();
#endif
                m_stopping = false;
                m_restartPending = false;
                setRunning(false);
                setReady(false);

                if (restartPending) {
                    m_protocolState.resetTransport();
                    setStatusText(QStringLiteral("Engine restarting"));
                    startProcess();
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

QVariantList EngineController::candidates() const
{
    return m_candidates;
}

int EngineController::candidateRevision() const
{
    return m_candidateRevision;
}

void EngineController::ensureStarted()
{
    if (m_process.state() != QProcess::NotRunning)
        return;
    startProcess();
}

void EngineController::restart()
{
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

void EngineController::requestAnalysis(const QStringList &syncCommands, const QString &analyzeCommand)
{
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

void EngineController::requestMove(const QStringList &syncCommands,
                                   const QString &timeSettingsCommand,
                                   const QString &genmoveCommand,
                                   int requestId)
{
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
        m_protocolState.resetTransaction();
    } else {
        const int preludeResponseCount = m_pendingCommands.size() - 1;
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

void EngineController::clearCandidates()
{
    m_protocolState.stopAcceptingCandidateInfo();
    if (m_candidates.isEmpty())
        return;

    m_candidates.clear();
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
    m_process.setWorkingDirectory(portableRootPath());
    m_process.start(programPath, parts.mid(1));
}

void EngineController::sendPendingCommands()
{
    if (m_process.state() != QProcess::Running || !m_ready || m_responsesPending > 0)
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
    qsizetype newlineIndex = -1;
    while ((newlineIndex = buffer.indexOf('\n')) >= 0) {
        QByteArray rawLine = buffer.left(newlineIndex);
        buffer.remove(0, newlineIndex + 1);
        if (rawLine.endsWith('\r'))
            rawLine.chop(1);
        const QString line = QString::fromUtf8(rawLine).trimmed();
        if (line.isEmpty())
            continue;
        if (stderrStream)
            handleStderrLine(line);
        else
            handleStdoutLine(line);
    }
}

void EngineController::handleStdoutLine(const QString &line)
{
    emit engineOutput(line);

    if (line.startsWith(QStringLiteral("info "))) {
        if (m_ready && m_protocolState.acceptsCandidateInfo())
            parseInfoLine(line);
        return;
    }

    setStatusText(line);
    const EngineProtocolState::Outcome outcome = m_protocolState.consumeLine(line);
    if (!outcome.handled)
        return;

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
            setReady(false);
            setFailed(true, message, QStringLiteral("protocol"));
            setLastError(message);
            setStatusText(message);
        }
        return;
    case EngineProtocolState::Event::AnalysisSyncCompleted:
        if (!outcome.success) {
            m_pendingCommands.clear();
            QString message = QStringLiteral("Engine synchronization failed");
            if (!outcome.rawLine.isEmpty())
                message += QStringLiteral(": ") + outcome.rawLine;
            setFailed(true, message, QStringLiteral("protocol"));
            setLastError(message);
            setStatusText(message);
        }
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

void EngineController::resetProtocolState(bool clearPendingCommands)
{
    if (clearPendingCommands)
        m_pendingCommands.clear();
    m_responsesPending = 0;
    m_protocolState.reset();
}

void EngineController::parseInfoLine(const QString &line)
{
    QStringView payload(line);
    if (payload.startsWith(QLatin1StringView("info ")))
        payload = payload.sliced(5);
    payload = trimmedView(payload);

    QVector<ParsedCandidateInfo> parsedCandidates;
    int segmentIndex = 0;
    qsizetype segmentStart = 0;

    while (segmentStart < payload.size()) {
        const qsizetype separator = nextInfoSeparator(payload, segmentStart);
        const QStringView segment = trimmedView(separator >= 0
                                                ? payload.sliced(segmentStart, separator - segmentStart)
                                                : payload.sliced(segmentStart));
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
                QVariantList pv;
                while (tokenPosition < segment.size()) {
                    const QString pvMove = nextMoveToken(segment, tokenPosition);
                    if (pvMove.isEmpty())
                        break;
                    if (pvMove == QLatin1StringView("pvVisits")) {
                        QVariantList pvVisits;
                        while (tokenPosition < segment.size()) {
                            const QStringView pvVisitToken = nextToken(segment, tokenPosition);
                            if (pvVisitToken.isEmpty())
                                break;
                            bool visitOk = false;
                            const int visitValue = pvVisitToken.toInt(&visitOk);
                            if (visitOk)
                                pvVisits.append(visitValue);
                        }
                        if (!pvVisits.isEmpty())
                            item.insert(QStringLiteral("pvVisits"), pvVisits);
                        break;
                    }
                    pv.append(pvMove);
                }
                if (!pv.isEmpty())
                    item.insert(QStringLiteral("pv"), pv);
                break;
            }

            if (key == QLatin1StringView("pvVisits")) {
                QVariantList pvVisits;
                while (tokenPosition < segment.size()) {
                    const QStringView pvVisitToken = nextToken(segment, tokenPosition);
                    if (pvVisitToken.isEmpty())
                        break;
                    bool visitOk = false;
                    const int visitValue = pvVisitToken.toInt(&visitOk);
                    if (visitOk)
                        pvVisits.append(visitValue);
                }
                if (!pvVisits.isEmpty())
                    item.insert(QStringLiteral("pvVisits"), pvVisits);
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
            } else if (key == QLatin1StringView("winrate")) {
                const double winrate = value.toDouble(&ok);
                if (ok)
                    item.insert(QStringLiteral("winrate"), winrate);
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
        while (segmentStart < payload.size() && payload.at(segmentStart).isSpace())
            ++segmentStart;
    }

    if (parsedCandidates.isEmpty())
        return;

    std::sort(parsedCandidates.begin(), parsedCandidates.end(), [](const ParsedCandidateInfo &a, const ParsedCandidateInfo &b) {
        return a.order < b.order;
    });

    QVariantList candidateItems;
    candidateItems.reserve(parsedCandidates.size());
    for (const ParsedCandidateInfo &candidate : parsedCandidates)
        candidateItems.append(candidate.item);

    m_candidates = candidateItems;
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
