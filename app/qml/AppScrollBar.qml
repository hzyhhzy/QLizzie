import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.ScrollBar {
    id: scrollBar

    property real startInset: 0
    property real endInset: 0
    property real hitThickness: 12
    property real trackThickness: 12
    property real thumbThickness: 8
    readonly property real basePadding: 2
    readonly property real crossAxisPadding:
        Math.max(0, (hitThickness - thumbThickness) / 2)

    leftPadding: orientation === Qt.Horizontal
                 ? basePadding + startInset : crossAxisPadding
    rightPadding: orientation === Qt.Horizontal
                  ? basePadding + endInset : crossAxisPadding
    topPadding: orientation === Qt.Vertical
                ? basePadding + startInset : crossAxisPadding
    bottomPadding: orientation === Qt.Vertical
                   ? basePadding + endInset : crossAxisPadding
    minimumSize: 0.08
    implicitWidth: orientation === Qt.Vertical ? hitThickness : 48
    implicitHeight: orientation === Qt.Vertical ? 48 : hitThickness

    background: Rectangle {
        x: scrollBar.orientation === Qt.Horizontal
           ? scrollBar.startInset
           : Math.max(0, (scrollBar.width - width) / 2)
        y: scrollBar.orientation === Qt.Vertical
           ? scrollBar.startInset
           : Math.max(0, (scrollBar.height - height) / 2)
        width: scrollBar.orientation === Qt.Horizontal
               ? Math.max(0, scrollBar.width - scrollBar.startInset - scrollBar.endInset)
               : Math.min(scrollBar.width, scrollBar.trackThickness)
        height: scrollBar.orientation === Qt.Vertical
                ? Math.max(0, scrollBar.height - scrollBar.startInset - scrollBar.endInset)
                : Math.min(scrollBar.height, scrollBar.trackThickness)
        radius: 6
        color: "#edf4f7"
        border.color: "#d2dee5"
    }

    contentItem: Rectangle {
        implicitWidth: scrollBar.orientation === Qt.Vertical
                       ? scrollBar.thumbThickness : 34
        implicitHeight: scrollBar.orientation === Qt.Vertical
                        ? 34 : scrollBar.thumbThickness
        radius: 4
        color: scrollBar.pressed ? "#5d737f" : scrollBar.hovered ? "#748a96" : "#9aadb6"
    }
}
