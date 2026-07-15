"use strict"

// Run with:
//   node tests/sgf_utils.test.js

const assert = require("node:assert/strict")
const path = require("node:path")
const { loadQmlJs } = require("./qmlJsLoader")

const registryPath = path.join(__dirname, "..", "app", "qml", "rules", "RuleRegistry.js")
const sourcePath = path.join(__dirname, "..", "app", "qml", "SgfUtils.js")
const ruleRegistry = loadQmlJs(registryPath)
const sgf = loadQmlJs(sourcePath, { imports: { RuleRegistry: ruleRegistry } })

function parseOptions(defaultRuleMode) {
    return {
        minBoardSize: 1,
        maxBoardSize: 100,
        defaultRuleMode: defaultRuleMode === undefined ? 0 : defaultRuleMode,
        gameRuleGo: 0,
        gameRuleGomoku: 1,
        gameRuleHex: 2,
        ignoreRuleMode: false
    }
}

function root(children, analysis) {
    const node = {
        id: 0,
        parent: -1,
        children: children || [],
        x: -1,
        y: -1,
        player: 0,
        moveNumber: 0,
        isPass: false
    }
    return Object.assign(node, analysis || {})
}

function move(id, parent, children, player, x, y, role, analysis) {
    const node = {
        id,
        parent,
        children: children || [],
        x,
        y,
        player,
        moveNumber: id,
        isPass: false,
        moveRole: role || ""
    }
    return Object.assign(node, analysis || {})
}

function parseBuilt(nodes, ruleMode, size, ruleText) {
    const text = sgf.buildSgf(nodes, ruleMode, size, size, ruleText || "test")
    const parsed = sgf.parseSgf(text, parseOptions(99))
    assert.equal(parsed.ok, true, parsed.error)
    return { text, parsed }
}

const tests = []

function test(name, fn) {
    tests.push({ name, fn })
}

test("Ataxx source and target roles round-trip", () => {
    const nodes = [
        root([1]),
        move(1, 0, [2], 1, 0, 0, "source"),
        move(2, 1, [], 1, 2, 2, "target")
    ]
    const result = parseBuilt(nodes, 9, 7)

    assert.match(result.text, /QLMR\[source\]/)
    assert.match(result.text, /QLMR\[target\]/)
    assert.equal(result.parsed.ruleMode, 9)
    assert.equal(result.parsed.ruleName, "QLizzie-Ataxx")
    assert.equal(result.parsed.gameId, "10")
    assert.equal(result.parsed.nodes[1].moveRole, "source")
    assert.equal(result.parsed.nodes[2].moveRole, "target")
})

test("Breakthrough gets unique metadata and movement roles", () => {
    const nodes = [
        root([1]),
        move(1, 0, [2], 2, 3, 6, "source"),
        move(2, 1, [], 2, 3, 5, "target")
    ]
    const result = parseBuilt(nodes, 10, 8)

    assert.match(result.text, /GM\[0\]/)
    assert.match(result.text, /RU\[QLizzie-Breakthrough\]/)
    assert.equal(result.parsed.ruleMode, 10)
    assert.equal(result.parsed.ruleName, "QLizzie-Breakthrough")
    assert.equal(result.parsed.nodes[1].moveRole, "source")
    assert.equal(result.parsed.nodes[2].moveRole, "target")
})

test("legacy files without QLMR remain loadable", () => {
    const legacy = "(;FF[4]GM[10]RU[QLizzie-Ataxx]SZ[7];B[aa]MN[1];B[cc]MN[2])"
    const parsed = sgf.parseSgf(legacy, parseOptions(0))

    assert.equal(parsed.ok, true, parsed.error)
    assert.equal(parsed.ruleMode, 9)
    assert.equal(parsed.ruleName, "QLizzie-Ataxx")
    assert.equal(parsed.nodes[1].moveRole, "")
    assert.equal(parsed.nodes[2].moveRole, "")
})

test("variations preserve their parent and child relationships", () => {
    const nodes = [
        root([1]),
        move(1, 0, [2, 3], 1, 0, 0),
        move(2, 1, [], 2, 1, 1),
        move(3, 1, [], 2, 2, 2)
    ]
    const result = parseBuilt(nodes, 0, 19)

    assert.deepEqual(Array.from(result.parsed.nodes[1].children), [2, 3])
    assert.equal(result.parsed.nodes[2].parent, 1)
    assert.equal(result.parsed.nodes[3].parent, 1)
    assert.equal(result.parsed.nodes[2].key, "1,1")
    assert.equal(result.parsed.nodes[3].key, "2,2")
})

test("escaped QLZ analysis payloads round-trip", () => {
    const boardSignature = "board]\\signature\nnext"
    const komiSignature = "komi\\]7.5\n值"
    const candidateMove = "move]\\value\nnext"
    const pvMove = "pv]\\value\nnext"
    const analysis = {
        analysisBlackWinrate: 0.625,
        analysisCandidateBoardSignature: boardSignature,
        analysisCandidateKomiSignature: komiSignature,
        analysisCandidates: [{
            move: candidateMove,
            order: 0,
            visits: 1234,
            winrate: 0.625,
            scoreMean: -1.75,
            scoreStdev: 0.5,
            pv: [pvMove, "pass"],
            pvVisits: [1234, 900]
        }]
    }
    const nodes = [root([1]), move(1, 0, [], 1, 3, 3, "", analysis)]
    const result = parseBuilt(nodes, 0, 19, "comment]\\value\nnext")
    const parsedNode = result.parsed.nodes[1]

    assert.equal(parsedNode.analysisBlackWinrate, 0.625)
    assert.equal(parsedNode.analysisCandidateBoardSignature, boardSignature)
    assert.equal(parsedNode.analysisCandidateKomiSignature, komiSignature)
    assert.equal(parsedNode.analysisCandidates.length, 1)
    assert.equal(parsedNode.analysisCandidates[0].move, candidateMove)
    assert.equal(parsedNode.analysisCandidates[0].pv[0], pvMove)
    assert.equal(parsedNode.analysisCandidates[0].visits, 1234)
    assert.equal(parsedNode.analysisCandidates[0].scoreMean, -1.75)
})

test("all current rule modes have stable and parseable RU/GM metadata", () => {
    const expected = [
        [1, "QLizzie-Go"],
        [4, "QLizzie-Gomoku"],
        [11, "QLizzie-Hex"],
        [0, "QLizzie-SquareFree"],
        [2, "QLizzie-Reversi"],
        [4, "QLizzie-Connect6"],
        [1, "QLizzie-HexGo-Parallelogram"],
        [1, "QLizzie-HexGo-Hexagon"],
        [1, "QLizzie-HexGo-Triangle"],
        [10, "QLizzie-Ataxx"],
        [0, "QLizzie-Breakthrough"],
        [1, "QLizzie-TorusGo"],
        [1, "QLizzie-TwoLibGo"],
        [40, "QLizzie-DotsAndBoxes"]
    ]

    expected.forEach(([gameId, ruleName], ruleMode) => {
        const info = sgf.sgfGameInfo(ruleMode)
        assert.equal(info.gameId, gameId)
        assert.equal(info.ruleName, ruleName)

        const result = parseBuilt([root([])], ruleMode, 19)
        assert.equal(result.parsed.ruleMode, ruleMode)
        assert.equal(result.parsed.ruleName, ruleName)
        assert.equal(result.parsed.gameId, String(gameId))
    })
})

let failures = 0
for (const current of tests) {
    try {
        current.fn()
        process.stdout.write(`ok - ${current.name}\n`)
    } catch (error) {
        failures += 1
        process.stderr.write(`not ok - ${current.name}\n${error.stack}\n`)
    }
}

if (failures > 0) {
    process.stderr.write(`${failures} test(s) failed\n`)
    process.exitCode = 1
} else {
    process.stdout.write(`${tests.length} tests passed\n`)
}
