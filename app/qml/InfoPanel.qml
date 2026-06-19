import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

Rectangle {
    id: infoPanel
    required property var app

    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.leftMargin: app.panelMargin
    anchors.topMargin: app.topContentMargin
    anchors.bottomMargin: app.bottomContentMargin
    width: app.infoPanelWidth
    radius: 4
    color: "transparent"
    border.width: 0
    clip: false

    readonly property int panelPadding: app.compactLayout ? 9 : 12
    readonly property int tableRowHeight: app.compactLayout ? 22 : 24
    readonly property int tableHeaderHeight: app.compactLayout ? 23 : 25
    readonly property int indexColumnWidth: app.compactLayout ? 34 : 38
    readonly property int positionColumnWidth: app.compactLayout ? 52 : 60
    readonly property int winrateColumnWidth: app.compactLayout ? 54 : 64
    readonly property int scoreColumnWidth: app.compactLayout ? 48 : 58
    readonly property int visitsColumnWidth: app.compactLayout ? 56 : 68
    readonly property int summaryRowHeight: 72
    readonly property int winrateBarHeight: 40
    readonly property int winrateGraphHeight: 96
    readonly property int activeStoneSize: 44
    readonly property int inactiveStoneSize: 34
    readonly property int panelGap: app.compactLayout ? 8 : 10
    readonly property bool winrateBarVisible: app.analysisModeActive() || app.engineWinratePlaceholderActive()
    readonly property bool winrateGraphVisible: app.analysisModeActive()
    readonly property int topPanelHeight: panelPadding * 2
                                          + summaryRowHeight
                                          + (winrateBarVisible ? 6 + 1 + 6 + winrateBarHeight : 0)
                                          + (winrateGraphVisible ? 6 + winrateGraphHeight : 0)
                                          + 2

    component TableHeaderCell: Rectangle {
        property string text: ""
        width: 60
        height: infoPanel.tableHeaderHeight
        color: "#c5c9cc"
        border.color: "#8d9498"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: parent.text
            color: "#2d3438"
            font.pixelSize: app.compactLayout ? 11 : 12
            font.bold: true
        }
    }

    component TableCell: Text {
        width: 60
        height: infoPanel.tableRowHeight
        color: "#15191c"
        font.pixelSize: app.compactLayout ? 12 : 13
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    Rectangle {
        id: summaryPanel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: infoPanel.topPanelHeight
        radius: 4
        color: "#4c5458"
        border.color: "#3b4449"
        border.width: 1
        clip: true

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 4
            color: "transparent"
            border.color: "#6a7377"
            opacity: 0.55
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: infoPanel.panelPadding
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Layout.minimumHeight: infoPanel.summaryRowHeight
                Layout.preferredHeight: infoPanel.summaryRowHeight
                Layout.maximumHeight: infoPanel.summaryRowHeight
                spacing: 12

                ColumnLayout {
                    Layout.preferredWidth: app.gameRuleMode === app.gameRuleGomoku
                                           ? (app.compactLayout ? 58 : 70) : 86
                    Layout.fillHeight: true
                    spacing: 5

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Rectangle {
                            anchors.centerIn: parent
                            width: app.currentPlayer === 1 ? infoPanel.activeStoneSize : infoPanel.inactiveStoneSize
                            height: width
                            radius: width / 2
                            color: "#050607"
                            border.color: "#11181d"
                            border.width: 1
                        }
                    }

                    Label {
                        visible: app.infoPanelSideTextVisible()
                        text: app.infoPanelSideText(1)
                        color: "#edf2f4"
                        font.pixelSize: app.compactLayout ? 13 : 15
                        font.bold: app.infoPanelShowsStoneCounts()
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                    }
                }

                ColumnLayout {
                    Layout.preferredWidth: app.gameRuleMode === app.gameRuleGomoku
                                           ? (app.compactLayout ? 80 : 100) : 58
                    Layout.fillHeight: true
                    spacing: 3

                    Label {
                        text: app.currentMoveNumberText()
                        color: "#f1f5f7"
                        font.pixelSize: app.compactLayout ? 20 : 24
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: app.compactLayout ? 14 : 16
                        height: width
                        radius: width / 2
                        color: app.engineDotColor()
                        border.color: "#3b4449"
                        border.width: 1
                    }

                    Label {
                        visible: app.infoPanelCenterBottomVisible()
                        text: app.infoPanelCenterBottomText()
                        color: "#f1f5f7"
                        font.pixelSize: app.gameRuleMode === app.gameRuleGomoku
                                        ? (app.compactLayout ? 11 : 13)
                                        : (app.compactLayout ? 18 : 22)
                        font.bold: app.gameRuleMode === app.gameRuleGomoku
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                ColumnLayout {
                    Layout.preferredWidth: app.gameRuleMode === app.gameRuleGomoku
                                           ? (app.compactLayout ? 58 : 70) : 86
                    Layout.fillHeight: true
                    spacing: 5

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Rectangle {
                            anchors.centerIn: parent
                            width: app.currentPlayer === 2 ? infoPanel.activeStoneSize : infoPanel.inactiveStoneSize
                            height: width
                            radius: width / 2
                            color: "#f8fbfd"
                            border.color: "#d7dee3"
                            border.width: 1
                        }
                    }

                    Label {
                        visible: app.infoPanelSideTextVisible()
                        text: app.infoPanelSideText(2)
                        color: "#edf2f4"
                        font.pixelSize: app.compactLayout ? 13 : 15
                        font.bold: app.infoPanelShowsStoneCounts()
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                    }
                }
            }

            Rectangle {
                visible: infoPanel.winrateBarVisible
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#384146"
                opacity: 0.75
            }

            Item {
                id: winrateBarSlot
                visible: infoPanel.winrateBarVisible
                Layout.fillWidth: true
                Layout.minimumHeight: infoPanel.winrateBarHeight
                Layout.preferredHeight: infoPanel.winrateBarHeight
                Layout.maximumHeight: infoPanel.winrateBarHeight

            Item {
                id: winrateContent
                anchors.fill: parent
                visible: !app.engineWinratePlaceholderActive() && app.currentAnalysisHasWinrate()

                readonly property real blackWinrate: app.currentAnalysisBlackWinrate()
                readonly property real whiteWinrate: app.currentAnalysisWhiteWinrate()

                Text {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    text: winrateContent.blackWinrate.toFixed(1) + "%"
                    color: "#f3f5f6"
                    font.pixelSize: app.compactLayout ? 13 : 15
                }

                Text {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    text: winrateContent.whiteWinrate.toFixed(1) + "%"
                    color: "#f3f5f6"
                    font.pixelSize: app.compactLayout ? 13 : 15
                }

                Rectangle {
                    id: winrateTrack
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 20
                    color: "#f6f7f8"
                    border.color: "#c7cbce"
                    border.width: 1

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * winrateContent.blackWinrate / 100
                        color: "#030405"
                    }

                    Rectangle {
                        x: parent.width * 0.5
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 1
                        color: "#8d9498"
                        opacity: 0.75
                    }
                }
            }

            Text {
                anchors.fill: parent
                visible: app.engineWinratePlaceholderActive()
                text: app.engineWinratePlaceholderText()
                color: "#edf2f4"
                font.pixelSize: app.compactLayout ? 15 : 17
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }

        Rectangle {
            id: winrateGraph
            visible: infoPanel.winrateGraphVisible
            Layout.fillWidth: true
            Layout.minimumHeight: infoPanel.winrateGraphHeight
            Layout.preferredHeight: infoPanel.winrateGraphHeight
            Layout.maximumHeight: infoPanel.winrateGraphHeight
            color: "#636b6f"
            border.color: "#3f484d"
            clip: true

            Canvas {
                id: winrateCanvas
                anchors.fill: parent
                anchors.margins: 4

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    var left = 26
                    var right = 8
                    var top = 8
                    var bottom = 18
                    var plotWidth = Math.max(1, width - left - right)
                    var plotHeight = Math.max(1, height - top - bottom)
                    var currentMove = app.currentMoveNumberValue()
                    var xMax = currentMove > 45 ? Math.max(50, currentMove * 1.1) : 50
                    var points = app.winrateHistoryPoints()

                    ctx.strokeStyle = "#dce2e5"
                    ctx.globalAlpha = 0.70
                    ctx.setLineDash([5, 5])
                    for (var g = 0; g <= 2; ++g) {
                        var gy = top + plotHeight * g / 2
                        ctx.beginPath()
                        ctx.moveTo(left, gy)
                        ctx.lineTo(left + plotWidth, gy)
                        ctx.stroke()
                    }
                    ctx.setLineDash([])
                    ctx.globalAlpha = 1

                    ctx.strokeStyle = "#20282d"
                    ctx.lineWidth = 1
                    ctx.beginPath()
                    ctx.moveTo(left, top)
                    ctx.lineTo(left, top + plotHeight)
                    ctx.lineTo(left + plotWidth, top + plotHeight)
                    ctx.stroke()

                    ctx.fillStyle = "#e9eef1"
                    ctx.font = (app.compactLayout ? "10px" : "11px") + " sans-serif"
                    ctx.textAlign = "right"
                    ctx.textBaseline = "middle"
                    ctx.fillText("100", left - 3, top)
                    ctx.fillText("50", left - 3, top + plotHeight / 2)
                    ctx.fillText("0", left - 3, top + plotHeight)

                    if (points.length <= 0)
                        return

                    ctx.strokeStyle = "#48d3ff"
                    ctx.fillStyle = "#48d3ff"
                    ctx.lineWidth = 2
                    ctx.beginPath()
                    var started = false
                    for (var i = 0; i < points.length; ++i) {
                        var px = left + app.clamp(points[i].move / xMax, 0, 1) * plotWidth
                        var py = top + (100 - points[i].winrate) / 100 * plotHeight
                        if (!started) {
                            ctx.moveTo(px, py)
                            started = true
                        } else {
                            ctx.lineTo(px, py)
                        }
                    }
                    ctx.stroke()

                    for (var p = 0; p < points.length; ++p) {
                        var dx = left + app.clamp(points[p].move / xMax, 0, 1) * plotWidth
                        var dy = top + (100 - points[p].winrate) / 100 * plotHeight
                        ctx.beginPath()
                        ctx.arc(dx, dy, 2.3, 0, Math.PI * 2)
                        ctx.fill()
                    }
                }

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                Component.onCompleted: requestPaint()

                Connections {
                    target: app
                    function onAnalysisRevisionChanged() { winrateCanvas.requestPaint() }
                    function onCurrentNodeIdChanged() { winrateCanvas.requestPaint() }
                    function onLanguageChanged() { winrateCanvas.requestPaint() }
                    function onPlayModeChanged() { winrateCanvas.requestPaint() }
                }
            }
        }

        }
    }

    Rectangle {
        id: candidateTable
        visible: app.analysisModeActive()
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: summaryPanel.bottom
        anchors.topMargin: infoPanel.panelGap
        anchors.bottom: parent.bottom
        radius: 4
        color: "#dfe3e5"
        border.color: "#8d9498"
        clip: true

        Row {
            id: candidateHeader
            width: parent.width
            height: infoPanel.tableHeaderHeight

            TableHeaderCell {
                width: infoPanel.indexColumnWidth
                text: app.trText("candidateIndex")
            }

            TableHeaderCell {
                width: infoPanel.positionColumnWidth
                text: app.trText("candidatePosition")
            }

            TableHeaderCell {
                width: infoPanel.winrateColumnWidth
                text: app.trText("candidateWinrate")
            }

            TableHeaderCell {
                width: infoPanel.scoreColumnWidth
                text: app.trText("candidateScoreMean")
            }

            TableHeaderCell {
                width: infoPanel.visitsColumnWidth
                text: app.trText("candidateVisits")
            }
        }

        ListModel {
            id: candidateRows
        }

        function candidateRowObject(item) {
            return {
                "row": item && item.row !== undefined ? Number(item.row) : 0,
                "key": item && item.key !== undefined ? String(item.key) : "",
                "coordinate": item && item.coordinate !== undefined ? String(item.coordinate) : "",
                "winrateText": item && item.winrateText !== undefined ? String(item.winrateText) : "",
                "scoreText": item && item.scoreText !== undefined ? String(item.scoreText) : "",
                "visitsText": item && item.visitsText !== undefined ? String(item.visitsText) : ""
            }
        }

        function syncCandidateRows() {
            var rows = app.engineCandidateTableItems || []
            var userControlled = candidateList.userControlsScroll()
            if (userControlled)
                candidateList.saveUserScrollPosition()

            candidateList.syncingRows = true
            for (var i = 0; i < rows.length; ++i) {
                var rowObject = candidateRowObject(rows[i])
                if (i < candidateRows.count)
                    candidateRows.set(i, rowObject)
                else
                    candidateRows.append(rowObject)
            }
            while (candidateRows.count > rows.length)
                candidateRows.remove(candidateRows.count - 1)

            candidateList.syncingRows = false
            if (userControlled) {
                Qt.callLater(function() { candidateList.saveUserScrollPosition() })
            } else {
                Qt.callLater(function() { candidateList.restorePreservedScroll() })
            }
        }

        Component.onCompleted: syncCandidateRows()

        Connections {
            target: app
            function onEngineCandidateTableItemsChanged() {
                candidateTable.syncCandidateRows()
            }
        }

        ListView {
            id: candidateList
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: candidateHeader.bottom
            anchors.bottom: parent.bottom
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: candidateRows
            reuseItems: true
            cacheBuffer: infoPanel.tableRowHeight * 16
            property real preservedContentY: 0
            property bool restoringScroll: false
            property bool userScrolling: false
            property bool syncingRows: false

            function maxContentY() {
                return Math.max(0, contentHeight - height)
            }

            function userControlsScroll() {
                return userScrolling || moving || flicking || draggingVertically || candidateVerticalScrollBar.pressed
            }

            function saveUserScrollPosition() {
                preservedContentY = Math.min(contentY, maxContentY())
            }

            function restorePreservedScroll() {
                restoringScroll = true
                contentY = Math.min(preservedContentY, maxContentY())
                Qt.callLater(function() {
                    restoringScroll = false
                    preservedContentY = Math.min(preservedContentY, candidateList.maxContentY())
                })
            }

            function scrollToTop() {
                preservedContentY = 0
                contentY = 0
            }

            onContentYChanged: {
                if (!restoringScroll && !syncingRows && userControlsScroll())
                    saveUserScrollPosition()
            }

            onMovementStarted: userScrolling = true
            onMovementEnded: {
                saveUserScrollPosition()
                userScrolling = false
            }
            onCountChanged: Qt.callLater(function() { candidateList.restorePreservedScroll() })
            onContentHeightChanged: Qt.callLater(function() { candidateList.restorePreservedScroll() })
            onHeightChanged: Qt.callLater(function() { candidateList.restorePreservedScroll() })

            ScrollBar.vertical: AppScrollBar {
                id: candidateVerticalScrollBar

                policy: ScrollBar.AsNeeded
                startInset: 22
            }

            delegate: Rectangle {
                width: candidateList.width
                height: infoPanel.tableRowHeight
                readonly property bool selected: model.key !== "" && app.hoverKey === model.key
                color: selected ? "#b9bdc0"
                                : index % 2 === 0 ? "#f0f2f3" : "#e3e6e8"
                border.color: "#9ba2a6"
                border.width: 1

                Row {
                    anchors.fill: parent

                    TableCell {
                        width: infoPanel.indexColumnWidth
                        text: model.row
                        color: parent.parent.selected ? "#003cff" : "#15191c"
                        font.bold: parent.parent.selected
                    }

                    TableCell {
                        width: infoPanel.positionColumnWidth
                        text: model.coordinate
                        font.family: app.coordinateFontFamily
                        color: parent.parent.selected ? "#003cff" : "#15191c"
                        font.bold: parent.parent.selected
                    }

                    TableCell {
                        width: infoPanel.winrateColumnWidth
                        text: model.winrateText
                        color: parent.parent.selected ? "#003cff" : "#15191c"
                        font.bold: parent.parent.selected
                    }

                    TableCell {
                        width: infoPanel.scoreColumnWidth
                        text: model.scoreText
                        color: parent.parent.selected ? "#003cff" : "#15191c"
                        font.bold: parent.parent.selected
                    }

                    TableCell {
                        width: infoPanel.visitsColumnWidth
                        text: model.visitsText
                        color: parent.parent.selected ? "#003cff" : "#15191c"
                        font.bold: parent.parent.selected
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        app.selectEngineCandidateRow(model.row)
                        mouse.accepted = true
                    }
                }
            }
        }

        Rectangle {
            id: candidateScrollTopButton
            visible: candidateList.contentHeight > candidateList.height
            anchors.top: candidateHeader.bottom
            anchors.right: parent.right
            anchors.topMargin: 2
            anchors.rightMargin: 0
            width: 12
            height: 18
            radius: 6
            color: topMouse.pressed ? "#d3e1e8" : topMouse.containsMouse ? "#e8f1f5" : "#f8fbfd"
            border.color: "#9aadb6"
            border.width: 1

            Canvas {
                id: topArrow
                anchors.centerIn: parent
                width: 8
                height: 8

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.strokeStyle = "#41515a"
                    ctx.lineWidth = 1.5
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    ctx.beginPath()
                    ctx.moveTo(1.5, 5.2)
                    ctx.lineTo(4, 2.4)
                    ctx.lineTo(6.5, 5.2)
                    ctx.stroke()
                }
            }

            MouseArea {
                id: topMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    candidateList.scrollToTop()
                    app.focusBoardInput()
                }
                onContainsMouseChanged: topArrow.requestPaint()
                onPressedChanged: topArrow.requestPaint()
            }
        }
    }
}
