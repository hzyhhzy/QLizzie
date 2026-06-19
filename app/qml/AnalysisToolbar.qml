import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

Rectangle {
    id: toolbar
    required property var app

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: app.analysisToolbarHeight
    color: "#e7ecef"
    border.color: "#c4cdd2"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: app.compactLayout ? 8 : 12
        anchors.rightMargin: app.compactLayout ? 8 : 12
        spacing: app.compactLayout ? 7 : 11

        RuleSettingsButton {
            visible: app.toolbarRuleSettingsVisible()
        }

        Rectangle {
            visible: app.toolbarRuleSettingsVisible()
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: 7
            Layout.bottomMargin: 7
            color: "#c4cdd2"
        }

        Label {
            visible: app.toolbarBoardPresentationVisible()
            text: app.trText("boardPresentation")
            color: "#26333b"
            font.pixelSize: app.compactLayout ? 13 : 15
            verticalAlignment: Text.AlignVCenter
        }

        ToolbarPresentationCombo {
            app: toolbar.app
            visible: app.toolbarBoardPresentationVisible()
            options: app.boardPresentationOptions()
            currentIndex: app.boardPresentationCurrentIndex()
            Layout.preferredWidth: app.compactLayout ? 134 : 178
            implicitHeight: app.compactLayout ? 28 : 32
            onPicked: function(index) {
                app.setBoardPresentationFromIndex(index)
                app.focusBoardInput()
            }
        }

        Label {
            visible: app.toolbarHexBoardStyleVisible()
            text: app.trText("hexBoardStyle")
            color: "#26333b"
            font.pixelSize: app.compactLayout ? 13 : 15
            verticalAlignment: Text.AlignVCenter
        }

        ToolbarPresentationCombo {
            app: toolbar.app
            visible: app.toolbarHexBoardStyleVisible()
            options: app.hexBoardStyleOptions()
            currentIndex: app.hexBoardStyleCurrentIndex()
            Layout.preferredWidth: app.compactLayout ? 116 : 150
            implicitHeight: app.compactLayout ? 28 : 32
            onPicked: function(index) {
                app.setHexBoardStyleFromIndex(index)
                app.focusBoardInput()
            }
        }

        Label {
            visible: app.toolbarHexBoardRotationVisible()
            text: app.trText("hexBoardRotation")
            color: "#26333b"
            font.pixelSize: app.compactLayout ? 13 : 15
            verticalAlignment: Text.AlignVCenter
        }

        ToolbarPresentationCombo {
            app: toolbar.app
            visible: app.toolbarHexBoardRotationVisible()
            options: app.hexBoardRotationOptions()
            currentIndex: app.hexBoardRotationCurrentIndex()
            Layout.preferredWidth: app.compactLayout ? 132 : 178
            implicitHeight: app.compactLayout ? 28 : 32
            onPicked: function(index) {
                app.setHexBoardRotationFromIndex(index)
                app.focusBoardInput()
            }
        }

        Rectangle {
            visible: app.toolbarPresentationControlsVisible()
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: 7
            Layout.bottomMargin: 7
            color: "#c4cdd2"
        }

        Label {
            visible: app.komiControlsVisible()
            text: app.komiLabelText()
            color: "#26333b"
            font.pixelSize: app.compactLayout ? 13 : 15
            verticalAlignment: Text.AlignVCenter
        }

        Basic.TextField {
            id: komiField
            visible: app.komiControlsVisible()
            text: Number(app.effectiveKomi()).toFixed(1)
            selectByMouse: true
            validator: DoubleValidator {
                bottom: app.komiMinimum()
                top: app.komiMaximum()
                decimals: 2
                notation: DoubleValidator.StandardNotation
            }
            Layout.preferredWidth: app.compactLayout ? 72 : 82
            implicitHeight: app.compactLayout ? 28 : 32
            leftPadding: 3
            rightPadding: 3
            topPadding: 0
            bottomPadding: 1
            color: "#17252d"
            selectedTextColor: "#ffffff"
            selectionColor: "#2e8eb0"
            font.pixelSize: app.compactLayout ? 15 : 17
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            background: Rectangle {
                radius: 4
                color: komiField.activeFocus ? "#ffffff" : "#f9fbfc"
                border.color: komiField.activeFocus ? "#2e8eb0" : "#9fb0b8"
                border.width: komiField.activeFocus ? 2 : 1
            }

            function applyValue() {
                var nextValue = Number(text)
                if (!isNaN(nextValue))
                    app.setKomiValue(nextValue)
                text = Number(app.effectiveKomi()).toFixed(1)
            }

            onEditingFinished: applyValue()
            Keys.onReturnPressed: {
                applyValue()
                app.focusBoardInput()
            }
            Keys.onEnterPressed: {
                applyValue()
                app.focusBoardInput()
            }

            Connections {
                target: app
                function onKomiChanged() {
                    if (!komiField.activeFocus)
                        komiField.text = Number(app.effectiveKomi()).toFixed(1)
                }
                function onGameRuleModeChanged() {
                    if (!komiField.activeFocus)
                        komiField.text = Number(app.effectiveKomi()).toFixed(1)
                }
            }
        }

        ColumnLayout {
            visible: app.komiControlsVisible()
            spacing: 0
            Layout.minimumWidth: app.compactLayout ? 14 : 16
            Layout.preferredWidth: app.compactLayout ? 14 : 16
            Layout.maximumWidth: app.compactLayout ? 14 : 16
            Layout.preferredHeight: app.compactLayout ? 30 : 34

            StepButton {
                text: "^"
                onClicked: app.adjustKomi(0.5)
            }

            StepButton {
                text: "v"
                onClicked: app.adjustKomi(-0.5)
            }
        }

        Basic.CheckBox {
            id: wideRootNoiseEnabledBox
            visible: app.analysisWideRootNoiseControlsVisible()
            checked: app.analysisWideRootNoiseEnabled
            ToolTip.visible: hovered
            ToolTip.text: app.trText("wideRootNoiseTip")
            Layout.preferredWidth: app.compactLayout ? 18 : 20
            Layout.preferredHeight: app.compactLayout ? 28 : 32
            leftPadding: 0
            rightPadding: 0
            topPadding: 0
            bottomPadding: 0
            onToggled: app.setAnalysisWideRootNoiseEnabled(checked)

            indicator: Rectangle {
                x: Math.round((wideRootNoiseEnabledBox.width - width) / 2)
                y: Math.round((wideRootNoiseEnabledBox.height - height) / 2)
                width: app.compactLayout ? 14 : 16
                height: width
                radius: 2
                color: wideRootNoiseEnabledBox.checked ? "#1678bd" : "#ffffff"
                border.color: wideRootNoiseEnabledBox.checked ? "#1678bd"
                              : wideRootNoiseEnabledBox.hovered ? "#6f8794" : "#9fb0b8"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    visible: wideRootNoiseEnabledBox.checked
                    text: "\u2713"
                    color: "#ffffff"
                    font.pixelSize: app.compactLayout ? 11 : 12
                    font.bold: true
                }
            }

            contentItem: Item {}
        }

        Label {
            visible: app.analysisWideRootNoiseControlsVisible()
            text: app.trText("wideRootNoise") + ":"
            color: "#26333b"
            font.pixelSize: app.compactLayout ? 13 : 15
            verticalAlignment: Text.AlignVCenter
        }

        Basic.TextField {
            id: wideRootNoiseField
            visible: app.analysisWideRootNoiseControlsVisible()
            text: app.formatAnalysisWideRootNoise(app.analysisWideRootNoise)
            selectByMouse: true
            validator: DoubleValidator {
                bottom: 0
                top: 2
                decimals: 3
                notation: DoubleValidator.StandardNotation
            }
            ToolTip.visible: hovered
            ToolTip.text: app.trText("wideRootNoiseTip")
            Layout.preferredWidth: app.compactLayout ? 54 : 62
            implicitHeight: app.compactLayout ? 28 : 32
            leftPadding: 3
            rightPadding: 3
            topPadding: 0
            bottomPadding: 1
            color: "#17252d"
            selectedTextColor: "#ffffff"
            selectionColor: "#2e8eb0"
            font.pixelSize: app.compactLayout ? 15 : 17
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            background: Rectangle {
                radius: 4
                color: wideRootNoiseField.activeFocus ? "#ffffff" : "#f9fbfc"
                border.color: wideRootNoiseField.activeFocus ? "#2e8eb0" : "#9fb0b8"
                border.width: wideRootNoiseField.activeFocus ? 2 : 1
            }

            function applyValue() {
                var nextValue = Number(text)
                if (!isNaN(nextValue))
                    app.setAnalysisWideRootNoise(nextValue)
                text = app.formatAnalysisWideRootNoise(app.analysisWideRootNoise)
            }

            onEditingFinished: applyValue()
            Keys.onReturnPressed: {
                applyValue()
                app.focusBoardInput()
            }
            Keys.onEnterPressed: {
                applyValue()
                app.focusBoardInput()
            }

            Connections {
                target: app
                function onAnalysisWideRootNoiseChanged() {
                    if (!wideRootNoiseField.activeFocus)
                        wideRootNoiseField.text = app.formatAnalysisWideRootNoise(app.analysisWideRootNoise)
                }
            }
        }

        Rectangle {
            visible: app.komiControlsVisible() || app.analysisWideRootNoiseControlsVisible()
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: 7
            Layout.bottomMargin: 7
            color: "#c4cdd2"
        }

        Label {
            text: app.trText("stoneColor")
            color: "#26333b"
            font.pixelSize: app.compactLayout ? 13 : 15
            verticalAlignment: Text.AlignVCenter
        }

        RowLayout {
            spacing: app.compactLayout ? 4 : 5

            StoneColorButton {
                mode: app.stoneColorModeAuto
                tip: app.trText("stoneColorAutoTip")
            }

            StoneColorButton {
                mode: app.stoneColorModeBlack
                tip: app.trText("stoneColorBlackTip")
            }

            StoneColorButton {
                mode: app.stoneColorModeWhite
                tip: app.trText("stoneColorWhiteTip")
            }

            PassButton {}
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: 7
            Layout.bottomMargin: 7
            color: "#c4cdd2"
        }

        RowLayout {
            spacing: app.compactLayout ? 3 : 4

            PlayModeButton {
                mode: app.playModeAnalysis
                text: app.trText("playModeAnalysis")
            }

            PlayModeButton {
                mode: app.playModeAiBlack
                text: app.trText("playModeAiBlack")
            }

            PlayModeButton {
                mode: app.playModeAiWhite
                text: app.trText("playModeAiWhite")
            }

            PlayModeButton {
                mode: app.playModeAiSelf
                text: app.trText("playModeAiSelf")
            }
        }

        Label {
            text: app.trText("secondsPerMove")
            color: app.engineReadyForPlayMode() ? "#26333b" : "#7f8b92"
            font.pixelSize: app.compactLayout ? 12 : 14
            verticalAlignment: Text.AlignVCenter
        }

        Basic.TextField {
            id: secondsField
            enabled: app.engineReadyForPlayMode()
            text: Number(app.secondsPerMove).toFixed(1)
            selectByMouse: true
            validator: DoubleValidator {
                bottom: 0.1
                top: 999
                decimals: 1
                notation: DoubleValidator.StandardNotation
            }
            Layout.preferredWidth: app.compactLayout ? 44 : 50
            implicitHeight: app.compactLayout ? 28 : 32
            leftPadding: 3
            rightPadding: 3
            topPadding: 0
            bottomPadding: 1
            color: enabled ? "#17252d" : "#7f8b92"
            selectedTextColor: "#ffffff"
            selectionColor: "#2e8eb0"
            font.pixelSize: app.compactLayout ? 13 : 15
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            background: Rectangle {
                radius: 4
                color: secondsField.enabled ? (secondsField.activeFocus ? "#ffffff" : "#f9fbfc") : "#e2e8eb"
                border.color: secondsField.activeFocus ? "#2e8eb0" : "#b5c2c9"
                border.width: secondsField.activeFocus ? 2 : 1
            }

            function applyValue() {
                var nextValue = Number(text)
                if (!isNaN(nextValue))
                    app.secondsPerMove = Math.max(0.1, nextValue)
                text = Number(app.secondsPerMove).toFixed(1)
            }

            onEditingFinished: applyValue()
            Keys.onReturnPressed: {
                applyValue()
                app.focusBoardInput()
            }
            Keys.onEnterPressed: {
                applyValue()
                app.focusBoardInput()
            }

            Connections {
                target: app
                function onSecondsPerMoveChanged() {
                    if (!secondsField.activeFocus)
                        secondsField.text = Number(app.secondsPerMove).toFixed(1)
                }
            }
        }

        Label {
            text: app.trText("secondsUnit")
            color: app.engineReadyForPlayMode() ? "#26333b" : "#7f8b92"
            font.pixelSize: app.compactLayout ? 12 : 14
            verticalAlignment: Text.AlignVCenter
        }

        Item { Layout.fillWidth: true }
    }

    component RuleSettingsButton: Rectangle {
        id: ruleSettingsButton

        Layout.preferredWidth: app.compactLayout ? 84 : 104
        Layout.preferredHeight: app.compactLayout ? 28 : 32
        radius: 4
        color: ruleSettingsMouse.pressed ? "#d5e1e8"
             : ruleSettingsMouse.containsMouse ? "#eef5f8" : "#f8fafb"
        border.color: "#2e8eb0"
        border.width: 1

        Text {
            anchors.centerIn: parent
            width: parent.width - 10
            text: app.trText("ruleSettingsButton")
            color: "#26333b"
            font.pixelSize: app.compactLayout ? 12 : 13
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        ToolTip.visible: ruleSettingsMouse.containsMouse
        ToolTip.text: app.ruleVariantText()

        MouseArea {
            id: ruleSettingsMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                app.openRuleVariantDialog()
                app.focusBoardInput()
            }
        }
    }

    component StepButton: Rectangle {
        id: stepButton
        signal clicked()
        property string text: ""

        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 2
        opacity: enabled ? 1 : 0.48
        color: stepMouse.pressed ? "#cfdbe1" : stepMouse.containsMouse ? "#dde6eb" : "#f7fafb"
        border.color: "#aebbc2"

        Text {
            anchors.centerIn: parent
            text: stepButton.text
            color: "#26333b"
            font.pixelSize: app.compactLayout ? 9 : 10
            font.bold: true
        }

        MouseArea {
            id: stepMouse
            anchors.fill: parent
            enabled: stepButton.enabled
            hoverEnabled: true
            onClicked: {
                stepButton.clicked()
                app.focusBoardInput()
            }
        }
    }

    component StoneColorButton: Rectangle {
        id: colorButton
        property int mode: 0
        property string tip: ""
        readonly property bool selected: app.stoneColorMode === mode

        Layout.preferredWidth: app.compactLayout ? 34 : 38
        Layout.preferredHeight: app.compactLayout ? 28 : 32
        radius: 4
        color: selected ? "#d8e9f1" : colorMouse.containsMouse ? "#eef5f8" : "#f8fafb"
        border.color: selected ? "#2e8eb0" : "#b5c2c9"
        border.width: selected ? 2 : 1

        Item {
            anchors.fill: parent

            Rectangle {
                visible: colorButton.mode === app.stoneColorModeAuto
                x: parent.width / 2 - width + 3
                y: parent.height / 2 - height / 2
                width: app.currentPlayer === 1 ? 17 : 13
                height: width
                radius: width / 2
                color: "#050607"
                border.color: "#1a1d20"
            }

            Rectangle {
                visible: colorButton.mode === app.stoneColorModeAuto
                x: parent.width / 2 - 2
                y: parent.height / 2 - height / 2
                width: app.currentPlayer === 2 ? 17 : 13
                height: width
                radius: width / 2
                color: "#ffffff"
                border.color: "#aeb8be"
            }

            Rectangle {
                visible: colorButton.mode === app.stoneColorModeBlack
                anchors.centerIn: parent
                width: app.compactLayout ? 18 : 21
                height: width
                radius: width / 2
                color: "#050607"
                border.color: "#1a1d20"
            }

            Rectangle {
                visible: colorButton.mode === app.stoneColorModeWhite
                anchors.centerIn: parent
                width: app.compactLayout ? 18 : 21
                height: width
                radius: width / 2
                color: "#ffffff"
                border.color: "#aeb8be"
            }
        }

        ToolTip.visible: colorMouse.containsMouse
        ToolTip.text: tip

        MouseArea {
            id: colorMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                app.setStoneColorMode(colorButton.mode)
                app.focusBoardInput()
            }
        }
    }

    component PassButton: Rectangle {
        id: passButton

        Layout.preferredWidth: app.compactLayout ? 44 : 52
        Layout.preferredHeight: app.compactLayout ? 28 : 32
        radius: 4
        color: passMouse.pressed ? "#d5e1e8" : passMouse.containsMouse ? "#eef5f8" : "#f8fafb"
        border.color: "#b5c2c9"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: app.trText("passMove")
            color: "#26333b"
            font.pixelSize: app.compactLayout ? 11 : 12
            font.bold: true
        }

        ToolTip.visible: passMouse.containsMouse
        ToolTip.text: app.trText("passMoveTooltip")

        MouseArea {
            id: passMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                app.passMove()
                app.focusBoardInput()
            }
        }
    }

    component PlayModeButton: Rectangle {
        id: modeButton
        property int mode: 0
        property string text: ""
        readonly property bool selected: app.playMode === mode

        enabled: app.engineReadyForPlayMode()
        Layout.preferredWidth: app.compactLayout ? 54 : 68
        Layout.preferredHeight: app.compactLayout ? 28 : 32
        radius: 4
        opacity: enabled ? 1 : 0.48
        color: selected ? "#d8e9f1" : modeMouse.containsMouse ? "#eef5f8" : "#f8fafb"
        border.color: selected ? "#2e8eb0" : "#b5c2c9"
        border.width: selected ? 2 : 1

        Text {
            anchors.centerIn: parent
            width: parent.width - 6
            text: modeButton.text
            color: "#26333b"
            font.pixelSize: app.compactLayout ? 10 : 12
            font.bold: modeButton.selected
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        MouseArea {
            id: modeMouse
            anchors.fill: parent
            enabled: modeButton.enabled
            hoverEnabled: true
            onClicked: {
                app.setPlayMode(modeButton.mode)
                app.focusBoardInput()
            }
        }
    }

    component RuleButton: Rectangle {
        id: ruleButton
        property int mode: 0
        property string text: ""
        readonly property bool selected: app.gameRuleMode === mode

        Layout.preferredWidth: app.compactLayout ? 44 : 56
        Layout.preferredHeight: app.compactLayout ? 28 : 32
        radius: 4
        color: selected ? "#d8e9f1" : ruleMouse.containsMouse ? "#eef5f8" : "#f8fafb"
        border.color: selected ? "#2e8eb0" : "#b5c2c9"
        border.width: selected ? 2 : 1

        Text {
            anchors.centerIn: parent
            text: ruleButton.text
            color: "#26333b"
            font.pixelSize: app.compactLayout ? 12 : 14
            font.bold: ruleButton.selected
        }

        MouseArea {
            id: ruleMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                app.requestRuleModeChange(ruleButton.mode)
                app.focusBoardInput()
            }
        }
    }

    component ToolbarPresentationCombo: Basic.ComboBox {
        id: control

        required property var app
        property var options: []
        signal picked(int index)

        model: options
        textRole: "label"
        valueRole: "value"
        leftPadding: 9
        rightPadding: 28
        onActivated: function(index) { picked(index) }

        contentItem: Text {
            leftPadding: control.leftPadding
            rightPadding: control.rightPadding
            text: control.displayText
            color: "#17212a"
            font.pixelSize: control.app.compactLayout ? 13 : 15
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        indicator: Canvas {
            id: toolbarComboArrow
            x: control.width - width - 9
            y: Math.round((control.height - height) / 2)
            width: 12
            height: 8

            Connections {
                target: control
                function onHoveredChanged() { toolbarComboArrow.requestPaint() }
                function onPressedChanged() { toolbarComboArrow.requestPaint() }
            }

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = control.pressed ? "#1f6f8d" : "#6b7880"
                ctx.beginPath()
                ctx.moveTo(1, 1)
                ctx.lineTo(width - 1, 1)
                ctx.lineTo(width / 2, height - 1)
                ctx.closePath()
                ctx.fill()
            }
        }

        background: Rectangle {
            radius: 5
            color: control.pressed ? "#dcecf3"
                                 : control.hovered ? "#eef7fa" : "#f8fbfd"
            border.color: control.activeFocus ? "#2a91c9" : "#a8bac5"
            border.width: control.activeFocus ? 2 : 1
        }

        delegate: Basic.ItemDelegate {
            id: optionDelegate

            width: control.width
            height: control.app.compactLayout ? 30 : 34
            highlighted: control.highlightedIndex === index
            hoverEnabled: true

            contentItem: Text {
                text: modelData.label
                color: "#14242e"
                font.pixelSize: control.app.compactLayout ? 12 : 13
                verticalAlignment: Text.AlignVCenter
                leftPadding: 10
                elide: Text.ElideRight
            }

            background: Rectangle {
                color: optionDelegate.highlighted ? "#d8e9f1"
                                                  : optionDelegate.hovered ? "#edf5f8" : "#ffffff"
            }
        }
    }
}
