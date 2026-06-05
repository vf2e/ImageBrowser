import QtQuick 2.15
import QtGraphicalEffects 1.15

Rectangle {
    id: toast
    anchors.horizontalCenter: parent.horizontalCenter
    y: parent.height - height - 100

    property string type: "info"
    property alias message: toastLabel.text

    visible: opacity > 0
    width: Math.min(contentRow.width + 60, 500)
    height: 56
    radius: 28

    gradient: Gradient {
        GradientStop {
            position: 0.0
            color: {
                if (toast.type === "fav") return "#E6F0FDF4"
                if (toast.type === "unfav") return "#E6FEF2F2"
                return "#E61A1A1F"
            }
        }
        GradientStop {
            position: 1.0
            color: {
                if (toast.type === "fav") return "#E6DCFCE7"
                if (toast.type === "unfav") return "#E6FEE2E2"
                return "#E6181820"
            }
        }
    }

    border.color: {
        if (toast.type === "fav") return "#6686EFAC"
        if (toast.type === "unfav") return "#66FCA5A5"
        return "#2A2A35"
    }
    border.width: 1.5

    layer.enabled: true
    layer.effect: DropShadow {
        transparentBorder: true
        radius: 25
        samples: 25
        verticalOffset: 8
        color: {
            if (toast.type === "fav") return "#4022C55E"
            if (toast.type === "unfav") return "#40EF4444"
            return "#60000000"
        }
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 12

        Item {
            width: 24
            height: 24
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: {
                    if (toast.type === "fav") return "✨"
                    if (toast.type === "unfav") return "🫧"
                    return "💎"
                }
                font.pixelSize: toast.type === "fav" ? 20 : 18

                scale: toast.opacity > 0.8 ? 1.0 : 0.2
                Behavior on scale {
                    NumberAnimation { duration: 500; easing.type: Easing.OutBack }
                }
            }
        }

        Text {
            id: toastLabel
            color: {
                if (toast.type === "fav") return "#166534"
                if (toast.type === "unfav") return "#991B1B"
                return "#F8FAFC"
            }
            font {
                pixelSize: 14
                weight: Font.Medium
                family: "Microsoft YaHei"
            }
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    opacity: 0
    scale: opacity > 0 ? 1.0 : 0.95

    Behavior on opacity {
        NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
    }

    Behavior on scale {
        NumberAnimation { duration: 400; easing.type: Easing.OutBack }
    }

    Behavior on y {
        NumberAnimation {
            duration: 500
            easing.type: Easing.OutExpo
        }
    }

    function show(msg, type) {
        toast.message = msg
        toast.type = type || "info"

        toast.opacity = 1.0
        toast.y = parent.height - toast.height - 80
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 500
        onTriggered: {
            toast.opacity = 0
            toast.y = parent.height - toast.height - 100
        }
    }
}
