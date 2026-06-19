import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

AppDialog {
    id: initialSetupDialog

    modal: true
    title: app.trText("initialSetupTitle")
    closePolicy: Popup.NoAutoClose
    width: Math.min(440, app.width - 70)

    contentItem: ColumnLayout {
        implicitWidth: 404
        spacing: 18

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Label {
                text: app.trText("menuLanguage")
                color: "#162a36"
                font.pixelSize: 15
                font.bold: true
                Layout.preferredWidth: 86
            }

            AppComboBox {
                id: languageCombo
                Layout.fillWidth: true
                model: [
                    { "label": app.trText("languageChinese"), "value": "zh" },
                    { "label": app.trText("languageEnglish"), "value": "en" }
                ]
                textRole: "label"
                valueRole: "value"
                currentIndex: app.language === "en" ? 1 : 0
                onActivated: function(index) {
                    app.language = model[index].value
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Item { Layout.fillWidth: true }

            SavePromptButton {
                text: app.trText("startUsing")
                primary: true
                implicitWidth: 118
                onClicked: {
                    app.completeInitialSetup()
                    initialSetupDialog.close()
                }
            }
        }
    }
}
