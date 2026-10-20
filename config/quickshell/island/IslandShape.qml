import QtQuick
import "."

Item {
    id: root

    property string islandStyle: "capsule" // "capsule", "orbital", "split_wings", "minimal_rail"
    property bool isBottom: false
    property real animProgress: 0.0
    readonly property bool isExpanded: animProgress > 0.001

    property real totalWidth: 480
    property real animatedHeight: 485
    property real cornerRadius: 26

    property color fillColor: Theme.alpha(Theme.background, 0.96)
    property color strokeColor: Theme.alpha(Theme.accent, 0.45)
    property real strokeWidth: 1.5

    width: totalWidth
    height: animatedHeight
    clip: false

    // Main Obsidian Shape with Bezel Adaptation
    Item {
        id: shapeClipContainer
        anchors.fill: parent

        Rectangle {
            id: bgCard
            color: root.fillColor
            border.color: {
                if (root.isExpanded) return root.strokeColor
                if (root.islandStyle === "minimal_rail") return Theme.alpha(Theme.foreground, 0.16)
                if (root.islandStyle === "orbital") return Theme.alpha(Theme.accent, 0.55)
                return root.strokeColor
            }
            border.width: {
                if (root.isExpanded) return root.strokeWidth
                if (root.islandStyle === "minimal_rail") return 1.0
                if (root.islandStyle === "orbital") return 1.2
                return root.strokeWidth
            }

            anchors.fill: parent

            radius: {
                if (root.isExpanded) return root.cornerRadius
                if (root.islandStyle === "minimal_rail") return 16
                if (root.islandStyle === "orbital") return 17
                return root.cornerRadius
            }

            Behavior on border.color { ColorAnimation { duration: 180 } }
            Behavior on color { ColorAnimation { duration: 180 } }
            Behavior on radius { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        }
    }
}
