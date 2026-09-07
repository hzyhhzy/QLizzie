"use strict"

const assert = require("node:assert/strict")
const path = require("node:path")
const test = require("node:test")
const { loadQmlJs } = require("./qmlJsLoader")

const qmlPath = name => path.join(__dirname, "..", "app", "qml", name)
const schema = loadQmlJs(qmlPath("SettingsSchema.js"))
const store = loadQmlJs(qmlPath("SettingsStore.js"))
const registry = loadQmlJs(qmlPath("rules/RuleRegistry.js"))

// Explicit compatibility fixture captured from the existing settings.ini keys.
// Adding/removing a persistent preference requires reviewing this contract.
const LEGACY_KEYS = [
    "settingsVersion",
    "language",
    "firstLaunchCompleted",
    "showBeginnerTutorialOnNextLaunch",
    "boardSizeX",
    "boardSizeY",
    "gameRuleMode",
    "ruleVisibilityJson",
    "commonRuleOrderJson",
    "gomokuRuleMode",
    "gomokuRuleMaxMoves",
    "gomokuRuleVcn",
    "gomokuRuleFirstPassWin",
    "goScoringRule",
    "goKoRule",
    "goSuicideAllowed",
    "goTaxRule",
    "goWhiteHandicapBonus",
    "goButtonRule",
    "komi",
    "moveNumberDisplayMode",
    "coordinateDisplayMode",
    "boardPresentationMode",
    "gomokuBoardPresentationMode",
    "torusGoBoardPresentationMode",
    "hexBoardStyle",
    "hexBoardRotation",
    "packageMode",
    "ignoreGtpErrors",
    "engineCommunicationLogLimit",
    "engineCommunicationLogCharacterLimit",
    "engineCommunicationLineCharacterLimit",
    "enginePresetsJson",
    "defaultEngineId",
    "activeEngineId",
    "engineStartupMode",
    "engineCommand",
    "legacyHexEngineCoordinates",
    "analysisIntervalCentiseconds",
    "maxAnalysisSeconds",
    "analysisWideRootNoiseEnabled",
    "analysisWideRootNoise",
    "candidateDisplayCount",
    "candidateTableRowLimit",
    "candidateMinVisitRatio",
    "candidateShowFilteredMarkers",
    "candidateVariationPreviewVisible",
    "candidateVariationPreviewMaxMoves",
    "candidateVariationPreviewOpacity",
    "candidateWinrateLabelVisible",
    "candidateVisitsLabelVisible",
    "candidateScoreLabelVisible",
    "candidateWinrateFontSize",
    "candidateVisitsFontSize",
    "candidateScoreFontSize",
    "candidateWinrateBold",
    "candidateVisitsBold",
    "candidateScoreBold",
    "candidateWinrateOffsetY",
    "candidateVisitsOffsetY",
    "candidateScoreOffsetY",
    "candidateWinrateDecimals",
    "candidateScoreDecimals",
    "candidateWinrateShowPercent",
    "candidateScoreShowPercent",
    "candidateScoreTitleMode",
    "candidateRingVisible",
    "candidateRingLineWidth",
    "candidateRankLabelVisible",
    "candidateFirstLabelTextColor",
    "candidateLabelTextColor",
    "backgroundColor",
    "boardWoodColor",
    "stoneScale",
    "gridOpacity",
    "gridLineWidth",
    "selectedPointScale",
    "moveNumberLabelScale",
    "secondsPerMove",
    "analysisSecondsPerMove",
    "aiMoveMode",
    "hideAnalysisDuringPlay",
    "analysisTotalVisitsPerMove",
    "analysisFirstMoveVisitsPerMove",
    "resignMinMove",
    "resignConsecutiveMoves",
    "resignWinrateThreshold"
]

function plain(value) {
    return JSON.parse(JSON.stringify(value))
}

function freeze(value) {
    if (value && typeof value === "object") {
        for (const child of Object.values(value))
            freeze(child)
        Object.freeze(value)
    }
    return value
}

function sampleValues() {
    const values = {}
    schema.fields.forEach((entry, index) => {
        values[entry.property] = entry.type === "number" ? index + 0.25
            : entry.type === "boolean" ? index % 2 === 0
            : entry.type === "json-object" ? { "0": true, "14": false, nested: { value: index } }
            : entry.type === "json-array" ? [14, 9, 0]
            : entry.type === "engine-presets" ? '[{"id":"engine-a","command":"engine.exe gtp"}]'
            : `setting-${index}`
    })
    return values
}

function backend(initial = {}) {
    const values = Object.assign({}, initial)
    const reads = []
    const writes = []
    return { values, reads, writes,
        value(key, fallback) {
            reads.push({ key, fallback })
            return Object.hasOwn(values, key) ? values[key] : fallback
        },
        setValue(key, value) {
            writes.push({ key, value })
            values[key] = value
        }
    }
}

function application(overrides = {}) {
    return Object.assign(sampleValues(), {
        currentSettingsVersion: 3, loadedSettingsVersion: 3,
        language: "zh", firstLaunchCompleted: false, showBeginnerTutorialOnNextLaunch: true,
        boardSizeX: 19, boardSizeY: 19, gameRuleMode: 0,
        ruleVisibilityMap: { "0": true, "1": true, "2": true }, commonRuleOrder: [2, 0, 1],
        enginePresets: [], persistedEngineCommand: "saved-engine.exe gtp",
        gameRuleGo: registry.RULE_GO, gameRuleGomoku: registry.RULE_GOMOKU,
        gameRuleDotsAndBoxes: registry.RULE_DOTS_AND_BOXES,
        gameRuleTorusGo: registry.RULE_TORUS_GO, gameRuleTwoLibGo: registry.RULE_TWO_LIB_GO,
        gameRuleHexGoParallelogram: registry.RULE_HEX_GO_PARALLELOGRAM,
        gameRuleHexGoHexagon: registry.RULE_HEX_GO_HEXAGON, gameRuleHexGoTriangle: registry.RULE_HEX_GO_TRIANGLE,
        goScoringArea: 0, goScoringTerritory: 1, goKoSimple: 0, goKoPositional: 1, goKoSituational: 2,
        goTaxNone: 0, goTaxAll: 2,
        minBoardSize: 2, maxBoardSize: 99, defaultBoardSize: 19, maxLargeIntegerSetting: 2147483647,
        boardPresentationIntersections: 0, boardPresentationCells: 1,
        ownershipEnabled: true,
        clamp(value, low, high) { return Math.min(Math.max(value, low), high) },
        clampKomiValue(value) {
            const number = Number(value)
            return Number.isNaN(number) ? this.komi : this.clamp(number, -1000, 1000)
        },
        clampKomiSettingValue(value) { return this.clamp(Number(value), -1000, 1000) },
        clampAnalysisWideRootNoise(value) {
            const number = Number(value)
            return Number.isNaN(number) ? this.analysisWideRootNoise : this.clamp(number, 0, 2)
        },
        gameRuleOptions() { return Array.from(registry.RULES, rule => ({ value: rule.id })) },
        commonRuleOptionsForEngines() { return this.gameRuleOptions() },
        validRuleMode(mode) { return registry.validMode(mode) },
        adjustedBoardDimensionsForRule(mode, x, y) { return { x, y } },
        normalizedGomokuRuleMode(value) { return this.clamp(Number(value) || 0, 0, 5) },
        normalizedGomokuVcnRule(value) { return String(value || "NOVC") },
        trText(key) { return key }
    }, overrides)
}

test("one schema preserves every historical key and excludes transient ownership", () => {
    assert.deepEqual(Array.from(schema.fields, entry => entry.key), LEGACY_KEYS)
    assert.equal(new Set(schema.fields.map(entry => entry.key)).size, 87)
    assert.equal(new Set(schema.fields.map(entry => entry.property)).size, 87)
    const input = sampleValues()
    input.ownershipEnabled = true
    input.mouseHitRadiusScale = 0.7
    input.engineOwnership = [1]
    const snapshot = schema.snapshot(input)
    const saved = schema.write(snapshot)
    assert.equal(Object.hasOwn(snapshot, "ownershipEnabled"), false)
    assert.equal(Object.hasOwn(saved, "ownershipEnabled"), false)
    assert.equal(Object.hasOwn(saved, "engineOwnership"), false)
    assert.equal(Object.hasOwn(saved, "mouseHitRadiusScale"), false)
})

test("all 87 fields round-trip through the value schema without mutating inputs", () => {
    const values = freeze(sampleValues())
    const before = JSON.stringify(values)
    const raw = freeze(schema.write(values))
    const restored = schema.read(raw, values)
    assert.deepEqual(plain(restored), plain(values))
    assert.equal(JSON.stringify(values), before)
    assert.notEqual(restored.ruleVisibilityMap, values.ruleVisibilityMap)
    assert.notEqual(restored.commonRuleOrder, values.commonRuleOrder)
    const snapshot = schema.snapshot(values)
    snapshot.ruleVisibilityMap.nested.value = -1
    snapshot.commonRuleOrder.push(2)
    assert.notEqual(values.ruleVisibilityMap.nested.value, -1)
    assert.equal(values.commonRuleOrder.length, 3)
})

test("missing keys retain supplied startup defaults except historical JSON wire defaults", () => {
    const defaults = freeze(sampleValues())
    const decoded = schema.read({}, defaults)
    for (const entry of schema.fields) {
        if (entry.key === "ruleVisibilityJson")
            assert.deepEqual(plain(decoded[entry.property]), {})
        else if (entry.key === "commonRuleOrderJson")
            assert.deepEqual(plain(decoded[entry.property]), [])
        else if (entry.key === "enginePresetsJson")
            assert.equal(decoded[entry.property], "")
        else
            assert.equal(decoded[entry.property], defaults[entry.property], entry.key)
    }
})

test("legacy boolean coercion recognizes only true, one and yes without trimming", () => {
    for (const value of [true, "true", "TRUE", "TrUe", "1", 1, "yes", "YES"])
        assert.equal(schema.read({ ignoreGtpErrors: value }, sampleValues()).ignoreGtpErrors, true)
    for (const value of [false, "false", "0", 0, 2, "on", " true ", " yes", "", null, undefined])
        assert.equal(schema.read({ ignoreGtpErrors: value }, sampleValues()).ignoreGtpErrors, false)
})

test("malformed values retain number/string conversion and JSON fallback semantics", () => {
    const defaults = freeze(sampleValues())
    const decoded = schema.read({ boardSizeX: "invalid", boardSizeY: "", language: null,
        ruleVisibilityJson: "[]", commonRuleOrderJson: "{broken", enginePresetsJson: "{broken" }, defaults)
    assert.equal(Number.isNaN(decoded.boardSizeX), true)
    assert.equal(decoded.boardSizeY, 0)
    assert.equal(decoded.language, "null")
    assert.deepEqual(plain(decoded.ruleVisibilityMap), plain(defaults.ruleVisibilityMap))
    assert.deepEqual(plain(decoded.commonRuleOrder), plain(defaults.commonRuleOrder))
    assert.notEqual(decoded.commonRuleOrder, defaults.commonRuleOrder)
    assert.equal(decoded.enginePresets, "{broken")
})

test("load applies rule-dependent adapters in original order and migrates last", () => {
    const events = []
    const app = application({ loadedSettingsVersion: 0 })
    const observed = new Proxy(app, {
        set(target, key, value) { events.push({ key, value: plain(value) }); target[key] = value; return true }
    })
    app.clampKomiValue = function(value) {
        assert.equal(this.gameRuleMode, registry.RULE_ATAXX)
        return Number(value) + 1
    }
    const settings = backend({ settingsVersion: 2, gameRuleMode: registry.RULE_ATAXX, komi: "3.5",
        ruleVisibilityJson: '{"0":false,"9":true}', commonRuleOrderJson: "[9,0]",
        analysisWideRootNoise: "9" })
    store.loadPersistentSettings(observed, settings)
    assert.deepEqual(settings.reads.map(entry => entry.key), LEGACY_KEYS)
    assert.equal(app.komi, 4.5)
    assert.equal(app.analysisWideRootNoise, 2)
    assert.equal(app.loadedSettingsVersion, 3)
    assert.equal(app.ruleVisibilityMap["0"], true)
    assert.equal(app.ruleVisibilityMap["9"], false)
    // The old migration resets visibility only; order is normalized later by
    // normalizePersistentSettings, exactly as before this refactor.
    assert.equal(app.commonRuleOrder[0], 9)
    assert.equal(events.at(-1).key, "loadedSettingsVersion")
    assert.equal(events.at(-2).key, "ruleVisibilityMap")
})

test("current versions keep saved visibility and malformed versions preserve legacy comparison", () => {
    for (const settingsVersion of [3, "invalid"]) {
        const app = application()
        store.loadPersistentSettings(app, backend({ settingsVersion,
            ruleVisibilityJson: '{"0":false,"9":true}', commonRuleOrderJson: "[9,9,0,999]" }))
        assert.equal(app.ruleVisibilityMap["0"], false)
        assert.equal(app.ruleVisibilityMap["9"], true)
        assert.deepEqual(Array.from(app.commonRuleOrder), [9, 1, 2])
        assert.equal(app.loadedSettingsVersion, 3)
    }
})

test("engine preset JSON still passes through the real preset normalizer", () => {
    const app = application()
    store.loadPersistentSettings(app, backend({ settingsVersion: 3,
        enginePresetsJson: JSON.stringify([
            { id: "same", name: "Engine A", command: "a.exe gtp", initialCommands: "komi 6.5\nname",
              ruleMode: registry.RULE_SURAKARTA, boardSizeX: 6, boardSizeY: 6, komi: 0,
              preload: true, ownershipPerspective: "white" },
            { id: "same", name: "Engine B", command: "b.exe", ruleMode: registry.RULE_GO }
        ]), defaultEngineId: "same", activeEngineId: "same-2", engineStartupMode: "1",
        engineCommand: '"C:/Engine A/a.exe" gtp' }))
    assert.equal(app.enginePresets.length, 2)
    assert.equal(app.enginePresets[0].ruleMode, registry.RULE_SURAKARTA)
    assert.equal(app.enginePresets[0].initialCommands, "komi 6.5\nname")
    assert.equal(app.enginePresets[0].preload, undefined)
    assert.equal(app.enginePresets[0].ownershipPerspective, undefined)
    assert.equal(app.enginePresets[1].id, "same-2")
    assert.equal(app.defaultEngineId, "same")
    assert.equal(app.activeEngineId, "same-2")
    assert.equal(app.engineStartupMode, 1)
    assert.equal(app.persistedEngineCommand, '"C:/Engine A/a.exe" gtp')
    const saved = backend()
    store.savePersistentSettings(app, saved, null)
    assert.deepEqual(JSON.parse(saved.values.enginePresetsJson), plain(app.enginePresets))
})

test("invalid engine preset JSON clears the list instead of using prior presets", () => {
    for (const text of ["{broken", "{}", "null", ""]) {
        const app = application({ enginePresets: [{ id: "previous" }] })
        store.loadPersistentSettings(app, backend({ settingsVersion: 3, enginePresetsJson: text }))
        assert.equal(app.enginePresets.length, 0)
    }
})

test("save uses current schema version and the exact controller command when present", () => {
    const app = application({ loadedSettingsVersion: 1, currentSettingsVersion: 3 })
    const before = JSON.stringify(store.persistentSettingsSnapshot(app))
    for (const controller of [null, { command: "running.exe gtp" }, { command: "" }]) {
        const settings = backend()
        store.savePersistentSettings(app, settings, controller)
        assert.deepEqual(settings.writes.map(entry => entry.key), LEGACY_KEYS)
        assert.equal(settings.values.settingsVersion, 3)
        assert.equal(settings.values.engineCommand, controller ? controller.command : "saved-engine.exe gtp")
        assert.equal(Object.hasOwn(settings.values, "ownershipEnabled"), false)
        assert.equal(Object.hasOwn(settings.values, "persistedEngineCommand"), false)
    }
    assert.equal(JSON.stringify(store.persistentSettingsSnapshot(app)), before)
    assert.doesNotThrow(() => store.savePersistentSettings(null, null, null))
})

test("save normalizes JSON without changing live rule preferences or temporary toggles", () => {
    const visibility = freeze({ "0": true, "1": false, "2": true, "9": true })
    const order = freeze([9, 9, "2", 9999, 0])
    const app = application({ ruleVisibilityMap: visibility, commonRuleOrder: order, ownershipEnabled: true })
    const settings = backend()
    store.savePersistentSettings(app, settings, null)
    assert.deepEqual(JSON.parse(settings.values.commonRuleOrderJson), [9, 2, 0])
    assert.equal(JSON.parse(settings.values.ruleVisibilityJson)["1"], false)
    assert.equal(app.ruleVisibilityMap, visibility)
    assert.equal(app.commonRuleOrder, order)
    assert.equal(app.ownershipEnabled, true)
})
