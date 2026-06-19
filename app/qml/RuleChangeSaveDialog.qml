import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

AppDialog {
    id: ruleChangeSaveDialog

    modal: true
    title: app.pendingClearTitle()
    closePolicy: Popup.CloseOnEscape
    width: Math.max(400, Math.min(480, app.width - 80))

    contentItem: Rectangle {
        implicitWidth: 440
        implicitHeight: Math.max(72, messageLabel.implicitHeight + 24)
        color: "#f8fbfd"

        Label {
            id: messageLabel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 2
            anchors.rightMargin: 2
            text: app.pendingClearMessage()
            color: "#17212a"
            wrapMode: Text.WordWrap
            font.pixelSize: 15
            lineHeight: 1.12
        }
    }

    footer: AppDialogFooter {
        Item { Layout.fillWidth: true }

        SavePromptButton {
            text: app.trText("save")
            primary: true
            onClicked: {
                ruleChangeSaveDialog.close()
                app.openSaveSgfDialog(false)
            }
        }

        SavePromptButton {
            text: app.trText("dontSave")
            onClicked: {
                ruleChangeSaveDialog.close()
                app.applyPendingClearAction()
            }
        }

        SavePromptButton {
            text: app.trText("cancel")
            onClicked: {
                ruleChangeSaveDialog.close()
                app.clearPendingClearAction()
                app.onSettingsDialogClosed()
                app.focusBoardInput()
            }
        }
    }
}
