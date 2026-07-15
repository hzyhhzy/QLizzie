.pragma library

var RULE_GO = 0
var RULE_GOMOKU = 1
var RULE_HEX = 2
var RULE_SQUARE_FREE = 3
var RULE_REVERSI = 4
var RULE_CONNECT6 = 5
var RULE_HEX_GO_PARALLELOGRAM = 6
var RULE_HEX_GO_HEXAGON = 7
var RULE_HEX_GO_TRIANGLE = 8
var RULE_ATAXX = 9
var RULE_BREAKTHROUGH = 10
var RULE_TORUS_GO = 11
var RULE_TWO_LIB_GO = 12
var RULE_DOTS_AND_BOXES = 13

var GOMOKU_RULE_FREESTYLE = 0
var GOMOKU_RULE_STANDARD = 1
var GOMOKU_RULE_RENJU = 2
var GOMOKU_RULE_CARO = 3
var GOMOKU_RULE_DIRECT_FOUR = 4
var GOMOKU_RULE_CARO_NO_SIX = 5

var NEIGHBOR_OFFSETS = [
    { "dx": 1, "dy": 0 },
    { "dx": -1, "dy": 0 },
    { "dx": 0, "dy": 1 },
    { "dx": 0, "dy": -1 }
]

var HEX_NEIGHBOR_OFFSETS = [
    { "dx": 1, "dy": 0 },
    { "dx": -1, "dy": 0 },
    { "dx": 0, "dy": 1 },
    { "dx": 0, "dy": -1 },
    { "dx": 1, "dy": -1 },
    { "dx": -1, "dy": 1 }
]

var GOMOKU_DIRECTIONS = [
    { "dx": 1, "dy": 0 },
    { "dx": 0, "dy": 1 },
    { "dx": 1, "dy": 1 },
    { "dx": 1, "dy": -1 }
]

var SQUARE_DIRECTIONS = [
    { "dx": 1, "dy": 0 },
    { "dx": -1, "dy": 0 },
    { "dx": 0, "dy": 1 },
    { "dx": 0, "dy": -1 },
    { "dx": 1, "dy": 1 },
    { "dx": -1, "dy": -1 },
    { "dx": 1, "dy": -1 },
    { "dx": -1, "dy": 1 }
]

function keyFor(x, y) {
    return x + "," + y
}

function pointInBoard(dims, x, y) {
    return x >= 0 && x < dims.x && y >= 0 && y < dims.y
}

function isHexGoRule(ruleMode) {
    return ruleMode === RULE_HEX_GO_PARALLELOGRAM
           || ruleMode === RULE_HEX_GO_HEXAGON
           || ruleMode === RULE_HEX_GO_TRIANGLE
}

function isGoCaptureRule(ruleMode) {
    return ruleMode === RULE_GO
           || ruleMode === RULE_TORUS_GO
           || ruleMode === RULE_TWO_LIB_GO
           || isHexGoRule(ruleMode)
}

function isHexGridRule(ruleMode) {
    return ruleMode === RULE_HEX || isHexGoRule(ruleMode)
}

function pointInRuleBoard(dims, x, y, ruleMode) {
    if (!pointInBoard(dims, x, y))
        return false
    if (ruleMode === RULE_HEX_GO_HEXAGON) {
        if (dims.x !== dims.y || dims.x % 2 === 0)
            return false
        var half = Math.floor(dims.x / 2)
        return x + y >= half
               && (dims.x - x - 1) + (dims.y - y - 1) >= half
    }
    if (ruleMode === RULE_HEX_GO_TRIANGLE) {
        if (dims.x !== dims.y)
            return false
        return x + y >= dims.x - 1
    }
    return true
}

function dotsAndBoxesPointKind(x, y) {
    if (x % 2 === 0 && y % 2 === 0)
        return "dot"
    if (x % 2 !== y % 2)
        return "edge"
    return "box"
}

function dotsAndBoxesCompletedBoxes(map, dims, edgeX, edgeY) {
    var boxes = []
    var candidates = edgeX % 2 === 0
                     ? [{ "x": edgeX - 1, "y": edgeY }, { "x": edgeX + 1, "y": edgeY }]
                     : [{ "x": edgeX, "y": edgeY - 1 }, { "x": edgeX, "y": edgeY + 1 }]
    for (var i = 0; i < candidates.length; ++i) {
        var box = candidates[i]
        if (!pointInBoard(dims, box.x, box.y) || dotsAndBoxesPointKind(box.x, box.y) !== "box")
            continue
        var closed = stoneMapPlayerAt(map, box.x - 1, box.y) !== 0
                     && stoneMapPlayerAt(map, box.x + 1, box.y) !== 0
                     && stoneMapPlayerAt(map, box.x, box.y - 1) !== 0
                     && stoneMapPlayerAt(map, box.x, box.y + 1) !== 0
        if (closed && stoneMapPlayerAt(map, box.x, box.y) === 0)
            boxes.push(box)
    }
    return boxes
}

function applyDotsAndBoxesMoveOnMap(map, dims, stoneItem) {
    if (!pointInBoard(dims, stoneItem.x, stoneItem.y)
            || dotsAndBoxesPointKind(stoneItem.x, stoneItem.y) !== "edge"
            || stoneMapPlayerAt(map, stoneItem.x, stoneItem.y) !== 0)
        return { "ok": false, "completedBoxes": [] }

    map[stoneItem.key] = stoneItem
    var completed = dotsAndBoxesCompletedBoxes(map, dims, stoneItem.x, stoneItem.y)
    for (var i = 0; i < completed.length; ++i) {
        var box = completed[i]
        var key = keyFor(box.x, box.y)
        map[key] = {
            "x": box.x, "y": box.y, "key": key,
            "player": stoneItem.player,
            "moveNumber": stoneItem.moveNumber,
            "nodeId": stoneItem.nodeId,
            "derivedBox": true
        }
    }
    return { "ok": true, "completedBoxes": completed }
}

function neighborOffsetsForRule(ruleMode) {
    return isHexGridRule(ruleMode) ? HEX_NEIGHBOR_OFFSETS : NEIGHBOR_OFFSETS
}

function wrappedCoordinate(value, size) {
    if (size <= 0)
        return value
    var result = value % size
    return result < 0 ? result + size : result
}

function neighborPointsForRule(dims, x, y, ruleMode) {
    var offsets = neighborOffsetsForRule(ruleMode)
    var points = []
    var seen = ({})
    for (var i = 0; i < offsets.length; ++i) {
        var offset = offsets[i]
        var nx = x + offset.dx
        var ny = y + offset.dy
        if (ruleMode === RULE_TORUS_GO) {
            nx = wrappedCoordinate(nx, dims.x)
            ny = wrappedCoordinate(ny, dims.y)
        }
        if (!pointInRuleBoard(dims, nx, ny, ruleMode))
            continue
        var key = keyFor(nx, ny)
        if (seen[key])
            continue
        seen[key] = true
        points.push({ "x": nx, "y": ny, "key": key })
    }
    return points
}

function stoneMapDataAt(map, x, y) {
    var value = map[keyFor(x, y)]
    return value === undefined ? null : value
}

function stoneMapPlayerAt(map, x, y) {
    var value = stoneMapDataAt(map, x, y)
    return value ? value.player : 0
}

function cloneStoneMap(map) {
    var nextMap = ({})
    for (var key in map) {
        var value = map[key]
        nextMap[key] = {
            "x": value.x,
            "y": value.y,
            "key": value.key,
            "player": value.player,
            "moveNumber": value.moveNumber,
            "nodeId": value.nodeId
        }
    }
    return nextMap
}

function copyStoneItem(stone) {
    return {
        "x": stone.x,
        "y": stone.y,
        "key": stone.key,
        "player": stone.player,
        "moveNumber": stone.moveNumber,
        "nodeId": stone.nodeId
    }
}

function collectGroupInMap(map, dims, x, y, visited, ruleMode) {
    var start = stoneMapDataAt(map, x, y)
    if (!start)
        return []

    var group = []
    var stack = [start]
    var player = start.player
    while (stack.length > 0) {
        var stone = stack.pop()
        if (visited[stone.key])
            continue

        visited[stone.key] = true
        group.push(stone)
        var neighbors = neighborPointsForRule(dims, stone.x, stone.y, ruleMode)
        for (var i = 0; i < neighbors.length; ++i) {
            var neighborPoint = neighbors[i]
            var neighbor = stoneMapDataAt(map, neighborPoint.x, neighborPoint.y)
            if (neighbor && neighbor.player === player && !visited[neighbor.key])
                stack.push(neighbor)
        }
    }
    return group
}

function groupHasLibertyInMap(map, dims, group, ruleMode) {
    for (var i = 0; i < group.length; ++i) {
        var stone = group[i]
        var neighbors = neighborPointsForRule(dims, stone.x, stone.y, ruleMode)
        for (var n = 0; n < neighbors.length; ++n) {
            var neighbor = neighbors[n]
            if (stoneMapPlayerAt(map, neighbor.x, neighbor.y) === 0)
                return true
        }
    }
    return false
}

function groupLibertyCountInMap(map, dims, group, ruleMode) {
    var liberties = ({})
    var count = 0
    for (var i = 0; i < group.length; ++i) {
        var stone = group[i]
        var neighbors = neighborPointsForRule(dims, stone.x, stone.y, ruleMode)
        for (var n = 0; n < neighbors.length; ++n) {
            var neighbor = neighbors[n]
            if (stoneMapPlayerAt(map, neighbor.x, neighbor.y) !== 0)
                continue

            var libertyKey = neighbor.key
            if (!liberties[libertyKey]) {
                liberties[libertyKey] = true
                count += 1
            }
        }
    }
    return count
}

function groupLibertyPointsInMap(map, dims, group, ruleMode) {
    var liberties = ({})
    var points = []
    for (var i = 0; i < group.length; ++i) {
        var stone = group[i]
        var neighbors = neighborPointsForRule(dims, stone.x, stone.y, ruleMode)
        for (var n = 0; n < neighbors.length; ++n) {
            var neighbor = neighbors[n]
            if (stoneMapPlayerAt(map, neighbor.x, neighbor.y) !== 0)
                continue
            if (liberties[neighbor.key])
                continue
            liberties[neighbor.key] = true
            points.push(neighbor)
        }
    }
    return points
}

function pointIsLibertyOfGroupInMap(map, dims, point, group, ruleMode) {
    if (!point || stoneMapPlayerAt(map, point.x, point.y) !== 0)
        return false
    for (var i = 0; i < group.length; ++i) {
        var stone = group[i]
        var neighbors = neighborPointsForRule(dims, stone.x, stone.y, ruleMode)
        for (var n = 0; n < neighbors.length; ++n) {
            if (neighbors[n].key === point.key)
                return true
        }
    }
    return false
}

function removeGroupFromMap(map, group) {
    for (var i = 0; i < group.length; ++i)
        delete map[group[i].key]
}

function stoneMapSignature(map) {
    var parts = []
    for (var key in map) {
        var stone = map[key]
        if (stone)
            parts.push(key + ":" + stone.player)
    }
    parts.sort()
    return parts.join("|")
}

function goMoveResult(ok, captured, reason, capturedStones, ownGroupSize, ownLibertyCount,
                      selfCapturedStones, koLoc) {
    var selfCaptured = selfCapturedStones || []
    return {
        "ok": ok,
        "captured": captured,
        "reason": reason,
        "capturedStones": capturedStones || [],
        "selfCaptured": selfCaptured.length,
        "selfCapturedStones": selfCaptured,
        "ownGroupSize": ownGroupSize || 0,
        "ownLibertyCount": ownLibertyCount || 0,
        "koLoc": koLoc || emptyKoLoc()
    }
}

function simulateGoMoveOnMap(map, dims, stoneItem, collectKoInfo, ruleMode) {
    ruleMode = ruleMode === undefined ? RULE_GO : ruleMode
    if (ruleMode === RULE_TWO_LIB_GO)
        return simulateTwoLibGoMoveOnMap(map, dims, stoneItem, collectKoInfo, ruleMode)
    if (map[stoneItem.key] !== undefined)
        return goMoveResult(false, 0, "occupied")

    map[stoneItem.key] = stoneItem

    var captured = 0
    var capturedStones = []
    var opponent = stoneItem.player === 1 ? 2 : 1
    var checked = ({})
    var neighbors = neighborPointsForRule(dims, stoneItem.x, stoneItem.y, ruleMode)
    for (var i = 0; i < neighbors.length; ++i) {
        var neighborPoint = neighbors[i]
        var neighbor = stoneMapDataAt(map, neighborPoint.x, neighborPoint.y)
        if (!neighbor || neighbor.player !== opponent || checked[neighbor.key])
            continue

        var group = collectGroupInMap(map, dims, neighborPoint.x, neighborPoint.y, ({}), ruleMode)
        for (var g = 0; g < group.length; ++g)
            checked[group[g].key] = true
        if (!groupHasLibertyInMap(map, dims, group, ruleMode)) {
            captured += group.length
            if (collectKoInfo) {
                for (var c = 0; c < group.length; ++c)
                    capturedStones.push(copyStoneItem(group[c]))
            }
            removeGroupFromMap(map, group)
        }
    }

    var ownGroup = collectGroupInMap(map, dims, stoneItem.x, stoneItem.y, ({}), ruleMode)
    if (!groupHasLibertyInMap(map, dims, ownGroup, ruleMode)) {
        delete map[stoneItem.key]
        for (var r = 0; r < capturedStones.length; ++r)
            map[capturedStones[r].key] = capturedStones[r]
        return goMoveResult(false, captured, "suicide", capturedStones, ownGroup.length, 0)
    }

    var ownLibertyCount = collectKoInfo ? groupLibertyCountInMap(map, dims, ownGroup, ruleMode) : 0
    return goMoveResult(true, captured, "", capturedStones, ownGroup.length, ownLibertyCount)
}

function addKoLoc(ko, point) {
    if (!point || !point.key || point.key.length <= 0)
        return
    if (ko.key === "") {
        ko.key = point.key
        ko.x = point.x
        ko.y = point.y
    } else if (ko.key !== point.key && ko.key2 === "") {
        ko.key2 = point.key
        ko.x2 = point.x
        ko.y2 = point.y
    }
}

function simulateTwoLibGoMoveOnMap(map, dims, stoneItem, collectKoInfo, ruleMode, computeKo) {
    ruleMode = ruleMode === undefined ? RULE_TWO_LIB_GO : ruleMode
    if (computeKo === undefined)
        computeKo = collectKoInfo === true
    if (map[stoneItem.key] !== undefined)
        return goMoveResult(false, 0, "occupied")

    var beforeSignature = computeKo ? stoneMapSignature(map) : ""
    map[stoneItem.key] = stoneItem

    var captured = 0
    var capturedStones = []
    var possibleKoPoint = null
    var opponent = stoneItem.player === 1 ? 2 : 1
    var checked = ({})
    var neighbors = neighborPointsForRule(dims, stoneItem.x, stoneItem.y, ruleMode)
    for (var i = 0; i < neighbors.length; ++i) {
        var neighborPoint = neighbors[i]
        var neighbor = stoneMapDataAt(map, neighborPoint.x, neighborPoint.y)
        if (!neighbor || neighbor.player !== opponent || checked[neighbor.key])
            continue

        var group = collectGroupInMap(map, dims, neighborPoint.x, neighborPoint.y, ({}), ruleMode)
        for (var g = 0; g < group.length; ++g)
            checked[group[g].key] = true
        if (groupLibertyCountInMap(map, dims, group, ruleMode) <= 1) {
            captured += group.length
            if (group.length === 1)
                possibleKoPoint = copyStoneItem(group[0])
            if (collectKoInfo) {
                for (var c = 0; c < group.length; ++c)
                    capturedStones.push(copyStoneItem(group[c]))
            }
            removeGroupFromMap(map, group)
        }
    }

    var selfCapturedStones = []
    var ownGroup = []
    var ownLibertyCount = 0
    if (stoneMapDataAt(map, stoneItem.x, stoneItem.y)) {
        ownGroup = collectGroupInMap(map, dims, stoneItem.x, stoneItem.y, ({}), ruleMode)
        ownLibertyCount = groupLibertyCountInMap(map, dims, ownGroup, ruleMode)
        if (ownLibertyCount <= 1) {
            // Two-liberty Go only allows suicide when the move also captures opponent stones.
            if (captured === 0) {
                delete map[stoneItem.key]
                return goMoveResult(false, 0, "suicide", [], ownGroup.length, ownLibertyCount)
            }
            if (collectKoInfo) {
                for (var s = 0; s < ownGroup.length; ++s)
                    selfCapturedStones.push(copyStoneItem(ownGroup[s]))
            }
            removeGroupFromMap(map, ownGroup)
            ownGroup = []
            ownLibertyCount = 0
        }
    }

    var ko = emptyKoLoc()
    if (computeKo) {
        if (captured === 1 && possibleKoPoint) {
            if (selfCapturedStones.length === 0
                    && ownGroup.length > 0
                    && ownLibertyCount === 2
                    && pointIsLibertyOfGroupInMap(map, dims, possibleKoPoint, ownGroup, ruleMode)) {
                addKoLoc(ko, possibleKoPoint)
            } else if (selfCapturedStones.length === 1) {
                addKoLoc(ko, possibleKoPoint)
            }
        } else if (captured === 0 && selfCapturedStones.length === 0
                   && ownGroup.length === 1 && ownLibertyCount === 2) {
            var liberties = groupLibertyPointsInMap(map, dims, ownGroup, ruleMode)
            for (var l = 0; l < liberties.length; ++l) {
                var liberty = liberties[l]
                var copy = cloneStoneMap(map)
                var reply = {
                    "x": liberty.x,
                    "y": liberty.y,
                    "key": liberty.key,
                    "player": opponent,
                    "moveNumber": 0,
                    "nodeId": -1
                }
                var replyResult = simulateTwoLibGoMoveOnMap(copy, dims, reply, false, ruleMode, false)
                if (replyResult.ok && stoneMapSignature(copy) === beforeSignature)
                    addKoLoc(ko, liberty)
            }
        }
    }

    return goMoveResult(true, captured, "", capturedStones, ownGroup.length, ownLibertyCount,
                        selfCapturedStones, ko)
}

function reversiFlipsForMove(map, dims, x, y, player) {
    if (!pointInBoard(dims, x, y) || stoneMapPlayerAt(map, x, y) !== 0)
        return []
    var opponent = player === 1 ? 2 : 1
    var flips = []
    for (var d = 0; d < SQUARE_DIRECTIONS.length; ++d) {
        var direction = SQUARE_DIRECTIONS[d]
        var run = []
        var nx = x + direction.dx
        var ny = y + direction.dy
        while (pointInBoard(dims, nx, ny) && stoneMapPlayerAt(map, nx, ny) === opponent) {
            run.push(stoneMapDataAt(map, nx, ny))
            nx += direction.dx
            ny += direction.dy
        }
        if (run.length > 0 && pointInBoard(dims, nx, ny) && stoneMapPlayerAt(map, nx, ny) === player) {
            for (var r = 0; r < run.length; ++r)
                flips.push(run[r])
        }
    }
    return flips
}

function ataxxMoveKind(map, dims, x, y, player, source) {
    if (!pointInBoard(dims, x, y))
        return ""
    if (source && source.x >= 0 && source.y >= 0) {
        if (stoneMapPlayerAt(map, source.x, source.y) !== player || stoneMapPlayerAt(map, x, y) !== 0)
            return ""
        var dx = Math.abs(x - source.x)
        var dy = Math.abs(y - source.y)
        var distance = Math.max(dx, dy)
        return distance === 2 ? "jump" : ""
    }
    if (stoneMapPlayerAt(map, x, y) !== 0)
        return stoneMapPlayerAt(map, x, y) === player ? "source" : ""
    for (var sy = Math.max(0, y - 1); sy <= Math.min(dims.y - 1, y + 1); ++sy) {
        for (var sx = Math.max(0, x - 1); sx <= Math.min(dims.x - 1, x + 1); ++sx) {
            if ((sx !== x || sy !== y) && stoneMapPlayerAt(map, sx, sy) === player)
                return "clone"
        }
    }
    return ""
}

function breakthroughForward(player) {
    return player === 1 ? -1 : 1
}

function breakthroughMoveKind(map, dims, x, y, player, source) {
    if (!pointInBoard(dims, x, y))
        return ""
    if (!source || source.x < 0 || source.y < 0)
        return stoneMapPlayerAt(map, x, y) === player ? "source" : ""
    if (stoneMapPlayerAt(map, source.x, source.y) !== player)
        return ""
    var dy = y - source.y
    var dx = x - source.x
    var forward = breakthroughForward(player)
    if (dy !== forward || Math.abs(dx) > 1)
        return ""
    var target = stoneMapPlayerAt(map, x, y)
    if (dx === 0)
        return target === 0 ? "move" : ""
    return target !== player ? "capture" : ""
}

function pointLegalInMap(map, dims, x, y, player, activeKoLocKey, ruleMode, source) {
    if (!pointInRuleBoard(dims, x, y, ruleMode))
        return false

    if (ruleMode === RULE_SQUARE_FREE)
        return true
    if (ruleMode === RULE_DOTS_AND_BOXES)
        return dotsAndBoxesPointKind(x, y) === "edge" && stoneMapPlayerAt(map, x, y) === 0
    if (ruleMode === RULE_ATAXX)
        return ataxxMoveKind(map, dims, x, y, player, source) !== ""
    if (ruleMode === RULE_BREAKTHROUGH)
        return breakthroughMoveKind(map, dims, x, y, player, source) !== ""
    if (stoneMapPlayerAt(map, x, y) !== 0)
        return false
    if (ruleMode === RULE_REVERSI)
        return reversiFlipsForMove(map, dims, x, y, player).length > 0
    if (!isGoCaptureRule(ruleMode))
        return true

    var pointKey = keyFor(x, y)
    if (koLocMatches(activeKoLocKey, pointKey))
        return false

    var item = {
        "x": x,
        "y": y,
        "key": pointKey,
        "player": player,
        "moveNumber": 0,
        "nodeId": -1
    }
    return simulateGoMoveOnMap(cloneStoneMap(map), dims, item, false, ruleMode).ok
}

function buildPointLegalityMap(map, dims, player, activeKoLocKey, ruleMode, source) {
    var result = ({})
    for (var y = 0; y < dims.y; ++y) {
        for (var x = 0; x < dims.x; ++x)
            result[keyFor(x, y)] = pointLegalInMap(map, dims, x, y, player, activeKoLocKey, ruleMode, source)
    }
    return result
}

function emptyKoLoc() {
    return { "key": "", "x": -1, "y": -1, "key2": "", "x2": -1, "y2": -1 }
}

function koLocMatches(koLoc, key) {
    if (!koLoc || key === "")
        return false
    if (typeof koLoc === "string")
        return koLoc !== "" && koLoc === key
    return koLoc.key === key || koLoc.key2 === key
}

function koLocFromGoMoveResult(ruleMode, result) {
    if (result && result.koLoc
            && (ruleMode === RULE_TWO_LIB_GO
                || result.koLoc.key !== ""
                || result.koLoc.key2 !== ""))
        return result.koLoc
    if (!isGoCaptureRule(ruleMode) || !result || !result.ok
            || result.captured !== 1
            || result.capturedStones.length !== 1
            || result.ownGroupSize !== 1
            || result.ownLibertyCount !== 1)
        return emptyKoLoc()

    var captured = result.capturedStones[0]
    return { "key": captured.key, "x": captured.x, "y": captured.y,
             "key2": "", "x2": -1, "y2": -1 }
}

function gomokuRuleTargetLength(gomokuRuleMode, ruleMode) {
    if (ruleMode === RULE_CONNECT6)
        return 6
    if (gomokuRuleMode === GOMOKU_RULE_DIRECT_FOUR)
        return 4
    return 5
}

function gomokuRuleExactLength(gomokuRuleMode, player, ruleMode) {
    if (ruleMode === RULE_CONNECT6)
        return false
    if (gomokuRuleMode === GOMOKU_RULE_STANDARD)
        return true
    if (gomokuRuleMode === GOMOKU_RULE_RENJU && player === 1)
        return true
    return false
}

function gomokuRuleUsesDirection(gomokuRuleMode, direction) {
    if (gomokuRuleMode !== GOMOKU_RULE_DIRECT_FOUR)
        return true
    return (Math.abs(direction.dx) + Math.abs(direction.dy)) === 1
}

function caroEndBlocked(map, dims, player, x, y) {
    if (!pointInBoard(dims, x, y))
        return false
    var occupant = stoneMapPlayerAt(map, x, y)
    return occupant !== 0 && occupant !== player
}

function caroRunWins(map, dims, run, direction, noSix) {
    if (run.length < 5)
        return false
    if (run.length === 6 && noSix)
        return false
    if (run.length > 5)
        return true

    var start = run[0]
    var end = run[run.length - 1]
    var blockedBefore = caroEndBlocked(map, dims, start.player,
                                       start.x - direction.dx, start.y - direction.dy)
    var blockedAfter = caroEndBlocked(map, dims, start.player,
                                      end.x + direction.dx, end.y + direction.dy)
    return !(blockedBefore && blockedAfter)
}

function gomokuRunWins(map, dims, run, direction, gomokuRuleMode, player, ruleMode) {
    var target = gomokuRuleTargetLength(gomokuRuleMode, ruleMode)
    if (gomokuRuleMode === GOMOKU_RULE_CARO)
        return caroRunWins(map, dims, run, direction, false)
    if (gomokuRuleMode === GOMOKU_RULE_CARO_NO_SIX)
        return caroRunWins(map, dims, run, direction, true)
    if (gomokuRuleExactLength(gomokuRuleMode, player, ruleMode))
        return run.length === target
    return run.length >= target
}

function buildGomokuWinRuns(map, dims, ruleMode, gomokuRuleMode) {
    if (ruleMode !== RULE_GOMOKU && ruleMode !== RULE_CONNECT6)
        return []
    var lines = []
    for (var key in map) {
        var stone = map[key]
        for (var d = 0; d < GOMOKU_DIRECTIONS.length; ++d) {
            var direction = GOMOKU_DIRECTIONS[d]
            if (!gomokuRuleUsesDirection(gomokuRuleMode, direction))
                continue

            var px = stone.x - direction.dx
            var py = stone.y - direction.dy
            if (pointInBoard(dims, px, py) && stoneMapPlayerAt(map, px, py) === stone.player)
                continue

            var run = []
            var x = stone.x
            var y = stone.y
            while (pointInBoard(dims, x, y) && stoneMapPlayerAt(map, x, y) === stone.player) {
                run.push(stoneMapDataAt(map, x, y))
                x += direction.dx
                y += direction.dy
            }

            if (!gomokuRunWins(map, dims, run, direction, gomokuRuleMode, stone.player, ruleMode))
                continue

            var start = run[0]
            var end = run[run.length - 1]
            lines.push({
                "dx": direction.dx,
                "dy": direction.dy,
                "startX": start.x,
                "startY": start.y,
                "endX": end.x,
                "endY": end.y,
                "player": stone.player
            })
        }
    }
    return lines
}

function hexPlayerReachedGoal(player, dims, stone) {
    if (player === 1)
        return stone.y === dims.y - 1
    return stone.x === dims.x - 1
}

function reconstructHexPath(map, parentByKey, endKey) {
    var keys = []
    var key = endKey
    while (key !== "") {
        keys.push(key)
        key = parentByKey[key] || ""
    }
    keys.reverse()

    var path = []
    for (var i = 0; i < keys.length; ++i) {
        var stone = map[keys[i]]
        if (stone)
            path.push(copyStoneItem(stone))
    }
    return path
}

function buildHexWinPathForPlayer(map, dims, player) {
    var queue = []
    var visited = ({})
    var parentByKey = ({})

    if (player === 1) {
        for (var x = 0; x < dims.x; ++x) {
            var blackStart = stoneMapDataAt(map, x, 0)
            if (!blackStart || blackStart.player !== player)
                continue
            queue.push(blackStart)
            visited[blackStart.key] = true
            parentByKey[blackStart.key] = ""
        }
    } else {
        for (var y = 0; y < dims.y; ++y) {
            var whiteStart = stoneMapDataAt(map, 0, y)
            if (!whiteStart || whiteStart.player !== player)
                continue
            queue.push(whiteStart)
            visited[whiteStart.key] = true
            parentByKey[whiteStart.key] = ""
        }
    }

    var head = 0
    while (head < queue.length) {
        var stone = queue[head++]
        if (hexPlayerReachedGoal(player, dims, stone))
            return reconstructHexPath(map, parentByKey, stone.key)

        for (var n = 0; n < HEX_NEIGHBOR_OFFSETS.length; ++n) {
            var offset = HEX_NEIGHBOR_OFFSETS[n]
            var nx = stone.x + offset.dx
            var ny = stone.y + offset.dy
            if (!pointInBoard(dims, nx, ny))
                continue

            var neighbor = stoneMapDataAt(map, nx, ny)
            if (!neighbor || neighbor.player !== player || visited[neighbor.key])
                continue

            visited[neighbor.key] = true
            parentByKey[neighbor.key] = stone.key
            queue.push(neighbor)
        }
    }
    return []
}

function buildHexWinPath(map, dims, ruleMode) {
    if (ruleMode !== RULE_HEX)
        return { "player": 0, "path": [] }

    var blackPath = buildHexWinPathForPlayer(map, dims, 1)
    if (blackPath.length > 0)
        return { "player": 1, "path": blackPath }

    var whitePath = buildHexWinPathForPlayer(map, dims, 2)
    if (whitePath.length > 0)
        return { "player": 2, "path": whitePath }

    return { "player": 0, "path": [] }
}

function ataxxFlippedNeighbors(map, dims, x, y, player) {
    var opponent = player === 1 ? 2 : 1
    var flipped = []
    for (var dy = -1; dy <= 1; ++dy) {
        for (var dx = -1; dx <= 1; ++dx) {
            if (dx === 0 && dy === 0)
                continue
            var nx = x + dx
            var ny = y + dy
            var neighbor = pointInBoard(dims, nx, ny) ? stoneMapDataAt(map, nx, ny) : null
            if (neighbor && neighbor.player === opponent)
                flipped.push(neighbor)
        }
    }
    return flipped
}

function applyReversiMoveOnMap(map, dims, stoneItem) {
    var flips = reversiFlipsForMove(map, dims, stoneItem.x, stoneItem.y, stoneItem.player)
    if (flips.length <= 0)
        return { "ok": false, "capturedStones": [] }
    map[stoneItem.key] = stoneItem
    for (var i = 0; i < flips.length; ++i)
        flips[i].player = stoneItem.player
    return { "ok": true, "capturedStones": [] }
}

function applyAtaxxMoveOnMap(map, dims, stoneItem, source) {
    var kind = ataxxMoveKind(map, dims, stoneItem.x, stoneItem.y, stoneItem.player, source)
    if (kind !== "clone" && kind !== "jump")
        return { "ok": false, "capturedStones": [] }
    if (kind === "jump")
        delete map[keyFor(source.x, source.y)]
    map[stoneItem.key] = stoneItem
    var flipped = ataxxFlippedNeighbors(map, dims, stoneItem.x, stoneItem.y, stoneItem.player)
    for (var i = 0; i < flipped.length; ++i)
        flipped[i].player = stoneItem.player
    return { "ok": true, "capturedStones": [] }
}

function applyBreakthroughMoveOnMap(map, dims, stoneItem, source) {
    var kind = breakthroughMoveKind(map, dims, stoneItem.x, stoneItem.y, stoneItem.player, source)
    if (kind !== "move" && kind !== "capture")
        return { "ok": false, "capturedStones": [] }
    var sourceKey = keyFor(source.x, source.y)
    var moving = stoneMapDataAt(map, source.x, source.y)
    var captured = []
    var target = stoneMapDataAt(map, stoneItem.x, stoneItem.y)
    if (target && target.player !== stoneItem.player)
        captured.push(copyStoneItem(target))
    delete map[sourceKey]
    map[stoneItem.key] = {
        "x": stoneItem.x,
        "y": stoneItem.y,
        "key": stoneItem.key,
        "player": stoneItem.player,
        "moveNumber": moving ? moving.moveNumber : stoneItem.moveNumber,
        "nodeId": stoneItem.nodeId
    }
    return { "ok": true, "capturedStones": captured }
}

function initialStoneMap(dims, ruleMode) {
    var map = ({})
    function put(x, y, player) {
        if (!pointInRuleBoard(dims, x, y, ruleMode))
            return
        var key = keyFor(x, y)
        map[key] = { "x": x, "y": y, "key": key, "player": player, "moveNumber": 0, "nodeId": 0 }
    }
    if (ruleMode === RULE_REVERSI) {
        if (dims.x < 2 || dims.y < 2)
            return map
        var cx = Math.floor(dims.x / 2) - 1
        var cy = Math.floor(dims.y / 2) - 1
        put(cx, cy, 2)
        put(cx + 1, cy + 1, 2)
        put(cx + 1, cy, 1)
        put(cx, cy + 1, 1)
    } else if (ruleMode === RULE_ATAXX) {
        if (dims.x < 2 || dims.y < 2)
            return map
        put(0, 0, 1)
        put(dims.x - 1, dims.y - 1, 1)
        put(dims.x - 1, 0, 2)
        put(0, dims.y - 1, 2)
    } else if (ruleMode === RULE_BREAKTHROUGH) {
        for (var x = 0; x < dims.x; ++x) {
            put(x, dims.y - 1, 1)
            put(x, dims.y - 2, 1)
            put(x, 0, 2)
            put(x, 1, 2)
        }
    }
    return map
}

function countPlayerStones(map, player) {
    var count = 0
    for (var key in map) {
        if (map[key].player === player)
            count += 1
    }
    return count
}

function buildBreakthroughWin(map, dims, ruleMode) {
    if (ruleMode !== RULE_BREAKTHROUGH)
        return { "player": 0, "reason": "" }
    var black = 0
    var white = 0
    for (var key in map) {
        var stone = map[key]
        if (stone.player === 1) {
            black += 1
            if (stone.y === 0)
                return { "player": 1, "reason": "goal" }
        } else if (stone.player === 2) {
            white += 1
            if (stone.y === dims.y - 1)
                return { "player": 2, "reason": "goal" }
        }
    }
    if (black <= 0 && white > 0)
        return { "player": 2, "reason": "captured" }
    if (white <= 0 && black > 0)
        return { "player": 1, "reason": "captured" }
    return { "player": 0, "reason": "" }
}
