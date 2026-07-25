import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import "EnginePresets.js" as EnginePresets

AppWindowDialog {
    id: engineListDialog

    required property var controller
    readonly property int manageMode: 0
    readonly property int startupSelectionMode: 1
    readonly property int pickerSelectionMode: 2
    property int dialogMode: manageMode
    property int selectedIndex: -1
    property bool syncingEditor: false
    property string listTooltipText: ""
    property string listTooltipKey: ""
    property bool listTooltipReady: false
    property real listTooltipX: 0
    property real listTooltipY: 0
    property var editorGoRules: ({})
    property var editorGomokuRules: ({})
    property int editorRuleMode: app.gameRuleGo
    property var engineRuleCollapsedGroups: ({})
    property var editorRuleOptionsModel: []
    property var pendingUnsavedAction: null
    readonly property bool startupMode: dialogMode === startupSelectionMode
    readonly property bool pickerMode: dialogMode === pickerSelectionMode
    readonly property bool readOnlyMode: dialogMode !== manageMode
    readonly property real legacyHexColumnWidth: readOnlyMode ? 0 : 82
    readonly property real ruleColumnWidth: readOnlyMode ? 150 : 164
    readonly property real scrollBarHitThickness: 20

    modal: true
    title: readOnlyMode ? app.trText("loadEngineTitle") : app.trText("engineSettingsTitle")
    closePolicy: Popup.NoAutoClose
    onNativeCloseRequested: requestClose()
    padding: 8
    preferredWidth: boundedPreferredWidth(1180, 36)
    preferredHeight: readOnlyMode ? boundedPreferredHeight(430, 80)
                                  : boundedPreferredHeight(820, 36)
    dialogMinimumWidth: Math.min(readOnlyMode ? 620 : 900, preferredWidth)
    dialogMinimumHeight: Math.min(readOnlyMode ? 360 : 680, preferredHeight)

    function ensureSelection() {
        if (!app.enginePresets || app.enginePresets.length <= 0) {
            selectedIndex = -1
            return
        }
        if (selectedIndex < 0 || selectedIndex >= app.enginePresets.length)
            selectedIndex = 0
    }

    function prepareOpeningOwner(ownerWindow) {
        var nextOwner = ownerWindow && ownerWindow !== engineListDialog ? ownerWindow : app
        owningWindow = nextOwner
        centerTarget = nextOwner
    }

    function openStartup(ownerWindow) {
        dialogMode = startupSelectionMode
        prepareOpeningOwner(ownerWindow)
        selectedIndex = app.enginePresets.length > 0 ? 0 : -1
        syncEditor()
        open()
    }

    function openPicker(ownerWindow) {
        dialogMode = pickerSelectionMode
        prepareOpeningOwner(ownerWindow)
        var activeIndex = app.enginePresetIndexById(app.activeEngineId)
        selectedIndex = activeIndex >= 0 ? activeIndex : (app.enginePresets.length > 0 ? 0 : -1)
        syncEditor()
        open()
    }

    function openManage(ownerWindow) {
        dialogMode = manageMode
        prepareOpeningOwner(ownerWindow)
        var activeIndex = app.enginePresetIndexById(app.activeEngineId)
        selectedIndex = activeIndex >= 0 ? activeIndex : (app.enginePresets.length > 0 ? 0 : -1)
        syncEditor()
        open()
    }

    function presetAt(row) {
        return row >= 0 && row < app.enginePresets.length ? app.enginePresets[row] : null
    }

    function selectedPreset() {
        return presetAt(selectedIndex)
    }

    function currentEditorRuleMode() {
        return editorRuleMode
    }

    function refreshEditorRuleOptions() {
        editorRuleOptionsModel = app.commonGameRuleOptionsWithModeAndMore(editorRuleMode)
    }

    function editorRuleCurrentIndex() {
        var options = editorRuleOptionsModel
        for (var i = 0; i < options.length; ++i) {
            if (options[i].value === editorRuleMode)
                return i
        }
        return 0
    }

    function setEditorRuleMode(mode) {
        if (!app.validRuleMode(mode))
            return
        var previousMode = editorRuleMode
        editorRuleMode = mode
        refreshEditorRuleOptions()
        ruleCombo.currentIndex = editorRuleCurrentIndex()
        if (!syncingEditor && previousMode !== mode) {
            komiSpin.value = Math.round(EnginePresets.defaultKomiForRule(app, mode) * 2)
            if (mode === app.gameRuleDotsAndBoxes) {
                widthSpin.value = 5
                heightSpin.value = 5
            }
        }
    }

    function openEditorRuleSelectionPopup() {
        engineRuleSelectionPopup.open()
    }

    function setEngineRuleGroupCollapsed(groupId, collapsed) {
        var next = {}
        for (var key in engineRuleCollapsedGroups)
            next[key] = engineRuleCollapsedGroups[key]
        if (collapsed)
            next[groupId] = true
        else
            delete next[groupId]
        engineRuleCollapsedGroups = next
    }

    function editorRuleVariantText() {
        var ruleMode = currentEditorRuleMode()
        if (ruleMode === app.gameRuleGo)
            return EnginePresets.goRuleLabelForRules(app, editorGoRules)
        if (ruleMode === app.gameRuleGomoku)
            return app.gomokuRuleLabel(EnginePresets.normalizeGomokuRules(
                                           app, editorGomokuRules, app.gomokuRuleFreestyle).ruleMode)
        return app.trText("noRuleVariantShort")
    }

    function openEditorRuleDialog() {
        var ruleMode = currentEditorRuleMode()
        if (ruleMode === app.gameRuleGo) {
            var goRules = EnginePresets.normalizeGoRules(app, editorGoRules)
            engineGoRuleDialog.applyToApp = false
            engineGoRuleDialog.openWithRules(goRules.scoringRule, goRules.koRule,
                                             goRules.suicideAllowed, goRules.taxRule,
                                             goRules.handicapBonus, goRules.buttonRule)
        } else if (ruleMode === app.gameRuleGomoku) {
            var gomokuRules = EnginePresets.normalizeGomokuRules(
                        app, editorGomokuRules, app.gomokuRuleFreestyle)
            engineGomokuRuleDialog.applyToApp = false
            engineGomokuRuleDialog.openWithRules(gomokuRules.ruleMode, gomokuRules.maxMoves,
                                                 gomokuRules.vcnRule, gomokuRules.firstPassWin)
        } else {
            engineNoRuleVariantDialog.open()
        }
    }

    function setEditorGoRules(scoringRule, koRule, suicideAllowed, taxRule, handicapBonus, buttonRule) {
        editorGoRules = EnginePresets.normalizeGoRules(app, {
            "scoringRule": scoringRule,
            "koRule": koRule,
            "suicideAllowed": suicideAllowed,
            "taxRule": taxRule,
            "handicapBonus": handicapBonus,
            "buttonRule": buttonRule
        })
    }

    function setEditorGomokuRules(ruleMode, maxMoves, vcnRule, firstPassWin) {
        editorGomokuRules = EnginePresets.normalizeGomokuRules(app, {
            "ruleMode": ruleMode,
            "maxMoves": maxMoves,
            "vcnRule": vcnRule,
            "firstPassWin": firstPassWin
        }, app.gomokuRuleFreestyle)
    }

    function boolEqual(a, b) {
        return (a === true) === (b === true)
    }

    function numberEqual(a, b) {
        return Math.abs(Number(a) - Number(b)) < 0.000001
    }

    function goRulesEqual(a, b) {
        var left = EnginePresets.normalizeGoRules(app, a)
        var right = EnginePresets.normalizeGoRules(app, b)
        return left.scoringRule === right.scoringRule
               && left.koRule === right.koRule
               && boolEqual(left.suicideAllowed, right.suicideAllowed)
               && left.taxRule === right.taxRule
               && left.handicapBonus === right.handicapBonus
               && boolEqual(left.buttonRule, right.buttonRule)
    }

    function gomokuRulesEqual(a, b, fallbackRule) {
        var left = EnginePresets.normalizeGomokuRules(app, a, fallbackRule)
        var right = EnginePresets.normalizeGomokuRules(app, b, fallbackRule)
        return left.ruleMode === right.ruleMode
               && left.maxMoves === right.maxMoves
               && left.vcnRule === right.vcnRule
               && boolEqual(left.firstPassWin, right.firstPassWin)
    }

    function presetsEqual(a, b) {
        if (!a || !b)
            return a === b
        return a.id === b.id
               && a.name === b.name
               && a.command === b.command
               && String(a.initialCommands || "") === String(b.initialCommands || "")
               && a.ruleMode === b.ruleMode
               && a.ruleVariant === b.ruleVariant
               && a.boardSizeX === b.boardSizeX
               && a.boardSizeY === b.boardSizeY
               && numberEqual(a.komi, b.komi)
               && boolEqual(a.legacyHexEngineCoordinates, b.legacyHexEngineCoordinates)
               && goRulesEqual(a.goRules, b.goRules)
               && gomokuRulesEqual(a.gomokuRules, b.gomokuRules, a.ruleVariant)
    }

    function editorDirty() {
        if (readOnlyMode || syncingEditor || selectedIndex < 0)
            return false
        var original = selectedPreset()
        if (!original)
            return false
        return !presetsEqual(collectPreset(), original)
    }

    function confirmUnsavedOrRun(action) {
        if (!editorDirty()) {
            action()
            return
        }
        pendingUnsavedAction = action
        unsavedEngineDialog.open()
    }

    function runPendingUnsavedAction(saveFirst) {
        var action = pendingUnsavedAction
        pendingUnsavedAction = null
        if (saveFirst)
            saveSelected()
        if (action)
            action()
    }

    function closeTopmostChildOverlay() {
        if (unsavedEngineDialog.visible) {
            unsavedEngineDialog.close()
            return true
        }
        if (confirmDeleteEngineDialog.visible) {
            confirmDeleteEngineDialog.close()
            return true
        }
        if (engineGoRuleDialog.visible) {
            engineGoRuleDialog.close()
            return true
        }
        if (engineGomokuRuleDialog.visible) {
            engineGomokuRuleDialog.close()
            return true
        }
        if (engineNoRuleVariantDialog.visible) {
            engineNoRuleVariantDialog.close()
            return true
        }
        if (engineRuleSelectionPopup.visible) {
            engineRuleSelectionPopup.close()
            return true
        }
        if (ruleCombo.popup && ruleCombo.popup.visible) {
            ruleCombo.popup.close()
            return true
        }
        if (defaultEngineCombo.popup && defaultEngineCombo.popup.visible) {
            defaultEngineCombo.popup.close()
            return true
        }
        return false
    }

    function closeAllChildOverlays() {
        hideListTooltip("")
        if (unsavedEngineDialog.visible)
            unsavedEngineDialog.close()
        if (confirmDeleteEngineDialog.visible)
            confirmDeleteEngineDialog.close()
        if (engineGoRuleDialog.visible)
            engineGoRuleDialog.close()
        if (engineGomokuRuleDialog.visible)
            engineGomokuRuleDialog.close()
        if (engineNoRuleVariantDialog.visible)
            engineNoRuleVariantDialog.close()
        if (engineRuleSelectionPopup.visible)
            engineRuleSelectionPopup.close()
        if (ruleCombo.popup && ruleCombo.popup.visible)
            ruleCombo.popup.close()
        if (defaultEngineCombo.popup && defaultEngineCombo.popup.visible)
            defaultEngineCombo.popup.close()
    }

    function closeWithoutPrompt() {
        pendingUnsavedAction = null
        closeAllChildOverlays()
        closeDialog()
    }

    function requestClose() {
        if (closeTopmostChildOverlay())
            return
        confirmUnsavedOrRun(function() { engineListDialog.closeWithoutPrompt() })
    }

    function selectIndexNow(index) {
        selectedIndex = Math.max(-1, Math.min(index, app.enginePresets.length - 1))
        syncEditor()
    }

    function requestSelectIndex(index) {
        if (index === selectedIndex)
            return
        if (readOnlyMode) {
            selectIndexNow(index)
            return
        }
        confirmUnsavedOrRun(function() { engineListDialog.selectIndexNow(index) })
    }

    function loadSelectedNow() {
        var preset = selectedPreset()
        if (!preset)
            return
        if (app.loadEnginePreset(preset.id, startupMode))
            closeWithoutPrompt()
    }

    function requestLoadSelected() {
        confirmUnsavedOrRun(function() { engineListDialog.loadSelectedNow() })
    }

    function requestLoadIndex(index) {
        confirmUnsavedOrRun(function() {
            engineListDialog.selectIndexNow(index)
            engineListDialog.loadSelectedNow()
        })
    }

    function syncEditor() {
        ensureSelection()
        syncingEditor = true
        var preset = selectedPreset()
        var hasPreset = preset !== null
        nameEdit.text = hasPreset ? preset.name : ""
        commandEdit.text = hasPreset ? preset.command : ""
        initialCommandEdit.text = hasPreset ? String(preset.initialCommands || "") : ""
        widthSpin.value = hasPreset ? preset.boardSizeX : app.defaultBoardSize
        heightSpin.value = hasPreset ? preset.boardSizeY : app.defaultBoardSize
        komiSpin.value = hasPreset ? Math.round(Number(preset.komi) * 2) : 13
        legacyHexCheck.checked = hasPreset && preset.legacyHexEngineCoordinates === true

        editorRuleMode = hasPreset ? preset.ruleMode : app.gameRuleGo
        refreshEditorRuleOptions()
        ruleCombo.currentIndex = editorRuleCurrentIndex()
        editorGoRules = EnginePresets.normalizeGoRules(app, hasPreset ? preset.goRules : null)
        editorGomokuRules = EnginePresets.normalizeGomokuRules(
                    app, hasPreset ? preset.gomokuRules : null,
                    hasPreset ? preset.ruleVariant : app.gomokuRuleFreestyle)
        syncingEditor = false
    }

    function collectPreset() {
        var base = selectedPreset() || EnginePresets.newPreset(app)
        var ruleMode = currentEditorRuleMode()
        var gomokuRules = EnginePresets.normalizeGomokuRules(app, editorGomokuRules, app.gomokuRuleFreestyle)
        var preset = EnginePresets.clonePreset(base)
        preset.name = nameEdit.text.trim().length > 0 ? nameEdit.text.trim() : app.trText("newEngine")
        preset.command = commandEdit.text.trim()
        preset.initialCommands = initialCommandEdit.text.trim()
        preset.ruleMode = ruleMode
        preset.goRules = EnginePresets.normalizeGoRules(app, editorGoRules)
        preset.gomokuRules = gomokuRules
        preset.ruleVariant = ruleMode === app.gameRuleGomoku ? gomokuRules.ruleMode : -1
        preset.boardSizeX = widthSpin.value
        preset.boardSizeY = heightSpin.value
        preset.komi = komiSpin.value / 2
        preset.legacyHexEngineCoordinates = legacyHexCheck.checked
        preset.boardPresentationMode = app.boardPresentationIntersections
        return app.normalizeEnginePreset(preset, selectedIndex)
    }

    function saveSelected() {
        if (selectedIndex < 0)
            return
        var preset = collectPreset()
        app.replaceEnginePreset(selectedIndex, preset)
        syncEditor()
    }

    function setSelectedAsDefault() {
        var preset = selectedPreset()
        if (preset)
            app.setDefaultEnginePreset(preset.id)
    }

    function loadSelected() {
        requestLoadSelected()
    }

    function createPresetNow() {
        selectedIndex = app.addEnginePreset(EnginePresets.newPreset(app))
        syncEditor()
    }

    function createPreset() {
        confirmUnsavedOrRun(function() { engineListDialog.createPresetNow() })
    }

    function deleteSelectedNow() {
        selectedIndex = app.removeEnginePreset(selectedIndex)
        syncEditor()
    }

    function deleteSelected() {
        if (selectedIndex < 0)
            return
        confirmUnsavedOrRun(function() { confirmDeleteEngineDialog.open() })
    }

    function moveSelectedNow(delta) {
        if (selectedIndex < 0)
            return
        selectedIndex = app.moveEnginePreset(selectedIndex, delta)
        syncEditor()
    }

    function moveSelected(delta) {
        confirmUnsavedOrRun(function() { engineListDialog.moveSelectedNow(delta) })
    }

    function moveSelectedStepsNow(delta, steps) {
        if (selectedIndex < 0)
            return
        var target = Math.max(0, Math.min(app.enginePresets.length - 1, selectedIndex + delta * steps))
        selectedIndex = app.moveEnginePresetTo(selectedIndex, target)
        syncEditor()
    }

    function moveSelectedSteps(delta, steps) {
        confirmUnsavedOrRun(function() { engineListDialog.moveSelectedStepsNow(delta, steps) })
    }

    function moveSelectedToNow(target) {
        if (selectedIndex < 0)
            return
        selectedIndex = app.moveEnginePresetTo(selectedIndex,
                                               Math.max(0, Math.min(app.enginePresets.length - 1, target)))
        syncEditor()
    }

    function moveSelectedTo(target) {
        confirmUnsavedOrRun(function() { engineListDialog.moveSelectedToNow(target) })
    }

    function chooseNoEngineMode() {
        confirmUnsavedOrRun(function() {
            app.chooseNoEngineFromList()
            engineListDialog.closeWithoutPrompt()
        })
    }

    function scheduleListTooltip(item, key, text, mouseX, mouseY) {
        if (!item || key.length <= 0 || text.length <= 0) {
            hideListTooltip("")
            return
        }
        var point = item.mapToItem(dialogContent, mouseX + 12, mouseY + 18)
        listTooltipX = point.x
        listTooltipY = point.y
        if (key === listTooltipKey && text === listTooltipText)
            return
        listTooltipKey = key
        listTooltipText = text
        listTooltipReady = false
        listTooltipTimer.restart()
    }

    function hideListTooltip(key) {
        if (key.length > 0 && key !== listTooltipKey)
            return
        listTooltipTimer.stop()
        listTooltipReady = false
        listTooltipKey = ""
        listTooltipText = ""
    }

    Timer {
        id: listTooltipTimer
        interval: 700
        repeat: false
        onTriggered: {
            if (engineListDialog.listTooltipText.length > 0)
                engineListDialog.listTooltipReady = true
        }
    }

    onOpened: syncEditor()
    onClosed: {
        closeAllChildOverlays()
        pendingUnsavedAction = null
        if (!app.applicationShutdownPrepared)
            app.focusBoardInput()
    }

    dialogBody: Flickable {
        id: dialogFlick
        implicitWidth: 1160
        implicitHeight: 720
        contentWidth: width
        contentHeight: dialogContent.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        acceptedButtons: Qt.NoButton

        ScrollBar.vertical: AppScrollBar {
            id: dialogScrollBar
            policy: dialogFlick.contentHeight > dialogFlick.height
                    ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
            hitThickness: engineListDialog.scrollBarHitThickness
        }

        ColumnLayout {
            id: dialogContent
            width: Math.max(0, dialogFlick.width - engineListDialog.scrollBarHitThickness)
            height: Math.max(dialogFlick.height, implicitHeight)
            spacing: 8

            Label {
                visible: engineListDialog.readOnlyMode
                Layout.fillWidth: true
                text: engineListDialog.startupMode ? app.trText("engineStartupManualHint")
                                                    : app.trText("enginePickerHint")
                color: "#4e626e"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
            }

            Rectangle {
                visible: !engineListDialog.readOnlyMode
                Layout.fillWidth: true
                Layout.preferredHeight: 470
                color: "#f6fafc"
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Label {
                        text: app.trText("engineSettingIndex").replace("%1", Math.max(1, engineListDialog.selectedIndex + 1))
                        color: "#2b53ff"
                        font.pixelSize: 15
                        font.bold: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        FieldLabel { text: app.trText("engineName") }
                        Basic.TextField {
                            id: nameEdit
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            selectByMouse: true
                            enabled: engineListDialog.selectedPreset() !== null
                        }
                    }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 156
                    spacing: 6

                    FieldLabel {
                        Layout.preferredWidth: 86
                        Layout.alignment: Qt.AlignTop
                        text: app.trText("engineCommand")
                    }

                    Basic.TextArea {
                        id: commandEdit
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumWidth: 0
                        enabled: engineListDialog.selectedPreset() !== null
                        selectByMouse: true
                        wrapMode: TextEdit.WrapAnywhere
                        color: enabled ? "#13232d" : "#78868d"
                        background: Rectangle {
                            color: commandEdit.enabled ? "#ffffff" : "#edf2f4"
                            border.color: commandEdit.activeFocus ? "#2388b8" : "#8f9ca3"
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    FieldLabel { text: app.trText("engineInitialCommands") }
                    Basic.TextField {
                        id: initialCommandEdit
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        enabled: engineListDialog.selectedPreset() !== null
                        placeholderText: app.trText("engineInitialCommandsPlaceholder")
                        selectByMouse: true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Label { text: app.trText("engineWidthShort"); color: "#52636d"; font.bold: true }
                    AppSpinBox {
                        id: widthSpin
                        from: app.minBoardSize
                        to: engineListDialog.currentEditorRuleMode() === app.gameRuleDotsAndBoxes
                            ? Math.floor((app.maxBoardSize - 1) / 2) : app.maxBoardSize
                        editable: true
                        enabled: engineListDialog.selectedPreset() !== null
                        font.bold: true
                        Layout.preferredWidth: 70
                    }

                    Label { text: app.trText("engineHeightShort"); color: "#52636d"; font.bold: true }
                    AppSpinBox {
                        id: heightSpin
                        from: app.minBoardSize
                        to: engineListDialog.currentEditorRuleMode() === app.gameRuleDotsAndBoxes
                            ? Math.floor((app.maxBoardSize - 1) / 2) : app.maxBoardSize
                        editable: true
                        enabled: engineListDialog.selectedPreset() !== null
                        font.bold: true
                        Layout.preferredWidth: 70
                    }

                    Label { text: app.trText("komi"); color: "#52636d"; font.bold: true }
                    AppSpinBox {
                        id: komiSpin
                        from: -Math.round(app.maxKomiMagnitude * 2)
                        to: Math.round(app.maxKomiMagnitude * 2)
                        editable: true
                        enabled: engineListDialog.selectedPreset() !== null
                        font.bold: true
                        Layout.preferredWidth: 116
                        validator: DoubleValidator {
                            bottom: -app.maxKomiMagnitude
                            top: app.maxKomiMagnitude
                            decimals: 1
                            notation: DoubleValidator.StandardNotation
                            locale: "C"
                        }
                        textFromValue: function(value) { return (value / 2).toFixed(1) }
                        valueFromText: function(text) {
                            var number = Number(text)
                            return isNaN(number) ? komiSpin.value : Math.round(number * 2)
                        }
                    }

                    AppCheckBox {
                        id: legacyHexCheck
                        enabled: engineListDialog.selectedPreset() !== null
                        text: app.trText("legacyHexEngineCoordinatesShort")
                    }

                    Item { Layout.fillWidth: true }

                    CompactButton {
                        text: app.trText("newEngine")
                        onClicked: engineListDialog.createPreset()
                    }

                    CompactButton {
                        text: app.trText("delete")
                        danger: true
                        enabled: engineListDialog.selectedPreset() !== null
                        onClicked: engineListDialog.deleteSelected()
                    }

                    CompactButton {
                        text: app.trText("save")
                        primary: true
                        enabled: engineListDialog.selectedPreset() !== null
                        onClicked: engineListDialog.saveSelected()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    FieldLabel { text: app.trText("mainRule") }
                    StyledComboBox {
                        id: ruleCombo
                        model: engineListDialog.editorRuleOptionsModel
                        textRole: "label"
                        enabled: engineListDialog.selectedPreset() !== null
                        Layout.preferredWidth: 340
                        Layout.minimumWidth: 280
                        Layout.maximumWidth: 420
                        onActivated: function(index) {
                            var option = engineListDialog.editorRuleOptionsModel[index]
                            if (!option)
                                return
                            if (option.value === app.gameRuleMoreOption) {
                                currentIndex = engineListDialog.editorRuleCurrentIndex()
                                engineListDialog.openEditorRuleSelectionPopup()
                            } else {
                                engineListDialog.setEditorRuleMode(option.value)
                            }
                        }
                    }

                    FieldLabel {
                        Layout.preferredWidth: 72
                        text: app.trText("ruleVariant")
                    }
                    AppButton {
                        id: variantButton
                        enabled: engineListDialog.selectedPreset() !== null
                        Layout.preferredWidth: 300
                        Layout.minimumWidth: 240
                        Layout.maximumWidth: 360
                        text: engineListDialog.editorRuleVariantText()
                        onClicked: engineListDialog.openEditorRuleDialog()
                    }

                    Item { Layout.fillWidth: true }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    CompactButton { text: app.trText("moveUp"); enabled: engineListDialog.selectedIndex > 0; onClicked: engineListDialog.moveSelected(-1) }
                    CompactButton { text: app.trText("moveDown"); enabled: engineListDialog.selectedIndex >= 0 && engineListDialog.selectedIndex < app.enginePresets.length - 1; onClicked: engineListDialog.moveSelected(1) }
                    CompactButton { text: app.trText("moveUp5"); enabled: engineListDialog.selectedIndex > 0; onClicked: engineListDialog.moveSelectedSteps(-1, 5) }
                    CompactButton { text: app.trText("moveDown5"); enabled: engineListDialog.selectedIndex >= 0 && engineListDialog.selectedIndex < app.enginePresets.length - 1; onClicked: engineListDialog.moveSelectedSteps(1, 5) }
                    CompactButton { text: app.trText("moveTop"); enabled: engineListDialog.selectedIndex > 0; onClicked: engineListDialog.moveSelectedTo(0) }
                    CompactButton { text: app.trText("moveBottom"); enabled: engineListDialog.selectedIndex >= 0 && engineListDialog.selectedIndex < app.enginePresets.length - 1; onClicked: engineListDialog.moveSelectedTo(app.enginePresets.length - 1) }

                    Item { Layout.fillWidth: true }

                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Label {
                        text: app.trText("engineDefaultEngine")
                        color: "#24313a"
                    }

                    StyledComboBox {
                        id: defaultEngineCombo
                        model: app.engineDefaultOptions()
                        currentIndex: app.engineDefaultCurrentIndex()
                        Layout.preferredWidth: 320
                        Layout.minimumWidth: 220
                        Layout.maximumWidth: 420
                        onActivated: function(index) { app.setDefaultEnginePresetFromIndex(index) }
                    }

                    CompactButton {
                        text: app.trText("engineSetAsDefault")
                        enabled: engineListDialog.selectedPreset() !== null
                        Layout.preferredWidth: Math.max(160, implicitWidth + 14)
                        onClicked: engineListDialog.setSelectedAsDefault()
                    }

                    Item { Layout.fillWidth: true }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Label {
                        text: app.trText("engineStartupAutoLoad")
                        color: "#24313a"
                    }

                    AppRadioChoice {
                        text: app.trText("engineStartupDefault")
                        checked: app.engineStartupMode === app.engineStartupDefault
                        onClicked: app.setEngineStartupMode(app.engineStartupDefault)
                    }

                    AppRadioChoice {
                        text: app.trText("engineStartupLast")
                        checked: app.engineStartupMode === app.engineStartupLast
                        onClicked: app.setEngineStartupMode(app.engineStartupLast)
                    }

                    AppRadioChoice {
                        text: app.trText("engineStartupManual")
                        checked: app.engineStartupMode === app.engineStartupManual
                        onClicked: app.setEngineStartupMode(app.engineStartupManual)
                    }

                    AppRadioChoice {
                        text: app.trText("engineStartupNone")
                        checked: app.engineStartupMode === app.engineStartupNone
                        onClicked: app.setEngineStartupMode(app.engineStartupNone)
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }

        Rectangle {
            id: tablePanel
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: engineListDialog.readOnlyMode ? 190 : 210
            color: "#ffffff"
            border.color: "#b9ccd6"

            Item {
                anchors.fill: parent
                anchors.margins: 1

                Rectangle {
                    id: tableHeader
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.rightMargin: engineListDialog.scrollBarHitThickness
                    anchors.top: parent.top
                    height: 34
                    color: "#e4eef4"

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        HeaderCell { text: app.trText("candidateIndex"); widthValue: 52 }
                        HeaderCell { text: app.trText("engineName"); widthValue: 200 }
                        HeaderCell { text: app.trText("engineCommand"); fill: true }
                        HeaderCell { text: app.trText("engineRule"); widthValue: engineListDialog.ruleColumnWidth }
                        HeaderCell { text: app.trText("engineWidthShort"); widthValue: 50; alignCenter: true }
                        HeaderCell { text: app.trText("engineHeightShort"); widthValue: 50; alignCenter: true }
                        HeaderCell { text: app.trText("komi"); widthValue: 58; alignCenter: true }
                        HeaderCell {
                            visible: !engineListDialog.readOnlyMode
                            text: app.trText("legacyHexEngineCoordinatesShort")
                            widthValue: engineListDialog.legacyHexColumnWidth
                            alignCenter: true
                        }
                    }
                }

                ListView {
                    id: engineListView
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: tableHeader.bottom
                    anchors.bottom: parent.bottom
                    clip: true
                    model: app.enginePresets ? app.enginePresets.length : 0
                    currentIndex: engineListDialog.selectedIndex

                    ScrollBar.vertical: AppScrollBar {
                        id: engineListScrollBar
                        policy: engineListView.contentHeight > engineListView.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                        hitThickness: engineListDialog.scrollBarHitThickness
                        minimumSize: Math.min(
                                         1,
                                         32 / Math.max(
                                             1,
                                             height - topPadding - bottomPadding))
                        hoverEnabled: true
                        interactive: true
                        z: 10
                    }

                    delegate: Rectangle {
                        id: rowItem
                        readonly property var preset: engineListDialog.presetAt(index)
                        readonly property bool selected: index === engineListDialog.selectedIndex
                        readonly property real nameColumnStart: 52
                        readonly property real nameColumnEnd: 252
                        readonly property real trailingColumnsWidth: 158 + engineListDialog.ruleColumnWidth
                                                                    + engineListDialog.legacyHexColumnWidth
                        readonly property real commandColumnStart: nameColumnEnd
                        readonly property real commandColumnEnd: Math.max(commandColumnStart, width - trailingColumnsWidth)
                        property string tooltipKey: ""

                        function tooltipTextAt(mouseX) {
                            if (!preset)
                                return ""
                            if (mouseX >= nameColumnStart && mouseX < nameColumnEnd)
                                return preset.name
                            if (mouseX >= commandColumnStart && mouseX < commandColumnEnd)
                                return preset.command
                            return ""
                        }

                        function updateTooltipCandidate() {
                            var nextText = tooltipTextAt(rowMouse.mouseX)
                            var nextKey = ""
                            if (nextText.length > 0) {
                                nextKey = index + ":"
                                          + (rowMouse.mouseX < commandColumnStart ? "name" : "command")
                            }
                            tooltipKey = nextKey
                            engineListDialog.scheduleListTooltip(rowItem, nextKey, nextText,
                                                                  rowMouse.mouseX, rowMouse.mouseY)
                        }

                        width: engineListView.width - engineListDialog.scrollBarHitThickness
                        height: 28
                        color: selected ? "#0078d7" : rowMouse.containsMouse ? "#e9f3f8" : "#ffffff"
                        border.color: selected ? "#0078d7" : "#d4dce2"

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            DataCell { text: String(index + 1); widthValue: 52; alignCenter: true; selected: rowItem.selected }
                            DataCell { text: rowItem.preset ? rowItem.preset.name : ""; widthValue: 200; selected: rowItem.selected }
                            DataCell { text: rowItem.preset ? rowItem.preset.command : ""; fill: true; selected: rowItem.selected }
                            DataCell { text: rowItem.preset ? app.enginePresetRuleDetailText(rowItem.preset) : ""; widthValue: engineListDialog.ruleColumnWidth; selected: rowItem.selected }
                            DataCell { text: rowItem.preset ? String(rowItem.preset.boardSizeX) : ""; widthValue: 50; alignCenter: true; selected: rowItem.selected }
                            DataCell { text: rowItem.preset ? String(rowItem.preset.boardSizeY) : ""; widthValue: 50; alignCenter: true; selected: rowItem.selected }
                            DataCell { text: rowItem.preset ? Number(rowItem.preset.komi).toFixed(1) : ""; widthValue: 58; alignCenter: true; selected: rowItem.selected }
                            DataCell {
                                visible: !engineListDialog.readOnlyMode
                                text: rowItem.preset && rowItem.preset.legacyHexEngineCoordinates ? app.trText("yes") : app.trText("no")
                                widthValue: engineListDialog.legacyHexColumnWidth
                                alignCenter: true
                                selected: rowItem.selected
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton
                            onEntered: rowItem.updateTooltipCandidate()
                            onExited: {
                                engineListDialog.hideListTooltip(rowItem.tooltipKey)
                                rowItem.tooltipKey = ""
                            }
                            onPositionChanged: rowItem.updateTooltipCandidate()
                            onClicked: {
                                engineListDialog.requestSelectIndex(index)
                            }
                            onDoubleClicked: {
                                if (engineListDialog.readOnlyMode)
                                    engineListDialog.requestLoadIndex(index)
                                else
                                    engineListDialog.requestSelectIndex(index)
                            }
                        }
                    }
                }
            }
        }
        }
    }

    dialogFooter: AppDialogFooter {
        implicitHeight: 58
        contentMargins: 10

        Item { Layout.fillWidth: true }

        SavePromptButton {
            visible: engineListDialog.readOnlyMode
            text: app.trText("loadSelectedEngine")
            primary: true
            enabled: engineListDialog.selectedPreset() !== null
            Layout.preferredWidth: 144
            onClicked: engineListDialog.requestLoadSelected()
        }

        SavePromptButton {
            visible: engineListDialog.startupMode
            text: app.trText("engineNoEngineMode")
            Layout.preferredWidth: 122
            onClicked: engineListDialog.chooseNoEngineMode()
        }

        SavePromptButton {
            text: app.trText("close")
            visible: !engineListDialog.startupMode
            Layout.preferredWidth: 86
            onClicked: engineListDialog.readOnlyMode
                       ? engineListDialog.closeWithoutPrompt()
                       : engineListDialog.requestClose()
        }
    }

    Popup {
        id: sharedListTooltip
        parent: dialogContent
        visible: engineListDialog.listTooltipReady && engineListDialog.listTooltipText.length > 0
        closePolicy: Popup.NoAutoClose
        padding: 6
        x: Math.max(8, Math.min(engineListDialog.listTooltipX,
                                dialogContent.width - width - 8))
        y: Math.max(8, Math.min(engineListDialog.listTooltipY,
                                dialogContent.height - height - 8))

        contentItem: Text {
            text: engineListDialog.listTooltipText
            color: "#102532"
            font.pixelSize: 13
            wrapMode: Text.WrapAnywhere
            width: Math.min(720, Math.max(180, implicitWidth))
        }

        background: Rectangle {
            radius: 4
            color: "#fffff4"
            border.color: "#8fa5b0"
        }
    }

    AppDialog {
        id: unsavedEngineDialog

        property bool explicitClose: false

        parent: engineListDialog.contentItem
        app: engineListDialog.app
        centerTarget: engineListDialog.contentItem
        owningWindow: engineListDialog.hostWindow
        modal: true
        title: app.trText("unsavedEngineTitle")
        closePolicy: Popup.CloseOnEscape
        preferredWidth: Math.max(380, Math.min(480, engineListDialog.width - 80))
        dialogMinimumWidth: Math.min(380, preferredWidth)
        dialogMinimumHeight: Math.min(220, preferredHeight)

        onOpened: explicitClose = false
        onClosed: {
            if (explicitClose) {
                explicitClose = false
                return
            }
            engineListDialog.pendingUnsavedAction = null
        }

        contentItem: Rectangle {
            implicitWidth: 440
            implicitHeight: Math.max(72, unsavedEngineMessage.implicitHeight + 24)
            color: "#f8fbfd"

            Label {
                id: unsavedEngineMessage
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 2
                anchors.rightMargin: 2
                text: app.trText("confirmSaveEngineSettings")
                color: "#17212a"
                wrapMode: Text.WordWrap
                font.pixelSize: 15
                lineHeight: 1.12
            }
        }

        footer: AppDialogFooter {
            tone: unsavedEngineDialog.tone
            Item { Layout.fillWidth: true }

            SavePromptButton {
                text: app.trText("save")
                primary: true
                onClicked: {
                    unsavedEngineDialog.explicitClose = true
                    unsavedEngineDialog.close()
                    engineListDialog.runPendingUnsavedAction(true)
                }
            }

            SavePromptButton {
                text: app.trText("dontSave")
                onClicked: {
                    unsavedEngineDialog.explicitClose = true
                    unsavedEngineDialog.close()
                    engineListDialog.runPendingUnsavedAction(false)
                }
            }

            SavePromptButton {
                text: app.trText("cancel")
                onClicked: {
                    engineListDialog.pendingUnsavedAction = null
                    unsavedEngineDialog.close()
                }
            }
        }
    }

    AppDialog {
        id: confirmDeleteEngineDialog

        parent: engineListDialog.contentItem
        app: engineListDialog.app
        centerTarget: engineListDialog.contentItem
        owningWindow: engineListDialog.hostWindow
        modal: true
        tone: "warning"
        title: app.trText("confirmDeleteEngineTitle")
        closePolicy: Popup.CloseOnEscape
        preferredWidth: Math.max(360, Math.min(460, engineListDialog.width - 80))
        dialogMinimumWidth: Math.min(360, preferredWidth)
        dialogMinimumHeight: Math.min(210, preferredHeight)

        contentItem: Rectangle {
            implicitWidth: 420
            implicitHeight: Math.max(76, confirmDeleteEngineMessage.implicitHeight + 24)
            color: "transparent"

            Label {
                id: confirmDeleteEngineMessage
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 2
                anchors.rightMargin: 2
                text: app.trText("confirmDeleteEngineMessage")
                         .replace("%1", engineListDialog.selectedPreset()
                                  ? engineListDialog.selectedPreset().name : "")
                color: "#17212a"
                wrapMode: Text.WordWrap
                font.pixelSize: 15
                lineHeight: 1.12
            }
        }

        footer: AppDialogFooter {
            tone: confirmDeleteEngineDialog.tone
            Item { Layout.fillWidth: true }

            SavePromptButton {
                text: app.trText("cancel")
                onClicked: confirmDeleteEngineDialog.close()
            }

            SavePromptButton {
                text: app.trText("delete")
                danger: true
                onClicked: {
                    confirmDeleteEngineDialog.close()
                    engineListDialog.deleteSelectedNow()
                }
            }
        }
    }

    GoRuleDialog {
        id: engineGoRuleDialog
        parent: engineListDialog.contentItem
        app: engineListDialog.app
        centerTarget: engineListDialog.contentItem
        owningWindow: engineListDialog.hostWindow
        onRulesAccepted: function(scoringRule, koRule, suicideAllowed,
                                  taxRule, handicapBonus, buttonRule) {
            engineListDialog.setEditorGoRules(scoringRule, koRule, suicideAllowed,
                                              taxRule, handicapBonus, buttonRule)
        }
    }

    GomokuRuleDialog {
        id: engineGomokuRuleDialog
        parent: engineListDialog.contentItem
        app: engineListDialog.app
        centerTarget: engineListDialog.contentItem
        owningWindow: engineListDialog.hostWindow
        onRulesAccepted: function(ruleMode, maxMoves, vcnRule, firstPassWin) {
            engineListDialog.setEditorGomokuRules(ruleMode, maxMoves, vcnRule, firstPassWin)
        }
    }

    NoRuleVariantDialog {
        id: engineNoRuleVariantDialog
        parent: engineListDialog.contentItem
        app: engineListDialog.app
        centerTarget: engineListDialog.contentItem
        owningWindow: engineListDialog.hostWindow
    }

    AppPopup {
        id: engineRuleSelectionPopup

        parent: engineListDialog.contentItem
        readonly property int treeDepthStep: app.compactLayout ? 20 : 24
        readonly property int treeNodeCenter: app.compactLayout ? 22 : 26
        readonly property int treeTextGap: app.compactLayout ? 22 : 26

        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: Math.min(620, engineListDialog.width - 70)
        height: Math.min(520, engineListDialog.height - 90)
        x: Math.round((engineListDialog.width - width) / 2)
        y: Math.round((engineListDialog.height - height) / 2)
        padding: 0

        background: Rectangle {
            radius: 8
            color: "#f8fbfd"
            border.color: "#9fb3bf"
            border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                color: "#e6eff4"
                radius: 8

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: parent.radius
                    color: parent.color
                }

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 18
                    text: app.trText("ruleSelectionMenu")
                    color: "#14242e"
                    font.pixelSize: app.compactLayout ? 16 : 18
                    font.bold: true
                }
            }

            Flickable {
                id: engineRuleSelectionFlick
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: engineRuleSelectionColumn.implicitHeight + 20
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: AppScrollBar {
                    policy: engineRuleSelectionFlick.contentHeight > engineRuleSelectionFlick.height
                            ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                }

                ColumnLayout {
                    id: engineRuleSelectionColumn
                    x: 10
                    y: 10
                    width: engineRuleSelectionFlick.width - 28
                    spacing: 4

                    Repeater {
                        model: app.ruleTreeRows(engineListDialog.engineRuleCollapsedGroups)

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: app.compactLayout ? 34 : 38
                            radius: 5
                            color: modelData.type === "leaf" && modelData.value === engineListDialog.editorRuleMode ? "#dcecf3"
                                  : engineRuleMouse.containsMouse ? "#eef6fa"
                                  : modelData.type === "group" ? "#f2f7fa" : "#ffffff"
                            border.color: modelData.type === "group" ? "#c6d6df" : "#e1e8ed"
                            border.width: 1
                            ToolTip.visible: engineRuleMouse.containsMouse
                                             && modelData.type === "leaf"
                                             && modelData.tip.length > 0
                            ToolTip.text: modelData.tip
                            ToolTip.delay: 250
                            ToolTip.timeout: 8000

                            Item {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10

                                Repeater {
                                    model: Math.max(0, modelData.depth)

                                    Rectangle {
                                        x: engineRuleSelectionPopup.treeNodeCenter
                                           + index * engineRuleSelectionPopup.treeDepthStep
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: 1
                                        color: "#cbd9e1"
                                    }
                                }

                                Rectangle {
                                    visible: modelData.depth > 0
                                    x: engineRuleSelectionPopup.treeNodeCenter
                                       + (modelData.depth - 1) * engineRuleSelectionPopup.treeDepthStep
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: engineRuleSelectionPopup.treeDepthStep
                                    height: 1
                                    color: "#cbd9e1"
                                }

                                Text {
                                    visible: modelData.type === "group"
                                    x: engineRuleSelectionPopup.treeNodeCenter
                                       + Math.max(0, modelData.depth) * engineRuleSelectionPopup.treeDepthStep
                                       - width / 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.collapsed ? "\u25b6" : "\u25be"
                                    color: "#38505c"
                                    font.pixelSize: app.compactLayout ? 17 : 19
                                    font.bold: true
                                }

                                AppCheckMark {
                                    visible: modelData.type === "leaf"
                                             && modelData.value === engineListDialog.editorRuleMode
                                    width: app.compactLayout ? 16 : 18
                                    height: width
                                    x: engineRuleSelectionPopup.treeNodeCenter
                                       + Math.max(0, modelData.depth) * engineRuleSelectionPopup.treeDepthStep
                                       - width / 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    checked: true
                                    markColor: "#1678bd"
                                    lineWidth: app.compactLayout ? 2.3 : 2.6
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: engineRuleSelectionPopup.treeNodeCenter
                                                        + Math.max(0, modelData.depth) * engineRuleSelectionPopup.treeDepthStep
                                                        + engineRuleSelectionPopup.treeTextGap
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label
                                    color: modelData.type === "leaf" && !app.ruleModeAllowedForPackage(modelData.value)
                                           ? "#8a969d" : "#14242e"
                                    font.pixelSize: modelData.type === "group"
                                                    ? (app.compactLayout ? 14 : 16)
                                                    : (app.compactLayout ? 13 : 15)
                                    font.bold: modelData.type === "group"
                                               || (modelData.type === "leaf"
                                                   && modelData.value === engineListDialog.editorRuleMode)
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            MouseArea {
                                id: engineRuleMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: modelData.type === "group"
                                         || app.ruleModeAllowedForPackage(modelData.value)
                                onClicked: {
                                    if (modelData.type === "group") {
                                        engineListDialog.setEngineRuleGroupCollapsed(modelData.groupId, !modelData.collapsed)
                                    } else {
                                        engineListDialog.setEditorRuleMode(modelData.value)
                                        engineRuleSelectionPopup.close()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                color: "#eef4f7"
                border.color: "#d3e0e7"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10

                    Item { Layout.fillWidth: true }

                    SavePromptButton {
                        text: app.trText("cancel")
                        onClicked: engineRuleSelectionPopup.close()
                    }
                }
            }
        }
    }

    component FieldLabel: Label {
        Layout.preferredWidth: 86
        color: "#52636d"
        verticalAlignment: Text.AlignVCenter
    }

    component CompactButton: SavePromptButton {
        Layout.preferredWidth: Math.max(70, implicitWidth + 10)
        Layout.preferredHeight: 32
    }

    component StyledComboBox: AppComboBox {
        id: combo

        textRole: "label"
        valueRole: "value"
        implicitHeight: 34
    }

    component HeaderCell: Item {
        property string text: ""
        property real widthValue: 80
        property bool fill: false
        property bool alignCenter: false

        Layout.preferredWidth: widthValue
        Layout.fillWidth: fill
        Layout.fillHeight: true

        Rectangle {
            anchors.fill: parent
            color: "#e4eef4"
            border.color: "#c0d0d9"
        }

        Text {
            anchors.fill: parent
            anchors.leftMargin: alignCenter ? 2 : 8
            anchors.rightMargin: alignCenter ? 2 : 8
            text: parent.text
            color: "#102532"
            font.pixelSize: 13
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: alignCenter ? Text.AlignHCenter : Text.AlignLeft
            elide: Text.ElideRight
        }
    }

    component DataCell: Item {
        id: dataCell
        property string text: ""
        property real widthValue: 80
        property bool fill: false
        property bool alignCenter: false
        property bool selected: false

        Layout.preferredWidth: widthValue
        Layout.fillWidth: fill
        Layout.fillHeight: true

        Text {
            anchors.fill: parent
            anchors.leftMargin: alignCenter ? 2 : 8
            anchors.rightMargin: alignCenter ? 2 : 8
            text: parent.text
            color: parent.selected ? "#ffffff" : "#1c2d36"
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: alignCenter ? Text.AlignHCenter : Text.AlignLeft
            elide: Text.ElideRight
        }
    }
}
