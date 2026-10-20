import QtQuick
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root

    implicitWidth: 280
    implicitHeight: 165

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string wifiSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M1.42 9a16 16 0 0 1 21.16 0"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1.2" fill="currentColor"/></svg>')
    readonly property string btSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6.5 6.5 17.5 17.5 12 23 12 1 17.5 6.5 6.5 17.5"/></svg>')
    readonly property string coffeeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8h1a4 4 0 0 1 0 8h-1"/><path d="M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z"/><line x1="6" y1="1" x2="6" y2="4"/><line x1="10" y1="1" x2="10" y2="4"/><line x1="14" y1="1" x2="14" y2="4"/></svg>')
    readonly property string moonSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>')
    readonly property string dndSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M13.73 21a2 2 0 0 1-3.46 0"/><path d="M18.63 13A17.89 17.89 0 0 1 18 8"/><path d="M6.26 6.26A5.86 5.86 0 0 0 6 8c0 7-3 9-3 9h14"/><line x1="1" y1="1" x2="23" y2="23"/></svg>')
    readonly property string perfSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="m12 14 4-4"/><path d="M3.34 19a10 10 0 1 1 17.32 0"/></svg>')

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : "/home/shell-ninja"
    }

    // ── STATES ───────────────────────────────────────────────────────────────
    property bool wifiActive: true
    property string wifiName: "Wi-Fi"
    property bool btActive: true
    property bool caffeineActive: false
    property string nightLightMode: "off" // "off", "on", "scheduled"
    property bool dndActive: false
    property string perfMode: "performance"

    Process { id: toggleCmd }

    // Caffeine (hypridle) Reader
    Process {
        id: caffeineReader
        command: [root.homeDir + "/.hyprconf/hypr/scripts/sh/caffeine-manager.sh", "get"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    root.caffeineActive = (text.trim() === "on")
                }
            }
        }
    }

    // Night Light (hyprsunset 3-stage) Reader
    Process {
        id: nightLightReader
        command: [root.homeDir + "/.hyprconf/hypr/scripts/sh/hyprsunset-manager.sh", "get"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    var m = text.trim()
                    if (m === "off" || m === "on" || m === "scheduled") {
                        root.nightLightMode = m
                    }
                }
            }
        }
    }

    // DND Reader (Native Quickshell Island State)
    Process {
        id: dndReader
        command: ["python3", "-c", "import json, os; p=os.path.expanduser('~/.hyprconf/hypr/.cache/dnd_state.json'); print('on' if os.path.exists(p) and json.load(open(p)).get('dnd') else 'off')"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (text) root.dndActive = (text.trim() === "on")
            }
        }
    }

    // Power Profile Reader (3 states: performance, balanced, power-saver)
    Process {
        id: perfReader
        command: ["powerprofilesctl", "get"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    var m = text.trim()
                    if (m === "performance" || m === "balanced" || m === "power-saver") {
                        root.perfMode = m
                    }
                }
            }
        }
    }

    // Wi-Fi & BT Readers
    Process {
        id: statusReader
        command: ["bash", "-c", "echo $(nmcli -t -f STATE g 2>/dev/null):$(bluetoothctl show 2>/dev/null | grep -c 'Powered: yes')"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text) return
                var parts = text.trim().split(":")
                if (parts.length >= 2) {
                    root.wifiActive = (parts[0] === "connected")
                    root.btActive = (parts[1] === "1")
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            if (!statusReader.running) statusReader.running = true
            if (!caffeineReader.running) caffeineReader.running = true
            if (!nightLightReader.running) nightLightReader.running = true
            if (!dndReader.running) dndReader.running = true
            if (!perfReader.running) perfReader.running = true
        }
    }

    Process {
        id: dndIpc
        command: ["qs", "ipc", "-c", "island", "call", "island", "toggleDnd"]
    }

    function toggleDnd() {
        root.dndActive = !root.dndActive
        var pyCmd = "import json, os; p=os.path.expanduser('~/.hyprconf/hypr/.cache/dnd_state.json'); os.makedirs(os.path.dirname(p), exist_ok=True); json.dump({'dnd': " + (root.dndActive ? "True" : "False") + "}, open(p, 'w'))"
        toggleCmd.command = ["python3", "-c", pyCmd]
        toggleCmd.running = true
        dndIpc.running = true
    }

    function toggleNightLight() {
        if (root.nightLightMode === "off") root.nightLightMode = "on"
        else if (root.nightLightMode === "on") root.nightLightMode = "scheduled"
        else root.nightLightMode = "off"

        toggleCmd.command = [root.homeDir + "/.hyprconf/hypr/scripts/sh/hyprsunset-manager.sh", "toggle"]
        toggleCmd.running = true
    }

    function toggleCaffeine() {
        root.caffeineActive = !root.caffeineActive
        toggleCmd.command = [root.homeDir + "/.hyprconf/hypr/scripts/sh/caffeine-manager.sh", "toggle"]
        toggleCmd.running = true
    }

    function togglePerformance() {
        if (root.perfMode === "performance") {
            root.perfMode = "balanced"
        } else if (root.perfMode === "balanced") {
            root.perfMode = "power-saver"
        } else {
            root.perfMode = "performance"
        }
        toggleCmd.command = ["powerprofilesctl", "set", root.perfMode]
        toggleCmd.running = true
    }

    function toggleWifi() {
        root.wifiActive = !root.wifiActive
        toggleCmd.command = ["bash", "-c", root.wifiActive ? "nmcli radio wifi on" : "nmcli radio wifi off"]
        toggleCmd.running = true
    }

    function toggleBt() {
        root.btActive = !root.btActive
        toggleCmd.command = ["bash", "-c", "bluetoothctl power " + (root.btActive ? "on" : "off")]
        toggleCmd.running = true
    }

    // ── 6 TOGGLES GRID (2 COLUMNS x 3 ROWS) ──────────────────────────────────
    Grid {
        anchors.fill: parent
        columns: 2
        spacing: 10
        rowSpacing: 9

        // 1. Wi-Fi
        Rectangle {
            width: 135
            height: 48
            radius: 14
            color: root.wifiActive ? Theme.accent : Theme.alpha(Theme.surface, 0.65)
            border.color: root.wifiActive ? Theme.accent : Theme.alpha(Theme.foreground, 0.08)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }

            Row {
                anchors.centerIn: parent
                spacing: 8
                Image {
                    width: 16; height: 16
                    source: root.wifiSvg
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "Wi-Fi"
                    font.family: "Outfit"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: root.wifiActive ? Theme.background : Theme.foreground
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleWifi()
            }
        }

        // 2. Bluetooth
        Rectangle {
            width: 135
            height: 48
            radius: 14
            color: root.btActive ? Theme.accent : Theme.alpha(Theme.surface, 0.65)
            border.color: root.btActive ? Theme.accent : Theme.alpha(Theme.foreground, 0.08)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }

            Row {
                anchors.centerIn: parent
                spacing: 8
                Image {
                    width: 16; height: 16
                    source: root.btSvg
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "Bluetooth"
                    font.family: "Outfit"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: root.btActive ? Theme.background : Theme.foreground
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleBt()
            }
        }

        // 3. Caffeine (bound to hypridle)
        Rectangle {
            width: 135
            height: 48
            radius: 14
            color: root.caffeineActive ? Theme.accent : Theme.alpha(Theme.surface, 0.65)
            border.color: root.caffeineActive ? Theme.accent : Theme.alpha(Theme.foreground, 0.08)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }

            Row {
                anchors.centerIn: parent
                spacing: 8
                Image {
                    width: 16; height: 16
                    source: root.coffeeSvg
                    anchors.verticalCenter: parent.verticalCenter
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1
                    Text {
                        text: "Caffeine"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: root.caffeineActive ? Theme.background : Theme.foreground
                    }
                    Text {
                        text: root.caffeineActive ? "Awake" : "Idle On"
                        font.family: "Outfit"
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        color: root.caffeineActive ? Theme.alpha(Theme.background, 0.8) : Theme.muted
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleCaffeine()
            }
        }

        // 4. Night Light (Hyprsunset 3 stages: Off, Always On, Scheduled)
        Rectangle {
            id: nightLightCard
            width: 135
            height: 48
            radius: 14
            readonly property bool isNightOn: root.nightLightMode === "on"
            readonly property bool isNightSched: root.nightLightMode === "scheduled"
            color: isNightOn ? Theme.accent : (isNightSched ? Theme.alpha(Theme.accent, 0.35) : Theme.alpha(Theme.surface, 0.65))
            border.color: (isNightOn || isNightSched) ? Theme.accent : Theme.alpha(Theme.foreground, 0.08)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }

            Row {
                anchors.centerIn: parent
                spacing: 8
                Image {
                    width: 16; height: 16
                    source: root.moonSvg
                    anchors.verticalCenter: parent.verticalCenter
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1
                    Text {
                        text: "Night Light"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: nightLightCard.isNightOn ? Theme.background : Theme.foreground
                    }
                    Text {
                        text: nightLightCard.isNightOn ? "Always On" : (nightLightCard.isNightSched ? "Scheduled" : "Off")
                        font.family: "Outfit"
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        color: nightLightCard.isNightOn ? Theme.alpha(Theme.background, 0.8) : (nightLightCard.isNightSched ? Theme.accent : Theme.muted)
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleNightLight()
            }
        }

        // 5. DND (Do Not Disturb)
        Rectangle {
            width: 135
            height: 48
            radius: 14
            color: root.dndActive ? Theme.accent : Theme.alpha(Theme.surface, 0.65)
            border.color: root.dndActive ? Theme.accent : Theme.alpha(Theme.foreground, 0.08)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }

            Row {
                anchors.centerIn: parent
                spacing: 8
                Image {
                    width: 16; height: 16
                    source: root.dndSvg
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "DND"
                    font.family: "Outfit"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: root.dndActive ? Theme.background : Theme.foreground
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleDnd()
            }
        }

        // 6. Performance Mode (3 states: Performance, Balanced, Power-Saver)
        Rectangle {
            width: 135
            height: 48
            radius: 14
            color: root.perfMode === "performance" ? Theme.accent : (root.perfMode === "balanced" ? Theme.alpha(Theme.accent, 0.35) : Theme.alpha(Theme.surface, 0.65))
            border.color: (root.perfMode === "performance" || root.perfMode === "balanced") ? Theme.accent : Theme.alpha(Theme.foreground, 0.08)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }

            Row {
                anchors.centerIn: parent
                spacing: 8
                Image {
                    width: 16; height: 16
                    source: root.perfSvg
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: root.perfMode === "performance" ? "Performance" : (root.perfMode === "balanced" ? "Balanced" : "Power-Saver")
                    font.family: "Outfit"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: root.perfMode === "performance" ? Theme.background : Theme.foreground
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.togglePerformance()
            }
        }
    }
}
