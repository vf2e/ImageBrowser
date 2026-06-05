import QtQuick 2.15
import QtGraphicalEffects 1.15

Rectangle {
    id: imageContainer
    required property var controller

    readonly property int imageCount: controller ? controller.totalCount : 0
    readonly property string imagePath: controller ? controller.currentImagePath : ""
    readonly property bool currentFavorite: controller ? controller.isCurrentFavorite : false

    anchors.fill: parent
    anchors.topMargin: imageCount > 0 ? 88 : 16
    anchors.bottomMargin: imageCount > 0 ? 96 : 16
    anchors.leftMargin: 16
    anchors.rightMargin: 16
    radius: 16
    color: "#1A1A1F"
    border.width: 1
    border.color: "#2A2A35"

    signal requestFocus()

    Behavior on anchors.topMargin { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
    Behavior on anchors.bottomMargin { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

    Item {
        id: imageDisplayWrapper
        anchors.fill: parent
        anchors.margins: 1

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: imageContainer.width
                height: imageContainer.height
                radius: imageContainer.radius
            }
        }

        property string currentSrc: imagePath ? "file:///" + imagePath : ""

        Image {
            id: oldImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            autoTransform: true
            sourceSize: Qt.size(width, height)
            visible: imageCount > 0
        }

        Image {
            id: newImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            autoTransform: true
            sourceSize: Qt.size(width, height)
            visible: imageCount > 0

            opacity: 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 0
                    easing.type: Easing.OutCubic
                    onRunningChanged: {
                        if (!running && newImage.opacity === 1.0) {
                            oldImage.source = newImage.source
                        }
                    }
                }
            }

            onStatusChanged: {
                if (status === Image.Ready) opacity = 1.0
                else if (status === Image.Loading) opacity = 0
            }
        }

        onCurrentSrcChanged: {
            if (newImage.status === Image.Ready) {
                oldImage.source = newImage.source
            }
            newImage.source = currentSrc
        }

        Rectangle {
            id: favoriteBadge
            anchors { top: parent.top; right: parent.right; margins: 24 }
            width: 56
            height: 56
            radius: 28
            color: "#E61A1A1F"
            border.color: "#FFD700"
            border.width: 2
            visible: currentFavorite
            scale: visible ? 1.0 : 0.0

            layer.enabled: true
            layer.effect: DropShadow {
                color: "#80FFD700"
                radius: 20
                samples: 25
                spread: 0.15
            }

            Behavior on scale {
                NumberAnimation { duration: 400; easing.type: Easing.OutBack }
            }

            Text {
                anchors.centerIn: parent
                text: "⭐"
                font { pixelSize: 26; bold: true }
                color: "#FFD700"

                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    running: favoriteBadge.visible
                    NumberAnimation { from: 1.0; to: 1.15; duration: 1000; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1.15; to: 1.0; duration: 1000; easing.type: Easing.InOutSine }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onWheel: (wheel) => {
                if (!controller) return
                if (wheel.angleDelta.y > 0) controller.previousImage()
                else controller.nextImage()
            }
            onClicked: (mouse) => {
                requestFocus()
                if (mouse.button === Qt.RightButton && controller)
                    controller.toggleFavoriteForCurrent()
            }
        }
    }
}
