import QtQuick
import QtQuick.Layouts
import "."

// The hover area spans the full 44px bar height, so the pointer can travel
// from the 26px capsule down into its popup without ever leaving the trigger.
Item {
    id: root

    property color pillColor: Theme.alpha(Theme.surface, 0.88)
    property bool flat: false
    property int hPad: 12
    property int pillHeight: 26
    property int spacing: 7
    readonly property bool hovered: hover.hovered
    default property alias content: row.data

    implicitWidth: row.implicitWidth + hPad * 2
    implicitHeight: 44

    Rectangle {
        id: bg
        width: parent.width
        height: root.pillHeight
        radius: height / 2
        anchors.verticalCenter: parent.verticalCenter
        color: root.flat ? "transparent" : (root.hovered ? Theme.alpha(Theme.surface, 0.95) : root.pillColor)
        border.width: (root.flat || !root.hovered) ? 0 : 1
        border.color: root.hovered ? Theme.alpha(Theme.accent, 0.50) : "transparent"

        scale: root.flat ? (root.hovered ? 1.12 : 1.0) : (root.hovered ? 1.05 : 1.0)
        transformOrigin: Item.Center

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 160 } }
        Behavior on scale {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutBack
                easing.overshoot: 1.45
            }
        }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: root.spacing
        }
    }

    HoverHandler { id: hover }
}
