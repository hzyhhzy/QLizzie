import QtQuick
import QtQuick.Window

Item {
    id: inputLayer
    required property var app
    focus: true

    property real lastX: 0
    property real lastY: 0
    property bool moved: false
    property int pressedButton: 0
    property bool boardPressBlocked: false

    function ownsKeyboardFocus() {
        var hostWindow = inputLayer.Window.window
        return inputLayer.activeFocus
               && (!hostWindow
                   || (hostWindow.active
                       && hostWindow.activeFocusItem === inputLayer))
    }

    Keys.onPressed: function(event) {
        if (!inputLayer.ownsKeyboardFocus())
            return

        if (event.modifiers & Qt.ControlModifier)
            return

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (!event.isAutoRepeat && app.playActiveCandidateVariation())
                event.accepted = true
        } else if (event.key === Qt.Key_Space) {
            if (!event.isAutoRepeat)
                app.toggleEnginePause()
            event.accepted = true
        } else if (event.key === Qt.Key_Comma) {
            app.playBestEngineMove()
            event.accepted = true
        } else if (event.key === Qt.Key_P) {
            if (!event.isAutoRepeat)
                app.passMove()
            event.accepted = true
        } else if (event.key === Qt.Key_Backspace) {
            app.requestDeleteCurrentNode()
            event.accepted = true
        } else if (event.key === Qt.Key_M) {
            if (!event.isAutoRepeat)
                app.cycleMoveNumberDisplayMode()
            event.accepted = true
        } else if (event.key === Qt.Key_E) {
            if (!event.isAutoRepeat)
                app.openEngineCommunicationLog()
            event.accepted = true
        } else if (event.key === Qt.Key_Period) {
            if (app.gameRuleMode === app.gameRuleGo) {
                if (!event.isAutoRepeat)
                    app.ownershipEnabled = !app.ownershipEnabled
                event.accepted = true
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onPressed: function(mouse) {
            inputLayer.boardPressBlocked = app.boardInputBlocked(inputLayer, mouse.x, mouse.y)
            if (inputLayer.boardPressBlocked) {
                inputLayer.pressedButton = 0
                inputLayer.moved = false
                app.clearHover()
                mouse.accepted = true
                return
            }

            app.focusBoardInput()
            inputLayer.lastX = mouse.x
            inputLayer.lastY = mouse.y
            inputLayer.moved = false
            inputLayer.pressedButton = mouse.button
            mouse.accepted = true
        }

        onPositionChanged: function(mouse) {
            if (inputLayer.boardPressBlocked || (mouse.buttons === Qt.NoButton && app.boardInputBlocked(inputLayer, mouse.x, mouse.y))) {
                app.clearHover()
                mouse.accepted = true
                return
            }

            var dx = mouse.x - inputLayer.lastX
            var dy = mouse.y - inputLayer.lastY
            if (mouse.buttons !== Qt.NoButton && Math.abs(dx) + Math.abs(dy) > 2)
                inputLayer.moved = true
            if (mouse.buttons === Qt.NoButton)
                app.updateHover(mouse.x, mouse.y)
            inputLayer.lastX = mouse.x
            inputLayer.lastY = mouse.y
        }

        onReleased: function(mouse) {
            var skipHoverUpdate = false
            if (!inputLayer.boardPressBlocked && !inputLayer.moved) {
                if (inputLayer.pressedButton === Qt.LeftButton)
                    skipHoverUpdate = app.handleBoardClickFromMouse(mouse.x, mouse.y) === true
                else if (inputLayer.pressedButton === Qt.RightButton)
                    skipHoverUpdate = app.cancelCandidateListSelection() === true
            }
            inputLayer.pressedButton = 0
            inputLayer.boardPressBlocked = false
            if (skipHoverUpdate)
                app.clearHover(true)
            else if (app.boardInputBlocked(inputLayer, mouse.x, mouse.y))
                app.clearHover()
            else
                app.updateHover(mouse.x, mouse.y)
            mouse.accepted = true
        }

        onWheel: function(wheel) {
            if (app.boardInputBlocked(inputLayer, wheel.x, wheel.y)) {
                wheel.accepted = true
                return
            }

            app.focusBoardInput()
            var delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y
            if (delta > 0)
                app.gotoRelativeMove(-1)
            else if (delta < 0)
                app.gotoRelativeMove(1)
            wheel.accepted = true
        }

        onExited: app.clearHover()
    }
}
