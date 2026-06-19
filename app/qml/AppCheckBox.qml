import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic

Basic.CheckBox {
    id: appCheckBox

    spacing: 8

    indicator: Rectangle {
        implicitWidth: 20
        implicitHeight: 20
        x: appCheckBox.leftPadding
        y: Math.round((appCheckBox.height - height) / 2)
        radius: 4
        color: appCheckBox.checkState === Qt.Checked || appCheckBox.checkState === Qt.PartiallyChecked
               ? "#0f6fbf"
               : appCheckBox.hovered ? "#eef7fa" : "#ffffff"
        border.color: appCheckBox.checkState === Qt.Checked || appCheckBox.checkState === Qt.PartiallyChecked
                      ? "#0f6fbf"
                      : appCheckBox.hovered ? "#5c8da6" : "#7f8b92"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: appCheckBox.checkState === Qt.PartiallyChecked ? "-"
                  : appCheckBox.checkState === Qt.Checked ? "\u2713" : ""
            color: "#ffffff"
            font.pixelSize: appCheckBox.checkState === Qt.PartiallyChecked ? 18 : 15
            font.bold: true
            lineHeight: 0.9
        }
    }

    contentItem: Text {
        text: appCheckBox.text
        color: appCheckBox.enabled ? "#24313a" : "#7d8e98"
        font.pixelSize: 14
        verticalAlignment: Text.AlignVCenter
        leftPadding: appCheckBox.indicator.width + appCheckBox.spacing
        elide: Text.ElideRight
    }
}
