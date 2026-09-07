const assert = require("node:assert/strict")
const path = require("node:path")
const test = require("node:test")
const { loadQmlJs } = require("./qmlJsLoader")

const qml = path.join(__dirname, "..", "app", "qml")
const registry = loadQmlJs(path.join(qml, "rules", "RuleRegistry.js"))
const rules = loadQmlJs(path.join(qml, "GameRules.js"), { imports: { RuleRegistry: registry } })
const tree = loadQmlJs(path.join(qml, "GameTree.js"), { imports: { GameRules: rules } })
const sgf = loadQmlJs(path.join(qml, "SgfUtils.js"), { imports: { RuleRegistry: registry } })
const config = (ruleMode = rules.RULE_GO, extra = {}) => ({
    boardSizeX: 9, boardSizeY: 9, ruleMode, stoneColorMode: 0, ...extra
})
const plain = value => JSON.parse(JSON.stringify(value))

function apply(state, points, options) {
    for (const [x, y] of points) {
        const result = tree.play(state, x, y, options)
        assert.equal(result.ok, true, result.reason)
        state = result.state
    }
    return state
}

function frozen(value) {
    if (value && typeof value === "object" && !Object.isFrozen(value)) {
        Object.freeze(value)
        for (const child of Object.values(value)) frozen(child)
    }
    return value
}

test("moves and navigation preserve previous snapshots and reuse an existing branch", () => {
    const options = config()
    const initial = frozen(tree.create(options, 7))
    const first = tree.play(initial, 2, 2, options)
    assert.equal(first.ok, true)
    assert.equal(initial.gameNodes.length, 1)
    assert.equal(initial.stoneCount, 0)
    const second = tree.play(frozen(first.state), 3, 2, options)
    const back = tree.navigate(frozen(second.state), 1, options)
    assert.equal(back.state.stoneCount, 1)
    assert.equal(back.state.currentPlayer, 2)
    const again = tree.play(back.state, 3, 2, options)
    assert.equal(again.reused, true)
    assert.equal(again.dirty, false)
    assert.equal(again.state.nextNodeId, 3)
    assert.equal(again.state.currentNodeId, 2)
    assert.equal(again.state.gameTreeGeneration, 7)
    assert.deepEqual(plain(again.state.stones), plain(second.state.stones))
})

test("promoting and deleting a variation preserve siblings and never recycle node IDs", () => {
    const options = config()
    let state = apply(tree.create(options), [[0, 0], [1, 0], [2, 0]], options)
    state = tree.navigate(state, 1, options).state
    state = apply(state, [[1, 1], [2, 1]], options)
    const original = frozen(state)
    const promoted = tree.promote(original, 5)
    assert.equal(promoted.positionChanged, false)
    assert.deepEqual(plain(promoted.state.gameNodes[1].children), [4, 2])
    assert.deepEqual(plain(original.gameNodes[1].children), [2, 4])
    const deleted = tree.remove(frozen(promoted.state), 4, options)
    assert.equal(deleted.state.currentNodeId, 1)
    assert.equal(deleted.state.gameNodes[4], undefined)
    assert.equal(deleted.state.gameNodes[5], undefined)
    assert.deepEqual(plain(deleted.state.gameNodes[1].children), [2])
    assert.equal(deleted.state.stoneCount, 1)
    assert.equal(deleted.state.nextNodeId, 6)
    assert.equal(tree.play(deleted.state, 4, 4, options).state.currentNodeId, 6)
    assert.equal(tree.remove(deleted.state, 0, options).changed, false)
})

test("occupied moves and a failing replay leave node metadata and position unchanged", () => {
    const options = config()
    let state = apply(tree.create(options), [[2, 2], [3, 3]], options)
    const invalid = tree.play(frozen(state), 2, 2, options)
    assert.equal(invalid.ok, false)
    assert.equal(invalid.reason, "occupied")
    assert.equal(invalid.state, state)
    state = plain(state)
    state.gameNodes[2].x = 2
    state.gameNodes[2].y = 2
    state.gameNodes[2].key = "2,2"
    state.gameNodes[1].blackCaptures = 99
    const before = plain(state)
    const rejected = tree.replay(frozen(state), 2, options)
    assert.equal(rejected.ok, false)
    assert.equal(rejected.nodeId, 2)
    assert.equal(rejected.state, state)
    assert.deepEqual(plain(state), before)
    assert.equal(tree.navigate(state, 999, options).ok, false)
})

test("passes clear ko, preserve stones, alternate player and are reused", () => {
    const options = config()
    let state = apply(tree.create(options), [[1, 1]], options)
    state.ko = { key: "0,0", x: 0, y: 0, key2: "", x2: -1, y2: -1 }
    const passed = tree.pass(frozen(state), options)
    assert.equal(passed.state.ko.key, "")
    assert.equal(passed.state.currentPlayer, 1)
    assert.equal(passed.node.key, "pass")
    assert.equal(passed.node.isPass, true)
    assert.equal(passed.state.stoneCount, 1)
    const back = tree.navigate(passed.state, 1, options)
    assert.equal(tree.pass(back.state, options).reused, true)
})

test("an existing ordinary variation uses replayed history before live placement validation", () => {
    const options = config()
    const played = apply(tree.create(options), [[1, 1]], options)
    const back = tree.navigate(played, 0, options).state
    // A stale UI position must not prevent following a valid record branch.
    back.ko = { key: "1,1", x: 1, y: 1, key2: "", x2: -1, y2: -1 }
    const reused = tree.play(frozen(back), 1, 1, options)
    assert.equal(reused.ok, true)
    assert.equal(reused.reused, true)
    assert.equal(reused.state.currentNodeId, 1)
    assert.equal(reused.state.ko.key, "")
})

test("fixed colors and Connect6 turn pairs survive navigation and reset", () => {
    const black = config(rules.RULE_GOMOKU, { stoneColorMode: 1 })
    const blackState = apply(tree.create(black), [[0, 0], [1, 0]], black)
    assert.equal(blackState.currentPlayer, 1)
    assert.equal(blackState.stones["1,0"].player, 1)
    const white = config(rules.RULE_GO, { stoneColorMode: 2 })
    assert.equal(tree.create(white).currentPlayer, 2)
    const connect = config(rules.RULE_CONNECT6)
    let state = tree.create(connect)
    const players = []
    for (let x = 0; x < 5; ++x) {
        players.push(state.currentPlayer)
        state = tree.play(state, x, 0, connect).state
    }
    assert.deepEqual(players, [1, 2, 2, 1, 1])
    assert.equal(tree.navigate(state, 2, connect).state.currentPlayer, 2)
})

test("source and target half-moves preserve board and completed move numbers", () => {
    const options = config(rules.RULE_ATAXX, { boardSizeX: 7, boardSizeY: 7 })
    const initial = frozen(tree.create(options))
    const source = tree.play(initial, 0, 0, options)
    assert.equal(source.node.moveRole, "source")
    assert.equal(source.state.currentPlayer, 1)
    assert.equal(tree.currentMoveNumber(source.state), 0)
    assert.deepEqual(plain(source.state.stones), plain(initial.stones))
    const invalid = tree.play(frozen(source.state), 3, 3, options)
    assert.equal(invalid.ok, false)
    assert.equal(invalid.state, source.state)
    const target = tree.play(source.state, 2, 2, options)
    assert.equal(target.node.moveRole, "target")
    assert.equal(target.state.currentPlayer, 2)
    assert.equal(target.state.stoneCount, 4)
    assert.equal(tree.currentMoveNumber(target.state), 1)
    assert.equal(tree.maxMoveNumber(target.state), 1)
    assert.equal(target.state.stones["2,2"].moveNumber, 1)
    assert.equal(target.state.stones["2,2"].nodeId, 2)
    const back = tree.navigate(target.state, 1, options)
    assert.deepEqual(plain(back.state.stones), plain(initial.stones))
    const reused = tree.play(back.state, 2, 2, options)
    assert.equal(reused.reused, true)
    assert.equal(reused.state.currentPlayer, 2)
    assert.deepEqual(plain(reused.state.stones), plain(target.state.stones))
    assert.equal(tree.nodeIdAtMoveNumber(target.state, 0), 0)
    assert.equal(tree.nodeIdAtMoveNumber(target.state, 1), 2)
    const clone = tree.play(initial, 1, 1, options)
    assert.equal(clone.ok, true)
    assert.equal(clone.node.moveRole, "target")
    assert.equal(clone.state.stoneCount, 5)
    assert.equal(tree.replay(clone.state, 1, options).ok, true)
})

test("Dots and Boxes grants an extra turn and replay preserves derived box ownership", () => {
    const options = config(rules.RULE_DOTS_AND_BOXES, { boardSizeX: 3, boardSizeY: 3 })
    const state = apply(tree.create(options), [[1, 0], [0, 1], [2, 1], [1, 2]], options)
    assert.equal(state.gameNodes[4].extraTurn, true)
    assert.equal(state.currentPlayer, 2)
    assert.equal(state.stones["1,1"].player, 2)
    const replay = tree.replay(frozen(state), 4, options)
    assert.equal(replay.state.currentPlayer, 2)
    assert.deepEqual(plain(replay.state.stones), plain(state.stones))
})

test("captures accumulate for the player and replay reproduces capture metadata", () => {
    const options = config()
    const state = apply(tree.create(options), [
        [0, 1], [1, 1], [1, 0], [7, 7], [2, 1], [7, 6], [1, 2]
    ], options)
    assert.equal(state.blackCaptures, 1)
    assert.equal(state.stones["1,1"], undefined)
    assert.equal(state.gameNodes[7].capturedStones[0].key, "1,1")
    const replay = tree.replay(frozen(state), 7, options)
    assert.equal(replay.state.blackCaptures, 1)
    assert.deepEqual(plain(replay.state.stones), plain(state.stones))
    assert.equal(tree.navigate(state, 6, options).state.blackCaptures, 0)
})

test("forbidden markers are evaluated against the pre-move map without rejecting the record", () => {
    const seen = []
    const options = config(rules.RULE_GOMOKU, {
        forbiddenChecker(x, y, player, map) {
            seen.push([x, y, player, Object.keys(map).length])
            return x === 1 && player === 1
        }
    })
    const played = tree.play(tree.create(options), 1, 1, options)
    assert.equal(played.ok, true)
    assert.equal(played.node.gomokuForbidden, true)
    assert.deepEqual(seen[0], [1, 1, 1, 0])
    const replay = tree.replay(played.state, 1, options)
    assert.equal(replay.state.gameNodes[1].gomokuForbidden, true)
})

test("SGF load validates all branches, preserves annotations and does not share input nodes", () => {
    const options = config()
    const initial = frozen(tree.create(options, 3))
    const parsed = sgf.parseSgf("(;GM[1]SZ[9];B[aa](;W[bb])(;W[cc]))", {
        minBoardSize: 2, maxBoardSize: 52, defaultRuleMode: rules.RULE_GO
    })
    assert.equal(parsed.ok, true)
    parsed.nodes[1].analysisBlackWinrate = 0.67
    parsed.nodes[1].analysisCandidates = [{ move: "B2", visits: 100 }]
    const loaded = tree.load(initial, parsed, options)
    assert.equal(loaded.ok, true)
    assert.equal(loaded.state.gameTreeGeneration, 4)
    assert.equal(loaded.state.currentNodeId, 2)
    assert.equal(loaded.state.gameNodes[1].analysisBlackWinrate, 0.67)
    parsed.nodes[1].analysisCandidates[0].visits = 0
    assert.equal(loaded.state.gameNodes[1].analysisCandidates[0].visits, 100)
    assert.equal(initial.gameNodes.length, 1)
    parsed.nodes[3].x = 0
    parsed.nodes[3].y = 0
    const rejected = tree.load(initial, parsed, options)
    assert.equal(rejected.ok, false)
    assert.equal(rejected.nodeId, 3)
    assert.equal(rejected.state, initial)
})

test("a source-target variation survives SGF roundtrip, including root-first loading", () => {
    const options = config(rules.RULE_ATAXX, { boardSizeX: 7, boardSizeY: 7 })
    let state = apply(tree.create(options), [[0, 0], [2, 2]], options)
    state = tree.navigate(state, 1, options).state
    state = apply(state, [[0, 2]], options)
    const text = sgf.buildSgf(state.gameNodes, options.ruleMode, 7, 7, "Ataxx")
    const parsed = sgf.parseSgf(text, {
        minBoardSize: 2, maxBoardSize: 52, defaultRuleMode: rules.RULE_GO
    })
    assert.equal(parsed.ok, true)
    const loaded = tree.load(tree.create(options), parsed, options, false)
    assert.equal(loaded.ok, true)
    assert.equal(loaded.state.currentNodeId, 0)
    assert.equal(loaded.state.gameNodes[1].moveRole, "source")
    assert.equal(tree.maxMoveNumber(loaded.state), 1)
    const alternative = tree.navigate(loaded.state, 3, options)
    assert.equal(alternative.ok, true)
    assert.equal(alternative.state.stones["0,2"].player, 1)
    assert.equal(alternative.state.currentPlayer, 2)
    assert.equal(tree.currentMoveNumber(alternative.state), 1)
})

test("square-free overwrites survive undo and existing branch reuse", () => {
    const options = config(rules.RULE_SQUARE_FREE)
    const state = apply(tree.create(options), [[2, 2], [2, 2]], options)
    assert.equal(state.stoneCount, 1)
    assert.equal(state.stones["2,2"].player, 2)
    const back = tree.navigate(state, 1, options)
    assert.equal(back.state.stones["2,2"].player, 1)
    const reused = tree.play(back.state, 2, 2, options)
    assert.equal(reused.reused, true)
    assert.equal(reused.state.stones["2,2"].player, 2)
    assert.equal(reused.state.nextNodeId, 3)
})

test("load rejects malformed IDs, orphan nodes and cycles without changing generation", () => {
    const options = config()
    const initial = tree.create(options, 10)
    const game = apply(tree.create(options), [[0, 0], [1, 1]], options)
    function reject(mutator, expected) {
        const parsed = { ...options, nodes: plain(game.gameNodes), nextNodeId: 3 }
        mutator(parsed)
        const result = tree.load(initial, parsed, options)
        assert.equal(result.ok, false)
        assert.equal(result.reason, expected)
        assert.equal(result.state.gameTreeGeneration, 10)
    }
    reject(parsed => { parsed.nodes[1].id = 99 }, "invalid-node-id")
    reject(parsed => { parsed.nodes[0].children = [] }, "orphan-node")
    reject(parsed => { parsed.nodes[1].children = [2, 2] }, "cycle-or-duplicate")
    reject(parsed => { parsed.boardSizeX = NaN }, "invalid-board-size")
    for (const invalid of [Infinity, NaN, 3.5, -1, 0, 2, 2147483648])
        reject(parsed => { parsed.nextNodeId = invalid }, "invalid-node-allocator")
    assert.equal(tree.load(initial, null, options).reason, "missing-game")
    const loaded = tree.load(initial, { ...options, nodes: plain(game.gameNodes) }, options)
    assert.equal(loaded.ok, true)
    assert.equal(loaded.state.nextNodeId, 3)
})

test("analysis metadata updates leave game topology and board untouched", () => {
    const options = config()
    const state = frozen(apply(tree.create(options), [[0, 0]], options))
    const values = { analysisOwnership: [0.4, -0.5], analysisBlackWinrate: 0.7 }
    const result = tree.updateNodeAnalysis(state, 1, values)
    assert.equal(result.ok, true)
    assert.equal(result.positionChanged, false)
    assert.equal(result.dirty, false)
    assert.equal(result.state.stones, state.stones)
    assert.equal(state.gameNodes[1].analysisBlackWinrate, -1)
    values.analysisOwnership[0] = 1
    assert.equal(result.node.analysisOwnership[0], 0.4)
    const rejected = tree.updateNodeAnalysis(state, 1, { parent: 3 })
    assert.equal(rejected.ok, false)
    assert.equal(rejected.state, state)
})

test("Surakarta repetition and pass outcomes follow history across navigation", () => {
    const options = config(rules.RULE_SURAKARTA, { boardSizeX: 6, boardSizeY: 6 })
    let state = apply(tree.create(options), [
        [0, 4], [0, 3], [0, 1], [0, 2],
        [0, 3], [0, 4], [0, 2], [0, 1]
    ], options)
    assert.equal(state.surakartaWinInfo.finished, true)
    assert.equal(state.surakartaWinInfo.reason, "repetition")
    assert.equal(tree.currentMoveNumber(state), 4)
    state = tree.navigate(state, 2, options).state
    assert.equal(state.surakartaWinInfo.finished, false)
    const passed = tree.pass(state, options)
    assert.equal(passed.state.surakartaWinInfo.finished, true)
    assert.equal(passed.state.surakartaWinInfo.reason, "pass")
    assert.equal(passed.state.surakartaWinInfo.player, 1)
})
