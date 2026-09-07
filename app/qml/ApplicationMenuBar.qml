import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

MenuBar {

    id: applicationMenu
    required property bool compactLayout
    required property int currentNodeId
    required property int gameRuleMode
    required property string currentRuleText
    required property string engineTitle
    required property bool hasActiveEngine
    required property bool engineDisabled
    required property string activeEngineId
    required property var enginePresets
    required property var commonOptions
    required property var translate
    required property var ruleAllowed
    required property var enginePresetText
    signal openRequested()
    signal saveRequested()
    signal quitRequested()
    signal undoRequested()
    signal deleteRequested()
    signal clearRequested()
    signal boardSizeRequested()
    signal resetVisualsRequested()
    signal settingsRequested()
    signal engineManagerRequested()
    signal ruleSelectionRequested()
    signal tutorialRequested()
    signal helpRequested()
    signal aboutRequested()
    signal engineRestartRequested()
    signal engineStopRequested()
    signal enginePickerRequested()
    signal languageRequested(string language)
    signal ruleChosen(int mode)
    signal engineChosen(string engineId)

    function dismissSettings() {
        settingsMenu.dismiss()
        settingsMenu.close()
    }

    font.pixelSize: applicationMenu.compactLayout ? 15 : 17

    Menu {
        title: applicationMenu.translate("menuFile")
        font.pixelSize: applicationMenu.compactLayout ? 14 : 16

        Action {
            text: applicationMenu.translate("menuOpenSgf")
            shortcut: "Ctrl+O"
            onTriggered: applicationMenu.openRequested()
        }

        Action {
            text: applicationMenu.translate("menuSaveSgf")
            shortcut: "Ctrl+S"
            onTriggered: applicationMenu.saveRequested()
        }

        Action {
            text: applicationMenu.translate("menuExit")
            onTriggered: applicationMenu.quitRequested()
        }
    }

    Menu {
        title: applicationMenu.translate("menuEdit")
        font.pixelSize: applicationMenu.compactLayout ? 14 : 16

        Action {
            text: applicationMenu.translate("menuUndo")
            enabled: applicationMenu.currentNodeId !== 0
            onTriggered: applicationMenu.undoRequested()
        }

        Action {
            text: applicationMenu.translate("menuDeleteNode")
            enabled: applicationMenu.currentNodeId !== 0
            onTriggered: applicationMenu.deleteRequested()
        }

        Action {
            text: applicationMenu.translate("menuClearBoard")
            onTriggered: applicationMenu.clearRequested()
        }

        Action {
            text: applicationMenu.translate("menuBoardSize")
            onTriggered: applicationMenu.boardSizeRequested()
        }
    }

    Menu {
        title: applicationMenu.translate("menuView")
        font.pixelSize: applicationMenu.compactLayout ? 14 : 16

        Action {
            text: applicationMenu.translate("menuResetVisual")
            onTriggered: applicationMenu.resetVisualsRequested()
        }
    }

    Menu {
        id: settingsMenu
        title: applicationMenu.translate("menuSettings")
        font.pixelSize: applicationMenu.compactLayout ? 14 : 16

        MenuItem {
            text: applicationMenu.translate("settingsDialogTitle")
            font.pixelSize: applicationMenu.compactLayout ? 14 : 16
            onTriggered: applicationMenu.settingsRequested()
        }

        Menu {
            id: ruleSelectionMenu
            title: applicationMenu.translate("ruleSelectionMenu")
            width: applicationMenu.compactLayout ? 260 : 320
            font.pixelSize: applicationMenu.compactLayout ? 14 : 16

            MenuItem {
                width: ruleSelectionMenu.width
                enabled: false
                text: applicationMenu.currentRuleText
                font.pixelSize: applicationMenu.compactLayout ? 13 : 15
                leftPadding: 0
                rightPadding: 0

                contentItem: Text {
                    leftPadding: 18
                    rightPadding: 18
                    text: applicationMenu.currentRuleText
                    color: "#7b8a93"
                    font.pixelSize: applicationMenu.compactLayout ? 13 : 15
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
            }

            MenuSeparator { }

            Instantiator {
                model: applicationMenu.commonOptions

                delegate: MenuItem {
                    id: commonRuleMenuItem

                    readonly property bool selected: applicationMenu.gameRuleMode === modelData.value

                    width: ruleSelectionMenu.width
                    text: modelData.label
                    checkable: false
                    enabled: applicationMenu.ruleAllowed(modelData.value)
                    font.pixelSize: applicationMenu.compactLayout ? 14 : 16
                    leftPadding: 0
                    rightPadding: 0
                    onTriggered: applicationMenu.ruleChosen(modelData.value)

                    indicator: Item {
                        x: 10
                        y: 0
                        width: 26
                        height: commonRuleMenuItem.height

                        AppCheckMark {
                            anchors.centerIn: parent
                            visible: commonRuleMenuItem.selected
                            width: applicationMenu.compactLayout ? 15 : 17
                            height: width
                            checked: true
                            markColor: "#17212a"
                            lineWidth: applicationMenu.compactLayout ? 2.1 : 2.4
                        }
                    }

                    contentItem: Item {
                        implicitWidth: ruleSelectionMenu.width
                        implicitHeight: commonRuleMenuItem.implicitContentHeight

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 52
                            anchors.right: parent.right
                            anchors.rightMargin: 18
                            anchors.verticalCenter: parent.verticalCenter
                            text: commonRuleMenuItem.text
                            color: commonRuleMenuItem.enabled ? "#17212a" : "#8a969d"
                            font.pixelSize: applicationMenu.compactLayout ? 14 : 16
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }
                }

                onObjectAdded: function(index, object) {
                    ruleSelectionMenu.insertItem(index + 2, object)
                }

                onObjectRemoved: function(index, object) {
                    ruleSelectionMenu.removeItem(object)
                }
            }

            MenuSeparator { visible: applicationMenu.commonOptions.length > 0 }

            MenuItem {
                width: ruleSelectionMenu.width
                text: applicationMenu.translate("moreRules")
                font.pixelSize: applicationMenu.compactLayout ? 14 : 16
                onTriggered: applicationMenu.ruleSelectionRequested()
            }
        }

        MenuItem {
            text: applicationMenu.translate("engineListTitle")
            font.pixelSize: applicationMenu.compactLayout ? 14 : 16
            onTriggered: applicationMenu.engineManagerRequested()
        }

        Menu {
            title: applicationMenu.translate("menuLanguage")
            width: applicationMenu.compactLayout ? 180 : 220
            font.pixelSize: applicationMenu.compactLayout ? 14 : 16

            MenuItem {
                text: applicationMenu.translate("languageChinese")
                width: parent ? parent.width : 220
                font.pixelSize: applicationMenu.compactLayout ? 14 : 16
                onTriggered: applicationMenu.languageRequested("zh")
            }

            MenuItem {
                text: applicationMenu.translate("languageEnglish")
                width: parent ? parent.width : 220
                font.pixelSize: applicationMenu.compactLayout ? 14 : 16
                onTriggered: applicationMenu.languageRequested("en")
            }
        }
    }

    Menu {
        title: applicationMenu.translate("menuHelp")
        font.pixelSize: applicationMenu.compactLayout ? 14 : 16

        Action {
            text: applicationMenu.translate("helpKeysTitle")
            onTriggered: applicationMenu.helpRequested()
        }

        Action {
            text: applicationMenu.translate("beginnerTutorialTitle")
            onTriggered: applicationMenu.tutorialRequested()
        }

        Action {
            text: applicationMenu.translate("aboutTitle")
            onTriggered: applicationMenu.aboutRequested()
        }
    }

    Menu {
        id: engineMenu
        title: applicationMenu.engineTitle
        width: applicationMenu.compactLayout ? 520 : 600
        font.pixelSize: applicationMenu.compactLayout ? 14 : 16

        Action {
            text: applicationMenu.translate("engineAddAndConfigure")
            onTriggered: applicationMenu.engineManagerRequested()
        }

        Action {
            text: applicationMenu.translate("engineRestartCurrent")
            enabled: applicationMenu.hasActiveEngine !== null
            onTriggered: applicationMenu.engineRestartRequested()
        }

        Action {
            text: applicationMenu.translate("engineCloseCurrent")
            enabled: !applicationMenu.engineDisabled
            onTriggered: applicationMenu.engineStopRequested()
        }

        MenuSeparator { }

        Instantiator {
            model: Math.min(10, applicationMenu.enginePresets.length)

            delegate: MenuItem {
                width: engineMenu.width
                text: applicationMenu.enginePresetText(index)
                checkable: true
                checked: {
                    var preset = applicationMenu.enginePresets[index]
                    return preset && applicationMenu.activeEngineId === preset.id
                }
                onTriggered: {
                    var preset = applicationMenu.enginePresets[index]
                    if (preset)
                        applicationMenu.engineChosen(preset.id)
                }
            }

            onObjectAdded: function(index, object) {
                engineMenu.insertItem(index + 4, object)
            }

            onObjectRemoved: function(index, object) {
                engineMenu.removeItem(object)
            }
        }

        Action {
            text: applicationMenu.translate("moreEngines")
            onTriggered: applicationMenu.enginePickerRequested()
        }
    }
}
