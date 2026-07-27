"use strict"

const assert = require("node:assert/strict")
const path = require("node:path")
const test = require("node:test")
const { loadQmlJs } = require("./qmlJsLoader")

const analysisStatus = loadQmlJs(
    path.join(__dirname, "..", "app", "qml", "AnalysisStatus.js")
)

function analysisApp(nodes, currentNodeId) {
    return {
        nodes,
        currentNodeId,
        nodeById(id) {
            return this.nodes[id] === undefined ? null : this.nodes[id]
        },
        currentNode() {
            return this.nodeById(this.currentNodeId)
        },
        nodePath(id) {
            const result = []
            let node = this.nodeById(id)
            while (node && node.id !== 0) {
                result.unshift(node)
                node = this.nodeById(node.parent)
            }
            return result
        },
        currentMoveNumberValue() {
            const node = this.currentNode()
            return node ? node.moveNumber : 0
        }
    }
}

test("winrate history spans the selected continuation beyond the current node", () => {
    const nodes = [
        { id: 0, parent: -1, children: [1], moveNumber: 0, analysisBlackWinrate: -1 },
        { id: 1, parent: 0, children: [2, 4], moveNumber: 1, analysisBlackWinrate: 52 },
        { id: 2, parent: 1, children: [3], moveNumber: 150, analysisBlackWinrate: 57 },
        { id: 3, parent: 2, children: [], moveNumber: 300, analysisBlackWinrate: 63 },
        { id: 4, parent: 1, children: [], moveNumber: 999, analysisBlackWinrate: 10 }
    ]
    const history = analysisStatus.winrateHistoryData(analysisApp(nodes, 2))

    assert.equal(history.currentMove, 150)
    assert.equal(history.maximumMove, 300)
    assert.deepEqual(
        Array.from(history.points, point => [point.move, point.winrate]),
        [[1, 52], [150, 57], [300, 63]]
    )
})

test("winrate history ignores invalid continuation cycles", () => {
    const nodes = [
        { id: 0, parent: -1, children: [1], moveNumber: 0, analysisBlackWinrate: -1 },
        { id: 1, parent: 0, children: [2], moveNumber: 1, analysisBlackWinrate: 50 },
        { id: 2, parent: 1, children: [1], moveNumber: 2, analysisBlackWinrate: 51 }
    ]
    const history = analysisStatus.winrateHistoryData(analysisApp(nodes, 1))

    assert.equal(history.maximumMove, 2)
    assert.equal(history.points.length, 2)
})
