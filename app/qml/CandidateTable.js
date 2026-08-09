.pragma library
.import "CandidateAnalysis.js" as CandidateAnalysis

function finiteNumber(value, fallback) {
    var number = Number(value)
    return isFinite(number) ? number : fallback
}

function optionalNumber(value) {
    if (value === undefined || value === null || String(value).trim() === "")
        return NaN
    return finiteNumber(value, NaN)
}

function percentageValue(value) {
    var number = optionalNumber(value)
    if (isNaN(number))
        return NaN
    return Math.abs(number) <= 1 ? number * 100 : number
}

function fixedText(value, decimals) {
    return isNaN(value) ? "--" : value.toFixed(decimals)
}

function orderedCandidates(candidates) {
    var ordered = []
    for (var index = 0; candidates && index < candidates.length; ++index) {
        ordered.push({
            "candidate": candidates[index],
            "sourceIndex": index,
            "order": optionalNumber(candidates[index].order)
        })
    }
    ordered.sort(function(left, right) {
        var leftOrder = isNaN(left.order) ? left.sourceIndex : left.order
        var rightOrder = isNaN(right.order) ? right.sourceIndex : right.order
        if (leftOrder !== rightOrder)
            return leftOrder - rightOrder
        return left.sourceIndex - right.sourceIndex
    })
    return ordered
}

function rowForCandidate(app, candidate, displayIndex, totalVisits) {
    var visits = Math.max(0, Math.round(finiteNumber(candidate.visits, 0)))
    var lcb = percentageValue(candidate.lcb)
    var winrate = percentageValue(candidate.winrate)
    var policySource = candidate.prior !== undefined ? candidate.prior : candidate.policy
    var policy = percentageValue(policySource)
    var scoreMean = optionalNumber(candidate.scoreMean)
    var scoreStdev = optionalNumber(candidate.scoreStdev)
    var visitShare = totalVisits > 0 ? visits * 100 / totalVisits : 0
    var coordinate = CandidateAnalysis.candidateMoveText(app, candidate)

    return {
        "displayIndex": displayIndex,
        "key": String(candidate.move === undefined ? "" : candidate.move),
        "indexValue": displayIndex,
        "coordinateValue": coordinate,
        "lcbValue": lcb,
        "winrateValue": winrate,
        "visitsValue": visits,
        "shareValue": visitShare,
        "policyValue": policy,
        "scoreMeanValue": scoreMean,
        "scoreStdevValue": scoreStdev,
        "indexText": String(displayIndex),
        "coordinateText": coordinate,
        "lcbText": fixedText(lcb, 1),
        "winrateText": fixedText(winrate, 1),
        "visitsText": CandidateAnalysis.formatVisitCount(visits),
        "shareText": fixedText(visitShare, 1),
        "policyText": fixedText(policy, 2),
        "scoreMeanText": fixedText(scoreMean, 1),
        "scoreStdevText": fixedText(scoreStdev, 1)
    }
}

function compareOptionalNumbers(left, right, ascending) {
    var leftMissing = isNaN(left)
    var rightMissing = isNaN(right)
    if (leftMissing || rightMissing) {
        if (leftMissing && rightMissing)
            return 0
        return leftMissing ? 1 : -1
    }
    if (left === right)
        return 0
    return (left < right ? -1 : 1) * (ascending ? 1 : -1)
}

function compareRows(left, right, sortColumn, ascending) {
    var result = 0
    if (sortColumn === 1) {
        result = String(left.coordinateValue).localeCompare(String(right.coordinateValue))
        if (!ascending)
            result = -result
    } else {
        var field = [
            "indexValue",
            "indexValue",
            "lcbValue",
            "winrateValue",
            "visitsValue",
            "shareValue",
            "policyValue",
            "scoreMeanValue",
            "scoreStdevValue"
        ][Math.max(0, Math.min(8, Math.round(sortColumn)))]
        result = compareOptionalNumbers(Number(left[field]), Number(right[field]), ascending)
    }
    if (result !== 0)
        return result
    return left.displayIndex - right.displayIndex
}

function concentrationValue(ordered, totalVisits, maxVisits) {
    if (totalVisits <= 0 || maxVisits <= 0)
        return 0
    var sum = 0
    for (var index = 0; index < 11; ++index) {
        var visits = index < ordered.length
                ? Math.max(0, finiteNumber(ordered[index].candidate.visits, 0)) : 0
        var difference = maxVisits - visits
        sum += difference * difference
    }
    return Math.sqrt(sum / 10 / totalVisits / totalVisits) * 100
}

function buildTable(app, candidates, sortColumn, ascending) {
    var ordered = orderedCandidates(candidates || [])
    var totalVisits = 0
    var maxVisits = 0
    for (var index = 0; index < ordered.length; ++index) {
        var visits = Math.max(0, finiteNumber(ordered[index].candidate.visits, 0))
        totalVisits += visits
        maxVisits = Math.max(maxVisits, visits)
    }

    var rows = []
    for (var rowIndex = 0; rowIndex < ordered.length; ++rowIndex)
        rows.push(rowForCandidate(app, ordered[rowIndex].candidate,
                                  rowIndex + 1, totalVisits))
    rows.sort(function(left, right) {
        return compareRows(left, right, sortColumn, ascending)
    })

    return {
        "rows": rows,
        "totalVisits": totalVisits,
        "maxVisits": maxVisits,
        "concentration": concentrationValue(ordered, totalVisits, maxVisits)
    }
}
