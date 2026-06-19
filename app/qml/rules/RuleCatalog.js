.pragma library

function boardPresentationOptions(app, ruleMode) {
    if (ruleMode === app.gameRuleTorusGo) {
        return [
            {
                "label": app.trText("boardPresentationTorusEdge"),
                "value": app.boardPresentationTorusEdge,
                "tip": app.trText("boardPresentationTorusEdgeTip")
            },
            {
                "label": app.trText("boardPresentationTorusHalf"),
                "value": app.boardPresentationTorusHalf,
                "tip": app.trText("boardPresentationTorusHalfTip")
            },
            {
                "label": app.trText("boardPresentationTorusFull"),
                "value": app.boardPresentationTorusFull,
                "tip": app.trText("boardPresentationTorusFullTip")
            }
        ]
    }
    if (ruleMode === app.gameRuleGomoku) {
        return [
            {
                "label": app.trText("boardPresentationIntersections"),
                "value": app.boardPresentationIntersections,
                "tip": app.trText("boardPresentationIntersectionsTip")
            },
            {
                "label": app.trText("boardPresentationCells"),
                "value": app.boardPresentationCells,
                "tip": app.trText("boardPresentationCellsTip")
            }
        ]
    }
    if (ruleMode === app.gameRuleReversi
            || ruleMode === app.gameRuleAtaxx
            || ruleMode === app.gameRuleBreakthrough) {
        return [
            {
                "label": app.trText("boardPresentationCells"),
                "value": app.boardPresentationCells,
                "tip": app.trText("boardPresentationCellsTip")
            }
        ]
    }
    return [
        {
            "label": app.trText("boardPresentationIntersections"),
            "value": app.boardPresentationIntersections,
            "tip": app.trText("boardPresentationIntersectionsTip")
        }
    ]
}

function boardPresentationCurrentIndex(app) {
    var options = boardPresentationOptions(app, app.gameRuleMode)
    for (var i = 0; i < options.length; ++i) {
        if (options[i].value === app.boardPresentationMode)
            return i
    }
    return 0
}

function boardPresentationText(app, mode) {
    var options = boardPresentationOptions(app, app.gameRuleMode)
    for (var i = 0; i < options.length; ++i) {
        if (options[i].value === mode)
            return options[i].label
    }
    return options.length > 0 ? options[0].label : ""
}

function rememberedBoardPresentationMode(app, ruleMode) {
    if (ruleMode === app.gameRuleGomoku)
        return app.gomokuBoardPresentationMode
    if (ruleMode === app.gameRuleTorusGo)
        return app.torusGoBoardPresentationMode
    return app.boardPresentationIntersections
}

function normalizeBoardPresentationMode(app, ruleMode, value) {
    var options = boardPresentationOptions(app, ruleMode)
    for (var i = 0; i < options.length; ++i) {
        if (options[i].value === value)
            return value
    }
    return options.length > 0 ? options[0].value : app.boardPresentationIntersections
}

function hexBoardStyleOptions(app, ruleMode) {
    ruleMode = ruleMode === undefined ? app.gameRuleMode : ruleMode
    if (ruleMode !== app.gameRuleHex) {
        return [
            {
                "label": app.trText("hexBoardStyleTriangle"),
                "value": app.hexBoardStyleTriangle,
                "tip": app.trText("hexBoardStyleTriangleTip")
            }
        ]
    }
    return [
        {
            "label": app.trText("hexBoardStyleTriangle"),
            "value": app.hexBoardStyleTriangle,
            "tip": app.trText("hexBoardStyleTriangleTip")
        },
        {
            "label": app.trText("hexBoardStyleCells"),
            "value": app.hexBoardStyleCells,
            "tip": app.trText("hexBoardStyleCellsTip")
        }
    ]
}

function hexBoardStyleCurrentIndex(app) {
    var options = hexBoardStyleOptions(app)
    for (var i = 0; i < options.length; ++i) {
        if (options[i].value === app.hexBoardStyle)
            return i
    }
    return 0
}

function hexBoardRotationOptions(app, ruleMode) {
    ruleMode = ruleMode === undefined ? app.gameRuleMode : ruleMode
    if (ruleMode === app.gameRuleHexGoParallelogram) {
        return [
            { "label": app.trText("hexRotationCurrent"), "value": app.hexRotationCurrent, "tip": app.trText("hexRotationCurrentTip") },
            { "label": app.trText("hexRotationFlipX"), "value": app.hexRotationFlipX, "tip": app.trText("hexRotationFlipXTip") },
            { "label": app.trText("hexRotationHorizontal"), "value": app.hexRotationHorizontal, "tip": app.trText("hexRotationHorizontalTip") },
            { "label": app.trText("hexRotationVertical"), "value": app.hexRotationVertical, "tip": app.trText("hexRotationVerticalTip") }
        ]
    }
    if (ruleMode === app.gameRuleHexGoTriangle) {
        return [
            { "label": app.trText("hexRotationCurrent"), "value": app.hexRotationCurrent, "tip": app.trText("hexRotationCurrentTip") },
            { "label": app.trText("hexRotationMirror"), "value": app.hexRotationMirror, "tip": app.trText("hexRotationMirrorTip") }
        ]
    }
    if (ruleMode !== app.gameRuleHex)
        return [
            { "label": app.trText("hexRotationCurrent"), "value": app.hexRotationCurrent, "tip": app.trText("hexRotationCurrentTip") }
        ]
    return [
        {
            "label": app.trText("hexRotationCurrent"),
            "value": app.hexRotationCurrent,
            "tip": app.trText("hexRotationCurrentTip")
        },
        {
            "label": app.trText("hexRotationTranspose"),
            "value": app.hexRotationTranspose,
            "tip": app.trText("hexRotationTransposeTip")
        },
        {
            "label": app.trText("hexRotationFlipX"),
            "value": app.hexRotationFlipX,
            "tip": app.trText("hexRotationFlipXTip")
        },
        {
            "label": app.trText("hexRotationFlipXTranspose"),
            "value": app.hexRotationFlipXTranspose,
            "tip": app.trText("hexRotationFlipXTransposeTip")
        },
        {
            "label": app.trText("hexRotationHorizontal"),
            "value": app.hexRotationHorizontal,
            "tip": app.trText("hexRotationHorizontalTip")
        },
        {
            "label": app.trText("hexRotationHorizontalTranspose"),
            "value": app.hexRotationHorizontalTranspose,
            "tip": app.trText("hexRotationHorizontalTransposeTip")
        },
        {
            "label": app.trText("hexRotationVertical"),
            "value": app.hexRotationVertical,
            "tip": app.trText("hexRotationVerticalTip")
        },
        {
            "label": app.trText("hexRotationVerticalTranspose"),
            "value": app.hexRotationVerticalTranspose,
            "tip": app.trText("hexRotationVerticalTransposeTip")
        }
    ]
}

function hexBoardRotationCurrentIndex(app) {
    var options = hexBoardRotationOptions(app)
    for (var i = 0; i < options.length; ++i) {
        if (options[i].value === app.hexBoardRotation)
            return i
    }
    return 0
}
