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
