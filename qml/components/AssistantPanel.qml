import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

Item {
    id: root
    required property var controller

    readonly property bool open: controller && controller.assistantPanelOpen
    readonly property bool busy: controller ? controller.assistantBusy : false
    readonly property var messages: controller ? controller.assistantMessages : []
    readonly property real bubbleWidthRatio: 0.94

    readonly property var quickQuestions: [
        "有哪些快捷键？",
        "怎么收藏和导出？",
        "美学评分怎么开启？",
        "AI 点评为什么很慢？"
    ]

    function sendCurrentMessage() {
        if (!controller || busy) return
        const text = inputField.text.trim()
        if (text.length === 0) return
        controller.sendAssistantMessage(text)
        inputField.text = ""
        inputField.forceActiveFocus()
    }

    anchors.fill: parent
    visible: opacity > 0
    opacity: open ? 1 : 0
    z: 600

    Behavior on opacity {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    // 拦截滚轮，避免与图片翻页 / 底部进度条冲突
    MouseArea {
        anchors.fill: parent
        enabled: open
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onWheel: (wheel) => { wheel.accepted = true }
    }

    Rectangle {
        anchors.fill: parent
        color: "#99000000"
    }

    MouseArea {
        anchors.fill: parent
        enabled: open
        z: 0
        onClicked: {
            if (controller)
                controller.assistantPanelOpen = false
        }
        hoverEnabled: true
        onWheel: (wheel) => { wheel.accepted = true }
    }

    Rectangle {
        id: panel
        z: 1
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.9, 560)
        height: Math.min(parent.height * 0.78, 640)
        radius: 20
        clip: true

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#F0181820" }
            GradientStop { position: 1.0; color: "#F010101A" }
        }

        border.color: "#2A2A35"
        border.width: 1.5

        scale: root.open ? 1.0 : 0.94
        opacity: root.open ? 1.0 : 0.0
        Behavior on scale {
            NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 220 }
        }

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: 12
            radius: 32
            samples: 25
            color: "#99000000"
        }

        // 面板内再次拦截滚轮
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onWheel: (wheel) => { wheel.accepted = true }
        }

        Row {
            id: headerActions
            z: 3
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 14
            anchors.rightMargin: 14
            spacing: 8

            Rectangle {
                width: clearLabel.implicitWidth + 20
                height: 32
                radius: 10
                color: clearMouse.containsMouse ? "#33333A" : "#261A1A1F"
                border.width: 1
                border.color: clearMouse.containsMouse ? "#4D4D5A" : "#2A2A35"

                Text {
                    id: clearLabel
                    anchors.centerIn: parent
                    text: "清空"
                    color: clearMouse.containsMouse ? "#F8FAFC" : "#94A3B8"
                    font { pixelSize: 12; family: "Microsoft YaHei UI" }
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !busy
                    onClicked: {
                        if (controller)
                            controller.clearAssistantChat()
                        inputField.forceActiveFocus()
                    }
                }
            }

            Rectangle {
                width: 32
                height: 32
                radius: 10
                color: closeMouse.containsMouse ? "#33333A" : "#261A1A1F"
                border.width: 1
                border.color: closeMouse.containsMouse ? "#4D4D5A" : "#2A2A35"

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: closeMouse.containsMouse ? "#F8FAFC" : "#94A3B8"
                    font { pixelSize: 14; weight: Font.Medium }
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (controller)
                            controller.assistantPanelOpen = false
                    }
                }
            }
        }

        FocusScope {
            id: panelFocus
            anchors.fill: parent
            focus: root.open

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                anchors.topMargin: 16
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    Layout.rightMargin: headerActions.width + 8
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        radius: 14
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#06B6D4" }
                            GradientStop { position: 1.0; color: "#6366F1" }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "💬"
                            font.pixelSize: 20
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "小助理"
                            color: "#F8FAFC"
                            font {
                                pixelSize: 17
                                weight: Font.DemiBold
                                family: "Microsoft YaHei UI"
                            }
                        }

                        Text {
                            text: "ImageBrowser 使用指南 · 本地知识库"
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
                    Layout.fillHeight: true
                    radius: 16
                    color: "#1A1A1F"
                    border.width: 1
                    border.color: "#2A2A35"
                    clip: true

                    ListView {
                        id: chatList
                        anchors.fill: parent
                        anchors.margins: 10
                        clip: true
                        spacing: 10
                        model: messages
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            implicitWidth: 6
                            contentItem: Rectangle {
                                radius: 3
                                color: "#4D4D5A"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                            onWheel: (wheel) => {
                                wheel.accepted = true
                                const step = wheel.angleDelta.y > 0 ? -48 : 48
                                chatList.contentY = Math.max(
                                    0,
                                    Math.min(chatList.contentHeight - chatList.height,
                                             chatList.contentY + step))
                            }
                        }

                        delegate: Item {
                            width: chatList.width
                            implicitHeight: bubbleRect.height + 4

                            readonly property bool isUser: modelData.role === "user"
                            readonly property real bubbleW: chatList.width * root.bubbleWidthRatio

                            Rectangle {
                                id: bubbleRect
                                width: bubbleW
                                height: bubbleText.implicitHeight + 20
                                radius: 14
                                anchors.right: isUser ? parent.right : undefined
                                anchors.left: isUser ? undefined : parent.left
                                color: isUser ? "#4338CA" : "#262630"
                                border.width: isUser ? 0 : 1
                                border.color: "#33333A"

                                Text {
                                    id: bubbleText
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 10
                                    width: bubbleW - 20
                                    wrapMode: Text.WordWrap
                                    color: isUser ? "#FFFFFF" : "#E2E8F0"
                                    lineHeight: 1.55
                                    lineHeightMode: Text.ProportionalHeight
                                    font {
                                        pixelSize: 14
                                        family: "Microsoft YaHei UI"
                                    }
                                    text: modelData.text
                                }
                            }
                        }

                        onCountChanged: Qt.callLater(function() {
                            if (count > 0)
                                chatList.positionViewAtEnd()
                        })
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "常见问题"
                        color: "#64748B"
                        font { pixelSize: 11; family: "Microsoft YaHei UI" }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: quickQuestions

                            Rectangle {
                                height: 30
                                width: chipText.implicitWidth + 20
                                radius: 15
                                color: chipMouse.containsMouse ? "#2A2A35" : "#1E1E28"
                                border.width: 1
                                border.color: chipMouse.containsMouse ? "#6366F1" : "#33333A"
                                opacity: busy ? 0.5 : 1.0

                                Text {
                                    id: chipText
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: chipMouse.containsMouse ? "#E2E8F0" : "#94A3B8"
                                    font { pixelSize: 12; family: "Microsoft YaHei UI" }
                                }

                                MouseArea {
                                    id: chipMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: busy ? Qt.ArrowCursor : Qt.PointingHandCursor
                                    enabled: !busy
                                    onClicked: {
                                        if (!controller) return
                                        controller.sendAssistantMessage(modelData)
                                        inputField.forceActiveFocus()
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    visible: busy

                    Repeater {
                        model: 3
                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: "#06B6D4"
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                running: busy
                                PauseAnimation { duration: index * 180 }
                                NumberAnimation { to: 1.0; duration: 400 }
                                NumberAnimation { to: 0.35; duration: 400 }
                            }
                        }
                    }

                    Text {
                        text: "思考中…"
                        color: "#06B6D4"
                        font { pixelSize: 12; family: "Microsoft YaHei UI" }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    TextField {
                        id: inputField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        placeholderText: "输入问题，或点击上方常见问题…"
                        placeholderTextColor: "#64748B"
                        color: "#F8FAFC"
                        font { pixelSize: 14; family: "Microsoft YaHei UI" }
                        selectByMouse: true
                        focus: panelFocus.focus
                        enabled: !busy
                        background: Rectangle {
                            radius: 14
                            color: "#121218"
                            border.width: 1
                            border.color: inputField.activeFocus ? "#6366F1" : "#2A2A35"
                        }

                        Keys.onReturnPressed: root.sendCurrentMessage()
                        Keys.onEnterPressed: root.sendCurrentMessage()
                    }

                    Rectangle {
                        Layout.preferredWidth: 72
                        Layout.preferredHeight: 44
                        radius: 14
                        opacity: (inputField.text.trim().length > 0 && !busy) ? 1.0 : 0.5

                        gradient: Gradient {
                            GradientStop {
                                position: 0.0
                                color: sendMouse.containsMouse ? "#0891B2" : "#06B6D4"
                            }
                            GradientStop {
                                position: 1.0
                                color: sendMouse.containsMouse ? "#0284C7" : "#0891B2"
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "发送"
                            color: "white"
                            font {
                                pixelSize: 14
                                weight: Font.DemiBold
                                family: "Microsoft YaHei UI"
                            }
                        }

                        MouseArea {
                            id: sendMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: busy ? Qt.ArrowCursor : Qt.PointingHandCursor
                            enabled: inputField.text.trim().length > 0 && !busy
                            onClicked: root.sendCurrentMessage()
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: controller
        enabled: controller !== null
        function onAssistantPanelOpenChanged() {
            if (controller.assistantPanelOpen)
                Qt.callLater(function() { inputField.forceActiveFocus() })
        }
    }
}
