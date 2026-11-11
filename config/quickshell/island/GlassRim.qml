import QtQuick
import "."

// Directional top specular hairline gradient to give obsidian glass cards subtle elevation depth without shader cost.
Rectangle {
    property real horizontalInset: 16
    property real peakOpacity: 1.0

    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: horizontalInset
    anchors.rightMargin: horizontalInset
    height: 1
    z: 3

    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: "transparent" }
        GradientStop { position: 0.25; color: Theme.alpha(Theme.foreground, 0.085 * peakOpacity) }
        GradientStop { position: 0.50; color: Theme.alpha(Theme.foreground, 0.16 * peakOpacity) }
        GradientStop { position: 0.75; color: Theme.alpha(Theme.foreground, 0.085 * peakOpacity) }
        GradientStop { position: 1.0; color: "transparent" }
    }
}
