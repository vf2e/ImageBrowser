import QtQuick 2.15
import QtQuick.Window 2.15

// 与 main.qml 中 mainContainer 的 Keys.onPressed 逻辑一致，供 C++ 集成测试加载
Window {
    id: root
    width: 480
    height: 360
    visible: true
    color: "#0F0F13"

    property alias focusHost: mainContainer

    Item {
        id: mainContainer
        anchors.fill: parent
        focus: true

        Keys.onPressed: (event) => {
            if (!controller) return
            switch (event.key) {
                case Qt.Key_Left: controller.previousImage(); break
                case Qt.Key_Right: controller.nextImage(); break
                case Qt.Key_Up:
                case Qt.Key_Down:
                case Qt.Key_Space: controller.toggleFavoriteForCurrent(); break
                default: return
            }
            event.accepted = true
        }

        Component.onCompleted: forceActiveFocus()
    }
}
