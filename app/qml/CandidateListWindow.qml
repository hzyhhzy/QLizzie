import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import "CandidateAnalysis.js" as CandidateAnalysis
import "CandidateTable.js" as CandidateTable
import "WindowGeometry.js" as WindowGeometry

Window {
    id: candidateWindow

    required property var app

    title: app.trText("candidateListWindowTitle")
    flags: Qt.Window
    transientParent: null
    color: "#f3f7f9"
    minimumWidth: 720
    minimumHeight: 300
    width: 980
    height: 520
    visible: false

    property bool positionedOnce: false
    property int sortColumn: 0
    property bool sortAscending: true
    property string selectedCandidateKey: ""
    property bool tableRefreshPending: false
    readonly property real tableContentWidth: 878
    readonly property var emptyTableData: ({
        "rows": [],
        "totalVisits": 0,
        "maxVisits": 0,
        "concentration": 0
    })
    property var tableData: emptyTableData
    readonly property var columns: [
        { "textKey": "candidateIndex", "field": "indexText", "width": 58 },
        { "textKey": "candidateCoordinate", "field": "coordinateText", "width": 88 },
        { "textKey": "candidateLcbPercent", "field": "lcbText", "width": 82 },
        { "textKey": "candidateWinratePercent", "field": "winrateText", "width": 92 },
        { "textKey": "candidateVisits", "field": "visitsText", "width": 94 },
        { "textKey": "candidateVisitShare", "field": "shareText", "width": 90 },
        { "textKey": "candidatePolicyPercent", "field": "policyText", "width": 116 },
        { "textKey": "candidateScoreMean", "field": "scoreMeanText", "width": 96 },
        { "textKey": "candidateScoreStdev", "field": "scoreStdevText", "width": 162 }
    ]

    ListModel {
        id: candidateRows
    }

    function openWindow() {
        if (!positionedOnce) {
            WindowGeometry.centerWindow(
                        candidateWindow, app,
                        Math.min(980, Math.max(minimumWidth, app.width - 60)),
                        Math.min(520, Math.max(minimumHeight, app.height - 80)))
            positionedOnce = true
        } else {
            WindowGeometry.clampWindow(candidateWindow, app)
        }
        visible = true
        raise()
        requestActivate()
    }

    function closeWindow() {
        if (visible)
            candidateWindow.close()
    }

    function toggleWindow() {
        if (visible)
            closeWindow()
        else
            openWindow()
    }

    function setSortColumn(columnIndex) {
        if (sortColumn === columnIndex)
            sortAscending = !sortAscending
        else {
            sortColumn = columnIndex
            sortAscending = columnIndex <= 1
        }
        requestTableRefresh(true)
    }

    function refreshTable() {
        if (!visible)
            return
        if (candidateList.replacingModel) {
            tableRefreshPending = true
            return
        }
        candidateList.saveScrollPosition()
        candidateList.replacingModel = true
        tableRefreshPending = false
        var nextTableData = CandidateTable.buildTable(
                    app, app.engineCandidates || [], sortColumn, sortAscending)
        tableData = nextTableData
        for (var index = 0; index < nextTableData.rows.length; ++index) {
            if (index < candidateRows.count)
                candidateRows.set(index, nextTableData.rows[index])
            else
                candidateRows.append(nextTableData.rows[index])
        }
        while (candidateRows.count > nextTableData.rows.length)
            candidateRows.remove(candidateRows.count - 1)
        if (candidateList.userControlsScroll()) {
            candidateList.replacingModel = false
            flushPendingTableRefresh()
        } else {
            candidateList.scheduleScrollRestore()
        }
    }

    function requestTableRefresh(forceRefresh) {
        if (!visible)
            return
        if (candidateList.replacingModel) {
            tableRefreshPending = true
            return
        }
        refreshTable()
    }

    function flushPendingTableRefresh() {
        if (tableRefreshPending && !candidateList.replacingModel)
            refreshTable()
    }

    function rowKey(row) {
        var point = app.parseEngineCoordinate(row.key)
        return point ? app.keyFor(point.x, point.y)
                     : String(row.key).trim().toLowerCase()
    }

    onVisibleChanged: {
        if (visible) {
            requestTableRefresh(true)
        } else {
            tableRefreshPending = false
            tableData = emptyTableData
            Qt.callLater(function() {
                if (!candidateWindow.visible)
                    candidateRows.clear()
            })
        }
        if (!visible && !app.applicationShutdownPrepared)
            app.focusBoardInput()
    }

    Connections {
        target: app

        function onVisibleChanged() {
            if (!app.visible)
                candidateWindow.closeWindow()
        }

        function onEngineCandidateRevisionChanged() {
            candidateWindow.requestTableRefresh(false)
        }

        function onLanguageChanged() {
            candidateWindow.requestTableRefresh(false)
        }
    }

    Shortcut {
        sequence: "U"
        context: Qt.WindowShortcut
        onActivated: candidateWindow.closeWindow()
    }

    Shortcut {
        sequence: "Esc"
        context: Qt.WindowShortcut
        onActivated: candidateWindow.closeWindow()
    }

    component HeaderCell: Rectangle {
        required property int columnIndex
        required property string textKey

        height: 38
        color: headerMouse.pressed ? "#d5e1e7"
                                  : headerMouse.containsMouse ? "#e8f0f4" : "#dfe8ed"
        border.color: "#aab8c0"
        border.width: 1

        Label {
            anchors.centerIn: parent
            width: parent.width - 10
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            color: "#14252e"
            font.pixelSize: app.compactLayout ? 12 : 13
            font.bold: true
            text: app.trText(parent.textKey)
                  + (candidateWindow.sortColumn === parent.columnIndex
                     ? (candidateWindow.sortAscending ? " \u25B2" : " \u25BC") : "")
        }

        MouseArea {
            id: headerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: candidateWindow.setSortColumn(parent.columnIndex)
        }
    }

    component DataCell: Rectangle {
        required property string cellText
        property bool selected: false
        property bool alternate: false

        height: 34
        color: selected ? "#c9e6f5" : alternate ? "#f0f4f6" : "#ffffff"
        border.color: "#c2cdd3"
        border.width: 1

        Label {
            anchors.fill: parent
            anchors.leftMargin: 5
            anchors.rightMargin: 5
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            color: "#17242b"
            font.family: app.coordinateFontFamily
            font.pixelSize: app.compactLayout ? 12 : 13
            font.weight: Font.Medium
            text: parent.cellText
        }
    }

    ColumnLayout {
        objectName: "candidateListWindowLayout"
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Rectangle {
            id: candidateTableFrame
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#ffffff"
            border.color: "#9eafb8"
            border.width: 1
            clip: true

            Flickable {
                id: candidateHorizontalViewport
                objectName: "candidateListHorizontalViewport"
                anchors.fill: parent
                clip: true
                contentWidth: candidateWindow.tableContentWidth
                contentHeight: height
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick

                onContentXChanged: candidateList.handleHorizontalPositionChange()
                onMovementStarted: {
                    if (!candidateList.restoringScroll
                            && !candidateList.replacingModel)
                        candidateList.userScrolling = true
                }
                onMovementEnded: candidateList.finishUserScroll()
                onWidthChanged: candidateList.scheduleScrollRestore()

                ScrollBar.horizontal: AppScrollBar {
                    id: candidateHorizontalScrollBar
                    objectName: "candidateListHorizontalScrollBar"
                    parent: candidateTableFrame
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    policy: ScrollBar.AsNeeded
                    onPressedChanged: {
                        if (pressed)
                            candidateList.userScrolling = true
                        else
                            candidateList.finishUserScroll()
                    }
                }

                Item {
                    width: candidateWindow.tableContentWidth
                    height: candidateHorizontalViewport.height

                    Row {
                        id: candidateHeader
                        width: parent.width
                        height: 38

                        Repeater {
                            model: candidateWindow.columns

                            HeaderCell {
                                required property var modelData
                                required property int index
                                columnIndex: index
                                textKey: modelData.textKey
                                width: modelData.width
                            }
                        }
                    }

                    ListView {
                        id: candidateList
                        objectName: "candidateListWindowRows"
                        x: 0
                        y: candidateHeader.height
                        width: parent.width
                        height: Math.max(0, parent.height - y)
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        flickableDirection: Flickable.VerticalFlick
                        model: candidateRows
                        reuseItems: true
                        cacheBuffer: height
                        property real preservedContentX: 0
                        property real preservedContentY: 0
                        property bool restoringScroll: false
                        property bool replacingModel: false
                        property bool userScrolling: false

                        function maxContentX() {
                            return Math.max(
                                        0, candidateHorizontalViewport.contentWidth
                                        - candidateHorizontalViewport.width)
                        }

                        function maxContentY() {
                            return Math.max(0, contentHeight - height)
                        }

                        function userControlsScroll() {
                            return userScrolling || moving || flicking
                                    || draggingVertically
                                    || candidateHorizontalViewport.moving
                                    || candidateHorizontalViewport.flicking
                                    || candidateHorizontalViewport.draggingHorizontally
                                    || candidateVerticalScrollBar.pressed
                                    || candidateHorizontalScrollBar.pressed
                        }

                        function saveScrollPosition() {
                            if (restoringScroll || replacingModel)
                                return
                            preservedContentX = Math.max(
                                        0, Math.min(
                                            candidateHorizontalViewport.contentX,
                                            maxContentX()))
                            preservedContentY = Math.max(
                                        0, Math.min(contentY, maxContentY()))
                        }

                        function scheduleScrollRestore() {
                            scrollRestoreTimer.restart()
                        }

                        function restoreScrollPosition() {
                            restoringScroll = true
                            var targetX = Math.min(preservedContentX, maxContentX())
                            var targetY = Math.min(preservedContentY, maxContentY())
                            preservedContentX = targetX
                            preservedContentY = targetY
                            candidateHorizontalViewport.contentX = targetX
                            contentY = targetY
                            Qt.callLater(function() {
                                candidateHorizontalViewport.contentX
                                        = Math.min(preservedContentX, maxContentX())
                                contentY = Math.min(preservedContentY, maxContentY())
                                restoringScroll = false
                                replacingModel = false
                                candidateWindow.flushPendingTableRefresh()
                            })
                        }

                        function finishUserScroll() {
                            if (userScrolling)
                                saveScrollPosition()
                            userScrolling = false
                            candidateWindow.flushPendingTableRefresh()
                        }

                        function handleHorizontalPositionChange() {
                            if (!replacingModel && !restoringScroll
                                    && userScrolling) {
                                saveScrollPosition()
                            } else if (!replacingModel && !restoringScroll
                                       && Math.abs(
                                           candidateHorizontalViewport.contentX
                                           - Math.min(preservedContentX,
                                                      maxContentX())) > 0.5) {
                                scheduleScrollRestore()
                            }
                        }

                        onContentYChanged: {
                            if (!replacingModel && !restoringScroll
                                    && userScrolling) {
                                saveScrollPosition()
                            } else if (!replacingModel && !restoringScroll
                                       && Math.abs(
                                           contentY
                                           - Math.min(preservedContentY,
                                                      maxContentY())) > 0.5) {
                                scheduleScrollRestore()
                            }
                        }

                        onMovementStarted: {
                            if (!restoringScroll && !replacingModel)
                                userScrolling = true
                        }
                        onMovementEnded: finishUserScroll()
                        onContentHeightChanged: {
                            if (replacingModel)
                                scheduleScrollRestore()
                        }
                        onHeightChanged: scheduleScrollRestore()

                        ScrollBar.vertical: AppScrollBar {
                            id: candidateVerticalScrollBar
                            objectName: "candidateListVerticalScrollBar"
                            parent: candidateTableFrame
                            anchors.top: parent.top
                            anchors.topMargin: candidateHeader.height
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            policy: ScrollBar.AsNeeded
                            onPressedChanged: {
                                if (pressed)
                                    candidateList.userScrolling = true
                                else
                                    candidateList.finishUserScroll()
                            }
                        }

                        Timer {
                            id: scrollRestoreTimer
                            interval: 0
                            repeat: false
                            onTriggered: candidateList.restoreScrollPosition()
                        }

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property var rowData: modelData
                            readonly property bool selected:
                                candidateWindow.selectedCandidateKey
                                    === candidateWindow.rowKey(rowData)
                                || app.hoverKey === candidateWindow.rowKey(rowData)

                            width: candidateWindow.tableContentWidth
                            height: 34
                            color: "transparent"

                            Row {
                                anchors.fill: parent

                                Repeater {
                                    model: candidateWindow.columns

                                    DataCell {
                                        required property var modelData
                                        required property int index
                                        cellText: String(
                                                      parent.parent.rowData[
                                                          modelData.field] || "")
                                        width: modelData.width
                                        selected: parent.parent.selected
                                        alternate: parent.parent.index % 2 === 1
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                onClicked: {
                                    candidateWindow.selectedCandidateKey
                                            = candidateWindow.rowKey(parent.rowData)
                                    app.selectEngineCandidateRow(
                                                parent.rowData.displayIndex, false)
                                }
                            }
                        }

                        Label {
                            anchors.centerIn: parent
                            visible: candidateList.count <= 0
                            text: app.trText("engineNoCandidates")
                            color: "#6a7c85"
                            font.pixelSize: 15
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Label {
                Layout.fillWidth: true
                color: "#344a55"
                font.pixelSize: app.compactLayout ? 12 : 13
                text: app.trText("candidateTotalVisits") + ": "
                      + CandidateAnalysis.formatVisitCount(candidateWindow.tableData.totalVisits)
                      + "    " + app.trText("candidateMaxVisits") + ": "
                      + CandidateAnalysis.formatVisitCount(candidateWindow.tableData.maxVisits)
                      + "    " + app.trText("candidateConcentration") + ": "
                      + Number(candidateWindow.tableData.concentration).toFixed(2) + "%"
            }

            SavePromptButton {
                text: app.trText("close")
                primary: true
                onClicked: candidateWindow.closeWindow()
            }
        }
    }
}
