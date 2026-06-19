import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import "EnginePresets.js" as EnginePresets

Basic.Dialog {
    id: engineListDialog

    required property var app
    required property var controller
    property bool startupMode: false
    property bool pickerMode: false
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
    readonly property bool readOnlyMode: startupMode || pickerMode
    readonly property real legacyHexColumnWidth: readOnlyMode ? 0 : 82
    readonly property real ruleColumnWidth: readOnlyMode ? 150 : 164

    modal: true
    title: readOnlyMode ? app.trText("loadEngineTitle") : app.trText("engineSettingsTitle")
    closePolicy: Popup.NoAutoClose
    padding: 8
    width: Math.min(1180, app.width - 36)
    height: readOnlyMode ? Math.min(430, app.height - 80)
                         : Math.min(820, app.height - 36)
    x: Math.round((app.width - width) / 2)
    y: Math.round((app.height - height) / 2)

    function ensureSelection() {
        if (!app.enginePresets || app.enginePresets.length <= 0) {
            selectedIndex = -1
            return
        }
        if (selectedIndex < 0 || selectedIndex >= app.enginePresets.length)
            selectedIndex = 0
    }

    function openStartup() {
        startupMode = true
        pickerMode = false
        selectedIndex = app.enginePresets.length > 0 ? 0 : -1
        syncEditor()
        open()
    }

    function openPicker() {
        startupMode = false
        pickerMode = true
        var activeIndex = app.enginePresetIndexById(app.activeEngineId)
        selectedIndex = activeIndex >= 0 ? activeIndex : (app.enginePresets.length > 0 ? 0 : -1)
        syncEditor()
        open()
    }

    function openManage() {
        startupMode = false
        pickerMode = false
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
        editorRuleMode = mode
        refreshEditorRuleOptions()
        ruleCombo.currentIndex = editorRuleCurrentIndex()
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

    function closeWithoutPrompt() {
        pendingUnsavedAction = null
        close()
    }

    function requestClose() {
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
        confirmUnsavedOrRun(function() { engineListDialog.deleteSelectedNow() })
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
        hideListTooltip("")
        pendingUnsavedAction = null
        app.focusBoardInput()
    }

    background: Rectangle {
        color: "#f6fafc"
        border.color: "#8ea5b1"
    }

    header: Rectangle {
        height: 42
        color: "#e4eef4"

        Label {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            text: engineListDialog.title
            color: "#102532"
            font.pixelSize: 18
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    contentItem: ColumnLayout {
        id: dialogContent

        implicitWidth: 1160
        implicitHeight: 720
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
            Layout.preferredHeight: 440
            color: "#f6fafc"

            ColumnLayout {
                anchors.fill: parent
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
                        enabled: engineListDialog.selectedPreset() !== null
                        placeholderText: app.trText("engineInitialCommandsPlaceholder")
                        selectByMouse: true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Label { text: app.trText("engineWidthShort"); color: "#52636d" }
                    SpinBox {
                        id: widthSpin
                        from: app.minBoardSize
                        to: app.maxBoardSize
                        editable: true
                        enabled: engineListDialog.selectedPreset() !== null
                        Layout.preferredWidth: 70
                    }

                    Label { text: app.trText("engineHeightShort"); color: "#52636d" }
                    SpinBox {
                        id: heightSpin
                        from: app.minBoardSize
                        to: app.maxBoardSize
                        editable: true
                        enabled: engineListDialog.selectedPreset() !== null
                        Layout.preferredWidth: 70
                    }

                    Label { text: app.trText("komi"); color: "#52636d" }
                    SpinBox {
                        id: komiSpin
                        from: -Math.round(app.maxKomiMagnitude * 2)
                        to: Math.round(app.maxKomiMagnitude * 2)
                        editable: true
                        enabled: engineListDialog.selectedPreset() !== null
                        Layout.preferredWidth: 116
                        textFromValue: function(value) { return (value / 2).toFixed(1) }
                        valueFromText: function(text) { return Math.round(Number(text) * 2) }
                    }

                    CheckBox {
                        id: legacyHexCheck
                        enabled: engineListDialog.selectedPreset() !== null
                        text: app.trText("legacyHexEngineCoordinatesShort")
                    }

                    Item { Layout.fillWidth: true }
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
                    Basic.Button {
                        id: variantButton
                        enabled: engineListDialog.selectedPreset() !== null
                        Layout.preferredWidth: 300
                        Layout.minimumWidth: 240
                        implicitHeight: 34
                        text: engineListDialog.editorRuleVariantText()
                        onClicked: engineListDialog.openEditorRuleDialog()

                        contentItem: Text {
                            text: variantButton.text
                            color: variantButton.enabled ? "#102532" : "#7a8b94"
                            font.pixelSize: 14
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        background: Rectangle {
                            radius: 5
                            color: !variantButton.enabled ? "#eef3f6"
                                  : variantButton.pressed ? "#dcecf3"
                                  : variantButton.hovered ? "#eef7fa" : "#f8fbfd"
                            border.color: variantButton.activeFocus ? "#2a91c9" : "#a8bac5"
                            border.width: variantButton.activeFocus ? 2 : 1
                        }
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

                    CompactButton { text: app.trText("newEngine"); onClicked: engineListDialog.createPreset() }
                    CompactButton { text: app.trText("delete"); enabled: engineListDialog.selectedPreset() !== null; onClicked: engineListDialog.deleteSelected() }
                    CompactButton { text: app.trText("save"); enabled: engineListDialog.selectedPreset() !== null; primary: true; onClicked: engineListDialog.saveSelected() }
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
                        Layout.preferredWidth: 280
                        Layout.minimumWidth: 220
                        onActivated: function(index) { app.setDefaultEnginePresetFromIndex(index) }
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

                    RadioButton {
                        text: app.trText("engineStartupDefault")
                        checked: app.engineStartupMode === app.engineStartupDefault
                        onClicked: app.setEngineStartupMode(app.engineStartupDefault)
                    }

                    RadioButton {
                        text: app.trText("engineStartupLast")
                        checked: app.engineStartupMode === app.engineStartupLast
                        onClicked: app.setEngineStartupMode(app.engineStartupLast)
                    }

                    RadioButton {
                        text: app.trText("engineStartupManual")
                        checked: app.engineStartupMode === app.engineStartupManual
                        onClicked: app.setEngineStartupMode(app.engineStartupManual)
                    }

                    RadioButton {
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
                        policy: engineListView.contentHeight > engineListView.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
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

                        width: engineListView.width
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

    footer: Rectangle {
        implicitHeight: 58
        color: "#f6fafc"

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: "#d7e1e7"
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

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

    Basic.Dialog {
        id: unsavedEngineDialog

        modal: true
        title: app.trText("unsavedEngineTitle")
        closePolicy: Popup.CloseOnEscape
        padding: 18
        width: Math.max(380, Math.min(480, engineListDialog.width - 80))
        x: Math.round((engineListDialog.width - width) / 2)
        y: Math.round((engineListDialog.height - height) / 2)

        background: Rectangle {
            radius: 10
            color: "#f8fbfd"
            border.color: "#8ea5b1"
            border.width: 1
        }

        header: Rectangle {
            height: 52
            color: "#e6eff4"
            radius: 10

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.radius
                color: parent.color
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: "#c5d4dc"
            }

            Label {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                text: unsavedEngineDialog.title
                color: "#14242e"
                font.pixelSize: 17
                font.bold: true
                elide: Text.ElideRight
            }
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

        footer: Rectangle {
            implicitHeight: 68
            color: "#f8fbfd"
            radius: 10

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 1
                color: "#d7e1e7"
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: parent.radius
                color: parent.color
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 10

                Item { Layout.fillWidth: true }

                SavePromptButton {
                    text: app.trText("save")
                    primary: true
                    onClicked: {
                        unsavedEngineDialog.close()
                        engineListDialog.runPendingUnsavedAction(true)
                    }
                }

                SavePromptButton {
                    text: app.trText("dontSave")
                    onClicked: {
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
    }

    GoRuleDialog {
        id: engineGoRuleDialog
        app: engineListDialog.app
        onRulesAccepted: function(scoringRule, koRule, suicideAllowed,
                                  taxRule, handicapBonus, buttonRule) {
            engineListDialog.setEditorGoRules(scoringRule, koRule, suicideAllowed,
                                              taxRule, handicapBonus, buttonRule)
        }
    }

    GomokuRuleDialog {
        id: engineGomokuRuleDialog
        app: engineListDialog.app
        onRulesAccepted: function(ruleMode, maxMoves, vcnRule, firstPassWin) {
            engineListDialog.setEditorGomokuRules(ruleMode, maxMoves, vcnRule, firstPassWin)
        }
    }

    NoRuleVariantDialog {
        id: engineNoRuleVariantDialog
        app: engineListDialog.app
    }

    Basic.Popup {
        id: engineRuleSelectionPopup

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

                                Text {
                                    visible: modelData.type === "leaf"
                                    x: engineRuleSelectionPopup.treeNodeCenter
                                       + Math.max(0, modelData.depth) * engineRuleSelectionPopup.treeDepthStep
                                       - width / 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.value === engineListDialog.editorRuleMode ? "\u2713" : ""
                                    color: "#1678bd"
                                    font.pixelSize: app.compactLayout ? 16 : 18
                                    font.bold: true
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

    component StyledComboBox: Basic.ComboBox {
        id: combo

        textRole: "label"
        valueRole: "value"
        implicitHeight: 34

        contentItem: Text {
            leftPadding: 12
            rightPadding: 28
            text: combo.displayText
            color: combo.enabled ? "#102532" : "#7a8b94"
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        indicator: Text {
            x: combo.width - width - 8
            y: Math.round((combo.height - height) / 2)
            text: "\u25BE"
            color: combo.enabled ? "#657883" : "#9aa8af"
            font.pixelSize: 13
        }

        background: Rectangle {
            radius: 3
            color: combo.enabled ? "#ffffff" : "#eef3f6"
            border.color: combo.activeFocus ? "#2a91c9" : "#aebdc6"
            border.width: combo.activeFocus ? 2 : 1
        }

        delegate: Basic.ItemDelegate {
            width: combo.width
            height: 36
            highlighted: combo.highlightedIndex === index

            contentItem: Text {
                text: modelData && modelData[combo.textRole] !== undefined
                      ? modelData[combo.textRole]
                      : (modelData && modelData.label !== undefined ? modelData.label : String(modelData))
                color: "#102532"
                font.pixelSize: 14
                font.bold: highlighted
                verticalAlignment: Text.AlignVCenter
                leftPadding: 12
                elide: Text.ElideRight
            }

            background: Rectangle {
                color: highlighted ? "#d8e9f1" : "#ffffff"
                border.color: highlighted ? "#9abaca" : "#eef3f6"
            }
        }
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
