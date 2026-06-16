import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic

Basic.ComboBox {
    id: control

    required property var app
    property int textPixelSize: app.compactLayout ? 13 : 14
    property int tipWidth: 320
    property string hoveredTip: ""
    property real tipX: 0
    property real tipY: 0

    model: app.visibleGameRuleOptions()
    textRole: "label"
    currentIndex: app.visibleGameRuleCurrentIndex()
    leftPadding: 10
    rightPadding: 30
    onActivated: function(index) {
        app.setVisibleGameRuleFromIndex(index)
        hideTip()
    }

    function showTip(tip, item) {
        if (!tip || tip.length <= 0 || !Overlay.overlay)
            return

        var point = item.mapToItem(Overlay.overlay, item.width + 8, -2)
        hoveredTip = tip
        tipX = Math.min(Math.max(6, point.x), Math.max(6, Overlay.overlay.width - ruleTip.width - 6))
        tipY = Math.min(Math.max(6, point.y), Math.max(6, Overlay.overlay.height - ruleTip.height - 6))
    }

    function hideTip() {
        hoveredTip = ""
    }

    delegate: Component {
        ItemDelegate {
            id: optionDelegate

            width: control.width
            height: control.app.compactLayout ? 30 : 34
            hoverEnabled: true
            enabled: control.app.ruleModeAllowedForPackage(modelData.value)

            contentItem: Text {
                text: modelData.label
                color: optionDelegate.enabled ? "#17212a" : "#8a969d"
                font.pixelSize: control.textPixelSize
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            background: Rectangle {
                color: !optionDelegate.enabled ? "#f0f3f5"
                    : optionDelegate.highlighted ? "#d8e9f1"
                    : optionDelegate.hovered ? "#edf5f8" : "#ffffff"
            }

            onHoveredChanged: {
                if (hovered)
                    control.showTip(modelData.tip, optionDelegate)
                else if (control.hoveredTip === modelData.tip)
                    control.hideTip()
            }

            onClicked: control.hideTip()
        }
    }

    contentItem: Text {
        leftPadding: control.leftPadding
        rightPadding: control.rightPadding
        text: control.displayText
        color: "#17212a"
        font.pixelSize: control.textPixelSize
        font.bold: true
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Canvas {
        id: arrowCanvas
        x: control.width - width - 10
        y: Math.round((control.height - height) / 2)
        width: 12
        height: 8

        Connections {
            target: control
            function onHoveredChanged() { arrowCanvas.requestPaint() }
            function onPressedChanged() { arrowCanvas.requestPaint() }
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = control.pressed ? "#1f6f8d" : "#6b7880"
            ctx.beginPath()
            ctx.moveTo(1, 1)
            ctx.lineTo(width - 1, 1)
            ctx.lineTo(width / 2, height - 1)
            ctx.closePath()
            ctx.fill()
        }
    }

    background: Rectangle {
        radius: 4
        color: control.pressed ? "#dcecf3"
                            : control.hovered ? "#eef7fa" : "#f5f7f8"
        border.color: control.activeFocus ? "#2e8eb0" : "#b9c8d0"
        border.width: control.activeFocus ? 2 : 1
    }

    Connections {
        target: control.popup
        function onVisibleChanged() {
            if (!control.popup.visible)
                control.hideTip()
        }
    }

    Basic.Popup {
        id: ruleTip

        parent: Overlay.overlay
        x: control.tipX
        y: control.tipY
        visible: control.popup.visible && control.hoveredTip.length > 0
        modal: false
        focus: false
        closePolicy: Popup.NoAutoClose
        padding: 8

        background: Rectangle {
            radius: 5
            color: "#26343c"
            border.color: "#6f858f"
            border.width: 1
        }

        contentItem: Text {
            width: control.tipWidth
            text: control.hoveredTip
            color: "#f3f8fa"
            font.pixelSize: control.app.compactLayout ? 12 : 13
            lineHeight: 1.12
            wrapMode: Text.WordWrap
        }
    }
}
