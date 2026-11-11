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
    property real pointerAxisPos: -1
    property bool pointerActive: false
    property real containerOrigin: 0

    readonly property bool isHorizDock: dockPosition === "bottom" || dockPosition === "top"
    readonly property real itemAxisCenter: containerOrigin + (isHorizDock ? (x + width * 0.5) : (y + height * 0.5))
    readonly property real parabolicProximity: {
        if (hoverEffect !== "zoom" || isDragging || !pointerActive || pointerAxisPos < 0) return 0.0
        var reach = iconSize * 2.25
        var dist = Math.abs(pointerAxisPos - itemAxisCenter)
        if (dist >= reach) return 0.0
        var norm = 1.0 - (dist / reach) * (dist / reach)
        return norm * norm
    }

    width: iconSize + 16
    height: iconSize + 16
    z: isDragging ? 100 : (isHovered ? 30 : (parabolicProximity > 0.05 ? 10 : 1))

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
        width: iconSize * 1.24
        height: iconSize * 1.24
        radius: iconSize * 0.34
        color: Theme.alpha(Theme.accent, 0.20)
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.38)
        opacity: (dockItemRoot.isHovered && !dockItemRoot.isDragging && (hoverEffect === "glow" || hoverEffect === "zoom")) ? 1.0 : 0.0
        scale: dockItemRoot.isHovered ? 1.04 : 0.72
        visible: hoverEffect === "glow" || hoverEffect === "zoom"

        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
    }

    // ── ICON CONTAINER & ANIMATIONS ─────────────────────────────────────────
    Item {
        id: iconContainer
        anchors.centerIn: parent
        width: iconSize
        height: iconSize

        // Transformations based on hoverEffect, parabolic neighbor wave & dragging/press
        scale: {
            if (dockItemRoot.isDragging) return 1.18
            if (itemMouse.pressed) return 0.92
            if (hoverEffect === "zoom") {
                var p = dockItemRoot.isHovered ? 1.0 : dockItemRoot.parabolicProximity
                return 1.0 + 0.30 * p
            }
            if (!dockItemRoot.isHovered) return 1.0
            if (hoverEffect === "subtle") return 1.10
            return 1.0
        }

        transform: [
            Translate {
                id: liftTranslate
                x: {
                    if (dockItemRoot.isDragging) return 0
                    var shift = 0
                    if (hoverEffect === "zoom") {
                        shift = 7.0 * (dockItemRoot.isHovered ? 1.0 : dockItemRoot.parabolicProximity)
                    } else if (dockItemRoot.isHovered && hoverEffect === "lift") {
                        shift = 8.0
                    }
                    if (shift <= 0) return 0
                    if (dockPosition === "left") return shift
                    if (dockPosition === "right") return -shift
                    return 0
                }
                y: {
                    if (dockItemRoot.isDragging) return 0
                    var shift = 0
                    if (hoverEffect === "zoom") {
                        shift = 7.0 * (dockItemRoot.isHovered ? 1.0 : dockItemRoot.parabolicProximity)
                    } else if (dockItemRoot.isHovered && hoverEffect === "lift") {
                        shift = 8.0
                    }
                    if (shift <= 0) return 0
                    if (dockPosition === "bottom") return -shift
                    if (dockPosition === "top") return shift
                    return 0
                }

                Behavior on x { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
            },
            Translate {
                id: dragTranslate
                x: (dockPosition === "bottom" || dockPosition === "top") ? dockItemRoot.dragDelta : 0
                y: (dockPosition === "left" || dockPosition === "right") ? dockItemRoot.dragDelta : 0
            }
        ]

        Behavior on scale {
            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
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

    // ── RUNNING / ACTIVE WINDOW INDICATOR (UNIFIED MULTI-INSTANCE DOTS) ─────
    Grid {
        id: indicatorContainer
        visible: showIndicators && isRunning && !isDragging
        readonly property bool isHoriz: dockPosition === "bottom" || dockPosition === "top"
        columns: isHoriz ? 4 : 1
        spacing: 3

        anchors.horizontalCenter: isHoriz ? parent.horizontalCenter : undefined
        anchors.verticalCenter: !isHoriz ? parent.verticalCenter : undefined
        anchors.bottom: dockPosition === "bottom" ? parent.bottom : undefined
        anchors.bottomMargin: dockPosition === "bottom" ? 3 : 0
        anchors.top: dockPosition === "top" ? parent.top : undefined
        anchors.topMargin: dockPosition === "top" ? 3 : 0
        anchors.left: dockPosition === "left" ? parent.left : undefined
        anchors.leftMargin: dockPosition === "left" ? 3 : 0
        anchors.right: dockPosition === "right" ? parent.right : undefined
        anchors.rightMargin: dockPosition === "right" ? 3 : 0

        Repeater {
            model: Math.min(3, Math.max(1, dockItemRoot.windowCount))

            delegate: Rectangle {
                required property int index
                readonly property bool isPrimaryDot: index === 0
                readonly property bool isHorizDot: indicatorContainer.isHoriz
                width: isHorizDot ? ((isPrimaryDot && dockItemRoot.isActive) ? 16 : 5) : 4
                height: !isHorizDot ? ((isPrimaryDot && dockItemRoot.isActive) ? 16 : 5) : 4
                radius: 2
                color: isPrimaryDot
                    ? (dockItemRoot.isActive ? Theme.accent : Theme.alpha(Theme.foreground, 0.78))
                    : (dockItemRoot.isActive ? Theme.tertiary : Theme.alpha(Theme.foreground, 0.45))

                // Soft luminous halo behind active app indicator pill
                Rectangle {
                    visible: isPrimaryDot && dockItemRoot.isActive
                    anchors.centerIn: parent
                    width: parent.width + 6
                    height: parent.height + 4
                    radius: height / 2
                    color: Theme.alpha(Theme.accent, 0.28)
                    z: -1
                }

                Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 180 } }
            }
        }
    }

    // ── CONTEXTUAL HOVER PEEK TOOLTIP (APP + OPEN WINDOWS BADGE) ────────────
    Rectangle {
        id: tooltipPill
        visible: showTooltips && dockItemRoot.isHovered && !dockItemRoot.isDragging && itemData && itemData.name
        z: 9999

        readonly property var peekWindows: (itemData && itemData.windows) ? itemData.windows.slice(0, 3) : []
        readonly property int extraCount: (itemData && itemData.windows && itemData.windows.length > 3) ? (itemData.windows.length - 3) : 0

        width: Math.max(tooltipHeaderRow.implicitWidth, peekCol.implicitWidth) + 22
        height: peekMainCol.implicitHeight + 14
        radius: 12
        clip: true
        color: Theme.glassElevated
        border.width: 1
        border.color: Theme.alpha(Theme.foreground, 0.14)

        // Specular top rim on floating tooltip pill
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.50; color: Theme.alpha(Theme.foreground, 0.22) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // Accurate Positioning relative to dock orientation
        x: {
            if (dockPosition === "left") return parent.width + 14
            if (dockPosition === "right") return -width - 14
            return (parent.width - width) / 2
        }
        y: {
            if (dockPosition === "bottom") return -height - 14
            if (dockPosition === "top") return parent.height + 14
            return (parent.height - height) / 2
        }

        opacity: dockItemRoot.isHovered && !dockItemRoot.isDragging ? 1.0 : 0.0
        scale: dockItemRoot.isHovered && !dockItemRoot.isDragging ? 1.0 : 0.85

        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

        Column {
            id: peekMainCol
            anchors.centerIn: parent
            spacing: 5

            // App Name + Running Window Count Badge
            Row {
                id: tooltipHeaderRow
                spacing: 6

                Text {
                    id: tooltipText
                    anchors.verticalCenter: parent.verticalCenter
                    text: itemData ? (itemData.name || "") : ""
                    color: Theme.foreground
                    font.family: "Outfit"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    visible: dockItemRoot.windowCount > 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: winBadgeTxt.implicitWidth + 10
                    height: 15
                    radius: 7.5
                    color: Theme.alpha(Theme.primary, 0.22)
                    border.width: 1
                    border.color: Theme.alpha(Theme.primary, 0.45)

                    Text {
                        id: winBadgeTxt
                        anchors.centerIn: parent
                        text: dockItemRoot.windowCount + (dockItemRoot.windowCount === 1 ? " win" : " wins")
                        font.family: "Outfit"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: Theme.primary
                    }
                }
            }

            // Up to 3 Running Windows Preview
            Column {
                id: peekCol
                visible: tooltipPill.peekWindows.length > 0
                spacing: 3

                Repeater {
                    model: tooltipPill.peekWindows
                    delegate: Row {
                        required property var modelData
                        spacing: 5

                        Rectangle {
                            width: 5
                            height: 5
                            radius: 2.5
                            anchors.verticalCenter: parent.verticalCenter
                            color: (modelData && modelData.activated) ? Theme.primary : Theme.alpha(Theme.foreground, 0.38)
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: (modelData && modelData.title) ? modelData.title : (itemData ? itemData.name : "")
                            font.family: "Outfit"
                            font.pixelSize: 10
                            color: (modelData && modelData.activated) ? Theme.foreground : Theme.alpha(Theme.foreground, 0.72)
                            elide: Text.ElideRight
                            width: Math.min(160, implicitWidth)
                        }

                        Text {
                            visible: modelData && modelData.workspace && modelData.workspace > 0
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData ? ("WS" + modelData.workspace) : ""
                            font.family: "Outfit"
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            color: Theme.tertiary
                        }
                    }
                }

                Text {
                    visible: tooltipPill.extraCount > 0
                    text: "+" + tooltipPill.extraCount + " more open"
                    font.family: "Outfit"
                    font.pixelSize: 9
                    color: Theme.alpha(Theme.foreground, 0.55)
                }
            }
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
