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
    return color + "[" + coordinate + "]MN[" + node.moveNumber + "]" + sgfAnalysisProperties(node)
}

function candidateNumberValue(value, fallback) {
    var number = Number(value)
    return isNaN(number) ? fallback : number
}

function candidateStringValue(value) {
    if (value === undefined || value === null)
        return ""
    return String(value)
}

function serializableCandidate(candidate) {
    if (!candidate || candidate.move === undefined)
        return null

    var item = { "move": candidateStringValue(candidate.move) }
    if (candidate.order !== undefined)
        item.order = candidateNumberValue(candidate.order, 0)
    if (candidate.visits !== undefined)
        item.visits = candidateNumberValue(candidate.visits, 0)
    if (candidate.winrate !== undefined)
        item.winrate = candidateNumberValue(candidate.winrate, 0)
    if (candidate.scoreMean !== undefined)
        item.scoreMean = candidateNumberValue(candidate.scoreMean, 0)
    if (candidate.scoreStdev !== undefined)
        item.scoreStdev = candidateNumberValue(candidate.scoreStdev, 0)
    if (candidate.pv && candidate.pv.length !== undefined) {
        var pv = []
        for (var i = 0; i < candidate.pv.length; ++i) {
            var move = candidateStringValue(candidate.pv[i]).trim()
            if (move.length > 0)
                pv.push(move)
        }
        if (pv.length > 0)
            item.pv = pv
    }
    if (candidate.pvVisits && candidate.pvVisits.length !== undefined) {
        var pvVisits = []
        for (var p = 0; p < candidate.pvVisits.length; ++p) {
            var visits = candidateNumberValue(candidate.pvVisits[p], NaN)
            if (!isNaN(visits))
                pvVisits.push(visits)
        }
        if (pvVisits.length > 0)
            item.pvVisits = pvVisits
    }
    return item
}

function analysisPayloadForNode(node) {
    if (!node || !node.analysisCandidates || node.analysisCandidates.length <= 0)
        return null

    var candidates = []
    for (var i = 0; i < node.analysisCandidates.length; ++i) {
        var candidate = serializableCandidate(node.analysisCandidates[i])
        if (candidate)
            candidates.push(candidate)
    }
    if (candidates.length <= 0)
        return null

    return {
        "version": 1,
        "blackWinrate": node.analysisBlackWinrate === undefined ? -1 : Number(node.analysisBlackWinrate),
        "boardSignature": candidateStringValue(node.analysisCandidateBoardSignature),
        "komiSignature": candidateStringValue(node.analysisCandidateKomiSignature),
        "candidates": candidates
    }
}

function sgfAnalysisProperties(node) {
    var payload = analysisPayloadForNode(node)
    if (!payload)
        return ""
    return "QLZ[" + sgfEscape(JSON.stringify(payload)) + "]"
}

function sgfNodeSequence(nodes, id, numericCoordinates) {
    var node = nodes[id]
    if (!node)
        return ""

    var text = ";" + sgfMoveNode(node, numericCoordinates)
    var children = node.children || []
    if (children.length === 1) {
        text += sgfNodeSequence(nodes, children[0], numericCoordinates)
    } else {
        for (var i = 0; i < children.length; ++i)
            text += "(" + sgfNodeSequence(nodes, children[i], numericCoordinates) + ")"
    }
    return text
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
    if (ruleMode === 12)
        return { "gameId": 1, "ruleName": "QLizzie-TwoLibGo" }
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
    text += sgfAnalysisProperties(rootNode)
    var children = rootNode ? (rootNode.children || []) : []
    if (children.length === 1) {
        text += sgfNodeSequence(nodes, children[0], numericCoordinates)
    } else {
        for (var i = 0; i < children.length; ++i)
            text += "(" + sgfNodeSequence(nodes, children[i], numericCoordinates) + ")"
    }
    return text + ")\n"
}

function firstSgfValue(properties, key) {
    var values = properties[key]
    return values && values.length > 0 ? values[0] : ""
}

function parseVisitNumber(value) {
    var text = String(value).trim().toLowerCase()
    if (text.length <= 0)
        return NaN
    var factor = 1
    var suffix = text.charAt(text.length - 1)
    if (suffix === "k" || suffix === "m" || suffix === "g") {
        text = text.substring(0, text.length - 1)
        factor = suffix === "k" ? 1000 : suffix === "m" ? 1000000 : 1000000000
    }
    var number = Number(text)
    return isNaN(number) ? NaN : number * factor
}

function normalizeSavedWinrate(value) {
    var number = Number(value)
    if (isNaN(number))
        return NaN
    if (Math.abs(number) > 100)
        return number / 10000
    if (Math.abs(number) > 1)
        return number / 100
    return number
}

function normalizedCandidate(candidate, orderFallback) {
    if (!candidate || candidate.move === undefined)
        return null
    var move = candidateStringValue(candidate.move).trim()
    if (move.length <= 0)
        return null

    var item = { "move": move }
    var order = candidateNumberValue(candidate.order, orderFallback)
    item.order = isNaN(order) ? orderFallback : order

    if (candidate.visits !== undefined) {
        var visits = parseVisitNumber(candidate.visits)
        if (!isNaN(visits))
            item.visits = visits
    }
    if (candidate.winrate !== undefined) {
        var winrate = normalizeSavedWinrate(candidate.winrate)
        if (!isNaN(winrate))
            item.winrate = winrate
    }
    if (candidate.scoreMean !== undefined || candidate.scoreLead !== undefined) {
        var scoreMean = candidateNumberValue(candidate.scoreMean !== undefined
                                             ? candidate.scoreMean : candidate.scoreLead, NaN)
        if (!isNaN(scoreMean))
            item.scoreMean = scoreMean
    }
    if (candidate.scoreStdev !== undefined) {
        var scoreStdev = candidateNumberValue(candidate.scoreStdev, NaN)
        if (!isNaN(scoreStdev))
            item.scoreStdev = scoreStdev
    }
    if (candidate.pv && candidate.pv.length !== undefined) {
        var pv = []
        for (var p = 0; p < candidate.pv.length; ++p) {
            var pvMove = candidateStringValue(candidate.pv[p]).trim()
            if (pvMove.length > 0)
                pv.push(pvMove)
        }
        if (pv.length > 0)
            item.pv = pv
    }
    if (candidate.pvVisits && candidate.pvVisits.length !== undefined) {
        var pvVisits = []
        for (var v = 0; v < candidate.pvVisits.length; ++v) {
            var pvVisit = parseVisitNumber(candidate.pvVisits[v])
            if (!isNaN(pvVisit))
                pvVisits.push(pvVisit)
        }
        if (pvVisits.length > 0)
            item.pvVisits = pvVisits
    }
    return item
}

function analysisFromPayload(payload) {
    if (!payload || !payload.candidates || payload.candidates.length === undefined)
        return null

    var candidates = []
    for (var i = 0; i < payload.candidates.length; ++i) {
        var candidate = normalizedCandidate(payload.candidates[i], i)
        if (candidate)
            candidates.push(candidate)
    }
    if (candidates.length <= 0)
        return null
    candidates.sort(function(left, right) {
        return candidateNumberValue(left.order, 0) - candidateNumberValue(right.order, 0)
    })

    return {
        "blackWinrate": candidateNumberValue(payload.blackWinrate, -1),
        "boardSignature": candidateStringValue(payload.boardSignature),
        "komiSignature": candidateStringValue(payload.komiSignature),
        "candidates": candidates
    }
}

function parseQlzAnalysis(value) {
    try {
        return analysisFromPayload(JSON.parse(String(value)))
    } catch (error) {
        return null
    }
}

function tokenizeAnalysisSegment(text) {
    var source = String(text)
    var tokens = []
    var pos = 0
    while (pos < source.length) {
        while (pos < source.length && /\s/.test(source.charAt(pos)))
            pos += 1
        if (pos >= source.length)
            break

        var start = pos
        if (source.charAt(pos) === "(") {
            while (pos < source.length) {
                var ch = source.charAt(pos++)
                if (ch === ")")
                    break
            }
        } else {
            while (pos < source.length && !/\s/.test(source.charAt(pos)))
                pos += 1
        }
        tokens.push(source.substring(start, pos))
    }
    return tokens
}

function parseLizzieCandidateSegment(segment, orderFallback) {
    var tokens = tokenizeAnalysisSegment(segment)
    if (tokens.length <= 0)
        return null

    var candidate = { "move": tokens[0], "order": orderFallback }
    var index = 1
    while (index < tokens.length) {
        var key = tokens[index++]
        if (key === "pv") {
            var pv = []
            while (index < tokens.length && tokens[index] !== "pvVisits") {
                var pvMove = String(tokens[index++]).trim()
                if (pvMove.length > 0)
                    pv.push(pvMove)
            }
            if (pv.length > 0)
                candidate.pv = pv
            continue
        }
        if (key === "pvVisits") {
            var pvVisits = []
            while (index < tokens.length) {
                var visits = parseVisitNumber(tokens[index++])
                if (!isNaN(visits))
                    pvVisits.push(visits)
            }
            if (pvVisits.length > 0)
                candidate.pvVisits = pvVisits
            continue
        }

        if (index >= tokens.length)
            break
        var value = tokens[index++]
        if (key === "order")
            candidate.order = candidateNumberValue(value, orderFallback)
        else if (key === "visits")
            candidate.visits = value
        else if (key === "winrate")
            candidate.winrate = value
        else if (key === "scoreMean" || key === "scoreLead")
            candidate.scoreMean = value
        else if (key === "scoreStdev")
            candidate.scoreStdev = value
    }
    return normalizedCandidate(candidate, orderFallback)
}

function parseLizzieYzyAnalysis(value) {
    var text = String(value).replace(/\r?\n/g, " ")
    var moveStart = text.search(/(^|\s)move\s+/)
    if (moveStart < 0)
        return null

    text = text.substring(moveStart).trim()
    if (text.indexOf("move ") === 0)
        text = text.substring(5)
    var segments = text.split(/\s+info\s+move\s+/)
    var candidates = []
    for (var i = 0; i < segments.length; ++i) {
        var candidate = parseLizzieCandidateSegment(segments[i], i)
        if (candidate)
            candidates.push(candidate)
    }
    if (candidates.length <= 0)
        return null
    candidates.sort(function(left, right) {
        return candidateNumberValue(left.order, 0) - candidateNumberValue(right.order, 0)
    })
    return {
        "blackWinrate": -1,
        "boardSignature": "",
        "komiSignature": "",
        "candidates": candidates
    }
}

function analysisFromProperties(properties) {
    var qlz = firstSgfValue(properties, "QLZ")
    if (qlz !== "") {
        var parsedQlz = parseQlzAnalysis(qlz)
        if (parsedQlz)
            return parsedQlz
    }

    var lz = firstSgfValue(properties, "LZ")
    return lz === "" ? null : parseLizzieYzyAnalysis(lz)
}

function applyAnalysisToNode(node, analysis) {
    if (!node || !analysis || !analysis.candidates || analysis.candidates.length <= 0)
        return
    node.analysisBlackWinrate = isNaN(Number(analysis.blackWinrate)) ? -1 : Number(analysis.blackWinrate)
    node.analysisCandidates = analysis.candidates
    node.analysisCandidateBoardSignature = candidateStringValue(analysis.boardSignature)
    node.analysisCandidateKomiSignature = candidateStringValue(analysis.komiSignature)
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
        "koLocKey2": "", "koLocX2": -1, "koLocY2": -1,
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
                    applyAnalysisToNode(nodes[0], analysisFromProperties(props))
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
                    "koLocKey2": "",
                    "koLocX2": -1,
                    "koLocY2": -1,
                    "blackCaptures": 0,
                    "whiteCaptures": 0,
                    "analysisBlackWinrate": -1,
                    "analysisCandidates": [],
                    "analysisCandidateBoardSignature": "",
                    "analysisCandidateKomiSignature": ""
                }
                applyAnalysisToNode(nodes[id], analysisFromProperties(props))
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
