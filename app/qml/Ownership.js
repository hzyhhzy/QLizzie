.pragma library

function normalized(values, width, height, playerToMove) {
    var boardWidth = Math.max(1, Math.round(Number(width) || 0))
    var boardHeight = Math.max(1, Math.round(Number(height) || 0))
    var expected = boardWidth * boardHeight
    if (!values || values.length !== expected)
        return []

    var perspective = Number(playerToMove) === 2 ? -1 : 1
    var result = []
    for (var i = 0; i < expected; ++i) {
        var value = Number(values[i])
        if (!isFinite(value))
            return []
        result.push(Math.max(-1, Math.min(1, value)) * perspective)
    }
    return result
}

function usable(values, width, height) {
    var expected = Math.max(1, Math.round(Number(width) || 0))
                 * Math.max(1, Math.round(Number(height) || 0))
    return !!values && values.length === expected
}

function pointForIndex(index, width) {
    var boardWidth = Math.max(1, Math.round(Number(width) || 0))
    var itemIndex = Math.max(0, Math.round(Number(index) || 0))
    return {
        "x": itemIndex % boardWidth,
        "y": Math.floor(itemIndex / boardWidth)
    }
}

function markerOpacity(value) {
    var strength = Math.abs(Number(value) || 0)
    if (strength < 0.05)
        return 0
    return Math.min(0.92, 0.16 + strength * 0.76)
}
