const assert = require("node:assert/strict")
const path = require("node:path")
const test = require("node:test")
const { loadQmlJs } = require("./qmlJsLoader")

const enginePlay = loadQmlJs(
    path.join(__dirname, "..", "app", "qml", "EnginePlay.js")
)

test("analysis play limits use OR semantics and ignore symmetry visits", () => {
    const candidates = [
        { move: "D4", visits: 120 },
        { move: "Q16", visits: 80 },
        { move: "C3", visits: 900, isSymmetryOf: "D4" }
    ]

    assert.equal(enginePlay.totalVisits(candidates), 200)
    assert.equal(enginePlay.limitReached(candidates, 4999, 5, 0, 0), false)
    assert.equal(enginePlay.limitReached(candidates, 5000, 5, 0, 0), true)
    assert.equal(enginePlay.limitReached(candidates, 10, 5, 200, 0), true)
    assert.equal(enginePlay.limitReached(candidates, 10, 5, 0, 120), true)
})

test("zero seconds permits a pure visits limit", () => {
    const candidates = [{ move: "D4", visits: 49 }]

    assert.equal(enginePlay.limitReached(candidates, 60000, 0, 50, 0), false)
    candidates[0].visits = 50
    assert.equal(enginePlay.limitReached(candidates, 60000, 0, 50, 0), true)
})

test("limit changes cancel an all-zero search and restart once configured", () => {
    assert.equal(enginePlay.limitChangeAction(false, true, true), "cancel")
    assert.equal(enginePlay.limitChangeAction(false, false, true), "wait")
    assert.equal(enginePlay.limitChangeAction(true, false, true), "start")
    assert.equal(enginePlay.limitChangeAction(true, true, true), "evaluate")
})

test("elapsed time never causes a move before a candidate exists", () => {
    assert.equal(enginePlay.limitReached([], 60000, 1, 1, 1), false)
    assert.equal(enginePlay.bestCandidate([{ visits: 10 }]), null)
})

test("analysis request snapshots reject stale positions", () => {
    const position = {
        nodeId: 4,
        generation: 9,
        boardSignature: "19:19:go",
        komiSignature: "6.5",
        player: 2,
        engineSignature: "katago-a"
    }
    assert.equal(enginePlay.positionMatches(position, 4, 9, "19:19:go", "6.5", 2, "katago-a"), true)
    assert.equal(enginePlay.positionMatches(position, 5, 9, "19:19:go", "6.5", 2, "katago-a"), false)
    assert.equal(enginePlay.positionMatches(position, 4, 10, "19:19:go", "6.5", 2, "katago-a"), false)
    assert.equal(enginePlay.positionMatches(position, 4, 9, "19:19:go", "7.5", 2, "katago-a"), false)
    assert.equal(enginePlay.positionMatches(position, 4, 9, "19:19:go", "6.5", 1, "katago-a"), false)
    assert.equal(enginePlay.positionMatches(position, 4, 9, "19:19:go", "6.5", 2, "katago-b"), false)
})

test("resignation counter resets outside the configured conditions", () => {
    assert.equal(enginePlay.nextResignCount(0, 80, 4.9, 80, 5), 1)
    assert.equal(enginePlay.nextResignCount(1, 82, 4.0, 80, 5), 2)
    assert.equal(enginePlay.nextResignCount(2, 84, 5.0, 80, 5), 0)
    assert.equal(enginePlay.nextResignCount(2, 79, 1.0, 80, 5), 0)
    assert.equal(enginePlay.nextResignCount(2, 84, 1.0, 80, 0), 0)
})
