"use strict"

const assert = require("node:assert/strict")
const path = require("node:path")
const test = require("node:test")
const { loadQmlJs } = require("./qmlJsLoader")

const qmlPath = name => path.join(__dirname, "..", "app", "qml", name)
const engineSync = loadQmlJs(qmlPath("EngineSync.js"))
const session = loadQmlJs(qmlPath("EngineSessionState.js"), {
    imports: { EngineSync: engineSync }
})

function position(overrides = {}) {
    return Object.assign({
        nodeId: 3,
        generation: 1,
        boardSignature: "19:19:go",
        komiSignature: "7.5",
        player: 2,
        engineSignature: "katago:model-a"
    }, overrides)
}

function planned(kind = "beginAnalysis", current = position(), state = session.create()) {
    const started = session[kind](state, current, 100)
    const result = session.syncPlan(started.state, started.request.syncRequestId,
        [1, 2, current.nodeId], current.boardSignature, current.komiSignature, true)
    return { state: result.state, request: started.request, plan: result.plan }
}

function deepFreeze(value) {
    if (value && typeof value === "object" && !Object.isFrozen(value)) {
        Object.freeze(value)
        for (const child of Object.values(value))
            deepFreeze(child)
    }
    return value
}

test("a replacement before sync acknowledgement replays the entire path", () => {
    const first = planned()
    const replacement = planned("beginAnalysis", position({ nodeId: 4 }), first.state)
    assert.equal(replacement.plan.full, true)
    assert.equal(replacement.plan.playStartIndex, 0)
    const oldCompletion = session.commitSync(replacement.state, first.request.syncRequestId)
    assert.equal(oldCompletion.committed, false)
    assert.equal(oldCompletion.state, replacement.state)
    const completion = session.commitSync(oldCompletion.state, replacement.request.syncRequestId)
    assert.equal(completion.committed, true)
    assert.deepEqual(Array.from(completion.state.sync.committed.nodeIds), [1, 2, 4])
    assert.equal(completion.state.sync.pending, null)
})

test("confirmed sync permits incremental branch changes and parameter updates", () => {
    const first = planned()
    const committed = session.commitSync(first.state, first.request.syncRequestId).state
    const replacement = planned("beginAnalysis", position({ nodeId: 4, komiSignature: "6.5" }), committed)
    assert.equal(replacement.plan.full, false)
    assert.equal(replacement.plan.undoCount, 1)
    assert.equal(replacement.plan.playStartIndex, 2)
    assert.equal(replacement.plan.parametersChanged, true)
})

test("transport refusal or board changes force full sync after a committed path", () => {
    const first = planned()
    const committed = session.commitSync(first.state, first.request.syncRequestId).state
    const next = session.beginAnalysis(committed, position())
    assert.equal(session.syncPlan(next.state, next.request.syncRequestId,
        [1, 2, 3], "19:19:go", "7.5", false).plan.full, true)
    assert.equal(session.syncPlan(next.state, next.request.syncRequestId,
        [1, 2, 3], "13:13:go", "7.5", true).plan.full, true)
})

test("late failures and duplicate sync callbacks cannot erase a replacement", () => {
    const first = planned()
    const next = planned("beginAnalysis", position(), first.state)
    assert.equal(session.invalidateSyncRequest(next.state, first.request.syncRequestId), next.state)
    assert.equal(session.stageSync(next.state, first.request.syncRequestId, [], "", ""), next.state)
    const committed = session.commitSync(next.state, next.request.syncRequestId)
    assert.equal(session.commitSync(committed.state, next.request.syncRequestId).committed, false)
    assert.equal(session.invalidateSyncRequest(committed.state, first.request.syncRequestId), committed.state)
})

test("a new engine or game generation forces replay without an external reset", () => {
    const first = planned()
    const committed = session.commitSync(first.state, first.request.syncRequestId).state
    for (const change of [{ generation: 2 }, { engineSignature: "katago:model-b" }]) {
        const next = planned("beginAnalysis", position(change), committed)
        assert.equal(next.plan.full, true)
        assert.ok(next.state.epoch > committed.epoch)
        assert.equal(session.commitSync(next.state, first.request.syncRequestId).committed, false)
    }
})

test("engine replacement invalidates every transaction without recycling request IDs", () => {
    const first = planned("beginGenmove")
    const reset = session.invalidateAll(first.state)
    assert.equal(reset.epoch, first.state.epoch + 1)
    assert.equal(reset.sync.pending, null)
    assert.equal(reset.genmove, null)
    const next = planned("beginGenmove", position({ engineSignature: "katago:model-b" }), reset)
    assert.ok(next.request.requestId > first.request.requestId)
    assert.ok(next.request.syncRequestId > first.request.syncRequestId)
    assert.equal(session.completeGenmove(next.state, first.request.requestId, position(), true).accepted, false)
    assert.equal(session.commitSync(next.state, first.request.syncRequestId).committed, false)
})

test("cancelling a move consumes identity and rejects its late successful callback", () => {
    const active = planned("beginGenmove")
    const cancelled = session.cancelPlay(active.state, true)
    assert.equal(cancelled.genmove, null)
    assert.equal(cancelled.sync.pending, null)
    assert.equal(cancelled.sync.needsFull, true)
    const late = session.completeGenmove(cancelled, active.request.requestId, position(), true)
    assert.equal(late.accepted, false)
    assert.equal(late.state, cancelled)
})

test("each position dimension rejects stale genmove results, including engine identity", () => {
    for (const change of [
        { nodeId: 4 }, { generation: 2 }, { boardSignature: "13:13:go" },
        { komiSignature: "6.5" }, { player: 1 }, { engineSignature: "katago:model-b" }
    ]) {
        const active = planned("beginGenmove")
        const result = session.completeGenmove(active.state, active.request.requestId,
            position(change), true)
        assert.equal(result.status, "stale", JSON.stringify(change))
        assert.equal(result.positionStillCurrent, false)
        assert.equal(result.state.genmove, null)
        assert.equal(result.state.sync.needsFull, true)
    }
})

test("a valid genmove commits its prelude exactly once and permits a generated append", () => {
    const active = planned("beginGenmove")
    const result = session.completeGenmove(active.state, active.request.requestId, position(), true)
    assert.equal(result.status, "ready")
    assert.equal(result.request.position.player, 2)
    assert.equal(result.state.sync.needsFull, false)
    assert.equal(session.completeGenmove(result.state, active.request.requestId, position(), true).accepted, false)
    const appended = session.markGeneratedMoveSynced(result.state, [1, 2, 3, 4], "19:19:go", "7.5")
    assert.equal(appended.synced, true)
    assert.deepEqual(Array.from(appended.state.sync.committed.nodeIds), [1, 2, 3, 4])
    assert.equal(session.markGeneratedMoveSynced(result.state, [1, 2, 5, 6], "19:19:go", "7.5").synced, false)
})

test("failed genmove invalidates synchronization and is not completed twice", () => {
    const active = planned("beginGenmove")
    const result = session.completeGenmove(active.state, active.request.requestId, position(), false)
    assert.equal(result.status, "failed")
    assert.equal(result.state.sync.needsFull, true)
    assert.equal(result.state.genmove, null)
    assert.equal(session.completeGenmove(result.state, active.request.requestId, position(), false).accepted, false)
})

test("analysis tokens reject replaced, cancelled, wrong-engine, and wrong-position updates", () => {
    const first = planned()
    assert.equal(session.acceptsAnalysis(first.state, first.request.syncRequestId, position()), true)
    const next = planned("beginAnalysis", position({ nodeId: 4 }), first.state)
    assert.equal(session.acceptsAnalysis(next.state, first.request.syncRequestId, position()), false)
    assert.equal(session.acceptsAnalysis(next.state, next.request.syncRequestId, position()), false)
    assert.equal(session.acceptsAnalysis(next.state, next.request.syncRequestId,
        position({ nodeId: 4, engineSignature: "other" })), false)
    assert.equal(session.acceptsAnalysis(session.invalidateAnalysis(next.state),
        next.request.syncRequestId, position({ nodeId: 4 })), false)
})

test("AI analysis can complete only once and never consumes the next request", () => {
    const first = planned("beginAiAnalysis")
    const next = planned("beginAiAnalysis", position(), first.state)
    assert.equal(session.completeAiAnalysis(next.state, first.request.requestId, position()).accepted, false)
    const completed = session.completeAiAnalysis(next.state, next.request.requestId, position())
    assert.equal(completed.accepted, true)
    assert.equal(completed.state.analysis, null)
    assert.equal(completed.state.aiAnalysis, null)
    assert.equal(session.completeAiAnalysis(completed.state, next.request.requestId, position()).accepted, false)
})

test("AI cancellation after sync confirmation still invalidates its committed board", () => {
    const active = planned("beginAiAnalysis")
    const committed = session.commitSync(active.state, active.request.syncRequestId).state
    assert.equal(committed.aiAnalysis.synced, true)
    const cancelled = session.cancelAiAnalysis(committed, true)
    assert.equal(cancelled.sync.committed, null)
    assert.equal(cancelled.aiAnalysis, null)
    assert.equal(cancelled.analysis, null)
})

test("finishing AI analysis preserves its confirmed path for the ensuing play command", () => {
    const active = planned("beginAiAnalysis")
    const committed = session.commitSync(active.state, active.request.syncRequestId).state
    const completed = session.completeAiAnalysis(committed, active.request.requestId, position())
    assert.equal(completed.accepted, true)
    assert.equal(completed.state.sync.committed, committed.sync.committed)
    assert.equal(completed.state.sync.needsFull, false)
})

test("position changes cancel active play atomically and allow fresh requests", () => {
    for (const kind of ["beginGenmove", "beginAiAnalysis"]) {
        const active = planned(kind)
        assert.equal(session.positionChanged(active.state, position()), active.state)
        const changed = session.positionChanged(active.state, position({ generation: 2 }))
        assert.equal(changed.genmove, null)
        assert.equal(changed.aiAnalysis, null)
        assert.equal(changed.analysis, null)
        assert.equal(changed.sync.pending, null)
        assert.equal(planned(kind, position({ generation: 2 }), changed).plan.full, true)
    }
})

test("state transitions and input snapshots do not mutate their callers", () => {
    const current = position()
    const empty = deepFreeze(session.create())
    const start = session.beginAiAnalysis(empty, current, 100)
    current.nodeId = 999
    assert.equal(start.state.aiAnalysis.position.nodeId, 3)
    const nodes = [1, 2, 3]
    const stage = session.stageSync(deepFreeze(start.state), start.request.syncRequestId,
        nodes, "19:19:go", "7.5")
    nodes.push(999)
    assert.deepEqual(Array.from(stage.sync.pending.nodeIds), [1, 2, 3])
    const committed = session.commitSync(deepFreeze(stage), start.request.syncRequestId).state
    const restarted = session.restartAiAnalysisTime(deepFreeze(committed), 200)
    assert.equal(restarted.aiAnalysis.startedAt, 200)
    assert.equal(committed.aiAnalysis.startedAt, 100)
    assert.equal(session.cancelAiAnalysis(deepFreeze(restarted), false).aiAnalysis, null)
    assert.equal(session.invalidateAll(deepFreeze(restarted)).analysis, null)
})
