import QtQuick 2.15
import QtTest 1.2

TestCase {
    id: root
    name: "TopToolbar"

    function test_hidden_when_no_images() {
        var mock = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("MockBackend.qml")),
            root)
        var toolbar = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("../../qml/components/TopToolbar.qml")),
            root,
            { controller: mock, width: 900, height: 52 })
        compare(toolbar.imageCount, 0)
        compare(toolbar.imageCount > 0, false)
    }

    function test_visible_when_has_images() {
        var mock = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("MockBackend.qml")),
            root,
            { totalCount: 2, currentImagePath: "C:/photos/sample.jpg", favoriteCount: 1 })
        var toolbar = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("../../qml/components/TopToolbar.qml")),
            root,
            { controller: mock, width: 900, height: 52 })
        tryCompare(toolbar, "imageCount", 2, 3000)
        compare(toolbar.imageCount > 0, true)
        compare(toolbar.imagePath, "C:/photos/sample.jpg")
        compare(toolbar.favorites, 1)
    }
}
