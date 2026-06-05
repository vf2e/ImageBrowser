import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

Rectangle {
    id: topBar
    required property var controller

    readonly property int imageCount: controller ? controller.totalCount : 0
    readonly property string imagePath: controller ? controller.currentImagePath : ""
    readonly property int favorites: controller ? controller.favoriteCount : 0

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: 20
    width: Math.min(parent.width * 0.9, 900)
    height: 52
    radius: 16

    signal requestFocus()
    signal openRecentMenu()

    visible: imageCount > 0
    opacity: visible ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 400 } }

    gradient: Gradient {
        GradientStop { position: 0.0; color: "#E6181820" }
        GradientStop { position: 1.0; color: "#E610101A" }
    }

    border.color: topBarMouse.containsMouse ? "#4D4D5A" : "#2A2A35"
    border.width: 1.5

    layer.enabled: true
    layer.effect: DropShadow {
        transparentBorder: true
        horizontalOffset: 0
        verticalOffset: 6
        radius: 20
        samples: 25
        color: "#80000000"
    }

    MouseArea {
        id: topBarMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: requestFocus()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 16

        Rectangle {
            id: btnFolder
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: 12
            color: folderMouse.containsMouse ? "#33333A" : "transparent"
            border.width: 1
            border.color: folderMouse.containsMouse ? "#4D4D5A" : "transparent"

            Text {
                anchors.centerIn: parent
                text: "📁"
                font.pixelSize: 20
                opacity: folderMouse.containsMouse ? 1.0 : 0.7
                scale: folderMouse.pressed ? 0.9 : 1.0
                Behavior on scale { NumberAnimation { duration: 150 } }
            }

            MouseArea {
                id: folderMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    openRecentMenu()
                    requestFocus()
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 20
            color: "#33333A"
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: 12
            color: "#1A1A1F"

            Text {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                verticalAlignment: Text.AlignVCenter
                text: imagePath ? imagePath : qsTr("未选择路径")
                font {
                    pixelSize: 13
                    weight: Font.Normal
                    family: "Consolas"
                }
                color: "#AAAAAA"
                elide: Text.ElideMiddle
            }
        }

        Rectangle {
            Layout.preferredWidth: 100
            Layout.preferredHeight: 40
            radius: 12
            color: "#1A1A1F"
            border.width: 1
            border.color: "#33333A"

            Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: "✨"
                    font.pixelSize: 16
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: favorites
                    color: "#FFD700"
                    font {
                        pixelSize: 16
                        weight: Font.Bold
                        family: "Consolas"
                    }
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Rectangle {
            id: btnExport
            Layout.preferredWidth: 100
            Layout.preferredHeight: 40
            radius: 12

            gradient: Gradient {
                GradientStop { position: 0.0; color: exportMouse.containsMouse ? "#4F46E5" : "#4338CA" }
                GradientStop { position: 1.0; color: exportMouse.containsMouse ? "#3730A3" : "#312E81" }
            }

            border.width: 1
            border.color: exportMouse.containsMouse ? "#818CF8" : "#4F46E5"

            scale: exportMouse.pressed ? 0.95 : 1.0
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                color: exportMouse.containsMouse ? "#804F46E5" : "#004F46E5"
                radius: 16
                samples: 25
                verticalOffset: 4
                Behavior on color { ColorAnimation { duration: 300 } }
            }

            Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: qsTr("导出")
                    color: "white"
                    font {
                        pixelSize: 14
                        weight: Font.DemiBold
                        letterSpacing: 0.5
                    }
                }
            }

            MouseArea {
                id: exportMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (controller) controller.exportFavorites()
                    requestFocus()
                }
            }
        }
    }
}
