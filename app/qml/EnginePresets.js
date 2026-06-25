.pragma library

function makePreset(id, name, command, ruleMode, ruleVariant, boardSizeX, boardSizeY, komi, legacyHex) {
    return {
        "id": id,
        "name": name,
        "command": command,
        "initialCommands": "",
        "ruleMode": ruleMode,
        "ruleVariant": ruleVariant,
        "boardSizeX": boardSizeX,
        "boardSizeY": boardSizeY,
        "komi": komi,
        "legacyHexEngineCoordinates": legacyHex === true,
        "boardPresentationMode": 0
    }
}

function defaultPresets(app) {
    return []
}

function fallbackPreset(app, index) {
    var ruleMode = defaultRuleMode(app)
    return makePreset("engine-" + (index + 1),
                      app.trText("newEngine"),
                      "",
                      ruleMode,
                      -1,
                      19,
                      19,
                      defaultKomiForRule(app, ruleMode),
                      false)
}

function clonePreset(preset) {
    var copy = ({})
    for (var key in preset)
        copy[key] = preset[key]
    return copy
}

function cloneList(presets) {
    var list = []
    if (!presets)
        return list
    for (var i = 0; i < presets.length; ++i)
        list.push(clonePreset(presets[i]))
    return list
}

function numeric(value, fallback) {
    var number = Number(value)
    return isNaN(number) ? fallback : number
}

function defaultGoRules(app) {
    return {
        "scoringRule": app.goScoringArea,
        "koRule": app.goKoPositional,
        "suicideAllowed": true,
        "taxRule": app.goTaxNone,
        "handicapBonus": "N",
        "buttonRule": false
    }
}

function normalizeGoRules(app, source) {
    var fallback = defaultGoRules(app)
    var rules = source || fallback
    var handicap = String(rules.handicapBonus === undefined ? fallback.handicapBonus : rules.handicapBonus)
    return {
        "scoringRule": Math.round(app.clamp(numeric(rules.scoringRule, fallback.scoringRule),
                                            app.goScoringArea,
                                            app.goScoringTerritory)),
        "koRule": Math.round(app.clamp(numeric(rules.koRule, fallback.koRule),
                                       app.goKoSimple,
                                       app.goKoSituational)),
        "suicideAllowed": rules.suicideAllowed === true,
        "taxRule": Math.round(app.clamp(numeric(rules.taxRule, fallback.taxRule),
                                        app.goTaxNone,
                                        app.goTaxAll)),
        "handicapBonus": handicap === "0" || handicap === "N-1" ? handicap : "N",
        "buttonRule": rules.buttonRule === true
    }
}

function defaultGomokuRules(app, ruleVariant) {
    return {
        "ruleMode": app.normalizedGomokuRuleMode(ruleVariant),
        "maxMoves": 0,
        "vcnRule": "NOVC",
        "firstPassWin": false
    }
}

function normalizeGomokuRules(app, source, ruleVariant) {
    var fallback = defaultGomokuRules(app, ruleVariant)
    var rules = source || fallback
    var firstPassWin = rules.firstPassWin === true
    return {
        "ruleMode": app.normalizedGomokuRuleMode(rules.ruleMode === undefined
                                                 ? fallback.ruleMode : rules.ruleMode),
        "maxMoves": Math.round(app.clamp(numeric(rules.maxMoves, fallback.maxMoves),
                                         0,
                                         app.maxLargeIntegerSetting)),
        "vcnRule": firstPassWin ? "NOVC" : app.normalizedGomokuVcnRule(rules.vcnRule),
        "firstPassWin": firstPassWin
    }
}

function goRuleEngineObject(app, rules) {
    var normalized = normalizeGoRules(app, rules)
    return {
        "scoring": normalized.scoringRule === app.goScoringTerritory ? "TERRITORY" : "AREA",
        "ko": normalized.koRule === app.goKoSimple ? "SIMPLE"
              : normalized.koRule === app.goKoSituational ? "SITUATIONAL" : "POSITIONAL",
        "suicide": normalized.suicideAllowed === true,
        "tax": normalized.taxRule === app.goTaxAll ? "ALL"
               : normalized.taxRule === app.goTaxSeki ? "SEKI" : "NONE",
        "whiteHandicapBonus": normalized.handicapBonus,
        "hasButton": normalized.buttonRule === true
    }
}

function gomokuRuleEngineObject(app, rules) {
    var normalized = normalizeGomokuRules(app, rules, app.gomokuRuleFreestyle)
    var firstPassWin = normalized.firstPassWin === true
    return {
        "basicrule": app.gomokuRuleEngineValue(normalized.ruleMode),
        "maxmoves": normalized.maxMoves,
        "firstpasswin": firstPassWin,
        "vcnrule": firstPassWin ? "NOVC" : normalized.vcnRule
    }
}

function goRuleLabelForRules(app, rules) {
    var engineRules = goRuleEngineObject(app, rules)
    if (engineRules.scoring === "AREA" && engineRules.ko === "POSITIONAL" && engineRules.suicide
            && engineRules.tax === "NONE" && engineRules.whiteHandicapBonus === "N" && !engineRules.hasButton)
        return app.trText("goRuleTrompTaylor")
    if (engineRules.scoring === "AREA" && engineRules.tax === "NONE" && !engineRules.hasButton)
        return app.trText("goRuleChinese")
    if (engineRules.scoring === "AREA" && engineRules.tax === "ALL" && !engineRules.hasButton)
        return app.trText("goRuleChineseAncient")
    if (engineRules.scoring === "TERRITORY" && engineRules.tax === "SEKI")
        return app.trText("goRuleJapanese")
    return app.trText("customRule")
}

function goRulesMatchApp(app, rules) {
    var normalized = normalizeGoRules(app, rules)
    return normalized.scoringRule === app.goScoringRule
           && normalized.koRule === app.goKoRule
           && normalized.suicideAllowed === app.goSuicideAllowed
           && normalized.taxRule === app.goTaxRule
           && normalized.handicapBonus === app.goWhiteHandicapBonus
           && normalized.buttonRule === app.goButtonRule
}

function gomokuRulesMatchApp(app, rules) {
    var normalized = normalizeGomokuRules(app, rules, app.gomokuRuleFreestyle)
    return normalized.ruleMode === app.gomokuRuleMode
           && normalized.maxMoves === app.gomokuRuleMaxMoves
           && normalized.vcnRule === app.gomokuRuleVcn
           && normalized.firstPassWin === app.gomokuRuleFirstPassWin
}

function normalizePreset(app, preset, index) {
    var safeIndex = Math.max(0, Math.round(numeric(index, 0)))
    var fallback = fallbackPreset(app, safeIndex)
    var copy = clonePreset(preset || fallback)
    copy.id = String(copy.id || ("engine-" + (safeIndex + 1)))
    copy.name = String(copy.name || ("Engine " + (safeIndex + 1)))
    copy.command = copy.command === undefined || copy.command === null
                   ? ""
                   : String(copy.command)
    copy.initialCommands = String(copy.initialCommands || "")
    delete copy.preload

    copy.ruleMode = Math.round(numeric(copy.ruleMode, app.gameRuleGo))
    if (!app.validRuleMode(copy.ruleMode))
        copy.ruleMode = app.gameRuleGo

    copy.ruleVariant = Math.round(numeric(copy.ruleVariant, -1))
    copy.goRules = normalizeGoRules(app, copy.goRules)
    copy.gomokuRules = normalizeGomokuRules(app, copy.gomokuRules, copy.ruleVariant)
    if (copy.ruleMode !== app.gameRuleGomoku)
        copy.ruleVariant = -1
    else
        copy.ruleVariant = copy.gomokuRules.ruleMode

    copy.boardSizeX = Math.round(app.clamp(numeric(copy.boardSizeX, app.defaultBoardSize),
                                           app.minBoardSize,
                                           app.maxBoardSize))
    copy.boardSizeY = Math.round(app.clamp(numeric(copy.boardSizeY, copy.boardSizeX),
                                           app.minBoardSize,
                                           app.maxBoardSize))
    var adjusted = app.adjustedBoardDimensionsForRule(copy.ruleMode, copy.boardSizeX, copy.boardSizeY)
    copy.boardSizeX = adjusted.x
    copy.boardSizeY = adjusted.y
    copy.komi = app.clampKomiSettingValue(numeric(copy.komi, defaultKomiForRule(app, copy.ruleMode)))
    copy.legacyHexEngineCoordinates = copy.legacyHexEngineCoordinates === true
    copy.boardPresentationMode = Math.round(app.clamp(numeric(copy.boardPresentationMode, 0),
                                                       app.boardPresentationIntersections,
                                                       app.boardPresentationCells))
    if (copy.ruleMode !== app.gameRuleGomoku)
        copy.boardPresentationMode = app.boardPresentationIntersections
    return copy
}

function normalizeList(app, presets) {
    var source = presets && presets.length > 0 ? presets : []
    var list = []
    var used = ({})
    for (var i = 0; i < source.length; ++i) {
        var preset = normalizePreset(app, source[i], i)
        if (used[preset.id]) {
            var suffix = 2
            var base = preset.id
            while (used[base + "-" + suffix])
                ++suffix
            preset.id = base + "-" + suffix
        }
        used[preset.id] = true
        list.push(preset)
    }
    return list
}

function parseList(app, text) {
    try {
        var parsed = JSON.parse(String(text || ""))
        if (Array.isArray(parsed))
            return normalizeList(app, parsed)
    } catch (error) {
    }
    return []
}

function serializeList(presets) {
    return JSON.stringify(cloneList(presets || []))
}

function findIndexById(presets, id) {
    for (var i = 0; presets && i < presets.length; ++i) {
        if (String(presets[i].id) === String(id))
            return i
    }
    return -1
}

function findById(presets, id) {
    var index = findIndexById(presets, id)
    return index >= 0 ? presets[index] : null
}

function newPreset(app) {
    var now = Date.now ? Date.now() : Math.floor(Math.random() * 1000000000)
    var ruleMode = defaultRuleMode(app)
    var preset = makePreset("engine-" + now,
                            app.trText("newEngine"),
                            "",
                            ruleMode,
                            -1,
                            19,
                            19,
                            defaultKomiForRule(app, ruleMode),
                            false)
    preset.boardPresentationMode = app.boardPresentationIntersections
    return normalizePreset(app, preset, 0)
}

function defaultRuleMode(app) {
    var options = app.commonGameRuleOptions ? app.commonGameRuleOptions() : []
    for (var i = 0; options && i < options.length; ++i) {
        if (options[i] && app.validRuleMode(options[i].value))
            return options[i].value
    }
    return app.gameRuleGo
}

function defaultKomiForRule(app, mode) {
    if (mode === app.gameRuleGo
            || mode === app.gameRuleTorusGo
            || mode === app.gameRuleTwoLibGo
            || mode === app.gameRuleHexGoParallelogram
            || mode === app.gameRuleHexGoHexagon
            || mode === app.gameRuleHexGoTriangle)
        return 6.5
    return 0.0
}

function ruleText(app, preset) {
    if (!preset)
        return ""
    if (preset.ruleMode === app.gameRuleGo)
        return app.trText("gameRuleGo")
    if (preset.ruleMode === app.gameRuleHex)
        return app.trText("gameRuleHex")
    if (preset.ruleMode === app.gameRuleSquareFree)
        return app.trText("gameRuleSquareFree")
    if (preset.ruleMode === app.gameRuleReversi)
        return app.trText("gameRuleReversi")
    if (preset.ruleMode === app.gameRuleConnect6)
        return app.trText("gameRuleConnect6")
    if (preset.ruleMode === app.gameRuleHexGoParallelogram)
        return app.trText("gameRuleHexGoParallelogram")
    if (preset.ruleMode === app.gameRuleHexGoHexagon)
        return app.trText("gameRuleHexGoHexagon")
    if (preset.ruleMode === app.gameRuleHexGoTriangle)
        return app.trText("gameRuleHexGoTriangle")
    if (preset.ruleMode === app.gameRuleTorusGo)
        return app.trText("gameRuleTorusGo")
    if (preset.ruleMode === app.gameRuleTwoLibGo)
        return app.trText("gameRuleTwoLibGo")
    if (preset.ruleMode === app.gameRuleAtaxx)
        return app.trText("gameRuleAtaxx")
    if (preset.ruleMode === app.gameRuleBreakthrough)
        return app.trText("gameRuleBreakthrough")
    return app.trText("gameRuleGomoku")
}

function ruleDetailText(app, preset) {
    if (!preset)
        return ""
    if (preset.ruleMode === app.gameRuleGo)
        return goRuleLabelForRules(app, preset.goRules)
    if (preset.ruleMode === app.gameRuleGomoku)
        return app.gomokuRuleLabel(normalizeGomokuRules(app, preset.gomokuRules, preset.ruleVariant).ruleMode)
    return ruleText(app, preset)
}

function boardSizeText(preset) {
    if (!preset)
        return ""
    return preset.boardSizeX === preset.boardSizeY
           ? String(preset.boardSizeX)
           : preset.boardSizeX + "x" + preset.boardSizeY
}
