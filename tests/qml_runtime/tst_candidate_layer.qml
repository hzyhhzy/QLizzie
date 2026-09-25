import QtQuick
import QtTest
import QLizzie.Rendering 1.0

TestCase {
    id: test
    name: "CandidateLayer"
    width: 240
    height: 240
    visible: true
    when: windowShown
    readonly property color backgroundColor: "#202830"
    Rectangle { anchors.fill: parent; color: test.backgroundColor }

    Component {
        id: layerFactory
        CandidateLayer { width: 240; height: 240 }
    }

    function marker(color, x, text) {
        return { "x": x, "y": 100, "color": color, "opacity": 1,
            "outlineOpacity": 0, "displayIndex": 1, "qualified": !!text,
            "ring": false, "rank": 0,
            "lines": text ? [{ "text": text, "color": "white", "fontSize": 57,
                                "kind": 0, "bold": true }] : [] }
    }

    function style(radius) {
        return { "radius": radius, "stoneScale": 1, "ringWidth": 1,
            "firstLabelColor": "white", "ringColor": "red",
            "coordinateFont": "sans-serif", "offsets": [0, 0, 0] }
    }

    function test_latest_pending_frame_and_position_replacement_data() {
        return [{ tag: "newest-in-same-position", position: "position-a" },
                { tag: "new-position-invalidates-old-frame", position: "position-b" }]
    }

    function test_latest_pending_frame_and_position_replacement(data) {
        var layer = createTemporaryObject(layerFactory, test)
        verify(layer !== null)
        // The GUI submits these without processing the worker completion events.
        layer.submit([marker("red", 60, "")], style(25), "position-a")
        layer.submit([marker("green", 120, "")], style(25), "position-a")
        layer.submit([marker("blue", 180, "")], style(25), data.position)
        tryCompare(layer, "renderedRevision", 3)
        var image = grabImage(layer)
        compare(image.pixel(180, 100), Qt.rgba(0, 0, 1, 1))
        compare(image.pixel(60, 100), backgroundColor)
        compare(image.pixel(120, 100), backgroundColor)
    }

    function test_clear_discards_in_flight_results() {
        var layer = createTemporaryObject(layerFactory, test)
        var many = []
        for (var i = 0; i < 1225; ++i)
            many.push(marker("red", 100, "50.1%"))
        layer.submit(many, style(25), "old-position")
        layer.clear()
        layer.submit([marker("blue", 180, "")], style(25), "new-position")
        tryCompare(layer, "renderedRevision", 2)
        var image = grabImage(layer)
        compare(image.pixel(100, 100), backgroundColor)
        compare(image.pixel(180, 100), Qt.rgba(0, 0, 1, 1))
        layer.clear()
        image = grabImage(layer)
        compare(image.pixel(180, 100), backgroundColor)
    }

    function test_destruct_with_render_queued() {
        for (var round = 0; round < 4; ++round) {
            var layer = layerFactory.createObject(test)
            var many = []
            for (var i = 0; i < 1225; ++i)
                many.push(marker("red", 100, String(i)))
            layer.submit(many, style(25), "pending")
            layer.destroy()
            wait(0)
        }
    }
}
