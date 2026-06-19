import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

AppDialog {
    id: gomokuRuleDialog

    property int ruleMode: app.gomokuRuleFreestyle
    property int maxMoves: 0
    property string vcnRule: "NOVC"
    property bool firstPassWin: false
    property bool applyToApp: true

    signal rulesAccepted(int ruleMode, int maxMoves, string vcnRule, bool firstPassWin)

    modal: true
    title: app.trText("gomokuRuleDialogTitle")
    padding: 16
    width: Math.min(680, app.width - 42)
    height: Math.min(340, app.height - 42)

    function openWithCurrent() {
        applyToApp = true
        openWithRules(app.gomokuRuleMode, app.gomokuRuleMaxMoves,
                      app.gomokuRuleVcn, app.gomokuRuleFirstPassWin)
        applyToApp = true
    }

    function openWithRules(rule, moves, vcn, passWin) {
        ruleMode = app.normalizedGomokuRuleMode(rule)
        maxMoves = Math.round(app.clamp(Number(moves), 0, app.maxLargeIntegerSetting))
        vcnRule = app.normalizedGomokuVcnRule(vcn)
        firstPassWin = passWin === true
        if (firstPassWin)
            vcnRule = "NOVC"
        open()
    }

    function applyRules() {
        commitMaxMoves()
        if (firstPassWin)
            vcnRule = "NOVC"
        if (applyToApp)
            app.applyGomokuRuleSettings(ruleMode, maxMoves, vcnRule, firstPassWin)
        else
            rulesAccepted(ruleMode, maxMoves, vcnRule, firstPassWin)
        close()
    }

    function specialRuleIndex() {
        if (ruleMode === app.gomokuRuleCaro)
            return 0
        if (ruleMode === app.gomokuRuleCaroNoSix)
            return 1
        if (ruleMode === app.gomokuRuleDirectFour)
            return 2
        return -1
    }

    function commitMaxMoves() {
        var value = Number(maxMovesField.text)
        if (isNaN(value))
            value = maxMoves
        maxMoves = Math.round(app.clamp(value, 0, app.maxLargeIntegerSetting))
        maxMovesField.text = String(maxMoves)
    }

    function adjustMaxMoves(delta) {
        commitMaxMoves()
        maxMoves = Math.round(app.clamp(maxMoves + delta, 0, app.maxLargeIntegerSetting))
        maxMovesField.text = String(maxMoves)
    }

    function setVcnRule(rule) {
        vcnRule = rule
        if (rule !== "NOVC")
            firstPassWin = false
    }

    function setFirstPassWin(enabled) {
        firstPassWin = enabled
        if (enabled)
            vcnRule = "NOVC"
    }

    function resetExtraRules() {
        maxMoves = 0
        maxMovesField.text = "0"
        vcnRule = "NOVC"
        firstPassWin = false
    }

    component FieldLabel: Label {
        color: "#52636d"
        font.pixelSize: gomokuRuleDialog.app.compactLayout ? 12 : 13
        verticalAlignment: Text.AlignVCenter
        Layout.preferredWidth: 92
    }

    component ChoiceButton: Basic.Button {
        id: choiceButton

        property bool selected: false
        property bool primary: false

        implicitHeight: 32
        implicitWidth: 98

        contentItem: Text {
            text: choiceButton.text
            color: choiceButton.primary ? "#ffffff" : "#17212a"
            font.pixelSize: gomokuRuleDialog.app.compactLayout ? 12 : 13
            font.bold: choiceButton.selected || choiceButton.primary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            radius: 5
            color: choiceButton.primary ? (choiceButton.pressed ? "#1f6f8d" : "#2b8cc4")
                 : choiceButton.pressed ? "#dcecf3"
                 : choiceButton.selected ? "#e1f2f8"
                 : choiceButton.hovered ? "#eef7fa" : "#f8fbfd"
            border.color: choiceButton.primary ? "#1f6f8d"
                         : choiceButton.selected ? "#2e8eb0"
                         : choiceButton.activeFocus ? "#2a91c9" : "#a8bac5"
            border.width: choiceButton.selected || choiceButton.activeFocus ? 2 : 1
        }
    }

    component StyledCombo: Basic.ComboBox {
        id: combo

        property string placeholderText: ""

        implicitHeight: 32
        textRole: "label"

        contentItem: Text {
            leftPadding: 10
            rightPadding: 28
            text: combo.currentIndex >= 0 && combo.model && combo.model[combo.currentIndex]
                  ? combo.model[combo.currentIndex].label : combo.placeholderText
            color: "#17212a"
            font.pixelSize: gomokuRuleDialog.app.compactLayout ? 12 : 13
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        indicator: Canvas {
            x: combo.width - width - 10
            y: Math.round((combo.height - height) / 2)
            width: 12
            height: 8
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = combo.pressed ? "#1f6f8d" : "#6b7880"
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
            color: combo.pressed ? "#dcecf3" : combo.hovered ? "#eef7fa" : "#f8fbfd"
            border.color: combo.activeFocus ? "#2a91c9" : "#a8bac5"
            border.width: combo.activeFocus ? 2 : 1
        }

        delegate: Basic.ItemDelegate {
            id: optionDelegate
            width: combo.width
            height: 32
            hoverEnabled: true
            contentItem: Text {
                text: modelData.label
                color: "#17212a"
                font.pixelSize: gomokuRuleDialog.app.compactLayout ? 12 : 13
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

    component SpinStepButton: Rectangle {
        id: spinStepButton

        property bool up: true
        signal clicked()

        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 2
        color: stepMouse.pressed ? "#cfdbe1" : stepMouse.containsMouse ? "#dde6eb" : "#f7fafb"
        border.color: "#aebbc2"

        Canvas {
            id: stepArrow
            anchors.centerIn: parent
            width: 9
            height: 7

            Connections {
                target: spinStepButton
                function onUpChanged() { stepArrow.requestPaint() }
            }

            Connections {
                target: stepMouse
                function onContainsMouseChanged() { stepArrow.requestPaint() }
                function onPressedChanged() { stepArrow.requestPaint() }
            }

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = stepMouse.pressed ? "#122530" : "#26333b"
                ctx.beginPath()
                if (spinStepButton.up) {
                    ctx.moveTo(width / 2, 1)
                    ctx.lineTo(width - 1, height - 1)
                    ctx.lineTo(1, height - 1)
                } else {
                    ctx.moveTo(1, 1)
                    ctx.lineTo(width - 1, 1)
                    ctx.lineTo(width / 2, height - 1)
                }
                ctx.closePath()
                ctx.fill()
            }
        }

        MouseArea {
            id: stepMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: spinStepButton.clicked()
        }
    }

    component CheckSquare: Item {
        id: checkSquare

        property bool checked: false
        signal toggled()

        Layout.preferredWidth: 24
        Layout.preferredHeight: 24

        Rectangle {
            anchors.fill: parent
            radius: 3
            color: checkMouse.pressed ? "#dcecf3" : checkMouse.containsMouse ? "#eef7fa" : "#ffffff"
            border.color: checkSquare.checked ? "#2e8eb0"
                         : checkSquare.activeFocus ? "#2a91c9" : "#9fa8ad"
            border.width: checkSquare.checked || checkSquare.activeFocus ? 2 : 1
        }

        Canvas {
            id: checkCanvas
            anchors.fill: parent

            Connections {
                target: checkSquare
                function onCheckedChanged() { checkCanvas.requestPaint() }
            }

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                if (!checkSquare.checked)
                    return
                ctx.strokeStyle = "#0b6fb7"
                ctx.lineWidth = 3
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                ctx.beginPath()
                ctx.moveTo(width * 0.25, height * 0.53)
                ctx.lineTo(width * 0.43, height * 0.70)
                ctx.lineTo(width * 0.76, height * 0.30)
                ctx.stroke()
            }
        }

        MouseArea {
            id: checkMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: checkSquare.toggled()
        }
    }

    contentItem: ColumnLayout {
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            FieldLabel { text: gomokuRuleDialog.app.trText("gomokuBasicRule") }

            ChoiceButton {
                text: gomokuRuleDialog.app.trText("gomokuRuleFreestyle")
                selected: gomokuRuleDialog.ruleMode === gomokuRuleDialog.app.gomokuRuleFreestyle
                Layout.preferredWidth: 104
                onClicked: gomokuRuleDialog.ruleMode = gomokuRuleDialog.app.gomokuRuleFreestyle
            }
            ChoiceButton {
                text: gomokuRuleDialog.app.trText("gomokuRuleStandard")
                selected: gomokuRuleDialog.ruleMode === gomokuRuleDialog.app.gomokuRuleStandard
                Layout.preferredWidth: 126
                onClicked: gomokuRuleDialog.ruleMode = gomokuRuleDialog.app.gomokuRuleStandard
            }
            ChoiceButton {
                text: gomokuRuleDialog.app.trText("gomokuRuleRenju")
                selected: gomokuRuleDialog.ruleMode === gomokuRuleDialog.app.gomokuRuleRenju
                Layout.preferredWidth: 104
                onClicked: gomokuRuleDialog.ruleMode = gomokuRuleDialog.app.gomokuRuleRenju
            }
            StyledCombo {
                id: specialRuleCombo
                Layout.preferredWidth: 142
                model: [
                    { "label": gomokuRuleDialog.app.trText("gomokuRuleCaro"), "value": gomokuRuleDialog.app.gomokuRuleCaro },
                    { "label": gomokuRuleDialog.app.trText("gomokuRuleCaroNoSix"), "value": gomokuRuleDialog.app.gomokuRuleCaroNoSix },
                    { "label": gomokuRuleDialog.app.trText("gomokuRuleDirectFour"), "value": gomokuRuleDialog.app.gomokuRuleDirectFour }
                ]
                currentIndex: gomokuRuleDialog.specialRuleIndex()
                placeholderText: gomokuRuleDialog.app.trText("gomokuSpecialRules")
                onActivated: function(index) { gomokuRuleDialog.ruleMode = model[index].value }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: "#d5e1e7"
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            FieldLabel { text: gomokuRuleDialog.app.trText("gomokuMaxMoves") }

            Rectangle {
                Layout.preferredWidth: 136
                implicitHeight: 32
                radius: 4
                color: "#ffffff"
                border.color: maxMovesField.activeFocus ? "#2a91c9" : "#9fb0b8"
                border.width: maxMovesField.activeFocus ? 2 : 1

                Basic.TextField {
                    id: maxMovesField
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 26
                    text: String(gomokuRuleDialog.maxMoves)
                    color: "#111820"
                    font.pixelSize: gomokuRuleDialog.app.compactLayout ? 12 : 13
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    selectByMouse: true
                    inputMethodHints: Qt.ImhDigitsOnly
                    validator: IntValidator {
                        bottom: 0
                        top: gomokuRuleDialog.app.maxLargeIntegerSetting
                    }
                    background: Item {}
                    onEditingFinished: gomokuRuleDialog.commitMaxMoves()
                    Keys.onReturnPressed: gomokuRuleDialog.commitMaxMoves()

                    Connections {
                        target: gomokuRuleDialog
                        function onMaxMovesChanged() {
                            if (!maxMovesField.activeFocus)
                                maxMovesField.text = String(gomokuRuleDialog.maxMoves)
                        }
                    }
                }

                ColumnLayout {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 2
                    width: 20
                    spacing: 1

                    SpinStepButton {
                        up: true
                        onClicked: gomokuRuleDialog.adjustMaxMoves(1)
                    }
                    SpinStepButton {
                        up: false
                        onClicked: gomokuRuleDialog.adjustMaxMoves(-1)
                    }
                }
            }

            Label {
                text: gomokuRuleDialog.app.trText("zeroUnlimited")
                color: "#61727c"
                font.pixelSize: gomokuRuleDialog.app.compactLayout ? 12 : 13
            }
            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            FieldLabel { text: gomokuRuleDialog.app.trText("gomokuVcnRule") }
            ChoiceButton { text: gomokuRuleDialog.app.trText("gomokuVcnNone"); selected: gomokuRuleDialog.vcnRule === "NOVC"; Layout.preferredWidth: 82; onClicked: gomokuRuleDialog.setVcnRule("NOVC") }
            ChoiceButton { text: gomokuRuleDialog.app.trText("gomokuVcnBlackVct"); selected: gomokuRuleDialog.vcnRule === "VCTB"; Layout.preferredWidth: 92; onClicked: gomokuRuleDialog.setVcnRule("VCTB") }
            ChoiceButton { text: gomokuRuleDialog.app.trText("gomokuVcnWhiteVct"); selected: gomokuRuleDialog.vcnRule === "VCTW"; Layout.preferredWidth: 92; onClicked: gomokuRuleDialog.setVcnRule("VCTW") }
            ChoiceButton { text: gomokuRuleDialog.app.trText("gomokuVcnBlackVc2"); selected: gomokuRuleDialog.vcnRule === "VC2B"; Layout.preferredWidth: 92; onClicked: gomokuRuleDialog.setVcnRule("VC2B") }
            ChoiceButton { text: gomokuRuleDialog.app.trText("gomokuVcnWhiteVc2"); selected: gomokuRuleDialog.vcnRule === "VC2W"; Layout.preferredWidth: 92; onClicked: gomokuRuleDialog.setVcnRule("VC2W") }
            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            FieldLabel { text: gomokuRuleDialog.app.trText("gomokuFirstPassWin") }
            CheckSquare {
                checked: gomokuRuleDialog.firstPassWin
                onToggled: gomokuRuleDialog.setFirstPassWin(!gomokuRuleDialog.firstPassWin)
            }
            Item { Layout.fillWidth: true }
            ChoiceButton {
                text: gomokuRuleDialog.app.trText("reset")
                Layout.preferredWidth: 82
                onClicked: gomokuRuleDialog.resetExtraRules()
            }
        }

        Label {
            text: gomokuRuleDialog.app.trText("gomokuRuleEngineOnlyTip")
            color: "#61727c"
            font.pixelSize: gomokuRuleDialog.app.compactLayout ? 12 : 13
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }

    footer: AppDialogFooter {
        Item { Layout.fillWidth: true }
        ChoiceButton {
            text: gomokuRuleDialog.app.trText("confirm")
            primary: true
            Layout.preferredWidth: 108
            onClicked: gomokuRuleDialog.applyRules()
        }
        ChoiceButton {
            text: gomokuRuleDialog.app.trText("cancel")
            Layout.preferredWidth: 108
            onClicked: gomokuRuleDialog.close()
        }
    }
}
