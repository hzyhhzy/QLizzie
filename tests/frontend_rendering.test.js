const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const { loadQmlJs } = require("./qmlJsLoader")

const root = path.join(__dirname, "..")
const qmlDirectory = path.join(root, "app", "qml")
const directWindowFiles = fs.readdirSync(qmlDirectory)
    .filter(name => name.endsWith(".qml"))
    .filter(name => /^\s*(?:Application)?Window\s*\{/m.test(
        fs.readFileSync(path.join(qmlDirectory, name), "utf8")
    ))
    .sort()
assert.deepEqual(directWindowFiles, [
    "AppWindowDialog.qml",
    "BeginnerTutorialDialog.qml",
    "EngineCommunicationWindow.qml",
    "Main.qml"
])
const boardInputSource = fs.readFileSync(path.join(root, "app", "qml", "BoardInputLayer.qml"), "utf8")
const mainSource = fs.readFileSync(path.join(root, "app", "qml", "Main.qml"), "utf8")
const appWindowDialogSource = fs.readFileSync(
    path.join(root, "app", "qml", "AppWindowDialog.qml"),
    "utf8"
)
const beginnerTutorialSource = fs.readFileSync(
    path.join(root, "app", "qml", "BeginnerTutorialDialog.qml"),
    "utf8"
)
const hiddenSettingsSource = fs.readFileSync(path.join(root, "app", "qml", "HiddenSettingsDialog.qml"), "utf8")
const settingsDialogSource = fs.readFileSync(path.join(root, "app", "qml", "SettingsDialog.qml"), "utf8")
const analysisToolbarSource = fs.readFileSync(path.join(root, "app", "qml", "AnalysisToolbar.qml"), "utf8")
const helpKeysSource = fs.readFileSync(path.join(root, "app", "qml", "HelpKeysDialog.qml"), "utf8")
const boardSceneSource = fs.readFileSync(path.join(root, "app", "qml", "BoardScene.qml"), "utf8")
const infoPanelSource = fs.readFileSync(path.join(root, "app", "qml", "InfoPanel.qml"), "utf8")
const engineCommunicationSource = fs.readFileSync(
    path.join(root, "app", "qml", "EngineCommunicationWindow.qml"),
    "utf8"
)
const windowGeometrySource = fs.readFileSync(
    path.join(root, "app", "qml", "WindowGeometry.js"),
    "utf8"
)
const settingsStoreSource = fs.readFileSync(path.join(root, "app", "qml", "SettingsStore.js"), "utf8")
const applicationMainSource = fs.readFileSync(path.join(root, "app", "src", "main.cpp"), "utf8")
const engineControllerSource = fs.readFileSync(
    path.join(root, "app", "src", "enginecontroller.cpp"),
    "utf8"
)
const engineControllerHeader = fs.readFileSync(
    path.join(root, "app", "src", "enginecontroller.h"),
    "utf8"
)
const boardRenderer = loadQmlJs(path.join(root, "app", "qml", "BoardRenderer.js"), {
    imports: { CoordinateUtils: {} }
})
const boardVisuals = loadQmlJs(path.join(root, "app", "qml", "BoardVisuals.js"), {
    imports: { GameRules: {} }
})
const treeLayout = loadQmlJs(path.join(root, "app", "qml", "TreeLayout.js"))

function countingContext() {
    return {
        arcCount: 0,
        save() {},
        restore() {},
        beginPath() {},
        moveTo() {},
        lineTo() {},
        closePath() {},
        fill() {},
        stroke() {},
        arc() { this.arcCount += 1 }
    }
}

const dotsState = {
    boardSizeX: 3,
    boardSizeY: 3,
    gameRuleMode: 7,
    gameRuleDotsAndBoxes: 7,
    gameRuleHex: 2,
    gameRuleTorusGo: 3,
    hexGridBoard: false,
    squareCellBoard: false,
    hexCellStyleActive: false,
    gridOpacity: 1,
    gridLineWidth: 1
}
const dotsGeometry = {
    cellSize: 20,
    point(x, y) { return { x: x * 20, y: y * 20 } }
}

const gridContext = countingContext()
boardRenderer.drawGrid(gridContext, dotsState, dotsGeometry)
assert.equal(gridContext.arcCount, 4, "the static grid owns the four board dots")

const positionContext = countingContext()
boardRenderer.drawDotsAndBoxesPosition(positionContext, dotsState, dotsGeometry, [])
assert.equal(positionContext.arcCount, 0, "the position layer must not redraw static dots")

const node = { x: 100, y: 100, radius: 12 }
assert.equal(treeLayout.nodeVisibleInViewport(node, 80, 80, 40, 40, 0), true)
assert.equal(treeLayout.nodeVisibleInViewport(node, 113, 80, 40, 40, 0), false)
assert.equal(treeLayout.nodeVisibleInViewport(node, 113, 80, 40, 40, 1), true)

const crossingEdge = { x1: 0, y1: 100, x2: 200, y2: 100 }
const outsideEdge = { x1: 0, y1: 10, x2: 200, y2: 10 }
assert.equal(treeLayout.edgeVisibleInViewport(crossingEdge, 80, 80, 40, 40, 0), true)
assert.equal(treeLayout.edgeVisibleInViewport(outsideEdge, 80, 80, 40, 40, 0), false)

const nextMoveNodes = [
    { id: 0, children: [1, 2, 3, 4] },
    { id: 1, x: 3, y: 3, player: 1 },
    { id: 2, x: 10, y: 10, player: 1 },
    { id: 3, x: -1, y: -1, player: 1, isPass: true },
    { id: 4, x: 10, y: 10, player: 1 }
]
const nextMoveMarkers = boardVisuals.nextMoveMarkerItems({
    currentNode() { return nextMoveNodes[0] },
    nodeById(id) { return nextMoveNodes[id] },
    pointInRuleBoard(x, y) { return x >= 0 && y >= 0 && x < 19 && y < 19 },
    keyFor(x, y) { return `${x},${y}` }
})
assert.deepEqual(Array.from(nextMoveMarkers, marker => ({
    x: marker.x,
    y: marker.y,
    player: marker.player,
    mainBranch: marker.mainBranch
})), [
    { x: 3, y: 3, player: 1, mainBranch: true },
    { x: 10, y: 10, player: 1, mainBranch: false }
])
assert.match(boardSceneSource, /function drawNextMoveMarkers\(ctx,\s*stoneRadius\)/)
assert.match(boardSceneSource,
             /marker\.mainBranch[\s\S]*?stoneRadius\s*\/\s*7[\s\S]*?stoneRadius\s*\/\s*15/)
assert.match(boardSceneSource,
             /radius\s*=\s*Math\.max\(1,\s*stoneRadius\s*-\s*lineWidth\s*\*\s*0\.5\)/)
assert.match(boardSceneSource,
             /if \(!boardScene\.variationPreviewActive\)\s*drawNextMoveMarkers\(ctx,\s*stoneRadius\)/)
assert.match(boardSceneSource,
             /function onGameNodesChanged\(\) \{ boardCanvas\.requestPaint\(\) \}/)

const commaHandler = boardInputSource.slice(
    boardInputSource.indexOf("event.key === Qt.Key_Comma"),
    boardInputSource.indexOf("event.key === Qt.Key_P")
)
assert.match(commaHandler, /app\.playBestEngineMove\(\)/)
assert.doesNotMatch(commaHandler, /isAutoRepeat/)

const backspaceHandler = boardInputSource.slice(
    boardInputSource.indexOf("event.key === Qt.Key_Backspace"),
    boardInputSource.indexOf("event.key === Qt.Key_M")
)
assert.match(backspaceHandler, /app\.requestDeleteCurrentNode\(\)/)
assert.doesNotMatch(backspaceHandler, /isAutoRepeat/)
assert.match(boardInputSource, /function ownsKeyboardFocus\(\)/)
assert.match(boardInputSource, /if \(!inputLayer\.ownsKeyboardFocus\(\)\)/)
assert.match(boardInputSource,
             /event\.key === Qt\.Key_E[\s\S]*?app\.openEngineCommunicationLog\(\)/)
assert.doesNotMatch(boardInputSource, /Qt\.Key_U/)
assert.match(boardInputSource,
             /event\.key === Qt\.Key_Period[\s\S]*?app\.gameRuleMode === app\.gameRuleGo[\s\S]*?app\.ownershipEnabled = !app\.ownershipEnabled/)
assert.match(helpKeysSource, /\{\s*"keys":\s*"E",\s*"textKey":\s*"helpKeyEngineLogDesc"\s*\}/)
assert.match(helpKeysSource, /\{\s*"keys":\s*"\.",\s*"textKey":\s*"helpKeyOwnershipDesc"\s*\}/)
assert.doesNotMatch(helpKeysSource, /\{\s*"keys":\s*"U"/)

const engineMenu = mainSource.slice(
    mainSource.indexOf("id: engineMenu"),
    mainSource.indexOf("id: saveSgfDialog")
)
const addEnginePosition = engineMenu.indexOf('trText("engineAddAndConfigure")')
const restartEnginePosition = engineMenu.indexOf('trText("engineRestartCurrent")')
const closeEnginePosition = engineMenu.indexOf('trText("engineCloseCurrent")')
const presetListPosition = engineMenu.indexOf("Instantiator")
const moreEnginesPosition = engineMenu.indexOf('trText("moreEngines")')
assert.ok(addEnginePosition >= 0)
assert.ok(addEnginePosition < restartEnginePosition)
assert.ok(restartEnginePosition < closeEnginePosition)
assert.ok(closeEnginePosition < presetListPosition)
assert.ok(presetListPosition < moreEnginesPosition)
assert.match(engineMenu, /model:\s*Math\.min\(10,\s*root\.enginePresets\.length\)/)
assert.match(engineMenu, /engineMenu\.insertItem\(index\s*\+\s*4,\s*object\)/)

assert.match(mainSource, /property bool ignoreGtpErrors:\s*true/)
assert.match(mainSource, /property int candidateTableRowLimit:\s*20/)
assert.match(mainSource, /maxCandidateTableRowLimit:\s*10000/)
assert.match(mainSource, /messages\.length > 2/)
assert.match(mainSource, /interval:\s*5000/)
assert.match(mainSource, /enabled:\s*false/)
assert.match(mainSource, /function onGtpErrorResponse\(line\)/)
assert.match(mainSource,
             /var ignoredGtpError = root\.ignoreGtpErrors[\s\S]*?if \(ignoredGtpError\)\s*return/)
assert.match(hiddenSettingsSource, /text:\s*app\.trText\("ignoreGtpErrors"\)/)
assert.match(hiddenSettingsSource, /text:\s*app\.trText\("candidateTableRowLimit"\)/)
assert.match(hiddenSettingsSource, /to:\s*app\.maxCandidateTableRowLimit/)
assert.match(settingsStoreSource, /settingBool\(settings,\s*"ignoreGtpErrors"/)
assert.match(settingsStoreSource, /"candidateTableRowLimit"/)
assert.match(settingsStoreSource, /settings\.setValue\("ignoreGtpErrors",\s*app\.ignoreGtpErrors\)/)
assert.match(mainSource, /property int engineCommunicationLogLimit:\s*1000/)
assert.match(mainSource, /property int engineCommunicationLogCharacterLimit:\s*262144/)
assert.match(mainSource, /property int engineCommunicationLineCharacterLimit:\s*16384/)
assert.match(mainSource, /maxEngineCommunicationLogLines:\s*10000/)
assert.match(mainSource, /maxEngineCommunicationLogCharacters:\s*2097152/)
assert.match(mainSource, /maxEngineCommunicationLineCharacters:\s*262144/)
assert.match(hiddenSettingsSource, /engineLogMaxLines/)
assert.match(hiddenSettingsSource, /engineLogMaxCharacters/)
assert.match(hiddenSettingsSource, /engineLogMaxLineCharacters/)
assert.match(hiddenSettingsSource, /to:\s*app\.maxEngineCommunicationLogLines/)
assert.match(hiddenSettingsSource, /to:\s*app\.maxEngineCommunicationLogCharacters/)
assert.match(hiddenSettingsSource, /app\.maxEngineCommunicationLineCharacters/)
assert.match(settingsStoreSource, /"engineCommunicationLogLimit"/)
assert.match(settingsStoreSource, /"engineCommunicationLogCharacterLimit"/)
assert.match(settingsStoreSource, /"engineCommunicationLineCharacterLimit"/)
for (const sectionTitle of [
    "boardSize",
    "basicGameSettings",
    "gamePlaySettings",
    "candidateSettings",
    "visualSettings"
]) {
    assert.match(
        settingsDialogSource,
        new RegExp(
            `title:\\s*app\\.trText\\("${sectionTitle}"\\)`
            + `[\\s\\S]{0,180}ColumnLayout\\s*\\{`
            + `\\s*Layout\\.fillWidth:\\s*true`
        )
    )
}
assert.match(engineCommunicationSource, /stableViewportWidth:\s*Math\.max\(0,\s*width - 16\)/)
assert.match(engineCommunicationSource, /stableViewportHeight:\s*Math\.max\(0,\s*height - 2\)/)
assert.match(engineCommunicationSource, /function scheduleHeightUpdate\(\)/)
assert.match(engineCommunicationSource, /onContentHeightChanged:\s*engineCommunicationContent\.scheduleHeightUpdate\(\)/)
assert.doesNotMatch(
    engineCommunicationSource,
    /height:\s*Math\.max\([^\n]*engineCommunicationText\.(?:contentHeight|implicitHeight)/
)
assert.doesNotMatch(
    engineCommunicationSource,
    /engineCommunicationContent[\s\S]{0,500}engineCommunicationScroll\.available(?:Width|Height)/
)
assert.match(engineCommunicationSource, /width:\s*Math\.max\(0,\s*engineCommunicationDialog\.width - 28\)/)
assert.match(engineCommunicationSource, /height:\s*Math\.max\(0,\s*engineCommunicationDialog\.height - 28\)/)
assert.match(beginnerTutorialSource, /width:\s*tutorialDialog\.width/)
assert.match(beginnerTutorialSource, /height:\s*tutorialDialog\.height/)
assert.match(engineCommunicationSource, /WindowGeometry\.clampWindow\(engineCommunicationDialog,\s*app\)/)
assert.match(beginnerTutorialSource, /WindowGeometry\.clampWindow\(tutorialDialog,\s*app\)/)
assert.match(windowGeometrySource, /function clampWindow\(windowObject,\s*ownerWindow\)/)
assert.match(mainSource, /function prepareApplicationShutdown\(\)/)
assert.match(mainSource, /function closeAuxiliaryWindowsForShutdown\(\)/)
assert.match(mainSource, /engineCommunicationWindow\.closeWindow\(\)/)
assert.match(mainSource, /beginnerTutorialDialog\.closeTutorialWindow\(\)/)
assert.match(mainSource, /settingsDialog\.closeWindowForShutdown\(\)/)
assert.match(mainSource, /hiddenSettingsDialog\.closeWindowForShutdown\(\)/)
assert.match(mainSource, /engineListDialog\.closeWindowForShutdown\(\)/)
assert.match(mainSource, /helpKeysDialog\.closeWindowForShutdown\(\)/)
assert.match(mainSource, /function stopApplicationTimersForShutdown\(\)/)
assert.match(mainSource,
             /function prepareApplicationShutdown\(\)[\s\S]*?savePersistentSettings\(\)[\s\S]*?appSettings\.sync\(\)/)
assert.match(mainSource,
             /onClosing:\s*function\(event\)[\s\S]*?prepareApplicationShutdown\(\)\s*Qt\.quit\(\)/)
assert.doesNotMatch(mainSource, /Qt\.callLater\(Qt\.quit\)/)
assert.match(appWindowDialogSource,
             /!appWindowDialog\.owningWindow\.visible[\s\S]*?appWindowDialog\.closeWindowForShutdown\(\)/)
assert.match(engineCommunicationSource,
             /function onVisibleChanged\(\)\s*\{\s*if \(!app\.visible\)\s*engineCommunicationDialog\.closeWindow\(\)/)
assert.match(beginnerTutorialSource,
             /function onVisibleChanged\(\)\s*\{\s*if \(!app\.visible\)\s*tutorialDialog\.closeTutorialWindow\(\)/)
assert.match(applicationMainSource,
             /QCoreApplication::aboutToQuit[\s\S]*?EngineController::shutdown/)
const appSettingsConstruction = applicationMainSource.indexOf("AppSettings appSettings;")
const fileIoConstruction = applicationMainSource.indexOf("FileIo fileIo;")
const engineControllerConstruction = applicationMainSource.indexOf(
    "EngineController engineController;"
)
const gomokuForbiddenConstruction = applicationMainSource.indexOf(
    "GomokuForbidden gomokuForbidden;"
)
const qmlEngineConstruction = applicationMainSource.indexOf(
    "QQmlApplicationEngine engine;"
)
assert.ok(appSettingsConstruction >= 0)
assert.ok(fileIoConstruction > appSettingsConstruction)
assert.ok(engineControllerConstruction > fileIoConstruction)
assert.ok(gomokuForbiddenConstruction > engineControllerConstruction)
assert.ok(qmlEngineConstruction > gomokuForbiddenConstruction,
          "the QML engine must be destroyed before its context objects")
assert.match(settingsDialogSource, /if \(!app\.applicationShutdownPrepared\)/)
assert.match(hiddenSettingsSource, /if \(!app\.applicationShutdownPrepared\)/)
assert.match(engineControllerHeader, /bool m_shutdownRequested = false/)
assert.match(engineControllerSource,
             /void EngineController::shutdown\(\)\s*\{\s*m_shutdownRequested = true/)
assert.match(engineControllerSource,
             /if \(restartPending && !m_shutdownRequested\)/)
assert.match(engineControllerSource,
             /kMaximumEngineLineBytes\s*=\s*262144/)
assert.match(engineControllerSource,
             /kMaximumAnalysisInfoLineBytes\s*=\s*4\s*\*\s*1024\s*\*\s*1024/)
assert.match(engineControllerSource,
             /communicationInfoLineFiltered\(text\)[\s\S]*?return kMaximumAnalysisInfoLineBytes/)
assert.match(engineControllerSource, /item\.insert\(QStringLiteral\("pvText"\)/)
assert.match(engineControllerSource, /item\.insert\(QStringLiteral\("pvVisitsText"\)/)
assert.match(engineControllerSource,
             /newlineIndex > maximumBytes/)
assert.match(engineControllerSource,
             /buffer\.size\(\) > maximumBytes/)
assert.match(engineControllerSource,
             /void EngineController::failTransport\(const QString &message\)/)
assert.match(engineControllerSource,
             /setFailed\(true,\s*message,\s*QStringLiteral\("protocol"\)\)/)
assert.match(engineControllerSource,
             /attachProcessToJobObject\(\);[\s\S]*?if \(m_shutdownRequested\)/)
const stdoutHandler = engineControllerSource.slice(
    engineControllerSource.indexOf("void EngineController::handleStdoutLine"),
    engineControllerSource.indexOf("void EngineController::handleStderrLine")
)
assert.ok(stdoutHandler.indexOf("communicationInfoLineFiltered")
          < stdoutHandler.indexOf("emit engineOutput"))

const engineSyncCommands = mainSource.slice(
    mainSource.indexOf("function engineSyncCommands"),
    mainSource.indexOf("function analyzeCommand")
)
assert.match(engineSyncCommands, /pendingEngineSyncSnapshot !== null/)
assert.match(engineSyncCommands, /canUseIncrementalSync\(\)/)
assert.match(engineSyncCommands, /stageEngineSyncSnapshot\(/)
assert.doesNotMatch(engineSyncCommands, /engineSyncedNodeIds\s*=/)
assert.doesNotMatch(engineSyncCommands, /engineNeedsFullSync\s*=\s*false/)
assert.match(mainSource, /function resetGameTree\(\)\s*\{[\s\S]*?invalidateEngineSyncState\(\)/)
assert.match(mainSource, /function onEngineSynchronizationCompleted\(syncRequestId\)/)
assert.match(mainSource,
             /function requestEngineSynchronization\(\)[\s\S]*?requestSynchronization\(engineSyncCommands\(syncRequestId\)/)
assert.match(mainSource,
             /function requestScheduledEngineUpdate\(\)\s*\{[\s\S]*?if \(enginePaused\)[\s\S]*?requestEngineSynchronization\(\)[\s\S]*?requestEngineAnalysis\(false\)/)
assert.match(mainSource,
             /function scheduleAutoAnalysis\(\)\s*\{[\s\S]*?autoAnalyzeTimer\.interval = enginePaused \? 1 : 280/)
assert.match(mainSource,
             /function resetGameTree\(\)\s*\{[\s\S]*?boardRevision \+= 1\s*scheduleAutoAnalysis\(\)/)
assert.match(mainSource, /function markGeneratedMoveSynced\(\)/)
assert.match(mainSource, /if \(!root\.applyGeneratedMove\(move\)\)/)
assert.match(mainSource, /position\.generation === root\.gameTreeGeneration/)
assert.match(mainSource, /position\.nodeId === root\.currentNodeId/)
assert.match(engineControllerHeader,
             /Q_PROPERTY\(int candidateCount READ candidateCount NOTIFY candidatesChanged\)/)
assert.match(mainSource, /largeCandidateUiThreshold:\s*1000/)
assert.match(mainSource, /largeCandidateUiIntervalMs:\s*1000/)
assert.match(mainSource,
             /function flushEngineCandidateUpdate\(\)[\s\S]*?var candidateSnapshot = engineController\.candidates/)
assert.match(mainSource,
             /function scheduleEngineCandidateUpdate\(\)[\s\S]*?engineController\.candidateCount/)
assert.match(mainSource,
             /function scheduleEngineCandidateUpdate\(\)\s*\{\s*if \(applicationShutdownPrepared/)
assert.match(mainSource,
             /if \(!largeCandidateUiUpdateTimer\.running\)[\s\S]*?largeCandidateUiUpdateTimer\.start\(\)/)
assert.match(mainSource,
             /function onCandidatesChanged\(\)[\s\S]*?root\.scheduleEngineCandidateUpdate\(\)/)
assert.match(mainSource, /EngineSpeed\.totalVisits\(engineCandidates\)/)
assert.match(mainSource,
             /function stopApplicationTimersForShutdown\(\)[\s\S]*?largeCandidateUiUpdateTimer\.stop\(\)/)

const candidateUpdateFunction = mainSource.slice(
    mainSource.indexOf("function applyEngineCandidateUpdate(candidates, revision)"),
    mainSource.indexOf("function rebuildEngineCandidateItems()")
)
assert.doesNotMatch(candidateUpdateFunction, /cloneCandidateList/)
assert.match(boardSceneSource,
             /!showCandidateText && candidate\.displayIndex > 9[\s\S]*?simpleMarkerBuckets/)
assert.match(boardSceneSource,
             /simpleMarkerBucketKeys\.sort[\s\S]*?ctx\.fill\(\)[\s\S]*?ctx\.stroke\(\)/)
assert.match(mainSource, /function cancelActiveGenmoveRequest\(\)/)
assert.match(mainSource, /if \(!engineController\.ready\)/)
assert.match(mainSource, /engineInitialCommandsPendingForId/)
assert.match(mainSource, /property int aiMoveMode:\s*aiMoveModeGtp/)
assert.match(mainSource, /property bool hideAnalysisDuringPlay:\s*true/)
assert.match(mainSource,
             /function analysisPresentationVisible\(\)[\s\S]*?!hideAnalysisDuringPlay[\s\S]*?aiMoveMode === aiMoveModeAnalyze/)
assert.match(settingsDialogSource, /text:\s*app\.trText\("hideAnalysisDuringPlay"\)/)
assert.match(settingsStoreSource, /"hideAnalysisDuringPlay"/)
assert.match(boardSceneSource,
             /visible:\s*app\.analysisPresentationVisible\(\)[\s\S]*?app\.engineCandidateItems\.length > 0/)
assert.match(infoPanelSource,
             /readonly property bool winrateGraphVisible:\s*app\.analysisPresentationVisible\(\)/)
assert.match(infoPanelSource,
             /id:\s*candidateTable\s*visible:\s*app\.analysisPresentationVisible\(\)/)
assert.match(mainSource,
             /if \(aiMoveMode === aiMoveModeAnalyze\)\s*\{\s*requestAiAnalysisMove\(\)/)
assert.match(mainSource, /EnginePlay\.limitReached\(/)
assert.match(mainSource, /function activeAiAnalysisPositionMatches\(\)/)
assert.match(mainSource, /aiAnalysisMoveTimer\.stop\(\)/)
assert.match(mainSource, /id:\s*aiAnalysisWatchdogTimer/)
assert.match(mainSource, /function handleAiAnalysisWatchdogTimeout\(\)/)
assert.match(mainSource, /property bool engineAnalysisRequestValid:\s*false/)
assert.match(mainSource, /EnginePlay\.limitChangeAction\(/)
assert.match(mainSource,
             /function deferAnalysisCommandFailure\(analysisRequestId,\s*line\)/)
assert.match(mainSource,
             /function onAnalysisCommandFailed\(analysisRequestId,\s*line\)/)
assert.match(mainSource,
             /candidate && candidate\.winrate !== undefined[\s\S]*?!isFinite\(rawWinrate\)/)
assert.match(mainSource,
             /gameRuleMode === gameRuleGo && ownershipEnabled[\s\S]*?ownership true/)
assert.match(mainSource,
             /kata-analyze " \+ player \+ " " \+ interval/)
assert.match(mainSource, /Ownership\.normalized\(/)
assert.match(boardSceneSource, /id:\s*ownershipCanvas/)
assert.match(boardSceneSource, /Ownership\.pointForIndex\(/)
assert.match(boardSceneSource,
             /onCoordinateDisplayModeChanged\(\)\s*\{\s*ownershipCanvas\.requestVisiblePaint\(\)/)
assert.match(settingsStoreSource, /settingValue\(settings,\s*"aiMoveMode"/)
assert.match(settingsStoreSource,
             /settingValue\([\s\S]*?"analysisSecondsPerMove"/)
assert.match(settingsStoreSource,
             /settings\.setValue\("analysisSecondsPerMove",\s*app\.analysisSecondsPerMove\)/)
assert.match(settingsStoreSource,
             /settings\.setValue\("analysisTotalVisitsPerMove"/)
assert.doesNotMatch(settingsStoreSource, /ownershipEnabled/)
assert.match(mainSource,
             /onGameRuleModeChanged:[\s\S]*?gameRuleMode !== gameRuleGo[\s\S]*?ownershipEnabled = false/)
assert.match(settingsDialogSource,
             /text:\s*app\.trText\("showOwnership"\)[\s\S]*?enabled:\s*app\.gameRuleMode === app\.gameRuleGo/)
assert.doesNotMatch(settingsDialogSource, /ownershipGoOnlyTip/)
assert.doesNotMatch(analysisToolbarSource, /ownershipGoOnlyTip/)
assert.ok(settingsDialogSource.indexOf('app.trText("resignConsecutive")')
          < settingsDialogSource.indexOf('app.trText("showOwnership")'))
assert.match(settingsDialogSource, /app\.trText\("movesUnit"\)/)
assert.match(mainSource,
             /engineOwnershipBoardSignature === engineBoardSignature\(\)/)
assert.match(mainSource,
             /engineOwnershipKomiSignature === engineKomiSignature\(\)/)
assert.match(mainSource,
             /engineOwnershipEngineSignature === engineAnalysisSourceSignature\(\)/)
assert.match(engineControllerHeader,
             /Q_PROPERTY\(QVariantList ownership READ ownership NOTIFY candidatesChanged\)/)
assert.match(engineControllerHeader,
             /void analysisCommandFailed\(int analysisRequestId,\s*const QString &line\)/)

assert.doesNotMatch(engineCommunicationSource, /\bListView\s*\{/)
assert.match(engineCommunicationSource, /Basic\.TextArea\s*\{/)
assert.match(engineCommunicationSource, /persistentSelection:\s*true/)
assert.match(engineCommunicationSource, /selectByKeyboard:\s*true/)
assert.match(engineCommunicationSource, /function pauseLogFollowing\(\)/)
assert.match(engineCommunicationSource, /function resumeLogFollowing\(\)/)
assert.match(engineCommunicationSource, /logCharacterCount > 1048576 \? 750/)
assert.match(engineCommunicationSource, /logModel\.count > 500 \? 80 : 40/)
assert.match(engineCommunicationSource,
             /if\s*\(!logRefreshTimer\.running\)\s*logRefreshTimer\.start\(\)/)
assert.doesNotMatch(engineCommunicationSource, /logRefreshTimer\.restart\(\)/)
assert.doesNotMatch(engineCommunicationSource,
                    /onActiveFocusChanged:\s*pauseLogFollowing\(\)/)
assert.match(engineCommunicationSource, /engineLogAutoScrollPaused/)
assert.match(engineCommunicationSource, /engineLogViewLatest/)
assert.match(engineCommunicationSource,
             /engineLogViewLatest"\)\s*\+\s*"\("\s*\+\s*engineCommunicationDialog\.newMessageCount/)
assert.match(engineCommunicationSource,
             /if \(\(logChangeMask & visibleStreamMask\) === 0\)\s*return/)
assert.match(engineCommunicationSource,
             /Math\.min\(stdoutArrivalDelta,\s*stdoutRetainedCount\)/)
assert.match(engineCommunicationSource, /font\.family:\s*app\.coordinateFontFamily/)
assert.match(engineCommunicationSource, /font\.weight:\s*Font\.Medium/)
assert.match(engineCommunicationSource, /function reconcileLogPosition\(\)/)

console.log("frontend rendering tests passed")
