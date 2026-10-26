//@ pragma Env QS_NO_RELOAD_POPUP=1
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "."

FloatingWindow {
    id: window
    title: "Hyprland & Quickshell Settings"
    implicitWidth: 1220
    implicitHeight: 800
    color: Theme.background
    onClosed: Qt.quit()

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : "/home/user"
    }

    readonly property string configPath: homeDir + "/.hyprconf/quickshell/lockscreen.json"
    property real avatarTimestamp: 1
    readonly property string avatarPath: "file://" + homeDir + "/.hyprconf/hypr/.cache/.face" + (avatarTimestamp > 1 ? ("?t=" + avatarTimestamp) : "")
    readonly property string wallpaperPath: "file://" + homeDir + "/.hyprconf/hypr/.cache/current_wallpaper.png"

    IpcHandler {
        target: "settings"
        function openHyprconf() {
            window.activeRootNav = 0
            window.activeSection = 0
            window.visible = true
        }
        function openIsland() {
            window.activeRootNav = 1
            window.activeSection = 10
            window.visible = true
        }
        function openWidgets() {
            window.activeRootNav = 2
            window.activeSection = 11
            window.visible = true
        }
        function openWidgetsLibrary() {
            window.activeRootNav = 2
            window.activeSection = 11
            if (typeof widgetsSection !== "undefined" && widgetsSection) widgetsSection.activeTab = 0
            window.visible = true
        }
        function openWidgetsCustomizer() {
            window.activeRootNav = 2
            window.activeSection = 11
            if (typeof widgetsSection !== "undefined" && widgetsSection) widgetsSection.activeTab = 1
            window.visible = true
        }
        function openWeatherCustomizer() {
            window.activeRootNav = 2
            window.activeSection = 11
            if (typeof widgetsSection !== "undefined" && widgetsSection) {
                widgetsSection.selectedWidgetId = "weather"
                widgetsSection.activeTab = 1
            }
            window.visible = true
        }
        function openVisualizerCustomizer() {
            window.activeRootNav = 2
            window.activeSection = 11
            if (typeof widgetsSection !== "undefined" && widgetsSection) {
                widgetsSection.selectedWidgetId = "visualizer"
                widgetsSection.activeTab = 1
            }
            window.visible = true
        }
        function openWidgetsGlobal() {
            window.activeRootNav = 2
            window.activeSection = 11
            if (typeof widgetsSection !== "undefined" && widgetsSection) widgetsSection.activeTab = 2
            window.visible = true
        }
        function openWeather() {
            window.activeRootNav = 3
            window.activeSection = 7
            window.visible = true
        }
        function openLockscreen() {
            window.activeRootNav = 4
            window.activeSection = 9
            if (typeof lockscreenSection !== "undefined" && lockscreenSection) {
                lockscreenSection.studioMode = 0
            }
            window.visible = true
        }
        function openLockscreenPreview() {
            window.activeRootNav = 4
            window.activeSection = 9
            if (typeof lockscreenSection !== "undefined" && lockscreenSection) {
                lockscreenSection.studioMode = 1
            }
            window.visible = true
        }
        function openLockscreenSettings() {
            window.activeRootNav = 4
            window.activeSection = 9
            if (typeof lockscreenSection !== "undefined" && lockscreenSection) {
                lockscreenSection.studioMode = 2
            }
            window.visible = true
        }
        function openDock() {
            window.activeRootNav = 5
            window.activeSection = 12
            window.visible = true
        }
    }

    // Default configuration template for Lockscreen
    function getDefaultConfig() {
        return {
            layout: {
                mode: "freeform",
                alignment: "center",
                vertical_offset: 0,
                module_spacing: 20,
                corner_power_buttons: true,
                corner_session_badge: true
            },
            positions: {
                clock: { x: 0.50, y: 0.20, preset: "top-center" },
                quote: { x: 0.50, y: 0.33, preset: "top-center" },
                avatar: { x: 0.50, y: 0.52, preset: "center" },
                weather: { x: 0.80, y: 0.09, preset: "top-right" },
                media_player: { x: 0.25, y: 0.88, preset: "bottom-left" },
                system_stats: { x: 0.50, y: 0.88, preset: "bottom-center" }
            },
            clock: {
                enabled: true,
                format_24h: false,
                show_am_pm: true,
                size: 84,
                weight: "Light"
            },
            date: {
                enabled: true,
                format: "long"
            },
            avatar: {
                enabled: true,
                size: 116,
                breathing_enabled: true,
                orbit_satellites_enabled: true,
                glow_enabled: true,
                show_username: true,
                show_status: true
            },
            modules: {
                media_player: false,
                custom_quote: false,
                quote_text: "Crafting the digital realm.",
                system_stats: false,
                weather_widget: true,
                weather_city: "",
                weather_country: ""
            },
            stats: {
                show_uptime: true,
                show_ram: true,
                show_cpu: true,
                show_disk: false,
                show_battery: true,
                unit_format: "percent",
                separator: "•"
            },
            backdrop: {
                blur: 0.65,
                vignette: 0.65,
                dimming: 0.20
            }
        }
    }

    // activeRootNav: 0 for "Hyprconf Settings", 1 for "Dynamic Island", 2 for "Desktop Widgets", 3 for "Weather", 4 for "Lockscreen Canvas", 5 for "Application Dock"
    property int activeRootNav: (Quickshell.env("QS_SETTINGS_SECTION") === "island" ? 1 : (Quickshell.env("QS_SETTINGS_SECTION") === "widgets" ? 2 : (Quickshell.env("QS_SETTINGS_SECTION") === "dock" ? 5 : (Quickshell.env("QS_SETTINGS_SECTION") === "weather" ? 3 : (Quickshell.env("QS_SETTINGS_SECTION") === "lockscreen" ? 4 : 0)))))
    // Sub-sections under Hyprconf Settings:
    // 0: Overview, 1: Appearance, 2: Display, 3: Animations, 4: Input, 5: Login Avatar
    property int activeSection: (Quickshell.env("QS_SETTINGS_SECTION") === "island" ? 10 : (Quickshell.env("QS_SETTINGS_SECTION") === "widgets" ? 11 : (Quickshell.env("QS_SETTINGS_SECTION") === "dock" ? 12 : (Quickshell.env("QS_SETTINGS_SECTION") === "weather" ? 7 : (Quickshell.env("QS_SETTINGS_SECTION") === "lockscreen" ? 9 : 0)))))
    property int activeTab: 0 // Subtab in Lockscreen (0: Layout, 1: Clock, 2: Avatar, 3: Widgets, 4: Backdrop)
    property bool isDirty: false
    property bool showSaveToast: false
    property string toastMessage: "Settings Saved"

    // Bezier Curve Inspector & Easing Runner
    property string animInspectorCurve: "elegant_bounce"
    property real animInspectorP1x: 0.40
    property real animInspectorP1y: 1.07
    property real animInspectorP2x: 0.28
    property real animInspectorP2y: 1.15
    property real runnerTime: 0.0
    property bool runnerLoop: true
    property int runnerDurationMs: 1600

    SequentialAnimation {
        id: runnerAnimation
        loops: window.runnerLoop ? Animation.Infinite : 1
        running: window.runnerLoop

        NumberAnimation {
            target: window
            property: "runnerTime"
            from: 0.0
            to: 1.0
            duration: window.runnerDurationMs
            easing.type: Easing.Linear
        }

        PauseAnimation {
            duration: 650
        }

        ScriptAction {
            script: window.runnerTime = 0.0
        }
    }

    function evalBezier(t, x1, y1, x2, y2) {
        if (t <= 0) return 0.0
        if (t >= 1) return 1.0
        var s = t
        for (var i = 0; i < 8; i++) {
            var inv = 1.0 - s
            var x = 3.0 * inv * inv * s * x1 + 3.0 * inv * s * s * x2 + s * s * s
            var dx = 3.0 * inv * inv * x1 + 6.0 * inv * s * (x2 - x1) + 3.0 * s * s * (1.0 - x2)
            if (Math.abs(dx) < 1e-6) break
            s -= (x - t) / dx
            s = Math.max(0.0, Math.min(1.0, s))
        }
        var inv = 1.0 - s
        return 3.0 * inv * inv * s * y1 + 3.0 * inv * s * s * y2 + s * s * s
    }

    function selectBezierPreset(name) {
        window.animInspectorCurve = name
        if (window.liveCurves && window.liveCurves[name]) {
            var pts = window.liveCurves[name]
            if (pts.length >= 2) {
                window.animInspectorP1x = pts[0][0]
                window.animInspectorP1y = pts[0][1]
                window.animInspectorP2x = pts[1][0]
                window.animInspectorP2y = pts[1][1]
            }
        }
    }

    function saveCurrentCurve() {
        var cPending = window.pendingHyprChanges.curve || ({})
        cPending[window.animInspectorCurve] = [
            [Number(window.animInspectorP1x.toFixed(2)), Number(window.animInspectorP1y.toFixed(2))],
            [Number(window.animInspectorP2x.toFixed(2)), Number(window.animInspectorP2y.toFixed(2))]
        ]
        window.markHypr("curve", cPending)
    }

    function createCustomCurve(name) {
        var clean = name.trim().toLowerCase().replace(/[^a-z0-9_]/g, '_')
        if (!clean) return false
        var updated = Object.assign({}, window.liveCurves)
        updated[clean] = [
            [Number(window.animInspectorP1x.toFixed(2)), Number(window.animInspectorP1y.toFixed(2))],
            [Number(window.animInspectorP2x.toFixed(2)), Number(window.animInspectorP2y.toFixed(2))]
        ]
        window.liveCurves = updated
        window.animInspectorCurve = clean
        window.saveCurrentCurve()
        window.toastMessage = "Custom curve '" + clean + "' created & queued!"
        window.showSaveToast = true
        toastTimer.restart()
        return true
    }

    function deleteCustomCurve(name) {
        if (!name) return
        var updated = Object.assign({}, window.liveCurves)
        delete updated[name]
        window.liveCurves = updated

        var dPending = window.pendingHyprChanges.delete_curve || []
        if (dPending.indexOf(name) === -1) {
            dPending.push(name)
        }
        window.markHypr("delete_curve", dPending)

        var cPending = window.pendingHyprChanges.curve || ({})
        delete cPending[name]
        window.markHypr("curve", cPending)

        var remaining = Object.keys(window.liveCurves)
        if (remaining.length > 0) {
            window.selectBezierPreset(remaining[0])
            bezierVisualizer.p1x = window.animInspectorP1x
            bezierVisualizer.p1y = window.animInspectorP1y
            bezierVisualizer.p2x = window.animInspectorP2x
            bezierVisualizer.p2y = window.animInspectorP2y
            runnerAnimation.restart()
        }
        window.toastMessage = "Curve '" + name + "' removed"
        window.showSaveToast = true
        toastTimer.restart()
    }

    function updateAnimLeafPending(leaf, speed, bezier, style, enabled) {
        var lPending = window.pendingHyprChanges.anim_leaf || ({})
        lPending[leaf] = {
            "speed": Number(speed),
            "bezier": bezier,
            "style": (style !== undefined) ? style : "",
            "enabled": (enabled !== undefined) ? enabled : true
        }
        window.markHypr("anim_leaf", lPending)
    }

    function updateMonitorPending(output, mode, scale, pos) {
        var mPending = window.pendingHyprChanges.monitor || ({})
        mPending[output] = {
            "mode": mode,
            "scale": scale,
            "position": pos || "auto"
        }
        window.markHypr("monitor", mPending)
    }

    function updateInputBoolPending(key, val) {
        window.liveInput[key] = val
        var bPending = window.pendingHyprChanges.input_bool || ({})
        bPending[key] = val
        window.markHypr("input_bool", bPending)
    }

    function getStyleOptionsForLeaf(leaf) {
        if (leaf === "windowsIn" || leaf === "windowsOut" || leaf === "windowsMove") {
            return ["slide", "slide down", "slide up", "slide left", "slide right", "popin 80%", "popin 50%", "fade"]
        }
        if (leaf === "workspaces" || leaf === "specialWorkspace") {
            return ["slidevert", "slide", "slidefade", "slidefadevert 15%"]
        }
        if (leaf === "layersIn" || leaf === "layersOut") {
            return ["slide", "popin", "fade"]
        }
        if (leaf === "border" || leaf === "borderangle") {
            return ["loop", "once"]
        }
        return ["default", "fade"]
    }

    function getLeafMeta(leaf) {
        if (leaf === "windowsIn") return { title: "Windows Open", badge: "Window", icon: 1 }
        if (leaf === "windowsOut") return { title: "Windows Close", badge: "Window", icon: 1 }
        if (leaf === "windowsMove") return { title: "Windows Move", badge: "Move/Resize", icon: 1 }
        if (leaf === "workspaces") return { title: "Workspaces", badge: "Workspace", icon: 2 }
        if (leaf === "specialWorkspace") return { title: "Special Workspace", badge: "Scratchpad", icon: 2 }
        if (leaf === "layersIn") return { title: "Layers Entrance", badge: "Layers / UI", icon: 0 }
        if (leaf === "layersOut") return { title: "Layers Exit", badge: "Layers / UI", icon: 0 }
        if (leaf === "fade") return { title: "Opacity Fade", badge: "Fade", icon: 1 }
        if (leaf === "border") return { title: "Active Border", badge: "Border", icon: 1 }
        if (leaf === "borderangle") return { title: "Border Angle", badge: "Gradient", icon: 1 }
        return { title: leaf, badge: "Animation", icon: 3 }
    }

    // Lockscreen Config
    property var config: getDefaultConfig()

    // Hyprland Backend State
    property var backendData: null
    property var pendingHyprChanges: ({})
    property var liveAppearance: ({
        border: 2,
        rounding: 16,
        inner_gap: 4,
        outer_gap: 10,
        blur_size: 4,
        blur_pass: 4,
        opacity_act: 0.95,
        opacity_deact: 0.90,
        shadow_range: 0,
        layout: "scrolling",
        column_width: 0.8
    })
    property var liveInput: ({
        sensitivity: 0.0,
        natural_scroll: true,
        tap_to_click: true,
        disable_while_typing: true,
        left_handed: false,
        numlock_by_default: true
    })
    property var liveMonitors: []
    property var liveAnimations: []
    property var liveCurves: ({})
    property bool liveAnimGlobal: true
    property var liveEnvVars: []
    property var liveKeybinds: []
    property var liveFiles: []
    property var liveAvatar: ({})
    property var liveSddm: ({ current_theme: "prohori", is_silent_sddm: false, silent_sddm_available: true })
    property bool showNewCurveCreator: false

    // Search queries
    property string keybindSearchQuery: ""
    property string envSearchQuery: ""

    // Real-time typed properties
    property string liveWeatherCity: ""
    property string liveWeatherCountry: ""
    property string liveQuoteText: "Crafting the digital realm."
    property var sysStatsData: null
    property var currentTime: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: window.currentTime = new Date()
    }

    // ── System Stats Poller ──────────────────────────────────────────────────
    Process {
        id: sysStatsProc
        command: ["python3", window.homeDir + "/.hyprconf/hypr/scripts/py/system-stats.py"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    try {
                        window.sysStatsData = JSON.parse(text.trim())
                    } catch(e) {}
                }
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            if (!sysStatsProc.running) {
                sysStatsProc.running = true
            }
        }
    }

    // ── Backend Get Process ──────────────────────────────────────────────────
    Process {
        id: backendGetProc
        command: ["python3", window.homeDir + "/.hyprconf/hypr/scripts/py/hypr-settings-backend.py", "get"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(text)
                        window.syncBackendData(parsed)
                    } catch(e) {
                        console.log("[settings] Error parsing backend data:", e)
                    }
                }
            }
        }
    }

    function syncBackendData(data) {
        window.backendData = data
        if (data.appearance) {
            window.liveAppearance = JSON.parse(JSON.stringify(data.appearance))
        }
        if (data.input) {
            window.liveInput = JSON.parse(JSON.stringify(data.input))
        }
        if (data.monitors) {
            window.liveMonitors = data.monitors
        }
        if (data.animations) {
            window.liveAnimations = data.animations
        }
        if (data.curves) {
            window.liveCurves = data.curves
            if (data.curves["elegant_bounce"]) {
                window.selectBezierPreset("elegant_bounce")
            } else if (Object.keys(data.curves).length > 0) {
                window.selectBezierPreset(Object.keys(data.curves)[0])
            }
        }
        if (data.anim_global !== undefined) {
            window.liveAnimGlobal = data.anim_global
        }
        if (data.env_vars) {
            window.liveEnvVars = data.env_vars
        }
        if (data.keybinds) {
            window.liveKeybinds = data.keybinds
        }
        if (data.files) {
            window.liveFiles = data.files
        }
        if (data.avatar) {
            window.liveAvatar = data.avatar
        }
        if (data.sddm) {
            window.liveSddm = data.sddm
        }
    }

    // ── Backend Apply Process ────────────────────────────────────────────────
    Process {
        id: backendApplyProc
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    try {
                        var res = JSON.parse(text)
                        if (res.status === "ok") {
                            window.toastMessage = "Hyprland Configuration Applied!"
                            window.pendingHyprChanges = ({})
                            window.isDirty = false
                            backendGetProc.running = true
                        } else {
                            window.toastMessage = "Errors applying: " + (res.messages ? res.messages.join(", ") : "Unknown")
                        }
                        window.showSaveToast = true
                        toastTimer.restart()
                    } catch(e) {
                        console.log("[settings] Backend apply parse error:", e)
                    }
                }
            }
        }
    }

    // ── Lockscreen Config Save/Load ──────────────────────────────────────────
    Process {
        id: loadProc
        command: ["cat", window.configPath]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(text)
                        var base = window.getDefaultConfig()
                        window.mergeConfig(base, parsed)
                        window.config = base
                        if (base.modules) {
                            if (base.modules.weather_city !== undefined) window.liveWeatherCity = base.modules.weather_city
                            if (base.modules.weather_country !== undefined) window.liveWeatherCountry = base.modules.weather_country
                        }
                        window.isDirty = false
                    } catch(e) {}
                }
            }
        }
    }

    Process {
        id: saveProc
        command: [
            "python3", "-c",
            "import sys, json, os; from pathlib import Path; data = json.loads(sys.argv[1]); p = Path(sys.argv[2]); p.parent.mkdir(parents=True, exist_ok=True);\nwith open(p, 'w') as f:\n    json.dump(data, f, indent=4)",
            JSON.stringify(window.config),
            window.configPath
        ]
        onRunningChanged: {
            if (!running) {
                window.isDirty = false
                window.toastMessage = "Lockscreen Settings Saved!"
                window.showSaveToast = true
                toastTimer.restart()
            }
        }
    }

    // ── Avatar Picker Process ────────────────────────────────────────────────
    Process {
        id: pickAvatarProc
        command: ["python3", homeDir + "/.hyprconf/hypr/scripts/py/pick-avatar.py"]
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    try {
                        var res = JSON.parse(text)
                        if (res.status === "success") {
                            window.avatarTimestamp = Date.now()
                            window.toastMessage = "Avatar Updated Successfully!"
                            window.showSaveToast = true
                            toastTimer.restart()
                            window.markDirty()
                            backendGetProc.running = true
                        } else if (res.status === "reset") {
                            window.avatarTimestamp = Date.now()
                            window.toastMessage = "Avatar Restored to Default!"
                            window.showSaveToast = true
                            toastTimer.restart()
                            window.markDirty()
                            backendGetProc.running = true
                        }
                    } catch(e) {}
                }
            }
        }
    }

    Process {
        id: installSddmAvatarProc
        command: ["python3", homeDir + "/.hyprconf/hypr/scripts/py/hypr-settings-backend.py", "install-sddm-avatar"]
        onRunningChanged: {
            if (!running) {
                backendGetProc.running = true
            }
        }
    }

    Process {
        id: restoreSddmAvatarProc
        command: ["python3", homeDir + "/.hyprconf/hypr/scripts/py/hypr-settings-backend.py", "restore-sddm-avatar"]
        onRunningChanged: {
            if (!running) {
                backendGetProc.running = true
            }
        }
    }

    Process {
        id: resetAvatarProc
        command: ["python3", homeDir + "/.hyprconf/hypr/scripts/py/pick-avatar.py", "--reset"]
        onRunningChanged: {
            if (!running) {
                window.avatarTimestamp = Date.now()
                window.toastMessage = "Avatar Restored to Default!"
                window.showSaveToast = true
                toastTimer.restart()
                window.markDirty()
                backendGetProc.running = true
            }
        }
    }

    Timer {
        id: toastTimer
        interval: 3200
        onTriggered: window.showSaveToast = false
    }

    function mergeConfig(base, incoming) {
        for (var k in incoming) {
            if (incoming[k] !== null && typeof incoming[k] === "object" && !Array.isArray(incoming[k])) {
                if (!base[k]) base[k] = {}
                mergeConfig(base[k], incoming[k])
            } else {
                base[k] = incoming[k]
            }
        }
    }

    function markDirty() {
        window.isDirty = true
        var cloned = JSON.parse(JSON.stringify(window.config))
        window.config = cloned
    }

    function markHypr(key, value) {
        var p = JSON.parse(JSON.stringify(window.pendingHyprChanges))
        p[key] = value
        window.pendingHyprChanges = p
        window.isDirty = true
    }

    function discardAllChanges() {
        if (window.activeRootNav === 2 && typeof widgetsSection !== "undefined" && widgetsSection) {
            widgetsSection.reloadConfig()
            window.isDirty = false
            window.toastMessage = "Widget Changes Discarded"
            window.showSaveToast = true
            toastTimer.restart()
            return
        }

        window.pendingHyprChanges = ({})
        window.isDirty = false
        backendGetProc.running = true
        loadProc.running = true
        window.toastMessage = "Changes Discarded"
        window.showSaveToast = true
        toastTimer.restart()
    }

    function applyAllChanges() {
        if (window.activeRootNav === 2 && typeof widgetsSection !== "undefined" && widgetsSection) {
            widgetsSection.saveWidgetsConfig()
            window.isDirty = false
            return
        }

        var keys = Object.keys(window.pendingHyprChanges)
        if (keys.length > 0) {
            var jsonStr = JSON.stringify(window.pendingHyprChanges)
            backendApplyProc.command = [
                "python3",
                homeDir + "/.hyprconf/hypr/scripts/py/hypr-settings-backend.py",
                "apply",
                jsonStr
            ]
            backendApplyProc.running = true
        }

        saveProc.command = [
            "python3", "-c",
            "import sys, json, os; from pathlib import Path; data = json.loads(sys.argv[1]); p = Path(sys.argv[2]); p.parent.mkdir(parents=True, exist_ok=True);\nwith open(p, 'w') as f:\n    json.dump(data, f, indent=4)",
            JSON.stringify(window.config),
            window.configPath
        ]
        saveProc.running = true
    }

    function updateWidgetPosition(key, normX, normY, preset) {
        if (!window.config.positions) window.config.positions = {}
        if (!window.config.positions[key]) window.config.positions[key] = {}
        window.config.positions[key].x = Math.max(0.05, Math.min(0.95, normX))
        window.config.positions[key].y = Math.max(0.05, Math.min(0.95, normY))
        if (preset) {
            window.config.positions[key].preset = preset
        } else {
            window.config.positions[key].preset = "custom"
        }
        if (!window.config.layout) window.config.layout = {}
        window.config.layout.mode = "freeform"
        window.markDirty()
    }

    function updateWidgetScale(key, scale) {
        if (!window.config.positions) window.config.positions = {}
        if (!window.config.positions[key]) window.config.positions[key] = {}
        window.config.positions[key].scale = Math.max(0.5, Math.min(2.5, scale))
        window.markDirty()
    }

    function updateWidgetBackground(key, enabled) {
        if (!window.config) window.config = {}
        if (!window.config.widget_backgrounds) window.config.widget_backgrounds = {}
        window.config.widget_backgrounds[key] = enabled
        window.markDirty()
    }

    function applyPreset(key, presetName) {
        var presets = {
            "top-left": { x: 0.22, y: 0.10 },
            "top-center": { x: 0.50, y: 0.14 },
            "top-right": { x: 0.78, y: 0.10 },
            "center": { x: 0.50, y: 0.50 },
            "bottom-left": { x: 0.24, y: 0.88 },
            "bottom-center": { x: 0.50, y: 0.88 },
            "bottom-right": { x: 0.76, y: 0.88 }
        }
        if (presets[presetName]) {
            updateWidgetPosition(key, presets[presetName].x, presets[presetName].y, presetName)
        }
    }

    // Formatted System Stats string for live preview
    function getSystemStatsString() {
        var parts = []
        var s = (window.config && window.config.stats) ? window.config.stats : {}
        var unit = s.unit_format || "percent"
        var sep = s.separator || "•"
        var d = window.sysStatsData

        if (s.show_uptime !== false) {
            parts.push("Up: " + (d && d.uptime ? d.uptime : "1h 55m"))
        }
        if (s.show_cpu !== false) {
            parts.push("CPU: " + (d && d.cpu_pct !== undefined ? d.cpu_pct + "%" : "14%"))
        }
        if (s.show_ram !== false) {
            var rUsedGb = d ? (d.ram_used_bytes / (1024*1024*1024)).toFixed(1) : "3.8"
            var rTotGb = d ? (d.ram_total_bytes / (1024*1024*1024)).toFixed(1) : "16.0"
            var rPct = d ? d.ram_pct : 24
            if (unit === "gb" || unit === "bytes") parts.push("RAM: " + rUsedGb + " GB")
            else if (unit === "detailed") parts.push("RAM: " + rUsedGb + " / " + rTotGb + " GB")
            else parts.push("RAM: " + rPct + "%")
        }
        if (s.show_disk) {
            var dFreeGb = d ? Math.round(d.disk_free_bytes / (1024*1024*1024)) : 94
            var dFreePct = d ? d.disk_free_pct : 79
            if (unit === "gb" || unit === "bytes") parts.push("Disk: " + dFreeGb + " GB free")
            else parts.push("Disk: " + dFreePct + "% free")
        }
        if (s.show_battery !== false) {
            if (d && d.battery_pct >= 0) parts.push("Bat: " + d.battery_pct + "%")
            else if (!d) parts.push("Bat: 85%")
        }

        if (parts.length === 0) return "System Stats Active"
        return parts.join("  " + sep + "  ")
    }

    // Inline SVG Helpers
    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string settingsSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"></circle><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path></svg>')
    readonly property string closeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>')
    readonly property string checkSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>')
    readonly property string refreshSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21.5 2v6h-6M21.34 15.57a10 10 0 1 1-.57-8.38l5.67-5.67"/></svg>')
    readonly property string lockSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>')
    readonly property string userSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>')
    readonly property string imageSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/></svg>')
    readonly property string quoteSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 21c3 0 7-1 7-8V5c0-1.25-.756-2.017-2-2H4c-1.25 0-2 .75-2 1.972V11c0 1.25.75 2 2 2 1 0 1 0 1 1v1c0 1-1 2-2 2s-1 .008-1 1.031V20c0 1 0 1 1 1z"/><path d="M15 21c3 0 7-1 7-8V5c0-1.25-.757-2.017-2-2h-4c-1.25 0-2 .75-2 1.972V11c0 1.25.75 2 2 2 1 0 1 0 1 1v1c0 1-1 2-2 2s-1 .008-1 1.031V20c0 1 0 1 1 1z"/></svg>')
    readonly property string cloudSunSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2v2"/><path d="m4.93 4.93 1.41 1.41"/><path d="M20 12h2"/><path d="m19.07 4.93-1.41 1.41"/><path d="M15.947 12.65a4 4 0 0 0-5.925-4.128"/><path d="M13 22H7a5 5 0 1 1 4.9-6H13a3 3 0 0 1 0 6z"/></svg>')
    readonly property string moveSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="5 9 2 12 5 15"/><polyline points="9 5 12 2 15 5"/><polyline points="15 19 12 22 9 19"/><polyline points="19 9 22 12 19 15"/><line x1="2" y1="12" x2="22" y2="12"/><line x1="12" y1="2" x2="12" y2="22"/></svg>')
    readonly property string globeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>')
    readonly property string musicSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></svg>')
    readonly property string chartSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>')
    readonly property string slidersSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="4" y1="21" x2="4" y2="14"/><line x1="4" y1="10" x2="4" y2="3"/><line x1="12" y1="21" x2="12" y2="12"/><line x1="12" y1="8" x2="12" y2="3"/><line x1="20" y1="21" x2="20" y2="16"/><line x1="20" y1="12" x2="20" y2="3"/><line x1="1" y1="14" x2="7" y2="14"/><line x1="9" y1="8" x2="15" y2="8"/><line x1="17" y1="16" x2="23" y2="16"/></svg>')
    readonly property string paletteSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="13.5" cy="6.5" r=".5" fill="' + Theme.accent + '"/><circle cx="17.5" cy="10.5" r=".5" fill="' + Theme.accent + '"/><circle cx="8.5" cy="7.5" r=".5" fill="' + Theme.accent + '"/><circle cx="6.5" cy="12.5" r=".5" fill="' + Theme.accent + '"/><path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.926 0 1.648-.746 1.648-1.688 0-.437-.18-.835-.437-1.125-.29-.289-.438-.652-.438-1.125a1.64 1.64 0 0 1 1.668-1.668h1.996c3.051 0 5.555-2.503 5.555-5.554C21.965 6.012 17.461 2 12 2z"/></svg>')
    readonly property string crossSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>')
    readonly property string undoSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 7v6h6"/><path d="M21 17a9 9 0 0 0-9-9 9 9 0 0 0-6 2.3L3 13"/></svg>')
    readonly property string zapSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>')
    readonly property string restartSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21.5 2v6h-6M21.34 15.57a10 10 0 1 1-.57-8.38l5.67-5.67"/></svg>')
    readonly property string powerSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18.36 6.64a9 9 0 1 1-12.73 0"/><line x1="12" y1="2" x2="12" y2="12"/></svg>')

    property real orbitAngle: 0
    NumberAnimation on orbitAngle {
        from: 0
        to: 360
        duration: 12000
        loops: Animation.Infinite
        running: true
    }

    property real avatarScale: 1.0
    SequentialAnimation on avatarScale {
        loops: Animation.Infinite
        running: true
        NumberAnimation { from: 1.0; to: 1.03; duration: 2500; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1.03; to: 1.0; duration: 2500; easing.type: Easing.InOutSine }
    }


    function getTabSvg(tabIdx, isSelected) {
        var stroke = isSelected ? Theme.on_primary : Theme.accent
        if (tabIdx === 0) return svgUrl("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"" + stroke + "\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><rect x=\"3\" y=\"3\" width=\"18\" height=\"18\" rx=\"2\" ry=\"2\"/><line x1=\"3\" y1=\"9\" x2=\"21\" y2=\"9\"/><line x1=\"9\" y1=\"21\" x2=\"9\" y2=\"9\"/></svg>")
        if (tabIdx === 1) return svgUrl("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"" + stroke + "\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><circle cx=\"12\" cy=\"12\" r=\"10\"/><polyline points=\"12 6 12 12 16 14\"/></svg>")
        if (tabIdx === 2) return svgUrl("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"" + stroke + "\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2\"/><circle cx=\"12\" cy=\"7\" r=\"4\"/></svg>")
        if (tabIdx === 3) return svgUrl("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"" + stroke + "\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><rect x=\"3\" y=\"3\" width=\"7\" height=\"7\"/><rect x=\"14\" y=\"3\" width=\"7\" height=\"7\"/><rect x=\"14\" y=\"14\" width=\"7\" height=\"7\"/><rect x=\"3\" y=\"14\" width=\"7\" height=\"7\"/></svg>")
        return svgUrl("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"" + stroke + "\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><circle cx=\"13.5\" cy=\"6.5\" r=\".5\" fill=\"" + stroke + "\"/><circle cx=\"17.5\" cy=\"10.5\" r=\".5\" fill=\"" + stroke + "\"/><circle cx=\"8.5\" cy=\"7.5\" r=\".5\" fill=\"" + stroke + "\"/><circle cx=\"6.5\" cy=\"12.5\" r=\".5\" fill=\"" + stroke + "\"/><path d=\"M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.926 0 1.648-.746 1.648-1.688 0-.437-.18-.835-.437-1.125-.29-.289-.438-.652-.438-1.125a1.64 1.64 0 0 1 1.668-1.668h1.996c3.051 0 5.555-2.503 5.555-5.554C21.965 6.012 17.461 2 12 2z\"/></svg>")
    }

    function getNavSvg(secIdx, isSelected) {
        var s = isSelected ? Theme.on_primary : Theme.accent
        if (secIdx === 0) return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + s + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>')
        if (secIdx === 1) return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + s + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="13.5" cy="6.5" r=".5" fill="' + s + '"/><circle cx="17.5" cy="10.5" r=".5" fill="' + s + '"/><circle cx="8.5" cy="7.5" r=".5" fill="' + s + '"/><circle cx="6.5" cy="12.5" r=".5" fill="' + s + '"/><path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.926 0 1.648-.746 1.648-1.688 0-.437-.18-.835-.437-1.125-.29-.289-.438-.652-.438-1.125a1.64 1.64 0 0 1 1.668-1.668h1.996c3.051 0 5.555-2.503 5.555-5.554C21.965 6.012 17.461 2 12 2z"/></svg>')
        if (secIdx === 2) return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + s + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"></rect><line x1="8" y1="21" x2="16" y2="21"></line><line x1="12" y1="17" x2="12" y2="21"></line></svg>')
        if (secIdx === 3) return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + s + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="5 3 19 12 5 21 5 3"></polygon></svg>')
        if (secIdx === 4) return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + s + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="5" y="2" width="14" height="20" rx="7"></rect><line x1="12" y1="6" x2="12" y2="10"></line></svg>')
        if (secIdx === 5) return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + s + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="4" width="20" height="16" rx="2"></rect><line x1="6" y1="8" x2="6" y2="8"></line><line x1="10" y1="8" x2="10" y2="8"></line><line x1="14" y1="8" x2="14" y2="8"></line><line x1="18" y1="8" x2="18" y2="8"></line><line x1="6" y1="12" x2="6" y2="12"></line><line x1="10" y1="12" x2="10" y2="12"></line><line x1="14" y1="12" x2="14" y2="12"></line><line x1="18" y1="12" x2="18" y2="12"></line><line x1="7" y1="16" x2="17" y2="16"></line></svg>')
        if (secIdx === 6) return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + s + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="4 17 10 11 4 5"></polyline><line x1="12" y1="19" x2="20" y2="19"></line></svg>')
        if (secIdx === 7) return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + s + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>')
        if (secIdx === 8) return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + s + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>')
        if (secIdx === 9) return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + s + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2v2"/><path d="m4.93 4.93 1.41 1.41"/><path d="M20 12h2"/><path d="m19.07 4.93-1.41 1.41"/><path d="M15.947 12.65a4 4 0 0 0-5.925-4.128"/><path d="M13 22H7a5 5 0 1 1 4.9-6H13a3 3 0 0 1 0 6z"/></svg>')
        if (secIdx === 10) return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + s + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="6" width="16" height="6" rx="3"/><line x1="8" y1="16" x2="8" y2="18"/><line x1="12" y1="15" x2="12" y2="19"/><line x1="16" y1="16" x2="16" y2="18"/></svg>')
        if (secIdx === 11) return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + s + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg>')
        if (secIdx === 12) return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + s + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>')
        if (secIdx === 13) return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + s + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="5" width="20" height="14" rx="4"/><circle cx="7" cy="12" r="1.5" fill="' + s + '"/><circle cx="12" cy="12" r="1.5" fill="' + s + '"/><circle cx="17" cy="12" r="1.5" fill="' + s + '"/></svg>')
        return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + s + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>')
    }

    Item {
        anchors.fill: parent

        // Outer Background & Rim
        Rectangle {
            anchors.fill: parent
            color: Theme.background
            border.width: 1
            border.color: Theme.alpha(Theme.accent, 0.35)
        }

        // ── TOP HEADER BAR ───────────────────────────────────────────────────
        Item {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 64

            Rectangle {
                anchors.fill: parent
                color: Theme.alpha(Theme.surface, 0.85)
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.20)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 16

                Image {
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    source: window.settingsSvg
                    sourceSize: Qt.size(52, 52)
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 2

                    Row {
                        spacing: 8

                        Text {
                            text: "Hyprland & Quickshell Settings"
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }

                        // Unsaved Changes Pill
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            height: 20
                            width: dirtyText.implicitWidth + 14
                            radius: 10
                            color: Theme.alpha(Theme.error, 0.20)
                            border.width: 1
                            border.color: Theme.alpha(Theme.error, 0.60)
                            visible: window.isDirty

                            Text {
                                id: dirtyText
                                anchors.centerIn: parent
                                text: "• Unsaved Changes"
                                color: Theme.error
                                font.family: "Outfit"
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    Text {
                        text: {
                            if (window.activeSection === 0) return "Overview & status of Hyprland Lua configuration files"
                            if (window.activeSection === 1) return "Window layout, borders, rounding, gaps, blur, opacity, and shadows"
                            if (window.activeSection === 2) return "Monitors, resolutions, refresh rates, scaling, and positioning"
                            if (window.activeSection === 3) return "Animations toggle, bezier curve controls, and animation speeds"
                            if (window.activeSection === 4) return "Pointer sensitivity, touchpad tap to click, and natural scroll"
                            if (window.activeSection === 5) return "SDDM login screen avatar and desktop user face icons"
                            if (window.activeSection === 7) return "Real-time atmospheric conditions, generative background simulation, and solar trajectory"
                            return "Interactive drag & drop canvas and lockscreen widget placement"
                        }
                        color: Theme.alpha(Theme.foreground, 0.65)
                        font.family: "Outfit"
                        font.pixelSize: 11
                    }
                }

                // Discard Button
                Rectangle {
                    Layout.preferredWidth: 84
                    Layout.preferredHeight: 34
                    radius: 8
                    color: discardMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.50)
                    border.width: 1
                    border.color: window.isDirty ? Theme.alpha(Theme.error, 0.50) : Theme.alpha(Theme.accent, 0.15)
                    opacity: window.isDirty ? 1.0 : 0.5
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Discard"
                        color: window.isDirty ? Theme.foreground : Theme.muted
                        font.family: "Outfit"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        id: discardMouse
                        anchors.fill: parent
                        enabled: window.isDirty
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: window.discardAllChanges()
                    }
                }

                // Apply Button
                Rectangle {
                    Layout.preferredWidth: 94
                    Layout.preferredHeight: 34
                    radius: 8
                    color: window.isDirty
                        ? (applyMouse.containsMouse ? Theme.primary : Theme.accent)
                        : Theme.alpha(Theme.surface, 0.40)
                    border.width: 1
                    border.color: window.isDirty ? Theme.accent : Theme.alpha(Theme.accent, 0.15)
                    opacity: window.isDirty ? 1.0 : 0.6
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 12
                            height: 12
                            source: window.checkSvg
                            sourceSize: Qt.size(24, 24)
                            visible: window.isDirty
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Apply"
                            color: window.isDirty ? Theme.on_primary : Theme.muted
                            font.family: "Outfit"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                    }

                    MouseArea {
                        id: applyMouse
                        anchors.fill: parent
                        enabled: window.isDirty
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: window.applyAllChanges()
                    }
                }

                // Close Button
                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 16
                    color: closeMouse.containsMouse ? Theme.alpha(Theme.error, 0.35) : Theme.alpha(Theme.surface, 0.50)
                    border.width: 1
                    border.color: closeMouse.containsMouse ? Theme.alpha(Theme.error, 0.75) : Theme.alpha(Theme.accent, 0.25)

                    Image {
                        anchors.centerIn: parent
                        width: 12
                        height: 12
                        source: window.closeSvg
                        sourceSize: Qt.size(24, 24)
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.quit()
                    }
                }
            }
        }

        // ── BODY: SIDEBAR + MAIN CONTENT AREA ────────────────────────────────
        Item {
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right

            // ── LEFT NAVIGATION SIDEBAR ──────────────────────────────────────
            Rectangle {
                id: sidebar
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: 220
                color: Theme.alpha(Theme.surface, 0.60)
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.20)

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 10
                    contentWidth: availableWidth
                    clip: true

                    Column {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: "CONFIGURATION"
                            color: Theme.alpha(Theme.accent, 0.75)
                            font.family: "Outfit"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.2
                            leftPadding: 8
                            topPadding: 6
                            bottomPadding: 2
                        }

                        // 1. Parent Option: Hyprconf Settings
                        Rectangle {
                            width: parent.width
                            height: 48
                            radius: 10
                            readonly property bool isSelected: window.activeRootNav === 0

                            color: isSelected
                                ? Theme.accent
                                : (hyprconfMouse.containsMouse ? Theme.alpha(Theme.surface, 0.85) : "transparent")

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Image {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 20
                                    height: 20
                                    source: window.getNavSvg(1, parent.parent.isSelected)
                                    sourceSize: Qt.size(40, 40)
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        text: "Hyprconf Settings"
                                        color: parent.parent.parent.isSelected ? Theme.on_primary : Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 13
                                        font.weight: parent.parent.parent.isSelected ? Font.DemiBold : Font.Normal
                                    }

                                    Text {
                                        text: "System & Desktop"
                                        color: parent.parent.parent.isSelected ? Theme.alpha(Theme.on_primary, 0.80) : Theme.alpha(Theme.foreground, 0.50)
                                        font.family: "Outfit"
                                        font.pixelSize: 10
                                    }
                                }
                            }

                            MouseArea {
                                id: hyprconfMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    window.activeRootNav = 0
                                    if (window.activeSection === 9 || window.activeSection === 10 || window.activeSection === 11) window.activeSection = 0
                                }
                            }
                        }

                        // 2. Parent Option: Dynamic Island
                        Rectangle {
                            width: parent.width
                            height: 48
                            radius: 10
                            readonly property bool isSelected: window.activeRootNav === 1

                            color: isSelected
                                ? Theme.accent
                                : (islandNavMouse.containsMouse ? Theme.alpha(Theme.surface, 0.85) : "transparent")

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Image {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 20
                                    height: 20
                                    source: window.getNavSvg(10, parent.parent.isSelected)
                                    sourceSize: Qt.size(40, 40)
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        text: "Dynamic Island"
                                        color: parent.parent.parent.isSelected ? Theme.on_primary : Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 13
                                        font.weight: parent.parent.parent.isSelected ? Font.DemiBold : Font.Normal
                                    }

                                    Text {
                                        text: "Visualizer & Dynamics"
                                        color: parent.parent.parent.isSelected ? Theme.alpha(Theme.on_primary, 0.80) : Theme.alpha(Theme.foreground, 0.50)
                                        font.family: "Outfit"
                                        font.pixelSize: 10
                                    }
                                }
                            }

                            MouseArea {
                                id: islandNavMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    window.activeRootNav = 1
                                    window.activeSection = 10
                                }
                            }
                        }

                        // 3. Parent Option: Desktop Widgets
                        Rectangle {
                            width: parent.width
                            height: 48
                            radius: 10
                            readonly property bool isSelected: window.activeRootNav === 2

                            color: isSelected
                                ? Theme.accent
                                : (widgetsNavMouse.containsMouse ? Theme.alpha(Theme.surface, 0.85) : "transparent")

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Image {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 20
                                    height: 20
                                    source: window.getNavSvg(11, parent.parent.isSelected)
                                    sourceSize: Qt.size(40, 40)
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        text: "Desktop Widgets"
                                        color: parent.parent.parent.isSelected ? Theme.on_primary : Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 13
                                        font.weight: parent.parent.parent.isSelected ? Font.DemiBold : Font.Normal
                                    }

                                    Text {
                                        text: "Drag & Drop Canvas"
                                        color: parent.parent.parent.isSelected ? Theme.alpha(Theme.on_primary, 0.80) : Theme.alpha(Theme.foreground, 0.50)
                                        font.family: "Outfit"
                                        font.pixelSize: 10
                                    }
                                }
                            }

                            MouseArea {
                                id: widgetsNavMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    window.activeRootNav = 2
                                    window.activeSection = 11
                                    window.isDirty = (typeof widgetsSection !== "undefined" && widgetsSection) ? widgetsSection.isDirty : false
                                }
                            }
                        }

                        // 4. Parent Option: Weather
                        Rectangle {
                            width: parent.width
                            height: 48
                            radius: 10
                            readonly property bool isSelected: window.activeRootNav === 3

                            color: isSelected
                                ? Theme.accent
                                : (weatherNavMouse.containsMouse ? Theme.alpha(Theme.surface, 0.85) : "transparent")

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Image {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 20
                                    height: 20
                                    source: window.getNavSvg(9, parent.parent.isSelected)
                                    sourceSize: Qt.size(40, 40)
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        text: "Weather Forecast"
                                        color: parent.parent.parent.isSelected ? Theme.on_primary : Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 13
                                        font.weight: parent.parent.parent.isSelected ? Font.DemiBold : Font.Normal
                                    }

                                    Text {
                                        text: "Live Atmosphere"
                                        color: parent.parent.parent.isSelected ? Theme.alpha(Theme.on_primary, 0.80) : Theme.alpha(Theme.foreground, 0.50)
                                        font.family: "Outfit"
                                        font.pixelSize: 10
                                    }
                                }
                            }

                            MouseArea {
                                id: weatherNavMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    window.activeRootNav = 3
                                    window.activeSection = 7
                                }
                            }
                        }

                        // 5. Parent Option: Lockscreen Canvas
                        Rectangle {
                            width: parent.width
                            height: 48
                            radius: 10
                            readonly property bool isSelected: window.activeRootNav === 4

                            color: isSelected
                                ? Theme.accent
                                : (lockMouse.containsMouse ? Theme.alpha(Theme.surface, 0.85) : "transparent")

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Image {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 20
                                    height: 20
                                    source: window.getNavSvg(12, parent.parent.isSelected)
                                    sourceSize: Qt.size(40, 40)
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        text: "Lockscreen Canvas"
                                        color: parent.parent.parent.isSelected ? Theme.on_primary : Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 13
                                        font.weight: parent.parent.parent.isSelected ? Font.DemiBold : Font.Normal
                                    }

                                    Text {
                                        text: "WYSIWYG Editor"
                                        color: parent.parent.parent.isSelected ? Theme.alpha(Theme.on_primary, 0.80) : Theme.alpha(Theme.foreground, 0.50)
                                        font.family: "Outfit"
                                        font.pixelSize: 10
                                    }
                                }
                            }

                            MouseArea {
                                id: lockMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    window.activeRootNav = 4
                                    window.activeSection = 9
                                }
                            }
                        }

                        // 6. Parent Option: Application Dock
                        Rectangle {
                            width: parent.width
                            height: 48
                            radius: 10
                            readonly property bool isSelected: window.activeRootNav === 5

                            color: isSelected
                                ? Theme.accent
                                : (dockNavMouse.containsMouse ? Theme.alpha(Theme.surface, 0.85) : "transparent")

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Image {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 20
                                    height: 20
                                    source: window.getNavSvg(13, parent.parent.isSelected)
                                    sourceSize: Qt.size(40, 40)
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        text: "Application Dock"
                                        color: parent.parent.parent.isSelected ? Theme.on_primary : Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 13
                                        font.weight: parent.parent.parent.isSelected ? Font.DemiBold : Font.Normal
                                    }

                                    Text {
                                        text: "Stages, Pins & Positions"
                                        color: parent.parent.parent.isSelected ? Theme.alpha(Theme.on_primary, 0.80) : Theme.alpha(Theme.foreground, 0.50)
                                        font.family: "Outfit"
                                        font.pixelSize: 10
                                    }
                                }
                            }

                            MouseArea {
                                id: dockNavMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    window.activeRootNav = 5
                                    window.activeSection = 12
                                }
                            }
                        }
                    }
                }
            }

            // ── MAIN CONTENT CONTAINER ───────────────────────────────────────
            Item {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: sidebar.right
                anchors.right: parent.right

                // Horizontal Sub-Tab Bar for Hyprconf Settings
                Rectangle {
                    id: hyprTabBarContainer
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 52
                    color: "transparent"
                    visible: window.activeRootNav === 0

                    Flickable {
                        id: hyprTabFlickable
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        anchors.topMargin: 8
                        contentWidth: hyprTabRow.implicitWidth
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        flickableDirection: Flickable.HorizontalFlick

                        WheelHandler {
                            target: hyprTabFlickable
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: function(event) {
                                var delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x
                                hyprTabFlickable.contentX = Math.max(0, Math.min(hyprTabFlickable.contentWidth - hyprTabFlickable.width, hyprTabFlickable.contentX - delta))
                            }
                        }

                        Row {
                            id: hyprTabRow
                            spacing: 8
                            height: 36

                            Repeater {
                                model: [
                                    { name: "Overview", iconIdx: 0, secIdx: 0 },
                                    { name: "Appearance", iconIdx: 1, secIdx: 1 },
                                    { name: "Display", iconIdx: 2, secIdx: 2 },
                                    { name: "Animations", iconIdx: 3, secIdx: 3 },
                                    { name: "Input & Touchpad", iconIdx: 4, secIdx: 4 },
                                    { name: "Login Avatar", iconIdx: 7, secIdx: 5 }
                                ]

                                Rectangle {
                                    height: 36
                                    radius: 18
                                    readonly property bool isSelected: window.activeSection === modelData.secIdx
                                    implicitWidth: subTabRowContent.implicitWidth + 24
                                    color: isSelected
                                        ? Theme.accent
                                        : (subTabMouse.containsMouse ? Theme.alpha(Theme.surface, 0.85) : Theme.alpha(Theme.surface, 0.40))
                                    border.width: 1
                                    border.color: isSelected
                                        ? Theme.accent
                                        : Theme.alpha(Theme.accent, 0.22)
                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Row {
                                        id: subTabRowContent
                                        anchors.centerIn: parent
                                        spacing: 7

                                        Image {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 14
                                            height: 14
                                            source: window.getNavSvg(modelData.iconIdx, parent.parent.isSelected)
                                            sourceSize: Qt.size(28, 28)
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.name
                                            color: parent.parent.isSelected ? Theme.on_primary : Theme.foreground
                                            font.family: "Outfit"
                                            font.pixelSize: 11
                                            font.weight: parent.parent.isSelected ? Font.DemiBold : Font.Normal
                                        }
                                    }

                                    MouseArea {
                                        id: subTabMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            window.activeRootNav = 0
                                            window.activeSection = modelData.secIdx
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    id: hyprContentArea
                    anchors.top: window.activeRootNav === 0 ? hyprTabBarContainer.bottom : parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    visible: window.activeRootNav === 0

                // =============================================================
                // SECTION 0: OVERVIEW & CONFIG FILES
                // =============================================================
                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 18
                    contentWidth: availableWidth
                    clip: true
                    visible: window.activeSection === 0

                    Column {
                        width: parent.width
                        spacing: 16

                        SettingCard {
                            title: "Hyprland Configuration Files"
                            description: "Status and paths of the active Lua configuration scripts loaded by Hyprland."

                            Repeater {
                                model: window.liveFiles

                                Rectangle {
                                    width: parent.width
                                    height: 44
                                    radius: 8
                                    color: Theme.alpha(Theme.background, 0.60)
                                    border.width: 1
                                    border.color: Theme.alpha(Theme.foreground, 0.08)

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 14
                                        anchors.rightMargin: 14
                                        spacing: 12

                                        Column {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            Text {
                                                text: modelData.name
                                                color: Theme.foreground
                                                font.family: "Outfit"
                                                font.pixelSize: 13
                                                font.weight: Font.DemiBold
                                            }

                                            Text {
                                                text: modelData.path
                                                color: Theme.alpha(Theme.foreground, 0.50)
                                                font.family: "Outfit"
                                                font.pixelSize: 10
                                                elide: Text.ElideMiddle
                                            }
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: 64
                                            Layout.preferredHeight: 22
                                            radius: 11
                                            color: modelData.exists ? Theme.alpha(Theme.accent, 0.20) : Theme.alpha(Theme.error, 0.20)
                                            border.width: 1
                                            border.color: modelData.exists ? Theme.alpha(Theme.accent, 0.50) : Theme.alpha(Theme.error, 0.50)

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.exists ? "Active" : "Missing"
                                                color: modelData.exists ? Theme.accent : Theme.error
                                                font.family: "Outfit"
                                                font.pixelSize: 10
                                                font.weight: Font.DemiBold
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        SettingCard {
                            title: "System Actions"
                            description: "Quick operational commands for managing Hyprland and dotfiles."

                            Row {
                                spacing: 12

                                Rectangle {
                                    width: 160
                                    height: 38
                                    radius: 8
                                    color: Theme.alpha(Theme.accent, 0.20)
                                    border.width: 1
                                    border.color: Theme.alpha(Theme.accent, 0.50)

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 8
                                        Image {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 14; height: 14
                                            source: window.refreshSvg
                                            sourceSize: Qt.size(28, 28)
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "Reload Hyprland"
                                            color: Theme.accent
                                            font.family: "Outfit"
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            reloadProc.running = true
                                            window.toastMessage = "Hyprland Reloaded"
                                            window.showSaveToast = true
                                            toastTimer.restart()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // =============================================================
                // SECTION 1: APPEARANCE (Borders, Rounding, Gaps, Blur, Opacity)
                // =============================================================
                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 18
                    contentWidth: availableWidth
                    clip: true
                    visible: window.activeSection === 1

                    Column {
                        width: parent.width
                        spacing: 16

                        // Layout Card
                        SettingCard {
                            title: "Window Layout"
                            description: "Select active window tiling engine and column width for scrolling layout."

                            RowLayout {
                                width: parent.width
                                spacing: 16

                                Text {
                                    text: "Layout Engine"
                                    color: Theme.foreground
                                    font.family: "Outfit"
                                    font.pixelSize: 13
                                    Layout.fillWidth: true
                                }

                                ModernDropdown {
                                    model: ["scrolling", "dwindle", "master", "monocle"]
                                    currentValue: window.liveAppearance.layout || "scrolling"
                                    onSelected: function(val) {
                                        window.liveAppearance.layout = val
                                        window.markHypr("layout", val)
                                    }
                                }
                            }

                            Column {
                                width: parent.width
                                spacing: 4
                                visible: (window.liveAppearance.layout || "scrolling") === "scrolling"

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Column Width"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13; Layout.fillWidth: true }
                                    Text { text: Math.round(colWidthSlider.value * 100) + "%"; color: Theme.accent; font.family: "Outfit"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                }

                                ModernSlider {
                                    id: colWidthSlider
                                    width: parent.width
                                    from: 0.10
                                    to: 1.00
                                    stepSize: 0.05
                                    value: window.liveAppearance.column_width || 0.8
                                    onMoved: {
                                        window.liveAppearance.column_width = Number(value.toFixed(2))
                                        window.markHypr("column_width", Number(value.toFixed(2)))
                                    }
                                }
                            }
                        }

                        // Window Decoration Card
                        SettingCard {
                            title: "Window Decoration"
                            description: "Configure border thickness, corner roundness, and inner/outer workspace gaps."

                            Column {
                                width: parent.width
                                spacing: 4

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Border Thickness"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13; Layout.fillWidth: true }
                                    Text { text: Math.round(borderSlider.value) + " px"; color: Theme.accent; font.family: "Outfit"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                }

                                ModernSlider {
                                    id: borderSlider
                                    width: parent.width
                                    from: 0
                                    to: 16
                                    stepSize: 1
                                    value: window.liveAppearance.border || 2
                                    onMoved: {
                                        window.liveAppearance.border = Math.round(value)
                                        window.markHypr("border_size", Math.round(value))
                                    }
                                }
                            }

                            Column {
                                width: parent.width
                                spacing: 4

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Corner Rounding"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13; Layout.fillWidth: true }
                                    Text { text: Math.round(roundSlider.value) + " px"; color: Theme.accent; font.family: "Outfit"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                }

                                ModernSlider {
                                    id: roundSlider
                                    width: parent.width
                                    from: 0
                                    to: 32
                                    stepSize: 1
                                    value: window.liveAppearance.rounding || 16
                                    onMoved: {
                                        window.liveAppearance.rounding = Math.round(value)
                                        window.markHypr("roundness", Math.round(value))
                                    }
                                }
                            }

                            Column {
                                width: parent.width
                                spacing: 4

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Inner Window Gaps"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13; Layout.fillWidth: true }
                                    Text { text: Math.round(innerGapSlider.value) + " px"; color: Theme.accent; font.family: "Outfit"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                }

                                ModernSlider {
                                    id: innerGapSlider
                                    width: parent.width
                                    from: 0
                                    to: 30
                                    stepSize: 1
                                    value: window.liveAppearance.inner_gap || 4
                                    onMoved: {
                                        window.liveAppearance.inner_gap = Math.round(value)
                                        window.markHypr("inner_gap", Math.round(value))
                                    }
                                }
                            }

                            Column {
                                width: parent.width
                                spacing: 4

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Outer Workspace Gaps"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13; Layout.fillWidth: true }
                                    Text { text: Math.round(outerGapSlider.value) + " px"; color: Theme.accent; font.family: "Outfit"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                }

                                ModernSlider {
                                    id: outerGapSlider
                                    width: parent.width
                                    from: 0
                                    to: 40
                                    stepSize: 1
                                    value: window.liveAppearance.outer_gap || 10
                                    onMoved: {
                                        window.liveAppearance.outer_gap = Math.round(value)
                                        window.markHypr("outer_gap", Math.round(value))
                                    }
                                }
                            }
                        }

                        // Blur & Opacity Card
                        SettingCard {
                            title: "Blur & Transparency"
                            description: "Adjust hardware-accelerated dual-kawase blur and per-window opacity levels."

                            Column {
                                width: parent.width
                                spacing: 4

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Blur Size"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13; Layout.fillWidth: true }
                                    Text { text: Math.round(blurSizeSlider.value) + ""; color: Theme.accent; font.family: "Outfit"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                }

                                ModernSlider {
                                    id: blurSizeSlider
                                    width: parent.width
                                    from: 1
                                    to: 20
                                    stepSize: 1
                                    value: window.liveAppearance.blur_size || 4
                                    onMoved: {
                                        window.liveAppearance.blur_size = Math.round(value)
                                        window.markHypr("blur", [Math.round(value), Math.round(blurPassSlider.value)])
                                    }
                                }
                            }

                            Column {
                                width: parent.width
                                spacing: 4

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Blur Passes"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13; Layout.fillWidth: true }
                                    Text { text: Math.round(blurPassSlider.value) + ""; color: Theme.accent; font.family: "Outfit"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                }

                                ModernSlider {
                                    id: blurPassSlider
                                    width: parent.width
                                    from: 1
                                    to: 8
                                    stepSize: 1
                                    value: window.liveAppearance.blur_pass || 4
                                    onMoved: {
                                        window.liveAppearance.blur_pass = Math.round(value)
                                        window.markHypr("blur", [Math.round(blurSizeSlider.value), Math.round(value)])
                                    }
                                }
                            }

                            Column {
                                width: parent.width
                                spacing: 4

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Active Window Opacity"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13; Layout.fillWidth: true }
                                    Text { text: Math.round(opacityActSlider.value * 100) + "%"; color: Theme.accent; font.family: "Outfit"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                }

                                ModernSlider {
                                    id: opacityActSlider
                                    width: parent.width
                                    from: 0.10
                                    to: 1.00
                                    stepSize: 0.05
                                    value: window.liveAppearance.opacity_act || 0.95
                                    onMoved: {
                                        window.liveAppearance.opacity_act = Number(value.toFixed(2))
                                        window.markHypr("opacity", [Number(value.toFixed(2)), Number(opacityDeactSlider.value.toFixed(2))])
                                    }
                                }
                            }

                            Column {
                                width: parent.width
                                spacing: 4

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Inactive Window Opacity"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13; Layout.fillWidth: true }
                                    Text { text: Math.round(opacityDeactSlider.value * 100) + "%"; color: Theme.accent; font.family: "Outfit"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                }

                                ModernSlider {
                                    id: opacityDeactSlider
                                    width: parent.width
                                    from: 0.10
                                    to: 1.00
                                    stepSize: 0.05
                                    value: window.liveAppearance.opacity_deact || 0.90
                                    onMoved: {
                                        window.liveAppearance.opacity_deact = Number(value.toFixed(2))
                                        window.markHypr("opacity", [Number(opacityActSlider.value.toFixed(2)), Number(value.toFixed(2))])
                                    }
                                }
                            }
                        }

                        // Window Shadows Card
                        SettingCard {
                            title: "Window Shadows"
                            description: "Drop shadows cast by active and floating windows."

                            Column {
                                width: parent.width
                                spacing: 4

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Shadow Range"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13; Layout.fillWidth: true }
                                    Text { text: Math.round(shadowSlider.value) + " px"; color: Theme.accent; font.family: "Outfit"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                }

                                ModernSlider {
                                    id: shadowSlider
                                    width: parent.width
                                    from: 0
                                    to: 60
                                    stepSize: 2
                                    value: window.liveAppearance.shadow_range || 0
                                    onMoved: {
                                        window.liveAppearance.shadow_range = Math.round(value)
                                        window.markHypr("shadow", Math.round(value))
                                    }
                                }
                            }
                        }
                    }
                }

                // =============================================================
                // SECTION 2: DISPLAY / MONITORS
                // =============================================================
                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 18
                    contentWidth: availableWidth
                    clip: true
                    visible: window.activeSection === 2

                    Column {
                        width: parent.width
                        spacing: 16

                        Repeater {
                            model: window.liveMonitors

                            SettingCard {
                                readonly property var monItem: modelData
                                title: "Monitor: " + (monItem.output ? monItem.output : "Primary Display (Default)")
                                description: "Resolution, refresh rate, and scaling configuration for this display."

                                RowLayout {
                                    width: parent.width
                                    spacing: 16

                                    Text { text: "Mode / Resolution"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13; Layout.fillWidth: true }

                                    ModernDropdown {
                                        model: monItem.available_resolutions || ["1920x1080", "1680x1050", "1280x720"]
                                        currentValue: {
                                            var m = String(monItem.mode || "")
                                            return m.indexOf("@") !== -1 ? m.split("@")[0] : m
                                        }
                                        onSelected: function(val) {
                                            var curHz = "60.0"
                                            if (monItem.available_refresh && monItem.available_refresh[val] && monItem.available_refresh[val].length > 0) {
                                                curHz = monItem.available_refresh[val][0]
                                            }
                                            var newMode = val + "@" + curHz
                                            monItem.mode = newMode
                                            window.updateMonitorPending(monItem.output, newMode, monItem.scale, monItem.position)
                                        }
                                    }
                                }

                                RowLayout {
                                    width: parent.width
                                    spacing: 16

                                    Text { text: "Refresh Rate"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13; Layout.fillWidth: true }

                                    ModernDropdown {
                                        model: {
                                            var curRes = String(monItem.mode || "").split("@")[0]
                                            if (monItem.available_refresh && monItem.available_refresh[curRes]) {
                                                return monItem.available_refresh[curRes]
                                            }
                                            return ["60.0", "75.0", "120.0", "144.0"]
                                        }
                                        currentValue: {
                                            var parts = String(monItem.mode || "").split("@")
                                            return parts.length > 1 ? parts[1] : "60.0"
                                        }
                                        onSelected: function(val) {
                                            var curRes = String(monItem.mode || "").split("@")[0]
                                            var newMode = curRes + "@" + val
                                            monItem.mode = newMode
                                            window.updateMonitorPending(monItem.output, newMode, monItem.scale, monItem.position)
                                        }
                                    }
                                }

                                Column {
                                    width: parent.width
                                    spacing: 4

                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Display Scaling"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13; Layout.fillWidth: true }
                                        Text {
                                            text: scaleSlider.value.toFixed(2) + "x"
                                            color: Theme.accent
                                            font.family: "Outfit"
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                        }
                                    }

                                    ModernSlider {
                                        id: scaleSlider
                                        width: parent.width
                                        from: 0.50
                                        to: 2.50
                                        stepSize: 0.05
                                        value: (typeof monItem.scale === "number") ? monItem.scale : 1.0
                                        onMoved: {
                                            var s = Number(value.toFixed(2))
                                            monItem.scale = s
                                            window.updateMonitorPending(monItem.output, monItem.mode, s, monItem.position)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // =============================================================
                // SECTION 3: ANIMATIONS
                // =============================================================
                ScrollView {
                    id: animScrollView
                    anchors.fill: parent
                    anchors.margins: 18
                    contentWidth: availableWidth
                    clip: true
                    visible: window.activeSection === 3

                    Column {
                        width: parent.width
                        spacing: 16

                        // ── 1. Global Animations Master Switch ─────────────────
                        SettingCard {
                            title: "Master Animation Toggle"
                            description: "Globally enable or disable all window, workspace, and layer animations in Hyprland."

                            RowLayout {
                                width: parent.width

                                Text {
                                    text: "Enable Hyprland Animations"
                                    color: Theme.foreground
                                    font.family: "Outfit"
                                    font.pixelSize: 13
                                    Layout.fillWidth: true
                                }

                                CapsuleSwitch {
                                    checked: window.liveAnimGlobal
                                    onToggled: function(c) {
                                        window.liveAnimGlobal = c
                                        window.markHypr("anim_global", c)
                                    }
                                }
                            }
                        }

                        // ── 2. Interactive Cubic Bezier Graph & Live Runner ─────
                        SettingCard {
                            title: "Cubic Bezier Velocity Curve & Easing Simulator"
                            description: "Interactive visual cubic bezier curve editor with active control points (P₀, P₁, P₂, P₃) and real-time physical easing runner."

                            RowLayout {
                                width: parent.width
                                spacing: 20

                                // Left: Bezier Curve Graph (Wide domain with bounce & recoil support)
                                BezierGraph {
                                    id: bezierVisualizer
                                    Layout.preferredWidth: 340
                                    Layout.preferredHeight: 340
                                    p1x: window.animInspectorP1x
                                    p1y: window.animInspectorP1y
                                    p2x: window.animInspectorP2x
                                    p2y: window.animInspectorP2y
                                    curveName: window.animInspectorCurve

                                    onP1xChanged: window.animInspectorP1x = p1x
                                    onP1yChanged: window.animInspectorP1y = p1y
                                    onP2xChanged: window.animInspectorP2x = p2x
                                    onP2yChanged: window.animInspectorP2y = p2y
                                }

                                // Right: Curve Presets, Coordinates, and Live Motion Runner
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 14

                                    // Presets Title, + New Curve Action & Badges
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        RowLayout {
                                            width: parent.width

                                            Text {
                                                text: "CURVE PRESETS & CUSTOM BEZIERS"
                                                color: Theme.alpha(Theme.accent, 0.85)
                                                font.family: "Outfit"
                                                font.pixelSize: 10
                                                font.weight: Font.DemiBold
                                                font.letterSpacing: 1.0
                                                Layout.fillWidth: true
                                            }

                                            // + New Custom Curve Button
                                            Rectangle {
                                                height: 24
                                                radius: 12
                                                implicitWidth: newCurveBtnRow.implicitWidth + 16
                                                color: newCurveMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.accent, 0.15)
                                                border.width: 1
                                                border.color: Theme.accent
                                                Behavior on color { ColorAnimation { duration: 120 } }

                                                RowLayout {
                                                    id: newCurveBtnRow
                                                    anchors.centerIn: parent
                                                    spacing: 4

                                                    Text {
                                                        text: window.showNewCurveCreator ? "✕" : "+"
                                                        color: newCurveMouse.containsMouse ? Theme.on_primary : Theme.accent
                                                        font.family: "Outfit"
                                                        font.pixelSize: 11
                                                        font.weight: Font.Bold
                                                    }

                                                    Text {
                                                        text: window.showNewCurveCreator ? "Cancel" : "New Curve"
                                                        color: newCurveMouse.containsMouse ? Theme.on_primary : Theme.accent
                                                        font.family: "Outfit"
                                                        font.pixelSize: 10
                                                        font.weight: Font.DemiBold
                                                    }
                                                }

                                                MouseArea {
                                                    id: newCurveMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        window.showNewCurveCreator = !window.showNewCurveCreator
                                                        if (window.showNewCurveCreator) {
                                                            newCurveField.text = ""
                                                            newCurveField.forceActiveFocus()
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        // Inline Custom Curve Creator Box
                                        Rectangle {
                                            visible: window.showNewCurveCreator
                                            width: parent.width
                                            height: 42
                                            radius: 10
                                            color: Theme.alpha(Theme.surface, 0.70)
                                            border.width: 1
                                            border.color: Theme.accent

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 6
                                                spacing: 8

                                                Text {
                                                    text: "Name:"
                                                    color: Theme.alpha(Theme.foreground, 0.70)
                                                    font.family: "Outfit"
                                                    font.pixelSize: 11
                                                    font.weight: Font.Medium
                                                }

                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    height: 30
                                                    radius: 6
                                                    color: Theme.alpha(Theme.background, 0.75)
                                                    border.width: 1
                                                    border.color: newCurveField.activeFocus ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)

                                                    TextInput {
                                                        id: newCurveField
                                                        anchors.fill: parent
                                                        anchors.leftMargin: 8
                                                        anchors.rightMargin: 8
                                                        verticalAlignment: TextInput.AlignVCenter
                                                        font.family: "Outfit"
                                                        font.pixelSize: 11
                                                        color: Theme.foreground
                                                        clip: true

                                                        Text {
                                                            anchors.fill: parent
                                                            anchors.leftMargin: 8
                                                            verticalAlignment: Text.AlignVCenter
                                                            text: "e.g. snappy_bounce, extra_recoil"
                                                            color: Theme.alpha(Theme.foreground, 0.35)
                                                            font.family: "Outfit"
                                                            font.pixelSize: 11
                                                            visible: !newCurveField.text && !newCurveField.activeFocus
                                                        }

                                                        Keys.onReturnPressed: createBtnMouse.clicked(null)
                                                    }
                                                }

                                                Rectangle {
                                                    width: 72
                                                    height: 30
                                                    radius: 6
                                                    color: createBtnMouse.containsMouse ? Theme.primary : Theme.accent
                                                    Behavior on color { ColorAnimation { duration: 120 } }

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "Create"
                                                        color: Theme.on_primary
                                                        font.family: "Outfit"
                                                        font.pixelSize: 11
                                                        font.weight: Font.DemiBold
                                                    }

                                                    MouseArea {
                                                        id: createBtnMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            if (newCurveField.text.trim().length > 0) {
                                                                var success = window.createCustomCurve(newCurveField.text.trim())
                                                                if (success) {
                                                                    window.showNewCurveCreator = false
                                                                    newCurveField.text = ""
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Flow {
                                            width: parent.width
                                            spacing: 8

                                            Repeater {
                                                model: Object.keys(window.liveCurves).length > 0 ? Object.keys(window.liveCurves) : ["elegant_bounce", "fluent_decel", "md3_decel", "md3_accel", "backward", "linear"]

                                                Rectangle {
                                                    height: 28
                                                    radius: 14
                                                    readonly property bool isSelected: window.animInspectorCurve === modelData
                                                    readonly property bool isDefault: ["elegant_bounce", "fluent_decel", "md3_decel", "md3_accel", "backward", "linear"].indexOf(modelData) !== -1
                                                    implicitWidth: presetPillRow.implicitWidth + 22
                                                    color: isSelected
                                                        ? Theme.accent
                                                        : (presetMouse.containsMouse ? Theme.alpha(Theme.surface, 0.85) : Theme.alpha(Theme.surface, 0.45))
                                                    border.width: 1
                                                    border.color: isSelected ? Theme.accent : Theme.alpha(Theme.accent, 0.20)
                                                    Behavior on color { ColorAnimation { duration: 120 } }

                                                    RowLayout {
                                                        id: presetPillRow
                                                        anchors.centerIn: parent
                                                        spacing: 6

                                                        Text {
                                                            text: modelData
                                                            color: parent.parent.isSelected ? Theme.on_primary : Theme.foreground
                                                            font.family: "Outfit"
                                                            font.pixelSize: 11
                                                            font.weight: parent.parent.isSelected ? Font.DemiBold : Font.Normal
                                                        }

                                                        // Quick delete badge for custom user curves
                                                        Text {
                                                            visible: !parent.parent.isDefault
                                                            text: "✕"
                                                            color: parent.parent.isSelected ? Theme.alpha(Theme.on_primary, 0.70) : Theme.alpha(Theme.foreground, 0.50)
                                                            font.family: "Outfit"
                                                            font.pixelSize: 10
                                                            font.weight: Font.Bold

                                                            MouseArea {
                                                                anchors.fill: parent
                                                                anchors.margins: -4
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: window.deleteCustomCurve(modelData)
                                                            }
                                                        }
                                                    }

                                                    MouseArea {
                                                        id: presetMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            window.selectBezierPreset(modelData)
                                                            bezierVisualizer.p1x = window.animInspectorP1x
                                                            bezierVisualizer.p1y = window.animInspectorP1y
                                                            bezierVisualizer.p2x = window.animInspectorP2x
                                                            bezierVisualizer.p2y = window.animInspectorP2y
                                                            runnerAnimation.restart()
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Coordinates Display & Save Button
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 56
                                        radius: 10
                                        color: Theme.alpha(Theme.surface, 0.50)
                                        border.width: 1
                                        border.color: Theme.alpha(Theme.foreground, 0.10)

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12
                                            spacing: 12

                                            Column {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Text {
                                                    text: "Active Bezier Curve: " + window.animInspectorCurve
                                                    color: Theme.foreground
                                                    font.family: "Outfit"
                                                    font.pixelSize: 12
                                                    font.weight: Font.DemiBold
                                                }
                                                Text {
                                                    text: "P₁(" + window.animInspectorP1x.toFixed(2) + ", " + window.animInspectorP1y.toFixed(2) + ")  •  P₂(" + window.animInspectorP2x.toFixed(2) + ", " + window.animInspectorP2y.toFixed(2) + ")"
                                                    color: Theme.alpha(Theme.foreground, 0.65)
                                                    font.family: "Outfit"
                                                    font.pixelSize: 11
                                                }
                                            }

                                            // Save Curve Button
                                            Rectangle {
                                                width: 106
                                                height: 32
                                                radius: 8
                                                color: saveCurveMouse.containsMouse ? Theme.primary : Theme.accent
                                                Behavior on color { ColorAnimation { duration: 120 } }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "Apply Curve"
                                                    color: Theme.on_primary
                                                    font.family: "Outfit"
                                                    font.pixelSize: 11
                                                    font.weight: Font.DemiBold
                                                }

                                                MouseArea {
                                                    id: saveCurveMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        window.saveCurrentCurve()
                                                        window.toastMessage = "Curve '" + window.animInspectorCurve + "' queued"
                                                        window.showSaveToast = true
                                                        toastTimer.restart()
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Real-Time Motion Runner
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        RowLayout {
                                            width: parent.width

                                            Text {
                                                text: "LIVE MOTION PROGRESSION (EASING RUNNER)"
                                                color: Theme.alpha(Theme.accent, 0.85)
                                                font.family: "Outfit"
                                                font.pixelSize: 10
                                                font.weight: Font.DemiBold
                                                font.letterSpacing: 1.0
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                readonly property real ey: window.evalBezier(window.runnerTime, window.animInspectorP1x, window.animInspectorP1y, window.animInspectorP2x, window.animInspectorP2y)
                                                text: "Window Position: " + Math.round(ey * 100) + "%" + (ey > 1.0 ? " (Overshoot)" : (ey < 0.0 ? " (Recoil)" : ""))
                                                color: ey > 1.0 ? "#f59e0b" : (ey < 0.0 ? "#3b82f6" : Theme.accent)
                                                font.family: "Outfit"
                                                font.pixelSize: 10
                                                font.weight: Font.Medium
                                            }
                                        }

                                        // Runner Track
                                        Rectangle {
                                            id: runnerTrackBox
                                            width: parent.width
                                            height: 48
                                            radius: 10
                                            color: Theme.alpha(Theme.background, 0.80)
                                            border.width: 1
                                            border.color: Theme.alpha(Theme.accent, 0.25)
                                            clip: true

                                            readonly property real startX: 28
                                            readonly property real pillW: 44
                                            readonly property real maxTravel: width - pillW - 36
                                            readonly property real targetSpan: maxTravel * 0.72

                                            // Start line (0%)
                                            Rectangle {
                                                x: runnerTrackBox.startX
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 2
                                                height: 24
                                                radius: 1
                                                color: Theme.alpha(Theme.foreground, 0.25)
                                            }

                                            // Shaded Overshoot & Bounce Zone (Past 100%)
                                            Rectangle {
                                                x: runnerTrackBox.startX + runnerTrackBox.targetSpan + runnerPill.width
                                                y: 2
                                                width: parent.width - x - 2
                                                height: parent.height - 4
                                                radius: 8
                                                color: Theme.alpha("#f59e0b", 0.10)
                                                border.width: 1
                                                border.color: Theme.alpha("#f59e0b", 0.25)

                                                Text {
                                                    anchors.right: parent.right
                                                    anchors.rightMargin: 8
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: "OVERSHOOT ZONE"
                                                    color: Theme.alpha("#f59e0b", 0.65)
                                                    font.family: "Outfit"
                                                    font.pixelSize: 8
                                                    font.weight: Font.Bold
                                                    font.letterSpacing: 0.8
                                                }
                                            }

                                            // 100% Target Finish Line (Resting Position)
                                            Rectangle {
                                                id: targetLine
                                                x: runnerTrackBox.startX + runnerTrackBox.targetSpan + runnerPill.width
                                                y: 4
                                                width: 2
                                                height: parent.height - 8
                                                radius: 1
                                                color: Theme.accent
                                            }

                                            Text {
                                                anchors.right: targetLine.left
                                                anchors.rightMargin: 6
                                                anchors.top: parent.top
                                                anchors.topMargin: 4
                                                text: "100% TARGET"
                                                color: Theme.alpha(Theme.accent, 0.90)
                                                font.family: "Outfit"
                                                font.pixelSize: 8
                                                font.weight: Font.Bold
                                                font.letterSpacing: 0.8
                                            }

                                            // The gliding window pill
                                            Rectangle {
                                                id: runnerPill
                                                readonly property real currentProg: window.evalBezier(window.runnerTime, window.animInspectorP1x, window.animInspectorP1y, window.animInspectorP2x, window.animInspectorP2y)

                                                x: Math.max(4, Math.min(runnerTrackBox.width - width - 6, runnerTrackBox.startX + runnerTrackBox.targetSpan * currentProg))
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: runnerTrackBox.pillW
                                                height: 30
                                                radius: 7
                                                color: currentProg > 1.0 ? "#f59e0b" : Theme.accent
                                                border.width: 1.5
                                                border.color: Theme.on_primary

                                                Behavior on color { ColorAnimation { duration: 100 } }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "Win"
                                                    color: Theme.on_primary
                                                    font.family: "Outfit"
                                                    font.pixelSize: 11
                                                    font.weight: Font.Bold
                                                }
                                            }
                                        }

                                        // Runner Controls Row
                                        RowLayout {
                                            width: parent.width
                                            spacing: 10

                                            // Replay Button
                                            Rectangle {
                                                width: 76
                                                height: 28
                                                radius: 6
                                                color: replayMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.50)
                                                border.width: 1
                                                border.color: Theme.alpha(Theme.accent, 0.30)

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "▶ Replay"
                                                    color: Theme.foreground
                                                    font.family: "Outfit"
                                                    font.pixelSize: 11
                                                }

                                                MouseArea {
                                                    id: replayMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: runnerAnimation.restart()
                                                }
                                            }

                                            // Loop Toggle
                                            Row {
                                                spacing: 6
                                                CapsuleSwitch {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    checked: window.runnerLoop
                                                    onToggled: function(c) {
                                                        window.runnerLoop = c
                                                        if (!c) {
                                                            runnerAnimation.stop()
                                                            window.runnerTime = 1.0
                                                        } else {
                                                            runnerAnimation.restart()
                                                        }
                                                    }
                                                }
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: "Loop Motion"
                                                    color: Theme.alpha(Theme.foreground, 0.70)
                                                    font.family: "Outfit"
                                                    font.pixelSize: 11
                                                }
                                            }

                                            Item { Layout.fillWidth: true }

                                            // Duration Pills
                                            Text {
                                                text: "Duration:"
                                                color: Theme.alpha(Theme.foreground, 0.60)
                                                font.family: "Outfit"
                                                font.pixelSize: 10
                                            }

                                            Repeater {
                                                model: [
                                                    { label: "1.0s", ms: 1000 },
                                                    { label: "1.6s", ms: 1600 },
                                                    { label: "2.5s", ms: 2500 }
                                                ]

                                                Rectangle {
                                                    height: 24
                                                    radius: 12
                                                    implicitWidth: durText.implicitWidth + 14
                                                    readonly property bool isCur: window.runnerDurationMs === modelData.ms
                                                    color: isCur ? Theme.accent : Theme.alpha(Theme.surface, 0.50)
                                                    border.width: 1
                                                    border.color: isCur ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)

                                                    Text {
                                                        id: durText
                                                        anchors.centerIn: parent
                                                        text: modelData.label
                                                        color: parent.isCur ? Theme.on_primary : Theme.foreground
                                                        font.family: "Outfit"
                                                        font.pixelSize: 10
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            window.runnerDurationMs = modelData.ms
                                                            runnerAnimation.restart()
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ── 3. Animation Elements Grid (2 Columns) ─────────────
                        SettingCard {
                            title: "Animation Directives & Styles (Grid Layout)"
                            description: "Configure duration, cubic bezier curve, and visual transition style for each Hyprland window, workspace, and layer element."

                            Grid {
                                columns: 2
                                spacing: 14
                                width: parent.width

                                Repeater {
                                    model: window.liveAnimations

                                    Rectangle {
                                        width: (parent.width - 14) / 2
                                        height: 184
                                        radius: 12
                                        color: Theme.alpha(Theme.surface, 0.50)
                                        border.width: 1
                                        border.color: Theme.alpha(Theme.accent, 0.20)

                                        Column {
                                            anchors.fill: parent
                                            anchors.margins: 14
                                            spacing: 8

                                            // Row 1: Leaf Badge, Name, and Toggle Switch
                                            RowLayout {
                                                width: parent.width

                                                Rectangle {
                                                    height: 22
                                                    width: badgeText.implicitWidth + 12
                                                    radius: 11
                                                    color: Theme.alpha(Theme.accent, 0.18)
                                                    border.width: 1
                                                    border.color: Theme.alpha(Theme.accent, 0.40)

                                                    Text {
                                                        id: badgeText
                                                        anchors.centerIn: parent
                                                        text: window.getLeafMeta(modelData.leaf).badge
                                                        color: Theme.accent
                                                        font.family: "Outfit"
                                                        font.pixelSize: 10
                                                        font.weight: Font.DemiBold
                                                    }
                                                }

                                                Text {
                                                    text: modelData.leaf
                                                    color: Theme.foreground
                                                    font.family: "Outfit"
                                                    font.pixelSize: 13
                                                    font.weight: Font.DemiBold
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideRight
                                                }

                                                CapsuleSwitch {
                                                    checked: (modelData.enabled !== undefined) ? modelData.enabled : true
                                                    onToggled: function(c) {
                                                        modelData.enabled = c
                                                        window.updateAnimLeafPending(modelData.leaf, modelData.speed, modelData.bezier, modelData.style, c)
                                                    }
                                                }
                                            }

                                            // Row 2: Speed / Duration Slider
                                            RowLayout {
                                                width: parent.width
                                                Text {
                                                    text: "Speed: " + Number(speedSlider.value).toFixed(1) + " s"
                                                    color: Theme.accent
                                                    font.family: "Outfit"
                                                    font.pixelSize: 11
                                                    font.weight: Font.Medium
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            ModernSlider {
                                                id: speedSlider
                                                width: parent.width
                                                from: 0.5
                                                to: 15.0
                                                stepSize: 0.5
                                                value: modelData.speed || 5.0
                                                onMoved: {
                                                    modelData.speed = Number(value.toFixed(1))
                                                    window.updateAnimLeafPending(modelData.leaf, modelData.speed, modelData.bezier, modelData.style, modelData.enabled)
                                                }
                                            }

                                            // Row 3: Bezier Curve & Style Dropdowns
                                            RowLayout {
                                                width: parent.width
                                                spacing: 10

                                                Column {
                                                    Layout.fillWidth: true
                                                    spacing: 3
                                                    Text {
                                                        text: "Bezier Curve"
                                                        color: Theme.alpha(Theme.foreground, 0.60)
                                                        font.family: "Outfit"
                                                        font.pixelSize: 10
                                                    }
                                                    ModernDropdown {
                                                        width: parent.width
                                                        model: Object.keys(window.liveCurves).length > 0 ? Object.keys(window.liveCurves) : ["elegant_bounce", "fluent_decel", "md3_decel", "md3_accel", "backward", "linear"]
                                                        currentValue: modelData.bezier || "fluent_decel"
                                                        onSelected: function(val) {
                                                            modelData.bezier = val
                                                            window.updateAnimLeafPending(modelData.leaf, modelData.speed, val, modelData.style, modelData.enabled)
                                                        }
                                                    }
                                                }

                                                Column {
                                                    Layout.fillWidth: true
                                                    spacing: 3
                                                    Text {
                                                        text: "Animation Style"
                                                        color: Theme.alpha(Theme.foreground, 0.60)
                                                        font.family: "Outfit"
                                                        font.pixelSize: 10
                                                    }
                                                    ModernDropdown {
                                                        width: parent.width
                                                        model: window.getStyleOptionsForLeaf(modelData.leaf)
                                                        currentValue: modelData.style || (modelData.leaf === "borderangle" ? "loop" : (modelData.leaf.indexOf("workspace") >= 0 ? "slidevert" : "slide"))
                                                        onSelected: function(val) {
                                                            modelData.style = val
                                                            window.updateAnimLeafPending(modelData.leaf, modelData.speed, modelData.bezier, val, modelData.enabled)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // =============================================================
                // SECTION 4: INPUT & TOUCHPAD
                // =============================================================
                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 18
                    contentWidth: availableWidth
                    clip: true
                    visible: window.activeSection === 4

                    Column {
                        width: parent.width
                        spacing: 16

                        SettingCard {
                            title: "Pointer & Sensitivity"
                            description: "Mouse and touchpad acceleration curve offset (-1.0 to 1.0)."

                            Column {
                                width: parent.width
                                spacing: 4

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Pointer Sensitivity"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13; Layout.fillWidth: true }
                                    Text { text: sensSlider.value.toFixed(2); color: Theme.accent; font.family: "Outfit"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                }

                                ModernSlider {
                                    id: sensSlider
                                    width: parent.width
                                    from: -1.0
                                    to: 1.0
                                    stepSize: 0.05
                                    value: window.liveInput.sensitivity || 0.0
                                    onMoved: {
                                        window.liveInput.sensitivity = Number(value.toFixed(2))
                                        window.markHypr("input_sensitivity", Number(value.toFixed(2)))
                                    }
                                }
                            }
                        }

                        SettingCard {
                            title: "Touchpad & Keyboard Options"
                            description: "Toggle natural scrolling, tap-to-click, and typing palm rejection."

                            RowLayout {
                                width: parent.width
                                Text { text: "Natural Scrolling (Inverted)"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13; Layout.fillWidth: true }
                                CapsuleSwitch {
                                    checked: window.liveInput.natural_scroll
                                    onToggled: function(c) { window.updateInputBoolPending("natural_scroll", c) }
                                }
                            }

                            RowLayout {
                                width: parent.width
                                Text { text: "Tap to Click"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13; Layout.fillWidth: true }
                                CapsuleSwitch {
                                    checked: window.liveInput.tap_to_click
                                    onToggled: function(c) { window.updateInputBoolPending("tap_to_click", c) }
                                }
                            }

                            RowLayout {
                                width: parent.width
                                Text { text: "Disable Touchpad While Typing"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13; Layout.fillWidth: true }
                                CapsuleSwitch {
                                    checked: window.liveInput.disable_while_typing
                                    onToggled: function(c) { window.updateInputBoolPending("disable_while_typing", c) }
                                }
                            }

                            RowLayout {
                                width: parent.width
                                Text { text: "Left-Handed Mode (Swap Buttons)"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13; Layout.fillWidth: true }
                                CapsuleSwitch {
                                    checked: window.liveInput.left_handed
                                    onToggled: function(c) { window.updateInputBoolPending("left_handed", c) }
                                }
                            }

                            RowLayout {
                                width: parent.width
                                Text { text: "Numlock Enabled by Default"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13; Layout.fillWidth: true }
                                CapsuleSwitch {
                                    checked: window.liveInput.numlock_by_default
                                    onToggled: function(c) { window.updateInputBoolPending("numlock_by_default", c) }
                                }
                            }
                        }
                    }
                }

                // =============================================================
                // =============================================================
                // SECTION 5: LOGIN & DESKTOP AVATAR
                // =============================================================
                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 18
                    contentWidth: availableWidth
                    clip: true
                    visible: window.activeSection === 5

                    Column {
                        width: parent.width
                        spacing: 16

                        // SDDM Theme Compatibility & Switcher Banner
                        SettingCard {
                            title: "SDDM Display Manager Theme"
                            description: "SDDM login screen user avatar icons require the SilentSDDM theme."

                            Rectangle {
                                width: parent.width
                                height: sddmAlertCol.implicitHeight + 24
                                radius: 10
                                color: window.liveSddm.is_silent_sddm ? Theme.alpha(Theme.accent, 0.12) : Theme.alpha(Theme.error, 0.12)
                                border.width: 1
                                border.color: window.liveSddm.is_silent_sddm ? Theme.alpha(Theme.accent, 0.40) : Theme.alpha(Theme.error, 0.40)

                                Column {
                                    id: sddmAlertCol
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 10

                                    RowLayout {
                                        width: parent.width
                                        spacing: 8
                                        Text {
                                            text: window.liveSddm.is_silent_sddm ? "✓" : "⚠️"
                                            color: window.liveSddm.is_silent_sddm ? Theme.accent : Theme.error
                                            font.pixelSize: 14
                                        }
                                        Text {
                                            text: window.liveSddm.is_silent_sddm
                                                ? "SilentSDDM is active as the default SDDM theme."
                                                : "SilentSDDM is not active. Current SDDM theme: " + (window.liveSddm.current_theme || "default")
                                            color: Theme.foreground
                                            font.family: "Outfit"
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                            Layout.fillWidth: true
                                        }
                                    }

                                    Text {
                                        width: parent.width
                                        wrapMode: Text.WordWrap
                                        text: window.liveSddm.is_silent_sddm
                                            ? "Your display manager will display your configured login avatar seamlessly."
                                            : (window.liveSddm.silent_sddm_available
                                                ? "SilentSDDM is available on your system (/usr/share/sddm/themes/SilentSDDM). You can set it as your active theme below to unlock login avatar installation."
                                                : "SilentSDDM theme is not installed in /usr/share/sddm/themes/.")
                                        color: Theme.alpha(Theme.foreground, 0.75)
                                        font.family: "Outfit"
                                        font.pixelSize: 11
                                    }

                                    RowLayout {
                                        width: parent.width
                                        spacing: 10
                                        visible: !window.liveSddm.is_silent_sddm && window.liveSddm.silent_sddm_available

                                        Rectangle {
                                            width: 230
                                            height: 32
                                            radius: 6
                                            color: setSddmThemeMouse.containsMouse ? Theme.primary : Theme.accent

                                            Text {
                                                anchors.centerIn: parent
                                                text: "🔒 Set SilentSDDM as Active Theme"
                                                color: Theme.on_primary
                                                font.family: "Outfit"
                                                font.pixelSize: 11
                                                font.weight: Font.DemiBold
                                            }

                                            MouseArea {
                                                id: setSddmThemeMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    setSddmThemeProc.running = true
                                                    window.toastMessage = "Terminal launched to set SDDM theme"
                                                    window.showSaveToast = true
                                                    toastTimer.restart()
                                                }
                                            }
                                        }

                                        Text {
                                            text: "(Requires administrator/sudo privileges — will prompt in terminal)"
                                            color: Theme.alpha(Theme.foreground, 0.50)
                                            font.family: "Outfit"
                                            font.pixelSize: 10
                                        }
                                    }
                                }
                            }
                        }


                        SettingCard {
                            title: "User Profile & Avatars"
                            description: "Configure profile image used for the SDDM Login Screen and Desktop Lockscreen."

                            RowLayout {
                                width: parent.width
                                spacing: 20

                                // Avatar Preview Image
                                Rectangle {
                                    Layout.preferredWidth: 100
                                    Layout.preferredHeight: 100
                                    radius: 50
                                    color: Theme.alpha(Theme.surface, 0.8)
                                    border.width: 2
                                    border.color: Theme.accent

                                    Item {
                                        id: avatarCircleMask
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        visible: false
                                        layer.enabled: true
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: width / 2
                                            color: "black"
                                        }
                                    }

                                    Image {
                                        id: sec7AvatarImg
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        source: window.avatarPath
                                        sourceSize: Qt.size(256, 256)
                                        fillMode: Image.PreserveAspectCrop
                                        smooth: true
                                        visible: false
                                    }

                                    MultiEffect {
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        source: sec7AvatarImg
                                        maskEnabled: true
                                        maskSource: avatarCircleMask
                                    }
                                }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        text: (window.liveAvatar.username ? window.liveAvatar.username : "User")
                                        color: Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 18
                                        font.weight: Font.Bold
                                    }

                                    Text {
                                        text: "Lockscreen Avatar: " + (window.liveAvatar.local_face_exists ? "Installed" : "Default") + "\nSDDM Login Avatar: " + (window.liveAvatar.sddm_face_exists ? "Installed" : "Default")
                                        color: Theme.alpha(Theme.foreground, 0.65)
                                        font.family: "Outfit"
                                        font.pixelSize: 12
                                    }

                                    Flow {
                                        width: parent.width
                                        spacing: 10

                                        Rectangle {
                                            width: 135
                                            height: 34
                                            radius: 8
                                            color: Theme.alpha(Theme.accent, 0.25)
                                            border.width: 1
                                            border.color: Theme.accent

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Choose Image..."
                                                color: Theme.accent
                                                font.family: "Outfit"
                                                font.pixelSize: 12
                                                font.weight: Font.DemiBold
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: pickAvatarProc.running = true
                                            }
                                        }

                                        Rectangle {
                                            width: 155
                                            height: 34
                                            radius: 8
                                            opacity: window.liveSddm.is_silent_sddm ? 1.0 : 0.40
                                            enabled: window.liveSddm.is_silent_sddm
                                            color: Theme.alpha(Theme.surface, 0.8)
                                            border.width: 1
                                            border.color: Theme.alpha(Theme.accent, 0.5)

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Set as SDDM Avatar"
                                                color: Theme.foreground
                                                font.family: "Outfit"
                                                font.pixelSize: 12
                                                font.weight: Font.DemiBold
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: window.liveSddm.is_silent_sddm
                                                cursorShape: window.liveSddm.is_silent_sddm ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                                                onClicked: {
                                                    if (!window.liveSddm.is_silent_sddm) {
                                                        window.toastMessage = "SilentSDDM must be active to set SDDM avatar"
                                                        window.showSaveToast = true
                                                        toastTimer.restart()
                                                        return
                                                    }
                                                    installSddmAvatarProc.running = true
                                                    window.toastMessage = "Terminal launched for SDDM Avatar"
                                                    window.showSaveToast = true
                                                    toastTimer.restart()
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: 165
                                            height: 34
                                            radius: 8
                                            opacity: window.liveSddm.is_silent_sddm ? 1.0 : 0.40
                                            enabled: window.liveSddm.is_silent_sddm
                                            color: Theme.alpha(Theme.surface, 0.8)
                                            border.width: 1
                                            border.color: Theme.alpha(Theme.foreground, 0.2)
                                            visible: !!(window.liveAvatar && window.liveAvatar.sddm_face_backup_exists)

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Restore SDDM Backup"
                                                color: Theme.alpha(Theme.foreground, 0.8)
                                                font.family: "Outfit"
                                                font.pixelSize: 12
                                                font.weight: Font.DemiBold
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: window.liveSddm.is_silent_sddm
                                                cursorShape: window.liveSddm.is_silent_sddm ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                                                onClicked: {
                                                    if (!window.liveSddm.is_silent_sddm) return
                                                    restoreSddmAvatarProc.running = true
                                                    window.toastMessage = "Terminal launched to restore SDDM backup"
                                                    window.showSaveToast = true
                                                    toastTimer.restart()
                                                }
                                            }
                                        }

                                        Rectangle {
                                            width: 135
                                            height: 34
                                            radius: 8
                                            color: Theme.alpha(Theme.error, 0.15)
                                            border.width: 1
                                            border.color: Theme.alpha(Theme.error, 0.4)

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Reset to Default"
                                                color: Theme.error
                                                font.family: "Outfit"
                                                font.pixelSize: 12
                                                font.weight: Font.DemiBold
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: resetAvatarProc.running = true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                } // End of hyprContentArea

                Process {
                    id: setSddmThemeProc
                    command: ["python3", window.homeDir + "/.hyprconf/hypr/scripts/py/hypr-settings-backend.py", "set-sddm-theme", "SilentSDDM"]
                    onExited: function() {
                        backendGetProc.running = true
                    }
                }

                Process {
                    id: reloadProc
                    command: ["hyprctl", "reload"]
                }

                // =============================================================
                // ROOT NAV 1: DYNAMIC ISLAND & AUDIO VISUALIZER
                // =============================================================
                IslandSection {
                    visible: window.activeRootNav === 1
                }

                // =============================================================
                // ROOT NAV 2: DESKTOP WIDGETS & LIVE DRAG/DROP CANVAS
                // =============================================================
                WidgetsSection {
                    id: widgetsSection
                    visible: window.activeRootNav === 2
                }

                // =============================================================
                // ROOT NAV 3: LIVE WEATHER & GENERATIVE ATMOSPHERE (STANDALONE)
                // =============================================================
                WeatherSection {
                    anchors.fill: parent
                    visible: window.activeRootNav === 3
                }

                // =============================================================
                // ROOT NAV 4: LOCKSCREEN & LIVE CANVAS (The WYSIWYG Editor!)
                // =============================================================
                LockscreenSection {
                    id: lockscreenSection
                    visible: window.activeRootNav === 4
                }

                // =============================================================
                // ROOT NAV 5: APPLICATION DOCK STUDIO
                // =============================================================
                DockSection {
                    id: dockSection
                    visible: window.activeRootNav === 5
                }
            }
        }

        // ── SAVE TOAST NOTIFICATION ──────────────────────────────────────────
        Rectangle {
            id: toastPill
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 24
            anchors.horizontalCenter: parent.horizontalCenter
            height: 36
            width: toastRow.implicitWidth + 24
            radius: 18
            color: Theme.alpha(Theme.surface, 0.95)
            border.width: 1
            border.color: Theme.accent
            visible: window.showSaveToast
            opacity: window.showSaveToast ? 1.0 : 0.0

            Behavior on opacity { NumberAnimation { duration: 200 } }

            Row {
                id: toastRow
                anchors.centerIn: parent
                spacing: 8
                Image {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14; height: 14
                    source: window.checkSvg
                    sourceSize: Qt.size(28, 28)
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: window.toastMessage
                    color: Theme.foreground
                    font.family: "Outfit"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}