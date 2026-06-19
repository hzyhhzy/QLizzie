import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic

Basic.Dialog {
    id: appDialog

    property var app: null
    property string tone: "normal"
    property int dialogRadius: 10
    property int headerHeight: 52
    property int titlePixelSize: 17

    function panelColor() {
        if (tone === "error")
            return "#fff8f6"
        if (tone === "warning")
            return "#fff8ed"
        return "#f8fbfd"
    }

    function headerColor() {
        if (tone === "error")
            return "#ffe2de"
        if (tone === "warning")
            return "#f5e4cc"
        return "#e6eff4"
    }

    function borderColor() {
        if (tone === "error")
            return "#d0695f"
        if (tone === "warning")
            return "#c99452"
        return "#8ea5b1"
    }

    function dividerColor() {
        if (tone === "error")
            return "#efb3ad"
        if (tone === "warning")
            return "#dfc59e"
        return "#c5d4dc"
    }

    function titleColor() {
        if (tone === "error")
            return "#641a14"
        if (tone === "warning")
            return "#3d2a12"
        return "#14242e"
    }

    padding: 18
    closePolicy: Popup.CloseOnEscape
    x: app ? Math.round((app.width - width) / 2) : 0
    y: app ? Math.round((app.height - height) / 2) : 0

    background: Rectangle {
        radius: appDialog.dialogRadius
        color: appDialog.panelColor()
        border.color: appDialog.borderColor()
        border.width: 1
    }

    header: Rectangle {
        height: appDialog.headerHeight
        color: appDialog.headerColor()
        radius: appDialog.dialogRadius

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.radius
            color: parent.color
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: appDialog.dividerColor()
        }

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            text: appDialog.title
            color: appDialog.titleColor()
            font.pixelSize: appDialog.titlePixelSize
            font.bold: true
            elide: Text.ElideRight
        }
    }
}
