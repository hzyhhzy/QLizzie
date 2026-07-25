import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

Rectangle {
    id: toolbar
    required property var app
    readonly property int horizontalPadding: app.compactLayout ? 8 : 12
    readonly property int scrollButtonWidth: 24
    readonly property bool contentOverflows:
        toolbarContent.implicitWidth + horizontalPadding * 2 > width

    function maximumContentX() {
        return Math.max(0, toolbarFlick.contentWidth - toolbarFlick.width)
    }

    function setContentXClamped(value) {
        toolbarFlick.contentX = Math.max(0, Math.min(maximumContentX(), value))
    }

    function scrollBy(delta) {
        setContentXClamped(toolbarFlick.contentX + delta)
    }

    function ensureItemVisible(item) {
        if (!contentOverflows || !item || !item.activeFocus)
            return
        var position = item.mapToItem(toolbarFlick.contentItem, 0, 0)
        var itemLeft = position.x
        var itemRight = itemLeft + item.width
        if (itemLeft < toolbarFlick.contentX)
            setContentXClamped(itemLeft - horizontalPadding)
        else if (itemRight > toolbarFlick.contentX + toolbarFlick.width)
            setContentXClamped(itemRight - toolbarFlick.width + horizontalPadding)
    }

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: app.analysisToolbarHeight
    color: "#e7ecef"
    border.color: "#c4cdd2"

    Flickable {
        id: toolbarFlick
        anchors.fill: parent
        anchors.leftMargin: toolbar.contentOverflows ? toolbar.scrollButtonWidth : 0
        anchors.rightMargin: toolbar.contentOverflows ? toolbar.scrollButtonWidth : 0
        contentWidth: Math.max(width, toolbarContent.implicitWidth + toolbar.horizontalPadding * 2)
        contentHeight: height
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.HorizontalFlick
        interactive: toolbar.contentOverflows
        pixelAligned: true
        clip: true

        onContentWidthChanged: toolbar.setContentXClamped(contentX)
        onWidthChanged: toolbar.setContentXClamped(contentX)

        WheelHandler {
            enabled: toolbar.contentOverflows
            target: null
            onWheel: function(event) {
                var pixelDelta = Math.abs(event.pixelDelta.x) > Math.abs(event.pixelDelta.y)
                               ? event.pixelDelta.x : event.pixelDelta.y
                var angleDelta = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y)
                               ? event.angleDelta.x : event.angleDelta.y
                var delta = pixelDelta !== 0 ? pixelDelta : angleDelta
                if (delta === 0)
                    return
                toolbar.setContentXClamped(toolbarFlick.contentX - delta)
                event.accepted = true
            }
        }

        RowLayout {
            id: toolbarContent
            x: toolbar.horizontalPadding
            width: implicitWidth
            height: toolbarFlick.height
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
            onActiveFocusChanged: {
                if (activeFocus)
                    toolbar.ensureItemVisible(this)
            }
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
            onActiveFocusChanged: {
                if (activeFocus)
                    toolbar.ensureItemVisible(this)
            }
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
            onActiveFocusChanged: {
                if (activeFocus)
                    toolbar.ensureItemVisible(this)
            }
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

        AppSpinBox {
            id: komiSpin
            visible: app.komiControlsVisible()
            compact: true
            editable: true
            from: Math.round(app.komiMinimum() * 10)
            to: Math.round(app.komiMaximum() * 10)
            stepSize: 5
            value: Math.round(app.effectiveKomi() * 10)
            Layout.preferredWidth: app.compactLayout ? 72 : 82
            Layout.preferredHeight: app.compactLayout ? 28 : 32
            font.pixelSize: app.compactLayout ? 15 : 17
            font.bold: true
            onActiveFocusChanged: {
                if (activeFocus)
                    toolbar.ensureItemVisible(this)
            }
            textFromValue: function(value) { return (value / 10).toFixed(1) }
            valueFromText: function(text) {
                var number = Number(text)
                return isNaN(number) ? komiSpin.value : Math.round(number * 10)
            }

            onValueModified: app.setKomiValue(value / 10)
            Keys.onReturnPressed: {
                app.focusBoardInput()
            }
            Keys.onEnterPressed: {
                app.focusBoardInput()
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
            onActiveFocusChanged: {
                if (activeFocus)
                    toolbar.ensureItemVisible(this)
            }

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

                AppCheckMark {
                    anchors.fill: parent
                    anchors.margins: app.compactLayout ? 3 : 4
                    checked: wideRootNoiseEnabledBox.checked
                    markColor: "#ffffff"
                    lineWidth: app.compactLayout ? 1.8 : 2.0
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
            enabled: app.analysisWideRootNoiseEnabled
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
            color: enabled ? "#17252d" : "#80919a"
            selectedTextColor: "#ffffff"
            selectionColor: "#2e8eb0"
            font.pixelSize: app.compactLayout ? 15 : 17
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            onActiveFocusChanged: {
                if (activeFocus)
                    toolbar.ensureItemVisible(this)
            }
            background: Rectangle {
                radius: 4
                color: !wideRootNoiseField.enabled ? "#e7eef2"
                      : wideRootNoiseField.activeFocus ? "#ffffff" : "#f9fbfc"
                border.color: !wideRootNoiseField.enabled ? "#c5d0d6"
                              : wideRootNoiseField.activeFocus ? "#2e8eb0" : "#9fb0b8"
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

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: 7
            Layout.bottomMargin: 7
            color: "#c4cdd2"
        }

        Label {
            text: app.trText("aiMoveMethod")
            color: "#26333b"
            font.pixelSize: app.compactLayout ? 12 : 14
            verticalAlignment: Text.AlignVCenter
        }

        RowLayout {
            spacing: app.compactLayout ? 3 : 4

            AiMoveMethodButton {
                mode: app.aiMoveModeGtp
                text: app.trText("aiMoveModeGtp")
            }

            AiMoveMethodButton {
                mode: app.aiMoveModeAnalyze
                text: app.trText("aiMoveModeAnalyze")
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
            text: Number(app.currentAiMoveSecondsPerMove()).toFixed(1)
            selectByMouse: true
            validator: DoubleValidator {
                bottom: app.aiMoveMode === app.aiMoveModeAnalyze ? 0 : 0.1
                top: 999
                decimals: 1
                notation: DoubleValidator.StandardNotation
            }
            ToolTip.visible: hovered && app.aiMoveMode === app.aiMoveModeAnalyze
            ToolTip.text: app.trText("analysisTimeZeroTip")
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
            onActiveFocusChanged: {
                if (activeFocus)
                    toolbar.ensureItemVisible(this)
            }
            background: Rectangle {
                radius: 4
                color: secondsField.enabled ? (secondsField.activeFocus ? "#ffffff" : "#f9fbfc") : "#e2e8eb"
                border.color: secondsField.activeFocus ? "#2e8eb0" : "#b5c2c9"
                border.width: secondsField.activeFocus ? 2 : 1
            }

            function applyValue() {
                var nextValue = Number(text)
                if (!isNaN(nextValue))
                    app.setCurrentAiMoveSecondsPerMove(nextValue)
                text = Number(app.currentAiMoveSecondsPerMove()).toFixed(1)
            }

            function refreshText() {
                if (!activeFocus)
                    text = Number(app.currentAiMoveSecondsPerMove()).toFixed(1)
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
                    secondsField.refreshText()
                }
                function onAnalysisSecondsPerMoveChanged() {
                    secondsField.refreshText()
                }
                function onAiMoveModeChanged() {
                    secondsField.refreshText()
                }
            }
        }

        Label {
            text: app.trText("secondsUnit")
            color: app.engineReadyForPlayMode() ? "#26333b" : "#7f8b92"
            font.pixelSize: app.compactLayout ? 12 : 14
            verticalAlignment: Text.AlignVCenter
        }

        AppCheckBox {
            visible: app.gameRuleMode === app.gameRuleGo
            enabled: app.analysisModeActive() || app.aiMoveMode === app.aiMoveModeAnalyze
            compact: true
            text: app.trText("showOwnership")
            checked: app.ownershipEnabled
            onToggled: app.ownershipEnabled = checked
            onActiveFocusChanged: {
                if (activeFocus)
                    toolbar.ensureItemVisible(this)
            }
        }

        }
    }

    component ToolbarScrollButton: Basic.Button {
        id: scrollButton

        property int direction: 1

        visible: toolbar.contentOverflows
        enabled: direction < 0 ? toolbarFlick.contentX > 0.5
                               : toolbarFlick.contentX < toolbar.maximumContentX() - 0.5
        width: toolbar.scrollButtonWidth
        height: toolbar.height
        padding: 0
        focusPolicy: Qt.TabFocus
        z: 2
        opacity: enabled ? 1 : 0.42
        Accessible.name: direction < 0
                         ? (app.language === "zh" ? "向左滚动工具栏" : "Scroll toolbar left")
                         : (app.language === "zh" ? "向右滚动工具栏" : "Scroll toolbar right")
        Accessible.role: Accessible.Button

        onClicked: toolbar.scrollBy(direction * Math.max(140, toolbarFlick.width * 0.65))

        contentItem: Text {
            text: scrollButton.direction < 0 ? "\u25c0" : "\u25b6"
            color: scrollButton.enabled ? "#26333b" : "#829099"
            font.pixelSize: app.compactLayout ? 10 : 11
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            color: scrollButton.down ? "#cad8df"
                  : scrollButton.hovered || scrollButton.activeFocus ? "#f4f8fa"
                  : "#e7ecef"
            border.color: scrollButton.activeFocus ? "#2a91c9" : "#aab9c1"
            border.width: scrollButton.activeFocus ? 2 : 1
        }
    }

    ToolbarScrollButton {
        anchors.left: parent.left
        anchors.top: parent.top
        direction: -1
    }

    ToolbarScrollButton {
        anchors.right: parent.right
        anchors.top: parent.top
        direction: 1
    }

    component RuleSettingsButton: Basic.Button {
        id: ruleSettingsButton

        text: app.trText("ruleSettingsButton")
        Layout.preferredWidth: app.compactLayout ? 84 : 104
        Layout.preferredHeight: app.compactLayout ? 28 : 32
        padding: 0
        focusPolicy: Qt.TabFocus
        Accessible.name: text + ": " + app.ruleVariantText()
        Accessible.role: Accessible.Button
        ToolTip.visible: hovered
        ToolTip.text: app.ruleVariantText()

        onActiveFocusChanged: {
            if (activeFocus)
                toolbar.ensureItemVisible(this)
        }
        onClicked: app.openRuleVariantDialog()

        contentItem: Text {
            text: ruleSettingsButton.text
            color: "#26333b"
            font.pixelSize: app.compactLayout ? 12 : 13
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            radius: 4
            color: ruleSettingsButton.down ? "#d5e1e8"
                 : ruleSettingsButton.hovered || ruleSettingsButton.activeFocus ? "#eef5f8"
                 : "#f8fafb"
            border.color: ruleSettingsButton.activeFocus ? "#0f6f9f" : "#2e8eb0"
            border.width: ruleSettingsButton.activeFocus ? 2 : 1
        }
    }

    component StoneColorButton: Basic.Button {
        id: colorButton
        property int mode: 0
        property string tip: ""
        readonly property bool selected: app.stoneColorMode === mode

        Layout.preferredWidth: app.compactLayout ? 34 : 38
        Layout.preferredHeight: app.compactLayout ? 28 : 32
        padding: 0
        focusPolicy: Qt.TabFocus
        Accessible.name: tip
        Accessible.role: Accessible.RadioButton
        Accessible.checked: selected
        ToolTip.visible: hovered
        ToolTip.text: tip

        onActiveFocusChanged: {
            if (activeFocus)
                toolbar.ensureItemVisible(this)
        }
        onClicked: {
            app.setStoneColorMode(colorButton.mode)
            app.focusBoardInput()
        }

        contentItem: Item {

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

        background: Rectangle {
            radius: 4
            color: colorButton.selected ? "#d8e9f1"
                 : colorButton.down ? "#d5e1e8"
                 : colorButton.hovered || colorButton.activeFocus ? "#eef5f8"
                 : "#f8fafb"
            border.color: colorButton.activeFocus ? "#0f6f9f"
                          : colorButton.selected ? "#2e8eb0" : "#b5c2c9"
            border.width: colorButton.activeFocus || colorButton.selected ? 2 : 1
        }
    }

    component PassButton: Basic.Button {
        id: passButton

        text: app.trText("passMove")
        Layout.preferredWidth: app.compactLayout ? 44 : 52
        Layout.preferredHeight: app.compactLayout ? 28 : 32
        padding: 0
        focusPolicy: Qt.TabFocus
        Accessible.name: app.trText("passMoveTooltip")
        Accessible.role: Accessible.Button
        ToolTip.visible: hovered
        ToolTip.text: app.trText("passMoveTooltip")

        onActiveFocusChanged: {
            if (activeFocus)
                toolbar.ensureItemVisible(this)
        }
        onClicked: {
            app.passMove()
            app.focusBoardInput()
        }

        contentItem: Text {
            text: passButton.text
            color: "#26333b"
            font.pixelSize: app.compactLayout ? 11 : 12
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            radius: 4
            color: passButton.down ? "#d5e1e8"
                 : passButton.hovered || passButton.activeFocus ? "#eef5f8"
                 : "#f8fafb"
            border.color: passButton.activeFocus ? "#0f6f9f" : "#b5c2c9"
            border.width: passButton.activeFocus ? 2 : 1
        }
    }

    component PlayModeButton: Basic.Button {
        id: modeButton
        property int mode: 0
        readonly property bool selected: app.playMode === mode

        enabled: app.engineReadyForPlayMode()
        Layout.preferredWidth: app.compactLayout ? 54 : 68
        Layout.preferredHeight: app.compactLayout ? 28 : 32
        padding: 0
        focusPolicy: Qt.TabFocus
        opacity: enabled ? 1 : 0.48
        Accessible.name: text
        Accessible.role: Accessible.RadioButton
        Accessible.checked: selected

        onActiveFocusChanged: {
            if (activeFocus)
                toolbar.ensureItemVisible(this)
        }
        onClicked: {
            app.setPlayMode(modeButton.mode)
            app.focusBoardInput()
        }

        contentItem: Text {
            text: modeButton.text
            color: "#26333b"
            font.pixelSize: app.compactLayout ? 10 : 12
            font.bold: modeButton.selected
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            radius: 4
            color: modeButton.selected ? "#d8e9f1"
                 : modeButton.down ? "#d5e1e8"
                 : modeButton.hovered || modeButton.activeFocus ? "#eef5f8"
                 : "#f8fafb"
            border.color: modeButton.activeFocus ? "#0f6f9f"
                          : modeButton.selected ? "#2e8eb0" : "#b5c2c9"
            border.width: modeButton.activeFocus || modeButton.selected ? 2 : 1
        }
    }

    component AiMoveMethodButton: Basic.Button {
        id: aiMoveButton
        property int mode: 0
        readonly property bool selected: app.aiMoveMode === mode

        enabled: !app.applicationShutdownPrepared
        Layout.preferredWidth: app.compactLayout ? 48 : 58
        Layout.preferredHeight: app.compactLayout ? 28 : 32
        padding: 0
        focusPolicy: Qt.TabFocus
        opacity: enabled ? 1 : 0.48
        Accessible.name: app.trText("aiMoveMethod") + ": " + text
        Accessible.role: Accessible.RadioButton
        Accessible.checked: selected

        onActiveFocusChanged: {
            if (activeFocus)
                toolbar.ensureItemVisible(this)
        }
        onClicked: {
            app.setAiMoveMode(aiMoveButton.mode)
            app.focusBoardInput()
        }

        contentItem: Text {
            text: aiMoveButton.text
            color: "#26333b"
            font.pixelSize: app.compactLayout ? 10 : 12
            font.bold: aiMoveButton.selected
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            radius: 4
            color: aiMoveButton.selected ? "#d8e9f1"
                 : aiMoveButton.down ? "#d5e1e8"
                 : aiMoveButton.hovered || aiMoveButton.activeFocus ? "#eef5f8"
                 : "#f8fafb"
            border.color: aiMoveButton.activeFocus ? "#0f6f9f"
                          : aiMoveButton.selected ? "#2e8eb0" : "#b5c2c9"
            border.width: aiMoveButton.activeFocus || aiMoveButton.selected ? 2 : 1
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
