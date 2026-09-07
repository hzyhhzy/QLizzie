import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AppPopup {

    required property bool compactLayout
    required property real viewportWidth
    required property real viewportHeight
    required property int gameRuleMode
    required property var translate
    required property var rowsForGroups
    required property var initialCollapsedGroups
    required property var groupVisibilityState
    required property var modeVisible
    required property var groupMutable
    required property var commonOptions
    signal modesVisibilityRequested(var modes, bool visible)
    signal modeVisibilityRequested(int mode, bool visible)
    signal reorderRequested(int mode, int delta)

    id: commonGameRulesPopup

    property var collapsedGroups: ({})
    readonly property int leftRuleColumnWidth: commonGameRulesPopup.compactLayout ? 260 : 330
    readonly property int treeDepthStep: commonGameRulesPopup.compactLayout ? 20 : 24
    readonly property int treeNodeCenter: commonGameRulesPopup.compactLayout ? 28 : 34
    readonly property int treeCheckOffset: commonGameRulesPopup.compactLayout ? 34 : 38
    readonly property int treeNameOffset: commonGameRulesPopup.compactLayout ? 66 : 76
    readonly property int commonCheckSize: commonGameRulesPopup.compactLayout ? 18 : 20

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    width: Math.min(commonGameRulesPopup.viewportWidth - 80, commonGameRulesPopup.compactLayout ? 640 : 860)
    height: Math.min(commonGameRulesPopup.viewportHeight - 100, commonGameRulesPopup.compactLayout ? 500 : 640)
    x: Math.round((commonGameRulesPopup.viewportWidth - width) / 2)
    y: Math.round((commonGameRulesPopup.viewportHeight - height) / 2)
    padding: 0
    onOpened: collapsedGroups = commonGameRulesPopup.initialCollapsedGroups()

    function setGroupCollapsed(groupId, collapsed) {
        var next = {}
        for (var key in collapsedGroups)
            next[key] = collapsedGroups[key]
        if (collapsed)
            next[groupId] = true
        else
            delete next[groupId]
        collapsedGroups = next
    }

    background: Rectangle {
        radius: 9
        color: "#f8fbfd"
        border.color: "#9fb3bf"
        border.width: 1
    }

    contentItem: ColumnLayout {
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            color: "#e6eff4"
            radius: 9

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.radius
                color: parent.color
            }

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 18
                text: commonGameRulesPopup.translate("commonGameRulesTitle")
                color: "#14242e"
                font.pixelSize: commonGameRulesPopup.compactLayout ? 17 : 19
                font.bold: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 12
            spacing: 10

            Rectangle {
                id: allCommonRulePanel
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 6
                color: "#ffffff"
                border.color: "#c7d4dc"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        spacing: 8

                        Item {
                            Layout.preferredWidth: commonGameRulesPopup.leftRuleColumnWidth
                            Layout.preferredHeight: 28

                            Text {
                                x: commonGameRulesPopup.treeNodeCenter
                                   + commonGameRulesPopup.treeCheckOffset - width / 2
                                anchors.verticalCenter: parent.verticalCenter
                                text: commonGameRulesPopup.translate("commonRule")
                                color: "#52636d"
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                x: commonGameRulesPopup.treeNodeCenter
                                   + commonGameRulesPopup.treeNameOffset
                                anchors.verticalCenter: parent.verticalCenter
                                text: commonGameRulesPopup.translate("ruleName")
                                color: "#52636d"
                                font.pixelSize: 12
                            }
                        }

                        Text {
                            text: commonGameRulesPopup.translate("ruleDescription")
                            color: "#52636d"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                    }

                    Flickable {
                        id: commonRuleFlick
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: width
                        contentHeight: commonRuleColumn.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: AppScrollBar {
                            policy: commonRuleFlick.contentHeight > commonRuleFlick.height
                                    ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                        }

                        ColumnLayout {
                            id: commonRuleColumn
                            width: commonRuleFlick.width - 18
                            spacing: 4

                            Repeater {
                                model: commonGameRulesPopup.rowsForGroups(commonGameRulesPopup.collapsedGroups)

                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: Math.max(commonGameRulesPopup.compactLayout ? 36 : 40,
                                                             commonRuleRow.implicitHeight + 10)
                                    radius: 5
                                    color: modelData.type === "group" ? "#f2f7fa"
                                          : modelData.value === commonGameRulesPopup.gameRuleMode ? "#edf7fb" : "#ffffff"
                                    border.color: modelData.type === "group" ? "#c6d6df" : "#e1e8ed"
                                    border.width: 1
                                    ToolTip.visible: commonRuleRowHover.hovered
                                                     && modelData.type === "leaf"
                                                     && modelData.tip.length > 0
                                    ToolTip.text: modelData.tip
                                    ToolTip.delay: 250
                                    ToolTip.timeout: 8000

                                    HoverHandler {
                                        id: commonRuleRowHover
                                    }

                                    RowLayout {
                                        id: commonRuleRow
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 12
                                        spacing: 8

                                        Item {
                                            id: commonRuleLeftCell
                                            Layout.preferredWidth: commonGameRulesPopup.leftRuleColumnWidth
                                            Layout.fillHeight: true

                                            Repeater {
                                                model: Math.max(0, modelData.depth)

                                                Rectangle {
                                                    x: commonGameRulesPopup.treeNodeCenter
                                                       + commonGameRulesPopup.treeCheckOffset
                                                       + index * commonGameRulesPopup.treeDepthStep
                                                    anchors.top: parent.top
                                                    anchors.bottom: parent.bottom
                                                    width: 1
                                                    color: "#cbd9e1"
                                                }
                                            }

                                            Rectangle {
                                                visible: modelData.depth > 0
                                                x: commonGameRulesPopup.treeNodeCenter
                                                   + commonGameRulesPopup.treeCheckOffset
                                                   + (modelData.depth - 1) * commonGameRulesPopup.treeDepthStep
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: commonGameRulesPopup.treeDepthStep
                                                height: 1
                                                color: "#cbd9e1"
                                            }

                                            Rectangle {
                                                id: commonExpandButton
                                                visible: modelData.type === "group"
                                                x: commonGameRulesPopup.treeNodeCenter
                                                   + Math.max(0, modelData.depth) * commonGameRulesPopup.treeDepthStep
                                                   - width / 2
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: commonGameRulesPopup.compactLayout ? 28 : 32
                                                height: width
                                                radius: 4
                                                color: commonExpandMouse.containsMouse ? "#e2edf3" : "transparent"

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.collapsed ? "\u25b6" : "\u25be"
                                                    color: "#38505c"
                                                    font.pixelSize: commonGameRulesPopup.compactLayout ? 16 : 18
                                                    font.bold: true
                                                }

                                                MouseArea {
                                                    id: commonExpandMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    onClicked: commonGameRulesPopup.setGroupCollapsed(modelData.groupId, !modelData.collapsed)
                                                }
                                            }

                                            Item {
                                                id: commonRuleCheckBox
                                                x: commonGameRulesPopup.treeNodeCenter
                                                   + Math.max(0, modelData.depth) * commonGameRulesPopup.treeDepthStep
                                                   + commonGameRulesPopup.treeCheckOffset
                                                   - width / 2
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: commonGameRulesPopup.commonCheckSize
                                                height: commonGameRulesPopup.commonCheckSize

                                                readonly property int state: modelData.type === "group"
                                                                             ? commonGameRulesPopup.groupVisibilityState(modelData.modes)
                                                                             : (commonGameRulesPopup.modeVisible(modelData.value) ? Qt.Checked : Qt.Unchecked)
                                                readonly property bool checkEnabled: modelData.type === "group"
                                                                                     ? commonGameRulesPopup.groupMutable(modelData.modes)
                                                                                     : true

                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: 4
                                                    color: !commonRuleCheckBox.checkEnabled ? "#f0f3f5"
                                                          : commonRuleCheckBox.state === Qt.Checked
                                                            || commonRuleCheckBox.state === Qt.PartiallyChecked ? "#0f6fbf"
                                                          : commonRuleCheckMouse.containsMouse ? "#eef7fa" : "#ffffff"
                                                    border.color: commonRuleCheckBox.state === Qt.Checked
                                                                || commonRuleCheckBox.state === Qt.PartiallyChecked ? "#0f6fbf"
                                                                : commonRuleCheckMouse.containsMouse ? "#5c8da6" : "#7f8b92"
                                                    border.width: 1
                                                }

                                                AppCheckMark {
                                                    anchors.fill: parent
                                                    anchors.margins: commonGameRulesPopup.compactLayout ? 3 : 4
                                                    checked: commonRuleCheckBox.state === Qt.Checked
                                                    partial: commonRuleCheckBox.state === Qt.PartiallyChecked
                                                    markColor: "#ffffff"
                                                    lineWidth: partial ? 2.4 : (commonGameRulesPopup.compactLayout ? 2.0 : 2.3)
                                                }

                                                MouseArea {
                                                    id: commonRuleCheckMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    enabled: commonRuleCheckBox.checkEnabled
                                                    onClicked: {
                                                        var nextChecked = commonRuleCheckBox.state !== Qt.Checked
                                                        if (modelData.type === "group")
                                                            commonGameRulesPopup.modesVisibilityRequested(modelData.modes, nextChecked)
                                                        else
                                                            commonGameRulesPopup.modeVisibilityRequested(modelData.value, nextChecked)
                                                    }
                                                }
                                            }

                                            Text {
                                                anchors.left: parent.left
                                                anchors.leftMargin: commonGameRulesPopup.treeNodeCenter
                                                                    + Math.max(0, modelData.depth) * commonGameRulesPopup.treeDepthStep
                                                                    + commonGameRulesPopup.treeNameOffset
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: modelData.label
                                                color: modelData.type === "group" ? "#24313a" : "#17212a"
                                                font.pixelSize: modelData.type === "group"
                                                                ? (commonGameRulesPopup.compactLayout ? 13 : 14)
                                                                : (commonGameRulesPopup.compactLayout ? 12 : 13)
                                                font.bold: modelData.type === "group" || modelData.value === commonGameRulesPopup.gameRuleMode
                                                elide: Text.ElideRight
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                        }

                                        Text {
                                            text: modelData.type === "group" ? "" : modelData.tip
                                            color: "#61727c"
                                            font.pixelSize: commonGameRulesPopup.compactLayout ? 12 : 13
                                            wrapMode: Text.WordWrap
                                            verticalAlignment: Text.AlignVCenter
                                            Layout.fillWidth: true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: currentCommonRulePanel
                Layout.preferredWidth: commonGameRulesPopup.compactLayout ? 200 : 250
                Layout.fillHeight: true
                radius: 6
                color: "#ffffff"
                border.color: "#c7d4dc"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Text {
                        text: commonGameRulesPopup.translate("currentCommonGameRules")
                        color: "#17212a"
                        font.pixelSize: commonGameRulesPopup.compactLayout ? 14 : 15
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: "#d5e2e8"
                    }

                    Flickable {
                        id: currentCommonRuleFlick
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: width
                        contentHeight: currentCommonRuleColumn.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: AppScrollBar {
                            policy: currentCommonRuleFlick.contentHeight > currentCommonRuleFlick.height
                                    ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                        }

                        ColumnLayout {
                            id: currentCommonRuleColumn
                            width: currentCommonRuleFlick.width - 18
                            spacing: 5

                            Repeater {
                                model: commonGameRulesPopup.commonOptions

                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 38
                                    radius: 5
                                    color: modelData.value === commonGameRulesPopup.gameRuleMode ? "#edf7fb" : "#f8fbfd"
                                    border.color: "#d8e3e9"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 6
                                        spacing: 6

                                        Text {
                                            text: String(index + 1)
                                            color: "#61727c"
                                            font.pixelSize: 12
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            Layout.preferredWidth: 22
                                        }

                                        Text {
                                            text: modelData.label
                                            color: "#17212a"
                                            font.pixelSize: commonGameRulesPopup.compactLayout ? 12 : 13
                                            font.bold: modelData.value === commonGameRulesPopup.gameRuleMode
                                            elide: Text.ElideRight
                                            verticalAlignment: Text.AlignVCenter
                                            Layout.fillWidth: true
                                        }

                                        SavePromptButton {
                                            text: "\u2191"
                                            enabled: index > 0
                                            implicitWidth: 28
                                            implicitHeight: 26
                                            onClicked: commonGameRulesPopup.reorderRequested(modelData.value, -1)
                                        }

                                        SavePromptButton {
                                            text: "\u2193"
                                            enabled: index < commonGameRulesPopup.commonOptions.length - 1
                                            implicitWidth: 28
                                            implicitHeight: 26
                                            onClicked: commonGameRulesPopup.reorderRequested(modelData.value, 1)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 54
            color: "#eef4f7"
            border.color: "#d3e0e7"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10

                Item { Layout.fillWidth: true }

                SavePromptButton {
                    text: commonGameRulesPopup.translate("close")
                    onClicked: commonGameRulesPopup.close()
                }
            }
        }
    }
}
