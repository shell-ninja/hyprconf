import QtQuick
import QtQuick.Layouts
import Quickshell
import "."

Item {
    id: dockItemRoot

    property var itemData: null
    property int itemIndex: 0
    property int pinnedCount: 0
    property string dockPosition: "bottom" // "bottom" | "top" | "left" | "right"
    property real iconSize: 48
    property string hoverEffect: "zoom"    // "zoom" | "lift" | "glow" | "subtle" | "none"
    property bool showTooltips: true
    property bool showIndicators: true

    width: iconSize + 16
    height: iconSize + 16
    z: isDragging ? 100 : 1

    readonly property bool isPinned: itemData ? !!itemData.isPinned : false
    readonly property bool isHovered: itemMouse.containsMouse
    readonly property bool isRunning: itemData ? !!itemData.isRunning : false
    readonly property bool isActive: itemData ? !!itemData.isActive : false
    readonly property int windowCount: itemData ? (itemData.windowCount || 0) : 0

    property bool isDragging: false
    property real dragDelta: 0

    signal itemClicked()
    signal itemRightClicked(Item visualItem)
    signal hoverStateChanged(bool hovered)
    signal reorderPinned(int fromIndex, int toIndex)

    onIsHoveredChanged: {
        dockItemRoot.hoverStateChanged(isHovered)
    }

    // Default fallback icon
    readonly property string defaultSvg: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%23" + Theme.accent.toString().replace('#', '') + "' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><rect x='3' y='3' width='18' height='18' rx='4'/><path d='m9 10 2 2 4-4'/></svg>"

    // ── GLOW BACKDROP EFFECT ────────────────────────────────────────────────
    Rectangle {
        id: glowAura
        anchors.centerIn: iconContainer
        width: iconSize * 1.3
        height: iconSize * 1.3
        radius: width / 2
        color: Theme.alpha(Theme.accent, 0.35)
        opacity: (dockItemRoot.isHovered && !dockItemRoot.isDragging && (hoverEffect === "glow" || hoverEffect === "zoom")) ? 1.0 : 0.0
        scale: dockItemRoot.isHovered ? 1.05 : 0.6
        visible: hoverEffect === "glow" || hoverEffect === "zoom"

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
    }

    // ── ICON CONTAINER & ANIMATIONS ─────────────────────────────────────────
    Item {
        id: iconContainer
        anchors.centerIn: parent
        width: iconSize
        height: iconSize

        // Transformations based on hoverEffect & dragging
        scale: {
            if (dockItemRoot.isDragging) return 1.20
            if (!dockItemRoot.isHovered) return 1.0
            if (hoverEffect === "zoom") return 1.28
            if (hoverEffect === "subtle") return 1.10
            return 1.0
        }

        transform: [
            Translate {
                id: liftTranslate
                x: {
                    if (dockItemRoot.isDragging) return 0
                    if (!dockItemRoot.isHovered || hoverEffect !== "lift") return 0
                    if (dockPosition === "left") return 8
                    if (dockPosition === "right") return -8
                    return 0
                }
                y: {
                    if (dockItemRoot.isDragging) return 0
                    if (!dockItemRoot.isHovered || hoverEffect !== "lift") return 0
                    if (dockPosition === "bottom") return -8
                    if (dockPosition === "top") return 8
                    return 0
                }

                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
                Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
            },
            Translate {
                id: dragTranslate
                x: (dockPosition === "bottom" || dockPosition === "top") ? dockItemRoot.dragDelta : 0
                y: (dockPosition === "left" || dockPosition === "right") ? dockItemRoot.dragDelta : 0
            }
        ]

        Behavior on scale {
            NumberAnimation { duration: 160; easing.type: Easing.OutBack }
        }

        // The Application Icon Image
        Image {
            id: appImg
            anchors.fill: parent
            source: itemData && itemData.icon_path ? itemData.icon_path : defaultSvg
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            asynchronous: true

            onStatusChanged: {
                if (status === Image.Error) {
                    source = defaultSvg
                }
            }
        }
    }

    // ── RUNNING / ACTIVE WINDOW INDICATOR ────────────────────────────────────
    Item {
        id: indicatorContainer
        anchors.fill: parent
        visible: showIndicators && isRunning && !isDragging

        // Indicator Pill for Bottom dock
        Rectangle {
            visible: dockPosition === "bottom"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 3
            width: isActive ? 16 : (windowCount > 1 ? 8 : 4)
            height: 4
            radius: 2
            color: isActive ? Theme.accent : Theme.alpha(Theme.foreground, 0.65)

            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
            Behavior on color { ColorAnimation { duration: 180 } }
        }

        // Indicator Pill for Top dock
        Rectangle {
            visible: dockPosition === "top"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 3
            width: isActive ? 16 : (windowCount > 1 ? 8 : 4)
            height: 4
            radius: 2
            color: isActive ? Theme.accent : Theme.alpha(Theme.foreground, 0.65)

            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
            Behavior on color { ColorAnimation { duration: 180 } }
        }

        // Indicator Pill for Left dock
        Rectangle {
            visible: dockPosition === "left"
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 3
            width: 4
            height: isActive ? 16 : (windowCount > 1 ? 8 : 4)
            radius: 2
            color: isActive ? Theme.accent : Theme.alpha(Theme.foreground, 0.65)

            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
            Behavior on color { ColorAnimation { duration: 180 } }
        }

        // Indicator Pill for Right dock
        Rectangle {
            visible: dockPosition === "right"
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 3
            width: 4
            height: isActive ? 16 : (windowCount > 1 ? 8 : 4)
            radius: 2
            color: isActive ? Theme.accent : Theme.alpha(Theme.foreground, 0.65)

            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
            Behavior on color { ColorAnimation { duration: 180 } }
        }
    }

    // ── TOOLTIP PILL ────────────────────────────────────────────────────────
    Rectangle {
        id: tooltipPill
        visible: showTooltips && dockItemRoot.isHovered && !dockItemRoot.isDragging && itemData && itemData.name
        z: 9999

        width: tooltipText.implicitWidth + 18
        height: 26
        radius: 13
        color: Theme.alpha(Theme.surface, 0.96)
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.40)

        // Accurate Positioning relative to dock orientation
        x: {
            if (dockPosition === "left") return parent.width + 12
            if (dockPosition === "right") return -width - 12
            return (parent.width - width) / 2
        }
        y: {
            if (dockPosition === "bottom") return -36
            if (dockPosition === "top") return parent.height + 10
            return (parent.height - height) / 2
        }

        opacity: dockItemRoot.isHovered && !dockItemRoot.isDragging ? 1.0 : 0.0
        scale: dockItemRoot.isHovered && !dockItemRoot.isDragging ? 1.0 : 0.80

        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: itemData ? (itemData.name || "") : ""
            color: Theme.foreground
            font.family: "Outfit"
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }
    }

    // ── INTERACTION MOUSE AREA WITH DRAG TO PLACE SUPPORT ───────────────────
    MouseArea {
        id: itemMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: dockItemRoot.isDragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        property real startX: 0
        property real startY: 0
        property bool dragActive: false
        property bool wasDragged: false

        onPressed: (mouse) => {
            wasDragged = false
            dragActive = false
            if (mouse.button === Qt.LeftButton && dockItemRoot.isPinned) {
                startX = mouse.x
                startY = mouse.y
            }
        }

        onPositionChanged: (mouse) => {
            if (pressed && (mouse.buttons & Qt.LeftButton) && dockItemRoot.isPinned) {
                var isHoriz = (dockPosition === "bottom" || dockPosition === "top")
                var delta = isHoriz ? (mouse.x - startX) : (mouse.y - startY)
                if (!dragActive && Math.abs(delta) > 6) {
                    dragActive = true
                    wasDragged = true
                    dockItemRoot.isDragging = true
                }
                if (dragActive) {
                    dockItemRoot.dragDelta = delta
                }
            }
        }

        onReleased: (mouse) => {
            if (dragActive) {
                var isHoriz = (dockPosition === "bottom" || dockPosition === "top")
                var slotSize = isHoriz ? (dockItemRoot.width + 4) : (dockItemRoot.height + 4)
                var slotShift = Math.round(dockItemRoot.dragDelta / slotSize)
                if (slotShift !== 0 && dockItemRoot.pinnedCount > 1) {
                    var newIndex = Math.max(0, Math.min(dockItemRoot.pinnedCount - 1, dockItemRoot.itemIndex + slotShift))
                    if (newIndex !== dockItemRoot.itemIndex) {
                        dockItemRoot.reorderPinned(dockItemRoot.itemIndex, newIndex)
                    }
                }
                dockItemRoot.isDragging = false
                dockItemRoot.dragDelta = 0
                dragActive = false
            }
        }

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                dockItemRoot.itemRightClicked(dockItemRoot)
            } else if (!wasDragged) {
                dockItemRoot.itemClicked()
            }
            wasDragged = false
        }
    }
}
