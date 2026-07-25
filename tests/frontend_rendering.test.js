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
const engineCommunicationSource = fs.readFileSync(
    path.join(root, "app", "qml", "EngineCommunicationWindow.qml"),
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
assert.match(mainSource, /messages\.length > 2/)
assert.match(mainSource, /interval:\s*5000/)
assert.match(mainSource, /enabled:\s*false/)
assert.match(mainSource, /function onGtpErrorResponse\(line\)/)
assert.match(mainSource,
             /var ignoredGtpError = root\.ignoreGtpErrors[\s\S]*?if \(ignoredGtpError\)\s*return/)
assert.match(hiddenSettingsSource, /text:\s*app\.trText\("ignoreGtpErrors"\)/)
assert.match(settingsStoreSource, /settingBool\(settings,\s*"ignoreGtpErrors"/)
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
assert.match(mainSource, /function prepareApplicationShutdown\(\)/)
assert.match(mainSource, /function closeAuxiliaryWindowsForShutdown\(\)/)
assert.match(mainSource, /engineCommunicationWindow\.visible = false/)
assert.match(mainSource, /beginnerTutorialDialog\.visible = false/)
assert.match(mainSource, /function stopApplicationTimersForShutdown\(\)/)
assert.match(mainSource,
             /function prepareApplicationShutdown\(\)[\s\S]*?savePersistentSettings\(\)[\s\S]*?appSettings\.sync\(\)/)
assert.match(mainSource,
             /if \(!visible && applicationShutdownPrepared\)\s*Qt\.callLater\(Qt\.quit\)/)
assert.match(appWindowDialogSource,
             /!appWindowDialog\.owningWindow\.visible[\s\S]*?appWindowDialog\.closeDialog\(\)/)
assert.match(engineCommunicationSource,
             /function onVisibleChanged\(\)\s*\{\s*if \(!app\.visible\)\s*engineCommunicationDialog\.visible = false/)
assert.match(beginnerTutorialSource,
             /function onVisibleChanged\(\)\s*\{\s*if \(!app\.visible\)\s*tutorialDialog\.visible = false/)
assert.match(applicationMainSource,
             /QCoreApplication::aboutToQuit[\s\S]*?EngineController::shutdown/)
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
assert.match(mainSource, /function markGeneratedMoveSynced\(\)/)
assert.match(mainSource, /if \(!root\.applyGeneratedMove\(move\)\)/)
assert.match(mainSource, /position\.generation === root\.gameTreeGeneration/)
assert.match(mainSource, /position\.nodeId === root\.currentNodeId/)
assert.match(mainSource, /function cancelActiveGenmoveRequest\(\)/)
assert.match(mainSource, /if \(!engineController\.ready\)/)
assert.match(mainSource, /engineInitialCommandsPendingForId/)
assert.match(mainSource, /property int aiMoveMode:\s*aiMoveModeGtp/)
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
