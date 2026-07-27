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
import "EnginePlay.js" as EnginePlay
import "EngineSpeed.js" as EngineSpeed
import "EngineSync.js" as EngineSync
import "EngineSupport.js" as EngineSupport
import "GameRules.js" as GameRules
import "Ownership.js" as Ownership
import "RuleSupport.js" as RuleSupport
import "rules/RuleRegistry.js" as RuleRegistry
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
    property bool applicationShutdownPrepared: false
    readonly property string saveContinuationNone: ""
    readonly property string saveContinuationQuit: "quit"
    readonly property string saveContinuationPendingAction: "pendingAction"
    property string pendingSaveContinuation: saveContinuationNone
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
    property string koLocKey2: ""
    property int koLocX2: -1
    property int koLocY2: -1
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

    readonly property int gameRuleGo: RuleRegistry.RULE_GO
    readonly property int gameRuleGomoku: RuleRegistry.RULE_GOMOKU
    readonly property int gameRuleHex: RuleRegistry.RULE_HEX
    readonly property int gameRuleSquareFree: RuleRegistry.RULE_SQUARE_FREE
    readonly property int gameRuleReversi: RuleRegistry.RULE_REVERSI
    readonly property int gameRuleConnect6: RuleRegistry.RULE_CONNECT6
    readonly property int gameRuleHexGoParallelogram: RuleRegistry.RULE_HEX_GO_PARALLELOGRAM
    readonly property int gameRuleHexGoHexagon: RuleRegistry.RULE_HEX_GO_HEXAGON
    readonly property int gameRuleHexGoTriangle: RuleRegistry.RULE_HEX_GO_TRIANGLE
    readonly property int gameRuleAtaxx: RuleRegistry.RULE_ATAXX
    readonly property int gameRuleBreakthrough: RuleRegistry.RULE_BREAKTHROUGH
    readonly property int gameRuleTorusGo: RuleRegistry.RULE_TORUS_GO
    readonly property int gameRuleTwoLibGo: RuleRegistry.RULE_TWO_LIB_GO
    readonly property int gameRuleDotsAndBoxes: RuleRegistry.RULE_DOTS_AND_BOXES
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
    readonly property int aiMoveModeGtp: 0
    readonly property int aiMoveModeAnalyze: 1
    property int aiMoveMode: aiMoveModeGtp
    property bool hideAnalysisDuringPlay: true
    property real secondsPerMove: 5.0
    property real analysisSecondsPerMove: 5.0
    property int analysisTotalVisitsPerMove: 0
    property int analysisFirstMoveVisitsPerMove: 0
    readonly property int aiAnalysisWatchdogMilliseconds: 60000
    property int resignMinMove: 80
    property int resignConsecutiveMoves: 3
    property real resignWinrateThreshold: 5.0
    property int aiAnalysisBlackResignCount: 0
    property int aiAnalysisWhiteResignCount: 0
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
    property string engineInitialCommandsPendingForId: ""
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
    property int activeGenmoveSyncRequestId: 0
    property var activeGenmovePosition: null
    property int genmovePlayer: 0
    property bool aiAnalysisInFlight: false
    property int aiAnalysisRequestSerial: 0
    property int activeAiAnalysisRequestId: 0
    property int activeAiAnalysisSyncRequestId: 0
    property var activeAiAnalysisPosition: null
    property double aiAnalysisStartedAt: 0
    property bool applyingGeneratedMove: false
    property var engineCandidates: []
    property var engineCandidateItems: []
    property var engineCandidateItemMap: ({})
    property var engineCandidateTableItems: []
    property int engineCandidateRevision: 0
    property bool engineCandidatesFromCache: false
    property double lastEngineCandidateUiUpdateAt: 0
    readonly property int largeCandidateUiThreshold: 1000
    readonly property int largeCandidateUiIntervalMs: 1000
    property bool bestCandidateRingVisible: false
    property string bestCandidateRingKey: ""
    property int bestCandidateRingX: -1
    property int bestCandidateRingY: -1
    property var engineSyncedNodeIds: []
    property string engineSyncedBoardSignature: ""
    property string engineSyncedKomiSignature: ""
    property bool engineNeedsFullSync: true
    property int engineSyncRequestSerial: 0
    property var pendingEngineSyncSnapshot: null
    property int engineAnalysisRequestNodeId: -1
    property int engineAnalysisRequestGeneration: -1
    property string engineAnalysisRequestBoardSignature: ""
    property string engineAnalysisRequestKomiSignature: ""
    property int engineAnalysisRequestPlayer: 0
    property string engineAnalysisRequestEngineSignature: ""
    property int engineAnalysisSyncRequestId: 0
    property bool engineAnalysisRequestValid: false
    property bool ownershipEnabled: false
    property var engineOwnership: []
    property bool engineOwnershipFromCache: false
    property string engineOwnershipBoardSignature: ""
    property string engineOwnershipKomiSignature: ""
    property string engineOwnershipEngineSignature: ""
    property int engineOwnershipRevision: 0
    property var engineSearchSpeedSamples: []
    property int engineSearchSpeed: -1
    property string engineSearchSpeedKey: ""
    property int analysisRevision: 0
    property int analysisIntervalCentiseconds: 10
    property int maxAnalysisSeconds: 0
    property bool analysisWideRootNoiseEnabled: false
    property real analysisWideRootNoise: 0.05
    readonly property int maxLargeIntegerSetting: 1073741824
    property int candidateDisplayCount: 10
    property int candidateTableRowLimit: 20
    readonly property int maxCandidateTableRowLimit: 10000
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
    property int engineCommunicationLogCharacterLimit: 262144
    property int engineCommunicationLineCharacterLimit: 16384
    readonly property int maxEngineCommunicationLogLines: 10000
    readonly property int maxEngineCommunicationLogCharacters: 2097152
    readonly property int maxEngineCommunicationLineCharacters: 262144
    property int engineCommunicationLogCharacterCount: 0
    property int engineCommunicationLogChangeMask: 0
    property int engineCommunicationStdinRetainedCount: 0
    property int engineCommunicationStdoutRetainedCount: 0
    property int engineCommunicationStderrRetainedCount: 0
    property var engineCommunicationLogState: ({
        "characterCount": 0,
        "stdinRetainedCount": 0,
        "stdoutRetainedCount": 0,
        "stderrRetainedCount": 0,
        "lastChangeMask": 0
    })
    property double engineCommunicationRevision: 0
    property double engineCommunicationStdinRevision: 0
    property double engineCommunicationStdoutRevision: 0
    property double engineCommunicationStderrRevision: 0
    property bool showEngineCommunicationStdin: true
    property bool showEngineCommunicationStdout: true
    property bool showEngineCommunicationStderr: true
    property bool ignoreGtpErrors: true
    property var recentGtpErrors: []

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
        if (gameDirty && !suppressUnsavedPrompt) {
            event.accepted = false
            unsavedSgfDialog.open()
            return
        }
        prepareApplicationShutdown()
        Qt.quit()
    }

    onCoordinateDisplayModeChanged: refreshCoordinateDisplayText()
    onCurrentNodeIdChanged: {
        resetEngineSearchSpeed()
        handleAiAnalysisPositionChanged()
    }
    onGameTreeGenerationChanged: {
        resetEngineSearchSpeed()
        handleAiAnalysisPositionChanged()
    }
    onCurrentPlayerChanged: handleAiAnalysisPositionChanged()
    onActiveEngineIdChanged: {
        resetEngineSearchSpeed()
        handleAiAnalysisPositionChanged()
    }
    onEngineAutoAnalyzeChanged: resetEngineSearchSpeed()
    onEnginePausedChanged: resetEngineSearchSpeed()
    onEngineDisabledChanged: resetEngineSearchSpeed()
    onPlayModeChanged: resetEngineSearchSpeed()
    onAiMoveModeChanged: resetEngineSearchSpeed()
    onAnalysisSecondsPerMoveChanged: handleAiAnalysisLimitsChanged(true)
    onAnalysisTotalVisitsPerMoveChanged: handleAiAnalysisLimitsChanged(false)
    onAnalysisFirstMoveVisitsPerMoveChanged: handleAiAnalysisLimitsChanged(false)
    onOwnershipEnabledChanged: refreshOwnershipRequest()
    onIgnoreGtpErrorsChanged: {
        if (engineController)
            engineController.ignoreGtpErrors = ignoreGtpErrors
    }
    onLanguageChanged: rebuildEngineCandidateItems()
    onCandidateDisplayCountChanged: rebuildEngineCandidateItems()
    onCandidateTableRowLimitChanged: rebuildEngineCandidateItems()
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
    onGameRuleModeChanged: {
        rebuildEngineCandidateItems()
        if (gameRuleMode !== gameRuleGo) {
            ownershipEnabled = false
            resetEngineOwnershipDisplay()
        }
    }
    onLegacyHexEngineCoordinatesChanged: {
        resetEngineSyncState()
        handleAiAnalysisPositionChanged()
        clearEngineCandidates()
        scheduleAutoAnalysis()
        requestAiMoveIfNeeded()
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

                MenuItem {
                    width: ruleSelectionMenu.width
                    enabled: false
                    text: root.currentRuleSelectionText()
                    font.pixelSize: root.compactLayout ? 13 : 15
                    leftPadding: 0
                    rightPadding: 0

                    contentItem: Text {
                        leftPadding: 18
                        rightPadding: 18
                        text: root.currentRuleSelectionText()
                        color: "#7b8a93"
                        font.pixelSize: root.compactLayout ? 13 : 15
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }

                MenuSeparator { }

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

                            AppCheckMark {
                                anchors.centerIn: parent
                                visible: commonRuleMenuItem.selected
                                width: root.compactLayout ? 15 : 17
                                height: width
                                checked: true
                                markColor: "#17212a"
                                lineWidth: root.compactLayout ? 2.1 : 2.4
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
                        ruleSelectionMenu.insertItem(index + 2, object)
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

            Action {
                text: root.trText("engineAddAndConfigure")
                onTriggered: engineListDialog.openManage()
            }

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

            MenuSeparator { }

            Instantiator {
                model: Math.min(10, root.enginePresets.length)

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
                    engineMenu.insertItem(index + 4, object)
                }

                onObjectRemoved: function(index, object) {
                    engineMenu.removeItem(object)
                }
            }

            Action {
                text: root.trText("moreEngines")
                onTriggered: engineListDialog.openPicker()
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
            root.pendingSaveContinuation = root.saveContinuationNone
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
        onTriggered: root.requestScheduledEngineUpdate()
    }

    Timer {
        id: engineSearchSpeedTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.sampleEngineSearchSpeed()
    }

    Timer {
        id: largeCandidateUiUpdateTimer
        interval: root.largeCandidateUiIntervalMs
        repeat: false
        onTriggered: root.flushEngineCandidateUpdate()
    }

    Timer {
        id: engineInitialCommandsCompletionTimer
        interval: 30
        repeat: true
        onTriggered: root.finishActiveEngineInitialCommandsIfIdle()
    }

    Timer {
        id: analysisLimitTimer
        interval: Math.max(1, root.maxAnalysisSeconds) * 1000
        repeat: false
        onTriggered: root.pauseEngineAnalysisByLimit()
    }

    Timer {
        id: aiAnalysisMoveTimer
        interval: Math.max(100, Math.round(Number(root.analysisSecondsPerMove) * 1000))
        repeat: false
        onTriggered: root.tryFinishAiAnalysisMove()
    }

    Timer {
        id: aiAnalysisWatchdogTimer
        interval: root.aiAnalysisWatchdogMilliseconds
        repeat: false
        onTriggered: root.handleAiAnalysisWatchdogTimeout()
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

    AppPopup {
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
        onOpened: collapsedGroups = root.allRuleGroupsCollapsed()

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
                    text: root.currentRuleSelectionText()
                    color: "#7b8a93"
                    font.pixelSize: root.compactLayout ? 13 : 15
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
                                    font.pixelSize: root.compactLayout ? 17 : 19
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                AppCheckMark {
                                    id: ruleSelectionLeafMark
                                    visible: modelData.type === "leaf"
                                             && modelData.value === root.gameRuleMode
                                    width: root.compactLayout ? 16 : 18
                                    height: width
                                    x: ruleSelectionPopup.treeNodeCenter
                                       + Math.max(0, modelData.depth) * ruleSelectionPopup.treeDepthStep
                                       - width / 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    checked: true
                                    markColor: "#1678bd"
                                    lineWidth: root.compactLayout ? 2.3 : 2.6
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

    AppPopup {
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
        onOpened: collapsedGroups = root.allRuleGroupsCollapsed()

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

                                                    AppCheckMark {
                                                        anchors.fill: parent
                                                        anchors.margins: root.compactLayout ? 3 : 4
                                                        checked: commonRuleCheckBox.state === Qt.Checked
                                                        partial: commonRuleCheckBox.state === Qt.PartiallyChecked
                                                        markColor: "#ffffff"
                                                        lineWidth: partial ? 2.4 : (root.compactLayout ? 2.0 : 2.3)
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
        logRevision: root.engineCommunicationRevision
        logCharacterCount: root.engineCommunicationLogCharacterCount
        logChangeMask: root.engineCommunicationLogChangeMask
        stdinRevision: root.engineCommunicationStdinRevision
        stdoutRevision: root.engineCommunicationStdoutRevision
        stderrRevision: root.engineCommunicationStderrRevision
        stdinRetainedCount: root.engineCommunicationStdinRetainedCount
        stdoutRetainedCount: root.engineCommunicationStdoutRetainedCount
        stderrRetainedCount: root.engineCommunicationStderrRetainedCount
        onSendCommand: function(command) { engineController.sendCommand(command) }
        onClearLogRequested: root.clearEngineCommunicationLog()
    }

    function trText(key) {
        language
        var table = translations[language] || translations.zh
        return table[key] || key
    }

    function windowTitleText() {
        var titleText = trText("windowTitle")
        if (!engineController || !engineController.running || engineDisabled)
            return titleText

        var preset = activeEnginePreset()
        if (preset && String(preset.name || "").trim().length > 0)
            titleText += " - " + String(preset.name).trim()

        var speedText = "-"
        var currentKey = currentEngineSearchSpeedKey()
        if (engineSearchSpeedActive()
                && engineSearchSpeedKey === currentKey
                && engineSearchSpeed >= 0) {
            speedText = String(engineSearchSpeed)
        }
        return titleText + " - " + speedText + " " + trText("engineSpeedUnit")
    }

    function currentEngineSearchSpeedKey() {
        return [
                    activeEngineId,
                    engineSyncRequestSerial,
                    gameTreeGeneration,
                    engineAnalysisRequestNodeId,
                    engineAnalysisRequestBoardSignature,
                    engineAnalysisRequestKomiSignature
                ].join("|")
    }

    function engineSearchSpeedActive() {
        return !applicationShutdownPrepared
               && (analysisModeActive() || aiAnalysisInFlight)
               && (aiAnalysisInFlight || engineAutoAnalyze)
               && !enginePaused
               && !engineDisabled
               && !engineLoading
               && !engineCandidatesFromCache
               && engineAnalysisRequestValid
               && !!engineController
               && engineController.running
               && engineController.ready
               && !engineController.failed
               && engineAnalysisRequestNodeId === currentNodeId
               && engineAnalysisRequestGeneration === gameTreeGeneration
               && engineAnalysisRequestBoardSignature === engineBoardSignature()
               && engineAnalysisRequestKomiSignature === engineKomiSignature()
    }

    function resetEngineSearchSpeed() {
        engineSearchSpeedSamples = []
        engineSearchSpeed = -1
        engineSearchSpeedKey = ""
    }

    function sampleEngineSearchSpeed() {
        if (!engineSearchSpeedActive()) {
            resetEngineSearchSpeed()
            return
        }

        var key = currentEngineSearchSpeedKey()
        var total = EngineSpeed.totalVisits(engineCandidates)
        if (total < 0) {
            resetEngineSearchSpeed()
            return
        }

        var sampled = EngineSpeed.nextSample(engineSearchSpeedSamples,
                                             key,
                                             total,
                                             Date.now(),
                                             4,
                                             5000)
        engineSearchSpeedSamples = sampled.samples
        engineSearchSpeed = sampled.speed
        engineSearchSpeedKey = key
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

    function ruleUsesDotsAndBoxes() {
        return RuleSupport.ruleUsesDotsAndBoxes(root, gameRuleMode)
    }

    function infoPanelShowsGoCaptures() {
        return ruleUsesGoCapture()
    }

    function infoPanelShowsStoneCounts() {
        return gameRuleMode === gameRuleReversi || gameRuleMode === gameRuleAtaxx
               || gameRuleMode === gameRuleDotsAndBoxes
    }

    function infoPanelSideText(player) {
        if (infoPanelShowsGoCaptures())
            return trText("captured") + ": " + (player === 1 ? blackCaptures : whiteCaptures)
        if (infoPanelShowsStoneCounts())
            return String(gameRuleMode === gameRuleDotsAndBoxes
                          ? dotsAndBoxesClaimedCount(player) : stoneCountForPlayer(player))
        return ""
    }

    function dotsAndBoxesClaimedCount(player) {
        var count = 0
        for (var key in stones) {
            var stone = stones[key]
            if (stone && stone.player === player && stone.x % 2 === 1 && stone.y % 2 === 1)
                count += 1
        }
        return count
    }

    function dotsAndBoxesBoardFull() {
        if (gameRuleMode !== gameRuleDotsAndBoxes)
            return false
        for (var y = 0; y < boardSizeY; ++y) {
            for (var x = 0; x < boardSizeX; ++x) {
                if (x % 2 !== y % 2 && stoneAt(x, y) === 0)
                    return false
            }
        }
        return true
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
            "koLocKey2": "",
            "koLocX2": -1,
            "koLocY2": -1,
            "analysisBlackWinrate": -1,
            "analysisCandidates": [],
            "analysisCandidateBoardSignature": "",
            "analysisCandidateKomiSignature": "",
            "analysisOwnership": [],
            "analysisOwnershipBoardSignature": "",
            "analysisOwnershipKomiSignature": "",
            "analysisOwnershipEngineSignature": ""
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
        if (gameRuleMode === gameRuleDotsAndBoxes && node && node.extraTurn === true)
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

    function currentKoLoc() {
        return {
            "key": koLocKey,
            "x": koLocX,
            "y": koLocY,
            "key2": koLocKey2,
            "x2": koLocX2,
            "y2": koLocY2
        }
    }

    function pointKeyIsKoBanned(pointKey) {
        return GameRules.koLocMatches(currentKoLoc(), pointKey)
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
                        ? buildPointLegalityMap(stones, currentPlayer, currentKoLoc())
                        : ({})
        legalityRevision += 1
    }

    function pointIsLegal(x, y) {
        legalityRevision
        if (!pointInBoard(x, y))
            return false
        if (!shouldCachePointLegality())
            return pointLegalInMap(stones, x, y, currentPlayer, currentKoLoc())
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
        var candidate = engineCandidateItemMap[key]
        return candidate !== undefined && candidate.boardPoint === true
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
        if (pointKeyIsKoBanned(keyFor(x, y)))
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

    function updateNodePositionMetadata(node, blackCap, whiteCap, ko) {
        ko = ko || GameRules.emptyKoLoc()
        node.blackCaptures = blackCap
        node.whiteCaptures = whiteCap
        node.koLocKey = ko.key
        node.koLocX = ko.x
        node.koLocY = ko.y
        node.koLocKey2 = ko.key2
        node.koLocX2 = ko.x2
        node.koLocY2 = ko.y2
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
            var action = {
                "x": node.x,
                "y": node.y,
                "key": keyFor(node.x, node.y),
                "player": node.player,
                "moveNumber": node.moveNumber,
                "nodeId": node.id,
                "isPass": node.isPass === true,
                "moveRole": node.moveRole || ""
            }
            if (!node.isPass)
                node.gomokuForbidden = pointIsGomokuForbidden(node.x, node.y, node.player, map)
            var result = GameRules.applyMoveOnMap(map, boardDims(), action, {
                "ruleMode": gameRuleMode,
                "activeKoLoc": ko,
                "pendingSource": pendingSource,
                "mutate": true
            })
            if (!result.ok) {
                return {
                    "ok": false,
                    "reason": result.reason,
                    "nodeId": node.id,
                    "moveNumber": node.moveNumber,
                    "x": node.x,
                    "y": node.y
                }
            }
            map = result.nextMap
            ko = result.ko
            pendingSource = result.nextSource
            if (result.role === "source" || result.role === "target")
                node.moveRole = result.role
            node.extraTurn = result.extraTurn === true
            node.capturedStones = (result.capturedStones || [])
                    .concat(result.selfCapturedStones || [])
            if (node.player === 1) {
                blackCap += result.captured || 0
                whiteCap += result.selfCaptured || 0
            } else if (node.player === 2) {
                whiteCap += result.captured || 0
                blackCap += result.selfCaptured || 0
            }
            updateNodePositionMetadata(node, blackCap, whiteCap, ko)
        }

        stones = map
        stoneItems = mapStoneItems(map)
        stoneCount = stoneItems.length
        blackCaptures = blackCap
        whiteCaptures = whiteCap
        koLocKey = ko.key
        koLocX = ko.x
        koLocY = ko.y
        koLocKey2 = ko.key2
        koLocX2 = ko.x2
        koLocY2 = ko.y2
        currentPlayer = nextPlayerFromMode()
        rebuildPointLegality()
        refreshWinVisuals(map)
        refreshGameOutcomeFromCurrentNode(false)
        boardRevision += 1
        showCachedAnalysisForCurrentNode()
        return { "ok": true }
    }

    function resetGameTree() {
        stopAnalysisLimitTimer()
        invalidateEngineSyncState()
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
        koLocKey2 = ""
        koLocX2 = -1
        koLocY2 = -1
        gameWinner = 0
        gameOverReason = ""
        aiAnalysisBlackResignCount = 0
        aiAnalysisWhiteResignCount = 0
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
        scheduleAutoAnalysis()
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
            "extraTurn": false,
            "capturedStones": capturedStones || [],
            "blackCaptures": blackCaptures,
            "whiteCaptures": whiteCaptures,
            "koLocKey": koLoc ? koLoc.key : "",
            "koLocX": koLoc ? koLoc.x : -1,
            "koLocY": koLoc ? koLoc.y : -1,
            "koLocKey2": koLoc ? koLoc.key2 : "",
            "koLocX2": koLoc ? koLoc.x2 : -1,
            "koLocY2": koLoc ? koLoc.y2 : -1,
            "analysisBlackWinrate": -1,
            "analysisCandidates": [],
            "analysisCandidateBoardSignature": "",
            "analysisCandidateKomiSignature": "",
            "analysisOwnership": [],
            "analysisOwnershipBoardSignature": "",
            "analysisOwnershipKomiSignature": "",
            "analysisOwnershipEngineSignature": ""
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
            if (!applyingGeneratedMove)
                requestAiMoveIfNeeded()
        }
        return node
    }

    function placeStone(x, y) {
        if (!pointInRuleBoard(x, y))
            return false

        if (ruleUsesMoveSource())
            return placeMoveRulePoint(x, y)

        var pointKey = keyFor(x, y)
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
        var result = GameRules.applyMoveOnMap(stones, boardDims(), item, {
            "ruleMode": gameRuleMode,
            "activeKoLoc": currentKoLoc()
        })
        if (!result.ok) {
            statusMode = stoneAt(x, y) !== 0 ? "occupied" : "message"
            statusMessage = illegalPointMessage(x, y, result.reason)
            return false
        }
        var captured = (result.capturedStones || []).concat(result.selfCapturedStones || [])

        selectedPointLocked = false
        selectedPointFromCandidateList = false
        var node = addMoveNode(player, x, y, false, captured, result.ko, true, true)
        if (!node)
            return false
        node.extraTurn = result.extraTurn === true
        node.gomokuForbidden = forbiddenMove
        applyIncrementalMovePosition(node, result.nextMap, result.captured,
                                     result.ko, result.selfCaptured)
        statusMode = "turn"
        statusMessage = captured.length > 0 ? trText("captureMessage") + ": " + captured.length : ""
        checkGameOverAfterMove(node)
        scheduleAutoAnalysis()
        if (!applyingGeneratedMove)
            requestAiMoveIfNeeded()
        return true
    }

    function placeMoveRulePoint(x, y) {
        var player = currentPlayer
        var sourceNode = currentMoveSourceNode()
        var sourcePoint = sourceNode ? { "x": sourceNode.x, "y": sourceNode.y } : null
        var pointKey = keyFor(x, y)
        var item = {
            "x": x,
            "y": y,
            "key": pointKey,
            "player": player,
            "moveNumber": currentMoveNumberValue() + 1,
            "nodeId": -1
        }
        var result = GameRules.applyMoveOnMap(stones, boardDims(), item, {
            "ruleMode": gameRuleMode,
            "pendingSource": sourcePoint
        })
        if (!result.ok) {
            statusMode = "message"
            statusMessage = illegalPointMessage(x, y, result.reason)
            return false
        }

        selectedPointLocked = false
        selectedPointFromCandidateList = false

        if (result.role === "source") {
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

        var node = addMoveNode(player, x, y, false, result.capturedStones || [],
                               result.ko, true, true, "target")
        if (!node)
            return false
        applyIncrementalMovePosition(node, result.nextMap, result.captured,
                                     result.ko, result.selfCaptured)
        statusMode = "turn"
        statusMessage = ""
        checkGameOverAfterMove(node)
        scheduleAutoAnalysis()
        if (!applyingGeneratedMove)
            requestAiMoveIfNeeded()
        return true
    }

    function applyIncrementalMovePosition(node, nextMap, capturedCount, ko, selfCapturedCount) {
        if (!node || !nextMap)
            return

        if (!node.isPass && nextMap[node.key]) {
            nextMap[node.key].nodeId = node.id
            nextMap[node.key].moveNumber = node.moveNumber
        }

        stones = nextMap
        stoneItems = mapStoneItems(nextMap)
        stoneCount = stoneItems.length
        capturedCount = Math.max(0, Math.round(Number(capturedCount || 0)))
        selfCapturedCount = Math.max(0, Math.round(Number(selfCapturedCount || 0)))
        if (node.player === 1) {
            blackCaptures += capturedCount
            whiteCaptures += selfCapturedCount
        } else if (node.player === 2) {
            whiteCaptures += capturedCount
            blackCaptures += selfCapturedCount
        }
        ko = ko || GameRules.emptyKoLoc()
        koLocKey = ko.key
        koLocX = ko.x
        koLocY = ko.y
        koLocKey2 = ko.key2
        koLocX2 = ko.x2
        koLocY2 = ko.y2
        node.blackCaptures = blackCaptures
        node.whiteCaptures = whiteCaptures
        node.koLocKey = koLocKey
        node.koLocX = koLocX
        node.koLocY = koLocY
        node.koLocKey2 = koLocKey2
        node.koLocX2 = koLocX2
        node.koLocY2 = koLocY2
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
        } else if (gameRuleMode === gameRuleDotsAndBoxes && dotsAndBoxesBoardFull()) {
            var blackBoxes = dotsAndBoxesClaimedCount(1)
            var whiteScore = dotsAndBoxesClaimedCount(2) + effectiveKomi()
            nextWinner = blackBoxes > whiteScore ? 1 : whiteScore > blackBoxes ? 2 : 0
            nextReason = trText("gameOverDotsAndBoxes") + ": " + blackBoxes + " - " + whiteScore
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
        var previousNodeId = currentNodeId
        currentNodeId = id
        selectedPointLocked = false
        selectedPointFromCandidateList = false
        var replay = rebuildPositionFromNode(id)
        if (!replay.ok) {
            currentNodeId = previousNodeId
            rebuildPositionFromNode(previousNodeId)
            statusMode = "message"
            statusMessage = trText("invalidGameRecordNode") + " #"
                            + replay.nodeId + ": " + replay.reason
            return false
        }
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
        if (id === currentNodeId)
            return true
        return gotoNode(id)
    }

    function validateParsedGame(parsed) {
        var mode = parsed.ruleMode === undefined || parsed.ruleMode === null
                   ? gameRuleMode : Number(parsed.ruleMode)
        return GameRules.validateGameTree(parsed.nodes, {
                                              "x": parsed.boardSizeX,
                                              "y": parsed.boardSizeY
                                          }, mode)
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

    function currentRuleSelectionText() {
        if (language === "zh")
            return "\u5f53\u524d\uff1a" + gameRuleText()
        return "Current: " + gameRuleText()
    }

    function gameRuleTextForMode(mode) {
        return RuleSupport.gameRuleTextForMode(root, mode)
    }

    function gameRuleTipForMode(mode) {
        return RuleSupport.ruleModeTipForMode(root, mode)
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

    function allRuleGroupsCollapsed() {
        return RuleSupport.allRuleGroupsCollapsed(root)
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

    function logicalBoardDimensionForRule(mode, internalSize) {
        return RuleSupport.logicalBoardDimensionForRule(root, mode, internalSize)
    }

    function internalBoardDimensionForRule(mode, logicalSize) {
        return RuleSupport.internalBoardDimensionForRule(root, mode, logicalSize)
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

    function activateRuleModeForSgf(mode) {
        return RuleSupport.activateRuleMode(root, mode)
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
        next.unshift(EnginePresets.normalizePreset(root, preset || EnginePresets.newPreset(root), next.length))
        setEnginePresetList(next)
        return 0
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
        var presetInternalX = internalBoardDimensionForRule(preset.ruleMode, preset.boardSizeX)
        var presetInternalY = internalBoardDimensionForRule(preset.ruleMode, preset.boardSizeY)
        var adjusted = RuleSupport.adjustedBoardDimensionsForRule(root, preset.ruleMode,
                                                                  presetInternalX, presetInternalY)
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
        engineInitialCommandsPendingForId = ""
        engineInitialCommandsCompletionTimer.stop()
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
        if (applicationShutdownPrepared || enginePresetStartupPromptShown
                || engineStartupMode === engineStartupNone)
            return
        if (engineStartupMode === engineStartupDefault && defaultEngineId.length > 0 && enginePresetById(defaultEngineId))
            return
        if (engineStartupMode === engineStartupLast && activeEngineId.length > 0 && enginePresetById(activeEngineId))
            return
        enginePresetStartupPromptShown = true
        engineListDialog.openStartup()
    }

    function runStartupEnginePolicy() {
        if (applicationShutdownPrepared)
            return
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
        if (engineInitialCommandsSentForId === activeEngineId
                || engineInitialCommandsPendingForId === activeEngineId)
            return
        var commands = activeEngineInitialCommands()
        if (commands.length === 0) {
            engineInitialCommandsSentForId = activeEngineId
            engineInitialCommandsPendingForId = ""
            return
        }
        engineInitialCommandsPendingForId = activeEngineId
        for (var i = 0; i < commands.length; ++i)
            engineController.sendCommand(commands[i])
        engineInitialCommandsCompletionTimer.start()
    }

    function finishActiveEngineInitialCommandsIfIdle() {
        if (engineInitialCommandsPendingForId.length === 0) {
            engineInitialCommandsCompletionTimer.stop()
            return
        }
        if (!engineController || !engineController.running || !engineController.ready
                || engineController.failed || !engineController.canUseIncrementalSync())
            return

        var completedEngineId = engineInitialCommandsPendingForId
        engineInitialCommandsPendingForId = ""
        engineInitialCommandsCompletionTimer.stop()
        if (completedEngineId !== activeEngineId)
            return
        engineInitialCommandsSentForId = completedEngineId
        scheduleAutoAnalysis()
        requestAiMoveIfNeeded()
    }

    function engineRuleCommands() {
        if (gameRuleMode === gameRuleGo)
            return [ "kata-set-rules " + JSON.stringify(RuleSupport.goRulesObject(root)) ]
        if (gameRuleMode === gameRuleTorusGo)
            return [ "kata-set-rules " + JSON.stringify(RuleSupport.torusGoRulesObject(root)) ]
        if (gameRuleMode === gameRuleTwoLibGo)
            return [ "kata-set-rules " + JSON.stringify(RuleSupport.twoLibGoRulesObject(root)) ]
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
                       : gameRuleMode === gameRuleTwoLibGo ? JSON.stringify(RuleSupport.twoLibGoRulesObject(root))
                       : gameRuleMode === gameRuleHex ? "hex" : "go"
        return [boardSizeX, boardSizeY, gameRuleMode, ruleDetail,
                legacyHexEngineCoordinateMode() ? "legacyHex" : "normal"].join(":")
    }

    function engineAnalysisSourceSignature() {
        var command = engineController ? String(engineController.command) : ""
        return [String(activeEngineId), command].join("\n")
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

    function stageEngineSyncSnapshot(syncRequestId, pathIds, boardSignature, komiSignature) {
        pendingEngineSyncSnapshot = {
            "requestId": syncRequestId,
            "nodeIds": pathIds.slice(),
            "boardSignature": boardSignature,
            "komiSignature": komiSignature
        }
    }

    function commitEngineSyncSnapshot(syncRequestId) {
        var snapshot = pendingEngineSyncSnapshot
        if (!snapshot || snapshot.requestId !== syncRequestId)
            return false

        engineSyncedNodeIds = snapshot.nodeIds.slice()
        engineSyncedBoardSignature = snapshot.boardSignature
        engineSyncedKomiSignature = snapshot.komiSignature
        engineNeedsFullSync = false
        pendingEngineSyncSnapshot = null
        return true
    }

    function engineSyncCommands(syncRequestId) {
        var path = nodePath(currentNodeId)
        var pathIds = []
        for (var pathIndex = 0; pathIndex < path.length; ++pathIndex)
            pathIds.push(path[pathIndex].id)
        var boardSignature = engineBoardSignature()
        var komiSignature = engineKomiSignature()
        var controllerAllowsIncremental = !!engineController
                                           && engineController.canUseIncrementalSync()
        var forceFullSync = engineNeedsFullSync
                            || pendingEngineSyncSnapshot !== null
                            || engineSyncedBoardSignature !== boardSignature
                            || !controllerAllowsIncremental
        var plan = EngineSync.buildPlan(engineSyncedNodeIds, pathIds, forceFullSync)
        var commands = [ "stop" ]

        if (plan.full) {
            commands = commands.concat(engineBoardSizeCommands())
            commands = commands.concat(engineAnalysisParameterCommands())
            var fullRuleCommands = engineRuleCommands()
            for (var ruleCommandIndex = 0; ruleCommandIndex < fullRuleCommands.length; ++ruleCommandIndex)
                commands.push(fullRuleCommands[ruleCommandIndex])
            commands.push("clear_board")
            for (var fullIndex = 0; fullIndex < path.length; ++fullIndex)
                commands.push(enginePlayCommandForNode(path[fullIndex]))
            stageEngineSyncSnapshot(syncRequestId, pathIds, boardSignature, komiSignature)
            return commands
        }

        if (engineSyncedKomiSignature !== komiSignature)
            commands = commands.concat(engineAnalysisParameterCommands())

        for (var undoIndex = 0; undoIndex < plan.undoCount; ++undoIndex)
            commands.push("undo")
        for (var playIndex = plan.playStartIndex; playIndex < path.length; ++playIndex)
            commands.push(enginePlayCommandForNode(path[playIndex]))

        stageEngineSyncSnapshot(syncRequestId, pathIds, boardSignature, komiSignature)
        return commands
    }

    function analyzeCommand() {
        var interval = Math.max(1, Math.round(Number(analysisIntervalCentiseconds)))
        var player = currentPlayer === 1 ? "B" : "W"
        var command = "kata-analyze " + player + " " + interval
        if (gameRuleMode === gameRuleGo && ownershipEnabled)
            command += " ownership true"
        return command
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

    function invalidateEngineSyncState() {
        engineSyncedNodeIds = []
        engineSyncedBoardSignature = ""
        engineSyncedKomiSignature = ""
        engineNeedsFullSync = true
        pendingEngineSyncSnapshot = null
        engineAnalysisRequestValid = false
        engineAnalysisSyncRequestId = 0
    }

    function invalidateEngineSyncRequest(syncRequestId) {
        engineSyncedNodeIds = []
        engineSyncedBoardSignature = ""
        engineSyncedKomiSignature = ""
        engineNeedsFullSync = true
        var snapshot = pendingEngineSyncSnapshot
        if (snapshot && snapshot.requestId === syncRequestId)
            pendingEngineSyncSnapshot = null
        if (engineAnalysisSyncRequestId === syncRequestId) {
            engineAnalysisRequestValid = false
            engineAnalysisSyncRequestId = 0
        }
    }

    function resetEngineSyncState() {
        stopAnalysisLimitTimer()
        invalidateEngineSyncState()
        handleAiAnalysisPositionChanged()
    }

    function markGeneratedMoveSynced() {
        if (engineNeedsFullSync
                || engineSyncedBoardSignature !== engineBoardSignature()
                || engineSyncedKomiSignature !== engineKomiSignature()) {
            invalidateEngineSyncState()
            return false
        }

        var path = nodePath(currentNodeId)
        var pathIds = []
        for (var pathIndex = 0; pathIndex < path.length; ++pathIndex)
            pathIds.push(path[pathIndex].id)
        if (pathIds.length !== engineSyncedNodeIds.length + 1) {
            invalidateEngineSyncState()
            return false
        }
        for (var prefixIndex = 0; prefixIndex < engineSyncedNodeIds.length; ++prefixIndex) {
            if (pathIds[prefixIndex] !== engineSyncedNodeIds[prefixIndex]) {
                invalidateEngineSyncState()
                return false
            }
        }

        engineSyncedNodeIds = pathIds
        return true
    }

    function requestEngineAnalysis(force) {
        if (applicationShutdownPrepared || !analysisModeActive()
                || enginePaused || engineDisabled || !engineAutoAnalyze
                || !engineController)
            return
        if (!engineController.ready) {
            engineLoading = true
            return
        }
        if (engineInitialCommandsPendingForId.length > 0) {
            engineInitialCommandsCompletionTimer.start()
            return
        }
        engineLoading = !engineController.ready
        engineNoticeDismissed = false
        engineAnalysisRequestNodeId = currentNodeId
        engineAnalysisRequestGeneration = gameTreeGeneration
        engineAnalysisRequestBoardSignature = engineBoardSignature()
        engineAnalysisRequestKomiSignature = engineKomiSignature()
        engineAnalysisRequestPlayer = currentPlayer
        engineAnalysisRequestEngineSignature = engineAnalysisSourceSignature()
        var syncRequestId = ++engineSyncRequestSerial
        engineAnalysisSyncRequestId = syncRequestId
        engineAnalysisRequestValid = true
        engineController.requestAnalysis(engineSyncCommands(syncRequestId),
                                         analyzeCommand(),
                                         syncRequestId)
        statusMode = "message"
        statusMessage = trText("engineAnalyzeRequested")
        resetAnalysisLimitTimer()
    }

    function requestEngineSynchronization() {
        if (applicationShutdownPrepared || !analysisModeActive()
                || !enginePaused || engineDisabled || !engineAutoAnalyze
                || !engineController)
            return
        if (!engineController.ready) {
            engineLoading = true
            return
        }
        if (engineInitialCommandsPendingForId.length > 0) {
            engineInitialCommandsCompletionTimer.start()
            return
        }
        engineLoading = false
        engineAnalysisRequestValid = false
        engineAnalysisSyncRequestId = 0
        var syncRequestId = ++engineSyncRequestSerial
        engineController.requestSynchronization(engineSyncCommands(syncRequestId),
                                                syncRequestId)
    }

    function requestScheduledEngineUpdate() {
        if (enginePaused)
            requestEngineSynchronization()
        else
            requestEngineAnalysis(false)
    }

    function scheduleAutoAnalysis() {
        if (applicationShutdownPrepared || !appReady || !analysisModeActive()
                || engineDisabled || !engineAutoAnalyze)
            return
        autoAnalyzeTimer.interval = enginePaused ? 1 : 280
        autoAnalyzeTimer.restart()
    }

    function startEngine() {
        if (applicationShutdownPrepared || !engineController)
            return
        resetEngineSearchSpeed()
        engineDisabled = false
        engineLoading = true
        engineNoticeDismissed = false
        engineFailureNoticeText = ""
        if (!engineController.running) {
            engineInitialCommandsSentForId = ""
            engineInitialCommandsPendingForId = ""
            engineInitialCommandsCompletionTimer.stop()
        }
        engineController.ensureStarted()
    }

    function stopEngine() {
        if (!engineController)
            return
        cancelActiveEnginePlayRequest(true)
        engineDisabled = true
        engineController.stop()
        engineInitialCommandsSentForId = ""
        engineInitialCommandsPendingForId = ""
        engineInitialCommandsCompletionTimer.stop()
        engineLoading = false
        engineFailureNoticeText = ""
        stopAnalysisLimitTimer()
        clearEngineCandidates()
        showCachedAnalysisForCurrentNode()
    }

    function restartEngine() {
        if (applicationShutdownPrepared || !engineController)
            return
        cancelActiveEnginePlayRequest(true)
        resetEngineSearchSpeed()
        engineDisabled = false
        engineLoading = true
        engineNoticeDismissed = false
        engineFailureNoticeText = ""
        engineInitialCommandsSentForId = ""
        engineInitialCommandsPendingForId = ""
        engineInitialCommandsCompletionTimer.stop()
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
        resetEngineSearchSpeed()
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
        var modeChanged = playMode !== mode
        var leavingOrdinaryAnalysis = modeChanged
                                      && playMode === playModeAnalysis
                                      && mode !== playModeAnalysis
        var hadPlayRequest = genmoveInFlight || activeGenmoveRequestId > 0
                             || aiAnalysisInFlight || activeAiAnalysisRequestId > 0
        if (modeChanged && hadPlayRequest) {
            cancelActiveEnginePlayRequest(true)
            if (engineController)
                engineController.sendCommand("stop")
        }
        if (leavingOrdinaryAnalysis) {
            engineAnalysisRequestValid = false
            engineAnalysisSyncRequestId = 0
            resetEngineCandidateDisplay()
            resetEngineOwnershipDisplay()
            if (engineController)
                engineController.clearCandidates()
        }
        if (modeChanged) {
            aiAnalysisBlackResignCount = 0
            aiAnalysisWhiteResignCount = 0
        }
        playMode = mode
        if (analysisModeActive()) {
            refreshGameOutcomeFromCurrentNode(false)
            scheduleAutoAnalysis()
        } else {
            enginePaused = false
            refreshGameOutcomeFromCurrentNode(false)
            if (leavingOrdinaryAnalysis && !aiShouldMove() && engineController)
                engineController.sendCommand("stop")
            requestAiMoveIfNeeded()
        }
    }

    function setAiMoveMode(mode) {
        var nextMode = Number(mode)
        if (nextMode !== aiMoveModeGtp && nextMode !== aiMoveModeAnalyze)
            return
        if (aiMoveMode === nextMode)
            return

        var playing = !analysisModeActive()
        if (playing) {
            cancelActiveEnginePlayRequest(true)
            if (engineController)
                engineController.sendCommand("stop")
        }
        aiMoveMode = nextMode
        aiAnalysisBlackResignCount = 0
        aiAnalysisWhiteResignCount = 0
        if (playing)
            Qt.callLater(function() { root.requestAiMoveIfNeeded() })
    }

    function aiMoveModeOptions() {
        return [
            { "label": trText("aiMoveModeGtp"), "value": aiMoveModeGtp },
            { "label": trText("aiMoveModeAnalyze"), "value": aiMoveModeAnalyze }
        ]
    }

    function currentAiMoveSecondsPerMove() {
        return aiMoveMode === aiMoveModeAnalyze ? analysisSecondsPerMove
                                                : secondsPerMove
    }

    function setCurrentAiMoveSecondsPerMove(value) {
        var seconds = Number(value)
        if (!isFinite(seconds))
            return
        if (aiMoveMode === aiMoveModeAnalyze)
            analysisSecondsPerMove = clamp(seconds, 0, 999)
        else
            secondsPerMove = clamp(seconds, 0.1, 999)
    }

    function analysisMoveLimitConfigured() {
        return Number(analysisSecondsPerMove) > 0
                || Number(analysisTotalVisitsPerMove) > 0
                || Number(analysisFirstMoveVisitsPerMove) > 0
    }

    function handleAiAnalysisLimitsChanged(restartTimeLimit) {
        if (!appReady || aiMoveMode !== aiMoveModeAnalyze)
            return

        var action = EnginePlay.limitChangeAction(analysisMoveLimitConfigured(),
                                                  aiAnalysisInFlight,
                                                  aiShouldMove())
        if (action === "cancel") {
            cancelActiveAiAnalysisRequest(true)
            if (engineController)
                engineController.sendCommand("stop")
        }
        if (action === "cancel" || action === "wait") {
            if (aiShouldMove()) {
                statusMode = "message"
                statusMessage = trText("analysisMoveLimitRequired")
            }
            return
        }

        if (action === "evaluate") {
            if (restartTimeLimit)
                restartAiAnalysisTimeLimit()
            tryFinishAiAnalysisMove()
            return
        }
        if (action === "start")
            Qt.callLater(function() { root.requestAiMoveIfNeeded() })
    }

    function analysisModeActive() {
        return playMode === playModeAnalysis
    }

    function analysisPresentationVisible() {
        return analysisModeActive()
                || (!hideAnalysisDuringPlay
                    && aiMoveMode === aiMoveModeAnalyze)
    }

    function engineReadyForPlayMode() {
        return !!engineController
               && !engineDisabled
               && engineController.running
               && engineController.ready
               && !engineController.failed
               && !engineLoading
               && engineInitialCommandsPendingForId.length === 0
               && (activeEngineId.length === 0
                   || engineInitialCommandsSentForId === activeEngineId)
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
        if (!aiShouldMove() || genmoveInFlight || aiAnalysisInFlight
                || engineDisabled || !engineController)
            return
        if (!engineReadyForPlayMode()) {
            startEngine()
            return
        }
        if (aiMoveMode === aiMoveModeAnalyze) {
            requestAiAnalysisMove()
            return
        }

        engineAnalysisRequestValid = false
        engineAnalysisSyncRequestId = 0
        genmoveInFlight = true
        genmovePlayer = currentPlayer
        activeGenmoveRequestId = ++genmoveRequestSerial
        activeGenmoveSyncRequestId = ++engineSyncRequestSerial
        activeGenmovePosition = {
            "requestId": activeGenmoveRequestId,
            "nodeId": currentNodeId,
            "generation": gameTreeGeneration,
            "boardSignature": engineBoardSignature(),
            "komiSignature": engineKomiSignature(),
            "player": currentPlayer
        }
        engineController.requestMove(engineSyncCommands(activeGenmoveSyncRequestId),
                                     timeSettingsCommand(),
                                     genmoveCommand(),
                                     activeGenmoveRequestId,
                                     activeGenmoveSyncRequestId)
        statusMode = "message"
        statusMessage = trText("engineThinking")
    }

    function requestAiAnalysisMove() {
        if (!aiShouldMove() || aiMoveMode !== aiMoveModeAnalyze
                || genmoveInFlight || aiAnalysisInFlight
                || !engineReadyForPlayMode())
            return
        if (!analysisMoveLimitConfigured()) {
            statusMode = "message"
            statusMessage = trText("analysisMoveLimitRequired")
            return
        }

        aiAnalysisInFlight = true
        activeAiAnalysisRequestId = ++aiAnalysisRequestSerial
        activeAiAnalysisSyncRequestId = ++engineSyncRequestSerial
        activeAiAnalysisPosition = {
            "requestId": activeAiAnalysisRequestId,
            "nodeId": currentNodeId,
            "generation": gameTreeGeneration,
            "boardSignature": engineBoardSignature(),
            "komiSignature": engineKomiSignature(),
            "player": currentPlayer,
            "engineSignature": engineAnalysisSourceSignature()
        }
        engineAnalysisRequestNodeId = currentNodeId
        engineAnalysisRequestGeneration = gameTreeGeneration
        engineAnalysisRequestBoardSignature = engineBoardSignature()
        engineAnalysisRequestKomiSignature = engineKomiSignature()
        engineAnalysisRequestPlayer = currentPlayer
        engineAnalysisRequestEngineSignature = engineAnalysisSourceSignature()
        engineAnalysisSyncRequestId = activeAiAnalysisSyncRequestId
        engineAnalysisRequestValid = true
        aiAnalysisStartedAt = Date.now()
        restartAiAnalysisTimeLimit()
        restartAiAnalysisWatchdog()
        engineController.requestAnalysis(engineSyncCommands(activeAiAnalysisSyncRequestId),
                                         analyzeCommand(),
                                         activeAiAnalysisSyncRequestId)
        statusMode = "message"
        statusMessage = trText("engineThinking")
    }

    function restartAiAnalysisTimeLimit() {
        if (!aiAnalysisInFlight) {
            aiAnalysisMoveTimer.stop()
            return
        }
        var seconds = Math.max(0, Number(analysisSecondsPerMove))
        if (!isFinite(seconds))
            seconds = 5.0
        aiAnalysisStartedAt = Date.now()
        if (seconds <= 0) {
            aiAnalysisMoveTimer.stop()
            return
        }
        aiAnalysisMoveTimer.interval = Math.max(100, Math.round(seconds * 1000))
        aiAnalysisMoveTimer.restart()
    }

    function restartAiAnalysisWatchdog() {
        if (!aiAnalysisInFlight) {
            aiAnalysisWatchdogTimer.stop()
            return
        }
        aiAnalysisWatchdogTimer.interval = aiAnalysisWatchdogMilliseconds
        aiAnalysisWatchdogTimer.restart()
    }

    function handleAiAnalysisWatchdogTimeout() {
        if (!aiAnalysisInFlight)
            return
        pauseAfterEngineProtocolFailure("analysisNoResponse", "", true)
        statusMode = "message"
        statusMessage = trText("analysisNoResponse")
    }

    function activeAiAnalysisPositionMatches() {
        return EnginePlay.positionMatches(activeAiAnalysisPosition,
                                          currentNodeId,
                                          gameTreeGeneration,
                                          engineBoardSignature(),
                                          engineKomiSignature(),
                                          currentPlayer,
                                          engineAnalysisSourceSignature())
    }

    function pauseAfterEngineProtocolFailure(messageKey, detail, sendStop) {
        cancelActiveEnginePlayRequest(true)
        playMode = playModeAnalysis
        enginePaused = true
        refreshGameOutcomeFromCurrentNode(false)
        resetEngineCandidateDisplay()
        resetEngineOwnershipDisplay()
        if (engineController) {
            engineController.clearCandidates()
            if (sendStop)
                engineController.sendCommand("stop")
        }
        if (!ignoreGtpErrors) {
            statusMode = "message"
            statusMessage = trText(messageKey)
            if (detail && String(detail).length > 0)
                statusMessage += ": " + String(detail)
        }
    }

    function deferAnalysisCommandFailure(analysisRequestId, line) {
        if (analysisRequestId <= 0
                || analysisRequestId !== engineAnalysisSyncRequestId)
            return
        Qt.callLater(function() {
            if (root.engineAnalysisSyncRequestId !== analysisRequestId
                    || !root.engineAnalysisRequestValid)
                return
            root.pauseAfterEngineProtocolFailure("analysisMoveFailed", line, false)
        })
    }

    function handleAiAnalysisPositionChanged() {
        if (!aiAnalysisInFlight || applyingGeneratedMove
                || activeAiAnalysisPositionMatches())
            return
        cancelActiveAiAnalysisRequest(true)
        if (engineController)
            engineController.sendCommand("stop")
        if (appReady)
            Qt.callLater(function() { root.requestAiMoveIfNeeded() })
    }

    function aiAnalysisResignCount(player) {
        return player === 1 ? aiAnalysisBlackResignCount
                            : aiAnalysisWhiteResignCount
    }

    function setAiAnalysisResignCount(player, count) {
        if (player === 1)
            aiAnalysisBlackResignCount = count
        else if (player === 2)
            aiAnalysisWhiteResignCount = count
    }

    function aiAnalysisShouldResign(player, candidate) {
        var node = currentNode()
        var moveNumber = node ? Number(node.moveNumber) : 0
        var rawWinrate = candidate && candidate.winrate !== undefined
                       ? Number(candidate.winrate) : NaN
        if (!isFinite(rawWinrate)) {
            setAiAnalysisResignCount(player, 0)
            return false
        }
        var winrate = clamp(rawWinrate * 100, 0, 100)
        var nextCount = EnginePlay.nextResignCount(aiAnalysisResignCount(player),
                                                   moveNumber,
                                                   winrate,
                                                   resignMinMove,
                                                   resignWinrateThreshold)
        setAiAnalysisResignCount(player, nextCount)
        return nextCount >= Math.max(1, Math.round(Number(resignConsecutiveMoves)))
    }

    function tryFinishAiAnalysisMove() {
        if (!aiAnalysisInFlight || aiMoveMode !== aiMoveModeAnalyze
                || !aiShouldMove() || !engineController)
            return false
        if (!activeAiAnalysisPositionMatches()) {
            handleAiAnalysisPositionChanged()
            return false
        }

        var candidates = CandidateAnalysis.cloneCandidateList(engineController.candidates)
        var elapsed = Math.max(0, Date.now() - aiAnalysisStartedAt)
        if (!EnginePlay.limitReached(candidates,
                                     elapsed,
                                     analysisSecondsPerMove,
                                     analysisTotalVisitsPerMove,
                                     analysisFirstMoveVisitsPerMove))
            return false

        var best = EnginePlay.bestCandidate(candidates)
        if (!best)
            return false
        var move = String(best.move).trim()
        var player = activeAiAnalysisPosition.player
        var shouldResign = aiAnalysisShouldResign(player, best)

        cancelActiveAiAnalysisRequest(false)
        if (shouldResign || move.toLowerCase() === "resign") {
            finishEngineResignation(player)
            return true
        }

        if (!applyGeneratedMove(move)) {
            engineController.sendCommand("stop")
            invalidateEngineSyncState()
            statusMode = "message"
            statusMessage = trText("engineMoveInvalid") + ": " + move
            return false
        }

        if (aiShouldMove())
            Qt.callLater(function() { root.requestAiMoveIfNeeded() })
        else
            engineController.sendCommand("stop")
        return true
    }

    function stopAiPlay() {
        cancelActiveEnginePlayRequest(true)
        playMode = playModeAnalysis
        if (engineController)
            engineController.sendCommand("stop")
        statusMode = "message"
        statusMessage = trText("gameStopped")
        scheduleAutoAnalysis()
    }

    function cancelActiveEnginePlayRequest(invalidateSync) {
        cancelActiveGenmoveRequest()
        cancelActiveAiAnalysisRequest(invalidateSync)
    }

    function cancelActiveGenmoveRequest() {
        if (activeGenmoveSyncRequestId > 0)
            invalidateEngineSyncRequest(activeGenmoveSyncRequestId)
        genmoveInFlight = false
        activeGenmoveRequestId = 0
        activeGenmoveSyncRequestId = 0
        activeGenmovePosition = null
        genmovePlayer = 0
    }

    function cancelActiveAiAnalysisRequest(invalidateSync) {
        aiAnalysisMoveTimer.stop()
        aiAnalysisWatchdogTimer.stop()
        if (invalidateSync !== false && activeAiAnalysisSyncRequestId > 0)
            invalidateEngineSyncRequest(activeAiAnalysisSyncRequestId)
        engineAnalysisRequestValid = false
        engineAnalysisSyncRequestId = 0
        aiAnalysisInFlight = false
        activeAiAnalysisRequestId = 0
        activeAiAnalysisSyncRequestId = 0
        activeAiAnalysisPosition = null
        aiAnalysisStartedAt = 0
    }

    function finishEngineResignation(losingPlayer) {
        cancelActiveEnginePlayRequest(false)
        if (engineController)
            engineController.sendCommand("stop")
        gameWinner = losingPlayer === 1 ? 2 : 1
        gameOverReason = trText("engineSuggestsResign")
        statusMode = "message"
        statusMessage = gameOverReason
        gameOverDialog.open()
    }

    function applyGeneratedMove(moveText) {
        var text = String(moveText).trim()
        var previousNodeId = currentNodeId
        var applied = false
        applyingGeneratedMove = true
        if (text.toLowerCase() === "pass" || text.length === 0) {
            passMove()
            applied = currentNodeId !== previousNodeId
        } else {
            var point = parseEngineCoordinate(text)
            if (point)
                applied = placeStone(point.x, point.y)
        }
        applyingGeneratedMove = false
        return applied
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
        var candidatesShown = CandidateAnalysis.showCachedAnalysisForCurrentNode(root)
        var ownershipShown = showCachedOwnershipForCurrentNode()
        return candidatesShown || ownershipShown
    }

    function applyEngineCandidateUpdate(candidates, revision) {
        CandidateAnalysis.applyEngineCandidateUpdate(
                    root,
                    candidates,
                    revision)
    }

    function flushEngineCandidateUpdate() {
        if (!engineController)
            return
        var candidateSnapshot = engineController.candidates
        applyEngineCandidateUpdate(candidateSnapshot,
                                   engineController.candidateRevision)
        applyEngineOwnershipUpdate(engineController.ownership)
        lastEngineCandidateUiUpdateAt = Date.now()
        tryFinishAiAnalysisMove()
    }

    function scheduleEngineCandidateUpdate() {
        if (applicationShutdownPrepared || !engineController)
            return

        var candidateCount = engineController.candidateCount
        if (candidateCount <= largeCandidateUiThreshold
                || aiAnalysisInFlight) {
            largeCandidateUiUpdateTimer.stop()
            flushEngineCandidateUpdate()
            return
        }

        var elapsed = Date.now() - lastEngineCandidateUiUpdateAt
        if (lastEngineCandidateUiUpdateAt <= 0
                || elapsed >= largeCandidateUiIntervalMs) {
            largeCandidateUiUpdateTimer.stop()
            flushEngineCandidateUpdate()
            return
        }

        if (!largeCandidateUiUpdateTimer.running) {
            largeCandidateUiUpdateTimer.interval = Math.max(
                        1, largeCandidateUiIntervalMs - elapsed)
            largeCandidateUiUpdateTimer.start()
        }
    }

    function rebuildEngineCandidateItems() {
        CandidateAnalysis.rebuildItems(root)
    }

    function resetEngineOwnershipDisplay() {
        if ((!engineOwnership || engineOwnership.length <= 0)
                && !engineOwnershipFromCache
                && engineOwnershipBoardSignature.length <= 0
                && engineOwnershipKomiSignature.length <= 0
                && engineOwnershipEngineSignature.length <= 0)
            return
        engineOwnership = []
        engineOwnershipFromCache = false
        engineOwnershipBoardSignature = ""
        engineOwnershipKomiSignature = ""
        engineOwnershipEngineSignature = ""
        engineOwnershipRevision += 1
    }

    function setEngineOwnershipDisplay(values, fromCache, boardSignature,
                                       komiSignature, engineSignature) {
        var cached = fromCache === true
        var nextBoardSignature = boardSignature || engineBoardSignature()
        var nextKomiSignature = komiSignature || engineKomiSignature()
        var nextEngineSignature = engineSignature || engineAnalysisSourceSignature()
        if (engineOwnership === values
                && engineOwnershipFromCache === cached
                && engineOwnershipBoardSignature === nextBoardSignature
                && engineOwnershipKomiSignature === nextKomiSignature
                && engineOwnershipEngineSignature === nextEngineSignature)
            return
        engineOwnership = values || []
        engineOwnershipFromCache = cached
        engineOwnershipBoardSignature = nextBoardSignature
        engineOwnershipKomiSignature = nextKomiSignature
        engineOwnershipEngineSignature = nextEngineSignature
        engineOwnershipRevision += 1
    }

    function nodeOwnershipCacheUsable(node) {
        return ownershipEnabled
                && gameRuleMode === gameRuleGo
                && !!node
                && node.analysisOwnership !== undefined
                && Ownership.usable(node.analysisOwnership, boardSizeX, boardSizeY)
                && node.analysisOwnershipBoardSignature === engineBoardSignature()
                && node.analysisOwnershipKomiSignature === engineKomiSignature()
                && node.analysisOwnershipEngineSignature === engineAnalysisSourceSignature()
    }

    function showCachedOwnershipForCurrentNode() {
        var node = currentNode()
        if (!nodeOwnershipCacheUsable(node)) {
            resetEngineOwnershipDisplay()
            return false
        }
        setEngineOwnershipDisplay(node.analysisOwnership,
                                  true,
                                  node.analysisOwnershipBoardSignature,
                                  node.analysisOwnershipKomiSignature,
                                  node.analysisOwnershipEngineSignature)
        return true
    }

    function applyEngineOwnershipUpdate(values) {
        var updateActive = engineAnalysisRequestValid
                           && (analysisModeActive() || aiAnalysisInFlight)
        if (!ownershipEnabled || gameRuleMode !== gameRuleGo || !updateActive) {
            resetEngineOwnershipDisplay()
            return
        }

        var normalized = Ownership.normalized(values,
                                              boardSizeX,
                                              boardSizeY,
                                              engineAnalysisRequestPlayer)
        if (normalized.length <= 0) {
            if (!showCachedOwnershipForCurrentNode())
                resetEngineOwnershipDisplay()
            return
        }

        var targetId = engineAnalysisRequestNodeId >= 0
                     ? engineAnalysisRequestNodeId : currentNodeId
        var targetGeneration = engineAnalysisRequestGeneration >= 0
                             ? engineAnalysisRequestGeneration : gameTreeGeneration
        if (targetGeneration !== gameTreeGeneration) {
            if (!showCachedOwnershipForCurrentNode())
                resetEngineOwnershipDisplay()
            return
        }

        var targetBoardSignature = engineAnalysisRequestBoardSignature.length > 0
                                 ? engineAnalysisRequestBoardSignature
                                 : engineBoardSignature()
        var targetKomiSignature = engineAnalysisRequestKomiSignature.length > 0
                                ? engineAnalysisRequestKomiSignature
                                : engineKomiSignature()
        var targetEngineSignature = engineAnalysisRequestEngineSignature.length > 0
                                  ? engineAnalysisRequestEngineSignature
                                  : engineAnalysisSourceSignature()
        var targetNode = nodeById(targetId)
        if (targetNode) {
            targetNode.analysisOwnership = normalized
            targetNode.analysisOwnershipBoardSignature = targetBoardSignature
            targetNode.analysisOwnershipKomiSignature = targetKomiSignature
            targetNode.analysisOwnershipEngineSignature = targetEngineSignature
        }

        if (targetId !== currentNodeId
                || targetBoardSignature !== engineBoardSignature()
                || targetKomiSignature !== engineKomiSignature()
                || targetEngineSignature !== engineAnalysisSourceSignature()) {
            if (!showCachedOwnershipForCurrentNode())
                resetEngineOwnershipDisplay()
            return
        }
        setEngineOwnershipDisplay(normalized,
                                  false,
                                  targetBoardSignature,
                                  targetKomiSignature,
                                  targetEngineSignature)
    }

    function ownershipVisibleForCurrentPosition() {
        return analysisPresentationVisible()
                && ownershipEnabled
                && gameRuleMode === gameRuleGo
                && Ownership.usable(engineOwnership, boardSizeX, boardSizeY)
                && engineOwnershipBoardSignature === engineBoardSignature()
                && engineOwnershipKomiSignature === engineKomiSignature()
                && engineOwnershipEngineSignature === engineAnalysisSourceSignature()
    }

    function refreshOwnershipRequest() {
        resetEngineOwnershipDisplay()
        if (!appReady || !engineController)
            return
        if (aiAnalysisInFlight) {
            cancelActiveAiAnalysisRequest(true)
            engineController.sendCommand("stop")
            Qt.callLater(function() { root.requestAiMoveIfNeeded() })
            return
        }
        if (analysisModeActive() && engineAutoAnalyze
                && !enginePaused && !engineDisabled) {
            clearEngineCandidates()
            scheduleAutoAnalysis()
        }
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
        if (!best || best.displayIndex !== 1 || best.boardPoint !== true) {
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
        resetEngineSearchSpeed()
        resetEngineCandidateDisplay()
        resetEngineOwnershipDisplay()
        if (engineController)
            engineController.clearCandidates()
    }

    function enterNoEngineMode(message, keepEngineNotice) {
        engineDisabled = true
        engineLoading = false
        engineNoticeDismissed = keepEngineNotice === true ? false : true
        cancelActiveEnginePlayRequest(true)
        engineInitialCommandsPendingForId = ""
        engineInitialCommandsCompletionTimer.stop()
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
        resetEngineSyncState()
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
        if (candidate.boardPoint !== true) {
            clearHover(true)
            statusMode = "message"
            statusMessage = trText("engineBestMove") + ": " + candidate.displayMoveText
            focusBoardInput()
            return
        }
        setSelectedPoint(candidate.x, candidate.y, true, true)
        focusBoardInput()
    }

    function playBestEngineMove() {
        CandidateAnalysis.playBestCandidate(root, engineCandidateItems)
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

    function winrateHistoryData() {
        return AnalysisStatus.winrateHistoryData(root)
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
        handleAiAnalysisPositionChanged()
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
        if (Math.abs(previousEffectiveValue - effectiveAnalysisWideRootNoise()) >= 0.0001) {
            handleAiAnalysisPositionChanged()
            scheduleAutoAnalysis()
        }
        if (persistentSettingsLoaded)
            savePersistentSettings()
    }

    function setAnalysisWideRootNoiseEnabled(enabled) {
        var nextEnabled = !!enabled
        if (analysisWideRootNoiseEnabled === nextEnabled)
            return
        var previousEffectiveValue = effectiveAnalysisWideRootNoise()
        analysisWideRootNoiseEnabled = nextEnabled
        if (Math.abs(previousEffectiveValue - effectiveAnalysisWideRootNoise()) >= 0.0001) {
            handleAiAnalysisPositionChanged()
            scheduleAutoAnalysis()
        }
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

    function openEngineListDialog(ownerWindow) {
        engineListDialog.openManage(ownerWindow)
    }

    function openSaveSgfDialog(continuation) {
        if (continuation !== saveContinuationQuit
                && continuation !== saveContinuationPendingAction)
            continuation = saveContinuationNone
        pendingSaveContinuation = continuation
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

    function openSgfGameTypeWarning(gameId, expectedGameId, ruleName, expectedRuleName) {
        Qt.callLater(function() {
            engineRuleWarningDialog.openForSgf(gameId, expectedGameId,
                                               ruleName, expectedRuleName)
        })
    }

    function buildSgf() {
        return SgfSession.build(root)
    }

    function saveSgfToFile(url) {
        var continuation = pendingSaveContinuation
        pendingSaveContinuation = saveContinuationNone
        var ok = SgfSession.saveToFile(root, fileIo, url)
        if (!ok) {
            if (continuation === saveContinuationPendingAction
                    && pendingClearAction.length > 0) {
                Qt.callLater(function() { ruleChangeSaveDialog.open() })
            } else if (continuation === saveContinuationQuit) {
                Qt.callLater(function() { unsavedSgfDialog.open() })
            } else {
                focusBoardInput()
            }
            return false
        }
        if (continuation === saveContinuationQuit) {
            suppressUnsavedPrompt = true
            prepareApplicationShutdown()
            Qt.quit()
            return true
        }
        if (continuation === saveContinuationPendingAction) {
            applyPendingClearAction()
            return true
        }
        focusBoardInput()
        return true
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
        prepareApplicationShutdown()
        Qt.quit()
    }

    function closeAuxiliaryWindowsForShutdown() {
        engineCommunicationWindow.closeWindow()
        beginnerTutorialDialog.closeTutorialWindow()
        settingsDialog.closeWindowForShutdown()
        hiddenSettingsDialog.closeWindowForShutdown()
        engineListDialog.closeWindowForShutdown()
        helpKeysDialog.closeWindowForShutdown()
        if (saveSgfDialog.visible)
            saveSgfDialog.close()
        if (loadSgfDialog.visible)
            loadSgfDialog.close()
    }

    function stopApplicationTimersForShutdown() {
        autoAnalyzeTimer.stop()
        engineSearchSpeedTimer.stop()
        largeCandidateUiUpdateTimer.stop()
        engineInitialCommandsCompletionTimer.stop()
        analysisLimitTimer.stop()
        aiAnalysisMoveTimer.stop()
        aiAnalysisWatchdogTimer.stop()
        focusBoardInputTimer.stop()
        treeLayoutTimer.stop()
        firstLaunchTimer.stop()
        startupEngineListTimer.stop()
        startupBeginnerTutorialTimer.stop()
        gtpErrorHideTimer.stop()
        gtpErrorFadeAnimation.stop()
    }

    function prepareApplicationShutdown() {
        if (applicationShutdownPrepared)
            return
        applicationShutdownPrepared = true
        stopApplicationTimersForShutdown()
        closeAuxiliaryWindowsForShutdown()
        savePersistentSettings()
        if (appSettings)
            appSettings.sync()
    }

    function requestQuit() {
        if (gameDirty) {
            unsavedSgfDialog.open()
            return
        }
        suppressUnsavedPrompt = true
        prepareApplicationShutdown()
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
        if (EngineSupport.appendCommunication(engineCommunicationLogModel, stream, line,
                                              engineCommunicationLogLimit,
                                              engineCommunicationLogCharacterLimit,
                                               engineCommunicationLineCharacterLimit,
                                               engineCommunicationLogState)) {
            syncEngineCommunicationLogMetadata()
            if (stream === "stdin")
                engineCommunicationStdinRevision += 1
            else if (stream === "stderr")
                engineCommunicationStderrRevision += 1
            else
                engineCommunicationStdoutRevision += 1
            engineCommunicationRevision += 1
        }
    }

    function syncEngineCommunicationLogMetadata() {
        engineCommunicationLogCharacterCount = Math.max(
                    0, Number(engineCommunicationLogState.characterCount) || 0)
        engineCommunicationLogChangeMask = Math.max(
                    0, Number(engineCommunicationLogState.lastChangeMask) || 0)
        engineCommunicationStdinRetainedCount = Math.max(
                    0, Number(engineCommunicationLogState.stdinRetainedCount) || 0)
        engineCommunicationStdoutRetainedCount = Math.max(
                    0, Number(engineCommunicationLogState.stdoutRetainedCount) || 0)
        engineCommunicationStderrRetainedCount = Math.max(
                    0, Number(engineCommunicationLogState.stderrRetainedCount) || 0)
    }

    function applyEngineCommunicationLogLimits() {
        engineCommunicationLogLimit = Math.round(clamp(
                    Number(engineCommunicationLogLimit), 1,
                    maxEngineCommunicationLogLines))
        engineCommunicationLogCharacterLimit = Math.round(clamp(
                    Number(engineCommunicationLogCharacterLimit), 1024,
                    maxEngineCommunicationLogCharacters))
        engineCommunicationLineCharacterLimit = Math.round(clamp(
                    Number(engineCommunicationLineCharacterLimit), 128,
                    Math.min(maxEngineCommunicationLineCharacters,
                             Math.max(128,
                                      engineCommunicationLogCharacterLimit - 1))))
        var changed = EngineSupport.enforceCommunicationLimits(
                    engineCommunicationLogModel,
                    engineCommunicationLogLimit,
                    engineCommunicationLogCharacterLimit,
                    engineCommunicationLineCharacterLimit,
                    engineCommunicationLogState)
        syncEngineCommunicationLogMetadata()
        if (changed)
            engineCommunicationRevision += 1
    }

    function clearEngineCommunicationLog() {
        EngineSupport.clearCommunication(engineCommunicationLogModel,
                                         engineCommunicationLogState)
        syncEngineCommunicationLogMetadata()
        engineCommunicationRevision += 1
    }

    function showGtpErrorResponse(line) {
        var messages = recentGtpErrors.slice()
        messages.push(trText("gtpErrorPrefix") + String(line))
        if (messages.length > 2)
            messages = messages.slice(messages.length - 2)
        recentGtpErrors = messages

        gtpErrorFadeAnimation.stop()
        gtpErrorToast.opacity = 1
        gtpErrorHideTimer.restart()
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

        function onGtpErrorResponse(line) {
            root.showGtpErrorResponse(line)
        }

        function onAnalysisCommandFailed(analysisRequestId, line) {
            root.deferAnalysisCommandFailure(analysisRequestId, line)
        }

        function onEngineSynchronizationCompleted(syncRequestId) {
            var committed = root.commitEngineSyncSnapshot(syncRequestId)
            var aiAnalysisSync = syncRequestId === root.activeAiAnalysisSyncRequestId
            if (committed && aiAnalysisSync) {
                root.activeAiAnalysisSyncRequestId = 0
                root.restartAiAnalysisTimeLimit()
            }
        }

        function onCommandChanged() {
            root.cancelActiveEnginePlayRequest(true)
            root.resetEngineSearchSpeed()
            root.engineInitialCommandsSentForId = ""
            root.engineInitialCommandsPendingForId = ""
            engineInitialCommandsCompletionTimer.stop()
            root.resetEngineSyncState()
        }

        function onCandidatesChanged() {
            if (engineController.candidateCount <= 0)
                root.resetEngineSearchSpeed()
            else if (root.aiAnalysisInFlight && root.engineAnalysisRequestValid)
                root.restartAiAnalysisWatchdog()
            root.scheduleEngineCandidateUpdate()
        }

        function onReadyChanged() {
            if (!engineController.ready) {
                root.resetEngineSearchSpeed()
                root.cancelActiveEnginePlayRequest(true)
            }
            if (engineController.ready) {
                root.engineLoading = false
                root.sendActiveEngineInitialCommands()
                root.scheduleAutoAnalysis()
                root.requestAiMoveIfNeeded()
            }
        }

        function onFailedChanged() {
            if (engineController.failed) {
                root.cancelActiveEnginePlayRequest(true)
                root.resetEngineSearchSpeed()
                root.handleEngineLoadFailure(root.engineFailureMessage())
            }
        }

        function onRunningChanged() {
            if (!engineController.running) {
                root.cancelActiveEnginePlayRequest(true)
                root.resetEngineSearchSpeed()
            }
        }

        function onMoveGenerated(requestId, move, ok, rawLine) {
            if (requestId !== root.activeGenmoveRequestId)
                return
            var syncRequestId = root.activeGenmoveSyncRequestId
            var position = root.activeGenmovePosition
            var positionStillCurrent = !!position
                    && position.requestId === requestId
                    && position.nodeId === root.currentNodeId
                    && position.generation === root.gameTreeGeneration
                    && position.boardSignature === root.engineBoardSignature()
                    && position.komiSignature === root.engineKomiSignature()
                    && position.player === root.currentPlayer
            root.genmoveInFlight = false
            root.activeGenmoveRequestId = 0
            root.activeGenmoveSyncRequestId = 0
            root.activeGenmovePosition = null
            root.genmovePlayer = 0
            if (!ok) {
                var ignoredGtpError = root.ignoreGtpErrors
                                      && String(rawLine).trim().indexOf("?") === 0
                if (ignoredGtpError)
                    return
                root.invalidateEngineSyncRequest(syncRequestId)
                root.pauseAfterEngineProtocolFailure(
                            "engineMoveFailed",
                            rawLine,
                            false)
                return
            }
            if (!positionStillCurrent) {
                root.invalidateEngineSyncRequest(syncRequestId)
                root.requestAiMoveIfNeeded()
                return
            }
            root.commitEngineSyncSnapshot(syncRequestId)
            if (String(move).trim().toLowerCase() === "resign") {
                root.finishEngineResignation(position.player)
                return
            }
            if (!root.applyGeneratedMove(move)) {
                root.invalidateEngineSyncState()
                return
            }
            root.markGeneratedMoveSynced()
            root.requestAiMoveIfNeeded()
        }
    }

    Component.onCompleted: {
        loadPersistentSettings()
        engineController.ignoreGtpErrors = ignoreGtpErrors
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

    Rectangle {
        id: gtpErrorToast

        anchors.right: parent.right
        anchors.rightMargin: root.panelMargin
        anchors.bottom: commandToolbar.top
        anchors.bottomMargin: root.panelGap
        width: Math.min(680, Math.max(320, root.width * 0.52))
        height: gtpErrorColumn.implicitHeight + 16
        radius: 5
        color: "#d9fff4f2"
        border.color: "#b4372f"
        border.width: 1
        opacity: 0
        visible: opacity > 0
        enabled: false
        z: 1000

        Column {
            id: gtpErrorColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 3

            Repeater {
                model: root.recentGtpErrors

                delegate: Text {
                    required property string modelData

                    width: gtpErrorColumn.width
                    text: modelData
                    color: "#8f1f18"
                    font.pixelSize: root.compactLayout ? 13 : 14
                    font.bold: true
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }
    }

    Timer {
        id: gtpErrorHideTimer
        interval: 5000
        repeat: false
        onTriggered: gtpErrorFadeAnimation.start()
    }

    NumberAnimation {
        id: gtpErrorFadeAnimation
        target: gtpErrorToast
        property: "opacity"
        to: 0
        duration: 500
        easing.type: Easing.OutCubic
        onFinished: root.recentGtpErrors = []
    }
}
