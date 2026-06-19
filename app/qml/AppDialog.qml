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
            return "#fff8f7"
        if (tone === "warning")
            return "#fffaf2"
        return "#f8fbfd"
    }

    function headerColor() {
        if (tone === "error")
            return "#f4e7e6"
        if (tone === "warning")
            return "#f4ead6"
        return "#e6eff4"
    }

    function borderColor() {
        if (tone === "error")
            return "#c98b84"
        if (tone === "warning")
            return "#c9a46d"
        return "#8ea5b1"
    }

    function dividerColor() {
        if (tone === "error")
            return "#e3c0bc"
        if (tone === "warning")
            return "#dfc79e"
        return "#c5d4dc"
    }

    function titleColor() {
        if (tone === "error")
            return "#8a241b"
        if (tone === "warning")
            return "#5a370f"
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

    header: Item {
        height: appDialog.headerHeight

        Rectangle {
            id: headerPanel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 1
            anchors.rightMargin: 1
            anchors.topMargin: 1
            color: appDialog.headerColor()
            radius: Math.max(0, appDialog.dialogRadius - 1)

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.radius
                color: parent.color
            }
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
