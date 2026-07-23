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

    Widgets.AppDialog {
        id: dialog

        app: testRoot
        centerTarget: testRoot
        owningWindow: testRoot.Window.window
        modal: true
        title: "Geometry test"
        closePolicy: Popup.NoAutoClose
        preferredWidth: 760
        preferredHeight: 500
        dialogMinimumWidth: 640
        dialogMinimumHeight: 400

        contentItem: Rectangle {
            implicitWidth: 300
            implicitHeight: 200
            color: "transparent"
        }

        onNativeCloseRequested: {
            testRoot.nativeCloseRequests += 1
            close()
        }
    }

    function cleanup() {
        dialog.close()
        wait(0)
    }

    function test_initialGeometryAndResizePosition() {
        dialog.open()
        tryCompare(dialog, "visible", true)
        wait(50)

        compare(dialog.width, 760)
        compare(dialog.height, 500)
        verify(dialog.owningWindow !== null)
        verify(dialog.hostWindow !== null)
        verify(dialog.hostWindow !== dialog.owningWindow)
        compare(dialog.hostWindow.minimumWidth, 640)
        compare(dialog.hostWindow.minimumHeight, 400)

        dialog.hostWindow.x = 85
        dialog.hostWindow.y = 65
        wait(20)
        var movedX = dialog.hostWindow.x
        var movedY = dialog.hostWindow.y

        dialog.hostWindow.width = 700
        dialog.hostWindow.height = 450
        wait(20)

        compare(dialog.hostWindow.x, movedX)
        compare(dialog.hostWindow.y, movedY)
        compare(dialog.width, 700)
        compare(dialog.height, 450)
    }

    function test_nativeCloseIsDelegatedToTheDialog() {
        nativeCloseRequests = 0
        dialog.open()
        tryCompare(dialog, "visible", true)
        wait(20)

        dialog.hostWindow.close()

        tryCompare(testRoot, "nativeCloseRequests", 1)
        tryCompare(dialog, "visible", false)
    }
}
