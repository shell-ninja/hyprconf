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
    property color surface: Theme.background
    property int barHeight: 44
    property int edge: 12
    property int bottomRadius: 22
    property int fillet: 16
    property int padding: 18
    property int duration: 320
    readonly property int topOverlap: 1   // hides the AA seam against the bar

    default property alias content: contentHolder.data

    property bool shown: false
    property bool suppressed: false
    property real bodyX: edge

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
        if (!trigger || !parent)
            return
        const p = trigger.mapToItem(parent, 0, 0)
        const cx = p.x + trigger.width / 2
        if (align === "left")
            bodyX = edge
        else if (align === "right")
            bodyX = parent.width - edge - popupWidth
        else
            bodyX = Math.max(edge + fillet, Math.min(parent.width - edge - fillet - popupWidth, cx - popupWidth / 2))
    }

    function close() {
        shown = false
        suppressed = true
    }

    onWantOpenChanged: {
        if (wantOpen) {
            closeTimer.stop()
            if (!suppressed) {
                reposition()
                shown = true
            }
        } else {
            suppressed = false
            closeTimer.restart()
        }
    }

    // 80ms debounce: moving between pill and panel never flickers.
    Timer {
        id: closeTimer
        interval: 80
        onTriggered: if (!popup.wantOpen) popup.shown = false
    }

    x: bodyX - fillet
    y: barHeight - topOverlap
    z: 20
    width: popupWidth + fillet * 2
    height: revealHeight
    visible: height > 0.5
    clip: true

    HoverHandler { id: hover }

    // Concave corner fillet, top-left (hidden when the panel is flush with the left frame)
    Shape {
        x: 0
        y: popup.topOverlap
        width: popup.fillet
        height: popup.fillet
        visible: popup.align !== "left"
        layer.enabled: true
        layer.samples: 4
        ShapePath {
            fillColor: popup.surface
            strokeWidth: -1
            PathSvg { path: "M 0 0 L " + popup.fillet + " 0 L " + popup.fillet + " " + popup.fillet + " A " + popup.fillet + " " + popup.fillet + " 0 0 0 0 0 Z" }
        }
    }

    // Concave corner fillet, top-right (hidden when flush with the right frame)
    Shape {
        x: popup.width - popup.fillet
        y: popup.topOverlap
        width: popup.fillet
        height: popup.fillet
        visible: popup.align !== "right"
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
        x: popup.fillet
        y: 0
        width: popup.popupWidth
        height: popup.height
        color: popup.surface
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.30)
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: popup.bottomRadius
        bottomRightRadius: popup.bottomRadius
        clip: true

        // Seamless fusion: covers the top 1px border so dropdown flows smoothly from the bar
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            color: popup.surface
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
