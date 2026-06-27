import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

Item {
    id: root
    required property var controller

    readonly property bool open: controller && controller.critiquePanelOpen
    readonly property bool evaluating: controller ? controller.critiqueEvaluating : false
    readonly property bool hasText: controller ? controller.critiqueValid : false
    readonly property string critiqueText: controller ? controller.critiqueText : ""
    readonly property string statusHint: controller ? controller.critiqueStatusHint : ""
    readonly property bool qualityScoreValid: controller ? controller.critiqueQualityScoreValid : false
    readonly property real qualityScore: controller ? controller.critiqueQualityScore : 0

    readonly property string bodyText: {
        if (evaluating) return "正在分析构图、光影与色彩，请稍候..."
        if (hasText) return critiqueText
        if (statusHint.length > 0) return statusHint
        return "点击下方按钮，Q-SiT 将从摄影角度生成本地 AI 点评。"
    }

    anchors.fill: parent
    visible: opacity > 0
    opacity: open ? 1 : 0
    z: 200

    Behavior on opacity {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        color: "#99000000"
    }

    MouseArea {
        anchors.fill: parent
        enabled: open
        onClicked: {
            if (controller)
                controller.critiquePanelOpen = false
        }
    }

    Rectangle {
        id: panel
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
            topMargin: 20
            bottomMargin: 20
            rightMargin: 16
        }
        width: Math.min(parent.width * 0.36, 400)
        radius: 20
        clip: true

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#F0181820" }
            GradientStop { position: 1.0; color: "#F010101A" }
        }

        border.color: "#2A2A35"
        border.width: 1.5

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: -10
            verticalOffset: 0
            radius: 28
            samples: 25
            color: "#99000000"
        }

        x: root.open ? 0 : width + 32
        Behavior on x {
            NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse.accepted = true
        }

        Rectangle {
            id: closeButton
            z: 2
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 14
            anchors.rightMargin: 14
            width: 36
            height: 36
            radius: 12
            color: closeMouse.containsMouse ? "#33333A" : "#261A1A1F"
            border.width: 1
            border.color: closeMouse.containsMouse ? "#4D4D5A" : "#2A2A35"

            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "✕"
                color: closeMouse.containsMouse ? "#F8FAFC" : "#94A3B8"
                font { pixelSize: 14; weight: Font.Medium }
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (controller)
                        controller.critiquePanelOpen = false
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            anchors.rightMargin: 20
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                Layout.rightMargin: 44
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    radius: 14
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#6366F1" }
                        GradientStop { position: 1.0; color: "#8B5CF6" }
                    }

                    layer.enabled: true
                    layer.effect: DropShadow {
                        radius: 12
                        samples: 17
                        color: "#668B5CF6"
                        verticalOffset: 2
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "✦"
                        color: "white"
                        font { pixelSize: 18; weight: Font.Bold }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "AI 摄影点评"
                        color: "#F8FAFC"
                        font {
                            pixelSize: 17
                            weight: Font.DemiBold
                            family: "Microsoft YaHei UI"
                        }
                    }

                    Text {
                        text: "Q-SiT 本地大模型 · 250字以内"
                        color: "#64748B"
                        font {
                            pixelSize: 11
                            family: "Microsoft YaHei UI"
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: qualityScoreValid ? 52 : 0
                visible: qualityScoreValid
                radius: 12
                color: "#1A1A1F"
                border.width: 1
                border.color: {
                    if (qualityScore >= 7.0) return "#6686EFAC"
                    if (qualityScore >= 5.0) return "#66FBBF24"
                    return "#66FCA5A5"
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "AI 质量评分"
                            color: "#94A3B8"
                            font { pixelSize: 12; family: "Microsoft YaHei UI" }
                        }

                        Text {
                            text: "Q-SiT"
                            color: "#8B5CF6"
                            font { pixelSize: 10; weight: Font.Medium; family: "Consolas" }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: qualityScore.toFixed(2)
                            color: "#F8FAFC"
                            font { pixelSize: 16; weight: Font.Bold; family: "Consolas" }
                        }

                        Text {
                            text: "/ 10"
                            color: "#64748B"
                            font { pixelSize: 12; family: "Consolas" }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "左上角「美学」为 EAT 专用评分，两者模型不同"
                        color: "#475569"
                        font { pixelSize: 10; family: "Microsoft YaHei UI" }
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16
                color: "#1A1A1F"
                border.width: 1
                border.color: "#2A2A35"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Row {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: evaluating

                        Repeater {
                            model: 3
                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: "#8B5CF6"
                                opacity: evaluating ? 0.35 : 0

                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    running: evaluating
                                    PauseAnimation { duration: index * 180 }
                                    NumberAnimation { to: 1.0; duration: 400; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: 0.35; duration: 400; easing.type: Easing.InOutSine }
                                }
                            }
                        }

                        Text {
                            text: "模型推理中"
                            color: "#8B5CF6"
                            font {
                                pixelSize: 12
                                weight: Font.Medium
                                family: "Microsoft YaHei UI"
                            }
                            visible: evaluating
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                        Text {
                            width: panel.width - 72
                            wrapMode: Text.WordWrap
                            color: hasText ? "#E2E8F0" : "#94A3B8"
                            lineHeight: 1.6
                            lineHeightMode: Text.ProportionalHeight
                            font {
                                pixelSize: 14
                                family: "Microsoft YaHei UI"
                            }
                            text: bodyText
                        }
                    }
                }
            }

            Rectangle {
                id: actionButton
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 14
                opacity: (controller && controller.totalCount > 0 && !evaluating) ? 1.0 : 0.55

                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: actionMouse.containsMouse && !evaluating ? "#4F46E5" : "#4338CA"
                    }
                    GradientStop {
                        position: 1.0
                        color: actionMouse.containsMouse && !evaluating ? "#3730A3" : "#312E81"
                    }
                }

                border.width: 1
                border.color: actionMouse.containsMouse && !evaluating ? "#818CF8" : "#4F46E5"

                scale: actionMouse.pressed && !evaluating ? 0.97 : 1.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                layer.enabled: !evaluating
                layer.effect: DropShadow {
                    transparentBorder: true
                    radius: 16
                    samples: 25
                    verticalOffset: 4
                    color: actionMouse.containsMouse ? "#804F46E5" : "#404338CA"
                    Behavior on color { ColorAnimation { duration: 250 } }
                }

                Text {
                    anchors.centerIn: parent
                    text: evaluating ? "点评中..." : (hasText ? "重新点评" : "开始点评")
                    color: "white"
                    font {
                        pixelSize: 14
                        weight: Font.DemiBold
                        letterSpacing: 0.5
                        family: "Microsoft YaHei UI"
                    }
                }

                MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: evaluating ? Qt.ArrowCursor : Qt.PointingHandCursor
                    enabled: controller && controller.totalCount > 0 && !evaluating
                    onClicked: controller.requestCritique()
                }
            }
        }
    }
}
