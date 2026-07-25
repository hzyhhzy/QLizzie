.pragma library

function visitCount(candidate) {
    if (!candidate)
        return 0
    var value = Number(candidate.visits)
    if (!isFinite(value) || value < 0)
        return 0
    return value
}

function totalVisits(candidates) {
    if (!candidates || candidates.length <= 0)
        return 0

    var total = 0
    for (var i = 0; i < candidates.length; ++i) {
        var candidate = candidates[i]
        if (!candidate || (candidate.isSymmetryOf !== undefined
                           && String(candidate.isSymmetryOf).length > 0))
            continue
        total += visitCount(candidate)
    }
    return total
}

function bestCandidate(candidates) {
    if (!candidates || candidates.length <= 0)
        return null
    for (var i = 0; i < candidates.length; ++i) {
        var candidate = candidates[i]
        if (candidate && candidate.move !== undefined
                && String(candidate.move).trim().length > 0)
            return candidate
    }
    return null
}

function limitReached(candidates, elapsedMilliseconds, secondsLimit,
                      totalVisitsLimit, firstMoveVisitsLimit) {
    var best = bestCandidate(candidates)
    if (!best)
        return false

    var elapsed = Math.max(0, Number(elapsedMilliseconds) || 0)
    var seconds = Math.max(0, Number(secondsLimit) || 0)
    var totalLimit = Math.max(0, Number(totalVisitsLimit) || 0)
    var firstLimit = Math.max(0, Number(firstMoveVisitsLimit) || 0)

    return (seconds > 0 && elapsed >= seconds * 1000)
            || (totalLimit > 0 && totalVisits(candidates) >= totalLimit)
            || (firstLimit > 0 && visitCount(best) >= firstLimit)
}

function limitChangeAction(configured, inFlight, shouldMove) {
    if (!configured)
        return inFlight ? "cancel" : "wait"
    if (inFlight)
        return "evaluate"
    return shouldMove ? "start" : "none"
}

function positionMatches(position, nodeId, generation, boardSignature,
                         komiSignature, player, engineSignature) {
    return !!position
            && Number(position.nodeId) === Number(nodeId)
            && Number(position.generation) === Number(generation)
            && String(position.boardSignature) === String(boardSignature)
            && String(position.komiSignature) === String(komiSignature)
            && Number(position.player) === Number(player)
            && String(position.engineSignature || "") === String(engineSignature || "")
}

function nextResignCount(previousCount, moveNumber, winrate,
                         minimumMove, winrateThreshold) {
    var move = Math.max(0, Math.round(Number(moveNumber) || 0))
    var minimum = Math.max(0, Math.round(Number(minimumMove) || 0))
    var value = Number(winrate)
    var threshold = Number(winrateThreshold)
    if (!isFinite(value) || !isFinite(threshold)
            || threshold <= 0 || move < minimum || value >= threshold)
        return 0
    return Math.max(0, Math.round(Number(previousCount) || 0)) + 1
}
