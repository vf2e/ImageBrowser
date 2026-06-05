import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

Rectangle {
    id: bottomBar
    required property var controller

    readonly property int imageCount: controller ? controller.totalCount : 0
    readonly property int imageIndex: controller ? controller.currentIndex : 0

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 20
    width: Math.min(parent.width * 0.9, 900)
    height: 60
    radius: 20

    visible: imageCount > 0
    opacity: visible ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 400 } }

    gradient: Gradient {
        GradientStop { position: 0.0; color: "#E6181820" }
        GradientStop { position: 1.0; color: "#E610101A" }
    }

    border.color: "#2A2A35"
    border.width: 1.5

    layer.enabled: true
    layer.effect: DropShadow {
        transparentBorder: true
        horizontalOffset: 0
        verticalOffset: -6
        radius: 20
        samples: 25
        color: "#80000000"
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        spacing: 20

        Rectangle {
            Layout.preferredHeight: 36
            Layout.preferredWidth: 120
            radius: 18
            color: "#1A1A1F"
            border.width: 1
            border.color: "#33333A"

            Text {
                anchors.centerIn: parent
                text: imageCount > 0 ? (imageIndex + 1) + " / " + imageCount : "0 / 0"
                font {
                    pixelSize: 14
                    weight: Font.Medium
                    family: "Consolas"
                }
                color: "white"
            }
        }

        Slider {
            id: customProgress
            Layout.fillWidth: true
            from: 0
            to: Math.max(0, imageCount - 1)
            stepSize: 1
            value: imageIndex

            Connections {
                target: bottomBar.controller
                enabled: bottomBar.controller !== null
                function onCurrentIndexChanged() {
                    if (!customProgress.pressed) {
                        customProgress.value = bottomBar.imageIndex
                    }
                }
            }

            onMoved: {
                if (bottomBar.controller)
                    bottomBar.controller.currentIndex = Math.round(value)
            }

            background: Rectangle {
                x: customProgress.leftPadding
                y: customProgress.topPadding + customProgress.availableHeight / 2 - height / 2
                implicitHeight: 6
                width: customProgress.availableWidth
                height: implicitHeight
                radius: 3
                color: "#2A2A35"

                Rectangle {
                    width: customProgress.visualPosition * parent.width
                    height: parent.height
                    radius: 3

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#6366F1" }
                        GradientStop { position: 0.5; color: "#8B5CF6" }
                        GradientStop { position: 1.0; color: "#10B981" }
                    }
                }
            }

            handle: Rectangle {
                x: customProgress.leftPadding + customProgress.visualPosition * (customProgress.availableWidth - width)
                y: customProgress.topPadding + customProgress.availableHeight / 2 - height / 2
                width: 12
                height: 12
                radius: 6
                color: "#FFFFFF"

                scale: customProgress.pressed ? 1.3 : 1.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                layer.enabled: true
                layer.effect: DropShadow {
                    radius: 8
                    color: "#8B5CF6"
                    samples: 12
                }
            }
        }

        Row {
            spacing: 20
            Layout.alignment: Qt.AlignVCenter

            Repeater {
                model: ["↑↓ Space 右键 收藏", "← → 滚轮 翻页"]
                delegate: Text {
                    text: modelData
                    font {
                        pixelSize: 12
                        weight: Font.Normal
                        family: "Microsoft YaHei"
                    }
                    color: "#888888"
                }
            }
        }
    }
}
