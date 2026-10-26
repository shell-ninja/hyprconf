import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "."

Item {
    id: root

    readonly property real requiredWidth: {
        if (root.islandStyle === "split_wings") return (splitWingsItem && splitWingsItem.width > 0) ? Math.ceil(splitWingsItem.width + 16) : 412
        if (root.islandStyle === "orbital") return (orbitalItem && orbitalItem.width > 0) ? Math.ceil(orbitalItem.width + 16) : 340
        if (root.islandStyle === "minimal_rail") return (minimalRailItem && minimalRailItem.width > 0) ? Math.ceil(minimalRailItem.width + 16) : 582
        return (capsuleRow && capsuleRow.width > 0) ? Math.ceil(capsuleRow.width + 56) : 316
    }
    implicitWidth: requiredWidth
    implicitHeight: 36
    clip: false

    property string timeString: "12:00 PM"
    property int activeWorkspace: (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 0) ? Hyprland.focusedWorkspace.id : 1
    property bool isBottom: false
    property string dateString: ""
    property string ramString: "RAM 5.6 GB"
    property string netDownString: "0B"
    property string netUpString: "0B"
    readonly property string dayOfWeek: {
        var d = new Date()
        var days = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
        return days[d.getDay()]
    }

    readonly property var wsLabels: {
        if (root.islandStyle === "split_wings") return ["一", "二", "三", "四", "五"]
        if (root.islandStyle === "orbital") return ["1", "2", "3", "4", "5"]
        if (root.islandStyle === "minimal_rail") return ["✦", "◈", "◆", "❖", "⬡"]
        return ["一", "二", "三", "四", "五"]
    }

    readonly property string effectiveVizStyle: {
        if (root.visualizerStyle && root.visualizerStyle !== "wave") return root.visualizerStyle
        if (root.islandStyle === "minimal_rail") return "hairline"
        return "wave"
    }

    property bool hasNotification: false
    property var currentNotification: null
    property int notificationCount: 0
    // Measured height of the notification content — shell.qml reads this to size the island
    readonly property real notifContentHeight: notifContentCol.implicitHeight + 20 // 10px top + 10px bottom margin

    property bool hasOsd: false
    property string osdType: "volume"
    property real osdValue: 0.5
    property string osdLabel: ""
    property string osdIcon: ""
    property string osdSubLabel: ""
    signal triggerOsd(string type, real value, string label, string icon, string subLabel)

    property bool audioMonitorInitialized: false
    property string lastSinkState: ""
    property string lastSourceState: ""
    property bool hyprlandLayoutInitialized: false
    property string lastHyprlandLayout: ""

    property bool isTimerActive: false
    property int timerRemaining: 0
    property int timerTotal: 5
    property bool isAudioPlaying: false
    property var cavaBars: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    property bool visualizerEnabled: true
    property string visualizerStyle: "wave"
    property string islandStyle: "capsule"
    property int visualizerBarCount: 8
    property real animProgress: 0.0
    property bool matrixStreamEnabled: true

    // Volume & Battery Hardware State for Split Wings
    property real currentVolume: 0.50
    property bool isDraggingVolume: false
    property bool isMuted: false
    property bool hasBattery: false
    property int batteryPct: -1

    signal clockClicked()
    signal notificationClicked()
    signal dismissNotificationClicked()
    signal notificationHovered(bool hovered)
    signal cancelTimerClicked()
    signal minimalClockHovered(bool hovered)
    property bool isWorkspaceAreaHovered: false

    function updateWsHoverState() {
        var h = false
        if (typeof wsCapsuleHover !== "undefined" && wsCapsuleHover && wsCapsuleHover.hovered) h = true
        if (typeof wsOrbitalHover !== "undefined" && wsOrbitalHover && wsOrbitalHover.hovered) h = true
        if (typeof wsSplitHover !== "undefined" && wsSplitHover && wsSplitHover.hovered) h = true
        if (typeof wsMinimalHover !== "undefined" && wsMinimalHover && wsMinimalHover.hovered) h = true
        root.isWorkspaceAreaHovered = h
    }

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string bellSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>')
    readonly property string cameraSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/><circle cx="12" cy="13" r="4"/></svg>')
    readonly property string closeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.muted + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>')
    readonly property string chipSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="4" width="16" height="16" rx="2"/><rect x="9" y="9" width="6" height="6"/><path d="M9 1v3M15 1v3M9 20v3M15 20v3M20 9h3M20 14h3M1 9h3M1 14h3"/></svg>')
    readonly property string speakerSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14"/></svg>')
    readonly property string speakerMuteSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.muted + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><line x1="23" y1="9" x2="17" y2="15"/><line x1="17" y1="9" x2="23" y2="15"/></svg>')
    readonly property string micSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3z"/><path d="M19 10v2a7 7 0 0 1-14 0v-2"/><line x1="12" y1="19" x2="12" y2="23"/><line x1="8" y1="23" x2="16" y2="23"/></svg>')
    readonly property string micMuteSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.error + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="1" y1="1" x2="23" y2="23"/><path d="M9 9v3a3 3 0 0 0 5.12 2.12M15 9.34V5a3 3 0 0 0-5.94-.6"/><path d="M17 16.95A7 7 0 0 1 5 12v-2m14 0v2a7 7 0 0 1-.11 1.23"/><line x1="12" y1="19" x2="12" y2="23"/><line x1="8" y1="23" x2="16" y2="23"/></svg>')
    readonly property string sunSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>')
    readonly property string keyboardSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="4" width="20" height="16" rx="2" ry="2"/><line x1="6" y1="8" x2="6" y2="8"/><line x1="10" y1="8" x2="10" y2="8"/><line x1="14" y1="8" x2="14" y2="8"/><line x1="18" y1="8" x2="18" y2="8"/><line x1="6" y1="12" x2="6" y2="12"/><line x1="10" y1="12" x2="10" y2="12"/><line x1="14" y1="12" x2="14" y2="12"/><line x1="18" y1="12" x2="18" y2="12"/><line x1="8" y1="16" x2="16" y2="16"/></svg>')
    readonly property string ethernetSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h16c1.1 0 2 .9 2 2v10c0 1.1-.9 2-2 2h-4v2h2v2H6v-2h2v-2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><path d="M7 9h2v4H7zM11 9h2v4h-2zM15 9h2v4h-2z"/></svg>')
    readonly property string wifiSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M1.42 9a16 16 0 0 1 21.16 0"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1.2" fill="' + Theme.accent + '"/></svg>')

    function getWifiSvg(signal, isEnabled) {
        if (!isEnabled) {
            return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.muted + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="1" y1="1" x2="23" y2="23"/><path d="M16.72 11.06A10.94 10.94 0 0 1 19 12.55"/><path d="M5 12.55a10.94 10.94 0 0 1 5.17-2.39"/><path d="M10.71 5.05A16 16 0 0 1 22.58 9"/><path d="M1.42 9a15.91 15.91 0 0 1 4.7-2.88"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1.2" fill="' + Theme.muted + '"/></svg>')
        }
        if (signal >= 75) {
            return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1.42 9a16 16 0 0 1 21.16 0"/><path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1.2" fill="' + Theme.accent + '"/></svg>')
        } else if (signal >= 50) {
            return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1.2" fill="' + Theme.accent + '"/></svg>')
        } else if (signal >= 25) {
            return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1.2" fill="' + Theme.accent + '"/></svg>')
        } else {
            return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="20" r="1.8" fill="' + Theme.accent + '"/></svg>')
        }
    }

    property var occupiedWorkspaces: []

    Process {
        id: occupiedFetcher
        command: ["hyprctl", "workspaces", "-j"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(text.trim())
                        var occ = []
                        for (var i = 0; i < parsed.length; i++) {
                            var ws = parsed[i]
                            if (ws && ws.id > 0 && ws.windows > 0) {
                                occ.push(ws.id)
                            }
                        }
                        root.occupiedWorkspaces = occ
                    } catch(e) {}
                }
            }
        }
    }

    Timer {
        id: occupiedPollTimer
        interval: 2500
        repeat: true
        running: true
        onTriggered: {
            if (!occupiedFetcher.running) occupiedFetcher.running = true
        }
    }

    // ── NATIVE ZERO-LATENCY HYPRLAND WORKSPACE INTEGRATION ───────────────────
    Connections {
        target: Hyprland

        function onFocusedWorkspaceChanged() {
            if (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 0) {
                root.activeWorkspace = Hyprland.focusedWorkspace.id
            }
            if (!occupiedFetcher.running) occupiedFetcher.running = true
        }

        function onRawEvent(event) {
            if (event.name === "workspace" || event.name === "workspacev2") {
                var ws = parseInt(event.data, 10)
                if (!isNaN(ws) && ws > 0) {
                    root.activeWorkspace = ws
                }
                if (!occupiedFetcher.running) occupiedFetcher.running = true
            } else if (event.name === "openwindow" || event.name === "closewindow" || event.name === "movewindow" || event.name === "createworkspace" || event.name === "destroyworkspace") {
                if (!occupiedFetcher.running) occupiedFetcher.running = true
            } else if (event.name === "activelayout") {
                if (event.data && event.data.length > 0) {
                    var parts = event.data.split(",")
                    var layout = (parts.length > 1) ? parts[1].trim() : parts[0].trim()
                    if (layout.length > 0 && root.hyprlandLayoutInitialized && layout !== root.lastHyprlandLayout) {
                        root.triggerOsd("input", 0, layout, "keyboard", "Keyboard Layout")
                    }
                    root.lastHyprlandLayout = layout
                    root.hyprlandLayoutInitialized = true
                }
            }
        }
    }

    Process {
        id: wsProc
        command: []
    }

    function switchWorkspace(id) {
        root.activeWorkspace = id
        wsProc.running = false
        wsProc.command = ["hyprctl", "eval", "hl.dispatch(hl.dsp.focus({ workspace = " + id + " }))"]
        wsProc.running = true
    }

    // ── LIVE AUDIO MONITOR (ZERO-LATENCY PIPEWIRE STREAM) ────────────────────
    Process {
        id: audioMonitorProc
        command: [Quickshell.env("HOME") + "/.hyprconf/hypr/scripts/py/audio-monitor.py"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (!data || data.length === 0) return
                var line = data.trim()
                if (line.indexOf("sink:") === 0) {
                    var rest = line.substring(5)
                    var parts = rest.split(":")
                    if (parts.length >= 2) {
                        var v = parseFloat(parts[0])
                        var m = (parts[1] === "1")
                        if (!isNaN(v) && !root.isDraggingVolume) {
                            root.currentVolume = Math.max(0.0, Math.min(1.0, v))
                        }
                        root.isMuted = m
                        if (root.audioMonitorInitialized && rest !== root.lastSinkState) {
                            var pctStr = Math.round(v * 100) + "%"
                            var sIcon = m ? "volume-mute" : (v > 0.5 ? "volume-high" : (v > 0 ? "volume-low" : "volume-mute"))
                            root.triggerOsd("volume", Math.round(v * 100), m ? "Muted" : pctStr, sIcon, "")
                        }
                        root.lastSinkState = rest
                    }
                } else if (line.indexOf("source:") === 0) {
                    var rest = line.substring(7)
                    var parts = rest.split(":")
                    if (parts.length >= 2) {
                        var v = parseFloat(parts[0])
                        var m = (parts[1] === "1")
                        if (root.audioMonitorInitialized && rest !== root.lastSourceState) {
                            var pctStr = Math.round(v * 100) + "%"
                            var mIcon = m ? "mic-mute" : "mic"
                            root.triggerOsd("mic", Math.round(v * 100), m ? "Muted" : pctStr, mIcon, "")
                        }
                        root.lastSourceState = rest
                    }
                }
                if (!root.audioMonitorInitialized && root.lastSinkState.length > 0 && root.lastSourceState.length > 0) {
                    root.audioMonitorInitialized = true
                }
            }
        }
    }

    // ── HARDWARE STATUS (BATTERY DETECTION) ──────────────────────────────────
    Process {
        id: batFetcher
        command: ["python3", "-c", "import glob, os, json; bats = glob.glob('/sys/class/power_supply/BAT*/capacity'); has_bat = bool(bats and os.path.exists(bats[0])); bat_pct = int(open(bats[0]).read().strip()) if has_bat else -1; print(json.dumps({'has_bat': has_bat, 'bat_pct': bat_pct}))"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    try {
                        var d = JSON.parse(text.trim())
                        if (d.has_bat !== undefined) root.hasBattery = d.has_bat
                        if (d.bat_pct !== undefined) root.batteryPct = d.bat_pct
                    } catch(e) {}
                }
            }
        }
    }

    // ── NETWORK STATUS (ETHERNET / WI-FI) ────────────────────────────────────
    property string barNetType: "none"
    property int barNetSignal: 0
    property bool barNetConnected: false

    Process {
        id: barNetFetcher
        command: ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/island-network.py", "status"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var d = JSON.parse(text.trim())
                    root.barNetType = d.type || "none"
                    root.barNetSignal = d.signal || 0
                    root.barNetConnected = d.connected
                } catch(e) {}
            }
        }
    }

    Timer {
        id: batPollTimer
        interval: 10000
        repeat: true
        running: true
        onTriggered: {
            if (!batFetcher.running) batFetcher.running = true
            if (!barNetFetcher.running) barNetFetcher.running = true
        }
    }

    Process {
        id: volSetter
        command: []
    }

    function setVolume(pct) {
        pct = Math.max(0.0, Math.min(1.0, pct))
        root.currentVolume = pct
        root.isMuted = false
        volSetter.running = false
        volSetter.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", pct.toFixed(2)]
        volSetter.running = true
    }

    function toggleMute() {
        volSetter.running = false
        volSetter.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        volSetter.running = true
        root.isMuted = !root.isMuted
    }

    // ── 1. STANDARD COLLAPSED BAR CONTAINER (STYLE SPECIFIC ARCHITECTURE) ────
    Item {
        id: standardContainer
        anchors.fill: parent
        opacity: (root.isTimerActive || root.hasNotification || root.hasOsd) ? 0.0 : 1.0
        scale: (root.isTimerActive || root.hasNotification || root.hasOsd) ? 0.94 : 1.0
        visible: opacity > 0.001

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        // ═════════════════════════════════════════════════════════════════════
        // STYLE 1: CAPSULE (ORGANIC MONOLITHIC FLOATING PILL)
        // ═════════════════════════════════════════════════════════════════════
        Row {
            id: capsuleRow
            anchors.centerIn: parent
            spacing: 10
            clip: false
            visible: root.islandStyle === "capsule"

            AudioVisualizer {
                id: leftVisualizer
                anchors.verticalCenter: parent.verticalCenter
                active: root.isAudioPlaying && root.visualizerEnabled
                wingMode: "left"
                barCount: Math.max(2, Math.floor(root.visualizerBarCount / 2))
                style: root.effectiveVizStyle
                cavaValues: root.cavaBars
                visible: width > 0
                width: (root.isAudioPlaying && root.visualizerEnabled) ? implicitWidth : 0
                opacity: (root.isAudioPlaying && root.visualizerEnabled) ? Math.max(0.0, 1.0 - root.animProgress * 2.5) : 0.0
                clip: true
                transform: Translate {
                    x: -root.animProgress * 25
                    y: root.animProgress * 18
                }
                Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            }

            Item {
                id: wsClusterCapsule
                width: 154
                height: parent.height
                anchors.verticalCenter: parent.verticalCenter
                clip: false

                HoverHandler {
                    id: wsCapsuleHover
                    onHoveredChanged: root.updateWsHoverState()
                }

                WheelHandler {
                    onWheel: function(event) {
                        var delta = (event.angleDelta.y > 0) ? -1 : 1
                        var nextWs = Math.max(1, Math.min(5, root.activeWorkspace + delta))
                        root.switchWorkspace(nextWs)
                    }
                }

                Row {
                    spacing: 6
                    height: parent.height
                    anchors.centerIn: parent
                    clip: false

                    Repeater {
                        model: 5
                        Item {
                            readonly property int wsId: index + 1
                            readonly property bool isActive: (root.activeWorkspace === wsId)
                            readonly property bool isOccupied: (root.occupiedWorkspaces && root.occupiedWorkspaces.indexOf(wsId) !== -1)
                            readonly property string labelText: (index >= 0 && index < root.wsLabels.length) ? root.wsLabels[index] : wsId.toString()

                            width: 22
                            height: parent.height

                            Text {
                                anchors.centerIn: parent
                                text: parent.labelText
                                font.family: "Outfit"
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                color: parent.isOccupied ? Theme.secondary : Theme.foreground
                                opacity: parent.isActive ? 0.0 : (slotMouseCapsule.containsMouse ? 1.0 : (parent.isOccupied ? 0.95 : 0.55))
                                scale: slotMouseCapsule.containsMouse ? 1.2 : 1.0
                                Behavior on opacity { NumberAnimation { duration: 180 } }
                                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                width: 3
                                height: 3
                                radius: 1.5
                                color: Theme.secondary
                                visible: parent.isOccupied && !parent.isActive
                                opacity: visible ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 180 } }
                            }

                            MouseArea {
                                id: slotMouseCapsule
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: function(mouse) {
                                    mouse.accepted = true
                                    root.switchWorkspace(parent.wsId)
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: capsuleMedallion
                    readonly property int targetIndex: Math.max(0, Math.min(4, root.activeWorkspace - 1))
                    width: 38
                    height: 38
                    radius: 19
                    color: Theme.accent
                    z: 20
                    y: (parent.height - height) / 2
                    x: {
                        var sw = 22
                        var sp = 6
                        var totalW = 5 * sw + 4 * sp
                        var rowStart = (parent.width - totalW) / 2
                        var centerX = rowStart + targetIndex * (sw + sp) + sw / 2
                        return Math.round(centerX - width / 2)
                    }

                    Behavior on x {
                        NumberAnimation {
                            duration: 280
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.15
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 3
                        height: parent.height + 3
                        radius: width / 2
                        color: Theme.alpha(Theme.accent, 0.22)
                        z: -1
                    }

                    border.color: Theme.alpha(Theme.background, 0.20)
                    border.width: 1.0

                    Text {
                        anchors.centerIn: parent
                        text: (capsuleMedallion.targetIndex >= 0 && capsuleMedallion.targetIndex < root.wsLabels.length) ? root.wsLabels[capsuleMedallion.targetIndex] : root.activeWorkspace.toString()
                        font.family: "Outfit"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: Theme.background
                    }
                }
            }

            Rectangle {
                width: 1
                height: 14
                color: Theme.alpha(Theme.accent, 0.40)
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                id: capsuleClockArea
                width: capsuleClockRow.width
                height: capsuleClockRow.height
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    id: capsuleClockRow
                    spacing: 6
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: Theme.accent
                        anchors.verticalCenter: parent.verticalCenter
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.35; duration: 1400; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 1.0; duration: 1400; easing.type: Easing.InOutQuad }
                        }
                    }

                    Text {
                        text: root.timeString
                        color: Theme.accent
                        font.family: "Outfit"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        font.letterSpacing: 0.5
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.clockClicked()
                }
            }

            AudioVisualizer {
                id: rightVisualizer
                anchors.verticalCenter: parent.verticalCenter
                active: root.isAudioPlaying && root.visualizerEnabled
                wingMode: "right"
                barCount: Math.max(2, Math.floor(root.visualizerBarCount / 2))
                style: root.effectiveVizStyle
                cavaValues: root.cavaBars
                visible: width > 0
                width: (root.isAudioPlaying && root.visualizerEnabled) ? implicitWidth : 0
                opacity: (root.isAudioPlaying && root.visualizerEnabled) ? Math.max(0.0, 1.0 - root.animProgress * 2.5) : 0.0
                clip: true
                transform: Translate {
                    x: root.animProgress * 25
                    y: root.animProgress * 18
                }
                Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            }
        }



        // ═════════════════════════════════════════════════════════════════════
        // STYLE 3: ORBITAL SATELLITE (ACTION BUTTON & TOP-BORDER PEARL — IMAGE 2)
        // ═════════════════════════════════════════════════════════════════════
        Item {
            id: orbitalItem
            anchors.centerIn: parent
            width: 328
            height: 34
            clip: false
            visible: root.islandStyle === "orbital"

            // Ambient Glow Halo
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 4
                height: parent.height + 4
                radius: 19
                color: Theme.alpha(Theme.accent, 0.15)
                z: -1
            }

            // Main Pill Background
            Rectangle {
                anchors.fill: parent
                radius: 17
                color: Theme.alpha(Theme.background, 0.92)
                border.color: Theme.alpha(Theme.accent, 0.55)
                border.width: 1.2
            }

            // Main Horizontal Content Row (Matching Image 2)
            Row {
                id: orbitalContentRow
                anchors.centerIn: parent
                spacing: 10

                // 1. Action Knob Button (Circle with minus inside)
                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: Theme.accent
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.centerIn: parent
                        width: 9
                        height: 2.2
                        radius: 1.1
                        color: Theme.background
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.clockClicked()
                    }
                }

                // 2. Workspaces with Western digits 1, 2, 3, 4, 5
                Item {
                    id: wsClusterOrbital
                    width: 128
                    height: 24
                    anchors.verticalCenter: parent.verticalCenter

                    HoverHandler {
                        id: wsOrbitalHover
                        onHoveredChanged: root.updateWsHoverState()
                    }

                    WheelHandler {
                        onWheel: function(event) {
                            var delta = (event.angleDelta.y > 0) ? -1 : 1
                            var nextWs = Math.max(1, Math.min(5, root.activeWorkspace + delta))
                            root.switchWorkspace(nextWs)
                        }
                    }

                    Row {
                        id: slotsRowOrbital
                        spacing: 5
                        anchors.centerIn: parent
                        height: parent.height

                        Repeater {
                            model: 5
                            Item {
                                readonly property int wsId: index + 1
                                readonly property bool isActive: (root.activeWorkspace === wsId)
                                readonly property bool isOccupied: (root.occupiedWorkspaces && root.occupiedWorkspaces.indexOf(wsId) !== -1)
                                readonly property var digits: ["1", "2", "3", "4", "5"]
                                readonly property string labelText: (index >= 0 && index < digits.length) ? digits[index] : wsId.toString()

                                width: 20
                                height: parent.height

                                Text {
                                    anchors.centerIn: parent
                                    text: parent.labelText
                                    font.family: "Outfit"
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                    color: parent.isOccupied ? Theme.secondary : Theme.foreground
                                    opacity: parent.isActive ? 0.0 : (slotMouseOrbital.containsMouse ? 1.0 : (parent.isOccupied ? 0.95 : 0.65))
                                    scale: slotMouseOrbital.containsMouse ? 1.2 : 1.0
                                    Behavior on opacity { NumberAnimation { duration: 180 } }
                                    Behavior on scale { NumberAnimation { duration: 140 } }
                                }

                                MouseArea {
                                    id: slotMouseOrbital
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: function(mouse) {
                                        mouse.accepted = true
                                        root.switchWorkspace(parent.wsId)
                                    }
                                }
                            }
                        }
                    }

                    // Active Workspace Squircle Badge
                    Rectangle {
                        id: orbitalMedallion
                        readonly property int targetIndex: Math.max(0, Math.min(4, root.activeWorkspace - 1))
                        width: 22
                        height: 22
                        radius: 5
                        color: Theme.accent
                        z: 20
                        y: (parent.height - height) / 2
                        x: {
                            var sw = 20
                            var sp = 5
                            var totalW = 5 * sw + 4 * sp
                            var rowStart = (parent.width - totalW) / 2
                            var centerX = rowStart + targetIndex * (sw + sp) + sw / 2
                            return Math.round(centerX - width / 2)
                        }

                        Behavior on x {
                            NumberAnimation {
                                duration: 280
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.15
                            }
                        }

                        Text {
                            readonly property var digits: ["1", "2", "3", "4", "5"]
                            anchors.centerIn: parent
                            text: (orbitalMedallion.targetIndex >= 0 && orbitalMedallion.targetIndex < digits.length) ? digits[orbitalMedallion.targetIndex] : root.activeWorkspace.toString()
                            font.family: "Outfit"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: Theme.background
                        }
                    }
                }

                // 3. Vertical hairline divider |
                Rectangle {
                    width: 1
                    height: 14
                    color: Theme.alpha(Theme.accent, 0.40)
                    anchors.verticalCenter: parent.verticalCenter
                }

                // 4. Notification Bell Icon with Dynamic Count Badge
                Item {
                    id: orbitalBellContainer
                    width: (root.notificationCount > 0) ? 20 : 16
                    height: 18
                    anchors.verticalCenter: parent.verticalCenter
                    clip: false
                    Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    Image {
                        id: orbitalBellImg
                        width: 14
                        height: 14
                        source: root.bellSvg
                        anchors.centerIn: parent
                        opacity: (root.notificationCount > 0) ? 1.0 : 0.70
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                    }

                    // Notification Dot Badge (Shows number of notifications)
                    Rectangle {
                        id: orbitalNotifBadge
                        visible: root.notificationCount > 0
                        opacity: visible ? 1.0 : 0.0
                        scale: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

                        // Overlap top-right corner of bell
                        anchors.top: orbitalBellImg.top
                        anchors.topMargin: -4
                        anchors.right: orbitalBellImg.right
                        anchors.rightMargin: -6

                        width: Math.max(13, notifCountText.implicitWidth + 5)
                        height: 13
                        radius: 6.5
                        color: Theme.error
                        border.color: Theme.background
                        border.width: 1.2
                        z: 10

                        // Soft ambient breathing pulse when unread notifications exist
                        SequentialAnimation on scale {
                            running: root.notificationCount > 0
                            loops: Animation.Infinite
                            NumberAnimation { to: 1.15; duration: 1200; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 1.0; duration: 1200; easing.type: Easing.InOutQuad }
                        }

                        Text {
                            id: notifCountText
                            anchors.centerIn: parent
                            text: root.notificationCount > 99 ? "99+" : root.notificationCount.toString()
                            font.family: "Outfit"
                            font.pixelSize: 8
                            font.weight: Font.Black
                            color: "#ffffff"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            root.notificationClicked()
                        }
                    }
                }

                // 5. Time Text (11:08 PM)
                Text {
                    text: root.timeString
                    font.family: "Outfit"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: Theme.accent
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.clockClicked()
                    }
                }
            }

            // The Protruding Satellite Pearl (overlaps the top border right above active workspace!)
            Item {
                id: orbitalPearl
                z: 40
                width: 8
                height: 8
                y: -4
                x: {
                    var wsClusterX = (orbitalItem.width - orbitalContentRow.width) / 2 + 24 + 10
                    return wsClusterX + orbitalMedallion.x + orbitalMedallion.width / 2 - width / 2
                }

                Behavior on x {
                    NumberAnimation {
                        duration: 280
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.15
                    }
                }

                // Diffuse glowing halo ring
                Rectangle {
                    anchors.centerIn: parent
                    width: 13
                    height: 13
                    radius: 6.5
                    color: Theme.alpha(Theme.accent, 0.28)
                    border.color: Theme.alpha(Theme.accent, 0.60)
                    border.width: 1
                }

                // Solid radiant center pearl
                Rectangle {
                    anchors.centerIn: parent
                    width: 6.5
                    height: 6.5
                    radius: 3.25
                    color: Theme.accent
                }
            }
        }

        // ═════════════════════════════════════════════════════════════════════
        // STYLE 4: SPLIT WINGS (ADAPTIVE DESKTOP & LAPTOP TRIPARTITE — IMAGE 3)
        // ═════════════════════════════════════════════════════════════════════
        Item {
            id: splitWingsItem
            anchors.centerIn: parent
            width: 396
            height: 42
            clip: false
            visible: root.islandStyle === "split_wings"

            readonly property real wingW: 174
            readonly property real wingH: 34
            readonly property real orbDiameter: 42

            // ── 1. LEFT WING: VOLUME CONTROLLER & LEVEL BARS ─────────────────
            Item {
                id: splitLeftWing
                x: 0
                y: (parent.height - parent.wingH) / 2
                width: parent.wingW
                height: parent.wingH

                // Concave Hugging Silhouette with Rounded Fillet Shoulders
                Shape {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.samples: 4

                    ShapePath {
                        strokeColor: Theme.alpha(Theme.accent, 0.55)
                        strokeWidth: 1.2
                        fillColor: Theme.alpha(Theme.background, 0.94)
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin

                        // 1. Start at top-left after outer pill cap
                        startX: 16
                        startY: 1

                        // 2. Top edge with subtle streamline flare
                        PathLine {
                            x: splitLeftWing.width - 14
                            y: 0.5
                        }

                        // 3. Top-right rounded shoulder (convex fillet, r=10)
                        PathCubic {
                            x: splitLeftWing.width - 1.5
                            y: 9
                            control1X: splitLeftWing.width - 4
                            control1Y: 0.5
                            control2X: splitLeftWing.width - 0.5
                            control2Y: 4.5
                        }

                        // 4. Concave arc hugging center circle (curving inward towards the volume bars)
                        PathCubic {
                            x: splitLeftWing.width - 1.5
                            y: splitLeftWing.height - 9
                            control1X: splitLeftWing.width - 3.2
                            control1Y: 13.5
                            control2X: splitLeftWing.width - 3.2
                            control2Y: splitLeftWing.height - 13.5
                        }

                        // 5. Bottom-right rounded shoulder (convex fillet, r=10)
                        PathCubic {
                            x: splitLeftWing.width - 14
                            y: splitLeftWing.height - 0.5
                            control1X: splitLeftWing.width - 0.5
                            control1Y: splitLeftWing.height - 4.5
                            control2X: splitLeftWing.width - 4
                            control2Y: splitLeftWing.height - 0.5
                        }

                        // 6. Bottom edge running back to left cap
                        PathLine {
                            x: 16
                            y: splitLeftWing.height - 1
                        }

                        // 7. Left semi-circular pill cap
                        PathArc {
                            x: 16
                            y: 1
                            radiusX: 16
                            radiusY: 16
                            direction: PathArc.Clockwise
                        }
                    }
                }

                // Left Wing Content Row
                Row {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -4
                    spacing: 7
                    height: parent.height

                    // A. Speaker Icon (Toggle Mute)
                    Item {
                        width: 18
                        height: 18
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            anchors.centerIn: parent
                            width: 15
                            height: 15
                            source: root.isMuted ? root.speakerMuteSvg : root.speakerSvg
                            opacity: root.isMuted ? 0.45 : 1.0
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleMute()
                        }
                    }

                    // B. Interactive Volume Slider
                    Item {
                        id: volumeSliderArea
                        width: 78
                        height: 18
                        anchors.verticalCenter: parent.verticalCenter

                        // Track Background
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 3.5
                            radius: 1.75
                            color: Theme.alpha(Theme.foreground, 0.20)
                        }

                        // Active Volume Fill
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(0, Math.min(parent.width, parent.width * (root.isMuted ? 0 : root.currentVolume)))
                            height: 3.5
                            radius: 1.75
                            color: Theme.accent
                        }

                        // Circular Slider Thumb
                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            color: Theme.accent
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(volumeSliderArea.width - width, volumeSliderArea.width * (root.isMuted ? 0 : root.currentVolume) - width / 2))

                            border.color: Theme.background
                            border.width: 1.2

                            Behavior on x {
                                enabled: !root.isDraggingVolume
                                NumberAnimation { duration: 120 }
                            }
                        }

                        MouseArea {
                            id: volMouseArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true

                            function updateFromPos(mouseX) {
                                var ratio = Math.max(0.0, Math.min(1.0, mouseX / volumeSliderArea.width))
                                root.setVolume(ratio)
                            }

                            onPressed: function(mouse) {
                                root.isDraggingVolume = true
                                updateFromPos(mouse.x)
                            }

                            onReleased: function(mouse) {
                                root.isDraggingVolume = false
                            }

                            onCanceled: {
                                root.isDraggingVolume = false
                            }

                            onPositionChanged: function(mouse) {
                                if (pressed) {
                                    updateFromPos(mouse.x)
                                }
                            }

                            WheelHandler {
                                onWheel: function(event) {
                                    var delta = (event.angleDelta.y > 0) ? 0.05 : -0.05
                                    root.setVolume(root.currentVolume + delta)
                                }
                            }
                        }
                    }

                    // C. 3 Stepped Level Bars (  ▂ ▅ )
                    Row {
                        spacing: 2.2
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            width: 2.5
                            height: 4
                            radius: 1
                            color: Theme.accent
                            opacity: (!root.isMuted && root.currentVolume > 0.05) ? 1.0 : 0.25
                            anchors.bottom: parent.bottom
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                        Rectangle {
                            width: 2.5
                            height: 8
                            radius: 1
                            color: Theme.accent
                            opacity: (!root.isMuted && root.currentVolume > 0.35) ? 1.0 : 0.25
                            anchors.bottom: parent.bottom
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                        Rectangle {
                            width: 2.5
                            height: 12
                            radius: 1
                            color: Theme.accent
                            opacity: (!root.isMuted && root.currentVolume > 0.70) ? 1.0 : 0.25
                            anchors.bottom: parent.bottom
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }
                }
            }

            // ── 2. CENTER ORB: ACTIVE WORKSPACE MEDALLION ────────────────────
            Item {
                id: splitCenterOrb
                anchors.centerIn: parent
                width: parent.orbDiameter
                height: parent.orbDiameter
                z: 20

                // Ambient glow halo
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 4
                    height: parent.height + 4
                    radius: width / 2
                    color: Theme.alpha(Theme.accent, 0.22)
                    z: -1
                }

                // Solid Accent Disc
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Theme.accent
                    border.color: Theme.alpha(Theme.background, 0.30)
                    border.width: 1.2

                    Text {
                        anchors.centerIn: parent
                        readonly property var labels: ["一", "二", "三", "四", "五"]
                        readonly property int idx: Math.max(0, Math.min(4, root.activeWorkspace - 1))
                        text: (idx >= 0 && idx < labels.length) ? labels[idx] : root.activeWorkspace.toString()
                        font.family: "Outfit"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        color: Theme.background
                    }
                }

                HoverHandler {
                    id: wsSplitHover
                    onHoveredChanged: root.updateWsHoverState()
                }

                WheelHandler {
                    onWheel: function(event) {
                        var delta = (event.angleDelta.y > 0) ? -1 : 1
                        var nextWs = Math.max(1, Math.min(5, root.activeWorkspace + delta))
                        root.switchWorkspace(nextWs)
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var nextWs = (root.activeWorkspace % 5) + 1
                        root.switchWorkspace(nextWs)
                    }
                }
            }

            // ── 3. RIGHT WING: CLOCK & ADAPTIVE DESKTOP (WIFI) / LAPTOP (BATTERY) ─
            Item {
                id: splitRightWing
                x: parent.width - parent.wingW
                y: (parent.height - parent.wingH) / 2
                width: parent.wingW
                height: parent.wingH

                // Concave Hugging Silhouette with Rounded Fillet Shoulders
                Shape {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.samples: 4

                    ShapePath {
                        strokeColor: Theme.alpha(Theme.accent, 0.55)
                        strokeWidth: 1.2
                        fillColor: Theme.alpha(Theme.background, 0.94)
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin

                        // 1. Start on top edge after top-left rounded shoulder
                        startX: 14
                        startY: 0.5

                        // 2. Top edge running right to outer pill cap
                        PathLine {
                            x: splitRightWing.width - 16
                            y: 1
                        }

                        // 3. Right semi-circular pill cap
                        PathArc {
                            x: splitRightWing.width - 16
                            y: splitRightWing.height - 1
                            radiusX: 16
                            radiusY: 16
                            direction: PathArc.Clockwise
                        }

                        // 4. Bottom edge running left to bottom-left corner
                        PathLine {
                            x: 14
                            y: splitRightWing.height - 0.5
                        }

                        // 5. Bottom-left rounded shoulder (convex fillet, r=10)
                        PathCubic {
                            x: 1.5
                            y: splitRightWing.height - 9
                            control1X: 4
                            control1Y: splitRightWing.height - 0.5
                            control2X: 0.5
                            control2Y: splitRightWing.height - 4.5
                        }

                        // 6. Concave arc hugging center circle (curving inward towards the clock)
                        PathCubic {
                            x: 1.5
                            y: 9
                            control1X: 3.2
                            control1Y: splitRightWing.height - 13.5
                            control2X: 3.2
                            control2Y: 13.5
                        }

                        // 7. Top-left rounded shoulder (convex fillet, r=10)
                        PathCubic {
                            x: 14
                            y: 0.5
                            control1X: 0.5
                            control1Y: 4.5
                            control2X: 4
                            control2Y: 0.5
                        }
                    }
                }

                // Right Wing Content Row
                Row {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: 4
                    spacing: 7
                    height: parent.height

                    // A. Breathing Status Dot
                    Rectangle {
                        width: 5
                        height: 5
                        radius: 2.5
                        color: Theme.accent
                        anchors.verticalCenter: parent.verticalCenter
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.35; duration: 1400; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 1.0; duration: 1400; easing.type: Easing.InOutQuad }
                        }
                    }

                    // B. Time Text (11:21 PM)
                    Text {
                        text: root.timeString
                        color: Theme.accent
                        font.family: "Outfit"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        font.letterSpacing: 0.5
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.clockClicked()
                        }
                    }

                    // C. Vertical Hairline Divider |
                    Rectangle {
                        width: 1
                        height: 14
                        color: Theme.alpha(Theme.foreground, 0.22)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // D. Adaptive Right Module:
                    // If Desktop / No Battery: Ethernet or Wi-Fi Icon
                    Item {
                        width: 18
                        height: 18
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !root.hasBattery || root.batteryPct < 0

                        Image {
                            anchors.centerIn: parent
                            width: 15
                            height: 15
                            source: root.barNetType === "ethernet" ? root.ethernetSvg : root.getWifiSvg(root.barNetSignal, true)
                        }
                    }

                    // If Laptop / Battery Exists: Battery Icon + 78% (Matching LAPTOP Image)
                    Row {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.hasBattery && root.batteryPct >= 0

                        // Vector Battery Gauge
                        Item {
                            width: 22
                            height: 12
                            anchors.verticalCenter: parent.verticalCenter

                            // Battery Shell
                            Rectangle {
                                width: 19
                                height: 11
                                radius: 2.5
                                color: "transparent"
                                border.color: Theme.accent
                                border.width: 1.2
                                anchors.verticalCenter: parent.verticalCenter

                                // Fill Level
                                Rectangle {
                                    x: 2
                                    y: 2
                                    width: Math.max(1, Math.min(15, 15 * (root.batteryPct / 100.0)))
                                    height: 7
                                    radius: 1
                                    color: (root.batteryPct <= 15) ? Theme.error : Theme.accent
                                }
                            }

                            // Battery Terminal Nub
                            Rectangle {
                                x: 19
                                width: 2
                                height: 5
                                radius: 0.8
                                color: Theme.accent
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Battery Percentage Text (78%)
                        Text {
                            text: (root.batteryPct >= 0 ? root.batteryPct : 78) + "%"
                            color: Theme.accent
                            font.family: "Outfit"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }



        // ═════════════════════════════════════════════════════════════════════
        // STYLE 4: MINIMAL DUAL-RAIL (ANIMATED RYOKU MATRIX CONVEYOR STREAM)
        // ═════════════════════════════════════════════════════════════════════
        Item {
            id: minimalRailItem
            anchors.centerIn: parent
            width: minimalContentRow.width
            height: 32
            visible: root.islandStyle === "minimal_rail"

            // ═════════════════════════════════════════════════════════════════════
            // ✦ RYOKU MATRIX STREAM BRIDGE (Between Modules)
            // ═════════════════════════════════════════════════════════════════════
            component RyokuStreamBridge: Item {
                id: bridgeItem
                width: 76
                height: 18
                anchors.verticalCenter: parent.verticalCenter
                clip: true
                property bool reverse: false
                property int streamDuration: 1800

                // 1. Single Straight Center Line (Matching Reference Screenshot)
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 1.2
                    color: Theme.alpha(Theme.foreground, 0.22)
                }

                // 2. Static Ambient Constellation Dot Nodes on the Line
                Item {
                    anchors.fill: parent

                    Rectangle {
                        x: Math.round(parent.width * 0.26 - width / 2)
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2.2
                        height: 2.2
                        radius: 1.1
                        color: Theme.alpha(Theme.foreground, 0.35)
                    }

                    Rectangle {
                        x: Math.round(parent.width * 0.74 - width / 2)
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2.2
                        height: 2.2
                        radius: 1.1
                        color: Theme.alpha(Theme.foreground, 0.35)
                    }
                }

                // 3. Static minimal indicator when stream animation is toggled off
                Item {
                    anchors.centerIn: parent
                    width: 10
                    height: 10
                    visible: !root.matrixStreamEnabled
                    opacity: visible ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 180 } }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 8
                        height: 8
                        radius: 4
                        color: Theme.alpha(Theme.accent, 0.25)
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: 3.2
                        height: 3.2
                        radius: 1.6
                        color: Theme.accent
                    }
                }

                // 4. Dynamic Animated Glowing Dot/Particle Nodes Traveling on the Straight Line
                Item {
                    id: animStreamContainer
                    anchors.fill: parent
                    visible: root.matrixStreamEnabled
                    opacity: visible ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 180 } }

                    property real streamPhase: 0.0
                    NumberAnimation on streamPhase {
                        from: 0.0
                        to: 1.0
                        duration: bridgeItem.streamDuration
                        loops: Animation.Infinite
                        running: root.matrixStreamEnabled && minimalRailItem.visible
                        easing.type: Easing.Linear
                    }

                    Repeater {
                        model: 3
                        Item {
                            id: particleItem
                            readonly property real offset: index * 0.333
                            readonly property real progress: (animStreamContainer.streamPhase + offset) % 1.0
                            readonly property real nodeSpan: 24

                            // Both bars move towards each other (converging at center clock)
                            x: bridgeItem.reverse ?
                                ((1.0 - progress) * (bridgeItem.width + nodeSpan) - nodeSpan) :
                                (progress * (bridgeItem.width + nodeSpan) - nodeSpan)

                            anchors.verticalCenter: parent.verticalCenter
                            width: nodeSpan
                            height: 16

                            // Smooth fade in as it enters the bridge, fade out as it reaches the capsule
                            opacity: {
                                if (progress < 0.16) return progress / 0.16
                                if (progress > 0.84) return (1.0 - progress) / 0.16
                                return 1.0
                            }

                            // Alternating particle styles: index 0 & 2 are glowing halo nodes, index 1 is satellite dots
                            readonly property bool isHaloNode: (index % 2 === 0)

                            // ── GLOWING HALO PARTICLE (Like in Reference Image) ──
                            Item {
                                anchors.centerIn: parent
                                width: 14
                                height: 14
                                visible: particleItem.isHaloNode

                                // Outer diffuse glow halo
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: Theme.alpha(Theme.accent, 0.22)
                                }

                                // Mid radiant corona ring
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: Theme.alpha(Theme.accent, 0.50)
                                }

                                // High-intensity center core dot
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 3.4
                                    height: 3.4
                                    radius: 1.7
                                    color: "#ffffff"
                                }
                            }

                            // ── SATELLITE MICRO-PARTICLES (Paired dots on line) ──
                            Row {
                                anchors.centerIn: parent
                                spacing: 5
                                visible: !particleItem.isHaloNode

                                Rectangle {
                                    width: 2.2
                                    height: 2.2
                                    radius: 1.1
                                    color: Theme.alpha(Theme.accent, 0.85)
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Item {
                                    width: 8
                                    height: 8
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: Theme.alpha(Theme.accent, 0.35)
                                    }
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 3.2
                                        height: 3.2
                                        radius: 1.6
                                        color: Theme.accent
                                    }
                                }

                                Rectangle {
                                    width: 2.2
                                    height: 2.2
                                    radius: 1.1
                                    color: Theme.alpha(Theme.accent, 0.85)
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }
                }
            }

            Row {
                id: minimalContentRow
                anchors.centerIn: parent
                spacing: 0
                z: 10

                // ── Module 1: Celestial Workspace Cluster (Capsule 1) ───────
                Rectangle {
                    id: wsClusterMinimal
                    width: 136
                    height: 28
                    radius: 14
                    color: Theme.alpha(Theme.background, 0.92)
                    border.color: Theme.alpha(Theme.foreground, 0.16)
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter

                    HoverHandler {
                        id: wsMinimalHover
                        onHoveredChanged: root.updateWsHoverState()
                    }

                    WheelHandler {
                        onWheel: function(event) {
                            var delta = (event.angleDelta.y > 0) ? -1 : 1
                            var nextWs = Math.max(1, Math.min(5, root.activeWorkspace + delta))
                            root.switchWorkspace(nextWs)
                        }
                    }

                    Row {
                        spacing: 4
                        height: parent.height
                        anchors.centerIn: parent

                        Repeater {
                            model: 5
                            Item {
                                readonly property int wsId: index + 1
                                readonly property bool isActive: (root.activeWorkspace === wsId)
                                readonly property bool isOccupied: (root.occupiedWorkspaces && root.occupiedWorkspaces.indexOf(wsId) !== -1)
                                readonly property var glyphs: ["✦", "◈", "◆", "❖", "⬡"]
                                readonly property string labelText: (index >= 0 && index < glyphs.length) ? glyphs[index] : wsId.toString()

                                width: 22
                                height: parent.height

                                Text {
                                    anchors.centerIn: parent
                                    text: parent.labelText
                                    font.family: "Outfit"
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                    color: parent.isOccupied ? Theme.secondary : Theme.foreground
                                    opacity: parent.isActive ? 0.0 : (slotMouseMinimal.containsMouse ? 1.0 : (parent.isOccupied ? 0.95 : 0.40))
                                    scale: slotMouseMinimal.containsMouse ? 1.2 : 1.0
                                    Behavior on opacity { NumberAnimation { duration: 180 } }
                                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 2
                                    width: 2.5
                                    height: 2.5
                                    radius: 1.25
                                    color: Theme.secondary
                                    visible: parent.isOccupied && !parent.isActive
                                    opacity: visible ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 180 } }
                                }

                                MouseArea {
                                    id: slotMouseMinimal
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: function(mouse) {
                                        mouse.accepted = true
                                        root.switchWorkspace(parent.wsId)
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: minimalMedallion
                        readonly property int targetIndex: Math.max(0, Math.min(4, root.activeWorkspace - 1))
                        width: 26
                        height: 20
                        radius: 10
                        color: Theme.accent
                        z: 20
                        y: (parent.height - height) / 2
                        x: {
                            var sw = 22
                            var sp = 4
                            var totalW = 5 * sw + 4 * sp
                            var rowStart = (parent.width - totalW) / 2
                            var centerX = rowStart + targetIndex * (sw + sp) + sw / 2
                            return Math.round(centerX - width / 2)
                        }

                        Behavior on x {
                            NumberAnimation {
                                duration: 280
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.15
                            }
                        }

                        Text {
                            readonly property var glyphs: ["✦", "◈", "◆", "❖", "⬡"]
                            anchors.centerIn: parent
                            text: (minimalMedallion.targetIndex >= 0 && minimalMedallion.targetIndex < glyphs.length) ? glyphs[minimalMedallion.targetIndex] : root.activeWorkspace.toString()
                            font.family: "Outfit"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: Theme.background
                        }
                    }
                }

                // ── Conduit 1: Forward Ryoku Stream (Workspaces -> Clock) ──
                RyokuStreamBridge {
                    id: bridgeWsToClock
                    reverse: false
                }

                // ── Module 2: Swiss Minimal Clock & Day (Capsule 2) ────────
                Rectangle {
                    id: minimalClockModule
                    width: minimalClockText.implicitWidth + 28
                    height: 28
                    radius: 14
                    color: clockHover.hovered ? Theme.alpha(Theme.background, 0.98) : Theme.alpha(Theme.background, 0.92)
                    border.color: clockHover.hovered ? Theme.alpha(Theme.accent, 0.60) : Theme.alpha(Theme.foreground, 0.16)
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        id: minimalClockText
                        anchors.centerIn: parent
                        text: root.timeString + " • " + root.dayOfWeek
                        color: Theme.accent
                        font.family: "Outfit"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }

                    HoverHandler {
                        id: clockHover
                        onHoveredChanged: {
                            root.minimalClockHovered(hovered)
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.clockClicked()
                    }
                }

                // ── Conduit 2: Inward Ryoku Stream (Net Speed -> Clock) ────
                RyokuStreamBridge {
                    id: bridgeClockToNet
                    reverse: true
                }

                // ── Module 3: Internet Bandwidth Badge (Capsule 3) ─────────
                Rectangle {
                    id: minimalNetBadge
                    width: Math.max(136, netContentRow.implicitWidth + 24)
                    height: 28
                    radius: 14
                    color: Theme.alpha(Theme.background, 0.92)
                    border.color: Theme.alpha(Theme.foreground, 0.16)
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        id: netContentRow
                        anchors.centerIn: parent
                        spacing: 8

                        // Download Speed (Matching Clock Font Size 12 & Color Theme.accent)
                        Row {
                            spacing: 3
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: "↓"
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: Theme.accent
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: root.netDownString
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: Theme.accent
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Subtle Divider Bar
                        Rectangle {
                            width: 1
                            height: 10
                            radius: 0.5
                            color: Theme.alpha(Theme.accent, 0.22)
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Upload Speed (Matching Clock Font Size 12, Slightly Muter Accent Color)
                        Row {
                            spacing: 3
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: "↑"
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: Theme.alpha(Theme.accent, 0.60)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: root.netUpString
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: Theme.alpha(Theme.accent, 0.60)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }
        }
    }

    // ── 2. DYNAMIC ISLAND EXPANDED NOTIFICATION POPUP VIEW ────────────────────
    Item {
        id: notificationRow
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 14
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        opacity: (!root.isTimerActive && !root.hasOsd && root.hasNotification) ? 1.0 : 0.0
        scale: (!root.isTimerActive && !root.hasOsd && root.hasNotification) ? 1.0 : 0.94
        visible: opacity > 0.001

        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        Row {
            id: notifInnerRow
            anchors.fill: parent
            spacing: 12

            // Left: Large Squircle Notification / App Icon Badge
            Rectangle {
                id: notifIconBadge
                width: 38
                height: 38
                radius: 12
                color: Theme.alpha(Theme.accent, 0.16)
                border.color: Theme.alpha(Theme.accent, 0.38)
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter
                clip: true

                Image {
                    id: notifImg
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    fillMode: Image.PreserveAspectFit
                    source: (root.currentNotification && root.currentNotification.icon) ? root.currentNotification.icon : ""
                    visible: status === Image.Ready && source != ""
                }

                Image {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: root.bellSvg
                    visible: !notifImg.visible
                }
            }

            // Middle: Detailed Notification Column
            Column {
                id: notifContentCol
                width: parent.width - notifIconBadge.width - notifDismissBtn.width - 24
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                // Header Row: App Name + Bullet + Timestamp
                Row {
                    spacing: 6
                    width: parent.width

                    Text {
                        text: {
                            if (!root.currentNotification) return "NOTIFICATION"
                            var a = root.currentNotification.app || "NOTIFICATION"
                            return a.toUpperCase()
                        }
                        font.family: "Outfit"
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.6
                        color: Theme.alpha(Theme.foreground, 0.55)
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                    }

                    Text {
                        text: "•"
                        font.pixelSize: 8
                        color: Theme.alpha(Theme.foreground, 0.30)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Now"
                        font.family: "Outfit"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: Theme.accent
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Summary / Title
                Text {
                    text: (root.currentNotification && root.currentNotification.summary) ? root.currentNotification.summary : "Notification"
                    font.family: "Outfit"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: Theme.foreground
                    elide: Text.ElideRight
                    width: parent.width
                    maximumLineCount: 1
                }

                // Detailed Message Body (Wrapped for full viewing)
                Text {
                    text: {
                        if (!root.currentNotification) return ""
                        return root.currentNotification.body || ""
                    }
                    font.family: "Outfit"
                    font.pixelSize: 11
                    font.weight: Font.Normal
                    lineHeight: 1.15
                    color: Theme.alpha(Theme.foreground, 0.78)
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    width: parent.width
                    visible: text.length > 0
                }

                // Action Buttons Row (only shown when notification has actions)
                Row {
                    id: notifActionsRow
                    spacing: 6
                    width: parent.width
                    visible: root.currentNotification &&
                             root.currentNotification.actions &&
                             root.currentNotification.actions.length > 0

                    Repeater {
                        model: (root.currentNotification && root.currentNotification.actions)
                               ? root.currentNotification.actions
                               : []

                        delegate: Rectangle {
                            required property var modelData
                            height: 20
                            width: Math.min(actionLabel.implicitWidth + 14, 120)
                            radius: 10
                            color: actionBtnMouse.containsMouse
                                   ? Theme.alpha(Theme.accent, 0.28)
                                   : Theme.alpha(Theme.accent, 0.12)
                            border.color: actionBtnMouse.containsMouse
                                          ? Theme.alpha(Theme.accent, 0.60)
                                          : Theme.alpha(Theme.accent, 0.28)
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                id: actionLabel
                                anchors.centerIn: parent
                                text: modelData.text || ""
                                font.family: "Outfit"
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                color: Theme.accent
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            MouseArea {
                                id: actionBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                preventStealing: true
                                onClicked: function(mouse) {
                                    mouse.accepted = true
                                    // Invoke the Quickshell NotificationAction
                                    try { modelData.action.invoke() } catch(e) {}
                                    // Dismiss popup after invoking
                                    root.dismissNotificationClicked()
                                }
                            }
                        }
                    }
                }
            }

            // Right: Quick Dismiss Button (✕)
            Rectangle {
                id: notifDismissBtn
                z: 100
                width: 24
                height: 24
                radius: 12
                color: dismissMouse.containsMouse ? Theme.alpha("#ef4444", 0.20) : Theme.alpha(Theme.foreground, 0.08)
                border.width: 1
                border.color: dismissMouse.containsMouse ? Theme.alpha("#ef4444", 0.40) : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.centerIn: parent
                    width: 10
                    height: 10
                    source: root.closeSvg
                    sourceSize: Qt.size(20, 20)
                }

                MouseArea {
                    id: dismissMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true
                    onClicked: function(mouse) {
                        mouse.accepted = true
                        root.dismissNotificationClicked()
                    }
                }
            }
        }

        // Full toast mouse area: clicking body dismisses the notification
        // (does NOT expand the island — use the ✕ button or action buttons instead)
        MouseArea {
            id: notifPillMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            z: -1
            onEntered: root.notificationHovered(true)
            onExited: root.notificationHovered(false)
            onClicked: root.dismissNotificationClicked()
        }
    }

    // ── 3. SCREENSHOT COUNTDOWN TIMER VIEW ───────────────────────────────────
    Item {
        id: timerRow
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        opacity: root.isTimerActive ? 1.0 : 0.0
        scale: root.isTimerActive ? 1.0 : 0.94
        visible: opacity > 0.001

        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        Row {
            anchors.fill: parent
            spacing: 8

            // Left: Glowing Camera badge with breathing pulse ring
            Rectangle {
                id: timerCameraBadge
                width: 24
                height: 24
                radius: 12
                color: Theme.alpha(Theme.accent, 0.20)
                border.color: Theme.alpha(Theme.accent, 0.50)
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.centerIn: parent
                    width: 13
                    height: 13
                    source: root.cameraSvg
                }

                // Ambient pulse ring
                Rectangle {
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    radius: 14
                    color: "transparent"
                    border.color: Theme.alpha(Theme.accent, 0.40)
                    border.width: 1

                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        running: root.isTimerActive
                        NumberAnimation { from: 1.0; to: 1.25; duration: 750; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 1.25; to: 1.0; duration: 750; easing.type: Easing.InOutQuad }
                    }
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: root.isTimerActive
                        NumberAnimation { from: 0.6; to: 0.0; duration: 750; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 0.0; to: 0.6; duration: 750; easing.type: Easing.InOutQuad }
                    }
                }
            }

            // Middle: Label, Countdown Pill & Progress Track
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                width: parent.width - timerCameraBadge.width - cancelBtn.width - 16

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Capturing in"
                    font.family: "Outfit"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: Theme.alpha(Theme.foreground, 0.85)
                }

                // Number badge with pop animation on tick
                Rectangle {
                    id: timerNumPill
                    anchors.verticalCenter: parent.verticalCenter
                    height: 20
                    width: timerNumText.width + 12
                    radius: 10
                    color: Theme.alpha(Theme.accent, 0.22)
                    border.color: Theme.accent
                    border.width: 1

                    Text {
                        id: timerNumText
                        anchors.centerIn: parent
                        text: root.timerRemaining + "s"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Theme.accent

                        transformOrigin: Item.Center
                    }

                    SequentialAnimation {
                        id: numPopAnim
                        NumberAnimation { target: timerNumText; property: "scale"; from: 1.4; to: 1.0; duration: 220; easing.type: Easing.OutBack }
                    }
                }

                // Mini horizontal progress line
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 3
                    width: 44
                    radius: 1.5
                    color: Theme.alpha(Theme.foreground, 0.15)
                    clip: true

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        radius: 1.5
                        color: Theme.accent
                        width: parent.width * Math.max(0.0, Math.min(1.0, root.timerRemaining / Math.max(1, root.timerTotal)))

                        Behavior on width {
                            NumberAnimation { duration: 900; easing.type: Easing.Linear }
                        }
                    }
                }
            }

            // Right: Abort / Cancel Button (✕)
            Rectangle {
                id: cancelBtn
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22
                radius: 11
                color: cancelMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.16) : Theme.alpha(Theme.surface, 0.6)
                border.color: cancelMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.35) : Theme.alpha(Theme.foreground, 0.12)
                border.width: 1

                Image {
                    anchors.centerIn: parent
                    width: 10
                    height: 10
                    source: root.closeSvg
                }

                MouseArea {
                    id: cancelMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cancelTimerClicked()
                }
            }
        }
    }

    onTimerRemainingChanged: {
        if (root.isTimerActive) {
            numPopAnim.restart()
        }
    }

    // ── 4. DYNAMIC ISLAND EXPANDED OSD VIEW (VOLUME, BRIGHTNESS, MIC, INPUT) ──
    Item {
        id: osdRow
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        opacity: (!root.isTimerActive && root.hasOsd) ? 1.0 : 0.0
        scale: (!root.isTimerActive && root.hasOsd) ? 1.0 : 0.94
        visible: opacity > 0.001

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        readonly property bool isMuted: {
            if (root.osdType === "volume") return (root.osdIcon.indexOf("mute") !== -1 || root.osdLabel === "Muted")
            if (root.osdType === "mic") return (root.osdIcon.indexOf("mute") !== -1 || root.osdLabel === "Muted")
            return false
        }

        readonly property string displayTitle: {
            if (root.osdType === "volume") return "Volume"
            if (root.osdType === "mic") return "Microphone"
            if (root.osdType === "brightness") return "Brightness"
            if (root.osdType === "input") return "Input Method"
            return "Setting"
        }

        readonly property string iconSvg: {
            var v = root.osdValue   // 0.0 – 1.0
            var c = Theme.accent
            var m = Theme.muted
            var e = Theme.error

            if (root.osdType === "volume") {
                if (isMuted) return root.svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + e + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><line x1="23" y1="9" x2="17" y2="15"/><line x1="17" y1="9" x2="23" y2="15"/></svg>')
                if (v <= 0.33)
                    // Low volume: speaker cone only
                    return root.svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + c + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/></svg>')
                // High volume: speaker cone + 2 arcs
                return root.svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + c + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14"/></svg>')
            }
            if (root.osdType === "mic") {
                return isMuted ? root.micMuteSvg : root.micSvg
            }
            if (root.osdType === "brightness") {
                // Sun with rays that grow with brightness:
                // Low  (≤33%): small circle + 4 short rays
                // Mid  (≤66%): medium circle + 6 medium rays
                // High (>66%): large circle + 8 long rays
                var r = (v <= 0.33) ? 3.5 : (v <= 0.66) ? 4.5 : 5.5
                var rayLen = (v <= 0.33) ? 1.0 : (v <= 0.66) ? 1.8 : 2.8
                var numRays = (v <= 0.33) ? 4 : (v <= 0.66) ? 6 : 8
                var cx = 12, cy = 12
                var innerR = r + 1.8
                var outerR = innerR + rayLen
                var paths = ''
                for (var i = 0; i < numRays; i++) {
                    var angle = (i / numRays) * 2 * Math.PI - Math.PI / 2
                    var x1 = (cx + innerR * Math.cos(angle)).toFixed(2)
                    var y1 = (cy + innerR * Math.sin(angle)).toFixed(2)
                    var x2 = (cx + outerR * Math.cos(angle)).toFixed(2)
                    var y2 = (cy + outerR * Math.sin(angle)).toFixed(2)
                    paths += '<line x1="' + x1 + '" y1="' + y1 + '" x2="' + x2 + '" y2="' + y2 + '"/>'
                }
                return root.svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + c + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="' + cx + '" cy="' + cy + '" r="' + r + '"/>' + paths + '</svg>')
            }
            if (root.osdType === "input") {
                return root.keyboardSvg
            }
            return root.speakerSvg
        }

        Row {
            anchors.fill: parent
            spacing: 12

            // Left: Icon Badge with soft glow
            Rectangle {
                id: osdIconBadge
                width: 28
                height: 28
                radius: 10
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.alpha(osdRow.isMuted ? Theme.error : Theme.accent, 0.16)
                border.width: 1
                border.color: Theme.alpha(osdRow.isMuted ? Theme.error : Theme.accent, 0.35)

                Image {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: osdRow.iconSvg
                    sourceSize: Qt.size(32, 32)
                }
            }

            // Right: Text info and progress bar track
            Column {
                width: parent.width - osdIconBadge.width - 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                // Top line: Label + Value Badge
                Item {
                    width: parent.width
                    height: 16

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: osdRow.displayTitle
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: Theme.foreground
                        elide: Text.ElideRight
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            if (root.osdType === "volume") {
                                return osdRow.isMuted ? "Muted" : Math.round(root.osdValue * 100) + "%"
                            }
                            if (root.osdType === "brightness") {
                                return Math.round(root.osdValue * 100) + "%"
                            }
                            return root.osdLabel
                        }
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: osdRow.isMuted ? Theme.error : Theme.accent
                    }
                }

                // Bottom line: Level bar or sub-tag
                Item {
                    width: parent.width
                    height: 6

                    // Track
                    Rectangle {
                        anchors.fill: parent
                        radius: 3
                        color: Theme.alpha(Theme.foreground, 0.12)
                        visible: root.osdType !== "input"
                    }

                    // Fill bar
                    Rectangle {
                        height: parent.height
                        width: Math.max(0, Math.min(parent.width, parent.width * root.osdValue))
                        radius: 3
                        color: osdRow.isMuted ? Theme.error : Theme.accent
                        visible: root.osdType !== "input"

                        Behavior on width {
                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                        }
                    }

                    // Input Method subtitle
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.osdSubLabel.length > 0 ? root.osdSubLabel : "Active Keymap"
                        font.family: "Outfit"
                        font.pixelSize: 9
                        color: Theme.alpha(Theme.foreground, 0.50)
                        visible: root.osdType === "input"
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}

