import QtQuick
import QtTest
import "../../app/qml" as Models

TestCase {
    id: testCase
    name: "AnalysisSession"
    property int coordinateParseCalls: 0
    property string boardSignature: "2x2-go"
    property bool swapCoordinates: false

    function parseCoordinate(text) {
        coordinateParseCalls += 1
        if (text !== "A1" && text !== "B2")
            return null
        var index = text === "A1" ? 0 : 1
        return { "x": swapCoordinates ? 1 - index : index, "y": index }
    }

    Models.GameSession {
        id: game
        boardSizeX: 2
        boardSizeY: 2
    }

    Models.AnalysisSession {
        id: analysis
        boardSizeX: 2
        boardSizeY: 2
        ownershipEnabled: true
        ownershipSupported: true
        position: ({ "nodeId": game.currentNodeId, "generation": game.gameTreeGeneration,
                     "player": game.currentPlayer, "boardSignature": testCase.boardSignature,
                     "komiSignature": "7.5", "engineSignature": "test-engine" })
        currentNode: game.currentNode()
        nodeResolver: function(id) { return game.nodeById(id) }
        nodeAnalysisWriter: function(id, values) { return game.updateNodeAnalysis(id, values) }
        coordinateParser: testCase.parseCoordinate
        coordinateFormatter: function(x, y) { return x === 0 ? "A1" : "B2" }
        presentationSettings: ({
            "displayCount": 10, "minVisitRatio": 0, "showFilteredMarkers": true,
            "tableRowLimit": 20, "labelColor": "#000000",
            "winrate": { "visible": true, "decimals": 1, "percent": false, "fontSize": 57, "bold": true },
            "visits": { "visible": false, "fontSize": 42, "bold": false },
            "score": { "visible": false, "decimals": 1, "percent": false, "fontSize": 36, "bold": true },
            "marker": { "alphaFactor": 5, "colorRatio": 2, "minAlpha": 32, "maxAlpha": 240 }
        })
    }

    SignalSpy { id: boardSpy; target: game; signalName: "positionChanged" }
    SignalSpy { id: treeSpy; target: game; signalName: "treeChanged" }
    SignalSpy { id: displaySpy; target: analysis; signalName: "candidatesChangedForDisplay" }
    SignalSpy { id: acceptedSpy; target: analysis; signalName: "liveCandidatesAccepted" }

    function init() {
        game.reset()
        analysis.resetCandidates()
        analysis.resetOwnership()
        analysis.boardSizeX = 2
        analysis.boardSizeY = 2
        boardSignature = "2x2-go"
        swapCoordinates = false
        analysis.coordinateParser = testCase.parseCoordinate
        analysis.coordinateFormatter = function(x, y) { return x === 0 ? "A1" : "B2" }
        coordinateParseCalls = 0
        boardSpy.clear()
        treeSpy.clear()
        displaySpy.clear()
        acceptedSpy.clear()
    }

    function test_candidates_commit_one_annotation_without_changing_board() {
        var oldNode = game.currentNode()
        var candidates = [{ "move": "A1", "visits": 50, "winrate": 0.6, "pv": ["A1", "B2"] }]
        verify(analysis.applyCandidateUpdate(candidates, 9, analysis.position, true))
        compare(analysis.engineCandidates[0].visits, 50)
        compare(analysis.engineCandidateRevision, 9)
        compare(analysis.engineCandidateItems[0].winrateText, "60.0")
        compare(analysis.engineCandidateTableItems[0].coordinate, "A1")
        compare(game.currentNode().analysisBlackWinrate, 60)
        compare(game.currentNode().analysisCandidates[0].visits, 50)
        compare(oldNode.analysisCandidates.length, 0)
        compare(treeSpy.count, 1)
        compare(boardSpy.count, 0)
        compare(displaySpy.count, 1)
        compare(acceptedSpy.count, 1)
        candidates[0].visits = 1
        candidates[0].pv.push("pass")
        compare(game.currentNode().analysisCandidates[0].visits, 50)
        compare(game.currentNode().analysisCandidates[0].pv.length, 2)
    }

    function test_pause_restores_cached_candidates() {
        verify(analysis.applyCandidateUpdate([{ "move": "A1", "visits": 50 }], 1, analysis.position, true))
        acceptedSpy.clear()
        verify(!analysis.applyCandidateUpdate([], 2, null, false))
        verify(analysis.engineCandidatesFromCache)
        compare(analysis.engineCandidateItems.length, 1)
        compare(analysis.engineCandidates[0].visits, 50)
        compare(acceptedSpy.count, 0)
    }

    function test_repeated_candidates_reuse_coordinates_but_refresh_labels_and_visits() {
        analysis.setCandidates([{ "move": "A1", "visits": 50 }, { "move": "B2", "visits": 20 }])
        compare(coordinateParseCalls, 2)
        analysis.setCandidates([{ "move": "B2", "visits": 200 }, { "move": "A1", "visits": 100 }])
        compare(coordinateParseCalls, 2)
        compare(analysis.engineCandidateItems[0].key, "1,1")
        compare(analysis.engineCandidateItems[0].visits, 200)
        analysis.coordinateFormatter = function(x, y) { return (x + 1) + ":" + (y + 1) }
        compare(analysis.engineCandidateTableItems[0].coordinate, "2:2")
        compare(coordinateParseCalls, 2)
    }

    function test_coordinate_cache_expires_when_board_or_parser_changes() {
        var candidates = [{ "move": "A1", "visits": 50 }]
        analysis.setCandidates(candidates)
        compare(analysis.engineCandidateItems[0].key, "0,0")
        analysis.boardSizeX = 3
        analysis.setCandidates(candidates)
        compare(coordinateParseCalls, 2)
        swapCoordinates = true
        boardSignature = "2x2-legacy-hex"
        analysis.setCandidates(candidates)
        compare(coordinateParseCalls, 3)
        compare(analysis.engineCandidateItems[0].key, "1,0")
        analysis.coordinateParser = function(text) { return { "x": 0, "y": 1 } }
        compare(analysis.engineCandidateItems[0].key, "0,1")
        analysis.coordinateParser = testCase.parseCoordinate
        var calls = coordinateParseCalls
        analysis.resetCandidates()
        analysis.setCandidates(candidates)
        compare(coordinateParseCalls, calls + 1)
    }

    function test_late_previous_game_packet_never_annotates_reused_node() {
        var request = analysis.position
        game.reset()
        treeSpy.clear()
        verify(!analysis.applyCandidateUpdate([{ "move": "A1", "visits": 50 }], 1, request, true))
        compare(game.currentNode().analysisCandidates.length, 0)
        compare(analysis.engineCandidates.length, 0)
        compare(treeSpy.count, 0)
    }

    function test_ownership_commits_annotation_and_preserves_board_revision() {
        var revision = game.boardRevision
        var before = game.currentNode()
        verify(analysis.applyOwnershipUpdate([0.8, -0.8, 0.2, -0.2], analysis.position, true))
        compare(game.currentNode().analysisOwnership.length, 4)
        compare(before.analysisOwnership.length, 0)
        verify(analysis.ownershipVisible())
        compare(game.boardRevision, revision)
        compare(boardSpy.count, 0)
        verify(!analysis.applyOwnershipUpdate([], analysis.position, true))
        verify(analysis.engineOwnershipFromCache)
        verify(analysis.ownershipVisible())
        analysis.resetOwnership()
        verify(!analysis.ownershipVisible())
    }
}
