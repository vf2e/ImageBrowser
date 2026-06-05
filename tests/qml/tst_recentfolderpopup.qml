import QtQuick 2.15
import QtTest 1.2
import QtQuick.Controls 2.15

TestCase {
    id: root
    name: "RecentFolderPopup"

    function test_reads_recent_list_from_controller() {
        var mock = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("MockBackend.qml")),
            root,
            { recentFolders: ["C:/album-a", "C:/album-b", "C:/album-c"] })
        var popup = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("../../qml/components/RecentFolderPopup.qml")),
            root,
            { controller: mock, parent: root })
        verify(popup.controller !== null)
        compare(popup.controller.recentFolders.length, 3)
        compare(popup.controller.recentFolders[0], "C:/album-a")
    }

    function test_empty_recent_list() {
        var mock = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("MockBackend.qml")),
            root,
            { recentFolders: [] })
        var popup = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("../../qml/components/RecentFolderPopup.qml")),
            root,
            { controller: mock, parent: root })
        compare(popup.controller.recentFolders.length, 0)
    }
}
