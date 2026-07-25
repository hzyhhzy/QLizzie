const assert = require("node:assert/strict")
const path = require("node:path")
const test = require("node:test")
const { loadQmlJs } = require("./qmlJsLoader")

const engineSpeed = loadQmlJs(
    path.join(__dirname, "..", "app", "qml", "EngineSpeed.js")
)

test("sums visits while excluding symmetry candidates", () => {
    assert.equal(engineSpeed.totalVisits([
        { move: "D4", visits: 120 },
        { move: "Q16", visits: "80" },
        { move: "C3", visits: 999, isSymmetryOf: "D4" },
        { move: "pass", visits: -1 },
        { move: "R17", visits: "invalid" }
    ]), 200)
    assert.equal(engineSpeed.totalVisits([]), -1)
})

test("uses the oldest sample in a four-second rolling window", () => {
    let state = engineSpeed.nextSample([], "position", 100, 0, 4, 5000)
    assert.equal(state.speed, -1)

    state = engineSpeed.nextSample(state.samples, "position", 300, 1000, 4, 5000)
    assert.equal(state.speed, 200)
    state = engineSpeed.nextSample(state.samples, "position", 500, 2000, 4, 5000)
    state = engineSpeed.nextSample(state.samples, "position", 700, 3000, 4, 5000)
    state = engineSpeed.nextSample(state.samples, "position", 900, 4000, 4, 5000)

    assert.equal(state.speed, 200)
    assert.equal(state.samples.length, 4)
    assert.equal(state.samples[0].time, 1000)
})

test("resets on a position change, visits rollback, or stale sample", () => {
    let state = engineSpeed.nextSample([], "first", 100, 0, 4, 5000)
    state = engineSpeed.nextSample(state.samples, "first", 200, 1000, 4, 5000)
    assert.equal(state.speed, 100)

    state = engineSpeed.nextSample(state.samples, "second", 300, 2000, 4, 5000)
    assert.equal(state.speed, -1)
    assert.equal(state.samples.length, 1)
    assert.equal(state.samples[0].key, "second")

    state = engineSpeed.nextSample(state.samples, "second", 50, 3000, 4, 5000)
    assert.equal(state.speed, -1)
    assert.equal(state.samples.length, 1)
    assert.equal(state.samples[0].total, 50)

    state = engineSpeed.nextSample(state.samples, "second", 500, 9001, 4, 5000)
    assert.equal(state.speed, -1)
    assert.equal(state.samples.length, 1)
})
