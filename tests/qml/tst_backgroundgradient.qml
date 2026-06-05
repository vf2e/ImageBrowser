import QtQuick 2.15
import QtTest 1.2

TestCase {
    id: root
    name: "BackgroundGradient"

    function test_component_loads() {
        var comp = Qt.createComponent(Qt.resolvedUrl("../../qml/components/BackgroundGradient.qml"))
        compare(comp.status, Component.Ready, comp.errorString())
    }

    function test_gradient_has_two_stops() {
        var bg = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("../../qml/components/BackgroundGradient.qml")),
            root,
            { width: 200, height: 200 })
        verify(bg !== null)
        compare(bg.gradient.stops.length, 2)
        compare(bg.gradient.stops[0].position, 0.0)
        compare(bg.gradient.stops[1].position, 1.0)
    }
}
