import QtQuick
import "GameTree.js" as GameTree
import "GameRules.js" as GameRules

QtObject {
    id: session

    // Explicit rule inputs; the session never receives a window or app object.
    property int boardSizeX: 19
    property int boardSizeY: 19
    property int ruleMode: GameRules.RULE_GO
    property int stoneColorMode: 0
    property var forbiddenChecker: null

    property var _state: GameTree.create(configuration(), 0)
    readonly property var gameNodes: _state.gameNodes
    readonly property int currentNodeId: _state.currentNodeId
    readonly property int nextNodeId: _state.nextNodeId
    readonly property int gameTreeGeneration: _state.gameTreeGeneration
    readonly property var stones: _state.stones
    readonly property var stoneItems: _state.stoneItems
    readonly property int stoneCount: _state.stoneCount
    readonly property int currentPlayer: _state.currentPlayer
    readonly property int blackCaptures: _state.blackCaptures
    readonly property int whiteCaptures: _state.whiteCaptures
    readonly property string koLocKey: _state.ko.key
    readonly property int koLocX: _state.ko.x
    readonly property int koLocY: _state.ko.y
    readonly property string koLocKey2: _state.ko.key2
    readonly property int koLocX2: _state.ko.x2
    readonly property int koLocY2: _state.ko.y2
    readonly property var surakartaWinInfo: _state.surakartaWinInfo
    readonly property var legalPointMap: ({})
    property int boardRevision: 0
    property int legalityRevision: 0

    signal positionChanged(var result)
    signal treeChanged(var result)
    signal operationRejected(var result)

    function configuration() {
        return { "boardSizeX": boardSizeX, "boardSizeY": boardSizeY,
            "ruleMode": ruleMode, "stoneColorMode": stoneColorMode,
            "forbiddenChecker": forbiddenChecker }
    }

    function commit(result) {
        if (!result.ok) {
            operationRejected(result)
            return result
        }
        if (!result.changed)
            return result
        _state = result.state
        if (result.positionChanged) {
            boardRevision += 1
            legalityRevision += 1
        }
        if (result.treeChanged)
            treeChanged(result)
        if (result.positionChanged)
            positionChanged(result)
        return result
    }

    function reset() {
        return commit(GameTree.success(GameTree.create(configuration(), gameTreeGeneration + 1),
                                       "reset", true, false))
    }

    function placeStone(x, y) { return commit(GameTree.play(_state, x, y, configuration())) }
    function play(x, y) { return placeStone(x, y) }
    function playAction(action) { return commit(GameTree.move(_state, action, configuration())) }
    function passMove() { return commit(GameTree.pass(_state, configuration())) }
    function gotoNode(id) { return commit(GameTree.navigate(_state, id, configuration())) }
    function gotoFirstMove() { return gotoNode(0) }
    function gotoLastMove() { return gotoNode(GameTree.lastNodeId(_state, currentNodeId)) }
    function gotoRelativeMove(delta) { return gotoNode(GameTree.relativeNodeId(_state, delta)) }
    function undoMove() { return gotoRelativeMove(-1) }
    function gotoMoveNumber(value) {
        var id = GameTree.nodeIdAtMoveNumber(_state, value)
        return id >= 0 ? gotoNode(id) : GameTree.unchanged(_state, "navigate")
    }
    function rebuildPositionFromNode(id) { return commit(GameTree.replay(_state, id, configuration())) }
    function deleteCurrentNode() { return deleteSubtree(currentNodeId) }
    function deleteSubtree(id) { return commit(GameTree.remove(_state, id, configuration())) }
    function setCurrentVariationAsMainBranch() { return commit(GameTree.promote(_state, currentNodeId)) }
    function validateParsedGame(parsed) { return GameTree.validate(parsed, configuration()) }
    function loadTree(parsed, selectLast) {
        return commit(GameTree.load(_state, parsed, configuration(), selectLast))
    }
    function updateNodeAnalysis(id, values) { return commit(GameTree.updateNodeAnalysis(_state, id, values)) }

    function nodeById(id) { return GameTree.nodeById(_state, id) }
    function currentNode() { return nodeById(currentNodeId) }
    function rootNode() { return GameTree.rootNode() }
    function nodePath(id) { return GameTree.nodePath(_state, id) }
    function currentMoveNumberValue() { return GameTree.currentMoveNumber(_state) }
    function maxMoveNumberValue() { return GameTree.maxMoveNumber(_state) }
    function playerToMoveAfterNode(node) { return GameTree.playerToMoveAfterNode(node, configuration()) }
    function nextPlayerFromMode() { return playerToMoveAfterNode(currentNode()) }
    function currentMoveSourceNode() {
        var node = currentNode()
        return node && node.moveRole === "source" ? node : null
    }
    function currentMoveSourcePoint() { return GameTree.currentMoveSourcePoint(_state) }
    function currentKoLoc() { return _state.ko }
    function pointKeyIsKoBanned(key) { return GameRules.koLocMatches(_state.ko, key) }
    function mapStoneItems(map) { return GameTree.mapStoneItems(map) }
    function branchChildMatching(parent, key, player, isPass, moveRole) {
        return GameTree.branchChildMatching(_state, parent, key, player, isPass, moveRole)
    }
    function pointLegalInMap(map, x, y, player, ko) {
        return GameRules.pointLegalInMap(map, GameTree.dimensions(configuration()),
                                         x, y, player, ko, ruleMode, currentMoveSourcePoint())
    }
    function buildPointLegalityMap(map, player, ko) {
        return GameRules.buildPointLegalityMap(map, GameTree.dimensions(configuration()),
                                               player, ko, ruleMode, currentMoveSourcePoint())
    }
    function pointIsLegal(x, y) {
        legalityRevision
        return pointLegalInMap(stones, x, y, currentPlayer, currentKoLoc())
    }
    function rebuildPointLegality() { legalityRevision += 1 }
    function refreshPlayer() {
        var next = GameTree.copyObject(_state)
        next.currentPlayer = nextPlayerFromMode()
        return commit(GameTree.success(next, "player", false, false, currentNode()))
    }
}
