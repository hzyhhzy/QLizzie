.pragma library
.import "GameRules.js" as GameRules
.import "CandidateModel.js" as CandidateModel
.import "MovePreview.js" as MovePreview

function visitCount(candidate) {
    return CandidateModel.visitCount(candidate)
}

function winrateValue(app, candidate) {
    return CandidateModel.winrateValue(candidate)
}

function scoreValue(app, candidate) {
    return CandidateModel.scoreValue(candidate)
}

function formatCandidateNumber(app, value, decimals, showPercent) {
    return CandidateModel.formatNumber(value, decimals, showPercent)
}

function winrateText(app, candidate) {
    return CandidateModel.winrateText(candidate, presentationSettings(app).winrate)
}

function scoreDisplayEnabled(app) {
    return app.candidateScoreLabelVisible
}

function scoreTitle(app) {
    return app.candidateScoreTitleMode === app.candidateScoreTitleDrawRate ? app.trText("candidateDrawRate")
                                                                           : app.trText("candidateScoreMean")
}

function scoreText(app, candidate) {
    return CandidateModel.scoreText(candidate, presentationSettings(app).score)
}

function labelLines(app, candidate) {
    return CandidateModel.labelLines(candidate, presentationSettings(app))
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
        var font = (line.bold ? "700 " : "400 ") + Math.round(fontSize) + "px sans-serif"
        var color = overrideColor || line.color || String(app.candidateLabelTextColor)
        var textY = y + lineHeight * 0.5 - labelLineOffset(app, line.kind) * scale
        var cached = app.textCache && app.textCache.draw(ctx, line.text || "", centerX, textY,
                                                        font, color, Math.round(fontSize))
        if (!cached) {
            ctx.font = font
            ctx.fillStyle = color
            ctx.fillText(line.text || "", centerX, textY, Math.max(8, markerRadius * 2 - 4))
        }
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

    if (drawBackground || drawOutline || drawRing) {
        ctx.save()
        var baseAlpha = ctx.globalAlpha
        if (drawBackground) {
            ctx.globalAlpha = baseAlpha * fillOpacity
            ctx.fillStyle = String(options.fillColor || "#00c8ff")
            ctx.beginPath()
            ctx.arc(centerX, centerY, markerRadius, 0, Math.PI * 2)
            ctx.fill()
        }
        if (drawOutline) {
            ctx.globalAlpha = baseAlpha * outlineOpacity
            ctx.strokeStyle = String(options.outlineColor || "#000000")
            ctx.lineWidth = Math.max(1, markerRadius / 26.5)
            ctx.beginPath()
            ctx.arc(centerX, centerY, markerRadius, 0, Math.PI * 2)
            ctx.stroke()
        }
        if (drawRing) {
            ctx.globalAlpha = baseAlpha * ringOpacity
            ctx.strokeStyle = String(options.ringColor || "#f01818")
            ctx.lineWidth = ringLineWidthForRadius(app, markerRadius)
            ctx.beginPath()
            ctx.arc(centerX, centerY, ringRadius(markerRadius), 0, Math.PI * 2)
            ctx.stroke()
        }
        ctx.restore()
    }

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
    return CandidateModel.hexComponent(value)
}

function hsbColorHex(app, hue, saturation, brightness) {
    return CandidateModel.hsbColorHex(hue, saturation, brightness)
}

function yzyAlphaRatio(app, visitRatio) {
    return CandidateModel.alphaRatio(visitRatio, markerSettings(app))
}

function markerColor(app, displayIndex, visitRatio) {
    return CandidateModel.markerColor(displayIndex, visitRatio, markerSettings(app))
}

function markerOpacity(app, displayIndex, visitRatio) {
    return CandidateModel.markerOpacity(visitRatio, markerSettings(app))
}

function markerOutlineOpacity(app, visitRatio) {
    return CandidateModel.markerOutlineOpacity(visitRatio, markerSettings(app))
}

function markerSettings(app) {
    return { "alphaFactor": app.candidateYzyAlphaFactor, "colorRatio": app.candidateYzyColorRatio,
             "minAlpha": app.candidateYzyMinAlpha, "maxAlpha": app.candidateYzyMaxAlpha }
}

// A paint pass reads the QML properties once, then draws every marker from these values.
function drawingSettings(app) {
    return { "candidateRingVisible": app.candidateRingVisible,
             "candidateRingLineWidth": app.candidateRingLineWidth,
             "candidateRankLabelVisible": app.candidateRankLabelVisible,
             "candidateLabelTextColor": String(app.candidateLabelTextColor),
             "candidateWinrateOffsetY": app.candidateWinrateOffsetY,
             "candidateVisitsOffsetY": app.candidateVisitsOffsetY,
             "candidateScoreOffsetY": app.candidateScoreOffsetY,
             "coordinateFontFamily": app.coordinateFontFamily,
             "stoneScale": app.stoneScale }
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
    return CandidateModel.formatVisitCount(value)
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

function tokenizePvText(text) {
    var source = String(text === undefined || text === null ? "" : text)
    var moves = []
    var position = 0
    while (position < source.length) {
        while (position < source.length && /\s/.test(source.charAt(position)))
            position += 1
        if (position >= source.length)
            break

        var start = position
        if (source.charAt(position) === "(") {
            while (position < source.length) {
                var character = source.charAt(position++)
                if (character === ")")
                    break
            }
        } else {
            while (position < source.length && !/\s/.test(source.charAt(position)))
                position += 1
        }
        var move = source.substring(start, position).trim()
        if (move.length > 0)
            moves.push(move)
    }
    return moves
}

function pvMoves(candidate) {
    if (!candidate)
        return []

    if (candidate._pvMoves !== undefined)
        return candidate._pvMoves

    var moves = []
    var pv = candidate.pv
    if (typeof pv === "string") {
        moves = tokenizePvText(pv)
    } else if (pv && pv.length !== undefined) {
        for (var i = 0; i < pv.length; ++i) {
            var pvMove = String(pv[i]).trim()
            if (pvMove.length > 0)
                moves.push(pvMove)
        }
    } else if (candidate.pvText !== undefined) {
        moves = tokenizePvText(candidate.pvText)
    }
    candidate._pvMoves = moves
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

function presentationSettings(app) {
    return {
        "displayCount": app.candidateDisplayCount,
        "minVisitRatio": app.candidateMinVisitRatio,
        "showFilteredMarkers": app.candidateShowFilteredMarkers,
        "tableRowLimit": app.candidateTableRowLimit,
        "labelColor": String(app.candidateLabelTextColor),
        "winrate": {
            "visible": app.candidateWinrateLabelVisible,
            "decimals": app.candidateWinrateDecimals,
            "percent": app.candidateWinrateShowPercent,
            "fontSize": app.candidateWinrateFontSize,
            "bold": app.candidateWinrateBold
        },
        "visits": {
            "visible": app.candidateVisitsLabelVisible,
            "fontSize": app.candidateVisitsFontSize,
            "bold": app.candidateVisitsBold
        },
        "score": {
            "visible": app.candidateScoreLabelVisible,
            "decimals": app.candidateScoreDecimals,
            "percent": app.candidateScoreShowPercent,
            "fontSize": app.candidateScoreFontSize,
            "bold": app.candidateScoreBold
        },
        "marker": markerSettings(app)
    }
}

function buildCandidateItems(app, candidates) {
    var entries = []
    candidates = candidates || []
    for (var i = 0; i < candidates.length; ++i) {
        var candidate = candidates[i] || ({})
        var moveKind = specialMoveKind(candidate.move)
        var point = moveKind === "" ? app.parseEngineCoordinate(candidate.move) : null
        entries.push({
            "candidate": candidate,
            "point": point,
            "moveKind": moveKind,
            "moveText": point ? app.coordinateText(point.x, point.y) : specialMoveText(app, moveKind)
        })
    }
    return CandidateModel.build(entries, presentationSettings(app))
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
    if (!candidate || pvMoves(candidate).length <= 0)
        return false
    if (moveRuleVariationPreview(app))
        return activeMoveRuleVariationItems(app, candidate, true).length > 0
    return true
}

function moveRuleVariationPreview(app) {
    return GameRules.isSourceMoveRule(app.gameRuleMode)
}

// This is the only protocol/UI boundary for variation data. Pure preview
// functions receive a position snapshot, board config and parsed coordinates.
function variationActions(app, candidate) {
    var moves = pvMoves(candidate)
    var actions = []
    for (var i = 0; i < moves.length; ++i) {
        var moveText = String(moves[i]).trim()
        var kind = specialMoveKind(moveText)
        actions.push(kind !== "" ? { "role": kind } : app.parseEngineCoordinate(moveText))
    }
    return actions
}

function variationConfig(app, respectMaxMoves) {
    return {
        "dims": app.boardDims(),
        "ruleMode": app.gameRuleMode,
        "maxMoves": respectMaxMoves === false ? 0 : app.candidateVariationPreviewMaxMoves
    }
}

function activeMoveRuleVariationItems(app, candidate, respectMaxMoves) {
    return MovePreview.sourceVariation({
        "map": app.stones,
        "player": app.currentPlayer,
        "source": app.currentMoveSourcePoint()
    }, variationConfig(app, respectMaxMoves), variationActions(app, candidate)).items
}

function activeCandidateVariationItems(app, respectMaxMoves) {
    var candidate = activeCandidateForVariationPreview(app)
    if (!candidate)
        return []
    if (moveRuleVariationPreview(app))
        return activeMoveRuleVariationItems(app, candidate, respectMaxMoves)
    return MovePreview.placementItems({ "player": app.currentPlayer },
                                     variationConfig(app, respectMaxMoves),
                                     variationActions(app, candidate))
}

function playActiveCandidateVariation(app) {
    if (!activeCandidateVariationPreviewActive(app))
        return false

    var candidate = activeCandidateForVariationPreview(app)
    var moves = pvMoves(candidate)
    if (moves.length <= 0)
        return false

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
