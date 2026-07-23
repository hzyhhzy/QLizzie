import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic

Basic.ComboBox {
    id: appComboBox

    property bool compact: false
    property int textHorizontalAlignment: Text.AlignLeft
    property string placeholderText: ""
    property int textPixelSize: compact ? 13 : 15

    implicitHeight: compact ? 30 : 38

    function textFor(modelData) {
        if (modelData === undefined || modelData === null)
            return ""
        if (typeof modelData === "object" && appComboBox.textRole.length > 0)
            return modelData[appComboBox.textRole]
        return String(modelData)
    }

    contentItem: Text {
        leftPadding: appComboBox.compact ? 8 : 12
        rightPadding: appComboBox.compact ? 24 : 32
        text: appComboBox.displayText.length > 0
              ? appComboBox.displayText : appComboBox.placeholderText
        color: appComboBox.enabled ? "#14242e" : "#7d8e98"
        font.pixelSize: appComboBox.textPixelSize
        font.bold: appComboBox.activeFocus
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: appComboBox.textHorizontalAlignment
        elide: Text.ElideRight
    }

    indicator: Text {
        anchors.right: parent.right
        anchors.rightMargin: appComboBox.compact ? 8 : 11
        anchors.verticalCenter: parent.verticalCenter
        text: "\u25be"
        color: appComboBox.enabled ? "#657781" : "#9aa8af"
        font.pixelSize: appComboBox.compact ? 13 : 16
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
        height: appComboBox.compact ? 30 : 40
        highlighted: appComboBox.highlightedIndex === index

        contentItem: Text {
            text: appComboBox.textFor(modelData)
            color: "#14242e"
            font.pixelSize: appComboBox.textPixelSize
            font.bold: appComboBox.currentIndex === index
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: appComboBox.textHorizontalAlignment
            leftPadding: appComboBox.compact ? 8 : 12
            rightPadding: appComboBox.compact ? 8 : 12
            elide: Text.ElideRight
        }

        background: Rectangle {
            color: highlighted ? "#dfeaf0" : "#ffffff"
        }
    }

    popup: Popup {
        y: appComboBox.height + 2
        width: appComboBox.width
        implicitHeight: Math.min(contentItem.implicitHeight, appComboBox.compact ? 180 : 280)
        padding: 1

        contentItem: ListView {
            id: popupList
            clip: true
            implicitHeight: contentHeight
            model: appComboBox.popup.visible ? appComboBox.delegateModel : null
            currentIndex: appComboBox.highlightedIndex
            ScrollBar.vertical: AppScrollBar {
                policy: popupList.contentHeight > popupList.height
                        ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
            }
        }

        background: Rectangle {
            radius: 5
            color: "#ffffff"
            border.color: "#91a8b4"
        }
    }
}
