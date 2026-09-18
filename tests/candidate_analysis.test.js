"use strict"

const assert = require("node:assert/strict")
const path = require("node:path")
const test = require("node:test")
const { loadQmlJs } = require("./qmlJsLoader")

const candidatePath = path.join(__dirname, "..", "app", "qml", "CandidateAnalysis.js")
const analysisStatusPath = path.join(__dirname, "..", "app", "qml", "AnalysisStatus.js")
const registryPath = path.join(__dirname, "..", "app", "qml", "rules", "RuleRegistry.js")
const gameRulesPath = path.join(__dirname, "..", "app", "qml", "GameRules.js")
const registry = loadQmlJs(registryPath)
const gameRules = loadQmlJs(gameRulesPath, { imports: { RuleRegistry: registry } })
const candidateModel = loadQmlJs(path.join(__dirname, "..", "app", "qml", "CandidateModel.js"))
const movePreview = loadQmlJs(path.join(__dirname, "..", "app", "qml", "MovePreview.js"), {
    imports: { GameRules: gameRules }
})
const candidateAnalysis = loadQmlJs(candidatePath, {
    imports: {
        GameRules: gameRules,
        CandidateModel: candidateModel,
        MovePreview: movePreview
    }
})
const analysisStatus = loadQmlJs(analysisStatusPath)

function createApp(overrides = {}) {
    const translations = {
        passMove: "Pass",
        resignMove: "Resign",
        engineSuggestsResign: "Engine suggests resigning",
        engineBestMove: "Best move"
    }
    return Object.assign({
        candidateDisplayCount: 10,
        candidateTableRowLimit: 20,
        candidateMinVisitRatio: 0,
        candidateShowFilteredMarkers: true,
        candidateYzyAlphaFactor: 5,
        candidateYzyColorRatio: 2,
        candidateYzyMinAlpha: 32,
        candidateYzyMaxAlpha: 240,
        candidateWinrateDecimals: 1,
        candidateWinrateShowPercent: false,
        candidateWinrateLabelVisible: true,
        candidateWinrateFontSize: 57,
        candidateWinrateBold: true,
        candidateVisitsLabelVisible: false,
        candidateVisitsFontSize: 42,
        candidateVisitsBold: false,
        candidateScoreLabelVisible: false,
        candidateScoreDecimals: 1,
        candidateScoreShowPercent: false,
        candidateScoreFontSize: 36,
        candidateScoreBold: true,
        candidateLabelTextColor: "#000000",
        clamp(value, low, high) {
            return Math.min(Math.max(value, low), high)
        },
        parseEngineCoordinate(move) {
            return String(move).trim().toUpperCase() === "D4" ? { x: 3, y: 5 } : null
        },
        keyFor(x, y) {
            return `${x},${y}`
        },
        coordinateText(x, y) {
            return `point(${x},${y})`
        },
        trText(key) {
            return translations[key] || key
        },
        passMove() {},
        placeStone() {
            return true
        },
        statusMode: "",
        statusMessage: ""
    }, overrides)
}

test("pass candidates remain in the candidate list without creating a board marker", () => {
    const app = createApp()
    const built = candidateAnalysis.buildCandidateItems(app, [
        { move: "pass", order: 0, visits: 100, winrate: 0.55, pv: ["pass"] },
        { move: "D4", order: 1, visits: 50, winrate: 0.50, pv: ["D4"] }
    ])

    assert.equal(built.items.length, 2)
    assert.equal(built.table.length, 2)
    assert.equal(built.items[0].specialMove, "pass")
    assert.equal(built.items[0].boardPoint, false)
    assert.equal(built.items[0].boardVisible, false)
    assert.equal(built.items[0].displayMoveText, "Pass")
    assert.equal(built.table[0].coordinate, "Pass")
    assert.equal(built.itemMap.pass, built.items[0])
    assert.equal(analysisStatus.engineCandidateSummaryText({
        engineCandidateItems: built.items,
        trText: app.trText,
        coordinateText: app.coordinateText
    }), "Best move: Pass 55.0")
})

test("best-candidate shortcut plays pass when pass is ranked first", () => {
    let passCount = 0
    let placedCount = 0
    const app = createApp({
        passMove() {
            passCount += 1
        },
        placeStone() {
            placedCount += 1
            return true
        }
    })
    const built = candidateAnalysis.buildCandidateItems(app, [
        { move: "PASS", order: 0, visits: 100, winrate: 0.60 },
        { move: "D4", order: 1, visits: 90, winrate: 0.59 }
    ])

    assert.equal(candidateAnalysis.playBestCandidate(app, built.items), true)
    assert.equal(passCount, 1)
    assert.equal(placedCount, 0)
})

test("best-candidate shortcut reports resign and never falls through to the next move", () => {
    let passCount = 0
    let placedCount = 0
    const app = createApp({
        passMove() {
            passCount += 1
        },
        placeStone() {
            placedCount += 1
            return true
        }
    })
    const built = candidateAnalysis.buildCandidateItems(app, [
        { move: "Resign", order: 0, visits: 120, winrate: 0.01 },
        { move: "D4", order: 1, visits: 110, winrate: 0.02 }
    ])

    assert.equal(built.items.length, 2)
    assert.equal(built.items[0].specialMove, "resign")
    assert.equal(built.items[0].displayMoveText, "Resign")
    assert.equal(built.items[1].boardPoint, true)
    assert.equal(candidateAnalysis.playBestCandidate(app, built.items), true)
    assert.equal(passCount, 0)
    assert.equal(placedCount, 0)
    assert.equal(app.statusMode, "message")
    assert.equal(app.statusMessage, "Engine suggests resigning")
    assert.equal(analysisStatus.engineCandidateSummaryText({
        engineCandidateItems: built.items,
        trText: app.trText,
        coordinateText: app.coordinateText
    }), "Best move: Resign 1.0")
})

test("candidate display preserves engine order and only sorts an out-of-order fallback", () => {
    const app = createApp()
    const alreadyOrdered = candidateAnalysis.buildCandidateItems(app, [
        { move: "pass", order: 0, visits: 30, winrate: 0.55 },
        { move: "D4", order: 1, visits: 20, winrate: 0.50 }
    ])
    assert.equal(alreadyOrdered.items.map(item => item.move).join(","), "pass,D4")

    const fallbackSorted = candidateAnalysis.buildCandidateItems(app, [
        { move: "D4", order: 2, visits: 20, winrate: 0.50 },
        { move: "pass", order: 1, visits: 30, winrate: 0.55 }
    ])
    assert.equal(fallbackSorted.items.map(item => item.move).join(","), "pass,D4")
})

test("unknown winrates stay distinct from a real zero without changing rank or marker colors", () => {
    const settings = candidateAnalysis.presentationSettings(createApp())
    const values = [0, NaN, Infinity, -Infinity, undefined]
    const entries = values.map((winrate, order) => ({
        candidate: { move: `A${order + 1}`, order, visits: 100, winrate },
        point: { x: 0, y: order }, moveKind: "", moveText: `A${order + 1}`
    }))
    const built = candidateModel.build(entries.slice().reverse(), settings)

    assert.deepEqual(Array.from(built.items, item => item.order), [0, 1, 2, 3, 4])
    assert.deepEqual(Array.from(built.table, row => row.winrateText), ["0.0", "--", "--", "--", "--"])
    assert.equal(candidateModel.winrateValue(entries[0].candidate), 0)
    for (let index = 0; index < built.items.length; ++index) {
        const item = built.items[index]
        assert.match(item.color, /^#[0-9a-f]{6}$/i)
        assert.ok(Number.isFinite(item.opacity))
        assert.ok(Number.isFinite(item.outlineOpacity))
        assert.equal(item.labelLines[0].text, index === 0 ? "0.0" : "--")
        if (index > 0)
            assert.ok(Number.isNaN(candidateModel.winrateValue(entries[index].candidate)))
    }
})

test("candidate table rows are capped without removing board candidates", () => {
    const app = createApp({
        candidateDisplayCount: 1,
        candidateTableRowLimit: 2,
        parseEngineCoordinate(move) {
            const match = /^A([1-3])$/.exec(String(move))
            return match ? { x: 0, y: Number(match[1]) - 1 } : null
        }
    })
    const built = candidateAnalysis.buildCandidateItems(app, [
        { move: "A1", order: 0, visits: 30, winrate: 0.55, pvText: "A1 A2" },
        { move: "A2", order: 1, visits: 20, winrate: 0.50, pvText: "A2 A3" },
        { move: "A3", order: 2, visits: 10, winrate: 0.45, pvText: "A3 A1" }
    ])

    assert.equal(built.items.length, 3)
    assert.equal(Object.keys(built.itemMap).length, 3)
    assert.equal(built.table.length, 2)
    assert.equal(built.table.map(row => row.coordinate).join(","),
                 "point(0,0),point(0,1)")
    assert.equal(built.items[2].labelLines.length, 0)
    assert.equal(built.items[2]._pvMoves, undefined)
    assert.equal(candidateAnalysis.pvMoves(built.items[2]).join(","), "A3,A1")
    assert.equal(built.items[2]._pvMoves.length, 2)
})

test("compact PV text preserves parenthesized moves and is expanded lazily", () => {
    const candidate = { pvText: "D4 (A1 B2) pass" }

    assert.equal(candidate._pvMoves, undefined)
    assert.equal(candidateAnalysis.pvMoves(candidate).join(","),
                 "D4,(A1 B2),pass")
    assert.equal(candidate._pvMoves.length, 3)
})

test("Surakarta PV preview consumes source and loop-capture target as one arrow", () => {
    const stones = {
        "1,2": { x: 1, y: 2, key: "1,2", player: 1, moveNumber: 0, nodeId: 0 },
        "2,3": { x: 2, y: 3, key: "2,3", player: 2, moveNumber: 0, nodeId: 0 }
    }
    const app = createApp({
        gameRuleAtaxx: registry.RULE_ATAXX,
        gameRuleBreakthrough: registry.RULE_BREAKTHROUGH,
        gameRuleSurakarta: registry.RULE_SURAKARTA,
        gameRuleMode: registry.RULE_SURAKARTA,
        currentPlayer: 1,
        stones,
        candidateVariationPreviewMaxMoves: 2,
        boardDims() { return { x: 6, y: 6 } },
        pointInRuleBoard(x, y) { return x >= 0 && x < 6 && y >= 0 && y < 6 },
        currentMoveSourcePoint() { return null },
        parseEngineCoordinate(move) {
            if (move === "source") return { x: 1, y: 2 }
            if (move === "target") return { x: 2, y: 3 }
            return null
        }
    })
    const items = candidateAnalysis.activeMoveRuleVariationItems(
        app, { pv: ["source", "target"] }, false
    )

    assert.equal(items.length, 1)
    assert.equal(items[0].kind, "arrow")
    assert.deepEqual(
        { fromX: items[0].fromX, fromY: items[0].fromY, x: items[0].x, y: items[0].y },
        { fromX: 1, fromY: 2, x: 2, y: 3 }
    )
})

function frozen(value) {
    if (value && typeof value === "object") {
        for (const child of Object.values(value))
            frozen(child)
        Object.freeze(value)
    }
    return value
}

function plain(value) {
    return JSON.parse(JSON.stringify(value))
}

function previewMap(...stones) {
    return Object.fromEntries(stones.map(([x, y, player]) => [
        `${x},${y}`, { x, y, player, key: `${x},${y}`, moveNumber: 0, nodeId: 0 }
    ]))
}

test("pure candidate projection filters markers independently of table rows and preserves input", () => {
    const settings = frozen(candidateAnalysis.presentationSettings(createApp({
        candidateDisplayCount: 2,
        candidateMinVisitRatio: 0.5,
        candidateShowFilteredMarkers: false,
        candidateTableRowLimit: 3,
        candidateVisitsLabelVisible: true,
        candidateScoreLabelVisible: true,
        candidateScoreShowPercent: true
    })))
    const entries = frozen([
        { candidate: { move: "B2", order: 2, visits: 40, winrate: 0.4, scoreMean: -1.25 },
          point: { x: 1, y: 1 }, moveKind: "", moveText: "B2" },
        { candidate: { move: "pass", order: 0, visits: 100, winrate: 0.75 },
          point: null, moveKind: "pass", moveText: "Pass" },
        { candidate: { move: "A1", order: 1, visits: 60, winrate: 0.55, pv: ["A1", "B2"] },
          point: { x: 0, y: 0 }, moveKind: "", moveText: "A1" }
    ])
    const before = JSON.stringify(entries)
    const built = candidateModel.build(entries, settings)

    assert.deepEqual(Array.from(built.items, item => item.move), ["pass", "A1", "B2"])
    assert.deepEqual(Array.from(built.items, item => item.boardVisible), [false, true, false])
    assert.deepEqual(Array.from(built.items, item => item.qualified), [true, true, false])
    assert.equal(built.table.length, 3)
    assert.equal(built.items[2].scoreText, "-1.3%")
    assert.equal(built.items[2].labelLines.length, 0)
    assert.deepEqual(Array.from(built.items[1].labelLines, line => line.text), ["55.0", "60"])
    assert.equal(built.itemMap["0,0"], built.items[1])
    assert.equal(JSON.stringify(entries), before)
})

test("projection retains engine ranks when a coordinate is malformed", () => {
    const settings = candidateAnalysis.presentationSettings(createApp({ candidateDisplayCount: 1 }))
    const built = candidateModel.build([
        { candidate: { move: "bad", order: 0, visits: 100 }, point: null, moveKind: "", moveText: "" },
        { candidate: { move: "A1", order: 1, visits: 50 }, point: { x: 0, y: 0 }, moveKind: "", moveText: "A1" }
    ], settings)
    assert.equal(built.items.length, 1)
    assert.equal(built.items[0].displayIndex, 2)
    assert.equal(built.items[0].qualified, false)
    assert.equal(built.items[0].visitRatio, 0.5)
    assert.equal(built.table[0].row, 2)
})

test("Ataxx preview clones and converts neighbors without changing a frozen position", () => {
    const position = frozen({
        map: previewMap([0, 0, 1], [2, 1, 2], [6, 6, 2]), player: 1, source: null
    })
    const actions = frozen([{ x: 1, y: 1 }, { x: 5, y: 5 }, { x: 2, y: 2 }])
    const config = frozen({ dims: { x: 7, y: 7 }, ruleMode: registry.RULE_ATAXX, maxMoves: 0 })
    const before = JSON.stringify(position)
    const result = movePreview.sourceVariation(position, config, actions)
    assert.equal(result.items.length, 2)
    assert.equal(result.nextIndex, 2)
    assert.deepEqual(Array.from(result.items, item => item.kind), ["stone", "stone"])
    assert.deepEqual(Array.from(result.items, item => item.player), [1, 2])
    assert.equal(result.position.map["0,0"].player, 1)
    assert.equal(result.position.map["2,1"].player, 1)
    assert.equal(result.position.map["2,2"], undefined)
    assert.equal(JSON.stringify(position), before)
})

test("Ataxx preview merges source and jump target into one numbered arrow", () => {
    const position = frozen({ map: previewMap([0, 0, 1], [6, 6, 2]), player: 1, source: null })
    const result = movePreview.sourceVariation(position, {
        dims: { x: 7, y: 7 }, ruleMode: registry.RULE_ATAXX, maxMoves: 1
    }, [{ x: 0, y: 0 }, { x: 2, y: 0 }, { x: 5, y: 5 }])
    assert.equal(result.nextIndex, 2)
    assert.equal(result.items.length, 1)
    assert.deepEqual(plain(result.items[0]), {
        kind: "arrow", fromX: 0, fromY: 0, x: 2, y: 0, key: "2,0", player: 1, moveNumber: 1, nodeId: -1
    })
    assert.equal(result.position.map["0,0"], undefined)
    assert.equal(result.position.map["2,0"].player, 1)
    assert.equal(position.map["0,0"].player, 1)
})

test("selected source needs only a target token and an illegal reply stops the preview", () => {
    const position = frozen({
        map: previewMap([1, 2, 1], [2, 1, 2], [4, 0, 2]),
        player: 1, source: { x: 1, y: 2 }
    })
    const result = movePreview.sourceVariation(position, {
        dims: { x: 5, y: 5 }, ruleMode: registry.RULE_BREAKTHROUGH, maxMoves: 10
    }, [{ x: 2, y: 1 }, { x: 4, y: 0 }, { x: 4, y: 2 }, { x: 4, y: 1 }])
    assert.equal(result.items.length, 1)
    assert.equal(result.items[0].kind, "arrow")
    assert.equal(result.items[0].fromX, 1)
    assert.equal(result.position.map["1,2"], undefined)
    assert.equal(result.position.map["2,1"].player, 1)
    assert.equal(result.position.map["4,0"].player, 2)
    assert.equal(result.position.map["4,1"], undefined)
    assert.equal(result.nextIndex, 2)
    assert.equal(result.reason, "invalid-target")
    assert.equal(position.map["2,1"].player, 2)
})

test("source-only, wrong-owner and malformed variations never invent a move", () => {
    const position = frozen({ map: previewMap([0, 0, 1], [6, 6, 2]), player: 1, source: null })
    const config = { dims: { x: 7, y: 7 }, ruleMode: registry.RULE_ATAXX, maxMoves: 2 }
    const incomplete = movePreview.sourceVariation(position, config, [{ x: 0, y: 0 }])
    assert.equal(incomplete.items.length, 0)
    assert.equal(incomplete.reason, "incomplete-move")
    for (const actions of [[{ x: 6, y: 6 }, { x: 4, y: 6 }], [null, { x: 1, y: 1 }],
                           [{ x: 0, y: 0 }, { x: 7, y: 7 }], [{ role: "pass" }]]) {
        const result = movePreview.sourceVariation(position, config, actions)
        assert.equal(result.items.length, 0)
        assert.notEqual(result.reason, "")
        assert.deepEqual(plain(result.position.map), plain(position.map))
    }
})

test("Surakarta preview simulates loop capture and blocks reuse of the captured source", () => {
    const position = frozen({ map: previewMap([1, 2, 1], [2, 3, 2]), player: 1, source: null })
    const result = movePreview.sourceVariation(position, {
        dims: { x: 6, y: 6 }, ruleMode: registry.RULE_SURAKARTA, maxMoves: 0
    }, [{ x: 1, y: 2 }, { x: 2, y: 3 }, { x: 2, y: 3 }, { x: 3, y: 3 }])
    assert.equal(result.items.length, 1)
    assert.equal(result.position.map["1,2"], undefined)
    assert.equal(result.position.map["2,3"].player, 1)
    assert.equal(result.nextIndex, 2)
    assert.equal(result.reason, "source-required")
    assert.equal(position.map["2,3"].player, 2)
})

test("ordinary previews count passes and skip bad coordinates without consuming a move", () => {
    const actions = frozen([null, { x: 8, y: 8 }, { role: "pass" }, { x: 0, y: 0 }, { x: 1, y: 1 }])
    const items = movePreview.placementItems({ player: 1 }, {
        dims: { x: 5, y: 5 }, ruleMode: registry.RULE_GO, maxMoves: 2
    }, actions)
    assert.equal(items.length, 1)
    assert.deepEqual(plain(items[0]), { x: 0, y: 0, key: "0,0", player: 2, moveNumber: 2, nodeId: -1 })
    assert.equal(movePreview.moveLimit(NaN), 0)
    assert.equal(movePreview.moveLimit(-4), 0)
    assert.equal(movePreview.moveLimit(1.7), 2)
})

// Candidate cache lifecycle tests live in analysis_cache.test.js and
// qml_runtime/tst_analysis_session.qml, using immutable GameSession nodes.
