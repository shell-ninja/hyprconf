import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "."

// Hover panel that grows out of the top bar as one continuous shape.
// Must be a direct child of the full-window frame Item (it reads parent.width).
Item {
    id: popup

    property var trigger: null            // a Pill (needs .hovered, mapToItem)
    property string align: "center"       // "left" | "center" | "right"
    property int popupWidth: 320
    property int maxContentHeight: 540
    property color surface: (typeof bar !== "undefined" && bar) ? Theme.alpha(Theme.surface, bar.barOpacity) : Theme.alpha(Theme.surface, 0.90)
    readonly property bool isFloating: (typeof bar !== "undefined" && bar && (bar.capsuleStyle === "islands" || bar.marginTop > 2))
    property int barHeight: (typeof bar !== "undefined" && bar) ? bar.barH : 36
    property int edge: 12
    property int bottomRadius: 18
    property int fillet: 16
    property int padding: 18
    property int duration: 320
    readonly property int topOverlap: 1   // hides the AA seam against the bar

    readonly property int minScreenX: (typeof bar !== "undefined" && bar && bar.capsuleStyle === "glass") ? (bar.frameThickness + 4) : 8
    readonly property int maxScreenX: (typeof bar !== "undefined" && bar && bar.capsuleStyle === "glass") ? (parent.width - bar.frameThickness - 4) : (parent.width - 8)

    // Dynamic fillet widths based on proximity to screen boundaries
    readonly property int fL: isFloating ? 0 : ((bodyX - fillet >= minScreenX) ? fillet : 0)
    readonly property int fR: isFloating ? 0 : ((bodyX + popupWidth + fillet <= maxScreenX) ? fillet : 0)

    default property alias content: contentHolder.data

    property bool hoverOpen: true
    property bool shown: false
    property bool suppressed: false
    property real bodyX: edge

    onShownChanged: {
        if (shown) {
            reposition()
        }
    }

    readonly property bool wantOpen: (trigger ? trigger.hovered : false) || hover.hovered
    readonly property real fullHeight: Math.min(contentHolder.implicitHeight + padding * 2 + topOverlap, maxContentHeight)
    property real revealHeight: shown ? fullHeight : 0

    // Bouncy spring animation when opening, snappy clean cubic when closing
    Behavior on revealHeight {
        NumberAnimation {
            duration: popup.shown ? popup.duration : 180
            easing.type: popup.shown ? Easing.OutBack : Easing.OutCubic
            easing.overshoot: 1.30
        }
    }

    function reposition() {
        if (!parent) return
        var targetCx = parent.width / 2

        if (trigger) {
            try {
                var p = trigger.mapToItem(parent, 0, 0)
                targetCx = p.x + trigger.width / 2
            } catch(e) {
                targetCx = parent.width / 2
            }
        } else if (align === "left") {
            targetCx = minScreenX + popupWidth / 2
        } else if (align === "right") {
            targetCx = maxScreenX - popupWidth / 2
        }

        var idealBodyX = targetCx - popupWidth / 2
        bodyX = Math.max(minScreenX, Math.min(maxScreenX - popupWidth, idealBodyX))
    }

    function close() {
        shown = false
        suppressed = true
    }

    Timer {
        id: hoverIntentTimer
        interval: 180
        repeat: false
        onTriggered: {
            if (popup.hoverOpen && popup.wantOpen && !popup.suppressed) {
                popup.reposition()
                popup.shown = true
            }
        }
    }

    onWantOpenChanged: {
        if (!hoverOpen) return
        if (wantOpen) {
            closeTimer.stop()
            if (!suppressed && !shown) {
                hoverIntentTimer.restart()
            }
        } else {
            hoverIntentTimer.stop()
            suppressed = false
            closeTimer.restart()
        }
    }

    // 160ms debounce: moving between pill and panel never flickers.
    Timer {
        id: closeTimer
        interval: 160
        onTriggered: if (popup.hoverOpen && !popup.wantOpen) popup.shown = false
    }

    Shortcut {
        sequence: "Escape"
        enabled: popup.shown
        onActivated: popup.close()
    }

    x: bodyX - fL
    y: isFloating ? ((typeof bar !== "undefined" && bar) ? (bar.marginTop + bar.barH + 6) : 48) : (barHeight - topOverlap)
    z: 20
    width: popupWidth + fL + fR
    height: revealHeight
    visible: height > 0.5
    clip: true

    HoverHandler { id: hover }

    // Unified Attached Monolithic Background (Top fillets + Body in one continuous shape)
    Shape {
        id: unifiedBg
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4
        visible: !popup.isFloating

        readonly property int fL: popup.fL
        readonly property int fR: popup.fR
        readonly property int br: popup.bottomRadius
        readonly property int w: popup.popupWidth
        readonly property int h: popup.height

        // 1. Fill Path (Monolithic Dropdown Fill)
        ShapePath {
            fillColor: popup.surface
            strokeColor: "transparent"
            strokeWidth: 0

            startX: 0
            startY: 0

            PathArc {
                x: unifiedBg.fL
                y: unifiedBg.fL
                radiusX: Math.max(1, unifiedBg.fL)
                radiusY: Math.max(1, unifiedBg.fL)
                direction: PathArc.Clockwise
            }

            PathLine {
                x: unifiedBg.fL
                y: Math.max(unifiedBg.fL, unifiedBg.h - unifiedBg.br)
            }

            PathArc {
                x: unifiedBg.fL + unifiedBg.br
                y: unifiedBg.h
                radiusX: unifiedBg.br
                radiusY: unifiedBg.br
                direction: PathArc.Counterclockwise
            }

            PathLine {
                x: unifiedBg.fL + unifiedBg.w - unifiedBg.br
                y: unifiedBg.h
            }

            PathArc {
                x: unifiedBg.fL + unifiedBg.w
                y: Math.max(unifiedBg.fL, unifiedBg.h - unifiedBg.br)
                radiusX: unifiedBg.br
                radiusY: unifiedBg.br
                direction: PathArc.Counterclockwise
            }

            PathLine {
                x: unifiedBg.fL + unifiedBg.w
                y: unifiedBg.fR
            }

            PathArc {
                x: unifiedBg.fL + unifiedBg.w + unifiedBg.fR
                y: 0
                radiusX: Math.max(1, unifiedBg.fR)
                radiusY: Math.max(1, unifiedBg.fR)
                direction: PathArc.Clockwise
            }

            // Close across the top edge back to (0, 0)
            PathLine {
                x: 0
                y: 0
            }
        }

        // 2. Stroke Path (Perimeter Outline Only — Open at top for zero-seam glass attachment)
        ShapePath {
            fillColor: "transparent"
            strokeColor: Theme.alpha(Theme.accent, 0.28)
            strokeWidth: 1

            startX: 0
            startY: 0

            PathArc {
                x: unifiedBg.fL
                y: unifiedBg.fL
                radiusX: Math.max(1, unifiedBg.fL)
                radiusY: Math.max(1, unifiedBg.fL)
                direction: PathArc.Clockwise
            }

            PathLine {
                x: unifiedBg.fL
                y: Math.max(unifiedBg.fL, unifiedBg.h - unifiedBg.br)
            }

            PathArc {
                x: unifiedBg.fL + unifiedBg.br
                y: unifiedBg.h
                radiusX: unifiedBg.br
                radiusY: unifiedBg.br
                direction: PathArc.Counterclockwise
            }

            PathLine {
                x: unifiedBg.fL + unifiedBg.w - unifiedBg.br
                y: unifiedBg.h
            }

            PathArc {
                x: unifiedBg.fL + unifiedBg.w
                y: Math.max(unifiedBg.fL, unifiedBg.h - unifiedBg.br)
                radiusX: unifiedBg.br
                radiusY: unifiedBg.br
                direction: PathArc.Counterclockwise
            }

            PathLine {
                x: unifiedBg.fL + unifiedBg.w
                y: unifiedBg.fR
            }

            PathArc {
                x: unifiedBg.fL + unifiedBg.w + unifiedBg.fR
                y: 0
                radiusX: Math.max(1, unifiedBg.fR)
                radiusY: Math.max(1, unifiedBg.fR)
                direction: PathArc.Clockwise
            }
        }
    }

    Rectangle {
        id: floatingBg
        visible: popup.isFloating
        anchors.fill: parent
        radius: 16
        color: popup.surface
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.28)
    }

    Item {
        id: body
        anchors.fill: parent
        clip: true

        // Inner subtle glass rim at top (floating only)
        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: popup.popupWidth * 0.75
            height: 1
            color: Theme.alpha(Theme.foreground, 0.12)
            visible: popup.isFloating
        }

        ColumnLayout {
            id: contentHolder
            x: popup.fL + popup.padding
            y: popup.topOverlap + popup.padding
            width: popup.popupWidth - popup.padding * 2
            spacing: 10

            opacity: popup.shown ? 1 : 0
            scale: popup.shown ? 1.0 : 0.94
            transformOrigin: Item.Top

            Behavior on opacity {
                NumberAnimation {
                    duration: popup.shown ? 220 : 140
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: popup.shown ? popup.duration : 180
                    easing.type: popup.shown ? Easing.OutBack : Easing.OutCubic
                    easing.overshoot: 1.30
                }
            }
        }
    }
}
