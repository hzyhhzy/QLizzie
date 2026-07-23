import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

AppDialog {
    id: gameOverDialog

    modal: false
    title: app.trText("gameOverTitle")
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    preferredWidth: Math.min(360, app.width - 80)

    contentItem: ColumnLayout {
        spacing: 16

        Label {
            text: app.gameOverDialogText()
            color: "#17212a"
            wrapMode: Text.WordWrap
            font.pixelSize: 16
            font.bold: true
            Layout.fillWidth: true
        }

        SavePromptButton {
            text: app.trText("confirm")
            primary: true
            Layout.alignment: Qt.AlignRight
            onClicked: {
                gameOverDialog.close()
                app.focusBoardInput()
            }
        }
    }
}
