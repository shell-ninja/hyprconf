import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root
    anchors.fill: parent

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string soundSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 5L6 9H2v6h4l5 4V5z"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14M15.54 8.46a5 5 0 0 1 0 7.07"/></svg>')
    readonly property string islandSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="6" width="16" height="6" rx="3"/><line x1="8" y1="16" x2="8" y2="18"/><line x1="12" y1="15" x2="12" y2="19"/><line x1="16" y1="16" x2="16" y2="18"/></svg>')
    readonly property string eyeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>')
    readonly property string saveSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.on_primary + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg>')
    readonly property string playSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="' + Theme.accent + '" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="5 3 19 12 5 21 5 3"/></svg>')
    readonly property string pauseSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="' + Theme.accent + '" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="6" y="4" width="4" height="16"/><rect x="14" y="4" width="4" height="16"/></svg>')

    // ── Local Configuration State ───────────────────────────────────────────
    property string islandPosition: "top"
    property bool islandAutoHide: false
    property string islandStyle: "capsule" // "capsule", "orbital", "split_wings", "minimal_rail"
    property bool matrixStreamEnabled: true
    property bool visualizerEnabled: true
    property int visualizerBarCount: 8
    property string visualizerStyle: "wave"
    property bool visualizerMoveOnHover: true

    property bool isDirty: false
    property bool isSimulating: true
    property var simulatedFrequencies: [0.35, 0.65, 0.90, 0.72, 0.45, 0.85, 0.60, 0.30, 0.40, 0.75, 0.88, 0.62, 0.50, 0.78, 0.64, 0.28]

    // ── Simulation Timer for Live Preview ───────────────────────────────────
    property real simPhase: 0.0
    Timer {
        id: simTimer
        interval: 40
        repeat: true
        running: root.isSimulating
        onTriggered: {
            root.simPhase += 0.12
            var arr = []
            for (var i = 0; i < 16; i++) {
                var wave1 = Math.sin(root.simPhase + i * 0.45) * 0.4 + 0.5
                var wave2 = Math.cos(root.simPhase * 1.5 - i * 0.3) * 0.25 + 0.25
                var combined = Math.max(0.05, Math.min(1.0, (wave1 + wave2) * 0.85))
                arr.push(combined)
            }
            root.simulatedFrequencies = arr
        }
    }

    // ── Config Loader ───────────────────────────────────────────────────────
    readonly property string configFilePath: window.homeDir + "/.hyprconf/quickshell/island/config.json"

    Process {
        id: configReader
        command: ["python3", "-c", "import json, os; p=os.path.expanduser('~/.hyprconf/quickshell/island/config.json'); print(open(p).read() if os.path.exists(p) else '{}')"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var data = JSON.parse(text.trim())
                    if (data.position) root.islandPosition = data.position
                    if (data.auto_hide !== undefined) root.islandAutoHide = data.auto_hide
                    if (data.style) root.islandStyle = data.style
                    if (data.matrix_stream !== undefined) root.matrixStreamEnabled = data.matrix_stream
                    if (data.visualizer) {
                        if (data.visualizer.enabled !== undefined) root.visualizerEnabled = data.visualizer.enabled
                        if (data.visualizer.bar_count !== undefined) root.visualizerBarCount = data.visualizer.bar_count
                        if (data.visualizer.style) root.visualizerStyle = data.visualizer.style
                        if (data.visualizer.move_to_bottom_on_hover !== undefined) root.visualizerMoveOnHover = data.visualizer.move_to_bottom_on_hover
                    }
                    root.isDirty = false
                } catch(e) {
                    console.log("[IslandSection] Error loading config.json:", e)
                }
            }
        }
    }

    // ── Config Saver ────────────────────────────────────────────────────────
    Process {
        id: configWriter
        onExited: {
            root.isDirty = false
            window.toastMessage = "Island Settings Applied"
            window.showSaveToast = true
            toastTimer.restart()
            // Signal running Island daemon to hot-reload immediately via IPC
            islandReloader.running = true
        }
    }

    Process {
        id: islandReloader
        command: ["qs", "ipc", "-c", "island", "call", "island", "reloadConfig"]
    }

    Timer {
        id: toastTimer
        interval: 2200
        repeat: false
        onTriggered: {
            window.showSaveToast = false
        }
    }

    function saveSettings() {
        var payload = {
            "position": root.islandPosition,
            "auto_hide": root.islandAutoHide,
            "style": root.islandStyle,
            "matrix_stream": root.matrixStreamEnabled,
            "visualizer": {
                "enabled": root.visualizerEnabled,
                "bar_count": root.visualizerBarCount,
                "style": root.visualizerStyle,
                "move_to_bottom_on_hover": root.visualizerMoveOnHover
            }
        }
        var jsonStr = JSON.stringify(payload, null, 2)
        var pyScript = "import json, os; p=os.path.expanduser('~/.hyprconf/quickshell/island/config.json'); os.makedirs(os.path.dirname(p), exist_ok=True); open(p, 'w').write('''" + jsonStr + "''')"
        configWriter.command = ["python3", "-c", pyScript]
        configWriter.running = true
    }

    // ── Main Scrollable Area ────────────────────────────────────────────────
    ScrollView {
        anchors.fill: parent
        anchors.margins: 18
        contentWidth: availableWidth
        clip: true

        Column {
            width: parent.width
            spacing: 16

            // ── Top Header Banner & Quick Save Action ────────────────────────
            Rectangle {
                width: parent.width
                height: 72
                radius: 12
                color: Theme.alpha(Theme.surface, 0.70)
                border.width: 1
                border.color: Theme.alpha(Theme.foreground, 0.08)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 14

                    Rectangle {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        radius: 21
                        color: Theme.alpha(Theme.accent, 0.18)
                        border.color: Theme.alpha(Theme.accent, 0.40)
                        border.width: 1

                        Image {
                            anchors.centerIn: parent
                            width: 20
                            height: 20
                            source: root.islandSvg
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Dynamic Island Architecture & Visualizer"
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 15
                            font.weight: Font.Bold
                        }

                        Text {
                            text: "Configure island positioning, idle auto-hide, spectrum visualizer wings, and fluid hover transitions."
                            color: Theme.alpha(Theme.foreground, 0.55)
                            font.family: "Outfit"
                            font.pixelSize: 11
                        }
                    }

                    // Save / Apply Button
                    Rectangle {
                        Layout.preferredWidth: 148
                        Layout.preferredHeight: 36
                        radius: 18
                        color: root.isDirty ? Theme.accent : Theme.alpha(Theme.surface, 0.85)
                        border.color: root.isDirty ? Theme.accent : Theme.alpha(Theme.accent, 0.40)
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 14
                                height: 14
                                source: root.saveSvg
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.isDirty ? "Save Changes" : "Save & Reload"
                                color: root.isDirty ? Theme.on_primary : Theme.accent
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: root.saveSettings()
                        }
                    }
                }
            }

            // ── Setting Card 1: Dynamic Island Architecture & Styles ────────
            SettingCard {
                title: "Dynamic Island Architecture & Designs"
                description: "Select from 6 unique, modern silhouettes with tailored workspace indicators, acoustics, and aesthetics."

                GridLayout {
                    width: parent.width
                    columns: 2
                    columnSpacing: 14
                    rowSpacing: 14

                    Repeater {
                        model: [
                            {
                                id: "capsule",
                                name: "Floating Capsule",
                                tag: "Classic Unified",
                                desc: "Unified obsidian floating capsule with Kanji numerals, sliding glowing medallion, breathing status LED, and audio wings."
                            },
                            {
                                id: "orbital",
                                name: "Orbital Satellite",
                                tag: "Action Knob & Pearl",
                                desc: "Sleek floating capsule with circular action knob button, Western digits, luminous top-border satellite pearl tracking active workspace, and bell."
                            },
                            {
                                id: "split_wings",
                                name: "Dual Wings Orb",
                                tag: "Desktop & Laptop Adaptive",
                                desc: "Concave split pods flanking an accent workspace orb: Left interactive volume controller & level bars; Right clock and auto-detecting Desktop (Wi-Fi) / Laptop (Battery) status."
                            },
                            {
                                id: "minimal_rail",
                                name: "Minimalist Matrix Rail",
                                tag: "Ryoku Animated Stream",
                                desc: "Continuous kinetic matrix conveyor stream with cyber telemetry pulses converging towards center Swiss clock, celestial glyphs, and frameless dual-bandwidth monitor."
                            }
                        ]

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 196
                            radius: 14
                            readonly property bool isSelected: root.islandStyle === modelData.id
                            color: isSelected ? Theme.alpha(Theme.surface, 0.90) : (cardHover.containsMouse ? Theme.alpha(Theme.surface, 0.65) : Theme.alpha(Theme.surface, 0.40))
                            border.width: isSelected ? 1.5 : 1
                            border.color: isSelected ? Theme.accent : (cardHover.containsMouse ? Theme.alpha(Theme.foreground, 0.20) : Theme.alpha(Theme.foreground, 0.08))

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Column {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10

                                // 1. Live Miniature Mockup Window
                                Rectangle {
                                    width: parent.width
                                    height: 72
                                    radius: 10
                                    color: Theme.alpha(Theme.background, 0.75)
                                    border.color: Theme.alpha(Theme.foreground, 0.08)
                                    border.width: 1
                                    clip: false

                                    // Rendered Miniature Island for modelData.id
                                    Item {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.min(parent.width - 24, (modelData.id === "minimal_rail") ? 230 : 210)
                                        height: (modelData.id === "minimal_rail") ? 24 : ((modelData.id === "orbital") ? 24 : 26)

                                        // 1. Orbital Satellite Glow Halo
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: parent.width + 3
                                            height: parent.height + 3
                                            radius: 13.5
                                            color: Theme.alpha(Theme.accent, 0.15)
                                            visible: modelData.id === "orbital"
                                        }

                                        // 2. Regular Rectangle Background for capsule/orbital styles only
                                        //    minimal_rail uses individual capsule backgrounds; split_wings uses its own layout
                                        Rectangle {
                                            anchors.fill: parent
                                            visible: modelData.id !== "split_wings" && modelData.id !== "minimal_rail"
                                            radius: (modelData.id === "orbital") ? 12 : 13
                                            color: Theme.alpha(Theme.surface, 0.95)
                                            border.color: (modelData.id === "orbital") ? Theme.alpha(Theme.accent, 0.6) : (parent.parent.parent.parent.parent.isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.18))
                                            border.width: 1
                                        }

                                        // Orbital Top-Border Protruding Satellite Pearl
                                        Item {
                                            visible: modelData.id === "orbital"
                                            y: -3
                                            x: parent.width / 2 - 12
                                            z: 30
                                            width: 6
                                            height: 6

                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: 10
                                                height: 10
                                                radius: 5
                                                color: Theme.alpha(Theme.accent, 0.25)
                                                border.color: Theme.alpha(Theme.accent, 0.55)
                                                border.width: 0.8
                                            }
                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: 5
                                                height: 5
                                                radius: 2.5
                                                color: Theme.accent
                                            }
                                        }

                                        // Miniature Content Elements (for Capsule and Orbital)
                                        Row {
                                            anchors.centerIn: parent
                                            visible: modelData.id === "capsule" || modelData.id === "orbital"
                                            spacing: (modelData.id === "orbital") ? 6 : 5

                                            // Left element: Orbital Action knob button (circle with minus)
                                            Rectangle {
                                                width: 15
                                                height: 15
                                                radius: 7.5
                                                color: Theme.accent
                                                anchors.verticalCenter: parent.verticalCenter
                                                visible: modelData.id === "orbital"

                                                Rectangle {
                                                    anchors.centerIn: parent
                                                    width: 6; height: 1.5; radius: 0.75
                                                    color: Theme.background
                                                }
                                            }

                                            // Mini left visualizer (for capsule)
                                            Row {
                                                spacing: 1.5
                                                anchors.verticalCenter: parent.verticalCenter
                                                visible: modelData.id === "capsule"
                                                Repeater {
                                                    model: 3
                                                    Rectangle {
                                                        width: 2
                                                        height: [4, 9, 6][index]
                                                        radius: 1
                                                        color: Theme.accent
                                                        anchors.verticalCenter: parent.verticalCenter
                                                    }
                                                }
                                            }

                                            // Mini Workspace cluster
                                            Item {
                                                width: (modelData.id === "orbital") ? 48 : 46
                                                height: 18
                                                anchors.verticalCenter: parent.verticalCenter

                                                Row {
                                                    spacing: 3
                                                    anchors.centerIn: parent
                                                    Repeater {
                                                        model: 3
                                                        Item {
                                                            width: 13
                                                            height: 18
                                                            readonly property bool isFocus: (index === 1)

                                                            Rectangle {
                                                                anchors.centerIn: parent
                                                                width: (modelData.id === "capsule") ? 16 : 13
                                                                height: (modelData.id === "capsule") ? 16 : 12
                                                                radius: (modelData.id === "capsule") ? 8 : 3.5
                                                                color: Theme.accent
                                                                visible: parent.isFocus
                                                            }

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: (modelData.id === "orbital") ? ["1", "2", "3"][index] : ["一", "二", "三"][index]
                                                                font.family: "Outfit"
                                                                font.pixelSize: 8
                                                                font.weight: Font.Bold
                                                                color: parent.isFocus ? Theme.background : Theme.alpha(Theme.foreground, 0.6)
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            // Divider
                                            Item {
                                                width: 4
                                                height: 12
                                                anchors.verticalCenter: parent.verticalCenter

                                                Rectangle {
                                                    anchors.centerIn: parent
                                                    width: 1
                                                    height: 10
                                                    color: Theme.alpha(Theme.accent, 0.45)
                                                }
                                            }

                                            // Orbital: Bell Icon
                                            Image {
                                                width: 10
                                                height: 10
                                                anchors.verticalCenter: parent.verticalCenter
                                                source: root.svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>')
                                                visible: modelData.id === "orbital"
                                            }

                                            // Clock & status
                                            Row {
                                                spacing: 3
                                                anchors.verticalCenter: parent.verticalCenter

                                                Text {
                                                    text: (modelData.id === "orbital") ? "11:08 PM" : "10:00"
                                                    font.family: "Outfit"
                                                    font.pixelSize: 8
                                                    font.weight: Font.Bold
                                                    color: Theme.accent
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }
                                        }

                                        // 3. Minimal Rail — faithful 3-capsule layout matching actual island
                                        //    Real island: wsCluster(136px,28h,r14) + bridge(76px) + clock(dynamic,28h,r14) + bridge(76px) + netBadge(136px,28h,r14)
                                        //    Preview scales this to ~(58+24+56+24+58=220px) × 18h, all on Theme.background (0.92 alpha)
                                        Row {
                                            anchors.centerIn: parent
                                            visible: modelData.id === "minimal_rail"
                                            spacing: 0

                                            // ── Capsule 1: Workspace Cluster (matches wsClusterMinimal) ──
                                            Rectangle {
                                                id: previewWsCapsule
                                                width: 60
                                                height: 18
                                                radius: 9
                                                color: Theme.alpha(Theme.background, 0.92)
                                                border.color: Theme.alpha(Theme.foreground, 0.16)
                                                border.width: 1
                                                anchors.verticalCenter: parent.verticalCenter
                                                clip: true

                                                // Floating accent medallion pill (active ws index = 1, glyph ◈)
                                                Rectangle {
                                                    id: previewMedallion
                                                    width: 12; height: 11; radius: 5.5
                                                    color: Theme.accent
                                                    z: 10
                                                    y: (parent.height - height) / 2
                                                    x: {
                                                        // slot 1 (0-indexed) → x = 3 + 1*(10+2) + 5 - 6 = 11
                                                        var slotW = 10; var sp = 2; var n = 5
                                                        var totalW = n * slotW + (n-1) * sp
                                                        var rowStart = (parent.width - totalW) / 2
                                                        return Math.round(rowStart + 1 * (slotW + sp) + slotW/2 - width/2)
                                                    }
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "◈"
                                                        font.family: "Outfit"; font.pixelSize: 5; font.weight: Font.Bold
                                                        color: Theme.background
                                                    }
                                                }

                                                Row {
                                                    spacing: 2
                                                    anchors.centerIn: parent
                                                    Repeater {
                                                        model: 5
                                                        Item {
                                                            width: 10; height: 18
                                                            readonly property bool isFocus: (index === 1)
                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: ["✦","◈","◆","❖","⬡"][index]
                                                                font.family: "Outfit"; font.pixelSize: 6; font.weight: Font.Bold
                                                                color: parent.isFocus ? Theme.background : Theme.alpha(Theme.foreground, 0.40)
                                                                opacity: parent.isFocus ? 0.0 : 1.0
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            // ── Bridge 1: Ryoku stream conduit (forward) ──
                                            Item {
                                                width: 22; height: 18
                                                anchors.verticalCenter: parent.verticalCenter
                                                // Center line
                                                Rectangle {
                                                    anchors.left: parent.left; anchors.right: parent.right
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    height: 1.2; color: Theme.alpha(Theme.foreground, 0.22)
                                                }
                                                // Ambient dot at 26%
                                                Rectangle {
                                                    x: Math.round(parent.width * 0.26 - 1.1)
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: 2.2; height: 2.2; radius: 1.1
                                                    color: Theme.alpha(Theme.foreground, 0.35)
                                                }
                                                // Ambient dot at 74%
                                                Rectangle {
                                                    x: Math.round(parent.width * 0.74 - 1.1)
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: 2.2; height: 2.2; radius: 1.1
                                                    color: Theme.alpha(Theme.foreground, 0.35)
                                                }
                                                // Center glow particle (halo + core)
                                                Rectangle {
                                                    anchors.centerIn: parent
                                                    width: 8; height: 8; radius: 4
                                                    color: Theme.alpha(Theme.accent, 0.22)
                                                }
                                                Rectangle {
                                                    anchors.centerIn: parent
                                                    width: 3.2; height: 3.2; radius: 1.6
                                                    color: Theme.accent
                                                }
                                            }

                                            // ── Capsule 2: Swiss Minimal Clock (matches minimalClockModule) ──
                                            Rectangle {
                                                width: 56
                                                height: 18
                                                radius: 9
                                                color: Theme.alpha(Theme.background, 0.92)
                                                border.color: Theme.alpha(Theme.foreground, 0.16)
                                                border.width: 1
                                                anchors.verticalCenter: parent.verticalCenter
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "10:27 • MON"
                                                    font.family: "Outfit"; font.pixelSize: 7; font.weight: Font.Bold
                                                    color: Theme.accent
                                                }
                                            }

                                            // ── Bridge 2: Ryoku stream conduit (reverse) ──
                                            Item {
                                                width: 22; height: 18
                                                anchors.verticalCenter: parent.verticalCenter
                                                Rectangle {
                                                    anchors.left: parent.left; anchors.right: parent.right
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    height: 1.2; color: Theme.alpha(Theme.foreground, 0.22)
                                                }
                                                Rectangle {
                                                    x: Math.round(parent.width * 0.26 - 1.1)
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: 2.2; height: 2.2; radius: 1.1
                                                    color: Theme.alpha(Theme.foreground, 0.35)
                                                }
                                                Rectangle {
                                                    x: Math.round(parent.width * 0.74 - 1.1)
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: 2.2; height: 2.2; radius: 1.1
                                                    color: Theme.alpha(Theme.foreground, 0.35)
                                                }
                                                Rectangle {
                                                    anchors.centerIn: parent
                                                    width: 8; height: 8; radius: 4
                                                    color: Theme.alpha(Theme.accent, 0.22)
                                                }
                                                Rectangle {
                                                    anchors.centerIn: parent
                                                    width: 3.2; height: 3.2; radius: 1.6
                                                    color: Theme.accent
                                                }
                                            }

                                            // ── Capsule 3: Net Bandwidth Badge (matches minimalNetBadge) ──
                                            Rectangle {
                                                width: 60
                                                height: 18
                                                radius: 9
                                                color: Theme.alpha(Theme.background, 0.92)
                                                border.color: Theme.alpha(Theme.foreground, 0.16)
                                                border.width: 1
                                                anchors.verticalCenter: parent.verticalCenter

                                                Row {
                                                    anchors.centerIn: parent
                                                    spacing: 5
                                                    Row {
                                                        spacing: 2; anchors.verticalCenter: parent.verticalCenter
                                                        Text { text: "↓"; font.family: "Outfit"; font.pixelSize: 7; font.weight: Font.Bold; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                                                        Text { text: "2.8M"; font.family: "Outfit"; font.pixelSize: 7; font.weight: Font.Bold; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                                                    }
                                                    Rectangle { width: 1; height: 8; color: Theme.alpha(Theme.accent, 0.22); anchors.verticalCenter: parent.verticalCenter }
                                                    Row {
                                                        spacing: 2; anchors.verticalCenter: parent.verticalCenter
                                                        Text { text: "↑"; font.family: "Outfit"; font.pixelSize: 7; font.weight: Font.Bold; color: Theme.alpha(Theme.accent, 0.60); anchors.verticalCenter: parent.verticalCenter }
                                                        Text { text: "672K"; font.family: "Outfit"; font.pixelSize: 7; font.weight: Font.Bold; color: Theme.alpha(Theme.accent, 0.60); anchors.verticalCenter: parent.verticalCenter }
                                                    }
                                                }
                                            }
                                        }


                                        // 4. Split Wings Dedicated Tripartite Preview
                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 4
                                            visible: modelData.id === "split_wings"

                                            // Mini Left Wing
                                            Rectangle {
                                                width: 82
                                                height: 22
                                                radius: 11
                                                color: Theme.alpha(Theme.surface, 0.95)
                                                border.color: parent.parent.parent.parent.parent.parent.isSelected ? Theme.accent : Theme.alpha(Theme.accent, 0.55)
                                                border.width: 1

                                                Row {
                                                    anchors.centerIn: parent
                                                    spacing: 4

                                                    // Mini speaker
                                                    Image {
                                                        width: 9
                                                        height: 9
                                                        source: root.svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14"/></svg>')
                                                        anchors.verticalCenter: parent.verticalCenter
                                                    }

                                                    // Mini volume slider track
                                                    Rectangle {
                                                        width: 36
                                                        height: 2.5
                                                        radius: 1.25
                                                        color: Theme.alpha(Theme.foreground, 0.20)
                                                        anchors.verticalCenter: parent.verticalCenter

                                                        Rectangle {
                                                            width: parent.width * 0.55
                                                            height: parent.height
                                                            radius: parent.radius
                                                            color: Theme.accent
                                                        }

                                                        Rectangle {
                                                            x: parent.width * 0.55 - 3
                                                            width: 6
                                                            height: 6
                                                            radius: 3
                                                            color: Theme.accent
                                                            anchors.verticalCenter: parent.verticalCenter
                                                        }
                                                    }

                                                    // Mini 3 level bars
                                                    Row {
                                                        spacing: 1.5
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        Rectangle { width: 1.5; height: 3; color: Theme.accent; anchors.bottom: parent.bottom }
                                                        Rectangle { width: 1.5; height: 6; color: Theme.accent; anchors.bottom: parent.bottom }
                                                        Rectangle { width: 1.5; height: 9; color: Theme.accent; opacity: 0.35; anchors.bottom: parent.bottom }
                                                    }
                                                }
                                            }

                                            // Mini Center Orb
                                            Rectangle {
                                                width: 26
                                                height: 26
                                                radius: 13
                                                color: Theme.accent
                                                anchors.verticalCenter: parent.verticalCenter

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "二"
                                                    font.family: "Outfit"
                                                    font.pixelSize: 12
                                                    font.weight: Font.Bold
                                                    color: Theme.background
                                                }
                                            }

                                            // Mini Right Wing
                                            Rectangle {
                                                width: 82
                                                height: 22
                                                radius: 11
                                                color: Theme.alpha(Theme.surface, 0.95)
                                                border.color: parent.parent.parent.parent.parent.parent.isSelected ? Theme.accent : Theme.alpha(Theme.accent, 0.55)
                                                border.width: 1

                                                Row {
                                                    anchors.centerIn: parent
                                                    spacing: 4

                                                    // Breathing dot
                                                    Rectangle {
                                                        width: 3.5
                                                        height: 3.5
                                                        radius: 1.75
                                                        color: Theme.accent
                                                        anchors.verticalCenter: parent.verticalCenter
                                                    }

                                                    // Time
                                                    Text {
                                                        text: "11:21"
                                                        color: Theme.accent
                                                        font.family: "Outfit"
                                                        font.pixelSize: 8
                                                        font.weight: Font.Bold
                                                        anchors.verticalCenter: parent.verticalCenter
                                                    }

                                                    // Divider
                                                    Rectangle {
                                                        width: 1
                                                        height: 8
                                                        color: Theme.alpha(Theme.foreground, 0.25)
                                                        anchors.verticalCenter: parent.verticalCenter
                                                    }

                                                    // Wi-Fi or Battery icon
                                                    Image {
                                                        width: 9
                                                        height: 9
                                                        source: root.svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M1.42 9a16 16 0 0 1 21.16 0"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1.2" fill="' + Theme.accent + '"/></svg>')
                                                        anchors.verticalCenter: parent.verticalCenter
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // 2. Text Meta
                                RowLayout {
                                    width: parent.width
                                    spacing: 6

                                    Text {
                                        text: modelData.name
                                        color: parent.parent.parent.isSelected ? Theme.accent : Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 13
                                        font.weight: Font.Bold
                                    }

                                    Item { Layout.fillWidth: true }

                                    Rectangle {
                                        height: 18
                                        width: tagText.implicitWidth + 12
                                        radius: 9
                                        color: Theme.alpha(Theme.accent, 0.15)
                                        border.color: Theme.alpha(Theme.accent, 0.35)
                                        border.width: 1

                                        Text {
                                            id: tagText
                                            anchors.centerIn: parent
                                            text: modelData.tag
                                            font.family: "Outfit"
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                            color: Theme.accent
                                        }
                                    }
                                }

                                Text {
                                    width: parent.width
                                    text: modelData.desc
                                    color: Theme.alpha(Theme.foreground, 0.55)
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }

                                Item { Layout.fillHeight: true }

                                // 3. Status Badge Button
                                Rectangle {
                                    width: parent.width
                                    height: 28
                                    radius: 14
                                    color: parent.parent.isSelected ? Theme.accent : Theme.alpha(Theme.surface, 0.8)
                                    border.color: parent.parent.isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: parent.parent.parent.isSelected ? "✓ Active Design" : "Select Design"
                                        font.family: "Outfit"
                                        font.pixelSize: 11
                                        font.weight: parent.parent.parent.isSelected ? Font.Bold : Font.Normal
                                        color: parent.parent.parent.isSelected ? Theme.on_primary : Theme.foreground
                                    }
                                }
                            }

                            MouseArea {
                                id: cardHover
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: {
                                    root.islandStyle = modelData.id
                                    root.isDirty = true
                                    root.saveSettings()
                                }
                            }
                        }
                    }
                }
            }

            // ── Setting Card 2: Island Layout & Placement ────────────────────
            SettingCard {
                title: "Island Notch Placement & Dynamics"
                description: "Screen anchor location, auto-hide dynamics, and hover behavior."

                // 1. Screen Anchor Position
                RowLayout {
                    width: parent.width
                    spacing: 12

                    Column {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Screen Position"
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "Choose whether the dynamic island is anchored at the top or bottom of your screen."
                            color: Theme.alpha(Theme.foreground, 0.50)
                            font.family: "Outfit"
                            font.pixelSize: 11
                        }
                    }

                    Row {
                        spacing: 6
                        Layout.alignment: Qt.AlignRight

                        // Top Notch Pill
                        Rectangle {
                            width: 96
                            height: 32
                            radius: 16
                            readonly property bool isSelected: root.islandPosition === "top"
                            color: isSelected ? Theme.accent : Theme.alpha(Theme.surface, 0.6)
                            border.width: 1
                            border.color: isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)

                            Behavior on color { ColorAnimation { duration: 140 } }

                            Text {
                                anchors.centerIn: parent
                                text: "Top Notch"
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: parent.isSelected ? Font.Bold : Font.Normal
                                color: parent.isSelected ? Theme.on_primary : Theme.foreground
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.islandPosition = "top"
                                    root.isDirty = true
                                }
                            }
                        }

                        // Bottom Dock Pill
                        Rectangle {
                            width: 104
                            height: 32
                            radius: 16
                            readonly property bool isSelected: root.islandPosition === "bottom"
                            color: isSelected ? Theme.accent : Theme.alpha(Theme.surface, 0.6)
                            border.width: 1
                            border.color: isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)

                            Behavior on color { ColorAnimation { duration: 140 } }

                            Text {
                                anchors.centerIn: parent
                                text: "Bottom Dock"
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: parent.isSelected ? Font.Bold : Font.Normal
                                color: parent.isSelected ? Theme.on_primary : Theme.foreground
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.islandPosition = "bottom"
                                    root.isDirty = true
                                }
                            }
                        }
                    }
                }

                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.alpha(Theme.foreground, 0.06)
                }

                // 2. Auto-Hide Toggle
                RowLayout {
                    width: parent.width
                    spacing: 12

                    Column {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Auto-Hide on Inactive"
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "Smoothly retract the island into the screen edge when idle. Springs into view on edge hover or notifications."
                            color: Theme.alpha(Theme.foreground, 0.50)
                            font.family: "Outfit"
                            font.pixelSize: 11
                        }
                    }

                    CapsuleSwitch {
                        checked: root.islandAutoHide
                        onToggled: {
                            root.islandAutoHide = checked
                            root.isDirty = true
                        }
                    }
                }

                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.alpha(Theme.foreground, 0.06)
                }

                // 3. Move Visualizer to Bottom on Hover Toggle
                RowLayout {
                    width: parent.width
                    spacing: 12

                    Column {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Move Visualizer to Bottom of Home on Hover"
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "While music is playing, hovering or expanding the island smoothly translates the spectrum to the bottom of the dashboard."
                            color: Theme.alpha(Theme.foreground, 0.50)
                            font.family: "Outfit"
                            font.pixelSize: 11
                        }
                    }

                    CapsuleSwitch {
                        checked: root.visualizerMoveOnHover
                        onToggled: {
                            root.visualizerMoveOnHover = checked
                            root.isDirty = true
                        }
                    }
                }

                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.alpha(Theme.foreground, 0.06)
                }

                // 4. Matrix Rail Stream Kinetic Animation Toggle
                RowLayout {
                    width: parent.width
                    spacing: 12

                    Column {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Matrix Rail Stream Animation"
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "Enable forward-moving Ryoku kinetic stream animation and laser chevrons between Minimalist Matrix Rail modules."
                            color: Theme.alpha(Theme.foreground, 0.50)
                            font.family: "Outfit"
                            font.pixelSize: 11
                        }
                    }

                    CapsuleSwitch {
                        checked: root.matrixStreamEnabled
                        onToggled: {
                            root.matrixStreamEnabled = checked
                            root.isDirty = true
                        }
                    }
                }
            }

            // ── Setting Card 2: Audio Spectrum Visualizer ────────────────────
            SettingCard {
                title: "Audio Spectrum Visualizer"
                description: "Harmonic audio frequency visualization, visual styles, and bar density."

                // 1. Enable Visualizer
                RowLayout {
                    width: parent.width
                    spacing: 12

                    Column {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Enable Audio Visualizer"
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "Display real-time audio spectrum frequency wings on the collapsed bar and Home dashboard during playback."
                            color: Theme.alpha(Theme.foreground, 0.50)
                            font.family: "Outfit"
                            font.pixelSize: 11
                        }
                    }

                    CapsuleSwitch {
                        checked: root.visualizerEnabled
                        onToggled: {
                            root.visualizerEnabled = checked
                            root.isDirty = true
                        }
                    }
                }

                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.alpha(Theme.foreground, 0.06)
                }

                // 2. Bar Style Selector (Wave, Cava, Dots)
                Column {
                    width: parent.width
                    spacing: 10

                    Column {
                        spacing: 2
                        Text {
                            text: "Visualizer Bar Style"
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: "Select the aesthetic rendering technique for spectrum bars."
                            color: Theme.alpha(Theme.foreground, 0.50)
                            font.family: "Outfit"
                            font.pixelSize: 11
                        }
                    }

                    RowLayout {
                        width: parent.width
                        spacing: 10

                        // Style 1: Harmonic Wave
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 74
                            radius: 10
                            readonly property bool isSelected: root.visualizerStyle === "wave"
                            color: isSelected ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.55)
                            border.width: 1
                            border.color: isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.10)

                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Harmonic Wave"
                                    font.family: "Outfit"
                                    font.pixelSize: 12
                                    font.weight: parent.parent.isSelected ? Font.Bold : Font.DemiBold
                                    color: parent.parent.isSelected ? Theme.accent : Theme.foreground
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Organic rounded capsules"
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                    color: Theme.alpha(Theme.foreground, 0.55)
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.visualizerStyle = "wave"
                                    root.isDirty = true
                                }
                            }
                        }

                        // Style 2: Cava Spectrum Bars
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 74
                            radius: 10
                            readonly property bool isSelected: root.visualizerStyle === "cava"
                            color: isSelected ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.55)
                            border.width: 1
                            border.color: isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.10)

                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Spectrum Equalizer"
                                    font.family: "Outfit"
                                    font.pixelSize: 12
                                    font.weight: parent.parent.isSelected ? Font.Bold : Font.DemiBold
                                    color: parent.parent.isSelected ? Theme.accent : Theme.foreground
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Cava columns with peak caps"
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                    color: Theme.alpha(Theme.foreground, 0.55)
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.visualizerStyle = "cava"
                                    root.isDirty = true
                                }
                            }
                        }

                        // Style 3: Floating Beads / Dots
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 74
                            radius: 10
                            readonly property bool isSelected: root.visualizerStyle === "dots"
                            color: isSelected ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.55)
                            border.width: 1
                            border.color: isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.10)

                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Floating Beads"
                                    font.family: "Outfit"
                                    font.pixelSize: 12
                                    font.weight: parent.parent.isSelected ? Font.Bold : Font.DemiBold
                                    color: parent.parent.isSelected ? Theme.accent : Theme.foreground
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Pulsing audio particle dots"
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                    color: Theme.alpha(Theme.foreground, 0.55)
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.visualizerStyle = "dots"
                                    root.isDirty = true
                                }
                            }
                        }
                    }
                }

                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.alpha(Theme.foreground, 0.06)
                }

                // 3. Bar Count Selector (4, 8, 12, 16)
                RowLayout {
                    width: parent.width
                    spacing: 12

                    Column {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Spectrum Bar Count"
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "Number of audio frequency bins analyzed and rendered."
                            color: Theme.alpha(Theme.foreground, 0.50)
                            font.family: "Outfit"
                            font.pixelSize: 11
                        }
                    }

                    Row {
                        spacing: 6
                        Layout.alignment: Qt.AlignRight

                        Repeater {
                            model: [
                                { label: "4 Bars", count: 4 },
                                { label: "8 Bars", count: 8 },
                                { label: "12 Bars", count: 12 },
                                { label: "16 Bars", count: 16 }
                            ]

                            Rectangle {
                                width: 72
                                height: 32
                                radius: 16
                                readonly property bool isSelected: root.visualizerBarCount === modelData.count
                                color: isSelected ? Theme.accent : Theme.alpha(Theme.surface, 0.6)
                                border.width: 1
                                border.color: isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)

                                Behavior on color { ColorAnimation { duration: 140 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    font.weight: parent.isSelected ? Font.Bold : Font.Normal
                                    color: parent.isSelected ? Theme.on_primary : Theme.foreground
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.visualizerBarCount = modelData.count
                                        root.isDirty = true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Setting Card 3: Interactive Live Preview & Simulation ────────
            SettingCard {
                title: "Live Spectrum Simulation & Preview"
                description: "Test rendering physics, attack/decay rates, and responsive styling in real time."

                // Preview Box
                Rectangle {
                    width: parent.width
                    height: 140
                    radius: 14
                    color: Theme.alpha(Theme.background, 0.85)
                    border.color: Theme.alpha(Theme.accent, 0.35)
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 16

                        // Collapsed Pill Miniature Simulation (Reflects Active Island Style)
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: (root.islandStyle === "minimal_rail") ? 32 : ((root.islandStyle === "orbital") ? 34 : ((root.islandStyle === "split_wings") ? 42 : 36))
                            width: Math.max(260, root.visualizerBarCount * 12 + 180)
                            radius: {
                                if (root.islandStyle === "minimal_rail") return 16
                                if (root.islandStyle === "orbital") return 17
                                return 18
                            }
                            color: Theme.alpha(Theme.surface, 0.95)
                            border.color: Theme.alpha(Theme.accent, 0.40)
                            border.width: 1

                            // Orbital Ambient Halo
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width + 4
                                height: parent.height + 4
                                radius: 19
                                color: Theme.alpha(Theme.accent, 0.15)
                                z: -1
                                visible: root.islandStyle === "orbital"
                            }

                            // Minimal Rail Guide Line
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width - 24
                                height: 1
                                color: Theme.alpha(Theme.foreground, 0.08)
                                visible: root.islandStyle === "minimal_rail"
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 14

                                // Left wing
                                AudioVisualizer {
                                    anchors.verticalCenter: parent.verticalCenter
                                    active: root.isSimulating && root.visualizerEnabled
                                    barCount: Math.max(2, Math.floor(root.visualizerBarCount / 2))
                                    style: root.visualizerStyle
                                    cavaValues: root.simulatedFrequencies.slice(0, barCount)
                                    height: 18
                                    barW: (root.visualizerStyle === "cava" ? 4.0 : 3.2)
                                    gap: 2.4
                                    visible: root.visualizerEnabled
                                }

                                // Center Status Badge
                                Row {
                                    spacing: 6
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        width: 6
                                        height: 6
                                        radius: 3
                                        color: Theme.accent
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "12:00 PM"
                                        font.family: "Outfit"
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                        color: Theme.accent
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                // Right wing
                                AudioVisualizer {
                                    anchors.verticalCenter: parent.verticalCenter
                                    active: root.isSimulating && root.visualizerEnabled
                                    mirror: true
                                    barCount: Math.max(2, Math.floor(root.visualizerBarCount / 2))
                                    style: root.visualizerStyle
                                    cavaValues: root.simulatedFrequencies.slice(barCount, barCount * 2)
                                    height: 18
                                    barW: (root.visualizerStyle === "cava" ? 4.0 : 3.2)
                                    gap: 2.4
                                    visible: root.visualizerEnabled
                                }
                            }
                        }

                        // Expanded Bottom Pill Miniature Simulation
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: 28
                            width: Math.max(220, root.visualizerBarCount * 14 + 50)
                            radius: 14
                            color: Theme.alpha(Theme.surface, 0.60)
                            border.color: Theme.alpha(Theme.foreground, 0.12)
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 10

                                Text {
                                    text: "HOME EXPANDED:"
                                    font.family: "Outfit"
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    font.letterSpacing: 0.8
                                    color: Theme.alpha(Theme.accent, 0.85)
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                AudioVisualizer {
                                    anchors.verticalCenter: parent.verticalCenter
                                    active: root.isSimulating && root.visualizerEnabled
                                    barCount: root.visualizerBarCount
                                    style: root.visualizerStyle
                                    cavaValues: root.simulatedFrequencies.slice(0, root.visualizerBarCount)
                                    height: 18
                                    barW: (root.visualizerStyle === "cava" ? 4.5 : 3.5)
                                    gap: 2.6
                                    visible: root.visualizerEnabled
                                }
                            }
                        }
                    }
                }

                // Simulation Controls Row
                RowLayout {
                    width: parent.width
                    spacing: 12

                    Text {
                        Layout.fillWidth: true
                        text: "Simulating live harmonic frequencies at 30 fps"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        color: Theme.alpha(Theme.foreground, 0.50)
                    }

                    Rectangle {
                        Layout.preferredWidth: 136
                        Layout.preferredHeight: 32
                        radius: 16
                        color: root.isSimulating ? Theme.alpha(Theme.accent, 0.20) : Theme.alpha(Theme.surface, 0.70)
                        border.color: root.isSimulating ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)
                        border.width: 1

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 10
                                height: 10
                                source: root.isSimulating ? root.pauseSvg : root.playSvg
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.isSimulating ? "Pause Simulation" : "Start Simulation"
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: root.isSimulating ? Theme.accent : Theme.foreground
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.isSimulating = !root.isSimulating
                        }
                    }
                }
            }
        }
    }
}
