"use strict"

const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const test = require("node:test")
const { loadQmlJs } = require("./qmlJsLoader")

const translationsPath = path.join(__dirname, "..", "app", "qml", "Translations.js")
const source = fs.readFileSync(translationsPath, "utf8")
const translations = loadQmlJs(translationsPath).translations

function countKey(sourceText, key) {
    const escaped = key.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
    return (sourceText.match(new RegExp(`"${escaped}"\\s*:`, "g")) || []).length
}

test("Chinese and English expose the same translation keys", () => {
    assert.deepEqual(
        Object.keys(translations.zh).sort(),
        Object.keys(translations.en).sort()
    )
})

test("pass tooltip exists once per language with the intended text", () => {
    const englishStart = source.indexOf('"en": {')
    assert.notEqual(englishStart, -1)
    const chineseSource = source.slice(0, englishStart)
    const englishSource = source.slice(englishStart)

    assert.equal(countKey(chineseSource, "passMoveTooltip"), 1)
    assert.equal(countKey(englishSource, "passMoveTooltip"), 1)
    assert.equal(translations.zh.passMoveTooltip, "Pass（停一手）")
    assert.equal(translations.en.passMoveTooltip, "Pass (pass a move)")
})

test("special candidate move labels are localized", () => {
    assert.equal(translations.zh.resignMove, "认输")
    assert.equal(translations.en.resignMove, "Resign")
    assert.equal(translations.zh.engineSuggestsResign, "引擎建议认输")
    assert.equal(translations.en.engineSuggestsResign, "Engine suggests resigning")
})
