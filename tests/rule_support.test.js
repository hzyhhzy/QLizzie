"use strict"

const assert = require("node:assert/strict")
const path = require("node:path")
const test = require("node:test")
const { loadQmlJs } = require("./qmlJsLoader")

const registryPath = path.join(__dirname, "..", "app", "qml", "rules", "RuleRegistry.js")
const supportPath = path.join(__dirname, "..", "app", "qml", "RuleSupport.js")
const registry = loadQmlJs(registryPath)
const support = loadQmlJs(supportPath, {
    imports: {
        RuleRegistry: registry,
        RuleCatalog: {}
    }
})

const app = {
    trText(key) { return key },
    gameRuleMoreOption: -1000000
}

test("saved settings and live menus normalize the same visible rule order", () => {
    const settings = loadQmlJs(path.join(__dirname, "..", "app", "qml", "SettingsStore.js"))
    const state = Object.assign({}, app, {
        ruleVisibilityMap: Object.freeze({ "0": true, "1": false, "2": true, "9": true }),
        commonRuleOrder: Object.freeze([9, "2", 9, 9999, 1]),
        gameRuleOptions() { return support.gameRuleOptions(this) }
    })
    assert.deepEqual(Array.from(support.normalizedCommonRuleOrder(state, state.commonRuleOrder)), [9, 2, 0])
    assert.deepEqual(
        Array.from(settings.normalizeCommonRuleOrder(state, state.commonRuleOrder)),
        Array.from(support.normalizedCommonRuleOrder(state, state.commonRuleOrder))
    )
    assert.deepEqual(JSON.parse(JSON.stringify(settings.normalizeRuleVisibilityMap(state, state.ruleVisibilityMap))),
                     JSON.parse(JSON.stringify(support.normalizedRuleVisibilityMap(state, state.ruleVisibilityMap))))
})

test("visibility and reordering replace snapshots and preserve unrelated choices", () => {
    let saves = 0
    const state = Object.assign({}, app, {
        ruleVisibilityMap: Object.freeze({ "0": true, "1": true, "2": false, "9": false }),
        commonRuleOrder: Object.freeze([1, 0]),
        persistentSettingsLoaded: true,
        savePersistentSettings() { ++saves }
    })
    support.setRuleModesVisible(state, [2, 9], true)
    assert.deepEqual(Array.from(state.commonRuleOrder), [1, 0, 2, 9])
    support.moveCommonRule(state, 9, -2)
    assert.deepEqual(Array.from(state.commonRuleOrder), [1, 9, 0, 2])
    support.setRuleModeVisible(state, 0, false)
    assert.deepEqual(Array.from(state.commonRuleOrder), [1, 9, 2])
    assert.equal(saves, 3)
})

test("rule menu is built once from every registry entry", () => {
    const options = support.gameRuleOptions(app)
    const modes = options.map(option => option.value)

    assert.equal(options.length, registry.allModes().length)
    assert.deepEqual([...modes].sort((a, b) => a - b), Array.from(registry.allModes()))
    assert.equal(new Set(modes).size, modes.length)
})

test("rule lookup returns the registry-backed menu option", () => {
    const ataxx = support.ruleOptionForMode(app, registry.RULE_ATAXX)

    assert.equal(ataxx.value, registry.RULE_ATAXX)
    assert.equal(ataxx.label, "gameRuleAtaxx")
    assert.equal(ataxx.tip, "gameRuleAtaxxTip")
    assert.equal(support.ruleOptionForMode(app, 9999), null)
})

test("capability helpers delegate to the registry", () => {
    assert.equal(support.ruleUsesMoveSource(app, registry.RULE_ATAXX), true)
    assert.equal(support.ruleUsesMoveSource(app, registry.RULE_GO), false)
    assert.equal(support.ruleUsesGoCapture(app, registry.RULE_TWO_LIB_GO), true)
    assert.equal(support.ruleUsesDotsAndBoxes(app, registry.RULE_DOTS_AND_BOXES), true)
    assert.equal(support.ruleUsesMoveSource(app, registry.RULE_SURAKARTA), true)
})

test("Surakarta always normalizes to its fixed 6x6 board", () => {
    const dimensionsApp = {
        minBoardSize: 2,
        maxBoardSize: 52,
        packageMode: 0,
        packageModeUniversal: 0,
        gameRuleSurakarta: registry.RULE_SURAKARTA,
        clamp(value, low, high) { return Math.min(Math.max(value, low), high) }
    }
    assert.deepEqual(
        JSON.parse(JSON.stringify(support.adjustedBoardDimensionsForRule(
            dimensionsApp, registry.RULE_SURAKARTA, 19, 13
        ))),
        { x: 6, y: 6 }
    )
    assert.equal(support.boardDimensionsAllowedForRule(
        dimensionsApp, registry.RULE_SURAKARTA, 6, 6
    ), true)
    assert.equal(support.boardDimensionsAllowedForRule(
        dimensionsApp, registry.RULE_SURAKARTA, 7, 6
    ), false)
    dimensionsApp.gameRuleMode = registry.RULE_SURAKARTA
    assert.equal(support.customBoardSizeAllowed(dimensionsApp), false)
})

test("opening a replacement record keeps the current game dirty until load succeeds", () => {
    let opened = false
    const pendingApp = {
        pendingClearAction: "openSgf",
        pendingRuleMode: -1,
        pendingBoardSizeX: -1,
        pendingBoardSizeY: -1,
        gameDirty: true,
        focusBoardInput() {}
    }

    support.applyPendingClearAction(pendingApp, {
        open() { opened = true }
    })

    assert.equal(opened, true)
    assert.equal(pendingApp.pendingClearAction, "")
    assert.equal(pendingApp.gameDirty, true)
})
