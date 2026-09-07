.pragma library
.import "RuleRegistry.js" as RuleRegistry

// Settings loading and the live rule menus share these value-only operations.
function defaultOrder() {
    return [RuleRegistry.RULE_GO, RuleRegistry.RULE_GOMOKU, RuleRegistry.RULE_HEX]
}

function normalizeVisibility(options, source, preserveUnknown) {
    var map = source || ({})
    var next = ({})
    for (var i = 0; i < options.length; ++i) {
        var mode = options[i].value
        var key = String(mode)
        next[key] = typeof map[key] === "boolean" ? map[key]
                   : RuleRegistry.hasCapability(mode, "defaultVisible")
    }
    if (preserveUnknown && options.length === 0) {
        for (var existing in map) {
            if (typeof map[existing] === "boolean")
                next[existing] = map[existing]
        }
    }
    return next
}

function normalizeOrder(options, source, visibility) {
    var order = Array.isArray(source) ? source : []
    var map = normalizeVisibility(options, visibility, false)
    var used = ({})
    var next = []
    var sequence = order.slice()
    for (var i = 0; i < options.length; ++i)
        sequence.push(options[i].value)
    for (var j = 0; j < sequence.length; ++j) {
        var mode = Number(sequence[j])
        var key = String(mode)
        if (map[key] === true && !used[key]) {
            next.push(mode)
            used[key] = true
        }
    }
    return next
}

function setVisible(options, order, visibility, modes, visible) {
    var map = normalizeVisibility(options, visibility, false)
    for (var i = 0; modes && i < modes.length; ++i) {
        var key = String(modes[i])
        if (map[key] !== undefined)
            map[key] = visible === true
    }
    return { "visibility": map, "order": normalizeOrder(options, order, map) }
}

function move(order, mode, delta) {
    var next = order.slice()
    var from = next.indexOf(mode)
    if (from < 0)
        return next
    var to = Math.max(0, Math.min(next.length - 1, from + delta))
    next.splice(to, 0, next.splice(from, 1)[0])
    return next
}
