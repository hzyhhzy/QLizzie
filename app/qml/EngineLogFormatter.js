.pragma library

function escapeHtml(value) {
    return String(value)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
}

function streamVisible(stream, showStdin, showStdout, showStderr) {
    if (stream === "stdin")
        return showStdin
    if (stream === "stdout")
        return showStdout
    if (stream === "stderr")
        return showStderr
    return true
}

function safeColor(color) {
    var value = String(color || "")
    return /^#[0-9a-fA-F]{6}$/.test(value) ? value : "#d9e6ee"
}

function buildHtml(model, showStdin, showStdout, showStderr) {
    if (!model)
        return ""

    var lines = []
    var count = Number(model.count)
    if (isNaN(count))
        count = model.length || 0
    for (var index = 0; index < count; ++index) {
        var entry = model.get ? model.get(index) : model[index]
        if (!entry || !streamVisible(entry.stream, showStdin, showStdout, showStderr))
            continue
        lines.push("<span style=\"color:" + safeColor(entry.color) + "\">"
                   + escapeHtml(entry.line)
                   + "</span>")
    }

    if (lines.length === 0)
        return ""
    return "<pre style=\"margin:0; white-space:pre-wrap;"
           + " font-family:'JetBrains Mono'; font-weight:500;\">"
           + lines.join("\n") + "</pre>"
}
