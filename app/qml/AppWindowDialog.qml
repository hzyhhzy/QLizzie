import QtQuick
import QtQuick.Window
import QtQuick.Controls

// A real top-level window for content-heavy modal dialogs. Geometry is applied
// once while hidden so user resizing and movement are never fought by bindings.
Window {
    id: appWindowDialog

    property var app: null
    property string tone: "normal"
    property int padding: 18
    property int dialogRadius: 10
    property bool modal: true
    property var centerTarget: owningWindow
    property var owningWindow: app
    property Item dialogBody: null
    property Item dialogFooter: null
    property real preferredWidth: Math.max(
                                      (dialogBody ? dialogBody.implicitWidth : 0) + padding * 2,
                                      320)
    property real preferredHeight: Math.max(
                                       (dialogBody ? dialogBody.implicitHeight : 0)
                                       + (dialogFooter ? dialogFooter.implicitHeight : 0)
                                       + padding * 2,
                                       140)
    property real dialogMinimumWidth: Math.min(preferredWidth, 320)
    property real dialogMinimumHeight: Math.min(preferredHeight, 140)
    property int closePolicy: Popup.CloseOnEscape
    property bool blockNativeClose: closePolicy === Popup.NoAutoClose

    readonly property bool windowed: true
    readonly property bool separateWindow: true
    readonly property var hostWindow: appWindowDialog
    readonly property var targetScreen:
        owningWindow && owningWindow.screen ? owningWindow.screen : appWindowDialog.screen
    readonly property rect availableScreenGeometry:
        targetScreen && targetScreen.availableGeometry
                     && targetScreen.availableGeometry.width > 0
                     && targetScreen.availableGeometry.height > 0
            ? targetScreen.availableGeometry
            : Qt.rect(dialogSurface.Screen.virtualX, dialogSurface.Screen.virtualY,
                      dialogSurface.Screen.desktopAvailableWidth > 0
                          ? dialogSurface.Screen.desktopAvailableWidth
                          : (app ? app.width : preferredWidth),
                      dialogSurface.Screen.desktopAvailableHeight > 0
                          ? dialogSurface.Screen.desktopAvailableHeight
                          : (app ? app.height : preferredHeight))
    readonly property real availableScreenWidth: availableScreenGeometry.width
    readonly property real availableScreenHeight: availableScreenGeometry.height

    property bool _openCycleActive: false

    signal opened()
    signal closed()
    signal aboutToShow()
    signal aboutToHide()
    signal nativeCloseRequested()

    visible: false
    flags: Qt.Dialog
    modality: modal ? Qt.WindowModal : Qt.NonModal
    transientParent: owningWindow && owningWindow !== appWindowDialog ? owningWindow : null
    minimumWidth: Math.max(1, Math.ceil(dialogMinimumWidth))
    minimumHeight: Math.max(1, Math.ceil(dialogMinimumHeight))
    width: 320
    height: 140
    color: panelColor()

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

    function targetGlobalGeometry(target) {
        if (!target)
            return availableScreenGeometry
        if (target.contentItem && target.contentItem.mapToGlobal) {
            var contentOrigin = target.contentItem.mapToGlobal(0, 0)
            return Qt.rect(contentOrigin.x, contentOrigin.y,
                           target.contentItem.width, target.contentItem.height)
        }
        if (target.mapToGlobal) {
            var itemOrigin = target.mapToGlobal(0, 0)
            return Qt.rect(itemOrigin.x, itemOrigin.y,
                           target.width, target.height)
        }
        return Qt.rect(Number(target.x) || 0, Number(target.y) || 0,
                       Number(target.width) || availableScreenGeometry.width,
                       Number(target.height) || availableScreenGeometry.height)
    }

    function clamp(value, minimumValue, maximumValue) {
        return Math.max(minimumValue, Math.min(value, maximumValue))
    }

    function applyPreferredGeometry() {
        var nextWidth = Math.max(1, Math.ceil(preferredGeometryWidth()))
        var nextHeight = Math.max(1, Math.ceil(preferredGeometryHeight()))
        width = nextWidth
        height = nextHeight

        var target = centerTarget
        var targetGeometry = targetGlobalGeometry(target)
        var desiredX = targetGeometry.x + Math.round((targetGeometry.width - nextWidth) / 2)
        var desiredY = targetGeometry.y + Math.round((targetGeometry.height - nextHeight) / 2)
        var maximumX = availableScreenGeometry.x
                       + Math.max(0, availableScreenGeometry.width - nextWidth)
        var maximumY = availableScreenGeometry.y
                       + Math.max(0, availableScreenGeometry.height - nextHeight)
        x = Math.round(clamp(desiredX, availableScreenGeometry.x, maximumX))
        y = Math.round(clamp(desiredY, availableScreenGeometry.y, maximumY))
    }

    function open() {
        if (visible) {
            raise()
            requestActivate()
            return
        }
        applyPreferredGeometry()
        aboutToShow()
        visible = true
        raise()
        requestActivate()
    }

    function closeDialog() {
        if (!visible)
            return
        aboutToHide()
        visible = false
    }

    function requestUiClose() {
        if (blockNativeClose)
            nativeCloseRequested()
        else
            closeDialog()
    }

    function panelColor() {
        if (tone === "error")
            return "#fff8f7"
        if (tone === "warning")
            return "#fffaf2"
        return "#f8fbfd"
    }

    onVisibleChanged: {
        if (visible) {
            _openCycleActive = true
            opened()
        } else if (_openCycleActive) {
            _openCycleActive = false
            closed()
        }
    }

    onClosing: function(closeEvent) {
        if (blockNativeClose) {
            closeEvent.accepted = false
            Qt.callLater(function() {
                appWindowDialog.nativeCloseRequested()
            })
            return
        }
        aboutToHide()
    }

    Connections {
        target: appWindowDialog.owningWindow
        ignoreUnknownSignals: true

        function onVisibleChanged() {
            if (appWindowDialog.owningWindow
                    && !appWindowDialog.owningWindow.visible
                    && appWindowDialog.visible)
                appWindowDialog.closeDialog()
        }
    }

    onDialogBodyChanged: {
        if (dialogBody)
            dialogBody.parent = bodyHost
    }

    onDialogFooterChanged: {
        if (dialogFooter)
            dialogFooter.parent = footerHost
    }

    Component.onCompleted: {
        if (dialogBody)
            dialogBody.parent = bodyHost
        if (dialogFooter)
            dialogFooter.parent = footerHost
    }

    FocusScope {
        id: dialogSurface
        anchors.fill: parent
        focus: true

        // Let the focused control (especially a ComboBox popup) consume Escape
        // first. Only an unhandled Escape closes the containing window.
        Keys.priority: Keys.AfterItem
        Keys.onEscapePressed: function(event) {
            if ((appWindowDialog.closePolicy & Popup.CloseOnEscape) === 0)
                return
            event.accepted = true
            appWindowDialog.requestUiClose()
        }

        Rectangle {
            anchors.fill: parent
            color: appWindowDialog.panelColor()
            border.color: "#8ea5b1"
            border.width: 1
        }

        Item {
            id: bodyHost
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: footerHost.top
            anchors.leftMargin: appWindowDialog.padding
            anchors.rightMargin: appWindowDialog.padding
            anchors.topMargin: appWindowDialog.padding
            anchors.bottomMargin: footerHost.height > 0 ? 0 : appWindowDialog.padding
            clip: true
        }

        Item {
            id: footerHost
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: appWindowDialog.dialogFooter
                    ? appWindowDialog.dialogFooter.implicitHeight : 0
            visible: height > 0
        }
    }

    Binding {
        target: appWindowDialog.dialogBody
        property: "x"
        value: 0
        when: appWindowDialog.dialogBody !== null
    }

    Binding {
        target: appWindowDialog.dialogBody
        property: "y"
        value: 0
        when: appWindowDialog.dialogBody !== null
    }

    Binding {
        target: appWindowDialog.dialogBody
        property: "width"
        value: bodyHost.width
        when: appWindowDialog.dialogBody !== null
    }

    Binding {
        target: appWindowDialog.dialogBody
        property: "height"
        value: bodyHost.height
        when: appWindowDialog.dialogBody !== null
    }

    Binding {
        target: appWindowDialog.dialogFooter
        property: "x"
        value: 0
        when: appWindowDialog.dialogFooter !== null
    }

    Binding {
        target: appWindowDialog.dialogFooter
        property: "y"
        value: 0
        when: appWindowDialog.dialogFooter !== null
    }

    Binding {
        target: appWindowDialog.dialogFooter
        property: "width"
        value: footerHost.width
        when: appWindowDialog.dialogFooter !== null
    }

    Binding {
        target: appWindowDialog.dialogFooter
        property: "height"
        value: footerHost.height
        when: appWindowDialog.dialogFooter !== null
    }
}
