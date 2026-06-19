import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

AppDialog {
    id: engineParametersDialog

    required property var controller

    modal: true
    title: app.trText("engineParameters")
    closePolicy: Popup.CloseOnEscape
    width: Math.min(720, app.width - 80)

    function openForCurrentEngine() {
        engineCommandEdit.text = controller ? controller.command : ""
        open()
    }

    contentItem: ColumnLayout {
        implicitWidth: 684
        spacing: 14

        Label {
            text: app.trText("engineCommand")
            color: "#17212a"
            font.pixelSize: 14
            Layout.fillWidth: true
        }

        AppTextArea {
            id: engineCommandEdit
            Layout.fillWidth: true
            Layout.preferredHeight: 92
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Item { Layout.fillWidth: true }

            SavePromptButton {
                text: app.trText("confirm")
                primary: true
                onClicked: {
                    if (controller && controller.command !== engineCommandEdit.text)
                        controller.command = engineCommandEdit.text
                    engineParametersDialog.close()
                    app.focusBoardInput()
                }
            }

            SavePromptButton {
                text: app.trText("cancel")
                onClicked: {
                    engineParametersDialog.close()
                    app.focusBoardInput()
                }
            }
        }
    }
}
