import QtQuick 2.15
import QtGraphicalEffects 1.15
import QtQuick.Controls 2.15

Rectangle {
    id: imageContainer
    required property var controller

    readonly property int imageCount: controller ? controller.totalCount : 0
    readonly property string imagePath: controller ? controller.currentImagePath : ""
    readonly property bool currentFavorite: controller ? controller.isCurrentFavorite : false
    readonly property real aestheticScore: controller ? controller.aestheticScore : 0
    readonly property bool aestheticScoreValid: controller ? controller.aestheticScoreValid : false
    readonly property bool aestheticEvaluating: controller ? controller.aestheticEvaluating : false
    readonly property string aestheticStatusHint: controller ? controller.aestheticStatusHint : ""

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
            id: aestheticBadge
            z: 10
            anchors { top: parent.top; left: parent.left; margins: 24 }
            height: 36
            width: aestheticLabel.implicitWidth + 24
            radius: 18
            color: "#CC1A1A1F"
            border.width: 1
            visible: imageCount > 0
            opacity: visible ? 1.0 : 0.0
            border.color: {
                if (!aestheticScoreValid) return "#334155"
                if (aestheticScore >= 7.0) return "#6686EFAC"
                if (aestheticScore >= 5.0) return "#66FBBF24"
                return "#66FCA5A5"
            }

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
            }

            ToolTip.visible: badgeHover.containsMouse
            ToolTip.text: aestheticScoreValid
                ? "EAT 美学评分（专用模型，非 Q-SiT）"
                : aestheticStatusHint
            ToolTip.delay: 300

            Text {
                id: aestheticLabel
                anchors.centerIn: parent
                color: aestheticScoreValid ? "#F8FAFC" : "#94A3B8"
                font {
                    pixelSize: 13
                    weight: Font.Medium
                    family: "Microsoft YaHei UI"
                }
                text: {
                    if (aestheticEvaluating) return "评分中..."
                    if (aestheticScoreValid) return "美学 " + aestheticScore.toFixed(2)
                    if (aestheticStatusHint.length > 0) return "美学 未就绪"
                    return "美学 --"
                }
            }
        }

        Rectangle {
            id: critiqueButton
            z: 10
            anchors { bottom: parent.bottom; left: parent.left; margins: 24 }
            height: 36
            width: critiqueRow.implicitWidth + 24
            radius: 18
            color: critiqueButtonHover.containsMouse ? "#DD4338CA" : "#CC312E81"
            border.width: 1
            border.color: critiqueButtonHover.containsMouse ? "#818CF8" : "#664F46E5"
            visible: imageCount > 0

            Behavior on color { ColorAnimation { duration: 180 } }
            Behavior on border.color { ColorAnimation { duration: 180 } }

            scale: critiqueButtonHover.pressed ? 0.96 : 1.0
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                radius: 12
                samples: 17
                verticalOffset: 3
                color: critiqueButtonHover.containsMouse ? "#664F46E5" : "#004F46E5"
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            Row {
                id: critiqueRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "✦"
                    color: "#C4B5FD"
                    font { pixelSize: 12; weight: Font.Bold }
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    id: critiqueButtonLabel
                    text: "AI 点评"
                    color: "#F8FAFC"
                    font {
                        pixelSize: 13
                        weight: Font.DemiBold
                        family: "Microsoft YaHei UI"
                    }
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: critiqueButtonHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (controller)
                        controller.openCritiquePanel()
                }
            }
        }

        Rectangle {
            id: favoriteBadge
            z: 10
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
            z: 0
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
