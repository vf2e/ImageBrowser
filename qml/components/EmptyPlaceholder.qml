import QtQuick 2.15
import QtGraphicalEffects 1.15

Rectangle {
    id: placeholderContainer
    required property var controller

    readonly property int imageCount: controller ? controller.totalCount : 0
    readonly property var recentList: controller ? controller.recentFolders : []

    anchors.centerIn: parent
    width: 400
    height: 200
    radius: 20
    color: "#1A1A1F"
    border.width: 1.5
    border.color: "#2A2A35"
    visible: imageCount === 0

    signal requestFocus()
    signal openRecentMenu()
    signal selectFolder()

    layer.enabled: true
    layer.effect: DropShadow {
        color: "#40000000"
        radius: 20
        samples: 25
        verticalOffset: 4
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: placeholderText.color = "#FFFFFF"
        onExited: placeholderText.color = "#AAAAAA"
        onClicked: {
            if (recentList.length > 0) {
                openRecentMenu()
            } else {
                selectFolder()
            }
            requestFocus()
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 20

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "📁"
            font.pixelSize: 48
            color: "#6666FF"
        }

        Text {
            id: placeholderText
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("请选择一个图片文件夹")
            font {
                pixelSize: 18
                weight: Font.Medium
                family: "Microsoft YaHei"
            }
            color: "#AAAAAA"
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    SequentialAnimation on opacity {
        running: placeholderContainer.visible
        loops: Animation.Infinite
        NumberAnimation { from: 0.8; to: 1.0; duration: 2000; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1.0; to: 0.8; duration: 2000; easing.type: Easing.InOutSine }
    }
}
