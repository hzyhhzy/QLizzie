import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.RadioButton {
    id: appRadioChoice

    property bool compact: false
    property int textPixelSize: compact ? 12 : 14

    spacing: compact ? 6 : 8
    Accessible.name: text
    Accessible.role: Accessible.RadioButton
    Accessible.checked: checked

    indicator: Rectangle {
        implicitWidth: appRadioChoice.compact ? 22 : 24
        implicitHeight: implicitWidth
        x: appRadioChoice.leftPadding
        y: Math.round((appRadioChoice.height - height) / 2)
        radius: width / 2
        color: "#ffffff"
        border.color: appRadioChoice.visualFocus ? "#0f5f8f"
                    : appRadioChoice.checked ? "#2e8eb0"
                    : appRadioChoice.hovered ? "#6f9dad" : "#9fa8ad"
        border.width: appRadioChoice.checked || appRadioChoice.visualFocus ? 2 : 1

        Rectangle {
            anchors.centerIn: parent
            visible: appRadioChoice.checked
            width: appRadioChoice.compact ? 12 : 14
            height: width
            radius: width / 2
            color: "#000000"
        }
    }

    contentItem: Text {
        text: appRadioChoice.text
        color: appRadioChoice.enabled ? "#24313a" : "#7d8e98"
        font.pixelSize: appRadioChoice.textPixelSize
        verticalAlignment: Text.AlignVCenter
        leftPadding: appRadioChoice.indicator.width + appRadioChoice.spacing
        elide: Text.ElideRight
    }
}
