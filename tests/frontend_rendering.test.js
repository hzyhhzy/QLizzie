const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const { loadQmlJs } = require("./qmlJsLoader")

const root = path.join(__dirname, "..")
const boardInputSource = fs.readFileSync(path.join(root, "app", "qml", "BoardInputLayer.qml"), "utf8")
const mainSource = fs.readFileSync(path.join(root, "app", "qml", "Main.qml"), "utf8")
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

const commaHandler = boardInputSource.slice(
    boardInputSource.indexOf("event.key === Qt.Key_Comma"),
    boardInputSource.indexOf("event.key === Qt.Key_P")
)
assert.match(commaHandler, /app\.playBestEngineMove\(\)/)
assert.doesNotMatch(commaHandler, /isAutoRepeat/)

const backspaceHandler = boardInputSource.slice(
    boardInputSource.indexOf("event.key === Qt.Key_Backspace"),
    boardInputSource.indexOf("event.key === Qt.Key_M")
)
assert.match(backspaceHandler, /app\.requestDeleteCurrentNode\(\)/)
assert.doesNotMatch(backspaceHandler, /isAutoRepeat/)
assert.match(boardInputSource, /function ownsKeyboardFocus\(\)/)
assert.match(boardInputSource, /if \(!inputLayer\.ownsKeyboardFocus\(\)\)/)

const engineMenu = mainSource.slice(
    mainSource.indexOf("id: engineMenu"),
    mainSource.indexOf("id: saveSgfDialog")
)
const addEnginePosition = engineMenu.indexOf('trText("engineAddAndConfigure")')
const restartEnginePosition = engineMenu.indexOf('trText("engineRestartCurrent")')
const closeEnginePosition = engineMenu.indexOf('trText("engineCloseCurrent")')
const presetListPosition = engineMenu.indexOf("Instantiator")
const moreEnginesPosition = engineMenu.indexOf('trText("moreEngines")')
assert.ok(addEnginePosition >= 0)
assert.ok(addEnginePosition < restartEnginePosition)
assert.ok(restartEnginePosition < closeEnginePosition)
assert.ok(closeEnginePosition < presetListPosition)
assert.ok(presetListPosition < moreEnginesPosition)
assert.match(engineMenu, /model:\s*Math\.min\(10,\s*root\.enginePresets\.length\)/)
assert.match(engineMenu, /engineMenu\.insertItem\(index\s*\+\s*4,\s*object\)/)

console.log("frontend rendering tests passed")
