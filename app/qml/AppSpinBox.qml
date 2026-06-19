import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic

Basic.SpinBox {
    id: appSpinBox

    property bool compact: false
    readonly property int stepButtonWidth: compact ? 20 : 24
    readonly property int arrowCanvasWidth: compact ? 8 : 10
    readonly property int arrowCanvasHeight: compact ? 6 : 7

    editable: true
    implicitWidth: 96
    implicitHeight: compact ? 30 : 34
    padding: 0
    leftPadding: compact ? 6 : 8
    rightPadding: stepButtonWidth + (compact ? 5 : 6)

    contentItem: TextInput {
        z: 2
        text: appSpinBox.displayText
        font: appSpinBox.font
        color: appSpinBox.enabled ? "#14242e" : "#7d8e98"
        selectionColor: "#b8d9ea"
        selectedTextColor: "#102532"
        selectByMouse: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        readOnly: !appSpinBox.editable
        validator: appSpinBox.validator
        inputMethodHints: appSpinBox.inputMethodHints
        clip: true
    }

    up.indicator: Rectangle {
        x: appSpinBox.width - width - 2
        y: 2
        width: appSpinBox.stepButtonWidth
        height: Math.floor((appSpinBox.height - 4) / 2)
        radius: appSpinBox.compact ? 2 : 3
        color: !appSpinBox.up.pressed
               ? (appSpinBox.up.hovered ? "#e7f0f5" : "#f4f8fa")
               : "#cfdee6"

        Canvas {
            id: upArrow
            anchors.centerIn: parent
            width: appSpinBox.arrowCanvasWidth
            height: appSpinBox.arrowCanvasHeight

            Connections {
                target: appSpinBox.up
                function onHoveredChanged() { upArrow.requestPaint() }
                function onPressedChanged() { upArrow.requestPaint() }
            }

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = appSpinBox.enabled ? "#24343c" : "#9baab2"
                ctx.lineWidth = appSpinBox.compact ? 1.6 : 1.8
                ctx.lineCap = "square"
                ctx.lineJoin = "miter"
                ctx.beginPath()
                ctx.moveTo(1.3, height - 1.3)
                ctx.lineTo(width / 2, 1.3)
                ctx.lineTo(width - 1.3, height - 1.3)
                ctx.stroke()
            }
        }
    }

    down.indicator: Rectangle {
        x: appSpinBox.width - width - 2
        y: appSpinBox.height - height - 2
        width: appSpinBox.stepButtonWidth
        height: Math.floor((appSpinBox.height - 4) / 2)
        radius: appSpinBox.compact ? 2 : 3
        color: !appSpinBox.down.pressed
               ? (appSpinBox.down.hovered ? "#e7f0f5" : "#f4f8fa")
               : "#cfdee6"

        Canvas {
            id: downArrow
            anchors.centerIn: parent
            width: appSpinBox.arrowCanvasWidth
            height: appSpinBox.arrowCanvasHeight

            Connections {
                target: appSpinBox.down
                function onHoveredChanged() { downArrow.requestPaint() }
                function onPressedChanged() { downArrow.requestPaint() }
            }

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = appSpinBox.enabled ? "#24343c" : "#9baab2"
                ctx.lineWidth = appSpinBox.compact ? 1.6 : 1.8
                ctx.lineCap = "square"
                ctx.lineJoin = "miter"
                ctx.beginPath()
                ctx.moveTo(1.3, 1.3)
                ctx.lineTo(width / 2, height - 1.3)
                ctx.lineTo(width - 1.3, 1.3)
                ctx.stroke()
            }
        }
    }

    background: Rectangle {
        radius: 6
        color: appSpinBox.enabled ? "#ffffff" : "#edf2f4"
        border.color: appSpinBox.activeFocus ? "#2a91c9"
                    : appSpinBox.hovered ? "#7fa3b6" : "#9fb2bd"
        border.width: appSpinBox.activeFocus ? 2 : 1

        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.rightMargin: appSpinBox.stepButtonWidth + 3
            width: 1
            color: "#d1dde4"
        }

        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            width: appSpinBox.stepButtonWidth
            height: 1
            color: "#d1dde4"
        }
    }
}
