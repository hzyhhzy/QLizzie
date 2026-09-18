.pragma library

// Candidate presentation is a projection of values. Formatting options and
// already-resolved coordinates are supplied by the UI boundary; there are no
// callbacks, application objects or writes to the engine's candidate snapshot.
function clamp(value, low, high) {
    return Math.min(Math.max(value, low), high)
}

function visitCount(candidate) {
    var visits = Number(candidate ? candidate.visits : 0)
    return isNaN(visits) ? 0 : visits
}

function winrateValue(candidate) {
    var value = Number(candidate ? candidate.winrate : NaN)
    return isFinite(value) ? clamp(value * 100, 0, 100) : NaN
}

function scoreValue(candidate) {
    return Number(candidate && candidate.scoreMean !== undefined ? candidate.scoreMean : NaN)
}

function formatNumber(value, decimals, showPercent) {
    var number = Number(value)
    if (isNaN(number))
        return ""
    return number.toFixed(Math.round(clamp(decimals, 0, 2))) + (showPercent ? "%" : "")
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

function winrateText(candidate, style) {
    if (!candidate)
        return ""
    var value = winrateValue(candidate)
    return isFinite(value) ? formatNumber(value, style.decimals, style.percent) : "--"
}

function scoreText(candidate, style) {
    return !candidate || !style.visible ? ""
           : formatNumber(scoreValue(candidate), style.decimals, style.percent)
}

function labelLine(kind, text, style, color) {
    return { "kind": kind, "text": text, "fontSize": style.fontSize,
             "color": color, "bold": style.bold }
}

function labelLines(candidate, settings) {
    var lines = []
    var winrate = winrateText(candidate, settings.winrate)
    if (settings.winrate.visible && winrate.length > 0)
        lines.push(labelLine(0, winrate, settings.winrate, settings.labelColor))
    if (settings.visits.visible)
        lines.push(labelLine(1, formatVisitCount(visitCount(candidate)), settings.visits, settings.labelColor))
    var score = scoreText(candidate, settings.score)
    if (score.length > 0)
        lines.push(labelLine(2, score, settings.score, settings.labelColor))
    if (lines.length <= 0 && winrate.length > 0)
        lines.push(labelLine(0, winrate, settings.winrate, settings.labelColor))
    return lines
}

function hexComponent(value) {
    var text = Math.round(clamp(value, 0, 255)).toString(16)
    return text.length < 2 ? "0" + text : text
}

function hsbColorHex(hue, saturation, brightness) {
    hue = ((Number(hue) % 1) + 1) % 1
    saturation = clamp(Number(saturation), 0, 1)
    brightness = clamp(Number(brightness), 0, 1)
    var sector = Math.floor(hue * 6)
    var fraction = hue * 6 - sector
    var p = brightness * (1 - saturation)
    var q = brightness * (1 - saturation * fraction)
    var t = brightness * (1 - saturation * (1 - fraction))
    var colors = [[brightness, t, p], [q, brightness, p], [p, brightness, t],
                  [p, q, brightness], [t, p, brightness], [brightness, p, q]]
    var rgb = colors[sector]
    return "#" + hexComponent(rgb[0] * 255) + hexComponent(rgb[1] * 255) + hexComponent(rgb[2] * 255)
}

function alphaRatio(visitRatio, style) {
    return Math.max(0, Math.log(clamp(Number(visitRatio), 0.000001, 1)) / style.alphaFactor + 1)
}

function markerColor(displayIndex, visitRatio, style) {
    var hue = displayIndex <= 1 ? 0.5
            : Math.pow(clamp(Number(visitRatio), 0, 1), 1 / style.colorRatio) / 3
    return hsbColorHex(hue, 1, 0.85)
}

function markerOpacity(visitRatio, style) {
    return clamp((style.minAlpha + (style.maxAlpha - style.minAlpha) * alphaRatio(visitRatio, style)) / 255, 0, 1)
}

function markerOutlineOpacity(visitRatio, style) {
    return clamp((48 + 48 * alphaRatio(visitRatio, style)) / 255, 0, 1)
}

// entries = [{ candidate, point, moveKind, moveText }]. The engine rank is
// preserved even when malformed candidates are filtered from the projection.
function build(entries, settings) {
    var sorted = entries.slice()
    var needsSort = false
    var previousOrder = -Infinity
    for (var rank = 0; rank < sorted.length; ++rank) {
        var order = Number(sorted[rank].candidate.order || 0)
        if (order < previousOrder)
            needsSort = true
        previousOrder = order
    }
    if (needsSort) {
        sorted.sort(function(left, right) {
            return Number(left.candidate.order || 0) - Number(right.candidate.order || 0)
        })
    }
    var maxVisits = 0
    for (var m = 0; m < sorted.length; ++m)
        maxVisits = Math.max(maxVisits, visitCount(sorted[m].candidate))
    var limit = settings.displayCount <= 0 ? sorted.length : Math.min(settings.displayCount, sorted.length)
    var threshold = maxVisits > 0 ? maxVisits * settings.minVisitRatio : 0
    var tableLimit = Math.round(Number(settings.tableRowLimit))
    if (!isFinite(tableLimit) || tableLimit < 1)
        tableLimit = 20
    var items = []
    var itemMap = ({})
    var table = []
    for (var c = 0; c < sorted.length; ++c) {
        var entry = sorted[c]
        var point = entry.point
        var moveKind = entry.moveKind
        if (!point && moveKind === "")
            continue
        var candidate = entry.candidate
        var boardPoint = !!point
        var visits = visitCount(candidate)
        var visitRatio = maxVisits > 0 ? clamp(visits / maxVisits, 0, 1) : 1
        var qualified = c < limit && (maxVisits <= 0 || visits >= threshold)
        var tableEligible = table.length < tableLimit
        var needsDetails = qualified || tableEligible
        var item = {
            "x": boardPoint ? point.x : -1,
            "y": boardPoint ? point.y : -1,
            "key": boardPoint ? point.x + "," + point.y : moveKind,
            "move": candidate.move,
            "specialMove": moveKind,
            "boardPoint": boardPoint,
            "order": candidate.order,
            "displayIndex": c + 1,
            "visits": visits,
            "visitRatio": visitRatio,
            "qualified": qualified,
            "boardVisible": boardPoint && (qualified || settings.showFilteredMarkers),
            "opacity": boardPoint ? markerOpacity(visitRatio, settings.marker) : 0,
            "color": boardPoint ? markerColor(c + 1, visitRatio, settings.marker) : "transparent",
            "outlineOpacity": boardPoint ? markerOutlineOpacity(visitRatio, settings.marker) : 0,
            "winrate": candidate.winrate,
            "winrateText": needsDetails ? winrateText(candidate, settings.winrate) : "",
            "scoreMean": candidate.scoreMean,
            "scoreText": needsDetails ? scoreText(candidate, settings.score) : "",
            "pv": candidate.pv,
            "pvText": candidate.pvText,
            "labelLines": qualified ? labelLines(candidate, settings) : []
        }
        if (needsDetails)
            item.displayMoveText = entry.moveText
        items.push(item)
        itemMap[item.key] = item
        if (tableEligible) {
            table.push({ "row": c + 1, "key": item.key, "coordinate": item.displayMoveText,
                         "winrateText": item.winrateText, "scoreText": item.scoreText,
                         "visitsText": visits > 0 ? formatVisitCount(visits) : "" })
        }
    }
    return { "items": items, "itemMap": itemMap, "table": table }
}
