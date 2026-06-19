import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Dialogs
import QtQuick.Layouts
import "AnalysisStatus.js" as AnalysisStatus
import "BoardInteraction.js" as BoardInteraction
import "BoardVisuals.js" as BoardVisuals
import "CandidateAnalysis.js" as CandidateAnalysis
import "CoordinateUtils.js" as CoordinateUtils
import "EnginePresets.js" as EnginePresets
import "EngineSupport.js" as EngineSupport
import "GameRules.js" as GameRules
import "RuleSupport.js" as RuleSupport
import "SettingsStore.js" as SettingsStore
import "SgfSession.js" as SgfSession
import "SgfUtils.js" as SgfUtils
import "Translations.js" as TranslationData
import "TreeLayout.js" as TreeLayout

ApplicationWindow {
    id: root

    width: Math.min(1600, Screen.desktopAvailableWidth > 0 ? Screen.desktopAvailableWidth : 1600)
    height: Math.min(900, Screen.desktopAvailableHeight > 0 ? Screen.desktopAvailableHeight : 900)
    minimumWidth: 1024
    minimumHeight: 640
    visible: true
    color: backgroundColor
    title: windowTitleText()

    property string language: "zh"
    property var translations: TranslationData.translations
    property bool firstLaunchCompleted: false
    property bool showBeginnerTutorialOnNextLaunch: true
    property bool startupBeginnerTutorialRequested: false
    property bool appReady: false
    property bool persistentSettingsLoaded: false
    property bool gameDirty: false
    property bool suppressUnsavedPrompt: false
    property bool saveDialogClosesApp: false
    property string pendingClearAction: ""
    property int pendingRuleMode: -1
    property int pendingBoardSizeX: -1
    property int pendingBoardSizeY: -1

    readonly property string coordinateFontFamily: coordinateFont.status === FontLoader.Ready
                                                    ? coordinateFont.name
                                                    : "JetBrains Mono"

    readonly property int minBoardSize: 1
    readonly property int maxBoardSize: 1001
    readonly property int maxCachedLegalPoints: 40000
    readonly property int currentSettingsVersion: 3
    property int loadedSettingsVersion: 0
    readonly property int defaultBoardSize: 19
    property int boardSizeX: defaultBoardSize
    property int boardSizeY: defaultBoardSize
    readonly property int boardSize: Math.max(boardSizeX, boardSizeY)
    property real spacing: 100

    readonly property bool compactLayout: width < 1500 || height < 820
    readonly property real analysisToolbarHeight: compactLayout ? 40 : 46
    readonly property real commandToolbarHeight: compactLayout ? 34 : 38
    readonly property real panelMargin: compactLayout ? 10 : 18
    readonly property real panelGap: compactLayout ? 8 : 14
    readonly property real panelInnerMargin: compactLayout ? 10 : 14
    readonly property real topContentMargin: analysisToolbarHeight + panelMargin
    readonly property real bottomContentMargin: panelMargin + commandToolbarHeight + panelGap
    readonly property real infoPanelWidth: compactLayout ? 260 : 314
    readonly property real branchPanelWidth: compactLayout ? 180 : 240
    readonly property int minimumTreeCanvasWidth: compactLayout ? 164 : 220
    readonly property int minimumTreeCanvasHeight: compactLayout ? 210 : 260
    readonly property real boardStageLeftReserve: panelMargin + infoPanelWidth + panelGap
    readonly property real boardStageRightReserve: panelMargin + branchPanelWidth + panelGap
    readonly property real boardStageCenterX: boardStageLeftReserve
                                                + (width - boardStageLeftReserve - boardStageRightReserve) / 2

    property var commandToolbarItems: [
        { "type": "button", "action": "candidates", "zh": "选点列表", "en": "Candidates", "width": 76 },
        { "type": "button", "action": "refresh", "zh": "刷新", "en": "Refresh", "width": 52 },
        { "type": "button", "action": "setMainBranch", "zh": "设为主分支", "en": "Set main", "width": 90 },
        { "type": "button", "action": "clearBoard", "zh": "清空棋盘", "en": "Clear board", "width": 76 },
        { "type": "button", "action": "delete", "zh": "删除", "en": "Delete", "width": 52 },
        { "type": "button", "action": "firstMove", "zh": "|<", "en": "|<", "width": 40 },
        { "type": "button", "action": "back10", "zh": "<<", "en": "<<", "width": 40 },
        { "type": "button", "action": "back1", "zh": "<", "en": "<", "width": 38 },
        { "type": "moveInput", "width": 56 },
        { "type": "button", "action": "forward1", "zh": ">", "en": ">", "width": 38 },
        { "type": "button", "action": "forward10", "zh": ">>", "en": ">>", "width": 40 },
        { "type": "button", "action": "lastMove", "zh": ">|", "en": ">|", "width": 40 }
    ]

    property var stones: ({})
    property var stoneItems: []
    property var gameNodes: []
    property var treeNodes: []
    property var treeEdges: []
    property int treeCanvasWidth: 220
    property int treeCanvasHeight: 260
    property int currentNodeId: 0
    property int nextNodeId: 1
    property int gameTreeGeneration: 0
    property int boardRevision: 0
    property int treeRevision: 0
    property int legalityRevision: 0
    property int currentPlayer: 1
    property int stoneCount: 0
    property int blackCaptures: 0
    property int whiteCaptures: 0
    property string koLocKey: ""
    property int koLocX: -1
    property int koLocY: -1
    property string hoverKey: ""
    property int hoverX: -1
    property int hoverY: -1
    property bool selectedPointLocked: false
    property bool selectedPointFromCandidateList: false
    property var legalPointMap: ({})
    property string statusMode: "turn"
    property string statusMessage: ""
    property int statusX: -1
    property int statusY: -1

    readonly property int stoneColorModeAuto: 0
    readonly property int stoneColorModeBlack: 1
    readonly property int stoneColorModeWhite: 2
    property int stoneColorMode: stoneColorModeAuto

    readonly property int gameRuleGo: 0
    readonly property int gameRuleGomoku: 1
    readonly property int gameRuleHex: 2
    readonly property int gameRuleSquareFree: 3
    readonly property int gameRuleReversi: 4
    readonly property int gameRuleConnect6: 5
    readonly property int gameRuleHexGoParallelogram: 6
    readonly property int gameRuleHexGoHexagon: 7
    readonly property int gameRuleHexGoTriangle: 8
    readonly property int gameRuleAtaxx: 9
    readonly property int gameRuleBreakthrough: 10
    readonly property int gameRuleTorusGo: 11
    readonly property int gameRuleMoreOption: -1000000
    property int gameRuleMode: gameRuleGo
    property var ruleVisibilityMap: ({})
    property var commonRuleOrder: []
    readonly property int gomokuRuleFreestyle: 0
    readonly property int gomokuRuleStandard: 1
    readonly property int gomokuRuleRenju: 2
    readonly property int gomokuRuleCaro: 3
    readonly property int gomokuRuleDirectFour: 4
    readonly property int gomokuRuleCaroNoSix: 5
    property int gomokuRuleMode: gomokuRuleFreestyle
    property int gomokuRuleMaxMoves: 0
    property string gomokuRuleVcn: "NOVC"
    property bool gomokuRuleFirstPassWin: false
    readonly property int goScoringArea: 0
    readonly property int goScoringTerritory: 1
    readonly property int goKoSimple: 0
    readonly property int goKoPositional: 1
    readonly property int goKoSituational: 2
    readonly property int goTaxNone: 0
    readonly property int goTaxSeki: 1
    readonly property int goTaxAll: 2
    property int goScoringRule: goScoringArea
    property int goKoRule: goKoPositional
    property bool goSuicideAllowed: true
    property int goTaxRule: goTaxNone
    property string goWhiteHandicapBonus: "N"
    property bool goButtonRule: false
    property var gomokuWinLineItems: []
    property var gomokuForbiddenPointItems: []
    property var hexWinPathItems: []
    property int hexWinPathPlayer: 0
    property var breakthroughWinInfo: ({ "player": 0, "reason": "" })

    property real komi: 6.5
    readonly property real maxKomiMagnitude: 99999
    readonly property int komiUsageNone: 0
    readonly property int komiUsageKomi: 1
    readonly property int komiUsageBlackAggression: 2
    readonly property int playModeAnalysis: 0
    readonly property int playModeAiBlack: 1
    readonly property int playModeAiWhite: 2
    readonly property int playModeAiSelf: 3
    property int playMode: playModeAnalysis
    property real secondsPerMove: 5.0
    property int resignMinMove: 80
    property int resignConsecutiveMoves: 3
    property real resignWinrateThreshold: 5.0
    property int gameWinner: 0
    property string gameOverReason: ""

    readonly property int moveNumberModeAll: 0
    readonly property int moveNumberModeLastOnly: 1
    readonly property int moveNumberModeHidden: 2
    readonly property int defaultMoveNumberDisplayMode: moveNumberModeAll
    property int moveNumberDisplayMode: defaultMoveNumberDisplayMode
    readonly property int coordinateDisplayGoNoI: 0
    readonly property int coordinateDisplayGomokuWithI: 1
    readonly property int coordinateDisplayNumeric: 2
    readonly property int coordinateDisplayNumericOneBased: 3
    readonly property int coordinateDisplayHex: 4
    readonly property int coordinateDisplayNone: 5
    property int coordinateDisplayMode: coordinateDisplayGoNoI
    readonly property int boardPresentationIntersections: 0
    readonly property int boardPresentationCells: 1
    readonly property int boardPresentationTorusEdge: 2
    readonly property int boardPresentationTorusHalf: 3
    readonly property int boardPresentationTorusFull: 4
    property int boardPresentationMode: boardPresentationIntersections
    property int goBoardPresentationMode: boardPresentationIntersections
    property int gomokuBoardPresentationMode: boardPresentationIntersections
    property int torusGoBoardPresentationMode: boardPresentationTorusEdge
    readonly property int hexBoardStyleTriangle: 0
    readonly property int hexBoardStyleCells: 1
    property int hexBoardStyle: hexBoardStyleTriangle
    readonly property int hexRotationCurrent: 0
    readonly property int hexRotationTranspose: 1
    readonly property int hexRotationFlipX: 2
    readonly property int hexRotationFlipXTranspose: 3
    readonly property int hexRotationHorizontal: 4
    readonly property int hexRotationHorizontalTranspose: 5
    readonly property int hexRotationVertical: 6
    readonly property int hexRotationVerticalTranspose: 7
    readonly property int hexRotationMirror: 8
    readonly property int hexRotationMirrorTranspose: 9
    property int hexBoardRotation: hexRotationCurrent
    readonly property int packageModeUniversal: 0
    readonly property int packageModeGo: 1
    readonly property int packageModeSix: 2
    property int packageMode: packageModeUniversal
    property string defaultGo7EngineCommand: ""
    property string persistedEngineCommand: ""
    property bool legacyHexEngineCoordinates: false
    property var enginePresets: []
    property string activeEngineId: ""
    property string defaultEngineId: ""
    readonly property int engineStartupDefault: 0
    readonly property int engineStartupLast: 1
    readonly property int engineStartupManual: 2
    readonly property int engineStartupNone: 3
    property int engineStartupMode: engineStartupDefault
    property string engineInitialCommandsSentForId: ""
    property bool enginePresetStartupPromptShown: false

    property bool engineAutoAnalyze: true
    property bool enginePaused: false
    property bool engineDisabled: false
    property bool engineLoading: false
    property bool engineNoticeDismissed: false
    property string engineFailureNoticeText: ""
    property bool genmoveInFlight: false
    property int genmoveRequestSerial: 0
    property int activeGenmoveRequestId: 0
    property int genmovePlayer: 0
    property bool applyingGeneratedMove: false
    property var engineCandidates: []
    property var engineCandidateItems: []
    property var engineCandidateItemMap: ({})
    property var engineCandidateTableItems: []
    property int engineCandidateRevision: 0
    property bool engineCandidatesFromCache: false
    property bool bestCandidateRingVisible: false
    property string bestCandidateRingKey: ""
    property int bestCandidateRingX: -1
    property int bestCandidateRingY: -1
    property var engineSyncedNodeIds: []
    property string engineSyncedBoardSignature: ""
    property string engineSyncedKomiSignature: ""
    property bool engineNeedsFullSync: true
    property int engineAnalysisRequestNodeId: -1
    property int engineAnalysisRequestGeneration: -1
    property string engineAnalysisRequestBoardSignature: ""
    property string engineAnalysisRequestKomiSignature: ""
    property int analysisRevision: 0
    property int analysisIntervalCentiseconds: 10
    property int maxAnalysisSeconds: 0
    property bool analysisWideRootNoiseEnabled: false
    property real analysisWideRootNoise: 0.05
    readonly property int maxLargeIntegerSetting: 1073741824
    property int candidateDisplayCount: 10
    property real candidateMinVisitRatio: 0.001
    property bool candidateShowFilteredMarkers: true
    property bool candidateVariationPreviewVisible: true
    property int candidateVariationPreviewMaxMoves: 10
    readonly property real defaultCandidateVariationPreviewOpacity: 0.40
    property real candidateVariationPreviewOpacity: defaultCandidateVariationPreviewOpacity
    property bool candidateWinrateLabelVisible: true
    property bool candidateVisitsLabelVisible: true
    property bool candidateScoreLabelVisible: true
    property int candidateWinrateFontSize: 57
    property int candidateVisitsFontSize: 42
    property int candidateScoreFontSize: 36
    property bool candidateWinrateBold: true
    property bool candidateVisitsBold: false
    property bool candidateScoreBold: true
    property int candidateWinrateOffsetY: -10
    property int candidateVisitsOffsetY: -5
    property int candidateScoreOffsetY: -5
    property int candidateWinrateDecimals: 1
    property int candidateScoreDecimals: 1
    property bool candidateWinrateShowPercent: false
    property bool candidateScoreShowPercent: false
    readonly property int candidateScoreTitleScoreMean: 0
    readonly property int candidateScoreTitleDrawRate: 1
    property int candidateScoreTitleMode: candidateScoreTitleScoreMean
    property bool candidateRingVisible: true
    property int candidateRingLineWidth: 12
    property bool candidateRankLabelVisible: true
    property string candidateFirstLabelTextColor: "#ff0000"
    property string candidateLabelTextColor: "#000000"
    readonly property string firstCandidateRingColor: "#003b8e"
    readonly property int candidateYzyMinAlpha: 32
    readonly property int candidateYzyMaxAlpha: 240
    readonly property real candidateYzyAlphaFactor: 5.0
    readonly property real candidateYzyColorRatio: 2.0

    property int engineCommunicationLogLimit: 1000
    property bool showEngineCommunicationStdin: true
    property bool showEngineCommunicationStdout: true
    property bool showEngineCommunicationStderr: true

    readonly property string defaultBackgroundColor: "#dbe5ea"
    readonly property string defaultBoardWoodColor: "#d9a75f"
    property string backgroundColor: defaultBackgroundColor
    property string boardWoodColor: defaultBoardWoodColor
    readonly property real minStoneScale: 0.50
    readonly property real defaultStoneScale: 0.95
    readonly property real defaultGridOpacity: 0.92
    readonly property real defaultGridLineWidth: 1.2
    readonly property real defaultSelectedPointScale: 1.00
    readonly property real defaultMoveNumberLabelScale: 1.00
    readonly property real defaultMouseHitRadiusScale: 0.38
    property real stoneScale: defaultStoneScale
    property real gridOpacity: defaultGridOpacity
    property real gridLineWidth: defaultGridLineWidth
    property real selectedPointScale: defaultSelectedPointScale
    property real moveNumberLabelScale: defaultMoveNumberLabelScale
    property real mouseHitRadiusScale: defaultMouseHitRadiusScale

    FontLoader {
        id: coordinateFont
        source: "qrc:/resources/fonts/JetBrainsMono-Regular.ttf"
    }

    onClosing: function(event) {
        savePersistentSettings()
        if (appSettings)
            appSettings.sync()
        if (gameDirty && !suppressUnsavedPrompt) {
            event.accepted = false
            unsavedSgfDialog.open()
        }
    }

    onCoordinateDisplayModeChanged: refreshCoordinateDisplayText()
    onCandidateDisplayCountChanged: rebuildEngineCandidateItems()
    onCandidateMinVisitRatioChanged: rebuildEngineCandidateItems()
    onCandidateShowFilteredMarkersChanged: rebuildEngineCandidateItems()
    onCandidateWinrateLabelVisibleChanged: rebuildEngineCandidateItems()
    onCandidateVisitsLabelVisibleChanged: rebuildEngineCandidateItems()
    onCandidateScoreLabelVisibleChanged: rebuildEngineCandidateItems()
    onCandidateWinrateFontSizeChanged: rebuildEngineCandidateItems()
    onCandidateVisitsFontSizeChanged: rebuildEngineCandidateItems()
    onCandidateScoreFontSizeChanged: rebuildEngineCandidateItems()
    onCandidateWinrateBoldChanged: rebuildEngineCandidateItems()
    onCandidateVisitsBoldChanged: rebuildEngineCandidateItems()
    onCandidateScoreBoldChanged: rebuildEngineCandidateItems()
    onCandidateWinrateDecimalsChanged: rebuildEngineCandidateItems()
    onCandidateScoreDecimalsChanged: rebuildEngineCandidateItems()
    onCandidateWinrateShowPercentChanged: rebuildEngineCandidateItems()
    onCandidateScoreShowPercentChanged: rebuildEngineCandidateItems()
    onCandidateLabelTextColorChanged: rebuildEngineCandidateItems()
    onPackageModeChanged: rebuildEngineCandidateItems()
    onGameRuleModeChanged: rebuildEngineCandidateItems()
    onLegacyHexEngineCoordinatesChanged: {
        resetEngineSyncState()
        clearEngineCandidates()
        scheduleAutoAnalysis()
    }

    menuBar: MenuBar {
        font.pixelSize: root.compactLayout ? 15 : 17

        Menu {
            title: root.trText("menuFile")
            font.pixelSize: root.compactLayout ? 14 : 16

            Action {
                text: root.trText("menuOpenSgf")
                shortcut: "Ctrl+O"
                onTriggered: root.openLoadSgfDialog()
            }

            Action {
                text: root.trText("menuSaveSgf")
                shortcut: "Ctrl+S"
                onTriggered: root.openSaveSgfDialog()
            }

            Action {
                text: root.trText("menuExit")
                onTriggered: root.requestQuit()
            }
        }

        Menu {
            title: root.trText("menuEdit")
            font.pixelSize: root.compactLayout ? 14 : 16

            Action {
                text: root.trText("menuUndo")
                enabled: root.currentNodeId !== 0
                onTriggered: root.undoMove()
            }

            Action {
                text: root.trText("menuDeleteNode")
                enabled: root.currentNodeId !== 0
                onTriggered: root.requestDeleteCurrentNode()
            }

            Action {
                text: root.trText("menuClearBoard")
                onTriggered: root.requestClearBoard()
            }

            Action {
                text: root.trText("menuBoardSize")
                onTriggered: root.openBoardSizeDialog()
            }
        }

        Menu {
            title: root.trText("menuView")
            font.pixelSize: root.compactLayout ? 14 : 16

            Action {
                text: root.trText("menuResetVisual")
                onTriggered: root.resetVisualSettings()
            }
        }

        Menu {
            id: settingsMenu
            title: root.trText("menuSettings")
            font.pixelSize: root.compactLayout ? 14 : 16

            MenuItem {
                text: root.trText("settingsDialogTitle")
                font.pixelSize: root.compactLayout ? 14 : 16
                onTriggered: settingsDialog.openPage(0)
            }

            Menu {
                id: ruleSelectionMenu
                title: root.trText("ruleSelectionMenu")
                width: root.compactLayout ? 260 : 320
                font.pixelSize: root.compactLayout ? 14 : 16

                Instantiator {
                    model: root.commonGameRuleOptions()

                    delegate: MenuItem {
                        id: commonRuleMenuItem

                        readonly property bool selected: root.gameRuleMode === modelData.value

                        width: ruleSelectionMenu.width
                        text: modelData.label
                        checkable: false
                        enabled: root.ruleModeAllowedForPackage(modelData.value)
                        font.pixelSize: root.compactLayout ? 14 : 16
                        leftPadding: 0
                        rightPadding: 0
                        onTriggered: root.chooseRuleModeFromMenu(modelData.value)

                        indicator: Item {
                            x: 10
                            y: 0
                            width: 26
                            height: commonRuleMenuItem.height

                            Text {
                                anchors.centerIn: parent
                                visible: commonRuleMenuItem.selected
                                text: "\u2713"
                                color: "#17212a"
                                font.pixelSize: root.compactLayout ? 15 : 17
                                font.bold: true
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
                                font.pixelSize: root.compactLayout ? 14 : 16
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                        }
                    }

                    onObjectAdded: function(index, object) {
                        ruleSelectionMenu.insertItem(index, object)
                    }

                    onObjectRemoved: function(index, object) {
                        ruleSelectionMenu.removeItem(object)
                    }
                }

                MenuSeparator { visible: root.commonGameRuleOptions().length > 0 }

                MenuItem {
                    width: ruleSelectionMenu.width
                    text: root.trText("moreRules")
                    font.pixelSize: root.compactLayout ? 14 : 16
                    onTriggered: root.openRuleSelectionPopup()
                }
            }

            MenuItem {
                text: root.trText("engineListTitle")
                font.pixelSize: root.compactLayout ? 14 : 16
                onTriggered: engineListDialog.openManage()
            }

            Menu {
                title: root.trText("menuLanguage")
                width: root.compactLayout ? 180 : 220
                font.pixelSize: root.compactLayout ? 14 : 16

                MenuItem {
                    text: root.trText("languageChinese")
                    width: parent ? parent.width : 220
                    font.pixelSize: root.compactLayout ? 14 : 16
                    onTriggered: root.language = "zh"
                }

                MenuItem {
                    text: root.trText("languageEnglish")
                    width: parent ? parent.width : 220
                    font.pixelSize: root.compactLayout ? 14 : 16
                    onTriggered: root.language = "en"
                }
            }
        }

        Menu {
            title: root.trText("menuHelp")
            font.pixelSize: root.compactLayout ? 14 : 16

            Action {
                text: root.trText("helpKeysTitle")
                onTriggered: helpKeysDialog.open()
            }

            Action {
                text: root.trText("beginnerTutorialTitle")
                onTriggered: root.openBeginnerTutorial()
            }

            Action {
                text: root.trText("aboutTitle")
                onTriggered: aboutDialog.open()
            }
        }

        Menu {
            id: engineMenu
            title: root.engineMenuTitle()
            width: root.compactLayout ? 520 : 600
            font.pixelSize: root.compactLayout ? 14 : 16

            Instantiator {
                model: Math.min(20, root.enginePresets.length)

                delegate: MenuItem {
                    width: engineMenu.width
                    text: root.engineMenuPresetText(index)
                    checkable: true
                    checked: {
                        var preset = root.enginePresets[index]
                        return preset && root.activeEngineId === preset.id
                    }
                    onTriggered: {
                        var preset = root.enginePresets[index]
                        if (preset)
                            root.loadEnginePreset(preset.id, false)
                    }
                }

                onObjectAdded: function(index, object) {
                    engineMenu.insertItem(index, object)
                }

                onObjectRemoved: function(index, object) {
                    engineMenu.removeItem(object)
                }
            }

            MenuSeparator { visible: root.enginePresets.length > 0 }

            Action {
                text: root.trText("moreEngines")
                onTriggered: engineListDialog.openPicker()
            }

            Action {
                text: root.trText("engineAddAndConfigure")
                onTriggered: engineListDialog.openManage()
            }

            MenuSeparator { }

            Action {
                text: root.trText("engineRestartCurrent")
                enabled: root.activeEnginePreset() !== null
                onTriggered: root.restartEngine()
            }

            Action {
                text: root.trText("engineCloseCurrent")
                enabled: !root.engineDisabled
                onTriggered: root.stopEngine()
            }
        }
    }

    FileDialog {
        id: saveSgfDialog
        title: root.trText("sgfSaveTitle")
        fileMode: FileDialog.SaveFile
        defaultSuffix: "sgf"
        nameFilters: [root.trText("sgfFileFilter"), root.trText("allFileFilter")]
        onAccepted: root.saveSgfToFile(selectedFile)
        onRejected: {
            root.saveDialogClosesApp = false
            root.clearPendingClearAction()
            root.onSettingsDialogClosed()
            root.focusBoardInput()
        }
    }

    FileDialog {
        id: loadSgfDialog
        title: root.trText("sgfOpenTitle")
        fileMode: FileDialog.OpenFile
        nameFilters: [root.trText("sgfFileFilter"), root.trText("allFileFilter")]
        onAccepted: root.loadSgfFromFile(selectedFile)
        onRejected: root.focusBoardInput()
    }

    Shortcut {
        sequence: "Ctrl+I"
        context: Qt.ApplicationShortcut
        onActivated: root.openBoardSizeDialog()
        onActivatedAmbiguously: root.openBoardSizeDialog()
    }

    Timer {
        id: autoAnalyzeTimer
        interval: 280
        repeat: false
        onTriggered: root.requestEngineAnalysis(false)
    }

    Timer {
        id: analysisLimitTimer
        interval: Math.max(1, root.maxAnalysisSeconds) * 1000
        repeat: false
        onTriggered: root.pauseEngineAnalysisByLimit()
    }

    Timer {
        id: focusBoardInputTimer
        interval: 0
        repeat: false
        onTriggered: root.focusBoardInput()
    }

    Timer {
        id: treeLayoutTimer
        interval: 1
        repeat: false
        onTriggered: root.rebuildTreeLayout()
    }

    Timer {
        id: firstLaunchTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (!root.firstLaunchCompleted)
                initialSetupDialog.open()
        }
    }

    Timer {
        id: startupEngineListTimer
        interval: 180
        repeat: false
        onTriggered: root.showStartupEngineListIfNeeded()
    }

    Timer {
        id: startupBeginnerTutorialTimer
        interval: 260
        repeat: false
        onTriggered: {
            root.startupBeginnerTutorialRequested = false
            beginnerTutorialDialog.openTutorial()
        }
    }

    ListModel {
        id: engineCommunicationLogModel
    }

    SettingsDialog { id: settingsDialog; app: root; controller: engineController }
    HiddenSettingsDialog { id: hiddenSettingsDialog; app: root; controller: engineController }
    EngineParametersDialog { id: engineParametersDialog; app: root; controller: engineController }
    EngineListDialog { id: engineListDialog; app: root; controller: engineController }
    EngineRuleWarningDialog { id: engineRuleWarningDialog; app: root }
    EngineFailureDialog { id: engineFailureDialog; app: root }
    HelpKeysDialog { id: helpKeysDialog; app: root }
    AboutDialog { id: aboutDialog; app: root }
    InitialSetupDialog { id: initialSetupDialog; app: root }
    BeginnerTutorialDialog { id: beginnerTutorialDialog; app: root }
    ConfirmDeleteNodeDialog { id: confirmDeleteNodeDialog; app: root }
    GameOverDialog { id: gameOverDialog; app: root }
    GoRuleDialog { id: goRuleDialog; app: root }
    GomokuRuleDialog { id: gomokuRuleDialog; app: root }
    NoRuleVariantDialog { id: noRuleVariantDialog; app: root }
    UnsavedSgfDialog { id: unsavedSgfDialog; app: root }
    RuleChangeSaveDialog { id: ruleChangeSaveDialog; app: root }
    BoardSizeDialog { id: boardSizeDialog; app: root }

    Basic.Popup {
        id: ruleSelectionPopup

        property var collapsedGroups: ({})
        readonly property int treeDepthStep: root.compactLayout ? 20 : 24
        readonly property int treeNodeCenter: root.compactLayout ? 22 : 26
        readonly property int treeTextGap: root.compactLayout ? 22 : 26

        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: Math.min(root.width - 80, root.compactLayout ? 420 : 520)
        height: Math.min(root.height - 100, root.compactLayout ? 430 : 520)
        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)
        padding: 0

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
            root.chooseRuleModeFromMenu(mode)
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
                    text: root.trText("ruleSelectionMenu")
                    color: "#14242e"
                    font.pixelSize: root.compactLayout ? 17 : 19
                    font.bold: true
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
                        model: root.ruleTreeRows(ruleSelectionPopup.collapsedGroups)

                        delegate: Rectangle {
                            readonly property bool rowVisible: true

                            Layout.fillWidth: true
                            implicitHeight: rowVisible ? (root.compactLayout ? 34 : 38) : 0
                            radius: 5
                            color: modelData.type === "leaf" && modelData.value === root.gameRuleMode ? "#dcecf3"
                                  : ruleMouse.containsMouse ? "#eef6fa"
                                  : modelData.type === "group" ? "#f2f7fa" : "#ffffff"
                            border.color: modelData.type === "group" ? "#c6d6df" : "#e1e8ed"
                            border.width: 1

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
                                    font.pixelSize: root.compactLayout ? 17 : 19
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    id: ruleSelectionLeafMark
                                    visible: modelData.type === "leaf"
                                    x: ruleSelectionPopup.treeNodeCenter
                                       + Math.max(0, modelData.depth) * ruleSelectionPopup.treeDepthStep
                                       - width / 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.value === root.gameRuleMode ? "\u2713" : ""
                                    color: "#1678bd"
                                    font.pixelSize: root.compactLayout ? 16 : 18
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: ruleSelectionPopup.treeNodeCenter
                                                        + Math.max(0, modelData.depth) * ruleSelectionPopup.treeDepthStep
                                                        + ruleSelectionPopup.treeTextGap
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label
                                    color: modelData.type === "leaf" && !root.ruleModeAllowedForPackage(modelData.value)
                                           ? "#8a969d" : "#14242e"
                                    font.pixelSize: modelData.type === "group"
                                                    ? (root.compactLayout ? 14 : 16)
                                                    : (root.compactLayout ? 13 : 15)
                                    font.bold: modelData.type === "group"
                                               || (modelData.type === "leaf" && modelData.value === root.gameRuleMode)
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            MouseArea {
                                id: ruleMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: modelData.type === "group"
                                         || root.ruleModeAllowedForPackage(modelData.value)
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
                        text: root.trText("setCommonGameRules") + "..."
                        onClicked: {
                            ruleSelectionPopup.close()
                            root.openCommonGameRulesPopup()
                        }
                    }

                    Item { Layout.fillWidth: true }

                    SavePromptButton {
                        text: root.trText("cancel")
                        onClicked: ruleSelectionPopup.close()
                    }
                }
            }
        }
    }

    Basic.Popup {
        id: commonGameRulesPopup

        property var collapsedGroups: ({})
        readonly property int leftRuleColumnWidth: root.compactLayout ? 260 : 330
        readonly property int treeDepthStep: root.compactLayout ? 20 : 24
        readonly property int treeNodeCenter: root.compactLayout ? 28 : 34
        readonly property int treeCheckOffset: root.compactLayout ? 34 : 38
        readonly property int treeNameOffset: root.compactLayout ? 66 : 76
        readonly property int commonCheckSize: root.compactLayout ? 18 : 20

        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: Math.min(root.width - 80, root.compactLayout ? 640 : 860)
        height: Math.min(root.height - 100, root.compactLayout ? 500 : 640)
        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)
        padding: 0

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
                    text: root.trText("commonGameRulesTitle")
                    color: "#14242e"
                    font.pixelSize: root.compactLayout ? 17 : 19
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
                                    text: root.trText("commonRule")
                                    color: "#52636d"
                                    font.pixelSize: 12
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                Text {
                                    x: commonGameRulesPopup.treeNodeCenter
                                       + commonGameRulesPopup.treeNameOffset
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.trText("ruleName")
                                    color: "#52636d"
                                    font.pixelSize: 12
                                }
                            }

                            Text {
                                text: root.trText("ruleDescription")
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
                                    model: root.ruleTreeRows(commonGameRulesPopup.collapsedGroups)

                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: Math.max(root.compactLayout ? 36 : 40,
                                                                 commonRuleRow.implicitHeight + 10)
                                        radius: 5
                                        color: modelData.type === "group" ? "#f2f7fa"
                                              : modelData.value === root.gameRuleMode ? "#edf7fb" : "#ffffff"
                                        border.color: modelData.type === "group" ? "#c6d6df" : "#e1e8ed"
                                        border.width: 1

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
                                                    width: root.compactLayout ? 28 : 32
                                                    height: width
                                                    radius: 4
                                                    color: commonExpandMouse.containsMouse ? "#e2edf3" : "transparent"

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: modelData.collapsed ? "\u25b6" : "\u25be"
                                                        color: "#38505c"
                                                        font.pixelSize: root.compactLayout ? 16 : 18
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
                                                                                 ? root.ruleGroupVisibilityCheckState(modelData.modes)
                                                                                 : (root.ruleModeVisible(modelData.value) ? Qt.Checked : Qt.Unchecked)
                                                    readonly property bool checkEnabled: modelData.type === "group"
                                                                                         ? root.ruleGroupHasMutableVisibility(modelData.modes)
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

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: commonRuleCheckBox.state === Qt.PartiallyChecked ? "\u2212"
                                                              : commonRuleCheckBox.state === Qt.Checked ? "\u2713" : ""
                                                        color: commonRuleCheckBox.state === Qt.Checked
                                                               || commonRuleCheckBox.state === Qt.PartiallyChecked ? "#ffffff" : "#17212a"
                                                        font.pixelSize: root.compactLayout ? 13 : 15
                                                        font.bold: true
                                                    }

                                                    MouseArea {
                                                        id: commonRuleCheckMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        enabled: commonRuleCheckBox.checkEnabled
                                                        onClicked: {
                                                            var nextChecked = commonRuleCheckBox.state !== Qt.Checked
                                                            if (modelData.type === "group")
                                                                root.setRuleModesVisible(modelData.modes, nextChecked)
                                                            else
                                                                root.setRuleModeVisible(modelData.value, nextChecked)
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
                                                                    ? (root.compactLayout ? 13 : 14)
                                                                    : (root.compactLayout ? 12 : 13)
                                                    font.bold: modelData.type === "group" || modelData.value === root.gameRuleMode
                                                    elide: Text.ElideRight
                                                    verticalAlignment: Text.AlignVCenter
                                                }
                                            }

                                            Text {
                                                text: modelData.type === "group" ? "" : modelData.tip
                                                color: "#61727c"
                                                font.pixelSize: root.compactLayout ? 12 : 13
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
                    Layout.preferredWidth: root.compactLayout ? 200 : 250
                    Layout.fillHeight: true
                    radius: 6
                    color: "#ffffff"
                    border.color: "#c7d4dc"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Text {
                            text: root.trText("currentCommonGameRules")
                            color: "#17212a"
                            font.pixelSize: root.compactLayout ? 14 : 15
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
                                    model: root.commonGameRuleOptions()

                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 38
                                        radius: 5
                                        color: modelData.value === root.gameRuleMode ? "#edf7fb" : "#f8fbfd"
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
                                                font.pixelSize: root.compactLayout ? 12 : 13
                                                font.bold: modelData.value === root.gameRuleMode
                                                elide: Text.ElideRight
                                                verticalAlignment: Text.AlignVCenter
                                                Layout.fillWidth: true
                                            }

                                            SavePromptButton {
                                                text: "\u2191"
                                                enabled: index > 0
                                                implicitWidth: 28
                                                implicitHeight: 26
                                                onClicked: root.moveCommonRule(modelData.value, -1)
                                            }

                                            SavePromptButton {
                                                text: "\u2193"
                                                enabled: index < root.commonGameRuleOptions().length - 1
                                                implicitWidth: 28
                                                implicitHeight: 26
                                                onClicked: root.moveCommonRule(modelData.value, 1)
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
                        text: root.trText("close")
                        onClicked: commonGameRulesPopup.close()
                    }
                }
            }
        }
    }

    EngineCommunicationWindow {
        id: engineCommunicationWindow
        app: root
        logModel: engineCommunicationLogModel
        onSendCommand: function(command) { engineController.sendCommand(command) }
        onClearLogRequested: root.clearEngineCommunicationLog()
    }

    function trText(key) {
        language
        var table = translations[language] || translations.zh
        return table[key] || key
    }

    function windowTitleText() {
        return trText("windowTitle")
    }

    function clamp(value, low, high) {
        return Math.min(Math.max(value, low), high)
    }

    function keyFor(x, y) {
        return CoordinateUtils.keyFor(x, y)
    }

    function passKey() {
        return CoordinateUtils.passKey()
    }

    function boardDimensionsText() {
        return CoordinateUtils.boardDimensionsText(boardSizeX, boardSizeY)
    }

    function boardDimensionsTextForSize(xSize, ySize) {
        return CoordinateUtils.boardDimensionsText(xSize, ySize)
    }

    function boardPointCount() {
        return CoordinateUtils.boardPointCount(boardSizeX, boardSizeY)
    }

    function effectiveCoordinateDisplayMode() {
        return CoordinateUtils.effectiveCoordinateFormat(boardSizeX, boardSizeY, coordinateDisplayMode)
    }

    function coordinateDisplayForcedNumeric() {
        return effectiveCoordinateDisplayMode() === coordinateDisplayNumeric
               && coordinateDisplayMode !== coordinateDisplayNumeric
               && coordinateDisplayMode !== coordinateDisplayNone
    }

    function xCoordinateText(x) {
        return CoordinateUtils.xCoordinateText(x, boardSizeX, boardSizeY, coordinateDisplayMode)
    }

    function yCoordinateText(y) {
        return CoordinateUtils.yCoordinateText(y, boardSizeX, boardSizeY, coordinateDisplayMode)
    }

    function coordinateText(x, y) {
        return CoordinateUtils.coordinateText(x, y, boardSizeX, boardSizeY, coordinateDisplayMode)
    }

    function parseCoordinateText(text) {
        return CoordinateUtils.parseCoordinateText(text, boardSizeX, boardSizeY, coordinateDisplayMode)
    }

    function setCoordinateDisplayMode(mode) {
        var nextMode = Math.round(clamp(mode, coordinateDisplayGoNoI, coordinateDisplayNone))
        if (coordinateDisplayMode === nextMode)
            return
        coordinateDisplayMode = nextMode
    }

    function refreshCoordinateDisplayText() {
        rebuildTreeLayout()
        rebuildEngineCandidateItems()
    }

    function gtpCoordinateName(x, y, width, height) {
        return CoordinateUtils.gtpCoordinateName(x, y, width, height)
    }

    function parseGtpCoordinateName(text, width, height) {
        return CoordinateUtils.parseGtpCoordinateName(text, width, height)
    }

    function sgfCoordinateText(x, y) {
        return SgfUtils.sgfCoordinateText(x, y)
    }

    function pointInBoard(x, y) {
        return x >= 0 && x < boardSizeX && y >= 0 && y < boardSizeY
    }

    function boardDims() {
        return { "x": boardSizeX, "y": boardSizeY }
    }

    function pointInRuleBoard(x, y) {
        return GameRules.pointInRuleBoard(boardDims(), x, y, gameRuleMode)
    }

    function ruleUsesHexGrid() {
        return RuleSupport.ruleUsesHexGrid(root, gameRuleMode)
    }

    function ruleUsesSquareCells() {
        return RuleSupport.ruleUsesSquareCells(root, gameRuleMode)
    }

    function ruleUsesHexCellStyle() {
        return RuleSupport.ruleUsesHexCellStyle(root, gameRuleMode)
    }

    function ruleUsesGoCapture() {
        return RuleSupport.ruleUsesGoCapture(root, gameRuleMode)
    }

    function ruleAllowsOccupiedMoves() {
        return RuleSupport.ruleAllowsOccupiedMoves(root, gameRuleMode)
    }

    function ruleUsesMoveSource() {
        return RuleSupport.ruleUsesMoveSource(root, gameRuleMode)
    }

    function infoPanelShowsGoCaptures() {
        return ruleUsesGoCapture()
    }

    function infoPanelShowsStoneCounts() {
        return gameRuleMode === gameRuleReversi || gameRuleMode === gameRuleAtaxx
    }

    function infoPanelSideText(player) {
        if (infoPanelShowsGoCaptures())
            return trText("captured") + ": " + (player === 1 ? blackCaptures : whiteCaptures)
        if (infoPanelShowsStoneCounts())
            return String(stoneCountForPlayer(player))
        return ""
    }

    function infoPanelSideTextVisible() {
        return infoPanelShowsGoCaptures() || infoPanelShowsStoneCounts()
    }

    function infoPanelCenterBottomText() {
        if (infoPanelShowsGoCaptures() || infoPanelShowsStoneCounts())
            return Number(effectiveKomi()).toFixed(1)
        if (gameRuleMode === gameRuleGomoku)
            return gomokuRuleLabel(gomokuRuleMode)
        return ""
    }

    function infoPanelCenterBottomVisible() {
        return infoPanelCenterBottomText().length > 0
    }

    function stoneCountForPlayer(player) {
        boardRevision
        var count = 0
        for (var i = 0; i < stoneItems.length; ++i) {
            if (stoneItems[i].player === player)
                ++count
        }
        return count
    }

    function currentMoveSourceNode() {
        var node = currentNode()
        return node && node.moveRole === "source" ? node : null
    }

    function currentMoveSourcePoint() {
        var source = currentMoveSourceNode()
        return source ? { "x": source.x, "y": source.y } : null
    }

    function stoneDataAt(x, y) {
        boardRevision
        var value = stones[keyFor(x, y)]
        return value === undefined ? null : value
    }

    function stoneAt(x, y) {
        var value = stoneDataAt(x, y)
        return value ? value.player : 0
    }

    function isLastMoveAt(x, y) {
        boardRevision
        var node = currentNode()
        return !!node && !node.isPass && node.moveRole !== "source" && node.key === keyFor(x, y)
    }

    function nodeById(id) {
        return gameNodes[id] === undefined ? null : gameNodes[id]
    }

    function currentNode() {
        return nodeById(currentNodeId)
    }

    function rootNode() {
        return {
            "id": 0,
            "parent": -1,
            "children": [],
            "x": -1,
            "y": -1,
            "key": "",
            "player": 0,
            "moveNumber": 0,
            "isPass": false,
            "moveRole": "",
            "gomokuForbidden": false,
            "blackCaptures": 0,
            "whiteCaptures": 0,
            "koLocKey": "",
            "koLocX": -1,
            "koLocY": -1,
            "analysisBlackWinrate": -1,
            "analysisCandidates": [],
            "analysisCandidateBoardSignature": "",
            "analysisCandidateKomiSignature": ""
        }
    }

    function nodePath(id) {
        var path = []
        var node = nodeById(id)
        while (node && node.id !== 0) {
            path.unshift(node)
            node = nodeById(node.parent)
        }
        return path
    }

    function playerToMoveAfterNode(node) {
        if (stoneColorMode === stoneColorModeBlack)
            return 1
        if (stoneColorMode === stoneColorModeWhite)
            return 2

        if (node && node.moveRole === "source")
            return node.player
        if (gameRuleMode === gameRuleConnect6) {
            var moveNumber = node ? node.moveNumber : 0
            if (moveNumber <= 0)
                return 1
            var pair = Math.floor((moveNumber - 1) / 2)
            return pair % 2 === 0 ? 2 : 1
        }
        if (node && node.player === 1)
            return 2
        if (node && node.player === 2)
            return 1
        return 1
    }

    function nextPlayerFromMode() {
        return playerToMoveAfterNode(currentNode())
    }

    function setStoneColorMode(mode) {
        var nextMode = Math.round(clamp(mode, stoneColorModeAuto, stoneColorModeWhite))
        if (stoneColorMode === nextMode) {
            currentPlayer = nextPlayerFromMode()
            rebuildPointLegality()
            refreshWinVisuals(stones)
            boardRevision += 1
            return
        }
        stoneColorMode = nextMode
        currentPlayer = nextPlayerFromMode()
        selectedPointLocked = false
        selectedPointFromCandidateList = false
        clearEngineCandidates()
        rebuildPointLegality()
        refreshWinVisuals(stones)
        boardRevision += 1
        scheduleAutoAnalysis()
        requestAiMoveIfNeeded()
    }

    function pointLegalInMap(map, x, y, player, activeKoLocKey) {
        return GameRules.pointLegalInMap(map, boardDims(), x, y, player, activeKoLocKey,
                                         gameRuleMode, currentMoveSourcePoint())
    }

    function buildPointLegalityMap(map, player, activeKoLocKey) {
        return GameRules.buildPointLegalityMap(map, boardDims(), player, activeKoLocKey,
                                               gameRuleMode, currentMoveSourcePoint())
    }

    function shouldCachePointLegality() {
        return false
    }

    function rebuildPointLegality() {
        legalPointMap = shouldCachePointLegality()
                        ? buildPointLegalityMap(stones, currentPlayer, koLocKey)
                        : ({})
        legalityRevision += 1
    }

    function pointIsLegal(x, y) {
        legalityRevision
        if (!pointInBoard(x, y))
            return false
        if (!shouldCachePointLegality())
            return pointLegalInMap(stones, x, y, currentPlayer, koLocKey)
        return legalPointMap[keyFor(x, y)] === true
    }

    function selectedPointLegal() {
        legalityRevision
        hoverKey
        if (hoverKey === "")
            return false
        return pointIsLegal(hoverX, hoverY)
    }

    function selectedPointPlayable() {
        return selectedPointLegal()
    }

    function selectedPointColor() {
        return selectedPointLegal() ? "#2fb97f" : "#e3342f"
    }

    function pointIsEngineCandidateKey(key) {
        if (!key || key.length <= 0)
            return false
        return engineCandidateItemMap[key] !== undefined
    }

    function clampCoordinateInput(text, size) {
        var value = parseInt(String(text), 10)
        if (isNaN(value))
            value = 0
        return Math.round(clamp(value, 0, size - 1))
    }

    function clampOneBasedCoordinateInput(text, size) {
        var value = parseInt(String(text), 10)
        if (isNaN(value))
            value = 1
        return Math.round(clamp(value, 1, size))
    }

    function setHoverPoint(x, y) {
        var nextX = Math.round(clamp(x, 0, boardSizeX - 1))
        var nextY = Math.round(clamp(y, 0, boardSizeY - 1))
        hoverX = nextX
        hoverY = nextY
        hoverKey = keyFor(nextX, nextY)
    }

    function setSelectedPoint(x, y, locked, fromCandidateList) {
        var nextX = Math.round(clamp(x, 0, boardSizeX - 1))
        var nextY = Math.round(clamp(y, 0, boardSizeY - 1))
        if (locked !== undefined) {
            selectedPointLocked = locked
            selectedPointFromCandidateList = locked === true && fromCandidateList === true
        } else if (!selectedPointLocked) {
            selectedPointFromCandidateList = false
        }
        setHoverPoint(nextX, nextY)
        if (!pointIsLegal(nextX, nextY)) {
            statusMode = stoneAt(nextX, nextY) !== 0 ? "occupied" : "message"
            statusMessage = illegalPointMessage(nextX, nextY, "")
            statusX = nextX
            statusY = nextY
        } else if (statusMode === "occupied"
                   || (statusMode === "message"
                       && (statusMessage.indexOf(trText("suicideMove")) === 0
                           || statusMessage.indexOf(trText("koMove")) === 0))) {
            statusMode = "turn"
        }
        return true
    }

    function illegalPointMessage(x, y, fallback) {
        if (stoneAt(x, y) !== 0 && !ruleAllowsOccupiedMoves() && !ruleUsesMoveSource())
            return trText("occupied") + ": " + coordinateText(x, y)
        if (koLocKey !== "" && keyFor(x, y) === koLocKey)
            return trText("koMove") + ": " + coordinateText(x, y)
        if (ruleUsesGoCapture())
            return trText("suicideMove") + ": " + coordinateText(x, y)
        return fallback
    }

    function mapStoneItems(map) {
        var items = []
        for (var key in map)
            items.push(map[key])
        items.sort(function(left, right) { return left.moveNumber - right.moveNumber })
        return items
    }

    function rebuildPositionFromNode(id) {
        clearEngineCandidates()
        var map = GameRules.initialStoneMap(boardDims(), gameRuleMode)
        var blackCap = 0
        var whiteCap = 0
        var ko = GameRules.emptyKoLoc()
        var pendingSource = null
        var path = nodePath(id)
        for (var i = 0; i < path.length; ++i) {
            var node = path[i]
            if (node.isPass) {
                ko = GameRules.emptyKoLoc()
                pendingSource = null
                node.blackCaptures = blackCap
                node.whiteCaptures = whiteCap
                node.koLocKey = ko.key
                node.koLocX = ko.x
                node.koLocY = ko.y
                continue
            }
            if (node.moveRole === "source") {
                pendingSource = { "x": node.x, "y": node.y, "player": node.player }
                ko = GameRules.emptyKoLoc()
                node.blackCaptures = blackCap
                node.whiteCaptures = whiteCap
                node.koLocKey = ko.key
                node.koLocX = ko.x
                node.koLocY = ko.y
                continue
            }

            var item = {
                "x": node.x,
                "y": node.y,
                "key": keyFor(node.x, node.y),
                "player": node.player,
                "moveNumber": node.moveNumber,
                "nodeId": node.id
            }
            node.gomokuForbidden = pointIsGomokuForbidden(node.x, node.y, node.player, map)
            if (ruleUsesGoCapture()) {
                var result = GameRules.simulateGoMoveOnMap(map, boardDims(), item, true, gameRuleMode)
                if (result.ok) {
                    if (node.player === 1)
                        blackCap += result.captured
                    else
                        whiteCap += result.captured
                    ko = GameRules.koLocFromGoMoveResult(gameRuleMode, result)
                }
            } else if (gameRuleMode === gameRuleReversi) {
                GameRules.applyReversiMoveOnMap(map, boardDims(), item)
                ko = GameRules.emptyKoLoc()
            } else if (gameRuleMode === gameRuleAtaxx) {
                GameRules.applyAtaxxMoveOnMap(map, boardDims(), item, pendingSource)
                pendingSource = null
                ko = GameRules.emptyKoLoc()
            } else if (gameRuleMode === gameRuleBreakthrough && pendingSource) {
                var breakthrough = GameRules.applyBreakthroughMoveOnMap(map, boardDims(), item, pendingSource)
                if (breakthrough.ok) {
                    if (node.player === 1)
                        blackCap += breakthrough.capturedStones.length
                    else
                        whiteCap += breakthrough.capturedStones.length
                }
                pendingSource = null
                ko = GameRules.emptyKoLoc()
            } else {
                map[item.key] = item
                ko = GameRules.emptyKoLoc()
            }
            node.blackCaptures = blackCap
            node.whiteCaptures = whiteCap
            node.koLocKey = ko.key
            node.koLocX = ko.x
            node.koLocY = ko.y
        }

        stones = map
        stoneItems = mapStoneItems(map)
        stoneCount = stoneItems.length
        blackCaptures = blackCap
        whiteCaptures = whiteCap
        koLocKey = ko.key
        koLocX = ko.x
        koLocY = ko.y
        currentPlayer = nextPlayerFromMode()
        rebuildPointLegality()
        refreshWinVisuals(map)
        refreshGameOutcomeFromCurrentNode(false)
        boardRevision += 1
        showCachedAnalysisForCurrentNode()
    }

    function resetGameTree() {
        stopAnalysisLimitTimer()
        gameTreeGeneration += 1
        gameNodes = [rootNode()]
        currentNodeId = 0
        nextNodeId = 1
        stones = GameRules.initialStoneMap(boardDims(), gameRuleMode)
        stoneItems = []
        stoneItems = mapStoneItems(stones)
        stoneCount = stoneItems.length
        blackCaptures = 0
        whiteCaptures = 0
        koLocKey = ""
        koLocX = -1
        koLocY = -1
        gameWinner = 0
        gameOverReason = ""
        gomokuWinLineItems = []
        gomokuForbiddenPointItems = []
        hexWinPathItems = []
        hexWinPathPlayer = 0
        breakthroughWinInfo = ({ "player": 0, "reason": "" })
        currentPlayer = 1
        clearHover(true)
        clearEngineCandidates()
        rebuildPointLegality()
        rebuildTreeLayout()
        boardRevision += 1
    }

    function branchChildMatching(parent, key, player, isPass, moveRole) {
        moveRole = moveRole || ""
        var children = parent ? (parent.children || []) : []
        for (var i = 0; i < children.length; ++i) {
            var child = nodeById(children[i])
            if (child && child.key === key && child.player === player && child.isPass === isPass
                    && (child.moveRole || "") === moveRole)
                return child
        }
        return null
    }

    function addMoveNode(player, x, y, isPass, capturedStones, koLoc, skipPositionRebuild, deferTreeLayoutRebuild, moveRole) {
        var parent = currentNode()
        if (!parent)
            return null
        var key = isPass ? passKey() : keyFor(x, y)
        moveRole = moveRole || ""
        if (isPass || moveRole !== "" || !ruleAllowsOccupiedMoves()) {
            var existing = branchChildMatching(parent, key, player, isPass, moveRole)
            if (existing) {
                gotoNode(existing.id)
                return existing
            }
        }

        var id = nextNodeId++
        var node = {
            "id": id,
            "parent": parent.id,
            "children": [],
            "x": isPass ? -1 : x,
            "y": isPass ? -1 : y,
            "key": key,
            "player": player,
            "moveNumber": parent.moveNumber + 1,
            "isPass": isPass,
            "moveRole": moveRole,
            "gomokuForbidden": false,
            "capturedStones": capturedStones || [],
            "blackCaptures": blackCaptures,
            "whiteCaptures": whiteCaptures,
            "koLocKey": koLoc ? koLoc.key : "",
            "koLocX": koLoc ? koLoc.x : -1,
            "koLocY": koLoc ? koLoc.y : -1,
            "analysisBlackWinrate": -1,
            "analysisCandidates": [],
            "analysisCandidateBoardSignature": "",
            "analysisCandidateKomiSignature": ""
        }
        gameNodes[id] = node
        parent.children = (parent.children || []).slice()
        parent.children.push(id)
        gameNodes = gameNodes.slice()
        currentNodeId = id
        gameDirty = true
        if (!skipPositionRebuild)
            rebuildPositionFromNode(currentNodeId)
        if (deferTreeLayoutRebuild)
            scheduleTreeLayoutRebuild()
        else
            rebuildTreeLayout()
        clearEngineCandidates()
        if (!skipPositionRebuild) {
            scheduleAutoAnalysis()
            requestAiMoveIfNeeded()
        }
        return node
    }

    function placeStone(x, y) {
        if (!pointInRuleBoard(x, y))
            return false

        if (ruleUsesMoveSource())
            return placeMoveRulePoint(x, y)

        if (stoneAt(x, y) !== 0 && !ruleAllowsOccupiedMoves()) {
            statusMode = "occupied"
            statusMessage = illegalPointMessage(x, y, "")
            return false
        }

        var pointKey = keyFor(x, y)
        if (ruleUsesGoCapture() && koLocKey !== "" && pointKey === koLocKey) {
            statusMode = "message"
            statusMessage = illegalPointMessage(x, y, "ko")
            return false
        }

        var player = currentPlayer
        var forbiddenMove = pointIsGomokuForbidden(x, y, player, stones)
        var existingChild = branchChildMatching(currentNode(), pointKey, player, false)
        if (existingChild) {
            selectedPointLocked = false
            selectedPointFromCandidateList = false
            gotoNode(existingChild.id)
            return true
        }

        var item = {
            "x": x,
            "y": y,
            "key": pointKey,
            "player": player,
            "moveNumber": currentMoveNumberValue() + 1,
            "nodeId": -1
        }
        var captured = []
        var ko = GameRules.emptyKoLoc()
        var working = GameRules.cloneStoneMap(stones)
        if (ruleUsesGoCapture()) {
            var result = GameRules.simulateGoMoveOnMap(working, boardDims(), item, true, gameRuleMode)
            if (!result.ok) {
                statusMode = "message"
                statusMessage = illegalPointMessage(x, y, result.reason)
                return false
            }
            captured = result.capturedStones
            ko = GameRules.koLocFromGoMoveResult(gameRuleMode, result)
        } else if (gameRuleMode === gameRuleReversi) {
            var reversi = GameRules.applyReversiMoveOnMap(working, boardDims(), item)
            if (!reversi.ok) {
                statusMode = "message"
                statusMessage = illegalPointMessage(x, y, "")
                return false
            }
        } else {
            working[item.key] = item
        }

        selectedPointLocked = false
        selectedPointFromCandidateList = false
        var node = addMoveNode(player, x, y, false, captured, ko, true, true)
        if (!node)
            return false
        node.gomokuForbidden = forbiddenMove
        applyIncrementalMovePosition(node, working, captured.length, ko)
        statusMode = "turn"
        statusMessage = captured.length > 0 ? trText("captureMessage") + ": " + captured.length : ""
        checkGameOverAfterMove(node)
        scheduleAutoAnalysis()
        requestAiMoveIfNeeded()
        return true
    }

    function placeMoveRulePoint(x, y) {
        var player = currentPlayer
        var sourceNode = currentMoveSourceNode()
        var sourcePoint = sourceNode ? { "x": sourceNode.x, "y": sourceNode.y } : null
        var pointKey = keyFor(x, y)
        var kind = gameRuleMode === gameRuleAtaxx
                   ? GameRules.ataxxMoveKind(stones, boardDims(), x, y, player, sourcePoint)
                   : GameRules.breakthroughMoveKind(stones, boardDims(), x, y, player, sourcePoint)
        if (kind === "" || kind === "source" && sourceNode) {
            statusMode = "message"
            statusMessage = illegalPointMessage(x, y, "")
            return false
        }

        selectedPointLocked = false
        selectedPointFromCandidateList = false

        if (kind === "source") {
            var source = addMoveNode(player, x, y, false, [], GameRules.emptyKoLoc(), true, true, "source")
            if (!source)
                return false
            currentPlayer = player
            rebuildPointLegality()
            boardRevision += 1
            resetEngineSyncState()
            scheduleAutoAnalysis()
            statusMode = "message"
            statusMessage = trText("moveSourceSelected") + ": " + coordinateText(x, y)
            return true
        }

        var item = {
            "x": x,
            "y": y,
            "key": pointKey,
            "player": player,
            "moveNumber": currentMoveNumberValue() + 1,
            "nodeId": -1
        }
        var working = GameRules.cloneStoneMap(stones)
        var result = gameRuleMode === gameRuleAtaxx
                     ? GameRules.applyAtaxxMoveOnMap(working, boardDims(), item, sourcePoint)
                     : GameRules.applyBreakthroughMoveOnMap(working, boardDims(), item, sourcePoint)
        if (!result.ok) {
            statusMode = "message"
            statusMessage = illegalPointMessage(x, y, "")
            return false
        }
        var node = addMoveNode(player, x, y, false, result.capturedStones || [],
                               GameRules.emptyKoLoc(), true, true, "target")
        if (!node)
            return false
        applyIncrementalMovePosition(node, working, (result.capturedStones || []).length, GameRules.emptyKoLoc())
        statusMode = "turn"
        statusMessage = ""
        checkGameOverAfterMove(node)
        scheduleAutoAnalysis()
        requestAiMoveIfNeeded()
        return true
    }

    function applyIncrementalMovePosition(node, nextMap, capturedCount, ko) {
        if (!node || !nextMap)
            return

        if (!node.isPass && nextMap[node.key]) {
            nextMap[node.key].nodeId = node.id
            nextMap[node.key].moveNumber = node.moveNumber
        }

        stones = nextMap
        stoneItems = mapStoneItems(nextMap)
        stoneCount = stoneItems.length
        if (node.player === 1)
            blackCaptures += capturedCount
        else if (node.player === 2)
            whiteCaptures += capturedCount
        ko = ko || GameRules.emptyKoLoc()
        koLocKey = ko.key
        koLocX = ko.x
        koLocY = ko.y
        node.blackCaptures = blackCaptures
        node.whiteCaptures = whiteCaptures
        node.koLocKey = koLocKey
        node.koLocX = koLocX
        node.koLocY = koLocY
        currentPlayer = nextPlayerFromMode()
        rebuildPointLegality()
        refreshWinVisuals(nextMap)
        boardRevision += 1
    }

    function passMove() {
        var player = currentPlayer
        selectedPointLocked = false
        selectedPointFromCandidateList = false
        var node = addMoveNode(player, -1, -1, true, [], GameRules.emptyKoLoc())
        if (!node)
            return
        statusMode = "message"
        statusMessage = (player === 1 ? trText("black") : trText("white")) + " " + trText("passMessage")
        checkGameOverAfterMove(node)
    }

    function checkGameOverAfterMove(node) {
        if (!node)
            return
        refreshGameOutcomeFromCurrentNode(true)
    }

    function refreshGameOutcomeFromCurrentNode(openDialog) {
        if (analysisModeActive()) {
            gameWinner = 0
            gameOverReason = ""
            return false
        }

        var nextWinner = 0
        var nextReason = ""
        var node = currentNode()
        if (gameRuleMode === gameRuleGo && node && node.isPass) {
            var parent = nodeById(node.parent)
            if (parent && parent.isPass)
                nextReason = trText("gameOverDoublePass")
        } else if (gameRuleMode === gameRuleGomoku && node && node.gomokuForbidden === true) {
            nextWinner = node.player === 1 ? 2 : 1
            nextReason = trText("gameOverForbidden")
        } else if ((gameRuleMode === gameRuleGomoku || gameRuleMode === gameRuleConnect6)
                   && gomokuWinLineItems.length > 0) {
            nextWinner = gomokuWinLineItems[0].player
            nextReason = trText("gameOverFive")
        } else if (gameRuleMode === gameRuleHex && hexWinPathPlayer !== 0) {
            nextWinner = hexWinPathPlayer
            nextReason = trText("gameOverHex")
        } else if (gameRuleMode === gameRuleBreakthrough && breakthroughWinInfo.player !== 0) {
            nextWinner = breakthroughWinInfo.player
            nextReason = trText("gameOverBreakthrough")
        }

        gameWinner = nextWinner
        gameOverReason = nextReason
        if (nextReason !== "" && openDialog)
            gameOverDialog.open()
        return nextReason !== ""
    }

    function gameOverDialogText() {
        var reason = gameOverReason.length > 0 ? gameOverReason : trText("gameOverTitle")
        if (gameWinner === 1)
            return trText("blackWins") + "\n" + reason
        if (gameWinner === 2)
            return trText("whiteWins") + "\n" + reason
        return reason
    }

    function undoMove() {
        var node = currentNode()
        if (node && node.parent >= 0)
            gotoNode(node.parent)
    }

    function gotoNode(id) {
        if (!nodeById(id))
            return false
        if (id === currentNodeId)
            return false
        currentNodeId = id
        selectedPointLocked = false
        selectedPointFromCandidateList = false
        rebuildPositionFromNode(id)
        rebuildTreeLayout()
        scheduleAutoAnalysis()
        focusBoardInput()
        return true
    }

    function gotoFirstMove() {
        gotoNode(0)
    }

    function gotoLastMove() {
        var id = currentNodeId
        var node = nodeById(id)
        while (node && node.children && node.children.length > 0) {
            id = node.children[0]
            node = nodeById(id)
        }
        gotoNode(id)
    }

    function gotoRelativeMove(delta) {
        var targetId = currentNodeId
        if (delta < 0) {
            for (var i = 0; i < -delta; ++i) {
                var node = nodeById(targetId)
                if (!node || node.parent < 0)
                    break
                targetId = node.parent
            }
            gotoNode(targetId)
            return
        }
        for (var f = 0; f < delta; ++f) {
            var n = nodeById(targetId)
            if (!n || !n.children || n.children.length <= 0)
                break
            targetId = n.children[0]
        }
        gotoNode(targetId)
    }

    function gotoMoveNumber(moveNumber) {
        if (isNaN(moveNumber))
            return
        var path = [nodeById(0)].concat(nodePath(currentNodeId))
        for (var i = 0; i < path.length; ++i) {
            if (path[i] && path[i].moveNumber === moveNumber) {
                gotoNode(path[i].id)
                return
            }
        }
        for (var id = 0; id < gameNodes.length; ++id) {
            var node = nodeById(id)
            if (node && node.moveNumber === moveNumber) {
                gotoNode(node.id)
                return
            }
        }
    }

    function currentMoveNumberValue() {
        var node = currentNode()
        return node ? node.moveNumber : 0
    }

    function currentMoveNumberText() {
        return String(currentMoveNumberValue())
    }

    function maxMoveNumberValue() {
        var maxMove = 0
        for (var i = 0; i < gameNodes.length; ++i) {
            var node = nodeById(i)
            if (node)
                maxMove = Math.max(maxMove, node.moveNumber)
        }
        return maxMove
    }

    function currentNodeText() {
        var node = currentNode()
        if (!node || node.id === 0)
            return trText("rootMove")
        if (node.moveRole === "source")
            return node.moveNumber + " " + trText("moveSource") + " " + coordinateText(node.x, node.y)
        return node.moveNumber + " " + (node.isPass ? trText("passMove") : coordinateText(node.x, node.y))
    }

    function deleteCurrentNode() {
        var node = currentNode()
        if (!node || node.id === 0)
            return
        var parent = nodeById(node.parent)
        if (parent) {
            var children = (parent.children || []).slice()
            var index = children.indexOf(node.id)
            if (index >= 0)
                children.splice(index, 1)
            parent.children = children
        }
        deleteSubtree(node.id)
        currentNodeId = parent ? parent.id : 0
        gameNodes = gameNodes.slice()
        gameDirty = true
        rebuildPositionFromNode(currentNodeId)
        rebuildTreeLayout()
        scheduleAutoAnalysis()
    }

    function deleteSubtree(id) {
        var node = nodeById(id)
        if (!node)
            return
        var children = (node.children || []).slice()
        for (var i = 0; i < children.length; ++i)
            deleteSubtree(children[i])
        gameNodes[id] = undefined
    }

    function requestDeleteCurrentNode() {
        var node = currentNode()
        if (!node || node.id === 0)
            return
        if (node.children && node.children.length > 0)
            confirmDeleteNodeDialog.open()
        else
            deleteCurrentNode()
    }

    function requestClearBoard() {
        if (gameDirty) {
            pendingClearAction = "clearBoard"
            ruleChangeSaveDialog.open()
            return
        }
        resetGameTree()
    }

    function setCurrentVariationAsMainBranch() {
        var path = nodePath(currentNodeId)
        var changed = false
        for (var i = 0; i < path.length; ++i) {
            var child = path[i]
            var parent = nodeById(child.parent)
            if (!parent)
                continue
            var children = (parent.children || []).slice()
            var index = children.indexOf(child.id)
            if (index > 0) {
                children.splice(index, 1)
                children.unshift(child.id)
                parent.children = children
                changed = true
            }
        }
        if (changed) {
            gameNodes = gameNodes.slice()
            rebuildTreeLayout()
            gameDirty = true
        }
    }

    function toolbarActionEnabled(action) {
        if (action === "delete" || action === "back1" || action === "back10" || action === "firstMove")
            return currentNodeId !== 0
        if (action === "forward1" || action === "forward10" || action === "lastMove") {
            var node = currentNode()
            return !!node && node.children && node.children.length > 0
        }
        if (action === "setMainBranch")
            return currentNodeId !== 0
        return true
    }

    function runToolbarAction(action) {
        if (action === "refresh")
            requestEngineAnalysis(false)
        else if (action === "setMainBranch")
            setCurrentVariationAsMainBranch()
        else if (action === "clearBoard")
            requestClearBoard()
        else if (action === "delete")
            requestDeleteCurrentNode()
        else if (action === "firstMove")
            gotoFirstMove()
        else if (action === "back10")
            gotoRelativeMove(-10)
        else if (action === "back1")
            gotoRelativeMove(-1)
        else if (action === "forward1")
            gotoRelativeMove(1)
        else if (action === "forward10")
            gotoRelativeMove(10)
        else if (action === "lastMove")
            gotoLastMove()
        else if (action === "candidates")
            focusBoardInput()
    }

    function treeNodeAt(x, y) {
        return TreeLayout.nodeAt(treeNodes, x, y)
    }

    function scheduleTreeLayoutRebuild() {
        if (treeLayoutTimer)
            treeLayoutTimer.restart()
        else
            rebuildTreeLayout()
    }

    function rebuildTreeLayout() {
        TreeLayout.rebuild(root)
    }

    function gomokuRuleLabel(rule) {
        return RuleSupport.gomokuRuleLabel(root, rule)
    }

    function gomokuRuleTip(rule) {
        return RuleSupport.gomokuRuleTip(root, rule)
    }

    function gomokuRuleEngineValue(rule) {
        return RuleSupport.gomokuRuleEngineValue(root, rule)
    }

    function normalizedGomokuRuleMode(rule) {
        return RuleSupport.normalizedGomokuRuleMode(root, rule)
    }

    function normalizedGomokuVcnRule(rule) {
        return RuleSupport.normalizedGomokuVcnRule(root, rule)
    }

    function gameRuleText() {
        return RuleSupport.gameRuleText(root)
    }

    function gameRuleTextForMode(mode) {
        return RuleSupport.gameRuleTextForMode(root, mode)
    }

    function gameRuleOptions() {
        return RuleSupport.gameRuleOptions(root)
    }

    function validRuleMode(mode) {
        return RuleSupport.validRuleMode(root, mode)
    }

    function visibleGameRuleOptions() {
        return RuleSupport.visibleGameRuleOptions(root)
    }

    function commonGameRuleOptions() {
        return RuleSupport.commonGameRuleOptions(root)
    }

    function commonGameRuleOptionsWithCurrentAndMore() {
        return RuleSupport.commonGameRuleOptionsWithCurrentAndMore(root)
    }

    function commonGameRuleOptionsWithModeAndMore(mode) {
        return RuleSupport.commonGameRuleOptionsWithModeAndMore(root, mode)
    }

    function ruleTreeRows(collapsedGroups) {
        return RuleSupport.ruleTreeRows(root, collapsedGroups || {})
    }

    function gameRuleCurrentIndex() {
        return RuleSupport.gameRuleCurrentIndex(root)
    }

    function visibleGameRuleCurrentIndex() {
        return RuleSupport.visibleGameRuleCurrentIndex(root)
    }

    function setGameRuleFromIndex(index) {
        RuleSupport.setGameRuleFromIndex(root, index)
    }

    function setVisibleGameRuleFromIndex(index) {
        RuleSupport.setVisibleGameRuleFromIndex(root, index)
    }

    function ruleModeVisible(mode) {
        return RuleSupport.ruleModeVisible(root, mode)
    }

    function ruleGroupVisible(modes) {
        return RuleSupport.ruleGroupVisible(root, modes)
    }

    function setRuleModeVisible(mode, visible) {
        RuleSupport.setRuleModeVisible(root, mode, visible)
    }

    function setRuleModesVisible(modes, visible) {
        RuleSupport.setRuleModesVisible(root, modes, visible)
    }

    function moveCommonRule(mode, delta) {
        RuleSupport.moveCommonRule(root, mode, delta)
    }

    function ruleGroupVisibilityCheckState(modes) {
        return RuleSupport.ruleGroupVisibilityCheckState(root, modes)
    }

    function ruleGroupHasMutableVisibility(modes) {
        return RuleSupport.ruleGroupHasMutableVisibility(root, modes)
    }

    function goRuleOptions() {
        return RuleSupport.goRuleOptions(root)
    }

    function gomokuRuleOptions() {
        return RuleSupport.gomokuRuleOptions(root)
    }

    function ruleVariantOptions() {
        return RuleSupport.ruleVariantOptions(root)
    }

    function ruleVariantCurrentIndex() {
        return RuleSupport.ruleVariantCurrentIndex(root)
    }

    function ruleVariantCurrentTip() {
        return RuleSupport.ruleVariantCurrentTip(root)
    }

    function setRuleVariantFromIndex(index) {
        RuleSupport.setRuleVariantFromIndex(root, index)
    }

    function ruleVariantText() {
        return RuleSupport.ruleVariantText(root)
    }

    function openRuleVariantDialog() {
        if (gameRuleMode === gameRuleGo)
            goRuleDialog.openWithCurrent()
        else if (gameRuleMode === gameRuleGomoku)
            gomokuRuleDialog.openWithCurrent()
        else
            noRuleVariantDialog.open()
    }

    function applyGoRuleSettings(scoring, ko, suicide, tax, handicapBonus, hasButton) {
        goScoringRule = scoring
        goKoRule = ko
        goSuicideAllowed = suicide === true
        goTaxRule = tax
        goWhiteHandicapBonus = String(handicapBonus)
        goButtonRule = hasButton === true
        resetEngineSyncState()
        scheduleAutoAnalysis()
        if (persistentSettingsLoaded)
            savePersistentSettings()
    }

    function applyGomokuRuleSettings(ruleMode, maxMoves, vcn, firstPassWin) {
        var useFirstPassWin = firstPassWin === true
        gomokuRuleMode = RuleSupport.normalizedGomokuRuleMode(root, ruleMode)
        gomokuRuleMaxMoves = Math.round(clamp(Number(maxMoves), 0, maxLargeIntegerSetting))
        gomokuRuleVcn = useFirstPassWin ? "NOVC" : RuleSupport.normalizedGomokuVcnRule(root, vcn)
        gomokuRuleFirstPassWin = useFirstPassWin
        rebuildPositionFromNode(currentNodeId)
        resetEngineSyncState()
        scheduleAutoAnalysis()
        if (persistentSettingsLoaded)
            savePersistentSettings()
    }

    function ruleModeButtonsVisible() {
        return RuleSupport.ruleModeButtonsVisible(root)
    }

    function ruleVariantComboVisible() {
        return RuleSupport.ruleVariantComboVisible(root)
    }

    function toolbarRuleSettingsVisible() {
        return RuleSupport.toolbarRuleSettingsVisible(root)
    }

    function toolbarBoardPresentationVisible() {
        return RuleSupport.toolbarBoardPresentationVisible(root)
    }

    function toolbarHexBoardStyleVisible() {
        return RuleSupport.toolbarHexBoardStyleVisible(root)
    }

    function toolbarHexBoardRotationVisible() {
        return RuleSupport.toolbarHexBoardRotationVisible(root)
    }

    function toolbarPresentationControlsVisible() {
        return RuleSupport.toolbarPresentationControlsVisible(root)
    }

    function komiControlsVisible() {
        return RuleSupport.komiControlsVisible(root)
    }

    function komiUsageForRule(mode) {
        return RuleSupport.komiUsageForRule(root, mode)
    }

    function currentKomiUsage() {
        return RuleSupport.currentKomiUsage(root)
    }

    function komiLabelText() {
        return currentKomiUsage() === komiUsageBlackAggression ? trText("blackAggression") : trText("komi")
    }

    function komiMinimumForRule(mode) {
        return komiUsageForRule(mode) === komiUsageBlackAggression ? -10 : -maxKomiMagnitude
    }

    function komiMaximumForRule(mode) {
        return komiUsageForRule(mode) === komiUsageBlackAggression ? 10 : maxKomiMagnitude
    }

    function komiMinimum() {
        return komiMinimumForRule(gameRuleMode)
    }

    function komiMaximum() {
        return komiMaximumForRule(gameRuleMode)
    }

    function analysisWideRootNoiseControlsVisible() {
        return true
    }

    function engineCommandEditable() {
        return RuleSupport.engineCommandEditable(root)
    }

    function customBoardSizeAllowed() {
        return RuleSupport.customBoardSizeAllowed(root)
    }

    function boardSizePresets() {
        return RuleSupport.boardSizePresets(root)
    }

    function boardSizePresetAllowed(size) {
        return RuleSupport.boardSizePresetAllowed(root, size)
    }

    function boardDimensionsAllowedForPackage(xSize, ySize) {
        return RuleSupport.boardDimensionsAllowedForPackage(root, xSize, ySize)
    }

    function adjustedBoardDimensionsForRule(mode, xSize, ySize) {
        return RuleSupport.adjustedBoardDimensionsForRule(root, mode, xSize, ySize)
    }

    function boardDimensionsAllowedForRule(mode, xSize, ySize) {
        return RuleSupport.boardDimensionsAllowedForRule(root, mode, xSize, ySize)
    }

    function ruleModeAllowedForPackage(mode) {
        return RuleSupport.ruleModeAllowedForPackage(root, mode)
    }

    function ruleBoardSizeRejectText(mode, xSize, ySize) {
        return RuleSupport.ruleBoardSizeRejectText(root, mode, xSize, ySize)
    }

    function packageDefaultBoardSize() {
        return RuleSupport.packageDefaultBoardSize(root)
    }

    function packageModeText(mode) {
        return RuleSupport.packageModeText(root, mode)
    }

    function boardPresentationOptions() {
        return RuleSupport.boardPresentationOptions(root)
    }

    function boardPresentationCurrentIndex() {
        return RuleSupport.boardPresentationCurrentIndex(root)
    }

    function setBoardPresentationFromIndex(index) {
        RuleSupport.setBoardPresentationFromIndex(root, index)
    }

    function boardPresentationText(mode) {
        return RuleSupport.boardPresentationText(root, mode)
    }

    function hexBoardStyleOptions() {
        return RuleSupport.hexBoardStyleOptions(root)
    }

    function hexBoardStyleCurrentIndex() {
        return RuleSupport.hexBoardStyleCurrentIndex(root)
    }

    function setHexBoardStyleFromIndex(index) {
        RuleSupport.setHexBoardStyleFromIndex(root, index)
    }

    function hexBoardRotationOptions() {
        return RuleSupport.hexBoardRotationOptions(root)
    }

    function hexBoardRotationCurrentIndex() {
        return RuleSupport.hexBoardRotationCurrentIndex(root)
    }

    function setHexBoardRotationFromIndex(index) {
        RuleSupport.setHexBoardRotationFromIndex(root, index)
    }

    function packageBoardSizeRejectText(xSize, ySize) {
        return RuleSupport.packageBoardSizeRejectText(root, xSize, ySize)
    }

    function normalizeGomokuRuleForCurrentMode() {
        RuleSupport.normalizeGomokuRuleForCurrentMode(root)
    }

    function requestRuleModeChange(mode) {
        RuleSupport.requestRuleModeChange(root, mode, ruleChangeSaveDialog)
    }

    function openRuleSelectionPopup() {
        Qt.callLater(function() {
            ruleSelectionPopup.open()
        })
    }

    function openCommonGameRulesPopup() {
        Qt.callLater(function() {
            commonGameRulesPopup.open()
        })
    }

    function chooseRuleModeFromMenu(mode) {
        if (typeof settingsMenu !== "undefined") {
            if (typeof settingsMenu.dismiss === "function")
                settingsMenu.dismiss()
            settingsMenu.close()
        }
        Qt.callLater(function() {
            requestRuleModeChange(mode)
            queueFocusBoardInput()
        })
    }

    function applyRuleModeChange(mode) {
        RuleSupport.applyRuleModeChange(root, mode)
    }

    function requestBoardDimensionsChange(xSize, ySize, markDirty) {
        return RuleSupport.requestBoardDimensionsChange(root, xSize, ySize, markDirty, ruleChangeSaveDialog)
    }

    function setBoardDimensions(xSize, ySize, markDirty) {
        return RuleSupport.setBoardDimensions(root, xSize, ySize, markDirty)
    }

    function resetBoardSize() {
        RuleSupport.resetBoardSize(root)
    }

    function pendingClearMessage() {
        return RuleSupport.pendingClearMessage(root)
    }

    function pendingClearTitle() {
        return RuleSupport.pendingClearTitle(root)
    }

    function clearPendingClearAction() {
        RuleSupport.clearPendingClearAction(root)
    }

    function applyPendingClearAction() {
        RuleSupport.applyPendingClearAction(root, loadSgfDialog)
    }

    function normalizeEnginePreset(preset, index) {
        return EnginePresets.normalizePreset(root, preset, index || 0)
    }

    function normalizeEnginePresetList(presets) {
        return EnginePresets.normalizeList(root, presets)
    }

    function serializeEnginePresets() {
        return EnginePresets.serializeList(enginePresets)
    }

    function enginePresetById(id) {
        return EnginePresets.findById(enginePresets, id)
    }

    function activeEnginePreset() {
        return enginePresetById(activeEngineId)
    }

    function enginePresetIndexById(id) {
        return EnginePresets.findIndexById(enginePresets, id)
    }

    function enginePresetRuleText(preset) {
        return EnginePresets.ruleText(root, preset)
    }

    function enginePresetRuleDetailText(preset) {
        return EnginePresets.ruleDetailText(root, preset)
    }

    function enginePresetBoardSizeText(preset) {
        return EnginePresets.boardSizeText(preset)
    }

    function engineMenuTitle() {
        var preset = activeEnginePreset()
        if (!preset || engineDisabled)
            return trText("engineMenuNoEngine")
        if (engineLoading || !engineController || !engineController.ready)
            return "\u23F8 " + preset.name
        return "\u25B6 " + preset.name
    }

    function engineMenuPresetText(index) {
        var preset = index >= 0 && index < enginePresets.length ? enginePresets[index] : null
        return preset ? "[" + (index + 1) + "] " + preset.name : ""
    }

    function engineDefaultOptions() {
        var options = [{ "label": trText("engineNoDefault"), "id": "" }]
        for (var i = 0; i < enginePresets.length; ++i)
            options.push({ "label": "[" + (i + 1) + "] " + enginePresets[i].name, "id": enginePresets[i].id })
        return options
    }

    function engineDefaultCurrentIndex() {
        if (defaultEngineId.length <= 0)
            return 0
        for (var i = 0; i < enginePresets.length; ++i) {
            if (enginePresets[i].id === defaultEngineId)
                return i + 1
        }
        return 0
    }

    function setDefaultEnginePresetFromIndex(index) {
        var options = engineDefaultOptions()
        if (index < 0 || index >= options.length)
            return
        setDefaultEnginePreset(options[index].id)
    }

    function defaultEnginePreset() {
        return enginePresetById(defaultEngineId)
    }

    function setEnginePresetList(presets) {
        enginePresets = EnginePresets.normalizeList(root, presets)
        if (defaultEngineId.length > 0 && !enginePresetById(defaultEngineId))
            defaultEngineId = ""
        if (activeEngineId.length > 0 && !enginePresetById(activeEngineId))
            activeEngineId = ""
        if (persistentSettingsLoaded)
            savePersistentSettings()
    }

    function replaceEnginePreset(index, preset) {
        if (index < 0 || index >= enginePresets.length)
            return
        var next = EnginePresets.cloneList(enginePresets)
        next[index] = EnginePresets.normalizePreset(root, preset, index)
        setEnginePresetList(next)
        if (activeEngineId === next[index].id) {
            applyEnginePresetKomi(next[index], false)
            legacyHexEngineCoordinates = next[index].legacyHexEngineCoordinates
            if (engineController && engineController.command !== next[index].command)
                engineController.command = next[index].command
            resetEngineSyncState()
            scheduleAutoAnalysis()
        }
    }

    function addEnginePreset(preset) {
        var next = EnginePresets.cloneList(enginePresets)
        next.push(EnginePresets.normalizePreset(root, preset || EnginePresets.newPreset(root), next.length))
        setEnginePresetList(next)
        return next.length - 1
    }

    function removeEnginePreset(index) {
        if (index < 0 || index >= enginePresets.length)
            return -1
        var removedId = enginePresets[index].id
        var removedDefault = defaultEngineId === removedId
        var removedActive = activeEngineId === removedId
        var next = EnginePresets.cloneList(enginePresets)
        next.splice(index, 1)
        setEnginePresetList(next)
        if (removedDefault)
            defaultEngineId = ""
        if (removedActive) {
            activeEngineId = ""
            stopEngine()
        }
        if (persistentSettingsLoaded)
            savePersistentSettings()
        return Math.min(index, Math.max(0, next.length - 1))
    }

    function moveEnginePreset(index, delta) {
        return moveEnginePresetTo(index, index + delta)
    }

    function moveEnginePresetTo(index, target) {
        if (index < 0 || target < 0 || index >= enginePresets.length || target >= enginePresets.length)
            return index
        if (index === target)
            return index
        var next = EnginePresets.cloneList(enginePresets)
        var item = next.splice(index, 1)[0]
        next.splice(target, 0, item)
        setEnginePresetList(next)
        return target
    }

    function setDefaultEnginePreset(id) {
        defaultEngineId = enginePresetById(id) ? String(id) : ""
        if (persistentSettingsLoaded)
            savePersistentSettings()
    }

    function setEngineStartupMode(mode) {
        var nextMode = Math.round(clamp(Number(mode), engineStartupDefault, engineStartupNone))
        if (engineStartupMode === nextMode)
            return
        engineStartupMode = nextMode
        if (persistentSettingsLoaded)
            savePersistentSettings()
    }

    function boardTreeEmptyForEngineSwitch() {
        if (currentNodeId !== 0)
            return false
        var rootNode = nodeById(0)
        return !rootNode || !rootNode.children || rootNode.children.length === 0
    }

    function enginePresetRuleMatchesCurrent(preset) {
        if (!preset || preset.ruleMode !== gameRuleMode)
            return false
        if (preset.ruleMode === gameRuleGo)
            return EnginePresets.goRulesMatchApp(root, preset.goRules)
        if (preset.ruleMode === gameRuleGomoku)
            return EnginePresets.gomokuRulesMatchApp(root, preset.gomokuRules)
        return true
    }

    function applyEnginePresetKomi(preset, usePresetRule) {
        if (!preset)
            return
        var mode = usePresetRule ? preset.ruleMode : gameRuleMode
        if (komiUsageForRule(mode) === komiUsageKomi)
            komi = clampKomiValueForRule(preset.komi, mode, defaultKomiForRule(mode))
        else
            komi = 0.0
    }

    function applyEnginePresetBoardDefaults(preset) {
        if (!preset)
            return
        gameRuleMode = preset.ruleMode
        if (preset.ruleMode === gameRuleGo) {
            var goRules = EnginePresets.normalizeGoRules(root, preset.goRules)
            goScoringRule = goRules.scoringRule
            goKoRule = goRules.koRule
            goSuicideAllowed = goRules.suicideAllowed
            goTaxRule = goRules.taxRule
            goWhiteHandicapBonus = goRules.handicapBonus
            goButtonRule = goRules.buttonRule
        } else if (preset.ruleMode === gameRuleGomoku) {
            var gomokuRules = EnginePresets.normalizeGomokuRules(root, preset.gomokuRules, preset.ruleVariant)
            gomokuRuleMode = gomokuRules.ruleMode
            gomokuRuleMaxMoves = gomokuRules.maxMoves
            gomokuRuleVcn = gomokuRules.vcnRule
            gomokuRuleFirstPassWin = gomokuRules.firstPassWin
        }
        normalizeGomokuRuleForCurrentMode()
        if (preset.ruleMode === gameRuleGomoku) {
            gomokuBoardPresentationMode = preset.boardPresentationMode
            boardPresentationMode = gomokuBoardPresentationMode
        } else if (preset.ruleMode === gameRuleTorusGo) {
            boardPresentationMode = torusGoBoardPresentationMode
        } else {
            goBoardPresentationMode = boardPresentationIntersections
            boardPresentationMode = goBoardPresentationMode
        }
        var adjusted = RuleSupport.adjustedBoardDimensionsForRule(root, preset.ruleMode,
                                                                  preset.boardSizeX, preset.boardSizeY)
        boardSizeX = adjusted.x
        boardSizeY = adjusted.y
        if (preset.ruleMode === gameRuleHex)
            coordinateDisplayMode = coordinateDisplayHex
        applyEnginePresetKomi(preset, true)
        legacyHexEngineCoordinates = preset.legacyHexEngineCoordinates
        clearHover(true)
        resetGameTree()
        setSelectedPoint(0, 0)
        gameDirty = false
    }

    function loadEnginePreset(id, startup) {
        var preset = enginePresetById(id)
        if (!preset || !engineController)
            return false

        var emptyBoard = boardTreeEmptyForEngineSwitch()
        var mismatchedRule = !emptyBoard && !enginePresetRuleMatchesCurrent(preset)
        if (emptyBoard)
            applyEnginePresetBoardDefaults(preset)
        else {
            applyEnginePresetKomi(preset, false)
            legacyHexEngineCoordinates = preset.legacyHexEngineCoordinates
        }

        activeEngineId = preset.id
        engineInitialCommandsSentForId = ""
        engineDisabled = false
        engineLoading = true
        engineNoticeDismissed = false
        engineFailureNoticeText = ""
        if (engineController.command !== preset.command)
            engineController.command = preset.command
        resetEngineSyncState()
        clearEngineCandidates()
        if (engineController.running)
            restartEngine()
        else
            startEngine()
        if (mismatchedRule)
            engineRuleWarningDialog.openForPreset(preset)
        if (persistentSettingsLoaded)
            savePersistentSettings()
        statusMode = "message"
        statusMessage = trText("engineLoaded") + ": " + preset.name
        return true
    }

    function chooseNoEngineFromList() {
        activeEngineId = ""
        stopEngine()
        if (persistentSettingsLoaded)
            savePersistentSettings()
        focusBoardInput()
    }

    function showStartupEngineListIfNeeded() {
        if (enginePresetStartupPromptShown || engineStartupMode === engineStartupNone)
            return
        if (engineStartupMode === engineStartupDefault && defaultEngineId.length > 0 && enginePresetById(defaultEngineId))
            return
        if (engineStartupMode === engineStartupLast && activeEngineId.length > 0 && enginePresetById(activeEngineId))
            return
        enginePresetStartupPromptShown = true
        engineListDialog.openStartup()
    }

    function runStartupEnginePolicy() {
        if (engineStartupMode === engineStartupNone) {
            engineDisabled = true
            return
        }
        if (engineStartupMode === engineStartupManual) {
            engineDisabled = true
            startupEngineListTimer.start()
            return
        }

        var startupId = engineStartupMode === engineStartupLast ? activeEngineId : defaultEngineId
        if (startupId.length > 0 && enginePresetById(startupId)) {
            loadEnginePreset(startupId, true)
            return
        }
        engineDisabled = true
        startupEngineListTimer.start()
    }

    function activeEngineInitialCommands() {
        var preset = activeEnginePreset()
        if (!preset)
            return []
        var pieces = String(preset.initialCommands || "").split(";")
        var commands = []
        for (var i = 0; i < pieces.length; ++i) {
            var command = pieces[i].trim()
            if (command.length > 0)
                commands.push(command)
        }
        return commands
    }

    function sendActiveEngineInitialCommands() {
        if (!engineController || !engineController.ready || activeEngineId.length <= 0)
            return
        if (engineInitialCommandsSentForId === activeEngineId)
            return
        engineInitialCommandsSentForId = activeEngineId
        var commands = activeEngineInitialCommands()
        for (var i = 0; i < commands.length; ++i)
            engineController.sendCommand(commands[i])
    }

    function engineRuleCommands() {
        if (gameRuleMode === gameRuleGo)
            return [ "kata-set-rules " + JSON.stringify(RuleSupport.goRulesObject(root)) ]
        if (gameRuleMode === gameRuleTorusGo)
            return [ "kata-set-rules " + JSON.stringify(RuleSupport.torusGoRulesObject(root)) ]
        if (gameRuleMode === gameRuleGomoku)
            return [ "kata-set-rules " + JSON.stringify(RuleSupport.gomokuRulesObject(root)) ]
        return []
    }

    function engineBoardSizeCommands() {
        if (boardSizeX === boardSizeY)
            return [ "boardsize " + boardSizeX ]
        return [ "rectangular_boardsize " + boardSizeX + " " + boardSizeY ]
    }

    function legacyHexEngineCoordinateMode() {
        return legacyHexEngineCoordinates
    }

    function engineCommunicationBoardWidth() {
        if (!legacyHexEngineCoordinateMode())
            return boardSizeX
        return Math.max(1, 2 * Math.max(1, boardSizeX) + Math.max(1, boardSizeY) - 1)
    }

    function engineCommunicationBoardHeight() {
        if (!legacyHexEngineCoordinateMode())
            return boardSizeY
        return Math.max(1, 2 * Math.max(1, boardSizeY))
    }

    function engineCommunicationPoint(x, y) {
        if (!legacyHexEngineCoordinateMode())
            return { "x": x, "y": y }
        return { "x": 2 * x + y + 1, "y": 2 * y }
    }

    function boardPointFromEngineCommunication(x, y) {
        if (!legacyHexEngineCoordinateMode())
            return { "x": x, "y": y }
        if (y % 2 !== 0)
            return null
        var boardY = y / 2
        var rawX = x - 1 - boardY
        if (rawX % 2 !== 0)
            return null
        return { "x": rawX / 2, "y": boardY }
    }

    function engineCoordinateForNode(node) {
        if (!node)
            return ""
        if (node.isPass)
            return "pass"
        var point = engineCommunicationPoint(node.x, node.y)
        return gtpCoordinateName(point.x, point.y, engineCommunicationBoardWidth(), engineCommunicationBoardHeight())
    }

    function parseEngineCoordinate(text) {
        var point = parseGtpCoordinateName(text,
                                           engineCommunicationBoardWidth(),
                                           engineCommunicationBoardHeight())
        if (!point)
            return null
        var boardPoint = boardPointFromEngineCommunication(point.x, point.y)
        if (!boardPoint || !pointInRuleBoard(boardPoint.x, boardPoint.y))
            return null
        return boardPoint
    }

    function enginePlayCommandForNode(node) {
        var color = node.player === 1 ? "B" : "W"
        return "play " + color + " " + engineCoordinateForNode(node)
    }

    function engineBoardSignature() {
        var ruleDetail = gameRuleMode === gameRuleGomoku ? JSON.stringify(RuleSupport.gomokuRulesObject(root))
                       : gameRuleMode === gameRuleGo ? JSON.stringify(RuleSupport.goRulesObject(root))
                       : gameRuleMode === gameRuleTorusGo ? JSON.stringify(RuleSupport.torusGoRulesObject(root))
                       : gameRuleMode === gameRuleHex ? "hex" : "go"
        return [boardSizeX, boardSizeY, gameRuleMode, ruleDetail,
                legacyHexEngineCoordinateMode() ? "legacyHex" : "normal"].join(":")
    }

    function engineKomiCommand() {
        if (!komiControlsVisible())
            return ""
        return "komi " + Number(effectiveKomi()).toFixed(1)
    }

    function engineAnalysisWideRootNoiseCommand() {
        return "kata-set-param analysisWideRootNoise " + formatAnalysisWideRootNoise(effectiveAnalysisWideRootNoise())
    }

    function engineAnalysisParameterCommands() {
        var commands = []
        var komiCommand = engineKomiCommand()
        if (komiCommand.length > 0)
            commands.push(komiCommand)
        commands.push(engineAnalysisWideRootNoiseCommand())
        return commands
    }

    function engineKomiSignature() {
        var usage = currentKomiUsage()
        var komiPart = usage === komiUsageNone ? "none" : (usage + ":" + Number(effectiveKomi()).toFixed(1))
        return komiPart + ":wrn:" + formatAnalysisWideRootNoise(effectiveAnalysisWideRootNoise())
    }

    function engineSyncCommands() {
        var path = nodePath(currentNodeId)
        var commands = [ "stop" ]

        if (engineNeedsFullSync || engineSyncedBoardSignature !== engineBoardSignature()) {
            commands = commands.concat(engineBoardSizeCommands())
            commands = commands.concat(engineAnalysisParameterCommands())
            var fullRuleCommands = engineRuleCommands()
            for (var ruleCommandIndex = 0; ruleCommandIndex < fullRuleCommands.length; ++ruleCommandIndex)
                commands.push(fullRuleCommands[ruleCommandIndex])
            commands.push("clear_board")
            for (var fullIndex = 0; fullIndex < path.length; ++fullIndex)
                commands.push(enginePlayCommandForNode(path[fullIndex]))
            engineSyncedNodeIds = []
            for (var fullPathIndex = 0; fullPathIndex < path.length; ++fullPathIndex)
                engineSyncedNodeIds.push(path[fullPathIndex].id)
            engineSyncedBoardSignature = engineBoardSignature()
            engineSyncedKomiSignature = engineKomiSignature()
            engineNeedsFullSync = false
            return commands
        }

        if (engineSyncedKomiSignature !== engineKomiSignature()) {
            commands = commands.concat(engineAnalysisParameterCommands())
            engineSyncedKomiSignature = engineKomiSignature()
        }
        var pathIds = []
        for (var p = 0; p < path.length; ++p)
            pathIds.push(path[p].id)

        var commonLength = 0
        var maxCommonLength = Math.min(engineSyncedNodeIds.length, pathIds.length)
        while (commonLength < maxCommonLength
               && engineSyncedNodeIds[commonLength] === pathIds[commonLength])
            commonLength += 1

        for (var undoIndex = engineSyncedNodeIds.length - 1; undoIndex >= commonLength; --undoIndex)
            commands.push("undo")
        for (var playIndex = commonLength; playIndex < path.length; ++playIndex)
            commands.push(enginePlayCommandForNode(path[playIndex]))

        engineSyncedNodeIds = pathIds
        engineSyncedBoardSignature = engineBoardSignature()
        engineNeedsFullSync = false
        return commands
    }

    function analyzeCommand() {
        var interval = Math.max(1, Math.round(Number(analysisIntervalCentiseconds)))
        return "kata-analyze " + interval
    }

    function genmoveCommand() {
        return "genmove " + (currentPlayer === 1 ? "B" : "W")
    }

    function timeSettingsCommand() {
        var seconds = Math.max(0.1, Number(secondsPerMove))
        if (isNaN(seconds))
            seconds = 5.0
        return "time_settings 0 " + seconds.toFixed(1) + " 1"
    }

    function resetEngineSyncState() {
        stopAnalysisLimitTimer()
        engineSyncedNodeIds = []
        engineSyncedBoardSignature = ""
        engineSyncedKomiSignature = ""
        engineNeedsFullSync = true
    }

    function requestEngineAnalysis(force) {
        if (!analysisModeActive() || enginePaused || engineDisabled || !engineAutoAnalyze || !engineController)
            return
        engineLoading = !engineController.ready
        engineNoticeDismissed = false
        engineAnalysisRequestNodeId = currentNodeId
        engineAnalysisRequestGeneration = gameTreeGeneration
        engineAnalysisRequestBoardSignature = engineBoardSignature()
        engineAnalysisRequestKomiSignature = engineKomiSignature()
        engineController.requestAnalysis(engineSyncCommands(), analyzeCommand())
        statusMode = "message"
        statusMessage = trText("engineAnalyzeRequested")
        resetAnalysisLimitTimer()
    }

    function scheduleAutoAnalysis() {
        if (!appReady || !analysisModeActive() || enginePaused || engineDisabled || !engineAutoAnalyze)
            return
        autoAnalyzeTimer.restart()
    }

    function startEngine() {
        if (!engineController)
            return
        engineDisabled = false
        engineLoading = true
        engineNoticeDismissed = false
        engineFailureNoticeText = ""
        if (!engineController.running)
            engineInitialCommandsSentForId = ""
        engineController.ensureStarted()
    }

    function stopEngine() {
        if (!engineController)
            return
        engineDisabled = true
        engineController.stop()
        engineInitialCommandsSentForId = ""
        engineLoading = false
        engineFailureNoticeText = ""
        stopAnalysisLimitTimer()
        clearEngineCandidates()
        showCachedAnalysisForCurrentNode()
    }

    function restartEngine() {
        if (!engineController)
            return
        engineDisabled = false
        engineLoading = true
        engineNoticeDismissed = false
        engineFailureNoticeText = ""
        engineInitialCommandsSentForId = ""
        resetEngineSyncState()
        engineController.restart()
    }

    function toggleEnginePause() {
        if (!analysisModeActive()) {
            stopAiPlay()
            return
        }
        if (enginePaused)
            resumeEngineAnalysis()
        else
            pauseEngineAnalysis()
    }

    function pauseEngineAnalysis() {
        enginePaused = true
        stopAnalysisLimitTimer()
        if (engineController)
            engineController.sendCommand("stop")
        statusMode = "message"
        statusMessage = trText("enginePaused")
    }

    function resumeEngineAnalysis() {
        enginePaused = false
        scheduleAutoAnalysis()
    }

    function resetAnalysisLimitTimer() {
        if (!analysisModeActive() || enginePaused || engineDisabled || !engineAutoAnalyze || maxAnalysisSeconds <= 0) {
            analysisLimitTimer.stop()
            return
        }
        analysisLimitTimer.interval = Math.max(1, Math.round(Number(maxAnalysisSeconds))) * 1000
        analysisLimitTimer.restart()
    }

    function stopAnalysisLimitTimer() {
        analysisLimitTimer.stop()
    }

    function pauseEngineAnalysisByLimit() {
        if (!analysisModeActive() || enginePaused || maxAnalysisSeconds <= 0)
            return
        pauseEngineAnalysis()
        statusMode = "message"
        statusMessage = trText("analysisAutoPaused")
    }

    function setPlayMode(mode) {
        if (mode < playModeAnalysis || mode > playModeAiSelf)
            return
        playMode = mode
        if (analysisModeActive()) {
            refreshGameOutcomeFromCurrentNode(false)
            genmoveInFlight = false
            scheduleAutoAnalysis()
        } else {
            enginePaused = false
            refreshGameOutcomeFromCurrentNode(false)
            requestAiMoveIfNeeded()
        }
    }

    function analysisModeActive() {
        return playMode === playModeAnalysis
    }

    function engineReadyForPlayMode() {
        return !!engineController
               && !engineDisabled
               && engineController.running
               && engineController.ready
               && !engineController.failed
               && !engineLoading
    }

    function aiShouldMove() {
        if (analysisModeActive() || gameWinner !== 0 || gameOverReason !== "")
            return false
        if (playMode === playModeAiSelf)
            return true
        if (playMode === playModeAiBlack)
            return currentPlayer === 1
        if (playMode === playModeAiWhite)
            return currentPlayer === 2
        return false
    }

    function requestAiMoveIfNeeded() {
        if (!aiShouldMove() || genmoveInFlight || engineDisabled || !engineController)
            return
        if (!engineReadyForPlayMode()) {
            startEngine()
            return
        }
        genmoveInFlight = true
        genmovePlayer = currentPlayer
        activeGenmoveRequestId = ++genmoveRequestSerial
        engineController.requestMove(engineSyncCommands(), timeSettingsCommand(), genmoveCommand(), activeGenmoveRequestId)
        statusMode = "message"
        statusMessage = trText("engineThinking")
    }

    function stopAiPlay() {
        genmoveInFlight = false
        activeGenmoveRequestId = 0
        genmovePlayer = 0
        playMode = playModeAnalysis
        if (engineController)
            engineController.sendCommand("stop")
        statusMode = "message"
        statusMessage = trText("gameStopped")
        scheduleAutoAnalysis()
    }

    function applyGeneratedMove(moveText) {
        var text = String(moveText).trim()
        applyingGeneratedMove = true
        if (text.toLowerCase() === "pass" || text.length === 0)
            passMove()
        else {
            var point = parseEngineCoordinate(text)
            if (point)
                placeStone(point.x, point.y)
        }
        applyingGeneratedMove = false
    }

    function candidateVisitCount(candidate) {
        return CandidateAnalysis.visitCount(candidate)
    }

    function candidateWinrateValue(candidate) {
        return CandidateAnalysis.winrateValue(root, candidate)
    }

    function candidateScoreValue(candidate) {
        return CandidateAnalysis.scoreValue(root, candidate)
    }

    function formatCandidateNumber(value, decimals, showPercent) {
        return CandidateAnalysis.formatCandidateNumber(root, value, decimals, showPercent)
    }

    function candidateWinrateText(candidate) {
        return CandidateAnalysis.winrateText(root, candidate)
    }

    function candidateScoreDisplayEnabled() {
        return CandidateAnalysis.scoreDisplayEnabled(root)
    }

    function candidateScoreTitle() {
        return CandidateAnalysis.scoreTitle(root)
    }

    function candidateScoreText(candidate) {
        return CandidateAnalysis.scoreText(root, candidate)
    }

    function candidateLabelLines(candidate) {
        return CandidateAnalysis.labelLines(root, candidate)
    }

    function candidateLabelLineOffset(kind) {
        return CandidateAnalysis.labelLineOffset(root, kind)
    }

    function candidateLabelLineHeight(line) {
        return CandidateAnalysis.labelLineHeight(line)
    }

    function candidateLabelScale(markerRadius) {
        return CandidateAnalysis.labelScale(markerRadius)
    }

    function candidateLabelGap(markerRadius) {
        return CandidateAnalysis.labelGap(markerRadius)
    }

    function candidateRingRadius(markerRadius) {
        return CandidateAnalysis.ringRadius(markerRadius)
    }

    function candidateRingLineWidthForRadius(markerRadius) {
        return CandidateAnalysis.ringLineWidthForRadius(root, markerRadius)
    }

    function candidateRankLabelText(displayIndex) {
        return CandidateAnalysis.rankLabelText(root, displayIndex)
    }

    function candidateLabelTotalHeight(lines) {
        return CandidateAnalysis.labelTotalHeight(lines)
    }

    function candidateLabelLineCenterY(lines, lineIndex, height) {
        return CandidateAnalysis.labelLineCenterY(root, lines, lineIndex, height)
    }

    function candidateLabelScaledTotalHeight(lines, markerRadius) {
        return CandidateAnalysis.labelScaledTotalHeight(root, lines, markerRadius)
    }

    function drawCandidateLabelLines(ctx, lines, centerX, centerY, markerRadius, overrideColor) {
        CandidateAnalysis.drawLabelLines(root, ctx, lines, centerX, centerY, markerRadius, overrideColor)
    }

    function drawCandidateRankLabel(ctx, centerX, centerY, markerRadius, rankText) {
        CandidateAnalysis.drawRankLabel(root, ctx, centerX, centerY, markerRadius, rankText)
    }

    function drawCandidateMarker(ctx, centerX, centerY, markerRadius, lines, options) {
        CandidateAnalysis.drawMarker(root, ctx, centerX, centerY, markerRadius, lines, options)
    }

    function candidateMarkerRadius(width, height) {
        return CandidateAnalysis.markerRadius(root, width, height)
    }

    function hexComponent(value) {
        return CandidateAnalysis.hexComponent(root, value)
    }

    function hsbColorHex(hue, saturation, brightness) {
        return CandidateAnalysis.hsbColorHex(root, hue, saturation, brightness)
    }

    function candidateYzyAlphaRatio(visitRatio) {
        return CandidateAnalysis.yzyAlphaRatio(root, visitRatio)
    }

    function candidateMarkerColor(displayIndex, visitRatio) {
        return CandidateAnalysis.markerColor(root, displayIndex, visitRatio)
    }

    function candidateMarkerOpacity(displayIndex, visitRatio) {
        return CandidateAnalysis.markerOpacity(root, displayIndex, visitRatio)
    }

    function candidateMarkerOutlineOpacity(visitRatio) {
        return CandidateAnalysis.markerOutlineOpacity(root, visitRatio)
    }

    function candidatePreviewLabelLines(digitText) {
        return CandidateAnalysis.previewLabelLines(root, digitText)
    }

    function formatVisitCount(value) {
        return CandidateAnalysis.formatVisitCount(value)
    }

    function cloneEngineCandidate(candidate) {
        return CandidateAnalysis.cloneCandidate(candidate)
    }

    function cloneEngineCandidateList(candidates) {
        return CandidateAnalysis.cloneCandidateList(candidates)
    }

    function resetEngineCandidateDisplay() {
        CandidateAnalysis.resetDisplay(root)
    }

    function setEngineCandidateDisplay(candidates, fromCache, revision) {
        CandidateAnalysis.setDisplay(root, candidates, fromCache, revision)
    }

    function nodeAnalysisCacheUsable(node) {
        return CandidateAnalysis.nodeAnalysisCacheUsable(root, node)
    }

    function recordAnalysisWinrateForNode(node, candidates, playerToMove) {
        return CandidateAnalysis.recordAnalysisWinrateForNode(root, node, candidates, playerToMove)
    }

    function cacheAnalysisCandidatesForNode(node, candidates, boardSignature, komiSignature) {
        return CandidateAnalysis.cacheAnalysisCandidatesForNode(root, node, candidates, boardSignature, komiSignature)
    }

    function showCachedAnalysisForCurrentNode() {
        return CandidateAnalysis.showCachedAnalysisForCurrentNode(root)
    }

    function applyEngineCandidateUpdate(candidates, revision) {
        CandidateAnalysis.applyEngineCandidateUpdate(root, candidates, revision)
    }

    function rebuildEngineCandidateItems() {
        CandidateAnalysis.rebuildItems(root)
    }

    function candidatePvMoves(candidate) {
        return CandidateAnalysis.pvMoves(candidate)
    }

    function activeCandidateForVariationPreview() {
        return CandidateAnalysis.activeCandidateForVariationPreview(root)
    }

    function activeCandidateVariationPreviewActive() {
        return CandidateAnalysis.activeCandidateVariationPreviewActive(root)
    }

    function activeCandidateVariationItems(respectMaxMoves) {
        return CandidateAnalysis.activeCandidateVariationItems(root, respectMaxMoves)
    }

    function playActiveCandidateVariation() {
        return CandidateAnalysis.playActiveCandidateVariation(root)
    }
    function updateBestCandidateRing(items) {
        if (!items || items.length <= 0) {
            bestCandidateRingVisible = false
            bestCandidateRingKey = ""
            return
        }
        var best = items[0]
        if (!best || best.displayIndex !== 1) {
            bestCandidateRingVisible = false
            bestCandidateRingKey = ""
            return
        }
        bestCandidateRingX = best.x
        bestCandidateRingY = best.y
        bestCandidateRingKey = best.key
        bestCandidateRingVisible = true
    }

    function clearEngineCandidates() {
        resetEngineCandidateDisplay()
        if (engineController)
            engineController.clearCandidates()
    }

    function enterNoEngineMode(message, keepEngineNotice) {
        engineDisabled = true
        engineLoading = false
        engineNoticeDismissed = keepEngineNotice === true ? false : true
        genmoveInFlight = false
        activeGenmoveRequestId = 0
        genmovePlayer = 0
        if (!analysisModeActive())
            playMode = playModeAnalysis
        stopAnalysisLimitTimer()
        clearEngineCandidates()
        showCachedAnalysisForCurrentNode()
        statusMode = "message"
        statusMessage = message && message.length > 0 ? message + " - " + trText("engineNoEngineMode")
                                                       : trText("engineNoEngineMode")
    }

    function handleEngineLoadFailure(message) {
        var text = message && message.length > 0 ? message : trText("engineFailedNotice")
        engineFailureNoticeText = text
        engineNoticeDismissed = false
        enterNoEngineMode(text, true)
        Qt.callLater(function() {
            engineFailureDialog.open()
        })
    }

    function selectEngineCandidateRow(row) {
        var displayIndex = Math.round(row)
        if (displayIndex <= 0)
            return
        var candidate = null
        for (var i = 0; i < engineCandidateItems.length; ++i) {
            if (engineCandidateItems[i] && engineCandidateItems[i].displayIndex === displayIndex) {
                candidate = engineCandidateItems[i]
                break
            }
        }
        if (!candidate)
            return
        setSelectedPoint(candidate.x, candidate.y, true, true)
        focusBoardInput()
    }

    function playBestEngineMove() {
        if (engineCandidateItems.length <= 0)
            return
        var best = engineCandidateItems[0]
        placeStone(best.x, best.y)
    }

    function recordCurrentAnalysisFromCandidates() {
        AnalysisStatus.recordCurrentAnalysisFromCandidates(root)
    }

    function currentAnalysisHasWinrate() {
        return AnalysisStatus.currentAnalysisHasWinrate(root)
    }

    function currentAnalysisBlackWinrate() {
        return AnalysisStatus.currentAnalysisBlackWinrate(root)
    }

    function currentAnalysisWhiteWinrate() {
        return AnalysisStatus.currentAnalysisWhiteWinrate(root)
    }

    function winrateHistoryPoints() {
        return AnalysisStatus.winrateHistoryPoints(root)
    }

    function engineWinratePlaceholderActive() {
        return AnalysisStatus.engineWinratePlaceholderActive(root)
    }

    function engineWinratePlaceholderText() {
        return AnalysisStatus.engineWinratePlaceholderText(root, engineController)
    }

    function engineCandidateSummaryText() {
        return AnalysisStatus.engineCandidateSummaryText(root)
    }

    function engineDotColor() {
        return AnalysisStatus.engineDotColor(root, engineController)
    }

    function engineNoticeVisible() {
        return AnalysisStatus.engineNoticeVisible(root, engineController)
    }

    function engineNoticeText() {
        return AnalysisStatus.engineNoticeText(root, engineController)
    }

    function engineNoticeFillColor() {
        return AnalysisStatus.engineNoticeFillColor(root, engineController)
    }

    function engineNoticeBorderColor() {
        return AnalysisStatus.engineNoticeBorderColor(root, engineController)
    }

    function engineNoticeTextColor() {
        return AnalysisStatus.engineNoticeTextColor(root, engineController)
    }

    function engineFailureMessage() {
        return AnalysisStatus.engineFailureMessage(root, engineController)
    }

    function engineFailureDialogText() {
        return engineFailureNoticeText.length > 0 ? engineFailureNoticeText : engineFailureMessage()
    }

    function effectiveKomi() {
        if (!komiControlsVisible())
            return 0.0
        return clampKomiValue(komi)
    }

    function defaultKomiForRule(mode) {
        return komiUsageForRule(mode) === komiUsageKomi ? 6.5 : 0.0
    }

    function clampKomiSettingValue(value) {
        var number = Number(value)
        if (isNaN(number))
            return 6.5
        return clamp(number, -maxKomiMagnitude, maxKomiMagnitude)
    }

    function clampKomiValueForRule(value, mode, fallback) {
        var number = Number(value)
        if (isNaN(number))
            number = fallback === undefined ? defaultKomiForRule(mode) : Number(fallback)
        if (isNaN(number))
            number = 0
        if (komiUsageForRule(mode) === komiUsageNone)
            return 0.0
        return clamp(number, komiMinimumForRule(mode), komiMaximumForRule(mode))
    }

    function clampKomiValue(value) {
        return clampKomiValueForRule(value, gameRuleMode, komi)
    }

    function adjustKomiForRuleChange(previousUsage) {
        var usage = currentKomiUsage()
        if (usage === komiUsageNone || usage === komiUsageBlackAggression) {
            komi = 0.0
            return
        }
        if (previousUsage !== komiUsageKomi)
            komi = defaultKomiForRule(gameRuleMode)
        else
            komi = clampKomiValue(komi)
    }

    function setKomiValue(value) {
        var nextKomi = Math.round(clampKomiValue(value) * 10) / 10
        if (isNaN(nextKomi))
            return
        if (Math.abs(komi - nextKomi) < 0.0001)
            return
        komi = nextKomi
        scheduleAutoAnalysis()
    }

    function adjustKomi(delta) {
        setKomiValue(komi + delta)
    }

    function clampAnalysisWideRootNoise(value) {
        var number = Number(value)
        if (isNaN(number))
            return analysisWideRootNoise
        return clamp(number, 0, 2)
    }

    function effectiveAnalysisWideRootNoise() {
        return analysisWideRootNoiseEnabled ? clampAnalysisWideRootNoise(analysisWideRootNoise) : 0
    }

    function formatAnalysisWideRootNoise(value) {
        var number = clampAnalysisWideRootNoise(value)
        return Number(number.toFixed(3)).toString()
    }

    function setAnalysisWideRootNoise(value) {
        var previousEffectiveValue = effectiveAnalysisWideRootNoise()
        var nextValue = Math.round(clampAnalysisWideRootNoise(value) * 1000) / 1000
        if (isNaN(nextValue))
            return
        if (Math.abs(analysisWideRootNoise - nextValue) < 0.0001)
            return
        analysisWideRootNoise = nextValue
        if (Math.abs(previousEffectiveValue - effectiveAnalysisWideRootNoise()) >= 0.0001)
            scheduleAutoAnalysis()
        if (persistentSettingsLoaded)
            savePersistentSettings()
    }

    function setAnalysisWideRootNoiseEnabled(enabled) {
        var nextEnabled = !!enabled
        if (analysisWideRootNoiseEnabled === nextEnabled)
            return
        var previousEffectiveValue = effectiveAnalysisWideRootNoise()
        analysisWideRootNoiseEnabled = nextEnabled
        if (Math.abs(previousEffectiveValue - effectiveAnalysisWideRootNoise()) >= 0.0001)
            scheduleAutoAnalysis()
        if (persistentSettingsLoaded)
            savePersistentSettings()
    }

    function buildGomokuWinLineItems(map) {
        return BoardVisuals.buildGomokuWinLineItems(root, map)
    }

    function buildHexWinPath(map) {
        return BoardVisuals.buildHexWinPath(root, map)
    }

    function gomokuForbiddenActiveForPlayer(player) {
        return gameRuleMode === gameRuleGomoku && gomokuRuleMode === gomokuRuleRenju && player === 1
    }

    function pointIsGomokuForbidden(x, y, player, map) {
        if (!gomokuForbiddenActiveForPlayer(player))
            return false
        var sourceMap = map || stones
        return gomokuForbidden.isForbiddenMove(mapStoneItems(sourceMap), boardSizeX, boardSizeY, x, y)
    }

    function buildGomokuForbiddenPointItems(map) {
        if (!gomokuForbiddenActiveForPlayer(currentPlayer))
            return []
        if (boardSizeX * boardSizeY > maxCachedLegalPoints)
            return []
        return gomokuForbidden.forbiddenPoints(mapStoneItems(map), boardSizeX, boardSizeY)
    }

    function refreshWinVisuals(map) {
        gomokuWinLineItems = buildGomokuWinLineItems(map)
        gomokuForbiddenPointItems = buildGomokuForbiddenPointItems(map)
        var hex = buildHexWinPath(map)
        hexWinPathItems = hex.path || []
        hexWinPathPlayer = hex.player || 0
        breakthroughWinInfo = GameRules.buildBreakthroughWin(map, boardDims(), gameRuleMode)
    }

    function stoneOverlayVisible(moveNumber, lastMove) {
        return BoardVisuals.stoneOverlayVisible(root, moveNumber, lastMove)
    }

    function stoneNumberVisible(moveNumber, lastMove) {
        return BoardVisuals.stoneNumberVisible(root, moveNumber, lastMove)
    }

    function stoneNumberColor(player, lastMove) {
        return BoardVisuals.stoneNumberColor(player, lastMove)
    }

    function stoneNumberCanvasFont(size, bold) {
        return BoardVisuals.stoneNumberCanvasFont(root, size, bold)
    }

    function stoneNumberBaseFontSize(ctx, text, radius) {
        return BoardVisuals.stoneNumberBaseFontSize(root, ctx, text, radius)
    }

    function stoneNumberFontSize(ctx, text, radius) {
        return BoardVisuals.stoneNumberFontSize(root, ctx, text, radius)
    }

    function stoneNumberMaxWidth(radius) {
        return BoardVisuals.stoneNumberMaxWidth(root, radius)
    }

    function stoneNumberOffsetY(fontSize) {
        return BoardVisuals.stoneNumberOffsetY(fontSize)
    }

    function focusBoardInput() {
        BoardInteraction.focusBoardInput(inputLayer)
    }

    function queueFocusBoardInput() {
        focusBoardInputTimer.restart()
    }

    function itemContainsInputPoint(item, sourceItem, x, y) {
        return BoardInteraction.itemContainsInputPoint(item, sourceItem, x, y)
    }

    function boardInputBlocked(sourceItem, x, y) {
        return BoardInteraction.boardInputBlocked(sourceItem, x, y,
                                                  analysisToolbar, infoPanel,
                                                  branchPanel, commandToolbar)
    }

    function pointFromMouse(x, y) {
        return BoardInteraction.pointFromMouse(boardScene, x, y)
    }

    function clearHover(force) {
        BoardInteraction.clearHover(root, force)
    }

    function cancelCandidateListSelection() {
        return BoardInteraction.cancelCandidateListSelection(root)
    }

    function updateHover(x, y) {
        BoardInteraction.updateHover(root, boardScene, x, y)
    }

    function handleBoardClickFromMouse(x, y) {
        return BoardInteraction.handleBoardClickFromMouse(root, boardScene, x, y)
    }

    function cycleMoveNumberDisplayMode() {
        BoardInteraction.cycleMoveNumberDisplayMode(root)
    }

    function resetBoardVisualSettings() {
        SettingsStore.resetBoardVisualSettings(root)
    }

    function resetCandidateVisualSettings() {
        SettingsStore.resetCandidateVisualSettings(root)
    }

    function resetVisualSettings() {
        SettingsStore.resetVisualSettings(root)
    }

    function openBoardSizeDialog() {
        boardSizeDialog.showForCurrentBoard()
    }

    function openHiddenSettingsDialog() {
        hiddenSettingsDialog.openDialog()
    }

    function openBeginnerTutorial() {
        beginnerTutorialDialog.openTutorial()
    }

    function openEngineCommunicationLog() {
        engineCommunicationWindow.openWindow()
    }

    function openEngineListDialog() {
        engineListDialog.openManage()
    }

    function openSaveSgfDialog() {
        saveSgfDialog.currentFile = ""
        saveSgfDialog.open()
    }

    function openLoadSgfDialog() {
        if (gameDirty) {
            pendingClearAction = "openSgf"
            ruleChangeSaveDialog.open()
            return
        }
        loadSgfDialog.open()
    }

    function openSgfGameTypeWarning(gameId, expectedGameId) {
        Qt.callLater(function() {
            engineRuleWarningDialog.openForSgf(gameId, expectedGameId)
        })
    }

    function buildSgf() {
        return SgfSession.build(root)
    }

    function saveSgfToFile(url) {
        SgfSession.saveToFile(root, fileIo, url)
    }

    function parseSgf(text) {
        return SgfSession.parse(root, text)
    }

    function applyParsedSgf(parsed, url) {
        SgfSession.applyParsed(root, parsed, url)
    }

    function loadSgfFromFile(url) {
        SgfSession.loadFromFile(root, fileIo, url)
    }

    function closeWithoutSaving() {
        suppressUnsavedPrompt = true
        Qt.quit()
    }

    function requestQuit() {
        if (gameDirty) {
            unsavedSgfDialog.open()
            return
        }
        suppressUnsavedPrompt = true
        Qt.quit()
    }

    function onSettingsDialogClosed() {
        scheduleAutoAnalysis()
    }

    function normalizeColorHex(value, fallback) {
        return SettingsStore.normalizeColorHex(value, fallback)
    }

    function normalizePersistentSettings() {
        SettingsStore.normalizePersistentSettings(root)
    }

    function settingValue(key, fallback) {
        return SettingsStore.settingValue(appSettings, key, fallback)
    }

    function settingBool(key, fallback) {
        return SettingsStore.settingBool(appSettings, key, fallback)
    }

    function settingNumberEquals(value, expected) {
        return SettingsStore.settingNumberEquals(value, expected)
    }

    function migratePersistentSettings() {
        SettingsStore.migratePersistentSettings(root)
    }

    function loadPersistentSettings() {
        SettingsStore.loadPersistentSettings(root, appSettings)
    }

    function savePersistentSettings() {
        SettingsStore.savePersistentSettings(root, appSettings, engineController)
    }
    function applyPackageModeConstraints(restartIfChanged) {
        EngineSupport.applyPackageModeConstraints(root, restartIfChanged, engineController)
    }

    function applyUniversalEngineCommand(restartIfChanged) {
        EngineSupport.applyUniversalEngineCommand(root, restartIfChanged, engineController)
    }

    function completeInitialSetup(openTutorial) {
        firstLaunchCompleted = true
        savePersistentSettings()
        if (initialSetupDialog.visible)
            initialSetupDialog.close()
        if (openTutorial || startupBeginnerTutorialRequested) {
            startupBeginnerTutorialRequested = false
            openBeginnerTutorial()
        }
        runStartupEnginePolicy()
        focusBoardInput()
    }

    function appendEngineCommunication(stream, line) {
        EngineSupport.appendCommunication(engineCommunicationLogModel, stream, line, engineCommunicationLogLimit)
    }

    function clearEngineCommunicationLog() {
        EngineSupport.clearCommunication(engineCommunicationLogModel)
    }

    function engineCommunicationLineFiltered(stream, line) {
        return EngineSupport.communicationLineFiltered(stream, line)
    }

    function engineCommunicationColor(stream) {
        return EngineSupport.communicationColor(stream)
    }

    Connections {
        target: engineController

        function onEngineInput(line) {
            root.appendEngineCommunication("stdin", line)
        }

        function onEngineOutput(line) {
            root.appendEngineCommunication("stdout", line)
        }

        function onEngineErrorOutput(line) {
            root.appendEngineCommunication("stderr", line)
        }

        function onCommandChanged() {
            root.resetEngineSyncState()
        }

        function onCandidatesChanged() {
            root.applyEngineCandidateUpdate(engineController.candidates,
                                            engineController.candidateRevision)
        }

        function onReadyChanged() {
            if (engineController.ready) {
                root.engineLoading = false
                root.sendActiveEngineInitialCommands()
                root.scheduleAutoAnalysis()
                root.requestAiMoveIfNeeded()
            }
        }

        function onFailedChanged() {
            if (engineController.failed) {
                root.handleEngineLoadFailure(root.engineFailureMessage())
            }
        }

        function onMoveGenerated(requestId, move, ok, rawLine) {
            if (requestId !== root.activeGenmoveRequestId)
                return
            root.genmoveInFlight = false
            root.activeGenmoveRequestId = 0
            root.genmovePlayer = 0
            if (!ok) {
                root.statusMode = "message"
                root.statusMessage = rawLine
                return
            }
            root.applyGeneratedMove(move)
            root.requestAiMoveIfNeeded()
        }
    }

    Component.onCompleted: {
        loadPersistentSettings()
        startupBeginnerTutorialRequested = showBeginnerTutorialOnNextLaunch
        if (showBeginnerTutorialOnNextLaunch) {
            showBeginnerTutorialOnNextLaunch = false
            savePersistentSettings()
        }
        normalizePersistentSettings()
        persistentSettingsLoaded = true
        resetGameTree()
        setSelectedPoint(0, 0)
        appReady = true
        if (!firstLaunchCompleted)
            firstLaunchTimer.start()
        if (firstLaunchCompleted)
            runStartupEnginePolicy()
        else
            engineDisabled = true
        if (firstLaunchCompleted && startupBeginnerTutorialRequested)
            startupBeginnerTutorialTimer.start()
        scheduleAutoAnalysis()
    }

    AnalysisToolbar { id: analysisToolbar; app: root }
    CommandToolbar { id: commandToolbar; app: root }
    BoardScene { id: boardScene; app: root }
    BoardInputLayer { id: inputLayer; app: root; anchors.fill: boardScene }
    InfoPanel { id: infoPanel; app: root }

    Rectangle {
        id: engineStartupNotice
        visible: root.engineNoticeVisible()
        x: Math.round(root.clamp(root.boardStageCenterX - width / 2,
                                 root.boardStageLeftReserve + root.panelGap,
                                 root.width - root.boardStageRightReserve - root.panelGap - width))
        anchors.bottom: commandToolbar.top
        anchors.bottomMargin: root.panelGap
        width: Math.min(root.compactLayout ? 390 : 470,
                        Math.max(280, root.width - root.boardStageLeftReserve
                                 - root.boardStageRightReserve - root.panelGap * 2))
        height: root.compactLayout ? 42 : 48
        radius: 6
        color: root.engineNoticeFillColor()
        border.color: root.engineNoticeBorderColor()
        border.width: 2
        opacity: 0.96

        Text {
            anchors.left: parent.left
            anchors.right: noticeCloseButton.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 12
            anchors.rightMargin: 6
            text: root.engineNoticeText()
            color: root.engineNoticeTextColor()
            font.pixelSize: root.compactLayout ? 16 : 18
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        Basic.Button {
            id: noticeCloseButton
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.compactLayout ? 34 : 38
            text: "x"
            font.pixelSize: root.compactLayout ? 18 : 20
            font.bold: true
            onClicked: root.engineNoticeDismissed = true

            contentItem: Text {
                text: noticeCloseButton.text
                color: noticeCloseButton.hovered ? "#11181d" : root.engineNoticeTextColor()
                font: noticeCloseButton.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                color: noticeCloseButton.hovered ? "#ffffff66" : "transparent"
                radius: 4
            }
        }
    }

    BranchPanel { id: branchPanel; app: root }
}
