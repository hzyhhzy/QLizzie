import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AppDialog {
    id: warningDialog

    property string messageText: ""

    modal: true
    tone: "warning"
    title: app.trText("engineRuleMismatchTitle")
    closePolicy: Popup.CloseOnEscape
    preferredWidth: boundedPreferredWidth(520, 80)
    dialogMinimumWidth: Math.min(420, preferredWidth)
    dialogMinimumHeight: Math.min(220, preferredHeight)

    function openForPreset(preset) {
        title = app.trText("engineRuleMismatchTitle")
        messageText = app.trText("engineRuleMismatchBody")
                      + "\n\n"
                      + app.trText("currentRule") + ": " + app.gameRuleText()
                      + "\n"
                      + app.trText("enginePresetRule") + ": " + app.enginePresetRuleDetailText(preset)
        open()
    }

    function sgfRuleIdentity(gameId, ruleName) {
        var identity = "GM[" + gameId + "]"
        if (ruleName !== undefined && String(ruleName).length > 0)
            identity += "  RU[" + ruleName + "]"
        return identity
    }

    function openForSgf(gameId, expectedGameId, ruleName, expectedRuleName) {
        title = app.trText("sgfGameTypeMismatchTitle")
        messageText = app.trText("sgfGameTypeMismatchBody")
                      + "\n\n"
                      + app.trText("currentRule") + ": " + app.gameRuleText()
                      + "\n"
                      + app.trText("sgfGameTypeField") + ": "
                      + sgfRuleIdentity(gameId, ruleName)
                      + "\n"
                      + app.trText("expectedGameType") + ": "
                      + sgfRuleIdentity(expectedGameId, expectedRuleName)
        open()
    }

    contentItem: Flickable {
        id: warningFlick
        implicitWidth: 484
        implicitHeight: Math.min(320, Math.max(72, warningMessage.implicitHeight + 6))
        contentWidth: width
        contentHeight: Math.max(height, warningMessage.implicitHeight)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: AppScrollBar {
            policy: warningFlick.contentHeight > warningFlick.height
                    ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
        }

        Label {
            id: warningMessage
            width: warningFlick.width
            y: Math.max(0, Math.round((warningFlick.height - implicitHeight) / 2))
            text: warningDialog.messageText
            color: "#342414"
            font.pixelSize: 14
            wrapMode: Text.WordWrap
        }
    }

    footer: AppDialogFooter {
        tone: warningDialog.tone
        Item { Layout.fillWidth: true }

        SavePromptButton {
            text: app.trText("confirm")
            primary: true
            Layout.preferredWidth: 104
            onClicked: {
                warningDialog.close()
                app.focusBoardInput()
            }
        }
    }
}
