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

function activeVariationNodes(app) {
    var path = app.nodePath(app.currentNodeId).slice()
    var seen = ({})
    for (var i = 0; i < path.length; ++i) {
        if (path[i])
            seen[String(path[i].id)] = true
    }

    var node = app.currentNode()
    while (node && node.children && node.children.length > 0) {
        var child = app.nodeById(node.children[0])
        if (!child || seen[String(child.id)])
            break
        path.push(child)
        seen[String(child.id)] = true
        node = child
    }
    return path
}

function winrateHistoryData(app) {
    var points = []
    var maximumMove = 0
    var path = activeVariationNodes(app)
    for (var i = 0; i < path.length; ++i) {
        var node = path[i]
        maximumMove = Math.max(maximumMove, Number(node.moveNumber) || 0)
        if (node.analysisBlackWinrate !== undefined && node.analysisBlackWinrate >= 0)
            points.push({ "move": node.moveNumber, "winrate": node.analysisBlackWinrate })
    }
    return {
        "points": points,
        "maximumMove": maximumMove,
        "currentMove": Math.max(0, Number(app.currentMoveNumberValue()) || 0)
    }
}

function winrateHistoryPoints(app) {
    return winrateHistoryData(app).points
}

function engineWinratePlaceholderActive(app) {
    return app.analysisPresentationVisible() && !currentAnalysisHasWinrate(app)
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
