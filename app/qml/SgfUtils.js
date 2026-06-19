.pragma library

function keyFor(x, y) {
    return x + "," + y
}

function passKey() {
    return "pass"
}

function sgfEscape(value) {
    return String(value)
        .replace(/\\/g, "\\\\")
        .replace(/\]/g, "\\]")
        .replace(/\r?\n/g, "\\n")
}

var SGF_COORDINATE_ALPHABET = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

function useNumericSgfCoordinates(xSize, ySize) {
    return xSize > SGF_COORDINATE_ALPHABET.length || ySize > SGF_COORDINATE_ALPHABET.length
}

function sgfCoordinateText(x, y, numeric) {
    if (numeric === true
            || x >= SGF_COORDINATE_ALPHABET.length
            || y >= SGF_COORDINATE_ALPHABET.length)
        return x + "," + y
    return SGF_COORDINATE_ALPHABET.charAt(x) + SGF_COORDINATE_ALPHABET.charAt(y)
}

function parseSgfCoordinateText(value) {
    var coordinate = String(value).trim()
    if (coordinate.length === 0 || coordinate.toLowerCase() === "pass")
        return { "ok": true, "x": -1, "y": -1, "isPass": true }

    var numeric = coordinate.match(/^\(?\s*(\d+)\s*[,: ]\s*(\d+)\s*\)?$/)
    if (numeric) {
        return {
            "ok": true,
            "x": parseInt(numeric[1], 10),
            "y": parseInt(numeric[2], 10),
            "isPass": false
        }
    }

    if (coordinate.length < 2)
        return { "ok": false }

    var x = SGF_COORDINATE_ALPHABET.indexOf(coordinate.charAt(0))
    var y = SGF_COORDINATE_ALPHABET.indexOf(coordinate.charAt(1))
    if (x < 0 || y < 0)
        return { "ok": false }
    return { "ok": true, "x": x, "y": y, "isPass": false }
}

function sgfMoveNode(node, numericCoordinates) {
    var color = node.player === 1 ? "B" : "W"
    var coordinate = node.isPass ? "" : sgfCoordinateText(node.x, node.y, numericCoordinates)
    return color + "[" + coordinate + "]MN[" + node.moveNumber + "]"
}

function sgfSubtree(nodes, id, numericCoordinates) {
    var node = nodes[id]
    if (!node)
        return ""

    var text = "(;" + sgfMoveNode(node, numericCoordinates)
    var children = node.children || []
    for (var i = 0; i < children.length; ++i)
        text += sgfSubtree(nodes, children[i], numericCoordinates)
    return text + ")"
}

function boardSizeText(xSize, ySize) {
    return xSize === ySize ? String(xSize) : xSize + ":" + ySize
}

function sgfGameInfo(ruleMode) {
    if (ruleMode === 0)
        return { "gameId": 1, "ruleName": "QLizzie-Go" }
    if (ruleMode === 1)
        return { "gameId": 4, "ruleName": "QLizzie-Gomoku" }
    if (ruleMode === 2)
        return { "gameId": 11, "ruleName": "QLizzie-Hex" }
    if (ruleMode === 5)
        return { "gameId": 4, "ruleName": "QLizzie-Connect6" }
    if (ruleMode === 6)
        return { "gameId": 1, "ruleName": "QLizzie-HexGo-Parallelogram" }
    if (ruleMode === 7)
        return { "gameId": 1, "ruleName": "QLizzie-HexGo-Hexagon" }
    if (ruleMode === 8)
        return { "gameId": 1, "ruleName": "QLizzie-HexGo-Triangle" }
    if (ruleMode === 11)
        return { "gameId": 1, "ruleName": "QLizzie-TorusGo" }
    if (ruleMode === 4)
        return { "gameId": 2, "ruleName": "QLizzie-Reversi" }
    if (ruleMode === 9)
        return { "gameId": 10, "ruleName": "QLizzie-Ataxx" }
    return { "gameId": 0, "ruleName": "QLizzie-Custom" }
}

function buildSgf(nodes, ruleMode, xSize, ySize, ruleText) {
    var gameInfo = sgfGameInfo(ruleMode)
    var numericCoordinates = useNumericSgfCoordinates(xSize, ySize)
    var text = "(;FF[4]GM[" + gameInfo.gameId + "]CA[UTF-8]AP[QLizzie]RU[" + sgfEscape(gameInfo.ruleName) + "]"
               + "SZ[" + boardSizeText(xSize, ySize) + "]"
               + "C[" + sgfEscape("QLizzie " + ruleText) + "]"
    var rootNode = nodes[0]
    var children = rootNode ? (rootNode.children || []) : []
    for (var i = 0; i < children.length; ++i)
        text += sgfSubtree(nodes, children[i], numericCoordinates)
    return text + ")\n"
}

function firstSgfValue(properties, key) {
    var values = properties[key]
    return values && values.length > 0 ? values[0] : ""
}

function parseSgfBoardSize(value) {
    var parts = String(value).split(":")
    if (parts.length !== 1 && parts.length !== 2)
        return { "ok": false }

    var x = parseInt(parts[0], 10)
    var y = parts.length === 1 ? x : parseInt(parts[1], 10)
    if (isNaN(x) || isNaN(y))
        return { "ok": false }
    return { "ok": true, "x": x, "y": y }
}

function parseSgf(text, options) {
    var sgf = String(text)
    var pos = 0
    var minBoardSize = options.minBoardSize
    var maxBoardSize = options.maxBoardSize
    var gameRuleGo = options.gameRuleGo
    var gameRuleGomoku = options.gameRuleGomoku
    var gameRuleHex = options.gameRuleHex
    var ignoreRuleMode = options.ignoreRuleMode === true
    var parsedBoardSizeX = 19
    var parsedBoardSizeY = 19
    var parsedRuleMode = options.defaultRuleMode
    var parsedGameId = ""
    var maxX = -1
    var maxY = -1
    var parseError = ""
    var nodes = [{
        "id": 0, "parent": -1, "children": [], "x": -1, "y": -1,
        "key": "", "player": 0, "moveNumber": 0, "isPass": false,
        "koLocKey": "", "koLocX": -1, "koLocY": -1,
        "blackCaptures": 0, "whiteCaptures": 0,
        "analysisBlackWinrate": -1,
        "analysisCandidates": [],
        "analysisCandidateBoardSignature": "",
        "analysisCandidateKomiSignature": ""
    }]
    var nextId = 1

    function fail(message) {
        if (parseError === "")
            parseError = message
    }

    function skipWhitespace() {
        while (pos < sgf.length && /\s/.test(sgf.charAt(pos)))
            pos += 1
    }

    function isPropertyCharacter(ch) {
        return /[A-Za-z]/.test(ch)
    }

    function parseIdentifier() {
        var start = pos
        while (pos < sgf.length && isPropertyCharacter(sgf.charAt(pos)))
            pos += 1
        return sgf.substring(start, pos).toUpperCase()
    }

    function parsePropertyValue() {
        if (sgf.charAt(pos) !== "[") {
            fail("Expected property value.")
            return ""
        }

        pos += 1
        var value = ""
        while (pos < sgf.length) {
            var ch = sgf.charAt(pos)
            pos += 1

            if (ch === "\\") {
                if (pos >= sgf.length)
                    break
                var escaped = sgf.charAt(pos)
                pos += 1
                if (escaped === "\r") {
                    if (sgf.charAt(pos) === "\n")
                        pos += 1
                } else if (escaped !== "\n") {
                    value += escaped
                }
            } else if (ch === "]") {
                return value
            } else {
                value += ch
            }
        }

        fail("Unclosed property value.")
        return value
    }

    function parseNodeProperties() {
        var properties = ({})
        while (pos < sgf.length && parseError === "") {
            skipWhitespace()
            if (!isPropertyCharacter(sgf.charAt(pos)))
                break

            var key = parseIdentifier()
            var values = []
            skipWhitespace()
            while (sgf.charAt(pos) === "[" && parseError === "") {
                values.push(parsePropertyValue())
                skipWhitespace()
            }

            if (values.length === 0) {
                fail("Missing value for property " + key + ".")
                return properties
            }
            properties[key] = (properties[key] || []).concat(values)
        }
        return properties
    }

    function updateSizeFromProperties(properties) {
        var sizeValue = firstSgfValue(properties, "SZ")
        if (sizeValue === "")
            return

        var size = parseSgfBoardSize(sizeValue)
        if (!size.ok || size.x < minBoardSize || size.x > maxBoardSize
                || size.y < minBoardSize || size.y > maxBoardSize) {
            fail("Unsupported board size: " + sizeValue + ".")
            return
        }
        parsedBoardSizeX = size.x
        parsedBoardSizeY = size.y
    }

    function updateGameIdFromProperties(properties) {
        parsedGameId = firstSgfValue(properties, "GM").trim()
    }

    function updateRuleFromProperties(properties) {
        var gmValue = firstSgfValue(properties, "GM")
        var ruValue = firstSgfValue(properties, "RU").toUpperCase()
        if (ruValue.indexOf("GOMOKU") >= 0) {
            parsedRuleMode = gameRuleGomoku
            return
        }
        if (ruValue.indexOf("HEX") >= 0) {
            parsedRuleMode = gameRuleHex
            return
        }
        if (ruValue.indexOf("GO") >= 0) {
            parsedRuleMode = gameRuleGo
            return
        }
        if (gmValue === "1")
            parsedRuleMode = gameRuleGo
        else if (gmValue === "4")
            parsedRuleMode = gameRuleGomoku
        else if (gmValue === "11")
            parsedRuleMode = gameRuleHex
    }

    function moveFromProperties(properties) {
        var value = ""
        var player = 0
        if (properties["B"] && properties["B"].length > 0) {
            value = properties["B"][0]
            player = 1
        } else if (properties["W"] && properties["W"].length > 0) {
            value = properties["W"][0]
            player = 2
        } else {
            return null
        }

        var point = parseSgfCoordinateText(value)
        if (!point.ok) {
            fail("Expected coordinate: " + value + ".")
            return null
        }

        if (point.isPass)
            return { "x": -1, "y": -1, "player": player, "isPass": true }

        var x = point.x
        var y = point.y
        maxX = Math.max(maxX, x)
        maxY = Math.max(maxY, y)
        return { "x": x, "y": y, "player": player, "isPass": false }
    }

    function parseSequence(parentId) {
        var currentParent = parentId
        var lastId = parentId
        while (pos < sgf.length && parseError === "") {
            skipWhitespace()
            var ch = sgf.charAt(pos)
            if (ch === ";") {
                pos += 1
                var props = parseNodeProperties()
                if (currentParent === 0 && lastId === 0) {
                    updateSizeFromProperties(props)
                    updateGameIdFromProperties(props)
                    if (!ignoreRuleMode)
                        updateRuleFromProperties(props)
                }
                var move = moveFromProperties(props)
                if (!move)
                    continue

                var id = nextId++
                var moveNumberValue = parseInt(firstSgfValue(props, "MN"), 10)
                var parentNode = nodes[currentParent]
                var moveNumber = isNaN(moveNumberValue)
                                 ? (parentNode ? parentNode.moveNumber + 1 : 1)
                                 : moveNumberValue
                var key = move.isPass ? passKey() : keyFor(move.x, move.y)
                nodes[id] = {
                    "id": id,
                    "parent": currentParent,
                    "children": [],
                    "x": move.x,
                    "y": move.y,
                    "key": key,
                    "player": move.player,
                    "moveNumber": moveNumber,
                    "isPass": move.isPass,
                    "koLocKey": "",
                    "koLocX": -1,
                    "koLocY": -1,
                    "blackCaptures": 0,
                    "whiteCaptures": 0,
                    "analysisBlackWinrate": -1,
                    "analysisCandidates": [],
                    "analysisCandidateBoardSignature": "",
                    "analysisCandidateKomiSignature": ""
                }
                if (nodes[currentParent])
                    nodes[currentParent].children.push(id)
                currentParent = id
                lastId = id
            } else if (ch === "(") {
                pos += 1
                parseSequence(currentParent)
            } else if (ch === ")") {
                pos += 1
                return lastId
            } else {
                pos += 1
            }
        }
        return lastId
    }

    skipWhitespace()
    if (sgf.charAt(pos) === "(") {
        pos += 1
        parseSequence(0)
    } else {
        fail("Expected SGF tree.")
    }

    if (parseError !== "")
        return { "ok": false, "error": parseError }

    var targetBoardSizeX = Math.max(parsedBoardSizeX, maxX + 1)
    var targetBoardSizeY = Math.max(parsedBoardSizeY, maxY + 1)
    if (targetBoardSizeX < minBoardSize || targetBoardSizeX > maxBoardSize
            || targetBoardSizeY < minBoardSize || targetBoardSizeY > maxBoardSize)
        return { "ok": false, "error": "Unsupported board size." }

    return {
        "ok": true,
        "nodes": nodes,
        "nextNodeId": nextId,
        "ruleMode": parsedRuleMode,
        "gameId": parsedGameId,
        "boardSizeX": targetBoardSizeX,
        "boardSizeY": targetBoardSizeY
    }
}
