import QtQuick
import "."

Item {
    id: root

    property bool active: false
    property bool mirror: false
    // Wing mode: "full" (mirrored valley aaabbbccccbbbaaa from center), "left" (left wing a->b->c), "right" (right wing c->b->a)
    property string wingMode: root.mirror ? "right" : "full"
    property color barColor: Theme.accent
    property color tipColor: Theme.secondary

    // Visualizer configuration
    property int barCount: 4
    property string style: "wave" // "wave", "cava", "dots"

    // Frequency bands passed from parent (each in range 0.0 .. 1.0)
    property var cavaValues: []

    property real barW: 3.2
    property real gap: 2.4

    implicitWidth: Math.max(20, root.barCount * (root.barW + root.gap) - root.gap + 6)
    implicitHeight: 20
    width: implicitWidth
    height: 20

    // Bar state (array size matches barCount)
    property var barHeights: []
    property bool hasRealAudio: false

    function getU(i, bCount, mode) {
        if (bCount <= 1) return 0.0
        if (mode === "left") {
            return i / (bCount - 1.0)
        } else if (mode === "right") {
            return (bCount - 1.0 - i) / (bCount - 1.0)
        } else {
            var maxDist = (bCount - 1) / 2.0
            var distFromEdge = Math.min(i, bCount - 1 - i)
            return maxDist > 0 ? (distFromEdge / maxDist) : 0.0
        }
    }

    function getTierMultiplier(u) {
        if (u <= 0.35) {
            return 1.00 - 0.15 * (u / 0.35)
        } else if (u <= 0.70) {
            return 0.85 - 0.33 * ((u - 0.35) / 0.35)
        } else {
            return 0.52 - 0.24 * ((u - 0.70) / 0.30)
        }
    }

    function sampleCava(u, arr) {
        if (!arr || arr.length === 0) return 0.0
        var maxIdx = arr.length - 1
        var fIdx = Math.max(0.0, Math.min(maxIdx, u * maxIdx))
        var idx0 = Math.floor(fIdx)
        var idx1 = Math.min(maxIdx, idx0 + 1)
        var frac = fIdx - idx0
        var v0 = (arr[idx0] !== undefined) ? arr[idx0] : 0.0
        var v1 = (arr[idx1] !== undefined) ? arr[idx1] : 0.0
        return v0 * (1.0 - frac) + v1 * frac
    }

    function initBars() {
        var arr = []
        for (var i = 0; i < root.barCount; i++) {
            arr.push(3.2)
        }
        root.barHeights = arr
    }

    Component.onCompleted: root.initBars()
    onBarCountChanged: root.initBars()

    onCavaValuesChanged: {
        var sum = 0
        if (cavaValues && cavaValues.length > 0) {
            for (var i = 0; i < cavaValues.length; i++) {
                sum += (cavaValues[i] || 0.0)
            }
        }
        if (sum > 0.015) {
            root.hasRealAudio = true
            if (root.active && !animTimer.running) {
                animTimer.restart()
            }
            fallbackTimer.restart()
        }
    }

    Timer {
        id: fallbackTimer
        interval: 1200
        repeat: false
        onTriggered: {
            root.hasRealAudio = false
        }
    }

    // Canvas 2D spectrum renderer
    Canvas {
        id: vizCanvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var grad = ctx.createLinearGradient(0, height, 0, 0)
            grad.addColorStop(0.0, root.barColor)
            grad.addColorStop(1.0, root.tipColor)
            ctx.fillStyle = grad

            var bCount = root.barCount
            var bw = root.barW
            var gp = root.gap
            var totalW = bCount * bw + (bCount - 1) * gp
            var startX = (width - totalW) / 2

            for (var i = 0; i < bCount; i++) {
                var h = Math.max(3.2, Math.min(height, (root.barHeights[i] !== undefined ? root.barHeights[i] : 3.2)))
                var x = startX + i * (bw + gp)

                if (root.style === "cava") {
                    // ── CAVA SPECTRUM BARS (EQUALIZER WITH NEON PEAK CAP) ────
                    var barH = Math.max(2.5, h)
                    var topY = height - barH
                    ctx.fillStyle = grad
                    ctx.fillRect(x, topY, bw, barH)

                    // Peak line cap floating 2px above bar
                    ctx.fillStyle = root.tipColor
                    var peakY = Math.max(0, topY - 2.5)
                    ctx.fillRect(x, peakY, bw, 1.2)
                } else if (root.style === "blocks") {
                    // ── CYBER STEPPED MATRIX BLOCKS / DIGITAL VU METER ──────
                    var blockH = 2.4
                    var blockGap = 1.4
                    var step = blockH + blockGap
                    var numBlocks = Math.max(1, Math.floor(h / step))
                    for (var b = 0; b < numBlocks; b++) {
                        var blockY = height - (b + 1) * step + blockGap
                        ctx.fillStyle = (b >= numBlocks - 1) ? root.tipColor : root.barColor
                        ctx.fillRect(x, blockY, bw, blockH)
                    }
                } else if (root.style === "hairline") {
                    // ── ULTRA-SLIM SWISS PRECISION HAIRLINE BARS ─────────────
                    var hlH = Math.max(2.0, h)
                    var hlY = (height - hlH) / 2
                    ctx.fillStyle = grad
                    ctx.fillRect(x + (bw - 1.5) / 2, hlY, 1.5, hlH)
                } else if (root.style === "dots") {
                    // ── FLOATING AUDIO BEADS / DOTS ─────────────────────────
                    ctx.fillStyle = grad
                    var dotR = bw / 2
                    var numDots = Math.max(1, Math.floor(h / (bw + 2)))
                    for (var d = 0; d < numDots; d++) {
                        var dotY = height - (d + 1) * (bw + 2) + 1
                        ctx.beginPath()
                        ctx.arc(x + dotR, dotY + dotR, dotR, 0, 2 * Math.PI)
                        ctx.fill()
                    }
                } else {
                    // ── HARMONIC ORGANIC CAPSULE WAVE (DEFAULT) ──────────────
                    ctx.fillStyle = grad
                    var y = (height - h) / 2
                    var r = bw / 2

                    if (h <= bw) {
                        ctx.beginPath()
                        ctx.arc(x + r, y + r, r, 0, 2 * Math.PI)
                        ctx.fill()
                    } else {
                        ctx.beginPath()
                        ctx.moveTo(x + r, y)
                        ctx.lineTo(x + bw - r, y)
                        ctx.arcTo(x + bw, y, x + bw, y + r, r)
                        ctx.lineTo(x + bw, y + h - r)
                        ctx.arcTo(x + bw, y + h, x + bw - r, y + h, r)
                        ctx.lineTo(x + r, y + h)
                        ctx.arcTo(x, y + h, x, y + h - r, r)
                        ctx.lineTo(x, y + r)
                        ctx.arcTo(x, y, x + r, y, r)
                        ctx.closePath()
                        ctx.fill()
                    }
                }
            }
        }
    }

    // 30fps animation loop with harmonic audio physics (stops completely when silent to save CPU)
    Timer {
        id: animTimer
        interval: 33
        repeat: true
        running: root.active && (root.hasRealAudio || (root.barHeights.length > 0 && root.barHeights[0] > 3.3))

        onTriggered: {
            var minH = 3.2
            var maxH = root.height - 2.0
            var bCount = root.barCount
            var updated = []

            if (root.active && root.hasRealAudio && root.cavaValues && root.cavaValues.length > 0) {
                // Real audio frequency sync from Cava with aaabbbccccbbbaaa symmetrical envelope
                for (var i = 0; i < bCount; i++) {
                    var u = root.getU(i, bCount, root.wingMode)
                    var tier = root.getTierMultiplier(u)
                    var rawVal = root.sampleCava(u, root.cavaValues)

                    // Boost responsiveness with slight non-linear curve for punchiness
                    var curved = Math.pow(Math.min(1.0, rawVal * 1.35), 0.85)
                    var effectiveRatio = Math.max(0.04 * tier, curved * tier)
                    var tgtH = minH + (maxH - minH) * effectiveRatio
                    var curH = (i < root.barHeights.length) ? root.barHeights[i] : minH

                    // Snappy attack on volume increases (0.68), smooth decay on drops (0.28)
                    if (tgtH > curH) {
                        curH += (tgtH - curH) * 0.68
                    } else {
                        curH += (tgtH - curH) * 0.28
                    }
                    updated.push(curH)
                }
                root.barHeights = updated
            } else {
                // Smooth decay to rest dots (NO PHANTOM SINE WAVE WHEN SILENT!)
                var isStillMoving = false
                for (var k = 0; k < bCount; k++) {
                    var c = (k < root.barHeights.length) ? root.barHeights[k] : minH
                    var nextH = c + (minH - c) * 0.25
                    if (Math.abs(nextH - minH) > 0.1) isStillMoving = true
                    updated.push(nextH)
                }
                root.barHeights = updated
                if (!isStillMoving && (!root.hasRealAudio || !root.active)) {
                    animTimer.stop()
                }
            }

            vizCanvas.requestPaint()
        }
    }

    onActiveChanged: {
        if (active) {
            animTimer.restart()
        }
    }
}
