import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

AppDialog {
    id: unsavedSgfDialog

    modal: true
    title: app.trText("unsavedGameTitle")
    closePolicy: Popup.CloseOnEscape
    width: Math.max(380, Math.min(460, app.width - 80))

    contentItem: Rectangle {
        implicitWidth: 424
        implicitHeight: Math.max(72, messageLabel.implicitHeight + 24)
        color: "#f8fbfd"

        Label {
            id: messageLabel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 2
            anchors.rightMargin: 2
            text: app.trText("confirmSaveGame")
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
                unsavedSgfDialog.close()
                app.openSaveSgfDialog(true)
            }
        }

        SavePromptButton {
            text: app.trText("dontSave")
            onClicked: {
                unsavedSgfDialog.close()
                app.closeWithoutSaving()
            }
        }

        SavePromptButton {
            text: app.trText("cancel")
            onClicked: {
                unsavedSgfDialog.close()
                app.focusBoardInput()
            }
        }
    }
}
