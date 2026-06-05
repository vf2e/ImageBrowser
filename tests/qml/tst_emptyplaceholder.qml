import QtQuick 2.15
import QtTest 1.2

TestCase {
    id: root
    name: "EmptyPlaceholder"

    function test_visible_when_no_images() {
        var mock = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("MockBackend.qml")),
            root,
            { totalCount: 0 })
        var placeholder = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("../../qml/components/EmptyPlaceholder.qml")),
            root,
            { controller: mock })
        tryCompare(placeholder, "imageCount", 0)
        compare(placeholder.imageCount === 0, true)
    }

    function test_hidden_when_images_loaded() {
        var mock = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("MockBackend.qml")),
            root,
            { totalCount: 3 })
        var placeholder = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("../../qml/components/EmptyPlaceholder.qml")),
            root,
            { controller: mock })
        compare(placeholder.imageCount === 0, false)
        compare(placeholder.imageCount, 3)
    }

    function test_reads_recent_folders_from_controller() {
        var mock = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("MockBackend.qml")),
            root,
            { recentFolders: ["/a", "/b"] })
        var placeholder = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("../../qml/components/EmptyPlaceholder.qml")),
            root,
            { controller: mock })
        compare(placeholder.recentList.length, 2)
    }
}
