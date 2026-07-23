const assert = require("node:assert/strict")
const path = require("node:path")
const { loadQmlJs } = require("./qmlJsLoader")

const root = path.join(__dirname, "..")
const boardRenderer = loadQmlJs(path.join(root, "app", "qml", "BoardRenderer.js"), {
    imports: { CoordinateUtils: {} }
})
const treeLayout = loadQmlJs(path.join(root, "app", "qml", "TreeLayout.js"))

function countingContext() {
    return {
        arcCount: 0,
        save() {},
        restore() {},
        beginPath() {},
        moveTo() {},
        lineTo() {},
        closePath() {},
        fill() {},
        stroke() {},
        arc() { this.arcCount += 1 }
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

const node = { x: 100, y: 100, radius: 12 }
assert.equal(treeLayout.nodeVisibleInViewport(node, 80, 80, 40, 40, 0), true)
assert.equal(treeLayout.nodeVisibleInViewport(node, 113, 80, 40, 40, 0), false)
assert.equal(treeLayout.nodeVisibleInViewport(node, 113, 80, 40, 40, 1), true)

const crossingEdge = { x1: 0, y1: 100, x2: 200, y2: 100 }
const outsideEdge = { x1: 0, y1: 10, x2: 200, y2: 10 }
assert.equal(treeLayout.edgeVisibleInViewport(crossingEdge, 80, 80, 40, 40, 0), true)
assert.equal(treeLayout.edgeVisibleInViewport(outsideEdge, 80, 80, 40, 40, 0), false)

console.log("frontend rendering tests passed")
