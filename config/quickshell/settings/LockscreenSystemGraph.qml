import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

Item {
    id: root

    property var statsData: null
    property bool previewMode: false
    property bool showBackground: true

    implicitWidth: 320
    implicitHeight: 76
    width: implicitWidth
    height: implicitHeight

    // Metrics state
    property int cpuPercent: 18
    property int gpuPercent: 12
    property int ramPercent: 25

    // Rolling historical trend buffers (16 points for high-density sparkline)
    property var cpuHistory: [14, 18, 12, 22, 16, 28, 20, 24, 15, 19, 23, 17, 21, 26, 18, 20]
    property var gpuHistory: [8, 12, 10, 15, 8, 20, 14, 18, 10, 12, 16, 11, 14, 22, 15, 12]
    property var ramHistory: [25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25]

    // History shift function (always maintains fixed 16 points)
    function pushHistory(arr, val) {
        var copy = (arr && arr.length) ? arr.slice() : []
        copy.push(val)
        while (copy.length > 16) copy.shift()
        while (copy.length < 16) copy.unshift(val)
        return copy
    }

    // Whenever statsData updates (polled every 1s), advance the time buffer
    onStatsDataChanged: {
        if (!statsData) return
        var c = statsData.cpu_pct !== undefined ? statsData.cpu_pct : root.cpuPercent
        var g = statsData.gpu_pct !== undefined ? statsData.gpu_pct : root.gpuPercent
        var r = statsData.ram_pct !== undefined ? statsData.ram_pct : root.ramPercent

        root.cpuPercent = c
        root.gpuPercent = g
        root.ramPercent = r

        root.cpuHistory = pushHistory(root.cpuHistory, c)
        root.gpuHistory = pushHistory(root.gpuHistory, g)
        root.ramHistory = pushHistory(root.ramHistory, r)

        cpuCanvas.requestPaint()
        gpuCanvas.requestPaint()
        ramCanvas.requestPaint()
    }

    // Fallback/Demo 1s advancement timer if statsData is null (e.g. standalone preview)
    Timer {
        id: fallback1sTimer
        interval: 1000
        repeat: true
        running: !root.statsData || root.previewMode
        onTriggered: {
            if (root.statsData && !root.previewMode) return
            // Organic realistic random walk
            var deltaCpu = (Math.random() * 16 - 8)
            var nextCpu = Math.max(5, Math.min(85, Math.round(root.cpuPercent + deltaCpu)))

            var deltaGpu = (Math.random() * 12 - 6)
            var nextGpu = Math.max(2, Math.min(75, Math.round(root.gpuPercent + deltaGpu)))

            var deltaRam = (Math.random() * 2 - 1)
            var nextRam = Math.max(20, Math.min(45, Math.round(root.ramPercent + deltaRam)))

            root.cpuPercent = nextCpu
            root.gpuPercent = nextGpu
            root.ramPercent = nextRam

            root.cpuHistory = pushHistory(root.cpuHistory, nextCpu)
            root.gpuHistory = pushHistory(root.gpuHistory, nextGpu)
            root.ramHistory = pushHistory(root.ramHistory, nextRam)

            cpuCanvas.requestPaint()
            gpuCanvas.requestPaint()
            ramCanvas.requestPaint()
        }
    }

    // Obsidian Glass Container
    Rectangle {
        anchors.fill: parent
        radius: 16
        visible: root.showBackground
        color: Theme.alpha(Theme.surface, 0.55)
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.32)

        // Subtle specular highlight line
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            height: 1
            color: Theme.alpha(Theme.foreground, 0.12)
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        // ── 1. CPU GRAPH CELL ───────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Column {
                anchors.fill: parent
                spacing: 2

                RowLayout {
                    width: parent.width
                    Text {
                        text: "CPU"
                        color: Theme.alpha(Theme.foreground, 0.75)
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.5
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.cpuPercent + "%"
                        color: Theme.accent
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }

                Canvas {
                    id: cpuCanvas
                    width: parent.width
                    height: parent.height - 16
                    antialiasing: true

                    onPaint: {
                        var ctx = getContext("2d")
                        root.drawSparkline(ctx, width, height, root.cpuHistory, Theme.accent, Theme.alpha(Theme.accent, 0.28))
                    }
                }
            }
        }

        // Cell Divider
        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            color: Theme.alpha(Theme.foreground, 0.08)
        }

        // ── 2. GPU GRAPH CELL ───────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Column {
                anchors.fill: parent
                spacing: 2

                RowLayout {
                    width: parent.width
                    Text {
                        text: "GPU"
                        color: Theme.alpha(Theme.foreground, 0.75)
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.5
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.gpuPercent + "%"
                        color: Theme.secondary
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }

                Canvas {
                    id: gpuCanvas
                    width: parent.width
                    height: parent.height - 16
                    antialiasing: true

                    onPaint: {
                        var ctx = getContext("2d")
                        root.drawSparkline(ctx, width, height, root.gpuHistory, Theme.secondary, Theme.alpha(Theme.secondary, 0.28))
                    }
                }
            }
        }

        // Cell Divider
        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            color: Theme.alpha(Theme.foreground, 0.08)
        }

        // ── 3. RAM GRAPH CELL ───────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Column {
                anchors.fill: parent
                spacing: 2

                RowLayout {
                    width: parent.width
                    Text {
                        text: "RAM"
                        color: Theme.alpha(Theme.foreground, 0.75)
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.5
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.ramPercent + "%"
                        color: Theme.accent
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }

                Canvas {
                    id: ramCanvas
                    width: parent.width
                    height: parent.height - 16
                    antialiasing: true

                    onPaint: {
                        var ctx = getContext("2d")
                        root.drawSparkline(ctx, width, height, root.ramHistory, Theme.accent, Theme.alpha(Theme.accent, 0.25))
                    }
                }
            }
        }
    }

    // Bezier Area Sparkline Plotting Core
    function drawSparkline(ctx, w, h, points, strokeColor, fillColor) {
        if (!points || points.length < 2 || w <= 0 || h <= 0) return
        ctx.reset()
        ctx.clearRect(0, 0, w, h)

        var n = points.length
        var stepX = w / Math.max(1, n - 1)

        // 1. Subtle horizontal threshold guides
        ctx.strokeStyle = "rgba(255, 255, 255, 0.05)"
        ctx.lineWidth = 1
        ctx.beginPath()
        ctx.moveTo(0, h * 0.5)
        ctx.lineTo(w, h * 0.5)
        ctx.stroke()

        // 2. Smooth Area Gradient Fill
        ctx.beginPath()
        ctx.moveTo(0, h)
        for (var i = 0; i < n; i++) {
            var val = Math.max(0, Math.min(100, points[i]))
            var px = i * stepX
            var py = h - 2 - (val / 100.0) * (h - 6)
            if (i === 0) {
                ctx.lineTo(px, py)
            } else {
                var prevVal = Math.max(0, Math.min(100, points[i - 1]))
                var prevX = (i - 1) * stepX
                var prevY = h - 2 - (prevVal / 100.0) * (h - 6)
                var cpx = (prevX + px) / 2
                ctx.bezierCurveTo(cpx, prevY, cpx, py, px, py)
            }
        }
        ctx.lineTo(w, h)
        ctx.closePath()

        var grad = ctx.createLinearGradient(0, 0, 0, h)
        grad.addColorStop(0.0, fillColor)
        grad.addColorStop(1.0, "transparent")
        ctx.fillStyle = grad
        ctx.fill()

        // 3. Smooth Stroke Line
        ctx.beginPath()
        for (var j = 0; j < n; j++) {
            var v = Math.max(0, Math.min(100, points[j]))
            var sx = j * stepX
            var sy = h - 2 - (v / 100.0) * (h - 6)
            if (j === 0) {
                ctx.moveTo(sx, sy)
            } else {
                var pV = Math.max(0, Math.min(100, points[j - 1]))
                var pX = (j - 1) * stepX
                var pY = h - 2 - (pV / 100.0) * (h - 6)
                var midX = (pX + sx) / 2
                ctx.bezierCurveTo(midX, pY, midX, sy, sx, sy)
            }
        }
        ctx.lineWidth = 1.6
        ctx.strokeStyle = strokeColor
        ctx.stroke()

        // 4. Glowing Leading Endpoint Bead
        var endVal = Math.max(0, Math.min(100, points[n - 1]))
        var endY = h - 2 - (endVal / 100.0) * (h - 6)
        ctx.beginPath()
        ctx.arc(w - 2, endY, 2.5, 0, Math.PI * 2)
        ctx.fillStyle = strokeColor
        ctx.fill()
    }
}
