import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.TextArea {
    id: appTextArea

    selectByMouse: true
    wrapMode: TextEdit.WrapAnywhere
    font.pixelSize: 13
    color: "#13232d"
    selectionColor: "#b8d9ea"
    selectedTextColor: "#102532"

    background: Rectangle {
        radius: 5
        color: appTextArea.enabled ? "#ffffff" : "#edf2f4"
        border.color: appTextArea.activeFocus ? "#2388b8" : "#b7c5cc"
        border.width: 1
    }
}
