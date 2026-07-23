import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import "TreeLayout.js" as TreeLayout

Rectangle {
    id: branchPanel
    required property var app
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.rightMargin: app.panelMargin
    anchors.topMargin: app.topContentMargin
    anchors.bottomMargin: app.bottomContentMargin
    width: app.branchPanelWidth
    radius: 8
    color: "#f3f7f9"
    border.color: "#b9c8d0"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: app.panelInnerMargin
        spacing: app.compactLayout ? 6 : 8

        Label {
            text: app.trText("gameTree")
            color: "#17212a"
            font.pixelSize: app.compactLayout ? 16 : 18
            font.bold: true
            Layout.fillWidth: true
        }

        Label {
            text: app.trText("currentMove") + ": " + app.currentNodeText()
            color: "#52636d"
            font.family: app.coordinateFontFamily
            font.pixelSize: 12
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Rectangle {
            id: treeViewport
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 6
            color: "#e9f0f4"
            border.color: "#c5d1d8"
            clip: true

            Flickable {
                id: treeFlick
                anchors.fill: parent
                anchors.margins: app.compactLayout ? 6 : 8
                z: 1
                clip: true
                contentWidth: Math.max(width, app.treeCanvasWidth)
                contentHeight: Math.max(height, app.treeCanvasHeight)
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.horizontal: AppScrollBar {
                    policy: ScrollBar.AsNeeded
                    endInset: 14
                }

                ScrollBar.vertical: AppScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                Item {
                    id: treeContentExtent
                    width: treeFlick.contentWidth
                    height: treeFlick.contentHeight

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        hoverEnabled: true

                        onClicked: function(mouse) {
                            var nodeId = app.treeNodeAt(mouse.x, mouse.y)
                            if (nodeId >= 0) {
                                app.focusBoardInput()
                                app.gotoNode(nodeId)
                            }
                            mouse.accepted = true
                        }
                    }
                }
            }

            Canvas {
                id: branchCanvas
                anchors.fill: treeFlick
                z: 0

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    var viewportLeft = treeFlick.contentX
                    var viewportTop = treeFlick.contentY
                    var viewportPadding = 18
                    var leftNodeByMove = ({})
                    for (var r = 0; r < app.treeNodes.length; ++r) {
                        var rowNode = app.treeNodes[r]
                        var rowRadius = rowNode.radius + viewportPadding
                        if (rowNode.y + rowRadius < viewportTop
                                || rowNode.y - rowRadius > viewportTop + height)
                            continue
                        var currentLeft = leftNodeByMove[rowNode.moveNumber]
                        if (!currentLeft || rowNode.x < currentLeft.x)
                            leftNodeByMove[rowNode.moveNumber] = rowNode
                    }

                    ctx.save()
                    ctx.translate(-viewportLeft, -viewportTop)
                    ctx.font = "9px sans-serif"
                    ctx.textAlign = "right"
                    ctx.textBaseline = "middle"
                    ctx.fillStyle = "#6f7f88"
                    for (var moveNumber in leftNodeByMove) {
                        var leftNode = leftNodeByMove[moveNumber]
                        ctx.fillText(String(leftNode.moveNumber),
                                     Math.max(10, leftNode.x - leftNode.radius - 7),
                                     leftNode.y)
                    }

                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    for (var e = 0; e < app.treeEdges.length; ++e) {
                        var edge = app.treeEdges[e]
                        if (!TreeLayout.edgeVisibleInViewport(edge,
                                                              viewportLeft,
                                                              viewportTop,
                                                              width,
                                                              height,
                                                              viewportPadding))
                            continue
                        ctx.beginPath()
                        ctx.moveTo(edge.x1, edge.y1)
                        ctx.lineTo(edge.x2, edge.y2)
                        ctx.lineWidth = edge.current ? 3 : 2
                        ctx.strokeStyle = edge.current ? "#2b83c6" : "#afbdc5"
                        ctx.stroke()
                    }

                    for (var i = 0; i < app.treeNodes.length; ++i) {
                        var node = app.treeNodes[i]
                        if (!TreeLayout.nodeVisibleInViewport(node,
                                                              viewportLeft,
                                                              viewportTop,
                                                              width,
                                                              height,
                                                              viewportPadding))
                            continue

                        if (node.moveNumber === 0) {
                            var side = node.radius * 1.72
                            ctx.beginPath()
                            ctx.rect(node.x - side / 2, node.y - side / 2, side, side)
                            ctx.fillStyle = "#2b83c6"
                            ctx.fill()
                            ctx.lineWidth = node.current ? 3 : 1.5
                            ctx.strokeStyle = node.current ? "#0f4f83" : "#1d6fa8"
                            ctx.stroke()
                            ctx.fillStyle = "#ffffff"
                        } else {
                            ctx.beginPath()
                            ctx.arc(node.x, node.y, node.radius, 0, Math.PI * 2)
                            if (node.player === 1) {
                                ctx.fillStyle = "#101418"
                            } else if (node.player === 2) {
                                ctx.fillStyle = "#fff8e8"
                            } else {
                                ctx.fillStyle = "#d9e3e9"
                            }
                            ctx.fill()
                            ctx.lineWidth = node.current ? 3 : 1.5
                            ctx.strokeStyle = node.current ? "#2b83c6" : (node.player === 2 ? "#65747d" : "#41515a")
                            ctx.stroke()
                            ctx.fillStyle = node.player === 1 ? "#f7fbfd" : "#1a252d"
                        }

                        ctx.font = node.current ? "bold 10px sans-serif" : "10px sans-serif"
                        ctx.textAlign = "center"
                        ctx.textBaseline = "middle"
                        ctx.fillText(node.label, node.x, node.y)
                    }
                    ctx.restore()
                }

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                Connections {
                    target: app
                    function onTreeRevisionChanged() {
                        branchCanvas.requestPaint()
                    }
                }

                Connections {
                    target: treeFlick
                    function onContentXChanged() { branchCanvas.requestPaint() }
                    function onContentYChanged() { branchCanvas.requestPaint() }
                }
            }
        }
    }
}
