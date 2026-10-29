import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root

    implicitWidth: 444
    implicitHeight: 496

    property bool active: false
    property bool showingNetworkDetail: false
    property alias networkDetailPage: networkDetailPage
    signal backClicked()
    signal pageDotClicked(int pageIndex)
    signal openNetworkDetail()

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string arrowLeftSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>')
    readonly property string cpuSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="4" width="16" height="16" rx="2"/><rect x="9" y="9" width="6" height="6"/><line x1="9" y1="1" x2="9" y2="4"/><line x1="15" y1="1" x2="15" y2="4"/><line x1="9" y1="20" x2="9" y2="23"/><line x1="15" y1="20" x2="15" y2="23"/><line x1="20" y1="9" x2="23" y2="9"/><line x1="20" y1="14" x2="23" y2="14"/><line x1="1" y1="9" x2="4" y2="9"/><line x1="1" y1="14" x2="4" y2="14"/></svg>')
    readonly property string ramSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.primary + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 19v-3"/><path d="M10 19v-3"/><path d="M14 19v-3"/><path d="M18 19v-3"/><rect x="2" y="6" width="20" height="9" rx="1"/></svg>')
    readonly property string gpuSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="8" cy="12" r="2.5"/><circle cx="16" cy="12" r="2.5"/><line x1="5" y1="18" x2="5" y2="20"/><line x1="19" y1="18" x2="19" y2="20"/></svg>')
    readonly property string netSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>')
    readonly property string downSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#06b6d4" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="7 13 12 18 17 13"/><line x1="12" y1="6" x2="12" y2="18"/></svg>')
    readonly property string upSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="17 11 12 6 7 11"/><line x1="12" y1="18" x2="12" y2="6"/></svg>')
    readonly property string tempSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 14.76V3.5a2.5 2.5 0 0 0-5 0v11.26a4.5 4.5 0 1 0 5 0z"/></svg>')
    readonly property string chevronRightSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 18 15 12 9 6"/></svg>')

    // ── LIVE METRIC STATES ───────────────────────────────────────────────────
    property int cpuPct: 0
    property var cpuCores: [0, 0, 0, 0, 0, 0, 0, 0]
    property int cpuTemp: 45

    property string gpuName: "GPU"
    property int gpuLoad: 0
    property int gpuTemp: 45
    property string gpuMem: ""
    property string gpuType: "none"

    property real ramUsedGb: 0.0
    property real ramTotalGb: 16.0
    property int ramPct: 0
    property string ramStr: "0.0 GB / 0.0 GB (0%)"

    property string netDownStr: "0 B/s"
    property string netUpStr: "0 B/s"
    property real netDownKb: 0.0
    property real netUpKb: 0.0

    // History arrays for live graph (max 30 points)
    property var cpuHistory: []
    property var ramHistory: []
    property var gpuHistory: []
    property var netHistory: []

    function updateMetrics(data) {
        if (!data) return
        if (data.cpu_pct !== undefined) root.cpuPct = data.cpu_pct
        if (data.cpu_cores && Array.isArray(data.cpu_cores)) root.cpuCores = data.cpu_cores
        if (data.cpu_temp !== undefined) root.cpuTemp = data.cpu_temp
        if (data.gpu_name !== undefined) root.gpuName = data.gpu_name
        if (data.gpu_load !== undefined) root.gpuLoad = data.gpu_load
        if (data.gpu_temp !== undefined) root.gpuTemp = data.gpu_temp
        if (data.gpu_mem !== undefined) root.gpuMem = data.gpu_mem
        if (data.gpu_type !== undefined) root.gpuType = data.gpu_type
        if (data.ram_used_gb !== undefined) root.ramUsedGb = data.ram_used_gb
        if (data.ram_total_gb !== undefined) root.ramTotalGb = data.ram_total_gb
        if (data.ram_pct !== undefined) root.ramPct = data.ram_pct
        if (data.ram_str !== undefined) root.ramStr = data.ram_str
        if (data.net_down_str !== undefined) root.netDownStr = data.net_down_str
        if (data.net_up_str !== undefined) root.netUpStr = data.net_up_str
        if (data.net_down_kb !== undefined) root.netDownKb = data.net_down_kb
        if (data.net_up_kb !== undefined) root.netUpKb = data.net_up_kb

        // Append to history
        var ch = root.cpuHistory.slice(0)
        ch.push(root.cpuPct)
        if (ch.length > 30) ch.shift()
        root.cpuHistory = ch

        var rh = root.ramHistory.slice(0)
        rh.push(root.ramPct)
        if (rh.length > 30) rh.shift()
        root.ramHistory = rh

        var gh = root.gpuHistory.slice(0)
        gh.push(root.gpuLoad)
        if (gh.length > 30) gh.shift()
        root.gpuHistory = gh

        var nh = root.netHistory.slice(0)
        var netVal = Math.min(100, Math.log10(Math.max(1, root.netDownKb)) * 25)
        nh.push(netVal)
        if (nh.length > 30) nh.shift()
        root.netHistory = nh

        liveGraphCanvas.requestPaint()
    }

    // ── CONTINUOUS STATS PROCESS ─────────────────────────────────────────────
    Process {
        id: monitorProc
        command: ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/island-monitor.py"]
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var parsed = JSON.parse(text.trim())
                    root.updateMetrics(parsed)
                } catch(e) {}
            }
        }
    }

    Timer {
        id: pollTimer
        interval: 1000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: {
            if (!monitorProc.running) {
                monitorProc.running = true
            }
        }
    }

    onActiveChanged: {
        if (!root.active) {
            root.showingNetworkDetail = false
        }
        if (root.active && !monitorProc.running) {
            monitorProc.running = true
        }
    }

    // ── MAIN STATUS VIEW (PAGE 3: SYSTEM INFO) ────────────────────────────────
    Column {
        id: statusMainView
        anchors.fill: parent
        spacing: 8
        visible: opacity > 0.001
        opacity: root.showingNetworkDetail ? 0.0 : 1.0
        x: root.showingNetworkDetail ? -28 : 0
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        // ── 1. HEADER ROW ────────────────────────────────────────────────────
        RowLayout {
            width: parent.width
            height: 30
            spacing: 8

            // Left: Back button to return to Page 1 (Home Page)
            Rectangle {
                width: 30
                height: 30
                radius: 15
                color: backMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.16) : Theme.alpha(Theme.surface, 0.65)
                border.width: 1
                border.color: backMouse.containsMouse ? Theme.alpha(Theme.accent, 0.45) : Theme.alpha(Theme.foreground, 0.12)
                scale: backMouse.pressed ? 0.94 : (backMouse.containsMouse ? 1.05 : 1.0)
                Behavior on scale { NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 120 } }

                Image {
                    anchors.centerIn: parent
                    width: 13
                    height: 13
                    source: root.arrowLeftSvg
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backClicked()
                }
            }

            // Title & Pulsing Live Indicator
            Row {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 7

                Text {
                    text: "SYSTEM METRICS"
                    font.family: "Outfit"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    font.letterSpacing: 1.1
                    color: Theme.foreground
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: 7
                    height: 7
                    radius: 3.5
                    color: Theme.accent
                    anchors.verticalCenter: parent.verticalCenter

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: root.active
                        NumberAnimation { to: 0.3; duration: 800; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                    }
                }
            }

            // Right: Dual Temp Badges (CPU & GPU)
            Row {
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                // CPU Temp
                Rectangle {
                    height: 24
                    width: cpuTempRow.width + 12
                    radius: 12
                    readonly property color cColor: root.cpuTemp >= 80 ? Theme.error : (root.cpuTemp >= 65 ? "#f59e0b" : Theme.accent)
                    color: Theme.alpha(cColor, 0.16)
                    border.width: 1
                    border.color: Theme.alpha(cColor, 0.40)

                    Row {
                        id: cpuTempRow
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "CPU " + root.cpuTemp + "°C"
                            font.family: "Outfit"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: parent.parent.cColor
                        }
                    }
                }

                // GPU Temp
                Rectangle {
                    height: 24
                    width: gpuTempRow.width + 12
                    radius: 12
                    readonly property color gColor: root.gpuTemp >= 80 ? Theme.error : (root.gpuTemp >= 65 ? "#f59e0b" : "#f59e0b")
                    color: Theme.alpha(gColor, 0.16)
                    border.width: 1
                    border.color: Theme.alpha(gColor, 0.40)

                    Row {
                        id: gpuTempRow
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "GPU " + root.gpuTemp + "°C"
                            font.family: "Outfit"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: parent.parent.gColor
                        }
                    }
                }
            }
        }

        // ── 2. HERO CARD: LIVE SMOOTH BEZIER GRAPH (CPU, RAM, GPU, NET) ───────
        Rectangle {
            id: graphCard
            width: parent.width
            height: 114
            radius: 14
            color: Theme.alpha(Theme.surface, 0.55)
            border.width: 1
            border.color: Theme.alpha(Theme.foreground, 0.12)
            clip: true

            // Top Legend Row
            Row {
                anchors.top: parent.top
                anchors.topMargin: 6
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 10
                spacing: 12

                // CPU Legend
                Row {
                    spacing: 4
                    Rectangle { width: 7; height: 7; radius: 3.5; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: "CPU " + root.cpuPct + "%"
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Theme.foreground
                    }
                }

                // RAM Legend
                Row {
                    spacing: 4
                    Rectangle { width: 7; height: 7; radius: 3.5; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: "RAM " + root.ramPct + "%"
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Theme.foreground
                    }
                }

                // GPU Legend
                Row {
                    spacing: 4
                    Rectangle { width: 7; height: 7; radius: 3.5; color: "#f59e0b"; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: "GPU " + root.gpuLoad + "%"
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Theme.foreground
                    }
                }

                // Net Legend
                Row {
                    spacing: 4
                    Rectangle { width: 7; height: 7; radius: 3.5; color: "#06b6d4"; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: "NET " + root.netDownStr
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Theme.foreground
                    }
                }
            }

            // Canvas Graph Rendering
            Canvas {
                id: liveGraphCanvas
                anchors.top: parent.top
                anchors.topMargin: 24
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.right: parent.right
                anchors.rightMargin: 6

                onPaint: {
                    var ctx = getContext("2d")
                    var w = width
                    var h = height

                    ctx.clearRect(0, 0, w, h)

                    // Horizontal grid guidelines
                    ctx.strokeStyle = "rgba(255, 255, 255, 0.05)"
                    ctx.lineWidth = 1
                    for (var g = 1; g < 4; g++) {
                        var gy = h * (g / 4.0)
                        ctx.beginPath()
                        ctx.moveTo(0, gy)
                        ctx.lineTo(w, gy)
                        ctx.stroke()
                    }

                    function drawSeries(points, strokeColor, fillColor) {
                        if (!points || points.length < 2) return
                        var step = w / 29.0
                        var startX = w - ((points.length - 1) * step)

                        // 1. Draw fill polygon
                        ctx.beginPath()
                        ctx.moveTo(startX, h)
                        for (var i = 0; i < points.length; i++) {
                            var px = startX + i * step
                            var py = h - (h * (Math.max(0, Math.min(100, points[i])) / 100.0))
                            if (i === 0) {
                                ctx.lineTo(px, py)
                            } else {
                                var prevX = startX + (i - 1) * step
                                var prevY = h - (h * (Math.max(0, Math.min(100, points[i - 1])) / 100.0))
                                var cpX = (prevX + px) / 2
                                ctx.bezierCurveTo(cpX, prevY, cpX, py, px, py)
                            }
                        }
                        ctx.lineTo(w, h)
                        ctx.closePath()

                        var grad = ctx.createLinearGradient(0, 0, 0, h)
                        grad.addColorStop(0, fillColor)
                        grad.addColorStop(1, "rgba(0, 0, 0, 0.0)")
                        ctx.fillStyle = grad
                        ctx.fill()

                        // 2. Draw line
                        ctx.beginPath()
                        for (var j = 0; j < points.length; j++) {
                            var sx = startX + j * step
                            var sy = h - (h * (Math.max(0, Math.min(100, points[j])) / 100.0))
                            if (j === 0) {
                                ctx.moveTo(sx, sy)
                            } else {
                                var ppx = startX + (j - 1) * step
                                var ppy = h - (h * (Math.max(0, Math.min(100, points[j - 1])) / 100.0))
                                var cpx = (ppx + sx) / 2
                                ctx.bezierCurveTo(cpx, ppy, cpx, sy, sx, sy)
                            }
                        }
                        ctx.strokeStyle = strokeColor
                        ctx.lineWidth = 1.8
                        ctx.stroke()
                    }

                    // Render Net (cyan)
                    drawSeries(root.netHistory, "#06b6d4", "rgba(6, 182, 212, 0.16)")
                    // Render GPU (amber)
                    drawSeries(root.gpuHistory, "#f59e0b", "rgba(245, 158, 11, 0.18)")
                    // Render RAM (violet)
                    drawSeries(root.ramHistory, Theme.primary, "rgba(172, 103, 228, 0.20)")
                    // Render CPU (accent green)
                    drawSeries(root.cpuHistory, Theme.accent, "rgba(16, 185, 129, 0.28)")
                }
            }
        }

        // ── 3. HARDWARE CARDS: ROW 1 (RAM & GPU) ─────────────────────────────
        RowLayout {
            width: parent.width
            height: 64
            spacing: 8

            // Left: RAM Card (Usage / Total format)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: Theme.alpha(Theme.surface, 0.55)
                border.width: 1
                border.color: Theme.alpha(Theme.foreground, 0.12)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 2

                    Row {
                        spacing: 5
                        Image { width: 12; height: 12; source: root.ramSvg; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: "Memory (RAM)"
                            font.family: "Outfit"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: Theme.muted
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        text: root.ramStr
                        font.family: "Outfit"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: Theme.foreground
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 4
                        radius: 2
                        color: Theme.alpha(Theme.foreground, 0.12)
                        clip: true

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            radius: 2
                            width: parent.width * Math.max(0.0, Math.min(1.0, root.ramPct / 100.0))
                            color: Theme.primary
                            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            // Right: GPU Status Card
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: Theme.alpha(Theme.surface, 0.55)
                border.width: 1
                border.color: Theme.alpha(Theme.foreground, 0.12)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 2

                    Row {
                        spacing: 5
                        Image { width: 12; height: 12; source: root.gpuSvg; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: root.gpuName
                            font.family: "Outfit"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: Theme.muted
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: root.gpuLoad + "% Load"
                            font.family: "Outfit"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: "#f59e0b"
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: root.gpuMem
                            font.family: "Outfit"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: Theme.muted
                            visible: root.gpuMem.length > 0
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 4
                        radius: 2
                        color: Theme.alpha(Theme.foreground, 0.12)
                        clip: true

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            radius: 2
                            width: parent.width * Math.max(0.0, Math.min(1.0, root.gpuLoad / 100.0))
                            color: "#f59e0b"
                            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }
        }

        // ── 4. CLICKABLE NETWORK SECTION (OPENS INDIVIDUAL APPS PAGE) ─────────
        Rectangle {
            id: netCard
            width: parent.width
            height: 48
            radius: 12
            color: netCardMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.14) : Theme.alpha(Theme.surface, 0.55)
            border.width: 1
            border.color: netCardMouse.containsMouse ? Theme.alpha("#06b6d4", 0.55) : Theme.alpha(Theme.foreground, 0.12)
            scale: netCardMouse.pressed ? 0.98 : (netCardMouse.containsMouse ? 1.01 : 1.0)
            Behavior on scale { NumberAnimation { duration: 120 } }
            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 10
                spacing: 10

                // Left: Network icon + Speeds
                Row {
                    spacing: 7
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        width: 26
                        height: 26
                        radius: 13
                        color: Theme.alpha("#06b6d4", 0.18)
                        Image { anchors.centerIn: parent; width: 13; height: 13; source: root.netSvg }
                    }

                    Column {
                        spacing: 1
                        Text {
                            text: "Network Activity"
                            font.family: "Outfit"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: Theme.muted
                        }
                        Row {
                            spacing: 8
                            Row {
                                spacing: 3
                                Image { width: 10; height: 10; source: root.downSvg; anchors.verticalCenter: parent.verticalCenter }
                                Text {
                                    text: root.netDownStr
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    color: "#06b6d4"
                                }
                            }
                            Row {
                                spacing: 3
                                Image { width: 10; height: 10; source: root.upSvg; anchors.verticalCenter: parent.verticalCenter }
                                Text {
                                    text: root.netUpStr
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    color: "#f59e0b"
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Right: Drill-down action pill button
                Rectangle {
                    height: 26
                    width: drillDownRow.width + 16
                    radius: 13
                    color: netCardMouse.containsMouse ? Theme.alpha("#06b6d4", 0.25) : Theme.alpha("#06b6d4", 0.15)
                    border.width: 1
                    border.color: netCardMouse.containsMouse ? Theme.alpha("#06b6d4", 0.70) : Theme.alpha("#06b6d4", 0.35)

                    Row {
                        id: drillDownRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "App Speeds"
                            font.family: "Outfit"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: "#06b6d4"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Image {
                            width: 11
                            height: 11
                            source: root.chevronRightSvg
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            MouseArea {
                id: netCardMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.showingNetworkDetail = true
                    root.openNetworkDetail()
                }
            }
        }

        // ── 5. SCALABLE CPU CORES MATRIX (4, 8, 12, 16, 24, 32, 64+ CORES) ────
        Rectangle {
            id: coresCard
            width: parent.width
            height: 124
            radius: 14
            color: Theme.alpha(Theme.surface, 0.55)
            border.width: 1
            border.color: Theme.alpha(Theme.foreground, 0.12)
            clip: true

            Column {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                // Section Header
                RowLayout {
                    width: parent.width
                    height: 16

                    Row {
                        spacing: 5
                        Image { width: 12; height: 12; source: root.cpuSvg; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: "CPU Cores (" + root.cpuCores.length + " Cores" + (root.cpuCores.length > 16 ? " • Scrollable" : "") + ")"
                            font.family: "Outfit"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: Theme.muted
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        height: 16
                        width: coreLoadTxt.width + 10
                        radius: 8
                        color: Theme.alpha(Theme.accent, 0.16)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.35)

                        Text {
                            id: coreLoadTxt
                            anchors.centerIn: parent
                            text: root.cpuPct + "% Total"
                            font.family: "Outfit"
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            color: Theme.accent
                        }
                    }
                }

                // Dynamic Responsive Cores Viewport
                Flickable {
                    id: coresFlickable
                    width: parent.width
                    height: 86
                    contentWidth: width
                    contentHeight: coresGrid.height
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    readonly property int coreCount: Math.max(1, root.cpuCores.length)
                    // If <= 8 cores: 1 row with coreCount columns
                    // If <= 16 cores: 2 rows with ceil(coreCount/2) columns
                    // If > 16 cores: 8 columns in a scrollable matrix
                    readonly property int cols: coreCount <= 8 ? coreCount : (coreCount <= 16 ? Math.ceil(coreCount / 2) : 8)
                    readonly property int colSpacing: 5
                    readonly property int tileWidth: Math.floor((width - ((cols - 1) * colSpacing)) / cols)
                    readonly property int tileHeight: coreCount <= 8 ? 84 : 40

                    Grid {
                        id: coresGrid
                        width: parent.width
                        columns: coresFlickable.cols
                        spacing: coresFlickable.colSpacing

                        Repeater {
                            model: root.cpuCores

                            Rectangle {
                                width: coresFlickable.tileWidth
                                height: coresFlickable.tileHeight
                                radius: 6
                                readonly property int coreVal: modelData
                                readonly property color barColor: coreVal >= 80 ? Theme.error : (coreVal >= 55 ? "#f59e0b" : Theme.accent)
                                color: Theme.alpha(Theme.background, 0.65)
                                border.width: 1
                                border.color: Theme.alpha(Theme.foreground, 0.08)

                                // 1-row layout when <= 8 cores (Large Equalizer)
                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    spacing: 3
                                    visible: coresFlickable.coreCount <= 8

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "C" + (index + 1)
                                        font.family: "Outfit"
                                        font.pixelSize: 8
                                        font.weight: Font.Bold
                                        color: Theme.muted
                                    }

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: parent.width - 6
                                        height: 48
                                        radius: 3
                                        color: Theme.alpha(Theme.foreground, 0.08)
                                        clip: true

                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            radius: 3
                                            height: Math.max(2, parent.height * (parent.parent.parent.coreVal / 100.0))
                                            color: parent.parent.parent.barColor
                                            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                        }
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: parent.parent.coreVal + "%"
                                        font.family: "Outfit"
                                        font.pixelSize: 8
                                        font.weight: Font.Bold
                                        color: parent.parent.barColor
                                    }
                                }

                                // Multi-row layout when > 8 cores (Compact Tile)
                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    spacing: 2
                                    visible: coresFlickable.coreCount > 8

                                    RowLayout {
                                        width: parent.width
                                        Text {
                                            text: "C" + (index + 1)
                                            font.family: "Outfit"
                                            font.pixelSize: 8
                                            font.weight: Font.Bold
                                            color: Theme.muted
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: parent.parent.parent.coreVal + "%"
                                            font.family: "Outfit"
                                            font.pixelSize: 8
                                            font.weight: Font.Bold
                                            color: parent.parent.parent.barColor
                                        }
                                    }

                                    // Compact horizontal progress line
                                    Rectangle {
                                        width: parent.width
                                        height: 5
                                        radius: 2.5
                                        color: Theme.alpha(Theme.foreground, 0.10)
                                        clip: true

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            radius: 2.5
                                            width: parent.width * Math.max(0.0, Math.min(1.0, parent.parent.parent.coreVal / 100.0))
                                            color: parent.parent.parent.barColor
                                            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── 6. PAGINATION DOTS PILL (3 PAGES: 1=Weather, 2=Control Center, 3=System Info) ────
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            // Dot 1: Page 1 (Weather)
            Rectangle {
                width: 6
                height: 5
                radius: 2.5
                color: dot1Mouse.containsMouse ? "#38bdf8" : Theme.alpha(Theme.foreground, 0.25)
                Behavior on color { ColorAnimation { duration: 150 } }

                MouseArea {
                    id: dot1Mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pageDotClicked(0)
                }
            }

            // Dot 2: Page 2 (Control Center)
            Rectangle {
                width: 6
                height: 5
                radius: 2.5
                color: dot2Mouse.containsMouse ? Theme.foreground : Theme.alpha(Theme.foreground, 0.35)
                Behavior on color { ColorAnimation { duration: 150 } }

                MouseArea {
                    id: dot2Mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pageDotClicked(1)
                }
            }

            // Dot 3: Page 3 (System Info) - Active
            Rectangle {
                width: 18
                height: 5
                radius: 2.5
                color: Theme.accent
                Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }
        }
    }

    // ── SUB-PAGE: PER-PROCESS NETWORK DETAIL ─────────────────────────────────
    NetworkDetailPage {
        id: networkDetailPage
        anchors.fill: parent
        active: root.active && root.showingNetworkDetail
        visible: opacity > 0.001
        opacity: root.showingNetworkDetail ? 1.0 : 0.0
        x: root.showingNetworkDetail ? 0 : 28

        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        onBackClicked: {
            root.showingNetworkDetail = false
        }
        onPageDotClicked: function(pageIdx) {
            root.showingNetworkDetail = false
            root.pageDotClicked(pageIdx)
        }
    }
}
