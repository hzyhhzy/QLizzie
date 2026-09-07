.pragma library
.import "GameRules.js" as GameRules

// Domain transitions never modify the supplied state. UI, engine and storage
// effects belong to the caller and run only after a successful transition.
function copyObject(value) {
    var copy = ({})
    for (var key in value)
        copy[key] = value[key]
    return copy
}

function copyRecord(value) {
    if (!value || typeof value !== "object")
        return value
    var copy = Array.isArray(value) ? [] : ({})
    for (var key in value)
        copy[key] = copyRecord(value[key])
    return copy
}

function rootNode() {
    return {
        "id": 0, "parent": -1, "children": [],
        "x": -1, "y": -1, "key": "", "player": 0,
        "moveNumber": 0, "isPass": false, "moveRole": "",
        "gomokuForbidden": false, "extraTurn": false, "capturedStones": [],
        "blackCaptures": 0, "whiteCaptures": 0,
        "koLocKey": "", "koLocX": -1, "koLocY": -1,
        "koLocKey2": "", "koLocX2": -1, "koLocY2": -1,
        "analysisBlackWinrate": -1, "analysisCandidates": [],
        "analysisCandidateBoardSignature": "", "analysisCandidateKomiSignature": "",
        "analysisOwnership": [], "analysisOwnershipBoardSignature": "",
        "analysisOwnershipKomiSignature": "", "analysisOwnershipEngineSignature": ""
    }
}

function dimensions(config) {
    return { "x": config.boardSizeX, "y": config.boardSizeY }
}

function nodeById(state, id) {
    return state.gameNodes[id] || null
}

function nodePath(state, id) {
    var path = []
    var node = nodeById(state, id)
    var seen = ({})
    while (node && node.id !== 0) {
        if (seen[node.id])
            return []
        seen[node.id] = true
        path.push(node)
        node = nodeById(state, node.parent)
    }
    return node && node.id === 0 ? path.reverse() : []
}

function currentMoveSourcePoint(state) {
    var node = nodeById(state, state.currentNodeId)
    return node && node.moveRole === "source" ? { "x": node.x, "y": node.y } : null
}

function playerToMoveAfterNode(node, config) {
    if (config.stoneColorMode === 1 || config.stoneColorMode === 2)
        return config.stoneColorMode
    if (node && node.moveRole === "source")
        return node.player
    if (config.ruleMode === GameRules.RULE_DOTS_AND_BOXES && node && node.extraTurn === true)
        return node.player
    if (config.ruleMode === GameRules.RULE_CONNECT6) {
        var moveNumber = node ? node.moveNumber : 0
        if (moveNumber <= 0)
            return 1
        return Math.floor((moveNumber - 1) / 2) % 2 === 0 ? 2 : 1
    }
    return node && node.player === 1 ? 2 : 1
}

function mapStoneItems(map) {
    var items = []
    for (var key in map)
        items.push(map[key])
    items.sort(function(left, right) { return left.moveNumber - right.moveNumber })
    return items
}

function currentMoveNumber(state) {
    return GameRules.completedMoveNumber(nodePath(state, state.currentNodeId))
}

function maxMoveNumber(state) {
    var maxMove = 0
    var sourcesById = ({ "0": 0 })
    // Traverse the tree rather than relying on numerical IDs being in path order.
    var pending = [0]
    while (pending.length > 0) {
        var node = nodeById(state, pending.pop())
        if (!node)
            continue
        var sources = Number(sourcesById[node.parent] || 0)
                      + (node.moveRole === "source" ? 1 : 0)
        sourcesById[node.id] = sources
        maxMove = Math.max(maxMove, Math.max(0, Number(node.moveNumber || 0) - sources))
        var children = node.children || []
        for (var i = 0; i < children.length; ++i)
            pending.push(children[i])
    }
    return maxMove
}

function positionState(state, nodes, id, map, blackCaptures, whiteCaptures, ko, config) {
    var next = copyObject(state)
    next.gameNodes = nodes
    next.currentNodeId = id
    next.stones = map
    next.stoneItems = mapStoneItems(map)
    next.stoneCount = next.stoneItems.length
    next.blackCaptures = blackCaptures
    next.whiteCaptures = whiteCaptures
    next.ko = ko || GameRules.emptyKoLoc()
    next.currentPlayer = playerToMoveAfterNode(nodes[id], config)
    next.surakartaWinInfo = GameRules.buildSurakartaHistoryOutcome(
                nodePath(next, id), dimensions(config), config.ruleMode)
    return next
}

function create(config, generation) {
    return positionState({ "nextNodeId": 1, "gameTreeGeneration": Number(generation || 0) },
                         [rootNode()], 0,
                         GameRules.initialStoneMap(dimensions(config), config.ruleMode),
                         0, 0, GameRules.emptyKoLoc(), config)
}

function success(state, kind, treeChanged, dirty, node, reused) {
    return { "ok": true, "state": state, "changed": true,
        "positionChanged": true, "treeChanged": treeChanged === true,
        "dirty": dirty === true, "kind": kind, "node": node || null,
        "reused": reused === true }
}

function unchanged(state, kind) {
    return { "ok": true, "state": state, "changed": false,
        "positionChanged": false, "treeChanged": false, "dirty": false, "kind": kind }
}

function failure(state, reason, node, kind) {
    return { "ok": false, "state": state, "changed": false,
        "positionChanged": false, "treeChanged": false, "dirty": false,
        "kind": kind || "move", "reason": reason,
        "nodeId": node ? node.id : -1, "moveNumber": node ? node.moveNumber : 0,
        "x": node ? node.x : -1, "y": node ? node.y : -1 }
}

function updatePositionMetadata(node, blackCaptures, whiteCaptures, ko) {
    node.blackCaptures = blackCaptures
    node.whiteCaptures = whiteCaptures
    node.koLocKey = ko.key
    node.koLocX = ko.x
    node.koLocY = ko.y
    node.koLocKey2 = ko.key2
    node.koLocX2 = ko.x2
    node.koLocY2 = ko.y2
}

function forbidden(config, node, map) {
    return !node.isPass && typeof config.forbiddenChecker === "function"
           && config.forbiddenChecker(node.x, node.y, node.player, map) === true
}

function replay(state, id, config) {
    var target = nodeById(state, id)
    if (!target)
        return failure(state, "missing-node", null, "rebuild")
    var path = nodePath(state, id)
    if (id !== 0 && path.length === 0)
        return failure(state, "invalid-path", target, "rebuild")
    var nodes = state.gameNodes.slice()
    var map = GameRules.initialStoneMap(dimensions(config), config.ruleMode)
    var blackCaptures = 0
    var whiteCaptures = 0
    var ko = GameRules.emptyKoLoc()
    var source = null
    var sourceMoves = 0
    for (var i = 0; i < path.length; ++i) {
        var node = copyObject(path[i])
        var isForbidden = forbidden(config, node, map)
        var result = GameRules.applyMoveOnMap(map, dimensions(config), {
            "x": node.x, "y": node.y, "key": GameRules.keyFor(node.x, node.y),
            "player": node.player, "moveNumber": Math.max(0, node.moveNumber - sourceMoves),
            "nodeId": node.id, "isPass": node.isPass === true, "moveRole": node.moveRole || ""
        }, { "ruleMode": config.ruleMode, "activeKoLoc": ko,
             "pendingSource": source, "mutate": true })
        if (!result.ok)
            return failure(state, result.reason, node, "rebuild")
        map = result.nextMap
        ko = result.ko
        source = result.nextSource
        if (result.role === "source")
            sourceMoves += 1
        if (result.role === "source" || result.role === "target")
            node.moveRole = result.role
        node.extraTurn = result.extraTurn === true
        node.gomokuForbidden = isForbidden
        node.capturedStones = (result.capturedStones || []).concat(result.selfCapturedStones || [])
        if (node.player === 1) {
            blackCaptures += result.captured || 0
            whiteCaptures += result.selfCaptured || 0
        } else if (node.player === 2) {
            whiteCaptures += result.captured || 0
            blackCaptures += result.selfCaptured || 0
        }
        updatePositionMetadata(node, blackCaptures, whiteCaptures, ko)
        nodes[node.id] = node
    }
    return success(positionState(state, nodes, id, map, blackCaptures, whiteCaptures, ko, config),
                   "rebuild", false, false, nodes[id])
}

function navigate(state, id, config) {
    if (id === state.currentNodeId)
        return unchanged(state, "navigate")
    var result = replay(state, id, config)
    result.kind = "navigate"
    return result
}

function branchChildMatching(state, parent, key, player, isPass, moveRole) {
    var children = parent ? parent.children || [] : []
    for (var i = 0; i < children.length; ++i) {
        var child = nodeById(state, children[i])
        if (child && child.key === key && child.player === player
                && child.isPass === isPass && (child.moveRole || "") === (moveRole || ""))
            return child
    }
    return null
}

function move(state, action, config) {
    var parent = nodeById(state, state.currentNodeId)
    if (!parent)
        return failure(state, "missing-parent", null)
    var isPass = action.isPass === true
    var player = action.player === undefined ? state.currentPlayer : action.player
    if (player !== 1 && player !== 2)
        return failure(state, "invalid-player", action)
    var key = isPass ? "pass" : GameRules.keyFor(action.x, action.y)
    var usesSource = config.ruleMode === GameRules.RULE_ATAXX
                     || config.ruleMode === GameRules.RULE_BREAKTHROUGH
                     || config.ruleMode === GameRules.RULE_SURAKARTA
    // Existing variations are replayed before considering a new placement.
    // Replaying is still transactional if rules or loaded metadata changed.
    if (isPass || (!usesSource && !action.moveRole)) {
        var ordinaryChild = branchChildMatching(state, parent, key, player, isPass, "")
        if (ordinaryChild) {
            var existingResult = navigate(state, ordinaryChild.id, config)
            existingResult.reused = true
            return existingResult
        }
    }
    var item = { "x": isPass ? -1 : action.x, "y": isPass ? -1 : action.y,
        "key": key, "player": player, "moveNumber": currentMoveNumber(state) + 1,
        "nodeId": state.nextNodeId, "isPass": isPass, "moveRole": action.moveRole || "" }
    var isForbidden = forbidden(config, item, state.stones)
    var applied = GameRules.applyMoveOnMap(state.stones, dimensions(config), item, {
        "ruleMode": config.ruleMode, "activeKoLoc": state.ko,
        "pendingSource": currentMoveSourcePoint(state)
    })
    if (!applied.ok)
        return failure(state, applied.reason, item)
    var role = applied.role === "source" || applied.role === "target" ? applied.role : ""
    var existing = branchChildMatching(state, parent, key, player, isPass, role)
    if (existing) {
        var reused = navigate(state, existing.id, config)
        reused.reused = true
        return reused
    }
    var node = rootNode()
    node.id = state.nextNodeId
    node.parent = parent.id
    node.x = item.x
    node.y = item.y
    node.key = key
    node.player = player
    node.moveNumber = Number(parent.moveNumber) + 1
    node.isPass = isPass
    node.moveRole = role
    node.gomokuForbidden = isForbidden
    node.extraTurn = applied.extraTurn === true
    node.capturedStones = (applied.capturedStones || []).concat(applied.selfCapturedStones || [])
    var blackCaptures = state.blackCaptures
    var whiteCaptures = state.whiteCaptures
    if (player === 1) {
        blackCaptures += applied.captured || 0
        whiteCaptures += applied.selfCaptured || 0
    } else {
        whiteCaptures += applied.captured || 0
        blackCaptures += applied.selfCaptured || 0
    }
    updatePositionMetadata(node, blackCaptures, whiteCaptures, applied.ko)
    var nodes = state.gameNodes.slice()
    var nextParent = copyObject(parent)
    nextParent.children = (parent.children || []).concat([node.id])
    nodes[parent.id] = nextParent
    nodes[node.id] = node
    var next = positionState(state, nodes, node.id, applied.nextMap,
                             blackCaptures, whiteCaptures, applied.ko, config)
    next.nextNodeId = node.id + 1
    var result = success(next, isPass ? "pass" : role || "move", true, true, node)
    result.captured = applied.captured || 0
    result.selfCaptured = applied.selfCaptured || 0
    return result
}

function play(state, x, y, config) {
    return move(state, { "x": x, "y": y }, config)
}

function pass(state, config) {
    return move(state, { "isPass": true }, config)
}

function lastNodeId(state, startId) {
    var id = startId
    var node = nodeById(state, id)
    while (node && node.children && node.children.length > 0) {
        id = node.children[0]
        node = nodeById(state, id)
    }
    return id
}

function relativeNodeId(state, delta) {
    var id = state.currentNodeId
    for (var i = 0; i < Math.abs(delta); ++i) {
        var node = nodeById(state, id)
        if (!node)
            break
        if (delta < 0) {
            if (node.parent < 0)
                break
            id = node.parent
        } else {
            if (!node.children || node.children.length === 0)
                break
            id = node.children[0]
        }
    }
    return id
}

function nodeIdAtMoveNumber(state, moveNumber) {
    if (isNaN(moveNumber))
        return -1
    var path = [nodeById(state, 0)].concat(nodePath(state, state.currentNodeId))
    var sourceMoves = 0
    for (var i = 0; i < path.length; ++i) {
        var node = path[i]
        if (node.moveRole === "source")
            sourceMoves += 1
        if (node.moveRole !== "source"
                && Math.max(0, Number(node.moveNumber || 0) - sourceMoves) === moveNumber)
            return node.id
    }
    for (var id = 0; id < state.gameNodes.length; ++id) {
        var candidate = nodeById(state, id)
        if (candidate && candidate.moveRole !== "source"
                && GameRules.completedMoveNumber(nodePath(state, id)) === moveNumber)
            return id
    }
    return -1
}

function remove(state, id, config) {
    var node = nodeById(state, id)
    if (!node || id === 0)
        return unchanged(state, "delete")
    var nodes = state.gameNodes.slice()
    var pending = [id]
    var removedCurrent = false
    while (pending.length > 0) {
        var removedId = pending.pop()
        var removed = nodes[removedId]
        if (!removed)
            continue
        var descendants = removed.children || []
        for (var i = 0; i < descendants.length; ++i)
            pending.push(descendants[i])
        removedCurrent = removedCurrent || removedId === state.currentNodeId
        nodes[removedId] = undefined
    }
    var parent = copyObject(nodes[node.parent])
    parent.children = (parent.children || []).filter(function(childId) { return childId !== id })
    nodes[parent.id] = parent
    var next = copyObject(state)
    next.gameNodes = nodes
    var result = replay(next, removedCurrent ? parent.id : state.currentNodeId, config)
    if (!result.ok)
        return failure(state, result.reason, node, "delete")
    result.kind = "delete"
    result.treeChanged = true
    result.dirty = true
    return result
}

function promote(state, id) {
    var path = nodePath(state, id)
    var nodes = state.gameNodes.slice()
    var changed = false
    for (var i = 0; i < path.length; ++i) {
        var node = path[i]
        var parent = nodes[node.parent]
        var index = parent.children.indexOf(node.id)
        if (index <= 0)
            continue
        var replacement = copyObject(parent)
        replacement.children = parent.children.slice()
        replacement.children.splice(index, 1)
        replacement.children.unshift(node.id)
        nodes[parent.id] = replacement
        changed = true
    }
    if (!changed)
        return unchanged(state, "promote")
    var next = copyObject(state)
    next.gameNodes = nodes
    var result = success(next, "promote", true, true)
    result.positionChanged = false
    return result
}

function validate(parsed, config) {
    if (!parsed || typeof parsed !== "object")
        return { "ok": false, "reason": "missing-game", "nodeId": 0 }
    var width = Number(parsed.boardSizeX)
    var height = Number(parsed.boardSizeY)
    if (!isFinite(width) || !isFinite(height) || width < 1 || height < 1
            || Math.floor(width) !== width || Math.floor(height) !== height)
        return { "ok": false, "reason": "invalid-board-size", "nodeId": 0 }
    var nodes = parsed.nodes
    if (!Array.isArray(nodes) || !nodes[0])
        return { "ok": false, "reason": "missing-root", "nodeId": 0 }
    // Node IDs cross the QML int boundary. Reject a corrupt allocator before
    // committing any state; omitted allocators are derived from the node array.
    if (parsed.nextNodeId !== undefined) {
        var nextId = Number(parsed.nextNodeId)
        if (!isFinite(nextId) || Math.floor(nextId) !== nextId
                || nextId < nodes.length || nextId > 2147483646)
            return { "ok": false, "reason": "invalid-node-allocator", "nodeId": 0 }
    }
    for (var i = 0; i < nodes.length; ++i) {
        if (nodes[i] && (nodes[i].id !== i || (i === 0 && nodes[i].parent !== -1)))
            return { "ok": false, "reason": "invalid-node-id", "nodeId": i }
    }
    var ruleMode = parsed.ruleMode === undefined || parsed.ruleMode === null
                   ? config.ruleMode : Number(parsed.ruleMode)
    return GameRules.validateGameTree(nodes, { "x": width, "y": height }, ruleMode)
}

function load(state, parsed, config, selectLast) {
    var validation = validate(parsed, config)
    if (!validation.ok) {
        var rejected = failure(state, validation.reason, null, "load")
        rejected.nodeId = validation.nodeId
        return rejected
    }
    var next = copyObject(state)
    next.gameNodes = copyRecord(parsed.nodes)
    next.nextNodeId = parsed.nextNodeId === undefined ? next.gameNodes.length : Number(parsed.nextNodeId)
    next.gameTreeGeneration = state.gameTreeGeneration + 1
    var loadConfig = copyObject(config)
    loadConfig.boardSizeX = parsed.boardSizeX
    loadConfig.boardSizeY = parsed.boardSizeY
    if (parsed.ruleMode !== undefined && parsed.ruleMode !== null)
        loadConfig.ruleMode = Number(parsed.ruleMode)
    // The validator has already replayed all branches. Only the selected path
    // needs materializing now; other paths are materialized on navigation.
    var id = selectLast === false ? 0 : lastNodeId(next, 0)
    var result = replay(next, id, loadConfig)
    if (!result.ok)
        return failure(state, result.reason, result.node, "load")
    result.kind = "load"
    result.treeChanged = true
    return result
}

function updateNodeAnalysis(state, id, values) {
    var node = nodeById(state, id)
    if (!node)
        return failure(state, "missing-node", null, "annotations")
    var nextNode = copyObject(node)
    var changed = false
    for (var key in values) {
        if (key.indexOf("analysis") !== 0)
            return failure(state, "unsupported-metadata", node, "annotations")
        nextNode[key] = copyRecord(values[key])
        changed = true
    }
    if (!changed)
        return unchanged(state, "annotations")
    var next = copyObject(state)
    next.gameNodes = state.gameNodes.slice()
    next.gameNodes[id] = nextNode
    var result = success(next, "annotations", true, false, nextNode)
    result.positionChanged = false
    return result
}
