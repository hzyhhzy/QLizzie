import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

Basic.Dialog {
    id: initialSetupDialog

    required property var app

    modal: true
    title: app.trText("initialSetupTitle")
    closePolicy: Popup.NoAutoClose
    padding: 18
    width: Math.min(440, app.width - 70)
    x: Math.round((app.width - width) / 2)
    y: Math.round((app.height - height) / 2)

    background: Rectangle {
        radius: 10
        color: "#f8fbfd"
        border.color: "#8ea5b1"
        border.width: 1
    }

    header: Rectangle {
        height: 52
        color: "#e6eff4"
        radius: 10

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.radius
            color: parent.color
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: "#c5d4dc"
        }

        Label {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            text: initialSetupDialog.title
            color: "#14242e"
            font.pixelSize: 17
            font.bold: true
            elide: Text.ElideRight
        }
    }

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

            Basic.ComboBox {
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

                contentItem: Text {
                    leftPadding: 12
                    rightPadding: 30
                    text: languageCombo.displayText
                    color: "#14242e"
                    font.pixelSize: 15
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                background: Rectangle {
                    implicitHeight: 38
                    radius: 6
                    color: "#ffffff"
                    border.color: languageCombo.activeFocus ? "#2a91c9" : "#a8bac5"
                    border.width: languageCombo.activeFocus ? 2 : 1
                }

                delegate: Component {
                    ItemDelegate {
                        width: languageCombo.width
                        height: 42
                        highlighted: languageCombo.highlightedIndex === index

                        contentItem: Text {
                            text: modelData.label
                            color: "#14242e"
                            font.pixelSize: 15
                            font.bold: languageCombo.currentIndex === index
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 12
                        }

                        background: Rectangle {
                            color: highlighted ? "#dfeaf0" : "#ffffff"
                        }
                    }
                }

                popup: Popup {
                    y: languageCombo.height + 2
                    width: languageCombo.width
                    implicitHeight: contentItem.implicitHeight
                    padding: 1

                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: languageCombo.popup.visible ? languageCombo.delegateModel : null
                        currentIndex: languageCombo.highlightedIndex
                    }

                    background: Rectangle {
                        color: "#ffffff"
                        border.color: "#a8bac5"
                        radius: 4
                    }
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
