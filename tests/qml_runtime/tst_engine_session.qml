import QtQuick
import QtTest
import "../../app/qml" as Engine

TestCase {
    id: testRoot
    name: "EngineSession"
    when: windowShown

    Engine.EngineSession {
        id: session
        aiAnalysisSeconds: 0.1
        aiAnalysisWatchdogMilliseconds: 180
    }

    SignalSpy { id: moveLimit; target: session; signalName: "aiAnalysisLimitReached" }
    SignalSpy { id: watchdog; target: session; signalName: "aiAnalysisWatchdogExpired" }
    SignalSpy { id: scheduled; target: session; signalName: "scheduledUpdateRequested" }

    function position() {
        return { nodeId: 3, generation: 1, boardSignature: "19:go",
            komiSignature: "7.5", player: 2, engineSignature: "engine-a" }
    }

    function init() {
        session.shutdown()
        session.aiAnalysisSeconds = 0.1
        session.aiAnalysisWatchdogMilliseconds = 180
        moveLimit.clear()
        watchdog.clear()
        scheduled.clear()
    }

    function cleanup() {
        session.shutdown()
    }

    function test_cancelStopsRequestTimers() {
        var request = session.beginAiAnalysis(position())
        verify(session.aiAnalysisTimeLimitRunning)
        verify(session.aiAnalysisWatchdogRunning)
        session.cancelAiAnalysis(true)
        verify(!session.aiAnalysisTimeLimitRunning)
        verify(!session.aiAnalysisWatchdogRunning)
        verify(!session.aiAnalysisInFlight)
        verify(!session.engineAnalysisRequestValid)
        wait(250)
        compare(moveLimit.count, 0)
        compare(watchdog.count, 0)
        verify(!session.completeAiAnalysis(request.requestId, position()).accepted)
    }

    function test_syncAcknowledgementRestartsMoveClockOnce() {
        session.aiAnalysisSeconds = 0
        var request = session.beginAiAnalysis(position())
        verify(!session.aiAnalysisTimeLimitRunning)
        session.syncPlan(request.syncRequestId, [1, 2, 3], "19:go", "7.5", true)
        session.aiAnalysisSeconds = 0.1
        verify(session.commitSync(request.syncRequestId))
        verify(session.aiAnalysisTimeLimitRunning)
        compare(session.activeAiAnalysisSyncRequestId, 0)
        var startedAt = session.aiAnalysisStartedAt
        verify(!session.commitSync(request.syncRequestId))
        compare(session.aiAnalysisStartedAt, startedAt)
        tryCompare(moveLimit, "count", 1, 500)
        session.cancelAiAnalysis(true)
        verify(session.engineNeedsFullSync)
    }

    function test_replacedAnalysisCannotFirePlayTimers() {
        var old = session.beginAiAnalysis(position())
        var replacement = session.beginAnalysis(position())
        verify(!session.aiAnalysisTimeLimitRunning)
        verify(!session.aiAnalysisWatchdogRunning)
        verify(!session.acceptsAnalysis(old.syncRequestId, position()))
        verify(session.acceptsAnalysis(replacement.syncRequestId, position()))
        wait(250)
        compare(moveLimit.count, 0)
        compare(watchdog.count, 0)
    }

    function test_watchdogEmitsOnlyForActiveRequest() {
        session.aiAnalysisSeconds = 0
        session.beginAiAnalysis(position())
        tryCompare(watchdog, "count", 1, 600)
        compare(moveLimit.count, 0)
        verify(session.aiAnalysisInFlight)
    }

    function test_invalidatingSessionCancelsScheduledUpdate() {
        session.scheduleAutoAnalysis(false)
        session.invalidateAll()
        wait(350)
        compare(scheduled.count, 0)
        session.scheduleAutoAnalysis(true)
        tryCompare(scheduled, "count", 1, 500)
    }

    function test_genmoveCompletionUpdatesBindingsAtomically() {
        var request = session.beginGenmove(position())
        verify(session.genmoveInFlight)
        compare(session.activeGenmovePosition.engineSignature, "engine-a")
        session.syncPlan(request.syncRequestId, [1, 2, 3], "19:go", "7.5", true)
        var completed = session.completeGenmove(request.requestId, position(), true)
        verify(completed.accepted)
        compare(completed.status, "ready")
        verify(!session.genmoveInFlight)
        compare(session.activeGenmoveRequestId, 0)
        compare(session.activeGenmovePosition, null)
        verify(!session.engineNeedsFullSync)
        verify(!session.completeGenmove(request.requestId, position(), true).accepted)
    }

    function test_exportedSnapshotsCannotChangeAnActiveTransaction() {
        var request = session.beginGenmove(position())
        request.position.nodeId = 999
        compare(session.activeGenmovePosition.nodeId, 3)
        session.syncPlan(request.syncRequestId, [1, 2, 3], "19:go", "7.5", true)
        var pending = session.pendingEngineSyncSnapshot
        pending.nodeIds.push(999)
        verify(session.commitSync(request.syncRequestId))
        compare(session.engineSyncedNodeIds.length, 3)
        var completed = session.completeGenmove(request.requestId, position(), true)
        verify(completed.accepted)
        compare(completed.state, undefined)
    }
}
