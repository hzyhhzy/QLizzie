const assert = require('node:assert/strict')
const path = require('node:path')
const test = require('node:test')
const { loadQmlJs } = require('./qmlJsLoader')
const layout = loadQmlJs(path.join(__dirname, '../app/qml/TreeLayout.js'))
const options = Object.freeze({
    compactLayout: false, minimumWidth: 220, minimumHeight: 260,
    rootText: 'Root', passText: 'Pass', coordinateText: (x, y) => `${x},${y}`
})
const plain = value => JSON.parse(JSON.stringify(value))
function node(id, parent, children, extra = {}) {
    return Object.freeze({ id, parent, children: Object.freeze(children),
        moveNumber: id, player: id % 2 ? 1 : 2, x: id, y: 1, ...extra })
}

test('branches keep first-child lanes, current ancestry, labels and immutable input', () => {
    const nodes = Object.freeze([
        node(0, -1, [1, 3]), node(1, 0, [2]),
        node(2, 1, [], { isPass: true }), node(3, 0, [], { moveNumber: 1 })
    ])
    const result = layout.build(nodes, 2, options)
    assert.deepEqual(plain(result.nodes.map(n => [n.id, n.x, n.y, n.currentPath, n.current])), [
        [0, 36, 36, true, false], [1, 36, 74, true, false],
        [2, 36, 112, true, true], [3, 78, 74, false, false]
    ])
    assert.deepEqual(plain(result.nodes.map(n => [n.coordinate, n.label])), [
        ['Root', '0'], ['1,1', '1'], ['Pass', 'P'], ['3,1', '1']
    ])
    assert.equal(result.edges.length, 3)
    assert.deepEqual(plain(result.edges.map(e => e.current)), [true, true, false])
    assert.equal(result.width, 220)
    assert.equal(result.height, 260)
    assert.equal(layout.nodeAt(result.nodes, 36, 112), 2)
    assert.equal(layout.nodeAt(result.nodes, 1000, 1000), -1)
})

test('sparse deleted nodes and reordered variations preserve surviving IDs', () => {
    const nodes = [node(0, -1, [3, 1]), node(1, 0, []), null, node(3, 0, [], { moveNumber: 1 })]
    const result = layout.build(nodes, 3, { ...options, compactLayout: true })
    assert.deepEqual(plain(result.nodes.map(n => [n.id, n.x])), [[0, 32], [1, 74], [3, 32]])
    assert.equal(result.edges.length, 2)
    assert.equal(result.nodes[2].currentPath, true)
})

test('large board game paths lay out without recursive stack overflow', () => {
    const count = 30000
    const nodes = Array.from({ length: count }, (_, id) =>
        node(id, id - 1, id + 1 < count ? [id + 1] : []))
    const result = layout.build(nodes, count - 1, options)
    assert.equal(result.nodes.length, count)
    assert.equal(result.edges.length, count - 1)
    assert.equal(result.nodes[count - 1].current, true)
    assert.equal(result.nodes.every(n => n.x === 36 && n.currentPath), true)
    assert.equal(result.height, 72 + (count - 1) * 38 + 24)
})
