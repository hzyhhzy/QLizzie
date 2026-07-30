.pragma library
.import "GameRules.js" as GameRules

function buildGomokuWinLineItems(app, map) {
    var runs = GameRules.buildGomokuWinRuns(map, app.boardDims(), app.gameRuleMode, app.gomokuRuleMode)
    var items = []
    for (var i = 0; i < runs.length; ++i) {
        var run = runs[i]
        items.push({
            "startX": run.startX,
            "startY": run.startY,
            "endX": run.endX,
            "endY": run.endY,
            "player": run.player
        })
    }
    return items
}

function buildHexWinPath(app, map) {
    return GameRules.buildHexWinPath(map, app.boardDims(), app.gameRuleMode)
}

function nextMoveMarkerItems(app) {
    var current = app.currentNode()
    var children = current ? (current.children || []) : []
    var items = []
    var itemByKey = ({})
    for (var i = 0; i < children.length; ++i) {
        var child = app.nodeById(children[i])
        if (!child || child.isPass === true
                || !app.pointInRuleBoard(child.x, child.y))
            continue

        var key = app.keyFor(child.x, child.y)
        var existing = itemByKey[key]
        if (existing) {
            if (i === 0)
                existing.mainBranch = true
            continue
        }

        var item = {
            "x": child.x,
            "y": child.y,
            "player": child.player,
            "mainBranch": i === 0
        }
        items.push(item)
        itemByKey[key] = item
    }
    return items
}

function stoneOverlayVisible(app, moveNumber, lastMove) {
    if (app.moveNumberDisplayMode === app.moveNumberModeHidden)
        return lastMove
    if (app.moveNumberDisplayMode === app.moveNumberModeLastOnly)
        return lastMove
    return moveNumber > 0
}

function stoneNumberVisible(app, moveNumber, lastMove) {
    if (app.moveNumberDisplayMode === app.moveNumberModeHidden)
        return false
    if (app.moveNumberDisplayMode === app.moveNumberModeLastOnly)
        return lastMove
    return moveNumber > 0
}

function stoneNumberColor(player, lastMove) {
    return player === 1 ? "#f5f7f8" : "#1a252d"
}

function stoneNumberCanvasFont(app, size, bold) {
    var family = String(app.coordinateFontFamily).replace(/"/g, "")
    return (bold ? "700 " : "400 ") + Math.max(1, Math.round(size))
         + "px \"" + family + "\", sans-serif"
}

function stoneNumberBaseFontSize(app, ctx, text, radius) {
    var label = String(text)
    var digits = Math.max(1, label.length)
    var digitFactor = digits <= 1 ? 1.18
                    : digits === 2 ? 1.02
                    : digits === 3 ? 0.86
                    : Math.max(0.58, 0.86 - (digits - 3) * 0.12)
    var baseSize = Math.min(radius * digitFactor, radius * 1.42)
    var maxWidth = radius * 1.78
    if (ctx) {
        ctx.save()
        ctx.font = stoneNumberCanvasFont(app, baseSize, true)
        var measuredWidth = Math.max(1, ctx.measureText(label).width)
        ctx.restore()
        if (measuredWidth > maxWidth)
            baseSize *= maxWidth / measuredWidth
    }
    return Math.max(1, baseSize)
}

function stoneNumberFontSize(app, ctx, text, radius) {
    return Math.max(1, stoneNumberBaseFontSize(app, ctx, text, radius) * Number(app.moveNumberLabelScale))
}

function stoneNumberMaxWidth(app, radius) {
    return radius * 1.86 * Math.max(1, Number(app.moveNumberLabelScale))
}

function stoneNumberOffsetY(fontSize) {
    return Math.max(1, Number(fontSize) * 0.08)
}
