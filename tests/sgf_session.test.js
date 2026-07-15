"use strict"

const assert = require("node:assert/strict")
const path = require("node:path")
const test = require("node:test")
const { loadQmlJs } = require("./qmlJsLoader")

const sourcePath = path.join(__dirname, "..", "app", "qml", "SgfSession.js")
const registryPath = path.join(__dirname, "..", "app", "qml", "rules", "RuleRegistry.js")
const sgfUtilsPath = path.join(__dirname, "..", "app", "qml", "SgfUtils.js")
const registry = loadQmlJs(registryPath)
const sgfUtils = loadQmlJs(sgfUtilsPath, { imports: { RuleRegistry: registry } })
const session = loadQmlJs(sourcePath, {
    imports: {
        CandidateAnalysis: {},
        SgfUtils: {
            buildSgf() { return "(;GM[1])\n" }
        }
    }
})
const parsingSession = loadQmlJs(sourcePath, {
    imports: {
        CandidateAnalysis: {},
        SgfUtils: sgfUtils
    }
})

function appState() {
    return {
        gameNodes: [],
        gameRuleMode: 0,
        boardSizeX: 19,
        boardSizeY: 19,
        gameDirty: true,
        statusMode: "turn",
        statusMessage: "",
        gameRuleText() { return "Go" },
        trText(key) { return key }
    }
}

test("successful save commits clean state and returns true", () => {
    const app = appState()
    const fileIo = {
        lastError: "",
        writeTextFile(url, text) {
            assert.equal(url, "file:///game.sgf")
            assert.equal(text, "(;GM[1])\n")
            return true
        }
    }

    assert.equal(session.saveToFile(app, fileIo, "file:///game.sgf"), true)
    assert.equal(app.gameDirty, false)
    assert.equal(app.statusMessage, "sgfSaved: file:///game.sgf")
})

test("failed save preserves dirty state and returns false", () => {
    const app = appState()
    const fileIo = {
        lastError: "disk full",
        writeTextFile() { return false }
    }

    assert.equal(session.saveToFile(app, fileIo, "file:///game.sgf"), false)
    assert.equal(app.gameDirty, true)
    assert.equal(app.statusMessage, "sgfSaveFailed: disk full")
})

test("same-GM variants are detected as different rules", () => {
    const app = Object.assign(appState(), {
        minBoardSize: 1,
        maxBoardSize: 100,
        gameRuleMode: registry.RULE_GOMOKU,
        gameRuleGo: registry.RULE_GO,
        gameRuleGomoku: registry.RULE_GOMOKU,
        gameRuleHex: registry.RULE_HEX
    })
    const parsed = parsingSession.parse(
        app,
        "(;FF[4]GM[4]RU[QLizzie-Connect6]SZ[19];B[aa])"
    )

    assert.equal(parsed.ok, true, parsed.error)
    assert.equal(parsed.ruleMode, registry.RULE_CONNECT6)
    assert.notEqual(parsed.ruleMode, app.gameRuleMode)
})

test("loading activates the detected rule before rebuilding", () => {
    const events = []
    const root = {
        id: 0,
        parent: -1,
        children: [],
        analysisCandidates: []
    }
    const app = Object.assign(appState(), {
        minBoardSize: 1,
        maxBoardSize: 100,
        gameRuleMode: registry.RULE_GOMOKU,
        gameTreeGeneration: 0,
        analysisRevision: 0,
        ruleModeAllowedForPackage() { return true },
        boardDimensionsAllowedForPackage() { return true },
        boardDimensionsAllowedForRule() { return true },
        validateParsedGame() { return { ok: true } },
        activateRuleModeForSgf(mode) {
            events.push(`activate:${mode}`)
            this.gameRuleMode = mode
            return true
        },
        resetEngineSyncState() { events.push("reset-engine") },
        engineBoardSignature() { return "board" },
        engineKomiSignature() { return "komi" },
        clearHover() {},
        rebuildPositionFromNode() { events.push(`rebuild:${this.gameRuleMode}`) },
        rebuildTreeLayout() {},
        gotoLastMove() {},
        focusBoardInput() {}
    })
    const parsed = {
        ok: true,
        nodes: [root],
        nextNodeId: 1,
        ruleMode: registry.RULE_CONNECT6,
        ruleName: "QLizzie-Connect6",
        gameId: "4",
        boardSizeX: 19,
        boardSizeY: 19
    }

    parsingSession.applyParsed(app, parsed, "file:///connect6.sgf")

    assert.equal(app.gameRuleMode, registry.RULE_CONNECT6)
    assert.deepEqual(events, ["activate:5", "reset-engine", "rebuild:5"])
    assert.equal(app.gameDirty, false)
})

test("invalid trees are rejected before rule activation", () => {
    let activated = false
    const app = Object.assign(appState(), {
        gameRuleMode: registry.RULE_GOMOKU,
        ruleModeAllowedForPackage() { return true },
        boardDimensionsAllowedForPackage() { return true },
        boardDimensionsAllowedForRule() { return true },
        validateParsedGame() { return { ok: false, nodeId: 2, reason: "invalid-target" } },
        activateRuleModeForSgf() { activated = true; return true },
        focusBoardInput() {}
    })
    const parsed = {
        ruleMode: registry.RULE_CONNECT6,
        ruleName: "QLizzie-Connect6",
        gameId: "4",
        boardSizeX: 19,
        boardSizeY: 19
    }

    parsingSession.applyParsed(app, parsed, "file:///broken.sgf")

    assert.equal(activated, false)
    assert.equal(app.gameRuleMode, registry.RULE_GOMOKU)
    assert.match(app.statusMessage, /#2: invalid-target/)
})
