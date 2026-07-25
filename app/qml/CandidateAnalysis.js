.pragma library
.import "GameRules.js" as GameRules

function visitCount(candidate) {
    if (!candidate)
        return 0
    var visits = Number(candidate.visits)
    return isNaN(visits) ? 0 : visits
}

function winrateValue(app, candidate) {
    if (!candidate || candidate.winrate === undefined)
        return 0
    var value = Number(candidate.winrate)
    if (isNaN(value))
        return 0
    return app.clamp(value * 100, 0, 100)
}

function scoreValue(app, candidate) {
    if (!candidate || candidate.scoreMean === undefined)
        return NaN
    var value = Number(candidate.scoreMean)
    return isNaN(value) ? NaN : value
}

function formatCandidateNumber(app, value, decimals, showPercent) {
    var number = Number(value)
    if (isNaN(number))
        return ""
    var displayValue = number
    var text = displayValue.toFixed(Math.round(app.clamp(decimals, 0, 2)))
    if (showPercent)
        text += "%"
    return text
}

function winrateText(app, candidate) {
    if (!candidate || candidate.winrate === undefined)
        return ""
    return formatCandidateNumber(app,
                                 winrateValue(app, candidate),
                                 app.candidateWinrateDecimals,
                                 app.candidateWinrateShowPercent)
}

function scoreDisplayEnabled(app) {
    return app.candidateScoreLabelVisible
}

function scoreTitle(app) {
    return app.candidateScoreTitleMode === app.candidateScoreTitleDrawRate ? app.trText("candidateDrawRate")
                                                                           : app.trText("candidateScoreMean")
}

function scoreText(app, candidate) {
    if (!candidate || !scoreDisplayEnabled(app))
        return ""
    var value = scoreValue(app, candidate)
    if (isNaN(value))
        return ""
    return formatCandidateNumber(app,
                                 value,
                                 app.candidateScoreDecimals,
                                 app.candidateScoreShowPercent)
}

function labelLines(app, candidate) {
    var lines = []
    var winrateLabel = winrateText(app, candidate)
    if (app.candidateWinrateLabelVisible && winrateLabel.length > 0) {
        lines.push({
            "kind": 0,
            "text": winrateLabel,
            "fontSize": app.candidateWinrateFontSize,
            "color": String(app.candidateLabelTextColor),
            "bold": app.candidateWinrateBold
        })
    }
    if (app.candidateVisitsLabelVisible) {
        var visitsLabel = formatVisitCount(visitCount(candidate))
        if (visitsLabel.length > 0) {
            lines.push({
                "kind": 1,
                "text": visitsLabel,
                "fontSize": app.candidateVisitsFontSize,
                "color": String(app.candidateLabelTextColor),
                "bold": app.candidateVisitsBold
            })
        }
    }
    var scoreLabel = scoreText(app, candidate)
    if (scoreLabel.length > 0) {
        lines.push({
            "kind": 2,
            "text": scoreLabel,
            "fontSize": app.candidateScoreFontSize,
            "color": String(app.candidateLabelTextColor),
            "bold": app.candidateScoreBold
        })
    }
    if (lines.length <= 0 && winrateLabel.length > 0) {
        lines.push({
            "kind": 0,
            "text": winrateLabel,
            "fontSize": app.candidateWinrateFontSize,
            "color": String(app.candidateLabelTextColor),
            "bold": app.candidateWinrateBold
        })
    }
    return lines
}

function labelLineOffset(app, kind) {
    if (kind === 0)
        return app.candidateWinrateOffsetY
    if (kind === 1)
        return app.candidateVisitsOffsetY
    return app.candidateScoreOffsetY
}

function labelLineHeight(line) {
    return Math.max(16, Number(line.fontSize) * 0.88)
}

function labelScale(markerRadius) {
    return Math.max(0.12, markerRadius * 2 / 151)
}

function labelGap(markerRadius) {
    return 2 * labelScale(markerRadius)
}

function ringRadius(markerRadius) {
    return markerRadius * 1.02
}

function ringLineWidthForRadius(app, markerRadius) {
    return Math.max(1, app.candidateRingLineWidth * labelScale(markerRadius))
}

function rankLabelText(app, displayIndex) {
    if (!app.candidateRankLabelVisible)
        return ""
    var rank = Math.round(Number(displayIndex))
    return rank >= 1 && rank <= 9 ? String(rank) : ""
}

function labelTotalHeight(lines) {
    if (!lines || lines.length <= 0)
        return 0
    var totalHeight = 0
    for (var i = 0; i < lines.length; ++i)
        totalHeight += labelLineHeight(lines[i])
    return totalHeight + 2 * Math.max(0, lines.length - 1)
}

function labelLineCenterY(lines, lineIndex, height) {
    if (!lines || lineIndex < 0 || lineIndex >= lines.length)
        return height * 0.5
    var gap = 2
    var y = (height - labelTotalHeight(lines)) * 0.5
    for (var i = 0; i < lineIndex; ++i)
        y += labelLineHeight(lines[i]) + gap
    return y + labelLineHeight(lines[lineIndex]) * 0.5
}

function labelScaledTotalHeight(lines, markerRadius) {
    if (!lines || lines.length <= 0)
        return 0
    var scale = labelScale(markerRadius)
    var totalHeight = 0
    for (var i = 0; i < lines.length; ++i)
        totalHeight += labelLineHeight(lines[i]) * scale
    return totalHeight + labelGap(markerRadius) * Math.max(0, lines.length - 1)
}

function drawLabelLines(app, ctx, lines, centerX, centerY, markerRadius, overrideColor) {
    if (!lines || lines.length <= 0)
        return

    var scale = labelScale(markerRadius)
    var y = centerY - labelScaledTotalHeight(lines, markerRadius) * 0.5
    ctx.textAlign = "center"
    ctx.textBaseline = "middle"
    for (var lineIndex = 0; lineIndex < lines.length; ++lineIndex) {
        var line = lines[lineIndex]
        var lineHeight = labelLineHeight(line) * scale
        var fontSize = Math.max(7, Number(line.fontSize) * scale)
        ctx.font = (line.bold ? "700 " : "400 ") + Math.round(fontSize) + "px sans-serif"
        ctx.fillStyle = overrideColor || line.color || String(app.candidateLabelTextColor)
        ctx.fillText(line.text || "",
                     centerX,
                     y + lineHeight * 0.5 - labelLineOffset(app, line.kind) * scale,
                     Math.max(8, markerRadius * 2 - 4))
        y += lineHeight + labelGap(markerRadius)
    }
}

function drawRankLabel(app, ctx, centerX, centerY, markerRadius, rankText) {
    if (!app.candidateRankLabelVisible || rankText === undefined || String(rankText).length <= 0)
        return

    var text = String(rankText)
    var squareWidth = markerRadius * 2 / Math.max(0.1, Number(app.stoneScale))
    var anchorX = centerX + squareWidth * 0.43 + (text === "1" ? 1 : 0)
    var anchorY = centerY - squareWidth * 0.358 - (text === "1" ? 1 : 0)
    var maxFontHeight = squareWidth * 0.36
    var maxFontWidth = squareWidth * 0.39
    var fontFamily = String(app.coordinateFontFamily).replace(/"/g, "")

    ctx.save()
    var fontSize = Math.max(1, maxFontHeight)
    ctx.font = "400 " + Math.round(fontSize) + "px \"" + fontFamily + "\", sans-serif"
    var measured = ctx.measureText(text)
    if (measured.width > maxFontWidth && measured.width > 0) {
        fontSize *= maxFontWidth / measured.width
        ctx.font = "400 " + Math.round(fontSize) + "px \"" + fontFamily + "\", sans-serif"
        measured = ctx.measureText(text)
    }

    var textWidth = Math.max(1, measured.width)
    var ascent = measured.actualBoundingBoxAscent || fontSize * 0.72
    var descent = measured.actualBoundingBoxDescent || fontSize * 0.12
    var textHeight = Math.max(1, ascent - descent)
    var x1 = anchorX - textWidth * 0.5
    var y1 = anchorY

    ctx.globalAlpha = 1
    ctx.fillStyle = "#ffa500"
    ctx.fillRect(x1, y1 - textHeight, textWidth, textHeight + Math.max(1, textHeight / 12))
    ctx.fillStyle = "#15191c"
    ctx.textAlign = "left"
    ctx.textBaseline = "alphabetic"
    ctx.fillText(text, x1, y1)
    ctx.restore()
}

function drawMarker(app, ctx, centerX, centerY, markerRadius, lines, options) {
    options = options || ({})

    var drawBackground = options.drawBackground === undefined ? true : !!options.drawBackground
    var drawOutline = !!options.drawOutline
    var drawRing = !!options.drawRing && app.candidateRingVisible
    var fillOpacity = options.fillOpacity === undefined ? 1 : Number(options.fillOpacity)
    var outlineOpacity = options.outlineOpacity === undefined ? 1 : Number(options.outlineOpacity)
    var ringOpacity = options.ringOpacity === undefined ? 1 : Number(options.ringOpacity)

    ctx.save()
    if (drawBackground) {
        ctx.globalAlpha = ctx.globalAlpha * fillOpacity
        ctx.fillStyle = String(options.fillColor || "#00c8ff")
        ctx.beginPath()
        ctx.arc(centerX, centerY, markerRadius, 0, Math.PI * 2)
        ctx.fill()
    }
    ctx.restore()

    ctx.save()
    if (drawOutline) {
        ctx.globalAlpha = ctx.globalAlpha * outlineOpacity
        ctx.strokeStyle = String(options.outlineColor || "#000000")
        ctx.lineWidth = Math.max(1, markerRadius / 26.5)
        ctx.beginPath()
        ctx.arc(centerX, centerY, markerRadius, 0, Math.PI * 2)
        ctx.stroke()
    }
    ctx.restore()

    ctx.save()
    if (drawRing) {
        ctx.globalAlpha = ctx.globalAlpha * ringOpacity
        ctx.strokeStyle = String(options.ringColor || "#f01818")
        ctx.lineWidth = ringLineWidthForRadius(app, markerRadius)
        ctx.beginPath()
        ctx.arc(centerX, centerY, ringRadius(markerRadius), 0, Math.PI * 2)
        ctx.stroke()
    }
    ctx.restore()

    if (lines && lines.length > 0) {
        drawLabelLines(app, ctx, lines, centerX, centerY, markerRadius, options.textColor)
    } else if (options.fallbackText !== undefined) {
        ctx.save()
        ctx.fillStyle = String(options.fallbackColor || app.candidateLabelTextColor)
        ctx.font = "700 " + Math.round(options.fallbackFontSize || Math.max(8, markerRadius * 0.8)) + "px sans-serif"
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        ctx.fillText(String(options.fallbackText), centerX, centerY, Math.max(8, markerRadius * 2 - 4))
        ctx.restore()
    }

    drawRankLabel(app, ctx, centerX, centerY, markerRadius, options.rankText)
}

function markerRadius(app, width, height) {
    var side = Math.min(width, height)
    var radius = side * 0.48
    var ringSafeRadius = (side * 0.5 - 1) / (1.02 + app.candidateRingLineWidth / 151)
    return Math.max(1, Math.min(radius, ringSafeRadius))
}

function hexComponent(app, value) {
    var text = Math.round(app.clamp(value, 0, 255)).toString(16)
    return text.length < 2 ? "0" + text : text
}

function hsbColorHex(app, hue, saturation, brightness) {
    hue = ((Number(hue) % 1) + 1) % 1
    saturation = app.clamp(Number(saturation), 0, 1)
    brightness = app.clamp(Number(brightness), 0, 1)
    var r = brightness
    var g = brightness
    var b = brightness
    if (saturation > 0) {
        var h = hue * 6
        var sector = Math.floor(h)
        var fraction = h - sector
        var p = brightness * (1 - saturation)
        var q = brightness * (1 - saturation * fraction)
        var t = brightness * (1 - saturation * (1 - fraction))
        switch (sector) {
        case 0:
            r = brightness; g = t; b = p
            break
        case 1:
            r = q; g = brightness; b = p
            break
        case 2:
            r = p; g = brightness; b = t
            break
        case 3:
            r = p; g = q; b = brightness
            break
        case 4:
            r = t; g = p; b = brightness
            break
        default:
            r = brightness; g = p; b = q
            break
        }
    }
    return "#" + hexComponent(app, r * 255) + hexComponent(app, g * 255) + hexComponent(app, b * 255)
}

function yzyAlphaRatio(app, visitRatio) {
    var ratio = app.clamp(Number(visitRatio), 0.000001, 1)
    return Math.max(0, Math.log(ratio) / app.candidateYzyAlphaFactor + 1)
}

function markerColor(app, displayIndex, visitRatio) {
    if (displayIndex <= 1)
        return hsbColorHex(app, 0.5, 1.0, 0.85)
    var fraction = Math.pow(app.clamp(Number(visitRatio), 0, 1), 1 / app.candidateYzyColorRatio)
    var hue = (1 / 3) * fraction
    return hsbColorHex(app, hue, 1.0, 0.85)
}

function markerOpacity(app, displayIndex, visitRatio) {
    var alphaRatio = yzyAlphaRatio(app, visitRatio)
    var alpha = app.candidateYzyMinAlpha + (app.candidateYzyMaxAlpha - app.candidateYzyMinAlpha) * alphaRatio
    return app.clamp(alpha / 255, 0, 1)
}

function markerOutlineOpacity(app, visitRatio) {
    var alpha = 48 + 48 * yzyAlphaRatio(app, visitRatio)
    return app.clamp(alpha / 255, 0, 1)
}

function previewLabelLines(app, digitText) {
    var lines = []
    var decimals = Math.round(app.clamp(app.candidateWinrateDecimals, 0, 2))
    var digit = digitText === undefined ? "6" : String(digitText)
    var text = decimals === 0 ? digit + digit
             : decimals === 1 ? digit + digit + "." + digit
             : digit + digit + "." + digit + digit
    if (app.candidateWinrateShowPercent)
        text += "%"

    if (app.candidateWinrateLabelVisible) {
        lines.push({
            "kind": 0,
            "text": text,
            "fontSize": app.candidateWinrateFontSize,
            "color": String(app.candidateLabelTextColor),
            "bold": app.candidateWinrateBold
        })
    }
    if (app.candidateVisitsLabelVisible) {
        lines.push({
            "kind": 1,
            "text": digit + digit + "K",
            "fontSize": app.candidateVisitsFontSize,
            "color": String(app.candidateLabelTextColor),
            "bold": app.candidateVisitsBold
        })
    }
    if (scoreDisplayEnabled(app)) {
        var previewScore = Number(digit + "." + digit)
        lines.push({
            "kind": 2,
            "text": scoreText(app, { "scoreMean": previewScore }),
            "fontSize": app.candidateScoreFontSize,
            "color": String(app.candidateLabelTextColor),
            "bold": app.candidateScoreBold
        })
    }
    if (lines.length <= 0) {
        lines.push({
            "kind": 0,
            "text": text,
            "fontSize": app.candidateWinrateFontSize,
            "color": String(app.candidateLabelTextColor),
            "bold": app.candidateWinrateBold
        })
    }
    return lines
}

function formatVisitCount(value) {
    var visits = Number(value)
    if (isNaN(visits) || visits <= 0)
        return "0"
    if (visits >= 1000000000)
        return (visits / 1000000000).toFixed(visits >= 10000000000 ? 0 : 1) + "G"
    if (visits >= 1000000)
        return (visits / 1000000).toFixed(visits >= 10000000 ? 0 : 1) + "M"
    if (visits >= 1000)
        return (visits / 1000).toFixed(visits >= 10000 ? 0 : 1) + "K"
    return String(Math.round(visits))
}

function cloneCandidate(candidate) {
    var copy = ({})
    if (!candidate)
        return copy

    for (var key in candidate) {
        var value = candidate[key]
        if (Array.isArray(value)) {
            copy[key] = value.slice()
        } else if (value && typeof value === "object" && value.length !== undefined
                   && typeof value.slice === "function") {
            copy[key] = value.slice()
        } else {
            copy[key] = value
        }
    }
    return copy
}

function cloneCandidateList(candidates) {
    var copy = []
    if (!candidates)
        return copy
    for (var i = 0; i < candidates.length; ++i)
        copy.push(cloneCandidate(candidates[i]))
    return copy
}

function pvMoves(candidate) {
    if (!candidate)
        return []

    var moves = []
    var pv = candidate.pv || []
    for (var i = 0; i < pv.length; ++i) {
        var pvMove = String(pv[i]).trim()
        if (pvMove.length > 0)
            moves.push(pvMove)
    }
    return moves
}

function specialMoveKind(move) {
    var normalized = String(move === undefined || move === null ? "" : move).trim().toLowerCase()
    if (normalized === "pass" || normalized === "resign")
        return normalized
    return ""
}

function specialMoveText(app, moveKind) {
    if (moveKind === "pass")
        return app.trText("passMove")
    if (moveKind === "resign")
        return app.trText("resignMove")
    return ""
}

function candidateMoveText(app, candidate) {
    if (!candidate)
        return ""

    var moveKind = specialMoveKind(candidate.specialMove || candidate.move)
    if (moveKind !== "")
        return specialMoveText(app, moveKind)

    var point = null
    if (candidate.boardPoint === true && candidate.x !== undefined && candidate.y !== undefined) {
        point = { "x": Number(candidate.x), "y": Number(candidate.y) }
    } else {
        point = app.parseEngineCoordinate(candidate.move)
    }
    if (point)
        return app.coordinateText(point.x, point.y)
    return String(candidate.move === undefined || candidate.move === null ? "" : candidate.move)
}

function playCandidate(app, candidate) {
    if (!candidate)
        return false

    var moveKind = specialMoveKind(candidate.specialMove || candidate.move)
    if (moveKind === "pass") {
        app.passMove()
        return true
    }
    if (moveKind === "resign") {
        app.statusMode = "message"
        app.statusMessage = app.trText("engineSuggestsResign")
        return true
    }

    var point = null
    if (candidate.boardPoint === true && candidate.x !== undefined && candidate.y !== undefined) {
        point = { "x": Number(candidate.x), "y": Number(candidate.y) }
    } else {
        point = app.parseEngineCoordinate(candidate.move)
    }
    return !!point && app.placeStone(point.x, point.y) !== false
}

function playBestCandidate(app, candidates) {
    if (!candidates || candidates.length <= 0)
        return false
    return playCandidate(app, candidates[0])
}

function buildCandidateItems(app, candidates) {
    var sorted = []
    var needsSort = false
    var previousOrder = -Infinity
    for (var s = 0; s < candidates.length; ++s) {
        sorted.push(candidates[s])
        var currentOrder = candidates[s].order === undefined ? 0 : Number(candidates[s].order)
        if (currentOrder < previousOrder)
            needsSort = true
        previousOrder = currentOrder
    }
    if (needsSort) {
        sorted.sort(function(left, right) {
            var lo = left.order === undefined ? 0 : Number(left.order)
            var ro = right.order === undefined ? 0 : Number(right.order)
            return lo - ro
        })
    }

    var maxVisits = 0
    for (var m = 0; m < sorted.length; ++m)
        maxVisits = Math.max(maxVisits, visitCount(sorted[m]))

    var limit = app.candidateDisplayCount <= 0 ? sorted.length : Math.min(app.candidateDisplayCount, sorted.length)
    var threshold = maxVisits > 0 ? maxVisits * app.candidateMinVisitRatio : 0

    var items = []
    var itemMap = ({})
    var table = []
    for (var c = 0; c < sorted.length; ++c) {
        var candidate = sorted[c]
        var moveKind = specialMoveKind(candidate.move)
        var point = moveKind === "" ? app.parseEngineCoordinate(candidate.move) : null
        if (point || moveKind !== "") {
            var boardPoint = !!point
            var visits = visitCount(candidate)
            var visitRatio = maxVisits > 0 ? app.clamp(visits / maxVisits, 0, 1) : 1
            var rawWinrate = winrateValue(app, candidate)
            var qualified = c < limit && (maxVisits <= 0 || visits >= threshold)
            var item = {
                "x": boardPoint ? point.x : -1,
                "y": boardPoint ? point.y : -1,
                "key": boardPoint ? app.keyFor(point.x, point.y) : moveKind,
                "move": candidate.move,
                "specialMove": moveKind,
                "boardPoint": boardPoint,
                "order": candidate.order,
                "displayIndex": c + 1,
                "visits": visits,
                "visitRatio": visitRatio,
                "qualified": qualified,
                "boardVisible": boardPoint && (qualified || app.candidateShowFilteredMarkers),
                "opacity": boardPoint ? markerOpacity(app, c + 1, visitRatio) : 0,
                "color": boardPoint ? markerColor(app, c + 1, visitRatio) : "transparent",
                "outlineOpacity": boardPoint ? markerOutlineOpacity(app, visitRatio) : 0,
                "winrate": rawWinrate,
                "winrateText": winrateText(app, candidate),
                "scoreMean": scoreValue(app, candidate),
                "scoreText": scoreText(app, candidate),
                "pv": pvMoves(candidate),
                "labelLines": labelLines(app, candidate)
            }
            item.displayMoveText = candidateMoveText(app, item)
            items.push(item)
            itemMap[item.key] = item
            table.push({
                "row": c + 1,
                "key": item.key,
                "coordinate": item.displayMoveText,
                "winrateText": item.winrateText,
                "scoreText": item.scoreText,
                "visitsText": visits > 0 ? formatVisitCount(visits) : ""
            })
        }
    }
    return {
        "items": items,
        "itemMap": itemMap,
        "table": table
    }
}

function rebuildItems(app) {
    var built = buildCandidateItems(app, app.engineCandidates || [])
    app.engineCandidateItems = built.items
    app.engineCandidateItemMap = built.itemMap
    app.engineCandidateTableItems = built.table
    app.updateBestCandidateRing(built.items)
}

function resetDisplay(app) {
    app.engineCandidates = []
    app.engineCandidatesFromCache = false
    app.engineCandidateItems = []
    app.engineCandidateItemMap = ({})
    app.engineCandidateTableItems = []
    app.bestCandidateRingVisible = false
    app.bestCandidateRingKey = ""
    app.engineCandidateRevision += 1
}

function setDisplay(app, candidates, fromCache, revision) {
    // Candidate snapshots are immutable after capture, so the node cache and the
    // current display can safely share one list instead of cloning it again.
    app.engineCandidates = candidates || []
    app.engineCandidatesFromCache = fromCache === true
    if (revision === undefined)
        app.engineCandidateRevision += 1
    else
        app.engineCandidateRevision = revision
    rebuildItems(app)
}

function nodeAnalysisCacheUsable(app, node) {
    return !!node
           && node.analysisCandidates !== undefined
           && node.analysisCandidates.length > 0
           && node.analysisCandidateBoardSignature === app.engineBoardSignature()
           && node.analysisCandidateKomiSignature === app.engineKomiSignature()
}

function recordAnalysisWinrateForNode(app, node, candidates, playerToMove) {
    if (!node || !candidates || candidates.length <= 0)
        return false
    var best = candidates[0]
    if (!best || best.winrate === undefined)
        return false

    var blackWinrate = playerToMove === 1 ? winrateValue(app, best)
                                          : 100 - winrateValue(app, best)
    blackWinrate = app.clamp(blackWinrate, 0, 100)
    if (node.analysisBlackWinrate !== undefined
            && Math.abs(Number(node.analysisBlackWinrate) - blackWinrate) < 0.0001)
        return false
    node.analysisBlackWinrate = blackWinrate
    app.analysisRevision += 1
    return true
}

function cacheAnalysisCandidatesForNode(app, node, candidates, boardSignature, komiSignature) {
    if (!node || !candidates || candidates.length <= 0)
        return false

    node.analysisCandidates = candidates
    node.analysisCandidateBoardSignature = boardSignature || app.engineBoardSignature()
    node.analysisCandidateKomiSignature = komiSignature || app.engineKomiSignature()
    recordAnalysisWinrateForNode(app, node, node.analysisCandidates, app.playerToMoveAfterNode(node))
    return true
}

function showCachedAnalysisForCurrentNode(app) {
    var node = app.currentNode()
    if (!nodeAnalysisCacheUsable(app, node))
        return false
    setDisplay(app, node.analysisCandidates, true)
    return app.engineCandidateItems.length > 0
}

function applyEngineCandidateUpdate(app, candidates, revision) {
    if (app.engineAnalysisRequestValid === false
            || (!app.analysisModeActive() && app.aiAnalysisInFlight !== true)) {
        resetDisplay(app)
        return
    }

    var incoming = cloneCandidateList(candidates)
    if (incoming.length <= 0) {
        if (!showCachedAnalysisForCurrentNode(app))
            resetDisplay(app)
        return
    }

    app.engineLoading = false
    var targetId = app.engineAnalysisRequestNodeId >= 0 ? app.engineAnalysisRequestNodeId
                                                        : app.currentNodeId
    var targetGeneration = app.engineAnalysisRequestGeneration >= 0 ? app.engineAnalysisRequestGeneration
                                                                    : app.gameTreeGeneration
    if (targetGeneration !== app.gameTreeGeneration) {
        if (!showCachedAnalysisForCurrentNode(app))
            resetDisplay(app)
        return
    }

    var targetNode = app.nodeById(targetId)
    var targetBoardSignature = app.engineAnalysisRequestBoardSignature.length > 0
                             ? app.engineAnalysisRequestBoardSignature
                             : app.engineBoardSignature()
    var targetKomiSignature = app.engineAnalysisRequestKomiSignature.length > 0
                            ? app.engineAnalysisRequestKomiSignature
                            : app.engineKomiSignature()

    if (targetNode)
        cacheAnalysisCandidatesForNode(app, targetNode, incoming, targetBoardSignature, targetKomiSignature)

    if (targetId !== app.currentNodeId || targetBoardSignature !== app.engineBoardSignature()
            || targetKomiSignature !== app.engineKomiSignature()) {
        if (!showCachedAnalysisForCurrentNode(app))
            resetDisplay(app)
        return
    }

    setDisplay(app, incoming, false, revision)
    if (app.engineCandidateItems.length > 0) {
        app.statusMode = "message"
        app.statusMessage = app.engineCandidateSummaryText()
    }
}

function activeCandidateForVariationPreview(app) {
    if (!app.candidateVariationPreviewVisible || app.hoverKey === "" || !app.pointIsEngineCandidateKey(app.hoverKey))
        return null
    var candidate = app.engineCandidateItemMap[app.hoverKey]
    if (!candidate)
        return null
    return candidate
}

function activeCandidateVariationPreviewActive(app) {
    var candidate = activeCandidateForVariationPreview(app)
    if (!candidate || !candidate.pv || candidate.pv.length <= 0)
        return false
    if (moveRuleVariationPreview(app))
        return activeMoveRuleVariationItems(app, candidate, true).length > 0
    return true
}

function moveRuleVariationPreview(app) {
    return app.gameRuleMode === app.gameRuleAtaxx
           || app.gameRuleMode === app.gameRuleBreakthrough
}

function parsedPvPoint(app, moveText) {
    var point = app.parseEngineCoordinate(String(moveText || "").trim())
    if (!point || !app.pointInRuleBoard(point.x, point.y))
        return null
    return point
}

function previewStoneItem(point, player, moveNumber) {
    return {
        "kind": "stone",
        "x": point.x,
        "y": point.y,
        "key": point.x + "," + point.y,
        "player": player,
        "moveNumber": moveNumber,
        "nodeId": -1
    }
}

function previewArrowItem(fromPoint, toPoint, player, moveNumber) {
    return {
        "kind": "arrow",
        "fromX": fromPoint.x,
        "fromY": fromPoint.y,
        "x": toPoint.x,
        "y": toPoint.y,
        "key": toPoint.x + "," + toPoint.y,
        "player": player,
        "moveNumber": moveNumber,
        "nodeId": -1
    }
}

function consumeAtaxxPreviewMove(app, map, moves, index, player, sourcePoint, moveNumber) {
    if (index >= moves.length)
        return null
    var first = parsedPvPoint(app, moves[index])
    if (!first)
        return null

    var dims = app.boardDims()
    var item = {
        "x": first.x,
        "y": first.y,
        "key": app.keyFor(first.x, first.y),
        "player": player,
        "moveNumber": moveNumber,
        "nodeId": -1
    }

    if (sourcePoint) {
        var sourceKind = GameRules.ataxxMoveKind(map, dims, first.x, first.y, player, sourcePoint)
        if (sourceKind !== "clone" && sourceKind !== "jump")
            return null
        GameRules.applyAtaxxMoveOnMap(map, dims, item, sourcePoint)
        return {
            "item": previewArrowItem(sourcePoint, first, player, moveNumber),
            "nextIndex": index + 1
        }
    }

    var firstKind = GameRules.ataxxMoveKind(map, dims, first.x, first.y, player, null)
    if (firstKind === "clone") {
        GameRules.applyAtaxxMoveOnMap(map, dims, item, null)
        return {
            "item": previewStoneItem(first, player, moveNumber),
            "nextIndex": index + 1
        }
    }

    if (firstKind !== "source" || index + 1 >= moves.length)
        return null

    var second = parsedPvPoint(app, moves[index + 1])
    if (!second)
        return null
    var moveKind = GameRules.ataxxMoveKind(map, dims, second.x, second.y, player, first)
    if (moveKind !== "clone" && moveKind !== "jump")
        return null

    var targetItem = {
        "x": second.x,
        "y": second.y,
        "key": app.keyFor(second.x, second.y),
        "player": player,
        "moveNumber": moveNumber,
        "nodeId": -1
    }
    GameRules.applyAtaxxMoveOnMap(map, dims, targetItem, first)
    return {
        "item": previewArrowItem(first, second, player, moveNumber),
        "nextIndex": index + 2
    }
}

function consumeBreakthroughPreviewMove(app, map, moves, index, player, sourcePoint, moveNumber) {
    if (index >= moves.length)
        return null
    var dims = app.boardDims()
    var source = sourcePoint
    var targetIndex = index
    if (!source) {
        source = parsedPvPoint(app, moves[index])
        if (!source || GameRules.breakthroughMoveKind(map, dims, source.x, source.y, player, null) !== "source")
            return null
        targetIndex = index + 1
    }
    if (targetIndex >= moves.length)
        return null
    var target = parsedPvPoint(app, moves[targetIndex])
    if (!target)
        return null
    var kind = GameRules.breakthroughMoveKind(map, dims, target.x, target.y, player, source)
    if (kind !== "move" && kind !== "capture")
        return null
    var item = {
        "x": target.x,
        "y": target.y,
        "key": app.keyFor(target.x, target.y),
        "player": player,
        "moveNumber": moveNumber,
        "nodeId": -1
    }
    GameRules.applyBreakthroughMoveOnMap(map, dims, item, source)
    return {
        "item": previewArrowItem(source, target, player, moveNumber),
        "nextIndex": targetIndex + 1
    }
}

function activeMoveRuleVariationItems(app, candidate, respectMaxMoves) {
    if (!candidate || !candidate.pv || candidate.pv.length <= 0)
        return []

    var maxMoves = respectMaxMoves !== false ? Math.round(Number(app.candidateVariationPreviewMaxMoves)) : 0
    if (isNaN(maxMoves))
        maxMoves = 0
    maxMoves = Math.max(0, maxMoves)

    var items = []
    var map = GameRules.cloneStoneMap(app.stones)
    var player = app.currentPlayer
    var sourcePoint = app.currentMoveSourcePoint()
    var moveNumber = 1
    var consume = app.gameRuleMode === app.gameRuleAtaxx
                  ? consumeAtaxxPreviewMove
                  : consumeBreakthroughPreviewMove

    var current = consume(app, map, candidate.pv, 0, player, sourcePoint, moveNumber)
    if (!current)
        return []
    items.push(current.item)
    if (maxMoves === 1)
        return items

    var opponent = player === 1 ? 2 : 1
    var opponentMove = consume(app, map, candidate.pv, current.nextIndex, opponent, null, moveNumber + 1)
    if (opponentMove && (maxMoves === 0 || maxMoves >= 2))
        items.push(opponentMove.item)
    return items
}

function activeCandidateVariationItems(app, respectMaxMoves) {
    var candidate = activeCandidateForVariationPreview(app)
    if (!candidate || !candidate.pv || candidate.pv.length <= 0)
        return []
    if (moveRuleVariationPreview(app))
        return activeMoveRuleVariationItems(app, candidate, respectMaxMoves)

    var items = []
    var player = app.currentPlayer
    var moveNumber = 1
    var useMaxMoves = respectMaxMoves !== false
    var maxMoves = useMaxMoves ? Math.round(Number(app.candidateVariationPreviewMaxMoves)) : 0
    if (isNaN(maxMoves))
        maxMoves = 0
    maxMoves = Math.max(0, maxMoves)

    for (var i = 0; i < candidate.pv.length; ++i) {
        if (maxMoves > 0 && moveNumber > maxMoves)
            break
        var moveText = String(candidate.pv[i])
        var point = app.parseEngineCoordinate(moveText)
        if (!point) {
            if (moveText.trim().toLowerCase() === "pass") {
                player = player === 1 ? 2 : 1
                moveNumber += 1
            }
            continue
        }
        if (!app.pointInBoard(point.x, point.y))
            continue

        var key = app.keyFor(point.x, point.y)
        items.push({
            "x": point.x,
            "y": point.y,
            "key": key,
            "player": player,
            "moveNumber": moveNumber,
            "nodeId": -1
        })
        player = player === 1 ? 2 : 1
        moveNumber += 1
    }
    return items
}

function playActiveCandidateVariation(app) {
    if (!activeCandidateVariationPreviewActive(app))
        return false

    var candidate = activeCandidateForVariationPreview(app)
    if (!candidate || !candidate.pv || candidate.pv.length <= 0)
        return false

    var moves = candidate.pv.slice()
    var played = false
    for (var i = 0; i < moves.length; ++i) {
        var moveText = String(moves[i]).trim()
        if (moveText.length <= 0)
            continue
        if (moveText.toLowerCase() === "pass") {
            app.passMove()
            played = true
            continue
        }

        var point = app.parseEngineCoordinate(moveText)
        if (!point || !app.pointInBoard(point.x, point.y))
            continue
        if (!app.placeStone(point.x, point.y))
            break
        played = true
    }
    if (played) {
        app.clearHover(true)
        app.focusBoardInput()
    }
    return played
}
