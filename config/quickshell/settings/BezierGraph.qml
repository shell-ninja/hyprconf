import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

Rectangle {
    id: root
    implicitWidth: 340
    implicitHeight: 340
    radius: 14
    color: Theme.alpha(Theme.background, 0.70)
    border.width: 1
    border.color: Theme.alpha(Theme.foreground, 0.12)
    clip: false

    property real p1x: 0.40
    property real p1y: 1.07
    property real p2x: 0.28
    property real p2y: 1.15
    property string curveName: "elegant_bounce"

    // Supported domain ranges:
    // X is time [0.0, 1.0]
    // Y is progression [-0.75, 1.75] allowing extreme recoil and overshoot bounces
    readonly property real graphMinX: 0.0
    readonly property real graphMaxX: 1.0
    readonly property real graphMinY: -0.75
    readonly property real graphMaxY: 1.75
    readonly property real spanX: graphMaxX - graphMinX
    readonly property real spanY: graphMaxY - graphMinY

    onP1xChanged: graphCanvas.requestPaint()
    onP1yChanged: graphCanvas.requestPaint()
    onP2xChanged: graphCanvas.requestPaint()
    onP2yChanged: graphCanvas.requestPaint()

    Canvas {
        id: graphCanvas
        anchors.fill: parent
        anchors.margins: 14
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            // Padding around plot area inside canvas
            var padLeft = 46
            var padBottom = 30
            var padTop = 22
            var padRight = 24

            var plotW = width - padLeft - padRight
            var plotH = height - padTop - padBottom

            // Coordinate conversion helpers:
            function toCanvasX(x) {
                return padLeft + ((x - root.graphMinX) / root.spanX) * plotW
            }
            function toCanvasY(y) {
                return (height - padBottom) - ((y - root.graphMinY) / root.spanY) * plotH
            }

            var origX = toCanvasX(0.0)
            var origY = toCanvasY(0.0)
            var endX = toCanvasX(1.0)
            var endY = toCanvasY(1.0)
            var topY = toCanvasY(root.graphMaxY)
            var botY = toCanvasY(root.graphMinY)

            // ── Background Shaded Zones ──────────────────────────────────
            // 1. Overshoot Zone (> 1.0) - Warm amber subtle tint
            ctx.fillStyle = "rgba(245, 158, 11, 0.04)"
            ctx.fillRect(origX, topY, endX - origX, endY - topY)

            // 2. Standard Unit Box [0, 1] x [0, 1] - Neutral subtle tint
            ctx.fillStyle = "rgba(255, 255, 255, 0.025)"
            ctx.fillRect(origX, endY, endX - origX, origY - endY)

            // 3. Recoil/Bounce Zone (< 0.0) - Cool blue subtle tint
            ctx.fillStyle = "rgba(59, 130, 246, 0.04)"
            ctx.fillRect(origX, origY, endX - origX, botY - origY)

            // ── Zone Badges / Watermarks ──────────────────────────────────
            ctx.font = "bold 8px Outfit, sans-serif"
            ctx.fillStyle = "rgba(245, 158, 11, 0.35)"
            ctx.textAlign = "right"
            ctx.textBaseline = "top"
            ctx.fillText("OVERSHOOT (> 1.0)", endX - 6, topY + 4)

            ctx.fillStyle = "rgba(59, 130, 246, 0.35)"
            ctx.textBaseline = "bottom"
            ctx.fillText("RECOIL (< 0.0)", endX - 6, botY - 4)

            // ── Dashed Reference Lines ────────────────────────────────────
            ctx.setLineDash([3, 3])
            ctx.strokeStyle = "rgba(255, 255, 255, 0.12)"
            ctx.lineWidth = 1

            // Y = 1.0 reference line (100% resting position)
            ctx.beginPath()
            ctx.moveTo(origX, endY)
            ctx.lineTo(endX, endY)
            ctx.stroke()

            // X = 1.0 right boundary line
            ctx.beginPath()
            ctx.moveTo(endX, botY)
            ctx.lineTo(endX, topY)
            ctx.stroke()

            // Y = 0.5 reference line
            var midY = toCanvasY(0.5)
            ctx.beginPath()
            ctx.moveTo(origX, midY)
            ctx.lineTo(endX, midY)
            ctx.stroke()

            // X = 0.5 reference line
            var midX = toCanvasX(0.5)
            ctx.beginPath()
            ctx.moveTo(midX, botY)
            ctx.lineTo(midX, topY)
            ctx.stroke()

            // Y = -0.5 reference line
            var lowY = toCanvasY(-0.5)
            ctx.beginPath()
            ctx.moveTo(origX, lowY)
            ctx.lineTo(endX, lowY)
            ctx.stroke()

            // Y = 1.5 reference line
            var highY = toCanvasY(1.5)
            ctx.beginPath()
            ctx.moveTo(origX, highY)
            ctx.lineTo(endX, highY)
            ctx.stroke()

            ctx.setLineDash([])

            // ── Axes Lines (X & Y) ────────────────────────────────────────
            ctx.strokeStyle = "rgba(255, 255, 255, 0.45)"
            ctx.lineWidth = 1.5

            // Y axis line (from bottom recoil limit to top overshoot limit + arrow)
            ctx.beginPath()
            ctx.moveTo(origX, botY)
            ctx.lineTo(origX, topY - 6)
            ctx.stroke()

            // Y Arrow (Progression)
            ctx.beginPath()
            ctx.moveTo(origX - 4, topY + 2)
            ctx.lineTo(origX, topY - 6)
            ctx.lineTo(origX + 4, topY + 2)
            ctx.stroke()

            // X axis line (along Y = 0.0 baseline, from origX - 4 to endX + 10)
            ctx.beginPath()
            ctx.moveTo(origX - 4, origY)
            ctx.lineTo(endX + 12, origY)
            ctx.stroke()

            // X Arrow (Timeline)
            ctx.beginPath()
            ctx.moveTo(endX + 4, origY - 4)
            ctx.lineTo(endX + 12, origY)
            ctx.lineTo(endX + 4, origY + 4)
            ctx.stroke()

            // ── Ticks and Values ──────────────────────────────────────────
            ctx.font = "9px Outfit, sans-serif"
            ctx.fillStyle = "rgba(255, 255, 255, 0.55)"
            ctx.textAlign = "right"
            ctx.textBaseline = "middle"

            // Y ticks: -0.5, 0.0, 0.5, 1.0, 1.5
            var yTicks = [-0.5, 0.0, 0.5, 1.0, 1.5]
            for (var i = 0; i < yTicks.length; i++) {
                var yt = yTicks[i]
                var cy = toCanvasY(yt)
                ctx.beginPath()
                ctx.moveTo(origX - 4, cy)
                ctx.lineTo(origX, cy)
                ctx.stroke()
                ctx.fillText(yt.toFixed(1), origX - 7, cy)
            }

            // X ticks: 0.5, 1.0
            ctx.textAlign = "center"
            ctx.textBaseline = "top"
            var xTicks = [0.5, 1.0]
            for (var j = 0; j < xTicks.length; j++) {
                var xt = xTicks[j]
                var cx = toCanvasX(xt)
                ctx.beginPath()
                ctx.moveTo(cx, origY)
                ctx.lineTo(cx, origY + 4)
                ctx.stroke()
                ctx.fillText(xt.toFixed(1), cx, origY + 6)
            }

            // ── Axis Labels ───────────────────────────────────────────────
            // Duration Timeline -> (bottom)
            ctx.font = "10px Outfit, sans-serif"
            ctx.fillStyle = "rgba(255, 255, 255, 0.65)"
            ctx.textAlign = "center"
            ctx.fillText("Duration Timeline ──>", origX + plotW * 0.5, origY + 18)

            // Window Position -> (left, rotated -90 deg)
            ctx.save()
            ctx.translate(padLeft - 32, origY - (origY - endY) * 0.5)
            ctx.rotate(-Math.PI / 2)
            ctx.textAlign = "center"
            ctx.fillText("Window Position ──>", 0, 0)
            ctx.restore()

            // ── Control Tangent Lines ─────────────────────────────────────
            var c1x = toCanvasX(root.p1x)
            var c1y = toCanvasY(root.p1y)
            var c2x = toCanvasX(root.p2x)
            var c2y = toCanvasY(root.p2y)

            ctx.strokeStyle = "rgba(255, 255, 255, 0.35)"
            ctx.lineWidth = 1
            // Tangent P0 -> P1
            ctx.beginPath()
            ctx.moveTo(origX, origY)
            ctx.lineTo(c1x, c1y)
            ctx.stroke()

            // Tangent P3 -> P2
            ctx.beginPath()
            ctx.moveTo(endX, endY)
            ctx.lineTo(c2x, c2y)
            ctx.stroke()

            // ── Cubic Bezier Curve ────────────────────────────────────────
            ctx.strokeStyle = Theme.accent
            ctx.lineWidth = 3
            ctx.lineCap = "round"
            ctx.beginPath()
            ctx.moveTo(origX, origY)
            ctx.bezierCurveTo(c1x, c1y, c2x, c2y, endX, endY)
            ctx.stroke()

            // ── Control Knobs ─────────────────────────────────────────────
            // P0 (0,0) - White Circle
            drawKnob(ctx, origX, origY, "#ffffff", "P₀", false)

            // P3 (1,1) - White Circle
            drawKnob(ctx, endX, endY, "#ffffff", "P₃", true)

            // P1 (p1x, p1y) - Vibrant Orange Handle
            drawKnob(ctx, c1x, c1y, "#f59e0b", "P₁", false)

            // P2 (p2x, p2y) - Vibrant Orange Handle
            drawKnob(ctx, c2x, c2y, "#f59e0b", "P₂", true)
        }

        function drawKnob(ctx, x, y, colorHex, label, labelRight) {
            ctx.save()
            ctx.fillStyle = colorHex
            ctx.strokeStyle = "#121212"
            ctx.lineWidth = 2
            ctx.beginPath()
            ctx.arc(x, y, 6, 0, Math.PI * 2)
            ctx.fill()
            ctx.stroke()

            // Label text
            ctx.font = "bold 11px Outfit, sans-serif"
            ctx.fillStyle = colorHex
            ctx.textAlign = labelRight ? "left" : "right"
            ctx.textBaseline = "middle"
            var offX = labelRight ? 10 : -10
            ctx.fillText(label, x + offX, y - 4)
            ctx.restore()
        }
    }

    // Mouse interaction for dragging P1 and P2 handles
    property int draggingKnob: 0 // 0: none, 1: P1, 2: P2

    MouseArea {
        id: graphMouse
        anchors.fill: graphCanvas
        hoverEnabled: true

        readonly property real padLeft: 46
        readonly property real padBottom: 30
        readonly property real padTop: 22
        readonly property real padRight: 24
        readonly property real plotW: width - padLeft - padRight
        readonly property real plotH: height - padTop - padBottom

        function toCanvasX(x) {
            return padLeft + ((x - root.graphMinX) / root.spanX) * plotW
        }
        function toCanvasY(y) {
            return (height - padBottom) - ((y - root.graphMinY) / root.spanY) * plotH
        }
        function fromCanvasX(cx) {
            return root.graphMinX + ((cx - padLeft) / plotW) * root.spanX
        }
        function fromCanvasY(cy) {
            return root.graphMinY + (((height - padBottom) - cy) / plotH) * root.spanY
        }

        onPressed: function(mouse) {
            var c1x = toCanvasX(root.p1x)
            var c1y = toCanvasY(root.p1y)
            var c2x = toCanvasX(root.p2x)
            var c2y = toCanvasY(root.p2y)

            var d1 = Math.hypot(mouse.x - c1x, mouse.y - c1y)
            var d2 = Math.hypot(mouse.x - c2x, mouse.y - c2y)

            if (d1 < 22) {
                root.draggingKnob = 1
            } else if (d2 < 22) {
                root.draggingKnob = 2
            } else {
                root.draggingKnob = 0
            }
        }

        onPositionChanged: function(mouse) {
            var c1x = toCanvasX(root.p1x)
            var c1y = toCanvasY(root.p1y)
            var c2x = toCanvasX(root.p2x)
            var c2y = toCanvasY(root.p2y)

            var d1 = Math.hypot(mouse.x - c1x, mouse.y - c1y)
            var d2 = Math.hypot(mouse.x - c2x, mouse.y - c2y)

            if (root.draggingKnob === 0) {
                cursorShape = (d1 < 22 || d2 < 22) ? Qt.PointingHandCursor : Qt.ArrowCursor
            } else {
                cursorShape = Qt.ClosedHandCursor
                var nx = Math.max(root.graphMinX, Math.min(root.graphMaxX, fromCanvasX(mouse.x)))
                var ny = Math.max(root.graphMinY, Math.min(root.graphMaxY, fromCanvasY(mouse.y)))
                if (root.draggingKnob === 1) {
                    root.p1x = Number(nx.toFixed(2))
                    root.p1y = Number(ny.toFixed(2))
                } else if (root.draggingKnob === 2) {
                    root.p2x = Number(nx.toFixed(2))
                    root.p2y = Number(ny.toFixed(2))
                }
            }
        }

        onReleased: {
            root.draggingKnob = 0
            cursorShape = Qt.ArrowCursor
        }
    }
}
