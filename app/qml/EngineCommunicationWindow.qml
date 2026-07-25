import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import "EngineLogFormatter.js" as EngineLogFormatter

Window {
    id: engineCommunicationDialog

    required property var app
    required property var logModel
    required property double logRevision
    required property int logCharacterCount
    required property int logChangeMask
    required property double stdinRevision
    required property double stdoutRevision
    required property double stderrRevision
    required property int stdinRetainedCount
    required property int stdoutRetainedCount
    required property int stderrRetainedCount

    signal sendCommand(string command)
    signal clearLogRequested()

    title: app.trText("engineCommunicationLog")
    flags: Qt.Window
    transientParent: null
    color: "#f7fafc"
    minimumWidth: 520
    minimumHeight: 320
    width: 860
    height: 560
    visible: false

    property bool positionedOnce: false
    property bool logFollowsTail: true
    property bool rebuildingLog: false
    property bool reconcilingLogPosition: false
    property bool logDirty: true
    property int rebuildSerial: 0
    property int logPositionSerial: 0
    property double lastRenderedRevision: 0
    property double lastRenderedStdinRevision: 0
    property double lastRenderedStdoutRevision: 0
    property double lastRenderedStderrRevision: 0
    readonly property int visibleStreamMask:
        (app.showEngineCommunicationStdin ? 1 : 0)
        | (app.showEngineCommunicationStdout ? 2 : 0)
        | (app.showEngineCommunicationStderr ? 4 : 0)
    readonly property double stdinArrivalDelta:
        Math.max(0, stdinRevision - lastRenderedStdinRevision)
    readonly property double stdoutArrivalDelta:
        Math.max(0, stdoutRevision - lastRenderedStdoutRevision)
    readonly property double stderrArrivalDelta:
        Math.max(0, stderrRevision - lastRenderedStderrRevision)
    readonly property int newMessageCount: Math.floor(
        (app.showEngineCommunicationStdin
             ? Math.min(stdinArrivalDelta, stdinRetainedCount) : 0)
        + (app.showEngineCommunicationStdout
             ? Math.min(stdoutArrivalDelta, stdoutRetainedCount) : 0)
        + (app.showEngineCommunicationStderr
             ? Math.min(stderrArrivalDelta, stderrRetainedCount) : 0))
    readonly property bool newMessagesTruncated:
        (app.showEngineCommunicationStdin
             && stdinArrivalDelta > stdinRetainedCount)
        || (app.showEngineCommunicationStdout
             && stdoutArrivalDelta > stdoutRetainedCount)
        || (app.showEngineCommunicationStderr
             && stderrArrivalDelta > stderrRetainedCount)

    function clearCommandFocus() {
        engineCommunicationCommandField.focus = false
        engineCommunicationFocusSink.forceActiveFocus()
    }

    function logViewport() {
        return engineCommunicationScroll.contentItem
    }

    function logAtTail() {
        var viewport = logViewport()
        if (!viewport)
            return true
        var maxY = Math.max(0, viewport.contentHeight - viewport.height)
        return viewport.atYEnd || viewport.contentY >= maxY - 8
    }

    function scheduleLogPositionReconcile() {
        if (visible)
            logPositionTimer.restart()
    }

    function reconcileLogPosition() {
        var viewport = logViewport()
        if (!viewport)
            return

        reconcilingLogPosition = true
        var currentPosition = ++logPositionSerial
        var maxY = Math.max(0, viewport.contentHeight - viewport.height)
        viewport.contentY = logFollowsTail
                && engineCommunicationText.selectedText.length === 0
                ? maxY
                : Math.max(0, Math.min(viewport.contentY, maxY))

        Qt.callLater(function() {
            if (currentPosition !== engineCommunicationDialog.logPositionSerial)
                return
            var currentViewport = engineCommunicationDialog.logViewport()
            if (currentViewport) {
                var currentMaxY = Math.max(
                            0,
                            currentViewport.contentHeight - currentViewport.height)
                currentViewport.contentY = engineCommunicationDialog.logFollowsTail
                        && engineCommunicationText.selectedText.length === 0
                        ? currentMaxY
                        : Math.max(0,
                                   Math.min(currentViewport.contentY, currentMaxY))
            }
            engineCommunicationDialog.reconcilingLogPosition = false
        })
    }

    function pauseLogFollowing() {
        logFollowsTail = false
    }

    function scheduleLogRefresh() {
        if (!logRefreshTimer.running)
            logRefreshTimer.start()
    }

    function resumeLogFollowing() {
        engineCommunicationText.deselect()
        logFollowsTail = true
        if (logDirty)
            rebuildLog()
        else
            scheduleLogPositionReconcile()
    }

    function renderedLogHtml() {
        return EngineLogFormatter.buildHtml(
                    logModel,
                    app.showEngineCommunicationStdin,
                    app.showEngineCommunicationStdout,
                    app.showEngineCommunicationStderr)
    }

    function rebuildLog() {
        if (!visible)
            return
        var currentRebuild = ++rebuildSerial
        rebuildingLog = true
        engineCommunicationText.text = renderedLogHtml()
        lastRenderedRevision = logRevision
        lastRenderedStdinRevision = stdinRevision
        lastRenderedStdoutRevision = stdoutRevision
        lastRenderedStderrRevision = stderrRevision
        logDirty = false
        scheduleLogPositionReconcile()
        Qt.callLater(function() {
            if (currentRebuild !== engineCommunicationDialog.rebuildSerial)
                return
            engineCommunicationDialog.reconcileLogPosition()
            engineCommunicationDialog.rebuildingLog = false
            if (engineCommunicationDialog.logDirty
                    && engineCommunicationDialog.logFollowsTail)
                engineCommunicationDialog.scheduleLogRefresh()
        })
    }

    function notifyLogChanged() {
        if ((logChangeMask & visibleStreamMask) === 0)
            return
        logDirty = true
        if (!visible)
            return
        if (engineCommunicationText.selectedText.length > 0) {
            pauseLogFollowing()
            return
        }
        if (logFollowsTail)
            scheduleLogRefresh()
    }

    function refreshLogFilter() {
        logRefreshTimer.stop()
        engineCommunicationText.deselect()
        logFollowsTail = true
        rebuildLog()
    }

    function requestClearLog() {
        logRefreshTimer.stop()
        engineCommunicationText.deselect()
        logFollowsTail = true
        clearLogRequested()
        logRefreshTimer.stop()
        logDirty = true
        rebuildLog()
    }

    function submitCommand() {
        var command = engineCommunicationCommandField.text.trim()
        if (command.length <= 0)
            return

        engineCommunicationDialog.sendCommand(command)
        engineCommunicationCommandField.text = ""
        engineCommunicationCommandField.forceActiveFocus()
    }

    function openWindow(focusCommand) {
        if (!positionedOnce) {
            width = Math.min(860, Math.max(minimumWidth, app.width - 80))
            height = Math.min(560, Math.max(minimumHeight, app.height - 90))
            x = Math.round(app.x + (app.width - width) / 2)
            y = Math.round(app.y + (app.height - height) / 2)
            positionedOnce = true
        }
        visible = true
        raise()
        requestActivate()
        logFollowsTail = true
        logDirty = true
        rebuildLog()
        Qt.callLater(function() {
            if (focusCommand === true && engineCommunicationDialog.active)
                engineCommunicationCommandField.forceActiveFocus()
        })
    }

    onLogRevisionChanged: notifyLogChanged()

    onVisibleChanged: {
        if (!visible) {
            logRefreshTimer.stop()
            clearCommandFocus()
            if (!app.applicationShutdownPrepared)
                app.focusBoardInput()
        }
    }

    onActiveChanged: {
        if (!active)
            clearCommandFocus()
    }

    Shortcut {
        sequence: "Esc"
        onActivated: engineCommunicationDialog.visible = false
    }

    Timer {
        id: logRefreshTimer
        interval: engineCommunicationDialog.logCharacterCount > 1048576 ? 750
                  : engineCommunicationDialog.logCharacterCount > 524288 ? 400
                  : engineCommunicationDialog.logCharacterCount > 100000 ? 180
                  : engineCommunicationDialog.logModel.count > 500 ? 80 : 40
        repeat: false
        onTriggered: {
            if (engineCommunicationDialog.visible
                    && engineCommunicationDialog.logFollowsTail
                    && engineCommunicationText.selectedText.length === 0)
                engineCommunicationDialog.rebuildLog()
        }
    }

    Timer {
        id: logPositionTimer
        interval: 0
        repeat: false
        onTriggered: engineCommunicationDialog.reconcileLogPosition()
    }

    Connections {
        target: app

        function onShowEngineCommunicationStdinChanged() {
            engineCommunicationDialog.refreshLogFilter()
        }

        function onShowEngineCommunicationStdoutChanged() {
            engineCommunicationDialog.refreshLogFilter()
        }

        function onShowEngineCommunicationStderrChanged() {
            engineCommunicationDialog.refreshLogFilter()
        }

        function onActiveChanged() {
            if (app.active && engineCommunicationDialog.visible
                    && !engineCommunicationDialog.active)
                app.raise()
        }

        function onVisibleChanged() {
            if (!app.visible)
                engineCommunicationDialog.visible = false
        }
    }

    Connections {
        target: engineCommunicationScroll.contentItem

        function onContentYChanged() {
            var viewport = engineCommunicationScroll.contentItem
            if (!viewport)
                return
            if (engineCommunicationScrollBar.pressed) {
                engineCommunicationDialog.pauseLogFollowing()
                return
            }
            if (engineCommunicationDialog.rebuildingLog
                    || engineCommunicationDialog.reconcilingLogPosition)
                return
        }

        function onMovementStarted() {
            engineCommunicationDialog.pauseLogFollowing()
        }

        function onMovementEnded() {
            if (engineCommunicationDialog.rebuildingLog
                    || engineCommunicationDialog.reconcilingLogPosition)
                return
            if (engineCommunicationDialog.logAtTail()
                    && engineCommunicationText.selectedText.length === 0)
                engineCommunicationDialog.resumeLogFollowing()
            else
                engineCommunicationDialog.pauseLogFollowing()
        }

        function onContentHeightChanged() {
            engineCommunicationDialog.scheduleLogPositionReconcile()
        }

        function onHeightChanged() {
            engineCommunicationDialog.scheduleLogPositionReconcile()
        }
    }

    Item {
        id: engineCommunicationFocusSink
        width: 0
        height: 0
        focus: true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 18

            AppCheckBox {
                text: "stdin"
                checked: app.showEngineCommunicationStdin
                onToggled: app.showEngineCommunicationStdin = checked
            }

            AppCheckBox {
                text: "stdout"
                checked: app.showEngineCommunicationStdout
                onToggled: app.showEngineCommunicationStdout = checked
            }

            AppCheckBox {
                text: "stderr"
                checked: app.showEngineCommunicationStderr
                onToggled: app.showEngineCommunicationStderr = checked
            }

            Item { Layout.fillWidth: true }

            Label {
                visible: !engineCommunicationDialog.logFollowsTail
                text: app.trText("engineLogAutoScrollPaused")
                color: "#607782"
                font.pixelSize: 12
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#111820"
            border.color: "#2d3a44"
            border.width: 1
            clip: true

            ScrollView {
                id: engineCommunicationScroll
                objectName: "engineCommunicationScroll"
                anchors.fill: parent
                anchors.margins: 1
                clip: true
                contentWidth: availableWidth
                contentHeight: engineCommunicationContent.height

                onHeightChanged: {
                    if (engineCommunicationDialog.logFollowsTail
                            && !engineCommunicationDialog.rebuildingLog)
                        engineCommunicationDialog.scheduleLogPositionReconcile()
                }

                ScrollBar.vertical: AppScrollBar {
                    id: engineCommunicationScrollBar
                    parent: engineCommunicationScroll
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    onPressedChanged: {
                        if (pressed) {
                            engineCommunicationDialog.pauseLogFollowing()
                            return
                        }
                        if (engineCommunicationDialog.rebuildingLog
                                || engineCommunicationDialog.reconcilingLogPosition)
                            return
                        if (engineCommunicationDialog.logAtTail()
                                && engineCommunicationText.selectedText.length === 0)
                            engineCommunicationDialog.resumeLogFollowing()
                        else
                            engineCommunicationDialog.pauseLogFollowing()
                    }
                }

                ScrollBar.horizontal: Basic.ScrollBar {
                    policy: ScrollBar.AlwaysOff
                }

                Item {
                    id: engineCommunicationContent
                    width: Math.max(0, engineCommunicationScroll.availableWidth - 14)
                    height: Math.max(engineCommunicationScroll.availableHeight,
                                     engineCommunicationText.contentHeight + 12)

                    Basic.TextArea {
                        id: engineCommunicationText
                        objectName: "engineCommunicationText"
                        x: 8
                        y: 6
                        width: Math.max(0, parent.width - 16)
                        height: Math.max(contentHeight,
                                         engineCommunicationScroll.availableHeight - 12)
                        padding: 0
                        textFormat: TextEdit.RichText
                        readOnly: true
                        selectByMouse: true
                        selectByKeyboard: true
                        persistentSelection: true
                        cursorVisible: false
                        color: "#d9e6ee"
                        selectionColor: "#2a91c9"
                        selectedTextColor: "#ffffff"
                        font.family: app.coordinateFontFamily
                        font.pixelSize: app.compactLayout ? 12 : 13
                        font.weight: Font.Medium
                        wrapMode: TextEdit.WrapAnywhere
                        background: null

                        onSelectedTextChanged: {
                            if (selectedText.length > 0)
                                engineCommunicationDialog.pauseLogFollowing()
                        }
                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_End
                                    && (event.modifiers & Qt.ControlModifier)) {
                                engineCommunicationDialog.resumeLogFollowing()
                                event.accepted = true
                            }
                        }
                    }
                }
            }

            SavePromptButton {
                objectName: "engineCommunicationFollowButton"
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 14
                visible: !engineCommunicationDialog.logFollowsTail
                primary: engineCommunicationDialog.logDirty
                         && engineCommunicationDialog.newMessageCount > 0
                text: {
                    if (engineCommunicationDialog.logDirty
                            && engineCommunicationDialog.newMessageCount > 0)
                        return "\u2193 " + app.trText("engineLogViewLatest")
                                + "(" + engineCommunicationDialog.newMessageCount + ")"
                    return "\u2193 " + app.trText("engineLogFollowLatest")
                }
                onClicked: engineCommunicationDialog.resumeLogFollowing()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            AppTextField {
                id: engineCommunicationCommandField
                font.family: app.coordinateFontFamily
                font.pixelSize: app.compactLayout ? 12 : 13
                font.weight: Font.Medium
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                onAccepted: engineCommunicationDialog.submitCommand()
            }

            SavePromptButton {
                text: app.trText("send")
                primary: true
                onClicked: engineCommunicationDialog.submitCommand()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            SavePromptButton {
                text: app.trText("copySelected")
                enabled: engineCommunicationText.selectedText.length > 0
                onClicked: engineCommunicationText.copy()
            }

            SavePromptButton {
                text: app.trText("selectAll")
                enabled: engineCommunicationText.length > 0
                onClicked: {
                    engineCommunicationDialog.pauseLogFollowing()
                    engineCommunicationText.forceActiveFocus()
                    engineCommunicationText.selectAll()
                }
            }

            Item { Layout.fillWidth: true }

            SavePromptButton {
                text: app.trText("clear")
                onClicked: engineCommunicationDialog.requestClearLog()
            }

            SavePromptButton {
                text: app.trText("close")
                primary: true
                onClicked: {
                    engineCommunicationDialog.visible = false
                    app.focusBoardInput()
                }
            }
        }
    }
}
