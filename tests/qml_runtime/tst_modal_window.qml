import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtTest
import "../../app/qml" as Widgets

TestCase {
    id: testRoot

    name: "ModalWindowGeometry"
    when: windowShown
    width: 1000
    height: 700

    property int nativeCloseRequests: 0
    property bool observeClosingGeometry: false
    property int closingWidth: 0
    property int closingHeight: 0
    property int closingGeometryChanges: 0
    property bool observeOpeningVisibility: false
    property int openingVisibleCount: 0
    property int openingWidthWhenShown: 0
    property int openingHeightWhenShown: 0
    property int dialogPreferredHeight: 500

    Widgets.AppWindowDialog {
        id: dialog

        app: testRoot
        centerTarget: testRoot
        owningWindow: testRoot.Window.window
        modal: true
        title: "Geometry test"
        closePolicy: Popup.NoAutoClose
        preferredWidth: 760
        preferredHeight: testRoot.dialogPreferredHeight
        dialogMinimumWidth: 640
        dialogMinimumHeight: 400

        dialogBody: Rectangle {
            id: dialogBody
            implicitWidth: 300
            implicitHeight: 200
            color: "transparent"
        }

        onNativeCloseRequested: {
            testRoot.nativeCloseRequests += 1
            closeDialog()
        }
    }

    Connections {
        target: dialog

        function onWidthChanged() {
            if (testRoot.observeClosingGeometry
                    && dialog.visible
                    && Math.round(dialog.width) !== testRoot.closingWidth)
                testRoot.closingGeometryChanges += 1
        }

        function onHeightChanged() {
            if (testRoot.observeClosingGeometry
                    && dialog.visible
                    && Math.round(dialog.height) !== testRoot.closingHeight)
                testRoot.closingGeometryChanges += 1
        }

        function onVisibleChanged() {
            if (!testRoot.observeOpeningVisibility || !dialog.visible)
                return

            testRoot.openingVisibleCount += 1
            if (testRoot.openingVisibleCount !== 1)
                return

            testRoot.openingWidthWhenShown = Math.round(dialog.width)
            testRoot.openingHeightWhenShown = Math.round(dialog.height)
        }
    }

    function cleanup() {
        observeClosingGeometry = false
        observeOpeningVisibility = false
        dialog.closeDialog()
        dialogPreferredHeight = 500
        wait(0)
    }

    function test_initialGeometryAndResizePosition() {
        dialog.open()
        tryCompare(dialog, "visible", true)
        wait(20)

        compare(Math.round(dialog.width), 760)
        compare(Math.round(dialog.height), 500)
        compare(dialog.hostWindow, dialog)
        compare(dialog.modality, Qt.WindowModal)
        compare(dialog.transientParent, dialog.owningWindow)
        compare(Math.round(dialog.minimumWidth), 640)
        compare(Math.round(dialog.minimumHeight), 400)
        compare(dialogBody.parent !== null, true)

        dialog.x = 85
        dialog.y = 65
        wait(20)
        var movedX = dialog.x
        var movedY = dialog.y

        dialog.width = 700
        dialog.height = 450
        wait(20)

        compare(dialog.x, movedX)
        compare(dialog.y, movedY)
        compare(Math.round(dialog.width), 700)
        compare(Math.round(dialog.height), 450)
    }

    function test_closeKeepsWindowGeometryStable() {
        dialog.open()
        tryCompare(dialog, "visible", true)
        wait(20)

        dialog.width = 700
        dialog.height = 450
        wait(20)

        closingWidth = Math.round(dialog.width)
        closingHeight = Math.round(dialog.height)
        closingGeometryChanges = 0
        observeClosingGeometry = true

        dialog.closeDialog()
        tryCompare(dialog, "visible", false)
        wait(20)

        observeClosingGeometry = false
        compare(closingGeometryChanges, 0)
        compare(Math.round(dialog.width), closingWidth)
        compare(Math.round(dialog.height), closingHeight)
    }

    function test_reopenUsesPreferredGeometryOnFirstFrame() {
        dialog.open()
        tryCompare(dialog, "visible", true)
        wait(20)

        dialog.width = 700
        dialog.height = 450
        wait(20)
        dialog.closeDialog()
        tryCompare(dialog, "visible", false)

        openingVisibleCount = 0
        openingWidthWhenShown = 0
        openingHeightWhenShown = 0
        observeOpeningVisibility = true

        dialog.open()
        tryCompare(dialog, "visible", true)
        observeOpeningVisibility = false

        compare(openingVisibleCount, 1)
        compare(openingWidthWhenShown, 760)
        compare(openingHeightWhenShown, 500)
    }

    function test_reopenFromCompactToFullHeightFillsTheWindow() {
        dialogPreferredHeight = 430
        dialog.open()
        tryCompare(dialog, "visible", true)
        tryCompare(dialog, "height", 430)
        tryCompare(dialogBody, "height", 430 - dialog.padding * 2)

        dialog.closeDialog()
        tryCompare(dialog, "visible", false)

        dialogPreferredHeight = 650
        dialog.open()
        tryCompare(dialog, "visible", true)
        tryCompare(dialog, "height", 650)
        tryCompare(dialogBody, "height", 650 - dialog.padding * 2)
    }

    function test_nativeCloseIsDelegatedToTheDialog() {
        nativeCloseRequests = 0
        dialog.open()
        tryCompare(dialog, "visible", true)
        wait(20)

        dialog.close()

        tryCompare(testRoot, "nativeCloseRequests", 1)
        tryCompare(dialog, "visible", false)
    }
}
