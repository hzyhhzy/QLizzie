const assert = require("node:assert/strict")
const path = require("node:path")
const test = require("node:test")
const { loadQmlJs } = require("./qmlJsLoader")

const ownership = loadQmlJs(
    path.join(__dirname, "..", "app", "qml", "Ownership.js")
)

test("normalizes current-player ownership to a fixed black perspective", () => {
    assert.deepEqual(
        Array.from(ownership.normalized([1, -0.5, 0.25, -1], 2, 2, 1)),
        [1, -0.5, 0.25, -1]
    )
    assert.deepEqual(
        Array.from(ownership.normalized([1, -0.5, 0.25, -1], 2, 2, 2)),
        [-1, 0.5, -0.25, 1]
    )
})

test("rejects malformed ownership arrays and clamps finite values", () => {
    assert.deepEqual(Array.from(ownership.normalized([1, 2, -2, 0], 2, 2, 1)),
                     [1, 1, -1, 0])
    assert.deepEqual(Array.from(ownership.normalized([1, 0], 2, 2, 1)), [])
    assert.deepEqual(Array.from(ownership.normalized([1, NaN, 0, 0], 2, 2, 1)), [])
})

test("maps KataGo row-major values from the upper-left intersection", () => {
    assert.deepEqual(JSON.parse(JSON.stringify(ownership.pointForIndex(0, 19))), { x: 0, y: 0 })
    assert.deepEqual(JSON.parse(JSON.stringify(ownership.pointForIndex(18, 19))), { x: 18, y: 0 })
    assert.deepEqual(JSON.parse(JSON.stringify(ownership.pointForIndex(19, 19))), { x: 0, y: 1 })
})

test("suppresses near-zero noise and keeps strong markers visible", () => {
    assert.equal(ownership.markerOpacity(0.049), 0)
    assert.ok(ownership.markerOpacity(0.5) > 0.5)
    assert.ok(ownership.markerOpacity(1) <= 0.92)
})
