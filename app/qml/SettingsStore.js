.pragma library
.import "SettingsSchema.js" as SettingsSchema
.import "rules/RulePreferences.js" as RulePreferences
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
    var candidateTableRowLimit = Number(app.candidateTableRowLimit)
    if (isNaN(candidateTableRowLimit))
        candidateTableRowLimit = 20
    app.candidateTableRowLimit = Math.round(app.clamp(
                candidateTableRowLimit, 1, app.maxCandidateTableRowLimit))
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
    return SettingsSchema.booleanValue(settingValue(settings, key, fallback))
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
    var options = app && app.gameRuleOptions ? app.gameRuleOptions() : []
    return RulePreferences.normalizeVisibility(options, {}, false)
}

function defaultCommonRuleOrder(app) {
    return RulePreferences.defaultOrder()
}

function normalizeRuleVisibilityMap(app, source) {
    var options = app && app.gameRuleOptions ? app.gameRuleOptions() : []
    return RulePreferences.normalizeVisibility(options, source, true)
}

function normalizeCommonRuleOrder(app, source) {
    var options = app && app.gameRuleOptions ? app.gameRuleOptions() : []
    var order = Array.isArray(source) ? source : RulePreferences.defaultOrder()
    return RulePreferences.normalizeOrder(options, order, app.ruleVisibilityMap)
}

function settingNumberEquals(value, expected) {
    return Math.abs(Number(value) - Number(expected)) < 0.000001
}

function migratePersistentSettings(app) {
    if (app.loadedSettingsVersion < 3)
        app.ruleVisibilityMap = defaultRuleVisibilityMap(app)
    app.loadedSettingsVersion = app.currentSettingsVersion
}

// The facade alone touches QML properties or the settings backend. Schema
// operations consume detached value objects, never a window or controller.
function persistentSettingsSnapshot(app) {
    var values = ({})
    for (var i = 0; i < SettingsSchema.fields.length; ++i) {
        var property = SettingsSchema.fields[i].property
        values[property] = app[property]
    }
    return SettingsSchema.snapshot(values)
}

function applyPersistentSetting(app, entry, value) {
    if (entry.key === "ruleVisibilityJson")
        value = normalizeRuleVisibilityMap(app, value)
    else if (entry.key === "commonRuleOrderJson")
        value = normalizeCommonRuleOrder(app, value)
    else if (entry.key === "enginePresetsJson")
        value = EnginePresets.parseList(app, value)
    else if (entry.key === "komi")
        value = app.clampKomiValue(value)
    else if (entry.key === "analysisWideRootNoise")
        value = app.clampAnalysisWideRootNoise(value)
    app[entry.property] = value
}

function loadPersistentSettings(app, settings) {
    var defaults = persistentSettingsSnapshot(app)
    var raw = ({})
    for (var i = 0; i < SettingsSchema.fields.length; ++i) {
        var entry = SettingsSchema.fields[i]
        raw[entry.key] = settingValue(settings, entry.key, SettingsSchema.defaultValue(entry, defaults))
    }
    var values = SettingsSchema.read(raw, defaults)
    for (var j = 0; j < SettingsSchema.fields.length; ++j) {
        var field = SettingsSchema.fields[j]
        applyPersistentSetting(app, field, values[field.property])
    }
    // Version migrations deliberately follow all reads and special adapters.
    migratePersistentSettings(app)
}

function savePersistentSettings(app, settings, engineController) {
    if (!settings)
        return
    var values = persistentSettingsSnapshot(app)
    values.loadedSettingsVersion = app.currentSettingsVersion
    values.ruleVisibilityMap = normalizeRuleVisibilityMap(app, app.ruleVisibilityMap)
    values.commonRuleOrder = normalizeCommonRuleOrder(app, app.commonRuleOrder)
    values.enginePresets = EnginePresets.serializeList(app.enginePresets)
    values.persistedEngineCommand = engineController ? engineController.command : app.persistedEngineCommand
    var raw = SettingsSchema.write(values)
    for (var i = 0; i < SettingsSchema.fields.length; ++i) {
        var key = SettingsSchema.fields[i].key
        settings.setValue(key, raw[key])
    }
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
