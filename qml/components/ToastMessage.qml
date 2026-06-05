import QtQuick 2.15
import QtGraphicalEffects 1.15

Rectangle {
    id: toast
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 72

    property string type: "info"
    property alias message: toastLabel.text

    visible: opacity > 0
    width: Math.min(toastLabel.implicitWidth + 40, parent ? parent.width - 48 : 500)
    height: 44
    radius: 22

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
        radius: 16
        samples: 17
        verticalOffset: 4
        color: {
            if (toast.type === "fav") return "#4022C55E"
            if (toast.type === "unfav") return "#40EF4444"
            return "#60000000"
        }
    }

    Text {
        id: toastLabel
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        color: {
            if (toast.type === "fav") return "#166534"
            if (toast.type === "unfav") return "#991B1B"
            return "#F8FAFC"
        }
        font {
            pixelSize: 14
            weight: Font.Medium
            family: "Microsoft YaHei UI"
        }
        renderType: Text.NativeRendering
    }

    opacity: 0

    Behavior on opacity {
        NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
    }

    function show(msg, type) {
        hideTimer.stop()
        toast.message = msg
        toast.type = type || "info"
        toast.opacity = 1.0
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 1800
        onTriggered: toast.opacity = 0
    }
}
