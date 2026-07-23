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

function rebuild(app) {
    var rowHeight = 38
    var columnWidth = 42
    var margin = app.compactLayout ? 32 : 36
    var radius = 12
    var laneById = ({})
    var nextLane = 0

    function assignLane(id) {
        var node = app.nodeById(id)
        if (!node)
            return 0
        var children = node.children || []
        if (children.length === 0) {
            laneById[id] = nextLane
            nextLane += 1
            return laneById[id]
        }
        var firstLane = -1
        for (var i = 0; i < children.length; ++i) {
            var childLane = assignLane(children[i])
            if (firstLane < 0)
                firstLane = childLane
        }
        laneById[id] = firstLane < 0 ? 0 : firstLane
        return laneById[id]
    }

    assignLane(0)
    if (nextLane === 0)
        nextLane = 1

    var currentPathMap = ({})
    currentPathMap[0] = true
    var path = app.nodePath(app.currentNodeId)
    for (var p = 0; p < path.length; ++p)
        currentPathMap[path[p].id] = true

    var nodes = []
    var nodeMap = ({})
    var maxMove = 0
    for (var id = 0; id < app.gameNodes.length; ++id) {
        var node = app.nodeById(id)
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
                          ? app.trText("rootMove")
                          : node.isPass
                            ? app.trText("passMove")
                            : app.coordinateText(node.x, node.y),
            "current": id === app.currentNodeId,
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

    app.treeNodes = nodes
    app.treeEdges = edges
    app.treeCanvasWidth = Math.max(app.minimumTreeCanvasWidth,
                                   margin * 2 + Math.max(0, nextLane - 1) * columnWidth + radius * 2)
    app.treeCanvasHeight = Math.max(app.minimumTreeCanvasHeight,
                                    margin * 2 + maxMove * rowHeight + radius * 2)
    app.treeRevision += 1
}
