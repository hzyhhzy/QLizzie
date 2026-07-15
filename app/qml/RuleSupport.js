.pragma library
.import "rules/RuleCatalog.js" as RuleCatalog
.import "rules/RuleRegistry.js" as RuleRegistry

function gomokuRuleLabel(app, rule) {
    if (rule === app.gomokuRuleStandard)
        return app.trText("gomokuRuleStandard")
    if (rule === app.gomokuRuleRenju)
        return app.trText("gomokuRuleRenju")
    if (rule === app.gomokuRuleCaro)
        return app.trText("gomokuRuleCaro")
    if (rule === app.gomokuRuleCaroNoSix)
        return app.trText("gomokuRuleCaroNoSix")
    if (rule === app.gomokuRuleDirectFour)
        return app.trText("gomokuRuleDirectFour")
    return app.trText("gomokuRuleFreestyle")
}

function gomokuRuleTip(app, rule) {
    if (rule === app.gomokuRuleStandard)
        return app.trText("gomokuRuleStandardTip")
    if (rule === app.gomokuRuleRenju)
        return app.trText("gomokuRuleRenjuTip")
    if (rule === app.gomokuRuleCaro)
        return app.trText("gomokuRuleCaroTip")
    if (rule === app.gomokuRuleCaroNoSix)
        return app.trText("gomokuRuleCaroNoSixTip")
    if (rule === app.gomokuRuleDirectFour)
        return app.trText("gomokuRuleDirectFourTip")
    return app.trText("gomokuRuleFreestyleTip")
}

function gomokuRuleEngineValue(app, rule) {
    if (rule === app.gomokuRuleStandard)
        return "STANDARD"
    if (rule === app.gomokuRuleRenju)
        return "RENJU"
    if (rule === app.gomokuRuleCaro)
        return "CARO"
    if (rule === app.gomokuRuleCaroNoSix)
        return "CARO_NOSIX"
    if (rule === app.gomokuRuleDirectFour)
        return "DIRECT_FOUR"
    return "FREESTYLE"
}

function normalizedGomokuRuleMode(app, rule) {
    var value = Math.round(Number(rule))
    if (value === app.gomokuRuleStandard
            || value === app.gomokuRuleRenju
            || value === app.gomokuRuleCaro
            || value === app.gomokuRuleCaroNoSix
            || value === app.gomokuRuleDirectFour)
        return value
    return app.gomokuRuleFreestyle
}

function normalizedGomokuVcnRule(app, rule) {
    var value = String(rule || "NOVC").toUpperCase()
    if (value === "VCTB" || value === "VCTW" || value === "VC2B" || value === "VC2W")
        return value
    return "NOVC"
}

function goRulesObject(app) {
    return {
        "scoring": app.goScoringRule === app.goScoringTerritory ? "TERRITORY" : "AREA",
        "ko": app.goKoRule === app.goKoSimple ? "SIMPLE"
              : app.goKoRule === app.goKoSituational ? "SITUATIONAL" : "POSITIONAL",
        "suicide": app.goSuicideAllowed === true,
        "tax": app.goTaxRule === app.goTaxAll ? "ALL"
               : app.goTaxRule === app.goTaxSeki ? "SEKI" : "NONE",
        "whiteHandicapBonus": app.goWhiteHandicapBonus === "0" || app.goWhiteHandicapBonus === "N-1"
                               ? app.goWhiteHandicapBonus : "N",
        "hasButton": app.goButtonRule === true
    }
}

function torusGoRulesObject(app) {
    return {
        "koRule": "SIMPLE",
        "scoringRule": "AREA",
        "taxRule": "NONE",
        "multiStoneSuicideLegal": false,
        "hasButton": false
    }
}

function twoLibGoRulesObject(app) {
    return {
        "ko": "SIMPLE",
        "suicide": true
    }
}

function gomokuRulesObject(app) {
    var firstPassWin = app.gomokuRuleFirstPassWin === true
    return {
        "basicrule": gomokuRuleEngineValue(app, app.gomokuRuleMode),
        "maxmoves": Math.max(0, Math.round(Number(app.gomokuRuleMaxMoves))),
        "firstpasswin": firstPassWin,
        "vcnrule": firstPassWin ? "NOVC" : normalizedGomokuVcnRule(app, app.gomokuRuleVcn)
    }
}

function goRuleLabel(app) {
    var rules = goRulesObject(app)
    if (rules.scoring === "AREA" && rules.ko === "POSITIONAL" && rules.suicide
            && rules.tax === "NONE" && rules.whiteHandicapBonus === "N" && !rules.hasButton)
        return app.trText("goRuleTrompTaylor")
    if (rules.scoring === "AREA" && rules.tax === "NONE" && !rules.hasButton)
        return app.trText("goRuleChinese")
    if (rules.scoring === "AREA" && rules.tax === "ALL" && !rules.hasButton)
        return app.trText("goRuleChineseAncient")
    if (rules.scoring === "TERRITORY" && rules.tax === "SEKI")
        return app.trText("goRuleJapanese")
    return app.trText("customRule")
}

function ruleVariantText(app) {
    if (app.gameRuleMode === app.gameRuleGo)
        return goRuleLabel(app)
    if (app.gameRuleMode === app.gameRuleGomoku)
        return gomokuRuleLabel(app, app.gomokuRuleMode)
    return app.trText("noRuleVariantShort")
}

function ruleOption(app, labelKey, value, tipKey, groupKeys) {
    var label = app.trText(labelKey)
    var path = []
    for (var i = 0; groupKeys && i < groupKeys.length; ++i)
        path.push(app.trText(groupKeys[i]))
    return {
        "label": label,
        "value": value,
        "tip": app.trText(tipKey),
        "path": path,
        "fullLabel": path.length > 0 ? path.join(" - ") + " - " + label : label
    }
}

function ruleOptionFromRegistry(app, mode, groupKeys) {
    var item = RuleRegistry.descriptor(mode)
    if (!item)
        return ruleOption(app, "gameRuleGomoku", mode, "gameRuleGomokuTip", groupKeys)
    return ruleOption(app, item.textKey, item.id, item.tipKey, groupKeys)
}

function ruleGroup(labelKey, children) {
    return {
        "type": "group",
        "labelKey": labelKey,
        "children": children || []
    }
}

function ruleLeaf(option) {
    return {
        "type": "leaf",
        "option": option
    }
}

function gameRuleTree(app) {
    return [
        ruleLeaf(ruleOptionFromRegistry(app, RuleRegistry.RULE_GO, [])),
        ruleLeaf(ruleOptionFromRegistry(app, RuleRegistry.RULE_GOMOKU, [])),
        ruleGroup("ruleGroupGoVariants", [
            ruleLeaf(ruleOptionFromRegistry(app, RuleRegistry.RULE_TWO_LIB_GO,
                                       ["ruleGroupGoVariants"])),
            ruleLeaf(ruleOptionFromRegistry(app, RuleRegistry.RULE_TORUS_GO,
                                       ["ruleGroupGoVariants"])),
            ruleGroup("ruleGroupHexGo", [
                ruleLeaf(ruleOptionFromRegistry(app, RuleRegistry.RULE_HEX_GO_PARALLELOGRAM,
                                           ["ruleGroupGoVariants", "ruleGroupHexGo"])),
                ruleLeaf(ruleOptionFromRegistry(app, RuleRegistry.RULE_HEX_GO_HEXAGON,
                                           ["ruleGroupGoVariants", "ruleGroupHexGo"])),
                ruleLeaf(ruleOptionFromRegistry(app, RuleRegistry.RULE_HEX_GO_TRIANGLE,
                                           ["ruleGroupGoVariants", "ruleGroupHexGo"]))
            ])
        ]),
        ruleGroup("ruleGroupGomokuVariants", [
            ruleLeaf(ruleOptionFromRegistry(app, RuleRegistry.RULE_CONNECT6,
                                       ["ruleGroupGomokuVariants"]))
        ]),
        ruleGroup("ruleGroupCommonNewGames", [
            ruleLeaf(ruleOptionFromRegistry(app, RuleRegistry.RULE_HEX,
                                       ["ruleGroupCommonNewGames"])),
            ruleLeaf(ruleOptionFromRegistry(app, RuleRegistry.RULE_DOTS_AND_BOXES,
                                       ["ruleGroupCommonNewGames"])),
            ruleLeaf(ruleOptionFromRegistry(app, RuleRegistry.RULE_REVERSI,
                                       ["ruleGroupCommonNewGames"])),
            ruleLeaf(ruleOptionFromRegistry(app, RuleRegistry.RULE_ATAXX,
                                       ["ruleGroupCommonNewGames"])),
            ruleLeaf(ruleOptionFromRegistry(app, RuleRegistry.RULE_BREAKTHROUGH,
                                       ["ruleGroupCommonNewGames"]))
        ]),
        ruleGroup("ruleGroupOther", [
            ruleLeaf(ruleOptionFromRegistry(app, RuleRegistry.RULE_SQUARE_FREE,
                                       ["ruleGroupOther"]))
        ])
    ]
}

function collectRuleOptions(nodes, options) {
    for (var i = 0; nodes && i < nodes.length; ++i) {
        var node = nodes[i]
        if (node.type === "leaf")
            options.push(node.option)
        else
            collectRuleOptions(node.children, options)
    }
}

function gameRuleTextForMode(app, mode) {
    var item = RuleRegistry.descriptor(mode)
    if (item)
        return app.trText(item.textKey)
    return app.trText("gameRuleGomoku")
}

function gameRuleText(app) {
    return gameRuleTextForMode(app, app.gameRuleMode)
}

function gameRuleOptions(app) {
    var options = []
    collectRuleOptions(gameRuleTree(app), options)
    return options
}

function ruleModeTipForMode(app, mode) {
    var options = gameRuleOptions(app)
    for (var i = 0; i < options.length; ++i) {
        if (options[i].value === mode)
            return options[i].tip
    }
    return ""
}

function validRuleMode(app, mode) {
    return RuleRegistry.validMode(mode)
}

function ruleUsesHexGrid(app, mode) {
    return RuleRegistry.hasCapability(mode, "hexGrid")
}

function ruleUsesGoCapture(app, mode) {
    return RuleRegistry.hasCapability(mode, "goCapture")
}

function ruleUsesSquareCells(app, mode) {
    return (mode === app.gameRuleGomoku && app.boardPresentationMode === app.boardPresentationCells)
           || RuleRegistry.hasCapability(mode, "squareCells")
}

function ruleUsesDotsAndBoxes(app, mode) {
    return RuleRegistry.hasCapability(mode, "dotsAndBoxes")
}

function ruleUsesHexCellStyle(app, mode) {
    return mode === app.gameRuleHex && app.hexBoardStyle === app.hexBoardStyleCells
}

function ruleAllowsOccupiedMoves(app, mode) {
    return RuleRegistry.hasCapability(mode, "allowsOccupiedMoves")
}

function ruleUsesMoveSource(app, mode) {
    return RuleRegistry.hasCapability(mode, "moveSource")
}

function ruleHasBoardPresentation(app, mode) {
    return RuleCatalog.boardPresentationOptions(app, mode).length > 1
}

function ruleHasHexBoardStyle(app, mode) {
    return mode === app.gameRuleHex && RuleCatalog.hexBoardStyleOptions(app, mode).length > 1
}

function ruleHasHexRotation(app, mode) {
    return ruleUsesHexGrid(app, mode) && RuleCatalog.hexBoardRotationOptions(app, mode).length > 1
}

function ruleVisibilityKey(app, mode) {
    return String(mode)
}

function defaultCommonRuleOrder(app) {
    return [RuleRegistry.RULE_GO, RuleRegistry.RULE_GOMOKU, RuleRegistry.RULE_HEX]
}

function defaultRuleModeVisible(app, mode) {
    return RuleRegistry.hasCapability(mode, "defaultVisible")
}

function normalizedRuleVisibilityMap(app, source) {
    var map = source || {}
    var options = gameRuleOptions(app)
    var next = {}
    for (var i = 0; i < options.length; ++i) {
        var key = ruleVisibilityKey(app, options[i].value)
        next[key] = typeof map[key] === "boolean" ? map[key]
                                                  : defaultRuleModeVisible(app, options[i].value)
    }
    return next
}

function ruleOptionForMode(app, mode) {
    var options = gameRuleOptions(app)
    for (var i = 0; i < options.length; ++i) {
        if (options[i].value === mode)
            return options[i]
    }
    return null
}

function normalizedCommonRuleOrder(app, source) {
    var order = Array.isArray(source) ? source : []
    var map = normalizedRuleVisibilityMap(app, app.ruleVisibilityMap)
    var used = {}
    var next = []
    for (var i = 0; i < order.length; ++i) {
        var mode = Number(order[i])
        var key = ruleVisibilityKey(app, mode)
        if (!used[key] && map[key] === true && ruleOptionForMode(app, mode)) {
            next.push(mode)
            used[key] = true
        }
    }
    var options = gameRuleOptions(app)
    for (var j = 0; j < options.length; ++j) {
        var option = options[j]
        var optionKey = ruleVisibilityKey(app, option.value)
        if (!used[optionKey] && map[optionKey] === true) {
            next.push(option.value)
            used[optionKey] = true
        }
    }
    return next
}

function syncCommonRuleOrder(app) {
    app.commonRuleOrder = normalizedCommonRuleOrder(app, app.commonRuleOrder)
}

function ruleModeVisible(app, mode) {
    var key = ruleVisibilityKey(app, mode)
    var map = normalizedRuleVisibilityMap(app, app.ruleVisibilityMap)
    return map[key] !== false
}

function ruleGroupVisible(app, modes) {
    for (var i = 0; modes && i < modes.length; ++i) {
        if (ruleModeVisible(app, modes[i]))
            return true
    }
    return false
}

function setRuleModeVisible(app, mode, visible) {
    var key = ruleVisibilityKey(app, mode)
    var map = normalizedRuleVisibilityMap(app, app.ruleVisibilityMap)
    map[key] = visible === true
    app.ruleVisibilityMap = map
    if (visible === true) {
        var order = normalizedCommonRuleOrder(app, app.commonRuleOrder)
        var found = false
        for (var i = 0; i < order.length; ++i) {
            if (order[i] === mode) {
                found = true
                break
            }
        }
        if (!found)
            order.push(mode)
        app.commonRuleOrder = normalizedCommonRuleOrder(app, order)
    } else {
        app.commonRuleOrder = normalizedCommonRuleOrder(app, app.commonRuleOrder)
    }
    if (app.persistentSettingsLoaded)
        app.savePersistentSettings()
}

function ruleNodeModes(node, modes) {
    var result = modes || []
    if (!node)
        return result
    if (node.type === "leaf") {
        result.push(node.option.value)
    } else {
        for (var i = 0; node.children && i < node.children.length; ++i)
            ruleNodeModes(node.children[i], result)
    }
    return result
}

function setRuleModesVisible(app, modes, visible) {
    var map = normalizedRuleVisibilityMap(app, app.ruleVisibilityMap)
    for (var i = 0; modes && i < modes.length; ++i) {
        var mode = modes[i]
        var key = ruleVisibilityKey(app, mode)
        map[key] = visible === true
    }
    app.ruleVisibilityMap = map
    app.commonRuleOrder = normalizedCommonRuleOrder(app, app.commonRuleOrder)
    if (app.persistentSettingsLoaded)
        app.savePersistentSettings()
}

function ruleGroupVisibilityCheckState(app, modes) {
    var total = 0
    var visible = 0
    for (var i = 0; modes && i < modes.length; ++i) {
        ++total
        if (ruleModeVisible(app, modes[i]))
            ++visible
    }
    if (total <= 0 || visible <= 0)
        return 0
    if (visible >= total)
        return 2
    return 1
}

function ruleGroupHasMutableVisibility(app, modes) {
    return !!modes && modes.length > 0
}

function commonGameRuleOptions(app) {
    var order = normalizedCommonRuleOrder(app, app.commonRuleOrder)
    var visible = []
    for (var i = 0; i < order.length; ++i) {
        var option = ruleOptionForMode(app, order[i])
        if (option)
            visible.push(option)
    }
    return visible
}

function moveCommonRule(app, mode, delta) {
    var order = normalizedCommonRuleOrder(app, app.commonRuleOrder)
    var from = -1
    for (var i = 0; i < order.length; ++i) {
        if (order[i] === mode) {
            from = i
            break
        }
    }
    if (from < 0)
        return
    var to = Math.max(0, Math.min(order.length - 1, from + delta))
    if (to === from)
        return
    var item = order.splice(from, 1)[0]
    order.splice(to, 0, item)
    app.commonRuleOrder = order
    if (app.persistentSettingsLoaded)
        app.savePersistentSettings()
}

function visibleGameRuleOptions(app) {
    return commonGameRuleOptions(app)
}

function commonGameRuleOptionsWithModeAndMore(app, mode) {
    var options = commonGameRuleOptions(app)
    var hasCurrent = false
    for (var i = 0; i < options.length; ++i) {
        if (options[i].value === mode) {
            hasCurrent = true
            break
        }
    }
    if (!hasCurrent) {
        var allOptions = gameRuleOptions(app)
        for (var j = 0; j < allOptions.length; ++j) {
            if (allOptions[j].value === mode) {
                options = [allOptions[j]].concat(options)
                break
            }
        }
    }
    options = options.slice()
    options.push({
                     "label": app.trText("moreRules"),
                     "value": app.gameRuleMoreOption,
                     "tip": app.trText("moreRulesTip"),
                     "path": [],
                     "fullLabel": app.trText("moreRules")
                 })
    return options
}

function commonGameRuleOptionsWithCurrentAndMore(app) {
    return commonGameRuleOptionsWithModeAndMore(app, app.gameRuleMode)
}

function appendRuleTreeRows(app, nodes, depth, rows, collapsedGroups, parentId) {
    for (var i = 0; nodes && i < nodes.length; ++i) {
        var node = nodes[i]
        if (node.type === "leaf") {
            var option = node.option
            rows.push({
                          "type": "leaf",
                          "depth": depth,
                          "label": option.label,
                          "fullLabel": option.fullLabel,
                          "tip": option.tip,
                          "value": option.value
                      })
        } else {
            var groupId = parentId && parentId.length > 0 ? parentId + "/" + node.labelKey : node.labelKey
            var collapsed = collapsedGroups && collapsedGroups[groupId] === true
            var modes = ruleNodeModes(node, [])
            rows.push({
                          "type": "group",
                          "depth": depth,
                          "label": app.trText(node.labelKey),
                          "fullLabel": app.trText(node.labelKey),
                          "tip": "",
                          "value": -1,
                          "groupId": groupId,
                          "collapsed": collapsed,
                          "modes": modes
                      })
            if (!collapsed)
                appendRuleTreeRows(app, node.children, depth + 1, rows, collapsedGroups, groupId)
        }
    }
}

function ruleTreeRows(app, collapsedGroups) {
    var rows = []
    appendRuleTreeRows(app, gameRuleTree(app), 0, rows, collapsedGroups || {}, "")
    return rows
}

function appendCollapsedRuleGroups(nodes, parentId, groups) {
    for (var i = 0; nodes && i < nodes.length; ++i) {
        var node = nodes[i]
        if (node.type !== "group")
            continue
        var groupId = parentId && parentId.length > 0 ? parentId + "/" + node.labelKey : node.labelKey
        groups[groupId] = true
        appendCollapsedRuleGroups(node.children, groupId, groups)
    }
}

function allRuleGroupsCollapsed(app) {
    var groups = {}
    appendCollapsedRuleGroups(gameRuleTree(app), "", groups)
    return groups
}

function gameRuleCurrentIndex(app) {
    var options = gameRuleOptions(app)
    for (var i = 0; i < options.length; ++i) {
        if (options[i].value === app.gameRuleMode)
            return i
    }
    return 0
}

function setGameRuleFromIndex(app, index) {
    var options = gameRuleOptions(app)
    if (index < 0 || index >= options.length)
        return
    app.requestRuleModeChange(options[index].value)
}

function visibleGameRuleCurrentIndex(app) {
    var options = commonGameRuleOptionsWithCurrentAndMore(app)
    for (var i = 0; i < options.length; ++i) {
        if (options[i].value === app.gameRuleMode)
            return i
    }
    return 0
}

function setVisibleGameRuleFromIndex(app, index) {
    var options = commonGameRuleOptionsWithCurrentAndMore(app)
    if (index < 0 || index >= options.length)
        return
    if (options[index].value === app.gameRuleMoreOption) {
        app.openRuleSelectionPopup()
        return
    }
    app.requestRuleModeChange(options[index].value)
}

function goRuleOptions(app) {
    return [{ "label": goRuleLabel(app), "value": -1, "tip": app.trText("goRuleTrompTaylorTip") }]
}

function gomokuRuleOptions(app) {
    return [
        { "label": gomokuRuleLabel(app, app.gomokuRuleFreestyle), "value": app.gomokuRuleFreestyle, "tip": gomokuRuleTip(app, app.gomokuRuleFreestyle) },
        { "label": gomokuRuleLabel(app, app.gomokuRuleStandard), "value": app.gomokuRuleStandard, "tip": gomokuRuleTip(app, app.gomokuRuleStandard) },
        { "label": gomokuRuleLabel(app, app.gomokuRuleRenju), "value": app.gomokuRuleRenju, "tip": gomokuRuleTip(app, app.gomokuRuleRenju) },
        { "label": gomokuRuleLabel(app, app.gomokuRuleCaro), "value": app.gomokuRuleCaro, "tip": gomokuRuleTip(app, app.gomokuRuleCaro) },
        { "label": gomokuRuleLabel(app, app.gomokuRuleCaroNoSix), "value": app.gomokuRuleCaroNoSix, "tip": gomokuRuleTip(app, app.gomokuRuleCaroNoSix) },
        { "label": gomokuRuleLabel(app, app.gomokuRuleDirectFour), "value": app.gomokuRuleDirectFour, "tip": gomokuRuleTip(app, app.gomokuRuleDirectFour) }
    ]
}

function ruleVariantOptions(app) {
    if (app.gameRuleMode === app.gameRuleGomoku)
        return gomokuRuleOptions(app)
    if (app.gameRuleMode === app.gameRuleGo)
        return goRuleOptions(app)
    return [{ "label": gameRuleText(app), "value": -1, "tip": "" }]
}

function ruleVariantCurrentIndex(app) {
    var options = ruleVariantOptions(app)
    if (app.gameRuleMode === app.gameRuleGo)
        return 0
    for (var i = 0; i < options.length; ++i) {
        if (options[i].value === app.gomokuRuleMode)
            return i
    }
    return 0
}

function ruleVariantCurrentTip(app) {
    var options = ruleVariantOptions(app)
    var index = ruleVariantCurrentIndex(app)
    return index >= 0 && index < options.length ? options[index].tip : ""
}

function setRuleVariantFromIndex(app, index) {
    var options = ruleVariantOptions(app)
    if (index < 0 || index >= options.length)
        return
    if (app.gameRuleMode === app.gameRuleGomoku) {
        app.gomokuRuleMode = normalizedGomokuRuleMode(app, options[index].value)
        app.rebuildPositionFromNode(app.currentNodeId)
        app.resetEngineSyncState()
        app.scheduleAutoAnalysis()
    }
}

function ruleModeButtonsVisible(app) {
    return false
}

function ruleVariantComboVisible(app) {
    return true
}

function toolbarRuleSettingsVisible(app) {
    return app.gameRuleMode === app.gameRuleGo
           || app.gameRuleMode === app.gameRuleGomoku
}

function toolbarBoardPresentationVisible(app) {
    return app.gameRuleMode === app.gameRuleTorusGo
}

function toolbarHexBoardStyleVisible(app) {
    return app.gameRuleMode === app.gameRuleHex
}

function toolbarHexBoardRotationVisible(app) {
    return app.gameRuleMode === app.gameRuleHex
           || app.gameRuleMode === app.gameRuleHexGoParallelogram
           || app.gameRuleMode === app.gameRuleHexGoTriangle
}

function toolbarPresentationControlsVisible(app) {
    return toolbarBoardPresentationVisible(app)
           || toolbarHexBoardStyleVisible(app)
           || toolbarHexBoardRotationVisible(app)
}

function komiUsageForRule(app, mode) {
    if (mode === app.gameRuleGo
            || mode === app.gameRuleTorusGo
            || mode === app.gameRuleTwoLibGo
            || mode === app.gameRuleSquareFree
            || mode === app.gameRuleReversi
            || mode === app.gameRuleHexGoParallelogram
            || mode === app.gameRuleHexGoHexagon
            || mode === app.gameRuleHexGoTriangle
            || mode === app.gameRuleAtaxx)
        return app.komiUsageKomi
    if (mode === app.gameRuleDotsAndBoxes)
        return app.komiUsageKomi
    if (mode === app.gameRuleGomoku
            || mode === app.gameRuleConnect6)
        return app.komiUsageBlackAggression
    return app.komiUsageNone
}

function currentKomiUsage(app) {
    return komiUsageForRule(app, app.gameRuleMode)
}

function komiControlsVisible(app) {
    return currentKomiUsage(app) !== app.komiUsageNone
}

function boardPresentationOptions(app) {
    return RuleCatalog.boardPresentationOptions(app, app.gameRuleMode)
}

function boardPresentationCurrentIndex(app) {
    return RuleCatalog.boardPresentationCurrentIndex(app)
}

function setBoardPresentationFromIndex(app, index) {
    var options = boardPresentationOptions(app)
    if (index < 0 || index >= options.length)
        return
    var next = RuleCatalog.normalizeBoardPresentationMode(app, app.gameRuleMode, options[index].value)
    if (app.gameRuleMode === app.gameRuleGomoku)
        app.gomokuBoardPresentationMode = next
    else if (app.gameRuleMode === app.gameRuleGo)
        app.goBoardPresentationMode = next
    else if (app.gameRuleMode === app.gameRuleTorusGo)
        app.torusGoBoardPresentationMode = next
    if (app.boardPresentationMode !== next) {
        app.boardPresentationMode = next
        app.boardRevision += 1
    }
}

function boardPresentationText(app, mode) {
    return RuleCatalog.boardPresentationText(app, mode)
}

function hexBoardStyleOptions(app) {
    return RuleCatalog.hexBoardStyleOptions(app, app.gameRuleMode)
}

function hexBoardStyleCurrentIndex(app) {
    return RuleCatalog.hexBoardStyleCurrentIndex(app)
}

function setHexBoardStyleFromIndex(app, index) {
    var options = hexBoardStyleOptions(app)
    if (index < 0 || index >= options.length)
        return
    var next = options[index].value
    if (app.hexBoardStyle === next)
        return
    app.hexBoardStyle = next
    app.boardRevision += 1
}

function hexBoardRotationOptions(app) {
    return RuleCatalog.hexBoardRotationOptions(app, app.gameRuleMode)
}

function hexBoardRotationCurrentIndex(app) {
    return RuleCatalog.hexBoardRotationCurrentIndex(app)
}

function setHexBoardRotationFromIndex(app, index) {
    var options = hexBoardRotationOptions(app)
    if (index < 0 || index >= options.length)
        return
    var next = options[index].value
    if (app.hexBoardRotation === next)
        return
    app.hexBoardRotation = next
    app.boardRevision += 1
}

function engineCommandEditable(app) {
    return app.packageMode === app.packageModeUniversal
}

function customBoardSizeAllowed(app) {
    return app.packageMode === app.packageModeUniversal
}

function boardSizePresets(app) {
    if (app.packageMode === app.packageModeGo)
        return [9, 13, 19]
    if (app.packageMode === app.packageModeSix)
        return [15, 19]

    if (app.gameRuleMode === app.gameRuleGo || app.gameRuleMode === app.gameRuleTorusGo
            || app.gameRuleMode === app.gameRuleTwoLibGo)
        return [9, 13, 19]
    if (app.gameRuleMode === app.gameRuleGomoku)
        return [12, 15, 19]
    if (app.gameRuleMode === app.gameRuleConnect6)
        return [15, 19]
    if (app.gameRuleMode === app.gameRuleHex)
        return [11, 13, 19]
    if (app.gameRuleMode === app.gameRuleHexGoParallelogram
            || app.gameRuleMode === app.gameRuleHexGoHexagon
            || app.gameRuleMode === app.gameRuleHexGoTriangle)
        return [13, 19]
    if (app.gameRuleMode === app.gameRuleReversi)
        return [6, 8, 10]
    if (app.gameRuleMode === app.gameRuleAtaxx)
        return [5, 7, 9]
    if (app.gameRuleMode === app.gameRuleBreakthrough)
        return [6, 8, 10]
    if (app.gameRuleMode === app.gameRuleDotsAndBoxes)
        return [5, 6]
    return [9, 13, 19]
}

function boardSizePresetAllowed(app, size) {
    return boardSizePresets(app).indexOf(size) >= 0
}

function boardDimensionsAllowedForPackage(app, xSize, ySize) {
    if (app.packageMode === app.packageModeUniversal)
        return true
    if (xSize !== ySize)
        return false
    return boardSizePresetAllowed(app, xSize)
}

function ruleModeAllowedForPackage(app, mode) {
    if (app.packageMode === app.packageModeGo)
        return mode === app.gameRuleGo
    if (app.packageMode === app.packageModeSix)
        return mode === app.gameRuleGomoku
    return validRuleMode(app, mode)
}

function packageDefaultBoardSize(app) {
    if (app.packageMode === app.packageModeGo)
        return 19
    if (app.packageMode === app.packageModeSix)
        return 15
    return app.defaultBoardSize
}

function packageModeText(app, mode) {
    if (mode === app.packageModeGo)
        return app.trText("packageModeGo")
    if (mode === app.packageModeSix)
        return app.trText("packageModeSix")
    return app.trText("packageModeUniversal")
}

function packageBoardSizeRejectText(app, xSize, ySize) {
    var dims = app.boardDimensionsTextForSize(xSize, ySize)
    if (app.packageMode === app.packageModeGo)
        return app.trText("packageBoardSizeRejected") + ": " + dims
    if (app.packageMode === app.packageModeSix)
        return app.trText("packageBoardSizeRejected") + ": " + dims + " (15x15 / 19x19)"
    return app.trText("packageBoardSizeRejected") + ": " + dims
}

function normalizeGomokuRuleForCurrentMode(app) {
    if (app.gameRuleMode !== app.gameRuleGomoku)
        return
    app.gomokuRuleMode = normalizedGomokuRuleMode(app, app.gomokuRuleMode)
    if (app.packageMode === app.packageModeSix && app.gomokuRuleMode !== app.gomokuRuleFreestyle
            && app.gomokuRuleMode !== app.gomokuRuleStandard
            && app.gomokuRuleMode !== app.gomokuRuleRenju
            && app.gomokuRuleMode !== app.gomokuRuleCaro
            && app.gomokuRuleMode !== app.gomokuRuleCaroNoSix
            && app.gomokuRuleMode !== app.gomokuRuleDirectFour)
        app.gomokuRuleMode = app.gomokuRuleFreestyle
}

function requestRuleModeChange(app, mode, dialog) {
    if (mode === app.gameRuleMode)
        return
    if (!ruleModeAllowedForPackage(app, mode))
        return
    if (app.gameDirty) {
        app.pendingClearAction = "ruleMode"
        app.pendingRuleMode = mode
        dialog.open()
        return
    }
    applyRuleModeChange(app, mode)
}

function activateRuleMode(app, mode) {
    if (!validRuleMode(app, mode))
        return false
    if (!ruleModeAllowedForPackage(app, mode))
        return false
    var previousKomiUsage = currentKomiUsage(app)
    app.gameRuleMode = mode
    app.adjustKomiForRuleChange(previousKomiUsage)
    if (mode === app.gameRuleHex)
        app.coordinateDisplayMode = app.coordinateDisplayHex
    app.boardPresentationMode = RuleCatalog.normalizeBoardPresentationMode(
                app, mode, RuleCatalog.rememberedBoardPresentationMode(app, mode))
    if (mode === app.gameRuleGo)
        app.goBoardPresentationMode = app.boardPresentationMode
    else if (mode === app.gameRuleGomoku)
        app.gomokuBoardPresentationMode = app.boardPresentationMode
    else if (mode === app.gameRuleTorusGo)
        app.torusGoBoardPresentationMode = app.boardPresentationMode
    normalizeGomokuRuleForCurrentMode(app)
    return true
}

function applyRuleModeChange(app, mode) {
    if (!activateRuleMode(app, mode))
        return
    var requestedX = mode === app.gameRuleDotsAndBoxes ? 11 : app.boardSizeX
    var requestedY = mode === app.gameRuleDotsAndBoxes ? 11 : app.boardSizeY
    var adjusted = adjustedBoardDimensionsForRule(app, mode, requestedX, requestedY)
    app.boardSizeX = adjusted.x
    app.boardSizeY = adjusted.y
    app.clearHover(true)
    app.resetGameTree()
    app.gameDirty = false
    app.statusMode = "message"
    app.statusMessage = app.trText("ruleChanged") + ": " + gameRuleText(app)
    app.resetEngineSyncState()
    app.scheduleAutoAnalysis()
    app.requestAiMoveIfNeeded()
    if (app.queueFocusBoardInput)
        app.queueFocusBoardInput()
    else
        app.focusBoardInput()
}

function logicalBoardDimensionForRule(app, mode, internalSize) {
    if (mode === app.gameRuleDotsAndBoxes)
        return Math.max(1, Math.floor((Number(internalSize) - 1) / 2))
    return Number(internalSize)
}

function internalBoardDimensionForRule(app, mode, logicalSize) {
    if (mode === app.gameRuleDotsAndBoxes)
        return Math.max(3, Math.round(Number(logicalSize)) * 2 + 1)
    return Math.round(Number(logicalSize))
}

function adjustedBoardDimensionsForRule(app, mode, xSize, ySize) {
    var nextX = Math.round(app.clamp(xSize, app.minBoardSize, app.maxBoardSize))
    var nextY = Math.round(app.clamp(ySize, app.minBoardSize, app.maxBoardSize))
    if (mode === app.gameRuleHexGoHexagon) {
        if (nextX % 2 === 0)
            nextX += 1
        nextX = Math.round(app.clamp(nextX, app.minBoardSize, app.maxBoardSize))
        nextY = nextX
    } else if (mode === app.gameRuleHexGoTriangle) {
        nextY = nextX
    } else if (mode === app.gameRuleBreakthrough && nextY <= 3) {
        nextY = 4
    } else if (mode === app.gameRuleDotsAndBoxes) {
        if (nextX % 2 === 0)
            nextX += 1
        if (nextY % 2 === 0)
            nextY += 1
    }
    return { "x": nextX, "y": nextY }
}

function boardDimensionsAllowedForRule(app, mode, xSize, ySize) {
    if (mode === app.gameRuleHexGoHexagon)
        return xSize === ySize && xSize % 2 === 1
    if (mode === app.gameRuleHexGoTriangle)
        return xSize === ySize
    if (mode === app.gameRuleBreakthrough)
        return ySize > 3
    if (mode === app.gameRuleDotsAndBoxes)
        return xSize >= 3 && ySize >= 3 && xSize % 2 === 1 && ySize % 2 === 1
    return true
}

function requestBoardDimensionsChange(app, xSize, ySize, markDirty, dialog) {
    var nextX = Math.round(app.clamp(xSize, app.minBoardSize, app.maxBoardSize))
    var nextY = Math.round(app.clamp(ySize, app.minBoardSize, app.maxBoardSize))
    if (!boardDimensionsAllowedForPackage(app, nextX, nextY)) {
        app.statusMode = "message"
        app.statusMessage = packageBoardSizeRejectText(app, nextX, nextY)
        return false
    }
    if (!boardDimensionsAllowedForRule(app, app.gameRuleMode, nextX, nextY)) {
        app.statusMode = "message"
        app.statusMessage = ruleBoardSizeRejectText(app, app.gameRuleMode, nextX, nextY)
        return false
    }
    if (nextX === app.boardSizeX && nextY === app.boardSizeY)
        return true
    if (app.gameDirty) {
        app.pendingClearAction = "boardSize"
        app.pendingBoardSizeX = nextX
        app.pendingBoardSizeY = nextY
        dialog.open()
        return false
    }
    return setBoardDimensions(app, nextX, nextY, markDirty)
}

function setBoardDimensions(app, xSize, ySize, markDirty) {
    var nextX = Math.round(app.clamp(xSize, app.minBoardSize, app.maxBoardSize))
    var nextY = Math.round(app.clamp(ySize, app.minBoardSize, app.maxBoardSize))
    if (!boardDimensionsAllowedForPackage(app, nextX, nextY)) {
        app.statusMode = "message"
        app.statusMessage = packageBoardSizeRejectText(app, nextX, nextY)
        return false
    }
    if (!boardDimensionsAllowedForRule(app, app.gameRuleMode, nextX, nextY)) {
        app.statusMode = "message"
        app.statusMessage = ruleBoardSizeRejectText(app, app.gameRuleMode, nextX, nextY)
        return false
    }
    if (nextX === app.boardSizeX && nextY === app.boardSizeY)
        return true
    app.boardSizeX = nextX
    app.boardSizeY = nextY
    app.clearHover(true)
    app.resetGameTree()
    app.setSelectedPoint(0, 0)
    if (markDirty !== false)
        app.gameDirty = true
    app.resetEngineSyncState()
    app.scheduleAutoAnalysis()
    app.requestAiMoveIfNeeded()
    return true
}

function ruleBoardSizeRejectText(app, mode, xSize, ySize) {
    var dims = app.boardDimensionsTextForSize(xSize, ySize)
    if (mode === app.gameRuleHexGoHexagon)
        return app.trText("hexGoHexagonBoardSizeRejected") + ": " + dims
    if (mode === app.gameRuleHexGoTriangle)
        return app.trText("hexGoTriangleBoardSizeRejected") + ": " + dims
    if (mode === app.gameRuleBreakthrough)
        return app.trText("breakthroughBoardSizeRejected") + ": " + dims
    return packageBoardSizeRejectText(app, xSize, ySize)
}

function resetBoardSize(app) {
    var size = packageDefaultBoardSize(app)
    setBoardDimensions(app, size, size)
}

function pendingClearMessage(app) {
    if (app.pendingClearAction === "openSgf")
        return app.trText("confirmOpenSgfSave")
    if (app.pendingClearAction === "boardSize")
        return app.trText("confirmBoardSizeChangeSave")
    if (app.pendingClearAction === "clearBoard")
        return app.trText("confirmClearBoardSave")
    return app.trText("confirmRuleChangeSave")
}

function pendingClearTitle(app) {
    return app.trText("clearGamePromptTitle")
}

function clearPendingClearAction(app) {
    app.pendingClearAction = ""
    app.pendingRuleMode = -1
    app.pendingBoardSizeX = -1
    app.pendingBoardSizeY = -1
}

function applyPendingClearAction(app, loadSgfDialog) {
    if (app.pendingClearAction === "ruleMode") {
        var mode = app.pendingRuleMode
        clearPendingClearAction(app)
        app.gameDirty = false
        applyRuleModeChange(app, mode)
        return
    }
    if (app.pendingClearAction === "boardSize") {
        var xSize = app.pendingBoardSizeX
        var ySize = app.pendingBoardSizeY
        clearPendingClearAction(app)
        app.gameDirty = false
        setBoardDimensions(app, xSize, ySize)
        return
    }
    if (app.pendingClearAction === "openSgf") {
        clearPendingClearAction(app)
        loadSgfDialog.open()
        return
    }
    if (app.pendingClearAction === "clearBoard") {
        clearPendingClearAction(app)
        app.gameDirty = false
        app.resetGameTree()
        return
    }
    clearPendingClearAction(app)
    app.focusBoardInput()
}
