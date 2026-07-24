import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

AppWindowDialog {
    id: helpDialog

    modal: true
    title: app.trText("helpKeysTitle")
    closePolicy: Popup.CloseOnEscape
    preferredWidth: boundedPreferredWidth(640, 70)
    preferredHeight: boundedPreferredHeight(620, 70)
    dialogMinimumWidth: Math.min(520, preferredWidth)
    dialogMinimumHeight: Math.min(420, preferredHeight)

    property var helpRows: [
        { "keys": "Space", "textKey": "helpKeyPauseEngineDesc" },
        { "keys": ",", "textKey": "helpKeyPlayBestDesc" },
        { "keys": "P", "textKey": "helpKeyPassDesc" },
        { "keys": "U", "textKey": "helpKeyEngineLogDesc" },
        { "keys": "Backspace", "textKey": "helpKeyDeleteDesc" },
        { "keys": "M", "textKey": "helpKeyMoveLabelsDesc" },
        { "keys": "Ctrl+O", "textKey": "helpKeyOpenSgfDesc" },
        { "keys": "Ctrl+S", "textKey": "helpKeySaveSgfDesc" },
        { "keys": "Ctrl+I", "textKey": "helpKeyBoardSizeDesc" }
    ]

    dialogBody: ColumnLayout {
        implicitWidth: 600
        implicitHeight: 500
        spacing: 12

        Flickable {
            id: helpFlick

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: helpColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: AppScrollBar {
                policy: ScrollBar.AsNeeded
            }

            ColumnLayout {
                id: helpColumn
                width: helpFlick.width - 16
                spacing: 8

                Repeater {
                    model: helpDialog.helpRows

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Math.max(42, helpRowLayout.implicitHeight + 14)
                        radius: 7
                        color: "#ffffff"
                        border.color: "#cfdae0"
                        border.width: 1

                        RowLayout {
                            id: helpRowLayout
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 8
                            anchors.rightMargin: 10
                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 118
                                Layout.preferredHeight: 28
                                radius: 5
                                color: "#e8f0f4"
                                border.color: "#9fb3bf"
                                border.width: 1

                                TextEdit {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    width: parent.width - 8
                                    text: modelData.keys
                                    readOnly: true
                                    selectByMouse: true
                                    cursorVisible: false
                                    color: "#10242f"
                                    selectionColor: "#2a91c9"
                                    selectedTextColor: "#ffffff"
                                    font.pixelSize: 14
                                    font.bold: true
                                    font.family: "Consolas"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    clip: true
                                }
                            }

                            TextEdit {
                                Layout.fillWidth: true
                                text: app.trText(modelData.textKey)
                                readOnly: true
                                selectByMouse: true
                                cursorVisible: false
                                color: "#1e2d36"
                                selectionColor: "#2a91c9"
                                selectedTextColor: "#ffffff"
                                font.pixelSize: 15
                                wrapMode: TextEdit.WordWrap
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Item { Layout.fillWidth: true }

            SavePromptButton {
                text: app.trText("close")
                primary: true
                onClicked: {
                    helpDialog.closeDialog()
                    app.focusBoardInput()
                }
            }
        }
    }
}
