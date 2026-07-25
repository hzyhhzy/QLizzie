.pragma library

function buildPlan(committedNodeIds, targetNodeIds, forceFull) {
    var committed = committedNodeIds || []
    var target = targetNodeIds || []
    if (forceFull === true) {
        return {
            "full": true,
            "commonLength": 0,
            "undoCount": 0,
            "playStartIndex": 0
        }
    }

    var commonLength = 0
    var maxCommonLength = Math.min(committed.length, target.length)
    while (commonLength < maxCommonLength
           && committed[commonLength] === target[commonLength]) {
        commonLength += 1
    }

    return {
        "full": false,
        "commonLength": commonLength,
        "undoCount": committed.length - commonLength,
        "playStartIndex": commonLength
    }
}
