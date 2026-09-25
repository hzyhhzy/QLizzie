#include "enginecontroller.h"
#include "engineanalysis.h"
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
    void keepsSynchronizationFromAcceptingCandidates();
    void rejectsAnalysisWhenAnySyncCommandFails();
    void ignoresConfiguredProtocolErrors();
    void ignoredSyncErrorsOnlyNotify();
    void propagatesMovePreludeFailure();
    void completesAndCancelsMoveRequests();
    void rejectsOversizedStdoutAndRecoversFromOversizedStderr();
    void preservesCandidateSymmetryMetadata();
    void preservesCandidateTableMetrics();
    void parsesOwnershipWithoutPollutingCandidates();
    void clearsOwnershipWithNewCandidateBatch();
    void clearsOwnershipWithoutCandidates();
    void rejectsMalformedOwnership();
    void parsesAnalysisMetricsWithoutController();
    void preservesValidSegmentsInMalformedAnalysis();
    void preservesParenthesizedMovesAndPvVisits();
    void parsesEmptyAndInvalidOwnershipWithoutDiscardingCandidates();
    void ignoresBatchesWithoutCandidateMoves();
    void candidateSnapshotSurvivesNewBatches();
    void buffersPartialAnalysisLinesUntilComplete();
    void ignoresUnhandledAnalysisErrorsWhenConfigured();
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

void CoreTests::preservesCandidateSymmetryMetadata()
{
    EngineController controller;
    controller.parseInfoLine(QStringLiteral(
        "info move D4 visits 120 order 0 pv D4 "
        "info move Q16 visits 80 isSymmetryOf D4 order 1 pv Q16"));

    QCOMPARE(controller.m_candidates.size(), 2);
    const QVariantMap first = controller.m_candidates.at(0).toMap();
    const QVariantMap second = controller.m_candidates.at(1).toMap();
    QCOMPARE(first.value(QStringLiteral("move")).toString(), QStringLiteral("D4"));
    QVERIFY(!first.contains(QStringLiteral("isSymmetryOf")));
    QCOMPARE(second.value(QStringLiteral("move")).toString(), QStringLiteral("Q16"));
    QCOMPARE(second.value(QStringLiteral("isSymmetryOf")).toString(), QStringLiteral("D4"));
}

void CoreTests::candidateSnapshotSurvivesNewBatches()
{
    EngineController controller;
    controller.parseInfoLine(QStringLiteral("info move D4 visits 120 order 0 pv D4"));
    const QVariantList snapshot = controller.candidateSnapshot();
    controller.parseInfoLine(QStringLiteral("info move Q16 visits 240 order 0 pv Q16"));
    controller.clearCandidates();
    QCOMPARE(snapshot.size(), 1);
    QCOMPARE(snapshot.first().toMap().value(QStringLiteral("move")).toString(), QStringLiteral("D4"));
    QCOMPARE(snapshot.first().toMap().value(QStringLiteral("visits")).toInt(), 120);
    QVERIFY(controller.candidateSnapshot().isEmpty());
}

void CoreTests::preservesCandidateTableMetrics()
{
    EngineController controller;
    controller.parseInfoLine(QStringLiteral(
        "info move D4 visits 120 winrate 0.56 lcb 0.53 prior 0.125 "
        "scoreMean 1.75 scoreStdev 0.42 order 0 pv D4"));

    QCOMPARE(controller.m_candidates.size(), 1);
    const QVariantMap candidate = controller.m_candidates.first().toMap();
    QCOMPARE(candidate.value(QStringLiteral("lcb")).toDouble(), 0.53);
    QCOMPARE(candidate.value(QStringLiteral("prior")).toDouble(), 0.125);
    QCOMPARE(candidate.value(QStringLiteral("scoreMean")).toDouble(), 1.75);
    QCOMPARE(candidate.value(QStringLiteral("scoreStdev")).toDouble(), 0.42);
}

void CoreTests::parsesOwnershipWithoutPollutingCandidates()
{
    EngineController controller;
    QSignalSpy changedSpy(&controller, &EngineController::candidatesChanged);
    controller.parseInfoLine(QStringLiteral(
        "info move D4 visits 120 order 0 pv D4 C3 "
        "info move Q16 visits 80 order 1 pv Q16 R17 "
        "rootInfo visits 200 winrate 0.51 ownership 1 -0.5 0 0.25"));

    QCOMPARE(changedSpy.count(), 1);
    QCOMPARE(controller.candidates().size(), 2);
    QCOMPARE(controller.ownership().size(), 4);
    QCOMPARE(controller.ownership().at(0).toDouble(), 1.0);
    QCOMPARE(controller.ownership().at(1).toDouble(), -0.5);
    QCOMPARE(controller.ownership().at(2).toDouble(), 0.0);
    QCOMPARE(controller.ownership().at(3).toDouble(), 0.25);

    const QVariantMap first = controller.candidates().at(0).toMap();
    const QVariantMap second = controller.candidates().at(1).toMap();
    QCOMPARE(first.value(QStringLiteral("pvText")).toString(),
             QStringLiteral("D4 C3"));
    QCOMPARE(second.value(QStringLiteral("pvText")).toString(),
             QStringLiteral("Q16 R17"));
    QVERIFY(!first.contains(QStringLiteral("pv")));
    QVERIFY(!second.contains(QStringLiteral("pv")));
}

void CoreTests::clearsOwnershipWithNewCandidateBatch()
{
    EngineController controller;
    QSignalSpy changedSpy(&controller, &EngineController::candidatesChanged);
    controller.parseInfoLine(
        QStringLiteral("info move D4 visits 1 order 0 pv D4 ownership 0.75 -0.25"));
    QVERIFY(!controller.ownership().isEmpty());

    controller.parseInfoLine(
        QStringLiteral("info move Q16 visits 2 order 0 pv Q16 R17"));

    QCOMPARE(changedSpy.count(), 2);
    QVERIFY(controller.ownership().isEmpty());
    QCOMPARE(controller.candidates().size(), 1);
    QCOMPARE(controller.candidates().first().toMap().value(QStringLiteral("move")).toString(),
             QStringLiteral("Q16"));
}

void CoreTests::clearsOwnershipWithoutCandidates()
{
    EngineController controller;
    QSignalSpy changedSpy(&controller, &EngineController::candidatesChanged);
    controller.m_ownership = QVariantList({ 0.5, -0.5 });
    QVERIFY(controller.m_candidates.isEmpty());

    controller.clearCandidates();

    QCOMPARE(changedSpy.count(), 1);
    QVERIFY(controller.m_candidates.isEmpty());
    QVERIFY(controller.m_ownership.isEmpty());
    QCOMPARE(controller.m_candidateRevision, 1);
}

void CoreTests::rejectsMalformedOwnership()
{
    EngineController controller;
    controller.parseInfoLine(
        QStringLiteral("info move D4 visits 1 order 0 pv D4 ownership 0.5 -0.5"));
    QVERIFY(!controller.ownership().isEmpty());

    controller.parseInfoLine(
        QStringLiteral("info move Q16 visits 2 order 0 pv Q16 ownership 0.25 NaN -0.25"));

    QVERIFY(controller.ownership().isEmpty());
    QCOMPARE(controller.candidates().size(), 1);
    const QVariantMap candidate = controller.candidates().first().toMap();
    QCOMPARE(candidate.value(QStringLiteral("move")).toString(), QStringLiteral("Q16"));
    QCOMPARE(candidate.value(QStringLiteral("pvText")).toString(),
             QStringLiteral("Q16"));
}

void CoreTests::parsesAnalysisMetricsWithoutController()
{
    const EngineAnalysis::Batch batch = EngineAnalysis::parseInfoLine(QStringLiteral(
        "info move Q16 visits 80 isSymmetryOf D4 order 1 pv Q16 "
        "info move D4 visits 120 winrate 0.56 lcb 0.53 policy 0.125 "
        "scoreLead 1.75 scoreStdev 0.42 order 0 pv D4 C3 pvVisits 120 75 "
        "rootInfo visits 200 ownership 0.5 -0.5 ownershipStdev 0.1 0.2"));

    QCOMPARE(batch.candidates.size(), 2);
    const QVariantMap first = batch.candidates.at(0).toMap();
    const QVariantMap second = batch.candidates.at(1).toMap();
    QCOMPARE(first.value(QStringLiteral("move")).toString(), QStringLiteral("D4"));
    QCOMPARE(first.value(QStringLiteral("visits")).toInt(), 120);
    QCOMPARE(first.value(QStringLiteral("winrate")).toDouble(), 0.56);
    QCOMPARE(first.value(QStringLiteral("lcb")).toDouble(), 0.53);
    QCOMPARE(first.value(QStringLiteral("prior")).toDouble(), 0.125);
    QCOMPARE(first.value(QStringLiteral("scoreMean")).toDouble(), 1.75);
    QCOMPARE(first.value(QStringLiteral("scoreStdev")).toDouble(), 0.42);
    QCOMPARE(first.value(QStringLiteral("pvText")).toString(), QStringLiteral("D4 C3"));
    QCOMPARE(first.value(QStringLiteral("pvVisitsText")).toString(), QStringLiteral("120 75"));
    QCOMPARE(second.value(QStringLiteral("isSymmetryOf")).toString(), QStringLiteral("D4"));
    QCOMPARE(batch.ownership, QVariantList({ QVariant(0.5), QVariant(-0.5) }));
}

void CoreTests::preservesValidSegmentsInMalformedAnalysis()
{
    const EngineAnalysis::Batch batch = EngineAnalysis::parseInfoLine(QStringLiteral(
        "info visits 99 order 0 "
        "info move D4 visits invalid winrate bad lcb bad prior bad "
        "scoreMean bad scoreStdev bad order bad unknown ignored "
        "info move C3 visits 5 order -1 pv C3 "
        "info move"));

    QCOMPARE(batch.candidates.size(), 2);
    const QVariantMap first = batch.candidates.at(0).toMap();
    const QVariantMap second = batch.candidates.at(1).toMap();
    QCOMPARE(first.value(QStringLiteral("move")).toString(), QStringLiteral("C3"));
    QCOMPARE(first.value(QStringLiteral("order")).toInt(), -1);
    QCOMPARE(second.value(QStringLiteral("move")).toString(), QStringLiteral("D4"));
    QCOMPARE(second.value(QStringLiteral("order")).toInt(), 1);
    QCOMPARE(second.size(), 2);
}

void CoreTests::preservesParenthesizedMovesAndPvVisits()
{
    const EngineAnalysis::Batch batch = EngineAnalysis::parseInfoLine(QStringLiteral(
        "info move (2, 3) visits 7 order 1 pv (2, 3) D4 pvVisits 7 3 "
        "info move pass order 0 pvVisits 4 2 ownership 0.25"));

    QCOMPARE(batch.candidates.size(), 2);
    const QVariantMap first = batch.candidates.at(0).toMap();
    const QVariantMap second = batch.candidates.at(1).toMap();
    QCOMPARE(first.value(QStringLiteral("move")).toString(), QStringLiteral("pass"));
    QVERIFY(!first.contains(QStringLiteral("pvText")));
    QCOMPARE(first.value(QStringLiteral("pvVisitsText")).toString(), QStringLiteral("4 2"));
    QCOMPARE(second.value(QStringLiteral("move")).toString(), QStringLiteral("(2, 3)"));
    QCOMPARE(second.value(QStringLiteral("pvText")).toString(), QStringLiteral("(2, 3) D4"));
    QCOMPARE(second.value(QStringLiteral("pvVisitsText")).toString(), QStringLiteral("7 3"));
    QCOMPARE(batch.ownership, QVariantList({ QVariant(0.25) }));
}

void CoreTests::parsesEmptyAndInvalidOwnershipWithoutDiscardingCandidates()
{
    const QStringList trailers = {
        QString(), QStringLiteral("ownership"),
        QStringLiteral("ownership 0.5 invalid -0.5"),
        QStringLiteral("ownership 0.5 NaN -0.5"),
        QStringLiteral("ownership 0.5 inf -0.5"),
        QStringLiteral("ownership ownershipStdev 0.1")
    };
    for (const QString &trailer : trailers) {
        const EngineAnalysis::Batch batch = EngineAnalysis::parseInfoLine(
            QStringLiteral("info move D4 visits 1 pv D4 ") + trailer);
        QCOMPARE(batch.candidates.size(), 1);
        QCOMPARE(batch.candidates.first().toMap().value(QStringLiteral("pvText")).toString(),
                 QStringLiteral("D4"));
        QVERIFY2(batch.ownership.isEmpty(), qPrintable(trailer));
    }
    // Validation is limited to finite numeric tokens, as in the engine stream.
    // Perspective conversion and board-size checks belong to the UI consumer.
    const EngineAnalysis::Batch unbounded = EngineAnalysis::parseInfoLine(
        QStringLiteral("info move D4 ownership 2 -2"));
    QCOMPARE(unbounded.ownership, QVariantList({ QVariant(2.0), QVariant(-2.0) }));
}

void CoreTests::ignoresBatchesWithoutCandidateMoves()
{
    EngineController controller;
    controller.parseInfoLine(QStringLiteral("info move D4 visits 1 ownership 0.5"));
    const QVariantList before = controller.candidates();
    const int revision = controller.candidateRevision();
    QSignalSpy changedSpy(&controller, &EngineController::candidatesChanged);

    const QStringList incomplete = {
        QString(), QStringLiteral("info move"),
        QStringLiteral("info visits 99"),
        QStringLiteral("rootInfo visits 2 ownership 0.25")
    };
    for (const QString &line : incomplete) {
        QVERIFY(EngineAnalysis::parseInfoLine(line).candidates.isEmpty());
        controller.parseInfoLine(line);
        QCOMPARE(controller.candidates(), before);
        QCOMPARE(controller.ownership(), QVariantList({ QVariant(0.5) }));
        QCOMPARE(controller.candidateRevision(), revision);
    }
    QCOMPARE(changedSpy.count(), 0);
}

void CoreTests::buffersPartialAnalysisLinesUntilComplete()
{
    EngineController controller;
    controller.m_ready = true;
    controller.m_protocolState.beginAnalysis(0);
    QSignalSpy changedSpy(&controller, &EngineController::candidatesChanged);
    QByteArray pending("info move D4 visits 1 pv D4 ownership 0.");
    controller.consumeLines(pending, false);
    QVERIFY(controller.candidates().isEmpty());
    QCOMPARE(changedSpy.count(), 0);
    QVERIFY(!pending.isEmpty());

    pending.append("5 -0.5\n");
    controller.consumeLines(pending, false);
    QCOMPARE(controller.candidates().size(), 1);
    QCOMPARE(controller.ownership(), QVariantList({ QVariant(0.5), QVariant(-0.5) }));
    QCOMPARE(changedSpy.count(), 1);
    QVERIFY(pending.isEmpty());
}

void CoreTests::ignoresUnhandledAnalysisErrorsWhenConfigured()
{
    EngineController controller;
    controller.m_ready = true;
    controller.m_activeAnalysisRequestId = 73;
    controller.m_protocolState.beginAnalysis(0);
    QSignalSpy failedSpy(&controller, &EngineController::analysisCommandFailed);
    QSignalSpy errorSpy(&controller, &EngineController::gtpErrorResponse);

    controller.handleStdoutLine(QStringLiteral("? unknown command"));

    QCOMPARE(errorSpy.count(), 1);
    QCOMPARE(errorSpy.first().at(0).toString(), QStringLiteral("? unknown command"));
    QCOMPARE(failedSpy.count(), 0);
    QCOMPARE(controller.m_activeAnalysisRequestId, 73);
    QVERIFY(controller.m_protocolState.acceptsCandidateInfo());

    controller.setIgnoreGtpErrors(false);
    controller.handleStdoutLine(QStringLiteral("? analysis failed"));

    QCOMPARE(failedSpy.count(), 1);
    QCOMPARE(failedSpy.first().at(0).toInt(), 73);
    QCOMPARE(failedSpy.first().at(1).toString(), QStringLiteral("? analysis failed"));
    QCOMPARE(controller.m_activeAnalysisRequestId, 0);
    QVERIFY(!controller.m_protocolState.acceptsCandidateInfo());
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

void CoreTests::keepsSynchronizationFromAcceptingCandidates()
{
    EngineProtocolState state;
    state.beginSynchronization(2);
    state.expectResponse(EngineProtocolState::ResponseRole::AnalysisSync);
    state.expectResponse(EngineProtocolState::ResponseRole::AnalysisSync);

    const EngineProtocolState::Outcome first = state.consumeLine(QStringLiteral("="));
    QCOMPARE(first.event, EngineProtocolState::Event::None);
    QVERIFY(first.handled);
    QVERIFY(!state.acceptsCandidateInfo());

    const EngineProtocolState::Outcome synchronized =
        state.consumeLine(QStringLiteral("="));
    QCOMPARE(synchronized.event, EngineProtocolState::Event::AnalysisSyncCompleted);
    QVERIFY(synchronized.success);
    QVERIFY(!state.acceptsCandidateInfo());
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
    QVERIFY(!analysisState.acceptsCandidateInfo());

    analysisState.expectResponse(EngineProtocolState::ResponseRole::AnalysisSync);
    const EngineProtocolState::Outcome analysisCompleted =
        analysisState.consumeLine(QStringLiteral("="), true);
    QCOMPARE(analysisCompleted.event, EngineProtocolState::Event::AnalysisSyncCompleted);
    QVERIFY(analysisCompleted.success);
    QVERIFY(analysisState.acceptsCandidateInfo());

    EngineProtocolState moveState;
    moveState.beginMove(1, 74);
    moveState.expectResponse(EngineProtocolState::ResponseRole::MovePrelude);
    const EngineProtocolState::Outcome ignoredPreludeError =
        moveState.consumeLine(QStringLiteral("? unsupported time_settings"), true);
    QCOMPARE(ignoredPreludeError.event, EngineProtocolState::Event::MovePreludeCompleted);
    QVERIFY(ignoredPreludeError.handled);
    QVERIFY(ignoredPreludeError.success);
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

void CoreTests::ignoredSyncErrorsOnlyNotify()
{
    EngineController controller;
    controller.m_ready = true;
    controller.m_activeSyncRequestId = 88;
    controller.m_protocolState.beginAnalysis(1);
    controller.m_protocolState.expectResponse(
        EngineProtocolState::ResponseRole::AnalysisSync);
    controller.m_responsesPending = 1;

    QSignalSpy errorSpy(&controller, &EngineController::gtpErrorResponse);
    QSignalSpy synchronizedSpy(
        &controller, &EngineController::engineSynchronizationCompleted);
    QSignalSpy failedSpy(&controller, &EngineController::failedChanged);

    controller.handleStdoutLine(QStringLiteral("? cannot undo"));

    QCOMPARE(errorSpy.count(), 1);
    QCOMPARE(errorSpy.first().at(0).toString(), QStringLiteral("? cannot undo"));
    QCOMPARE(synchronizedSpy.count(), 1);
    QCOMPARE(synchronizedSpy.first().at(0).toInt(), 88);
    QCOMPARE(failedSpy.count(), 0);
    QVERIFY(!controller.failed());
    QCOMPARE(controller.m_responsesPending, 0);
    QVERIFY(controller.m_protocolState.acceptsCandidateInfo());
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
    constexpr qsizetype maximumAnalysisInfoLineBytes = 4 * 1024 * 1024;

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
        QByteArray largeAnalysisLine("info move A1 ");
        largeAnalysisLine.append(
            QByteArray(maximumEngineLineBytes - largeAnalysisLine.size() + 1, 'x'));
        largeAnalysisLine.append('\n');

        controller.consumeLines(largeAnalysisLine, false);

        QVERIFY(!controller.failed());
        QVERIFY(largeAnalysisLine.isEmpty());
    }

    {
        EngineController controller;
        QByteArray largePartialAnalysisLine("  info\tmove A1 ");
        largePartialAnalysisLine.append(
            QByteArray(maximumEngineLineBytes
                       - largePartialAnalysisLine.size() + 1, 'x'));

        controller.consumeLines(largePartialAnalysisLine, false);

        QVERIFY(!controller.failed());
        QVERIFY(largePartialAnalysisLine.size() > maximumEngineLineBytes);
    }

    {
        EngineController controller;
        QByteArray oversizedAnalysisLine("info move A1 ");
        oversizedAnalysisLine.append(
            QByteArray(maximumAnalysisInfoLineBytes
                       - oversizedAnalysisLine.size() + 1, 'x'));
        oversizedAnalysisLine.append('\n');

        controller.consumeLines(oversizedAnalysisLine, false);

        QVERIFY(controller.failed());
        QCOMPARE(controller.failureKind(), QStringLiteral("protocol"));
        QVERIFY(controller.failureMessage().contains(
            QString::number(maximumAnalysisInfoLineBytes)));
        QVERIFY(oversizedAnalysisLine.isEmpty());
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
    controller.requestSynchronization({}, 2);
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
