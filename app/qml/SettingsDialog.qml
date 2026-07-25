import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

AppWindowDialog {
    id: settingsDialog

    required property var controller
    property int currentPage: 0

    modal: true
    title: app.trText("settingsDialogTitle")
    closePolicy: Popup.CloseOnEscape
    preferredWidth: boundedPreferredWidth(820, 70)
    preferredHeight: boundedPreferredHeight(680, 70)
    dialogMinimumWidth: Math.min(720, preferredWidth)
    dialogMinimumHeight: Math.min(520, preferredHeight)

    function openPage(pageIndex) {
        currentPage = app.clamp(Math.round(pageIndex), 0, 3)
        syncFields()
        open()
    }

    function syncFields() {
        boardXSpin.value = app.logicalBoardDimensionForRule(app.gameRuleMode, app.boardSizeX)
        boardYSpin.value = app.logicalBoardDimensionForRule(app.gameRuleMode, app.boardSizeY)
        backgroundColorField.text = colorToText(app.backgroundColor)
        boardColorField.text = colorToText(app.boardWoodColor)
        candidateFirstTextColorField.text = colorToText(app.candidateFirstLabelTextColor)
        candidateTextColorField.text = colorToText(app.candidateLabelTextColor)
    }

    function chooseBoardPreset(size) {
        boardXSpin.value = size
        boardYSpin.value = size
    }

    function applyBoardSize() {
        return app.requestBoardDimensionsChange(
                    app.internalBoardDimensionForRule(app.gameRuleMode, boardXSpin.value),
                    app.internalBoardDimensionForRule(app.gameRuleMode, boardYSpin.value))
    }

    function colorToText(colorValue) {
        var text = String(colorValue)
        if (text.length === 9 && text[0] === "#" && text.slice(1, 3).toLowerCase() === "ff")
            return "#" + text.slice(3)
        return text
    }

    function applyColorText(field, setter, fallback) {
        var text = field.text.trim()
        if (/^#[0-9a-fA-F]{6}$/.test(text))
            setter(text)
        field.text = colorToText(fallback())
    }

    onOpened: syncFields()
    onClosed: {
        if (!app.applicationShutdownPrepared) {
            applyBoardSize()
            app.onSettingsDialogClosed()
            app.focusBoardInput()
        }
    }

    dialogBody: RowLayout {
        implicitWidth: 780
        implicitHeight: 570
        spacing: 14

        Rectangle {
            Layout.preferredWidth: 136
            Layout.fillHeight: true
            radius: 6
            color: "#e7eef3"
            border.color: "#c7d4dc"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                PageButton { page: 0; text: app.trText("settingsPageBasic") }
                PageButton { page: 1; text: app.trText("settingsPageRules") }
                PageButton { page: 2; text: app.trText("settingsPageVisual") }
                PageButton { page: 3; text: app.trText("settingsPageEngine") }
                Item { Layout.fillHeight: true }
            }
        }

        Flickable {
            id: pageFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: pageColumn.implicitHeight

            ScrollBar.vertical: AppScrollBar {
                policy: pageFlick.contentHeight > pageFlick.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
            }

            ColumnLayout {
                id: pageColumn
                width: pageFlick.width
                spacing: 14

                SectionBox {
                    visible: settingsDialog.currentPage === 0
                    title: app.trText("boardSize")

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: app.boardSizePresets()
                                SmallModeButton {
                                    text: modelData + "x" + modelData
                                    visible: app.boardSizePresetAllowed(modelData)
                                    selected: boardXSpin.value === modelData && boardYSpin.value === modelData
                                    onClicked: settingsDialog.chooseBoardPreset(modelData)
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label { text: app.trText("boardSizeX"); color: "#24313a" }

                            AppSpinBox {
                                id: boardXSpin
                                from: app.minBoardSize
                                to: app.gameRuleMode === app.gameRuleDotsAndBoxes
                                    ? Math.floor((app.maxBoardSize - 1) / 2) : app.maxBoardSize
                                enabled: app.customBoardSizeAllowed()
                                editable: true
                                Layout.preferredWidth: 84
                            }

                            Label { text: "x " + app.trText("boardSizeY"); color: "#24313a" }

                            AppSpinBox {
                                id: boardYSpin
                                from: app.minBoardSize
                                to: app.gameRuleMode === app.gameRuleDotsAndBoxes
                                    ? Math.floor((app.maxBoardSize - 1) / 2) : app.maxBoardSize
                                enabled: app.customBoardSizeAllowed()
                                editable: true
                                Layout.preferredWidth: 84
                            }

                            Item { Layout.fillWidth: true }

                            SavePromptButton {
                                text: app.trText("apply")
                                primary: true
                                onClicked: settingsDialog.applyBoardSize()
                            }
                        }
                    }
                }

                RuleSettingsPage {
                    visible: settingsDialog.currentPage === 1
                    app: settingsDialog.app
                    Layout.fillWidth: true
                }

                SectionBox {
                    visible: settingsDialog.currentPage === 0
                    title: app.trText("basicGameSettings")

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: app.trText("stoneColor")
                                color: "#24313a"
                                Layout.preferredWidth: 100
                            }

                            SmallModeButton {
                                text: app.trText("stoneColorAuto")
                                selected: app.stoneColorMode === app.stoneColorModeAuto
                                onClicked: app.setStoneColorMode(app.stoneColorModeAuto)
                            }

                            SmallModeButton {
                                text: app.trText("stoneColorBlack")
                                selected: app.stoneColorMode === app.stoneColorModeBlack
                                onClicked: app.setStoneColorMode(app.stoneColorModeBlack)
                            }

                            SmallModeButton {
                                text: app.trText("stoneColorWhite")
                                selected: app.stoneColorMode === app.stoneColorModeWhite
                                onClicked: app.setStoneColorMode(app.stoneColorModeWhite)
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: app.trText("analysisIntervalCentiseconds")
                                color: "#24313a"
                                Layout.preferredWidth: 240
                            }

                            AppSpinBox {
                                from: 1
                                to: app.maxLargeIntegerSetting
                                editable: true
                                value: app.analysisIntervalCentiseconds
                                Layout.preferredWidth: 130
                                onValueModified: app.analysisIntervalCentiseconds = value
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: app.trText("maxAnalysisSeconds")
                                color: "#24313a"
                                Layout.preferredWidth: 240
                            }

                            AppSpinBox {
                                from: 0
                                to: app.maxLargeIntegerSetting
                                editable: true
                                value: app.maxAnalysisSeconds
                                Layout.preferredWidth: 130
                                onValueModified: app.maxAnalysisSeconds = value
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                id: variationPreviewVisibleLabel
                                text: app.trText("candidateVariationPreviewVisible")
                                color: "#24313a"
                                Layout.preferredWidth: variationPreviewVisibleLabel.implicitWidth
                                elide: Text.ElideRight
                            }

                            AppCheckBox {
                                checked: app.candidateVariationPreviewVisible
                                onToggled: app.candidateVariationPreviewVisible = checked
                            }

                            Label {
                                text: app.trText("candidateVariationPreviewMaxMoves")
                                color: "#52636d"
                                font.pixelSize: 12
                            }

                            AppSpinBox {
                                from: 0
                                to: app.maxLargeIntegerSetting
                                editable: true
                                value: app.candidateVariationPreviewMaxMoves
                                Layout.preferredWidth: 104
                                onValueModified: app.candidateVariationPreviewMaxMoves = value
                            }

                            Label {
                                text: app.trText("candidateCountUnlimitedTip")
                                color: "#52636d"
                                font.pixelSize: 12
                            }

                            Item { Layout.fillWidth: true }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                id: variationPreviewOpacityLabel
                                text: app.trText("candidateVariationPreviewOpacity")
                                color: "#24313a"
                                Layout.preferredWidth: variationPreviewOpacityLabel.implicitWidth + 8
                                elide: Text.ElideRight
                            }

                            AppSpinBox {
                                from: 0
                                to: 100
                                editable: true
                                value: Math.round(app.candidateVariationPreviewOpacity * 100)
                                Layout.preferredWidth: 104
                                onValueModified: app.candidateVariationPreviewOpacity = value / 100
                            }

                            Label {
                                text: "%"
                                color: "#52636d"
                                font.pixelSize: 14
                            }

                            Item { Layout.fillWidth: true }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: app.trText("candidateDisplayCount")
                                color: "#24313a"
                                Layout.preferredWidth: 150
                            }

                            AppSpinBox {
                                from: 0
                                to: 65536
                                editable: true
                                value: app.candidateDisplayCount
                                Layout.preferredWidth: 116
                                onValueModified: app.candidateDisplayCount = value
                            }

                            Label {
                                text: app.trText("candidateCountUnlimitedTip")
                                color: "#52636d"
                                font.pixelSize: 12
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: app.trText("candidateMinVisitRatio")
                                color: "#24313a"
                                Layout.preferredWidth: 150
                            }

                            AppSpinBox {
                                from: 0
                                to: 1000
                                editable: true
                                value: Math.round(app.candidateMinVisitRatio * 1000)
                                Layout.preferredWidth: 96
                                textFromValue: function(value) {
                                    var percent = value / 10
                                    return value % 10 === 0 ? percent.toFixed(0) : percent.toFixed(1)
                                }
                                valueFromText: function(text) {
                                    var parsed = Number(String(text).replace("%", ""))
                                    return isNaN(parsed) ? 0 : Math.round(parsed * 10)
                                }
                                onValueModified: app.candidateMinVisitRatio = value / 1000
                            }

                            Label {
                                text: "%"
                                color: "#52636d"
                                font.pixelSize: 14
                            }

                            Item { Layout.fillWidth: true }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: app.trText("candidateShowFilteredMarkers")
                                color: "#24313a"
                                Layout.preferredWidth: 230
                                elide: Text.ElideRight
                            }

                            AppCheckBox {
                                checked: app.candidateShowFilteredMarkers
                                onToggled: app.candidateShowFilteredMarkers = checked
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }
                }

                SectionBox {
                    visible: settingsDialog.currentPage === 0
                    title: app.trText("gamePlaySettings")

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: app.trText("secondsPerMove")
                                color: "#24313a"
                                Layout.preferredWidth: 120
                            }

                            AppSpinBox {
                                from: 1
                                to: 999
                                value: Math.round(app.secondsPerMove * 10)
                                editable: true
                                Layout.preferredWidth: 110
                                textFromValue: function(value) { return (value / 10).toFixed(1) }
                                valueFromText: function(text) { return Math.round(Number(text) * 10) }
                                onValueModified: app.secondsPerMove = value / 10
                            }

                            Label {
                                text: app.trText("secondsUnit")
                                color: "#52636d"
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: app.trText("resignSettings")
                                color: "#24313a"
                                Layout.preferredWidth: 120
                            }

                            Label { text: app.trText("resignAfterMove"); color: "#52636d" }
                            AppSpinBox {
                                from: 1
                                to: 500
                                value: app.resignMinMove
                                Layout.preferredWidth: 82
                                onValueModified: app.resignMinMove = value
                            }

                            Label { text: app.trText("resignBelowWinrate"); color: "#52636d" }
                            AppSpinBox {
                                from: 0
                                to: 100
                                value: Math.round(app.resignWinrateThreshold)
                                Layout.preferredWidth: 82
                                onValueModified: app.resignWinrateThreshold = value
                            }
                        }
                    }
                }

                SectionBox {
                    visible: settingsDialog.currentPage === 2
                    title: app.trText("candidateSettings")

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Item {
                                Layout.preferredWidth: 88
                                Layout.preferredHeight: 178

                                CandidateMarkerView {
                                    x: 4
                                    y: 0
                                    width: 80
                                    height: 80
                                    app: settingsDialog.app
                                    labelLines: app.candidatePreviewLabelLines("6")
                                    drawBackground: true
                                    drawRing: true
                                    rankText: "1"
                                    backgroundColor: app.candidateMarkerColor(1, 1.0)
                                    backgroundOpacity: app.candidateMarkerOpacity(1, 1.0)
                                }

                                CandidateMarkerView {
                                    x: 4
                                    y: 92
                                    width: 80
                                    height: 80
                                    app: settingsDialog.app
                                    labelLines: app.candidatePreviewLabelLines("5")
                                    drawBackground: true
                                    drawRing: false
                                    drawOutline: true
                                    rankText: "2"
                                    backgroundColor: app.candidateMarkerColor(2, 0.55)
                                    backgroundOpacity: app.candidateMarkerOpacity(2, 0.55)
                                    outlineOpacity: app.candidateMarkerOutlineOpacity(0.55)
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                CandidateLabelControl {
                                    lineKind: 0
                                    title: app.trText("candidateWinrate")
                                }

                                CandidateLabelControl {
                                    lineKind: 1
                                    title: app.trText("candidateVisits")
                                }

                                CandidateLabelControl {
                                    lineKind: 2
                                    title: app.candidateScoreTitle()
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40
                                    radius: 6
                                    color: "#ffffff"
                                    border.color: "#c7d4db"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Label {
                                            text: app.trText("candidateThirdLineTitle")
                                            color: "#24313a"
                                            font.pixelSize: 12
                                            Layout.preferredWidth: 88
                                            elide: Text.ElideRight
                                        }

                                        AppComboBox {
                                            model: [
                                                app.trText("candidateScoreMean"),
                                                app.trText("candidateDrawRate")
                                            ]
                                            currentIndex: app.candidateScoreTitleMode
                                            Layout.preferredWidth: 126
                                            onActivated: function(index) { app.candidateScoreTitleMode = index }
                                        }

                                        Item { Layout.fillWidth: true }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 72
                                    radius: 6
                                    color: "#ffffff"
                                    border.color: "#c7d4db"

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 4

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            AppCheckBox {
                                                text: app.trText("candidateRingVisible")
                                                compact: true
                                                checked: app.candidateRingVisible
                                                onToggled: app.candidateRingVisible = checked
                                            }

                                            Label {
                                                text: app.trText("candidateRingWidth")
                                                color: "#53656f"
                                                font.pixelSize: 12
                                            }

                                            AppSpinBox {
                                                enabled: app.candidateRingVisible
                                                compact: true
                                                from: 1
                                                to: 64
                                                editable: true
                                                value: app.candidateRingLineWidth
                                                Layout.preferredWidth: 78
                                                Layout.preferredHeight: 30
                                                onValueModified: app.candidateRingLineWidth = value
                                            }

                                            Item { Layout.fillWidth: true }
                                        }

                                        AppCheckBox {
                                            text: app.trText("candidateRankLabelVisible")
                                            compact: true
                                            checked: app.candidateRankLabelVisible
                                            onToggled: app.candidateRankLabelVisible = checked
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    ColorRow {
                                        label: app.trText("candidateFirstLabelTextColor")
                                        field: candidateFirstTextColorField
                                        compact: true
                                        onApply: settingsDialog.applyColorText(candidateFirstTextColorField,
                                                                                function(value) { app.candidateFirstLabelTextColor = value },
                                                                                function() { return app.candidateFirstLabelTextColor })
                                    }

                                    ColorRow {
                                        label: app.trText("candidateSecondLabelTextColor")
                                        field: candidateTextColorField
                                        compact: true
                                        onApply: settingsDialog.applyColorText(candidateTextColorField,
                                                                                function(value) { app.candidateLabelTextColor = value },
                                                                                function() { return app.candidateLabelTextColor })
                                    }
                                }
                            }
                        }

                        SavePromptButton {
                            text: app.trText("reset")
                            Layout.preferredWidth: 120
                            onClicked: {
                                app.resetCandidateVisualSettings()
                                settingsDialog.syncFields()
                            }
                        }

                    }
                }

                SectionBox {
                    visible: settingsDialog.currentPage === 2
                    title: app.trText("visualSettings")

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 12

                        ColorRow {
                            label: app.trText("backgroundColor")
                            field: backgroundColorField
                            resettable: true
                            onApply: settingsDialog.applyColorText(backgroundColorField,
                                                                    function(value) { app.backgroundColor = value },
                                                                    function() { return app.backgroundColor })
                            onReset: {
                                app.backgroundColor = app.defaultBackgroundColor
                                settingsDialog.syncFields()
                            }
                        }

                        ColorRow {
                            label: app.trText("boardColor")
                            field: boardColorField
                            resettable: true
                            onApply: settingsDialog.applyColorText(boardColorField,
                                                                    function(value) { app.boardWoodColor = value },
                                                                    function() { return app.boardWoodColor })
                            onReset: {
                                app.boardWoodColor = app.defaultBoardWoodColor
                                settingsDialog.syncFields()
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: app.trText("coordinateDisplay")
                                color: "#24313a"
                                Layout.preferredWidth: 150
                            }

                            AppComboBox {
                                model: [
                                    app.trText("coordinateDisplayGoNoI"),
                                    app.trText("coordinateDisplayGomokuWithI"),
                                    app.trText("coordinateDisplayNumeric"),
                                    app.trText("coordinateDisplayNumericOneBased"),
                                    app.trText("coordinateDisplayHex"),
                                    app.trText("coordinateDisplayNone")
                                ]
                                currentIndex: app.effectiveCoordinateDisplayMode()
                                Layout.preferredWidth: 210
                                onActivated: function(index) { app.setCoordinateDisplayMode(index) }
                            }

                            Label {
                                text: app.coordinateDisplayForcedNumeric() ? app.trText("coordinateDisplayForcedNumeric") : ""
                                color: "#6a7a84"
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        SliderRow {
                            label: app.trText("stoneSize")
                            from: app.minStoneScale
                            to: 1.0
                            value: app.stoneScale
                            decimals: 2
                            resettable: true
                            onMoved: function(v) { app.stoneScale = v }
                            onReset: app.stoneScale = app.defaultStoneScale
                        }

                        SliderRow {
                            label: app.trText("gridPointOpacity")
                            from: 0.25
                            to: 1.0
                            value: app.gridOpacity
                            decimals: 2
                            resettable: true
                            onMoved: function(v) { app.gridOpacity = v }
                            onReset: app.gridOpacity = app.defaultGridOpacity
                        }

                        SliderRow {
                            label: app.trText("gridLineWidth")
                            from: 0.5
                            to: 4.0
                            value: app.gridLineWidth
                            decimals: 1
                            resettable: true
                            onMoved: function(v) { app.gridLineWidth = v }
                            onReset: app.gridLineWidth = app.defaultGridLineWidth
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: app.trText("moveNumberDisplay")
                                color: "#24313a"
                                Layout.preferredWidth: 150
                            }

                            AppComboBox {
                                model: [
                                    app.trText("moveNumberAll"),
                                    app.trText("moveNumberLastOnly"),
                                    app.trText("moveNumberHidden")
                                ]
                                currentIndex: app.moveNumberDisplayMode
                                Layout.preferredWidth: 210
                                onActivated: function(index) { app.moveNumberDisplayMode = index }
                            }

                            Item { Layout.fillWidth: true }
                        }

                        BoardVisualPreview {
                            Layout.fillWidth: true
                        }

                        SliderRow {
                            label: app.trText("selectedPointSize")
                            from: 0.5
                            to: 1.0
                            value: app.selectedPointScale
                            decimals: 2
                            resettable: true
                            onMoved: function(v) { app.selectedPointScale = v }
                            onReset: app.selectedPointScale = app.defaultSelectedPointScale
                        }

                        SliderRow {
                            label: app.trText("moveNumberLabelScale")
                            from: 0.5
                            to: 2.0
                            value: app.moveNumberLabelScale
                            decimals: 2
                            percent: true
                            resettable: true
                            onMoved: function(v) { app.moveNumberLabelScale = v }
                            onReset: app.moveNumberLabelScale = app.defaultMoveNumberLabelScale
                        }

                        SavePromptButton {
                            text: app.trText("resetAll")
                            Layout.preferredWidth: 120
                            onClicked: {
                                app.resetBoardVisualSettings()
                                settingsDialog.syncFields()
                            }
                        }
                    }
                }

                SectionBox {
                    visible: settingsDialog.currentPage === 3
                    title: app.trText("engine")

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            SavePromptButton {
                                text: app.trText("engineAddAndConfigure")
                                Layout.preferredWidth: 180
                                Layout.minimumWidth: 160
                                primary: true
                                onClicked: app.openEngineListDialog(settingsDialog)
                            }

                            Item { Layout.fillWidth: true }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: app.trText("engineDefaultEngine")
                                color: "#24313a"
                                font.bold: true
                                Layout.preferredWidth: 96
                            }

                            AppComboBox {
                                id: defaultEngineCombo
                                model: app.engineDefaultOptions()
                                textRole: "label"
                                valueRole: "id"
                                currentIndex: app.engineDefaultCurrentIndex()
                                onActivated: function(index) { app.setDefaultEnginePresetFromIndex(index) }
                                Layout.fillWidth: true
                                Layout.preferredWidth: 420
                                Layout.minimumWidth: 260
                                implicitHeight: 34
                            }

                            SavePromptButton {
                                text: app.trText("engineClearDefault")
                                Layout.preferredWidth: 132
                                Layout.minimumWidth: 124
                                enabled: app.defaultEngineId.length > 0
                                onClicked: app.setDefaultEnginePreset("")
                            }
                        }

                        Label {
                            text: app.trText("engineParameterEditHint")
                            color: "#647782"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: app.trText("engineName")
                                color: "#24313a"
                                Layout.preferredWidth: 96
                            }

                            ReadOnlyField {
                                text: app.defaultEnginePreset() ? app.defaultEnginePreset().name : app.trText("engineNoDefault")
                                Layout.fillWidth: true
                            }
                        }

                        Label {
                            text: app.trText("engineCommand")
                            color: "#24313a"
                            font.bold: true
                        }

                        ReadOnlyArea {
                            text: app.defaultEnginePreset() ? app.defaultEnginePreset().command : ""
                            Layout.fillWidth: true
                            Layout.preferredHeight: 72
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: app.trText("engineInitialCommands")
                                color: "#24313a"
                                Layout.preferredWidth: 96
                            }

                            ReadOnlyField {
                                text: app.defaultEnginePreset() ? String(app.defaultEnginePreset().initialCommands || "") : ""
                                Layout.fillWidth: true
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: app.trText("engineRule")
                                color: "#24313a"
                                Layout.preferredWidth: 96
                            }

                            ReadOnlyField {
                                text: app.defaultEnginePreset() ? app.enginePresetRuleDetailText(app.defaultEnginePreset()) : ""
                                Layout.fillWidth: true
                                Layout.minimumWidth: 160
                            }

                            Label {
                                text: app.trText("boardSize")
                                color: "#24313a"
                            }

                            ReadOnlyField {
                                text: app.defaultEnginePreset() ? app.enginePresetBoardSizeText(app.defaultEnginePreset()) : ""
                                Layout.preferredWidth: 88
                            }

                            Item { Layout.preferredWidth: 0 }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: app.trText("komi")
                                color: "#24313a"
                                Layout.preferredWidth: 96
                            }

                            ReadOnlyField {
                                text: app.defaultEnginePreset() ? Number(app.defaultEnginePreset().komi).toFixed(1) : ""
                                Layout.preferredWidth: 72
                            }

                            Label {
                                text: app.trText("legacyHexEngineCoordinatesShort")
                                color: "#24313a"
                            }

                            ReadOnlyField {
                                text: app.defaultEnginePreset()
                                      ? (app.defaultEnginePreset().legacyHexEngineCoordinates ? app.trText("yes") : app.trText("no"))
                                      : ""
                                Layout.preferredWidth: 72
                            }

                            Item { Layout.fillWidth: true }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            SavePromptButton {
                                text: app.trText("engineStart")
                                primary: true
                                onClicked: app.startEngine()
                            }

                            SavePromptButton {
                                text: app.trText("engineStop")
                                onClicked: app.stopEngine()
                            }

                            SavePromptButton {
                                text: app.trText("engineRestart")
                                onClicked: app.restartEngine()
                            }

                            SavePromptButton {
                                text: app.trText("engineCommunicationLog")
                                onClicked: app.openEngineCommunicationLog()
                            }
                        }

                    }
                }
            }
        }
    }

    dialogFooter: AppDialogFooter {
        implicitHeight: 62
        contentMargins: 16

        Item { Layout.fillWidth: true }

        SavePromptButton {
            text: app.trText("close")
            primary: true
            Layout.preferredWidth: 110
            onClicked: settingsDialog.closeDialog()
        }
    }

    component ReadOnlyField: Basic.TextField {
        readOnly: true
        selectByMouse: true
        color: "#667a85"

        background: Rectangle {
            radius: 4
            color: "#edf2f4"
            border.color: "#c3d0d8"
        }
    }

    component ReadOnlyArea: Basic.TextArea {
        readOnly: true
        selectByMouse: true
        wrapMode: TextEdit.WrapAnywhere
        color: "#667a85"

        background: Rectangle {
            radius: 4
            color: "#edf2f4"
            border.color: "#c3d0d8"
        }
    }

    component PageButton: Basic.Button {
        id: pageButton
        required property int page
        readonly property bool selected: settingsDialog.currentPage === page

        Layout.fillWidth: true
        Layout.preferredHeight: 36
        hoverEnabled: true
        checkable: true
        checked: selected
        Accessible.role: Accessible.PageTab
        Accessible.checked: selected
        onClicked: settingsDialog.currentPage = pageButton.page

        contentItem: Text {
            text: pageButton.text
            color: "#1b2d36"
            font.pixelSize: 14
            font.bold: pageButton.selected
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            radius: 5
            color: pageButton.selected ? "#d8e9f1"
                 : pageButton.pressed ? "#e1ebf0"
                 : pageButton.hovered ? "#f3f8fb" : "#ffffff"
            border.color: pageButton.visualFocus ? "#0f5f8f"
                         : pageButton.selected ? "#2e8eb0" : "#c7d4dc"
            border.width: pageButton.selected || pageButton.activeFocus ? 2 : 1
        }
    }

    component SectionBox: Rectangle {
        id: section
        property string title: ""
        default property alias content: sectionBody.data

        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(72, sectionColumn.implicitHeight + 28)
        radius: 6
        color: "#f5f8fa"
        border.color: "#c7d4dc"

        ColumnLayout {
            id: sectionColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 10

            Label {
                text: section.title
                color: "#17212a"
                font.pixelSize: 15
                font.bold: true
                Layout.fillWidth: true
            }

            ColumnLayout {
                id: sectionBody
                Layout.fillWidth: true
                spacing: 10
            }
        }
    }

    component SmallModeButton: Basic.Button {
        id: modeButton
        property bool selected: false

        Layout.preferredWidth: Math.max(62, modeLabel.implicitWidth + 22)
        Layout.preferredHeight: 30
        hoverEnabled: true
        checkable: true
        checked: selected
        Accessible.role: Accessible.RadioButton
        Accessible.checked: selected

        contentItem: Text {
            id: modeLabel
            text: modeButton.text
            color: "#26333b"
            font.pixelSize: 13
            font.bold: modeButton.selected
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            radius: 4
            opacity: modeButton.enabled ? 1 : 0.45
            color: modeButton.selected ? "#d8e9f1"
                 : modeButton.pressed ? "#dce7ec"
                 : modeButton.hovered ? "#eef5f8" : "#ffffff"
            border.color: modeButton.visualFocus ? "#0f5f8f"
                         : modeButton.selected ? "#2e8eb0" : "#b5c2c9"
            border.width: modeButton.selected || modeButton.activeFocus ? 2 : 1
        }
    }

    component CandidateLabelControl: Rectangle {
        id: labelControl

        required property int lineKind
        required property string title
        property bool controlsEnabled: true

        function lineVisible() {
            if (lineKind === 0)
                return app.candidateWinrateLabelVisible
            if (lineKind === 1)
                return app.candidateVisitsLabelVisible
            return app.candidateScoreLabelVisible
        }

        function setLineVisible(value) {
            if (lineKind === 0)
                app.candidateWinrateLabelVisible = value
            else if (lineKind === 1)
                app.candidateVisitsLabelVisible = value
            else
                app.candidateScoreLabelVisible = value
        }

        function lineFontSize() {
            if (lineKind === 0)
                return app.candidateWinrateFontSize
            if (lineKind === 1)
                return app.candidateVisitsFontSize
            return app.candidateScoreFontSize
        }

        function setLineFontSize(value) {
            if (lineKind === 0)
                app.candidateWinrateFontSize = value
            else if (lineKind === 1)
                app.candidateVisitsFontSize = value
            else
                app.candidateScoreFontSize = value
        }

        function lineBold() {
            if (lineKind === 0)
                return app.candidateWinrateBold
            if (lineKind === 1)
                return app.candidateVisitsBold
            return app.candidateScoreBold
        }

        function setLineBold(value) {
            if (lineKind === 0)
                app.candidateWinrateBold = value
            else if (lineKind === 1)
                app.candidateVisitsBold = value
            else
                app.candidateScoreBold = value
        }

        function lineOffsetY() {
            if (lineKind === 0)
                return app.candidateWinrateOffsetY
            if (lineKind === 1)
                return app.candidateVisitsOffsetY
            return app.candidateScoreOffsetY
        }

        function setLineOffsetY(value) {
            if (lineKind === 0)
                app.candidateWinrateOffsetY = value
            else if (lineKind === 1)
                app.candidateVisitsOffsetY = value
            else
                app.candidateScoreOffsetY = value
        }

        function lineDecimals() {
            return lineKind === 0 ? app.candidateWinrateDecimals : app.candidateScoreDecimals
        }

        function setLineDecimals(value) {
            if (lineKind === 0)
                app.candidateWinrateDecimals = value
            else if (lineKind === 2)
                app.candidateScoreDecimals = value
        }

        function lineShowPercent() {
            return lineKind === 0 ? app.candidateWinrateShowPercent : app.candidateScoreShowPercent
        }

        function setLineShowPercent(value) {
            if (lineKind === 0)
                app.candidateWinrateShowPercent = value
            else if (lineKind === 2)
                app.candidateScoreShowPercent = value
        }

        Layout.fillWidth: true
        Layout.preferredHeight: 44
        radius: 6
        color: "#ffffff"
        border.color: "#c7d4db"
        opacity: controlsEnabled ? 1 : 0.52

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 3

            Label {
                text: "<"
                color: "#58717e"
                font.pixelSize: 14
                font.bold: true
                Layout.preferredWidth: 10
            }

            AppCheckBox {
                enabled: labelControl.controlsEnabled
                compact: true
                checked: labelControl.lineVisible()
                Layout.preferredWidth: 24
                onToggled: labelControl.setLineVisible(checked)
            }

            Label {
                text: labelControl.title
                color: "#17212a"
                font.pixelSize: 13
                font.bold: true
                Layout.preferredWidth: 40
                elide: Text.ElideRight
            }

            AppCheckBox {
                enabled: labelControl.controlsEnabled
                compact: true
                text: app.trText("candidateLabelBold")
                checked: labelControl.lineBold()
                Layout.preferredWidth: 46
                onToggled: labelControl.setLineBold(checked)
            }

            Label {
                text: app.trText("candidateLabelFontSize")
                color: "#53656f"
                font.pixelSize: 11
                Layout.preferredWidth: 22
                elide: Text.ElideRight
            }

            AppSpinBox {
                enabled: labelControl.controlsEnabled
                compact: true
                from: 12
                to: 120
                editable: true
                value: labelControl.lineFontSize()
                Layout.preferredWidth: 58
                Layout.preferredHeight: 30
                onValueModified: labelControl.setLineFontSize(value)
            }

            Label {
                text: app.trText("candidateLabelOffsetY")
                color: "#53656f"
                font.pixelSize: 11
                Layout.preferredWidth: 22
                elide: Text.ElideRight
            }

            AppSpinBox {
                enabled: labelControl.controlsEnabled
                compact: true
                from: -64
                to: 64
                editable: true
                value: labelControl.lineOffsetY()
                Layout.preferredWidth: 58
                Layout.preferredHeight: 30
                onValueModified: labelControl.setLineOffsetY(value)
            }

            Label {
                visible: labelControl.lineKind !== 1
                text: app.trText("candidateLabelDecimals")
                color: "#53656f"
                font.pixelSize: 11
                Layout.preferredWidth: 24
                elide: Text.ElideRight
            }

            AppComboBox {
                visible: labelControl.lineKind !== 1
                enabled: labelControl.controlsEnabled
                compact: true
                textHorizontalAlignment: Text.AlignHCenter
                model: [ "0", "1", "2" ]
                currentIndex: labelControl.lineDecimals()
                Layout.preferredWidth: 48
                Layout.preferredHeight: 30
                onActivated: function(index) { labelControl.setLineDecimals(index) }
            }

            AppCheckBox {
                visible: labelControl.lineKind === 0
                         || (labelControl.lineKind === 2
                             && app.candidateScoreTitleMode === app.candidateScoreTitleDrawRate)
                enabled: labelControl.controlsEnabled
                compact: true
                text: "%"
                checked: labelControl.lineShowPercent()
                Layout.preferredWidth: 38
                onToggled: labelControl.setLineShowPercent(checked)
            }

            Item { Layout.fillWidth: true }
        }
    }

    component SliderRow: RowLayout {
        id: sliderRow
        property string label: ""
        property real from: 0
        property real to: 1
        property real value: 0
        property int decimals: 2
        property bool percent: false
        property bool resettable: false
        signal moved(real value)
        signal reset()

        Layout.fillWidth: true
        spacing: 8

        Label {
            text: sliderRow.label
            color: "#24313a"
            Layout.preferredWidth: 150
        }

        Slider {
            id: rowSlider
            from: sliderRow.from
            to: sliderRow.to
            value: sliderRow.value
            live: true
            Layout.fillWidth: true
            onMoved: sliderRow.moved(value)
        }

        Label {
            text: sliderRow.percent ? Math.round(Number(rowSlider.value) * 100) + "%"
                                    : Number(rowSlider.value).toFixed(sliderRow.decimals)
            color: "#52636d"
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 56
        }

        SavePromptButton {
            visible: sliderRow.resettable
            text: app.trText("reset")
            Layout.preferredWidth: 62
            onClicked: sliderRow.reset()
        }
    }

    component BoardVisualPreview: RowLayout {
        id: boardVisualPreview
        spacing: 10

        Label {
            text: app.trText("boardVisualPreview")
            color: "#24313a"
            Layout.preferredWidth: 190
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 110
            radius: 5
            color: "#ffffff"
            border.color: "#c4d0d7"

            Canvas {
                id: boardVisualPreviewCanvas
                anchors.fill: parent
                anchors.margins: 8

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    var cell = Math.min(44, Math.max(20, (width - 36) / 4))
                    var centerY = Math.round(height * 0.5)
                    var startX = Math.round((width - cell * 4) * 0.5)
                    var endX = startX + cell * 4
                    var top = centerY - cell * 0.7
                    var bottom = centerY + cell * 0.7
                    var stoneRadius = Math.max(8, cell * app.stoneScale * 0.5)

                    function drawStone(cx, cy, player) {
                        ctx.save()
                        var gradient = ctx.createRadialGradient(cx - stoneRadius * 0.28,
                                                                 cy - stoneRadius * 0.35,
                                                                 stoneRadius * 0.1,
                                                                 cx,
                                                                 cy,
                                                                 stoneRadius)
                        if (player === 1) {
                            gradient.addColorStop(0, "#555555")
                            gradient.addColorStop(1, "#050505")
                        } else {
                            gradient.addColorStop(0, "#ffffff")
                            gradient.addColorStop(1, "#d7d7d7")
                        }
                        ctx.fillStyle = gradient
                        ctx.beginPath()
                        ctx.arc(cx, cy, stoneRadius, 0, Math.PI * 2)
                        ctx.fill()
                        ctx.strokeStyle = player === 1 ? "#050505" : "#8f8f8f"
                        ctx.lineWidth = Math.max(1, stoneRadius * 0.05)
                        ctx.stroke()
                        ctx.restore()
                    }

                    function drawMoveNumber(cx, cy, player, moveNumber, last) {
                        if (!app.stoneNumberVisible(moveNumber, last))
                            return
                        var text = String(moveNumber)
                        var size = app.stoneNumberFontSize(ctx, text, stoneRadius)
                        ctx.save()
                        ctx.fillStyle = app.stoneNumberColor(player, last)
                        ctx.font = app.stoneNumberCanvasFont(size, true)
                        ctx.textAlign = "center"
                        ctx.textBaseline = "middle"
                        ctx.fillText(text, cx, cy + app.stoneNumberOffsetY(size),
                                     app.stoneNumberMaxWidth(stoneRadius))
                        ctx.restore()
                    }

                    function drawLastMoveMarker(cx, cy) {
                        var markerSize = stoneRadius * 0.62
                        var cornerX = cx - stoneRadius
                        var cornerY = cy - stoneRadius
                        ctx.fillStyle = "#e3342f"
                        ctx.beginPath()
                        ctx.moveTo(cornerX, cornerY)
                        ctx.lineTo(cornerX + markerSize, cornerY)
                        ctx.lineTo(cornerX, cornerY + markerSize)
                        ctx.closePath()
                        ctx.fill()
                    }

                    ctx.fillStyle = app.boardWoodColor
                    ctx.fillRect(6, 6, width - 12, height - 12)

                    ctx.save()
                    ctx.globalAlpha = app.gridOpacity
                    ctx.strokeStyle = "#1b252c"
                    ctx.lineWidth = Math.max(0.5, app.gridLineWidth)
                    ctx.beginPath()
                    ctx.moveTo(startX, centerY)
                    ctx.lineTo(endX, centerY)
                    for (var i = 0; i < 5; ++i) {
                        var x = startX + i * cell
                        ctx.moveTo(x, top)
                        ctx.lineTo(x, bottom)
                    }
                    ctx.stroke()
                    ctx.restore()

                    var black1X = startX + cell
                    var white2X = startX + cell * 2
                    var black3X = startX + cell * 3
                    drawStone(black1X, centerY, 1)
                    drawMoveNumber(black1X, centerY, 1, 1, false)
                    drawStone(white2X, centerY, 2)
                    drawMoveNumber(white2X, centerY, 2, 2, false)
                    drawStone(black3X, centerY, 1)
                    drawLastMoveMarker(black3X, centerY)
                    drawMoveNumber(black3X, centerY, 1, 3, true)
                }

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                Connections {
                    target: app
                    function onBoardWoodColorChanged() { boardVisualPreviewCanvas.requestPaint() }
                    function onGridOpacityChanged() { boardVisualPreviewCanvas.requestPaint() }
                    function onGridLineWidthChanged() { boardVisualPreviewCanvas.requestPaint() }
                    function onStoneScaleChanged() { boardVisualPreviewCanvas.requestPaint() }
                    function onMoveNumberDisplayModeChanged() { boardVisualPreviewCanvas.requestPaint() }
                    function onMoveNumberLabelScaleChanged() { boardVisualPreviewCanvas.requestPaint() }
                }
            }
        }
    }

    component ColorRow: RowLayout {
        id: colorRow
        property string label: ""
        property var field
        property bool compact: false
        property bool resettable: false
        signal apply()
        signal reset()

        Layout.fillWidth: true
        spacing: colorRow.compact ? 6 : 8

        Label {
            id: colorLabel
            text: colorRow.label
            color: "#24313a"
            Layout.preferredWidth: colorRow.compact ? Math.max(64, colorLabel.implicitWidth) : 150
            elide: Text.ElideRight
        }

        AppTextField {
            id: colorField
            text: colorRow.field ? colorRow.field.text : ""
            font.pixelSize: colorRow.compact ? 14 : 15
            Layout.preferredWidth: colorRow.compact ? 88 : 120
            Layout.preferredHeight: colorRow.compact ? 34 : 38
            onTextChanged: if (colorRow.field) colorRow.field.text = text
            onEditingFinished: colorRow.apply()
        }

        SavePromptButton {
            text: app.trText("apply")
            Layout.preferredWidth: colorRow.compact ? 58 : 88
            onClicked: colorRow.apply()
        }

        SavePromptButton {
            visible: colorRow.resettable
            text: app.trText("reset")
            Layout.preferredWidth: 62
            onClicked: colorRow.reset()
        }
    }

    QtObject { id: backgroundColorField; property string text: "" }
    QtObject { id: boardColorField; property string text: "" }
    QtObject { id: candidateFirstTextColorField; property string text: "" }
    QtObject { id: candidateTextColorField; property string text: "" }
}
