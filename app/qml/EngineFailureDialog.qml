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
    preferredWidth: boundedPreferredWidth(520, 80)
    dialogMinimumWidth: Math.min(420, preferredWidth)
    dialogMinimumHeight: Math.min(210, preferredHeight)

    contentItem: Flickable {
        id: engineFailureFlick
        implicitWidth: 484
        implicitHeight: Math.min(320, Math.max(62, engineFailureMessage.implicitHeight + 6))
        contentWidth: width
        contentHeight: Math.max(height, engineFailureMessage.implicitHeight)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: AppScrollBar {
            policy: engineFailureFlick.contentHeight > engineFailureFlick.height
                    ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
        }

        Label {
            id: engineFailureMessage
            width: engineFailureFlick.width
            y: Math.max(0, Math.round((engineFailureFlick.height - implicitHeight) / 2))
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
