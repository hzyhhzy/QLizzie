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

    contentItem: ColumnLayout {
        implicitWidth: 484
        spacing: 18

        Label {
            text: app.engineFailureDialogText()
            color: "#4a201b"
            wrapMode: Text.WordWrap
            font.pixelSize: 14
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true

            Item { Layout.fillWidth: true }

            SavePromptButton {
                text: app.trText("confirm")
                primary: true
                onClicked: {
                    engineFailureDialog.close()
                    app.focusBoardInput()
                }
            }
        }
    }
}
