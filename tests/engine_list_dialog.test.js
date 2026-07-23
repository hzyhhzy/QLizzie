"use strict"

const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const test = require("node:test")

const dialogPath = path.join(__dirname, "..", "app", "qml", "EngineListDialog.qml")
const source = fs.readFileSync(dialogPath, "utf8")

function sectionBetween(startMarker, endMarker) {
    const start = source.indexOf(startMarker)
    const end = source.indexOf(endMarker, start + startMarker.length)
    assert.notEqual(start, -1, `Missing ${startMarker}`)
    assert.notEqual(end, -1, `Missing ${endMarker}`)
    return source.slice(start, end)
}

test("nested engine dialogs keep their own footer tone", () => {
    const unsaved = sectionBetween("id: unsavedEngineDialog", "id: confirmDeleteEngineDialog")
    const confirmDelete = source.slice(source.indexOf("id: confirmDeleteEngineDialog"))

    assert.match(unsaved, /tone:\s*unsavedEngineDialog\.tone/)
    assert.doesNotMatch(unsaved, /tone:\s*confirmDeleteEngineDialog\.tone/)
    assert.match(confirmDelete, /tone:\s*confirmDeleteEngineDialog\.tone/)
})

test("escaping the unsaved-engine dialog clears its pending action", () => {
    const unsaved = sectionBetween("id: unsavedEngineDialog", "id: confirmDeleteEngineDialog")

    assert.match(unsaved, /property bool explicitClose:\s*false/)
    assert.match(
        unsaved,
        /onClosed:\s*\{[\s\S]*engineListDialog\.pendingUnsavedAction\s*=\s*null[\s\S]*\}/
    )
})
