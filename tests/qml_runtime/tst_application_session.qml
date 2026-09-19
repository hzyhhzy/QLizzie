import QtQuick
import QtQuick.Window
import QtTest
import "../../app/qml" as App

TestCase {
    id: harness
    name: "ApplicationSession"
    property var application: null

    // These context objects exercise the real application and its components
    // without accessing user settings, the filesystem or an engine process.
    QtObject {
        id: appSettings
        property var values: ({})
        function value(key, fallback) {
            var defaults = {
                "settingsVersion": 3,
                "firstLaunchCompleted": true,
                "showBeginnerTutorialOnNextLaunch": false,
                "engineStartupMode": 3,
                "boardSizeX": 9,
                "boardSizeY": 9
            }
            if (values[key] !== undefined)
                return values[key]
            return defaults[key] === undefined ? fallback : defaults[key]
        }
        function setValue(key, value) { values[key] = value }
        function sync() {}
    }

    QtObject {
        id: fileIo
        property string lastError: ""
        property string savedText: ""
        function writeTextFile(url, text) { savedText = text; return true }
        function readTextFile(url) { return savedText }
    }

    QtObject {
        id: gomokuForbidden
        function isForbiddenMove(items, width, height, x, y) { return false }
        function forbiddenPoints(items, width, height) { return [] }
    }

    QtObject {
        id: engineController
        property string command: "mock-engine"
        property bool running: false
        property bool ready: false
        property bool failed: false
        property bool ignoreGtpErrors: false
        property string failureKind: ""
        property var candidates: []
        readonly property int candidateCount: candidates.length
        property int candidateRevision: 0
        property var ownership: []
        property var requests: []
        property var commands: []

        signal engineInput(string line)
        signal engineOutput(string line)
        signal engineErrorOutput(string line)
        signal gtpErrorResponse(string line)
        signal analysisCommandFailed(int analysisRequestId, string line)
        signal engineSynchronizationCompleted(int syncRequestId)
        signal moveGenerated(int requestId, string move, bool ok, string rawLine)

        function canUseIncrementalSync() { return true }
        function clearCandidates() { candidates = []; ownership = [] }
        function sendCommand(text) { commands = commands.concat([text]) }
        function ensureStarted() { running = true; ready = true }
        function stop() { ready = false; running = false }
        function restart() { stop(); ensureStarted() }
        function requestMove(syncCommands, timeCommand, moveCommand, requestId, syncRequestId) {
            requests = requests.concat([{ "kind": "move", "requestId": requestId,
                "syncRequestId": syncRequestId, "syncCommands": syncCommands,
                "command": moveCommand }])
        }
        function requestAnalysis(syncCommands, analysisCommand, syncRequestId) {
            requests = requests.concat([{ "kind": "analysis", "syncRequestId": syncRequestId,
                "syncCommands": syncCommands, "command": analysisCommand }])
        }
        function requestSynchronization(syncCommands, syncRequestId) {
            requests = requests.concat([{ "kind": "sync", "syncRequestId": syncRequestId }])
        }
    }

    Component {
        id: applicationFactory
        App.Main { visible: false }
    }

    function init() {
        failOnWarning(/ReferenceError|TypeError|read.only|Binding loop|Unable to assign \[undefined\]/)
        appSettings.values = ({})
        engineController.running = false
        engineController.ready = false
        engineController.failed = false
        engineController.candidates = []
        engineController.ownership = []
        engineController.requests = []
        engineController.commands = []
        fileIo.lastError = ""
        fileIo.savedText = ""
        application = applicationFactory.createObject(null)
        verify(application !== null, "The full Main component must instantiate")
        verify(application.appReady)
    }

    function cleanup() {
        if (application) {
            application.prepareApplicationShutdown()
            application.destroy()
            application = null
            wait(0)
        }
    }

    function test_initialization_and_readonly_position_mirror() {
        compare(application.currentNodeId, 0)
        compare(application.stoneCount, 0)
        compare(application.currentPlayer, 1)
        compare(application.gameNodes.length, 1)
        verify(application.engineDisabled)
        compare(application.engineStartupMode, 3)
        var rejected = false
        try {
            application.currentNodeId = 99
        } catch (error) {
            rejected = true
        }
        verify(rejected, "The UI must not be able to replace the session's current node")
        compare(application.currentNodeId, 0)
    }

    function test_translation_preserves_empty_unit_and_missing_key_fallback() {
        application.language = "en"
        compare(application.trText("deleteNodeDescendantUnit"), "")
        compare(application.trText("missingTranslationForTest"), "missingTranslationForTest")
        application.language = "zh"
        compare(application.trText("deleteNodeDescendantUnit"), "个")
    }

    function test_new_engine_preset_precedes_existing_presets() {
        application.setEnginePresetList([
            { "id": "first", "name": "First", "command": "first-mock-engine" },
            { "id": "second", "name": "Second", "command": "second-mock-engine" }
        ])
        compare(application.addEnginePreset(), 0)
        compare(application.enginePresets.length, 3)
        var newId = application.enginePresets[0].id
        verify(newId.length > 0 && newId !== "first" && newId !== "second")
        compare(application.enginePresets[1].id, "first")
        compare(application.enginePresets[2].id, "second")
    }

    function test_common_rules_popup_belongs_to_the_window_that_opened_it() {
        application.visible = true
        var settings = findChild(application, "settingsDialog")
        var popup = findChild(application, "commonGameRulesPopup")
        verify(settings !== null && popup !== null)
        settings.openPage(1)
        application.openCommonGameRulesPopup(settings)
        tryCompare(popup, "visible", true)
        compare(popup.transientParent, settings)
        compare(popup.modality, Qt.WindowModal)
        compare(popup.dialogBody.width, popup.width)
        popup.close()
        settings.close()

        application.openCommonGameRulesPopup()
        tryCompare(popup, "visible", true)
        compare(popup.transientParent, application)
        popup.close()
    }

    function requestAnalysisSync() {
        application.engineDisabled = false
        engineController.running = true
        engineController.ready = true
        application.engineLoading = false
        application.requestEngineAnalysis(true)
        var request = engineController.requests[engineController.requests.length - 1]
        verify(request !== undefined)
        engineController.engineSynchronizationCompleted(request.syncRequestId)
        return request.syncCommands
    }

    function test_hexgo_shape_sync_data() {
        return [
            { tag: "parallelogram", mode: 6, shape: 4 },
            { tag: "hexagon", mode: 7, shape: 6 },
            { tag: "triangle", mode: 8, shape: 3 }
        ]
    }

    function test_hexgo_shape_sync(data) {
        application.gameRuleMode = data.mode
        application.resetGameTree()
        verify(application.placeStone(4, 4))
        var commands = requestAnalysisSync()
        compare(commands[0], "stop")
        compare(commands[1], "shape 4")
        compare(commands[2], "boardsize 9")
        var shapeIndex = commands.indexOf("shape " + data.shape)
        verify(shapeIndex > 0 && shapeIndex < commands.indexOf("clear_board"))
        verify(commands[commands.length - 1].indexOf("play B ") === 0)

        // shape clears the engine board, so an incremental update must not send it.
        verify(application.placeStone(4, 5))
        commands = requestAnalysisSync()
        compare(commands.length, 2)
        compare(commands[0], "stop")
        verify(commands[1].indexOf("play W ") === 0)
    }

    function test_hexgo_shape_change_resets_mask_before_resizing() {
        application.gameRuleMode = application.gameRuleHexGoHexagon
        application.resetGameTree()
        requestAnalysisSync()
        application.gameRuleMode = application.gameRuleHexGoTriangle
        application.boardSizeX = 8
        application.boardSizeY = 8
        application.resetGameTree()
        compare(requestAnalysisSync().slice(0, 4), ["stop", "shape 4", "boardsize 8", "shape 3"])

        application.gameRuleMode = application.gameRuleHexGoParallelogram
        application.boardSizeY = 6
        application.resetGameTree()
        compare(requestAnalysisSync().slice(0, 3), ["stop", "shape 4", "rectangular_boardsize 8 6"])
    }

    function test_regular_go_does_not_send_hexgo_shape() {
        var commands = requestAnalysisSync()
        for (var i = 0; i < commands.length; ++i)
            verify(commands[i].indexOf("shape ") !== 0)
    }

    function test_place_undo_branch_and_delete() {
        verify(application.placeStone(2, 2))
        verify(application.placeStone(3, 3))
        compare(application.stoneCount, 2)
        compare(application.currentMoveNumberValue(), 2)
        application.undoMove()
        compare(application.stoneCount, 1)
        compare(application.currentPlayer, 2)
        verify(application.placeStone(4, 4))
        compare(application.currentNode().parent, 1)
        compare(application.nodeById(1).children.length, 2)
        application.setCurrentVariationAsMainBranch()
        compare(application.nodeById(1).children[0], application.currentNodeId)
        application.deleteCurrentNode()
        compare(application.currentNodeId, 1)
        compare(application.nodeById(1).children.length, 1)
        application.gotoLastMove()
        compare(application.stoneAt(3, 3), 2)
        compare(application.stoneAt(4, 4), 0)
    }

    function test_sgf_roundtrip_and_failed_record_preserve_position() {
        verify(application.placeStone(2, 2))
        verify(application.placeStone(3, 3))
        var text = application.buildSgf()
        var parsed = application.parseSgf(text)
        verify(parsed.ok)
        application.resetGameTree()
        compare(application.stoneCount, 0)
        application.applyParsedSgf(parsed, "memory.sgf")
        compare(application.stoneCount, 2)
        compare(application.currentMoveNumberValue(), 2)
        compare(application.gameDirty, false)
        var generation = application.gameTreeGeneration
        var before = application.buildSgf()
        var invalid = application.parseSgf("(;GM[1]SZ[9];B[aa];W[aa])")
        verify(invalid.ok)
        application.applyParsedSgf(invalid, "invalid.sgf")
        compare(application.gameTreeGeneration, generation)
        compare(application.buildSgf(), before)
        compare(application.stoneCount, 2)
        verify(application.saveSgfToFile("memory.sgf"))
        compare(fileIo.savedText, before)
    }

    function test_illegal_move_is_transactional() {
        verify(application.placeStone(2, 2))
        var revision = application.boardRevision
        var nextId = application.nextNodeId
        verify(!application.placeStone(2, 2))
        compare(application.currentNodeId, 1)
        compare(application.boardRevision, revision)
        compare(application.nextNodeId, nextId)
        compare(application.stoneCount, 1)
        compare(application.currentPlayer, 2)
    }

    function test_source_target_navigation_and_fixed_color_reset() {
        application.gameRuleMode = application.gameRuleAtaxx
        application.boardSizeX = 7
        application.boardSizeY = 7
        application.resetGameTree()
        compare(application.stoneCount, 4)
        verify(application.placeStone(0, 0))
        compare(application.currentMoveSourceNode().id, 1)
        compare(application.currentMoveNumberValue(), 0)
        compare(application.currentPlayer, 1)
        verify(application.placeStone(2, 2))
        compare(application.currentMoveNumberValue(), 1)
        compare(application.currentPlayer, 2)
        compare(application.stoneAt(0, 0), 0)
        application.undoMove()
        compare(application.stoneAt(0, 0), 1)
        compare(application.currentPlayer, 1)
        application.gotoLastMove()
        compare(application.stoneAt(2, 2), 1)
        application.setStoneColorMode(application.stoneColorModeWhite)
        application.resetGameTree()
        compare(application.currentPlayer, 2)
        compare(application.stoneColorMode, application.stoneColorModeWhite)
    }

    function test_analysis_annotations_and_ownership_restore_after_navigation() {
        verify(application.placeStone(2, 2))
        application.ownershipEnabled = true
        application.engineDisabled = false
        engineController.running = true
        engineController.ready = true
        application.engineLoading = false
        application.requestEngineAnalysis(true)
        verify(application.engineAnalysisRequestValid)
        var values = []
        for (var i = 0; i < application.boardSizeX * application.boardSizeY; ++i)
            values.push(0.3)
        engineController.ownership = values
        engineController.candidateRevision += 1
        engineController.candidates = [{ "move": "D4", "visits": 100,
            "winrate": 0.65, "scoreMean": 1.5, "pv": ["D4", "C3"] }]
        compare(application.currentNode().analysisCandidates.length, 1)
        compare(application.currentNode().analysisOwnership.length, values.length)
        compare(application.engineCandidates.length, 1)
        compare(application.engineOwnership.length, values.length)

        // This public entry point must also route winrate annotations through
        // the session, without assigning the UI's read-only tree mirror.
        application.setEngineCandidateDisplay(
                    [{ "move": "D4", "visits": 200, "winrate": 0.75 }], false, 2)
        application.recordCurrentAnalysisFromCandidates()
        compare(application.currentNode().analysisBlackWinrate, 25)
        application.gotoFirstMove()
        application.gotoNode(1)
        compare(application.engineCandidates.length, 1)
        verify(application.engineCandidatesFromCache)
        compare(application.engineOwnership.length, values.length)
        verify(application.engineOwnershipFromCache)
    }

    function denseHexCandidates(visits) {
        var candidates = []
        for (var y = 0; y < application.boardSizeY; ++y) {
            for (var x = 0; x < application.boardSizeX; ++x) {
                if (application.pointInRuleBoard(x, y))
                    candidates.push({ "move": application.engineCoordinateForNode({ "x": x, "y": y }),
                                      "order": candidates.length, "visits": visits, "winrate": 0.5 })
            }
        }
        return candidates
    }

    function test_dense_analysis_coalesces_latest_packet_and_discards_old_position() {
        application.boardSizeX = 35
        application.boardSizeY = 35
        application.gameRuleMode = application.gameRuleHexGoHexagon
        application.legacyHexEngineCoordinates = true
        application.resetGameTree()
        requestAnalysisSync()
        application.lastEngineCandidateUiUpdateAt = 0
        engineController.candidateRevision = 101
        engineController.candidates = denseHexCandidates(100)
        compare(application.engineCandidateRevision, 101)
        compare(application.engineCandidateItems.length, 919)
        engineController.candidateRevision = 102
        engineController.candidates = denseHexCandidates(200)
        engineController.candidateRevision = 103
        engineController.candidates = denseHexCandidates(300)
        compare(application.engineCandidateRevision, 101)
        tryCompare(application, "engineCandidateRevision", 103, 1000)
        compare(application.engineCandidateItems.length, 919)
        compare(application.currentNode().analysisCandidates[0].visits, 300)

        engineController.candidateRevision = 104
        engineController.candidates = denseHexCandidates(400)
        application.resetGameTree()
        wait(application.largeCandidateUiIntervalMs + 50)
        compare(application.engineCandidateItems.length, 0)
        compare(application.currentNode().analysisCandidates.length, 0)
    }

    function test_board_geometry_stays_current_after_rotation_resize_and_rule_changes() {
        var scene = findChild(application, "boardScene")
        verify(scene !== null)
        application.width = 1280
        application.height = 900
        application.visible = true
        wait(20)
        application.boardSizeX = 35
        application.boardSizeY = 27
        application.gameRuleMode = application.gameRuleHexGoParallelogram
        var rotations = [application.hexRotationCurrent, application.hexRotationTranspose,
                         application.hexRotationFlipX, application.hexRotationVertical]
        for (var i = 0; i < rotations.length; ++i) {
            application.hexBoardRotation = rotations[i]
            var pixel = scene.boardPointLocal(3, 7)
            var point = scene.pointFromMouse(pixel.x, pixel.y)
            compare(point.x, 3)
            compare(point.y, 7)
        }
        var oldPoint = scene.boardPointLocal(3, 7)
        application.width = 900
        application.height = 600
        wait(20)
        var resizedPoint = scene.boardPointLocal(3, 7)
        verify(oldPoint.x !== resizedPoint.x || oldPoint.y !== resizedPoint.y)
        var resized = scene.pointFromMouse(resizedPoint.x, resizedPoint.y)
        compare(resized.x, 3)
        compare(resized.y, 7)
        application.gameRuleMode = application.gameRuleGo
        application.boardSizeX = 19
        application.boardSizeY = 19
        var goPoint = scene.boardPointLocal(3, 7)
        var go = scene.pointFromMouse(goPoint.x, goPoint.y)
        compare(go.x, 3)
        compare(go.y, 7)
    }

    function test_imported_analysis_without_signatures_shows_immediately() {
        verify(application.placeStone(2, 2))
        application.updateNodeAnalysis(1, {
            "analysisCandidates": [{ "move": "D4", "visits": 100, "winrate": 0.65 }]
        })
        var parsed = application.parseSgf(application.buildSgf())
        verify(parsed.ok)
        compare(parsed.nodes[1].analysisCandidates.length, 1)
        compare(parsed.nodes[1].analysisCandidateBoardSignature, "")
        application.resetGameTree()
        application.applyParsedSgf(parsed, "analysis.sgf")
        compare(application.currentNode().analysisCandidates.length, 1)
        verify(application.nodeAnalysisCacheUsable(application.currentNode()))
        compare(application.engineCandidates.length, 1)
        verify(application.engineCandidatesFromCache)
    }

    function startBlackEngineMove() {
        application.engineDisabled = false
        engineController.running = true
        engineController.ready = true
        application.engineLoading = false
        application.setPlayMode(application.playModeAiBlack)
        application.requestAiMoveIfNeeded()
        verify(application.genmoveInFlight)
        verify(application.activeGenmoveRequestId > 0)
        return application.activeGenmoveRequestId
    }

    function test_generated_move_applies_once_and_clears_request() {
        var requestId = startBlackEngineMove()
        engineController.engineSynchronizationCompleted(application.activeGenmoveSyncRequestId)
        engineController.moveGenerated(requestId, "C3", true, "= C3")
        compare(application.currentMoveNumberValue(), 1)
        compare(application.currentPlayer, 2)
        verify(!application.genmoveInFlight)
        compare(application.activeGenmoveRequestId, 0)
        verify(!application.engineNeedsFullSync)
        compare(application.engineSyncedNodeIds.length, 1)
        compare(application.engineSyncedNodeIds[0], application.currentNodeId)
        var nodeId = application.currentNodeId
        engineController.moveGenerated(requestId, "D4", true, "= D4")
        compare(application.currentNodeId, nodeId)
        compare(application.stoneCount, 1)
    }

    function test_generated_move_from_previous_game_is_ignored() {
        var requestId = startBlackEngineMove()
        var generation = application.gameTreeGeneration
        application.resetGameTree()
        verify(application.gameTreeGeneration > generation)
        application.requestAiMoveIfNeeded()
        var newerRequestId = application.activeGenmoveRequestId
        verify(newerRequestId > requestId)
        engineController.moveGenerated(requestId, "C3", true, "= C3")
        compare(application.currentNodeId, 0)
        compare(application.stoneCount, 0)
        compare(application.activeGenmoveRequestId, newerRequestId)
        verify(application.genmoveInFlight)
        engineController.moveGenerated(newerRequestId, "D4", true, "= D4")
        compare(application.currentMoveNumberValue(), 1)
    }

    function test_navigation_invalidates_generated_move_position() {
        verify(application.placeStone(2, 2))
        verify(application.placeStone(3, 3))
        var requestId = startBlackEngineMove()
        application.gotoFirstMove()
        engineController.moveGenerated(requestId, "C3", true, "= C3")
        compare(application.currentNodeId, 0)
        compare(application.stoneCount, 0)
    }

    function test_source_and_target_engine_requests_complete_one_turn() {
        application.gameRuleMode = application.gameRuleAtaxx
        application.boardSizeX = 7
        application.boardSizeY = 7
        application.resetGameTree()
        var sourceRequest = startBlackEngineMove()
        engineController.engineSynchronizationCompleted(application.activeGenmoveSyncRequestId)
        var sourceText = application.gtpCoordinateName(0, 0, 7, 7)
        engineController.moveGenerated(sourceRequest, sourceText, true, "= " + sourceText)
        compare(application.currentNode().moveRole, "source")
        compare(application.currentPlayer, 1)
        compare(application.currentMoveNumberValue(), 0)
        compare(application.stoneCount, 4)
        verify(application.genmoveInFlight)
        var targetRequest = application.activeGenmoveRequestId
        verify(targetRequest > sourceRequest)
        verify(application.engineNeedsFullSync)
        engineController.engineSynchronizationCompleted(application.activeGenmoveSyncRequestId)
        var targetText = application.gtpCoordinateName(2, 2, 7, 7)
        engineController.moveGenerated(targetRequest, targetText, true, "= " + targetText)
        compare(application.currentNode().moveRole, "target")
        compare(application.currentPlayer, 2)
        compare(application.currentMoveNumberValue(), 1)
        compare(application.stoneAt(0, 0), 0)
        compare(application.stoneAt(2, 2), 1)
        verify(!application.genmoveInFlight)
    }

    function test_rule_switch_discards_previous_request() {
        var requestId = startBlackEngineMove()
        var generation = application.gameTreeGeneration
        application.applyRuleModeChange(application.gameRuleSurakarta)
        compare(application.gameRuleMode, application.gameRuleSurakarta)
        compare(application.boardSizeX, 6)
        compare(application.boardSizeY, 6)
        compare(application.stoneCount, 24)
        verify(application.gameTreeGeneration > generation)
        engineController.moveGenerated(requestId, "C3", true, "= C3")
        compare(application.currentNodeId, 0)
        compare(application.stoneCount, 24)
    }

    function test_engine_switch_discards_previous_request() {
        var requestId = startBlackEngineMove()
        engineController.command = "different-mock-engine"
        engineController.moveGenerated(requestId, "C3", true, "= C3")
        compare(application.currentNodeId, 0)
        compare(application.stoneCount, 0)
        verify(!application.genmoveInFlight)
        verify(application.engineNeedsFullSync)
    }
}
