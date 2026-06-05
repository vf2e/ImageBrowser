import QtQuick 2.15
import QtTest 1.2

TestCase {
    id: root
    name: "ImageViewer"

    function test_binds_image_path_and_count() {
        var mock = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("MockBackend.qml")),
            root,
            { totalCount: 2, currentIndex: 1, currentImagePath: "C:/photos/sample.jpg" })
        var viewer = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("../../qml/components/ImageViewer.qml")),
            root,
            { controller: mock, width: 400, height: 300 })
        tryCompare(viewer, "imageCount", 2, 3000)
        compare(viewer.imagePath, "C:/photos/sample.jpg")
        compare(viewer.imageCount > 0, true)
    }

    function test_favorite_badge_follows_controller() {
        var mock = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("MockBackend.qml")),
            root,
            { totalCount: 1, isCurrentFavorite: true, currentImagePath: "C:/photos/fav.jpg" })
        var viewer = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("../../qml/components/ImageViewer.qml")),
            root,
            { controller: mock, width: 400, height: 300 })
        tryCompare(viewer, "currentFavorite", true, 3000)
        mock.isCurrentFavorite = false
        tryCompare(viewer, "currentFavorite", false, 3000)
    }

    function test_zero_images_hides_content() {
        var mock = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("MockBackend.qml")),
            root,
            { totalCount: 0, currentImagePath: "" })
        var viewer = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("../../qml/components/ImageViewer.qml")),
            root,
            { controller: mock, width: 400, height: 300 })
        compare(viewer.imageCount, 0)
        compare(viewer.imageCount > 0, false)
    }
}
