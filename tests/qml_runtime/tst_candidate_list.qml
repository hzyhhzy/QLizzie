import QtQuick
import QtQuick.Controls
import QtTest
import "../../app/qml" as Widgets

TestCase {
    id: testRoot

    name: "CandidateListWindow"
    when: windowShown
    width: 1100
    height: 760

    Rectangle {
        id: fakeApp
        width: testRoot.width
        height: testRoot.height
        property bool compactLayout: false
        property bool applicationShutdownPrepared: false
        property string language: "zh"
        property string coordinateFontFamily: "JetBrains Mono"
        property string hoverKey: ""
        property int engineCandidateRevision: 1
        property int selectedRow: 0
        property bool selectedFocusMain: true
        property var engineCandidates: baseCandidates()

        function baseCandidates() {
            return [
                {
                    "move": "D4",
                    "order": 0,
                    "visits": 100,
                    "lcb": 0.51,
                    "winrate": 0.55,
                    "prior": 0.125,
                    "scoreMean": 1.75,
                    "scoreStdev": 0.42
                },
                {
                    "move": "Q16",
                    "order": 1,
                    "visits": 50,
                    "lcb": 0.49,
                    "winrate": 0.52,
                    "prior": 0.25,
                    "scoreMean": -0.25,
                    "scoreStdev": 0.81
                }
            ]
        }

        function manyCandidates(count, visitOffset) {
            var candidates = []
            for (var index = 0; index < count; ++index) {
                candidates.push({
                    "move": "move-" + String(index + 1),
                    "order": index,
                    "visits": visitOffset + count - index,
                    "winrate": 0.5,
                    "prior": 1 / Math.max(1, count)
                })
            }
            return candidates
        }

        function trText(key) {
            return key
        }

        function parseEngineCoordinate(move) {
            if (move === "D4")
                return { "x": 3, "y": 3 }
            if (move === "Q16")
                return { "x": 15, "y": 15 }
            return null
        }

        function coordinateText(x, y) {
            return x === 3 ? "D4" : y === 15 ? "Q16" : ""
        }

        function keyFor(x, y) {
            return String(x) + "," + String(y)
        }

        function selectEngineCandidateRow(row, focusMainWindow) {
            selectedRow = row
            selectedFocusMain = focusMainWindow
        }

        function focusBoardInput() {
        }
    }

    Widgets.CandidateListWindow {
        id: dialog
        app: fakeApp
    }

    function cleanup() {
        dialog.closeWindow()
        dialog.sortColumn = 0
        dialog.sortAscending = true
        dialog.selectedCandidateKey = ""
        fakeApp.engineCandidates = fakeApp.baseCandidates()
        fakeApp.engineCandidateRevision += 1
        wait(0)
    }

    function test_openBuildsAllRowsAndSortsEveryMetricColumn() {
        dialog.openWindow()
        tryCompare(dialog, "visible", true)

        var list = findChild(dialog.contentItem, "candidateListWindowRows")
        verify(list !== null)
        tryCompare(list, "count", 2)
        tryCompare(list, "replacingModel", false)
        compare(dialog.tableData.rows[0].coordinateText, "D4")
        compare(dialog.tableData.rows[0].lcbText, "51.0")
        compare(dialog.tableData.rows[0].policyText, "12.50")
        compare(dialog.tableData.totalVisits, 150)

        dialog.setSortColumn(6)
        compare(dialog.sortAscending, false)
        tryCompare(list, "replacingModel", false)
        compare(dialog.tableData.rows[0].coordinateText, "Q16")

        dialog.setSortColumn(6)
        compare(dialog.sortAscending, true)
        tryCompare(list, "replacingModel", false)
        compare(dialog.tableData.rows[0].coordinateText, "D4")
    }

    function test_resizeAndCloseKeepTheNativeWindowUsable() {
        dialog.openWindow()
        tryCompare(dialog, "visible", true)
        dialog.width = 760
        dialog.height = 380
        wait(20)

        var layout = findChild(dialog.contentItem, "candidateListWindowLayout")
        verify(layout !== null)
        compare(Math.round(layout.width), 736)
        compare(Math.round(layout.height), 356)

        dialog.closeWindow()
        tryCompare(dialog, "visible", false)
    }

    function test_liveRefreshContinuesWithoutSnappingEitherScrollBarBack() {
        fakeApp.engineCandidates = fakeApp.manyCandidates(80, 100)
        fakeApp.engineCandidateRevision += 1
        dialog.openWindow()
        tryCompare(dialog, "visible", true)
        dialog.width = 760
        dialog.height = 380
        wait(20)

        var list = findChild(dialog.contentItem, "candidateListWindowRows")
        var horizontalViewport = findChild(
                    dialog.contentItem, "candidateListHorizontalViewport")
        verify(list !== null)
        verify(horizontalViewport !== null)
        tryCompare(list, "count", 80)
        tryCompare(list, "replacingModel", false)
        tryCompare(list, "restoringScroll", false)
        verify(horizontalViewport.contentWidth > horizontalViewport.width)
        verify(list.contentHeight > list.height)

        list.userScrolling = true
        horizontalViewport.contentX = Math.min(
                    90, horizontalViewport.contentWidth - horizontalViewport.width)
        list.contentY = 420
        compare(list.replacingModel, false)
        compare(list.restoringScroll, false)
        list.saveScrollPosition()
        var expectedX = horizontalViewport.contentX
        var expectedY = list.contentY
        var expectedMaxX = list.maxContentX()
        compare(Math.round(list.preservedContentX), Math.round(expectedX))

        fakeApp.engineCandidates = fakeApp.manyCandidates(80, 200)
        fakeApp.engineCandidateRevision += 1
        compare(dialog.tableRefreshPending, false)
        compare(dialog.tableData.rows[0].visitsValue, 280)
        compare(horizontalViewport.contentX, expectedX)
        compare(list.contentY, expectedY)
        compare(Math.round(list.preservedContentX), Math.round(expectedX))

        fakeApp.engineCandidates = fakeApp.manyCandidates(80, 300)
        fakeApp.engineCandidateRevision += 1
        compare(dialog.tableRefreshPending, false)
        compare(dialog.tableData.rows[0].visitsValue, 380)
        compare(horizontalViewport.contentX, expectedX)
        compare(list.contentY, expectedY)

        list.finishUserScroll()
        compare(Math.round(list.preservedContentX), Math.round(expectedX))
        tryCompare(list, "replacingModel", false)
        wait(30)
        compare(Math.round(list.maxContentX()), Math.round(expectedMaxX))
        compare(Math.round(list.preservedContentX), Math.round(expectedX))
        compare(Math.round(horizontalViewport.contentX), Math.round(expectedX))
        tryVerify(function() {
            return Math.abs(list.contentY - expectedY) < 1
        })
        compare(dialog.tableData.rows[0].visitsValue, 380)
    }
}
