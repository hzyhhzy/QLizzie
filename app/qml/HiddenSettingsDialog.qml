import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

AppDialog {
    id: hiddenDialog

    required property var controller

    modal: true
    title: app.trText("hiddenSettingsTitle")
    closePolicy: Popup.CloseOnEscape
    width: Math.min(760, app.width - 70)
    height: Math.min(640, app.height - 70)

    function openDialog() {
        syncFields()
        open()
    }

    function syncFields() {
        packageModeCombo.currentIndex = app.packageMode
    }

    onOpened: syncFields()
    onClosed: {
        app.focusBoardInput()
    }

    contentItem: ColumnLayout {
        implicitWidth: 700
        implicitHeight: 220
        spacing: 12

        Label {
            Layout.fillWidth: true
            text: app.trText("hiddenSettingsWarning")
            color: "#9b241c"
            font.pixelSize: 15
            font.bold: true
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label {
                text: app.trText("packageMode")
                color: "#24313a"
                font.pixelSize: 14
                Layout.preferredWidth: 100
            }

            AppComboBox {
                id: packageModeCombo
                model: [
                    app.trText("packageModeUniversal"),
                    app.trText("packageModeGo"),
                    app.trText("packageModeSix")
                ]
                Layout.preferredWidth: 210
                onActivated: function(index) {
                    app.packageMode = index
                    hiddenDialog.syncFields()
                }
            }

            Label {
                text: app.packageModeText(app.packageMode)
                color: "#51616b"
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true

            Item { Layout.fillWidth: true }

            SavePromptButton {
                text: app.trText("close")
                primary: true
                onClicked: hiddenDialog.close()
            }
        }
    }

}
