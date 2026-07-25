import QtQuick
import QtQuick.Controls
import QtTest
import "../../app/qml" as Widgets

TestCase {
    id: testRoot

    name: "EngineCommunicationWindow"
    when: windowShown
    width: 1000
    height: 700

    property real revision: 0
    property real stdinRevision: 0
    property real stdoutRevision: 0
    property real stderrRevision: 0
    property int logCharacterCount: 0
    property int logChangeMask: 0
    property int stdinRetainedCount: 0
    property int stdoutRetainedCount: 0
    property int stderrRetainedCount: 0

    Rectangle {
        id: fakeApp
        width: testRoot.width
        height: testRoot.height
        property bool active: true
        property bool compactLayout: false
        property bool applicationShutdownPrepared: false
        property bool showEngineCommunicationStdin: true
        property bool showEngineCommunicationStdout: true
        property bool showEngineCommunicationStderr: true
        property string coordinateFontFamily: "JetBrains Mono"

        function trText(key) {
            return key
        }

        function focusBoardInput() {
        }
    }

    ListModel {
        id: logModel
    }

    Widgets.EngineCommunicationWindow {
        id: dialog
        app: fakeApp
        logModel: logModel
        logRevision: testRoot.revision
        logCharacterCount: testRoot.logCharacterCount
        logChangeMask: testRoot.logChangeMask
        stdinRevision: testRoot.stdinRevision
        stdoutRevision: testRoot.stdoutRevision
        stderrRevision: testRoot.stderrRevision
        stdinRetainedCount: testRoot.stdinRetainedCount
        stdoutRetainedCount: testRoot.stdoutRetainedCount
        stderrRetainedCount: testRoot.stderrRetainedCount
        onClearLogRequested: {
            logModel.clear()
            testRoot.logCharacterCount = 0
            testRoot.logChangeMask = 7
            testRoot.stdinRetainedCount = 0
            testRoot.stdoutRetainedCount = 0
            testRoot.stderrRetainedCount = 0
            testRoot.revision += 1
        }
    }

    function streamMask(stream) {
        return stream === "stdin" ? 1 : stream === "stderr" ? 4 : 2
    }

    function adjustRetainedCount(stream, delta) {
        if (stream === "stdin")
            stdinRetainedCount += delta
        else if (stream === "stderr")
            stderrRetainedCount += delta
        else
            stdoutRetainedCount += delta
    }

    function appendLog(stream, line) {
        var color = stream === "stdin" ? "#7ee2a8"
                  : stream === "stderr" ? "#ff8b7f" : "#d9e6ee"
        logModel.append({ "stream": stream, "line": line, "color": color })
        logCharacterCount += String(line).length + 1
        logChangeMask = streamMask(stream)
        adjustRetainedCount(stream, 1)
        if (stream === "stdin")
            stdinRevision += 1
        else if (stream === "stderr")
            stderrRevision += 1
        else
            stdoutRevision += 1
        revision += 1
    }

    function appendBoundedLog(stream, line, maximumLines) {
        var mask = streamMask(stream)
        while (logModel.count >= maximumLines) {
            var removed = logModel.get(0)
            mask |= streamMask(removed.stream)
            adjustRetainedCount(removed.stream, -1)
            logCharacterCount -= String(removed.line).length + 1
            logModel.remove(0)
        }
        var color = stream === "stdin" ? "#7ee2a8"
                  : stream === "stderr" ? "#ff8b7f" : "#d9e6ee"
        logModel.append({ "stream": stream, "line": line, "color": color })
        logCharacterCount += String(line).length + 1
        logChangeMask = mask
        adjustRetainedCount(stream, 1)
        if (stream === "stdin")
            stdinRevision += 1
        else if (stream === "stderr")
            stderrRevision += 1
        else
            stdoutRevision += 1
        revision += 1
    }

    function editor() {
        return findChild(dialog.contentItem, "engineCommunicationText")
    }

    function cleanup() {
        dialog.visible = false
        logModel.clear()
        logCharacterCount = 0
        logChangeMask = 7
        stdinRetainedCount = 0
        stdoutRetainedCount = 0
        stderrRetainedCount = 0
        revision += 1
        fakeApp.showEngineCommunicationStdin = true
        fakeApp.showEngineCommunicationStdout = true
        fakeApp.showEngineCommunicationStderr = true
        wait(0)
    }

    function test_selectionCrossesSeveralLogLines() {
        appendLog("stdin", "first command")
        appendLog("stdout", "second response")
        appendLog("stderr", "third warning")
        dialog.openWindow()
        wait(80)

        var textEdit = editor()
        verify(textEdit !== null)
        var plainText = textEdit.getText(0, textEdit.length)
        var start = plainText.indexOf("first command")
        var end = plainText.indexOf("third warning") + "third warning".length
        verify(start >= 0)
        verify(end > start)

        textEdit.select(start, end)
        verify(textEdit.selectedText.indexOf("first command") >= 0)
        verify(textEdit.selectedText.indexOf("second response") >= 0)
        verify(textEdit.selectedText.indexOf("third warning") >= 0)
        compare(dialog.logFollowsTail, false)
    }

    function test_followingPausesAndResumesWithoutReplacingSelection() {
        for (var index = 0; index < 80; ++index)
            appendLog("stdout", "response " + index)
        dialog.openWindow()
        wait(100)
        verify(dialog.logAtTail())

        editor().forceActiveFocus()
        wait(0)
        compare(dialog.logFollowsTail, true)

        appendLog("stdout", "live response")
        wait(100)
        verify(dialog.logAtTail())
        verify(editor().getText(0, editor().length).indexOf("live response") >= 0)

        var scrollView = findChild(dialog.contentItem, "engineCommunicationScroll")
        verify(scrollView !== null)
        verify(scrollView.contentItem.contentHeight > scrollView.contentItem.height)
        scrollView.contentItem.flick(0, 2000)
        wait(100)
        compare(dialog.logFollowsTail, false)
        verify(!dialog.logAtTail())

        var renderedBefore = editor().getText(0, editor().length)
        appendLog("stdout", "paused response")
        wait(100)
        compare(editor().getText(0, editor().length), renderedBefore)
        compare(dialog.newMessageCount, 1)
        compare(findChild(dialog.contentItem,
                          "engineCommunicationFollowButton").text,
                "\u2193 engineLogViewLatest(1)")

        dialog.resumeLogFollowing()
        wait(100)
        verify(editor().getText(0, editor().length).indexOf("paused response") >= 0)
        verify(dialog.logAtTail())
        compare(dialog.newMessageCount, 0)
    }

    function test_continuousOutputIsThrottledWithoutStarvingRefresh() {
        dialog.openWindow()
        wait(80)

        var renderedDuringBurst = false
        for (var index = 0; index < 12; ++index) {
            appendLog("stdout", "burst line " + index)
            wait(12)
            if (editor().getText(0, editor().length).indexOf("burst line 0") >= 0)
                renderedDuringBurst = true
        }

        verify(renderedDuringBurst)
        compare(dialog.logFollowsTail, true)
    }

    function test_filteringAndHtmlEscapingUseLiteralLogText() {
        appendLog("stdin", "name")
        appendLog("stdout", "<img src='bad'> & response")
        dialog.openWindow()
        wait(80)

        var plainText = editor().getText(0, editor().length)
        verify(plainText.indexOf("name") >= 0)
        verify(plainText.indexOf("<img src='bad'> & response") >= 0)
        verify(plainText.indexOf("[stdin]") < 0)
        verify(plainText.indexOf("[stdout]") < 0)

        fakeApp.showEngineCommunicationStdin = false
        wait(80)
        plainText = editor().getText(0, editor().length)
        verify(plainText.indexOf("name") < 0)
        verify(plainText.indexOf("<img src='bad'> & response") >= 0)
    }

    function test_filteringLargeStreamKeepsViewportInsideShorterDocument() {
        appendLog("stdout", "kept response 1")
        appendLog("stdout", "kept response 2")
        for (var index = 0; index < 200; ++index)
            appendLog("stderr", "filtered error " + index)
        dialog.openWindow()
        wait(100)

        var viewport = findChild(dialog.contentItem,
                                 "engineCommunicationScroll").contentItem
        verify(viewport.contentHeight > viewport.height)
        dialog.pauseLogFollowing()

        fakeApp.showEngineCommunicationStderr = false
        wait(100)

        var maxY = Math.max(0, viewport.contentHeight - viewport.height)
        compare(dialog.logFollowsTail, true)
        verify(dialog.logAtTail())
        verify(viewport.contentY <= maxY + 1,
               "viewport was left below the filtered document")
        verify(editor().getText(0, editor().length).indexOf("kept response 1") >= 0)
    }

    function test_filterRebuildCannotOverrideNewFollowIntent() {
        appendLog("stdout", "kept response")
        for (var index = 0; index < 100; ++index)
            appendLog("stderr", "filtered error " + index)
        dialog.openWindow()
        wait(100)

        dialog.pauseLogFollowing()
        fakeApp.showEngineCommunicationStderr = false
        dialog.resumeLogFollowing()
        wait(100)

        compare(dialog.logFollowsTail, true)
        verify(dialog.logAtTail())
        verify(editor().getText(0, editor().length).indexOf("kept response") >= 0)
    }

    function test_hiddenStreamDoesNotRebuildTheVisibleDocument() {
        appendLog("stdout", "visible response")
        dialog.openWindow()
        wait(80)
        fakeApp.showEngineCommunicationStderr = false
        wait(80)
        var rebuildBefore = dialog.rebuildSerial
        var textBefore = editor().getText(0, editor().length)

        appendLog("stderr", "hidden warning")
        wait(220)

        compare(dialog.rebuildSerial, rebuildBefore)
        compare(editor().getText(0, editor().length), textBefore)
    }

    function test_hiddenAppendStillRebuildsWhenItEvictsVisibleText() {
        appendLog("stdout", "visible response")
        dialog.openWindow()
        wait(80)
        fakeApp.showEngineCommunicationStderr = false
        wait(80)

        var removed = logModel.get(0)
        logModel.remove(0)
        adjustRetainedCount(removed.stream, -1)
        logCharacterCount -= String(removed.line).length + 1
        var warning = "hidden warning"
        logModel.append({
            "stream": "stderr",
            "line": warning,
            "color": "#ff8b7f"
        })
        adjustRetainedCount("stderr", 1)
        logCharacterCount += warning.length + 1
        logChangeMask = 6
        stderrRevision += 1
        revision += 1
        wait(220)

        verify(editor().getText(0, editor().length)
                   .indexOf("visible response") < 0)
    }

    function test_newMessageCountDoesNotExceedRetainedMessages() {
        appendLog("stdout", "initial response")
        dialog.openWindow()
        wait(80)
        dialog.pauseLogFollowing()

        appendBoundedLog("stdout", "new response 1", 2)
        appendBoundedLog("stdout", "new response 2", 2)
        appendBoundedLog("stdout", "new response 3", 2)
        wait(80)

        compare(dialog.newMessageCount, 2)
        compare(dialog.newMessagesTruncated, true)
        compare(findChild(dialog.contentItem,
                          "engineCommunicationFollowButton").text,
                "\u2193 engineLogViewLatest(2)")
    }

    function test_userScrollWinsAgainstPendingPositionReconcile() {
        for (var index = 0; index < 100; ++index)
            appendLog("stdout", "response " + index)
        dialog.openWindow()
        wait(100)

        var viewport = findChild(dialog.contentItem,
                                 "engineCommunicationScroll").contentItem
        verify(dialog.logAtTail())
        dialog.reconcileLogPosition()
        viewport.flick(0, 2000)
        viewport.contentY = Math.max(0, viewport.contentY - 100)
        viewport.cancelFlick()
        wait(100)

        compare(dialog.logFollowsTail, false)
        verify(!dialog.logAtTail())
    }
}
