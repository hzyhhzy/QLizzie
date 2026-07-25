.pragma library

function applyPackageModeConstraints(app, restartIfChanged, engineController) {
    if (app.packageMode === app.packageModeGo) {
        app.gameRuleMode = app.gameRuleGo
        if (!app.boardDimensionsAllowedForPackage(app.boardSizeX, app.boardSizeY)) {
            app.boardSizeX = 19
            app.boardSizeY = 19
        }
    } else if (app.packageMode === app.packageModeSix) {
        app.gameRuleMode = app.gameRuleGomoku
        if (!app.boardDimensionsAllowedForPackage(app.boardSizeX, app.boardSizeY)) {
            app.boardSizeX = 15
            app.boardSizeY = 15
        }
    }
    app.normalizeGomokuRuleForCurrentMode()
    if (!app.activeEnginePreset())
        applyUniversalEngineCommand(app, restartIfChanged, engineController)
}

function applyUniversalEngineCommand(app, restartIfChanged, engineController) {
    if (!engineController || app.packageMode !== app.packageModeUniversal)
        return
    var command = app.persistedEngineCommand
    if (command.length <= 0 || engineController.command === command)
        return
    engineController.command = command
    app.resetEngineSyncState()
    if (restartIfChanged && app.appReady && engineController.running)
        app.restartEngine()
}

function communicationLineFiltered(stream, line) {
    if (stream !== "stdout")
        return false
    return /^info\s+move\b/.test(String(line).trim())
}

function communicationColor(stream) {
    if (stream === "stdin")
        return "#7ee2a8"
    if (stream === "stderr")
        return "#ff8b7f"
    return "#d9e6ee"
}

function communicationStreamMask(stream) {
    if (stream === "stdin")
        return 1
    if (stream === "stderr")
        return 4
    return 2
}

function communicationRetainedCountName(stream) {
    if (stream === "stdin")
        return "stdinRetainedCount"
    if (stream === "stderr")
        return "stderrRetainedCount"
    return "stdoutRetainedCount"
}

function recountCommunicationState(model, bufferState) {
    if (!bufferState)
        return

    var characterCount = 0
    var stdinCount = 0
    var stdoutCount = 0
    var stderrCount = 0
    if (model) {
        for (var index = 0; index < model.count; ++index) {
            var entry = model.get(index)
            characterCount += communicationEntryCharacters(entry)
            if (entry.stream === "stdin")
                ++stdinCount
            else if (entry.stream === "stderr")
                ++stderrCount
            else
                ++stdoutCount
        }
    }
    bufferState.characterCount = characterCount
    bufferState.stdinRetainedCount = stdinCount
    bufferState.stdoutRetainedCount = stdoutCount
    bufferState.stderrRetainedCount = stderrCount
}

function ensureCommunicationState(model, bufferState) {
    if (!bufferState)
        return
    if (!model) {
        recountCommunicationState(null, bufferState)
        return
    }
    var characterCount = Number(bufferState.characterCount)
    var stdinCount = Number(bufferState.stdinRetainedCount)
    var stdoutCount = Number(bufferState.stdoutRetainedCount)
    var stderrCount = Number(bufferState.stderrRetainedCount)
    if (!isFinite(characterCount) || characterCount < 0
            || !isFinite(stdinCount) || stdinCount < 0
            || !isFinite(stdoutCount) || stdoutCount < 0
            || !isFinite(stderrCount) || stderrCount < 0
            || stdinCount + stdoutCount + stderrCount !== model.count)
        recountCommunicationState(model, bufferState)
}

function adjustCommunicationRetainedCount(bufferState, stream, delta) {
    if (!bufferState)
        return
    var name = communicationRetainedCountName(stream)
    bufferState[name] = Math.max(0, Number(bufferState[name]) + delta)
}

function positiveInteger(value, fallback) {
    var number = Math.floor(Number(value))
    return isFinite(number) && number > 0 ? number : fallback
}

function communicationEntryCharacters(entry) {
    if (!entry)
        return 0
    var stored = Number(entry.characterCount)
    if (isFinite(stored) && stored >= 0)
        return stored
    return String(entry.line || "").length + 1
}

function communicationCharacterCount(model) {
    if (!model)
        return 0
    var total = 0
    for (var index = 0; index < model.count; ++index)
        total += communicationEntryCharacters(model.get(index))
    return total
}

function truncateCommunicationLine(line, limit) {
    var text = String(line)
    var maximum = positiveInteger(limit, 16384)
    if (text.length <= maximum)
        return text

    var marker = "\n... [line truncated] ...\n"
    var available = Math.max(0, maximum - marker.length)
    var headLength = Math.ceil(available * 0.75)
    var tailLength = available - headLength
    var headEnd = headLength
    if (headEnd > 0 && headEnd < text.length
            && text.charCodeAt(headEnd - 1) >= 0xD800
            && text.charCodeAt(headEnd - 1) <= 0xDBFF
            && text.charCodeAt(headEnd) >= 0xDC00
            && text.charCodeAt(headEnd) <= 0xDFFF)
        headEnd -= 1
    var tailStart = text.length - tailLength
    if (tailStart > 0 && tailStart < text.length
            && text.charCodeAt(tailStart) >= 0xDC00
            && text.charCodeAt(tailStart) <= 0xDFFF
            && text.charCodeAt(tailStart - 1) >= 0xD800
            && text.charCodeAt(tailStart - 1) <= 0xDBFF)
        tailStart += 1
    return text.slice(0, headEnd) + marker
            + (tailLength > 0 ? text.slice(tailStart) : "")
}

function enforceCommunicationLimits(model, lineLimit, characterLimit,
                                    lineCharacterLimit, bufferState) {
    if (!model)
        return false
    ensureCommunicationState(model, bufferState)

    var maximumLines = positiveInteger(lineLimit, 1000)
    var maximumCharacters = positiveInteger(characterLimit, 262144)
    var maximumLineCharacters = Math.min(
                positiveInteger(lineCharacterLimit, 16384),
                Math.max(1, maximumCharacters - 1))
    var totalCharacters = 0
    var changed = false
    var changeMask = 0

    for (var index = 0; index < model.count; ++index) {
        var entry = model.get(index)
        var text = truncateCommunicationLine(entry.line, maximumLineCharacters)
        var entryCharacters = text.length + 1
        totalCharacters += entryCharacters
        if (text !== String(entry.line)) {
            model.setProperty(index, "line", text)
            changed = true
            changeMask |= communicationStreamMask(entry.stream)
        }
        if (Number(entry.characterCount) !== entryCharacters) {
            model.setProperty(index, "characterCount", entryCharacters)
            changed = true
        }
    }

    while (model.count > maximumLines
           || totalCharacters > maximumCharacters) {
        var removedEntry = model.get(0)
        totalCharacters -= communicationEntryCharacters(removedEntry)
        changeMask |= communicationStreamMask(removedEntry.stream)
        model.remove(0)
        changed = true
    }

    totalCharacters = Math.max(0, totalCharacters)
    if (bufferState) {
        recountCommunicationState(model, bufferState)
        bufferState.characterCount = totalCharacters
        bufferState.lastChangeMask = changeMask
    }
    return changed
}

function appendCommunication(model, stream, line, lineLimit, characterLimit,
                             lineCharacterLimit, bufferState) {
    if (!model)
        return false
    if (communicationLineFiltered(stream, line))
        return false
    ensureCommunicationState(model, bufferState)

    var maximumLines = positiveInteger(lineLimit, 1000)
    var maximumCharacters = positiveInteger(characterLimit, 262144)
    var maximumLineCharacters = Math.min(
                positiveInteger(lineCharacterLimit, 16384),
                Math.max(1, maximumCharacters - 1))
    var text = truncateCommunicationLine(line, maximumLineCharacters)
    var entryCharacters = text.length + 1
    var totalCharacters = bufferState
            && isFinite(Number(bufferState.characterCount))
            ? Math.max(0, Number(bufferState.characterCount))
            : communicationCharacterCount(model)
    var changeMask = communicationStreamMask(stream)

    while (model.count > 0
           && (model.count >= maximumLines
               || totalCharacters + entryCharacters > maximumCharacters)) {
        var removedEntry = model.get(0)
        totalCharacters -= communicationEntryCharacters(removedEntry)
        changeMask |= communicationStreamMask(removedEntry.stream)
        adjustCommunicationRetainedCount(bufferState, removedEntry.stream, -1)
        model.remove(0)
    }

    model.append({
        "stream": stream,
        "line": text,
        "color": communicationColor(stream),
        "characterCount": entryCharacters
    })
    totalCharacters = Math.max(0, totalCharacters) + entryCharacters
    if (bufferState) {
        bufferState.characterCount = totalCharacters
        adjustCommunicationRetainedCount(bufferState, stream, 1)
        bufferState.lastChangeMask = changeMask
    }
    return true
}

function clearCommunication(model, bufferState) {
    ensureCommunicationState(model, bufferState)
    var changeMask = 0
    if (bufferState) {
        if (Number(bufferState.stdinRetainedCount) > 0)
            changeMask |= 1
        if (Number(bufferState.stdoutRetainedCount) > 0)
            changeMask |= 2
        if (Number(bufferState.stderrRetainedCount) > 0)
            changeMask |= 4
    } else if (model && model.count > 0) {
        changeMask = 7
    }
    if (model)
        model.clear()
    if (bufferState) {
        bufferState.characterCount = 0
        bufferState.stdinRetainedCount = 0
        bufferState.stdoutRetainedCount = 0
        bufferState.stderrRetainedCount = 0
        bufferState.lastChangeMask = changeMask
    }
}
