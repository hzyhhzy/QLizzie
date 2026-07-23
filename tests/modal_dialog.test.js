"use strict"

const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const test = require("node:test")

const qmlRoot = path.join(__dirname, "..", "app", "qml")
const appDialogSource = fs.readFileSync(path.join(qmlRoot, "AppDialog.qml"), "utf8")
const appDialogFooterSource = fs.readFileSync(path.join(qmlRoot, "AppDialogFooter.qml"), "utf8")
const engineListSource = fs.readFileSync(path.join(qmlRoot, "EngineListDialog.qml"), "utf8")
const engineFailureSource = fs.readFileSync(path.join(qmlRoot, "EngineFailureDialog.qml"), "utf8")
const engineRuleWarningSource = fs.readFileSync(path.join(qmlRoot, "EngineRuleWarningDialog.qml"), "utf8")
const gameOverSource = fs.readFileSync(path.join(qmlRoot, "GameOverDialog.qml"), "utf8")
const settingsSource = fs.readFileSync(path.join(qmlRoot, "SettingsDialog.qml"), "utf8")

test("modal application dialogs use independently movable popup windows", () => {
    assert.match(appDialogSource, /property bool windowed:\s*modal/)
    assert.match(appDialogSource, /popupType:\s*windowed\s*\?\s*Popup\.Window\s*:\s*Popup\.Item/)
    assert.match(appDialogSource, /onAboutToShow:\s*prepareWindowGeometry\(\)/)
})

test("window geometry is initialized once instead of continuously recentered", () => {
    assert.doesNotMatch(appDialogSource, /^\s*x:\s*app\s*\?/m)
    assert.doesNotMatch(appDialogSource, /^\s*y:\s*app\s*\?/m)
    assert.match(appDialogSource, /onAboutToShow:\s*prepareWindowGeometry\(\)/)
    assert.match(appDialogSource, /x\s*=\s*Math\.max\(minimumGlobalX/)
    assert.match(appDialogSource, /y\s*=\s*Math\.max\(minimumGlobalY/)
})

test("native popup windows enforce useful minimum sizes", () => {
    assert.match(appDialogSource, /popupWindow\.minimumWidth\s*=/)
    assert.match(appDialogSource, /popupWindow\.minimumHeight\s*=/)
    assert.match(engineListSource, /dialogMinimumWidth:\s*Math\.min\(readOnlyMode\s*\?\s*620\s*:\s*900/)
    assert.match(settingsSource, /dialogMinimumWidth:\s*Math\.min\(720,\s*preferredWidth\)/)
})

test("native window close requests can be guarded by application dialogs", () => {
    assert.match(appDialogSource, /property bool blockNativeClose:\s*closePolicy\s*===\s*Popup\.NoAutoClose/)
    assert.match(appDialogSource, /closeEvent\.accepted\s*=\s*false/)
    assert.match(engineListSource, /onNativeCloseRequested:\s*requestClose\(\)/)
})

test("large dialog bodies scroll instead of clipping on short screens", () => {
    assert.match(engineListSource, /contentItem:\s*Flickable\s*\{/)
    assert.match(engineListSource, /contentHeight:\s*dialogContent\.height/)
    assert.match(engineFailureSource, /contentItem:\s*Flickable\s*\{/)
    assert.match(engineRuleWarningSource, /contentItem:\s*Flickable\s*\{/)
})

test("engine-list child dialogs use the parent dialog window and viewport", () => {
    assert.match(engineListSource, /parent:\s*engineListDialog\.contentItem/)
    assert.match(engineListSource, /centerTarget:\s*engineListDialog\.contentItem/)
    assert.match(engineListSource, /owningWindow:\s*engineListDialog\.hostWindow/)
})

test("windowed dialogs use the native title bar and report correct implicit footer size", () => {
    assert.match(appDialogSource, /property var owningWindow:\s*app/)
    assert.match(appDialogSource, /windowed\s*&&\s*!!hostWindow\s*&&\s*hostWindow\s*!==\s*owningWindow/)
    assert.match(appDialogSource, /implicitHeight:\s*appDialog\.separateWindow\s*\?\s*0\s*:\s*appDialog\.headerHeight/)
    assert.match(appDialogSource, /visible:\s*!appDialog\.separateWindow/)
    assert.match(appDialogFooterSource, /implicitHeight:\s*footerRow\.implicitHeight\s*\+\s*verticalMargins\s*\*\s*2/)
})

test("the intentionally modeless game-over notice stays inside the main window", () => {
    assert.match(gameOverSource, /modal:\s*false/)
})
