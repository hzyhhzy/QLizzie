import QtQuick

Rectangle {
    id: commandToolbar
    required property var app
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: app.commandToolbarHeight
    clip: true
    color: "#edf2f5"
    border.color: "#b8c5cc"

    Flickable {
        id: commandToolbarFlick
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        contentWidth: commandToolbarRow.implicitWidth
        contentHeight: height
        interactive: contentWidth > width
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds

        Row {
            id: commandToolbarRow
            height: commandToolbarFlick.height
            spacing: app.compactLayout ? 3 : 4

            Repeater {
                model: app.commandToolbarItems

                delegate: Item {
                    width: Math.round((modelData.width || 52) * (app.compactLayout ? 0.94 : 1.0))
                    height: commandToolbarRow.height

                    AppButton {
                        visible: modelData.type === "button"
                        enabled: app.toolbarActionEnabled(modelData.action || "")
                        compact: app.compactLayout
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height - (app.compactLayout ? 6 : 8)
                        text: app.language === "zh" ? modelData.zh : modelData.en
                        onClicked: app.runToolbarAction(modelData.action || "")
                    }

                    AppTextField {
                        id: moveNumberInput
                        visible: modelData.type === "moveInput"
                        property bool committingMoveNumber: false
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height - (app.compactLayout ? 6 : 8)
                        selectByMouse: true
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter
                        font.pixelSize: app.compactLayout ? 12 : 13
                        validator: IntValidator {
                            bottom: 0
                            top: app.maxMoveNumberValue()
                        }
                        function commitMoveNumber() {
                            if (committingMoveNumber)
                                return

                            committingMoveNumber = true
                            app.gotoMoveNumber(parseInt(text, 10))
                            text = app.currentMoveNumberText()
                            committingMoveNumber = false
                        }
                        Component.onCompleted: text = app.currentMoveNumberText()
                        onActiveFocusChanged: {
                            if (activeFocus)
                                selectAll()
                        }
                        onAccepted: {
                            commitMoveNumber()
                            app.focusBoardInput()
                        }
                        onEditingFinished: commitMoveNumber()

                        Connections {
                            target: app

                            function onCurrentNodeIdChanged() {
                                if (!moveNumberInput.activeFocus)
                                    moveNumberInput.text = app.currentMoveNumberText()
                            }

                            function onBoardRevisionChanged() {
                                if (!moveNumberInput.activeFocus)
                                    moveNumberInput.text = app.currentMoveNumberText()
                            }
                        }
                    }
                }
            }
        }
    }
}
