import QtQuick
import "BoardRenderer.js" as BoardRenderer
import "Ownership.js" as Ownership

Item {
    id: boardScene
    required property var app

    x: app.boardStageLeftReserve
    y: app.analysisToolbarHeight
    width: parent.width - app.boardStageLeftReserve - app.boardStageRightReserve
    height: parent.height - app.analysisToolbarHeight - app.commandToolbarHeight - app.panelGap

    readonly property bool coordinatesVisible: app.effectiveCoordinateDisplayMode() !== app.coordinateDisplayNone
    readonly property real boardOuterMargin: app.compactLayout ? 12 : 18
    readonly property real coordinateFontRatio: 0.32
    readonly property real coordinateCharWidthRatio: 0.58
    readonly property real coordinateGapRatio: 0.10
    readonly property real coordinateOuterGapRatio: 0.10
    readonly property real hexCellCoordinateExtraRatio: hexCellStyle ? 0.35 : 0
    readonly property real stoneRadiusRatio: app.stoneScale * 0.5
    readonly property bool hexBoard: app.ruleUsesHexGrid()
    readonly property bool torusGoBoard: app.gameRuleMode === app.gameRuleTorusGo
    readonly property bool squareCellBoard: app.ruleUsesSquareCells()
    readonly property bool hexCellStyle: app.ruleUsesHexCellStyle()
    readonly property bool hexTransposed: app.hexBoardRotation === app.hexRotationTranspose
                                          || app.hexBoardRotation === app.hexRotationFlipXTranspose
                                          || app.hexBoardRotation === app.hexRotationHorizontalTranspose
                                          || app.hexBoardRotation === app.hexRotationVerticalTranspose
                                          || app.hexBoardRotation === app.hexRotationMirrorTranspose
    readonly property bool hexFlippedX: app.hexBoardRotation === app.hexRotationFlipX
                                        || app.hexBoardRotation === app.hexRotationFlipXTranspose
    readonly property bool hexFlippedY: app.hexBoardRotation === app.hexRotationMirror
                                        || app.hexBoardRotation === app.hexRotationMirrorTranspose
    readonly property real hexRowHeightRatio: 0.8660254037844386
    readonly property real hexCellRadiusRatio: 0.5773502691896258
    readonly property var hexDisplayTransform: hexBoard ? BoardRenderer.hexDisplayTransform(rendererState()) : null
    readonly property real horizontalPointRadiusRatio: hexBoard
                                                   ? (hexCellStyle ? 0.5 : Math.max(stoneRadiusRatio, 0.5))
                                                   : stoneRadiusRatio
    readonly property real verticalPointRadiusRatio: hexBoard
                                                 ? (hexCellStyle ? hexCellRadiusRatio : Math.max(stoneRadiusRatio, 0.5))
                                                 : stoneRadiusRatio
    readonly property int hexDisplaySizeX: hexTransposed ? app.boardSizeY : app.boardSizeX
    readonly property int hexDisplaySizeY: hexTransposed ? app.boardSizeX : app.boardSizeY
    readonly property int maxXCoordinateChars: coordinatesVisible
                                                ? Math.max(String(app.xCoordinateText(0)).length,
                                                           String(app.xCoordinateText(Math.max(0, app.boardSizeX - 1))).length)
                                                : 0
    readonly property int maxYCoordinateChars: coordinatesVisible
                                                ? Math.max(String(app.yCoordinateText(0)).length,
                                                           String(app.yCoordinateText(Math.max(0, app.boardSizeY - 1))).length)
                                                : 0
    readonly property real xCoordinateTextWidthRatio: maxXCoordinateChars * coordinateCharWidthRatio * coordinateFontRatio
    readonly property real yCoordinateTextWidthRatio: maxYCoordinateChars * coordinateCharWidthRatio * coordinateFontRatio
    readonly property real horizontalPaddingRatio: coordinatesVisible
                                                    ? horizontalPointRadiusRatio + coordinateGapRatio + yCoordinateTextWidthRatio
                                                      + coordinateOuterGapRatio + hexCellCoordinateExtraRatio
                                                    : horizontalPointRadiusRatio + coordinateOuterGapRatio
    readonly property real verticalPaddingRatio: coordinatesVisible
                                                  ? verticalPointRadiusRatio + coordinateGapRatio + coordinateFontRatio
                                                    + coordinateOuterGapRatio + hexCellCoordinateExtraRatio
                                                  : verticalPointRadiusRatio + coordinateOuterGapRatio
    readonly property real availableWidth: Math.max(1, width - boardOuterMargin * 2)
    readonly property real availableHeight: Math.max(1, height - boardOuterMargin * 2)
    readonly property real gridUnitWidth: hexBoard
                                           ? BoardRenderer.gridUnitWidth(rendererState(), hexDisplayTransform)
                                           : torusGoBoard ? BoardRenderer.gridUnitWidth(rendererState(), null)
                                           : squareCellBoard ? Math.max(1, app.boardSizeX)
                                                             : Math.max(1, app.boardSizeX - 1)
    readonly property real gridUnitHeight: hexBoard
                                            ? BoardRenderer.gridUnitHeight(rendererState(), hexDisplayTransform)
                                            : torusGoBoard ? BoardRenderer.gridUnitHeight(rendererState(), null)
                                            : squareCellBoard ? Math.max(1, app.boardSizeY)
                                                              : Math.max(1, app.boardSizeY - 1)
    readonly property real cellSize: Math.max(0.1, Math.min(
        availableWidth / (gridUnitWidth + horizontalPaddingRatio * 2),
        availableHeight / (gridUnitHeight + verticalPaddingRatio * 2)))
    readonly property real boardPaddingX: horizontalPaddingRatio * cellSize
    readonly property real boardPaddingY: verticalPaddingRatio * cellSize
    readonly property real coordinateFontSize: coordinateFontRatio * cellSize
    readonly property real xCoordinateLabelOffset: (verticalPointRadiusRatio + coordinateGapRatio
                                                    + coordinateFontRatio * 0.5 + hexCellCoordinateExtraRatio) * cellSize
    readonly property real yCoordinateLabelOffset: (horizontalPointRadiusRatio + coordinateGapRatio
                                                    + yCoordinateTextWidthRatio * 0.5 + hexCellCoordinateExtraRatio) * cellSize
    readonly property real gridWidth: cellSize * gridUnitWidth
    readonly property real gridHeight: cellSize * gridUnitHeight
    readonly property real boardLeft: Math.round((width - gridWidth) / 2)
    readonly property real boardTop: Math.round((height - gridHeight) / 2)
    readonly property real boardRight: boardLeft + gridWidth
    readonly property real boardBottom: boardTop + gridHeight
    readonly property bool variationPreviewActive:
        app.analysisPresentationVisible()
        && app.activeCandidateVariationPreviewActive()
    readonly property bool hoverCandidateActive:
        app.analysisPresentationVisible() && app.hoverKey !== ""
                                                  && app.pointIsEngineCandidateKey(app.hoverKey)

    function hexDisplayCoordForBoard(x, y) {
        return hexTransposed ? Qt.point(y, x) : Qt.point(x, y)
    }

    function boardCoordForHexDisplay(x, y) {
        return hexTransposed ? Qt.point(y, x) : Qt.point(x, y)
    }

    function hexDisplayPointLocal(x, y) {
        var point = BoardRenderer.hexDisplayPointLocal(rendererState(), rendererGeometry(), x, y)
        return Qt.point(point.x, point.y)
    }

    function boardPointLocal(x, y) {
        if (hexBoard) {
            var display = hexDisplayCoordForBoard(x, y)
            return hexDisplayPointLocal(display.x, display.y)
        }
        if (squareCellBoard)
            return Qt.point(boardLeft + (x + 0.5) * cellSize,
                            boardTop + (y + 0.5) * cellSize)
        if (torusGoBoard) {
            var torusPoint = BoardRenderer.torusDisplayPointLocal(rendererState(), rendererGeometry(), x, y)
            return Qt.point(torusPoint.x, torusPoint.y)
        }
        return Qt.point(boardLeft + x * cellSize, boardTop + y * cellSize)
    }

    function pointFromMouse(mouseX, mouseY) {
        if (cellSize <= 0)
            return null

        if (squareCellBoard) {
            var cellX = Math.floor((mouseX - boardLeft) / cellSize)
            var cellY = Math.floor((mouseY - boardTop) / cellSize)
            if (!app.pointInRuleBoard(cellX, cellY))
                return null
            return { "x": cellX, "y": cellY, "key": app.keyFor(cellX, cellY) }
        }

        var y
        var x
        if (hexBoard) {
            var display = BoardRenderer.hexDisplayCoordFromUnit(rendererState(),
                                                                 (mouseX - boardLeft) / cellSize,
                                                                 (mouseY - boardTop) / cellSize,
                                                                 hexDisplayTransform)
            var displayX = Math.round(display.x)
            var displayY = Math.round(display.y)
            var board = boardCoordForHexDisplay(displayX, displayY)
            x = board.x
            y = board.y
        } else if (torusGoBoard) {
            x = Math.round((mouseX - boardLeft) / cellSize
                           - BoardRenderer.torusPaddingX(rendererState()) - 0.5)
            y = Math.round((mouseY - boardTop) / cellSize
                           - BoardRenderer.torusPaddingY(rendererState()) - 0.5)
        } else {
            y = Math.round((mouseY - boardTop) / cellSize)
            x = Math.round((mouseX - boardLeft) / cellSize)
        }
        if (!app.pointInRuleBoard(x, y))
            return null

        var point = boardPointLocal(x, y)
        var dx = mouseX - point.x
        var dy = mouseY - point.y
        var hitRadiusRatio = hexBoard ? 0.62 : 0.50
        var hitRadius = Math.max(14, cellSize * app.mouseHitRadiusScale * 1.35)
        hitRadius = Math.min(hitRadius, cellSize * hitRadiusRatio)
        if (Math.sqrt(dx * dx + dy * dy) > hitRadius)
            return null
        return { "x": x, "y": y, "key": app.keyFor(x, y) }
    }

    function rendererState() {
        return BoardRenderer.stateFromApp(app)
    }

    function rendererGeometry() {
        return BoardRenderer.geometryFromScene(boardScene)
    }

    Rectangle {
        x: boardScene.boardLeft - boardScene.boardPaddingX
        y: boardScene.boardTop - boardScene.boardPaddingY
        width: boardScene.gridWidth + boardScene.boardPaddingX * 2
        height: boardScene.gridHeight + boardScene.boardPaddingY * 2
        radius: 6
        color: boardScene.hexCellStyle ? "#f2cc62" : app.boardWoodColor
        border.color: boardScene.hexCellStyle ? "#0b3d73" : "#9d7442"
        border.width: 1
        opacity: 0.98
    }

    Canvas {
        id: boardBaseCanvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            BoardRenderer.drawBoardBase(ctx,
                                        boardScene.rendererState(),
                                        boardScene.rendererGeometry())
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Connections {
            target: app
            function onGameRuleModeChanged() { boardBaseCanvas.requestPaint() }
            function onBoardPresentationModeChanged() { boardBaseCanvas.requestPaint() }
            function onHexBoardStyleChanged() { boardBaseCanvas.requestPaint() }
            function onHexBoardRotationChanged() { boardBaseCanvas.requestPaint() }
            function onBoardSizeXChanged() { boardBaseCanvas.requestPaint() }
            function onBoardSizeYChanged() { boardBaseCanvas.requestPaint() }
            function onStoneScaleChanged() { boardBaseCanvas.requestPaint() }
            function onGridOpacityChanged() { boardBaseCanvas.requestPaint() }
            function onGridLineWidthChanged() { boardBaseCanvas.requestPaint() }
            function onCoordinateDisplayModeChanged() { boardBaseCanvas.requestPaint() }
            function onCoordinateFontFamilyChanged() { boardBaseCanvas.requestPaint() }
            function onCompactLayoutChanged() { boardBaseCanvas.requestPaint() }
        }
    }

    Canvas {
        id: boardCanvas
        anchors.fill: parent
        property var renderState: null
        property var renderGeometry: null

        function drawStone(ctx, x, y, player, radius) {
            var state = renderState || boardScene.rendererState()
            var geometry = renderGeometry || boardScene.rendererGeometry()
            BoardRenderer.drawStone(ctx, state, geometry, x, y, player, radius)
        }

        function canvasFont(size, bold) {
            var family = String(app.coordinateFontFamily).replace(/"/g, "")
            return (bold ? "700 " : "400 ") + Math.max(1, Math.round(size)) + "px \"" + family + "\", sans-serif"
        }

        function drawCenteredText(ctx, text, x, y, color, size, bold, maxWidth) {
            ctx.save()
            ctx.fillStyle = color
            ctx.font = canvasFont(size, bold)
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"
            if (maxWidth !== undefined)
                ctx.fillText(text, x, y, maxWidth)
            else
                ctx.fillText(text, x, y)
            ctx.restore()
        }

        function drawNextMoveMarkers(ctx, stoneRadius) {
            var markers = app.nextMoveMarkerItems()
            for (var i = 0; i < markers.length; ++i) {
                var marker = markers[i]
                var point = boardScene.boardPointLocal(marker.x, marker.y)
                var lineWidth = marker.mainBranch
                              ? Math.max(stoneRadius / 7, 2)
                              : Math.max(stoneRadius / 15, 1)
                var radius = Math.max(1, stoneRadius - lineWidth * 0.5)
                ctx.save()
                ctx.strokeStyle = marker.player === 1 ? "#111820" : "#f8fbfd"
                ctx.lineWidth = lineWidth
                ctx.beginPath()
                ctx.arc(point.x, point.y, radius, 0, Math.PI * 2)
                ctx.stroke()
                ctx.restore()
            }
        }

        function drawVariationArrow(ctx, move, radius, opacity) {
            var from = boardScene.boardPointLocal(move.fromX, move.fromY)
            var to = boardScene.boardPointLocal(move.x, move.y)
            var dx = to.x - from.x
            var dy = to.y - from.y
            var length = Math.sqrt(dx * dx + dy * dy)
            if (length <= 0.001)
                return to

            var ux = dx / length
            var uy = dy / length
            var startOffset = Math.min(radius * 0.62, length * 0.28)
            var endOffset = Math.min(radius * 0.72, length * 0.34)
            var sx = from.x + ux * startOffset
            var sy = from.y + uy * startOffset
            var ex = to.x - ux * endOffset
            var ey = to.y - uy * endOffset
            var head = Math.max(8, radius * 0.42)
            var lineWidth = Math.max(4, radius * 0.16)
            var stroke = move.player === 1 ? "#111820" : "#f8fbfd"
            var outline = move.player === 1 ? "#f8fbfd" : "#13212b"

            function strokeArrow(color, width) {
                ctx.strokeStyle = color
                ctx.fillStyle = color
                ctx.lineWidth = width
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                ctx.beginPath()
                ctx.moveTo(sx, sy)
                ctx.lineTo(ex, ey)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(to.x - ux * endOffset * 0.20, to.y - uy * endOffset * 0.20)
                ctx.lineTo(ex - uy * head * 0.55, ey + ux * head * 0.55)
                ctx.lineTo(ex + uy * head * 0.55, ey - ux * head * 0.55)
                ctx.closePath()
                ctx.fill()
            }

            ctx.save()
            ctx.globalAlpha = Math.max(0.55, Math.min(1, opacity))
            strokeArrow(outline, lineWidth + Math.max(2, radius * 0.08))
            strokeArrow(stroke, lineWidth)
            ctx.restore()
            return to
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var cell = boardScene.cellSize
            renderState = boardScene.rendererState()
            renderGeometry = boardScene.rendererGeometry()

            var stoneRadius = Math.max(8, cell * app.stoneScale * 0.5)

            BoardRenderer.drawTorusRepeatedStones(ctx, renderState, renderGeometry,
                                                  app.stoneItems, stoneRadius)
            BoardRenderer.drawDotsAndBoxesPosition(ctx, renderState, renderGeometry, app.stoneItems)

            for (var f = 0; f < app.gomokuForbiddenPointItems.length; ++f) {
                var forbidden = app.gomokuForbiddenPointItems[f]
                var fp = boardScene.boardPointLocal(forbidden.x, forbidden.y)
                var crossSize = Math.max(7, stoneRadius * 0.42)
                ctx.save()
                ctx.strokeStyle = "#f01818"
                ctx.lineWidth = Math.max(2, cell * 0.055)
                ctx.lineCap = "round"
                ctx.beginPath()
                ctx.moveTo(fp.x - crossSize, fp.y - crossSize)
                ctx.lineTo(fp.x + crossSize, fp.y + crossSize)
                ctx.moveTo(fp.x + crossSize, fp.y - crossSize)
                ctx.lineTo(fp.x - crossSize, fp.y + crossSize)
                ctx.stroke()
                ctx.restore()
            }

            for (var s = 0; s < app.stoneItems.length; ++s) {
                var stone = app.stoneItems[s]
                if (!app.ruleUsesDotsAndBoxes())
                    drawStone(ctx, stone.x, stone.y, stone.player, stoneRadius)
            }

            var sourceNode = app.currentMoveSourceNode()
            if (sourceNode) {
                var sp = boardScene.boardPointLocal(sourceNode.x, sourceNode.y)
                var sourceSize = stoneRadius * 0.58
                ctx.fillStyle = "#f39c12"
                ctx.strokeStyle = "#7a3f00"
                ctx.lineWidth = Math.max(1, cell * 0.035)
                ctx.beginPath()
                ctx.moveTo(sp.x, sp.y - sourceSize * 0.72)
                ctx.lineTo(sp.x + sourceSize * 0.68, sp.y + sourceSize * 0.48)
                ctx.lineTo(sp.x - sourceSize * 0.68, sp.y + sourceSize * 0.48)
                ctx.closePath()
                ctx.fill()
                ctx.stroke()
            }

            for (var w = 0; w < app.gomokuWinLineItems.length; ++w) {
                var win = app.gomokuWinLineItems[w]
                var start = boardScene.boardPointLocal(win.startX, win.startY)
                var end = boardScene.boardPointLocal(win.endX, win.endY)
                ctx.strokeStyle = "#f01818"
                ctx.lineWidth = Math.max(4, cell * 0.09)
                ctx.lineCap = "round"
                ctx.beginPath()
                ctx.moveTo(start.x, start.y)
                ctx.lineTo(end.x, end.y)
                ctx.stroke()
            }

            if (app.hexWinPathItems.length > 0) {
                ctx.strokeStyle = "#f01818"
                ctx.lineWidth = Math.max(4, cell * 0.09)
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                if (app.hexWinPathItems.length === 1) {
                    var single = app.hexWinPathItems[0]
                    var singlePoint = boardScene.boardPointLocal(single.x, single.y)
                    ctx.beginPath()
                    ctx.arc(singlePoint.x, singlePoint.y, Math.max(5, cell * 0.16), 0, Math.PI * 2)
                    ctx.stroke()
                } else {
                    ctx.beginPath()
                    for (var hp = 0; hp < app.hexWinPathItems.length; ++hp) {
                        var pathPoint = app.hexWinPathItems[hp]
                        var point = boardScene.boardPointLocal(pathPoint.x, pathPoint.y)
                        if (hp === 0)
                            ctx.moveTo(point.x, point.y)
                        else
                            ctx.lineTo(point.x, point.y)
                    }
                    ctx.stroke()
                }
            }

            if (!boardScene.variationPreviewActive && !app.ruleUsesDotsAndBoxes()) {
                for (var o = 0; o < app.stoneItems.length; ++o) {
                    var overlayStone = app.stoneItems[o]
                    var last = app.isLastMoveAt(overlayStone.x, overlayStone.y)
                    if (!app.stoneOverlayVisible(overlayStone.moveNumber, last))
                        continue
                    var op = boardScene.boardPointLocal(overlayStone.x, overlayStone.y)
                    if (last) {
                        var markerSize = stoneRadius * 0.62
                        var markerCornerX = op.x - stoneRadius
                        var markerCornerY = op.y - stoneRadius
                        ctx.fillStyle = "#e3342f"
                        ctx.beginPath()
                        ctx.moveTo(markerCornerX, markerCornerY)
                        ctx.lineTo(markerCornerX + markerSize, markerCornerY)
                        ctx.lineTo(markerCornerX, markerCornerY + markerSize)
                        ctx.closePath()
                        ctx.fill()
                    }
                    if (app.stoneNumberVisible(overlayStone.moveNumber, last)) {
                        var moveNumberText = String(overlayStone.moveNumber)
                        var moveNumberFontSize = app.stoneNumberFontSize(ctx, moveNumberText, stoneRadius)
                        drawCenteredText(ctx, moveNumberText, op.x, op.y + app.stoneNumberOffsetY(moveNumberFontSize),
                                         app.stoneNumberColor(overlayStone.player, last),
                                         moveNumberFontSize, true,
                                         app.stoneNumberMaxWidth(stoneRadius))
                    }
                }
            }

            if (!boardScene.variationPreviewActive)
                drawNextMoveMarkers(ctx, stoneRadius)

            renderState = null
            renderGeometry = null
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Connections {
            target: app
            function onBoardRevisionChanged() { boardCanvas.requestPaint() }
            function onCurrentNodeIdChanged() { boardCanvas.requestPaint() }
            function onGameNodesChanged() { boardCanvas.requestPaint() }
            function onGameRuleModeChanged() { boardCanvas.requestPaint() }
            function onBoardPresentationModeChanged() { boardCanvas.requestPaint() }
            function onHexBoardStyleChanged() { boardCanvas.requestPaint() }
            function onHexBoardRotationChanged() { boardCanvas.requestPaint() }
            function onBoardSizeXChanged() { boardCanvas.requestPaint() }
            function onBoardSizeYChanged() { boardCanvas.requestPaint() }
            function onGomokuWinLineItemsChanged() { boardCanvas.requestPaint() }
            function onGomokuForbiddenPointItemsChanged() { boardCanvas.requestPaint() }
            function onHexWinPathItemsChanged() { boardCanvas.requestPaint() }
            function onStoneScaleChanged() { boardCanvas.requestPaint() }
            function onSelectedPointScaleChanged() { boardCanvas.requestPaint() }
            function onMoveNumberLabelScaleChanged() { boardCanvas.requestPaint() }
            function onMoveNumberDisplayModeChanged() { boardCanvas.requestPaint() }
            function onCoordinateDisplayModeChanged() { boardCanvas.requestPaint() }
            function onCoordinateFontFamilyChanged() { boardCanvas.requestPaint() }
            function onCompactLayoutChanged() { boardCanvas.requestPaint() }
        }
    }

    Canvas {
        id: ownershipCanvas
        anchors.fill: parent
        visible: app.ownershipVisibleForCurrentPosition()

        function requestVisiblePaint() {
            if (visible)
                requestPaint()
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            if (!visible)
                return

            var markerSize = Math.max(5, boardScene.cellSize * 0.30)
            var half = markerSize * 0.5
            for (var i = 0; i < app.engineOwnership.length; ++i) {
                var value = Number(app.engineOwnership[i])
                var opacity = Ownership.markerOpacity(value)
                if (opacity <= 0)
                    continue

                var coordinate = Ownership.pointForIndex(i, app.boardSizeX)
                var point = boardScene.boardPointLocal(coordinate.x, coordinate.y)
                ctx.save()
                ctx.globalAlpha = opacity
                ctx.fillStyle = value >= 0 ? "#070b0e" : "#ffffff"
                ctx.fillRect(point.x - half, point.y - half, markerSize, markerSize)
                ctx.globalAlpha = Math.min(0.72, opacity + 0.15)
                ctx.strokeStyle = value >= 0 ? "#eaf0f3" : "#17232a"
                ctx.lineWidth = Math.max(1, boardScene.cellSize * 0.018)
                ctx.strokeRect(point.x - half, point.y - half, markerSize, markerSize)
                ctx.restore()
            }
        }

        onVisibleChanged: requestVisiblePaint()
        onWidthChanged: requestVisiblePaint()
        onHeightChanged: requestVisiblePaint()

        Connections {
            target: app
            function onEngineOwnershipRevisionChanged() { ownershipCanvas.requestVisiblePaint() }
            function onOwnershipEnabledChanged() { ownershipCanvas.requestVisiblePaint() }
            function onGameRuleModeChanged() { ownershipCanvas.requestVisiblePaint() }
            function onBoardSizeXChanged() { ownershipCanvas.requestVisiblePaint() }
            function onBoardSizeYChanged() { ownershipCanvas.requestVisiblePaint() }
            function onBoardPresentationModeChanged() { ownershipCanvas.requestVisiblePaint() }
            function onStoneScaleChanged() { ownershipCanvas.requestVisiblePaint() }
            function onCoordinateDisplayModeChanged() { ownershipCanvas.requestVisiblePaint() }
            function onCompactLayoutChanged() { ownershipCanvas.requestVisiblePaint() }
        }
    }

    Canvas {
        id: candidateCanvas
        anchors.fill: parent
        visible: app.analysisPresentationVisible()
                 && !boardScene.variationPreviewActive
                 && app.engineCandidateItems.length > 0
                 || app.koLocKey !== ""
                 || app.koLocKey2 !== ""

        function requestVisiblePaint() {
            if (visible)
                requestPaint()
        }

        onPaint: {
            if (!visible)
                return

            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var cell = boardScene.cellSize
            var candidateRadius = Math.max(8, cell * app.stoneScale * 0.5)

            if (!boardScene.variationPreviewActive) {
                var simpleMarkerBuckets = ({})
                var simpleMarkerBucketKeys = []
                var detailedCandidates = []
                var bucketLevels = 32
                for (var c = app.engineCandidateItems.length - 1; c >= 0; --c) {
                    var candidate = app.engineCandidateItems[c]
                    if (!candidate.boardVisible)
                        continue
                    var cp = boardScene.boardPointLocal(candidate.x, candidate.y)
                    var showCandidateText = candidate.qualified
                    var candidateLines = showCandidateText ? (candidate.labelLines || []) : []
                    var isFirstCandidate = candidate.displayIndex === 1
                    var isBestCandidate = app.bestCandidateRingVisible
                                          && app.candidateRingVisible
                                          && candidate.key === app.bestCandidateRingKey
                    if (!showCandidateText && candidate.displayIndex > 9
                            && !isBestCandidate) {
                        var visitRatio = Math.max(0, Math.min(1, Number(candidate.visitRatio)))
                        var colorLevel = Math.round(Math.sqrt(visitRatio)
                                                    * (bucketLevels - 1))
                        var alphaLevel = Math.round(app.candidateYzyAlphaRatio(visitRatio)
                                                    * (bucketLevels - 1))
                        var bucketKey = colorLevel * bucketLevels + alphaLevel
                        var bucket = simpleMarkerBuckets[bucketKey]
                        if (!bucket) {
                            var colorFraction = colorLevel / (bucketLevels - 1)
                            var alphaFraction = alphaLevel / (bucketLevels - 1)
                            var colorVisitRatio = colorFraction * colorFraction
                            var alphaVisitRatio = Math.exp(
                                        (alphaFraction - 1)
                                        * app.candidateYzyAlphaFactor)
                            bucket = {
                                "points": [],
                                "fillColor": app.candidateMarkerColor(2,
                                                                       colorVisitRatio),
                                "fillOpacity": app.candidateMarkerOpacity(
                                                   2, alphaVisitRatio),
                                "outlineOpacity": app.candidateMarkerOutlineOpacity(
                                                      alphaVisitRatio)
                            }
                            simpleMarkerBuckets[bucketKey] = bucket
                            simpleMarkerBucketKeys.push(bucketKey)
                        }
                        bucket.points.push(cp.x)
                        bucket.points.push(cp.y)
                        continue
                    }
                    detailedCandidates.push({
                        "candidate": candidate,
                        "point": cp,
                        "showText": showCandidateText,
                        "isFirst": isFirstCandidate,
                        "isBest": isBestCandidate
                    })
                }

                simpleMarkerBucketKeys.sort(function(left, right) {
                    return Number(left) - Number(right)
                })
                for (var bucketIndex = 0;
                     bucketIndex < simpleMarkerBucketKeys.length;
                     ++bucketIndex) {
                    var simpleBucket =
                        simpleMarkerBuckets[simpleMarkerBucketKeys[bucketIndex]]
                    ctx.save()
                    ctx.beginPath()
                    for (var pointIndex = 0;
                         pointIndex < simpleBucket.points.length;
                         pointIndex += 2) {
                        var pointX = simpleBucket.points[pointIndex]
                        var pointY = simpleBucket.points[pointIndex + 1]
                        ctx.moveTo(pointX + candidateRadius, pointY)
                        ctx.arc(pointX, pointY, candidateRadius, 0, Math.PI * 2)
                    }
                    ctx.globalAlpha = simpleBucket.fillOpacity
                    ctx.fillStyle = simpleBucket.fillColor
                    ctx.fill()
                    ctx.globalAlpha = simpleBucket.outlineOpacity
                    ctx.strokeStyle = "#000000"
                    ctx.lineWidth = Math.max(1, candidateRadius / 26.5)
                    ctx.stroke()
                    ctx.restore()
                }

                for (var detailIndex = 0;
                     detailIndex < detailedCandidates.length;
                     ++detailIndex) {
                    var detail = detailedCandidates[detailIndex]
                    candidate = detail.candidate
                    cp = detail.point
                    showCandidateText = detail.showText
                    isFirstCandidate = detail.isFirst
                    isBestCandidate = detail.isBest
                    var candidateLines = showCandidateText ? (candidate.labelLines || []) : []
                    var markerOptions = {
                        "fillColor": candidate.color || app.candidateMarkerColor(candidate.displayIndex,
                                                                                  candidate.visitRatio),
                        "fillOpacity": candidate.opacity,
                        "drawOutline": !isFirstCandidate,
                        "outlineOpacity": candidate.outlineOpacity,
                        "drawRing": isBestCandidate,
                        "ringColor": app.firstCandidateRingColor,
                        "textColor": isFirstCandidate ? app.candidateFirstLabelTextColor : "",
                        "rankText": app.candidateRankLabelText(candidate.displayIndex)
                    }
                    if (showCandidateText) {
                        markerOptions.fallbackText = String(candidate.displayIndex)
                        markerOptions.fallbackColor = isFirstCandidate ? app.candidateFirstLabelTextColor : "#104f29"
                        markerOptions.fallbackFontSize = Math.max(10, Math.min(16, cell * 0.20))
                    }
                    app.drawCandidateMarker(ctx, cp.x, cp.y, candidateRadius, candidateLines, markerOptions)
                }
            }

            function drawKoMark(x, y) {
                var kp = boardScene.boardPointLocal(x, y)
                ctx.strokeStyle = "#f01818"
                ctx.lineWidth = 3
                ctx.lineCap = "round"
                ctx.beginPath()
                ctx.moveTo(kp.x - 8, kp.y - 8)
                ctx.lineTo(kp.x + 8, kp.y + 8)
                ctx.moveTo(kp.x + 8, kp.y - 8)
                ctx.lineTo(kp.x - 8, kp.y + 8)
                ctx.stroke()
            }
            if (app.koLocKey !== "" && app.stoneAt(app.koLocX, app.koLocY) === 0)
                drawKoMark(app.koLocX, app.koLocY)
            if (app.koLocKey2 !== "" && app.stoneAt(app.koLocX2, app.koLocY2) === 0)
                drawKoMark(app.koLocX2, app.koLocY2)
        }

        onVisibleChanged: requestVisiblePaint()
        onWidthChanged: requestVisiblePaint()
        onHeightChanged: requestVisiblePaint()

        Connections {
            target: app
            function onEngineCandidateItemsChanged() { candidateCanvas.requestVisiblePaint() }
            function onBoardRevisionChanged() { candidateCanvas.requestVisiblePaint() }
            function onBestCandidateRingVisibleChanged() { candidateCanvas.requestVisiblePaint() }
            function onBestCandidateRingKeyChanged() { candidateCanvas.requestVisiblePaint() }
            function onKoLocKeyChanged() { candidateCanvas.requestVisiblePaint() }
            function onKoLocXChanged() { candidateCanvas.requestVisiblePaint() }
            function onKoLocYChanged() { candidateCanvas.requestVisiblePaint() }
            function onKoLocKey2Changed() { candidateCanvas.requestVisiblePaint() }
            function onKoLocX2Changed() { candidateCanvas.requestVisiblePaint() }
            function onKoLocY2Changed() { candidateCanvas.requestVisiblePaint() }
            function onGameRuleModeChanged() { candidateCanvas.requestVisiblePaint() }
            function onBoardPresentationModeChanged() { candidateCanvas.requestVisiblePaint() }
            function onHexBoardStyleChanged() { candidateCanvas.requestVisiblePaint() }
            function onHexBoardRotationChanged() { candidateCanvas.requestVisiblePaint() }
            function onBoardSizeXChanged() { candidateCanvas.requestVisiblePaint() }
            function onBoardSizeYChanged() { candidateCanvas.requestVisiblePaint() }
            function onStoneScaleChanged() { candidateCanvas.requestVisiblePaint() }
            function onCoordinateDisplayModeChanged() { candidateCanvas.requestVisiblePaint() }
            function onCandidateWinrateLabelVisibleChanged() { candidateCanvas.requestVisiblePaint() }
            function onCandidateVisitsLabelVisibleChanged() { candidateCanvas.requestVisiblePaint() }
            function onCandidateScoreLabelVisibleChanged() { candidateCanvas.requestVisiblePaint() }
            function onCandidateWinrateFontSizeChanged() { candidateCanvas.requestVisiblePaint() }
            function onCandidateVisitsFontSizeChanged() { candidateCanvas.requestVisiblePaint() }
            function onCandidateScoreFontSizeChanged() { candidateCanvas.requestVisiblePaint() }
            function onCandidateWinrateBoldChanged() { candidateCanvas.requestVisiblePaint() }
            function onCandidateVisitsBoldChanged() { candidateCanvas.requestVisiblePaint() }
            function onCandidateScoreBoldChanged() { candidateCanvas.requestVisiblePaint() }
            function onCandidateWinrateOffsetYChanged() { candidateCanvas.requestVisiblePaint() }
            function onCandidateVisitsOffsetYChanged() { candidateCanvas.requestVisiblePaint() }
            function onCandidateScoreOffsetYChanged() { candidateCanvas.requestVisiblePaint() }
            function onCandidateWinrateDecimalsChanged() { candidateCanvas.requestVisiblePaint() }
            function onCandidateScoreDecimalsChanged() { candidateCanvas.requestVisiblePaint() }
            function onCandidateWinrateShowPercentChanged() { candidateCanvas.requestVisiblePaint() }
            function onCandidateScoreShowPercentChanged() { candidateCanvas.requestVisiblePaint() }
            function onCandidateScoreTitleModeChanged() { candidateCanvas.requestVisiblePaint() }
            function onCandidateRingVisibleChanged() { candidateCanvas.requestVisiblePaint() }
            function onCandidateRingLineWidthChanged() { candidateCanvas.requestVisiblePaint() }
            function onCandidateRankLabelVisibleChanged() { candidateCanvas.requestVisiblePaint() }
            function onCandidateFirstLabelTextColorChanged() { candidateCanvas.requestVisiblePaint() }
            function onCandidateLabelTextColorChanged() { candidateCanvas.requestVisiblePaint() }
            function onCoordinateFontFamilyChanged() { candidateCanvas.requestVisiblePaint() }
            function onCompactLayoutChanged() { candidateCanvas.requestVisiblePaint() }
        }
    }

    onVariationPreviewActiveChanged: {
        boardCanvas.requestPaint()
        candidateCanvas.requestVisiblePaint()
    }

    Canvas {
        id: variationPreviewCanvas
        anchors.fill: parent
        visible: boardScene.variationPreviewActive

        function requestVisiblePaint() {
            if (visible)
                requestPaint()
        }

        onPaint: {
            if (!visible)
                return

            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var activeCandidate = app.activeCandidateForVariationPreview()
            var variation = app.activeCandidateVariationItems()
            if (!variation || variation.length <= 0)
                return

            var cell = boardScene.cellSize
            var stoneRadius = Math.max(8, cell * app.stoneScale * 0.5)
            var previewRadius = stoneRadius * 0.92
            var previewState = boardScene.rendererState()
            var previewGeometry = boardScene.rendererGeometry()

            for (var i = 0; i < variation.length; ++i) {
                var move = variation[i]
                var point = boardScene.boardPointLocal(move.x, move.y)
                var previewOpacity = Number(app.candidateVariationPreviewOpacity)
                if (isNaN(previewOpacity))
                    previewOpacity = app.defaultCandidateVariationPreviewOpacity
                if (move.kind === "arrow") {
                    point = boardCanvas.drawVariationArrow(ctx, move, previewRadius, previewOpacity)
                } else if (app.ruleUsesDotsAndBoxes()) {
                    ctx.save()
                    ctx.globalAlpha = Math.max(0, Math.min(1, previewOpacity))
                    BoardRenderer.drawDotsAndBoxesPosition(ctx, previewState, previewGeometry, [move])
                    ctx.restore()
                } else {
                    ctx.save()
                    ctx.globalAlpha = Math.max(0, Math.min(1, previewOpacity))
                    BoardRenderer.drawStone(ctx, previewState, previewGeometry,
                                            move.x, move.y, move.player, previewRadius)
                    ctx.restore()
                }

                if (i === 0 && activeCandidate) {
                    var labelPoint = boardScene.boardPointLocal(activeCandidate.x, activeCandidate.y)
                    var activeCandidateLines = activeCandidate.labelLines || []
                    if (activeCandidateLines.length <= 0)
                        activeCandidateLines = app.candidateLabelLines(activeCandidate)
                    ctx.save()
                    if (app.ruleUsesDotsAndBoxes()) {
                        app.drawCandidateMarker(ctx, labelPoint.x, labelPoint.y, previewRadius,
                                                activeCandidateLines, {
                                                    "fillColor": "#ffffff",
                                                    "fillOpacity": 0.88,
                                                    "drawOutline": true,
                                                    "outlineOpacity": 1,
                                                    "textColor": "#111111"
                                                })
                    } else {
                        app.drawCandidateLabelLines(ctx,
                                                    activeCandidateLines,
                                                    labelPoint.x,
                                                    labelPoint.y,
                                                    previewRadius,
                                                    move.player === 1 ? "#ffffff" : "#000000")
                    }
                    ctx.restore()
                    continue
                }

                var text = String(move.moveNumber)
                var size = app.stoneNumberFontSize(ctx, text, previewRadius)
                boardCanvas.drawCenteredText(ctx,
                                             text,
                                             point.x,
                                             point.y + app.stoneNumberOffsetY(size),
                                             app.stoneNumberColor(move.player, false),
                                             size,
                                             true,
                                             app.stoneNumberMaxWidth(previewRadius))
            }
        }

        onVisibleChanged: requestVisiblePaint()
        onWidthChanged: requestVisiblePaint()
        onHeightChanged: requestVisiblePaint()

        Connections {
            target: app
            function onCandidateVariationPreviewVisibleChanged() { variationPreviewCanvas.requestVisiblePaint() }
            function onCandidateVariationPreviewMaxMovesChanged() { variationPreviewCanvas.requestVisiblePaint() }
            function onCandidateVariationPreviewOpacityChanged() { variationPreviewCanvas.requestVisiblePaint() }
            function onHoverKeyChanged() { variationPreviewCanvas.requestVisiblePaint() }
            function onSelectedPointLockedChanged() { variationPreviewCanvas.requestVisiblePaint() }
            function onSelectedPointFromCandidateListChanged() { variationPreviewCanvas.requestVisiblePaint() }
            function onEngineCandidateItemsChanged() { variationPreviewCanvas.requestVisiblePaint() }
            function onBoardRevisionChanged() { variationPreviewCanvas.requestVisiblePaint() }
            function onGameRuleModeChanged() { variationPreviewCanvas.requestVisiblePaint() }
            function onBoardPresentationModeChanged() { variationPreviewCanvas.requestVisiblePaint() }
            function onHexBoardStyleChanged() { variationPreviewCanvas.requestVisiblePaint() }
            function onHexBoardRotationChanged() { variationPreviewCanvas.requestVisiblePaint() }
            function onBoardSizeXChanged() { variationPreviewCanvas.requestVisiblePaint() }
            function onBoardSizeYChanged() { variationPreviewCanvas.requestVisiblePaint() }
            function onStoneScaleChanged() { variationPreviewCanvas.requestVisiblePaint() }
            function onMoveNumberDisplayModeChanged() { variationPreviewCanvas.requestVisiblePaint() }
            function onMoveNumberLabelScaleChanged() { variationPreviewCanvas.requestVisiblePaint() }
            function onCoordinateDisplayModeChanged() { variationPreviewCanvas.requestVisiblePaint() }
            function onCoordinateFontFamilyChanged() { variationPreviewCanvas.requestVisiblePaint() }
            function onCandidateWinrateOffsetYChanged() { variationPreviewCanvas.requestVisiblePaint() }
            function onCandidateVisitsOffsetYChanged() { variationPreviewCanvas.requestVisiblePaint() }
            function onCandidateScoreOffsetYChanged() { variationPreviewCanvas.requestVisiblePaint() }
            function onCompactLayoutChanged() { variationPreviewCanvas.requestVisiblePaint() }
        }
    }

    Canvas {
        id: hoverOverlayCanvas
        anchors.fill: parent
        visible: boardScene.hoverCandidateActive

        function requestVisiblePaint() {
            if (visible)
                requestPaint()
        }

        onPaint: {
            if (!visible)
                return

            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            if (app.hoverKey === "" || !app.pointIsEngineCandidateKey(app.hoverKey))
                return

            var candidate = app.engineCandidateItemMap[app.hoverKey]
            if (!candidate)
                return

            var cell = boardScene.cellSize
            var stoneRadius = Math.max(8, cell * app.stoneScale * 0.5)
            var cp = boardScene.boardPointLocal(candidate.x, candidate.y)
            var isFirstCandidate = candidate.displayIndex === 1
            var candidateLines = candidate.labelLines || []
            if (candidateLines.length <= 0)
                candidateLines = app.candidateLabelLines(candidate)

            if (!boardScene.variationPreviewActive && (!candidate.qualified || !candidate.boardVisible)) {
                var markerOptions = {
                    "drawBackground": !candidate.boardVisible,
                    "fillColor": candidate.color || app.candidateMarkerColor(candidate.displayIndex,
                                                                              candidate.visitRatio),
                    "fillOpacity": candidate.opacity,
                    "drawOutline": !candidate.boardVisible && !isFirstCandidate,
                    "outlineOpacity": candidate.outlineOpacity,
                    "drawRing": false,
                    "textColor": isFirstCandidate ? app.candidateFirstLabelTextColor : "",
                    "rankText": !candidate.boardVisible ? app.candidateRankLabelText(candidate.displayIndex) : ""
                }
                if (candidateLines.length <= 0) {
                    markerOptions.fallbackText = String(candidate.displayIndex)
                    markerOptions.fallbackColor = isFirstCandidate ? app.candidateFirstLabelTextColor : "#104f29"
                    markerOptions.fallbackFontSize = Math.max(10, Math.min(16, cell * 0.20))
                }
                app.drawCandidateMarker(ctx, cp.x, cp.y, stoneRadius, candidateLines, markerOptions)
            }

            ctx.save()
            ctx.globalAlpha = 1
            ctx.strokeStyle = "#ff1010"
            ctx.lineWidth = app.candidateRingLineWidthForRadius(stoneRadius)
            ctx.beginPath()
            ctx.arc(cp.x, cp.y, app.candidateRingRadius(stoneRadius), 0, Math.PI * 2)
            ctx.stroke()
            ctx.restore()
        }

        onVisibleChanged: requestVisiblePaint()
        onWidthChanged: requestVisiblePaint()
        onHeightChanged: requestVisiblePaint()

        Connections {
            target: app
            function onHoverKeyChanged() { hoverOverlayCanvas.requestVisiblePaint() }
            function onSelectedPointLockedChanged() { hoverOverlayCanvas.requestVisiblePaint() }
            function onSelectedPointFromCandidateListChanged() { hoverOverlayCanvas.requestVisiblePaint() }
            function onEngineCandidateItemsChanged() { hoverOverlayCanvas.requestVisiblePaint() }
            function onBoardRevisionChanged() { hoverOverlayCanvas.requestVisiblePaint() }
            function onGameRuleModeChanged() { hoverOverlayCanvas.requestVisiblePaint() }
            function onBoardPresentationModeChanged() { hoverOverlayCanvas.requestVisiblePaint() }
            function onHexBoardStyleChanged() { hoverOverlayCanvas.requestVisiblePaint() }
            function onHexBoardRotationChanged() { hoverOverlayCanvas.requestVisiblePaint() }
            function onBoardSizeXChanged() { hoverOverlayCanvas.requestVisiblePaint() }
            function onBoardSizeYChanged() { hoverOverlayCanvas.requestVisiblePaint() }
            function onStoneScaleChanged() { hoverOverlayCanvas.requestVisiblePaint() }
            function onCoordinateDisplayModeChanged() { hoverOverlayCanvas.requestVisiblePaint() }
            function onCandidateWinrateOffsetYChanged() { hoverOverlayCanvas.requestVisiblePaint() }
            function onCandidateVisitsOffsetYChanged() { hoverOverlayCanvas.requestVisiblePaint() }
            function onCandidateScoreOffsetYChanged() { hoverOverlayCanvas.requestVisiblePaint() }
            function onCandidateRingLineWidthChanged() { hoverOverlayCanvas.requestVisiblePaint() }
            function onCandidateRankLabelVisibleChanged() { hoverOverlayCanvas.requestVisiblePaint() }
            function onCandidateFirstLabelTextColorChanged() { hoverOverlayCanvas.requestVisiblePaint() }
            function onCoordinateFontFamilyChanged() { hoverOverlayCanvas.requestVisiblePaint() }
            function onCompactLayoutChanged() { hoverOverlayCanvas.requestVisiblePaint() }
        }
    }
}
