"use strict"

const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const test = require("node:test")

const qmlRoot = path.join(__dirname, "..", "app", "qml")
const appDialogSource = fs.readFileSync(path.join(qmlRoot, "AppDialog.qml"), "utf8")
const appWindowDialogSource = fs.readFileSync(path.join(qmlRoot, "AppWindowDialog.qml"), "utf8")
const appDialogFooterSource = fs.readFileSync(path.join(qmlRoot, "AppDialogFooter.qml"), "utf8")
const engineListSource = fs.readFileSync(path.join(qmlRoot, "EngineListDialog.qml"), "utf8")
const engineParametersSource = fs.readFileSync(path.join(qmlRoot, "EngineParametersDialog.qml"), "utf8")
const gameOverSource = fs.readFileSync(path.join(qmlRoot, "GameOverDialog.qml"), "utf8")
const settingsSource = fs.readFileSync(path.join(qmlRoot, "SettingsDialog.qml"), "utf8")
const hiddenSettingsSource = fs.readFileSync(path.join(qmlRoot, "HiddenSettingsDialog.qml"), "utf8")
const helpKeysSource = fs.readFileSync(path.join(qmlRoot, "HelpKeysDialog.qml"), "utf8")

test("lightweight application dialogs always stay inside their owning window", () => {
    assert.match(appDialogSource, /\bBasic\.Dialog\s*\{/)
    assert.match(appDialogSource, /popupType:\s*Popup\.Item/)
    assert.doesNotMatch(appDialogSource, /Popup\.Window/)
})

test("content-heavy dialogs use a real transient modal window", () => {
    assert.match(appWindowDialogSource, /\bWindow\s*\{/)
    assert.doesNotMatch(appWindowDialogSource, /\bBasic\.Dialog\s*\{/)
    assert.match(appWindowDialogSource, /flags:\s*Qt\.Dialog/)
    assert.match(appWindowDialogSource, /modality:\s*modal\s*\?\s*Qt\.WindowModal\s*:\s*Qt\.NonModal/)
    assert.match(
        appWindowDialogSource,
        /transientParent:\s*owningWindow\s*&&\s*owningWindow\s*!==\s*appWindowDialog\s*\?\s*owningWindow\s*:\s*null/
    )
    assert.match(appWindowDialogSource, /readonly property bool separateWindow:\s*true/)
    assert.match(appWindowDialogSource, /readonly property var hostWindow:\s*appWindowDialog/)
})

test("real dialog geometry is applied once before the window becomes visible", () => {
    const openFunction = appWindowDialogSource.match(
        /function open\(\)\s*\{[\s\S]*?(?=\n\s*function closeDialog)/
    )
    assert.ok(openFunction, "AppWindowDialog must expose an open() helper")
    assert.match(openFunction[0], /applyPreferredGeometry\(\)/)
    assert.match(openFunction[0], /visible\s*=\s*true/)
    assert.ok(
        openFunction[0].indexOf("applyPreferredGeometry()")
            < openFunction[0].indexOf("visible = true"),
        "geometry must be finalized while the native window is hidden"
    )
    assert.doesNotMatch(appWindowDialogSource, /^\s*x:\s*.*centerTarget/m)
    assert.doesNotMatch(appWindowDialogSource, /^\s*y:\s*.*centerTarget/m)
})

test("real dialog windows enforce useful minimum sizes", () => {
    assert.match(appWindowDialogSource, /minimumWidth:\s*Math\.max\(1,\s*Math\.ceil\(dialogMinimumWidth\)\)/)
    assert.match(appWindowDialogSource, /minimumHeight:\s*Math\.max\(1,\s*Math\.ceil\(dialogMinimumHeight\)\)/)
    assert.match(engineListSource, /dialogMinimumWidth:\s*Math\.min\(readOnlyMode\s*\?\s*620\s*:\s*900/)
    assert.match(settingsSource, /dialogMinimumWidth:\s*Math\.min\(720,\s*preferredWidth\)/)
})

test("native close requests can be guarded by content-heavy dialogs", () => {
    assert.match(
        appWindowDialogSource,
        /property bool blockNativeClose:\s*closePolicy\s*===\s*Popup\.NoAutoClose/
    )
    assert.match(appWindowDialogSource, /onClosing:\s*function\(closeEvent\)/)
    assert.match(appWindowDialogSource, /if\s*\(blockNativeClose\)\s*\{[\s\S]*?closeEvent\.accepted\s*=\s*false/)
    assert.match(appWindowDialogSource, /appWindowDialog\.nativeCloseRequested\(\)/)
    assert.match(engineListSource, /onNativeCloseRequested:\s*requestClose\(\)/)
})

test("content-heavy dialogs release their native window whenever they close", () => {
    assert.match(appWindowDialogSource, /property bool _acceptProgrammaticClose:\s*false/)
    assert.match(
        appWindowDialogSource,
        /function closeDialog\(\)[\s\S]*?closeNativeWindow\(\)/
    )
    assert.match(
        appWindowDialogSource,
        /function closeNativeWindow\(\)[\s\S]*?_acceptProgrammaticClose\s*=\s*true[\s\S]*?appWindowDialog\.close\(\)/
    )
    assert.match(
        appWindowDialogSource,
        /onClosing:\s*function\(closeEvent\)[\s\S]*?if\s*\(_acceptProgrammaticClose\)/
    )
})

test("dialog surface follows the Window size instead of a stale contentItem size", () => {
    assert.match(appWindowDialogSource, /id:\s*dialogSurface/)
    assert.match(appWindowDialogSource, /width:\s*appWindowDialog\.width/)
    assert.match(appWindowDialogSource, /height:\s*appWindowDialog\.height/)
    assert.doesNotMatch(appWindowDialogSource, /id:\s*dialogSurface\s*\n\s*anchors\.fill:\s*parent/)
})

test("Escape is handled after focused controls and their popups", () => {
    assert.doesNotMatch(appWindowDialogSource, /\bShortcut\s*\{/)
    assert.match(appWindowDialogSource, /\bFocusScope\s*\{/)
    assert.match(appWindowDialogSource, /Keys\.priority:\s*Keys\.AfterItem/)
    assert.match(appWindowDialogSource, /Keys\.onEscapePressed:\s*function\(event\)/)
})

test("selected content-heavy dialogs use the real-window body API", () => {
    for (const [name, source] of [
        ["SettingsDialog", settingsSource],
        ["HiddenSettingsDialog", hiddenSettingsSource],
        ["HelpKeysDialog", helpKeysSource],
        ["EngineListDialog", engineListSource]
    ]) {
        assert.match(source, /\bAppWindowDialog\s*\{/, `${name} should use AppWindowDialog`)
        assert.match(source, /\bdialogBody:\s*/, `${name} should provide dialogBody`)
    }
    assert.match(engineListSource, /\bdialogBody:\s*Flickable\s*\{/)
    assert.match(engineListSource, /\bdialogFooter:\s*AppDialogFooter\s*\{/)
    assert.match(engineListSource, /contentHeight:\s*dialogContent\.height/)
})

test("engine-list child dialogs use the parent dialog window and viewport", () => {
    assert.match(engineListSource, /parent:\s*engineListDialog\.contentItem/)
    assert.match(engineListSource, /centerTarget:\s*engineListDialog\.contentItem/)
    assert.match(engineListSource, /owningWindow:\s*engineListDialog\.hostWindow/)
})

test("dialog footers still report their full implicit size", () => {
    assert.match(appDialogFooterSource, /implicitHeight:\s*footerRow\.implicitHeight\s*\+\s*verticalMargins\s*\*\s*2/)
})

test("small engine-parameter and game-over dialogs remain lightweight popups", () => {
    assert.match(engineParametersSource, /\bAppDialog\s*\{/)
    assert.doesNotMatch(engineParametersSource, /\bAppWindowDialog\s*\{/)
    assert.match(gameOverSource, /\bAppDialog\s*\{/)
    assert.doesNotMatch(gameOverSource, /\bAppWindowDialog\s*\{/)
    assert.match(gameOverSource, /modal:\s*false/)
})
