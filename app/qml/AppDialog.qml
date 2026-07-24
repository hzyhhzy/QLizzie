import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic

// Lightweight dialogs stay inside their owning window. Content-heavy dialogs
// use AppWindowDialog instead so they can be moved beyond the main window.
Basic.Dialog {
    id: appDialog

    property var app: null
    property string tone: "normal"
    property int dialogRadius: 10
    property int headerHeight: 52
    property int titlePixelSize: 17
    property bool windowed: false
    property var centerTarget: app
    property var owningWindow: app
    property real preferredWidth: Math.max(implicitWidth, 320)
    property real preferredHeight: Math.max(implicitHeight, 140)
    property real dialogMinimumWidth: Math.min(preferredWidth, 320)
    property real dialogMinimumHeight: Math.min(preferredHeight, 140)
    property bool blockNativeClose: closePolicy === Popup.NoAutoClose
    signal nativeCloseRequested()

    readonly property var hostWindow: dialogHeader.containingWindow
    readonly property bool separateWindow: false
    readonly property var targetScreen:
        owningWindow && owningWindow.screen ? owningWindow.screen
                                            : (hostWindow && hostWindow.screen ? hostWindow.screen : null)
    readonly property rect availableScreenGeometry:
        targetScreen && targetScreen.availableGeometry
                     && targetScreen.availableGeometry.width > 0
                     && targetScreen.availableGeometry.height > 0
            ? targetScreen.availableGeometry
            : Qt.rect(dialogHeader.Screen.virtualX, dialogHeader.Screen.virtualY,
                      dialogHeader.Screen.desktopAvailableWidth > 0
                          ? dialogHeader.Screen.desktopAvailableWidth
                          : (app ? app.width : preferredWidth),
                      dialogHeader.Screen.desktopAvailableHeight > 0
                          ? dialogHeader.Screen.desktopAvailableHeight
                          : (app ? app.height : preferredHeight))
    readonly property real availableScreenWidth: availableScreenGeometry.width
    readonly property real availableScreenHeight: availableScreenGeometry.height

    function boundedPreferredWidth(maximumWidth, screenMargin) {
        return Math.max(1, Math.min(maximumWidth, availableScreenWidth - screenMargin))
    }

    function boundedPreferredHeight(maximumHeight, screenMargin) {
        return Math.max(1, Math.min(maximumHeight, availableScreenHeight - screenMargin))
    }

    function preferredGeometryWidth() {
        var nextWidth = Math.max(dialogMinimumWidth, preferredWidth)
        return Math.min(nextWidth,
                        Math.max(dialogMinimumWidth, availableScreenWidth - 24))
    }

    function preferredGeometryHeight() {
        var nextHeight = Math.max(dialogMinimumHeight, preferredHeight)
        return Math.min(nextHeight,
                        Math.max(dialogMinimumHeight, availableScreenHeight - 24))
    }

    function applyPreferredGeometry() {
        width = preferredGeometryWidth()
        height = preferredGeometryHeight()

        var target = centerTarget
        x = target ? Math.round((target.width - width) / 2) : 0
        y = target ? Math.round((target.height - height) / 2) : 0
    }

    function panelColor() {
        if (tone === "error")
            return "#fff8f7"
        if (tone === "warning")
            return "#fffaf2"
        return "#f8fbfd"
    }

    function headerColor() {
        if (tone === "error")
            return "#f4e7e6"
        if (tone === "warning")
            return "#f4ead6"
        return "#e6eff4"
    }

    function borderColor() {
        if (tone === "error")
            return "#c98b84"
        if (tone === "warning")
            return "#c9a46d"
        return "#8ea5b1"
    }

    function dividerColor() {
        if (tone === "error")
            return "#e3c0bc"
        if (tone === "warning")
            return "#dfc79e"
        return "#c5d4dc"
    }

    function titleColor() {
        if (tone === "error")
            return "#8a241b"
        if (tone === "warning")
            return "#5a370f"
        return "#14242e"
    }

    padding: 18
    popupType: Popup.Item
    closePolicy: Popup.CloseOnEscape
    onAboutToShow: applyPreferredGeometry()

    background: Rectangle {
        radius: appDialog.dialogRadius
        color: appDialog.panelColor()
        border.color: appDialog.borderColor()
        border.width: 1
    }

    header: Item {
        id: dialogHeader
        readonly property var containingWindow: Window.window
        implicitHeight: appDialog.headerHeight
        height: implicitHeight

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 1
            anchors.rightMargin: 1
            anchors.topMargin: 1
            color: appDialog.headerColor()
            radius: Math.max(0, appDialog.dialogRadius - 1)

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.radius
                color: parent.color
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: appDialog.dividerColor()
        }

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            text: appDialog.title
            color: appDialog.titleColor()
            font.pixelSize: appDialog.titlePixelSize
            font.bold: true
            elide: Text.ElideRight
        }
    }
}
