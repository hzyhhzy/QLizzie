.pragma library

function finiteNumber(value, fallback) {
    var number = Number(value)
    return isFinite(number) ? number : fallback
}

function clamp(value, minimumValue, maximumValue) {
    return Math.max(minimumValue, Math.min(value, maximumValue))
}

function validScreenGeometry(screen) {
    if (!screen || !screen.availableGeometry)
        return null
    var geometry = screen.availableGeometry
    var width = finiteNumber(geometry.width, 0)
    var height = finiteNumber(geometry.height, 0)
    if (width <= 0 || height <= 0)
        return null
    return {
        "x": finiteNumber(geometry.x, 0),
        "y": finiteNumber(geometry.y, 0),
        "width": width,
        "height": height
    }
}

function availableGeometry(windowObject, ownerWindow) {
    var geometry = validScreenGeometry(windowObject ? windowObject.screen : null)
    if (geometry)
        return geometry

    geometry = validScreenGeometry(ownerWindow ? ownerWindow.screen : null)
    if (geometry)
        return geometry

    return {
        "x": finiteNumber(ownerWindow ? ownerWindow.x : 0, 0),
        "y": finiteNumber(ownerWindow ? ownerWindow.y : 0, 0),
        "width": Math.max(1, finiteNumber(ownerWindow ? ownerWindow.width : 1, 1)),
        "height": Math.max(1, finiteNumber(ownerWindow ? ownerWindow.height : 1, 1))
    }
}

function ownerAvailableGeometry(windowObject, ownerWindow) {
    var geometry = validScreenGeometry(ownerWindow ? ownerWindow.screen : null)
    return geometry || availableGeometry(windowObject, ownerWindow)
}

function applyGeometry(windowObject, geometry, width, height, x, y) {
    var minimumWidth = Math.max(1, finiteNumber(windowObject.minimumWidth, 1))
    var minimumHeight = Math.max(1, finiteNumber(windowObject.minimumHeight, 1))
    var nextWidth = Math.max(minimumWidth, Math.min(finiteNumber(width, minimumWidth),
                                                    geometry.width))
    var nextHeight = Math.max(minimumHeight, Math.min(finiteNumber(height, minimumHeight),
                                                      geometry.height))
    var maximumX = geometry.x + Math.max(0, geometry.width - nextWidth)
    var maximumY = geometry.y + Math.max(0, geometry.height - nextHeight)

    windowObject.width = Math.round(nextWidth)
    windowObject.height = Math.round(nextHeight)
    windowObject.x = Math.round(clamp(finiteNumber(x, geometry.x), geometry.x, maximumX))
    windowObject.y = Math.round(clamp(finiteNumber(y, geometry.y), geometry.y, maximumY))
}

function clampWindow(windowObject, ownerWindow) {
    var geometry = availableGeometry(windowObject, ownerWindow)
    applyGeometry(windowObject, geometry,
                  windowObject.width, windowObject.height,
                  windowObject.x, windowObject.y)
}

function centerWindow(windowObject, ownerWindow, preferredWidth, preferredHeight) {
    var geometry = ownerAvailableGeometry(windowObject, ownerWindow)
    var ownerX = finiteNumber(ownerWindow ? ownerWindow.x : geometry.x, geometry.x)
    var ownerY = finiteNumber(ownerWindow ? ownerWindow.y : geometry.y, geometry.y)
    var ownerWidth = Math.max(1, finiteNumber(ownerWindow ? ownerWindow.width : geometry.width,
                                              geometry.width))
    var ownerHeight = Math.max(1, finiteNumber(ownerWindow ? ownerWindow.height : geometry.height,
                                               geometry.height))
    var width = finiteNumber(preferredWidth, windowObject.width)
    var height = finiteNumber(preferredHeight, windowObject.height)
    var x = ownerX + Math.round((ownerWidth - width) / 2)
    var y = ownerY + Math.round((ownerHeight - height) / 2)
    applyGeometry(windowObject, geometry, width, height, x, y)
}
