import QtQuick

Canvas {
    id: appCheckMark

    property bool checked: true
    property bool partial: false
    property color markColor: "#ffffff"
    property real lineWidth: Math.max(2, width * 0.16)

    onCheckedChanged: requestPaint()
    onPartialChanged: requestPaint()
    onMarkColorChanged: requestPaint()
    onLineWidthChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        if (!checked && !partial)
            return

        ctx.strokeStyle = markColor
        ctx.lineWidth = lineWidth
        ctx.lineCap = "square"
        ctx.lineJoin = "miter"
        ctx.beginPath()
        if (partial) {
            ctx.moveTo(width * 0.25, height * 0.50)
            ctx.lineTo(width * 0.75, height * 0.50)
        } else {
            ctx.moveTo(width * 0.18, height * 0.55)
            ctx.lineTo(width * 0.40, height * 0.76)
            ctx.lineTo(width * 0.82, height * 0.24)
        }
        ctx.stroke()
    }
}
