.pragma library
.import "SgfUtils.js" as SgfUtils
.import "CandidateAnalysis.js" as CandidateAnalysis

function build(app) {
    return SgfUtils.buildSgf(app.gameNodes, app.gameRuleMode,
                             app.boardSizeX, app.boardSizeY, app.gameRuleText())
}

function parse(app, text) {
    return SgfUtils.parseSgf(text, {
        "minBoardSize": app.minBoardSize,
        "maxBoardSize": app.maxBoardSize,
        "defaultRuleMode": app.gameRuleMode,
        "ignoreRuleMode": false,
        "gameRuleGo": app.gameRuleGo,
        "gameRuleGomoku": app.gameRuleGomoku,
        "gameRuleHex": app.gameRuleHex
    })
}

function finalizeAnalysisCaches(app) {
    var nodes = app.gameNodes || []
    var boardSignature = app.engineBoardSignature()
    var komiSignature = app.engineKomiSignature()
    var signatureChanged = false
    for (var i = 0; i < nodes.length; ++i) {
        var node = nodes[i]
        if (!node || !node.analysisCandidates || node.analysisCandidates.length <= 0)
            continue
        if (!node.analysisCandidateBoardSignature || node.analysisCandidateBoardSignature.length <= 0) {
            node.analysisCandidateBoardSignature = boardSignature
            signatureChanged = true
        }
        if (!node.analysisCandidateKomiSignature || node.analysisCandidateKomiSignature.length <= 0) {
            node.analysisCandidateKomiSignature = komiSignature
            signatureChanged = true
        }
        if (node.analysisBlackWinrate === undefined || Number(node.analysisBlackWinrate) < 0)
            CandidateAnalysis.recordAnalysisWinrateForNode(app, node,
                                                           node.analysisCandidates,
                                                           app.playerToMoveAfterNode(node))
    }
    if (signatureChanged)
        app.analysisRevision += 1
}

function applyParsed(app, parsed, url) {
    var targetRuleMode = parsed.ruleMode === undefined || parsed.ruleMode === null
                         ? app.gameRuleMode : Number(parsed.ruleMode)
    var ruleMismatch = targetRuleMode !== Number(app.gameRuleMode)
    if (ruleMismatch && !app.ruleModeAllowedForPackage(targetRuleMode)) {
        app.statusMode = "message"
        app.statusMessage = app.trText("sgfLoadFailed") + ": " + parsed.ruleName
        var currentRule = SgfUtils.sgfGameInfo(app.gameRuleMode)
        app.openSgfGameTypeWarning(parsed.gameId, currentRule.gameId,
                                   parsed.ruleName, currentRule.ruleName)
        return
    }
    if (!app.boardDimensionsAllowedForPackage(parsed.boardSizeX, parsed.boardSizeY)) {
        app.statusMode = "message"
        app.statusMessage = app.trText("sgfLoadFailed") + ": "
                            + app.packageBoardSizeRejectText(parsed.boardSizeX, parsed.boardSizeY)
        app.focusBoardInput()
        return
    }
    if (!app.boardDimensionsAllowedForRule(targetRuleMode, parsed.boardSizeX, parsed.boardSizeY)) {
        app.statusMode = "message"
        app.statusMessage = app.trText("sgfLoadFailed") + ": "
                            + app.ruleBoardSizeRejectText(targetRuleMode,
                                                          parsed.boardSizeX,
                                                          parsed.boardSizeY)
        app.focusBoardInput()
        return
    }
    var validation = app.validateParsedGame(parsed)
    if (!validation.ok) {
        app.statusMode = "message"
        app.statusMessage = app.trText("sgfLoadFailed") + ": "
                            + app.trText("invalidGameRecordNode") + " #"
                            + validation.nodeId + ": " + validation.reason
        app.focusBoardInput()
        return
    }
    if (ruleMismatch && !app.activateRuleModeForSgf(targetRuleMode)) {
        app.statusMode = "message"
        app.statusMessage = app.trText("sgfLoadFailed") + ": " + parsed.ruleName
        app.focusBoardInput()
        return
    }
    app.resetEngineSyncState()
    app.boardSizeX = parsed.boardSizeX
    app.boardSizeY = parsed.boardSizeY
    app.gameTreeGeneration += 1
    app.gameNodes = parsed.nodes
    app.nextNodeId = parsed.nextNodeId
    app.currentNodeId = 0
    finalizeAnalysisCaches(app)
    app.clearHover(true)
    app.rebuildPositionFromNode(app.currentNodeId)
    app.rebuildTreeLayout()
    app.gotoLastMove()
    app.gameDirty = false
    app.statusMode = "message"
    app.statusMessage = app.trText("sgfLoaded") + ": " + url
    app.focusBoardInput()
}

function saveToFile(app, fileIo, url) {
    var ok = fileIo.writeTextFile(url, build(app))
    if (ok) {
        app.gameDirty = false
        app.statusMode = "message"
        app.statusMessage = app.trText("sgfSaved") + ": " + url
    } else {
        app.statusMode = "message"
        app.statusMessage = app.trText("sgfSaveFailed") + ": " + fileIo.lastError
    }
    return ok
}

function loadFromFile(app, fileIo, url) {
    var text = fileIo.readTextFile(url)
    if (fileIo.lastError !== "") {
        app.statusMode = "message"
        app.statusMessage = app.trText("sgfLoadFailed") + ": " + fileIo.lastError
        app.focusBoardInput()
        return
    }
    var parsed = parse(app, text)
    if (!parsed.ok) {
        app.statusMode = "message"
        app.statusMessage = app.trText("sgfLoadFailed") + ": " + parsed.error
        app.focusBoardInput()
        return
    }
    applyParsed(app, parsed, url)
}
