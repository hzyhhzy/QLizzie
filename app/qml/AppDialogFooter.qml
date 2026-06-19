import QtQuick
import QtQuick.Layouts

Rectangle {
    id: appDialogFooter

    default property alias contentData: footerRow.data
    property int contentMargins: 18
    property int dialogRadius: 10

    implicitHeight: 68
    color: "#f8fbfd"
    radius: dialogRadius

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: parent.radius
        color: parent.color
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 1
        color: "#d7e1e7"
    }

    RowLayout {
        id: footerRow
        anchors.fill: parent
        anchors.margins: appDialogFooter.contentMargins
        spacing: 10
    }
}
