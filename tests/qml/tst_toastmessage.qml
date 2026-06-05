import QtQuick 2.15
import QtTest 1.2

TestCase {
    id: root
    name: "ToastMessage"

    function test_show_sets_message_and_type() {
        var toast = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("../../qml/components/ToastMessage.qml")),
            root,
            { width: 500 })
        toast.show("测试消息", "info")
        compare(toast.message, "测试消息")
        compare(toast.type, "info")
        tryCompare(toast, "opacity", 1.0)
    }

    function test_fav_type_updates_styling() {
        var toast = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("../../qml/components/ToastMessage.qml")),
            root)
        toast.show("已收藏", "fav")
        compare(toast.type, "fav")
        compare(toast.message, "已收藏")
    }

    function test_unfav_type_updates_styling() {
        var toast = createTemporaryObject(
            Qt.createComponent(Qt.resolvedUrl("../../qml/components/ToastMessage.qml")),
            root)
        toast.show("已取消", "unfav")
        compare(toast.type, "unfav")
    }
}
