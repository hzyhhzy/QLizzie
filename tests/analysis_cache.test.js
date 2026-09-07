"use strict"

const assert = require("node:assert/strict")
const path = require("node:path")
const test = require("node:test")
const { loadQmlJs } = require("./qmlJsLoader")

const qmlPath = name => path.join(__dirname, "..", "app", "qml", name)
const candidateModel = loadQmlJs(qmlPath("CandidateModel.js"))
const ownership = loadQmlJs(qmlPath("Ownership.js"))
const cache = loadQmlJs(qmlPath("AnalysisCache.js"), {
    imports: { CandidateModel: candidateModel, Ownership: ownership }
})

function position(overrides = {}) {
    return Object.assign({ nodeId: 3, generation: 2, player: 2, boardSignature: "2x2-go",
        komiSignature: "7.5", engineSignature: "katago:a" }, overrides)
}

function currentNode(identity = position()) {
    return { id: identity.nodeId, analysisCandidates: [{ move: "A1", visits: 20, winrate: 0.6 }],
        analysisCandidateBoardSignature: identity.boardSignature,
        analysisCandidateKomiSignature: identity.komiSignature,
        analysisCandidateEngineSignature: identity.engineSignature,
        analysisBlackWinrate: 40,
        analysisOwnership: [1, -1, 0.5, -0.5],
        analysisOwnershipBoardSignature: identity.boardSignature,
        analysisOwnershipKomiSignature: identity.komiSignature,
        analysisOwnershipEngineSignature: identity.engineSignature }
}

function deepFreeze(value) {
    if (value && typeof value === "object") {
        for (const child of Object.values(value))
            deepFreeze(child)
        Object.freeze(value)
    }
    return value
}

const ownershipConfig = deepFreeze({ width: 2, height: 2, ownershipEnabled: true, ownershipSupported: true })

test("candidate updates return a detached snapshot and one combined annotation patch", () => {
    const node = deepFreeze(currentNode())
    const candidates = [{ move: "B2", visits: 100, winrate: 0.7, pv: ["B2", "A1"] }]
    const before = JSON.stringify(node)
    const update = cache.candidateUpdate(position(), node, node, position(), candidates, true)
    assert.equal(update.accepted, true)
    assert.equal(update.fromCache, false)
    assert.equal(update.annotationNodeId, 3)
    assert.equal(update.annotations.analysisBlackWinrate, 30)
    assert.equal(update.values, update.annotations.analysisCandidates)
    candidates[0].visits = 1
    candidates[0].pv.push("pass")
    assert.equal(update.values[0].visits, 100)
    assert.equal(update.values[0].pv.length, 2)
    assert.equal(JSON.stringify(node), before)
})

test("paused or empty updates keep the persisted current-node candidates", () => {
    const node = deepFreeze(currentNode())
    for (const [active, candidates] of [[false, []], [false, [{ move: "B2" }]], [true, []]]) {
        const update = cache.candidateUpdate(position(), node, node, position(), candidates, active)
        assert.equal(update.values, node.analysisCandidates)
        assert.equal(update.fromCache, true)
        assert.equal(update.annotations, null)
        assert.equal(update.accepted, false)
    }
})

test("previous-generation packets cannot annotate a reused node id", () => {
    const node = deepFreeze(currentNode())
    const stale = position({ generation: 1 })
    const candidates = cache.candidateUpdate(position(), node, node, stale, [{ move: "B2" }], true)
    const territory = cache.ownershipUpdate(position(), node, node, stale, [0, 0, 0, 0], true, ownershipConfig)
    assert.equal(candidates.annotations, null)
    assert.equal(territory.annotations, null)
    assert.equal(candidates.values, node.analysisCandidates)
    assert.equal(territory.values, node.analysisOwnership)
})

test("off-screen results annotate their original node and retain the current display", () => {
    const node = deepFreeze(currentNode())
    const target = deepFreeze({ id: 4 })
    const request = position({ nodeId: 4, player: 1 })
    const update = cache.candidateUpdate(position(), node, target, request,
        [{ move: "B2", visits: 50, winrate: 0.8 }], true)
    assert.equal(update.annotationNodeId, 4)
    assert.equal(update.annotations.analysisBlackWinrate, 80)
    assert.equal(update.values, node.analysisCandidates)
    assert.equal(update.accepted, false)
    assert.equal(target.analysisCandidates, undefined)
})

test("candidate history matches board and komi and remains visible across engine changes", () => {
    const node = currentNode()
    for (const change of [{ komiSignature: "6.5" }, { boardSignature: "9x9-go" }])
        assert.equal(cache.candidateUsable(node, position(change)), false)
    assert.equal(cache.candidateUsable(node, position({ engineSignature: "katago:b" })), true)
    delete node.analysisCandidateEngineSignature
    assert.equal(cache.candidateUsable(node, position({ engineSignature: "katago:b" })), true)
})

test("ownership uses request-player perspective and a detached array", () => {
    const node = deepFreeze(currentNode())
    const raw = [2, -2, 0.25, 0]
    const update = cache.ownershipUpdate(position(), node, node, position(), raw, true, ownershipConfig)
    assert.equal(update.accepted, true)
    assert.deepEqual(Array.from(update.values), [-1, 1, -0.25, -0])
    assert.equal(update.annotations.analysisOwnership, update.values)
    raw[0] = 0
    assert.equal(update.values[0], -1)
    assert.equal(node.analysisOwnership[0], 1)
})

test("malformed ownership falls back to cache and disabled ownership resets", () => {
    const node = deepFreeze(currentNode())
    for (const values of [[], [1, 2], [1, 0, Infinity, 0]]) {
        const update = cache.ownershipUpdate(position(), node, node, position(), values, true, ownershipConfig)
        assert.equal(update.values, node.analysisOwnership)
        assert.equal(update.annotations, null)
    }
    for (const config of [Object.assign({}, ownershipConfig, { ownershipEnabled: false }),
                          Object.assign({}, ownershipConfig, { ownershipSupported: false })]) {
        const update = cache.ownershipUpdate(position(), node, node, position(), [0, 0, 0, 0], true, config)
        assert.equal(update.values.length, 0)
        assert.equal(update.annotations, null)
    }
    assert.equal(cache.ownershipUpdate(position(), node, node, position(), [0, 0, 0, 0], false,
        ownershipConfig).values.length, 0)
})

test("ownership engine changes cannot display another engine's map", () => {
    const node = deepFreeze(currentNode())
    const next = position({ engineSignature: "katago:b" })
    assert.equal(cache.ownershipUsable(node, next, ownershipConfig), false)
    const update = cache.ownershipUpdate(next, node, node, position(), [0, 0, 0, 0], true, ownershipConfig)
    assert.equal(update.accepted, false)
    assert.equal(update.values.length, 0)
    assert.equal(update.annotations, null)
    const candidates = cache.candidateUpdate(next, node, node, position(), [{ move: "B2" }], true)
    assert.equal(candidates.annotations, null)
    assert.equal(candidates.accepted, false)
    assert.equal(candidates.fromCache, true)
    assert.equal(candidates.values, node.analysisCandidates)
})

test("unchanged winrate avoids an extra annotation revision", () => {
    const node = deepFreeze(currentNode())
    const annotations = cache.winrateAnnotations(node, [{ winrate: 0.600000001 }], 2)
    assert.equal(Object.keys(annotations).length, 0)
})

test("missing candidates and non-finite winrates cannot write invalid graph annotations", () => {
    const node = deepFreeze(currentNode())
    for (const candidates of [null, [], [null], [{}], [{ winrate: NaN }], [{ winrate: Infinity }]])
        assert.equal(Object.keys(cache.winrateAnnotations(node, candidates, 1)).length, 0)
    assert.equal(cache.candidateAnnotations(node, [null], position()).analysisCandidates.length, 1)
})
