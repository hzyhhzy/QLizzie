import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.RadioButton {
    id: appRadioChoice

    spacing: 8

    indicator: Rectangle {
        implicitWidth: 24
        implicitHeight: 24
        x: appRadioChoice.leftPadding
        y: Math.round((appRadioChoice.height - height) / 2)
        radius: width / 2
        color: "#ffffff"
        border.color: appRadioChoice.checked ? "#2e8eb0"
                    : appRadioChoice.hovered ? "#6f9dad" : "#9fa8ad"
        border.width: appRadioChoice.checked ? 2 : 1

        Rectangle {
            anchors.centerIn: parent
            visible: appRadioChoice.checked
            width: 14
            height: 14
            radius: width / 2
            color: "#000000"
        }
    }

    contentItem: Text {
        text: appRadioChoice.text
        color: appRadioChoice.enabled ? "#24313a" : "#7d8e98"
        font.pixelSize: 14
        verticalAlignment: Text.AlignVCenter
        leftPadding: appRadioChoice.indicator.width + appRadioChoice.spacing
        elide: Text.ElideRight
    }
}
