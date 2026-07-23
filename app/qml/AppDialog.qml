import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic

Basic.Dialog {
    id: appDialog

    property var app: null
    property string tone: "normal"
    property int dialogRadius: 10
    property int headerHeight: 52
    property int titlePixelSize: 17
    // Modal dialogs use a dedicated popup window so they can leave the main
    // window bounds while keeping the application blocked.
    property bool windowed: modal
    property var centerTarget: app
    property var owningWindow: app
    property real preferredWidth: Math.max(implicitWidth, 320)
    property real preferredHeight: Math.max(implicitHeight, 140)
    property real dialogMinimumWidth: Math.min(preferredWidth, 320)
    property real dialogMinimumHeight: Math.min(preferredHeight, 140)
    property bool blockNativeClose: closePolicy === Popup.NoAutoClose
    readonly property int unconstrainedWindowMaximum: 16777215
    property var retainedHostWindow: null
    signal nativeCloseRequested()
    readonly property var targetScreen:
        owningWindow && owningWindow.screen ? owningWindow.screen
                                            : (hostWindow && hostWindow.screen ? hostWindow.screen : null)
    readonly property rect availableScreenGeometry:
        targetScreen && targetScreen.width > 0 && targetScreen.height > 0
            ? Qt.rect(targetScreen.virtualX, targetScreen.virtualY,
                      targetScreen.width, targetScreen.height)
            : Qt.rect(dialogHeader.Screen.virtualX, dialogHeader.Screen.virtualY,
                      dialogHeader.Screen.width > 0
                          ? dialogHeader.Screen.width
                          : (app ? app.width : preferredWidth),
                      dialogHeader.Screen.height > 0
                          ? dialogHeader.Screen.height
                          : (app ? app.height : preferredHeight))
    readonly property real availableScreenWidth:
        availableScreenGeometry.width
    readonly property real availableScreenHeight:
        availableScreenGeometry.height
    readonly property var hostWindow: dialogHeader.popupHostWindow
    readonly property bool separateWindow:
        windowed && !!hostWindow && hostWindow !== owningWindow

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
        var relativeX = target ? Math.round((target.width - width) / 2) : 0
        var relativeY = target ? Math.round((target.height - height) / 2) : 0
        // Popup coordinates are parent-local. Qt maps them to the native screen
        // and constrains Popup.Window to the real available screen geometry.
        x = relativeX
        y = relativeY
    }

    function resetWindowConstraints(popupWindow) {
        popupWindow.maximumWidth = unconstrainedWindowMaximum
        popupWindow.maximumHeight = unconstrainedWindowMaximum
        popupWindow.minimumWidth = 0
        popupWindow.minimumHeight = 0
    }

    function prepareWindowGeometry() {
        var popupWindow = hostWindow
        if (separateWindow && popupWindow)
            resetWindowConstraints(popupWindow)

        applyPreferredGeometry()
        if (separateWindow && popupWindow) {
            popupWindow.minimumWidth = Math.ceil(dialogMinimumWidth)
            popupWindow.minimumHeight = Math.ceil(dialogMinimumHeight)
        }
    }

    function freezeWindowGeometry() {
        var popupWindow = hostWindow
        if (!separateWindow || !popupWindow)
            return

        retainedHostWindow = popupWindow
        var currentWidth = Math.max(1, Math.round(popupWindow.width))
        var currentHeight = Math.max(1, Math.round(popupWindow.height))
        popupWindow.minimumWidth = currentWidth
        popupWindow.maximumWidth = currentWidth
        popupWindow.minimumHeight = currentHeight
        popupWindow.maximumHeight = currentHeight
    }

    function prepareHiddenWindowForNextOpen() {
        var popupWindow = retainedHostWindow
        if (!windowed || !popupWindow || popupWindow === owningWindow)
            return

        // QQuickPopupWindow is reused and becomes visible before aboutToShow.
        // Size and lock it while hidden so its first mapped frame is already
        // the preferred size. aboutToShow restores normal resize constraints.
        resetWindowConstraints(popupWindow)
        applyPreferredGeometry()

        var nextWidth = Math.max(1, Math.ceil(preferredGeometryWidth()))
        var nextHeight = Math.max(1, Math.ceil(preferredGeometryHeight()))
        popupWindow.width = nextWidth
        popupWindow.height = nextHeight
        popupWindow.minimumWidth = nextWidth
        popupWindow.maximumWidth = nextWidth
        popupWindow.minimumHeight = nextHeight
        popupWindow.maximumHeight = nextHeight
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
    popupType: windowed ? Popup.Window : Popup.Item
    closePolicy: Popup.CloseOnEscape
    onAboutToShow: prepareWindowGeometry()
    onAboutToHide: freezeWindowGeometry()
    onHostWindowChanged: {
        if (windowed && hostWindow && hostWindow !== owningWindow)
            retainedHostWindow = hostWindow
    }

    Connections {
        target: appDialog

        function onClosed() {
            appDialog.prepareHiddenWindowForNextOpen()
        }
    }

    Connections {
        target: appDialog.separateWindow ? appDialog.hostWindow : null
        ignoreUnknownSignals: true

        function onClosing(closeEvent) {
            if (!appDialog.blockNativeClose)
                return
            closeEvent.accepted = false
            appDialog.nativeCloseRequested()
        }
    }

    background: Rectangle {
        radius: appDialog.dialogRadius
        color: appDialog.panelColor()
        border.color: appDialog.borderColor()
        border.width: 1
    }

    header: Item {
        id: dialogHeader
        readonly property var popupHostWindow: Window.window
        implicitHeight: appDialog.separateWindow ? 0 : appDialog.headerHeight
        height: implicitHeight
        visible: !appDialog.separateWindow

        Rectangle {
            id: headerPanel
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
