.pragma library
.import "EnginePresets.js" as EnginePresets
.import "rules/RuleCatalog.js" as RuleCatalog
.import "rules/RuleRegistry.js" as RuleRegistry

function normalizeColorHex(value, fallback) {
    var text = String(value)
    if (/^#[0-9a-fA-F]{6}$/.test(text))
        return text
    return fallback
}

function normalizePersistentSettings(app) {
    app.boardSizeX = Math.round(app.clamp(app.boardSizeX, app.minBoardSize, app.maxBoardSize))
    app.boardSizeY = Math.round(app.clamp(app.boardSizeY, app.minBoardSize, app.maxBoardSize))
    if (!app.validRuleMode(app.gameRuleMode))
        app.gameRuleMode = app.gameRuleGo
    var adjustedRuleSize = app.adjustedBoardDimensionsForRule(app.gameRuleMode, app.boardSizeX, app.boardSizeY)
    app.boardSizeX = adjustedRuleSize.x
    app.boardSizeY = adjustedRuleSize.y
    app.ruleVisibilityMap = normalizeRuleVisibilityMap(app, app.ruleVisibilityMap)
    app.commonRuleOrder = normalizeCommonRuleOrder(app, app.commonRuleOrder)
    app.gomokuRuleMode = app.normalizedGomokuRuleMode(app.gomokuRuleMode)
    app.gomokuRuleMaxMoves = Math.round(app.clamp(Number(app.gomokuRuleMaxMoves), 0, app.maxLargeIntegerSetting))
    app.gomokuRuleVcn = app.normalizedGomokuVcnRule(app.gomokuRuleVcn)
    app.goScoringRule = Math.round(app.clamp(Number(app.goScoringRule), app.goScoringArea, app.goScoringTerritory))
    app.goKoRule = Math.round(app.clamp(Number(app.goKoRule), app.goKoSimple, app.goKoSituational))
    app.goTaxRule = Math.round(app.clamp(Number(app.goTaxRule), app.goTaxNone, app.goTaxAll))
    if (app.goWhiteHandicapBonus !== "0" && app.goWhiteHandicapBonus !== "N-1")
        app.goWhiteHandicapBonus = "N"
    if (app.stoneColorMode !== app.stoneColorModeAuto
            && app.stoneColorMode !== app.stoneColorModeBlack
            && app.stoneColorMode !== app.stoneColorModeWhite)
        app.stoneColorMode = app.stoneColorModeAuto
    if (app.moveNumberDisplayMode < app.moveNumberModeAll || app.moveNumberDisplayMode > app.moveNumberModeHidden)
        app.moveNumberDisplayMode = app.defaultMoveNumberDisplayMode
    if (app.coordinateDisplayMode < app.coordinateDisplayGoNoI || app.coordinateDisplayMode > app.coordinateDisplayNone)
        app.coordinateDisplayMode = app.coordinateDisplayGoNoI
    app.goBoardPresentationMode = app.boardPresentationIntersections
    app.gomokuBoardPresentationMode = RuleCatalog.normalizeBoardPresentationMode(
                app, app.gameRuleGomoku, Math.round(Number(app.gomokuBoardPresentationMode)))
    app.torusGoBoardPresentationMode = RuleCatalog.normalizeBoardPresentationMode(
                app, app.gameRuleTorusGo, Math.round(Number(app.torusGoBoardPresentationMode)))
    app.boardPresentationMode = RuleCatalog.normalizeBoardPresentationMode(
                app, app.gameRuleMode, Math.round(Number(app.boardPresentationMode)))
    if (app.gameRuleMode === app.gameRuleGomoku)
        app.gomokuBoardPresentationMode = app.boardPresentationMode
    else if (app.gameRuleMode === app.gameRuleTorusGo)
        app.torusGoBoardPresentationMode = app.boardPresentationMode
    else
        app.boardPresentationMode = RuleCatalog.rememberedBoardPresentationMode(app, app.gameRuleMode)
    var hexStyle = Number(app.hexBoardStyle)
    if (isNaN(hexStyle))
        hexStyle = app.hexBoardStyleTriangle
    app.hexBoardStyle = Math.round(app.clamp(hexStyle,
                                             app.hexBoardStyleTriangle,
                                             app.hexBoardStyleCells))
    var hexRotation = Number(app.hexBoardRotation)
    if (isNaN(hexRotation))
        hexRotation = app.hexRotationCurrent
    app.hexBoardRotation = Math.round(app.clamp(hexRotation,
                                                app.hexRotationCurrent,
                                                app.hexRotationMirrorTranspose))
    app.packageMode = Math.round(app.clamp(app.packageMode, app.packageModeUniversal, app.packageModeSix))
    var logLineLimit = Number(app.engineCommunicationLogLimit)
    if (isNaN(logLineLimit))
        logLineLimit = 1000
    var logCharacterLimit = Number(app.engineCommunicationLogCharacterLimit)
    if (isNaN(logCharacterLimit))
        logCharacterLimit = 262144
    var logLineCharacterLimit = Number(app.engineCommunicationLineCharacterLimit)
    if (isNaN(logLineCharacterLimit))
        logLineCharacterLimit = 16384
    app.engineCommunicationLogLimit = Math.round(app.clamp(
                logLineLimit, 1, app.maxEngineCommunicationLogLines))
    app.engineCommunicationLogCharacterLimit = Math.round(app.clamp(
                logCharacterLimit, 1024,
                app.maxEngineCommunicationLogCharacters))
    app.engineCommunicationLineCharacterLimit = Math.round(app.clamp(
                logLineCharacterLimit, 128,
                Math.min(app.maxEngineCommunicationLineCharacters,
                         Math.max(128,
                                  app.engineCommunicationLogCharacterLimit - 1))))
    app.enginePresets = EnginePresets.normalizeList(app, app.enginePresets)
    app.engineStartupMode = Math.round(app.clamp(Number(app.engineStartupMode),
                                                 app.engineStartupDefault,
                                                 app.engineStartupNone))
    if (app.defaultEngineId.length > 0 && !EnginePresets.findById(app.enginePresets, app.defaultEngineId))
        app.defaultEngineId = ""
    if (app.activeEngineId.length > 0 && !EnginePresets.findById(app.enginePresets, app.activeEngineId))
        app.activeEngineId = ""
    app.candidateDisplayCount = Math.round(app.clamp(app.candidateDisplayCount, 0, 65536))
    app.candidateMinVisitRatio = app.clamp(app.candidateMinVisitRatio, 0, 1)

    var previewMaxMoves = Number(app.candidateVariationPreviewMaxMoves)
    if (isNaN(previewMaxMoves))
        previewMaxMoves = 0
    app.candidateVariationPreviewMaxMoves = Math.round(app.clamp(previewMaxMoves, 0, app.maxLargeIntegerSetting))

    var previewOpacity = Number(app.candidateVariationPreviewOpacity)
    if (isNaN(previewOpacity))
        previewOpacity = app.defaultCandidateVariationPreviewOpacity
    app.candidateVariationPreviewOpacity = app.clamp(previewOpacity, 0, 1)

    app.candidateWinrateFontSize = Math.round(app.clamp(app.candidateWinrateFontSize, 12, 120))
    app.candidateVisitsFontSize = Math.round(app.clamp(app.candidateVisitsFontSize, 12, 120))
    app.candidateScoreFontSize = Math.round(app.clamp(app.candidateScoreFontSize, 12, 120))
    app.candidateWinrateOffsetY = Math.round(app.clamp(app.candidateWinrateOffsetY, -64, 64))
    app.candidateVisitsOffsetY = Math.round(app.clamp(app.candidateVisitsOffsetY, -64, 64))
    app.candidateScoreOffsetY = Math.round(app.clamp(app.candidateScoreOffsetY, -64, 64))
    app.candidateWinrateDecimals = Math.round(app.clamp(app.candidateWinrateDecimals, 0, 2))
    app.candidateScoreDecimals = Math.round(app.clamp(app.candidateScoreDecimals, 0, 2))
    app.candidateScoreTitleMode = Math.round(app.clamp(app.candidateScoreTitleMode,
                                                       app.candidateScoreTitleScoreMean,
                                                       app.candidateScoreTitleDrawRate))
    app.candidateRingLineWidth = Math.round(app.clamp(app.candidateRingLineWidth, 1, 64))
    app.candidateFirstLabelTextColor = normalizeColorHex(app.candidateFirstLabelTextColor, "#ff0000")
    app.candidateLabelTextColor = normalizeColorHex(app.candidateLabelTextColor, "#000000")
    app.backgroundColor = normalizeColorHex(app.backgroundColor, app.defaultBackgroundColor)
    app.boardWoodColor = normalizeColorHex(app.boardWoodColor, app.defaultBoardWoodColor)
    app.komi = app.clampKomiValue(app.komi)
    app.analysisIntervalCentiseconds = Math.round(app.clamp(Number(app.analysisIntervalCentiseconds), 0, app.maxLargeIntegerSetting))
    app.maxAnalysisSeconds = Math.round(app.clamp(Number(app.maxAnalysisSeconds), 0, app.maxLargeIntegerSetting))
    app.analysisWideRootNoiseEnabled = !!app.analysisWideRootNoiseEnabled
    app.analysisWideRootNoise = app.clampAnalysisWideRootNoise(app.analysisWideRootNoise)
    app.stoneScale = app.clamp(app.stoneScale, app.minStoneScale, 1.0)
    app.gridOpacity = app.clamp(app.gridOpacity, 0.25, 1)
    app.gridLineWidth = app.clamp(Number(app.gridLineWidth), 0.5, 4)
    app.selectedPointScale = app.clamp(Number(app.selectedPointScale), 0.5, 1.0)
    app.moveNumberLabelScale = app.clamp(Number(app.moveNumberLabelScale), 0.5, 2.0)
    app.mouseHitRadiusScale = app.clamp(Number(app.mouseHitRadiusScale), 0.1, 1.0)
    var secondsPerMove = Number(app.secondsPerMove)
    if (!isFinite(secondsPerMove))
        secondsPerMove = 5.0
    app.secondsPerMove = app.clamp(secondsPerMove, 0.1, 999)
    var analysisSecondsPerMove = Number(app.analysisSecondsPerMove)
    if (!isFinite(analysisSecondsPerMove))
        analysisSecondsPerMove = 5.0
    app.analysisSecondsPerMove = app.clamp(analysisSecondsPerMove, 0, 999)
    if (app.aiMoveMode !== app.aiMoveModeGtp
            && app.aiMoveMode !== app.aiMoveModeAnalyze)
        app.aiMoveMode = app.aiMoveModeGtp
    app.analysisTotalVisitsPerMove = Math.round(app.clamp(
                Number(app.analysisTotalVisitsPerMove) || 0,
                0, app.maxLargeIntegerSetting))
    app.analysisFirstMoveVisitsPerMove = Math.round(app.clamp(
                Number(app.analysisFirstMoveVisitsPerMove) || 0,
                0, app.maxLargeIntegerSetting))
    app.resignMinMove = Math.max(1, Math.round(Number(app.resignMinMove)))
    app.resignConsecutiveMoves = Math.max(1, Math.round(Number(app.resignConsecutiveMoves)))
    app.resignWinrateThreshold = app.clamp(Number(app.resignWinrateThreshold), 0, 100)
    app.normalizeGomokuRuleForCurrentMode()
    app.applyPackageModeConstraints(false)
}

function settingValue(settings, key, fallback) {
    return settings.value(key, fallback)
}

function settingBool(settings, key, fallback) {
    var value = settingValue(settings, key, fallback)
    if (typeof value === "boolean")
        return value
    var text = String(value).toLowerCase()
    return text === "true" || text === "1" || text === "yes"
}

function parseJsonObject(text, fallback) {
    try {
        var parsed = JSON.parse(String(text))
        if (parsed && typeof parsed === "object" && !Array.isArray(parsed))
            return parsed
    } catch (error) {
    }
    return fallback
}

function parseJsonArray(text, fallback) {
    try {
        var parsed = JSON.parse(String(text))
        if (Array.isArray(parsed))
            return parsed
    } catch (error) {
    }
    return fallback
}

function defaultRuleModeVisible(app, mode) {
    return RuleRegistry.hasCapability(mode, "defaultVisible")
}

function defaultRuleVisibilityMap(app) {
    var next = {}
    var options = app && app.gameRuleOptions ? app.gameRuleOptions() : []
    for (var i = 0; i < options.length; ++i)
        next[String(options[i].value)] = defaultRuleModeVisible(app, options[i].value)
    return next
}

function defaultCommonRuleOrder(app) {
    return [RuleRegistry.RULE_GO, RuleRegistry.RULE_GOMOKU, RuleRegistry.RULE_HEX]
}

function normalizeRuleVisibilityMap(app, source) {
    var map = source || {}
    var next = {}
    var options = app && app.gameRuleOptions ? app.gameRuleOptions() : []
    for (var i = 0; i < options.length; ++i) {
        var key = String(options[i].value)
        next[key] = typeof map[key] === "boolean" ? map[key]
                                                  : defaultRuleModeVisible(app, options[i].value)
    }
    if (options.length <= 0) {
        for (var existingKey in map) {
            if (typeof map[existingKey] === "boolean")
                next[existingKey] = map[existingKey]
        }
    }
    return next
}

function normalizeCommonRuleOrder(app, source) {
    var order = Array.isArray(source) ? source : defaultCommonRuleOrder(app)
    var map = normalizeRuleVisibilityMap(app, app.ruleVisibilityMap)
    var options = app && app.gameRuleOptions ? app.gameRuleOptions() : []
    var valid = {}
    for (var i = 0; i < options.length; ++i)
        valid[String(options[i].value)] = true
    var used = {}
    var next = []
    for (var j = 0; j < order.length; ++j) {
        var mode = Number(order[j])
        var key = String(mode)
        if (valid[key] && map[key] === true && !used[key]) {
            next.push(mode)
            used[key] = true
        }
    }
    for (var k = 0; k < options.length; ++k) {
        var optionKey = String(options[k].value)
        if (map[optionKey] === true && !used[optionKey]) {
            next.push(options[k].value)
            used[optionKey] = true
        }
    }
    return next
}

function settingNumberEquals(value, expected) {
    return Math.abs(Number(value) - Number(expected)) < 0.000001
}

function migratePersistentSettings(app) {
    if (app.loadedSettingsVersion < 3)
        app.ruleVisibilityMap = defaultRuleVisibilityMap(app)
    app.loadedSettingsVersion = app.currentSettingsVersion
}

function loadPersistentSettings(app, settings) {
    app.loadedSettingsVersion = Number(settingValue(settings, "settingsVersion", app.loadedSettingsVersion))
    app.language = String(settingValue(settings, "language", app.language))
    app.firstLaunchCompleted = settingBool(settings, "firstLaunchCompleted", app.firstLaunchCompleted)
    app.showBeginnerTutorialOnNextLaunch = settingBool(settings,
                                                       "showBeginnerTutorialOnNextLaunch",
                                                       app.showBeginnerTutorialOnNextLaunch)
    app.boardSizeX = Number(settingValue(settings, "boardSizeX", app.boardSizeX))
    app.boardSizeY = Number(settingValue(settings, "boardSizeY", app.boardSizeY))
    app.gameRuleMode = Number(settingValue(settings, "gameRuleMode", app.gameRuleMode))
    app.ruleVisibilityMap = normalizeRuleVisibilityMap(app,
                parseJsonObject(settingValue(settings, "ruleVisibilityJson", "{}"), app.ruleVisibilityMap))
    app.commonRuleOrder = normalizeCommonRuleOrder(app,
                parseJsonArray(settingValue(settings, "commonRuleOrderJson", "[]"), app.commonRuleOrder))
    app.gomokuRuleMode = Number(settingValue(settings, "gomokuRuleMode", app.gomokuRuleMode))
    app.gomokuRuleMaxMoves = Number(settingValue(settings, "gomokuRuleMaxMoves", app.gomokuRuleMaxMoves))
    app.gomokuRuleVcn = String(settingValue(settings, "gomokuRuleVcn", app.gomokuRuleVcn))
    app.gomokuRuleFirstPassWin = settingBool(settings, "gomokuRuleFirstPassWin", app.gomokuRuleFirstPassWin)
    app.goScoringRule = Number(settingValue(settings, "goScoringRule", app.goScoringRule))
    app.goKoRule = Number(settingValue(settings, "goKoRule", app.goKoRule))
    app.goSuicideAllowed = settingBool(settings, "goSuicideAllowed", app.goSuicideAllowed)
    app.goTaxRule = Number(settingValue(settings, "goTaxRule", app.goTaxRule))
    app.goWhiteHandicapBonus = String(settingValue(settings, "goWhiteHandicapBonus", app.goWhiteHandicapBonus))
    app.goButtonRule = settingBool(settings, "goButtonRule", app.goButtonRule)
    app.komi = app.clampKomiValue(settingValue(settings, "komi", app.komi))
    app.moveNumberDisplayMode = Number(settingValue(settings, "moveNumberDisplayMode", app.moveNumberDisplayMode))
    app.coordinateDisplayMode = Number(settingValue(settings, "coordinateDisplayMode", app.coordinateDisplayMode))
    app.boardPresentationMode = Number(settingValue(settings, "boardPresentationMode", app.boardPresentationMode))
    app.gomokuBoardPresentationMode = Number(settingValue(settings, "gomokuBoardPresentationMode", app.gomokuBoardPresentationMode))
    app.torusGoBoardPresentationMode = Number(settingValue(settings, "torusGoBoardPresentationMode", app.torusGoBoardPresentationMode))
    app.hexBoardStyle = Number(settingValue(settings, "hexBoardStyle", app.hexBoardStyle))
    app.hexBoardRotation = Number(settingValue(settings, "hexBoardRotation", app.hexBoardRotation))
    app.packageMode = Number(settingValue(settings, "packageMode", app.packageMode))
    app.ignoreGtpErrors = settingBool(settings, "ignoreGtpErrors", app.ignoreGtpErrors)
    app.engineCommunicationLogLimit = Number(settingValue(
                settings, "engineCommunicationLogLimit",
                app.engineCommunicationLogLimit))
    app.engineCommunicationLogCharacterLimit = Number(settingValue(
                settings, "engineCommunicationLogCharacterLimit",
                app.engineCommunicationLogCharacterLimit))
    app.engineCommunicationLineCharacterLimit = Number(settingValue(
                settings, "engineCommunicationLineCharacterLimit",
                app.engineCommunicationLineCharacterLimit))
    app.enginePresets = EnginePresets.parseList(app, String(settingValue(settings, "enginePresetsJson", "")))
    app.defaultEngineId = String(settingValue(settings, "defaultEngineId", app.defaultEngineId))
    app.activeEngineId = String(settingValue(settings, "activeEngineId", app.activeEngineId))
    app.engineStartupMode = Number(settingValue(settings, "engineStartupMode", app.engineStartupMode))
    app.persistedEngineCommand = String(settingValue(settings, "engineCommand", app.persistedEngineCommand))
    app.legacyHexEngineCoordinates = settingBool(settings, "legacyHexEngineCoordinates", app.legacyHexEngineCoordinates)
    app.analysisIntervalCentiseconds = Number(settingValue(settings, "analysisIntervalCentiseconds", app.analysisIntervalCentiseconds))
    app.maxAnalysisSeconds = Number(settingValue(settings, "maxAnalysisSeconds", app.maxAnalysisSeconds))
    app.analysisWideRootNoiseEnabled = settingBool(settings, "analysisWideRootNoiseEnabled", app.analysisWideRootNoiseEnabled)
    app.analysisWideRootNoise = app.clampAnalysisWideRootNoise(settingValue(settings, "analysisWideRootNoise", app.analysisWideRootNoise))
    app.candidateDisplayCount = Number(settingValue(settings, "candidateDisplayCount", app.candidateDisplayCount))
    app.candidateMinVisitRatio = Number(settingValue(settings, "candidateMinVisitRatio", app.candidateMinVisitRatio))
    app.candidateShowFilteredMarkers = settingBool(settings, "candidateShowFilteredMarkers", app.candidateShowFilteredMarkers)
    app.candidateVariationPreviewVisible = settingBool(settings, "candidateVariationPreviewVisible", app.candidateVariationPreviewVisible)
    app.candidateVariationPreviewMaxMoves = Number(settingValue(settings, "candidateVariationPreviewMaxMoves", app.candidateVariationPreviewMaxMoves))
    app.candidateVariationPreviewOpacity = Number(settingValue(settings, "candidateVariationPreviewOpacity", app.candidateVariationPreviewOpacity))
    app.candidateWinrateLabelVisible = settingBool(settings, "candidateWinrateLabelVisible", app.candidateWinrateLabelVisible)
    app.candidateVisitsLabelVisible = settingBool(settings, "candidateVisitsLabelVisible", app.candidateVisitsLabelVisible)
    app.candidateScoreLabelVisible = settingBool(settings, "candidateScoreLabelVisible", app.candidateScoreLabelVisible)
    app.candidateWinrateFontSize = Number(settingValue(settings, "candidateWinrateFontSize", app.candidateWinrateFontSize))
    app.candidateVisitsFontSize = Number(settingValue(settings, "candidateVisitsFontSize", app.candidateVisitsFontSize))
    app.candidateScoreFontSize = Number(settingValue(settings, "candidateScoreFontSize", app.candidateScoreFontSize))
    app.candidateWinrateBold = settingBool(settings, "candidateWinrateBold", app.candidateWinrateBold)
    app.candidateVisitsBold = settingBool(settings, "candidateVisitsBold", app.candidateVisitsBold)
    app.candidateScoreBold = settingBool(settings, "candidateScoreBold", app.candidateScoreBold)
    app.candidateWinrateOffsetY = Number(settingValue(settings, "candidateWinrateOffsetY", app.candidateWinrateOffsetY))
    app.candidateVisitsOffsetY = Number(settingValue(settings, "candidateVisitsOffsetY", app.candidateVisitsOffsetY))
    app.candidateScoreOffsetY = Number(settingValue(settings, "candidateScoreOffsetY", app.candidateScoreOffsetY))
    app.candidateWinrateDecimals = Number(settingValue(settings, "candidateWinrateDecimals", app.candidateWinrateDecimals))
    app.candidateScoreDecimals = Number(settingValue(settings, "candidateScoreDecimals", app.candidateScoreDecimals))
    app.candidateWinrateShowPercent = settingBool(settings, "candidateWinrateShowPercent", app.candidateWinrateShowPercent)
    app.candidateScoreShowPercent = settingBool(settings, "candidateScoreShowPercent", app.candidateScoreShowPercent)
    app.candidateScoreTitleMode = Number(settingValue(settings, "candidateScoreTitleMode", app.candidateScoreTitleMode))
    app.candidateRingVisible = settingBool(settings, "candidateRingVisible", app.candidateRingVisible)
    app.candidateRingLineWidth = Number(settingValue(settings, "candidateRingLineWidth", app.candidateRingLineWidth))
    app.candidateRankLabelVisible = settingBool(settings, "candidateRankLabelVisible", app.candidateRankLabelVisible)
    app.candidateFirstLabelTextColor = String(settingValue(settings, "candidateFirstLabelTextColor", app.candidateFirstLabelTextColor))
    app.candidateLabelTextColor = String(settingValue(settings, "candidateLabelTextColor", app.candidateLabelTextColor))
    app.backgroundColor = String(settingValue(settings, "backgroundColor", app.backgroundColor))
    app.boardWoodColor = String(settingValue(settings, "boardWoodColor", app.boardWoodColor))
    app.stoneScale = Number(settingValue(settings, "stoneScale", app.stoneScale))
    app.gridOpacity = Number(settingValue(settings, "gridOpacity", app.gridOpacity))
    app.gridLineWidth = Number(settingValue(settings, "gridLineWidth", app.gridLineWidth))
    app.selectedPointScale = Number(settingValue(settings, "selectedPointScale", app.selectedPointScale))
    app.moveNumberLabelScale = Number(settingValue(settings, "moveNumberLabelScale", app.moveNumberLabelScale))
    app.secondsPerMove = Number(settingValue(settings, "secondsPerMove", app.secondsPerMove))
    app.analysisSecondsPerMove = Number(settingValue(
                settings, "analysisSecondsPerMove",
                app.analysisSecondsPerMove))
    app.aiMoveMode = Number(settingValue(settings, "aiMoveMode", app.aiMoveMode))
    app.analysisTotalVisitsPerMove = Number(settingValue(
                settings, "analysisTotalVisitsPerMove",
                app.analysisTotalVisitsPerMove))
    app.analysisFirstMoveVisitsPerMove = Number(settingValue(
                settings, "analysisFirstMoveVisitsPerMove",
                app.analysisFirstMoveVisitsPerMove))
    app.resignMinMove = Number(settingValue(settings, "resignMinMove", app.resignMinMove))
    app.resignConsecutiveMoves = Number(settingValue(settings, "resignConsecutiveMoves", app.resignConsecutiveMoves))
    app.resignWinrateThreshold = Number(settingValue(settings, "resignWinrateThreshold", app.resignWinrateThreshold))
    migratePersistentSettings(app)
}

function savePersistentSettings(app, settings, engineController) {
    if (!settings)
        return
    settings.setValue("settingsVersion", app.currentSettingsVersion)
    settings.setValue("language", app.language)
    settings.setValue("firstLaunchCompleted", app.firstLaunchCompleted)
    settings.setValue("showBeginnerTutorialOnNextLaunch", app.showBeginnerTutorialOnNextLaunch)
    settings.setValue("boardSizeX", app.boardSizeX)
    settings.setValue("boardSizeY", app.boardSizeY)
    settings.setValue("gameRuleMode", app.gameRuleMode)
    settings.setValue("ruleVisibilityJson", JSON.stringify(normalizeRuleVisibilityMap(app, app.ruleVisibilityMap)))
    settings.setValue("commonRuleOrderJson", JSON.stringify(normalizeCommonRuleOrder(app, app.commonRuleOrder)))
    settings.setValue("gomokuRuleMode", app.gomokuRuleMode)
    settings.setValue("gomokuRuleMaxMoves", app.gomokuRuleMaxMoves)
    settings.setValue("gomokuRuleVcn", app.gomokuRuleVcn)
    settings.setValue("gomokuRuleFirstPassWin", app.gomokuRuleFirstPassWin)
    settings.setValue("goScoringRule", app.goScoringRule)
    settings.setValue("goKoRule", app.goKoRule)
    settings.setValue("goSuicideAllowed", app.goSuicideAllowed)
    settings.setValue("goTaxRule", app.goTaxRule)
    settings.setValue("goWhiteHandicapBonus", app.goWhiteHandicapBonus)
    settings.setValue("goButtonRule", app.goButtonRule)
    settings.setValue("komi", app.komi)
    settings.setValue("moveNumberDisplayMode", app.moveNumberDisplayMode)
    settings.setValue("coordinateDisplayMode", app.coordinateDisplayMode)
    settings.setValue("boardPresentationMode", app.boardPresentationMode)
    settings.setValue("gomokuBoardPresentationMode", app.gomokuBoardPresentationMode)
    settings.setValue("torusGoBoardPresentationMode", app.torusGoBoardPresentationMode)
    settings.setValue("hexBoardStyle", app.hexBoardStyle)
    settings.setValue("hexBoardRotation", app.hexBoardRotation)
    settings.setValue("packageMode", app.packageMode)
    settings.setValue("ignoreGtpErrors", app.ignoreGtpErrors)
    settings.setValue("engineCommunicationLogLimit", app.engineCommunicationLogLimit)
    settings.setValue("engineCommunicationLogCharacterLimit",
                      app.engineCommunicationLogCharacterLimit)
    settings.setValue("engineCommunicationLineCharacterLimit",
                      app.engineCommunicationLineCharacterLimit)
    settings.setValue("enginePresetsJson", EnginePresets.serializeList(app.enginePresets))
    settings.setValue("defaultEngineId", app.defaultEngineId)
    settings.setValue("activeEngineId", app.activeEngineId)
    settings.setValue("engineStartupMode", app.engineStartupMode)
    settings.setValue("engineCommand", engineController ? engineController.command : app.persistedEngineCommand)
    settings.setValue("legacyHexEngineCoordinates", app.legacyHexEngineCoordinates)
    settings.setValue("analysisIntervalCentiseconds", app.analysisIntervalCentiseconds)
    settings.setValue("maxAnalysisSeconds", app.maxAnalysisSeconds)
    settings.setValue("analysisWideRootNoiseEnabled", app.analysisWideRootNoiseEnabled)
    settings.setValue("analysisWideRootNoise", app.analysisWideRootNoise)
    settings.setValue("candidateDisplayCount", app.candidateDisplayCount)
    settings.setValue("candidateMinVisitRatio", app.candidateMinVisitRatio)
    settings.setValue("candidateShowFilteredMarkers", app.candidateShowFilteredMarkers)
    settings.setValue("candidateVariationPreviewVisible", app.candidateVariationPreviewVisible)
    settings.setValue("candidateVariationPreviewMaxMoves", app.candidateVariationPreviewMaxMoves)
    settings.setValue("candidateVariationPreviewOpacity", app.candidateVariationPreviewOpacity)
    settings.setValue("candidateWinrateLabelVisible", app.candidateWinrateLabelVisible)
    settings.setValue("candidateVisitsLabelVisible", app.candidateVisitsLabelVisible)
    settings.setValue("candidateScoreLabelVisible", app.candidateScoreLabelVisible)
    settings.setValue("candidateWinrateFontSize", app.candidateWinrateFontSize)
    settings.setValue("candidateVisitsFontSize", app.candidateVisitsFontSize)
    settings.setValue("candidateScoreFontSize", app.candidateScoreFontSize)
    settings.setValue("candidateWinrateBold", app.candidateWinrateBold)
    settings.setValue("candidateVisitsBold", app.candidateVisitsBold)
    settings.setValue("candidateScoreBold", app.candidateScoreBold)
    settings.setValue("candidateWinrateOffsetY", app.candidateWinrateOffsetY)
    settings.setValue("candidateVisitsOffsetY", app.candidateVisitsOffsetY)
    settings.setValue("candidateScoreOffsetY", app.candidateScoreOffsetY)
    settings.setValue("candidateWinrateDecimals", app.candidateWinrateDecimals)
    settings.setValue("candidateScoreDecimals", app.candidateScoreDecimals)
    settings.setValue("candidateWinrateShowPercent", app.candidateWinrateShowPercent)
    settings.setValue("candidateScoreShowPercent", app.candidateScoreShowPercent)
    settings.setValue("candidateScoreTitleMode", app.candidateScoreTitleMode)
    settings.setValue("candidateRingVisible", app.candidateRingVisible)
    settings.setValue("candidateRingLineWidth", app.candidateRingLineWidth)
    settings.setValue("candidateRankLabelVisible", app.candidateRankLabelVisible)
    settings.setValue("candidateFirstLabelTextColor", app.candidateFirstLabelTextColor)
    settings.setValue("candidateLabelTextColor", app.candidateLabelTextColor)
    settings.setValue("backgroundColor", app.backgroundColor)
    settings.setValue("boardWoodColor", app.boardWoodColor)
    settings.setValue("stoneScale", app.stoneScale)
    settings.setValue("gridOpacity", app.gridOpacity)
    settings.setValue("gridLineWidth", app.gridLineWidth)
    settings.setValue("selectedPointScale", app.selectedPointScale)
    settings.setValue("moveNumberLabelScale", app.moveNumberLabelScale)
    settings.setValue("secondsPerMove", app.secondsPerMove)
    settings.setValue("analysisSecondsPerMove", app.analysisSecondsPerMove)
    settings.setValue("aiMoveMode", app.aiMoveMode)
    settings.setValue("analysisTotalVisitsPerMove", app.analysisTotalVisitsPerMove)
    settings.setValue("analysisFirstMoveVisitsPerMove", app.analysisFirstMoveVisitsPerMove)
    settings.setValue("resignMinMove", app.resignMinMove)
    settings.setValue("resignConsecutiveMoves", app.resignConsecutiveMoves)
    settings.setValue("resignWinrateThreshold", app.resignWinrateThreshold)
}

function resetBoardVisualSettings(app) {
    app.backgroundColor = app.defaultBackgroundColor
    app.boardWoodColor = app.defaultBoardWoodColor
    app.stoneScale = app.defaultStoneScale
    app.gridOpacity = app.defaultGridOpacity
    app.gridLineWidth = app.defaultGridLineWidth
    app.selectedPointScale = app.defaultSelectedPointScale
    app.moveNumberLabelScale = app.defaultMoveNumberLabelScale
    app.mouseHitRadiusScale = app.defaultMouseHitRadiusScale
    app.coordinateDisplayMode = app.coordinateDisplayGoNoI
    app.boardRevision += 1
}

function resetCandidateVisualSettings(app) {
    app.candidateDisplayCount = 10
    app.candidateMinVisitRatio = 0.001
    app.candidateShowFilteredMarkers = true
    app.candidateVariationPreviewVisible = true
    app.candidateVariationPreviewMaxMoves = 10
    app.candidateVariationPreviewOpacity = app.defaultCandidateVariationPreviewOpacity
    app.candidateWinrateLabelVisible = true
    app.candidateVisitsLabelVisible = true
    app.candidateScoreLabelVisible = true
    app.candidateWinrateFontSize = 57
    app.candidateVisitsFontSize = 42
    app.candidateScoreFontSize = 36
    app.candidateWinrateBold = true
    app.candidateVisitsBold = false
    app.candidateScoreBold = true
    app.candidateWinrateOffsetY = -10
    app.candidateVisitsOffsetY = -5
    app.candidateScoreOffsetY = -5
    app.candidateWinrateDecimals = 1
    app.candidateScoreDecimals = 1
    app.candidateWinrateShowPercent = false
    app.candidateScoreShowPercent = false
    app.candidateScoreTitleMode = app.candidateScoreTitleScoreMean
    app.candidateRingVisible = true
    app.candidateRingLineWidth = 12
    app.candidateRankLabelVisible = true
    app.candidateFirstLabelTextColor = "#ff0000"
    app.candidateLabelTextColor = "#000000"
    app.boardRevision += 1
}

function resetVisualSettings(app) {
    resetBoardVisualSettings(app)
    resetCandidateVisualSettings(app)
}
