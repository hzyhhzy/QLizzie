.pragma library
.import "CandidateModel.js" as CandidateModel
.import "Ownership.js" as Ownership

// Cache decisions only consume snapshots. The caller applies returned node
// annotations through GameSession, which remains the sole game-tree writer.
function copyCandidates(candidates) {
    var copy = []
    for (var i = 0; candidates && i < candidates.length; ++i) {
        var item = ({})
        for (var key in candidates[i]) {
            var value = candidates[i][key]
            item[key] = value && typeof value !== "string" && typeof value.slice === "function"
                        ? value.slice() : value
        }
        copy.push(item)
    }
    return copy
}

function requestPosition(position, request) {
    request = request || ({})
    return {
        "nodeId": request.nodeId >= 0 ? request.nodeId : position.nodeId,
        "generation": request.generation >= 0 ? request.generation : position.generation,
        "player": request.player === 1 || request.player === 2 ? request.player : position.player,
        "boardSignature": request.boardSignature || position.boardSignature,
        "komiSignature": request.komiSignature || position.komiSignature,
        "engineSignature": request.engineSignature || position.engineSignature
    }
}

function samePosition(left, right) {
    return left.nodeId === right.nodeId && left.generation === right.generation
            && left.player === right.player
            && left.boardSignature === right.boardSignature
            && left.komiSignature === right.komiSignature
            && left.engineSignature === right.engineSignature
}

function candidateUsable(node, position) {
    return !!node && !!node.analysisCandidates && node.analysisCandidates.length > 0
            && node.analysisCandidateBoardSignature === position.boardSignature
            && node.analysisCandidateKomiSignature === position.komiSignature
}

function ownershipUsable(node, position, config) {
    return config.ownershipEnabled && config.ownershipSupported && !!node
            && Ownership.usable(node.analysisOwnership, config.width, config.height)
            && node.analysisOwnershipBoardSignature === position.boardSignature
            && node.analysisOwnershipKomiSignature === position.komiSignature
            && node.analysisOwnershipEngineSignature === position.engineSignature
}

function winrateAnnotations(node, candidates, player) {
    if (!node || !candidates || candidates.length <= 0 || !candidates[0]
            || candidates[0].winrate === undefined || !isFinite(Number(candidates[0].winrate)))
        return ({})
    var blackWinrate = CandidateModel.winrateValue(candidates[0])
    if (player === 2)
        blackWinrate = 100 - blackWinrate
    if (node.analysisBlackWinrate !== undefined
            && Math.abs(Number(node.analysisBlackWinrate) - blackWinrate) < 0.0001)
        return ({})
    return { "analysisBlackWinrate": blackWinrate }
}

function candidateAnnotations(node, candidates, position) {
    var snapshot = copyCandidates(candidates)
    var values = winrateAnnotations(node, snapshot, position.player)
    values.analysisCandidates = snapshot
    values.analysisCandidateBoardSignature = position.boardSignature
    values.analysisCandidateKomiSignature = position.komiSignature
    return values
}

function cachedCandidates(node, position) {
    return { "values": candidateUsable(node, position) ? node.analysisCandidates : [],
             "fromCache": true, "position": position, "accepted": false, "annotations": null }
}

function candidateUpdate(position, currentNode, targetNode, request, candidates, active) {
    if (!active || !request || !candidates || candidates.length <= 0)
        return cachedCandidates(currentNode, position)
    var target = requestPosition(position, request)
    if (target.generation !== position.generation || target.engineSignature !== position.engineSignature)
        return cachedCandidates(currentNode, position)
    var annotations = targetNode ? candidateAnnotations(targetNode, candidates, target) : null
    var result = samePosition(target, position)
            ? { "values": annotations ? annotations.analysisCandidates : copyCandidates(candidates),
                "fromCache": false, "position": target, "accepted": true }
            : cachedCandidates(currentNode, position)
    result.annotations = annotations
    result.annotationNodeId = target.nodeId
    return result
}

function cachedOwnership(node, position, config) {
    return { "values": ownershipUsable(node, position, config) ? node.analysisOwnership : [],
             "fromCache": true, "position": position, "accepted": false, "annotations": null }
}

function ownershipUpdate(position, currentNode, targetNode, request, values, active, config) {
    if (!config.ownershipEnabled || !config.ownershipSupported || !active || !request)
        return { "values": [], "fromCache": false, "position": position, "accepted": false, "annotations": null }
    var target = requestPosition(position, request)
    if (target.generation !== position.generation || target.engineSignature !== position.engineSignature)
        return cachedOwnership(currentNode, position, config)
    var normalized = Ownership.normalized(values, config.width, config.height, target.player)
    if (normalized.length <= 0)
        return cachedOwnership(currentNode, position, config)
    var result = samePosition(target, position)
            ? { "values": normalized, "fromCache": false, "position": target, "accepted": true }
            : cachedOwnership(currentNode, position, config)
    result.annotations = targetNode ? {
        "analysisOwnership": normalized,
        "analysisOwnershipBoardSignature": target.boardSignature,
        "analysisOwnershipKomiSignature": target.komiSignature,
        "analysisOwnershipEngineSignature": target.engineSignature
    } : null
    result.annotationNodeId = target.nodeId
    return result
}
