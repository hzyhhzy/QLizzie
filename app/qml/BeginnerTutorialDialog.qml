import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import "CandidateAnalysis.js" as CandidateAnalysis

Window {
    id: tutorialDialog

    required property var app
    property int pageIndex: 0
    property bool positionedOnce: false
    readonly property var pages: [
        { "title": app.trText("tutorialPageViewTitle"), "body": app.trText("tutorialPageViewBody") },
        { "title": app.trText("tutorialPageRulesTitle"), "body": app.trText("tutorialPageRulesBody") },
        { "title": app.trText("tutorialPageMoveTitle"), "body": app.trText("tutorialPageMoveBody") },
        { "title": app.trText("tutorialPageEngineTitle"), "body": app.trText("tutorialPageEngineBody") },
        { "title": app.trText("tutorialPageTreeTitle"), "body": app.trText("tutorialPageTreeBody") },
        { "title": app.trText("tutorialPageMoreTitle"), "body": app.trText("tutorialPageMoreBody") }
    ]
    readonly property int pageCount: pages.length

    title: app.trText("beginnerTutorialTitle")
    flags: Qt.Window
    color: "#f8fbfd"
    minimumWidth: 620
    minimumHeight: 430
    width: 760
    height: 640
    visible: false

    function openFirstPage() {
        pageIndex = 0
        openTutorialWindow()
    }

    function openTutorial() {
        openFirstPage()
    }

    function openTutorialWindow() {
        if (!positionedOnce) {
            width = Math.min(760, Math.max(minimumWidth, app.width - 80))
            height = Math.min(640, Math.max(minimumHeight, app.height - 90))
            x = Math.round(app.x + (app.width - width) / 2)
            y = Math.round(app.y + (app.height - height) / 2)
            positionedOnce = true
        }
        visible = true
        raise()
        requestActivate()
    }

    function finishTutorial() {
        visible = false
        app.focusBoardInput()
    }

    function currentPageTitle() {
        return pages[pageIndex] ? pages[pageIndex].title : ""
    }

    function currentPageBody() {
        return pages[pageIndex] ? pages[pageIndex].body : ""
    }

    function escapeHtml(text) {
        return String(text).replace(/&/g, "&amp;")
                           .replace(/</g, "&lt;")
                           .replace(/>/g, "&gt;")
                           .replace(/"/g, "&quot;")
    }

    function keyBadge(text) {
        return "<span style=\"background-color:#e7f0f5;color:#123240;"
               + "font-family:Consolas,monospace;font-weight:700;\">&nbsp;"
               + text + "&nbsp;</span>"
    }

    function tutorialRichText(text) {
        var escaped = escapeHtml(text)
        escaped = escaped.replace(/\{key:([^}]+)\}/g, function(match, keyText) {
            return keyBadge(keyText)
        })
        escaped = escaped.replace(/\{menu:([^}]+)\}/g, function(match, menuText) {
            return keyBadge(menuText)
        })
        return "<p style=\"margin-top:0;margin-bottom:0;\">" + escaped.replace(/\n\n/g, "</p><p style=\"margin-top:0;margin-bottom:0;\">")
                                                                     .replace(/\n/g, "<br>") + "</p>"
    }

    onClosing: function(closeEvent) {
        closeEvent.accepted = false
        skipTutorialDialog.open()
    }

    QtObject {
        id: tutorialPreviewStyle

        readonly property bool candidateWinrateLabelVisible: true
        readonly property bool candidateVisitsLabelVisible: true
        readonly property bool candidateScoreLabelVisible: true
        readonly property int candidateWinrateFontSize: 57
        readonly property int candidateVisitsFontSize: 42
        readonly property int candidateScoreFontSize: 36
        readonly property bool candidateWinrateBold: true
        readonly property bool candidateVisitsBold: false
        readonly property bool candidateScoreBold: true
        readonly property int candidateWinrateOffsetY: -10
        readonly property int candidateVisitsOffsetY: -5
        readonly property int candidateScoreOffsetY: -5
        readonly property int candidateWinrateDecimals: 1
        readonly property int candidateScoreDecimals: 1
        readonly property bool candidateWinrateShowPercent: false
        readonly property bool candidateScoreShowPercent: false
        readonly property int candidateScoreTitleDrawRate: 1
        readonly property int candidateScoreTitleMode: 0
        readonly property bool candidateRingVisible: true
        readonly property int candidateRingLineWidth: 12
        readonly property bool candidateRankLabelVisible: true
        readonly property string candidateFirstLabelTextColor: "#ff0000"
        readonly property string candidateLabelTextColor: "#000000"
        readonly property string firstCandidateRingColor: "#003b8e"
        readonly property int candidateYzyMinAlpha: 32
        readonly property int candidateYzyMaxAlpha: 240
        readonly property real candidateYzyAlphaFactor: 5.0
        readonly property real candidateYzyColorRatio: 2.0
        readonly property real stoneScale: 0.95
        readonly property string coordinateFontFamily: "Arial"

        function clamp(value, minValue, maxValue) {
            return Math.max(minValue, Math.min(maxValue, value))
        }

        function trText(key) {
            return tutorialDialog.app.trText(key)
        }

        function drawCandidateMarker(ctx, centerX, centerY, markerRadius, lines, options) {
            CandidateAnalysis.drawMarker(tutorialPreviewStyle, ctx, centerX, centerY, markerRadius, lines, options)
        }

        function candidateMarkerRadius(widthValue, heightValue) {
            return CandidateAnalysis.markerRadius(tutorialPreviewStyle, widthValue, heightValue)
        }

        function candidateMarkerColor(displayIndex, visitRatio) {
            return CandidateAnalysis.markerColor(tutorialPreviewStyle, displayIndex, visitRatio)
        }

        function candidateMarkerOpacity(displayIndex, visitRatio) {
            return CandidateAnalysis.markerOpacity(tutorialPreviewStyle, displayIndex, visitRatio)
        }

        function candidatePreviewLabelLines(digitText) {
            return CandidateAnalysis.previewLabelLines(tutorialPreviewStyle, digitText)
        }
    }

    Rectangle {
        id: tutorialRoot
        anchors.fill: parent
        color: "#f8fbfd"
        border.color: "#8ea5b1"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            Label {
                Layout.fillWidth: true
                text: (tutorialDialog.pageIndex + 1) + "/" + tutorialDialog.pageCount
                color: "#267fbb"
                font.pixelSize: 16
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Label {
                text: tutorialDialog.currentPageTitle()
                color: "#14242e"
                font.pixelSize: 21
                font.bold: true
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            ScrollView {
                id: tutorialScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.vertical: AppScrollBar {
                    parent: tutorialScroll
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                }
                ScrollBar.horizontal: Basic.ScrollBar {
                    policy: ScrollBar.AlwaysOff
                }

                Column {
                    width: Math.max(0, tutorialScroll.availableWidth - 14)
                    spacing: 14

                    TextEdit {
                        width: parent.width
                        text: tutorialDialog.tutorialRichText(tutorialDialog.currentPageBody())
                        textFormat: TextEdit.RichText
                        readOnly: true
                        selectByMouse: true
                        cursorVisible: false
                        color: "#1d2f39"
                        selectionColor: "#2a91c9"
                        selectedTextColor: "#ffffff"
                        font.pixelSize: 15
                        wrapMode: TextEdit.WordWrap
                    }

                    Item {
                        visible: tutorialDialog.pageIndex === 3
                        width: parent.width
                        height: visible ? 300 : 0
                        readonly property real markerSize: Math.max(130, Math.min(170, width * 0.26))
                        readonly property real markerX: 30
                        readonly property real markerY: 74
                        readonly property real markerCenterX: markerX + markerSize * 0.45
                        readonly property real markerCenterY: markerY + markerSize * 0.61
                        readonly property real textX: markerX + markerSize + 72
                        readonly property real rankY: 28
                        readonly property real winrateY: 92
                        readonly property real visitsY: 166
                        readonly property real scoreY: 232
                        readonly property real winrateTargetY: markerCenterY - markerSize * 0.21
                        readonly property real visitsTargetY: markerCenterY + markerSize * 0.01
                        readonly property real scoreTargetY: markerCenterY + markerSize * 0.22
                        readonly property real rankTargetX: markerCenterX + markerSize * 0.34
                        readonly property real rankTargetY: markerCenterY - markerSize * 0.31

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: "#e7f0f4"
                            border.color: "#c3d2db"
                        }

                        CandidateMarkerView {
                            id: tutorialCandidatePreview
                            x: parent.markerX
                            y: parent.markerY
                            width: parent.markerSize
                            height: parent.markerSize
                            app: tutorialPreviewStyle
                            labelLines: tutorialPreviewStyle.candidatePreviewLabelLines("6")
                            drawBackground: true
                            drawRing: true
                            rankText: "1"
                            backgroundColor: tutorialPreviewStyle.candidateMarkerColor(1, 1.0)
                            backgroundOpacity: tutorialPreviewStyle.candidateMarkerOpacity(1, 1.0)
                        }

                        Canvas {
                            id: candidateArrowCanvas
                            anchors.fill: parent

                            function drawArrow(ctx, fromX, fromY, toX, toY) {
                                var angle = Math.atan2(toY - fromY, toX - fromX)
                                var head = 9
                                ctx.beginPath()
                                ctx.moveTo(fromX, fromY)
                                ctx.lineTo(toX, toY)
                                ctx.stroke()
                                ctx.beginPath()
                                ctx.moveTo(toX, toY)
                                ctx.lineTo(toX - head * Math.cos(angle - Math.PI / 6),
                                           toY - head * Math.sin(angle - Math.PI / 6))
                                ctx.lineTo(toX - head * Math.cos(angle + Math.PI / 6),
                                           toY - head * Math.sin(angle + Math.PI / 6))
                                ctx.closePath()
                                ctx.fill()
                            }

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                ctx.strokeStyle = "#2c657f"
                                ctx.fillStyle = "#2c657f"
                                ctx.lineWidth = 2
                                ctx.lineCap = "round"
                                var fromX = parent.textX - 12
                                drawArrow(ctx, fromX, parent.rankY + 12, parent.rankTargetX, parent.rankTargetY)
                                drawArrow(ctx, fromX, parent.winrateY + 12, parent.markerCenterX, parent.winrateTargetY)
                                drawArrow(ctx, fromX, parent.visitsY + 12, parent.markerCenterX, parent.visitsTargetY)
                                drawArrow(ctx, fromX, parent.scoreY + 12, parent.markerCenterX, parent.scoreTargetY)
                            }
                        }

                        Item {
                            x: parent.textX
                            y: 0
                            width: Math.max(220, parent.width - x - 20)
                            height: parent.height

                            TutorialArrowLabel {
                                y: parent.parent.rankY
                                width: parent.width
                                title: app.trText("candidateRankTitle")
                                detail: app.trText("tutorialCandidateRankTip")
                            }

                            TutorialArrowLabel {
                                y: parent.parent.winrateY
                                width: parent.width
                                title: app.trText("candidateWinrate")
                                detail: app.trText("tutorialCandidateWinrateTip")
                            }

                            TutorialArrowLabel {
                                y: parent.parent.visitsY
                                width: parent.width
                                title: app.trText("candidateVisits")
                                detail: app.trText("tutorialCandidateVisitsTip")
                            }

                            TutorialArrowLabel {
                                y: parent.parent.scoreY
                                width: parent.width
                                title: app.trText("candidateScoreMean")
                                detail: app.trText("tutorialCandidateScoreTip")
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                SavePromptButton {
                    text: app.trText("skipTutorial")
                    onClicked: skipTutorialDialog.open()
                }

                Item { Layout.fillWidth: true }

                SavePromptButton {
                    text: app.trText("previous")
                    enabled: tutorialDialog.pageIndex > 0
                    onClicked: tutorialDialog.pageIndex -= 1
                }

                SavePromptButton {
                    text: tutorialDialog.pageIndex + 1 >= tutorialDialog.pageCount
                          ? app.trText("finish")
                          : app.trText("next")
                    primary: true
                    onClicked: {
                        if (tutorialDialog.pageIndex + 1 >= tutorialDialog.pageCount) {
                            tutorialDialog.finishTutorial()
                        } else {
                            tutorialDialog.pageIndex += 1
                        }
                    }
                }
            }
        }
    }

    AppDialog {
        id: skipTutorialDialog

        parent: tutorialRoot
        app: tutorialRoot
        owningWindow: tutorialDialog
        modal: true
        title: tutorialDialog.app.trText("skipTutorialTitle")
        closePolicy: Popup.NoAutoClose
        preferredWidth: Math.min(560, tutorialRoot.width - 80)
        dialogMinimumWidth: Math.min(440, preferredWidth)
        dialogMinimumHeight: Math.min(200, preferredHeight)

        contentItem: Rectangle {
            implicitWidth: 524
            implicitHeight: 64
            color: "transparent"

            Label {
                id: skipTutorialMessage
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: tutorialDialog.app.trText("skipTutorialMessage")
                color: "#24313a"
                font.pixelSize: 15
                lineHeight: 1.12
                wrapMode: Text.WordWrap
                maximumLineCount: 3
            }
        }

        footer: AppDialogFooter {
            Item { Layout.fillWidth: true }

            SavePromptButton {
                text: tutorialDialog.app.trText("continueTutorial")
                onClicked: skipTutorialDialog.close()
            }

            SavePromptButton {
                text: tutorialDialog.app.trText("skipTutorial")
                primary: true
                onClicked: {
                    skipTutorialDialog.close()
                    tutorialDialog.finishTutorial()
                }
            }
        }
    }

    component TutorialArrowLabel: Column {
        property string title: ""
        property string detail: ""

        spacing: 2

        Label {
            width: parent.width
            text: title
            color: "#123240"
            font.pixelSize: 15
            font.bold: true
            elide: Text.ElideRight
        }

        Label {
            width: parent.width
            text: detail
            textFormat: Text.RichText
            color: "#51636d"
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }
    }
}
