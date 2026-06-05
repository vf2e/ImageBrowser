import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

Popup {
    id: recentFolderMenu
    required property var controller

    readonly property var recentList: controller ? controller.recentFolders : []

    anchors.centerIn: parent
    width: 480
    height: contentColumn.height + 40
    modal: true
    focus: true

    signal selectFolder()

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 250; easing.type: Easing.OutCubic }
        NumberAnimation { property: "scale"; from: 0.95; to: 1.0; duration: 350; easing.type: Easing.OutBack }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 200 }
        NumberAnimation { property: "scale"; from: 1.0; to: 0.95; duration: 200 }
    }

    background: Rectangle {
        color: "#E61A1A1F"
        radius: 20
        border.width: 1.5
        border.color: "#2A2A35"

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            radius: 30
            samples: 25
            verticalOffset: 10
            color: "#99000000"
        }
    }

    Column {
        id: contentColumn
        anchors.centerIn: parent
        width: parent.width - 40
        spacing: 12

        Text {
            text: qsTr("最近打开")
            color: "#FFFFFF"
            font { pixelSize: 16; weight: Font.Bold; family: "Microsoft YaHei" }
            leftPadding: 8
            bottomPadding: 8
        }

        Repeater {
            model: recentList
            delegate: Rectangle {
                width: contentColumn.width
                height: 50
                radius: 12
                color: itemMouse.containsMouse ? "#33333A" : "transparent"

                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Text {
                        text: "📂"
                        font.pixelSize: 16
                        opacity: itemMouse.containsMouse ? 1.0 : 0.6
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData
                        color: itemMouse.containsMouse ? "#FFFFFF" : "#CCCCCC"
                        elide: Text.ElideLeft
                        font { pixelSize: 13; family: "Consolas" }
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (recentFolderMenu.controller)
                            recentFolderMenu.controller.loadFolder(modelData)
                        recentFolderMenu.close()
                    }
                }
            }
        }

        Text {
            visible: recentList.length === 0
            text: qsTr("暂无历史记录")
            color: "#666666"
            font.pixelSize: 13
            leftPadding: 8
            bottomPadding: 8
        }

        Rectangle {
            width: parent.width
            height: 1
            color: "#2A2A35"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Rectangle {
            width: contentColumn.width
            height: 50
            radius: 12
            color: browseMouse.containsMouse ? "#1A3B82F6" : "transparent"
            border.width: 1
            border.color: browseMouse.containsMouse ? "#3B82F6" : "transparent"

            Behavior on color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 8
                Text { text: "🔍"; font.pixelSize: 16; opacity: 0.8 }
                Text {
                    text: qsTr("浏览本地文件夹...")
                    color: browseMouse.containsMouse ? "#60A5FA" : "#AAAAAA"
                    font { pixelSize: 14; weight: Font.Medium }
                }
            }

            MouseArea {
                id: browseMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    recentFolderMenu.close()
                    selectFolder()
                }
            }
        }
    }
}
