import QtQuick
import "."

Item {
    id: root

    property string islandStyle: "prism_blade" // "prism_blade", "orbital", "minimal_rail"
    property bool isBottom: false
    property real animProgress: 0.0
    readonly property bool isExpanded: animProgress > 0.001

    property real totalWidth: 480
    property real animatedHeight: 485
    property real cornerRadius: 26

    // Perimeter travel: while the island is morphing into the water droplet the
    // radius must follow the controller exactly, with no tween lag.
    property bool travelling: false
    property real travelRadius: 18

    // Motion blur during the trip: offset (pixels) of the ghost echoes behind
    // the body plus an overall strength (0..1) that scales their opacity.
    property real trailX: 0
    property real trailY: 0
    property real trailStrength: 0

    property color fillColor: Theme.alpha(Theme.background, 0.84)
    property color strokeColor: Theme.alpha(Theme.accent, 0.45)
    property real strokeWidth: 1.5

    width: totalWidth
    height: animatedHeight
    clip: false

    // Main Obsidian Shape with Bezel Adaptation
    Item {
        id: shapeClipContainer
        anchors.fill: parent

        // Motion blur: offset copies of the body, fading with distance, drawn
        // behind the glass body. They trail the motion sampled by IslandTravel
        // and vanish again once the body slows down.
        Repeater {
            model: 4

            Rectangle {
                required property int index
                readonly property real fraction: (index + 1) / 5

                anchors.fill: parent
                z: -1
                visible: root.trailStrength > 0.02
                color: root.fillColor
                opacity: root.trailStrength * (0.26 - index * 0.05)
                radius: bgCard.radius
                transform: Translate {
                    x: root.trailX * fraction
                    y: root.trailY * fraction
                }
            }
        }

        Rectangle {
            id: bgCard
            color: root.fillColor
            border.color: {
                if (root.isExpanded) return root.strokeColor
                if (root.islandStyle === "minimal_rail") return Theme.alpha(Theme.foreground, 0.16)
                if (root.islandStyle === "orbital") return Theme.alpha(Theme.accent, 0.55)
                return Theme.alpha(Theme.accent, 0.44)
            }
            border.width: {
                if (root.isExpanded) return root.strokeWidth
                if (root.islandStyle === "minimal_rail") return 1.0
                if (root.islandStyle === "orbital") return 1.2
                return 1.1
            }

            anchors.fill: parent

            radius: {
                if (root.travelling) return root.travelRadius
                if (root.isExpanded) return root.cornerRadius
                if (root.islandStyle === "minimal_rail") return 16
                if (root.islandStyle === "orbital") return 17
                return 11
            }

            Behavior on border.color { ColorAnimation { duration: 180 } }
            Behavior on color { ColorAnimation { duration: 180 } }
            Behavior on radius {
                enabled: !root.travelling
                NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
            }
        }
    }
}
