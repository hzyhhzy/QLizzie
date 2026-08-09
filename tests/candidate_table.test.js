"use strict"

const assert = require("node:assert/strict")
const path = require("node:path")
const test = require("node:test")
const { loadQmlJs } = require("./qmlJsLoader")

const qmlDirectory = path.join(__dirname, "..", "app", "qml")
const candidateAnalysis = loadQmlJs(
    path.join(qmlDirectory, "CandidateAnalysis.js"),
    { imports: { GameRules: {} } }
)
const candidateTable = loadQmlJs(
    path.join(qmlDirectory, "CandidateTable.js"),
    { imports: { CandidateAnalysis: candidateAnalysis } }
)

function createApp() {
    return {
        parseEngineCoordinate(move) {
            const points = {
                D4: { x: 3, y: 3 },
                Q16: { x: 15, y: 15 },
                C3: { x: 2, y: 2 }
            }
            return points[String(move).toUpperCase()] || null
        },
        coordinateText(x, y) {
            return `${String.fromCharCode(65 + x)}${y + 1}`
        },
        trText(key) {
            return key
        }
    }
}

const candidates = [
    {
        move: "D4",
        order: 0,
        visits: 100,
        lcb: 0.51,
        winrate: 0.55,
        prior: 0.125,
        scoreMean: 1.75,
        scoreStdev: 0.42
    },
    {
        move: "Q16",
        order: 1,
        visits: 50,
        lcb: 0.49,
        winrate: 0.52,
        prior: 0.25,
        scoreMean: -0.25,
        scoreStdev: 0.81
    },
    {
        move: "C3",
        order: 2,
        visits: 0,
        winrate: 0.50
    }
]

test("candidate table exposes every LizzieYZY candidate metric", () => {
    const table = candidateTable.buildTable(createApp(), candidates, 0, true)

    assert.equal(table.rows.length, 3)
    assert.equal(table.rows[0].indexText, "1")
    assert.equal(table.rows[0].coordinateText, "D4")
    assert.equal(table.rows[0].lcbText, "51.0")
    assert.equal(table.rows[0].winrateText, "55.0")
    assert.equal(table.rows[0].visitsText, "100")
    assert.equal(table.rows[0].shareText, "66.7")
    assert.equal(table.rows[0].policyText, "12.50")
    assert.equal(table.rows[0].scoreMeanText, "1.8")
    assert.equal(table.rows[0].scoreStdevText, "0.4")
    assert.equal(table.rows[2].lcbText, "--")
    assert.equal(table.rows[2].policyText, "--")
    assert.equal(table.totalVisits, 150)
    assert.equal(table.maxVisits, 100)
    assert.ok(Number.isFinite(table.concentration))
})

test("candidate table sorts numeric columns and leaves missing values last", () => {
    const descendingPolicy = candidateTable.buildTable(
        createApp(), candidates, 6, false
    )
    assert.deepEqual(
        Array.from(descendingPolicy.rows, row => row.coordinateText),
        ["P16", "D4", "C3"]
    )

    const ascendingScore = candidateTable.buildTable(
        createApp(), candidates, 7, true
    )
    assert.deepEqual(
        Array.from(ascendingScore.rows, row => row.coordinateText),
        ["P16", "D4", "C3"]
    )
    assert.deepEqual(
        Array.from(ascendingScore.rows, row => row.displayIndex),
        [2, 1, 3]
    )
})
