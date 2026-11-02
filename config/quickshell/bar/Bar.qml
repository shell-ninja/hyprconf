import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "."

PanelWindow {
    id: bar

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    // ── Theme tokens (Hyprconf dynamic Obsidian Glassmorphism) ─────
    property color surface: Theme.alpha(Theme.surface, 0.96)
    property color pillColor: Theme.alpha(Theme.surface, 0.90)
    property color pillDark: Theme.accent
    property color pillBorder: Theme.alpha(Theme.accent, 0.40)
    property color fg: Theme.foreground
    property color fgDark: Theme.accent
    property color fgMuted: Theme.alpha(Theme.foreground, 0.60)
    property color accent: Theme.accent
    property color onPrimary: Theme.on_primary

    // ── Bar Geometry & Customization Properties (read from bar.json) ──
    property int barH: 36
    property int marginTop: 6
    property int marginLeft: 10
    property int marginRight: 10
    property int padding: 6
    property int widgetSpacing: 8
    property int capsuleRadius: 12
    property int capsulePadding: 8
    property string capsuleStyle: "islands"        // "islands" | "glass"
    property string trailStyle: "matrix"          // "matrix" | "thunder" | "none"
    property real barOpacity: 0.85
    property bool enableScreenFrame: false
    property bool hidePkgWhenEmpty: false

    readonly property int totalBarHeight: barH + marginTop + 4

    // ── Zone Layout Arrays (Dynamic elements) ───────────────────────
    property var startWidgets: ["workspaces", "tray", "weather"]
    property var centerWidgets: ["power_profile", "media", "clock", "notification"]
    property var endWidgets: ["pkg_update", "quick_toggles", "system_info", "volume", "power"]
    property var widgetSettings: ({})

    // ── Triggers (registered dynamically by BarWidgetLoader instances) ──
    property var launcherTrigger: null
    property var trayTrigger: null
    property var weatherTrigger: null
    property var perfTrigger: null
    property var clockTrigger: null
    property var notifTrigger: null
    property var togglesTrigger: null
    property var monitorTrigger: null
    property var volumeTrigger: null
    property var powerTrigger: null
    property var pkgTrigger: null

    // ── State ───────────────────────────────────────────────────────
    property bool caffeine: false
    property bool nightLight: false
    property bool gameModeActive: false
    property int profile: 1                       // 0 performance, 1 balanced, 2 saver
    property real cpuUsage: 0
    property var cpuCores: [0, 0, 0, 0, 0, 0, 0, 0]
    property var cpuHistory: [10, 14, 12, 18, 15, 20, 16, 22, 18, 15, 12, 14, 16, 18, 22, 25, 20, 18, 15, 14, 12, 16, 18, 20]
    property real cpuTemp: 40.0
    property var gpuStats: null
    property real memUsedGiB: 0
    property real memTotalGiB: 0
    property real memPercent: 35.0
    property real diskUsedGiB: 0
    property real diskTotalGiB: 0
    property real diskPercent: 40.0
    property var topProcs: []
    property int pkgCount: 0
    readonly property int activeWs: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    // ── Notifications State ─────────────────────────────────────────
    property var notificationList: []
    property int notifCount: 0

    // ── Dynamic Weather State (hyprconf cache) ─────────────────────
    property string weatherTemp: "24"
    property string weatherCond: "Clear sky"
    property string weatherCategory: "sunny"
    property string weatherCode: "0"
    property string weatherFeels: "24"
    property string weatherHumidity: "48"
    property string weatherWind: "6 km/h SW"
    property string weatherPressure: "1027 hPa"
    property string weatherUv: "4"
    property string weatherIconName: "moon"
    property string weatherCity: "Local"
    property string weatherCountry: ""
    property bool weatherIsDay: true
    property var weatherForecast: []

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

    readonly property var source: Pipewire.defaultAudioSource
    readonly property real micVolume: source && source.audio ? source.audio.volume : 0
    readonly property bool micMuted: source && source.audio ? source.audio.muted : false

    property var netTrigger: null
    property var netProcesses: []
    property string netDownStr: "0 KB/s"
    property string netUpStr: "0 KB/s"

    property bool _readyAudioOsd: false
    Timer {
        interval: 1600
        running: true
        repeat: false
        onTriggered: bar._readyAudioOsd = true
    }

    onVolumeChanged: {
        if (!_readyAudioOsd) return
        var pct = Math.round(bar.volume * 100)
        osd.show("volume", pct.toString(), bar.muted ? "Muted" : (pct + "%"), bar.muted ? "volume-mute" : "volume", "")
    }

    onMutedChanged: {
        if (!_readyAudioOsd) return
        var pct = Math.round(bar.volume * 100)
        osd.show("volume", pct.toString(), bar.muted ? "Muted" : (pct + "%"), bar.muted ? "volume-mute" : "volume", "")
    }

    readonly property var player: {
        const l = Mpris.players.values
        return l && l.length > 0 ? l[0] : null
    }

    readonly property bool trayPopShown: trayPop.shown

    // ── CONFIGURATION LOADER ─────────────────────────────────────────
    function parseBarConfig(rawText) {
        if (!rawText || rawText.trim().length === 0) return
        try {
            var cfg = JSON.parse(rawText.trim())
            if (cfg.top_panel !== undefined && cfg.top_panel === "island") {
                Qt.quit()
                return
            }
            if (cfg.height !== undefined) bar.barH = parseInt(cfg.height, 10) || 36
            if (cfg.margin_top !== undefined) bar.marginTop = parseInt(cfg.margin_top, 10) || 0
            if (cfg.margin_left !== undefined) bar.marginLeft = parseInt(cfg.margin_left, 10) || 0
            if (cfg.margin_right !== undefined) bar.marginRight = parseInt(cfg.margin_right, 10) || 0
            if (cfg.padding !== undefined) bar.padding = parseInt(cfg.padding, 10) || 6
            if (cfg.widget_spacing !== undefined) bar.widgetSpacing = parseInt(cfg.widget_spacing, 10) || 8
            if (cfg.capsule_radius !== undefined) bar.capsuleRadius = parseInt(cfg.capsule_radius, 10) || 12
            if (cfg.capsule_padding !== undefined) bar.capsulePadding = parseInt(cfg.capsule_padding, 10) || 10
            if (cfg.capsule_style !== undefined) bar.capsuleStyle = cfg.capsule_style
            if (cfg.trail_style !== undefined) bar.trailStyle = cfg.trail_style
            if (cfg.opacity !== undefined) bar.barOpacity = parseFloat(cfg.opacity) || 0.85
            if (cfg.screen_frame !== undefined) bar.enableScreenFrame = !!cfg.screen_frame
            if (cfg.hide_pkg_empty !== undefined) bar.hidePkgWhenEmpty = !!cfg.hide_pkg_empty

            if (cfg.start && Array.isArray(cfg.start)) bar.startWidgets = cfg.start
            if (cfg.center && Array.isArray(cfg.center)) bar.centerWidgets = cfg.center
            if (cfg.end && Array.isArray(cfg.end)) bar.endWidgets = cfg.end
            if (cfg.widget_settings && typeof cfg.widget_settings === "object") {
                bar.widgetSettings = cfg.widget_settings
            }
        } catch(e) {
            console.log("[Bar] Error parsing bar.json:", e)
        }
    }

    Process {
        id: configReader
        command: ["sh", "-c", "cat " + bar.homeDir + "/.local/share/hyprconf/bar.json 2>/dev/null || cat " + bar.homeDir + "/.hyprconf/quickshell/bar/config.json 2>/dev/null || echo '{}'"]
        running: true
        stdout: StdioCollector {
            onTextChanged: bar.parseBarConfig(text)
            onStreamFinished: bar.parseBarConfig(text)
        }
    }

    IpcHandler {
        target: "bar"
        function quit() {
            Qt.quit()
        }
        function reloadConfig() {
            configReader.running = true
        }
        function toggleLauncher() {
            bar.toggleLauncher()
        }
        function openLauncher() {
            launcherPop.shown = true
        }
        function closeLauncher() {
            launcherPop.shown = false
        }
        function toggleClipboard() {
            bar.toggleClipboard()
        }
        function clearClipboard() {
            bar.clearClipboardHistory()
        }
        function openClipboard() {
            clipProc.running = true
            togglesPop.shown = true
        }
        function closeClipboard() {
            togglesPop.shown = false
        }
        function clearNotifications() {
            bar.clearNotifications()
        }
        function togglePower() {
            bar.togglePower()
        }
        function openPower() {
            powerPop.shown = true
        }
        function closePower() {
            powerPop.shown = false
        }
        function toggleWeather() {
            bar.toggleWeather()
        }
        function toggleClock() {
            bar.toggleClock()
        }
        function toggleVolume() {
            bar.toggleVolume()
        }
        function toggleAudioDevices() {
            bar.showDeviceSwitcher = !bar.showDeviceSwitcher
            if (bar.showDeviceSwitcher) audioDevicesProc.running = true
        }
        function toggleNetwork() {
            bar.toggleNetwork()
        }
        function toggleMonitor() {
            bar.toggleMonitor()
        }
        function toggleNotif() {
            bar.toggleNotif()
        }
        function toggleTray() {
            bar.toggleTray()
        }
        function togglePkg() {
            bar.togglePkg()
        }
        function showOsd(type: string, value: string, label: string, icon: string, subLabel: string) {
            osd.show(type, value, label, icon, subLabel)
        }
        function hideOsd() {
            osd.close(true)
        }
        function closeOsd() {
            osd.close(true)
        }
    }

    // ── Window setup ────────────────────────────────────────────────
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore           // Space reserved by Reserve window in shell.qml
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "hyprconf-bar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // Input only on the top bar capsules, active OSD/toast, and open popups; the rest is transparent click-through.
    mask: Region {
        regions: [
            Region { item: (bar.capsuleStyle === "islands") ? null : topStrip },
            Region { item: (bar.capsuleStyle === "islands") ? startIsland : null },
            Region { item: (bar.capsuleStyle === "islands") ? centerIsland : null },
            Region { item: (bar.capsuleStyle === "islands") ? endIsland : null },
            Region { item: osd.shown ? osd : null },
            Region { item: notifToast.shown ? notifToast : null },
            Region { item: (powerPop.shown || togglesPop.shown) ? popupDismissArea : null },
            Region { item: trayPop.shown ? trayPop : null },
            Region { item: weatherPop.shown ? weatherPop : null },
            Region { item: perfPop.shown ? perfPop : null },
            Region { item: clockPop.shown ? clockPop : null },
            Region { item: notifPop.shown ? notifPop : null },
            Region { item: togglesPop.shown ? togglesPop : null },
            Region { item: monitorPop.shown ? monitorPop : null },
            Region { item: volumePop.shown ? volumePop : null },
            Region { item: netPop.shown ? netPop : null },
            Region { item: powerPop.shown ? powerPop : null },
            Region { item: pkgPop.shown ? pkgPop : null }
        ]
    }

    // ── Services & Background Monitors ──────────────────────────────
    SystemClock { id: clock; precision: SystemClock.Minutes }
    IdleInhibitor { window: bar; enabled: bar.caffeine }
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    // Ensure clipboard history daemon is active
    Process {
        id: clipDaemonStarter
        command: ["sh", "-c", "pgrep -f 'cliphist store' >/dev/null || (nohup wl-paste --watch cliphist store </dev/null &>/dev/null & nohup wl-paste --type image --watch cliphist store </dev/null &>/dev/null &)"]
        running: true
    }

    ListModel { id: clipModel }

    // Audio Devices (Output Sinks & Input Sources) via audio-devices.py
    property var audioSinks: []
    property var audioSources: []
    property bool showDeviceSwitcher: false

    // Per-App Audio Streams Matrix via audio-streams.py
    property var audioStreams: []

    Process {
        id: audioStreamsProc
        command: ["python3", bar.homeDir + "/.hyprconf/hypr/scripts/py/audio-streams.py"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0) {
                    try {
                        var d = JSON.parse(text.trim())
                        bar.audioStreams = d.streams || []
                    } catch(e) {}
                }
            }
        }
    }

    Process {
        id: audioDevicesProc
        command: ["python3", bar.homeDir + "/.hyprconf/hypr/scripts/py/audio-devices.py"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0) {
                    try {
                        var d = JSON.parse(text.trim())
                        bar.audioSinks = d.sinks || []
                        bar.audioSources = d.sources || []
                    } catch(e) {}
                }
            }
        }
    }

    NotificationServer {
        id: notifServer
        keepOnReload: false
        actionsSupported: true
        imageSupported: true

        onNotification: function(notif) {
            if (notif.lastGeneration) return
            notif.tracked = true
            bar.handleIncomingNotification(notif)
        }
    }

    // Power Profile Reader (0: performance, 1: balanced, 2: power-saver)
    Process {
        id: powerProfileReader
        command: ["powerprofilesctl", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim().length === 0) return
                var mode = text.trim().toLowerCase()
                if (mode === "performance") bar.profile = 0
                else if (mode === "power-saver") bar.profile = 2
                else bar.profile = 1
            }
        }
    }
    Timer {
        id: profileRefreshTimer
        interval: 350
        repeat: false
        onTriggered: if (!powerProfileReader.running) powerProfileReader.running = true
    }
    Timer {
        interval: 8000
        running: true
        repeat: true
        onTriggered: if (!powerProfileReader.running) powerProfileReader.running = true
    }

    // Clipboard item count reader
    property int clipCount: 0
    Process {
        id: clipCountProc
        command: ["sh", "-c", "cliphist list | wc -l"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0) {
                    var c = parseInt(text.trim(), 10)
                    if (!isNaN(c)) bar.clipCount = c
                }
            }
        }
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: if (!clipCountProc.running) clipCountProc.running = true
    }

    // Game Mode State Watcher
    Process {
        id: gameModeChecker
        command: ["sh", "-c", "cat " + bar.homeDir + "/.local/share/hyprconf/.cache/gamemode.state 2>/dev/null || echo '0'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                bar.gameModeActive = (text && text.trim() === "1")
            }
        }
    }
    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: if (!gameModeChecker.running) gameModeChecker.running = true
    }

    // System stats (CPU / RAM / Disk) via sys-monitor.py
    Process {
        id: statProc
        command: ["python3", bar.homeDir + "/.hyprconf/hypr/scripts/py/sys-monitor.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim().length === 0) return
                try {
                    var data = JSON.parse(text.trim())
                    bar.cpuUsage = data.total_cpu || 0
                    if (data.cores && Array.isArray(data.cores)) bar.cpuCores = data.cores
                    if (data.cpu_temp !== undefined) bar.cpuTemp = data.cpu_temp
                    if (data.gpu !== undefined) bar.gpuStats = data.gpu
                    if (data.mem_used_gib !== undefined) bar.memUsedGiB = data.mem_used_gib
                    if (data.mem_total_gib !== undefined) bar.memTotalGiB = data.mem_total_gib
                    if (data.mem_percent !== undefined) bar.memPercent = data.mem_percent
                    if (data.disk_used_gib !== undefined) bar.diskUsedGiB = data.disk_used_gib
                    if (data.disk_total_gib !== undefined) bar.diskTotalGiB = data.disk_total_gib
                    if (data.disk_percent !== undefined) bar.diskPercent = data.disk_percent
                    if (data.top_procs !== undefined) bar.topProcs = data.top_procs

                    // Append to CPU history sparkline array (max 28 entries)
                    var h = bar.cpuHistory.slice()
                    h.push(data.total_cpu)
                    if (h.length > 28) h.shift()
                    bar.cpuHistory = h
                } catch(e) {}
            }
        }
    }
    Timer {
        interval: (monitorPop && monitorPop.shown) ? 1200 : 3500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!statProc.running) statProc.running = true
    }

    // Package updates checker
    Process {
        id: pkgProc
        command: [
            "python3", "-c",
            "import subprocess, json, os; " +
            "cnt = 0; " +
            "try:\n" +
            "    r = subprocess.run(['checkupdates'], capture_output=True, text=True, timeout=8)\n" +
            "    if r.returncode == 0:\n" +
            "        cnt += len([l for l in r.stdout.splitlines() if l.strip()])\n" +
            "except Exception: pass\n" +
            "print(json.dumps({'count': cnt}))"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var d = JSON.parse(text)
                    if (d && d.count !== undefined) bar.pkgCount = d.count
                } catch(e) {}
            }
        }
    }
    Timer {
        interval: 180000 // 3 minutes
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: pkgProc.running = true
    }

    // Clipboard fetcher
    Process {
        id: clipProc
        command: ["sh", "-c", "cliphist list | head -n 12"]
        stdout: StdioCollector {
            onStreamFinished: {
                clipModel.clear()
                const lines = text.split("\n")
                for (const line of lines) {
                    const tab = line.indexOf("\t")
                    if (tab < 1) continue
                    const cid = parseInt(line.slice(0, tab), 10)
                    if (isNaN(cid)) continue
                    clipModel.append({ cid: cid, preview: line.slice(tab + 1) })
                }
            }
        }
    }

    // Weather reader
    Process {
        id: weatherProc
        command: [
            "python3", "-c",
            "import json, os; " +
            "p1 = os.path.expanduser('~/.local/share/hyprconf/.cache/weather.json'); " +
            "p2 = os.path.expanduser('~/.hyprconf/hypr/.cache/weather_cache.json'); " +
            "p = p1 if os.path.exists(p1) else (p2 if os.path.exists(p2) else None); " +
            "print(open(p).read() if p else '{}')"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    if (data.temp_C) {
                        bar.weatherTemp = data.temp_C
                        if (data.condition) bar.weatherCond = data.condition.trim()
                        if (data.feels_like_C) bar.weatherFeels = data.feels_like_C
                    } else if (data.current) {
                        if (data.current.temp !== undefined) bar.weatherTemp = Math.round(data.current.temp).toString()
                        if (data.current.condition) bar.weatherCond = data.current.condition.trim()
                        if (data.current.feels_like !== undefined) bar.weatherFeels = Math.round(data.current.feels_like).toString()
                    }
                    if (data.city) bar.weatherCity = data.city
                    if (data.country) bar.weatherCountry = data.country
                    if (data.humidity) bar.weatherHumidity = data.humidity.toString()
                    if (data.wind_speed) bar.weatherWind = data.wind_speed + " km/h " + (data.wind_dir || "")
                    if (data.pressure) bar.weatherPressure = data.pressure + " hPa"
                    if (data.uv_index) bar.weatherUv = data.uv_index.toString()
                    if (data.weather_category) bar.weatherCategory = data.weather_category
                    if (data.weather_code) bar.weatherCode = data.weather_code.toString()
                    if (data.is_day !== undefined) bar.weatherIsDay = !!data.is_day
                    if (data.forecast_7days && Array.isArray(data.forecast_7days)) {
                        bar.weatherForecast = data.forecast_7days.slice(0, 4)
                    }

                    var c = bar.weatherCond.toLowerCase()
                    if (c.indexOf("sun") !== -1 || c.indexOf("clear") !== -1) {
                        bar.weatherIconName = clock.date.getHours() >= 18 || clock.date.getHours() < 6 ? "moon" : "sun"
                    } else if (c.indexOf("rain") !== -1 || c.indexOf("drizzle") !== -1) {
                        bar.weatherIconName = "rain"
                    } else if (c.indexOf("snow") !== -1) {
                        bar.weatherIconName = "snow"
                    } else if (c.indexOf("thunder") !== -1 || c.indexOf("storm") !== -1) {
                        bar.weatherIconName = "thunder"
                    } else if (c.indexOf("cloud") !== -1) {
                        bar.weatherIconName = "cloud"
                    } else {
                        bar.weatherIconName = "moon"
                    }
                } catch(e) {}
            }
        }
    }
    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherProc.running = true
    }

    // ── Caps Lock Hardware Watcher ──────────────────────────────────
    property int _lastCapsState: -1
    Process {
        id: capsWatcher
        command: ["sh", "-c", "cat /sys/class/leds/*caps*/brightness 2>/dev/null | head -n 1"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim().length === 0) return
                var val = parseInt(text.trim(), 10)
                if (isNaN(val)) return
                if (bar._lastCapsState !== -1 && bar._lastCapsState !== val) {
                    var on = val > 0
                    osd.show("capslock", val.toString(), on ? "Caps Lock ON" : "Caps Lock OFF", "lock", on ? "Uppercase Typing Active" : "Standard Lowercase Active")
                }
                bar._lastCapsState = val
            }
        }
    }
    Timer {
        interval: 350
        running: true
        repeat: true
        onTriggered: if (!capsWatcher.running) capsWatcher.running = true
    }

    // ── Notifications Helper Handlers ────────────────────────────────
    function handleIncomingNotification(notif) {
        if (!notif) return
        var notifId = (notif.id !== undefined && notif.id !== null) ? notif.id : Date.now()
        var item = {
            id: notifId,
            appName: notif.appName || "Notification",
            summary: notif.summary || "New Notification",
            body: notif.body || "",
            appIcon: notif.appIcon || "",
            time: Qt.formatTime(new Date(), "hh:mm"),
            rawNotif: notif
        }
        var filtered = []
        for (var i = 0; i < bar.notificationList.length; i++) {
            if (bar.notificationList[i].id !== notifId) filtered.push(bar.notificationList[i])
        }
        bar.notificationList = [item].concat(filtered.slice(0, 49))
        bar.notifCount = bar.notificationList.length

        // Pop up modern floating toast notification
        notifToast.show(item)
    }

    function clearNotifications() {
        for (var i = 0; i < bar.notificationList.length; i++) {
            var item = bar.notificationList[i]
            if (item && item.rawNotif && typeof item.rawNotif.dismiss === "function") {
                try { item.rawNotif.dismiss() } catch(e) {}
            }
        }
        bar.notificationList = []
        bar.notifCount = 0
    }

    function dismissNotification(id) {
        var copy = []
        for (var i = 0; i < bar.notificationList.length; i++) {
            var item = bar.notificationList[i]
            if (item.id === id) {
                if (item.rawNotif && typeof item.rawNotif.dismiss === "function") {
                    try { item.rawNotif.dismiss() } catch(e) {}
                }
            } else {
                copy.push(item)
            }
        }
        bar.notificationList = copy
        bar.notifCount = bar.notificationList.length
    }

    function clearClipboardHistory() {
        Quickshell.execDetached(["sh", "-c", "cliphist wipe"])
        clipModel.clear()
        bar.clipCount = 0
    }

    // ── Methods & Action Handlers ────────────────────────────────────
    function toggleTray() { trayPop.shown = !trayPop.shown }
    function toggleLauncher() { launcherPop.shown = !launcherPop.shown }
    function toggleWeather() { weatherPop.shown = !weatherPop.shown }
    function toggleClock() { clockPop.shown = !clockPop.shown }
    function toggleNotif() { notifPop.shown = !notifPop.shown }
    function toggleToggles() { togglesPop.shown = !togglesPop.shown }
    function toggleClipboard(triggerItem) {
        if (triggerItem) bar.togglesTrigger = triggerItem
        clipProc.running = true
        clipCountProc.running = true
        togglesPop.shown = !togglesPop.shown
    }
    function toggleMonitor() { monitorPop.shown = !monitorPop.shown }
    function toggleVolume() { volumePop.shown = !volumePop.shown }
    function toggleNetwork() { netPop.shown = !netPop.shown }
    function togglePower() { powerPop.shown = !powerPop.shown }
    function togglePkg() { pkgPop.shown = !pkgPop.shown }

    function toggleCaffeine() {
        bar.caffeine = !bar.caffeine
        Quickshell.execDetached([homeDir + "/.hyprconf/hypr/scripts/sh/caffeine-manager.sh"])
        osd.show("caffeine", bar.caffeine ? "1" : "0", bar.caffeine ? "Awake" : "Normal", "coffee", bar.caffeine ? "Screen Inactivity Suspended" : "Idle Inhibitor Disabled")
    }

    function toggleNightLight() {
        bar.nightLight = !bar.nightLight
        Quickshell.execDetached([homeDir + "/.hyprconf/hypr/scripts/sh/hyprsunset-manager.sh"])
        osd.show("nightlight", bar.nightLight ? "1" : "0", bar.nightLight ? "Warm (4500K)" : "Off", "moon", bar.nightLight ? "Eye Strain Reduction Active" : "Color Temperature Normal")
    }

    function toggleGameMode() {
        bar.gameModeActive = !bar.gameModeActive
        Quickshell.execDetached([homeDir + "/.hyprconf/hypr/scripts/sh/gamemode.sh", "--toggle"])
    }

    function cycleProfile() {
        bar.setProfile((bar.profile + 1) % 3)
    }

    function setProfile(p) {
        bar.profile = p
        const names = ["performance", "balanced", "power-saver"]
        Quickshell.execDetached(["powerprofilesctl", "set", names[p]])
        profileRefreshTimer.restart()
        var modeName = (p === 0) ? "Performance" : ((p === 2) ? "Power Saver" : "Balanced")
        var sub = (p === 0) ? "Maximum Boost & Frequency" : ((p === 2) ? "Extended Battery Runtime" : "Optimized Efficiency")
        var icon = (p === 0) ? "bolt" : ((p === 2) ? "leaf" : "gauge")
        osd.show("power", p.toString(), modeName, icon, sub)
    }

    function setVolume(v) {
        const clamped = Math.max(0, Math.min(1.5, v))
        if (sink && sink.audio) {
            sink.audio.volume = clamped
            if (sink.audio.muted && clamped > 0) sink.audio.muted = false
        }
        var pct = Math.round(clamped * 100)
        Quickshell.execDetached(["pamixer", "--set-volume", pct.toString()])
    }

    function toggleMute() {
        if (!sink || !sink.audio) return
        sink.audio.muted = !sink.audio.muted
    }

    function setMicVolume(v) {
        const clamped = Math.max(0, Math.min(1.5, v))
        if (source && source.audio) {
            source.audio.volume = clamped
            if (source.audio.muted && clamped > 0) source.audio.muted = false
        }
        var pct = Math.round(clamped * 100)
        Quickshell.execDetached(["pamixer", "--default-source", "--set-volume", pct.toString()])
    }

    function toggleMicMute() {
        if (source && source.audio) {
            source.audio.muted = !source.audio.muted
        }
        Quickshell.execDetached(["pamixer", "--default-source", "-t"])
    }

    function parseStats(txt) {
        const lines = txt.trim().split("\n")
        if (lines.length < 3) return

        // CPU
        const cpuParts = lines[0].trim().split(/\s+/).slice(1).map(Number)
        if (cpuParts.length >= 4) {
            const idle = cpuParts[3] + (cpuParts[4] || 0)
            const total = cpuParts.reduce((a, b) => a + b, 0)
            if (bar.lastCpu) {
                const dTotal = total - bar.lastCpu.total
                const dIdle = idle - bar.lastCpu.idle
                if (dTotal > 0) {
                    bar.cpuUsage = Math.max(0, Math.min(100, Math.round((1 - dIdle / dTotal) * 100)))
                }
            }
            bar.lastCpu = { total: total, idle: idle }
        }

        // Memory
        const memParts = lines[1].trim().split(/\s+/).map(Number)
        if (memParts.length >= 2) {
            bar.memTotalGiB = memParts[0] / 1048576
            bar.memUsedGiB = memParts[1] / 1048576
        }

        // Disk
        const diskParts = lines[2].trim().split(/\s+/).map(Number)
        if (diskParts.length >= 2) {
            bar.diskTotalGiB = diskParts[0] / 1073741824
            bar.diskUsedGiB = diskParts[1] / 1073741824
        }
    }

    // ── MAIN BAR VISUAL SURFACE ─────────────────────────────────────
    Item {
        id: topStrip
        x: bar.marginLeft
        y: bar.marginTop
        width: bar.width - bar.marginLeft - bar.marginRight
        height: bar.barH

        // Unified Mode: Full-width continuous Obsidian Glass Shelf
        Rectangle {
            id: barBackground
            anchors.fill: parent
            radius: Math.min(bar.capsuleRadius + 2, height / 2)
            color: Theme.alpha(Theme.surface, bar.barOpacity)
            border.width: 1
            border.color: Theme.alpha(Theme.accent, 0.22)
            visible: (bar.capsuleStyle !== "islands") && bar.barOpacity > 0.05

            // Inner subtle top glass rim
            Rectangle {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.85
                height: 1
                color: Theme.alpha(Theme.foreground, 0.12)
            }
        }

        // ── 1. LEFT CAPSULE (Start Island) ──────────────────────────
        Rectangle {
            id: startIsland
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: startRow.implicitWidth + bar.padding * 2
            height: bar.barH
            radius: Math.min(bar.capsuleRadius + 4, height / 2)
            color: Theme.alpha(Theme.surface, bar.barOpacity)
            border.width: 1
            border.color: Theme.alpha(Theme.accent, 0.24)
            visible: bar.capsuleStyle === "islands"

            // Inner subtle glass rim
            Rectangle {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.75
                height: 1
                color: Theme.alpha(Theme.foreground, 0.12)
            }
        }

        RowLayout {
            id: startRow
            anchors.left: (bar.capsuleStyle === "islands") ? startIsland.left : parent.left
            anchors.leftMargin: bar.padding
            anchors.verticalCenter: parent.verticalCenter
            spacing: bar.widgetSpacing

            Repeater {
                model: bar.startWidgets
                delegate: BarWidgetLoader {
                    widgetId: modelData
                    zone: "start"
                }
            }
        }

        // ── 2. CENTER CAPSULE (Center Island) ────────────────────────
        Rectangle {
            id: centerIsland
            anchors.centerIn: parent
            width: centerRow.implicitWidth + bar.padding * 2
            height: bar.barH
            radius: Math.min(bar.capsuleRadius + 4, height / 2)
            color: Theme.alpha(Theme.surface, bar.barOpacity)
            border.width: 1
            border.color: Theme.alpha(Theme.accent, 0.24)
            visible: bar.capsuleStyle === "islands"

            // Inner subtle glass rim
            Rectangle {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.75
                height: 1
                color: Theme.alpha(Theme.foreground, 0.12)
            }
        }

        RowLayout {
            id: centerRow
            anchors.centerIn: (bar.capsuleStyle === "islands") ? centerIsland : parent
            spacing: bar.widgetSpacing

            Repeater {
                model: bar.centerWidgets
                delegate: BarWidgetLoader {
                    widgetId: modelData
                    zone: "center"
                }
            }
        }

        // ── 3. RIGHT CAPSULE (End Island) ────────────────────────────
        Rectangle {
            id: endIsland
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: endRow.implicitWidth + bar.padding * 2
            height: bar.barH
            radius: Math.min(bar.capsuleRadius + 4, height / 2)
            color: Theme.alpha(Theme.surface, bar.barOpacity)
            border.width: 1
            border.color: Theme.alpha(Theme.accent, 0.24)
            visible: bar.capsuleStyle === "islands"

            // Inner subtle glass rim
            Rectangle {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.75
                height: 1
                color: Theme.alpha(Theme.foreground, 0.12)
            }
        }

        RowLayout {
            id: endRow
            anchors.right: (bar.capsuleStyle === "islands") ? endIsland.right : parent.right
            anchors.rightMargin: bar.padding
            anchors.verticalCenter: parent.verticalCenter
            spacing: bar.widgetSpacing

            Repeater {
                model: bar.endWidgets
                delegate: BarWidgetLoader {
                    widgetId: modelData
                    zone: "end"
                }
            }
        }

        // ── ANIMATED TRAIL BRIDGES (Connecting Wings) ───────────────
        BarTrailBridge {
            id: leftBridge
            anchors.left: startIsland.right
            anchors.leftMargin: 8
            anchors.right: centerIsland.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            reverse: false
            theme: bar.trailStyle
            visible: (bar.capsuleStyle === "islands") && (bar.trailStyle !== "none")
        }

        BarTrailBridge {
            id: rightBridge
            anchors.left: centerIsland.right
            anchors.leftMargin: 8
            anchors.right: endIsland.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            reverse: true
            theme: bar.trailStyle
            visible: (bar.capsuleStyle === "islands") && (bar.trailStyle !== "none")
        }
    }

    // ================================================================
    // POPUPS (Smooth drop-downs dynamically attached to triggers)
    // ================================================================

    // Fullscreen dismiss backdrop for click-activated popups (Power, Toggles/Clipboard)
    MouseArea {
        id: popupDismissArea
        anchors.fill: parent
        z: 15
        enabled: powerPop.shown || togglesPop.shown
        visible: enabled
        onClicked: {
            powerPop.close()
            togglesPop.close()
        }
    }

    // 1. LAUNCHER POPUP
    BarPopup {
        id: launcherPop
        trigger: bar.launcherTrigger
        popupWidth: 320
        surface: bar.surface
        align: "left"
        hoverOpen: false

        property var allApps: []
        property var apps: []

        Process {
            id: launcherAppsLoader
            command: ["python3", "-c", "import json, os; p=os.path.expanduser('~/.hyprconf/hypr/.cache/apps.json'); print(open(p, encoding='utf-8').read() if os.path.exists(p) else '[]')"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        launcherPop.allApps = JSON.parse(text.trim())
                        launcherPop.filterApps()
                    } catch(e) {}
                }
            }
        }

        function filterApps() {
            const q = searchInput.text.toLowerCase().trim()
            if (!q) {
                apps = launcherPop.allApps.slice(0, 7).map(a => ({
                    name: a.name,
                    icon: a.icon || "",
                    execute: () => {
                        Quickshell.execDetached(a.exec ? a.exec.split(" ") : [a.name.toLowerCase()])
                    }
                }))
            } else {
                apps = launcherPop.allApps.filter(a => a.name.toLowerCase().includes(q)).slice(0, 7).map(a => ({
                    name: a.name,
                    icon: a.icon || "",
                    execute: () => {
                        Quickshell.execDetached(a.exec ? a.exec.split(" ") : [a.name.toLowerCase()])
                    }
                }))
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 38
            radius: 19
            color: bar.pillColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 8
                SvgIcon { name: "search"; size: 16 }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 20
                    MonoText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: searchInput.text === ""
                        text: "Search apps..."
                        color: Theme.muted
                        font.pixelSize: 12
                    }
                    TextInput {
                        id: searchInput
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        color: bar.fg
                        font.family: "JetBrainsMono Nerd Font, monospace"
                        font.pixelSize: 12
                        clip: true
                        selectByMouse: true
                        onTextChanged: launcherPop.filterApps()
                        onAccepted: {
                            if (launcherPop.apps.length > 0) {
                                launcherPop.apps[0].execute()
                                searchInput.text = ""
                                launcherPop.close()
                            }
                        }
                    }
                }
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(launcherPop.apps.length * 36, 240)
            clip: true
            spacing: 3
            boundsBehavior: Flickable.StopAtBounds
            model: launcherPop.apps

            delegate: Rectangle {
                id: appRow
                required property var modelData
                width: ListView.view.width
                height: 34
                radius: 10
                color: appMouse.containsMouse ? Theme.alpha(Theme.accent, 0.22) : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10
                    SvgIcon {
                        name: "app"
                        size: 16
                        color: appMouse.containsMouse ? Theme.accent : Theme.foreground
                    }
                    MonoText {
                        Layout.fillWidth: true
                        text: appRow.modelData.name
                        color: appMouse.containsMouse ? Theme.foreground : Theme.alpha(Theme.foreground, 0.9)
                        elide: Text.ElideRight
                        font.pixelSize: 12
                    }
                }
                MouseArea {
                    id: appMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        appRow.modelData.execute()
                        launcherPop.close()
                    }
                }
            }
        }
    }

    // 2. SYSTEM TRAY POPUP
    BarPopup {
        id: trayPop
        trigger: bar.trayTrigger
        popupWidth: Math.max(280, trayFlow.implicitWidth + 32)
        surface: bar.surface
        align: "left"

        Text {
            text: "SYSTEM TRAY"
            font.family: "Outfit"
            font.bold: true
            font.pixelSize: 11
            font.letterSpacing: 0.5
            color: Theme.muted
        }

        Flow {
            id: trayFlow
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: SystemTray.items.values
                delegate: Rectangle {
                    id: trayItemBox
                    required property var modelData
                    width: 32
                    height: 32
                    radius: 8
                    color: trayItemMouse.containsMouse ? Theme.alpha(Theme.surface, 0.95) : Theme.alpha(Theme.surface, 0.50)
                    border.width: 1
                    border.color: trayItemMouse.containsMouse ? Theme.alpha(Theme.accent, 0.40) : "transparent"

                    Image {
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        source: trayItemBox.modelData.icon || ""
                        fillMode: Image.PreserveAspectFit
                    }

                    MouseArea {
                        id: trayItemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                trayItemBox.modelData.secondaryActivate()
                            } else {
                                trayItemBox.modelData.activate()
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.alpha(Theme.foreground, 0.12)
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; icon: "wifi"; label: "Wi-Fi"; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
            ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; icon: "bluetooth"; label: "BT"; onClicked: Quickshell.execDetached(["blueman-manager"]) }
            ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; icon: "folder"; label: "Files"; onClicked: Quickshell.execDetached(["thunar"]) }
        }
    }

    // 3. WEATHER POPUP (Realistic Atmospheric Conditions & Multi-Metric Dashboard)
    BarPopup {
        id: weatherPop
        trigger: bar.weatherTrigger
        popupWidth: 350
        surface: bar.surface
        align: "left"

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            // Atmospheric Realistic Visual Hero Card
            Rectangle {
                Layout.fillWidth: true
                height: 146
                radius: 14
                clip: true

                // Dynamic atmospheric background color based on condition and time of day
                color: {
                    var c = bar.weatherCategory.toLowerCase()
                    if (c === "rain" || c === "drizzle") return "#0e1828"
                    if (c === "thunder" || c === "storm") return "#161026"
                    if (c === "cloudy" || c === "overcast") return "#141720"
                    if (c === "snow") return "#101826"
                    return bar.weatherIsDay ? "#221908" : "#0c1220"
                }
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.35)

                // Atmospheric ambient glow gradient
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: {
                                var c = bar.weatherCategory.toLowerCase()
                                if (c === "rain") return Theme.alpha("#38bdf8", 0.22)
                                if (c === "thunder") return Theme.alpha("#c084fc", 0.25)
                                if (c === "cloudy") return Theme.alpha("#94a3b8", 0.18)
                                if (c === "snow") return Theme.alpha("#e2e8f0", 0.20)
                                return bar.weatherIsDay ? Theme.alpha("#f59e0b", 0.28) : Theme.alpha("#38bdf8", 0.18)
                            }
                        }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                // Animated visual rain streaks if rainy condition
                Item {
                    anchors.fill: parent
                    visible: bar.weatherCategory.toLowerCase() === "rain" || bar.weatherCategory.toLowerCase() === "drizzle"
                    clip: true

                    Repeater {
                        model: 8
                        delegate: Rectangle {
                            required property int index
                            x: 20 + index * 40
                            width: 1.5
                            height: 16
                            radius: 1
                            color: Theme.alpha("#38bdf8", 0.50)

                            SequentialAnimation on y {
                                running: weatherPop.shown
                                loops: Animation.Infinite
                                NumberAnimation { from: -20; to: 150; duration: 600 + index * 80; easing.type: Easing.Linear }
                            }
                        }
                    }
                }

                // Ambient stars if clear night
                Item {
                    anchors.fill: parent
                    visible: (!bar.weatherIsDay) && (bar.weatherCategory.toLowerCase() === "sunny" || bar.weatherCond.toLowerCase().indexOf("clear") !== -1)

                    Repeater {
                        model: [
                            { x: 30, y: 20, s: 2, op: 0.8 },
                            { x: 75, y: 35, s: 1.5, op: 0.6 },
                            { x: 140, y: 15, s: 2.5, op: 0.9 },
                            { x: 200, y: 40, s: 1.5, op: 0.5 },
                            { x: 260, y: 22, s: 2, op: 0.7 },
                            { x: 310, y: 30, s: 2, op: 0.8 }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            x: modelData.x; y: modelData.y
                            width: modelData.s; height: modelData.s; radius: modelData.s / 2
                            color: "#ffffff"
                            opacity: modelData.op
                            SequentialAnimation on opacity {
                                running: weatherPop.shown
                                loops: Animation.Infinite
                                NumberAnimation { from: modelData.op * 0.4; to: modelData.op; duration: 1200 + index * 300; easing.type: Easing.InOutSine }
                                NumberAnimation { from: modelData.op; to: modelData.op * 0.4; duration: 1200 + index * 300; easing.type: Easing.InOutSine }
                            }
                        }
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    // Header row: Location & Quick Refresh
                    RowLayout {
                        Layout.fillWidth: true
                        SvgIcon { name: "pin"; size: 12; color: Theme.accent }
                        Text {
                            text: bar.weatherCity ? (bar.weatherCity + (bar.weatherCountry ? (", " + bar.weatherCountry) : "")) : "Local Weather"
                            font.family: "Outfit"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: Theme.foreground
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        Rectangle {
                            width: 22; height: 22; radius: 11
                            color: refreshMouse.containsMouse ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surface, 0.60)
                            SvgIcon { anchors.centerIn: parent; name: "refresh"; size: 11; color: Theme.foreground }
                            MouseArea {
                                id: refreshMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["python3", bar.homeDir + "/.hyprconf/hypr/scripts/py/weather.py", "--force"])
                            }
                        }
                    }

                    // Main Weather Metrics Row
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 12

                        // Big Temperature
                        Text {
                            text: bar.weatherTemp + "°C"
                            font.family: "Outfit"
                            font.pixelSize: 34
                            font.weight: Font.Bold
                            color: Theme.foreground
                        }

                        // Condition & Feels-like
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                text: bar.weatherCond
                                font.family: "Outfit"
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: Theme.foreground
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: "Feels like " + bar.weatherFeels + "°C"
                                font.family: "Outfit"
                                font.pixelSize: 10
                                color: Theme.alpha(Theme.foreground, 0.65)
                            }
                        }

                        // Large Weather Emblem Medallion
                        Rectangle {
                            width: 46
                            height: 46
                            radius: 23
                            color: Theme.alpha(Theme.surface, 0.75)
                            border.width: 1.5
                            border.color: Theme.alpha(Theme.accent, 0.45)
                            SvgIcon {
                                anchors.centerIn: parent
                                name: bar.weatherIconName
                                size: 26
                                color: Theme.accent
                            }
                        }
                    }
                }
            }

            // 4 Micro Atmospheric Metric Badges
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // 1. Humidity
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    height: 44; radius: 8
                    color: Theme.alpha(Theme.surface, 0.60)
                    border.width: 1; border.color: Theme.alpha(Theme.foreground, 0.08)
                    Column {
                        anchors.centerIn: parent; spacing: 2
                        Row {
                            spacing: 3; anchors.horizontalCenter: parent.horizontalCenter
                            SvgIcon { name: "droplet"; size: 9; color: "#38bdf8" }
                            Text { text: "Humidity"; font.family: "Outfit"; font.pixelSize: 9; color: Theme.muted }
                        }
                        Text { text: bar.weatherHumidity + "%"; font.family: "Outfit"; font.pixelSize: 11; font.bold: true; color: Theme.foreground; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                }

                // 2. Wind
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    height: 44; radius: 8
                    color: Theme.alpha(Theme.surface, 0.60)
                    border.width: 1; border.color: Theme.alpha(Theme.foreground, 0.08)
                    Column {
                        anchors.centerIn: parent; spacing: 2
                        Row {
                            spacing: 3; anchors.horizontalCenter: parent.horizontalCenter
                            SvgIcon { name: "wind"; size: 9; color: "#06b6d4" }
                            Text { text: "Wind"; font.family: "Outfit"; font.pixelSize: 9; color: Theme.muted }
                        }
                        Text { text: bar.weatherWind.split(" ")[0] + " km/h"; font.family: "Outfit"; font.pixelSize: 11; font.bold: true; color: Theme.foreground; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                }

                // 3. UV Index
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    height: 44; radius: 8
                    color: Theme.alpha(Theme.surface, 0.60)
                    border.width: 1; border.color: Theme.alpha(Theme.foreground, 0.08)
                    Column {
                        anchors.centerIn: parent; spacing: 2
                        Row {
                            spacing: 3; anchors.horizontalCenter: parent.horizontalCenter
                            SvgIcon { name: "sun"; size: 9; color: "#f59e0b" }
                            Text { text: "UV Index"; font.family: "Outfit"; font.pixelSize: 9; color: Theme.muted }
                        }
                        Text { text: bar.weatherUv; font.family: "Outfit"; font.pixelSize: 11; font.bold: true; color: Theme.foreground; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                }

                // 4. Pressure
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    height: 44; radius: 8
                    color: Theme.alpha(Theme.surface, 0.60)
                    border.width: 1; border.color: Theme.alpha(Theme.foreground, 0.08)
                    Column {
                        anchors.centerIn: parent; spacing: 2
                        Row {
                            spacing: 3; anchors.horizontalCenter: parent.horizontalCenter
                            SvgIcon { name: "gauge"; size: 9; color: Theme.accent }
                            Text { text: "Pressure"; font.family: "Outfit"; font.pixelSize: 9; color: Theme.muted }
                        }
                        Text { text: bar.weatherPressure.split(" ")[0]; font.family: "Outfit"; font.pixelSize: 11; font.bold: true; color: Theme.foreground; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                }
            }

            // 4-Day Mini Forecast Strip (if available)
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: bar.weatherForecast && bar.weatherForecast.length > 0

                Repeater {
                    model: bar.weatherForecast
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true; Layout.preferredWidth: 1
                        height: 54; radius: 8
                        color: Theme.alpha(Theme.surface, 0.50)
                        border.width: 1; border.color: Theme.alpha(Theme.foreground, 0.06)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 2
                            Text {
                                text: index === 0 ? "Today" : (modelData.day || modelData.display_date || "")
                                font.family: "Outfit"; font.pixelSize: 9; font.bold: true; color: Theme.muted
                                Layout.alignment: Qt.AlignHCenter
                            }
                            SvgIcon {
                                name: {
                                    var cat = (modelData.weather_category || "").toLowerCase()
                                    if (cat === "rain") return "rain"
                                    if (cat === "snow") return "snow"
                                    if (cat === "cloudy") return "cloud"
                                    return "sun"
                                }
                                size: 14
                                color: Theme.accent
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: (modelData.temp_max_C || "--") + "° / " + (modelData.temp_min_C || "--") + "°"
                                font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 9; color: Theme.foreground
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
            }
        }
    }

    // 4. POWER PROFILE POPUP (Performance / Balanced / Saver Modes)
    BarPopup {
        id: perfPop
        trigger: bar.perfTrigger
        popupWidth: 290
        surface: bar.surface
        align: "center"

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "POWER & ENERGY PROFILE"
                font.family: "Outfit"; font.bold: true; font.pixelSize: 10; font.letterSpacing: 0.5; color: Theme.muted
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; icon: "bolt"; label: "Perf"; active: bar.profile === 0; onClicked: bar.setProfile(0) }
                ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; icon: "gauge"; label: "Balanced"; active: bar.profile === 1; onClicked: bar.setProfile(1) }
                ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; icon: "leaf"; label: "Saver"; active: bar.profile === 2; onClicked: bar.setProfile(2) }
            }
        }
    }

    // 5. CLOCK & CALENDAR POPUP (Digital Glowing Clock & Obsidian Calendar)
    BarPopup {
        id: clockPop
        trigger: bar.clockTrigger
        popupWidth: 320
        surface: bar.surface
        align: "center"

        property var cells: {
            const d = clock.date
            const y = d.getFullYear(), m = d.getMonth()
            const first = (new Date(y, m, 1).getDay() + 6) % 7
            const n = new Date(y, m + 1, 0).getDate()
            const out = []
            for (let i = 0; i < first; i++) out.push(0)
            for (let i = 1; i <= n; i++) out.push(i)
            return out
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            // Digital Clock Header
            Rectangle {
                Layout.fillWidth: true
                height: 58
                radius: 10
                color: Theme.alpha(Theme.surface, 0.60)
                border.width: 1; border.color: Theme.alpha(Theme.foreground, 0.08)

                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    Text {
                        text: Qt.formatTime(clock.date, "hh:mm AP")
                        font.family: "Outfit"
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        color: Theme.foreground
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: Qt.formatDate(clock.date, "dddd, MMMM d, yyyy")
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Theme.accent
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // Month Title
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(clock.date, "MMMM yyyy").toUpperCase()
                color: Theme.foreground
                font.family: "Outfit"
                font.bold: true
                font.pixelSize: 12
                font.letterSpacing: 0.5
            }

            // Calendar Grid
            GridLayout {
                Layout.fillWidth: true
                columns: 7
                rowSpacing: 3
                columnSpacing: 3

                Repeater {
                    model: ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]
                    delegate: MonoText {
                        required property string modelData
                        Layout.fillWidth: true; Layout.preferredWidth: 1
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: Theme.muted
                        font.pixelSize: 10
                    }
                }
                Repeater {
                    model: clockPop.cells
                    delegate: Item {
                        id: dayCell
                        required property var modelData
                        Layout.fillWidth: true; Layout.preferredWidth: 1
                        implicitHeight: 26

                        Rectangle {
                            anchors.centerIn: parent
                            width: 24; height: 24; radius: 12
                            color: dayCell.modelData === clock.date.getDate()
                                   ? Theme.accent
                                   : (cellMouse.containsMouse ? Theme.alpha(Theme.surface, 0.95) : "transparent")
                            visible: dayCell.modelData > 0
                        }

                        MonoText {
                            anchors.centerIn: parent
                            visible: dayCell.modelData > 0
                            text: dayCell.modelData ? dayCell.modelData.toString() : ""
                            font.bold: dayCell.modelData === clock.date.getDate()
                            font.pixelSize: 11
                            color: dayCell.modelData === clock.date.getDate() ? Theme.background : Theme.foreground
                        }

                        MouseArea {
                            id: cellMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: dayCell.modelData > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        }
                    }
                }
            }
        }
    }

    // 6. NOTIFICATION POPUP (Modern Notification Center & Clear All Option)
    BarPopup {
        id: notifPop
        trigger: bar.notifTrigger
        popupWidth: 320
        surface: bar.surface
        align: "center"

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            // Header with unread count and Clear All button
            RowLayout {
                Layout.fillWidth: true
                SvgIcon { name: "bell"; size: 14; color: Theme.accent }
                Text {
                    text: "NOTIFICATIONS"
                    font.family: "Outfit"; font.bold: true; font.pixelSize: 11; font.letterSpacing: 0.5; color: Theme.muted
                }
                Rectangle {
                    visible: bar.notifCount > 0
                    width: 18; height: 18; radius: 9
                    color: Theme.accent
                    Text { anchors.centerIn: parent; text: bar.notifCount.toString(); font.family: "Outfit"; font.pixelSize: 10; font.bold: true; color: Theme.background }
                }
                Item { Layout.fillWidth: true }
                ActionButton {
                    icon: "trash"
                    label: "Clear All"
                    visible: bar.notifCount > 0
                    onClicked: bar.clearNotifications()
                }
            }

            // Notification Cards List / Empty State
            Item {
                Layout.fillWidth: true
                implicitHeight: (bar.notifCount === 0) ? 80 : Math.min(bar.notifCount * 62, 240)

                // Empty State
                Column {
                    anchors.centerIn: parent
                    visible: bar.notifCount === 0
                    spacing: 4
                    SvgIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "check"; size: 22; color: Theme.accent }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "All caught up"; font.family: "Outfit"; font.bold: true; font.pixelSize: 12; color: Theme.foreground }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Desktop quiet • No unread notifications"; font.family: "Outfit"; font.pixelSize: 10; color: Theme.muted }
                }

                ListView {
                    anchors.fill: parent
                    visible: bar.notifCount > 0
                    model: bar.notificationList
                    clip: true
                    spacing: 6

                    delegate: Rectangle {
                        id: notifCard
                        required property var modelData
                        width: ListView.view.width
                        height: 56
                        radius: 8
                        color: notifMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.55)
                        border.width: 1
                        border.color: notifMouse.containsMouse ? Theme.alpha(Theme.accent, 0.35) : Theme.alpha(Theme.foreground, 0.06)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: (modelData.appName || "App").toUpperCase()
                                    font.family: "Outfit"; font.bold: true; font.pixelSize: 9; color: Theme.accent
                                }
                                Text {
                                    text: "• " + (modelData.time || "")
                                    font.family: "Outfit"; font.pixelSize: 9; color: Theme.muted
                                }
                                Item { Layout.fillWidth: true }
                                Rectangle {
                                    width: 16; height: 16; radius: 8
                                    color: dismissMouse.containsMouse ? Theme.alpha(Theme.error, 0.25) : "transparent"
                                    SvgIcon { anchors.centerIn: parent; name: "x"; size: 10; color: Theme.muted }
                                    MouseArea {
                                        id: dismissMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: bar.dismissNotification(modelData.id)
                                    }
                                }
                            }

                            Text {
                                text: modelData.summary || ""
                                font.family: "Outfit"; font.bold: true; font.pixelSize: 11; color: Theme.foreground
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: modelData.body || ""
                                font.family: "Outfit"; font.pixelSize: 10; color: Theme.alpha(Theme.foreground, 0.70)
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: notifMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: bar.dismissNotification(modelData.id)
                        }
                    }
                }
            }
        }
    }

    // 7. PACKAGE UPDATES POPUP
    BarPopup {
        id: pkgPop
        trigger: bar.pkgTrigger
        popupWidth: 280
        surface: bar.surface
        align: "right"

        RowLayout {
            Layout.fillWidth: true
            SvgIcon { name: "package"; size: 28; color: Theme.accent }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                MonoText { text: bar.pkgCount > 0 ? (bar.pkgCount + " Updates Available") : "System Up to Date"; font.bold: true; font.pixelSize: 13 }
                MonoText { text: "Arch Linux official & AUR"; font.pixelSize: 10; color: Theme.muted }
            }
        }

        ActionButton {
            Layout.fillWidth: true
            icon: "bolt"
            label: "Open Package Updater"
            active: true
            onClicked: {
                pkgPop.close()
                Quickshell.execDetached([bar.homeDir + "/.hyprconf/hypr/scripts/sh/qs-updater.sh"])
            }
        }
    }

    // 8. QUICK TOGGLES & CLIPBOARD POPUP (with Clear History Option)
    BarPopup {
        id: togglesPop
        trigger: bar.togglesTrigger
        popupWidth: 320
        surface: bar.surface
        align: "right"
        hoverOpen: false

        onShownChanged: {
            if (shown) {
                clipProc.running = true
                clipCountProc.running = true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                ActionButton {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "coffee"; label: "Caffeine"
                    active: bar.caffeine
                    onClicked: bar.toggleCaffeine()
                }
                ActionButton {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "moonStar"; label: "Night Light"
                    active: bar.nightLight
                    onClicked: bar.toggleNightLight()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.alpha(Theme.foreground, 0.12)
            }

            // Clipboard Header with Clear History Button
            RowLayout {
                Layout.fillWidth: true
                SvgIcon { name: "clipboard"; size: 13; color: Theme.accent }
                Text {
                    text: "RECENT CLIPBOARD"
                    font.family: "Outfit"; font.bold: true; font.pixelSize: 11; font.letterSpacing: 0.5; color: Theme.muted
                }
                Rectangle {
                    visible: bar.clipCount > 0
                    width: 18; height: 18; radius: 9
                    color: Theme.alpha(Theme.accent, 0.20)
                    Text { anchors.centerIn: parent; text: bar.clipCount.toString(); font.family: "Outfit"; font.pixelSize: 10; font.bold: true; color: Theme.accent }
                }
                Item { Layout.fillWidth: true }
                ActionButton {
                    icon: "trash"
                    label: "Clear All"
                    visible: bar.clipCount > 0
                    onClicked: bar.clearClipboardHistory()
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(Math.max(clipModel.count * 30, 30), 160)
                model: clipModel
                clip: true

                // Empty state if 0 items
                Item {
                    anchors.fill: parent
                    visible: clipModel.count === 0
                    Text {
                        anchors.centerIn: parent
                        text: "Clipboard history is empty"
                        font.family: "Outfit"; font.pixelSize: 11; color: Theme.muted
                    }
                }

                delegate: Rectangle {
                    id: clipRowItem
                    width: ListView.view.width
                    height: 28
                    radius: 6
                    color: clipItemMouse.containsMouse ? Theme.alpha(Theme.accent, 0.20) : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6; anchors.rightMargin: 6
                        spacing: 6

                        Text {
                            text: "#" + (index + 1)
                            font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 10; font.bold: true
                            color: Theme.alpha(Theme.accent, 0.70)
                        }

                        MonoText {
                            Layout.fillWidth: true
                            text: model.preview
                            elide: Text.ElideRight
                            font.pixelSize: 11
                            color: clipItemMouse.containsMouse ? Theme.foreground : Theme.alpha(Theme.foreground, 0.85)
                        }
                    }

                    MouseArea {
                        id: clipItemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["sh", "-c", "cliphist decode " + model.cid + " | wl-copy"])
                            togglesPop.close()
                        }
                    }
                }
            }
        }
    }

    // 9. SYSTEM MONITOR POPUP (Real-Time CPU Sparkline Graph & Per-Core Grid)
    BarPopup {
        id: monitorPop
        trigger: bar.monitorTrigger
        popupWidth: 340
        surface: bar.surface
        align: "right"

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            // Header Row: Title & Temperature Badge
            RowLayout {
                Layout.fillWidth: true
                SvgIcon { name: "gauge"; size: 15; color: Theme.accent }
                Text {
                    text: "SYSTEM DIAGNOSTICS"
                    font.family: "Outfit"; font.bold: true; font.pixelSize: 11; font.letterSpacing: 0.5; color: Theme.muted
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: tempRow.implicitWidth + 12
                    height: 22
                    radius: 11
                    color: Theme.alpha(Theme.accent, 0.18)
                    border.width: 1; border.color: Theme.alpha(Theme.accent, 0.35)
                    Row {
                        id: tempRow
                        anchors.centerIn: parent
                        spacing: 4
                        SvgIcon { name: "thermometer"; size: 11; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: bar.cpuTemp + "°C"
                            font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 10; font.bold: true; color: Theme.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // Overview 2-Card Summary Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Card 1: CPU Total
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    height: 52; radius: 8
                    color: Theme.alpha(Theme.surface, 0.60)
                    border.width: 1; border.color: Theme.alpha(Theme.foreground, 0.08)
                    Column {
                        anchors.centerIn: parent; spacing: 2
                        Text {
                            text: "CPU LOAD"
                            font.family: "Outfit"; font.pixelSize: 9; font.bold: true; color: Theme.muted
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: Math.round(bar.cpuUsage) + "%"
                            font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 16; font.bold: true
                            color: bar.cpuUsage > 80 ? Theme.error : Theme.accent
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                // Card 2: Memory Total
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    height: 52; radius: 8
                    color: Theme.alpha(Theme.surface, 0.60)
                    border.width: 1; border.color: Theme.alpha(Theme.foreground, 0.08)
                    Column {
                        anchors.centerIn: parent; spacing: 2
                        Text {
                            text: "RAM (DDR4)"
                            font.family: "Outfit"; font.pixelSize: 9; font.bold: true; color: Theme.muted
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: bar.memUsedGiB.toFixed(1) + " / " + bar.memTotalGiB.toFixed(0) + " GB"
                            font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 13; font.bold: true; color: Theme.foreground
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }

            // Real-Time CPU Sparkline Graph
            Rectangle {
                Layout.fillWidth: true
                height: 64
                radius: 8
                color: Theme.alpha(Theme.surface, 0.50)
                border.width: 1; border.color: Theme.alpha(Theme.foreground, 0.08)
                clip: true

                // 50% guideline
                Rectangle {
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 1
                    color: Theme.alpha(Theme.foreground, 0.10)
                }

                Canvas {
                    id: cpuCanvas
                    anchors.fill: parent
                    antialiasing: true

                    Connections {
                        target: bar
                        function onCpuHistoryChanged() {
                            cpuCanvas.requestPaint()
                        }
                    }

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        var w = width
                        var h = height
                        var hist = bar.cpuHistory
                        if (!hist || hist.length < 2) return

                        var step = w / (hist.length - 1)
                        ctx.beginPath()
                        ctx.moveTo(0, h - (hist[0] / 100) * (h - 8) - 4)
                        for (var i = 1; i < hist.length; i++) {
                            var x = i * step
                            var y = h - (hist[i] / 100) * (h - 8) - 4
                            ctx.lineTo(x, y)
                        }

                        // Gradient stroke line
                        ctx.strokeStyle = Theme.accent
                        ctx.lineWidth = 2
                        ctx.stroke()

                        // Fill area under curve
                        ctx.lineTo(w, h)
                        ctx.lineTo(0, h)
                        ctx.closePath()
                        var grad = ctx.createLinearGradient(0, 0, 0, h)
                        grad.addColorStop(0, Theme.alpha(Theme.accent, 0.35))
                        grad.addColorStop(1, Theme.alpha(Theme.accent, 0.02))
                        ctx.fillStyle = grad
                        ctx.fill()

                        // Pulse head dot at current point
                        var lastX = (hist.length - 1) * step
                        var lastY = h - (hist[hist.length - 1] / 100) * (h - 8) - 4
                        ctx.beginPath()
                        ctx.arc(lastX - 2, lastY, 3, 0, Math.PI * 2)
                        ctx.fillStyle = Theme.accent
                        ctx.fill()
                    }
                }
            }

            // 8-Thread CPU Per-Core Updates Grid
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "PER-CORE THREAD METRICS"
                    font.family: "Outfit"; font.bold: true; font.pixelSize: 9; color: Theme.muted
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    rowSpacing: 4
                    columnSpacing: 4

                    Repeater {
                        model: bar.cpuCores
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true; Layout.preferredWidth: 1
                            height: 30
                            radius: 6
                            color: Theme.alpha(Theme.surface, 0.65)
                            border.width: 1
                            border.color: Theme.alpha(Theme.foreground, 0.06)

                            Column {
                                anchors.fill: parent
                                anchors.margins: 4
                                spacing: 2

                                RowLayout {
                                    width: parent.width
                                    Text {
                                        text: "C" + index
                                        font.family: "Outfit"; font.pixelSize: 8; font.bold: true; color: Theme.muted
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: Math.round(modelData) + "%"
                                        font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 9; font.bold: true
                                        color: modelData > 80 ? Theme.error : Theme.foreground
                                    }
                                }

                                // Level progress bar
                                Rectangle {
                                    width: parent.width
                                    height: 3; radius: 1.5
                                    color: Theme.alpha(Theme.surface, 0.90)

                                    Rectangle {
                                        width: parent.width * Math.min(1.0, Math.max(0.04, modelData / 100))
                                        height: parent.height; radius: 1.5
                                        color: modelData > 80 ? Theme.error : (modelData > 50 ? "#f59e0b" : Theme.accent)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // GPU Hardware Telemetry Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: gpuLayout.implicitHeight + 12
                radius: 8
                color: Theme.alpha(Theme.surface, 0.60)
                border.width: 1; border.color: Theme.alpha(Theme.foreground, 0.08)
                visible: bar.gpuStats !== null

                ColumnLayout {
                    id: gpuLayout
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        SvgIcon { name: "zap"; size: 12; color: Theme.accent }
                        Text {
                            text: (bar.gpuStats ? bar.gpuStats.type : "GPU") + " Hardware Graphics"
                            font.family: "Outfit"; font.pixelSize: 10; font.bold: true; color: Theme.foreground
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: {
                                if (!bar.gpuStats) return ""
                                if (bar.gpuStats.vram_used !== undefined && bar.gpuStats.vram_total > 0) {
                                    return bar.gpuStats.vram_used + " / " + bar.gpuStats.vram_total + " GB (" + Math.round(bar.gpuStats.vram_percent) + "%)"
                                }
                                if (bar.gpuStats.freq_mhz !== undefined) {
                                    return bar.gpuStats.freq_mhz + " MHz • " + Math.round(bar.gpuStats.load) + "%"
                                }
                                return Math.round(bar.gpuStats.load) + "% • " + Math.round(bar.gpuStats.temp) + "°C"
                            }
                            font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 9; color: Theme.accent
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 5; radius: 2.5
                        color: Theme.alpha(Theme.surface, 0.90)

                        Rectangle {
                            width: parent.width * Math.min(1.0, Math.max(0.04, (bar.gpuStats ? (bar.gpuStats.vram_percent || bar.gpuStats.load) : 0) / 100))
                            height: parent.height; radius: 2.5
                            color: Theme.accent
                        }
                    }
                }
            }

            // Storage / NVMe Bar
            Rectangle {
                Layout.fillWidth: true
                height: 42
                radius: 8
                color: Theme.alpha(Theme.surface, 0.60)
                border.width: 1; border.color: Theme.alpha(Theme.foreground, 0.08)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        SvgIcon { name: "disk"; size: 12; color: Theme.accent }
                        Text {
                            text: "Root NVMe SSD (/)"
                            font.family: "Outfit"; font.pixelSize: 10; font.bold: true; color: Theme.foreground
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: bar.diskUsedGiB.toFixed(1) + " / " + bar.diskTotalGiB.toFixed(0) + " GB (" + Math.round(bar.diskPercent) + "%)"
                            font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 9; color: Theme.muted
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 5; radius: 2.5
                        color: Theme.alpha(Theme.surface, 0.90)
                        Rectangle {
                            width: parent.width * (bar.diskTotalGiB > 0 ? (bar.diskUsedGiB / bar.diskTotalGiB) : 0)
                            height: parent.height; radius: 2.5
                            color: Theme.accent
                        }
                    }
                }
            }
        }
    }

    // 10. VOLUME & MICROPHONE POPUP
    BarPopup {
        id: volumePop
        trigger: bar.volumeTrigger
        popupWidth: 320
        surface: bar.surface
        align: "right"

        onShownChanged: {
            if (shown) {
                audioDevicesProc.running = true
                audioStreamsProc.running = true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            // ── AUDIO OUTPUT SECTION ─────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Rectangle {
                    width: 24; height: 24; radius: 6
                    color: bar.muted ? Theme.alpha(Theme.error, 0.20) : Theme.alpha(Theme.accent, 0.18)
                    SvgIcon {
                        anchors.centerIn: parent
                        name: bar.muted ? "volumeMute" : "volume"
                        size: 14
                        color: bar.muted ? Theme.error : Theme.accent
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bar.toggleMute()
                    }
                }
                Text {
                    text: "OUTPUT VOLUME"
                    font.family: "Outfit"; font.bold: true; font.pixelSize: 11; font.letterSpacing: 0.5; color: Theme.muted
                }
                Item { Layout.fillWidth: true }
                MonoText {
                    text: bar.muted ? "MUTED" : Math.round(bar.volume * 100) + "%"
                    font.bold: true; font.pixelSize: 12
                    color: bar.muted ? Theme.error : Theme.foreground
                }
            }

            // Interactive Volume Slider Bar (Click, Drag, and Mouse Scroll Wheel)
            Rectangle {
                Layout.fillWidth: true
                height: 10
                radius: 5
                color: Theme.alpha(Theme.surface, 0.90)

                Rectangle {
                    width: parent.width * Math.min(1.0, bar.volume)
                    height: parent.height
                    radius: 5
                    color: bar.muted ? Theme.error : Theme.accent
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: mouse => bar.setVolume(mouse.x / width)
                    onPositionChanged: mouse => {
                        if (pressed) bar.setVolume(mouse.x / width)
                    }
                    onWheel: wheel => {
                        var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                        bar.setVolume(Math.max(0, Math.min(1.5, bar.volume + delta)))
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.alpha(Theme.foreground, 0.10)
            }

            // ── MICROPHONE INPUT SECTION ─────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Rectangle {
                    width: 24; height: 24; radius: 6
                    color: bar.micMuted ? Theme.alpha(Theme.error, 0.20) : Theme.alpha(Theme.accent, 0.18)
                    SvgIcon {
                        anchors.centerIn: parent
                        name: bar.micMuted ? "micMute" : "mic"
                        size: 14
                        color: bar.micMuted ? Theme.error : Theme.accent
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bar.toggleMicMute()
                    }
                }
                Text {
                    text: "MICROPHONE"
                    font.family: "Outfit"; font.bold: true; font.pixelSize: 11; font.letterSpacing: 0.5; color: Theme.muted
                }
                Item { Layout.fillWidth: true }
                MonoText {
                    text: bar.micMuted ? "MUTED" : Math.round(bar.micVolume * 100) + "%"
                    font.bold: true; font.pixelSize: 12
                    color: bar.micMuted ? Theme.error : Theme.foreground
                }
            }

            // Interactive Mic Slider Bar (Click, Drag, and Mouse Scroll Wheel)
            Rectangle {
                Layout.fillWidth: true
                height: 10
                radius: 5
                color: Theme.alpha(Theme.surface, 0.90)

                Rectangle {
                    width: parent.width * Math.min(1.0, bar.micVolume)
                    height: parent.height
                    radius: 5
                    color: bar.micMuted ? Theme.error : Theme.accent
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: mouse => bar.setMicVolume(mouse.x / width)
                    onPositionChanged: mouse => {
                        if (pressed) bar.setMicVolume(mouse.x / width)
                    }
                    onWheel: wheel => {
                        var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                        bar.setMicVolume(Math.max(0, Math.min(1.5, bar.micVolume + delta)))
                    }
                }
            }

            // ── APPLICATION AUDIO STREAMS (PER-APP VOLUME) ────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                visible: bar.audioStreams.length > 0
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.alpha(Theme.foreground, 0.10)
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "APPLICATION AUDIO"
                        font.family: "Outfit"; font.bold: true; font.pixelSize: 10; font.letterSpacing: 0.5; color: Theme.muted
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: bar.audioStreams.length + " ACTIVE"
                        font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 9; color: Theme.accent
                    }
                }

                Timer {
                    id: streamRefreshTimer
                    interval: 150
                    repeat: false
                    onTriggered: audioStreamsProc.running = true
                }

                Repeater {
                    model: bar.audioStreams
                    delegate: ColumnLayout {
                        id: streamCol
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Rectangle {
                                width: 22; height: 22; radius: 5
                                color: streamCol.modelData.muted ? Theme.alpha(Theme.error, 0.20) : Theme.alpha(Theme.accent, 0.15)

                                Text {
                                    anchors.centerIn: parent
                                    text: streamCol.modelData.muted ? "󰝟" : "󰕾"
                                    font.family: "JetBrainsMono Nerd Font, monospace"
                                    font.pixelSize: 11
                                    color: streamCol.modelData.muted ? Theme.error : Theme.accent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(["python3", bar.homeDir + "/.hyprconf/hypr/scripts/py/audio-streams.py", "--toggle-mute", streamCol.modelData.id.toString()])
                                        streamRefreshTimer.restart()
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: streamCol.modelData.name
                                font.family: "Outfit"; font.pixelSize: 11; font.weight: Font.Medium
                                color: streamCol.modelData.muted ? Theme.muted : Theme.foreground
                                elide: Text.ElideRight
                            }

                            MonoText {
                                text: streamCol.modelData.muted ? "MUTED" : Math.round(streamCol.modelData.volume * 100) + "%"
                                font.pixelSize: 10; font.bold: true
                                color: streamCol.modelData.muted ? Theme.error : Theme.foreground
                            }
                        }

                        // App volume slider
                        Rectangle {
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            color: Theme.alpha(Theme.surface, 0.90)

                            Rectangle {
                                width: parent.width * Math.max(0.0, Math.min(1.0, streamCol.modelData.volume))
                                height: parent.height
                                radius: 3
                                color: streamCol.modelData.muted ? Theme.error : Theme.accent
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: mouse => {
                                    var pct = Math.round((mouse.x / width) * 100)
                                    Quickshell.execDetached(["python3", bar.homeDir + "/.hyprconf/hypr/scripts/py/audio-streams.py", "--set-vol", streamCol.modelData.id.toString(), pct.toString()])
                                    streamRefreshTimer.restart()
                                }
                                onWheel: wheel => {
                                    var delta = wheel.angleDelta.y > 0 ? 5 : -5
                                    var newPct = Math.max(0, Math.min(150, Math.round(streamCol.modelData.volume * 100) + delta))
                                    Quickshell.execDetached(["python3", bar.homeDir + "/.hyprconf/hypr/scripts/py/audio-streams.py", "--set-vol", streamCol.modelData.id.toString(), newPct.toString()])
                                    streamRefreshTimer.restart()
                                }
                            }
                        }
                    }
                }
            }

            // ── AUDIO DEVICE SWITCHER ACCORDION ──────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 28
                radius: 6
                color: devSwitchMouse.containsMouse ? Theme.alpha(Theme.surface, 0.95) : Theme.alpha(Theme.surface, 0.45)
                border.width: 1
                border.color: bar.showDeviceSwitcher ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8; anchors.rightMargin: 8
                    spacing: 6

                    SvgIcon { name: "refresh"; size: 12; color: bar.showDeviceSwitcher ? Theme.accent : Theme.muted }
                    Text {
                        text: "AUDIO DEVICES"
                        font.family: "Outfit"; font.bold: true; font.pixelSize: 10; font.letterSpacing: 0.5
                        color: bar.showDeviceSwitcher ? Theme.accent : Theme.muted
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: bar.showDeviceSwitcher ? "▲" : "▼"
                        font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 9
                        color: bar.showDeviceSwitcher ? Theme.accent : Theme.muted
                    }
                }

                MouseArea {
                    id: devSwitchMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        bar.showDeviceSwitcher = !bar.showDeviceSwitcher
                        if (bar.showDeviceSwitcher) audioDevicesProc.running = true
                    }
                }
            }

            // Expanded Audio Device List (Output Sinks & Input Sources)
            ColumnLayout {
                Layout.fillWidth: true
                visible: bar.showDeviceSwitcher
                spacing: 8

                // Sinks (Output)
                Text {
                    text: "OUTPUT DESTINATION"
                    font.family: "Outfit"; font.pixelSize: 9; font.bold: true; color: Theme.muted; font.letterSpacing: 0.5
                }
                Repeater {
                    model: bar.audioSinks
                    delegate: Rectangle {
                        id: sinkItem
                        required property var modelData
                        Layout.fillWidth: true
                        height: 26
                        radius: 5
                        color: sinkItem.modelData.is_default
                            ? Theme.alpha(Theme.accent, 0.22)
                            : (sinkMouse.containsMouse ? Theme.alpha(Theme.surface, 0.8) : Theme.alpha(Theme.surface, 0.35))
                        border.width: sinkItem.modelData.is_default ? 1 : 0
                        border.color: Theme.accent

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8; anchors.rightMargin: 8
                            spacing: 6

                            Rectangle {
                                width: 6; height: 6; radius: 3
                                color: sinkItem.modelData.is_default ? Theme.accent : Theme.alpha(Theme.foreground, 0.25)
                            }
                            Text {
                                Layout.fillWidth: true
                                text: sinkItem.modelData.name
                                font.family: "Outfit"; font.pixelSize: 10
                                font.weight: sinkItem.modelData.is_default ? Font.Bold : Font.Normal
                                color: sinkItem.modelData.is_default ? Theme.accent : Theme.foreground
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: sinkMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                Quickshell.execDetached(["wpctl", "set-default", sinkItem.modelData.id.toString()])
                                audioDevicesProc.running = true
                            }
                        }
                    }
                }

                // Sources (Input)
                Text {
                    text: "INPUT SOURCE"
                    font.family: "Outfit"; font.pixelSize: 9; font.bold: true; color: Theme.muted; font.letterSpacing: 0.5
                    Layout.topMargin: 4
                }
                Repeater {
                    model: bar.audioSources
                    delegate: Rectangle {
                        id: srcItem
                        required property var modelData
                        Layout.fillWidth: true
                        height: 26
                        radius: 5
                        color: srcItem.modelData.is_default
                            ? Theme.alpha(Theme.accent, 0.22)
                            : (srcMouse.containsMouse ? Theme.alpha(Theme.surface, 0.8) : Theme.alpha(Theme.surface, 0.35))
                        border.width: srcItem.modelData.is_default ? 1 : 0
                        border.color: Theme.accent

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8; anchors.rightMargin: 8
                            spacing: 6

                            Rectangle {
                                width: 6; height: 6; radius: 3
                                color: srcItem.modelData.is_default ? Theme.accent : Theme.alpha(Theme.foreground, 0.25)
                            }
                            Text {
                                Layout.fillWidth: true
                                text: srcItem.modelData.name
                                font.family: "Outfit"; font.pixelSize: 10
                                font.weight: srcItem.modelData.is_default ? Font.Bold : Font.Normal
                                color: srcItem.modelData.is_default ? Theme.accent : Theme.foreground
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: srcMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                Quickshell.execDetached(["wpctl", "set-default", srcItem.modelData.id.toString()])
                                audioDevicesProc.running = true
                            }
                        }
                    }
                }
            }

            // Media Controls (if player active)
            ColumnLayout {
                Layout.fillWidth: true
                visible: bar.player !== null
                spacing: 6

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.alpha(Theme.foreground, 0.12) }

                MonoText {
                    Layout.fillWidth: true
                    text: (bar.player && bar.player.trackTitle) ? bar.player.trackTitle : "No media playing"
                    font.bold: true
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12
                    ActionButton { icon: "prev"; label: ""; onClicked: if (bar.player) bar.player.previous() }
                    ActionButton {
                        icon: (bar.player && bar.player.playbackState === MprisPlaybackState.Playing) ? "pause" : "play"
                        label: ""
                        active: true
                        onClicked: if (bar.player) bar.player.togglePlaying()
                    }
                    ActionButton { icon: "next"; label: ""; onClicked: if (bar.player) bar.player.next() }
                }
            }
        }
    }

    // 11. NETWORK ACTIVITY & INDIVIDUAL APPS POPUP (Hover Dropdown on Internet Speed Meter)
    BarPopup {
        id: netPop
        trigger: bar.netTrigger
        popupWidth: 320
        surface: bar.surface
        align: "center"
        hoverOpen: true

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            // Header Row: Network Icon, Title, and Overall Throughput Badge
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                SvgIcon { name: "wifi"; size: 14; color: Theme.accent }
                Text {
                    text: "NETWORK ACTIVITY"
                    font.family: "Outfit"; font.bold: true; font.pixelSize: 11; font.letterSpacing: 0.5; color: Theme.muted
                }
                Item { Layout.fillWidth: true }

                Rectangle {
                    height: 20
                    implicitWidth: netSumRow.implicitWidth + 10
                    radius: 4
                    color: Theme.alpha(Theme.surface, 0.75)
                    border.width: 1
                    border.color: Theme.alpha(Theme.foreground, 0.12)

                    RowLayout {
                        id: netSumRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text { text: "↓ " + bar.netDownStr; font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 9; font.bold: true; color: "#06b6d4" }
                        Text { text: "↑ " + bar.netUpStr; font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 9; font.bold: true; color: "#f59e0b" }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.alpha(Theme.foreground, 0.10)
            }

            // Per-Process Bandwidth List
            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(Math.max((bar.netProcesses ? bar.netProcesses.length : 0) * 36, 36), 220)
                model: bar.netProcesses || []
                clip: true
                spacing: 4
                boundsBehavior: Flickable.StopAtBounds

                Item {
                    anchors.fill: parent
                    visible: !bar.netProcesses || bar.netProcesses.length === 0
                    Text {
                        anchors.centerIn: parent
                        text: "No active network connections"
                        font.family: "Outfit"; font.pixelSize: 11; color: Theme.muted
                    }
                }

                delegate: Rectangle {
                    id: procRowItem
                    required property var modelData
                    width: ListView.view.width
                    height: 32
                    radius: 6
                    color: procMouse.containsMouse ? Theme.alpha(Theme.accent, 0.16) : Theme.alpha(Theme.surface, 0.40)
                    border.width: 1
                    border.color: procMouse.containsMouse ? Theme.alpha(Theme.accent, 0.35) : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8; anchors.rightMargin: 8
                        spacing: 8

                        Rectangle {
                            width: 6; height: 6; radius: 3
                            color: procRowItem.modelData.active ? "#10b981" : Theme.alpha(Theme.foreground, 0.25)
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                text: procRowItem.modelData.name || procRowItem.modelData.raw_name || "Process"
                                font.family: "Outfit"; font.pixelSize: 11; font.weight: Font.DemiBold
                                color: Theme.foreground
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: "PID " + procRowItem.modelData.pid + (procRowItem.modelData.ext_conns ? (" • " + procRowItem.modelData.ext_conns + " sockets") : "")
                                font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 9
                                color: Theme.muted
                            }
                        }

                        RowLayout {
                            spacing: 6
                            Text {
                                text: "↓ " + (procRowItem.modelData.down_str || "0 B/s")
                                font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 9; font.bold: true
                                color: (procRowItem.modelData.down_bps > 0) ? "#06b6d4" : Theme.alpha(Theme.foreground, 0.40)
                            }
                            Text {
                                text: "↑ " + (procRowItem.modelData.up_str || "0 B/s")
                                font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 9; font.bold: true
                                color: (procRowItem.modelData.up_bps > 0) ? "#f59e0b" : Theme.alpha(Theme.foreground, 0.40)
                            }
                        }
                    }

                    MouseArea {
                        id: procMouse
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }
            }
        }
    }

    // 11. POWER & SESSION POPUP (Modern Obsidian Action Tiles)
    BarPopup {
        id: powerPop
        trigger: bar.powerTrigger
        popupWidth: 260
        surface: bar.surface
        align: "right"
        hoverOpen: false

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 6
            columnSpacing: 6

            ActionButton { Layout.fillWidth: true; icon: "lock"; label: "Lock"; onClicked: { powerPop.close(); Quickshell.execDetached(["loginctl", "lock-session"]) } }
            ActionButton { Layout.fillWidth: true; icon: "logout"; label: "Logout"; confirm: true; onClicked: { powerPop.close(); Quickshell.execDetached(["hyprctl", "dispatch", "exit"]) } }
            ActionButton { Layout.fillWidth: true; icon: "reboot"; label: "Reboot"; confirm: true; onClicked: { powerPop.close(); Quickshell.execDetached(["systemctl", "reboot"]) } }
            ActionButton { Layout.fillWidth: true; icon: "power"; label: "Shutdown"; confirm: true; onClicked: { powerPop.close(); Quickshell.execDetached(["systemctl", "poweroff"]) } }
        }
    }

    // ================================================================
    // 12. ON-SCREEN DISPLAY (OSD) & NOTIFICATION TOAST
    // ================================================================
    BarOSD {
        id: osd
        bar: bar
    }

    BarNotificationToast {
        id: notifToast
        bar: bar
    }
}
