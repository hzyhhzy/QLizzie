.pragma library

function normalizedVisitCount(value) {
    var number = Number(value)
    if (isNaN(number) || !isFinite(number) || number < 0)
        return -1
    return Math.floor(number)
}

function isSymmetryCandidate(candidate) {
    if (!candidate)
        return false
    if (candidate.isSymmetry === true)
        return true
    return candidate.isSymmetryOf !== undefined
           && candidate.isSymmetryOf !== null
           && String(candidate.isSymmetryOf).length > 0
}

function totalVisits(candidates) {
    if (!candidates || candidates.length <= 0)
        return -1

    var total = 0
    var found = false
    for (var index = 0; index < candidates.length; ++index) {
        var candidate = candidates[index]
        if (!candidate || isSymmetryCandidate(candidate))
            continue
        var visits = normalizedVisitCount(candidate.visits)
        if (visits < 0)
            continue
        total += visits
        found = true
    }
    return found ? total : -1
}

function nextSample(samples, key, total, nowMs, maximumSamples, maximumAgeMs) {
    var normalizedTotal = normalizedVisitCount(total)
    var timestamp = Number(nowMs)
    if (String(key).length <= 0 || normalizedTotal < 0
            || isNaN(timestamp) || !isFinite(timestamp)) {
        return { "samples": [], "speed": -1 }
    }

    var capacity = Math.max(1, Math.floor(Number(maximumSamples) || 4))
    var maximumAge = Math.max(1, Number(maximumAgeMs) || 5000)
    var matching = []
    var source = samples || []
    for (var index = 0; index < source.length; ++index) {
        var sample = source[index]
        if (!sample || String(sample.key) !== String(key))
            continue
        var sampleTotal = normalizedVisitCount(sample.total)
        var sampleTime = Number(sample.time)
        var age = timestamp - sampleTime
        if (sampleTotal < 0 || isNaN(sampleTime) || !isFinite(sampleTime)
                || age <= 0 || age > maximumAge)
            continue
        matching.push({
                          "key": String(key),
                          "total": sampleTotal,
                          "time": sampleTime
                      })
    }

    if (matching.length > 0
            && normalizedTotal < matching[matching.length - 1].total) {
        matching = []
    }

    var speed = -1
    if (matching.length > 0) {
        var baseline = matching[0]
        var elapsedMs = timestamp - baseline.time
        var delta = normalizedTotal - baseline.total
        if (elapsedMs > 0 && delta >= 0)
            speed = Math.floor(delta * 1000 / elapsedMs)
    }

    if (normalizedTotal > 0) {
        matching.push({
                          "key": String(key),
                          "total": normalizedTotal,
                          "time": timestamp
                      })
        while (matching.length > capacity)
            matching.shift()
    }

    return { "samples": matching, "speed": speed }
}
