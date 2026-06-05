import QtQuick 2.15
import QtTest 1.2

TestCase {
    id: root
    name: "BottomToolbar"

    function test_hidden_when_no_images() {
        var mock = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("MockBackend.qml")),
            root)
        var toolbar = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("../../qml/components/BottomToolbar.qml")),
            root,
            { controller: mock, width: 900, height: 60 })
        compare(toolbar.imageCount > 0, false)
    }

    function test_shows_index_counter() {
        var mock = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("MockBackend.qml")),
            root,
            { totalCount: 5, currentIndex: 2 })
        var toolbar = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("../../qml/components/BottomToolbar.qml")),
            root,
            { controller: mock, width: 900, height: 60 })
        tryCompare(toolbar, "imageCount", 5, 3000)
        compare(toolbar.imageCount > 0, true)
        tryCompare(toolbar, "imageIndex", 2, 3000)
        compare(toolbar.imageCount, 5)
    }
}
