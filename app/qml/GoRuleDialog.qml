import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

AppDialog {
    id: goRuleDialog

    property int scoringRule: app.goScoringArea
    property int koRule: app.goKoPositional
    property bool suicideAllowed: true
    property int taxRule: app.goTaxNone
    property string handicapBonus: "N"
    property bool buttonRule: false
    property bool applyToApp: true

    signal rulesAccepted(int scoringRule, int koRule, bool suicideAllowed,
                         int taxRule, string handicapBonus, bool buttonRule)

    modal: true
    title: app.trText("goRuleDialogTitle")
    padding: 16
    width: Math.min(780, app.width - 42)
    height: Math.min(430, app.height - 42)

    function openWithCurrent() {
        applyToApp = true
        openWithRules(app.goScoringRule, app.goKoRule, app.goSuicideAllowed,
                      app.goTaxRule, app.goWhiteHandicapBonus, app.goButtonRule)
        applyToApp = true
    }

    function openWithRules(scoring, ko, suicide, tax, handicap, hasButton) {
        scoringRule = Math.round(app.clamp(Number(scoring), app.goScoringArea, app.goScoringTerritory))
        koRule = Math.round(app.clamp(Number(ko), app.goKoSimple, app.goKoSituational))
        suicideAllowed = suicide === true
        taxRule = Math.round(app.clamp(Number(tax), app.goTaxNone, app.goTaxAll))
        handicapBonus = handicap === "0" || handicap === "N-1" ? handicap : "N"
        buttonRule = hasButton === true
        open()
    }

    function setChineseRules() {
        scoringRule = app.goScoringArea
        koRule = app.goKoSimple
        suicideAllowed = false
        taxRule = app.goTaxNone
        handicapBonus = "N"
        buttonRule = false
    }

    function setJapaneseRules() {
        scoringRule = app.goScoringTerritory
        koRule = app.goKoSimple
        suicideAllowed = false
        taxRule = app.goTaxSeki
        handicapBonus = "0"
        buttonRule = false
    }

    function setChineseAncientRules() {
        scoringRule = app.goScoringArea
        koRule = app.goKoSimple
        suicideAllowed = false
        taxRule = app.goTaxAll
        handicapBonus = "N"
        buttonRule = false
    }

    function setTrompTaylorRules() {
        scoringRule = app.goScoringArea
        koRule = app.goKoPositional
        suicideAllowed = true
        taxRule = app.goTaxNone
        handicapBonus = "N"
        buttonRule = false
    }

    function isChineseRules() {
        return scoringRule === app.goScoringArea && koRule === app.goKoSimple
                && !suicideAllowed && taxRule === app.goTaxNone
                && handicapBonus === "N" && !buttonRule
    }

    function isJapaneseRules() {
        return scoringRule === app.goScoringTerritory && koRule === app.goKoSimple
                && !suicideAllowed && taxRule === app.goTaxSeki
                && handicapBonus === "0" && !buttonRule
    }

    function isChineseAncientRules() {
        return scoringRule === app.goScoringArea && koRule === app.goKoSimple
                && !suicideAllowed && taxRule === app.goTaxAll
                && handicapBonus === "N" && !buttonRule
    }

    function isTrompTaylorRules() {
        return scoringRule === app.goScoringArea && koRule === app.goKoPositional
                && suicideAllowed && taxRule === app.goTaxNone
                && handicapBonus === "N" && !buttonRule
    }

    function applyRules() {
        if (applyToApp)
            app.applyGoRuleSettings(scoringRule, koRule, suicideAllowed, taxRule, handicapBonus, buttonRule)
        else
            rulesAccepted(scoringRule, koRule, suicideAllowed, taxRule, handicapBonus, buttonRule)
        close()
    }

    component FieldLabel: Label {
        color: "#52636d"
        font.pixelSize: goRuleDialog.app.compactLayout ? 12 : 13
        verticalAlignment: Text.AlignVCenter
        Layout.preferredWidth: 116
    }

    component PresetButton: Basic.Button {
        id: presetButton

        property bool selected: false
        property bool primary: false

        implicitHeight: 32
        implicitWidth: 126

        contentItem: Text {
            text: presetButton.text
            color: presetButton.primary ? "#ffffff" : "#17212a"
            font.pixelSize: goRuleDialog.app.compactLayout ? 12 : 13
            font.bold: presetButton.selected || presetButton.primary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            radius: 5
            color: presetButton.primary ? (presetButton.pressed ? "#1f6f8d" : "#2b8cc4")
                 : presetButton.pressed ? "#dcecf3"
                 : presetButton.selected ? "#e1f2f8"
                 : presetButton.hovered ? "#eef7fa" : "#f8fbfd"
            border.color: presetButton.primary ? "#1f6f8d"
                         : presetButton.selected ? "#2e8eb0"
                         : presetButton.activeFocus ? "#2a91c9" : "#a8bac5"
            border.width: presetButton.selected || presetButton.activeFocus ? 2 : 1
        }
    }

    component RuleChoice: Item {
        id: ruleChoice

        property string text: ""
        property bool checked: false
        signal clicked()

        implicitWidth: 150
        implicitHeight: 32

        RowLayout {
            anchors.fill: parent
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 12
                color: "#ffffff"
                border.color: ruleChoice.checked ? "#2e8eb0"
                             : choiceMouse.containsMouse ? "#6f9dad" : "#9fa8ad"
                border.width: ruleChoice.checked ? 2 : 1

                Rectangle {
                    anchors.centerIn: parent
                    visible: ruleChoice.checked
                    width: 14
                    height: 14
                    radius: 7
                    color: "#000000"
                }
            }

            Text {
                text: ruleChoice.text
                color: "#24313a"
                font.pixelSize: goRuleDialog.app.compactLayout ? 12 : 13
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        MouseArea {
            id: choiceMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: ruleChoice.clicked()
        }
    }

    contentItem: ColumnLayout {
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            FieldLabel { text: goRuleDialog.app.trText("classicRules") }
            PresetButton {
                text: goRuleDialog.app.trText("goRuleChinese")
                selected: goRuleDialog.isChineseRules()
                Layout.preferredWidth: 126
                onClicked: goRuleDialog.setChineseRules()
            }
            PresetButton {
                text: goRuleDialog.app.trText("goRuleJapanese")
                selected: goRuleDialog.isJapaneseRules()
                Layout.preferredWidth: 126
                onClicked: goRuleDialog.setJapaneseRules()
            }
            PresetButton {
                text: goRuleDialog.app.trText("goRuleChineseAncient")
                selected: goRuleDialog.isChineseAncientRules()
                Layout.preferredWidth: 126
                onClicked: goRuleDialog.setChineseAncientRules()
            }
            PresetButton {
                text: goRuleDialog.app.trText("goRuleTrompTaylor")
                selected: goRuleDialog.isTrompTaylorRules()
                Layout.preferredWidth: 164
                onClicked: goRuleDialog.setTrompTaylorRules()
            }
            Item { Layout.fillWidth: true }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: "#d5e1e7"
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            FieldLabel { text: goRuleDialog.app.trText("goScoringRule") }
            RuleChoice { text: goRuleDialog.app.trText("goScoringArea"); checked: goRuleDialog.scoringRule === goRuleDialog.app.goScoringArea; Layout.preferredWidth: 150; onClicked: goRuleDialog.scoringRule = goRuleDialog.app.goScoringArea }
            RuleChoice { text: goRuleDialog.app.trText("goScoringTerritory"); checked: goRuleDialog.scoringRule === goRuleDialog.app.goScoringTerritory; Layout.preferredWidth: 150; onClicked: goRuleDialog.scoringRule = goRuleDialog.app.goScoringTerritory }
            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            FieldLabel { text: goRuleDialog.app.trText("goKoRule") }
            RuleChoice { text: goRuleDialog.app.trText("goKoSimple"); checked: goRuleDialog.koRule === goRuleDialog.app.goKoSimple; Layout.preferredWidth: 150; onClicked: goRuleDialog.koRule = goRuleDialog.app.goKoSimple }
            RuleChoice { text: goRuleDialog.app.trText("goKoPositional"); checked: goRuleDialog.koRule === goRuleDialog.app.goKoPositional; Layout.preferredWidth: 150; onClicked: goRuleDialog.koRule = goRuleDialog.app.goKoPositional }
            RuleChoice { text: goRuleDialog.app.trText("goKoSituational"); checked: goRuleDialog.koRule === goRuleDialog.app.goKoSituational; Layout.preferredWidth: 190; onClicked: goRuleDialog.koRule = goRuleDialog.app.goKoSituational }
            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            FieldLabel { text: goRuleDialog.app.trText("goSuicideAllowed") }
            RuleChoice { text: goRuleDialog.app.trText("yes"); checked: goRuleDialog.suicideAllowed; Layout.preferredWidth: 150; onClicked: goRuleDialog.suicideAllowed = true }
            RuleChoice { text: goRuleDialog.app.trText("no"); checked: !goRuleDialog.suicideAllowed; Layout.preferredWidth: 150; onClicked: goRuleDialog.suicideAllowed = false }
            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            FieldLabel { text: goRuleDialog.app.trText("goTaxRule") }
            RuleChoice { text: goRuleDialog.app.trText("goTaxNone"); checked: goRuleDialog.taxRule === goRuleDialog.app.goTaxNone; Layout.preferredWidth: 150; onClicked: goRuleDialog.taxRule = goRuleDialog.app.goTaxNone }
            RuleChoice { text: goRuleDialog.app.trText("goTaxSeki"); checked: goRuleDialog.taxRule === goRuleDialog.app.goTaxSeki; Layout.preferredWidth: 150; onClicked: goRuleDialog.taxRule = goRuleDialog.app.goTaxSeki }
            RuleChoice { text: goRuleDialog.app.trText("goTaxAll"); checked: goRuleDialog.taxRule === goRuleDialog.app.goTaxAll; Layout.preferredWidth: 150; onClicked: goRuleDialog.taxRule = goRuleDialog.app.goTaxAll }
            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            FieldLabel { text: goRuleDialog.app.trText("goWhiteHandicapBonus") }
            RuleChoice { text: goRuleDialog.app.trText("goHandicapNone"); checked: goRuleDialog.handicapBonus === "0"; Layout.preferredWidth: 150; onClicked: goRuleDialog.handicapBonus = "0" }
            RuleChoice { text: goRuleDialog.app.trText("goHandicapN"); checked: goRuleDialog.handicapBonus === "N"; Layout.preferredWidth: 150; onClicked: goRuleDialog.handicapBonus = "N" }
            RuleChoice { text: goRuleDialog.app.trText("goHandicapNMinusOne"); checked: goRuleDialog.handicapBonus === "N-1"; Layout.preferredWidth: 150; onClicked: goRuleDialog.handicapBonus = "N-1" }
            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            FieldLabel { text: goRuleDialog.app.trText("goButtonRule") }
            RuleChoice { text: goRuleDialog.app.trText("yes"); checked: goRuleDialog.buttonRule; Layout.preferredWidth: 150; onClicked: goRuleDialog.buttonRule = true }
            RuleChoice { text: goRuleDialog.app.trText("no"); checked: !goRuleDialog.buttonRule; Layout.preferredWidth: 150; onClicked: goRuleDialog.buttonRule = false }
            Item { Layout.fillWidth: true }
        }
    }

    footer: AppDialogFooter {
        Item { Layout.fillWidth: true }
        PresetButton {
            text: goRuleDialog.app.trText("confirm")
            primary: true
            Layout.preferredWidth: 108
            onClicked: goRuleDialog.applyRules()
        }
        PresetButton {
            text: goRuleDialog.app.trText("cancel")
            Layout.preferredWidth: 108
            onClicked: goRuleDialog.close()
        }
    }
}
