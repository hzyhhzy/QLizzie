import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

AppDialog {
    id: warningDialog

    property string messageText: ""

    modal: true
    tone: "warning"
    title: app.trText("engineRuleMismatchTitle")
    closePolicy: Popup.CloseOnEscape
    width: Math.min(520, app.width - 80)

    function openForPreset(preset) {
        title = app.trText("engineRuleMismatchTitle")
        messageText = app.trText("engineRuleMismatchBody")
                      + "\n\n"
                      + app.trText("currentRule") + ": " + app.gameRuleText()
                      + "\n"
                      + app.trText("enginePresetRule") + ": " + app.enginePresetRuleDetailText(preset)
        open()
    }

    function openForSgf(gameId, expectedGameId) {
        title = app.trText("sgfGameTypeMismatchTitle")
        messageText = app.trText("sgfGameTypeMismatchBody")
                      + "\n\n"
                      + app.trText("currentRule") + ": " + app.gameRuleText()
                      + "\n"
                      + app.trText("sgfGameTypeField") + ": GM[" + gameId + "]"
                      + "\n"
                      + app.trText("expectedGameType") + ": GM[" + expectedGameId + "]"
        open()
    }

    contentItem: Rectangle {
        implicitWidth: 484
        implicitHeight: Math.max(72, warningMessage.implicitHeight + 6)
        color: "transparent"

        Label {
            id: warningMessage
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
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
