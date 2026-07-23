import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.Button {
    id: appButton

    property bool primary: false
    property bool danger: false
    property bool selected: false
    property bool compact: false
    property int textPixelSize: compact ? 12 : 13

    implicitWidth: 104
    implicitHeight: compact ? 32 : 34
    padding: 0
    enabled: true

    contentItem: Text {
        text: appButton.text
        color: appButton.enabled
               ? appButton.primary || appButton.danger ? "#ffffff" : "#22333d"
               : "#7d8e98"
        font.pixelSize: appButton.textPixelSize
        font.bold: appButton.primary || appButton.danger || appButton.selected
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: 6
        color: {
            if (!appButton.enabled)
                return "#edf2f4"
            if (appButton.danger)
                return appButton.pressed ? "#a02a1f" : appButton.hovered ? "#d14635" : "#c7352a"
            if (appButton.primary)
                return appButton.pressed ? "#1d6fa8" : appButton.hovered ? "#2c8dcc" : "#267fbb"
            if (appButton.selected)
                return appButton.pressed ? "#c9e0eb" : appButton.hovered ? "#d3e9f2" : "#e1f2f8"
            return appButton.pressed ? "#d5e1e8" : appButton.hovered ? "#edf4f8" : "#f8fbfd"
        }
        border.color: !appButton.enabled ? "#c8d3d9"
                    : appButton.danger ? "#a02a1f"
                    : appButton.primary ? "#1d6fa8"
                    : appButton.selected ? "#2e8eb0"
                    : appButton.activeFocus ? "#2a91c9" : "#9fb2bd"
        border.width: (appButton.activeFocus || appButton.selected)
                      && !appButton.primary && !appButton.danger ? 2 : 1

        Rectangle {
            anchors.fill: parent
            anchors.margins: 3
            radius: Math.max(2, parent.radius - 3)
            color: "transparent"
            border.color: appButton.primary || appButton.danger ? "#ffffff" : "#0f5f8f"
            border.width: 2
            visible: appButton.visualFocus
        }
    }
}
