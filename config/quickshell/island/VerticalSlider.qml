import QtQuick
import "."

Item {
    id: root

    property string title: ""
    property int value: 50
    property int minValue: 0
    property int maxValue: 100
    property color fillColor: Theme.accent
    property string iconSvg: ""
    property bool interactive: true
    property bool isMuted: false

    signal sliderMoved(int newValue)
    signal iconClicked()

    implicitWidth: 74
    implicitHeight: 170

    // Frosted glass vertical slider track
    Rectangle {
        id: track
        anchors.fill: parent
        radius: 20
        color: Theme.alpha(Theme.surface, 0.70)
        border.color: Theme.alpha(Theme.foreground, 0.10)
        border.width: 1
        clip: true

        // Filled level indicator (grows upward from bottom)
        Rectangle {
            id: fillLevel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * Math.max(0.0, Math.min(1.0, root.value / root.maxValue))
            radius: 20
            color: root.isMuted ? Theme.muted : root.fillColor
            opacity: 0.95

            Behavior on height {
                NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
            }
            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }

        // Top percentage value badge
        Text {
            id: percentLabel
            anchors.top: parent.top
            anchors.topMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.isMuted ? "MUTE" : (root.value + "%")
            font.family: "Outfit"
            font.pixelSize: 12
            font.weight: Font.Bold
            color: (fillLevel.height >= (parent.height - 28)) ? Theme.background : Theme.foreground
            opacity: 0.95
        }

        // Mouse interaction across the vertical track
        MouseArea {
            id: trackMouse
            anchors.fill: parent
            enabled: root.interactive
            hoverEnabled: true
            preventStealing: true
            cursorShape: Qt.PointingHandCursor

            function updateFromY(mouseY) {
                var norm = 1.0 - (mouseY / track.height)
                var clamped = Math.max(0.0, Math.min(1.0, norm))
                var newVal = Math.round(clamped * (root.maxValue - root.minValue) + root.minValue)
                root.sliderMoved(newVal)
            }

            onPressed: function(mouse) { updateFromY(mouse.y) }
            onPositionChanged: function(mouse) {
                if (pressed) {
                    updateFromY(mouse.y)
                }
            }

            onWheel: function(wheel) {
                var delta = wheel.angleDelta.y > 0 ? 5 : -5
                var newVal = Math.max(root.minValue, Math.min(root.maxValue, root.value + delta))
                root.sliderMoved(newVal)
            }
        }

        WheelHandler {
            target: track
            enabled: root.interactive
            onWheel: function(event) {
                var delta = event.angleDelta.y > 0 ? 5 : -5
                var newVal = Math.max(root.minValue, Math.min(root.maxValue, root.value + delta))
                root.sliderMoved(newVal)
            }
        }

        // Bottom circular icon badge
        Rectangle {
            id: iconBadge
            z: 10
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            width: 32
            height: 32
            radius: 16
            color: iconMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.15) : "transparent"

            Image {
                anchors.centerIn: parent
                width: 18
                height: 18
                sourceSize: Qt.size(36, 36)
                source: root.iconSvg
            }

            MouseArea {
                id: iconMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.iconClicked()
            }
        }
    }
}
