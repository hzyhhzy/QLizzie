import QtQuick
import QtQuick.Controls
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
    preferredWidth: boundedPreferredWidth(680, 42)
    preferredHeight: boundedPreferredHeight(410, 42)
    dialogMinimumWidth: Math.min(560, preferredWidth)
    dialogMinimumHeight: Math.min(360, preferredHeight)

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
        vcnRule = "NOVC"
        firstPassWin = false
    }

    component FieldLabel: Label {
        color: "#52636d"
        font.pixelSize: gomokuRuleDialog.app.compactLayout ? 12 : 13
        verticalAlignment: Text.AlignVCenter
        Layout.preferredWidth: 92
    }

    component ChoiceButton: AppButton {
        property bool selectionButton: false
        compact: gomokuRuleDialog.app.compactLayout
        implicitHeight: 32
        implicitWidth: 98
        Accessible.role: selectionButton ? Accessible.RadioButton : Accessible.Button
        Accessible.checked: selectionButton && selected
    }

    component StyledCombo: AppComboBox {
        compact: gomokuRuleDialog.app.compactLayout
        implicitHeight: 32
        textRole: "label"
        textPixelSize: gomokuRuleDialog.app.compactLayout ? 12 : 13
    }

    contentItem: ColumnLayout {
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            FieldLabel { text: gomokuRuleDialog.app.trText("gomokuBasicRule") }

            ChoiceButton {
                text: gomokuRuleDialog.app.trText("gomokuRuleFreestyle")
                selectionButton: true
                selected: gomokuRuleDialog.ruleMode === gomokuRuleDialog.app.gomokuRuleFreestyle
                Layout.preferredWidth: 104
                onClicked: gomokuRuleDialog.ruleMode = gomokuRuleDialog.app.gomokuRuleFreestyle
            }
            ChoiceButton {
                text: gomokuRuleDialog.app.trText("gomokuRuleStandard")
                selectionButton: true
                selected: gomokuRuleDialog.ruleMode === gomokuRuleDialog.app.gomokuRuleStandard
                Layout.preferredWidth: 126
                onClicked: gomokuRuleDialog.ruleMode = gomokuRuleDialog.app.gomokuRuleStandard
            }
            ChoiceButton {
                text: gomokuRuleDialog.app.trText("gomokuRuleRenju")
                selectionButton: true
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

            AppSpinBox {
                id: maxMovesSpin
                Layout.preferredWidth: 136
                compact: true
                implicitHeight: 32
                font.pixelSize: gomokuRuleDialog.app.compactLayout ? 12 : 13
                from: 0
                to: gomokuRuleDialog.app.maxLargeIntegerSetting
                editable: true
                value: gomokuRuleDialog.maxMoves
                Accessible.name: gomokuRuleDialog.app.trText("gomokuMaxMoves")
                onValueModified: gomokuRuleDialog.maxMoves = value
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
            ChoiceButton { text: gomokuRuleDialog.app.trText("gomokuVcnNone"); selectionButton: true; selected: gomokuRuleDialog.vcnRule === "NOVC"; Layout.preferredWidth: 82; onClicked: gomokuRuleDialog.setVcnRule("NOVC") }
            ChoiceButton { text: gomokuRuleDialog.app.trText("gomokuVcnBlackVct"); selectionButton: true; selected: gomokuRuleDialog.vcnRule === "VCTB"; Layout.preferredWidth: 92; onClicked: gomokuRuleDialog.setVcnRule("VCTB") }
            ChoiceButton { text: gomokuRuleDialog.app.trText("gomokuVcnWhiteVct"); selectionButton: true; selected: gomokuRuleDialog.vcnRule === "VCTW"; Layout.preferredWidth: 92; onClicked: gomokuRuleDialog.setVcnRule("VCTW") }
            ChoiceButton { text: gomokuRuleDialog.app.trText("gomokuVcnBlackVc2"); selectionButton: true; selected: gomokuRuleDialog.vcnRule === "VC2B"; Layout.preferredWidth: 92; onClicked: gomokuRuleDialog.setVcnRule("VC2B") }
            ChoiceButton { text: gomokuRuleDialog.app.trText("gomokuVcnWhiteVc2"); selectionButton: true; selected: gomokuRuleDialog.vcnRule === "VC2W"; Layout.preferredWidth: 92; onClicked: gomokuRuleDialog.setVcnRule("VC2W") }
            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            FieldLabel { text: gomokuRuleDialog.app.trText("gomokuFirstPassWin") }
            AppCheckBox {
                compact: true
                text: ""
                checked: gomokuRuleDialog.firstPassWin
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                Accessible.name: gomokuRuleDialog.app.trText("gomokuFirstPassWin")
                onToggled: gomokuRuleDialog.setFirstPassWin(checked)
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
