import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic

Basic.CheckBox {
    id: appCheckBox

    property bool compact: false
    readonly property int indicatorSize: compact ? 18 : 20

    spacing: compact ? 6 : 8

    indicator: Rectangle {
        implicitWidth: appCheckBox.indicatorSize
        implicitHeight: appCheckBox.indicatorSize
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

        AppCheckMark {
            anchors.fill: parent
            anchors.margins: appCheckBox.compact ? 3 : 4
            checked: appCheckBox.checkState === Qt.Checked
            partial: appCheckBox.checkState === Qt.PartiallyChecked
            markColor: "#ffffff"
            lineWidth: appCheckBox.compact ? 2.0 : (appCheckBox.checkState === Qt.PartiallyChecked ? 2.4 : 2.2)
        }
    }

    contentItem: Text {
        text: appCheckBox.text
        color: appCheckBox.enabled ? "#24313a" : "#7d8e98"
        font.pixelSize: appCheckBox.compact ? 13 : 14
        verticalAlignment: Text.AlignVCenter
        leftPadding: appCheckBox.indicator.width + appCheckBox.spacing
        elide: Text.ElideRight
    }
}
