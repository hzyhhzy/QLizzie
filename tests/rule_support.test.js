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
