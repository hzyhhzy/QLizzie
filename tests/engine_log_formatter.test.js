"use strict"

const assert = require("node:assert/strict")
const path = require("node:path")
const test = require("node:test")
const { loadQmlJs } = require("./qmlJsLoader")

const formatter = loadQmlJs(
    path.join(__dirname, "..", "app", "qml", "EngineLogFormatter.js")
)

function model(entries) {
    return {
        count: entries.length,
        get(index) {
            return entries[index]
        }
    }
}

test("engine text is escaped without adding stream labels", () => {
    const html = formatter.buildHtml(model([
        { stream: "stdin", line: "play B <D4>&", color: "#7ee2a8" },
        { stream: "stdout", line: "= ok", color: "#d9e6ee" }
    ]), true, true, true)

    assert.match(html, /play B &lt;D4&gt;&amp;/)
    assert.match(html, /= ok/)
    assert.doesNotMatch(html, /\[(?:stdin|stdout|stderr)\]/)
    assert.doesNotMatch(html, /play B <D4>/)
    assert.match(html, /font-family:'JetBrains Mono'/)
    assert.match(html, /font-weight:500/)
})

test("stream filters exclude complete lines", () => {
    const html = formatter.buildHtml(model([
        { stream: "stdin", line: "name", color: "#7ee2a8" },
        { stream: "stdout", line: "= KataGo", color: "#d9e6ee" },
        { stream: "stderr", line: "warning", color: "#ff8b7f" }
    ]), false, true, false)

    assert.doesNotMatch(html, /name/)
    assert.match(html, /= KataGo/)
    assert.doesNotMatch(html, /warning/)
})

test("untrusted colors fall back to the normal output color", () => {
    const html = formatter.buildHtml(model([
        { stream: "stdout", line: "safe", color: "red; background:url(x)" }
    ]), true, true, true)

    assert.match(html, /color:#d9e6ee/)
    assert.doesNotMatch(html, /background/)
})
