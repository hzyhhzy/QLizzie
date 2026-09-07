import QtQuick
import "EngineSessionState.js" as SessionState

QtObject {
    id: session

    // The owner supplies settings and immutable position snapshots. No game or
    // window object crosses this boundary; signals return decisions to it.
    property real analysisLimitSeconds: 0
    property real aiAnalysisSeconds: 5
    property int aiAnalysisWatchdogMilliseconds: 60000

    signal scheduledUpdateRequested()
    signal analysisLimitReached()
    signal aiAnalysisLimitReached()
    signal aiAnalysisWatchdogExpired()

    property var _state: SessionState.create()
    property int _scheduledEpoch: 0
    property int _analysisLimitSyncId: 0
    property int _aiMoveRequestId: 0
    property int _watchdogRequestId: 0

    readonly property int epoch: _state.epoch
    readonly property bool genmoveInFlight: _state.genmove !== null
    readonly property int genmoveRequestSerial: _state.genmoveSerial
    readonly property int activeGenmoveRequestId: _state.genmove ? _state.genmove.requestId : 0
    readonly property int activeGenmoveSyncRequestId: _state.genmove ? _state.genmove.syncRequestId : 0
    readonly property var activeGenmovePosition: requestPosition(_state.genmove)
    readonly property int genmovePlayer: _state.genmove ? _state.genmove.position.player : 0
    readonly property bool aiAnalysisInFlight: _state.aiAnalysis !== null
    readonly property int aiAnalysisRequestSerial: _state.aiAnalysisSerial
    readonly property int activeAiAnalysisRequestId: _state.aiAnalysis ? _state.aiAnalysis.requestId : 0
    readonly property int activeAiAnalysisSyncRequestId: _state.aiAnalysis && !_state.aiAnalysis.synced
                                                        ? _state.aiAnalysis.syncRequestId : 0
    readonly property var activeAiAnalysisPosition: requestPosition(_state.aiAnalysis)
    readonly property double aiAnalysisStartedAt: _state.aiAnalysis ? _state.aiAnalysis.startedAt : 0
    readonly property var engineSyncedNodeIds: _state.sync.committed ? _state.sync.committed.nodeIds.slice() : []
    readonly property string engineSyncedBoardSignature: _state.sync.committed ? _state.sync.committed.boardSignature : ""
    readonly property string engineSyncedKomiSignature: _state.sync.committed ? _state.sync.committed.komiSignature : ""
    readonly property bool engineNeedsFullSync: _state.sync.needsFull
    readonly property int engineSyncRequestSerial: _state.syncSerial
    readonly property var pendingEngineSyncSnapshot: syncSnapshot(_state.sync.pending)
    readonly property int engineAnalysisRequestNodeId: _state.analysis ? _state.analysis.position.nodeId : -1
    readonly property int engineAnalysisRequestGeneration: _state.analysis ? _state.analysis.position.generation : -1
    readonly property string engineAnalysisRequestBoardSignature: _state.analysis ? _state.analysis.position.boardSignature : ""
    readonly property string engineAnalysisRequestKomiSignature: _state.analysis ? _state.analysis.position.komiSignature : ""
    readonly property int engineAnalysisRequestPlayer: _state.analysis ? _state.analysis.position.player : 0
    readonly property string engineAnalysisRequestEngineSignature: _state.analysis ? _state.analysis.position.engineSignature : ""
    readonly property int engineAnalysisSyncRequestId: _state.analysis ? _state.analysis.syncRequestId : 0
    readonly property bool engineAnalysisRequestValid: _state.analysis !== null
    readonly property bool analysisLimitRunning: _analysisLimitTimer.running
    readonly property bool aiAnalysisTimeLimitRunning: _aiMoveTimer.running
    readonly property bool aiAnalysisWatchdogRunning: _watchdogTimer.running

    function requestPosition(request) {
        if (!request)
            return null
        var position = SessionState.positionSnapshot(request.position)
        position.requestId = request.requestId
        return position
    }

    function requestToken(request) {
        if (!request)
            return null
        return {
            epoch: request.epoch,
            requestId: request.requestId,
            syncRequestId: request.syncRequestId,
            position: SessionState.positionSnapshot(request.position)
        }
    }

    function syncSnapshot(snapshot) {
        if (!snapshot)
            return null
        return {
            requestId: snapshot.requestId,
            nodeIds: snapshot.nodeIds.slice(),
            boardSignature: snapshot.boardSignature,
            komiSignature: snapshot.komiSignature
        }
    }

    function replaceState(next) {
        _state = next
        if (!_state.analysis || _state.analysis.syncRequestId !== _analysisLimitSyncId)
            _analysisLimitTimer.stop()
        if (!_state.aiAnalysis || _state.aiAnalysis.requestId !== _aiMoveRequestId)
            _aiMoveTimer.stop()
        if (!_state.aiAnalysis || _state.aiAnalysis.requestId !== _watchdogRequestId)
            _watchdogTimer.stop()
    }

    function beginAnalysis(position) {
        var result = SessionState.beginAnalysis(_state, position)
        replaceState(result.state)
        return requestToken(result.request)
    }

    function beginSynchronization(position) {
        var result = SessionState.beginSynchronization(_state, position)
        replaceState(result.state)
        return requestToken(result.request)
    }

    function beginGenmove(position) {
        var result = SessionState.beginGenmove(_state, position)
        replaceState(result.state)
        return requestToken(result.request)
    }

    function beginAiAnalysis(position) {
        var result = SessionState.beginAiAnalysis(_state, position, Date.now())
        replaceState(result.state)
        restartAiAnalysisTimeLimit()
        restartAiAnalysisWatchdog()
        return requestToken(result.request)
    }

    function syncPlan(requestId, nodeIds, boardSignature, komiSignature, allowsIncremental) {
        var result = SessionState.syncPlan(_state, requestId, nodeIds,
                                           boardSignature, komiSignature, allowsIncremental)
        replaceState(result.state)
        return result.plan
    }

    function stageSync(requestId, nodeIds, boardSignature, komiSignature) {
        replaceState(SessionState.stageSync(_state, requestId, nodeIds,
                                            boardSignature, komiSignature))
    }

    function commitSync(requestId) {
        var result = SessionState.commitSync(_state, requestId)
        replaceState(result.state)
        if (result.committed && _state.aiAnalysis
                && _state.aiAnalysis.syncRequestId === requestId)
            restartAiAnalysisTimeLimit()
        return result.committed
    }

    function invalidateAll() {
        stopScheduledUpdates()
        replaceState(SessionState.invalidateAll(_state))
    }

    function invalidateSyncRequest(requestId) {
        replaceState(SessionState.invalidateSyncRequest(_state, requestId))
    }

    function invalidateAnalysis() {
        replaceState(SessionState.invalidateAnalysis(_state))
    }

    function cancelGenmove() {
        replaceState(SessionState.cancelGenmove(_state))
    }

    function cancelAiAnalysis(invalidateSync) {
        replaceState(SessionState.cancelAiAnalysis(_state, invalidateSync))
    }

    function cancelPlay(invalidateSync) {
        replaceState(SessionState.cancelPlay(_state, invalidateSync))
    }

    function positionChanged(position) {
        var next = SessionState.positionChanged(_state, position)
        var changed = next !== _state
        replaceState(next)
        return changed
    }

    function activeAiAnalysisPositionMatches(position) {
        return SessionState.aiAnalysisPositionMatches(_state, position)
    }

    function acceptsAnalysis(requestId, position) {
        return SessionState.acceptsAnalysis(_state, requestId, position)
    }

    function completeGenmove(requestId, position, ok) {
        var result = SessionState.completeGenmove(_state, requestId, position, ok)
        replaceState(result.state)
        return {
            accepted: result.accepted,
            status: result.status,
            positionStillCurrent: result.positionStillCurrent === true,
            request: requestToken(result.request)
        }
    }

    function completeAiAnalysis(requestId, position) {
        var result = SessionState.completeAiAnalysis(_state, requestId, position)
        replaceState(result.state)
        return { accepted: result.accepted, request: requestToken(result.request) }
    }

    function markGeneratedMoveSynced(nodeIds, boardSignature, komiSignature) {
        var result = SessionState.markGeneratedMoveSynced(_state, nodeIds,
                                                         boardSignature, komiSignature)
        replaceState(result.state)
        return result.synced
    }

    function scheduleAutoAnalysis(paused) {
        _scheduledEpoch = _state.epoch
        _autoAnalyzeTimer.interval = paused ? 1 : 280
        _autoAnalyzeTimer.restart()
    }

    function stopScheduledUpdates() {
        _autoAnalyzeTimer.stop()
    }

    function resetAnalysisLimitTimer(enabled) {
        var seconds = Number(analysisLimitSeconds)
        if (!enabled || !_state.analysis || !isFinite(seconds) || seconds <= 0) {
            _analysisLimitTimer.stop()
            return
        }
        _analysisLimitSyncId = _state.analysis.syncRequestId
        _analysisLimitTimer.interval = Math.max(1, Math.round(seconds)) * 1000
        _analysisLimitTimer.restart()
    }

    function stopAnalysisLimitTimer() {
        _analysisLimitTimer.stop()
    }

    function restartAiAnalysisTimeLimit() {
        if (!_state.aiAnalysis) {
            _aiMoveTimer.stop()
            return
        }
        replaceState(SessionState.restartAiAnalysisTime(_state, Date.now()))
        var seconds = Math.max(0, Number(aiAnalysisSeconds))
        if (!isFinite(seconds))
            seconds = 5
        if (seconds <= 0) {
            _aiMoveTimer.stop()
            return
        }
        _aiMoveRequestId = _state.aiAnalysis.requestId
        _aiMoveTimer.interval = Math.max(100, Math.round(seconds * 1000))
        _aiMoveTimer.restart()
    }

    function restartAiAnalysisWatchdog() {
        if (!_state.aiAnalysis) {
            _watchdogTimer.stop()
            return
        }
        _watchdogRequestId = _state.aiAnalysis.requestId
        _watchdogTimer.interval = Math.max(1, aiAnalysisWatchdogMilliseconds)
        _watchdogTimer.restart()
    }

    function shutdown() {
        invalidateAll()
    }

    property Timer _autoAnalyzeTimer: Timer {
        repeat: false
        onTriggered: {
            if (session._scheduledEpoch === session.epoch)
                session.scheduledUpdateRequested()
        }
    }

    property Timer _analysisLimitTimer: Timer {
        repeat: false
        onTriggered: {
            if (session.engineAnalysisRequestValid
                    && session.engineAnalysisSyncRequestId === session._analysisLimitSyncId)
                session.analysisLimitReached()
        }
    }

    property Timer _aiMoveTimer: Timer {
        repeat: false
        onTriggered: {
            if (session.aiAnalysisInFlight
                    && session.activeAiAnalysisRequestId === session._aiMoveRequestId)
                session.aiAnalysisLimitReached()
        }
    }

    property Timer _watchdogTimer: Timer {
        repeat: false
        onTriggered: {
            if (session.aiAnalysisInFlight
                    && session.activeAiAnalysisRequestId === session._watchdogRequestId)
                session.aiAnalysisWatchdogExpired()
        }
    }
}
