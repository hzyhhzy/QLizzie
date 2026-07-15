.pragma library

var RULE_GO = 0
var RULE_GOMOKU = 1
var RULE_HEX = 2
var RULE_SQUARE_FREE = 3
var RULE_REVERSI = 4
var RULE_CONNECT6 = 5
var RULE_HEX_GO_PARALLELOGRAM = 6
var RULE_HEX_GO_HEXAGON = 7
var RULE_HEX_GO_TRIANGLE = 8
var RULE_ATAXX = 9
var RULE_BREAKTHROUGH = 10
var RULE_TORUS_GO = 11
var RULE_TWO_LIB_GO = 12
var RULE_DOTS_AND_BOXES = 13

var RULES = [
    rule(RULE_GO, "gameRuleGo", "gameRuleGoTip", 1, "QLizzie-Go",
         { "goCapture": true, "defaultVisible": true }),
    rule(RULE_GOMOKU, "gameRuleGomoku", "gameRuleGomokuTip", 4, "QLizzie-Gomoku",
         { "defaultVisible": true }),
    rule(RULE_HEX, "gameRuleHex", "gameRuleHexTip", 11, "QLizzie-Hex",
         { "hexGrid": true, "defaultVisible": true }),
    rule(RULE_SQUARE_FREE, "gameRuleSquareFree", "gameRuleSquareFreeTip", 0, "QLizzie-SquareFree",
         { "allowsOccupiedMoves": true }),
    rule(RULE_REVERSI, "gameRuleReversi", "gameRuleReversiTip", 2, "QLizzie-Reversi",
         { "squareCells": true }),
    rule(RULE_CONNECT6, "gameRuleConnect6", "gameRuleConnect6Tip", 4, "QLizzie-Connect6"),
    rule(RULE_HEX_GO_PARALLELOGRAM, "gameRuleHexGoParallelogram", "gameRuleHexGoParallelogramTip",
         1, "QLizzie-HexGo-Parallelogram", { "hexGrid": true, "goCapture": true }),
    rule(RULE_HEX_GO_HEXAGON, "gameRuleHexGoHexagon", "gameRuleHexGoHexagonTip",
         1, "QLizzie-HexGo-Hexagon", { "hexGrid": true, "goCapture": true }),
    rule(RULE_HEX_GO_TRIANGLE, "gameRuleHexGoTriangle", "gameRuleHexGoTriangleTip",
         1, "QLizzie-HexGo-Triangle", { "hexGrid": true, "goCapture": true }),
    rule(RULE_ATAXX, "gameRuleAtaxx", "gameRuleAtaxxTip", 10, "QLizzie-Ataxx",
         { "squareCells": true, "moveSource": true }),
    rule(RULE_BREAKTHROUGH, "gameRuleBreakthrough", "gameRuleBreakthroughTip", 0, "QLizzie-Breakthrough",
         { "squareCells": true, "moveSource": true }),
    rule(RULE_TORUS_GO, "gameRuleTorusGo", "gameRuleTorusGoTip", 1, "QLizzie-TorusGo",
         { "goCapture": true }),
    rule(RULE_TWO_LIB_GO, "gameRuleTwoLibGo", "gameRuleTwoLibGoTip", 1, "QLizzie-TwoLibGo",
         { "goCapture": true }),
    rule(RULE_DOTS_AND_BOXES, "gameRuleDotsAndBoxes", "gameRuleDotsAndBoxesTip", 40,
         "QLizzie-DotsAndBoxes", { "dotsAndBoxes": true })
]

var RULE_BY_ID = buildRuleMap(RULES)
var RULE_BY_SGF_NAME = buildSgfRuleMap(RULES)

function rule(id, textKey, tipKey, sgfGameId, sgfRuleName, capabilities) {
    return {
        "id": id,
        "textKey": textKey,
        "tipKey": tipKey,
        "sgfGameId": sgfGameId,
        "sgfRuleName": sgfRuleName,
        "capabilities": capabilities || {}
    }
}

function buildRuleMap(rules) {
    var map = {}
    for (var i = 0; i < rules.length; ++i)
        map[String(rules[i].id)] = rules[i]
    return map
}

function buildSgfRuleMap(rules) {
    var map = {}
    for (var i = 0; i < rules.length; ++i)
        map[rules[i].sgfRuleName.toUpperCase()] = rules[i]
    return map
}

function descriptor(mode) {
    return RULE_BY_ID[String(Number(mode))] || null
}

function descriptorForSgfRuleName(name) {
    return RULE_BY_SGF_NAME[String(name || "").trim().toUpperCase()] || null
}

function validMode(mode) {
    return descriptor(mode) !== null
}

function hasCapability(mode, capability) {
    var item = descriptor(mode)
    return !!item && item.capabilities[capability] === true
}

function allModes() {
    var modes = []
    for (var i = 0; i < RULES.length; ++i)
        modes.push(RULES[i].id)
    return modes
}
