import QtQuick
import "AnalysisCache.js" as AnalysisCache
import "CandidateModel.js" as CandidateModel
import "Ownership.js" as Ownership

QtObject {
    id: session

    // Value inputs and narrow adapters. This session never owns or mutates a
    // game node; annotations are committed by the supplied GameSession writer.
    property var position: ({ "nodeId": -1, "generation": 0, "player": 1,
                              "boardSignature": "", "komiSignature": "", "engineSignature": "" })
    property var currentNode: null
    property var presentationSettings: null
    property int boardSizeX: 19
    property int boardSizeY: 19
    property bool ownershipEnabled: false
    property bool ownershipSupported: false
    property var nodeResolver: null
    property var nodeAnalysisWriter: null
    property var coordinateParser: null
    property var coordinateFormatter: null
    property string passText: "Pass"
    property string resignText: "Resign"

    property var _candidates: []
    property var _projection: ({ "items": [], "itemMap": ({}), "table": [] })
    property int _candidateRevision: 0
    property bool _candidatesFromCache: false
    property var _ownership: []
    property bool _ownershipFromCache: false
    property var _ownershipPosition: ({ "boardSignature": "", "komiSignature": "", "engineSignature": "" })
    property int _ownershipRevision: 0
    property int _analysisRevision: 0

    readonly property var engineCandidates: _candidates
    readonly property var engineCandidateItems: _projection.items
    readonly property var engineCandidateItemMap: _projection.itemMap
    readonly property var engineCandidateTableItems: _projection.table
    readonly property int engineCandidateRevision: _candidateRevision
    readonly property bool engineCandidatesFromCache: _candidatesFromCache
    readonly property var engineOwnership: _ownership
    readonly property bool engineOwnershipFromCache: _ownershipFromCache
    readonly property string engineOwnershipBoardSignature: _ownershipPosition.boardSignature
    readonly property string engineOwnershipKomiSignature: _ownershipPosition.komiSignature
    readonly property string engineOwnershipEngineSignature: _ownershipPosition.engineSignature
    readonly property int engineOwnershipRevision: _ownershipRevision
    readonly property int analysisRevision: _analysisRevision

    signal candidatesChangedForDisplay()
    signal liveCandidatesAccepted()

    onPresentationSettingsChanged: rebuildCandidates()
    onCoordinateParserChanged: rebuildCandidates()
    onCoordinateFormatterChanged: rebuildCandidates()
    onPassTextChanged: rebuildCandidates()
    onResignTextChanged: rebuildCandidates()

    function ownershipConfiguration() {
        return { "width": boardSizeX, "height": boardSizeY,
                 "ownershipEnabled": ownershipEnabled, "ownershipSupported": ownershipSupported }
    }

    function resolveNode(id) {
        return nodeResolver ? nodeResolver(id) : (currentNode && currentNode.id === id ? currentNode : null)
    }

    function writeAnnotations(nodeId, values) {
        if (!values || !nodeAnalysisWriter)
            return false
        var result = nodeAnalysisWriter(nodeId, values)
        if (result === false || (result && result.ok === false))
            return false
        if (values.analysisBlackWinrate !== undefined)
            _analysisRevision += 1
        return true
    }

    function rebuildCandidates() {
        if (!presentationSettings || !coordinateParser || !coordinateFormatter) {
            _projection = { "items": [], "itemMap": ({}), "table": [] }
            candidatesChangedForDisplay()
            return
        }
        var entries = []
        for (var i = 0; i < _candidates.length; ++i) {
            var candidate = _candidates[i] || ({})
            var normalized = String(candidate.move || "").trim().toLowerCase()
            var kind = normalized === "pass" || normalized === "resign" ? normalized : ""
            var point = kind === "" ? coordinateParser(candidate.move) : null
            entries.push({ "candidate": candidate, "point": point, "moveKind": kind,
                           "moveText": point ? coordinateFormatter(point.x, point.y)
                                       : kind === "pass" ? passText : kind === "resign" ? resignText : "" })
        }
        _projection = CandidateModel.build(entries, presentationSettings)
        candidatesChangedForDisplay()
    }

    function setCandidates(candidates, fromCache, revision) {
        _candidates = candidates || []
        _candidatesFromCache = fromCache === true
        _candidateRevision = revision === undefined ? _candidateRevision + 1 : revision
        rebuildCandidates()
    }

    function resetCandidates() { setCandidates([], false) }

    function nodeCandidateCacheUsable(node) {
        return AnalysisCache.candidateUsable(node, position)
    }

    function recordWinrate(node, candidates, player) {
        var values = AnalysisCache.winrateAnnotations(node, candidates, player)
        return values.analysisBlackWinrate !== undefined && writeAnnotations(node.id, values)
    }

    function cacheCandidates(node, candidates, boardSignature, komiSignature, player) {
        if (!node || !candidates || candidates.length <= 0)
            return false
        var identity = AnalysisCache.requestPosition(position, {
            "nodeId": node.id, "boardSignature": boardSignature, "komiSignature": komiSignature,
            "player": player
        })
        return writeAnnotations(node.id, AnalysisCache.candidateAnnotations(node, candidates, identity))
    }

    function showCachedCandidates() {
        if (!nodeCandidateCacheUsable(currentNode))
            return false
        setCandidates(currentNode.analysisCandidates, true)
        return engineCandidateItems.length > 0
    }

    function applyCandidateUpdate(candidates, revision, request, active) {
        var target = AnalysisCache.requestPosition(position, request)
        var update = AnalysisCache.candidateUpdate(position, currentNode, resolveNode(target.nodeId),
                                                   request, candidates, active)
        if (update.annotations && !writeAnnotations(update.annotationNodeId, update.annotations))
            return false
        setCandidates(update.values, update.values.length > 0 && update.fromCache,
                      update.accepted ? revision : undefined)
        if (update.accepted)
            liveCandidatesAccepted()
        return update.accepted
    }

    function resetOwnership() {
        if (_ownership.length <= 0 && !_ownershipFromCache
                && _ownershipPosition.boardSignature === ""
                && _ownershipPosition.komiSignature === ""
                && _ownershipPosition.engineSignature === "")
            return
        _ownership = []
        _ownershipFromCache = false
        _ownershipPosition = { "boardSignature": "", "komiSignature": "", "engineSignature": "" }
        _ownershipRevision += 1
    }

    function setOwnership(values, fromCache, boardSignature, komiSignature, engineSignature) {
        var identity = AnalysisCache.requestPosition(position, {
            "boardSignature": boardSignature, "komiSignature": komiSignature, "engineSignature": engineSignature
        })
        var cached = fromCache === true
        if (_ownership === values && _ownershipFromCache === cached
                && _ownershipPosition.boardSignature === identity.boardSignature
                && _ownershipPosition.komiSignature === identity.komiSignature
                && _ownershipPosition.engineSignature === identity.engineSignature)
            return
        _ownership = values || []
        _ownershipFromCache = cached
        _ownershipPosition = identity
        _ownershipRevision += 1
    }

    function nodeOwnershipCacheUsable(node) {
        return AnalysisCache.ownershipUsable(node, position, ownershipConfiguration())
    }

    function showCachedOwnership() {
        if (!nodeOwnershipCacheUsable(currentNode)) {
            resetOwnership()
            return false
        }
        setOwnership(currentNode.analysisOwnership, true,
                     currentNode.analysisOwnershipBoardSignature, currentNode.analysisOwnershipKomiSignature,
                     currentNode.analysisOwnershipEngineSignature)
        return true
    }

    function applyOwnershipUpdate(values, request, active) {
        var target = AnalysisCache.requestPosition(position, request)
        var update = AnalysisCache.ownershipUpdate(position, currentNode, resolveNode(target.nodeId),
                                                   request, values, active, ownershipConfiguration())
        if (update.annotations && !writeAnnotations(update.annotationNodeId, update.annotations))
            return false
        if (update.values.length <= 0) {
            resetOwnership()
            return false
        }
        setOwnership(update.values, update.fromCache, update.position.boardSignature,
                     update.position.komiSignature, update.position.engineSignature)
        return update.accepted
    }

    function ownershipVisible() {
        return ownershipEnabled && ownershipSupported
                && Ownership.usable(_ownership, boardSizeX, boardSizeY)
                && _ownershipPosition.boardSignature === position.boardSignature
                && _ownershipPosition.komiSignature === position.komiSignature
                && _ownershipPosition.engineSignature === position.engineSignature
    }
}
