"use strict"

const assert = require("node:assert/strict")
const path = require("node:path")
const test = require("node:test")
const { loadQmlJs } = require("./qmlJsLoader")

const translationsPath = path.join(__dirname, "..", "app", "qml", "Translations.js")
const translations = loadQmlJs(translationsPath).translations

test("all languages expose matching keys with string values", () => {
    const languages = Object.entries(translations)
    assert.ok(languages.length > 0, "At least one language must be available")
    const expectedKeys = Object.keys(languages[0][1]).sort()
    assert.ok(expectedKeys.length > 0, "Translation dictionaries must not be empty")

    for (const [language, dictionary] of languages) {
        assert.deepEqual(Object.keys(dictionary).sort(), expectedKeys, language)
        for (const [key, value] of Object.entries(dictionary))
            assert.equal(typeof value, "string", language + "." + key)
    }
})
