import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic

Basic.ComboBox {
    id: appComboBox

    implicitHeight: 38

    function textFor(modelData) {
        if (modelData === undefined || modelData === null)
            return ""
        if (typeof modelData === "object" && appComboBox.textRole.length > 0)
            return modelData[appComboBox.textRole]
        return String(modelData)
    }

    contentItem: Text {
        leftPadding: 12
        rightPadding: 32
        text: appComboBox.displayText
        color: appComboBox.enabled ? "#14242e" : "#7d8e98"
        font.pixelSize: 15
        font.bold: appComboBox.activeFocus
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Text {
        anchors.right: parent.right
        anchors.rightMargin: 11
        anchors.verticalCenter: parent.verticalCenter
        text: "\u25be"
        color: appComboBox.enabled ? "#657781" : "#9aa8af"
        font.pixelSize: 16
    }

    background: Rectangle {
        radius: 6
        color: appComboBox.enabled
               ? appComboBox.hovered ? "#f8fbfd" : "#ffffff"
               : "#edf2f4"
        border.color: appComboBox.activeFocus ? "#2a91c9" : "#a8bac5"
        border.width: appComboBox.activeFocus ? 2 : 1
    }

    delegate: Basic.ItemDelegate {
        width: appComboBox.width
        height: 40
        highlighted: appComboBox.highlightedIndex === index

        contentItem: Text {
            text: appComboBox.textFor(modelData)
            color: "#14242e"
            font.pixelSize: 14
            font.bold: appComboBox.currentIndex === index
            verticalAlignment: Text.AlignVCenter
            leftPadding: 12
            rightPadding: 12
            elide: Text.ElideRight
        }

        background: Rectangle {
            color: highlighted ? "#dfeaf0" : "#ffffff"
        }
    }

    popup: Popup {
        y: appComboBox.height + 2
        width: appComboBox.width
        implicitHeight: Math.min(contentItem.implicitHeight, 280)
        padding: 1

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: appComboBox.popup.visible ? appComboBox.delegateModel : null
            currentIndex: appComboBox.highlightedIndex
            ScrollBar.vertical: AppScrollBar {
                policy: parent.contentHeight > parent.height ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
            }
        }

        background: Rectangle {
            radius: 5
            color: "#ffffff"
            border.color: "#91a8b4"
        }
    }
}
