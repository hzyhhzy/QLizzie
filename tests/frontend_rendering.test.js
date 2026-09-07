const assert = require("node:assert/strict")
const path = require("node:path")
const { loadQmlJs } = require("./qmlJsLoader")
const root = path.join(__dirname, "..")

// Geometry is verified through drawing operations and returned values.
// Window lifecycle and application wiring run in tests/qml_runtime.
const boardRenderer = loadQmlJs(path.join(root, "app", "qml", "BoardRenderer.js"), {
    imports: { CoordinateUtils: {} }
})
const boardVisuals = loadQmlJs(path.join(root, "app", "qml", "BoardVisuals.js"), {
    imports: { GameRules: {} }
})
const treeLayout = loadQmlJs(path.join(root, "app", "qml", "TreeLayout.js"))

function countingContext() {
    return {
        arcCount: 0,
        lineDashCalls: [],
        lineSegments: [],
        textCalls: [],
        pendingMove: null,
        save() {},
        restore() {},
        beginPath() {},
        moveTo(x, y) { this.pendingMove = { x, y } },
        lineTo(x, y) {
            this.lineSegments.push({
                from: this.pendingMove,
                to: { x, y },
                dash: this.lineDashCalls.length > 0
                    ? this.lineDashCalls[this.lineDashCalls.length - 1] : []
            })
        },
        closePath() {},
        fill() {},
        stroke() {},
        arc() { this.arcCount += 1 },
        setLineDash(pattern) { this.lineDashCalls.push(Array.from(pattern)) },
        fillText(text, x, y) { this.textCalls.push({ text, x, y }) }
    }
}

const dotsState = {
    boardSizeX: 3,
    boardSizeY: 3,
    gameRuleMode: 7,
    gameRuleDotsAndBoxes: 7,
    gameRuleHex: 2,
    gameRuleTorusGo: 3,
    hexGridBoard: false,
    squareCellBoard: false,
    hexCellStyleActive: false,
    gridOpacity: 1,
    gridLineWidth: 1
}
const dotsGeometry = {
    cellSize: 20,
    point(x, y) { return { x: x * 20, y: y * 20 } }
}

const gridContext = countingContext()
boardRenderer.drawGrid(gridContext, dotsState, dotsGeometry)
assert.equal(gridContext.arcCount, 4, "the static grid owns the four board dots")

const positionContext = countingContext()
boardRenderer.drawDotsAndBoxesPosition(positionContext, dotsState, dotsGeometry, [])
assert.equal(positionContext.arcCount, 0, "the position layer must not redraw static dots")
assert.equal(positionContext.lineSegments.length, 4,
             "the four unclaimed links are drawn as construction guides")
assert.ok(positionContext.lineSegments.every(segment => segment.dash.length === 2),
          "unclaimed links use a dashed stroke")

const claimedPositionContext = countingContext()
boardRenderer.drawDotsAndBoxesPosition(claimedPositionContext, dotsState, dotsGeometry, [
    { x: 1, y: 0, player: 1, moveNumber: 7 },
    { x: 0, y: 1, player: 2, moveNumber: 8 }
])
const dashedSegments = claimedPositionContext.lineSegments.filter(
    segment => segment.dash.length === 2
)
assert.equal(dashedSegments.length, 2,
             "claimed links replace their dashed construction guides")
assert.equal(claimedPositionContext.textCalls.length, 2)
assert.ok(claimedPositionContext.textCalls[0].y > dotsGeometry.point(1, 0).y,
          "horizontal edge numbers are optically shifted downward")
assert.equal(claimedPositionContext.textCalls[1].y, dotsGeometry.point(0, 1).y,
             "vertical edge numbers keep their centered position")

const surakartaState = {
    boardSizeX: 6,
    boardSizeY: 6,
    gameRuleMode: 14,
    gameRuleSurakarta: 14,
    gameRuleGomoku: 1,
    gameRuleHex: 2,
    gameRuleTorusGo: 3,
    gameRuleDotsAndBoxes: 7,
    hexGridBoard: false,
    squareCellBoard: false,
    hexCellStyleActive: false,
    gridOpacity: 1,
    gridLineWidth: 1
}
const surakartaGeometry = {
    cellSize: 20,
    boardLeft: 40,
    boardTop: 40,
    boardRight: 140,
    boardBottom: 140,
    point(x, y) { return { x: 40 + x * 20, y: 40 + y * 20 } }
}
const surakartaContext = countingContext()
boardRenderer.drawGrid(surakartaContext, surakartaState, surakartaGeometry)
assert.equal(surakartaContext.arcCount, 8,
             "Surakarta draws two capture loops around each grid corner")

const node = { x: 100, y: 100, radius: 12 }
assert.equal(treeLayout.nodeVisibleInViewport(node, 80, 80, 40, 40, 0), true)
assert.equal(treeLayout.nodeVisibleInViewport(node, 113, 80, 40, 40, 0), false)
assert.equal(treeLayout.nodeVisibleInViewport(node, 113, 80, 40, 40, 1), true)

const crossingEdge = { x1: 0, y1: 100, x2: 200, y2: 100 }
const outsideEdge = { x1: 0, y1: 10, x2: 200, y2: 10 }
assert.equal(treeLayout.edgeVisibleInViewport(crossingEdge, 80, 80, 40, 40, 0), true)
assert.equal(treeLayout.edgeVisibleInViewport(outsideEdge, 80, 80, 40, 40, 0), false)

const nextMoveNodes = [
    { id: 0, children: [1, 2, 3, 4] },
    { id: 1, x: 3, y: 3, player: 1 },
    { id: 2, x: 10, y: 10, player: 1 },
    { id: 3, x: -1, y: -1, player: 1, isPass: true },
    { id: 4, x: 10, y: 10, player: 1 }
]
const nextMoveMarkers = boardVisuals.nextMoveMarkerItems({
    currentNode() { return nextMoveNodes[0] },
    nodeById(id) { return nextMoveNodes[id] },
    pointInRuleBoard(x, y) { return x >= 0 && y >= 0 && x < 19 && y < 19 },
    keyFor(x, y) { return `${x},${y}` }
})
assert.deepEqual(Array.from(nextMoveMarkers, marker => ({
    x: marker.x,
    y: marker.y,
    player: marker.player,
    mainBranch: marker.mainBranch
})), [
    { x: 3, y: 3, player: 1, mainBranch: true },
    { x: 10, y: 10, player: 1, mainBranch: false }
])

console.log("frontend rendering behavior tests passed")
