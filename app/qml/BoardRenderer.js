.pragma library
.import "CoordinateUtils.js" as CoordinateUtils

var HEX_ROW_HEIGHT = 0.8660254037844386
var HEX_CELL_RADIUS_RATIO = 0.5773502691896258

function wrappedCoordinate(value, size) {
    if (size <= 0)
        return value
    var result = value % size
    return result < 0 ? result + size : result
}

function stateFromApp(app, overrides) {
    var state = {
        "boardSizeX": app.boardSizeX,
        "boardSizeY": app.boardSizeY,
        "gameRuleMode": app.gameRuleMode,
        "gameRuleGo": app.gameRuleGo,
        "gameRuleGomoku": app.gameRuleGomoku,
        "gameRuleHex": app.gameRuleHex,
        "gameRuleHexGoParallelogram": app.gameRuleHexGoParallelogram,
        "gameRuleHexGoHexagon": app.gameRuleHexGoHexagon,
        "gameRuleHexGoTriangle": app.gameRuleHexGoTriangle,
        "gameRuleTorusGo": app.gameRuleTorusGo,
        "gameRuleReversi": app.gameRuleReversi,
        "gameRuleAtaxx": app.gameRuleAtaxx,
        "gameRuleBreakthrough": app.gameRuleBreakthrough,
        "hexGridBoard": app.ruleUsesHexGrid(),
        "squareCellBoard": app.ruleUsesSquareCells(),
        "hexCellStyleActive": app.ruleUsesHexCellStyle(),
        "boardPresentationMode": app.boardPresentationMode,
        "boardPresentationCells": app.boardPresentationCells,
        "boardPresentationTorusEdge": app.boardPresentationTorusEdge,
        "boardPresentationTorusHalf": app.boardPresentationTorusHalf,
        "boardPresentationTorusFull": app.boardPresentationTorusFull,
        "hexBoardStyle": app.hexBoardStyle,
        "hexBoardStyleCells": app.hexBoardStyleCells,
        "hexBoardRotation": app.hexBoardRotation,
        "hexRotationTranspose": app.hexRotationTranspose,
        "hexRotationFlipX": app.hexRotationFlipX,
        "hexRotationFlipXTranspose": app.hexRotationFlipXTranspose,
        "hexRotationHorizontal": app.hexRotationHorizontal,
        "hexRotationHorizontalTranspose": app.hexRotationHorizontalTranspose,
        "hexRotationVertical": app.hexRotationVertical,
        "hexRotationVerticalTranspose": app.hexRotationVerticalTranspose,
        "hexRotationMirror": app.hexRotationMirror,
        "hexRotationMirrorTranspose": app.hexRotationMirrorTranspose,
        "coordinateDisplayMode": app.coordinateDisplayMode,
        "coordinateDisplayNone": app.coordinateDisplayNone,
        "stoneScale": app.stoneScale,
        "gridOpacity": app.gridOpacity,
        "gridLineWidth": app.gridLineWidth,
        "boardWoodColor": app.boardWoodColor,
        "coordinateFontFamily": app.coordinateFontFamily,
        "compactLayout": app.compactLayout
    }
    for (var key in overrides || ({}))
        state[key] = overrides[key]
    return state
}

function hexBoard(state) {
    return state.hexGridBoard === true || state.gameRuleMode === state.gameRuleHex
}

function torusGoBoard(state) {
    return state.gameRuleMode === state.gameRuleTorusGo
}

function torusPaddingX(state) {
    if (!torusGoBoard(state))
        return 0
    if (state.boardPresentationMode === state.boardPresentationTorusHalf)
        return Math.ceil(Math.max(1, state.boardSizeX) / 2)
    if (state.boardPresentationMode === state.boardPresentationTorusFull)
        return Math.max(1, state.boardSizeX)
    return 0
}

function torusPaddingY(state) {
    if (!torusGoBoard(state))
        return 0
    if (state.boardPresentationMode === state.boardPresentationTorusHalf)
        return Math.ceil(Math.max(1, state.boardSizeY) / 2)
    if (state.boardPresentationMode === state.boardPresentationTorusFull)
        return Math.max(1, state.boardSizeY)
    return 0
}

function squareCellBoard(state) {
    return state.squareCellBoard === true
           || (state.gameRuleMode === state.gameRuleGomoku
               && state.boardPresentationMode === state.boardPresentationCells)
}

function hexCellStyle(state) {
    return state.hexCellStyleActive === true
           || (state.gameRuleMode === state.gameRuleHex && state.hexBoardStyle === state.hexBoardStyleCells)
}

function hexTransposed(state) {
    return state.hexBoardRotation === state.hexRotationTranspose
           || state.hexBoardRotation === state.hexRotationFlipXTranspose
           || state.hexBoardRotation === state.hexRotationHorizontalTranspose
           || state.hexBoardRotation === state.hexRotationVerticalTranspose
           || state.hexBoardRotation === state.hexRotationMirrorTranspose
}

function hexFlippedX(state) {
    return state.hexBoardRotation === state.hexRotationFlipX
           || state.hexBoardRotation === state.hexRotationFlipXTranspose
           || state.hexBoardRotation === state.hexRotationHorizontal
           || state.hexBoardRotation === state.hexRotationHorizontalTranspose
}

function hexFlippedY(state) {
    return state.hexBoardRotation === state.hexRotationMirror
           || state.hexBoardRotation === state.hexRotationMirrorTranspose
           || state.hexBoardRotation === state.hexRotationVertical
           || state.hexBoardRotation === state.hexRotationVerticalTranspose
}

function hexHorizontalOrientation(state) {
    return state.hexBoardRotation === state.hexRotationHorizontal
           || state.hexBoardRotation === state.hexRotationHorizontalTranspose
}

function hexVerticalOrientation(state) {
    return state.hexBoardRotation === state.hexRotationVertical
           || state.hexBoardRotation === state.hexRotationVerticalTranspose
}

function pointInRuleBoard(state, x, y) {
    if (x < 0 || x >= state.boardSizeX || y < 0 || y >= state.boardSizeY)
        return false
    if (state.gameRuleMode === state.gameRuleHexGoHexagon) {
        if (state.boardSizeX !== state.boardSizeY || state.boardSizeX % 2 === 0)
            return false
        var half = Math.floor(state.boardSizeX / 2)
        return x + y >= half
               && (state.boardSizeX - x - 1) + (state.boardSizeY - y - 1) >= half
    }
    if (state.gameRuleMode === state.gameRuleHexGoTriangle) {
        if (state.boardSizeX !== state.boardSizeY)
            return false
        return x + y >= state.boardSizeX - 1
    }
    return true
}

function validXRangeForRow(state, y) {
    if (y < 0 || y >= state.boardSizeY || state.boardSizeX <= 0)
        return null
    var minX = 0
    var maxX = state.boardSizeX - 1
    if (state.gameRuleMode === state.gameRuleHexGoHexagon) {
        if (state.boardSizeX !== state.boardSizeY || state.boardSizeX % 2 === 0)
            return null
        var half = Math.floor(state.boardSizeX / 2)
        minX = Math.max(minX, half - y)
        maxX = Math.min(maxX, (state.boardSizeX - 1) + (state.boardSizeY - 1) - y - half)
    } else if (state.gameRuleMode === state.gameRuleHexGoTriangle) {
        if (state.boardSizeX !== state.boardSizeY)
            return null
        minX = Math.max(minX, state.boardSizeX - 1 - y)
    }
    minX = Math.ceil(minX)
    maxX = Math.floor(maxX)
    if (minX > maxX)
        return null
    return { "min": minX, "max": maxX }
}

function updateBoundsWithBoardPoint(state, bounds, basisX, basisY, x, y) {
    var display = hexDisplayCoordForBoard(state, x, y)
    var unitX = display.x * basisX.x + display.y * basisY.x
    var unitY = display.x * basisX.y + display.y * basisY.y
    if (!bounds.valid) {
        bounds.minX = unitX
        bounds.maxX = unitX
        bounds.minY = unitY
        bounds.maxY = unitY
        bounds.valid = true
        return
    }
    bounds.minX = Math.min(bounds.minX, unitX)
    bounds.maxX = Math.max(bounds.maxX, unitX)
    bounds.minY = Math.min(bounds.minY, unitY)
    bounds.maxY = Math.max(bounds.maxY, unitY)
}

function hexDisplaySizeX(state) {
    return hexTransposed(state) ? state.boardSizeY : state.boardSizeX
}

function hexDisplaySizeY(state) {
    return hexTransposed(state) ? state.boardSizeX : state.boardSizeY
}

function hexDisplayTransform(state) {
    var basisX
    var basisY
    if (hexHorizontalOrientation(state)) {
        basisX = { "x": HEX_ROW_HEIGHT, "y": -0.5 }
        basisY = { "x": HEX_ROW_HEIGHT, "y": 0.5 }
    } else if (hexVerticalOrientation(state)) {
        basisX = { "x": 0.5, "y": HEX_ROW_HEIGHT }
        basisY = { "x": -0.5, "y": HEX_ROW_HEIGHT }
    } else {
        basisX = { "x": hexFlippedX(state) ? -1 : 1, "y": 0 }
        basisY = {
            "x": hexFlippedX(state) ? -0.5 : 0.5,
            "y": hexFlippedY(state) ? -HEX_ROW_HEIGHT : HEX_ROW_HEIGHT
        }
    }

    var bounds = { "valid": false, "minX": 0, "maxX": 0, "minY": 0, "maxY": 0 }
    for (var y = 0; y < state.boardSizeY; ++y) {
        var range = validXRangeForRow(state, y)
        if (!range)
            continue
        updateBoundsWithBoardPoint(state, bounds, basisX, basisY, range.min, y)
        if (range.max !== range.min)
            updateBoundsWithBoardPoint(state, bounds, basisX, basisY, range.max, y)
    }
    if (!bounds.valid)
        updateBoundsWithBoardPoint(state, bounds, basisX, basisY, 0, 0)
    return {
        "basisX": basisX,
        "basisY": basisY,
        "minX": bounds.minX,
        "minY": bounds.minY,
        "width": Math.max(0.0001, bounds.maxX - bounds.minX),
        "height": Math.max(0.0001, bounds.maxY - bounds.minY)
    }
}

function hexDisplayCoordFromUnit(state, unitX, unitY, transformOverride) {
    var transform = transformOverride || hexDisplayTransform(state)
    var rawX = unitX + transform.minX
    var rawY = unitY + transform.minY
    var bx = transform.basisX
    var by = transform.basisY
    var determinant = bx.x * by.y - bx.y * by.x
    if (Math.abs(determinant) <= 0.000001)
        return { "x": 0, "y": 0 }
    return {
        "x": (rawX * by.y - rawY * by.x) / determinant,
        "y": (bx.x * rawY - bx.y * rawX) / determinant
    }
}

function effectiveCoordinateDisplayMode(state) {
    return CoordinateUtils.effectiveCoordinateFormat(state.boardSizeX,
                                                     state.boardSizeY,
                                                     state.coordinateDisplayMode)
}

function coordinatesVisible(state) {
    return effectiveCoordinateDisplayMode(state) !== state.coordinateDisplayNone
}

function xCoordinateText(state, x) {
    return CoordinateUtils.xCoordinateText(x, state.boardSizeX, state.boardSizeY, state.coordinateDisplayMode)
}

function yCoordinateText(state, y) {
    return CoordinateUtils.yCoordinateText(y, state.boardSizeX, state.boardSizeY, state.coordinateDisplayMode)
}

function gridUnitWidth(state, transformOverride) {
    if (hexBoard(state))
        return Math.max(1, (transformOverride || hexDisplayTransform(state)).width)
    if (torusGoBoard(state))
        return Math.max(1, state.boardSizeX + torusPaddingX(state) * 2)
    return squareCellBoard(state) ? Math.max(1, state.boardSizeX)
                                  : Math.max(1, state.boardSizeX - 1)
}

function gridUnitHeight(state, transformOverride) {
    if (hexBoard(state))
        return Math.max(1, (transformOverride || hexDisplayTransform(state)).height)
    if (torusGoBoard(state))
        return Math.max(1, state.boardSizeY + torusPaddingY(state) * 2)
    return squareCellBoard(state) ? Math.max(1, state.boardSizeY)
                                  : Math.max(1, state.boardSizeY - 1)
}

function createGeometry(state, width, height, options) {
    var visible = coordinatesVisible(state)
    var coordinateFontRatio = 0.32
    var coordinateCharWidthRatio = 0.58
    var coordinateGapRatio = 0.10
    var coordinateOuterGapRatio = 0.10
    var hexCellCoordinateExtraRatio = hexCellStyle(state) ? 0.35 : 0
    var stoneRadiusRatio = state.stoneScale * 0.5
    var horizontalPointRadiusRatio = hexBoard(state)
            ? (hexCellStyle(state) ? 0.5 : Math.max(stoneRadiusRatio, 0.5))
            : stoneRadiusRatio
    var verticalPointRadiusRatio = hexBoard(state)
            ? (hexCellStyle(state) ? HEX_CELL_RADIUS_RATIO : Math.max(stoneRadiusRatio, 0.5))
            : stoneRadiusRatio
    var maxXCoordinateChars = visible
            ? Math.max(String(xCoordinateText(state, 0)).length,
                       String(xCoordinateText(state, Math.max(0, state.boardSizeX - 1))).length)
            : 0
    var maxYCoordinateChars = visible
            ? Math.max(String(yCoordinateText(state, 0)).length,
                       String(yCoordinateText(state, Math.max(0, state.boardSizeY - 1))).length)
            : 0
    var xCoordinateTextWidthRatio = maxXCoordinateChars * coordinateCharWidthRatio * coordinateFontRatio
    var yCoordinateTextWidthRatio = maxYCoordinateChars * coordinateCharWidthRatio * coordinateFontRatio
    var horizontalPaddingRatio = visible
            ? horizontalPointRadiusRatio + coordinateGapRatio + yCoordinateTextWidthRatio
              + coordinateOuterGapRatio + hexCellCoordinateExtraRatio
            : horizontalPointRadiusRatio + coordinateOuterGapRatio
    var verticalPaddingRatio = visible
            ? verticalPointRadiusRatio + coordinateGapRatio + coordinateFontRatio
              + coordinateOuterGapRatio + hexCellCoordinateExtraRatio
            : verticalPointRadiusRatio + coordinateOuterGapRatio
    var outerMargin = options && options.outerMargin !== undefined ? options.outerMargin : (state.compactLayout ? 12 : 18)
    var availableWidth = Math.max(1, width - outerMargin * 2)
    var availableHeight = Math.max(1, height - outerMargin * 2)
    var transform = hexBoard(state) ? hexDisplayTransform(state) : null
    var unitWidth = gridUnitWidth(state, transform)
    var unitHeight = gridUnitHeight(state, transform)
    var cellSize = Math.max(0.1, Math.min(
        availableWidth / (unitWidth + horizontalPaddingRatio * 2),
        availableHeight / (unitHeight + verticalPaddingRatio * 2)))
    var gridWidth = cellSize * unitWidth
    var gridHeight = cellSize * unitHeight
    var geometry = {
        "width": width,
        "height": height,
        "coordinatesVisible": visible,
        "coordinateFontSize": coordinateFontRatio * cellSize,
        "xCoordinateLabelOffset": (verticalPointRadiusRatio + coordinateGapRatio
                                   + coordinateFontRatio * 0.5 + hexCellCoordinateExtraRatio) * cellSize,
        "yCoordinateLabelOffset": (horizontalPointRadiusRatio + coordinateGapRatio
                                   + yCoordinateTextWidthRatio * 0.5 + hexCellCoordinateExtraRatio) * cellSize,
        "boardPaddingX": horizontalPaddingRatio * cellSize,
        "boardPaddingY": verticalPaddingRatio * cellSize,
        "cellSize": cellSize,
        "gridUnitWidth": unitWidth,
        "gridUnitHeight": unitHeight,
        "gridWidth": gridWidth,
        "gridHeight": gridHeight,
        "hexTransform": transform,
        "boardLeft": Math.round((width - gridWidth) / 2),
        "boardTop": Math.round((height - gridHeight) / 2)
    }
    geometry.boardRight = geometry.boardLeft + geometry.gridWidth
    geometry.boardBottom = geometry.boardTop + geometry.gridHeight
    geometry.point = function(x, y) { return boardPointLocal(state, geometry, x, y) }
    geometry.hexDisplayPoint = function(x, y) { return hexDisplayPointLocal(state, geometry, x, y) }
    return geometry
}

function geometryFromScene(scene) {
    return {
        "width": scene.width,
        "height": scene.height,
        "coordinatesVisible": scene.coordinatesVisible,
        "coordinateFontSize": scene.coordinateFontSize,
        "xCoordinateLabelOffset": scene.xCoordinateLabelOffset,
        "yCoordinateLabelOffset": scene.yCoordinateLabelOffset,
        "boardPaddingX": scene.boardPaddingX,
        "boardPaddingY": scene.boardPaddingY,
        "cellSize": scene.cellSize,
        "gridUnitWidth": scene.gridUnitWidth,
        "gridUnitHeight": scene.gridUnitHeight,
        "gridWidth": scene.gridWidth,
        "gridHeight": scene.gridHeight,
        "hexTransform": scene.hexDisplayTransform,
        "boardLeft": scene.boardLeft,
        "boardTop": scene.boardTop,
        "boardRight": scene.boardRight,
        "boardBottom": scene.boardBottom,
        "point": function(x, y) { return scene.boardPointLocal(x, y) },
        "hexDisplayPoint": function(x, y) { return scene.hexDisplayPointLocal(x, y) }
    }
}

function hexDisplayCoordForBoard(state, x, y) {
    return hexTransposed(state) ? { "x": y, "y": x } : { "x": x, "y": y }
}

function hexDisplayPointLocal(state, geometry, x, y) {
    var transform = geometry.hexTransform || hexDisplayTransform(state)
    var unitX = x * transform.basisX.x + y * transform.basisY.x - transform.minX
    var unitY = x * transform.basisX.y + y * transform.basisY.y - transform.minY
    return {
        "x": geometry.boardLeft + unitX * geometry.cellSize,
        "y": geometry.boardTop + unitY * geometry.cellSize
    }
}

function boardPointLocal(state, geometry, x, y) {
    if (hexBoard(state)) {
        var display = hexDisplayCoordForBoard(state, x, y)
        return hexDisplayPointLocal(state, geometry, display.x, display.y)
    }
    if (squareCellBoard(state))
        return {
            "x": geometry.boardLeft + (x + 0.5) * geometry.cellSize,
            "y": geometry.boardTop + (y + 0.5) * geometry.cellSize
        }
    if (torusGoBoard(state))
        return torusDisplayPointLocal(state, geometry, x, y)
    return {
        "x": geometry.boardLeft + x * geometry.cellSize,
        "y": geometry.boardTop + y * geometry.cellSize
    }
}

function torusDisplayPointLocal(state, geometry, virtualX, virtualY) {
    return {
        "x": geometry.boardLeft + (virtualX + torusPaddingX(state) + 0.5) * geometry.cellSize,
        "y": geometry.boardTop + (virtualY + torusPaddingY(state) + 0.5) * geometry.cellSize
    }
}

function hexCellVertexStartAngle(state) {
    return hexHorizontalOrientation(state) ? -Math.PI * 2 / 3 : -Math.PI / 2
}

function hexCellSideCenterAngle(state, side) {
    return hexCellVertexStartAngle(state) + (side + 0.5) * Math.PI / 3
}

function hexCellPath(ctx, state, cx, cy, radius) {
    ctx.beginPath()
    var startAngle = hexCellVertexStartAngle(state)
    for (var i = 0; i < 6; ++i) {
        var angle = startAngle + i * Math.PI / 3
        var px = cx + Math.cos(angle) * radius
        var py = cy + Math.sin(angle) * radius
        if (i === 0)
            ctx.moveTo(px, py)
        else
            ctx.lineTo(px, py)
    }
    ctx.closePath()
}

function hexCellVertex(state, center, radius, index) {
    var angle = hexCellVertexStartAngle(state) + index * Math.PI / 3
    return {
        "x": center.x + Math.cos(angle) * radius,
        "y": center.y + Math.sin(angle) * radius
    }
}

function hexCellBoardVertex(state, geometry, x, y, index) {
    return hexCellVertex(state, geometry.point(x, y), geometry.cellSize / Math.sqrt(3), index)
}

function pointDistanceSquared(a, b) {
    var dx = a.x - b.x
    var dy = a.y - b.y
    return dx * dx + dy * dy
}

function offsetPoint(point, normal, distance) {
    return {
        "x": point.x + normal.x * distance,
        "y": point.y + normal.y * distance
    }
}

function boardCenter(state, geometry) {
    return {
        "x": geometry.boardLeft + geometry.gridWidth / 2,
        "y": geometry.boardTop + geometry.gridHeight / 2
    }
}

function normalizedVector(x, y, fallbackX, fallbackY) {
    var length = Math.sqrt(x * x + y * y)
    if (length <= 0.000001)
        return { "x": fallbackX, "y": fallbackY }
    return { "x": x / length, "y": y / length }
}

function outwardNormalForSegment(state, geometry, a, b) {
    var center = boardCenter(state, geometry)
    var dx = b.x - a.x
    var dy = b.y - a.y
    var normal = normalizedVector(-dy, dx, 0, -1)
    var mid = { "x": (a.x + b.x) / 2, "y": (a.y + b.y) / 2 }
    var awayX = mid.x - center.x
    var awayY = mid.y - center.y
    if (normal.x * awayX + normal.y * awayY < 0) {
        normal.x = -normal.x
        normal.y = -normal.y
    }
    return normal
}

function logicalEdgeNormal(state, geometry, edge) {
    var maxX = Math.max(0, state.boardSizeX - 1)
    var maxY = Math.max(0, state.boardSizeY - 1)
    if (edge === "top")
        return outwardNormalForSegment(state, geometry, geometry.point(0, 0), geometry.point(maxX, 0))
    if (edge === "bottom")
        return outwardNormalForSegment(state, geometry, geometry.point(0, maxY), geometry.point(maxX, maxY))
    if (edge === "left")
        return outwardNormalForSegment(state, geometry, geometry.point(0, 0), geometry.point(0, maxY))
    return outwardNormalForSegment(state, geometry, geometry.point(maxX, 0), geometry.point(maxX, maxY))
}

function sideIndexForNeighbor(state, geometry, x, y, neighborX, neighborY) {
    var center = geometry.point(x, y)
    var neighbor = geometry.point(neighborX, neighborY)
    var vector = normalizedVector(neighbor.x - center.x, neighbor.y - center.y, 1, 0)
    var bestSide = 0
    var bestDot = -999999
    for (var side = 0; side < 6; ++side) {
        var angle = hexCellSideCenterAngle(state, side)
        var dot = vector.x * Math.cos(angle) + vector.y * Math.sin(angle)
        if (dot > bestDot) {
            bestDot = dot
            bestSide = side
        }
    }
    return bestSide
}

function hexBoundarySegmentForMissingNeighbor(state, geometry, x, y, neighborX, neighborY) {
    var side = sideIndexForNeighbor(state, geometry, x, y, neighborX, neighborY)
    return {
        "a": hexCellBoardVertex(state, geometry, x, y, side),
        "b": hexCellBoardVertex(state, geometry, x, y, (side + 1) % 6)
    }
}

function boundaryChainsFromSegments(segments, snapDistance) {
    var remaining = segments.slice()
    var chains = []
    var snapDistanceSquared = snapDistance * snapDistance
    while (remaining.length > 0) {
        var first = remaining.shift()
        var chain = [first.a, first.b]
        var extended = true
        while (extended && remaining.length > 0) {
            extended = false
            var best = null
            var bestDistance = snapDistanceSquared
            for (var i = 0; i < remaining.length; ++i) {
                var segment = remaining[i]
                var head = chain[0]
                var tail = chain[chain.length - 1]
                var tailToA = pointDistanceSquared(tail, segment.a)
                var tailToB = pointDistanceSquared(tail, segment.b)
                var headToA = pointDistanceSquared(head, segment.a)
                var headToB = pointDistanceSquared(head, segment.b)
                if (tailToA <= bestDistance) {
                    bestDistance = tailToA
                    best = { "index": i, "mode": "tailA" }
                }
                if (tailToB <= bestDistance) {
                    bestDistance = tailToB
                    best = { "index": i, "mode": "tailB" }
                }
                if (headToA <= bestDistance) {
                    bestDistance = headToA
                    best = { "index": i, "mode": "headA" }
                }
                if (headToB <= bestDistance) {
                    bestDistance = headToB
                    best = { "index": i, "mode": "headB" }
                }
            }
            if (best !== null) {
                var chosen = remaining.splice(best.index, 1)[0]
                if (best.mode === "tailA")
                    chain.push(chosen.b)
                else if (best.mode === "tailB")
                    chain.push(chosen.a)
                else if (best.mode === "headA")
                    chain.unshift(chosen.b)
                else
                    chain.unshift(chosen.a)
                extended = true
            }
        }
        chains.push(chain)
    }
    return chains
}

function canvasFont(state, size, bold) {
    var family = String(state.coordinateFontFamily).replace(/"/g, "")
    return (bold ? "700 " : "400 ") + Math.max(1, Math.round(size)) + "px \"" + family + "\", sans-serif"
}

function drawCenteredText(ctx, state, text, x, y, color, size, bold, maxWidth) {
    ctx.save()
    ctx.fillStyle = color
    ctx.font = canvasFont(state, size, bold)
    ctx.textAlign = "center"
    ctx.textBaseline = "middle"
    if (maxWidth !== undefined)
        ctx.fillText(text, x, y, maxWidth)
    else
        ctx.fillText(text, x, y)
    ctx.restore()
}

function starPoints(size) {
    if (size >= 19)
        return [3, Math.floor(size / 2), size - 4]
    if (size >= 13)
        return [3, size - 4]
    if (size >= 9)
        return [2, Math.floor(size / 2), size - 3]
    return []
}

function drawHexBoundaryPath(ctx, points, color, cell) {
    if (!points || points.length < 2)
        return
    ctx.save()
    ctx.globalAlpha = 1
    ctx.lineCap = "round"
    ctx.lineJoin = "miter"
    ctx.miterLimit = 4
    if (color === "#ffffff") {
        ctx.strokeStyle = "#0b3d73"
        ctx.lineWidth = Math.max(4, cell * 0.16)
        ctx.beginPath()
        ctx.moveTo(points[0].x, points[0].y)
        for (var back = 1; back < points.length; ++back)
            ctx.lineTo(points[back].x, points[back].y)
        ctx.stroke()
    }
    ctx.strokeStyle = color
    ctx.lineWidth = Math.max(3, cell * 0.10)
    ctx.beginPath()
    ctx.moveTo(points[0].x, points[0].y)
    for (var i = 1; i < points.length; ++i)
        ctx.lineTo(points[i].x, points[i].y)
    ctx.stroke()
    ctx.restore()
}

function lineIntersection(a1, a2, b1, b2) {
    var rx = a2.x - a1.x
    var ry = a2.y - a1.y
    var sx = b2.x - b1.x
    var sy = b2.y - b1.y
    var denominator = rx * sy - ry * sx
    if (Math.abs(denominator) <= 0.000001)
        return null
    var qpx = b1.x - a1.x
    var qpy = b1.y - a1.y
    var t = (qpx * sy - qpy * sx) / denominator
    return { "x": a1.x + t * rx, "y": a1.y + t * ry }
}

function offsetBoundaryPolyline(points, offset, geometry) {
    if (!points || points.length < 2 || offset <= 0)
        return points
    var center = {
        "x": geometry.boardLeft + geometry.gridWidth / 2,
        "y": geometry.boardTop + geometry.gridHeight / 2
    }
    var normals = []
    for (var i = 0; i < points.length - 1; ++i) {
        var a = points[i]
        var b = points[i + 1]
        var dx = b.x - a.x
        var dy = b.y - a.y
        var normal = normalizedVector(-dy, dx, 0, -1)
        var mid = { "x": (a.x + b.x) / 2, "y": (a.y + b.y) / 2 }
        if (normal.x * (mid.x - center.x) + normal.y * (mid.y - center.y) < 0) {
            normal.x = -normal.x
            normal.y = -normal.y
        }
        normals.push(normal)
    }

    var result = []
    result.push(offsetPoint(points[0], normals[0], offset))
    for (var p = 1; p < points.length - 1; ++p) {
        var prevNormal = normals[p - 1]
        var nextNormal = normals[p]
        var prevA = offsetPoint(points[p - 1], prevNormal, offset)
        var prevB = offsetPoint(points[p], prevNormal, offset)
        var nextA = offsetPoint(points[p], nextNormal, offset)
        var nextB = offsetPoint(points[p + 1], nextNormal, offset)
        var intersection = lineIntersection(prevA, prevB, nextA, nextB)
        if (intersection)
            result.push(intersection)
        else
            result.push({ "x": (prevB.x + nextA.x) / 2, "y": (prevB.y + nextA.y) / 2 })
    }
    result.push(offsetPoint(points[points.length - 1], normals[normals.length - 1], offset))
    return result
}

function drawHexBoundaryPathOffset(ctx, points, color, cell, offset, geometry) {
    drawHexBoundaryPath(ctx, offsetBoundaryPolyline(points, offset, geometry), color, cell)
}

function hexBoundaryOuterLineWidth(color, cell) {
    return color === "#ffffff" ? Math.max(4, cell * 0.16)
                               : Math.max(3, cell * 0.10)
}

function drawHexStraightEdge(ctx, p1, p2, color, cell) {
    drawHexBoundaryPath(ctx, [p1, p2], color, cell)
}

function drawHexCellColoredEdges(ctx, state, geometry) {
    var cell = geometry.cellSize
    var maxX = Math.max(0, state.boardSizeX - 1)
    var maxY = Math.max(0, state.boardSizeY - 1)
    var topSegments = []
    var bottomSegments = []
    var leftSegments = []
    var rightSegments = []
    var blackOffset = hexBoundaryOuterLineWidth("#000000", cell) * 0.5
    var whiteOffset = hexBoundaryOuterLineWidth("#ffffff", cell) * 0.5

    for (var lx = 0; lx < state.boardSizeX; ++lx) {
        topSegments.push(hexBoundarySegmentForMissingNeighbor(state, geometry, lx, 0, lx, -1))
        topSegments.push(hexBoundarySegmentForMissingNeighbor(state, geometry, lx, 0, lx + 1, -1))
        bottomSegments.push(hexBoundarySegmentForMissingNeighbor(state, geometry, lx, maxY, lx - 1, maxY + 1))
        bottomSegments.push(hexBoundarySegmentForMissingNeighbor(state, geometry, lx, maxY, lx, maxY + 1))
    }

    for (var ly = 0; ly < state.boardSizeY; ++ly) {
        leftSegments.push(hexBoundarySegmentForMissingNeighbor(state, geometry, 0, ly, -1, ly))
        leftSegments.push(hexBoundarySegmentForMissingNeighbor(state, geometry, 0, ly, -1, ly + 1))
        rightSegments.push(hexBoundarySegmentForMissingNeighbor(state, geometry, maxX, ly, maxX + 1, ly - 1))
        rightSegments.push(hexBoundarySegmentForMissingNeighbor(state, geometry, maxX, ly, maxX + 1, ly))
    }

    var snap = Math.max(1, cell * 0.12)
    var topChains = boundaryChainsFromSegments(topSegments, snap)
    var bottomChains = boundaryChainsFromSegments(bottomSegments, snap)
    var leftChains = boundaryChainsFromSegments(leftSegments, snap)
    var rightChains = boundaryChainsFromSegments(rightSegments, snap)
    for (var top = 0; top < topChains.length; ++top)
        drawHexBoundaryPathOffset(ctx, topChains[top], "#000000", cell, blackOffset, geometry)
    for (var bottom = 0; bottom < bottomChains.length; ++bottom)
        drawHexBoundaryPathOffset(ctx, bottomChains[bottom], "#000000", cell, blackOffset, geometry)
    for (var left = 0; left < leftChains.length; ++left)
        drawHexBoundaryPathOffset(ctx, leftChains[left], "#ffffff", cell, whiteOffset, geometry)
    for (var right = 0; right < rightChains.length; ++right)
        drawHexBoundaryPathOffset(ctx, rightChains[right], "#ffffff", cell, whiteOffset, geometry)
}

function drawStone(ctx, state, geometry, x, y, player, radius) {
    var point = geometry.point(x, y)
    drawStoneAtPoint(ctx, state, geometry, point, player, radius)
}

function drawStoneAtPoint(ctx, state, geometry, point, player, radius) {
    if (hexCellStyle(state)) {
        ctx.save()
        hexCellPath(ctx, state, point.x, point.y, geometry.cellSize / Math.sqrt(3))
        ctx.fillStyle = player === 1 ? "#101418" : "#ffffff"
        ctx.fill()
        ctx.strokeStyle = "#0b3d73"
        ctx.lineWidth = Math.max(1, geometry.cellSize * 0.035)
        ctx.stroke()
        ctx.restore()
        return
    }
    var gradient = ctx.createRadialGradient(point.x - radius * 0.28,
                                            point.y - radius * 0.34,
                                            radius * 0.12,
                                            point.x,
                                            point.y,
                                            radius)
    if (player === 1) {
        gradient.addColorStop(0, "#555b60")
        gradient.addColorStop(0.36, "#15191d")
        gradient.addColorStop(1, "#020304")
    } else {
        gradient.addColorStop(0, "#ffffff")
        gradient.addColorStop(0.48, "#fff8e6")
        gradient.addColorStop(1, "#d9cba8")
    }
    ctx.fillStyle = gradient
    ctx.beginPath()
    ctx.arc(point.x, point.y, radius, 0, Math.PI * 2)
    ctx.fill()
    ctx.strokeStyle = player === 1 ? "#000000" : "#9d9279"
    ctx.lineWidth = 1
    ctx.stroke()
}

function drawBoardBackground(ctx, state, geometry, width, height) {
    ctx.save()
    ctx.fillStyle = hexCellStyle(state) ? "#f2cc62" : state.boardWoodColor
    ctx.fillRect(0, 0, width, height)
    ctx.restore()
}

function drawTorusBoundary(ctx, state, geometry) {
    var padX = torusPaddingX(state)
    var padY = torusPaddingY(state)
    if (padX <= 0 && padY <= 0)
        return

    var cell = geometry.cellSize
    var left = geometry.boardLeft + padX * cell
    var top = geometry.boardTop + padY * cell
    var width = state.boardSizeX * cell
    var height = state.boardSizeY * cell
    ctx.save()
    ctx.strokeStyle = "#e3342f"
    ctx.globalAlpha = 0.95
    ctx.lineWidth = Math.max(1, cell * 0.035)
    ctx.strokeRect(left, top, width, height)
    ctx.restore()
}

function drawTorusGrid(ctx, state, geometry) {
    var cell = geometry.cellSize
    var padX = torusPaddingX(state)
    var padY = torusPaddingY(state)
    var startX = -padX
    var endX = state.boardSizeX - 1 + padX
    var startY = -padY
    var endY = state.boardSizeY - 1 + padY
    var leftPoint = torusDisplayPointLocal(state, geometry, startX, 0)
    var rightPoint = torusDisplayPointLocal(state, geometry, endX, 0)
    var topPoint = torusDisplayPointLocal(state, geometry, 0, startY)
    var bottomPoint = torusDisplayPointLocal(state, geometry, 0, endY)
    var lineExtend = padX <= 0 && padY <= 0 ? cell * 0.5 : 0
    var horizontalLeft = leftPoint.x - lineExtend
    var horizontalRight = rightPoint.x + lineExtend
    var verticalTop = topPoint.y - lineExtend
    var verticalBottom = bottomPoint.y + lineExtend

    for (var y = startY; y <= endY; ++y) {
        var p = torusDisplayPointLocal(state, geometry, 0, y)
        ctx.beginPath()
        ctx.moveTo(horizontalLeft, p.y)
        ctx.lineTo(horizontalRight, p.y)
        ctx.stroke()
    }
    for (var x = startX; x <= endX; ++x) {
        var px = torusDisplayPointLocal(state, geometry, x, 0)
        ctx.beginPath()
        ctx.moveTo(px.x, verticalTop)
        ctx.lineTo(px.x, verticalBottom)
        ctx.stroke()
    }
    drawTorusBoundary(ctx, state, geometry)
}

function drawGrid(ctx, state, geometry) {
    var cell = geometry.cellSize
    ctx.save()
    ctx.strokeStyle = hexCellStyle(state) ? "#0b3d73" : "#2d2114"
    ctx.globalAlpha = hexCellStyle(state) ? 1 : state.gridOpacity
    ctx.lineWidth = Math.max(1, state.gridLineWidth)
    if (hexBoard(state)) {
        if (hexCellStyle(state)) {
            for (var cellY = 0; cellY < state.boardSizeY; ++cellY) {
                for (var cellX = 0; cellX < state.boardSizeX; ++cellX) {
                    if (!pointInRuleBoard(state, cellX, cellY))
                        continue
                    var center = geometry.point(cellX, cellY)
                    hexCellPath(ctx, state, center.x, center.y, cell / Math.sqrt(3))
                    ctx.fillStyle = "#f2cc62"
                    ctx.fill()
                    ctx.stroke()
                }
            }
            if (state.gameRuleMode === state.gameRuleHex)
                drawHexCellColoredEdges(ctx, state, geometry)
        } else {
            var edgeOffsets = [
                { "dx": 1, "dy": 0 },
                { "dx": 0, "dy": 1 },
                { "dx": -1, "dy": 1 }
            ]
            for (var hy = 0; hy < state.boardSizeY; ++hy) {
                for (var hx = 0; hx < state.boardSizeX; ++hx) {
                    if (!pointInRuleBoard(state, hx, hy))
                        continue
                    var start = geometry.point(hx, hy)
                    for (var edge = 0; edge < edgeOffsets.length; ++edge) {
                        var offset = edgeOffsets[edge]
                        var ex = hx + offset.dx
                        var ey = hy + offset.dy
                        if (!pointInRuleBoard(state, ex, ey))
                            continue
                        var end = geometry.point(ex, ey)
                        ctx.beginPath()
                        ctx.moveTo(start.x, start.y)
                        ctx.lineTo(end.x, end.y)
                        ctx.stroke()
                    }
                }
            }
            if (state.gameRuleMode !== state.gameRuleHex) {
                ctx.restore()
                return
            }
            var blackTop1 = geometry.point(0, 0)
            var blackTop2 = geometry.point(state.boardSizeX - 1, 0)
            var blackBottom1 = geometry.point(0, state.boardSizeY - 1)
            var blackBottom2 = geometry.point(state.boardSizeX - 1, state.boardSizeY - 1)
            var whiteLeft1 = geometry.point(0, 0)
            var whiteLeft2 = geometry.point(0, state.boardSizeY - 1)
            var whiteRight1 = geometry.point(state.boardSizeX - 1, 0)
            var whiteRight2 = geometry.point(state.boardSizeX - 1, state.boardSizeY - 1)
            var triangleEdgeOffset = cell * 0.5
            var blackTopNormal = logicalEdgeNormal(state, geometry, "top")
            var blackBottomNormal = logicalEdgeNormal(state, geometry, "bottom")
            var whiteLeftNormal = logicalEdgeNormal(state, geometry, "left")
            var whiteRightNormal = logicalEdgeNormal(state, geometry, "right")
            drawHexStraightEdge(ctx,
                                offsetPoint(blackTop1, blackTopNormal, triangleEdgeOffset),
                                offsetPoint(blackTop2, blackTopNormal, triangleEdgeOffset),
                                "#000000", cell)
            drawHexStraightEdge(ctx,
                                offsetPoint(blackBottom1, blackBottomNormal, triangleEdgeOffset),
                                offsetPoint(blackBottom2, blackBottomNormal, triangleEdgeOffset),
                                "#000000", cell)
            drawHexStraightEdge(ctx,
                                offsetPoint(whiteLeft1, whiteLeftNormal, triangleEdgeOffset),
                                offsetPoint(whiteLeft2, whiteLeftNormal, triangleEdgeOffset),
                                "#ffffff", cell)
            drawHexStraightEdge(ctx,
                                offsetPoint(whiteRight1, whiteRightNormal, triangleEdgeOffset),
                                offsetPoint(whiteRight2, whiteRightNormal, triangleEdgeOffset),
                                "#ffffff", cell)
        }
    } else if (torusGoBoard(state)) {
        drawTorusGrid(ctx, state, geometry)
    } else {
        var xLineCount = squareCellBoard(state) ? state.boardSizeX + 1 : state.boardSizeX
        var yLineCount = squareCellBoard(state) ? state.boardSizeY + 1 : state.boardSizeY
        for (var x = 0; x < xLineCount; ++x) {
            var px = geometry.boardLeft + x * cell
            ctx.beginPath()
            ctx.moveTo(px, geometry.boardTop)
            ctx.lineTo(px, geometry.boardBottom)
            ctx.stroke()
        }
        for (var y = 0; y < yLineCount; ++y) {
            var py = geometry.boardTop + y * cell
            ctx.beginPath()
            ctx.moveTo(geometry.boardLeft, py)
            ctx.lineTo(geometry.boardRight, py)
            ctx.stroke()
        }
    }
    ctx.restore()
}

function drawStarPoints(ctx, state, geometry) {
    if (state.gameRuleMode !== state.gameRuleGo && state.gameRuleMode !== state.gameRuleTorusGo)
        return
    var cell = geometry.cellSize
    var xs = starPoints(state.boardSizeX)
    var ys = starPoints(state.boardSizeY)
    ctx.save()
    ctx.fillStyle = "#2d2114"
    for (var starX = 0; starX < xs.length; ++starX) {
        for (var starY = 0; starY < ys.length; ++starY) {
            var star = geometry.point(xs[starX], ys[starY])
            ctx.beginPath()
            ctx.arc(star.x, star.y, Math.max(2.8, cell * 0.065), 0, Math.PI * 2)
            ctx.fill()
        }
    }
    ctx.restore()
}

function coordinateEdgePointCount(state, edge) {
    var count = 0
    var maxX = Math.max(0, state.boardSizeX - 1)
    var maxY = Math.max(0, state.boardSizeY - 1)
    if (edge === "top" || edge === "bottom") {
        var y = edge === "top" ? 0 : maxY
        for (var x = 0; x < state.boardSizeX; ++x) {
            if (pointInRuleBoard(state, x, y))
                ++count
        }
    } else {
        var xEdge = edge === "left" ? 0 : maxX
        for (var yEdge = 0; yEdge < state.boardSizeY; ++yEdge) {
            if (pointInRuleBoard(state, xEdge, yEdge))
                ++count
        }
    }
    return count
}

function drawCoordinates(ctx, state, geometry) {
    if (!geometry.coordinatesVisible)
        return
    var cell = geometry.cellSize
    var maxX = Math.max(0, state.boardSizeX - 1)
    var maxY = Math.max(0, state.boardSizeY - 1)
    var drawTop = coordinateEdgePointCount(state, "top") > 1
    var drawBottom = coordinateEdgePointCount(state, "bottom") > 1
    var drawLeft = coordinateEdgePointCount(state, "left") > 1
    var drawRight = coordinateEdgePointCount(state, "right") > 1
    var topNormal = logicalEdgeNormal(state, geometry, "top")
    var bottomNormal = logicalEdgeNormal(state, geometry, "bottom")
    var leftNormal = logicalEdgeNormal(state, geometry, "left")
    var rightNormal = logicalEdgeNormal(state, geometry, "right")
    ctx.save()
    ctx.font = canvasFont(state, geometry.coordinateFontSize, false)
    ctx.fillStyle = "#4f371f"
    ctx.textAlign = "center"
    ctx.textBaseline = "middle"
    for (var lx = 0; lx < state.boardSizeX; ++lx) {
        var xLabel = xCoordinateText(state, lx)
        if (drawTop && pointInRuleBoard(state, lx, 0)) {
            var topPoint = geometry.point(lx, 0)
            ctx.fillText(xLabel,
                         topPoint.x + topNormal.x * geometry.xCoordinateLabelOffset,
                         topPoint.y + topNormal.y * geometry.xCoordinateLabelOffset,
                         cell * 0.96)
        }
        if (drawBottom && pointInRuleBoard(state, lx, maxY)) {
            var bottomPoint = geometry.point(lx, maxY)
            ctx.fillText(xLabel,
                         bottomPoint.x + bottomNormal.x * geometry.xCoordinateLabelOffset,
                         bottomPoint.y + bottomNormal.y * geometry.xCoordinateLabelOffset,
                         cell * 0.96)
        }
    }
    for (var ly = 0; ly < state.boardSizeY; ++ly) {
        var yLabel = yCoordinateText(state, ly)
        var yLabelMaxWidth = Math.max(1, geometry.boardPaddingX - cell * (state.stoneScale * 0.5 + 0.10))
        if (drawLeft && pointInRuleBoard(state, 0, ly)) {
            var leftPoint = geometry.point(0, ly)
            ctx.fillText(yLabel,
                         leftPoint.x + leftNormal.x * geometry.yCoordinateLabelOffset,
                         leftPoint.y + leftNormal.y * geometry.yCoordinateLabelOffset,
                         yLabelMaxWidth)
        }
        if (drawRight && pointInRuleBoard(state, maxX, ly)) {
            var rightPoint = geometry.point(maxX, ly)
            ctx.fillText(yLabel,
                         rightPoint.x + rightNormal.x * geometry.yCoordinateLabelOffset,
                         rightPoint.y + rightNormal.y * geometry.yCoordinateLabelOffset,
                         yLabelMaxWidth)
        }
    }
    ctx.restore()
}

function drawBoardBase(ctx, state, geometry) {
    drawGrid(ctx, state, geometry)
    drawStarPoints(ctx, state, geometry)
    drawCoordinates(ctx, state, geometry)
}

function drawTorusRepeatedStones(ctx, state, geometry, stones, radius) {
    if (!torusGoBoard(state))
        return
    var padX = torusPaddingX(state)
    var padY = torusPaddingY(state)
    if (padX <= 0 && padY <= 0)
        return

    var minX = -padX
    var maxX = state.boardSizeX - 1 + padX
    var minY = -padY
    var maxY = state.boardSizeY - 1 + padY
    for (var i = 0; i < stones.length; ++i) {
        var stone = stones[i]
        var minShiftX = Math.ceil((minX - stone.x) / Math.max(1, state.boardSizeX))
        var maxShiftX = Math.floor((maxX - stone.x) / Math.max(1, state.boardSizeX))
        var minShiftY = Math.ceil((minY - stone.y) / Math.max(1, state.boardSizeY))
        var maxShiftY = Math.floor((maxY - stone.y) / Math.max(1, state.boardSizeY))
        for (var shiftY = minShiftY; shiftY <= maxShiftY; ++shiftY) {
            var y = stone.y + shiftY * state.boardSizeY
            for (var shiftX = minShiftX; shiftX <= maxShiftX; ++shiftX) {
                var x = stone.x + shiftX * state.boardSizeX
                if (x >= 0 && x < state.boardSizeX && y >= 0 && y < state.boardSizeY)
                    continue
                drawStoneAtPoint(ctx, state, geometry, torusDisplayPointLocal(state, geometry, x, y), stone.player, radius)
            }
        }
    }
}

function drawBoard(ctx, state, geometry, options) {
    var opts = options || ({})
    if (opts.fillBackground === true)
        drawBoardBackground(ctx, state, geometry, opts.width || geometry.width, opts.height || geometry.height)
    drawBoardBase(ctx, state, geometry)
    var stones = opts.stones || []
    var radius = Math.max(8, geometry.cellSize * state.stoneScale * 0.5)
    drawTorusRepeatedStones(ctx, state, geometry, stones, radius)
    for (var i = 0; i < stones.length; ++i)
        drawStone(ctx, state, geometry, stones[i].x, stones[i].y, stones[i].player, radius)
}
