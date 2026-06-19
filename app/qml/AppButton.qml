import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.Button {
    id: appButton

    property bool primary: false
    property bool danger: false

    implicitWidth: 104
    implicitHeight: 34
    padding: 0
    enabled: true

    contentItem: Text {
        text: appButton.text
        color: appButton.enabled
               ? appButton.primary || appButton.danger ? "#ffffff" : "#22333d"
               : "#7d8e98"
        font.pixelSize: 13
        font.bold: appButton.primary || appButton.danger
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
            return appButton.pressed ? "#d5e1e8" : appButton.hovered ? "#edf4f8" : "#f8fbfd"
        }
        border.color: !appButton.enabled ? "#c8d3d9"
                    : appButton.danger ? "#a02a1f"
                    : appButton.primary ? "#1d6fa8"
                    : appButton.activeFocus ? "#2a91c9" : "#9fb2bd"
        border.width: appButton.activeFocus && !appButton.primary && !appButton.danger ? 2 : 1
    }
}
