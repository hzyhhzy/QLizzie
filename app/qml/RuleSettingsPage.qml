import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import "BoardRenderer.js" as BoardRenderer

ColumnLayout {
    id: ruleSettingsPage

    required property var app

    spacing: 14
    readonly property bool inlineBoardPresentationControls: app.boardPresentationOptions().length > 1
    readonly property bool inlineKomiControls: !inlineBoardPresentationControls && app.komiControlsVisible()
    property var collapsedRuleGroups: ({})

    function setRuleGroupCollapsed(groupId, collapsed) {
        var next = {}
        for (var key in collapsedRuleGroups)
            next[key] = collapsedRuleGroups[key]
        if (collapsed)
            next[groupId] = true
        else
            delete next[groupId]
        collapsedRuleGroups = next
    }

    function previewStone(x, y, player, moveNumber) {
        return {
            "x": x,
            "y": y,
            "player": player,
            "moveNumber": moveNumber === undefined ? 0 : moveNumber
        }
    }

    function centerStoneConfig(sizeX, sizeY, x, y) {
        var cx = x === undefined ? Math.floor(sizeX / 2) : x
        var cy = y === undefined ? Math.floor(sizeY / 2) : y
        return {
            "boardSizeX": sizeX,
            "boardSizeY": sizeY,
            "stones": [previewStone(cx, cy, 1, 1)],
            "lastMoveNumber": 0,
            "path": []
        }
    }

    function reversiPreviewConfig() {
        return {
            "boardSizeX": 4,
            "boardSizeY": 4,
            "stones": [
                previewStone(1, 1, 2, 0),
                previewStone(2, 2, 2, 0),
                previewStone(2, 1, 1, 0),
                previewStone(1, 2, 1, 0)
            ],
            "lastMoveNumber": 0,
            "path": []
        }
    }

    function ataxxPreviewConfig() {
        return {
            "boardSizeX": 4,
            "boardSizeY": 4,
            "stones": [
                previewStone(0, 0, 1, 0),
                previewStone(3, 3, 1, 0),
                previewStone(3, 0, 2, 0),
                previewStone(0, 3, 2, 0)
            ],
            "lastMoveNumber": 0,
            "path": []
        }
    }

    function breakthroughPreviewConfig() {
        var stones = []
        for (var x = 0; x < 6; ++x) {
            stones.push(previewStone(x, 0, 2, 0))
            stones.push(previewStone(x, 1, 2, 0))
            stones.push(previewStone(x, 4, 1, 0))
            stones.push(previewStone(x, 5, 1, 0))
        }
        return {
            "boardSizeX": 6,
            "boardSizeY": 6,
            "stones": stones,
            "lastMoveNumber": 0,
            "path": []
        }
    }

    function boardPreviewConfig() {
        if (app.gameRuleMode === app.gameRuleGo) {
            return {
                "boardSizeX": 4,
                "boardSizeY": 3,
                "stones": [
                    previewStone(0, 1, 1, 1),
                    previewStone(3, 1, 2, 2),
                    previewStone(1, 0, 1, 3),
                    previewStone(2, 0, 2, 4),
                    previewStone(1, 2, 1, 5),
                    previewStone(2, 2, 2, 6),
                    previewStone(2, 1, 1, 7)
                ],
                "lastMoveNumber": 7,
                "path": []
            }
        }
        if (app.gameRuleMode === app.gameRuleTorusGo) {
            return {
                "boardSizeX": 5,
                "boardSizeY": 5,
                "stones": [
                    previewStone(0, 0, 1, 1),
                    previewStone(4, 0, 2, 2),
                    previewStone(1, 4, 1, 3),
                    previewStone(4, 3, 2, 4),
                    previewStone(2, 2, 1, 5)
                ],
                "lastMoveNumber": 5,
                "path": []
            }
        }
        if (app.gameRuleMode === app.gameRuleGomoku) {
            return {
                "boardSizeX": 5,
                "boardSizeY": 5,
                "stones": [
                    previewStone(2, 2, 1, 1),
                    previewStone(2, 1, 2, 2),
                    previewStone(3, 1, 1, 3),
                    previewStone(3, 2, 2, 4),
                    previewStone(4, 0, 1, 5),
                    previewStone(2, 3, 2, 6),
                    previewStone(1, 3, 1, 7),
                    previewStone(1, 2, 2, 8),
                    previewStone(0, 4, 1, 9)
                ],
                "lastMoveNumber": 9,
                "path": []
            }
        }
        if (app.gameRuleMode === app.gameRuleHex) {
            return {
                "boardSizeX": 3,
                "boardSizeY": 3,
                "stones": [
                    previewStone(1, 1, 1, 1),
                    previewStone(1, 0, 2, 2),
                    previewStone(2, 0, 1, 3),
                    previewStone(1, 2, 2, 4),
                    previewStone(0, 2, 1, 5)
                ],
                "lastMoveNumber": 5,
                "path": [
                    { "x": 0, "y": 2 },
                    { "x": 1, "y": 1 },
                    { "x": 2, "y": 0 }
                ]
            }
        }
        if (app.gameRuleMode === app.gameRuleHexGoParallelogram
                || app.gameRuleMode === app.gameRuleHexGoHexagon)
            return centerStoneConfig(3, 3, 1, 1)
        if (app.gameRuleMode === app.gameRuleHexGoTriangle)
            return centerStoneConfig(4, 4, 2, 2)
        if (app.gameRuleMode === app.gameRuleReversi)
            return reversiPreviewConfig()
        if (app.gameRuleMode === app.gameRuleAtaxx)
            return ataxxPreviewConfig()
        if (app.gameRuleMode === app.gameRuleBreakthrough)
            return breakthroughPreviewConfig()
        return centerStoneConfig(3, 3)
    }

    function drawPreviewWinPath(ctx, state, geometry, path) {
        if (!path || path.length < 2)
            return
        ctx.save()
        ctx.strokeStyle = "#f01818"
        ctx.lineWidth = Math.max(4, geometry.cellSize * 0.09)
        ctx.lineCap = "round"
        ctx.lineJoin = "round"
        ctx.beginPath()
        for (var i = 0; i < path.length; ++i) {
            var point = geometry.point(path[i].x, path[i].y)
            if (i === 0)
                ctx.moveTo(point.x, point.y)
            else
                ctx.lineTo(point.x, point.y)
        }
        ctx.stroke()
        ctx.restore()
    }

    function drawPreviewStoneOverlay(ctx, state, geometry, stone, lastMoveNumber) {
        if (!stone.moveNumber || stone.moveNumber <= 0)
            return
        var last = stone.moveNumber === lastMoveNumber
        if (!app.stoneOverlayVisible(stone.moveNumber, last))
            return

        var stoneRadius = Math.max(8, geometry.cellSize * state.stoneScale * 0.5)
        var point = geometry.point(stone.x, stone.y)
        if (last) {
            var markerSize = stoneRadius * 0.62
            ctx.save()
            ctx.fillStyle = "#e3342f"
            ctx.beginPath()
            ctx.moveTo(point.x - stoneRadius, point.y - stoneRadius)
            ctx.lineTo(point.x - stoneRadius + markerSize, point.y - stoneRadius)
            ctx.lineTo(point.x - stoneRadius, point.y - stoneRadius + markerSize)
            ctx.closePath()
            ctx.fill()
            ctx.restore()
        }

        if (!app.stoneNumberVisible(stone.moveNumber, last))
            return
        var text = String(stone.moveNumber)
        var size = app.stoneNumberFontSize(ctx, text, stoneRadius)
        ctx.save()
        ctx.fillStyle = app.stoneNumberColor(stone.player, last)
        ctx.font = app.stoneNumberCanvasFont(size, true)
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        ctx.fillText(text,
                     point.x,
                     point.y + app.stoneNumberOffsetY(size),
                     app.stoneNumberMaxWidth(stoneRadius))
        ctx.restore()
    }

    component PresentationCombo: Basic.ComboBox {
        id: control

        required property var app
        property var options: []
        signal picked(int index)

        model: options
        textRole: "label"
        valueRole: "value"
        implicitHeight: 32
        leftPadding: 10
        rightPadding: 30
        onActivated: function(index) { picked(index) }

        contentItem: Text {
            leftPadding: control.leftPadding
            rightPadding: control.rightPadding
            text: control.displayText
            color: "#14242e"
            font.pixelSize: control.app.compactLayout ? 13 : 14
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        indicator: Canvas {
            id: arrowCanvas
            x: control.width - width - 10
            y: Math.round((control.height - height) / 2)
            width: 12
            height: 8

            Connections {
                target: control
                function onHoveredChanged() { arrowCanvas.requestPaint() }
                function onPressedChanged() { arrowCanvas.requestPaint() }
            }

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = control.pressed ? "#1f6f8d" : "#6b7880"
                ctx.beginPath()
                ctx.moveTo(1, 1)
                ctx.lineTo(width - 1, 1)
                ctx.lineTo(width / 2, height - 1)
                ctx.closePath()
                ctx.fill()
            }
        }

        background: Rectangle {
            radius: 5
            color: control.pressed ? "#dcecf3"
                                 : control.hovered ? "#eef7fa" : "#f8fbfd"
            border.color: control.activeFocus ? "#2a91c9" : "#a8bac5"
            border.width: control.activeFocus ? 2 : 1
        }

        delegate: Basic.ItemDelegate {
            id: optionDelegate
            width: control.width
            height: control.app.compactLayout ? 30 : 34
            highlighted: control.highlightedIndex === index
            hoverEnabled: true

            contentItem: Text {
                text: modelData.label
                color: "#14242e"
                font.pixelSize: control.app.compactLayout ? 12 : 13
                verticalAlignment: Text.AlignVCenter
                leftPadding: 10
                elide: Text.ElideRight
            }

            background: Rectangle {
                color: optionDelegate.highlighted ? "#d8e9f1"
                                                  : optionDelegate.hovered ? "#edf5f8" : "#ffffff"
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: ruleContent.implicitHeight + 28
        radius: 7
        color: "#f8fbfd"
        border.color: "#c7d4dc"

        ColumnLayout {
            id: ruleContent
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Label {
                text: app.trText("gameKindRuleSettings")
                color: "#17212a"
                font.pixelSize: 16
                font.bold: true
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: app.trText("mainRule")
                    color: "#24313a"
                    Layout.preferredWidth: 110
                }

                GameRuleComboBox {
                    app: ruleSettingsPage.app
                    Layout.preferredWidth: 360
                    Layout.minimumWidth: 220
                    implicitHeight: 32
                }

                Item { Layout.fillWidth: true }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: app.trText("ruleVariant")
                    color: "#24313a"
                    Layout.preferredWidth: 100
                }

                Basic.Button {
                    id: ruleVariantButton
                    Layout.preferredWidth: 170
                    Layout.minimumWidth: 150
                    implicitHeight: 32
                    text: app.ruleVariantText()
                    onClicked: app.openRuleVariantDialog()

                    contentItem: Text {
                        text: ruleVariantButton.text
                        color: "#17212a"
                        font.pixelSize: ruleSettingsPage.app.compactLayout ? 13 : 14
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    background: Rectangle {
                        radius: 5
                        color: ruleVariantButton.pressed ? "#dcecf3"
                             : ruleVariantButton.hovered ? "#eef7fa" : "#f8fbfd"
                        border.color: ruleVariantButton.activeFocus ? "#2a91c9" : "#a8bac5"
                        border.width: ruleVariantButton.activeFocus ? 2 : 1
                    }
                }

                Label {
                    text: app.trText("boardPresentation")
                    visible: ruleSettingsPage.inlineBoardPresentationControls
                    color: "#24313a"
                    Layout.preferredWidth: 110
                }

                PresentationCombo {
                    app: ruleSettingsPage.app
                    visible: ruleSettingsPage.inlineBoardPresentationControls
                    options: app.boardPresentationOptions()
                    currentIndex: app.boardPresentationCurrentIndex()
                    Layout.preferredWidth: 190
                    Layout.minimumWidth: 160
                    Layout.fillWidth: true
                    onPicked: function(index) { app.setBoardPresentationFromIndex(index) }
                }

                Label {
                    text: app.komiLabelText()
                    visible: ruleSettingsPage.inlineKomiControls
                    color: "#24313a"
                    Layout.preferredWidth: 70
                }

                SpinBox {
                    visible: ruleSettingsPage.inlineKomiControls
                    from: Math.round(app.komiMinimum() * 2)
                    to: Math.round(app.komiMaximum() * 2)
                    value: Math.round(app.effectiveKomi() * 2)
                    editable: true
                    Layout.preferredWidth: 116
                    textFromValue: function(value) { return (value / 2).toFixed(1) }
                    valueFromText: function(text) { return Math.round(Number(text) * 2) }
                    onValueModified: app.setKomiValue(value / 2)
                }

                Item {
                    visible: !ruleSettingsPage.inlineBoardPresentationControls
                    Layout.fillWidth: true
                }
            }

            Label {
                visible: ruleSettingsPage.inlineBoardPresentationControls
                text: app.boardPresentationOptions()[app.boardPresentationCurrentIndex()]
                      ? app.boardPresentationOptions()[app.boardPresentationCurrentIndex()].tip
                      : ""
                color: "#61727c"
                wrapMode: Text.WordWrap
                Layout.leftMargin: 278
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: app.hexBoardStyleOptions().length > 1

                Label {
                    text: app.trText("hexBoardStyle")
                    color: "#24313a"
                    Layout.preferredWidth: 110
                }

                PresentationCombo {
                    app: ruleSettingsPage.app
                    options: app.hexBoardStyleOptions()
                    currentIndex: app.hexBoardStyleCurrentIndex()
                    Layout.preferredWidth: 260
                    onPicked: function(index) { app.setHexBoardStyleFromIndex(index) }
                }

                Label {
                    text: app.hexBoardStyleOptions()[app.hexBoardStyleCurrentIndex()]
                          ? app.hexBoardStyleOptions()[app.hexBoardStyleCurrentIndex()].tip
                          : ""
                    color: "#61727c"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: app.hexBoardRotationOptions().length > 1

                Label {
                    text: app.trText("hexBoardRotation")
                    color: "#24313a"
                    Layout.preferredWidth: 110
                }

                PresentationCombo {
                    app: ruleSettingsPage.app
                    options: app.hexBoardRotationOptions()
                    currentIndex: app.hexBoardRotationCurrentIndex()
                    Layout.preferredWidth: 260
                    onPicked: function(index) { app.setHexBoardRotationFromIndex(index) }
                }

                Label {
                    text: app.hexBoardRotationOptions()[app.hexBoardRotationCurrentIndex()]
                          ? app.hexBoardRotationOptions()[app.hexBoardRotationCurrentIndex()].tip
                          : ""
                    color: "#61727c"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: app.trText("boardPreview")
                    color: "#24313a"
                    Layout.preferredWidth: 110
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 170
                    radius: 7
                    color: "#ffffff"
                    border.color: "#c7d4dc"

                    Canvas {
                        id: previewCanvas
                        anchors.fill: parent
                        anchors.margins: 8

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            var preview = ruleSettingsPage.boardPreviewConfig()
                            var state = BoardRenderer.stateFromApp(app, {
                                "boardSizeX": preview.boardSizeX,
                                "boardSizeY": preview.boardSizeY
                            })
                            var geometry = BoardRenderer.createGeometry(state, width, height, { "outerMargin": 8 })
                            BoardRenderer.drawBoard(ctx, state, geometry, {
                                "fillBackground": true,
                                "width": width,
                                "height": height,
                                "stones": preview.stones
                            })
                            ruleSettingsPage.drawPreviewWinPath(ctx, state, geometry, preview.path)
                            for (var i = 0; i < preview.stones.length; ++i)
                                ruleSettingsPage.drawPreviewStoneOverlay(ctx, state, geometry,
                                                                         preview.stones[i],
                                                                         preview.lastMoveNumber)
                        }

                        Connections {
                            target: app
                            function onGameRuleModeChanged() { previewCanvas.requestPaint() }
                            function onBoardPresentationModeChanged() { previewCanvas.requestPaint() }
                            function onHexBoardStyleChanged() { previewCanvas.requestPaint() }
                            function onHexBoardRotationChanged() { previewCanvas.requestPaint() }
                            function onBoardWoodColorChanged() { previewCanvas.requestPaint() }
                            function onCoordinateDisplayModeChanged() { previewCanvas.requestPaint() }
                            function onStoneScaleChanged() { previewCanvas.requestPaint() }
                            function onGridOpacityChanged() { previewCanvas.requestPaint() }
                            function onGridLineWidthChanged() { previewCanvas.requestPaint() }
                            function onMoveNumberDisplayModeChanged() { previewCanvas.requestPaint() }
                            function onMoveNumberLabelScaleChanged() { previewCanvas.requestPaint() }
                        }

                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: app.komiControlsVisible() && !ruleSettingsPage.inlineKomiControls

                Label {
                    text: app.komiLabelText()
                    color: "#24313a"
                    Layout.preferredWidth: 110
                }

                SpinBox {
                    from: Math.round(app.komiMinimum() * 2)
                    to: Math.round(app.komiMaximum() * 2)
                    value: Math.round(app.effectiveKomi() * 2)
                    editable: true
                    Layout.preferredWidth: 116
                    textFromValue: function(value) { return (value / 2).toFixed(1) }
                    valueFromText: function(text) { return Math.round(Number(text) * 2) }
                    onValueModified: app.setKomiValue(value / 2)
                }

                Item { Layout.fillWidth: true }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: commonRulesContent.implicitHeight + 28
        radius: 7
        color: "#f8fbfd"
        border.color: "#c7d4dc"

        ColumnLayout {
            id: commonRulesContent
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Label {
                text: app.trText("commonGameRulesTitle")
                color: "#17212a"
                font.pixelSize: 16
                font.bold: true
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                SavePromptButton {
                    text: app.trText("setCommonGameRules")
                    implicitWidth: 154
                    onClicked: app.openCommonGameRulesPopup()
                }

                Label {
                    text: app.trText("commonGameRulesTip")
                    color: "#61727c"
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
