import QtQuick
import QtTest
import "../../app/qml" as Models
import "../../app/qml/GameRules.js" as GameRules

TestCase {
    id: testCase
    name: "GameSession"

    Models.GameSession {
        id: session
        boardSizeX: 7
        boardSizeY: 7
    }

    SignalSpy { id: positionSpy; target: session; signalName: "positionChanged" }
    SignalSpy { id: treeSpy; target: session; signalName: "treeChanged" }
    SignalSpy { id: rejectedSpy; target: session; signalName: "operationRejected" }

    function init() {
        session.ruleMode = GameRules.RULE_GO
        session.stoneColorMode = 0
        session.reset()
        positionSpy.clear()
        treeSpy.clear()
        rejectedSpy.clear()
    }

    function test_move_navigation_and_rejection_are_atomic() {
        var initialRevision = session.boardRevision
        verify(session.placeStone(1, 1).ok)
        compare(session.currentNodeId, 1)
        compare(session.currentPlayer, 2)
        compare(session.stoneCount, 1)
        compare(positionSpy.count, 1)
        compare(treeSpy.count, 1)
        verify(!session.placeStone(1, 1).ok)
        compare(rejectedSpy.count, 1)
        compare(positionSpy.count, 1)
        compare(session.boardRevision, initialRevision + 1)
        verify(session.gotoFirstMove().ok)
        compare(session.stoneCount, 0)
        compare(session.currentPlayer, 1)
        verify(session.placeStone(1, 1).reused)
        compare(session.nextNodeId, 2)

        var treeChanges = treeSpy.count
        session.stoneColorMode = 1
        session.refreshPlayer()
        compare(session.currentPlayer, 1)
        compare(session.currentNodeId, 1)
        compare(session.stoneCount, 1)
        compare(treeSpy.count, treeChanges)
    }

    function test_source_target_and_delete() {
        session.ruleMode = GameRules.RULE_ATAXX
        session.reset()
        compare(session.stoneCount, 4)
        verify(session.placeStone(0, 0).ok)
        compare(session.currentMoveSourceNode().id, 1)
        compare(session.currentPlayer, 1)
        compare(session.currentMoveNumberValue(), 0)
        verify(session.pointIsLegal(2, 2))
        verify(session.placeStone(2, 2).ok)
        compare(session.stoneCount, 4)
        compare(session.currentMoveNumberValue(), 1)
        compare(session.currentPlayer, 2)
        verify(session.deleteCurrentNode().ok)
        compare(session.currentNodeId, 1)
        compare(session.stoneCount, 4)
        compare(session.currentPlayer, 1)
    }

    function test_annotations_do_not_emit_position_changes() {
        session.placeStone(2, 2)
        positionSpy.clear()
        treeSpy.clear()
        var revision = session.boardRevision
        verify(session.updateNodeAnalysis(1, { "analysisBlackWinrate": 0.65 }).ok)
        compare(session.currentNode().analysisBlackWinrate, 0.65)
        compare(positionSpy.count, 0)
        compare(treeSpy.count, 1)
        compare(session.boardRevision, revision)
        verify(!session.updateNodeAnalysis(1, { "parent": 99 }).ok)
        compare(session.currentNode().parent, 0)
    }

    function test_failed_load_preserves_state_and_emits_only_rejection() {
        session.placeStone(2, 2)
        var nodes = JSON.parse(JSON.stringify(session.gameNodes))
        nodes[0].children = [100]
        positionSpy.clear()
        treeSpy.clear()
        var generation = session.gameTreeGeneration
        var revision = session.boardRevision
        verify(!session.loadTree({ "nodes": nodes, "boardSizeX": 7, "boardSizeY": 7 }).ok)
        compare(session.currentNodeId, 1)
        compare(session.stoneCount, 1)
        compare(session.gameTreeGeneration, generation)
        compare(session.boardRevision, revision)
        compare(positionSpy.count, 0)
        compare(treeSpy.count, 0)
        compare(rejectedSpy.count, 1)
    }
}
