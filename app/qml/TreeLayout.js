.pragma library

function nodeAt(nodes, x, y) {
    for (var i = nodes.length - 1; i >= 0; --i) {
        var node = nodes[i]
        var dx = x - node.x
        var dy = y - node.y
        if (Math.sqrt(dx * dx + dy * dy) <= node.radius + 4)
            return node.id
    }
    return -1
}

function nodeVisibleInViewport(node, left, top, width, height, padding) {
    if (!node)
        return false
    var pad = Math.max(0, Number(padding) || 0)
    var radius = Math.max(0, Number(node.radius) || 0) + pad
    var right = left + Math.max(0, width)
    var bottom = top + Math.max(0, height)
    return node.x + radius >= left
           && node.x - radius <= right
           && node.y + radius >= top
           && node.y - radius <= bottom
}

function edgeVisibleInViewport(edge, left, top, width, height, padding) {
    if (!edge)
        return false
    var pad = Math.max(0, Number(padding) || 0)
    var right = left + Math.max(0, width)
    var bottom = top + Math.max(0, height)
    return Math.max(edge.x1, edge.x2) + pad >= left
           && Math.min(edge.x1, edge.x2) - pad <= right
           && Math.max(edge.y1, edge.y2) + pad >= top
           && Math.min(edge.y1, edge.y2) - pad <= bottom
}

// Pure projection: input nodes remain owned by GameSession. Labels and sizes
// are explicit inputs so laying out a tree does not require a window.
function build(gameNodes, currentNodeId, options) {
    var rowHeight = 38
    var columnWidth = 42
    var margin = options.compactLayout ? 32 : 36
    var radius = 12
    var laneById = ({})
    var nextLane = 0

    // Postorder traversal preserves the first child's lane without recursive
    // calls; long imported games must not exhaust the JavaScript call stack.
    var pending = [{ "id": 0, "expanded": false }]
    var visited = ({})
    while (pending.length > 0) {
        var frame = pending.pop()
        var branch = gameNodes[frame.id]
        if (!branch)
            continue
        var children = branch.children || []
        if (frame.expanded) {
            if (children.length === 0)
                laneById[frame.id] = nextLane++
            else
                laneById[frame.id] = laneById[children[0]] || 0
        } else if (!visited[frame.id]) {
            visited[frame.id] = true
            pending.push({ "id": frame.id, "expanded": true })
            for (var c = children.length - 1; c >= 0; --c)
                pending.push({ "id": children[c], "expanded": false })
        }
    }
    if (nextLane === 0)
        nextLane = 1

    var currentPathMap = ({})
    currentPathMap[0] = true
    var pathNode = gameNodes[currentNodeId]
    while (pathNode && !currentPathMap[pathNode.id]) {
        currentPathMap[pathNode.id] = true
        pathNode = gameNodes[pathNode.parent]
    }

    var nodes = []
    var nodeMap = ({})
    var maxMove = 0
    for (var id = 0; id < gameNodes.length; ++id) {
        var node = gameNodes[id]
        if (!node)
            continue

        var lane = laneById[id] === undefined ? 0 : laneById[id]
        var treeNode = {
            "id": id,
            "parent": node.parent,
            "x": margin + lane * columnWidth,
            "y": margin + node.moveNumber * rowHeight,
            "radius": radius,
            "moveNumber": node.moveNumber,
            "player": node.player,
            "isPass": node.isPass === true,
            "coordinate": node.id === 0
                          ? options.rootText
                          : node.isPass
                            ? options.passText
                            : options.coordinateText(node.x, node.y),
            "current": id === currentNodeId,
            "currentPath": currentPathMap[id] === true,
            "label": node.moveNumber === 0 ? "0" : node.isPass ? "P" : String(node.moveNumber)
        }
        nodes.push(treeNode)
        nodeMap[id] = treeNode
        maxMove = Math.max(maxMove, node.moveNumber)
    }

    var edges = []
    for (var e = 0; e < nodes.length; ++e) {
        var child = nodes[e]
        var parent = nodeMap[child.parent]
        if (parent) {
            edges.push({
                "x1": parent.x,
                "y1": parent.y,
                "x2": child.x,
                "y2": child.y,
                "current": child.currentPath
            })
        }
    }

    return {
        "nodes": nodes,
        "edges": edges,
        "width": Math.max(options.minimumWidth,
                          margin * 2 + Math.max(0, nextLane - 1) * columnWidth + radius * 2),
        "height": Math.max(options.minimumHeight,
                           margin * 2 + maxMove * rowHeight + radius * 2)
    }
}
