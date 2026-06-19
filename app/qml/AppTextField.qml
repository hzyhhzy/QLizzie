import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.TextField {
    id: appTextField

    selectByMouse: true
    font.pixelSize: 13
    color: "#13232d"
    selectionColor: "#b8d9ea"
    selectedTextColor: "#102532"

    background: Rectangle {
        radius: 5
        color: appTextField.enabled ? "#ffffff" : "#edf2f4"
        border.color: appTextField.activeFocus ? "#2388b8" : "#b7c5cc"
        border.width: appTextField.activeFocus ? 2 : 1
    }
}
