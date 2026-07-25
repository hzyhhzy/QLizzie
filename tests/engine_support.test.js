"use strict"

const assert = require("node:assert/strict")
const path = require("node:path")
const test = require("node:test")
const { loadQmlJs } = require("./qmlJsLoader")

const support = loadQmlJs(
    path.join(__dirname, "..", "app", "qml", "EngineSupport.js")
)

class MockListModel {
    constructor(entries = []) {
        this.entries = entries.map(entry => ({ ...entry }))
    }

    get count() {
        return this.entries.length
    }

    append(entry) {
        this.entries.push({ ...entry })
    }

    get(index) {
        return this.entries[index]
    }

    remove(index, count = 1) {
        this.entries.splice(index, count)
    }

    clear() {
        this.entries.length = 0
    }

    setProperty(index, name, value) {
        this.entries[index][name] = value
    }
}

function hasUnpairedSurrogate(text) {
    for (let index = 0; index < text.length; ++index) {
        const code = text.charCodeAt(index)
        if (code >= 0xD800 && code <= 0xDBFF) {
            const next = text.charCodeAt(index + 1)
            if (!(next >= 0xDC00 && next <= 0xDFFF))
                return true
            ++index
        } else if (code >= 0xDC00 && code <= 0xDFFF) {
            return true
        }
    }
    return false
}

test("communication buffer keeps only recent lines within both budgets", () => {
    const model = new MockListModel()
    const state = { characterCount: 0 }

    for (let index = 0; index < 6; ++index) {
        assert.equal(support.appendCommunication(
            model, "stderr", `line-${index}-` + "x".repeat(40),
            3, 110, 80, state
        ), true)
    }

    assert.ok(model.count <= 3)
    assert.ok(state.characterCount <= 110)
    assert.equal(model.get(model.count - 1).line.endsWith("x".repeat(40)), true)
    assert.match(model.get(model.count - 1).line, /^line-5-/)
})

test("oversized lines retain their beginning and end without splitting emoji", () => {
    const model = new MockListModel()
    const state = { characterCount: 0 }
    const line = "BEGIN-" + "😀".repeat(100) + "-END"

    support.appendCommunication(model, "stdout", line, 1000, 1000, 64, state)

    const stored = model.get(0).line
    assert.ok(stored.length <= 64)
    assert.ok(stored.startsWith("BEGIN-"))
    assert.ok(stored.endsWith("-END"))
    assert.match(stored, /\[line truncated\]/)
    assert.equal(hasUnpairedSurrogate(stored), false)
})

test("changing limits immediately trims and recounts the current buffer", () => {
    const model = new MockListModel([
        { stream: "stdout", line: "a".repeat(90), color: "#d9e6ee" },
        { stream: "stderr", line: "b".repeat(90), color: "#ff8b7f" },
        { stream: "stdin", line: "c".repeat(90), color: "#7ee2a8" }
    ])
    const state = { characterCount: 0 }

    assert.equal(support.enforceCommunicationLimits(
        model, 2, 100, 60, state
    ), true)

    assert.ok(model.count <= 2)
    assert.ok(state.characterCount <= 100)
    for (const entry of model.entries) {
        assert.ok(entry.line.length <= 60)
        assert.equal(entry.characterCount, entry.line.length + 1)
    }
})

test("filtered candidate info does not consume buffer budget", () => {
    const model = new MockListModel()
    const state = { characterCount: 0 }

    assert.equal(support.appendCommunication(
        model, "stdout", "info move D4 visits 10",
        1000, 262144, 16384, state
    ), false)
    assert.equal(model.count, 0)
    assert.equal(state.characterCount, 0)
})

test("communication metadata tracks changed streams and retained entries", () => {
    const model = new MockListModel()
    const state = {
        characterCount: 0,
        stdinRetainedCount: 0,
        stdoutRetainedCount: 0,
        stderrRetainedCount: 0,
        lastChangeMask: 0
    }

    support.appendCommunication(model, "stdout", "response", 1, 1000, 100, state)
    assert.equal(state.lastChangeMask, 2)
    assert.equal(state.stdoutRetainedCount, 1)

    support.appendCommunication(model, "stderr", "warning", 1, 1000, 100, state)
    assert.equal(state.lastChangeMask, 6)
    assert.equal(state.stdoutRetainedCount, 0)
    assert.equal(state.stderrRetainedCount, 1)

    support.appendCommunication(model, "stderr", "new warning", 1, 1000, 100, state)
    assert.equal(state.lastChangeMask, 4)
    assert.equal(state.stderrRetainedCount, 1)

    support.clearCommunication(model, state)
    assert.equal(state.lastChangeMask, 4)
    assert.equal(state.characterCount, 0)
    assert.equal(state.stdinRetainedCount, 0)
    assert.equal(state.stdoutRetainedCount, 0)
    assert.equal(state.stderrRetainedCount, 0)
})

test("enforcing limits reports every rendered stream it changes", () => {
    const model = new MockListModel([
        { stream: "stdout", line: "a".repeat(90), color: "#d9e6ee" },
        { stream: "stdin", line: "b".repeat(90), color: "#7ee2a8" },
        { stream: "stderr", line: "c".repeat(90), color: "#ff8b7f" }
    ])
    const state = {}

    support.enforceCommunicationLimits(model, 2, 200, 60, state)

    assert.equal(state.lastChangeMask & 2, 2)
    assert.equal(state.lastChangeMask & 1, 1)
    assert.equal(state.lastChangeMask & 4, 4)
    assert.equal(
        state.stdinRetainedCount
        + state.stdoutRetainedCount
        + state.stderrRetainedCount,
        model.count
    )
})
