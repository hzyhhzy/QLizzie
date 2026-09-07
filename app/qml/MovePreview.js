.pragma library
.import "GameRules.js" as GameRules

// The UI parses protocol coordinates once. This module only receives values:
// position = { map, player, source }, config = { dims, ruleMode, maxMoves },
// actions = [{ x, y }, { role: "pass" }, null, ...]. No application state is read.
function moveLimit(value) {
    var limit = Math.round(Number(value))
    return isFinite(limit) ? Math.max(0, limit) : 0
}

function stoneItem(point, player, moveNumber) {
    return {
        "kind": "stone",
        "x": point.x,
        "y": point.y,
        "key": GameRules.keyFor(point.x, point.y),
        "player": player,
        "moveNumber": moveNumber,
        "nodeId": -1
    }
}

function resultItem(result, player, moveNumber) {
    var item = stoneItem(result.target, player, moveNumber)
    if (result.source) {
        item.kind = "arrow"
        item.fromX = result.source.x
        item.fromY = result.source.y
    }
    return item
}

// Source selection consumes a protocol token but not a displayed move. The
// same reducer used for real moves validates selections, clones and captures.
function sourceVariation(position, config, actions) {
    var map = GameRules.cloneStoneMap(position.map || ({}))
    var source = position.source ? GameRules.movePointCopy(position.source, position.player) : null
    var player = position.player
    var items = []
    var limit = moveLimit(config.maxMoves)
    // Move-source games intentionally preview only this move and its reply.
    limit = limit > 0 ? Math.min(2, limit) : 2
    var index = 0
    var reason = ""
    while (index < actions.length && items.length < limit) {
        var action = actions[index]
        if (!action || action.role === "pass" || action.role === "resign") {
            reason = "invalid-coordinate"
            break
        }
        var result = GameRules.applyMoveOnMap(map, config.dims, {
            "x": action.x,
            "y": action.y,
            "player": player,
            "moveNumber": items.length + 1,
            "nodeId": -1,
            "role": source ? "target" : ""
        }, {
            "ruleMode": config.ruleMode,
            "source": source
        })
        if (!result.ok) {
            reason = result.reason
            break
        }
        index += 1
        map = result.nextMap
        source = result.nextSource
        if (!result.turnCompleted)
            continue
        items.push(resultItem(result, player, items.length + 1))
        player = player === 1 ? 2 : 1
    }
    if (source && reason === "")
        reason = "incomplete-move"
    return {
        "items": items,
        "position": { "map": map, "player": player, "source": source },
        "nextIndex": index,
        "reason": reason
    }
}

// Placement previews retain their display contract: pass counts toward the
// limit, malformed/out-of-board tokens are ignored, and colors alternate.
function placementItems(position, config, actions) {
    var items = []
    var player = position.player
    var moveNumber = 1
    var limit = moveLimit(config.maxMoves)
    for (var index = 0; index < actions.length; ++index) {
        if (limit > 0 && moveNumber > limit)
            break
        var action = actions[index]
        if (!action)
            continue
        if (action.role !== "pass") {
            if (!GameRules.pointInBoard(config.dims, action.x, action.y))
                continue
            var item = stoneItem(action, player, moveNumber)
            // Existing placement renderers consume point items without a kind.
            delete item.kind
            items.push(item)
        }
        player = player === 1 ? 2 : 1
        moveNumber += 1
    }
    return items
}
