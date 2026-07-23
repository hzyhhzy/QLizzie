import QtQuick
import QtQuick.Layouts

Item {
    id: appDialogFooter

    default property alias contentData: footerRow.data
    property string tone: "normal"
    property int contentMargins: 18
    property int horizontalMargins: contentMargins
    property int verticalMargins: 12
    property int dialogRadius: 10

    function footerColor() {
        if (tone === "error")
            return "#f7eeee"
        if (tone === "warning")
            return "#f7f0e3"
        return "#f1f6f9"
    }

    function dividerColor() {
        if (tone === "error")
            return "#e3c0bc"
        if (tone === "warning")
            return "#dfc79e"
        return "#d7e1e7"
    }

    implicitHeight: footerRow.implicitHeight + verticalMargins * 2

    Rectangle {
        id: footerPanel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 1
        anchors.rightMargin: 1
        anchors.bottomMargin: 1
        color: appDialogFooter.footerColor()
        radius: Math.max(0, appDialogFooter.dialogRadius - 1)

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: parent.radius
            color: parent.color
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 1
        color: appDialogFooter.dividerColor()
    }

    RowLayout {
        id: footerRow
        anchors.fill: footerPanel
        anchors.leftMargin: appDialogFooter.horizontalMargins
        anchors.rightMargin: appDialogFooter.horizontalMargins
        anchors.topMargin: appDialogFooter.verticalMargins
        anchors.bottomMargin: appDialogFooter.verticalMargins
        spacing: 10
    }
}
