#include "enginecontroller.h"
#include "engineprotocol.h"
#include "fileio.h"

#include <QDir>
#include <QFile>
#include <QSignalSpy>
#include <QTest>
#include <QUrl>

class CoreTests : public QObject
{
    Q_OBJECT

private slots:
    void parsesGtpResponses();
    void rejectsFailedHandshake();
    void keepsUnrelatedResponsesOutOfAnalysisTransaction();
    void rejectsAnalysisWhenAnySyncCommandFails();
    void ignoresConfiguredProtocolErrors();
    void propagatesMovePreludeFailure();
    void completesAndCancelsMoveRequests();
    void rejectsOversizedStdoutAndRecoversFromOversizedStderr();
    void shutdownIsTerminal();
    void writesTextThroughCommittedSaveFile();
};

void CoreTests::parsesGtpResponses()
{
    const EngineProtocolState::Response success = EngineProtocolState::parseResponse(QStringLiteral(" = D4 "));
    QCOMPARE(success.type, EngineProtocolState::ResponseType::Success);
    QCOMPARE(success.payload, QStringLiteral("D4"));

    const EngineProtocolState::Response error = EngineProtocolState::parseResponse(QStringLiteral("? illegal move"));
    QCOMPARE(error.type, EngineProtocolState::ResponseType::Error);
    QCOMPARE(error.payload, QStringLiteral("illegal move"));

    QVERIFY(!EngineProtocolState::parseResponse(QStringLiteral("info move D4")).isResponse());
}

void CoreTests::rejectsFailedHandshake()
{
    EngineProtocolState state;
    state.beginMove(0, 17);
    state.beginHandshake();

    const EngineProtocolState::Outcome outcome = state.consumeLine(QStringLiteral("? unknown command"));
    QCOMPARE(outcome.event, EngineProtocolState::Event::HandshakeCompleted);
    QVERIFY(!outcome.success);
    QVERIFY(!state.handshakePending());
    QVERIFY(!state.acceptsCandidateInfo());

    const EngineProtocolState::Outcome cancelled = state.cancelMove(QStringLiteral("handshake failed"));
    QCOMPARE(cancelled.event, EngineProtocolState::Event::MoveCompleted);
    QCOMPARE(cancelled.requestId, 17);
    QVERIFY(!cancelled.success);
}

void CoreTests::keepsUnrelatedResponsesOutOfAnalysisTransaction()
{
    EngineProtocolState state;
    state.beginAnalysis(1);
    state.expectResponse(EngineProtocolState::ResponseRole::Ignored);
    state.expectResponse(EngineProtocolState::ResponseRole::AnalysisSync);

    const EngineProtocolState::Outcome unrelated = state.consumeLine(QStringLiteral("= initialization"));
    QCOMPARE(unrelated.event, EngineProtocolState::Event::None);
    QVERIFY(unrelated.handled);
    QVERIFY(!state.acceptsCandidateInfo());

    const EngineProtocolState::Outcome synchronized = state.consumeLine(QStringLiteral("="));
    QCOMPARE(synchronized.event, EngineProtocolState::Event::AnalysisSyncCompleted);
    QVERIFY(synchronized.success);
    QVERIFY(state.acceptsCandidateInfo());
}

void CoreTests::rejectsAnalysisWhenAnySyncCommandFails()
{
    EngineProtocolState state;
    state.beginAnalysis(2);
    state.expectResponse(EngineProtocolState::ResponseRole::AnalysisSync);
    state.expectResponse(EngineProtocolState::ResponseRole::AnalysisSync);

    QVERIFY(state.consumeLine(QStringLiteral("= stopped")).handled);
    const EngineProtocolState::Outcome outcome = state.consumeLine(QStringLiteral("? unsupported rules"));

    QCOMPARE(outcome.event, EngineProtocolState::Event::AnalysisSyncCompleted);
    QVERIFY(!outcome.success);
    QCOMPARE(outcome.rawLine, QStringLiteral("? unsupported rules"));
    QVERIFY(!state.acceptsCandidateInfo());
}

void CoreTests::ignoresConfiguredProtocolErrors()
{
    EngineProtocolState handshakeState;
    handshakeState.beginHandshake();
    const EngineProtocolState::Outcome handshake =
        handshakeState.consumeLine(QStringLiteral(" ? unknown command "), true);
    QCOMPARE(handshake.event, EngineProtocolState::Event::HandshakeCompleted);
    QVERIFY(handshake.success);
    QCOMPARE(handshake.rawLine, QStringLiteral(" ? unknown command "));

    EngineProtocolState analysisState;
    analysisState.beginAnalysis(2);
    analysisState.expectResponse(EngineProtocolState::ResponseRole::AnalysisSync);
    const EngineProtocolState::Outcome ignoredSyncError =
        analysisState.consumeLine(QStringLiteral("? cannot undo"), true);
    QCOMPARE(ignoredSyncError.event, EngineProtocolState::Event::None);
    QVERIFY(ignoredSyncError.handled);
    QVERIFY(ignoredSyncError.toleratedSyncError);
    QVERIFY(!analysisState.acceptsCandidateInfo());

    analysisState.expectResponse(EngineProtocolState::ResponseRole::AnalysisSync);
    const EngineProtocolState::Outcome analysisCompleted =
        analysisState.consumeLine(QStringLiteral("="), true);
    QCOMPARE(analysisCompleted.event, EngineProtocolState::Event::AnalysisSyncCompleted);
    QVERIFY(analysisCompleted.success);
    QVERIFY(analysisCompleted.toleratedSyncError);
    QVERIFY(analysisState.acceptsCandidateInfo());

    EngineProtocolState moveState;
    moveState.beginMove(1, 74);
    moveState.expectResponse(EngineProtocolState::ResponseRole::MovePrelude);
    const EngineProtocolState::Outcome ignoredPreludeError =
        moveState.consumeLine(QStringLiteral("? unsupported time_settings"), true);
    QCOMPARE(ignoredPreludeError.event, EngineProtocolState::Event::MovePreludeCompleted);
    QVERIFY(ignoredPreludeError.handled);
    QVERIFY(ignoredPreludeError.success);
    QVERIFY(ignoredPreludeError.toleratedSyncError);
    QVERIFY(moveState.hasActiveMove());

    moveState.expectResponse(EngineProtocolState::ResponseRole::MoveGenerate);
    const EngineProtocolState::Outcome failedGenmove =
        moveState.consumeLine(QStringLiteral("? cannot generate move"), true);
    QCOMPARE(failedGenmove.event, EngineProtocolState::Event::MoveCompleted);
    QCOMPARE(failedGenmove.requestId, 74);
    QVERIFY(!failedGenmove.success);
    QCOMPARE(failedGenmove.rawLine, QStringLiteral("? cannot generate move"));
    QVERIFY(!moveState.hasActiveMove());
}

void CoreTests::propagatesMovePreludeFailure()
{
    EngineProtocolState state;
    state.beginMove(2, 73);
    state.expectResponse(EngineProtocolState::ResponseRole::MovePrelude);
    const EngineProtocolState::Outcome firstPrelude = state.consumeLine(QStringLiteral("="));
    QCOMPARE(firstPrelude.event, EngineProtocolState::Event::None);
    QVERIFY(firstPrelude.handled);

    state.expectResponse(EngineProtocolState::ResponseRole::MovePrelude);
    const EngineProtocolState::Outcome outcome = state.consumeLine(QStringLiteral("? board mismatch"));

    QCOMPARE(outcome.event, EngineProtocolState::Event::MovePreludeFailed);
    QCOMPARE(outcome.requestId, 73);
    QVERIFY(!outcome.success);
    QCOMPARE(outcome.rawLine, QStringLiteral("? board mismatch"));
    QVERIFY(!state.hasActiveMove());
}

void CoreTests::completesAndCancelsMoveRequests()
{
    EngineProtocolState state;
    state.beginMove(1, 91);
    state.expectResponse(EngineProtocolState::ResponseRole::MovePrelude);
    const EngineProtocolState::Outcome prelude = state.consumeLine(QStringLiteral("="));
    QCOMPARE(prelude.event, EngineProtocolState::Event::MovePreludeCompleted);
    QVERIFY(prelude.handled);
    QVERIFY(prelude.success);
    QVERIFY(!prelude.toleratedSyncError);

    state.expectResponse(EngineProtocolState::ResponseRole::MoveGenerate);

    const EngineProtocolState::Outcome completed = state.consumeLine(QStringLiteral("="));
    QCOMPARE(completed.event, EngineProtocolState::Event::MoveCompleted);
    QCOMPARE(completed.requestId, 91);
    QVERIFY(completed.success);
    QCOMPARE(completed.payload, QStringLiteral("pass"));

    state.beginMove(0, 92);
    state.expectResponse(EngineProtocolState::ResponseRole::MoveGenerate);
    const EngineProtocolState::Outcome cancelled = state.cancelMove(QStringLiteral("Engine exited (0)"));
    QCOMPARE(cancelled.event, EngineProtocolState::Event::MoveCompleted);
    QCOMPARE(cancelled.requestId, 92);
    QVERIFY(!cancelled.success);
    QCOMPARE(cancelled.rawLine, QStringLiteral("Engine exited (0)"));

    state.expectResponse(EngineProtocolState::ResponseRole::Ignored);
    const EngineProtocolState::Outcome cancelledMoveResponse = state.consumeLine(QStringLiteral("= Q16"));
    QCOMPARE(cancelledMoveResponse.event, EngineProtocolState::Event::None);
    QVERIFY(cancelledMoveResponse.handled);
    const EngineProtocolState::Outcome stopResponse = state.consumeLine(QStringLiteral("="));
    QCOMPARE(stopResponse.event, EngineProtocolState::Event::None);
    QVERIFY(stopResponse.handled);
}

void CoreTests::rejectsOversizedStdoutAndRecoversFromOversizedStderr()
{
    constexpr qsizetype maximumEngineLineBytes = 262144;

    {
        EngineController controller;
        QSignalSpy moveSpy(&controller, &EngineController::moveGenerated);
        controller.m_protocolState.beginMove(0, 93);
        controller.m_protocolState.expectResponse(
            EngineProtocolState::ResponseRole::MoveGenerate);
        controller.m_responsesPending = 1;
        QByteArray oversizedLine(maximumEngineLineBytes + 1, 'x');
        oversizedLine.append('\n');

        controller.consumeLines(oversizedLine, false);

        QVERIFY(controller.failed());
        QCOMPARE(controller.failureKind(), QStringLiteral("protocol"));
        QCOMPARE(controller.m_responsesPending, 0);
        QVERIFY(oversizedLine.isEmpty());
        QCOMPARE(moveSpy.count(), 1);
        QCOMPARE(moveSpy.first().at(0).toInt(), 93);
        QVERIFY(!moveSpy.first().at(2).toBool());
    }

    {
        EngineController controller;
        controller.m_responsesPending = 1;
        QByteArray oversizedPartialLine(maximumEngineLineBytes + 1, 'x');

        controller.consumeLines(oversizedPartialLine, false);

        QVERIFY(controller.failed());
        QCOMPARE(controller.failureKind(), QStringLiteral("protocol"));
        QCOMPARE(controller.m_responsesPending, 0);
        QVERIFY(oversizedPartialLine.isEmpty());
        QVERIFY(!controller.m_discardingOversizedStdoutLine);
    }

    {
        EngineController controller;
        QSignalSpy stderrSpy(&controller, &EngineController::engineErrorOutput);
        QByteArray oversizedPartialLine(maximumEngineLineBytes + 1, 'x');

        controller.consumeLines(oversizedPartialLine, true);
        QVERIFY(!controller.failed());
        QVERIFY(controller.m_discardingOversizedStderrLine);
        QCOMPARE(stderrSpy.count(), 1);

        oversizedPartialLine.append("\nusable stderr line\n");
        controller.consumeLines(oversizedPartialLine, true);

        QVERIFY(!controller.failed());
        QVERIFY(!controller.m_discardingOversizedStderrLine);
        QVERIFY(oversizedPartialLine.isEmpty());
        QCOMPARE(stderrSpy.count(), 2);
        QCOMPARE(stderrSpy.at(1).at(0).toString(),
                 QStringLiteral("usable stderr line"));
    }

    {
        EngineController controller;
        controller.m_stopping = true;
        controller.m_restartPending = true;
        QByteArray staleOversizedLine(maximumEngineLineBytes + 1, 'x');
        staleOversizedLine.append('\n');

        controller.consumeLines(staleOversizedLine, false);

        QVERIFY(!controller.failed());
        QVERIFY(controller.m_stopping);
        QVERIFY(controller.m_restartPending);
        QVERIFY(controller.m_transportFailureMessage.isEmpty());
    }
}

void CoreTests::shutdownIsTerminal()
{
    EngineController controller;
    controller.shutdown();
    controller.setCommand(QStringLiteral("definitely-missing-engine.exe"));

    controller.ensureStarted();
    controller.restart();
    controller.sendCommand(QStringLiteral("name"));
    controller.requestAnalysis({}, QStringLiteral("kata-analyze"), 1);
    controller.requestMove({}, QString(), QStringLiteral("genmove B"), 2, 3);

    QVERIFY(!controller.running());
    QVERIFY(!controller.ready());
    QVERIFY(!controller.failed());
}

void CoreTests::writesTextThroughCommittedSaveFile()
{
    const QString path = QDir::current().filePath(QStringLiteral("qlizzie-fileio-test.sgf"));
    QFile::remove(path);
    FileIo fileIo;
    QVERIFY2(fileIo.writeTextFile(QUrl::fromLocalFile(path), QStringLiteral("(;GM[1]C[initial])")),
             qPrintable(fileIo.lastError()));
    QCOMPARE(fileIo.lastError(), QString());

    QFile file(path);
    QVERIFY(file.open(QIODevice::ReadOnly));
    QCOMPARE(QString::fromUtf8(file.readAll()), QStringLiteral("(;GM[1]C[initial])"));
    file.close();

    QVERIFY2(fileIo.writeTextFile(QUrl::fromLocalFile(path), QStringLiteral("(;GM[1]C[updated])")),
             qPrintable(fileIo.lastError()));
    QVERIFY(file.open(QIODevice::ReadOnly));
    QCOMPARE(QString::fromUtf8(file.readAll()), QStringLiteral("(;GM[1]C[updated])"));
    file.close();
    QVERIFY(QFile::remove(path));
}

QTEST_APPLESS_MAIN(CoreTests)

#include "coretests.moc"
