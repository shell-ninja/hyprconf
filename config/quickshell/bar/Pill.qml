import QtQuick
import QtQuick.Layouts
import "."

Item {
    id: root

    property string capsuleStyle: (typeof bar !== "undefined" && bar && bar.capsuleStyle) ? bar.capsuleStyle : "islands"
    property color customBg: "transparent"
    property bool flat: false
    property int hPad: (typeof bar !== "undefined" && bar && bar.capsulePadding) ? bar.capsulePadding : 8
    property int pillHeight: (typeof bar !== "undefined" && bar && bar.barH) ? Math.max(22, bar.barH - 8) : 28
    property int pillRadius: (typeof bar !== "undefined" && bar && bar.capsuleRadius) ? bar.capsuleRadius : (pillHeight / 2)
    property int spacing: 7
    property bool clickable: false

    signal clicked()
    signal wheelScrolled(var wheel)

    readonly property bool hovered: hover.hovered || (mouseArea.enabled && mouseArea.containsMouse)
    readonly property bool pressed: mouseArea.enabled && mouseArea.pressed

    readonly property color fgColor: {
        if (flat) return hovered ? Theme.accent : Theme.foreground
        if (hovered && clickable) return Theme.accent
        return Theme.foreground
    }

    readonly property color currentBg: {
        if (flat) return "transparent"
        if (customBg !== "transparent") return customBg
        if (hovered && clickable) return Theme.alpha(Theme.accent, 0.15)
        return "transparent"
    }

    readonly property color currentBorder: {
        if (flat || !clickable) return "transparent"
        if (hovered) return Theme.alpha(Theme.accent, 0.35)
        return "transparent"
    }

    default property alias content: row.data

    implicitWidth: row.implicitWidth + hPad * 2
    implicitHeight: (typeof bar !== "undefined" && bar && bar.barH) ? bar.barH : 36

    Rectangle {
        id: bg
        width: parent.width
        height: root.pillHeight
        radius: Math.min(root.pillRadius, height / 2)
        anchors.verticalCenter: parent.verticalCenter
        color: root.currentBg
        border.width: (root.hovered && root.clickable && !root.flat) ? 1 : 0
        border.color: root.currentBorder

        scale: root.flat ? (root.hovered ? 1.10 : 1.0) : (root.pressed ? 0.95 : (root.hovered && root.clickable ? 1.03 : 1.0))
        transformOrigin: Item.Center

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutBack
                easing.overshoot: 1.30
            }
        }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: root.spacing
        }
    }

    HoverHandler { id: hover }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.clickable
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
        onWheel: function(wheel) {
            root.wheelScrolled(wheel)
        }
    }
}
