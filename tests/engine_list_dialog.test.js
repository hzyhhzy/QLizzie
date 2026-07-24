"use strict"

const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const test = require("node:test")

const dialogPath = path.join(__dirname, "..", "app", "qml", "EngineListDialog.qml")
const source = fs.readFileSync(dialogPath, "utf8")
const mainPath = path.join(__dirname, "..", "app", "qml", "Main.qml")
const mainSource = fs.readFileSync(mainPath, "utf8")

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

test("new engine presets are inserted at the top", () => {
    const start = mainSource.indexOf("function addEnginePreset(preset)")
    const end = mainSource.indexOf("function removeEnginePreset(index)", start)
    assert.notEqual(start, -1)
    assert.notEqual(end, -1)
    const addPreset = mainSource.slice(start, end)

    assert.match(addPreset, /next\.unshift\(/)
    assert.match(addPreset, /return\s+0/)
    assert.doesNotMatch(addPreset, /next\.push\(/)
})

test("engine editor fields keep mouse drags for text selection", () => {
    const flickable = sectionBetween("id: dialogFlick", "id: dialogContent")

    assert.match(source, /^AppWindowDialog\s*\{/m)
    assert.match(flickable, /acceptedButtons:\s*Qt\.NoButton/)
    assert.doesNotMatch(flickable, /interactive:\s*!\(/)
    assert.match(source, /Basic\.TextField\s*\{\s*id:\s*nameEdit[\s\S]*?selectByMouse:\s*true/)
    assert.match(source, /AppSpinBox\s*\{\s*id:\s*widthSpin/)
    assert.match(source, /AppSpinBox\s*\{\s*id:\s*heightSpin/)
    assert.match(source, /AppSpinBox\s*\{\s*id:\s*komiSpin/)
})

test("engine list uses one explicit mode instead of two independent flags", () => {
    assert.match(source, /property int dialogMode:\s*manageMode/)
    assert.match(source, /readonly property bool startupMode:\s*dialogMode\s*===\s*startupSelectionMode/)
    assert.match(source, /readonly property bool pickerMode:\s*dialogMode\s*===\s*pickerSelectionMode/)
    assert.doesNotMatch(source, /^\s*property bool startupMode:/m)
    assert.doesNotMatch(source, /^\s*property bool pickerMode:/m)
})

test("closing the native engine window does not strand child popups", () => {
    const requestClose = sectionBetween("function requestClose()", "function selectIndexNow")
    const closedHandler = sectionBetween("onClosed:", "dialogBody: Flickable")

    assert.match(requestClose, /closeTopmostChildOverlay\(\)/)
    assert.match(closedHandler, /closeAllChildOverlays\(\)/)
    assert.match(source, /if \(unsavedEngineDialog\.visible\)[\s\S]*unsavedEngineDialog\.close\(\)/)
    assert.match(source, /if \(engineRuleSelectionPopup\.visible\)[\s\S]*engineRuleSelectionPopup\.close\(\)/)
})

test("engine list scrollbar has a wide independent hit target", () => {
    const list = sectionBetween("id: engineListView", "delegate: Rectangle")

    assert.match(source, /readonly property real scrollBarHitThickness:\s*20/)
    assert.match(list, /id:\s*engineListScrollBar/)
    assert.match(list, /hitThickness:\s*engineListDialog\.scrollBarHitThickness/)
    assert.match(list, /32\s*\/\s*Math\.max/)
    assert.match(
        source,
        /width:\s*Math\.max\(0,\s*dialogFlick\.width\s*-\s*engineListDialog\.scrollBarHitThickness\)/
    )
})

test("engine komi editor accepts signed decimal values", () => {
    const komi = sectionBetween("id: komiSpin", "id: legacyHexCheck")

    assert.match(komi, /validator:\s*DoubleValidator/)
    assert.match(komi, /bottom:\s*-app\.maxKomiMagnitude/)
    assert.match(komi, /decimals:\s*1/)
    assert.match(komi, /locale:\s*"C"/)
    assert.match(komi, /Math\.round\(number\s*\*\s*2\)/)
})
