.pragma library

.import "EngineSync.js" as EngineSync

// This module owns transaction identity, not the engine transport or game tree.
// Every transition returns a new state so QML bindings observe one atomic change.
function create() {
    return {
        epoch: 1,
        syncSerial: 0,
        genmoveSerial: 0,
        aiAnalysisSerial: 0,
        sync: { activeRequestId: 0, position: null, committed: null, pending: null, needsFull: true },
        analysis: null,
        genmove: null,
        aiAnalysis: null
    }
}

function copy(state) {
    return {
        epoch: state.epoch,
        syncSerial: state.syncSerial,
        genmoveSerial: state.genmoveSerial,
        aiAnalysisSerial: state.aiAnalysisSerial,
        sync: {
            activeRequestId: state.sync.activeRequestId,
            position: state.sync.position,
            committed: state.sync.committed,
            pending: state.sync.pending,
            needsFull: state.sync.needsFull
        },
        analysis: state.analysis,
        genmove: state.genmove,
        aiAnalysis: state.aiAnalysis
    }
}

function positionSnapshot(position) {
    return {
        nodeId: Number(position.nodeId),
        generation: Number(position.generation),
        boardSignature: String(position.boardSignature),
        komiSignature: String(position.komiSignature),
        player: Number(position.player),
        engineSignature: String(position.engineSignature || "")
    }
}

function positionMatches(expected, actual) {
    return !!expected && !!actual
            && expected.nodeId === Number(actual.nodeId)
            && expected.generation === Number(actual.generation)
            && expected.boardSignature === String(actual.boardSignature)
            && expected.komiSignature === String(actual.komiSignature)
            && expected.player === Number(actual.player)
            && expected.engineSignature === String(actual.engineSignature || "")
}

function clearSync(next) {
    next.sync = { activeRequestId: 0, position: null, committed: null, pending: null, needsFull: true }
}

function begin(state, kind, position, now) {
    var next = copy(state)
    var target = positionSnapshot(position)
    var previous = state.sync.position
    if (previous && (previous.generation !== target.generation
                     || previous.engineSignature !== target.engineSignature)) {
        next.epoch += 1
        clearSync(next)
    }
    // A replaced genmove may already have changed the engine's board.
    if (state.genmove)
        clearSync(next)
    next.syncSerial += 1
    next.sync.activeRequestId = next.syncSerial
    next.sync.position = target
    next.analysis = null
    next.genmove = null
    next.aiAnalysis = null
    var request = {
        epoch: next.epoch,
        requestId: 0,
        syncRequestId: next.syncSerial,
        position: target
    }
    if (kind === "genmove") {
        next.genmoveSerial += 1
        request.requestId = next.genmoveSerial
        next.genmove = request
    } else if (kind === "analysis" || kind === "aiAnalysis") {
        next.analysis = {
            epoch: next.epoch,
            syncRequestId: request.syncRequestId,
            position: request.position
        }
        if (kind === "aiAnalysis") {
            next.aiAnalysisSerial += 1
            request.requestId = next.aiAnalysisSerial
            request.startedAt = Number(now) || 0
            request.synced = false
            next.aiAnalysis = request
        }
    }
    return { state: next, request: request }
}

function beginSynchronization(state, position) {
    return begin(state, "synchronization", position, 0)
}

function beginAnalysis(state, position) {
    return begin(state, "analysis", position, 0)
}

function beginGenmove(state, position) {
    return begin(state, "genmove", position, 0)
}

function beginAiAnalysis(state, position, now) {
    return begin(state, "aiAnalysis", position, now)
}

function stageSync(state, requestId, nodeIds, boardSignature, komiSignature) {
    if (requestId <= 0 || requestId !== state.sync.activeRequestId)
        return state
    var next = copy(state)
    next.sync.pending = {
        epoch: state.epoch,
        requestId: requestId,
        nodeIds: nodeIds.slice(),
        boardSignature: String(boardSignature),
        komiSignature: String(komiSignature)
    }
    return next
}

function syncPlan(state, requestId, nodeIds, boardSignature, komiSignature,
                  allowsIncremental) {
    if (requestId <= 0 || requestId !== state.sync.activeRequestId)
        return { state: state, plan: null }
    var committed = state.sync.committed
    var forceFull = state.sync.needsFull || !!state.sync.pending || !committed
            || committed.boardSignature !== String(boardSignature)
            || !allowsIncremental
    var plan = EngineSync.buildPlan(committed ? committed.nodeIds : [], nodeIds, forceFull)
    plan.parametersChanged = !committed
            || committed.komiSignature !== String(komiSignature)
    return {
        state: stageSync(state, requestId, nodeIds, boardSignature, komiSignature),
        plan: plan
    }
}

function commitSync(state, requestId) {
    var pending = state.sync.pending
    if (!pending || requestId !== state.sync.activeRequestId
            || pending.requestId !== requestId || pending.epoch !== state.epoch)
        return { state: state, committed: false }
    var next = copy(state)
    next.sync.committed = pending
    next.sync.pending = null
    next.sync.needsFull = false
    if (next.aiAnalysis && next.aiAnalysis.syncRequestId === requestId) {
        var request = next.aiAnalysis
        next.aiAnalysis = {
            epoch: request.epoch,
            requestId: request.requestId,
            syncRequestId: request.syncRequestId,
            position: request.position,
            startedAt: request.startedAt,
            synced: true
        }
    }
    return { state: next, committed: true }
}

function invalidateSyncRequest(state, requestId) {
    // A failure from a replaced transaction must never erase the new session.
    if (requestId <= 0 || requestId !== state.sync.activeRequestId)
        return state
    var next = copy(state)
    clearSync(next)
    if (next.analysis && next.analysis.syncRequestId === requestId)
        next.analysis = null
    if (next.genmove && next.genmove.syncRequestId === requestId)
        next.genmove = null
    if (next.aiAnalysis && next.aiAnalysis.syncRequestId === requestId)
        next.aiAnalysis = null
    return next
}

function invalidateAll(state) {
    var next = copy(state)
    next.epoch += 1
    clearSync(next)
    next.analysis = null
    next.genmove = null
    next.aiAnalysis = null
    return next
}

function invalidateAnalysis(state) {
    if (!state.analysis && !state.aiAnalysis)
        return state
    var next = copy(state)
    next.analysis = null
    next.aiAnalysis = null
    return next
}

function cancelGenmove(state) {
    if (!state.genmove)
        return state
    return invalidateSyncRequest(state, state.genmove.syncRequestId)
}

function cancelAiAnalysis(state, invalidateSync) {
    var request = state.aiAnalysis
    if (!request)
        return state
    if (invalidateSync !== false)
        return invalidateSyncRequest(state, request.syncRequestId)
    var next = copy(state)
    next.aiAnalysis = null
    if (next.analysis && next.analysis.syncRequestId === request.syncRequestId)
        next.analysis = null
    return next
}

function cancelPlay(state, invalidateSync) {
    return cancelAiAnalysis(cancelGenmove(state), invalidateSync)
}

function restartAiAnalysisTime(state, now) {
    if (!state.aiAnalysis)
        return state
    var next = copy(state)
    var request = state.aiAnalysis
    next.aiAnalysis = {
        epoch: request.epoch,
        requestId: request.requestId,
        syncRequestId: request.syncRequestId,
        position: request.position,
        startedAt: Number(now) || 0,
        synced: request.synced
    }
    return next
}

function acceptsAnalysis(state, syncRequestId, position) {
    var request = state.analysis
    return !!request && request.epoch === state.epoch
            && syncRequestId > 0 && request.syncRequestId === syncRequestId
            && positionMatches(request.position, position)
}

function aiAnalysisPositionMatches(state, position) {
    return !!state.aiAnalysis && state.aiAnalysis.epoch === state.epoch
            && positionMatches(state.aiAnalysis.position, position)
}

function positionChanged(state, position) {
    var stalePlay = (state.genmove && !positionMatches(state.genmove.position, position))
            || (state.aiAnalysis && !positionMatches(state.aiAnalysis.position, position))
    if (stalePlay)
        return invalidateAll(state)
    if (state.analysis && !positionMatches(state.analysis.position, position))
        return invalidateAnalysis(state)
    return state
}

function completeGenmove(state, requestId, position, ok) {
    var request = state.genmove
    if (!request || requestId <= 0 || request.requestId !== requestId
            || request.epoch !== state.epoch)
        return { state: state, accepted: false, status: "ignored", request: null }
    var current = positionMatches(request.position, position)
    var next = copy(state)
    next.genmove = null
    if (!ok || !current)
        next = invalidateSyncRequest(next, request.syncRequestId)
    else
        next = commitSync(next, request.syncRequestId).state
    return {
        state: next,
        accepted: true,
        status: !current ? "stale" : (ok ? "ready" : "failed"),
        positionStillCurrent: current,
        request: request
    }
}

function completeAiAnalysis(state, requestId, position) {
    var request = state.aiAnalysis
    if (!request || request.requestId !== requestId || request.epoch !== state.epoch)
        return { state: state, accepted: false, request: null }
    if (!positionMatches(request.position, position)) {
        return {
            state: invalidateSyncRequest(state, request.syncRequestId),
            accepted: false,
            request: null
        }
    }
    return { state: cancelAiAnalysis(state, false), accepted: true, request: request }
}

function markGeneratedMoveSynced(state, nodeIds, boardSignature, komiSignature) {
    var committed = state.sync.committed
    var matches = !state.sync.needsFull && !state.sync.pending && !!committed
            && committed.boardSignature === String(boardSignature)
            && committed.komiSignature === String(komiSignature)
            && nodeIds.length === committed.nodeIds.length + 1
    if (matches) {
        for (var index = 0; index < committed.nodeIds.length; ++index) {
            if (nodeIds[index] !== committed.nodeIds[index]) {
                matches = false
                break
            }
        }
    }
    if (!matches)
        return { state: invalidateAll(state), synced: false }
    var next = copy(state)
    next.sync.committed = {
        epoch: committed.epoch,
        requestId: committed.requestId,
        nodeIds: nodeIds.slice(),
        boardSignature: committed.boardSignature,
        komiSignature: committed.komiSignature
    }
    return { state: next, synced: true }
}
