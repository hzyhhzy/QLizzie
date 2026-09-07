import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AppPopup {

    required property bool compactLayout
    required property real viewportWidth
    required property real viewportHeight
    required property int gameRuleMode
    required property string currentRuleText
    required property var translate
    required property var rowsForGroups
    required property var initialCollapsedGroups
    required property var ruleAllowed
    signal ruleChosen(int mode)
    signal commonRulesRequested()

    id: ruleSelectionPopup

    property var collapsedGroups: ({})
    readonly property int treeDepthStep: ruleSelectionPopup.compactLayout ? 20 : 24
    readonly property int treeNodeCenter: ruleSelectionPopup.compactLayout ? 22 : 26
    readonly property int treeTextGap: ruleSelectionPopup.compactLayout ? 22 : 26

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    width: Math.min(ruleSelectionPopup.viewportWidth - 80, ruleSelectionPopup.compactLayout ? 420 : 520)
    height: Math.min(ruleSelectionPopup.viewportHeight - 100, ruleSelectionPopup.compactLayout ? 430 : 520)
    x: Math.round((ruleSelectionPopup.viewportWidth - width) / 2)
    y: Math.round((ruleSelectionPopup.viewportHeight - height) / 2)
    padding: 0
    onOpened: collapsedGroups = ruleSelectionPopup.initialCollapsedGroups()

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

    function chooseRule(mode) {
        close()
        ruleSelectionPopup.ruleChosen(mode)
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
                text: ruleSelectionPopup.translate("ruleSelectionMenu")
                color: "#14242e"
                font.pixelSize: ruleSelectionPopup.compactLayout ? 17 : 19
                font.bold: true
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            color: "#f2f7fa"
            border.color: "#d3e0e7"
            border.width: 1

            Text {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                text: ruleSelectionPopup.currentRuleText
                color: "#7b8a93"
                font.pixelSize: ruleSelectionPopup.compactLayout ? 13 : 15
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }

        Flickable {
            id: ruleSelectionFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: ruleSelectionColumn.implicitHeight + 20
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: AppScrollBar {
                policy: ruleSelectionFlick.contentHeight > ruleSelectionFlick.height
                        ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
            }

            ColumnLayout {
                id: ruleSelectionColumn
                x: 10
                y: 10
                width: ruleSelectionFlick.width - 28
                spacing: 4

                Repeater {
                    model: ruleSelectionPopup.rowsForGroups(ruleSelectionPopup.collapsedGroups)

                    delegate: Rectangle {
                        readonly property bool rowVisible: true

                        Layout.fillWidth: true
                        implicitHeight: rowVisible ? (ruleSelectionPopup.compactLayout ? 34 : 38) : 0
                        radius: 5
                        color: modelData.type === "leaf" && modelData.value === ruleSelectionPopup.gameRuleMode ? "#dcecf3"
                              : ruleMouse.containsMouse ? "#eef6fa"
                              : modelData.type === "group" ? "#f2f7fa" : "#ffffff"
                        border.color: modelData.type === "group" ? "#c6d6df" : "#e1e8ed"
                        border.width: 1
                        ToolTip.visible: ruleMouse.containsMouse
                                         && modelData.type === "leaf"
                                         && modelData.tip.length > 0
                        ToolTip.text: modelData.tip
                        ToolTip.delay: 250
                        ToolTip.timeout: 8000

                        Item {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10

                            Repeater {
                                model: Math.max(0, modelData.depth)

                                Rectangle {
                                    x: ruleSelectionPopup.treeNodeCenter
                                       + index * ruleSelectionPopup.treeDepthStep
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: 1
                                    color: "#cbd9e1"
                                }
                            }

                            Rectangle {
                                visible: modelData.depth > 0
                                x: ruleSelectionPopup.treeNodeCenter
                                   + (modelData.depth - 1) * ruleSelectionPopup.treeDepthStep
                                anchors.verticalCenter: parent.verticalCenter
                                width: ruleSelectionPopup.treeDepthStep
                                height: 1
                                color: "#cbd9e1"
                            }

                            Text {
                                id: ruleSelectionTreeMark
                                visible: modelData.type === "group"
                                x: ruleSelectionPopup.treeNodeCenter
                                   + Math.max(0, modelData.depth) * ruleSelectionPopup.treeDepthStep
                                   - width / 2
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.collapsed ? "\u25b6" : "\u25be"
                                color: "#38505c"
                                font.pixelSize: ruleSelectionPopup.compactLayout ? 17 : 19
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            AppCheckMark {
                                id: ruleSelectionLeafMark
                                visible: modelData.type === "leaf"
                                         && modelData.value === ruleSelectionPopup.gameRuleMode
                                width: ruleSelectionPopup.compactLayout ? 16 : 18
                                height: width
                                x: ruleSelectionPopup.treeNodeCenter
                                   + Math.max(0, modelData.depth) * ruleSelectionPopup.treeDepthStep
                                   - width / 2
                                anchors.verticalCenter: parent.verticalCenter
                                checked: true
                                markColor: "#1678bd"
                                lineWidth: ruleSelectionPopup.compactLayout ? 2.3 : 2.6
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: ruleSelectionPopup.treeNodeCenter
                                                    + Math.max(0, modelData.depth) * ruleSelectionPopup.treeDepthStep
                                                    + ruleSelectionPopup.treeTextGap
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: modelData.type === "leaf" && !ruleSelectionPopup.ruleAllowed(modelData.value)
                                       ? "#8a969d" : "#14242e"
                                font.pixelSize: modelData.type === "group"
                                                ? (ruleSelectionPopup.compactLayout ? 14 : 16)
                                                : (ruleSelectionPopup.compactLayout ? 13 : 15)
                                font.bold: modelData.type === "group"
                                           || (modelData.type === "leaf" && modelData.value === ruleSelectionPopup.gameRuleMode)
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        MouseArea {
                            id: ruleMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: modelData.type === "group"
                                     || ruleSelectionPopup.ruleAllowed(modelData.value)
                            onClicked: {
                                if (modelData.type === "group")
                                    ruleSelectionPopup.setGroupCollapsed(modelData.groupId, !modelData.collapsed)
                                else
                                    ruleSelectionPopup.chooseRule(modelData.value)
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
                spacing: 10

                SavePromptButton {
                    text: ruleSelectionPopup.translate("setCommonGameRules") + "..."
                    onClicked: {
                        ruleSelectionPopup.close()
                        ruleSelectionPopup.commonRulesRequested()
                    }
                }

                Item { Layout.fillWidth: true }

                SavePromptButton {
                    text: ruleSelectionPopup.translate("cancel")
                    onClicked: ruleSelectionPopup.close()
                }
            }
        }
    }
}
