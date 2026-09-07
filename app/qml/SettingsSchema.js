.pragma library

// One ordered schema drives both sides of the settings.ini contract. Unless
// a field declares a wire default, its fallback comes from the supplied startup
// configuration snapshot, so application defaults have a single owner.
var fields = [
    field("settingsVersion", "loadedSettingsVersion", "number"),
    field("language", "language", "string"),
    field("firstLaunchCompleted", "firstLaunchCompleted", "boolean"),
    field("showBeginnerTutorialOnNextLaunch", "showBeginnerTutorialOnNextLaunch", "boolean"),
    field("boardSizeX", "boardSizeX", "number"),
    field("boardSizeY", "boardSizeY", "number"),
    field("gameRuleMode", "gameRuleMode", "number"),
    field("ruleVisibilityJson", "ruleVisibilityMap", "json-object", "{}"),
    field("commonRuleOrderJson", "commonRuleOrder", "json-array", "[]"),
    field("gomokuRuleMode", "gomokuRuleMode", "number"),
    field("gomokuRuleMaxMoves", "gomokuRuleMaxMoves", "number"),
    field("gomokuRuleVcn", "gomokuRuleVcn", "string"),
    field("gomokuRuleFirstPassWin", "gomokuRuleFirstPassWin", "boolean"),
    field("goScoringRule", "goScoringRule", "number"),
    field("goKoRule", "goKoRule", "number"),
    field("goSuicideAllowed", "goSuicideAllowed", "boolean"),
    field("goTaxRule", "goTaxRule", "number"),
    field("goWhiteHandicapBonus", "goWhiteHandicapBonus", "string"),
    field("goButtonRule", "goButtonRule", "boolean"),
    field("komi", "komi", "number"),
    field("moveNumberDisplayMode", "moveNumberDisplayMode", "number"),
    field("coordinateDisplayMode", "coordinateDisplayMode", "number"),
    field("boardPresentationMode", "boardPresentationMode", "number"),
    field("gomokuBoardPresentationMode", "gomokuBoardPresentationMode", "number"),
    field("torusGoBoardPresentationMode", "torusGoBoardPresentationMode", "number"),
    field("hexBoardStyle", "hexBoardStyle", "number"),
    field("hexBoardRotation", "hexBoardRotation", "number"),
    field("packageMode", "packageMode", "number"),
    field("ignoreGtpErrors", "ignoreGtpErrors", "boolean"),
    field("engineCommunicationLogLimit", "engineCommunicationLogLimit", "number"),
    field("engineCommunicationLogCharacterLimit", "engineCommunicationLogCharacterLimit", "number"),
    field("engineCommunicationLineCharacterLimit", "engineCommunicationLineCharacterLimit", "number"),
    field("enginePresetsJson", "enginePresets", "engine-presets", ""),
    field("defaultEngineId", "defaultEngineId", "string"),
    field("activeEngineId", "activeEngineId", "string"),
    field("engineStartupMode", "engineStartupMode", "number"),
    field("engineCommand", "persistedEngineCommand", "string"),
    field("legacyHexEngineCoordinates", "legacyHexEngineCoordinates", "boolean"),
    field("analysisIntervalCentiseconds", "analysisIntervalCentiseconds", "number"),
    field("maxAnalysisSeconds", "maxAnalysisSeconds", "number"),
    field("analysisWideRootNoiseEnabled", "analysisWideRootNoiseEnabled", "boolean"),
    field("analysisWideRootNoise", "analysisWideRootNoise", "number"),
    field("candidateDisplayCount", "candidateDisplayCount", "number"),
    field("candidateTableRowLimit", "candidateTableRowLimit", "number"),
    field("candidateMinVisitRatio", "candidateMinVisitRatio", "number"),
    field("candidateShowFilteredMarkers", "candidateShowFilteredMarkers", "boolean"),
    field("candidateVariationPreviewVisible", "candidateVariationPreviewVisible", "boolean"),
    field("candidateVariationPreviewMaxMoves", "candidateVariationPreviewMaxMoves", "number"),
    field("candidateVariationPreviewOpacity", "candidateVariationPreviewOpacity", "number"),
    field("candidateWinrateLabelVisible", "candidateWinrateLabelVisible", "boolean"),
    field("candidateVisitsLabelVisible", "candidateVisitsLabelVisible", "boolean"),
    field("candidateScoreLabelVisible", "candidateScoreLabelVisible", "boolean"),
    field("candidateWinrateFontSize", "candidateWinrateFontSize", "number"),
    field("candidateVisitsFontSize", "candidateVisitsFontSize", "number"),
    field("candidateScoreFontSize", "candidateScoreFontSize", "number"),
    field("candidateWinrateBold", "candidateWinrateBold", "boolean"),
    field("candidateVisitsBold", "candidateVisitsBold", "boolean"),
    field("candidateScoreBold", "candidateScoreBold", "boolean"),
    field("candidateWinrateOffsetY", "candidateWinrateOffsetY", "number"),
    field("candidateVisitsOffsetY", "candidateVisitsOffsetY", "number"),
    field("candidateScoreOffsetY", "candidateScoreOffsetY", "number"),
    field("candidateWinrateDecimals", "candidateWinrateDecimals", "number"),
    field("candidateScoreDecimals", "candidateScoreDecimals", "number"),
    field("candidateWinrateShowPercent", "candidateWinrateShowPercent", "boolean"),
    field("candidateScoreShowPercent", "candidateScoreShowPercent", "boolean"),
    field("candidateScoreTitleMode", "candidateScoreTitleMode", "number"),
    field("candidateRingVisible", "candidateRingVisible", "boolean"),
    field("candidateRingLineWidth", "candidateRingLineWidth", "number"),
    field("candidateRankLabelVisible", "candidateRankLabelVisible", "boolean"),
    field("candidateFirstLabelTextColor", "candidateFirstLabelTextColor", "string"),
    field("candidateLabelTextColor", "candidateLabelTextColor", "string"),
    field("backgroundColor", "backgroundColor", "string"),
    field("boardWoodColor", "boardWoodColor", "string"),
    field("stoneScale", "stoneScale", "number"),
    field("gridOpacity", "gridOpacity", "number"),
    field("gridLineWidth", "gridLineWidth", "number"),
    field("selectedPointScale", "selectedPointScale", "number"),
    field("moveNumberLabelScale", "moveNumberLabelScale", "number"),
    field("secondsPerMove", "secondsPerMove", "number"),
    field("analysisSecondsPerMove", "analysisSecondsPerMove", "number"),
    field("aiMoveMode", "aiMoveMode", "number"),
    field("hideAnalysisDuringPlay", "hideAnalysisDuringPlay", "boolean"),
    field("analysisTotalVisitsPerMove", "analysisTotalVisitsPerMove", "number"),
    field("analysisFirstMoveVisitsPerMove", "analysisFirstMoveVisitsPerMove", "number"),
    field("resignMinMove", "resignMinMove", "number"),
    field("resignConsecutiveMoves", "resignConsecutiveMoves", "number"),
    field("resignWinrateThreshold", "resignWinrateThreshold", "number")
]

function field(key, property, type, missing) {
    var result = { "key": key, "property": property, "type": type }
    if (missing !== undefined)
        result.missing = missing
    return result
}

function copyValue(value) {
    if (!value || typeof value !== "object")
        return value
    var copy = Array.isArray(value) ? [] : ({})
    for (var key in value)
        copy[key] = copyValue(value[key])
    return copy
}

function defaultValue(entry, defaults) {
    return copyValue(entry.missing !== undefined ? entry.missing : defaults[entry.property])
}

function booleanValue(value) {
    if (typeof value === "boolean")
        return value
    var text = String(value).toLowerCase()
    return text === "true" || text === "1" || text === "yes"
}

function jsonValue(value, array, fallback) {
    try {
        var parsed = JSON.parse(String(value))
        if (parsed && typeof parsed === "object" && Array.isArray(parsed) === array)
            return parsed
    } catch (error) {
    }
    return copyValue(fallback)
}

function decode(entry, value, defaults) {
    if (entry.type === "number")
        return Number(value)
    if (entry.type === "boolean")
        return booleanValue(value)
    if (entry.type === "json-object" || entry.type === "json-array")
        return jsonValue(value, entry.type === "json-array", defaults[entry.property])
    // Engine preset JSON stays text until the facade applies EnginePresets'
    // existing parsing/normalization policy in the original load sequence.
    return String(value)
}

function read(rawSettings, defaults) {
    var values = ({})
    defaults = defaults || ({})
    rawSettings = rawSettings || ({})
    for (var i = 0; i < fields.length; ++i) {
        var entry = fields[i]
        var raw = Object.prototype.hasOwnProperty.call(rawSettings, entry.key)
                ? rawSettings[entry.key] : defaultValue(entry, defaults)
        values[entry.property] = decode(entry, raw, defaults)
    }
    return values
}

function write(values) {
    var rawSettings = ({})
    for (var i = 0; i < fields.length; ++i) {
        var entry = fields[i]
        var value = values[entry.property]
        rawSettings[entry.key] = entry.type === "json-object" || entry.type === "json-array"
                ? JSON.stringify(value) : value
    }
    return rawSettings
}

function snapshot(values) {
    var result = ({})
    for (var i = 0; i < fields.length; ++i) {
        var property = fields[i].property
        result[property] = copyValue(values[property])
    }
    return result
}
