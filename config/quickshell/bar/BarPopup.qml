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
    property color surface: Theme.alpha(Theme.surface, 0.96)
    readonly property bool isFloating: (typeof bar !== "undefined" && bar && (bar.capsuleStyle === "islands" || bar.marginTop > 2))
    readonly property int effectiveFillet: isFloating ? 0 : fillet
    property int barHeight: 44
    property int edge: 12
    property int bottomRadius: 22
    property int fillet: 16
    property int padding: 18
    property int duration: 320
    readonly property int topOverlap: 1   // hides the AA seam against the bar

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
        if (!parent)
            return
        if (align === "left") {
            bodyX = edge
        } else if (align === "right") {
            bodyX = parent.width - edge - popupWidth
        } else if (trigger) {
            const p = trigger.mapToItem(parent, 0, 0)
            const cx = p.x + trigger.width / 2
            bodyX = Math.max(edge + fillet, Math.min(parent.width - edge - fillet - popupWidth, cx - popupWidth / 2))
        } else {
            bodyX = Math.max(edge + fillet, (parent.width - popupWidth) / 2)
        }
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

    x: bodyX - effectiveFillet
    y: isFloating ? ((typeof bar !== "undefined" && bar) ? (bar.marginTop + bar.barH + 6) : 48) : (barHeight - topOverlap)
    z: 20
    width: popupWidth + effectiveFillet * 2
    height: revealHeight
    visible: height > 0.5
    clip: true

    HoverHandler { id: hover }

    // Concave corner fillet, top-left (hidden when floating or flush with the left frame)
    Shape {
        x: 0
        y: popup.topOverlap
        width: popup.fillet
        height: popup.fillet
        visible: !popup.isFloating && popup.align !== "left"
        layer.enabled: true
        layer.samples: 4
        ShapePath {
            fillColor: popup.surface
            strokeWidth: -1
            PathSvg { path: "M 0 0 L " + popup.fillet + " 0 L " + popup.fillet + " " + popup.fillet + " A " + popup.fillet + " " + popup.fillet + " 0 0 0 0 0 Z" }
        }
    }

    // Concave corner fillet, top-right (hidden when floating or flush with the right frame)
    Shape {
        x: popup.width - popup.fillet
        y: popup.topOverlap
        width: popup.fillet
        height: popup.fillet
        visible: !popup.isFloating && popup.align !== "right"
        layer.enabled: true
        layer.samples: 4
        ShapePath {
            fillColor: popup.surface
            strokeWidth: -1
            PathSvg { path: "M " + popup.fillet + " 0 L 0 0 L 0 " + popup.fillet + " A " + popup.fillet + " " + popup.fillet + " 0 0 1 " + popup.fillet + " 0 Z" }
        }
    }

    Rectangle {
        id: body
        x: popup.effectiveFillet
        y: 0
        width: popup.popupWidth
        height: popup.height
        color: popup.surface
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.28)
        radius: popup.isFloating ? 16 : 0
        topLeftRadius: popup.isFloating ? 16 : 0
        topRightRadius: popup.isFloating ? 16 : 0
        bottomLeftRadius: popup.isFloating ? 16 : popup.bottomRadius
        bottomRightRadius: popup.isFloating ? 16 : popup.bottomRadius
        clip: true

        // Inner subtle glass rim at top
        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.75
            height: 1
            color: Theme.alpha(Theme.foreground, 0.12)
        }

        // Seamless fusion: covers the top 1px border so dropdown flows smoothly from the bar (non-floating only)
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            color: popup.surface
            visible: !popup.isFloating
            z: 5
        }

        ColumnLayout {
            id: contentHolder
            x: popup.padding
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
