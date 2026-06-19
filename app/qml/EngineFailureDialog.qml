import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

AppDialog {
    id: engineFailureDialog

    modal: true
    tone: "error"
    title: app.trText("engineFailureTitle")
    closePolicy: Popup.CloseOnEscape
    width: Math.min(520, app.width - 80)

    contentItem: Rectangle {
        implicitWidth: 484
        implicitHeight: Math.max(62, engineFailureMessage.implicitHeight + 6)
        color: "transparent"

        Label {
            id: engineFailureMessage
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: app.engineFailureDialogText()
            color: "#4a201b"
            wrapMode: Text.WordWrap
            font.pixelSize: 15
            lineHeight: 1.12
        }
    }

    footer: AppDialogFooter {
        tone: engineFailureDialog.tone
        Item { Layout.fillWidth: true }

        SavePromptButton {
            text: app.trText("confirm")
            primary: true
            Layout.preferredWidth: 104
            onClicked: {
                engineFailureDialog.close()
                app.focusBoardInput()
            }
        }
    }
}
