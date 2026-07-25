"use strict"

const assert = require("node:assert/strict")
const path = require("node:path")
const test = require("node:test")
const { loadQmlJs } = require("./qmlJsLoader")

const candidatePath = path.join(__dirname, "..", "app", "qml", "CandidateAnalysis.js")
const analysisStatusPath = path.join(__dirname, "..", "app", "qml", "AnalysisStatus.js")
const candidateAnalysis = loadQmlJs(candidatePath, {
    imports: {
        GameRules: {}
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
