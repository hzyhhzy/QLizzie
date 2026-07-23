.pragma library

function recordCurrentAnalysisFromCandidates(app) {
    if (app.engineCandidates.length <= 0)
        return
    var node = app.currentNode()
    if (!node)
        return
    if (app.recordAnalysisWinrateForNode(node, app.engineCandidates, app.currentPlayer))
        app.gameNodes = app.gameNodes.slice()
}

function currentAnalysisHasWinrate(app) {
    var node = app.currentNode()
    return !!node && node.analysisBlackWinrate !== undefined && node.analysisBlackWinrate >= 0
}

function currentAnalysisBlackWinrate(app) {
    var node = app.currentNode()
    return currentAnalysisHasWinrate(app) ? node.analysisBlackWinrate : 50
}

function currentAnalysisWhiteWinrate(app) {
    return 100 - currentAnalysisBlackWinrate(app)
}

function winrateHistoryPoints(app) {
    var points = []
    var path = app.nodePath(app.currentNodeId)
    for (var i = 0; i < path.length; ++i) {
        var node = path[i]
        if (node.analysisBlackWinrate !== undefined && node.analysisBlackWinrate >= 0)
            points.push({ "move": node.moveNumber, "winrate": node.analysisBlackWinrate })
    }
    return points
}

function engineWinratePlaceholderActive(app) {
    return app.analysisModeActive() && !currentAnalysisHasWinrate(app)
}

function engineWinratePlaceholderText(app, engineController) {
    if (app.engineDisabled)
        return app.trText("engineNoEngineMode")
    if (app.enginePaused)
        return app.trText("enginePaused")
    if (app.engineLoading)
        return app.trText("engineLoading")
    if (engineController && engineController.failed)
        return engineFailureMessage(app, engineController)
    if (app.engineCandidateItems.length <= 0)
        return app.trText("engineNoCandidates")
    return ""
}

function engineCandidateSummaryText(app) {
    if (app.engineCandidateItems.length <= 0)
        return app.trText("engineNoCandidates")
    var best = app.engineCandidateItems[0]
    var moveText = best.displayMoveText === undefined
                 ? app.coordinateText(best.x, best.y)
                 : String(best.displayMoveText)
    return app.trText("engineBestMove") + ": " + moveText + " " + best.winrateText
}

function engineDotColor(app, engineController) {
    if (app.engineDisabled)
        return "#8d969c"
    if (app.enginePaused || (engineController && engineController.failed))
        return "#d64238"
    if (app.engineLoading)
        return "#b5bec4"
    if (engineController && engineController.running)
        return "#25b56f"
    return "#9aa5ab"
}

function engineNoticeVisible(app, engineController) {
    if (app.engineNoticeDismissed)
        return false
    if (app.engineFailureNoticeText && app.engineFailureNoticeText.length > 0)
        return true
    if (app.engineDisabled)
        return false
    return app.engineLoading || (engineController && engineController.failed)
}

function engineNoticeText(app, engineController) {
    if (app.engineFailureNoticeText && app.engineFailureNoticeText.length > 0)
        return app.engineFailureNoticeText
    if (engineController && engineController.failed)
        return engineFailureMessage(app, engineController)
    return app.trText("engineStartingNotice")
}

function engineNoticeFillColor(app, engineController) {
    return (app.engineFailureNoticeText && app.engineFailureNoticeText.length > 0)
            || (engineController && engineController.failed) ? "#fff1ee" : "#eef5f8"
}

function engineNoticeBorderColor(app, engineController) {
    return (app.engineFailureNoticeText && app.engineFailureNoticeText.length > 0)
            || (engineController && engineController.failed) ? "#d0695f" : "#8fb7c6"
}

function engineNoticeTextColor(app, engineController) {
    return (app.engineFailureNoticeText && app.engineFailureNoticeText.length > 0)
            || (engineController && engineController.failed) ? "#641a14" : "#183643"
}

function engineFailureMessage(app, engineController) {
    if (engineController && engineController.failureKind === "emptyCommand")
        return app.trText("engineFailureEmptyCommand")
    if (engineController && engineController.failureKind === "missingProgram")
        return app.trText("engineFailureMissingProgram")
    return app.trText("engineFailedNotice")
}
