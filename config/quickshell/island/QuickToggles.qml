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

    // Substitute currentColor dynamically so toggle icons stay crisp on both obsidian cards and bright active accent tiles.
    function tintSvg(rawTemplate, strokeCol) {
        return svgUrl(rawTemplate.replace(/currentColor/g, strokeCol))
    }

    signal openWifiDialogRequested()

    readonly property string ethernetRaw: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h16c1.1 0 2 .9 2 2v10c0 1.1-.9 2-2 2h-4v2h2v2H6v-2h2v-2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><path d="M7 9h2v4H7zM11 9h2v4h-2zM15 9h2v4h-2z"/></svg>'
    readonly property string chevronRightRaw: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 18 15 12 9 6"/></svg>'

    readonly property string wifiDisabledRaw: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><line x1="1" y1="1" x2="23" y2="23"/><path d="M16.72 11.06A10.94 10.94 0 0 1 19 12.55"/><path d="M5 12.55a10.94 10.94 0 0 1 5.17-2.39"/><path d="M10.71 5.05A16 16 0 0 1 22.58 9"/><path d="M1.42 9a15.91 15.91 0 0 1 4.7-2.88"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1.2" fill="currentColor"/></svg>'
    readonly property string wifiHighRaw: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M1.42 9a16 16 0 0 1 21.16 0"/><path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1.2" fill="currentColor"/></svg>'
    readonly property string wifiMidRaw: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1.2" fill="currentColor"/></svg>'
    readonly property string wifiLowRaw: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1.2" fill="currentColor"/></svg>'
    readonly property string wifiMinRaw: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="20" r="1.8" fill="currentColor"/></svg>'

    function getWifiSvg(signal, isEnabled, strokeCol) {
        var raw = root.wifiMinRaw
        if (!isEnabled) raw = root.wifiDisabledRaw
        else if (signal >= 75) raw = root.wifiHighRaw
        else if (signal >= 50) raw = root.wifiMidRaw
        else if (signal >= 25) raw = root.wifiLowRaw
        return tintSvg(raw, strokeCol)
    }

    readonly property string btRaw: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6.5 6.5 17.5 17.5 12 23 12 1 17.5 6.5 6.5 17.5"/></svg>'
    readonly property string coffeeRaw: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8h1a4 4 0 0 1 0 8h-1"/><path d="M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z"/><line x1="6" y1="1" x2="6" y2="4"/><line x1="10" y1="1" x2="10" y2="4"/><line x1="14" y1="1" x2="14" y2="4"/></svg>'
    readonly property string moonRaw: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>'
    readonly property string dndRaw: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M13.73 21a2 2 0 0 1-3.46 0"/><path d="M18.63 13A17.89 17.89 0 0 1 18 8"/><path d="M6.26 6.26A5.86 5.86 0 0 0 6 8c0 7-3 9-3 9h14"/><line x1="1" y1="1" x2="23" y2="23"/></svg>'
    readonly property string perfRaw: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="m12 14 4-4"/><path d="M3.34 19a10 10 0 1 1 17.32 0"/></svg>'

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    // ── STATES ───────────────────────────────────────────────────────────────
    property bool active: false
    property bool networkConnected: false
    property string networkType: "none" // "ethernet", "wifi", "none"
    property string networkName: "Wi-Fi"
    property int wifiSignal: 0
    property bool wifiActive: true
    readonly property bool isNetworkActive: networkConnected || (networkType === "wifi" && wifiActive)
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

    // DND Reader (Native Quickshell Island State - ultra lightweight bash grep)
    Process {
        id: dndReader
        command: ["bash", "-c", "grep -q '\"dnd\":\\s*true' ~/.hyprconf/hypr/.cache/dnd_state.json 2>/dev/null && echo on || echo off"]
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
        command: ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/island-network.py", "status"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var data = JSON.parse(text.trim())
                    root.networkConnected = data.connected
                    root.networkType = data.type || "none"
                    root.networkName = data.name || "Network"
                    root.wifiSignal = data.signal || 0
                    root.wifiActive = (data.wifi_enabled !== undefined) ? data.wifi_enabled : true
                } catch (e) {}
            }
        }
    }

    Process {
        id: btReader
        command: ["bash", "-c", "bluetoothctl show 2>/dev/null | grep -c 'Powered: yes'"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text) return
                root.btActive = (text.trim() === "1")
            }
        }
    }

    function refreshState() {
        if (!statusReader.running) statusReader.running = true
        if (!btReader.running) btReader.running = true
        if (!caffeineReader.running) caffeineReader.running = true
        if (!nightLightReader.running) nightLightReader.running = true
        if (!dndReader.running) dndReader.running = true
        if (!perfReader.running) perfReader.running = true
    }

    // Only poll when Island is actually open and visible!
    Timer {
        interval: 10000
        running: root.active
        repeat: true
        onTriggered: root.refreshState()
    }

    onActiveChanged: {
        if (active) {
            root.refreshState()
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
        toggleCmd.command = ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/island-network.py", "toggle-wifi"]
        toggleCmd.running = true
        statusReader.running = false
        statusReader.running = true
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

        // 1. Network Tile (Ethernet / Wi-Fi with dynamic signal & > arrow)
        Rectangle {
            id: netTile
            width: 135
            height: 48
            radius: 14
            clip: true
            readonly property bool hovered: netLeftMouse.containsMouse || arrowMouse.containsMouse
            color: root.isNetworkActive
                   ? (hovered ? Qt.lighter(Theme.accent, 1.07) : Theme.accent)
                   : (hovered ? Theme.mix(Theme.surface, Theme.accent, 0.14) : Theme.glassCard)
            border.color: root.isNetworkActive
                          ? Theme.alpha(Theme.foreground, 0.24)
                          : (hovered ? Theme.alpha(Theme.accent, 0.35) : Theme.alpha(Theme.foreground, 0.10))
            border.width: 1
            scale: (netLeftMouse.pressed || arrowMouse.pressed) ? 0.96 : (hovered ? 1.015 : 1.0)

            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }

            GlassRim {
                horizontalInset: 12
                peakOpacity: root.isNetworkActive ? 1.45 : 0.85
            }

            // Left Section: Network Status & Toggle
            Item {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: splitDivider.left

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 8
                    anchors.rightMargin: 4
                    spacing: 6

                    Image {
                        width: 16
                        height: 16
                        readonly property color iconCol: root.isNetworkActive ? Theme.background : Theme.foreground
                        source: root.networkType === "ethernet"
                                ? root.tintSvg(root.ethernetRaw, iconCol)
                                : root.getWifiSvg(root.wifiSignal, root.wifiActive, iconCol)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(10, parent.width - 22)
                        spacing: 1

                        Text {
                            text: root.networkType === "ethernet" ? "Ethernet" : "Wi-Fi"
                            font.family: "Outfit"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: root.isNetworkActive ? Theme.background : Theme.foreground
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: {
                                if (root.networkConnected) {
                                    if (root.networkType === "ethernet") return "Connected"
                                    if (root.networkName && root.networkName !== "Wi-Fi" && root.networkName !== "Network") {
                                        return root.networkName
                                    }
                                    return "Connected"
                                }
                                return root.wifiActive ? "Not joined" : "Off"
                            }
                            font.family: "Outfit"
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            color: root.isNetworkActive ? Theme.alpha(Theme.background, 0.85) : Theme.muted
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }
                }

                MouseArea {
                    id: netLeftMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.networkType === "ethernet") {
                            toggleCmd.command = ["kitty", "--title", "floating", "-e", "nmtui"]
                            toggleCmd.running = true
                        } else {
                            root.toggleWifi()
                        }
                    }
                }
            }

            // Divider Line
            Rectangle {
                id: splitDivider
                anchors.right: arrowContainer.left
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 22
                color: root.isNetworkActive ? Theme.alpha(Theme.background, 0.22) : Theme.alpha(Theme.foreground, 0.12)
            }

            // Right Section: Little Arrow '>' Button
            Item {
                id: arrowContainer
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 28

                Rectangle {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    radius: 12
                    color: arrowMouse.containsMouse ? (root.isNetworkActive ? Theme.alpha(Theme.background, 0.2) : Theme.alpha(Theme.foreground, 0.12)) : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Image {
                        anchors.centerIn: parent
                        width: 12
                        height: 12
                        source: root.tintSvg(root.chevronRightRaw, root.isNetworkActive ? Theme.background : Theme.foreground)
                        opacity: root.isNetworkActive ? 0.95 : 0.72
                    }
                }

                MouseArea {
                    id: arrowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.networkType === "ethernet") {
                            toggleCmd.command = ["kitty", "--title", "floating", "-e", "nmtui"]
                            toggleCmd.running = true
                        } else {
                            root.openWifiDialogRequested()
                        }
                    }
                }
            }
        }

        // 2. Bluetooth
        Rectangle {
            width: 135
            height: 48
            radius: 14
            clip: true
            color: root.btActive
                   ? (btMouse.containsMouse ? Qt.lighter(Theme.accent, 1.07) : Theme.accent)
                   : (btMouse.containsMouse ? Theme.mix(Theme.surface, Theme.accent, 0.14) : Theme.glassCard)
            border.color: root.btActive
                          ? Theme.alpha(Theme.foreground, 0.24)
                          : (btMouse.containsMouse ? Theme.alpha(Theme.accent, 0.35) : Theme.alpha(Theme.foreground, 0.10))
            border.width: 1
            scale: btMouse.pressed ? 0.96 : (btMouse.containsMouse ? 1.015 : 1.0)

            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }

            GlassRim {
                horizontalInset: 12
                peakOpacity: root.btActive ? 1.45 : 0.85
            }

            Row {
                anchors.centerIn: parent
                spacing: 8
                Image {
                    width: 16; height: 16
                    source: root.tintSvg(root.btRaw, root.btActive ? Theme.background : Theme.foreground)
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
                id: btMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleBt()
            }
        }

        // 3. Caffeine (bound to hypridle)
        Rectangle {
            width: 135
            height: 48
            radius: 14
            clip: true
            color: root.caffeineActive
                   ? (cafMouse.containsMouse ? Qt.lighter(Theme.accent, 1.07) : Theme.accent)
                   : (cafMouse.containsMouse ? Theme.mix(Theme.surface, Theme.accent, 0.14) : Theme.glassCard)
            border.color: root.caffeineActive
                          ? Theme.alpha(Theme.foreground, 0.24)
                          : (cafMouse.containsMouse ? Theme.alpha(Theme.accent, 0.35) : Theme.alpha(Theme.foreground, 0.10))
            border.width: 1
            scale: cafMouse.pressed ? 0.96 : (cafMouse.containsMouse ? 1.015 : 1.0)

            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }

            GlassRim {
                horizontalInset: 12
                peakOpacity: root.caffeineActive ? 1.45 : 0.85
            }

            Row {
                anchors.centerIn: parent
                spacing: 8
                Image {
                    width: 16; height: 16
                    source: root.tintSvg(root.coffeeRaw, root.caffeineActive ? Theme.background : Theme.foreground)
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
                id: cafMouse
                anchors.fill: parent
                hoverEnabled: true
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
            clip: true
            readonly property bool isNightOn: root.nightLightMode === "on"
            readonly property bool isNightSched: root.nightLightMode === "scheduled"
            color: isNightOn
                   ? (nlMouse.containsMouse ? Qt.lighter(Theme.accent, 1.07) : Theme.accent)
                   : (isNightSched
                      ? Theme.alpha(Theme.accent, nlMouse.containsMouse ? 0.44 : 0.34)
                      : (nlMouse.containsMouse ? Theme.mix(Theme.surface, Theme.accent, 0.14) : Theme.glassCard))
            border.color: (isNightOn || isNightSched)
                          ? Theme.alpha(isNightOn ? Theme.foreground : Theme.accent, 0.35)
                          : (nlMouse.containsMouse ? Theme.alpha(Theme.accent, 0.35) : Theme.alpha(Theme.foreground, 0.10))
            border.width: 1
            scale: nlMouse.pressed ? 0.96 : (nlMouse.containsMouse ? 1.015 : 1.0)

            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }

            GlassRim {
                horizontalInset: 12
                peakOpacity: nightLightCard.isNightOn ? 1.45 : 0.85
            }

            Row {
                anchors.centerIn: parent
                spacing: 8
                Image {
                    width: 16; height: 16
                    source: root.tintSvg(root.moonRaw, nightLightCard.isNightOn ? Theme.background : Theme.foreground)
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
                id: nlMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleNightLight()
            }
        }

        // 5. DND (Do Not Disturb)
        Rectangle {
            width: 135
            height: 48
            radius: 14
            clip: true
            color: root.dndActive
                   ? (dndMouse.containsMouse ? Qt.lighter(Theme.accent, 1.07) : Theme.accent)
                   : (dndMouse.containsMouse ? Theme.mix(Theme.surface, Theme.accent, 0.14) : Theme.glassCard)
            border.color: root.dndActive
                          ? Theme.alpha(Theme.foreground, 0.24)
                          : (dndMouse.containsMouse ? Theme.alpha(Theme.accent, 0.35) : Theme.alpha(Theme.foreground, 0.10))
            border.width: 1
            scale: dndMouse.pressed ? 0.96 : (dndMouse.containsMouse ? 1.015 : 1.0)

            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }

            GlassRim {
                horizontalInset: 12
                peakOpacity: root.dndActive ? 1.45 : 0.85
            }

            Row {
                anchors.centerIn: parent
                spacing: 8
                Image {
                    width: 16; height: 16
                    source: root.tintSvg(root.dndRaw, root.dndActive ? Theme.background : Theme.foreground)
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
                id: dndMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleDnd()
            }
        }

        // 6. Performance Mode (3 states: Performance, Balanced, Power-Saver)
        Rectangle {
            id: perfCard
            width: 135
            height: 48
            radius: 14
            clip: true
            readonly property bool isPerfHigh: root.perfMode === "performance"
            readonly property bool isPerfBal: root.perfMode === "balanced"
            color: perfCard.isPerfHigh
                   ? (perfMouse.containsMouse ? Qt.lighter(Theme.accent, 1.07) : Theme.accent)
                   : (perfCard.isPerfBal
                      ? Theme.alpha(Theme.accent, perfMouse.containsMouse ? 0.44 : 0.34)
                      : (perfMouse.containsMouse ? Theme.mix(Theme.surface, Theme.accent, 0.14) : Theme.glassCard))
            border.color: (perfCard.isPerfHigh || perfCard.isPerfBal)
                          ? Theme.alpha(perfCard.isPerfHigh ? Theme.foreground : Theme.accent, 0.35)
                          : (perfMouse.containsMouse ? Theme.alpha(Theme.accent, 0.35) : Theme.alpha(Theme.foreground, 0.10))
            border.width: 1
            scale: perfMouse.pressed ? 0.96 : (perfMouse.containsMouse ? 1.015 : 1.0)

            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }

            GlassRim {
                horizontalInset: 12
                peakOpacity: perfCard.isPerfHigh ? 1.45 : 0.85
            }

            Row {
                anchors.centerIn: parent
                spacing: 8
                Image {
                    width: 16; height: 16
                    source: root.tintSvg(root.perfRaw, perfCard.isPerfHigh ? Theme.background : Theme.foreground)
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: root.perfMode === "performance" ? "Performance" : (root.perfMode === "balanced" ? "Balanced" : "Power-Saver")
                    font.family: "Outfit"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: perfCard.isPerfHigh ? Theme.background : Theme.foreground
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: perfMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.togglePerformance()
            }
        }
    }
}
