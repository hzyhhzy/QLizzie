const assert = require("node:assert/strict")
const path = require("node:path")
const test = require("node:test")
const { loadQmlJs } = require("./qmlJsLoader")

function loadGameRules() {
    const qmlDirectory = path.join(__dirname, "..", "app", "qml")
    const registryFilename = path.join(qmlDirectory, "rules", "RuleRegistry.js")
    const registry = loadQmlJs(registryFilename)
    const filename = path.join(qmlDirectory, "GameRules.js")
    return loadQmlJs(filename, { imports: { RuleRegistry: registry } })
}

const rules = loadGameRules()

test("move-source capability identifies every supported source/target ruleset", () => {
    const sourceRules = [rules.RULE_ATAXX, rules.RULE_BREAKTHROUGH, rules.RULE_SURAKARTA]
    for (let ruleMode = 0; ruleMode <= rules.RULE_SURAKARTA; ++ruleMode)
        assert.equal(rules.isSourceMoveRule(ruleMode), sourceRules.includes(ruleMode))
    assert.equal(rules.isSourceMoveRule(-1), false)
})

function stone(x, y, player, extra = {}) {
    return {
        x,
        y,
        key: `${x},${y}`,
        player,
        moveNumber: 0,
        nodeId: 0,
        ...extra
    }
}

function mapOf(...stones) {
    const map = {}
    for (const item of stones)
        map[item.key] = item
    return map
}

function plain(value) {
    return JSON.parse(JSON.stringify(value))
}

test("ordinary placement is immutable and occupied failure is transactional", () => {
    const input = {}
    const placed = rules.applyMoveOnMap(
        input,
        { x: 9, y: 9 },
        stone(4, 4, 1, { moveNumber: 3, nodeId: 7 }),
        { ruleMode: rules.RULE_GOMOKU }
    )

    assert.equal(placed.ok, true)
    assert.equal(placed.role, "place")
    assert.equal(placed.nextMap["4,4"].nodeId, 7)
    assert.deepEqual(input, {})

    const occupied = rules.applyMoveOnMap(
        placed.nextMap,
        { x: 9, y: 9 },
        stone(4, 4, 2),
        { ruleMode: rules.RULE_GOMOKU }
    )
    assert.equal(occupied.ok, false)
    assert.equal(occupied.reason, "occupied")
    assert.deepEqual(plain(occupied.nextMap), plain(placed.nextMap))
})

test("trusted replay may opt into in-place reduction", () => {
    const input = {}
    const result = rules.applyMoveOnMap(
        input,
        { x: 9, y: 9 },
        stone(4, 4, 1),
        { ruleMode: rules.RULE_GOMOKU, mutate: true }
    )

    assert.equal(result.ok, true)
    assert.equal(result.nextMap, input)
    assert.equal(input["4,4"].player, 1)
})

test("square-free placement may replace a stone without changing the input map", () => {
    const input = mapOf(stone(1, 1, 1, { customMetadata: "kept-on-clone" }))
    const result = rules.applyMoveOnMap(
        input,
        { x: 3, y: 3 },
        stone(1, 1, 2),
        { ruleMode: rules.RULE_SQUARE_FREE }
    )

    assert.equal(result.ok, true)
    assert.equal(result.nextMap["1,1"].player, 2)
    assert.equal(input["1,1"].player, 1)
    assert.equal(rules.cloneStoneMap(input)["1,1"].customMetadata, "kept-on-clone")
})

test("Go capture exposes a unified capture and ko result", () => {
    const input = mapOf(
        stone(1, 1, 2),
        stone(0, 1, 1),
        stone(1, 0, 1),
        stone(2, 1, 1)
    )
    const result = rules.applyMoveOnMap(
        input,
        { x: 3, y: 3 },
        stone(1, 2, 1),
        { ruleMode: rules.RULE_GO }
    )

    assert.equal(result.ok, true)
    assert.equal(result.captured, 1)
    assert.equal(result.capturedStones[0].key, "1,1")
    assert.equal(result.nextMap["1,1"], undefined)
    assert.equal(input["1,1"].player, 2)
    assert.equal(typeof result.ko.key, "string")
    assert.equal(result.koLoc, result.ko)
})

test("Go rejects the active ko point before changing the returned map", () => {
    const input = mapOf(stone(0, 0, 1))
    const result = rules.applyMoveOnMap(
        input,
        { x: 3, y: 3 },
        stone(1, 1, 2),
        { ruleMode: rules.RULE_GO, activeKoLoc: { key: "1,1", key2: "" } }
    )

    assert.equal(result.ok, false)
    assert.equal(result.reason, "ko")
    assert.deepEqual(plain(result.nextMap), plain(input))
})

test("Reversi reports converted stones while keeping the source map immutable", () => {
    const input = rules.initialStoneMap({ x: 8, y: 8 }, rules.RULE_REVERSI)
    const result = rules.applyMoveOnMap(
        input,
        { x: 8, y: 8 },
        stone(2, 3, 1),
        { ruleMode: rules.RULE_REVERSI }
    )

    assert.equal(result.ok, true)
    assert.equal(result.convertedStones.length, 1)
    assert.equal(result.convertedStones[0].key, "3,3")
    assert.equal(result.nextMap["3,3"].player, 1)
    assert.equal(input["3,3"].player, 2)
})

test("Ataxx source and target actions have explicit phase semantics", () => {
    const input = rules.initialStoneMap({ x: 7, y: 7 }, rules.RULE_ATAXX)
    const selected = rules.applyMoveOnMap(
        input,
        { x: 7, y: 7 },
        { x: 0, y: 0, player: 1, role: "source" },
        { ruleMode: rules.RULE_ATAXX }
    )

    assert.equal(selected.ok, true)
    assert.equal(selected.role, "source")
    assert.equal(selected.turnCompleted, false)
    assert.equal(selected.mapChanged, false)
    assert.equal(selected.nextSource.key, "0,0")
    assert.deepEqual(plain(selected.nextMap), plain(input))

    const jumped = rules.applyMoveOnMap(
        selected.nextMap,
        { x: 7, y: 7 },
        { player: 1, role: "target", target: { x: 2, y: 0 }, source: selected.nextSource },
        { ruleMode: rules.RULE_ATAXX }
    )

    assert.equal(jumped.ok, true)
    assert.equal(jumped.role, "target")
    assert.equal(jumped.moveKind, "jump")
    assert.equal(jumped.turnCompleted, true)
    assert.equal(jumped.nextMap["0,0"], undefined)
    assert.equal(jumped.nextMap["2,0"].player, 1)
    assert.equal(input["0,0"].player, 1)
})

test("Ataxx clone is a complete target action without a selected source", () => {
    const input = rules.initialStoneMap({ x: 7, y: 7 }, rules.RULE_ATAXX)
    const result = rules.applyMoveOnMap(
        input,
        { x: 7, y: 7 },
        { x: 1, y: 0, player: 1 },
        { ruleMode: rules.RULE_ATAXX }
    )

    assert.equal(result.ok, true)
    assert.equal(result.role, "target")
    assert.equal(result.moveKind, "clone")
    assert.equal(result.nextMap["0,0"].player, 1)
    assert.equal(result.nextMap["1,0"].player, 1)
})

test("Breakthrough source and target use the same reducer contract", () => {
    const input = rules.initialStoneMap({ x: 8, y: 8 }, rules.RULE_BREAKTHROUGH)
    const selected = rules.applyMoveOnMap(
        input,
        { x: 8, y: 8 },
        { x: 0, y: 6, player: 1, moveRole: "source" },
        { ruleMode: rules.RULE_BREAKTHROUGH }
    )
    assert.equal(selected.ok, true)
    assert.equal(selected.nextSource.key, "0,6")

    const moved = rules.applyMoveOnMap(
        selected.nextMap,
        { x: 8, y: 8 },
        { x: 0, y: 5, player: 1, moveRole: "target" },
        { ruleMode: rules.RULE_BREAKTHROUGH, pendingSource: selected.nextSource }
    )
    assert.equal(moved.ok, true)
    assert.equal(moved.moveKind, "move")
    assert.equal(moved.nextMap["0,6"], undefined)
    assert.equal(moved.nextMap["0,5"].player, 1)
    assert.equal(moved.nextMap["0,5"].moveNumber, 0)
})

test("Breakthrough target metadata describes the completed move", () => {
    const input = rules.initialStoneMap({ x: 8, y: 8 }, rules.RULE_BREAKTHROUGH)
    const result = rules.applyMoveOnMap(
        input,
        { x: 8, y: 8 },
        {
            player: 1,
            source: { x: 0, y: 6 },
            target: { x: 0, y: 5, moveNumber: 12, nodeId: 34 },
            role: "target"
        },
        { ruleMode: rules.RULE_BREAKTHROUGH }
    )

    assert.equal(result.ok, true)
    assert.equal(result.nextMap["0,5"].moveNumber, 12)
    assert.equal(result.nextMap["0,5"].nodeId, 34)
})

test("Breakthrough captures are reported uniformly", () => {
    const input = mapOf(stone(1, 2, 1), stone(2, 1, 2))
    const result = rules.applyMoveOnMap(
        input,
        { x: 4, y: 4 },
        { player: 1, source: { x: 1, y: 2 }, target: { x: 2, y: 1 }, role: "target" },
        { ruleMode: rules.RULE_BREAKTHROUGH }
    )

    assert.equal(result.ok, true)
    assert.equal(result.moveKind, "capture")
    assert.equal(result.captured, 1)
    assert.equal(result.capturedStones[0].key, "2,1")
})

test("Surakarta starts from the fixed 6x6 opening and moves in two phases", () => {
    const input = rules.initialStoneMap({ x: 6, y: 6 }, rules.RULE_SURAKARTA)
    assert.equal(Object.keys(input).length, 24)
    for (let x = 0; x < 6; ++x) {
        assert.equal(input[`${x},0`].player, 2)
        assert.equal(input[`${x},1`].player, 2)
        assert.equal(input[`${x},4`].player, 1)
        assert.equal(input[`${x},5`].player, 1)
    }

    const selected = rules.applyMoveOnMap(
        input,
        { x: 6, y: 6 },
        { x: 0, y: 4, player: 1, role: "source" },
        { ruleMode: rules.RULE_SURAKARTA }
    )
    assert.equal(selected.ok, true)
    assert.equal(selected.role, "source")
    assert.equal(selected.nextSource.key, "0,4")

    const moved = rules.applyMoveOnMap(
        selected.nextMap,
        { x: 6, y: 6 },
        { x: 0, y: 3, player: 1, role: "target" },
        { ruleMode: rules.RULE_SURAKARTA, pendingSource: selected.nextSource }
    )
    assert.equal(moved.ok, true)
    assert.equal(moved.moveKind, "move")
    assert.equal(moved.nextMap["0,4"], undefined)
    assert.equal(moved.nextMap["0,3"].player, 1)
})

test("Surakarta captures require an unobstructed path through an outer loop", () => {
    const dims = { x: 6, y: 6 }
    const capturable = mapOf(stone(1, 2, 1), stone(2, 3, 2))
    const source = { x: 1, y: 2, player: 1, role: "source" }
    const selected = rules.applyMoveOnMap(
        capturable, dims, source, { ruleMode: rules.RULE_SURAKARTA }
    )
    assert.equal(selected.ok, true)

    const captured = rules.applyMoveOnMap(
        selected.nextMap,
        dims,
        { x: 2, y: 3, player: 1, role: "target" },
        { ruleMode: rules.RULE_SURAKARTA, pendingSource: selected.nextSource }
    )
    assert.equal(captured.ok, true)
    assert.equal(captured.moveKind, "capture")
    assert.equal(captured.captured, 1)
    assert.equal(captured.capturedStones[0].key, "2,3")
    assert.equal(captured.nextMap["1,2"], undefined)
    assert.equal(captured.nextMap["2,3"].player, 1)

    const blocked = mapOf(
        stone(1, 2, 1), stone(2, 1, 1), stone(2, 2, 1),
        stone(1, 1, 1), stone(1, 3, 1), stone(2, 3, 2)
    )
    const blockedCapture = rules.applyMoveOnMap(
        blocked,
        dims,
        { player: 1, role: "target", source: { x: 1, y: 2 }, target: { x: 2, y: 3 } },
        { ruleMode: rules.RULE_SURAKARTA }
    )
    assert.equal(blockedCapture.ok, false)

    const straight = mapOf(
        stone(1, 2, 1), stone(2, 2, 1), stone(1, 1, 1),
        stone(1, 3, 1), stone(0, 2, 2)
    )
    const straightCapture = rules.applyMoveOnMap(
        straight,
        dims,
        { player: 1, role: "target", source: { x: 1, y: 2 }, target: { x: 0, y: 2 } },
        { ruleMode: rules.RULE_SURAKARTA }
    )
    assert.equal(straightCapture.ok, false)

    const corner = mapOf(stone(0, 0, 1), stone(2, 3, 2))
    assert.equal(rules.surakartaCaptureTargets(
        corner, dims, 1, { x: 0, y: 0 }
    ).length, 0)
})

test("Surakarta ends by stone count when the next player has no legal move", () => {
    const input = mapOf(
        stone(0, 0, 1),
        stone(0, 1, 2), stone(1, 0, 2), stone(1, 1, 2)
    )
    const outcome = rules.buildSurakartaWin(
        input, { x: 6, y: 6 }, rules.RULE_SURAKARTA, 1
    )
    assert.equal(outcome.finished, true)
    assert.equal(outcome.player, 2)
    assert.equal(outcome.reason, "no-legal-move")
})

test("Surakarta uses completed turns for its twofold repetition result", () => {
    const path = [
        { id: 1, x: 0, y: 4, player: 1, moveRole: "source" },
        { id: 2, x: 0, y: 3, player: 1, moveRole: "target" },
        { id: 3, x: 0, y: 1, player: 2, moveRole: "source" },
        { id: 4, x: 0, y: 2, player: 2, moveRole: "target" },
        { id: 5, x: 0, y: 3, player: 1, moveRole: "source" },
        { id: 6, x: 0, y: 4, player: 1, moveRole: "target" },
        { id: 7, x: 0, y: 2, player: 2, moveRole: "source" },
        { id: 8, x: 0, y: 1, player: 2, moveRole: "target" }
    ]
    const outcome = rules.buildSurakartaHistoryOutcome(
        path, { x: 6, y: 6 }, rules.RULE_SURAKARTA
    )
    assert.equal(outcome.finished, true)
    assert.equal(outcome.player, 0)
    assert.equal(outcome.reason, "repetition")
})

test("passing loses immediately in Surakarta even after selecting a source", () => {
    const path = [
        { id: 1, x: 0, y: 4, player: 1, moveRole: "source" },
        { id: 2, x: -1, y: -1, player: 1, isPass: true, moveRole: "" }
    ]
    const outcome = rules.buildSurakartaHistoryOutcome(
        path, { x: 6, y: 6 }, rules.RULE_SURAKARTA
    )
    assert.equal(outcome.finished, true)
    assert.equal(outcome.player, 2)
    assert.equal(outcome.reason, "pass")
})

test("move-source nodes do not double the displayed move number", () => {
    assert.equal(rules.completedMoveNumber([
        { moveNumber: 1, moveRole: "source" },
        { moveNumber: 2, moveRole: "target" },
        { moveNumber: 3, moveRole: "source" },
        { moveNumber: 4, moveRole: "target" },
        { moveNumber: 5, moveRole: "source" }
    ]), 2)
})

test("Dots and Boxes reports claimed boxes and preserves derived metadata", () => {
    const input = mapOf(
        stone(0, 1, 1),
        stone(2, 1, 2),
        stone(1, 0, 1)
    )
    const result = rules.applyMoveOnMap(
        input,
        { x: 5, y: 5 },
        stone(1, 2, 2),
        { ruleMode: rules.RULE_DOTS_AND_BOXES }
    )

    assert.equal(result.ok, true)
    assert.equal(result.moveKind, "edge")
    assert.equal(result.completedBoxes.length, 1)
    assert.equal(result.completedBoxes[0].x, 1)
    assert.equal(result.extraTurn, true)
    assert.equal(result.nextMap["1,1"].player, 2)
    assert.equal(result.nextMap["1,1"].derivedBox, true)
    assert.equal(input["1,2"], undefined)
    assert.equal(rules.cloneStoneMap(result.nextMap)["1,1"].derivedBox, true)
})

test("pass completes a turn without changing the map", () => {
    const input = mapOf(stone(0, 0, 1))
    const result = rules.applyMoveOnMap(
        input,
        { x: 3, y: 3 },
        { isPass: true, player: 2 },
        { ruleMode: rules.RULE_GO }
    )

    assert.equal(result.ok, true)
    assert.equal(result.role, "pass")
    assert.equal(result.turnCompleted, true)
    assert.equal(result.mapChanged, false)
    assert.deepEqual(plain(result.nextMap), plain(input))
})

test("tree validation accepts legacy move phases and rejects an invalid target", () => {
    const validNodes = [
        { id: 0, parent: -1, children: [1] },
        { id: 1, parent: 0, children: [2], x: 0, y: 0, player: 1, moveNumber: 1 },
        { id: 2, parent: 1, children: [], x: 2, y: 0, player: 1, moveNumber: 2 }
    ]
    const valid = rules.validateGameTree(
        validNodes,
        { x: 7, y: 7 },
        rules.RULE_ATAXX
    )
    assert.equal(valid.ok, true)

    const invalidNodes = plain(validNodes)
    invalidNodes[2].x = 4
    const invalid = rules.validateGameTree(
        invalidNodes,
        { x: 7, y: 7 },
        rules.RULE_ATAXX
    )
    assert.equal(invalid.ok, false)
    assert.equal(invalid.nodeId, 2)
    assert.equal(invalid.reason, "invalid-target")
})
