import QtQuick 2.15
import QtGraphicalEffects 1.15

Rectangle {
    id: fab
    required property var controller

    signal requestFocus()

    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: 24
    anchors.bottomMargin: 24
    width: 56
    height: 56
    radius: 28
    z: 400

    gradient: Gradient {
        GradientStop { position: 0.0; color: fabMouse.containsMouse ? "#0891B2" : "#06B6D4" }
        GradientStop { position: 1.0; color: fabMouse.containsMouse ? "#0284C7" : "#0891B2" }
    }

    border.width: 1
    border.color: fabMouse.containsMouse ? "#67E8F9" : "#22D3EE"

    scale: fabMouse.pressed ? 0.92 : (fabMouse.containsMouse ? 1.05 : 1.0)
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

    layer.enabled: true
    layer.effect: DropShadow {
        transparentBorder: true
        radius: 20
        samples: 25
        verticalOffset: 6
        color: fabMouse.containsMouse ? "#8006B6D4" : "#5006B6D4"
    }

    Text {
        anchors.centerIn: parent
        text: "💬"
        font.pixelSize: 24
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: 6
        text: "小助理"
        color: "#94A3B8"
        font {
            pixelSize: 11
            family: "Microsoft YaHei UI"
        }
        visible: fabMouse.containsMouse
    }

    MouseArea {
        id: fabMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (controller)
                controller.openAssistantPanel()
        }
    }
}
