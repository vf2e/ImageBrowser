import QtQuick 2.15
import QtGraphicalEffects 1.15

RadialGradient {
    anchors.fill: parent
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#1A1A24" }
        GradientStop { position: 1.0; color: "#0F0F13" }
    }
}
