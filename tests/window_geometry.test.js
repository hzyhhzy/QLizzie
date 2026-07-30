"use strict"

const assert = require("node:assert/strict")
const path = require("node:path")
const test = require("node:test")
const { loadQmlJs } = require("./qmlJsLoader")

const geometry = loadQmlJs(
    path.join(__dirname, "..", "app", "qml", "WindowGeometry.js")
)

function screen(x, y, width, height) {
    return { availableGeometry: { x, y, width, height } }
}

test("centers a new window inside its owner's screen", () => {
    const owner = {
        x: 100,
        y: 50,
        width: 800,
        height: 600,
        screen: screen(0, 0, 1000, 700)
    }
    const windowObject = {
        x: 0,
        y: 0,
        width: 320,
        height: 200,
        minimumWidth: 520,
        minimumHeight: 320,
        screen: owner.screen
    }

    geometry.centerWindow(windowObject, owner, 760, 640)

    assert.deepEqual(
        [windowObject.x, windowObject.y, windowObject.width, windowObject.height],
        [120, 30, 760, 640]
    )
})

test("first opening prefers the owner's monitor over the hidden window default", () => {
    const ownerScreen = screen(1000, 0, 1200, 800)
    const owner = {
        x: 1100,
        y: 80,
        width: 900,
        height: 650,
        screen: ownerScreen
    }
    const windowObject = {
        x: 0,
        y: 0,
        width: 320,
        height: 200,
        minimumWidth: 520,
        minimumHeight: 320,
        screen: screen(0, 0, 1000, 700)
    }

    geometry.centerWindow(windowObject, owner, 760, 560)

    assert.deepEqual(
        [windowObject.x, windowObject.y, windowObject.width, windowObject.height],
        [1170, 125, 760, 560]
    )
})

test("clamps an old window rectangle into the current available screen", () => {
    const currentScreen = screen(0, 0, 1000, 700)
    const windowObject = {
        x: 1500,
        y: -200,
        width: 1200,
        height: 900,
        minimumWidth: 520,
        minimumHeight: 320,
        screen: currentScreen
    }

    geometry.clampWindow(windowObject, { screen: currentScreen })

    assert.deepEqual(
        [windowObject.x, windowObject.y, windowObject.width, windowObject.height],
        [0, 0, 1000, 700]
    )
})

test("preserves an on-screen user-adjusted rectangle", () => {
    const currentScreen = screen(-1200, 0, 1200, 900)
    const windowObject = {
        x: -1100,
        y: 80,
        width: 700,
        height: 500,
        minimumWidth: 520,
        minimumHeight: 320,
        screen: currentScreen
    }

    geometry.clampWindow(windowObject, { screen: currentScreen })

    assert.deepEqual(
        [windowObject.x, windowObject.y, windowObject.width, windowObject.height],
        [-1100, 80, 700, 500]
    )
})
