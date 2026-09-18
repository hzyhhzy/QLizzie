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
import "EngineSupport.js" as EngineSupport
import "GameRules.js" as GameRules
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

    readonly property var stones: gameSession.stones
    readonly property var stoneItems: gameSession.stoneItems
    readonly property var gameNodes: gameSession.gameNodes
    property var treeNodes: []
    property var treeEdges: []
    property int treeCanvasWidth: 220
    property int treeCanvasHeight: 260
    readonly property int currentNodeId: gameSession.currentNodeId
    readonly property int nextNodeId: gameSession.nextNodeId
    readonly property int gameTreeGeneration: gameSession.gameTreeGeneration
    property int boardRevision: 0
    property int treeRevision: 0
    readonly property int legalityRevision: gameSession.legalityRevision
    readonly property int currentPlayer: gameSession.currentPlayer
    readonly property int stoneCount: gameSession.stoneCount
    readonly property int blackCaptures: gameSession.blackCaptures
    readonly property int whiteCaptures: gameSession.whiteCaptures
    readonly property string koLocKey: gameSession.koLocKey
    readonly property int koLocX: gameSession.koLocX
    readonly property int koLocY: gameSession.koLocY
    readonly property string koLocKey2: gameSession.koLocKey2
    readonly property int koLocX2: gameSession.koLocX2
    readonly property int koLocY2: gameSession.koLocY2
    property string hoverKey: ""
    property int hoverX: -1
    property int hoverY: -1
    property bool selectedPointLocked: false
    property bool selectedPointFromCandidateList: false
    readonly property var legalPointMap: gameSession.legalPointMap
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
    readonly property int gameRuleSurakarta: RuleRegistry.RULE_SURAKARTA
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
    readonly property var surakartaWinInfo: gameSession.surakartaWinInfo

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
    readonly property bool genmoveInFlight: engineSession.genmoveInFlight
    readonly property int genmoveRequestSerial: engineSession.genmoveRequestSerial
    readonly property int activeGenmoveRequestId: engineSession.activeGenmoveRequestId
    readonly property int activeGenmoveSyncRequestId: engineSession.activeGenmoveSyncRequestId
    readonly property var activeGenmovePosition: engineSession.activeGenmovePosition
    readonly property int genmovePlayer: engineSession.genmovePlayer
    readonly property bool aiAnalysisInFlight: engineSession.aiAnalysisInFlight
    readonly property int aiAnalysisRequestSerial: engineSession.aiAnalysisRequestSerial
    readonly property int activeAiAnalysisRequestId: engineSession.activeAiAnalysisRequestId
    readonly property int activeAiAnalysisSyncRequestId: engineSession.activeAiAnalysisSyncRequestId
    readonly property var activeAiAnalysisPosition: engineSession.activeAiAnalysisPosition
    readonly property double aiAnalysisStartedAt: engineSession.aiAnalysisStartedAt
    property bool applyingGeneratedMove: false
    readonly property var engineCandidates: analysisSession.engineCandidates
    readonly property var engineCandidateItems: analysisSession.engineCandidateItems
    readonly property var engineCandidateItemMap: analysisSession.engineCandidateItemMap
    readonly property var engineCandidateTableItems: analysisSession.engineCandidateTableItems
    readonly property int engineCandidateRevision: analysisSession.engineCandidateRevision
    readonly property bool engineCandidatesFromCache: analysisSession.engineCandidatesFromCache
    property double lastEngineCandidateUiUpdateAt: 0
    property int pendingEngineCandidateSyncRequestId: 0
    readonly property int largeCandidateUiThreshold: 1000
    readonly property int largeCandidateUiIntervalMs: 1000
    property bool bestCandidateRingVisible: false
    property string bestCandidateRingKey: ""
    property int bestCandidateRingX: -1
    property int bestCandidateRingY: -1
    readonly property var engineSyncedNodeIds: engineSession.engineSyncedNodeIds
    readonly property string engineSyncedBoardSignature: engineSession.engineSyncedBoardSignature
    readonly property string engineSyncedKomiSignature: engineSession.engineSyncedKomiSignature
    readonly property bool engineNeedsFullSync: engineSession.engineNeedsFullSync
    readonly property int engineSyncRequestSerial: engineSession.engineSyncRequestSerial
    readonly property var pendingEngineSyncSnapshot: engineSession.pendingEngineSyncSnapshot
    readonly property int engineAnalysisRequestNodeId: engineSession.engineAnalysisRequestNodeId
    readonly property int engineAnalysisRequestGeneration: engineSession.engineAnalysisRequestGeneration
    readonly property string engineAnalysisRequestBoardSignature: engineSession.engineAnalysisRequestBoardSignature
    readonly property string engineAnalysisRequestKomiSignature: engineSession.engineAnalysisRequestKomiSignature
    readonly property int engineAnalysisRequestPlayer: engineSession.engineAnalysisRequestPlayer
    readonly property string engineAnalysisRequestEngineSignature: engineSession.engineAnalysisRequestEngineSignature
    readonly property int engineAnalysisSyncRequestId: engineSession.engineAnalysisSyncRequestId
    readonly property bool engineAnalysisRequestValid: engineSession.engineAnalysisRequestValid
    property bool ownershipEnabled: false
    readonly property var engineOwnership: analysisSession.engineOwnership
    readonly property bool engineOwnershipFromCache: analysisSession.engineOwnershipFromCache
    readonly property string engineOwnershipBoardSignature: analysisSession.engineOwnershipBoardSignature
    readonly property string engineOwnershipKomiSignature: analysisSession.engineOwnershipKomiSignature
    readonly property string engineOwnershipEngineSignature: analysisSession.engineOwnershipEngineSignature
    readonly property int engineOwnershipRevision: analysisSession.engineOwnershipRevision
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
    onCurrentNodeIdChanged: resetEngineSearchSpeed()
    onGameTreeGenerationChanged: resetEngineSearchSpeed()
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

    menuBar: ApplicationMenuBar {
        id: applicationMenu
        compactLayout: root.compactLayout
        currentNodeId: root.currentNodeId
        gameRuleMode: root.gameRuleMode
        currentRuleText: root.currentRuleSelectionText()
        engineTitle: root.engineMenuTitle()
        hasActiveEngine: root.activeEnginePreset() !== null
        engineDisabled: root.engineDisabled
        activeEngineId: root.activeEngineId
        enginePresets: root.enginePresets
        commonOptions: root.commonGameRuleOptions()
        translate: root.trText
        ruleAllowed: root.ruleModeAllowedForPackage
        enginePresetText: root.engineMenuPresetText
        onOpenRequested: root.openLoadSgfDialog()
        onSaveRequested: root.openSaveSgfDialog()
        onQuitRequested: root.requestQuit()
        onUndoRequested: root.undoMove()
        onDeleteRequested: root.requestDeleteCurrentNode()
        onClearRequested: root.requestClearBoard()
        onBoardSizeRequested: root.openBoardSizeDialog()
        onResetVisualsRequested: root.resetVisualSettings()
        onSettingsRequested: settingsDialog.openPage(0)
        onEngineManagerRequested: engineListDialog.openManage()
        onRuleSelectionRequested: root.openRuleSelectionPopup()
        onTutorialRequested: root.openBeginnerTutorial()
        onHelpRequested: helpKeysDialog.open()
        onAboutRequested: aboutDialog.open()
        onEngineRestartRequested: root.restartEngine()
        onEngineStopRequested: root.stopEngine()
        onEnginePickerRequested: engineListDialog.openPicker()
        onLanguageRequested: function(language) { root.language = language }
        onRuleChosen: function(mode) { root.chooseRuleModeFromMenu(mode) }
        onEngineChosen: function(engineId) { root.loadEnginePreset(engineId, false) }
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

    RuleSelectionPopup {
        id: ruleSelectionPopup
        compactLayout: root.compactLayout
        viewportWidth: root.width
        viewportHeight: root.height
        gameRuleMode: root.gameRuleMode
        currentRuleText: root.currentRuleSelectionText()
        translate: root.trText
        rowsForGroups: root.ruleTreeRows
        initialCollapsedGroups: root.allRuleGroupsCollapsed
        ruleAllowed: root.ruleModeAllowedForPackage
        onRuleChosen: function(mode) { root.chooseRuleModeFromMenu(mode) }
        onCommonRulesRequested: root.openCommonGameRulesPopup()
    }

    CommonRulesPopup {
        id: commonGameRulesPopup
        compactLayout: root.compactLayout
        viewportWidth: root.width
        viewportHeight: root.height
        gameRuleMode: root.gameRuleMode
        translate: root.trText
        rowsForGroups: root.ruleTreeRows
        initialCollapsedGroups: root.allRuleGroupsCollapsed
        groupVisibilityState: root.ruleGroupVisibilityCheckState
        modeVisible: root.ruleModeVisible
        groupMutable: root.ruleGroupHasMutableVisibility
        commonOptions: root.commonGameRuleOptions()
        onModesVisibilityRequested: function(modes, visible) { root.setRuleModesVisible(modes, visible) }
        onModeVisibilityRequested: function(mode, visible) { root.setRuleModeVisible(mode, visible) }
        onReorderRequested: function(mode, delta) { root.moveCommonRule(mode, delta) }
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

    CandidateListWindow {
        id: candidateListWindow
        app: root
    }


    // Domain state is read-only here. Only session operations can change a game.

    AnalysisSession {
        id: analysisSession
        position: root.enginePositionSnapshot()
        currentNode: root.currentNode()
        presentationSettings: CandidateAnalysis.presentationSettings(root)
        boardSizeX: root.boardSizeX
        boardSizeY: root.boardSizeY
        ownershipEnabled: root.ownershipEnabled
        ownershipSupported: root.gameRuleMode === root.gameRuleGo
        nodeResolver: root.nodeById
        nodeAnalysisWriter: root.updateNodeAnalysis
        coordinateParser: root.parseEngineCoordinate
        coordinateFormatter: root.coordinateText
        passText: root.trText("passMove")
        resignText: root.trText("resignMove")
        onCandidatesChangedForDisplay: root.updateBestCandidateRing(engineCandidateItems)
        onLiveCandidatesAccepted: {
            root.engineLoading = false
            if (engineCandidateItems.length > 0 && root.analysisPresentationVisible()) {
                root.statusMode = "message"
                root.statusMessage = root.engineCandidateSummaryText()
            }
        }
    }

    function currentAnalysisRequest() {
        if (!engineAnalysisRequestValid)
            return null
        return { "nodeId": engineAnalysisRequestNodeId, "generation": engineAnalysisRequestGeneration,
                 "player": engineAnalysisRequestPlayer, "boardSignature": engineAnalysisRequestBoardSignature,
                 "komiSignature": engineAnalysisRequestKomiSignature,
                 "engineSignature": engineAnalysisRequestEngineSignature }
    }

    EngineSession {
        id: engineSession
        analysisLimitSeconds: root.maxAnalysisSeconds
        aiAnalysisSeconds: root.analysisSecondsPerMove
        aiAnalysisWatchdogMilliseconds: root.aiAnalysisWatchdogMilliseconds
        onScheduledUpdateRequested: root.requestScheduledEngineUpdate()
        onAnalysisLimitReached: root.pauseEngineAnalysisByLimit()
        onAiAnalysisLimitReached: root.tryFinishAiAnalysisMove()
        onAiAnalysisWatchdogExpired: root.handleAiAnalysisWatchdogTimeout()
    }

    readonly property GameSession game: gameSession
    GameSession {
        id: gameSession
        boardSizeX: root.boardSizeX
        boardSizeY: root.boardSizeY
        ruleMode: root.gameRuleMode
        stoneColorMode: root.stoneColorMode
        forbiddenChecker: root.pointIsGomokuForbidden
        onPositionChanged: function(result) { root.onGamePositionChanged(result) }
        onTreeChanged: function(result) {
            if (result.dirty)
                root.gameDirty = true
            if (result.kind === "annotations")
                root.analysisRevision += 1
            else if (result.kind === "move" || result.kind === "source" || result.kind === "target")
                root.scheduleTreeLayoutRebuild()
            else
                root.rebuildTreeLayout()
        }
        onOperationRejected: function(result) {
            root.statusMode = result.kind === "move" && root.stoneAt(result.x, result.y) !== 0
                              ? "occupied" : "message"
            root.statusMessage = result.kind === "move"
                    ? root.illegalPointMessage(result.x, result.y, result.reason)
                    : root.trText("invalidGameRecordNode") + " #" + result.nodeId + ": " + result.reason
        }
    }

    function onGamePositionChanged(result) {
        selectedPointLocked = false
        selectedPointFromCandidateList = false
        handleAiAnalysisPositionChanged()
        clearEngineCandidates()
        refreshWinVisuals(stones)
        boardRevision += 1
        showCachedAnalysisForCurrentNode()
        if (result.kind === "source") {
            resetEngineSyncState()
            statusMode = "message"
            statusMessage = trText("moveSourceSelected") + ": " + coordinateText(result.node.x, result.node.y)
        } else if (result.kind === "pass") {
            statusMode = "message"
            statusMessage = trText(result.node.player === 1 ? "black" : "white") + " " + trText("passMessage")
        } else if (result.kind === "move" || result.kind === "target") {
            statusMode = "turn"
            var captures = result.node.capturedStones.length
            statusMessage = captures > 0 ? trText("captureMessage") + ": " + captures : ""
        }
        var played = result.kind === "move" || result.kind === "target" || result.kind === "pass"
        refreshGameOutcomeFromCurrentNode(played)
        scheduleAutoAnalysis()
        if (played && !applyingGeneratedMove)
            requestAiMoveIfNeeded()
        if (result.kind === "navigate")
            focusBoardInput()
    }

    function loadGameTree(parsed) {
        return gameSession.loadTree(parsed, true)
    }

    function updateNodeAnalysis(nodeId, metadata) {
        return gameSession.updateNodeAnalysis(nodeId, metadata)
    }

    function trText(key) {
        language
        var table = translations[language] || translations.zh
        return table[key] === undefined ? key : table[key]
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
               && engineSession.acceptsAnalysis(engineAnalysisSyncRequestId, enginePositionSnapshot())
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
               || gameRuleMode === gameRuleDotsAndBoxes || gameRuleMode === gameRuleSurakarta
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
        return gameSession.currentMoveSourceNode()
    }

    function currentMoveSourcePoint() {
        return gameSession.currentMoveSourcePoint()
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
        return gameSession.nodeById(id)
    }

    function currentNode() {
        return gameSession.currentNode()
    }



    function nodePath(id) {
        return gameSession.nodePath(id)
    }

    function playerToMoveAfterNode(node) {
        return gameSession.playerToMoveAfterNode(node)
    }

    function nextPlayerFromMode() {
        return gameSession.nextPlayerFromMode()
    }

    function setStoneColorMode(mode) {
        var nextMode = Math.round(clamp(mode, stoneColorModeAuto, stoneColorModeWhite))
        var changed = stoneColorMode !== nextMode
        stoneColorMode = nextMode
        gameSession.refreshPlayer()
        if (changed) {
            scheduleAutoAnalysis()
            requestAiMoveIfNeeded()
        }
    }

    function pointLegalInMap(map, x, y, player, activeKoLocKey) {
        return gameSession.pointLegalInMap(map, x, y, player, activeKoLocKey)
    }

    function currentKoLoc() {
        return gameSession.currentKoLoc()
    }

    function pointKeyIsKoBanned(pointKey) {
        return gameSession.pointKeyIsKoBanned(pointKey)
    }

    function buildPointLegalityMap(map, player, activeKoLocKey) {
        return gameSession.buildPointLegalityMap(map, player, activeKoLocKey)
    }



    function rebuildPointLegality() {
        return gameSession.rebuildPointLegality()
    }

    function pointIsLegal(x, y) {
        return gameSession.pointIsLegal(x, y)
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





    function rebuildPositionFromNode(id) {
        return gameSession.rebuildPositionFromNode(id)
    }

    function resetGameTree() {
        stopAnalysisLimitTimer()
        invalidateEngineSyncState()
        gameWinner = 0
        gameOverReason = ""
        aiAnalysisBlackResignCount = 0
        aiAnalysisWhiteResignCount = 0
        clearHover(true)
        return gameSession.reset()
    }





    function placeStone(x, y) {
        if (!pointInRuleBoard(x, y))
            return false
        return gameSession.placeStone(x, y).ok
    }





    function passMove() {
        return gameSession.passMove().ok
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
        } else if (gameRuleMode === gameRuleSurakarta && surakartaWinInfo.finished === true) {
            nextWinner = surakartaWinInfo.player
            nextReason = surakartaWinInfo.reason === "pass"
                         ? trText("gameOverSurakartaPass") : trText("gameOverSurakarta")
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
        return gameSession.undoMove().changed
    }

    function gotoNode(id) {
        return gameSession.gotoNode(id).changed === true
    }

    function gotoFirstMove() {
        return gameSession.gotoFirstMove().changed
    }

    function gotoLastMove() {
        return gameSession.gotoLastMove().ok
    }

    function validateParsedGame(parsed) {
        return gameSession.validateParsedGame(parsed)
    }

    function gotoRelativeMove(delta) {
        return gameSession.gotoRelativeMove(delta).changed
    }

    function gotoMoveNumber(moveNumber) {
        return gameSession.gotoMoveNumber(moveNumber).changed
    }

    function currentMoveNumberValue() {
        return gameSession.currentMoveNumberValue()
    }

    function currentMoveNumberText() {
        return String(currentMoveNumberValue())
    }

    function maxMoveNumberValue() {
        return gameSession.maxMoveNumberValue()
    }

    function currentNodeText() {
        var node = currentNode()
        if (!node || node.id === 0)
            return trText("rootMove")
        if (node.moveRole === "source")
            return (currentMoveNumberValue() + 1) + " " + trText("moveSource") + " " + coordinateText(node.x, node.y)
        return currentMoveNumberValue() + " " + (node.isPass ? trText("passMove") : coordinateText(node.x, node.y))
    }

    function deleteCurrentNode() {
        return gameSession.deleteCurrentNode().changed
    }

    function deleteSubtree(id) {
        return gameSession.deleteSubtree(id).changed
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
        return gameSession.setCurrentVariationAsMainBranch().changed
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
        var layout = TreeLayout.build(gameNodes, currentNodeId, {
            "compactLayout": compactLayout,
            "minimumWidth": minimumTreeCanvasWidth,
            "minimumHeight": minimumTreeCanvasHeight,
            "rootText": trText("rootMove"),
            "passText": trText("passMove"),
            "coordinateText": coordinateText
        })
        treeNodes = layout.nodes
        treeEdges = layout.edges
        treeCanvasWidth = layout.width
        treeCanvasHeight = layout.height
        treeRevision += 1
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
        applicationMenu.dismissSettings()
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
        if (gameRuleMode === gameRuleSurakarta)
            return [ "kata-set-rules Surakarta" ]
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
                       : gameRuleMode === gameRuleHex ? "hex"
                       : gameRuleMode === gameRuleSurakarta ? "surakarta" : "go"
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

    function enginePositionSnapshot() {
        return {
            nodeId: currentNodeId,
            generation: gameTreeGeneration,
            boardSignature: engineBoardSignature(),
            komiSignature: engineKomiSignature(),
            player: currentPlayer,
            engineSignature: engineAnalysisSourceSignature()
        }
    }

    function commitEngineSyncSnapshot(syncRequestId) {
        return engineSession.commitSync(syncRequestId)
    }

    function engineSyncCommands(syncRequestId) {
        var path = nodePath(currentNodeId)
        var pathIds = []
        for (var pathIndex = 0; pathIndex < path.length; ++pathIndex)
            pathIds.push(path[pathIndex].id)
        var plan = engineSession.syncPlan(syncRequestId, pathIds,
                                          engineBoardSignature(), engineKomiSignature(),
                                          !!engineController && engineController.canUseIncrementalSync())
        if (!plan)
            return []
        var commands = [ "stop" ]
        if (plan.full) {
            commands = commands.concat(engineBoardSizeCommands())
            commands = commands.concat(engineAnalysisParameterCommands())
            commands = commands.concat(engineRuleCommands())
            commands.push("clear_board")
            for (var fullIndex = 0; fullIndex < path.length; ++fullIndex)
                commands.push(enginePlayCommandForNode(path[fullIndex]))
            return commands
        }
        if (plan.parametersChanged)
            commands = commands.concat(engineAnalysisParameterCommands())
        for (var undoIndex = 0; undoIndex < plan.undoCount; ++undoIndex)
            commands.push("undo")
        for (var playIndex = plan.playStartIndex; playIndex < path.length; ++playIndex)
            commands.push(enginePlayCommandForNode(path[playIndex]))
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
        engineSession.invalidateAll()
        largeCandidateUiUpdateTimer.stop()
        pendingEngineCandidateSyncRequestId = 0
    }

    function invalidateEngineSyncRequest(syncRequestId) {
        engineSession.invalidateSyncRequest(syncRequestId)
    }

    function resetEngineSyncState() {
        var hadPlayRequest = genmoveInFlight || aiAnalysisInFlight
        invalidateEngineSyncState()
        if (hadPlayRequest && engineController)
            engineController.sendCommand("stop")
        if (hadPlayRequest && appReady)
            Qt.callLater(function() { root.requestAiMoveIfNeeded() })
    }

    function markGeneratedMoveSynced() {
        var path = nodePath(currentNodeId)
        var pathIds = []
        for (var pathIndex = 0; pathIndex < path.length; ++pathIndex)
            pathIds.push(path[pathIndex].id)
        return engineSession.markGeneratedMoveSynced(pathIds,
                                                     engineBoardSignature(), engineKomiSignature())
    }

    function requestEngineAnalysis(force) {
        if (applicationShutdownPrepared || !analysisModeActive()
                || enginePaused || engineDisabled || !engineAutoAnalyze || !engineController)
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
        engineNoticeDismissed = false
        var request = engineSession.beginAnalysis(enginePositionSnapshot())
        engineController.requestAnalysis(engineSyncCommands(request.syncRequestId),
                                         analyzeCommand(), request.syncRequestId)
        statusMode = "message"
        statusMessage = trText("engineAnalyzeRequested")
        resetAnalysisLimitTimer()
    }

    function requestEngineSynchronization() {
        if (applicationShutdownPrepared || !analysisModeActive()
                || !enginePaused || engineDisabled || !engineAutoAnalyze || !engineController)
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
        var request = engineSession.beginSynchronization(enginePositionSnapshot())
        engineController.requestSynchronization(engineSyncCommands(request.syncRequestId),
                                                request.syncRequestId)
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
        engineSession.scheduleAutoAnalysis(enginePaused)
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
        invalidateEngineSyncState()
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
        engineSession.invalidateAnalysis()
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
        engineSession.resetAnalysisLimitTimer(analysisModeActive() && !enginePaused
                                              && !engineDisabled && engineAutoAnalyze)
    }

    function stopAnalysisLimitTimer() {
        engineSession.stopAnalysisLimitTimer()
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
            engineSession.invalidateAnalysis()
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
        if (applicationShutdownPrepared || !aiShouldMove() || genmoveInFlight || aiAnalysisInFlight
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
        var request = engineSession.beginGenmove(enginePositionSnapshot())
        engineController.requestMove(engineSyncCommands(request.syncRequestId),
                                     timeSettingsCommand(), genmoveCommand(),
                                     request.requestId, request.syncRequestId)
        statusMode = "message"
        statusMessage = trText("engineThinking")
    }

    function requestAiAnalysisMove() {
        if (applicationShutdownPrepared || !aiShouldMove() || aiMoveMode !== aiMoveModeAnalyze
                || genmoveInFlight || aiAnalysisInFlight || !engineReadyForPlayMode())
            return
        if (!analysisMoveLimitConfigured()) {
            statusMode = "message"
            statusMessage = trText("analysisMoveLimitRequired")
            return
        }
        var request = engineSession.beginAiAnalysis(enginePositionSnapshot())
        engineController.requestAnalysis(engineSyncCommands(request.syncRequestId),
                                         analyzeCommand(), request.syncRequestId)
        statusMode = "message"
        statusMessage = trText("engineThinking")
    }

    function restartAiAnalysisTimeLimit() {
        engineSession.restartAiAnalysisTimeLimit()
    }

    function restartAiAnalysisWatchdog() {
        engineSession.restartAiAnalysisWatchdog()
    }

    function handleAiAnalysisWatchdogTimeout() {
        if (!aiAnalysisInFlight)
            return
        pauseAfterEngineProtocolFailure("analysisNoResponse", "", true)
        statusMode = "message"
        statusMessage = trText("analysisNoResponse")
    }

    function activeAiAnalysisPositionMatches() {
        return engineSession.activeAiAnalysisPositionMatches(enginePositionSnapshot())
    }

    function pauseAfterEngineProtocolFailure(messageKey, detail, sendStop) {
        invalidateEngineSyncState()
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
        if (!engineSession.acceptsAnalysis(analysisRequestId, enginePositionSnapshot()))
            return
        Qt.callLater(function() {
            if (engineSession.acceptsAnalysis(analysisRequestId, root.enginePositionSnapshot()))
                root.pauseAfterEngineProtocolFailure("analysisMoveFailed", line, false)
        })
    }

    function handleAiAnalysisPositionChanged() {
        if (applyingGeneratedMove)
            return
        var hadPlayRequest = genmoveInFlight || aiAnalysisInFlight
        if (!engineSession.positionChanged(enginePositionSnapshot()))
            return
        largeCandidateUiUpdateTimer.stop()
        pendingEngineCandidateSyncRequestId = 0
        if (hadPlayRequest && engineController)
            engineController.sendCommand("stop")
        if (hadPlayRequest && appReady)
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
        var moveNumber = currentMoveNumberValue()
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

        var completed = engineSession.completeAiAnalysis(activeAiAnalysisRequestId,
                                                          enginePositionSnapshot())
        if (!completed.accepted)
            return false
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
        engineSession.cancelPlay(invalidateSync)
    }

    function cancelActiveAiAnalysisRequest(invalidateSync) {
        engineSession.cancelAiAnalysis(invalidateSync)
    }

    function handleGeneratedMove(requestId, move, ok, rawLine) {
        var result = engineSession.completeGenmove(requestId, enginePositionSnapshot(), ok)
        if (!result.accepted)
            return
        if (result.status === "stale") {
            requestAiMoveIfNeeded()
            return
        }
        if (result.status === "failed") {
            if (ignoreGtpErrors && String(rawLine).trim().indexOf("?") === 0)
                return
            pauseAfterEngineProtocolFailure("engineMoveFailed", rawLine, false)
            return
        }
        if (String(move).trim().toLowerCase() === "resign") {
            finishEngineResignation(result.request.position.player)
            return
        }
        if (!applyGeneratedMove(move)) {
            invalidateEngineSyncState()
            return
        }
        markGeneratedMoveSynced()
        requestAiMoveIfNeeded()
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
        return CandidateAnalysis.labelLineCenterY(lines, lineIndex, height)
    }

    function candidateLabelScaledTotalHeight(lines, markerRadius) {
        return CandidateAnalysis.labelScaledTotalHeight(lines, markerRadius)
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
        return analysisSession.resetCandidates()
    }

    function setEngineCandidateDisplay(candidates, fromCache, revision) {
        return analysisSession.setCandidates(candidates, fromCache, revision)
    }

    function nodeAnalysisCacheUsable(node) {
        return analysisSession.nodeCandidateCacheUsable(node)
    }

    function recordAnalysisWinrateForNode(node, candidates, playerToMove) {
        return analysisSession.recordWinrate(node, candidates, playerToMove)
    }

    function cacheAnalysisCandidatesForNode(node, candidates, boardSignature, komiSignature) {
        return analysisSession.cacheCandidates(node, candidates, boardSignature, komiSignature, playerToMoveAfterNode(node))
    }

    function showCachedAnalysisForCurrentNode() {
        var candidatesShown = analysisSession.showCachedCandidates()
        var ownershipShown = analysisSession.showCachedOwnership()
        return candidatesShown || ownershipShown
    }

    function applyEngineCandidateUpdate(candidates, revision) {
        return analysisSession.applyCandidateUpdate(candidates, revision, currentAnalysisRequest(),
                engineAnalysisRequestValid && (analysisModeActive() || aiAnalysisInFlight))
    }

    function flushEngineCandidateUpdate() {
        var syncRequestId = pendingEngineCandidateSyncRequestId
        pendingEngineCandidateSyncRequestId = 0
        if (!engineController || !engineSession.acceptsAnalysis(syncRequestId, enginePositionSnapshot()))
            return
        var candidateSnapshot = engineController.candidates
        applyEngineCandidateUpdate(candidateSnapshot, engineController.candidateRevision)
        applyEngineOwnershipUpdate(engineController.ownership)
        lastEngineCandidateUiUpdateAt = Date.now()
        tryFinishAiAnalysisMove()
    }

    function scheduleEngineCandidateUpdate() {
        if (applicationShutdownPrepared || !engineController)
            return
        pendingEngineCandidateSyncRequestId = engineAnalysisSyncRequestId

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
        return analysisSession.rebuildCandidates()
    }

    function resetEngineOwnershipDisplay() {
        return analysisSession.resetOwnership()
    }

    function setEngineOwnershipDisplay(values, fromCache, boardSignature,
                                       komiSignature, engineSignature) {
        return analysisSession.setOwnership(values, fromCache, boardSignature, komiSignature, engineSignature)
    }

    function nodeOwnershipCacheUsable(node) {
        return analysisSession.nodeOwnershipCacheUsable(node)
    }

    function showCachedOwnershipForCurrentNode() {
        return analysisSession.showCachedOwnership()
    }

    function applyEngineOwnershipUpdate(values) {
        return analysisSession.applyOwnershipUpdate(values, currentAnalysisRequest(),
                engineAnalysisRequestValid && (analysisModeActive() || aiAnalysisInFlight))
    }

    function ownershipVisibleForCurrentPosition() {
        return analysisSession.ownershipVisible()
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
        invalidateEngineSyncState()
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

    function selectEngineCandidateRow(row, focusMainWindow) {
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
            if (focusMainWindow !== false)
                focusBoardInput()
            return
        }
        setSelectedPoint(candidate.x, candidate.y, true, true)
        if (focusMainWindow !== false)
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

    function nextMoveMarkerItems() {
        return BoardVisuals.nextMoveMarkerItems(root)
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

    function toggleCandidateListWindow() {
        candidateListWindow.toggleWindow()
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
        candidateListWindow.closeWindow()
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
        engineSession.shutdown()
        engineSearchSpeedTimer.stop()
        largeCandidateUiUpdateTimer.stop()
        engineInitialCommandsCompletionTimer.stop()
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
            engineSession.commitSync(syncRequestId)
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
                root.invalidateEngineSyncState()
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
                root.invalidateEngineSyncState()
                root.resetEngineSearchSpeed()
                root.handleEngineLoadFailure(root.engineFailureMessage())
            }
        }

        function onRunningChanged() {
            if (!engineController.running) {
                root.invalidateEngineSyncState()
                root.resetEngineSearchSpeed()
            }
        }

        function onMoveGenerated(requestId, move, ok, rawLine) {
            root.handleGeneratedMove(requestId, move, ok, rawLine)
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
