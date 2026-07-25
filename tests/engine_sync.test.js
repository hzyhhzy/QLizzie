"use strict"

const assert = require("node:assert/strict")
const path = require("node:path")
const test = require("node:test")
const { loadQmlJs } = require("./qmlJsLoader")

const engineSync = loadQmlJs(path.join(__dirname, "..", "app", "qml", "EngineSync.js"))

test("an unconfirmed replacement remains a full replay", () => {
    const committed = []
    const first = engineSync.buildPlan(committed, [1], true)
    const replacement = engineSync.buildPlan(committed, [1, 2, 3], true)

    assert.equal(first.full, true)
    assert.equal(replacement.full, true)
    assert.equal(replacement.playStartIndex, 0)
})

test("a confirmed path permits an incremental append", () => {
    const plan = engineSync.buildPlan([1, 2, 3], [1, 2, 3, 4, 5], false)

    assert.equal(plan.full, false)
    assert.equal(plan.undoCount, 0)
    assert.equal(plan.playStartIndex, 3)
})

test("a confirmed branch change undoes only the divergent suffix", () => {
    const plan = engineSync.buildPlan([1, 2, 3, 4], [1, 2, 5, 6], false)

    assert.equal(plan.full, false)
    assert.equal(plan.commonLength, 2)
    assert.equal(plan.undoCount, 2)
    assert.equal(plan.playStartIndex, 2)
})
