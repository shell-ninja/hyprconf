import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root
    anchors.fill: parent

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    // ── Local Configuration State ───────────────────────────────────────────
    property bool isInitialized: false
    property bool isSaving: false

    property string topPanelMode: "island"        // "island" | "bar"
    property int barHeight: 36
    property int marginTop: 6
    property int marginSides: 10
    property int barPadding: 6
    property int widgetSpacing: 8
    property int capsuleRadius: 12
    property int capsulePadding: 8
    property string capsuleStyle: "islands"       // "islands" | "glass"
    property string trailStyle: "matrix"          // "matrix" | "thunder" | "none"
    property real barOpacity: 0.85
    property bool hidePkgWhenEmpty: false

    property var startWidgets: ["workspaces", "tray", "weather"]
    property var centerWidgets: ["power_profile", "media", "clock", "notification"]
    property var endWidgets: ["pkg_update", "quick_toggles", "system_info", "volume", "power"]
    property var widgetSettings: ({})
    property string selectedCustomizerWidget: "visualizer"
    property string customizerCategoryFilter: "All"

    // Available widgets registry for "+ Add Element" dialog (All 21 native bar widgets)
    readonly property var allAvailableWidgets: [
        // Workspace & Window Management
        { id: "workspaces", name: "Dynamic Workspaces", desc: "Interactive workspace switcher with active indicator", icon: "layout", category: "Workspace" },
        { id: "active_window", name: "Active Window Title", desc: "Focused application icon and window title", icon: "window", category: "Workspace", isNew: true },
        { id: "launcher", name: "App Launcher", desc: "Application grid launcher drawer trigger", icon: "grid", category: "Workspace" },

        // Audio & Media
        { id: "media", name: "Media Player", desc: "Live MPRIS track metadata and playback controls", icon: "music", category: "Audio & Media" },
        { id: "visualizer", name: "Audio Spectrum Visualizer", desc: "Dynamic 8-bar mini audio equalizer spectrum", icon: "equalizer", category: "Audio & Media", isNew: true },
        { id: "volume", name: "Volume Controller", desc: "Audio sink volume percentage, scroll & quick mixer", icon: "volume", category: "Audio & Media" },

        // Performance & Hardware
        { id: "system_info", name: "System Monitor", desc: "Real-time RAM, CPU load percentage and disk gauges", icon: "gauge", category: "Performance" },
        { id: "network", name: "Network Speed Monitor", desc: "Real-time upload and download throughput (KB/s)", icon: "network", category: "Performance", isNew: true },
        { id: "battery", name: "Battery & AC Power", desc: "Live battery percentage on laptops or AC power badge", icon: "battery", category: "Performance", isNew: true },
        { id: "power_profile", name: "Power Profile Switcher", desc: "Cycle between Performance, Balanced and Saver modes", icon: "bolt", category: "Performance" },

        // Utilities & Information
        { id: "tray", name: "System Tray Drawer", desc: "Interactive system tray drawer for background apps", icon: "wifi", category: "Utilities" },
        { id: "weather", name: "Live Weather", desc: "Current temperature, weather condition & forecast", icon: "sun", category: "Utilities" },
        { id: "clock", name: "Clock & Calendar", desc: "Formatted local time and interactive calendar dropdown", icon: "clock", category: "Utilities" },
        { id: "notification", name: "Notification Center", desc: "Unread count indicator and notification toast history", icon: "bell", category: "Utilities" },
        { id: "dnd", name: "Do Not Disturb (DND)", desc: "Quick toggle to silence notifications and toasts", icon: "dnd", category: "Utilities", isNew: true },
        { id: "pkg_update", name: "Package Updates", desc: "Pending system packages counter and updater launcher", icon: "package", category: "Utilities" },

        // Quick Toggles & Controls
        { id: "quick_toggles", name: "Quick Toggles Group", desc: "All-in-one capsule for Caffeine, Night Light & Clipboard", icon: "coffee", category: "Quick Toggles" },
        { id: "caffeine", name: "Idle Inhibitor (Caffeine)", desc: "Standalone display sleep inhibitor toggle", icon: "coffee", category: "Quick Toggles" },
        { id: "nightlight", name: "Night Light (Sunset)", desc: "Standalone blue light filter night mode toggle", icon: "moon", category: "Quick Toggles" },
        { id: "clipboard", name: "Clipboard History", desc: "Standalone clipboard history opener and manager", icon: "clipboard", category: "Quick Toggles" },
        { id: "power", name: "Power Session Menu", desc: "Instant lock, logout, reboot and shutdown launcher", icon: "power", category: "Quick Toggles" }
    ]

    property bool showAddDialog: false
    property string addTargetZone: "start"
    property string addSearchQuery: ""
    property string addSelectedCategory: "All"
    readonly property var categoryList: ["All", "Workspace", "Audio & Media", "Performance", "Utilities", "Quick Toggles"]

    onShowAddDialogChanged: {
        if (root.showAddDialog) {
            root.addSearchQuery = ""
            root.addSelectedCategory = "All"
        }
    }

    // ── SVG Helpers ─────────────────────────────────────────────────────────
    function svgUrl(svgString) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgString)
    }

    readonly property string upSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><polyline points="18 15 12 9 6 15"/></svg>')
    readonly property string downSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg>')
    readonly property string leftSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><polyline points="15 18 9 12 15 6"/></svg>')
    readonly property string rightSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 18 15 12 9 6"/></svg>')
    readonly property string trashSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.error + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>')
    readonly property string plusSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>')
    readonly property string plusOnAccentSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.on_primary + '" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>')
    readonly property string checkSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>')
    readonly property string zapSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>')
    readonly property string searchSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.alpha(Theme.foreground, 0.6) + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>')

    function getWidgetMeta(id) {
        for (var i = 0; i < allAvailableWidgets.length; i++) {
            if (allAvailableWidgets[i].id === id) return allAvailableWidgets[i]
        }
        var formatted = id.replace(/_/g, " ").replace(/\b\w/g, function(l){ return l.toUpperCase() })
        return { id: id, name: formatted, desc: "Custom modular widget", icon: "app", category: "Other" }
    }

    function getWidgetZone(widgetId) {
        if (root.startWidgets && root.startWidgets.indexOf(widgetId) !== -1) return "Start (Left)"
        if (root.centerWidgets && root.centerWidgets.indexOf(widgetId) !== -1) return "Center"
        if (root.endWidgets && root.endWidgets.indexOf(widgetId) !== -1) return "End (Right)"
        return ""
    }

    function isWidgetInZone(widgetId, zoneName) {
        if (zoneName === "start") return root.startWidgets && root.startWidgets.indexOf(widgetId) !== -1
        if (zoneName === "center") return root.centerWidgets && root.centerWidgets.indexOf(widgetId) !== -1
        if (zoneName === "end") return root.endWidgets && root.endWidgets.indexOf(widgetId) !== -1
        return false
    }

    readonly property var filteredWidgets: {
        var q = (root.addSearchQuery || "").trim().toLowerCase()
        var cat = root.addSelectedCategory
        var list = []
        for (var i = 0; i < allAvailableWidgets.length; i++) {
            var w = allAvailableWidgets[i]
            if (cat !== "All" && w.category !== cat) continue
            if (q.length > 0) {
                var matchName = w.name.toLowerCase().indexOf(q) !== -1
                var matchDesc = (w.desc || "").toLowerCase().indexOf(q) !== -1
                var matchId = w.id.toLowerCase().indexOf(q) !== -1
                var matchCat = (w.category || "").toLowerCase().indexOf(q) !== -1
                if (!matchName && !matchDesc && !matchId && !matchCat) continue
            }
            list.push(w)
        }
        return list
    }

    function getWidgetSvg(id) {
        var meta = getWidgetMeta(id)
        var icon = meta.icon || "app"
        var inner = ""
        switch (icon) {
            case "grid": inner = '<rect x="3" y="3" width="7" height="7" rx="1.6"/><rect x="14" y="3" width="7" height="7" rx="1.6"/><rect x="3" y="14" width="7" height="7" rx="1.6"/><rect x="14.5" y="14.5" width="6" height="6" rx="1.2" transform="rotate(45 17.5 17.5)"/>'; break
            case "layout": inner = '<rect x="3" y="3" width="18" height="18" rx="2"/><line x1="3" y1="9" x2="21" y2="9"/><line x1="9" y1="21" x2="9" y2="9"/>'; break
            case "window": inner = '<rect x="3" y="4" width="18" height="16" rx="2"/><line x1="3" y1="9" x2="21" y2="9"/><circle cx="6.5" cy="6.5" r="0.8"/><circle cx="9.5" cy="6.5" r="0.8"/>'; break
            case "music": inner = '<path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/>'; break
            case "equalizer": inner = '<path d="M4 10v4M8 7v10M12 4v16M16 8v8M20 11v2"/>'; break
            case "volume": inner = '<path d="M11 5L6 9H3v6h3l5 4V5z"/><path d="M15.5 8.5a5 5 0 0 1 0 7"/><path d="M18.5 5.5a9 9 0 0 1 0 13"/>'; break
            case "gauge": inner = '<path d="M3.5 17.5a9 9 0 1 1 17 0"/><path d="M12 15l4-5"/><circle cx="12" cy="15" r="1"/>'; break
            case "network": inner = '<polyline points="7 10 12 5 17 10"/><line x1="12" y1="5" x2="12" y2="15"/><polyline points="17 14 12 19 7 14"/><line x1="12" y1="19" x2="12" y2="9"/>'; break
            case "battery": inner = '<rect x="2" y="7" width="16" height="10" rx="2"/><line x1="20" y1="11" x2="20" y2="13"/>'; break
            case "bolt": inner = '<path d="M13 2L4 14h7l-1 8 9-12h-7l1-8z"/>'; break
            case "wifi": inner = '<path d="M2 9a15 15 0 0 1 20 0"/><path d="M5.5 12.5a10 10 0 0 1 13 0"/><path d="M9 16a5 5 0 0 1 6 0"/><circle cx="12" cy="19.5" r="0.8"/>'; break
            case "sun": inner = '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>'; break
            case "clock": inner = '<circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>'; break
            case "bell": inner = '<path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 0 1-3.4 0"/>'; break
            case "dnd": inner = '<path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><line x1="2" y1="2" x2="22" y2="22"/>'; break
            case "package": inner = '<path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>'; break
            case "coffee": inner = '<path d="M5 9h12v5a5 5 0 0 1-5 5h-2a5 5 0 0 1-5-5V9z"/><path d="M17 11h1.5a2.5 2.5 0 0 1 0 5H17"/><path d="M8 3v3M12 3v3"/>'; break
            case "moon": inner = '<path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z"/>'; break
            case "clipboard": inner = '<rect x="5" y="4" width="14" height="17" rx="2"/><rect x="9" y="2.5" width="6" height="3.5" rx="1"/><path d="M9 12h6M9 16h4"/>'; break
            case "power": inner = '<path d="M12 3v9"/><path d="M6.4 6.6a8 8 0 1 0 11.2 0"/>'; break
            case "spark": inner = '<path d="M12 2l2.4 7.2L21 12l-6.6 2.8L12 22l-2.4-7.2L3 12l6.6-2.8z"/>'; break
            default: inner = '<rect x="4" y="4" width="16" height="16" rx="4"/><path d="M9 12h6"/>'; break
        }
        var doc = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' + inner + '</svg>'
        return svgUrl(doc)
    }

    function parseConfig(rawText) {
        if (!rawText || rawText.trim().length === 0) return
        try {
            var cfg = JSON.parse(rawText.trim())
            if (cfg.top_panel) root.topPanelMode = cfg.top_panel
            if (cfg.height !== undefined) root.barHeight = parseInt(cfg.height, 10) || 36
            if (cfg.margin_top !== undefined) root.marginTop = parseInt(cfg.margin_top, 10) || 0
            if (cfg.margin_left !== undefined) root.marginSides = parseInt(cfg.margin_left, 10) || 0
            if (cfg.padding !== undefined) root.barPadding = parseInt(cfg.padding, 10) || 6
            if (cfg.widget_spacing !== undefined) root.widgetSpacing = parseInt(cfg.widget_spacing, 10) || 8
            if (cfg.capsule_radius !== undefined) root.capsuleRadius = parseInt(cfg.capsule_radius, 10) || 12
            if (cfg.capsule_padding !== undefined) root.capsulePadding = parseInt(cfg.capsule_padding, 10) || 10
            if (cfg.capsule_style !== undefined) root.capsuleStyle = cfg.capsule_style
            if (cfg.trail_style !== undefined) root.trailStyle = cfg.trail_style
            if (cfg.opacity !== undefined) root.barOpacity = parseFloat(cfg.opacity) || 0.85
            if (cfg.hide_pkg_empty !== undefined) root.hidePkgWhenEmpty = !!cfg.hide_pkg_empty

            if (cfg.start && Array.isArray(cfg.start)) root.startWidgets = cfg.start
            if (cfg.center && Array.isArray(cfg.center)) root.centerWidgets = cfg.center
            if (cfg.end && Array.isArray(cfg.end)) root.endWidgets = cfg.end
            if (cfg.widget_settings && typeof cfg.widget_settings === "object") {
                root.widgetSettings = cfg.widget_settings
            }

            root.isInitialized = true
        } catch(e) {
            console.log("[BarSection] Error parsing bar.json:", e)
            root.isInitialized = true
        }
    }

    // ── READ BAR CONFIG ─────────────────────────────────────────────────────
    Process {
        id: configReader
        command: ["sh", "-c", "cat " + root.homeDir + "/.local/share/hyprconf/bar.json 2>/dev/null || cat " + root.homeDir + "/.hyprconf/quickshell/bar/config.json 2>/dev/null || echo '{}'"]
        running: true
        stdout: StdioCollector {
            onTextChanged: root.parseConfig(text)
            onStreamFinished: root.parseConfig(text)
        }
    }

    // ── SAVE BAR CONFIG ─────────────────────────────────────────────────────
    Process {
        id: barWriter
        onExited: {
            root.isSaving = false
            barReloader.running = true
        }
    }

    Process {
        id: barReloader
        command: ["sh", "-c", "qs ipc -c bar call bar reloadConfig 2>/dev/null || " + root.homeDir + "/.hyprconf/hypr/scripts/sh/qs-bar.sh --restart"]
    }

    Timer {
        id: autoSaveTimer
        interval: 150
        repeat: false
        onTriggered: root.executeSave()
    }

    function triggerAutoSave() {
        if (!root.isInitialized) return
        root.isSaving = true
        autoSaveTimer.restart()
    }

    function getWidgetOption(widgetId, key, fallback) {
        if (!root.widgetSettings || !root.widgetSettings[widgetId]) return fallback
        var val = root.widgetSettings[widgetId][key]
        return (val !== undefined) ? val : fallback
    }

    function setWidgetOption(widgetId, key, value) {
        var s = Object.assign({}, root.widgetSettings)
        if (!s[widgetId]) s[widgetId] = {}
        else s[widgetId] = Object.assign({}, s[widgetId])
        s[widgetId][key] = value
        root.widgetSettings = s
        root.triggerAutoSave()
    }

    function getWidgetZoneStatus(widgetId) {
        if (root.startWidgets.indexOf(widgetId) !== -1) return "Start Zone"
        if (root.centerWidgets.indexOf(widgetId) !== -1) return "Center Zone"
        if (root.endWidgets.indexOf(widgetId) !== -1) return "End Zone"
        return "Catalog (Not Placed)"
    }

    function executeSave() {
        var payload = {
            "top_panel": root.topPanelMode,
            "height": root.barHeight,
            "margin_top": root.marginTop,
            "margin_left": root.marginSides,
            "margin_right": root.marginSides,
            "padding": root.barPadding,
            "widget_spacing": root.widgetSpacing,
            "capsule_radius": root.capsuleRadius,
            "capsule_padding": root.capsulePadding,
            "capsule_style": root.capsuleStyle,
            "trail_style": root.trailStyle,
            "opacity": root.barOpacity,
            "hide_pkg_empty": root.hidePkgWhenEmpty,
            "start": root.startWidgets,
            "center": root.centerWidgets,
            "end": root.endWidgets,
            "widget_settings": root.widgetSettings
        }
        var jsonStr = JSON.stringify(payload, null, 2)
        var pyScript = "import json, os\n" +
            "for p in [os.path.expanduser('~/.local/share/hyprconf/bar.json'), os.path.expanduser('~/.hyprconf/quickshell/bar/config.json')]:\n" +
            "    try:\n" +
            "        os.makedirs(os.path.dirname(p), exist_ok=True)\n" +
            "        with open(p, 'w', encoding='utf-8') as f: f.write('''" + jsonStr + "''')\n" +
            "    except Exception as e: print(e)\n"
        barWriter.command = ["python3", "-c", pyScript]
        barWriter.running = true
    }

    function resetDefaults() {
        root.barHeight = 38
        root.marginTop = 6
        root.marginSides = 10
        root.barPadding = 8
        root.widgetSpacing = 6
        root.capsuleRadius = 14
        root.capsulePadding = 8
        root.capsuleStyle = "islands"
        root.trailStyle = "matrix"
        root.barOpacity = 0.85
        root.hidePkgWhenEmpty = false
        root.startWidgets = ["workspaces", "tray", "weather"]
        root.centerWidgets = ["power_profile", "media", "clock", "notification"]
        root.endWidgets = ["pkg_update", "quick_toggles", "system_info", "volume", "power"]
        root.triggerAutoSave()
    }

    function switchTopPanel(mode) {
        if (root.topPanelMode === mode) return
        root.topPanelMode = mode
        autoSaveTimer.stop()

        var payload = {
            "top_panel": mode,
            "height": root.barHeight,
            "margin_top": root.marginTop,
            "margin_left": root.marginSides,
            "margin_right": root.marginSides,
            "padding": root.barPadding,
            "widget_spacing": root.widgetSpacing,
            "capsule_radius": root.capsuleRadius,
            "capsule_padding": root.capsulePadding,
            "capsule_style": root.capsuleStyle,
            "trail_style": root.trailStyle,
            "opacity": root.barOpacity,
            "screen_frame": (root.capsuleStyle === "glass"),
            "hide_pkg_empty": root.hidePkgWhenEmpty,
            "start": root.startWidgets,
            "center": root.centerWidgets,
            "end": root.endWidgets,
            "widget_settings": root.widgetSettings
        }
        var jsonStr = JSON.stringify(payload, null, 2)
        var switchScript = "import json, os, subprocess, time\n" +
            "p1 = os.path.expanduser('~/.local/share/hyprconf/bar.json')\n" +
            "p2 = os.path.expanduser('~/.hyprconf/quickshell/bar/config.json')\n" +
            "content = '''" + jsonStr + "'''\n" +
            "for p in [p1, p2]:\n" +
            "    try:\n" +
            "        os.makedirs(os.path.dirname(p), exist_ok=True)\n" +
            "        with open(p, 'w', encoding='utf-8') as f:\n" +
            "            f.write(content)\n" +
            "            f.flush()\n" +
            "            os.fsync(f.fileno())\n" +
            "    except Exception as e: print(e)\n"

        if (mode === "bar") {
            switchScript += "subprocess.run(['bash', os.path.expanduser('~/.hyprconf/hypr/scripts/sh/qs-island.sh'), '--stop'], stderr=subprocess.DEVNULL)\n" +
                "subprocess.run(['pkill', '-9', '-f', '^qs -c island'], stderr=subprocess.DEVNULL)\n" +
                "time.sleep(0.1)\n" +
                "subprocess.run(['bash', os.path.expanduser('~/.hyprconf/hypr/scripts/sh/qs-bar.sh'), '--restart'], stderr=subprocess.DEVNULL)\n"
        } else {
            switchScript += "subprocess.run(['qs', 'ipc', '-c', 'bar', 'call', 'bar', 'quit'], stderr=subprocess.DEVNULL)\n" +
                "subprocess.run(['bash', os.path.expanduser('~/.hyprconf/hypr/scripts/sh/qs-bar.sh'), '--stop'], stderr=subprocess.DEVNULL)\n" +
                "subprocess.run(['pkill', '-9', '-f', '^qs -c bar'], stderr=subprocess.DEVNULL)\n" +
                "time.sleep(0.1)\n" +
                "subprocess.run(['bash', os.path.expanduser('~/.hyprconf/hypr/scripts/sh/qs-island.sh'), '--restart'], stderr=subprocess.DEVNULL)\n"
        }
        Quickshell.execDetached(["python3", "-c", switchScript])
    }

    // Zone mutation functions
    function moveWidget(zoneName, fromIndex, toIndex) {
        var arr = zoneName === "start" ? root.startWidgets.slice() : (zoneName === "center" ? root.centerWidgets.slice() : root.endWidgets.slice())
        if (toIndex < 0 || toIndex >= arr.length) return
        var item = arr.splice(fromIndex, 1)[0]
        arr.splice(toIndex, 0, item)
        if (zoneName === "start") root.startWidgets = arr
        else if (zoneName === "center") root.centerWidgets = arr
        else root.endWidgets = arr
        root.triggerAutoSave()
    }

    function transferWidget(fromZone, toZone, index) {
        var fromArr = fromZone === "start" ? root.startWidgets.slice() : (fromZone === "center" ? root.centerWidgets.slice() : root.endWidgets.slice())
        var toArr = toZone === "start" ? root.startWidgets.slice() : (toZone === "center" ? root.centerWidgets.slice() : root.endWidgets.slice())
        if (index < 0 || index >= fromArr.length) return
        var item = fromArr.splice(index, 1)[0]
        toArr.push(item)

        if (fromZone === "start") root.startWidgets = fromArr
        else if (fromZone === "center") root.centerWidgets = fromArr
        else root.endWidgets = fromArr

        if (toZone === "start") root.startWidgets = toArr
        else if (toZone === "center") root.centerWidgets = toArr
        else root.endWidgets = toArr

        root.triggerAutoSave()
    }

    function removeWidget(zoneName, index) {
        var arr = zoneName === "start" ? root.startWidgets.slice() : (zoneName === "center" ? root.centerWidgets.slice() : root.endWidgets.slice())
        if (index < 0 || index >= arr.length) return
        var removed = arr.splice(index, 1)[0]
        if (zoneName === "start") root.startWidgets = arr
        else if (zoneName === "center") root.centerWidgets = arr
        else root.endWidgets = arr
        root.triggerAutoSave()
        if (typeof window !== "undefined" && window && window.showSaveToast !== undefined) {
            var meta = root.getWidgetMeta(removed)
            window.toastMessage = "Removed " + meta.name
            window.showSaveToast = true
            if (typeof toastTimer !== "undefined") toastTimer.restart()
        }
    }

    function addWidget(zoneName, widgetId) {
        var arr = zoneName === "start" ? root.startWidgets.slice() : (zoneName === "center" ? root.centerWidgets.slice() : root.endWidgets.slice())
        arr.push(widgetId)
        if (zoneName === "start") root.startWidgets = arr
        else if (zoneName === "center") root.centerWidgets = arr
        else root.endWidgets = arr
        root.triggerAutoSave()
        root.showAddDialog = false
        if (typeof window !== "undefined" && window && window.showSaveToast !== undefined) {
            var meta = root.getWidgetMeta(widgetId)
            var zoneLabel = zoneName === "start" ? "Start (Left)" : (zoneName === "center" ? "Center" : "End (Right)")
            window.toastMessage = "Added " + meta.name + " to " + zoneLabel + " zone"
            window.showSaveToast = true
            if (typeof toastTimer !== "undefined") toastTimer.restart()
        }
    }

    // ── MAIN SCROLLABLE VIEW ────────────────────────────────────────────────
    ScrollView {
        id: scrollView
        anchors.fill: parent
        anchors.margins: 18
        clip: true

        ScrollBar.vertical: ScrollBar {
            id: vBar
            parent: scrollView
            anchors.top: scrollView.top
            anchors.right: scrollView.right
            anchors.bottom: scrollView.bottom
            width: 6
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 6
                radius: 3
                color: vBar.pressed ? Theme.accent : (vBar.hovered ? Theme.alpha(Theme.accent, 0.7) : Theme.alpha(Theme.foreground, 0.25))
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }

        Column {
            width: scrollView.width - 20
            spacing: 18

            // ── HEADER & MASTER TOP PANEL SWITCHER ──────────────────────────
            Rectangle {
                width: parent.width
                implicitHeight: headerLayout.implicitHeight + 28
                radius: 16
                color: Theme.alpha(Theme.surface, 0.65)
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.30)

                ColumnLayout {
                    id: headerLayout
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Column {
                            Layout.fillWidth: true
                            spacing: 3
                            Text {
                                text: "Top Interface Studio"
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 18
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: "Switch seamlessly between Dynamic Island and Full Top Bar, and arrange bar modules."
                                color: Theme.alpha(Theme.foreground, 0.60)
                                font.family: "Outfit"
                                font.pixelSize: 11
                            }
                        }

                        // Restart Daemon Button
                        Rectangle {
                            width: 110
                            height: 32
                            radius: 8
                            color: Theme.alpha(Theme.surface, 0.85)
                            border.width: 1
                            border.color: Theme.alpha(Theme.foreground, 0.15)
                            Text {
                                anchors.centerIn: parent
                                text: "Restart Bar"
                                color: Theme.alpha(Theme.foreground, 0.85)
                                font.family: "Outfit"
                                font.pixelSize: 11
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: barReloader.running = true
                            }
                        }

                        // Reset Defaults Button
                        Rectangle {
                            width: 110
                            height: 32
                            radius: 8
                            color: Theme.alpha(Theme.surface, 0.85)
                            border.width: 1
                            border.color: Theme.alpha(Theme.foreground, 0.15)
                            Text {
                                anchors.centerIn: parent
                                text: "Reset Defaults"
                                color: Theme.alpha(Theme.foreground, 0.85)
                                font.family: "Outfit"
                                font.pixelSize: 11
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.resetDefaults()
                            }
                        }
                    }

                    // ── INTERFACE SELECTOR CHIPS ────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        height: 48
                        radius: 12
                        color: Theme.alpha(Theme.background, 0.70)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.20)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 6

                            // Option 1: Dynamic Island
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 8
                                color: root.topPanelMode === "island" ? Theme.accent : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Image {
                                        width: 16
                                        height: 16
                                        source: root.svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + (root.topPanelMode === "island" ? Theme.on_primary : Theme.accent) + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="6" width="16" height="6" rx="3"/><line x1="8" y1="16" x2="8" y2="18"/><line x1="12" y1="15" x2="12" y2="19"/><line x1="16" y1="16" x2="16" y2="18"/></svg>')
                                        sourceSize: Qt.size(32, 32)
                                    }
                                    Text {
                                        text: "Dynamic Island"
                                        color: root.topPanelMode === "island" ? Theme.on_primary : Theme.foreground
                                        font.family: "Outfit"
                                        font.bold: true
                                        font.pixelSize: 13
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.switchTopPanel("island")
                                }
                            }

                            // Option 2: Full Top Bar
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 8
                                color: root.topPanelMode === "bar" ? Theme.accent : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Image {
                                        width: 16
                                        height: 16
                                        source: root.svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + (root.topPanelMode === "bar" ? Theme.on_primary : Theme.accent) + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="5" rx="1.5"/><rect x="4" y="5" width="2" height="1" fill="' + (root.topPanelMode === "bar" ? Theme.on_primary : Theme.accent) + '"/><rect x="8" y="5" width="2" height="1" fill="' + (root.topPanelMode === "bar" ? Theme.on_primary : Theme.accent) + '"/><rect x="18" y="5" width="2" height="1" fill="' + (root.topPanelMode === "bar" ? Theme.on_primary : Theme.accent) + '"/><rect x="2" y="11" width="20" height="10" rx="2" stroke-dasharray="2 2"/></svg>')
                                        sourceSize: Qt.size(32, 32)
                                    }
                                    Text {
                                        text: "Full Top Bar"
                                        color: root.topPanelMode === "bar" ? Theme.on_primary : Theme.foreground
                                        font.family: "Outfit"
                                        font.bold: true
                                        font.pixelSize: 13
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.switchTopPanel("bar")
                                }
                            }
                        }
                    }
                }
            }

            // ── LIVE VISUAL PREVIEW OF TOP BAR ──────────────────────────────
            SettingCard {
                title: "Live Bar Preview"
                description: "Real-time layout simulation with current dimensions and active zone modules"

                Column {
                    width: parent.width
                    spacing: 10

                    Rectangle {
                        width: parent.width
                        height: 52
                        radius: 10
                        color: Theme.alpha(Theme.background, 0.90)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.25)
                        clip: true

                        // Preview Bar Strip
                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.topMargin: Math.min(8, root.marginTop)
                            anchors.leftMargin: Math.min(16, root.marginSides)
                            anchors.rightMargin: Math.min(16, root.marginSides)
                            height: Math.min(36, root.barHeight)
                            radius: Math.min(root.capsuleRadius, height / 2)
                            color: Theme.alpha(Theme.surface, root.barOpacity)
                            border.width: 1
                            border.color: Theme.alpha(Theme.accent, 0.30)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8

                                // Left preview chips
                                Row {
                                    spacing: 4
                                    Repeater {
                                        model: root.startWidgets.slice(0, 6)
                                        delegate: Rectangle {
                                            width: 22; height: 18; radius: 5
                                            color: Theme.alpha(Theme.accent, 0.20)
                                            border.width: 1
                                            border.color: Theme.alpha(Theme.accent, 0.35)
                                            Image {
                                                anchors.centerIn: parent
                                                width: 11; height: 11
                                                source: root.getWidgetSvg(modelData)
                                            }
                                        }
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                // Center preview chips
                                Row {
                                    spacing: 4
                                    Repeater {
                                        model: root.centerWidgets.slice(0, 6)
                                        delegate: Rectangle {
                                            width: 22; height: 18; radius: 5
                                            color: Theme.alpha(Theme.accent, 0.20)
                                            border.width: 1
                                            border.color: Theme.alpha(Theme.accent, 0.35)
                                            Image {
                                                anchors.centerIn: parent
                                                width: 11; height: 11
                                                source: root.getWidgetSvg(modelData)
                                            }
                                        }
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                // Right preview chips
                                Row {
                                    spacing: 4
                                    Repeater {
                                        model: root.endWidgets.slice(0, 7)
                                        delegate: Rectangle {
                                            width: 22; height: 18; radius: 5
                                            color: Theme.alpha(Theme.accent, 0.20)
                                            border.width: 1
                                            border.color: Theme.alpha(Theme.accent, 0.35)
                                            Image {
                                                anchors.centerIn: parent
                                                width: 11; height: 11
                                                source: root.getWidgetSvg(modelData)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── 3-ZONE LAYOUT & REORDER EDITOR ──────────────────────────────
            SettingCard {
                title: "Layout Zones & Module Positioning"
                description: "Reorder modules within zones, transfer between zones, or add and remove elements"

                RowLayout {
                    width: parent.width
                    spacing: 12

                    // ── ZONE 1: START (LEFT) ────────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: startZoneCol.implicitHeight + 24
                        radius: 12
                        color: Theme.alpha(Theme.background, 0.60)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.20)

                        ColumnLayout {
                            id: startZoneCol
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    Layout.fillWidth: true
                                    text: "Start Zone (Left)"
                                    color: Theme.accent
                                    font.family: "Outfit"
                                    font.bold: true
                                    font.pixelSize: 13
                                }
                                Text {
                                    text: root.startWidgets.length + " items"
                                    color: Theme.muted
                                    font.pixelSize: 10
                                }
                            }

                            Repeater {
                                model: root.startWidgets
                                delegate: Rectangle {
                                    required property string modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    height: 38
                                    radius: 8
                                    color: root.selectedCustomizerWidget === modelData ? Theme.alpha(Theme.accent, 0.20) : Theme.alpha(Theme.surface, 0.85)
                                    border.width: root.selectedCustomizerWidget === modelData ? 1.5 : 1
                                    border.color: root.selectedCustomizerWidget === modelData ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)

                                    MouseArea {
                                        anchors.fill: parent
                                        z: -1
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.selectedCustomizerWidget = modelData
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 6

                                        Rectangle {
                                            width: 22; height: 22; radius: 5
                                            color: Theme.alpha(Theme.accent, 0.16)
                                            border.width: 1
                                            border.color: Theme.alpha(Theme.accent, 0.32)
                                            Image {
                                                anchors.centerIn: parent
                                                width: 13; height: 13
                                                source: root.getWidgetSvg(modelData)
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: root.getWidgetMeta(modelData).name
                                            color: Theme.foreground
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }

                                        // Move Up Button
                                        Rectangle {
                                            width: 22; height: 22; radius: 4
                                            color: Theme.alpha(Theme.surface, 0.9)
                                            visible: index > 0
                                            Image { anchors.centerIn: parent; width: 12; height: 12; source: root.upSvg }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.moveWidget("start", index, index - 1) }
                                        }

                                        // Move Down Button
                                        Rectangle {
                                            width: 22; height: 22; radius: 4
                                            color: Theme.alpha(Theme.surface, 0.9)
                                            visible: index < root.startWidgets.length - 1
                                            Image { anchors.centerIn: parent; width: 12; height: 12; source: root.downSvg }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.moveWidget("start", index, index + 1) }
                                        }

                                        // Move to Center Zone Button
                                        Rectangle {
                                            width: 22; height: 22; radius: 4
                                            color: Theme.alpha(Theme.surface, 0.9)
                                            Image { anchors.centerIn: parent; width: 12; height: 12; source: root.rightSvg }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.transferWidget("start", "center", index) }
                                        }

                                        // Remove Button
                                        Rectangle {
                                            width: 22; height: 22; radius: 4
                                            color: Theme.alpha(Theme.error, 0.15)
                                            Image { anchors.centerIn: parent; width: 12; height: 12; source: root.trashSvg }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.removeWidget("start", index) }
                                        }
                                    }
                                }
                            }

                            // Add Button
                            Rectangle {
                                Layout.fillWidth: true
                                height: 32
                                radius: 8
                                color: Theme.alpha(Theme.surface, 0.60)
                                border.width: 1
                                border.color: Theme.alpha(Theme.accent, 0.30)
                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Image { width: 12; height: 12; source: root.plusSvg }
                                    Text { text: "Add Module"; color: Theme.accent; font.pixelSize: 11; font.bold: true }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.addTargetZone = "start"
                                        root.showAddDialog = true
                                    }
                                }
                            }
                        }
                    }

                    // ── ZONE 2: CENTER ──────────────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: centerZoneCol.implicitHeight + 24
                        radius: 12
                        color: Theme.alpha(Theme.background, 0.60)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.20)

                        ColumnLayout {
                            id: centerZoneCol
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    Layout.fillWidth: true
                                    text: "Center Zone"
                                    color: Theme.accent
                                    font.family: "Outfit"
                                    font.bold: true
                                    font.pixelSize: 13
                                }
                                Text {
                                    text: root.centerWidgets.length + " items"
                                    color: Theme.muted
                                    font.pixelSize: 10
                                }
                            }

                            Repeater {
                                model: root.centerWidgets
                                delegate: Rectangle {
                                    required property string modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    height: 38
                                    radius: 8
                                    color: root.selectedCustomizerWidget === modelData ? Theme.alpha(Theme.accent, 0.20) : Theme.alpha(Theme.surface, 0.85)
                                    border.width: root.selectedCustomizerWidget === modelData ? 1.5 : 1
                                    border.color: root.selectedCustomizerWidget === modelData ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)

                                    MouseArea {
                                        anchors.fill: parent
                                        z: -1
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.selectedCustomizerWidget = modelData
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 6

                                        Rectangle {
                                            width: 22; height: 22; radius: 5
                                            color: Theme.alpha(Theme.accent, 0.16)
                                            border.width: 1
                                            border.color: Theme.alpha(Theme.accent, 0.32)
                                            Image {
                                                anchors.centerIn: parent
                                                width: 13; height: 13
                                                source: root.getWidgetSvg(modelData)
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: root.getWidgetMeta(modelData).name
                                            color: Theme.foreground
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }

                                        // Move to Left Button
                                        Rectangle {
                                            width: 22; height: 22; radius: 4
                                            color: Theme.alpha(Theme.surface, 0.9)
                                            Image { anchors.centerIn: parent; width: 12; height: 12; source: root.leftSvg }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.transferWidget("center", "start", index) }
                                        }

                                        // Move Up Button
                                        Rectangle {
                                            width: 22; height: 22; radius: 4
                                            color: Theme.alpha(Theme.surface, 0.9)
                                            visible: index > 0
                                            Image { anchors.centerIn: parent; width: 12; height: 12; source: root.upSvg }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.moveWidget("center", index, index - 1) }
                                        }

                                        // Move Down Button
                                        Rectangle {
                                            width: 22; height: 22; radius: 4
                                            color: Theme.alpha(Theme.surface, 0.9)
                                            visible: index < root.centerWidgets.length - 1
                                            Image { anchors.centerIn: parent; width: 12; height: 12; source: root.downSvg }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.moveWidget("center", index, index + 1) }
                                        }

                                        // Move to Right Button
                                        Rectangle {
                                            width: 22; height: 22; radius: 4
                                            color: Theme.alpha(Theme.surface, 0.9)
                                            Image { anchors.centerIn: parent; width: 12; height: 12; source: root.rightSvg }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.transferWidget("center", "end", index) }
                                        }

                                        // Remove Button
                                        Rectangle {
                                            width: 22; height: 22; radius: 4
                                            color: Theme.alpha(Theme.error, 0.15)
                                            Image { anchors.centerIn: parent; width: 12; height: 12; source: root.trashSvg }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.removeWidget("center", index) }
                                        }
                                    }
                                }
                            }

                            // Add Button
                            Rectangle {
                                Layout.fillWidth: true
                                height: 32
                                radius: 8
                                color: Theme.alpha(Theme.surface, 0.60)
                                border.width: 1
                                border.color: Theme.alpha(Theme.accent, 0.30)
                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Image { width: 12; height: 12; source: root.plusSvg }
                                    Text { text: "Add Module"; color: Theme.accent; font.pixelSize: 11; font.bold: true }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.addTargetZone = "center"
                                        root.showAddDialog = true
                                    }
                                }
                            }
                        }
                    }

                    // ── ZONE 3: END (RIGHT) ─────────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: endZoneCol.implicitHeight + 24
                        radius: 12
                        color: Theme.alpha(Theme.background, 0.60)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.20)

                        ColumnLayout {
                            id: endZoneCol
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    Layout.fillWidth: true
                                    text: "End Zone (Right)"
                                    color: Theme.accent
                                    font.family: "Outfit"
                                    font.bold: true
                                    font.pixelSize: 13
                                }
                                Text {
                                    text: root.endWidgets.length + " items"
                                    color: Theme.muted
                                    font.pixelSize: 10
                                }
                            }

                            Repeater {
                                model: root.endWidgets
                                delegate: Rectangle {
                                    required property string modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    height: 38
                                    radius: 8
                                    color: root.selectedCustomizerWidget === modelData ? Theme.alpha(Theme.accent, 0.20) : Theme.alpha(Theme.surface, 0.85)
                                    border.width: root.selectedCustomizerWidget === modelData ? 1.5 : 1
                                    border.color: root.selectedCustomizerWidget === modelData ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)

                                    MouseArea {
                                        anchors.fill: parent
                                        z: -1
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.selectedCustomizerWidget = modelData
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 6

                                        Rectangle {
                                            width: 22; height: 22; radius: 5
                                            color: Theme.alpha(Theme.accent, 0.16)
                                            border.width: 1
                                            border.color: Theme.alpha(Theme.accent, 0.32)
                                            Image {
                                                anchors.centerIn: parent
                                                width: 13; height: 13
                                                source: root.getWidgetSvg(modelData)
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: root.getWidgetMeta(modelData).name
                                            color: Theme.foreground
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }

                                        // Move to Center Zone Button
                                        Rectangle {
                                            width: 22; height: 22; radius: 4
                                            color: Theme.alpha(Theme.surface, 0.9)
                                            Image { anchors.centerIn: parent; width: 12; height: 12; source: root.leftSvg }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.transferWidget("end", "center", index) }
                                        }

                                        // Move Up Button
                                        Rectangle {
                                            width: 22; height: 22; radius: 4
                                            color: Theme.alpha(Theme.surface, 0.9)
                                            visible: index > 0
                                            Image { anchors.centerIn: parent; width: 12; height: 12; source: root.upSvg }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.moveWidget("end", index, index - 1) }
                                        }

                                        // Move Down Button
                                        Rectangle {
                                            width: 22; height: 22; radius: 4
                                            color: Theme.alpha(Theme.surface, 0.9)
                                            visible: index < root.endWidgets.length - 1
                                            Image { anchors.centerIn: parent; width: 12; height: 12; source: root.downSvg }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.moveWidget("end", index, index + 1) }
                                        }

                                        // Remove Button
                                        Rectangle {
                                            width: 22; height: 22; radius: 4
                                            color: Theme.alpha(Theme.error, 0.15)
                                            Image { anchors.centerIn: parent; width: 12; height: 12; source: root.trashSvg }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.removeWidget("end", index) }
                                        }
                                    }
                                }
                            }

                            // Add Button
                            Rectangle {
                                Layout.fillWidth: true
                                height: 32
                                radius: 8
                                color: Theme.alpha(Theme.surface, 0.60)
                                border.width: 1
                                border.color: Theme.alpha(Theme.accent, 0.30)
                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Image { width: 12; height: 12; source: root.plusSvg }
                                    Text { text: "Add Module"; color: Theme.accent; font.pixelSize: 11; font.bold: true }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.addTargetZone = "end"
                                        root.showAddDialog = true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── WIDGET FINE-TUNING & CUSTOMIZER ─────────────────────────────
            SettingCard {
                title: "Widget Fine-Tuning & Usability Options"
                description: "Select any widget below to customize its specific behavior, dimensions, display formats, and metrics"

                Column {
                    width: parent.width
                    spacing: 16

                    // ── Category Filter Chips ──────────────────────────────
                    RowLayout {
                        width: parent.width
                        spacing: 8
                        Repeater {
                            model: ["All", "Active in Bar", "Workspace", "Audio & Media", "Performance", "Utilities"]
                            Rectangle {
                                height: 28
                                implicitWidth: catText.implicitWidth + 20
                                radius: 7
                                color: root.customizerCategoryFilter === modelData ? Theme.accent : Theme.alpha(Theme.surface, 0.70)
                                border.width: 1
                                border.color: root.customizerCategoryFilter === modelData ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)

                                Text {
                                    id: catText
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    font.weight: root.customizerCategoryFilter === modelData ? Font.Bold : Font.Medium
                                    color: root.customizerCategoryFilter === modelData ? Theme.on_primary : Theme.foreground
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.customizerCategoryFilter = modelData
                                }
                            }
                        }
                    }

                    // ── Widget Selector Flow Grid ──────────────────────────
                    Flow {
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: {
                                var list = root.allAvailableWidgets
                                if (root.customizerCategoryFilter === "Active in Bar") {
                                    return list.filter(function(w) {
                                        return root.startWidgets.indexOf(w.id) !== -1 ||
                                               root.centerWidgets.indexOf(w.id) !== -1 ||
                                               root.endWidgets.indexOf(w.id) !== -1
                                    })
                                } else if (root.customizerCategoryFilter !== "All") {
                                    return list.filter(function(w) { return w.category === root.customizerCategoryFilter })
                                }
                                return list
                            }

                            Rectangle {
                                height: 34
                                implicitWidth: pillRow.implicitWidth + 20
                                radius: 8
                                color: root.selectedCustomizerWidget === modelData.id
                                    ? Theme.alpha(Theme.accent, 0.22)
                                    : Theme.alpha(Theme.surface, 0.60)
                                border.width: root.selectedCustomizerWidget === modelData.id ? 1.5 : 1
                                border.color: root.selectedCustomizerWidget === modelData.id ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)

                                RowLayout {
                                    id: pillRow
                                    anchors.centerIn: parent
                                    spacing: 7

                                    Image {
                                        width: 14; height: 14
                                        source: root.getWidgetSvg(modelData.id)
                                    }

                                    Text {
                                        text: modelData.name
                                        font.family: "Outfit"
                                        font.pixelSize: 11
                                        font.weight: root.selectedCustomizerWidget === modelData.id ? Font.Bold : Font.Normal
                                        color: root.selectedCustomizerWidget === modelData.id ? Theme.accent : Theme.foreground
                                    }

                                    // Placement dot
                                    Rectangle {
                                        width: 6; height: 6; radius: 3
                                        color: {
                                            if (root.startWidgets.indexOf(modelData.id) !== -1) return "#06b6d4"
                                            if (root.centerWidgets.indexOf(modelData.id) !== -1) return "#a855f7"
                                            if (root.endWidgets.indexOf(modelData.id) !== -1) return "#10b981"
                                            return Theme.alpha(Theme.foreground, 0.20)
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectedCustomizerWidget = modelData.id
                                }
                            }
                        }
                    }

                    // ── Dedicated Tailored Options Sub-Panel ───────────────
                    Rectangle {
                        width: parent.width
                        implicitHeight: optionsLayout.implicitHeight + 32
                        radius: 12
                        color: Theme.alpha(Theme.background, 0.85)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.35)

                        ColumnLayout {
                            id: optionsLayout
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 16

                            // Widget Header Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                Rectangle {
                                    width: 40; height: 40; radius: 10
                                    color: Theme.alpha(Theme.accent, 0.18)
                                    border.width: 1; border.color: Theme.accent
                                    Image {
                                        anchors.centerIn: parent
                                        width: 20; height: 20
                                        source: root.getWidgetSvg(root.selectedCustomizerWidget)
                                    }
                                }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text {
                                        text: root.getWidgetMeta(root.selectedCustomizerWidget).name
                                        font.family: "Outfit"
                                        font.pixelSize: 16
                                        font.weight: Font.Bold
                                        color: Theme.foreground
                                    }
                                    Text {
                                        text: root.getWidgetMeta(root.selectedCustomizerWidget).desc
                                        font.family: "Outfit"
                                        font.pixelSize: 11
                                        color: Theme.alpha(Theme.foreground, 0.60)
                                    }
                                }

                                Rectangle {
                                    height: 24
                                    implicitWidth: zoneText.implicitWidth + 16
                                    radius: 12
                                    color: {
                                        var z = root.getWidgetZoneStatus(root.selectedCustomizerWidget)
                                        if (z === "Start Zone") return Theme.alpha("#06b6d4", 0.20)
                                        if (z === "Center Zone") return Theme.alpha("#a855f7", 0.20)
                                        if (z === "End Zone") return Theme.alpha("#10b981", 0.20)
                                        return Theme.alpha(Theme.surface, 0.80)
                                    }
                                    border.width: 1
                                    border.color: {
                                        var z = root.getWidgetZoneStatus(root.selectedCustomizerWidget)
                                        if (z === "Start Zone") return "#06b6d4"
                                        if (z === "Center Zone") return "#a855f7"
                                        if (z === "End Zone") return "#10b981"
                                        return Theme.alpha(Theme.foreground, 0.25)
                                    }
                                    Text {
                                        id: zoneText
                                        anchors.centerIn: parent
                                        text: root.getWidgetZoneStatus(root.selectedCustomizerWidget)
                                        font.family: "Outfit"
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                        color: {
                                            var z = root.getWidgetZoneStatus(root.selectedCustomizerWidget)
                                            if (z === "Start Zone") return "#06b6d4"
                                            if (z === "Center Zone") return "#a855f7"
                                            if (z === "End Zone") return "#10b981"
                                            return Theme.alpha(Theme.foreground, 0.50)
                                        }
                                    }
                                }
                            }

                            // Divider
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Theme.alpha(Theme.foreground, 0.10)
                            }

                            // ── AUDIO SPECTRUM VISUALIZER OPTIONS ──────────
                            ColumnLayout {
                                visible: root.selectedCustomizerWidget === "visualizer"
                                Layout.fillWidth: true
                                spacing: 14

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Text {
                                        text: "Equalizer Bounce Baseline & Growth Direction"
                                        font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground
                                    }
                                    Text {
                                        text: "Orientation fix: Bottom Baseline ensures the equalizer bounces naturally UPWARDS from the bottom"
                                        font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55)
                                    }
                                    RowLayout {
                                        spacing: 8
                                        Repeater {
                                            model: [
                                                { id: "bottom", label: "Bottom Baseline (Upward Bounce) ✓" },
                                                { id: "center", label: "Centered (Outward Expansion)" },
                                                { id: "top", label: "Top Baseline (Downward)" }
                                            ]
                                            Rectangle {
                                                height: 32
                                                implicitWidth: modeText.implicitWidth + 24
                                                radius: 7
                                                color: root.getWidgetOption("visualizer", "alignment", "bottom") === modelData.id
                                                    ? Theme.accent
                                                    : Theme.alpha(Theme.surface, 0.8)
                                                border.width: 1
                                                border.color: root.getWidgetOption("visualizer", "alignment", "bottom") === modelData.id
                                                    ? Theme.accent
                                                    : Theme.alpha(Theme.foreground, 0.20)
                                                Text {
                                                    id: modeText
                                                    anchors.centerIn: parent
                                                    text: modelData.label
                                                    font.family: "Outfit"; font.pixelSize: 11
                                                    font.weight: root.getWidgetOption("visualizer", "alignment", "bottom") === modelData.id ? Font.Bold : Font.Medium
                                                    color: root.getWidgetOption("visualizer", "alignment", "bottom") === modelData.id ? Theme.on_primary : Theme.foreground
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.setWidgetOption("visualizer", "alignment", modelData.id)
                                                }
                                            }
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Number of Spectrum Bars"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: root.getWidgetOption("visualizer", "bars", 8) + " bars"
                                            font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 12; font.weight: Font.Bold; color: Theme.accent
                                        }
                                    }
                                    ModernSlider {
                                        Layout.fillWidth: true
                                        from: 4; to: 16; stepSize: 1
                                        value: root.getWidgetOption("visualizer", "bars", 8)
                                        onMoved: root.setWidgetOption("visualizer", "bars", Math.round(value))
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Bar Width (Thickness)"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: Number(root.getWidgetOption("visualizer", "bar_width", 3.0)).toFixed(1) + " px"
                                            font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 12; font.weight: Font.Bold; color: Theme.accent
                                        }
                                    }
                                    ModernSlider {
                                        Layout.fillWidth: true
                                        from: 2.0; to: 6.0; stepSize: 0.5
                                        value: root.getWidgetOption("visualizer", "bar_width", 3.0)
                                        onMoved: root.setWidgetOption("visualizer", "bar_width", parseFloat(value.toFixed(1)))
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Bar Gap / Spacing"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: Number(root.getWidgetOption("visualizer", "spacing", 2.5)).toFixed(1) + " px"
                                            font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 12; font.weight: Font.Bold; color: Theme.accent
                                        }
                                    }
                                    ModernSlider {
                                        Layout.fillWidth: true
                                        from: 1.5; to: 6.0; stepSize: 0.5
                                        value: root.getWidgetOption("visualizer", "spacing", 2.5)
                                        onMoved: root.setWidgetOption("visualizer", "spacing", parseFloat(value.toFixed(1)))
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Hide Visualizer When Idle"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Text { text: "Only show the visualizer module when music or audio is actively playing"; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                    }
                                    CapsuleSwitch {
                                        checked: !!root.getWidgetOption("visualizer", "hide_when_idle", false)
                                        onToggled: root.setWidgetOption("visualizer", "hide_when_idle", checked)
                                    }
                                }
                            }

                            // ── DYNAMIC WORKSPACES OPTIONS ─────────────────
                            ColumnLayout {
                                visible: root.selectedCustomizerWidget === "workspaces"
                                Layout.fillWidth: true
                                spacing: 14

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Text { text: "Workspace Symbol & Numbering Aesthetic"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                    Text { text: "Choose the visual character theme for workspace slots"; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                    RowLayout {
                                        spacing: 8
                                        Repeater {
                                            model: [
                                                { id: "kanji", label: "Kanji (一 二 三 四 五)" },
                                                { id: "number", label: "Arabic Numbers (1 2 3 4 5)" },
                                                { id: "glyph", label: "Sacred Glyphs (✦ ◈ ◆ ❖ ⬡)" },
                                                { id: "dot", label: "Minimal Dots (• • • • •)" }
                                            ]
                                            Rectangle {
                                                height: 32
                                                implicitWidth: wsOptText.implicitWidth + 24
                                                radius: 7
                                                color: root.getWidgetOption("workspaces", "style", "kanji") === modelData.id
                                                    ? Theme.accent
                                                    : Theme.alpha(Theme.surface, 0.8)
                                                border.width: 1
                                                border.color: root.getWidgetOption("workspaces", "style", "kanji") === modelData.id
                                                    ? Theme.accent
                                                    : Theme.alpha(Theme.foreground, 0.20)
                                                Text {
                                                    id: wsOptText
                                                    anchors.centerIn: parent
                                                    text: modelData.label
                                                    font.family: "Outfit"; font.pixelSize: 11
                                                    font.weight: root.getWidgetOption("workspaces", "style", "kanji") === modelData.id ? Font.Bold : Font.Medium
                                                    color: root.getWidgetOption("workspaces", "style", "kanji") === modelData.id ? Theme.on_primary : Theme.foreground
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.setWidgetOption("workspaces", "style", modelData.id)
                                                }
                                            }
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Visible Workspace Slot Count"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: root.getWidgetOption("workspaces", "count", 5) + " slots"
                                            font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 12; font.weight: Font.Bold; color: Theme.accent
                                        }
                                    }
                                    ModernSlider {
                                        Layout.fillWidth: true
                                        from: 3; to: 10; stepSize: 1
                                        value: root.getWidgetOption("workspaces", "count", 5)
                                        onMoved: root.setWidgetOption("workspaces", "count", Math.round(value))
                                    }
                                }
                            }

                            // ── CLOCK & CALENDAR OPTIONS ───────────────────
                            ColumnLayout {
                                visible: root.selectedCustomizerWidget === "clock"
                                Layout.fillWidth: true
                                spacing: 14

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "24-Hour Time Format"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Text { text: "Display time in 24-hour mode (14:30) instead of 12-hour AM/PM (02:30 PM)"; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                    }
                                    CapsuleSwitch {
                                        checked: !!root.getWidgetOption("clock", "format_24h", true)
                                        onToggled: root.setWidgetOption("clock", "format_24h", checked)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Show Live Seconds"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Text { text: "Show real-time seconds ticking counter in the clock display"; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                    }
                                    CapsuleSwitch {
                                        checked: !!root.getWidgetOption("clock", "show_seconds", false)
                                        onToggled: root.setWidgetOption("clock", "show_seconds", checked)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Show Calendar Date Chip"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Text { text: "Show abbreviated date badge (e.g. 'Mon, Nov 2') with subtle pulsing separator dot"; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                    }
                                    CapsuleSwitch {
                                        checked: root.getWidgetOption("clock", "show_date", true) !== false
                                        onToggled: root.setWidgetOption("clock", "show_date", checked)
                                    }
                                }
                            }

                            // ── ACTIVE WINDOW TITLE OPTIONS ────────────────
                            ColumnLayout {
                                visible: root.selectedCustomizerWidget === "active_window"
                                Layout.fillWidth: true
                                spacing: 14

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Max Title Characters (Truncation)"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: root.getWidgetOption("active_window", "max_length", 28) + " chars"
                                            font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 12; font.weight: Font.Bold; color: Theme.accent
                                        }
                                    }
                                    ModernSlider {
                                        Layout.fillWidth: true
                                        from: 12; to: 50; stepSize: 2
                                        value: root.getWidgetOption("active_window", "max_length", 28)
                                        onMoved: root.setWidgetOption("active_window", "max_length", Math.round(value))
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Show Application Vector Icon"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Text { text: "Show window/layout icon before the application title"; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                    }
                                    CapsuleSwitch {
                                        checked: root.getWidgetOption("active_window", "show_icon", true) !== false
                                        onToggled: root.setWidgetOption("active_window", "show_icon", checked)
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Text { text: "Fallback Title When Workspace is Empty"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                    RowLayout {
                                        spacing: 8
                                        Repeater {
                                            model: ["Desktop", "Hyprland", "Workspace", "Empty"]
                                            Rectangle {
                                                height: 30
                                                implicitWidth: fbText.implicitWidth + 20
                                                radius: 6
                                                color: root.getWidgetOption("active_window", "fallback", "Desktop") === modelData
                                                    ? Theme.accent
                                                    : Theme.alpha(Theme.surface, 0.8)
                                                border.width: 1
                                                border.color: root.getWidgetOption("active_window", "fallback", "Desktop") === modelData
                                                    ? Theme.accent
                                                    : Theme.alpha(Theme.foreground, 0.20)
                                                Text {
                                                    id: fbText
                                                    anchors.centerIn: parent
                                                    text: modelData
                                                    font.family: "Outfit"; font.pixelSize: 11
                                                    font.weight: root.getWidgetOption("active_window", "fallback", "Desktop") === modelData ? Font.Bold : Font.Medium
                                                    color: root.getWidgetOption("active_window", "fallback", "Desktop") === modelData ? Theme.on_primary : Theme.foreground
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.setWidgetOption("active_window", "fallback", modelData)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // ── BATTERY & AC POWER OPTIONS ─────────────────
                            ColumnLayout {
                                visible: root.selectedCustomizerWidget === "battery"
                                Layout.fillWidth: true
                                spacing: 14

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Show Percentage Value"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Text { text: "Display numerical battery percentage (e.g. '85%') beside the battery icon"; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                    }
                                    CapsuleSwitch {
                                        checked: root.getWidgetOption("battery", "show_percent", true) !== false
                                        onToggled: root.setWidgetOption("battery", "show_percent", checked)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Show on Desktop Systems (AC Power)"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Text { text: "Display AC bolt badge on desktop machines without a physical battery"; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                    }
                                    CapsuleSwitch {
                                        checked: root.getWidgetOption("battery", "show_on_desktop", true) !== false
                                        onToggled: root.setWidgetOption("battery", "show_on_desktop", checked)
                                    }
                                }
                            }

                            // ── NETWORK SPEED MONITOR OPTIONS ──────────────
                            ColumnLayout {
                                visible: root.selectedCustomizerWidget === "network"
                                Layout.fillWidth: true
                                spacing: 14

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Show Direction Arrows (↓ & ↑)"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Text { text: "Show colored arrow glyphs before download and upload speeds"; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                    }
                                    CapsuleSwitch {
                                        checked: root.getWidgetOption("network", "show_arrows", true) !== false
                                        onToggled: root.setWidgetOption("network", "show_arrows", checked)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Compact Mode (Download Speed Only)"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Text { text: "Only show download throughput to conserve horizontal space on the bar"; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                    }
                                    CapsuleSwitch {
                                        checked: !!root.getWidgetOption("network", "compact", false)
                                        onToggled: root.setWidgetOption("network", "compact", checked)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Show Network Vector Icon"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Text { text: "Display Wifi / Ethernet interface icon before the throughput readouts"; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                    }
                                    CapsuleSwitch {
                                        checked: root.getWidgetOption("network", "show_icon", true) !== false
                                        onToggled: root.setWidgetOption("network", "show_icon", checked)
                                    }
                                }
                            }

                            // ── SYSTEM MONITOR OPTIONS ─────────────────────
                            ColumnLayout {
                                visible: root.selectedCustomizerWidget === "system_info"
                                Layout.fillWidth: true
                                spacing: 14

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Show RAM Memory Load"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Text { text: "Display current memory usage in gigabytes (e.g. 'RAM 5.1G')"; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                    }
                                    CapsuleSwitch {
                                        checked: root.getWidgetOption("system_info", "show_ram", true) !== false
                                        onToggled: root.setWidgetOption("system_info", "show_ram", checked)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Show CPU Processor Load"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Text { text: "Display CPU utilization percentage (e.g. 'CPU 14%')"; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                    }
                                    CapsuleSwitch {
                                        checked: root.getWidgetOption("system_info", "show_cpu", true) !== false
                                        onToggled: root.setWidgetOption("system_info", "show_cpu", checked)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Show Root Disk Partition Usage"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Text { text: "Display disk space occupied on primary root partition (e.g. 'DISK 48G')"; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                    }
                                    CapsuleSwitch {
                                        checked: !!root.getWidgetOption("system_info", "show_disk", false)
                                        onToggled: root.setWidgetOption("system_info", "show_disk", checked)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Show Speedometer Gauge Icon"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Text { text: "Display gauge vector icon at the beginning of the metrics capsule"; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                    }
                                    CapsuleSwitch {
                                        checked: root.getWidgetOption("system_info", "show_icon", true) !== false
                                        onToggled: root.setWidgetOption("system_info", "show_icon", checked)
                                    }
                                }
                            }

                            // ── MEDIA PLAYER OPTIONS ───────────────────────
                            ColumnLayout {
                                visible: root.selectedCustomizerWidget === "media"
                                Layout.fillWidth: true
                                spacing: 14

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Max Track Characters (Truncation)"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: root.getWidgetOption("media", "max_length", 22) + " chars"
                                            font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 12; font.weight: Font.Bold; color: Theme.accent
                                        }
                                    }
                                    ModernSlider {
                                        Layout.fillWidth: true
                                        from: 12; to: 40; stepSize: 2
                                        value: root.getWidgetOption("media", "max_length", 22)
                                        onMoved: root.setWidgetOption("media", "max_length", Math.round(value))
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Show Artist Name Alongside Title"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Text { text: "Display 'Track • Artist' instead of track title only"; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                    }
                                    CapsuleSwitch {
                                        checked: root.getWidgetOption("media", "show_artist", true) !== false
                                        onToggled: root.setWidgetOption("media", "show_artist", checked)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Show Music Wave Vector Icon"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Text { text: "Display animated music wave vector icon"; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                    }
                                    CapsuleSwitch {
                                        checked: root.getWidgetOption("media", "show_icon", true) !== false
                                        onToggled: root.setWidgetOption("media", "show_icon", checked)
                                    }
                                }
                            }

                            // ── VOLUME CONTROLLER OPTIONS ──────────────────
                            ColumnLayout {
                                visible: root.selectedCustomizerWidget === "volume"
                                Layout.fillWidth: true
                                spacing: 14

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Mouse Wheel Scroll Step"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: root.getWidgetOption("volume", "scroll_step", 5) + "% per tick"
                                            font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 12; font.weight: Font.Bold; color: Theme.accent
                                        }
                                    }
                                    ModernSlider {
                                        Layout.fillWidth: true
                                        from: 1; to: 10; stepSize: 1
                                        value: root.getWidgetOption("volume", "scroll_step", 5)
                                        onMoved: root.setWidgetOption("volume", "scroll_step", Math.round(value))
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Show Percentage Text (e.g. '65%')"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Text { text: "Display numerical volume percentage readout"; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                    }
                                    CapsuleSwitch {
                                        checked: root.getWidgetOption("volume", "show_percent", true) !== false
                                        onToggled: root.setWidgetOption("volume", "show_percent", checked)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Show Mini Level Fill Bar"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Text { text: "Display 28px horizontal fill gauge showing volume level"; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                    }
                                    CapsuleSwitch {
                                        checked: root.getWidgetOption("volume", "show_bar", true) !== false
                                        onToggled: root.setWidgetOption("volume", "show_bar", checked)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Show Speaker Vector Icon"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Text { text: "Display speaker / mute icon"; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                    }
                                    CapsuleSwitch {
                                        checked: root.getWidgetOption("volume", "show_icon", true) !== false
                                        onToggled: root.setWidgetOption("volume", "show_icon", checked)
                                    }
                                }
                            }

                            // ── LIVE WEATHER OPTIONS ───────────────────────
                            ColumnLayout {
                                visible: root.selectedCustomizerWidget === "weather"
                                Layout.fillWidth: true
                                spacing: 14

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Text { text: "Temperature Measurement Unit"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                    RowLayout {
                                        spacing: 8
                                        Repeater {
                                            model: [
                                                { id: false, label: "Celsius (°C)" },
                                                { id: true, label: "Fahrenheit (°F)" }
                                            ]
                                            Rectangle {
                                                height: 32
                                                implicitWidth: unitText.implicitWidth + 24
                                                radius: 7
                                                color: Boolean(root.getWidgetOption("weather", "unit_f", false)) === modelData.id
                                                    ? Theme.accent
                                                    : Theme.alpha(Theme.surface, 0.8)
                                                border.width: 1
                                                border.color: Boolean(root.getWidgetOption("weather", "unit_f", false)) === modelData.id
                                                    ? Theme.accent
                                                    : Theme.alpha(Theme.foreground, 0.20)
                                                Text {
                                                    id: unitText
                                                    anchors.centerIn: parent
                                                    text: modelData.label
                                                    font.family: "Outfit"; font.pixelSize: 11
                                                    font.weight: Boolean(root.getWidgetOption("weather", "unit_f", false)) === modelData.id ? Font.Bold : Font.Medium
                                                    color: Boolean(root.getWidgetOption("weather", "unit_f", false)) === modelData.id ? Theme.on_primary : Theme.foreground
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.setWidgetOption("weather", "unit_f", modelData.id)
                                                }
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Always Show Condition Label"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Text { text: "Keep weather description ('Clear sky', 'Rainy') expanded without needing to hover"; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                    }
                                    CapsuleSwitch {
                                        checked: !!root.getWidgetOption("weather", "show_condition_always", false)
                                        onToggled: root.setWidgetOption("weather", "show_condition_always", checked)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Show Weather Vector Icon"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Text { text: "Display sun / moon / cloud glyph"; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                    }
                                    CapsuleSwitch {
                                        checked: root.getWidgetOption("weather", "show_icon", true) !== false
                                        onToggled: root.setWidgetOption("weather", "show_icon", checked)
                                    }
                                }
                            }

                            // ── DO NOT DISTURB (DND) OPTIONS ───────────────
                            ColumnLayout {
                                visible: root.selectedCustomizerWidget === "dnd"
                                Layout.fillWidth: true
                                spacing: 14

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Text { text: "Pill Label Mode"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                    RowLayout {
                                        spacing: 8
                                        Repeater {
                                            model: [
                                                { id: "full", label: "Full (DND ON / DND)" },
                                                { id: "compact", label: "Compact (ON / OFF)" },
                                                { id: "icon_only", label: "Icon Only" }
                                            ]
                                            Rectangle {
                                                height: 32
                                                implicitWidth: dndText.implicitWidth + 24
                                                radius: 7
                                                color: root.getWidgetOption("dnd", "label_mode", "full") === modelData.id
                                                    ? Theme.accent
                                                    : Theme.alpha(Theme.surface, 0.8)
                                                border.width: 1
                                                border.color: root.getWidgetOption("dnd", "label_mode", "full") === modelData.id
                                                    ? Theme.accent
                                                    : Theme.alpha(Theme.foreground, 0.20)
                                                Text {
                                                    id: dndText
                                                    anchors.centerIn: parent
                                                    text: modelData.label
                                                    font.family: "Outfit"; font.pixelSize: 11
                                                    font.weight: root.getWidgetOption("dnd", "label_mode", "full") === modelData.id ? Font.Bold : Font.Medium
                                                    color: root.getWidgetOption("dnd", "label_mode", "full") === modelData.id ? Theme.on_primary : Theme.foreground
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.setWidgetOption("dnd", "label_mode", modelData.id)
                                                }
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Show Bell Vector Icon"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Text { text: "Display bell / silenced bell vector icon"; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                    }
                                    CapsuleSwitch {
                                        checked: root.getWidgetOption("dnd", "show_icon", true) !== false
                                        onToggled: root.setWidgetOption("dnd", "show_icon", checked)
                                    }
                                }
                            }

                            // ── PACKAGE UPDATES OPTIONS ────────────────────
                            ColumnLayout {
                                visible: root.selectedCustomizerWidget === "pkg_update"
                                Layout.fillWidth: true
                                spacing: 14

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: "Auto-Hide When 0 Pending Updates"; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.foreground }
                                        Text { text: "Conceal this module from the bar when your system has zero pending packages"; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                    }
                                    CapsuleSwitch {
                                        checked: !!root.getWidgetOption("pkg_update", "hide_when_zero", false)
                                        onToggled: root.setWidgetOption("pkg_update", "hide_when_zero", checked)
                                    }
                                }
                            }

                            // ── NATIVE SYSTEM MODULE FALLBACK INFO ─────────
                            ColumnLayout {
                                visible: ["visualizer", "workspaces", "clock", "active_window", "battery", "network", "system_info", "media", "volume", "weather", "dnd", "pkg_update"].indexOf(root.selectedCustomizerWidget) === -1
                                Layout.fillWidth: true
                                spacing: 10

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 64
                                    radius: 8
                                    color: Theme.alpha(Theme.surface, 0.6)
                                    border.width: 1
                                    border.color: Theme.alpha(Theme.accent, 0.20)
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 12
                                        Image {
                                            width: 20; height: 20
                                            source: root.getWidgetSvg(root.selectedCustomizerWidget)
                                        }
                                        Column {
                                            Layout.fillWidth: true
                                            spacing: 2
                                            Text { text: "Native System Module"; font.family: "Outfit"; font.pixelSize: 13; font.bold: true; color: Theme.foreground }
                                            Text { text: "This module uses system-level triggers (Hyprland IPC, system tray, or daemon scripts) and automatically manages its state."; font.family: "Outfit"; font.pixelSize: 11; color: Theme.alpha(Theme.foreground, 0.55) }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            SettingCard {
                title: "Capsule Aesthetics"
                description: "Choose between solid accent color fill or translucent obsidian glass"

                RowLayout {
                    width: parent.width
                    spacing: 12

                    // Option 1: Accent Fill
                    // Option 1: Floating Islands
                    Rectangle {
                        Layout.fillWidth: true
                        height: 54
                        radius: 10
                        color: root.capsuleStyle === "islands" ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surface, 0.60)
                        border.width: root.capsuleStyle === "islands" ? 2 : 1
                        border.color: root.capsuleStyle === "islands" ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            Row {
                                spacing: 3
                                Rectangle { width: 10; height: 22; radius: 5; color: Theme.alpha(Theme.surface, 0.90); border.width: 1; border.color: Theme.accent }
                                Rectangle { width: 12; height: 22; radius: 5; color: Theme.alpha(Theme.surface, 0.90); border.width: 1; border.color: Theme.accent }
                                Rectangle { width: 10; height: 22; radius: 5; color: Theme.alpha(Theme.surface, 0.90); border.width: 1; border.color: Theme.accent }
                            }
                            Column {
                                Layout.fillWidth: true
                                Text { text: "Floating Islands"; color: Theme.foreground; font.bold: true; font.pixelSize: 12 }
                                Text { text: "3 modular floating obsidian glass wings with transparent gaps"; color: Theme.muted; font.pixelSize: 10 }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.capsuleStyle = "islands"
                                root.triggerAutoSave()
                            }
                        }
                    }

                    // Option 2: Obsidian Glass
                    Rectangle {
                        Layout.fillWidth: true
                        height: 54
                        radius: 10
                        color: root.capsuleStyle === "glass" ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surface, 0.60)
                        border.width: root.capsuleStyle === "glass" ? 2 : 1
                        border.color: root.capsuleStyle === "glass" ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            Rectangle {
                                width: 28; height: 28; radius: 14
                                color: Theme.alpha(Theme.surface, 0.85)
                                border.width: 1.5
                                border.color: Theme.accent
                            }
                            Column {
                                Layout.fillWidth: true
                                Text { text: "Continuous Glass Shelf"; color: Theme.foreground; font.bold: true; font.pixelSize: 12 }
                                Text { text: "Single floating translucent obsidian bar across the top"; color: Theme.muted; font.pixelSize: 10 }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.capsuleStyle = "glass"
                                root.triggerAutoSave()
                            }
                        }
                    }
                }
            }

            // ── TRAIL STREAM STYLE ───────────────────────────────────────────
            SettingCard {
                title: "Trail Stream Bridge"
                description: "Subtle animated particle bridges connecting the floating islands (active in Floating Islands mode)"

                RowLayout {
                    width: parent.width
                    spacing: 12

                    // Option 1: Matrix Stream
                    Rectangle {
                        Layout.fillWidth: true
                        height: 58
                        radius: 10
                        color: root.trailStyle === "matrix" ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surface, 0.60)
                        border.width: root.trailStyle === "matrix" ? 2 : 1
                        border.color: root.trailStyle === "matrix" ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Rectangle {
                                width: 28; height: 28; radius: 14
                                color: Theme.alpha(Theme.accent, 0.20)
                                border.width: 1.5; border.color: Theme.accent
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 3
                                    Rectangle { width: 3; height: 12; radius: 1.5; color: Theme.accent }
                                    Rectangle { width: 3; height: 18; radius: 1.5; color: Theme.accent }
                                    Rectangle { width: 3; height: 8; radius: 1.5; color: Theme.accent }
                                }
                            }
                            Column {
                                Layout.fillWidth: true
                                Text { text: "Matrix Stream"; color: Theme.foreground; font.bold: true; font.pixelSize: 12 }
                                Text { text: "Cybernetic glowing neon accent pulses & floating data nodes"; color: Theme.muted; font.pixelSize: 10; elide: Text.ElideRight; width: parent.width }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.trailStyle = "matrix"
                                root.triggerAutoSave()
                            }
                        }
                    }

                    // Option 2: Thunder Storm
                    Rectangle {
                        Layout.fillWidth: true
                        height: 58
                        radius: 10
                        color: (root.trailStyle === "thunder" || root.trailStyle === "storm") ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.60)
                        border.width: (root.trailStyle === "thunder" || root.trailStyle === "storm") ? 2 : 1
                        border.color: (root.trailStyle === "thunder" || root.trailStyle === "storm") ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Rectangle {
                                width: 28; height: 28; radius: 14
                                color: Theme.alpha(Theme.accent, 0.20)
                                border.width: 1.5; border.color: Theme.accent
                                Image {
                                    anchors.centerIn: parent
                                    width: 14; height: 14
                                    source: root.zapSvg
                                }
                            }
                            Column {
                                Layout.fillWidth: true
                                Text { text: "Thunder Storm"; color: Theme.foreground; font.bold: true; font.pixelSize: 12 }
                                Text { text: "Braided harmonic electric sine wave, travelling plasma spark & storm surge"; color: Theme.muted; font.pixelSize: 10; elide: Text.ElideRight; width: parent.width }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.trailStyle = "thunder"
                                root.triggerAutoSave()
                            }
                        }
                    }

                    // Option 3: None / Clean Gaps
                    Rectangle {
                        Layout.fillWidth: true
                        height: 58
                        radius: 10
                        color: root.trailStyle === "none" ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surface, 0.60)
                        border.width: root.trailStyle === "none" ? 2 : 1
                        border.color: root.trailStyle === "none" ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Rectangle {
                                width: 28; height: 28; radius: 14
                                color: Theme.alpha(Theme.surface, 0.85)
                                border.width: 1; border.color: Theme.alpha(Theme.foreground, 0.2)
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 12; height: 2; radius: 1
                                    color: Theme.muted
                                }
                            }
                            Column {
                                Layout.fillWidth: true
                                Text { text: "Clean Gaps (None)"; color: Theme.foreground; font.bold: true; font.pixelSize: 12 }
                                Text { text: "Clean gap spacing between islands without trails"; color: Theme.muted; font.pixelSize: 10; elide: Text.ElideRight; width: parent.width }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.trailStyle = "none"
                                root.triggerAutoSave()
                            }
                        }
                    }
                }
            }

            // ── DIMENSIONS & GEOMETRY SLIDERS ───────────────────────────────
            SettingCard {
                title: "Dimensions, Padding & Margins"
                description: "Fine-tune bar thickness, screen margins, capsule spacing and corner radii"

                Column {
                    width: parent.width
                    spacing: 14

                    // Bar Height
                    Column {
                        width: parent.width
                        spacing: 4
                        RowLayout {
                            width: parent.width
                            Text { text: "Bar Thickness / Height"; color: Theme.foreground; font.pixelSize: 12 }
                            Item { Layout.fillWidth: true }
                            Text { text: root.barHeight + " px"; color: Theme.accent; font.bold: true; font.pixelSize: 12 }
                        }
                        ModernSlider {
                            width: parent.width
                            from: 28
                            to: 52
                            stepSize: 1
                            value: root.barHeight
                            onMoved: { root.barHeight = Math.round(value); root.triggerAutoSave(); }
                        }
                    }

                    // Top Margin
                    Column {
                        width: parent.width
                        spacing: 4
                        RowLayout {
                            width: parent.width
                            Text { text: "Top Margin (Edge Gap)"; color: Theme.foreground; font.pixelSize: 12 }
                            Item { Layout.fillWidth: true }
                            Text { text: root.marginTop + " px"; color: Theme.accent; font.bold: true; font.pixelSize: 12 }
                        }
                        ModernSlider {
                            width: parent.width
                            from: 0
                            to: 24
                            stepSize: 1
                            value: root.marginTop
                            onMoved: { root.marginTop = Math.round(value); root.triggerAutoSave(); }
                        }
                    }

                    // Side Margins
                    Column {
                        width: parent.width
                        spacing: 4
                        RowLayout {
                            width: parent.width
                            Text { text: "Side Margins (Left & Right)"; color: Theme.foreground; font.pixelSize: 12 }
                            Item { Layout.fillWidth: true }
                            Text { text: root.marginSides + " px"; color: Theme.accent; font.bold: true; font.pixelSize: 12 }
                        }
                        ModernSlider {
                            width: parent.width
                            from: 0
                            to: 48
                            stepSize: 1
                            value: root.marginSides
                            onMoved: { root.marginSides = Math.round(value); root.triggerAutoSave(); }
                        }
                    }

                    // Capsule Corner Radius
                    Column {
                        width: parent.width
                        spacing: 4
                        RowLayout {
                            width: parent.width
                            Text { text: "Capsule Corner Radius"; color: Theme.foreground; font.pixelSize: 12 }
                            Item { Layout.fillWidth: true }
                            Text { text: root.capsuleRadius + " px"; color: Theme.accent; font.bold: true; font.pixelSize: 12 }
                        }
                        ModernSlider {
                            width: parent.width
                            from: 4
                            to: 24
                            stepSize: 1
                            value: root.capsuleRadius
                            onMoved: { root.capsuleRadius = Math.round(value); root.triggerAutoSave(); }
                        }
                    }

                    // Capsule Horizontal Padding
                    Column {
                        width: parent.width
                        spacing: 4
                        RowLayout {
                            width: parent.width
                            Text { text: "Capsule Inner Padding"; color: Theme.foreground; font.pixelSize: 12 }
                            Item { Layout.fillWidth: true }
                            Text { text: root.capsulePadding + " px"; color: Theme.accent; font.bold: true; font.pixelSize: 12 }
                        }
                        ModernSlider {
                            width: parent.width
                            from: 4
                            to: 20
                            stepSize: 1
                            value: root.capsulePadding
                            onMoved: { root.capsulePadding = Math.round(value); root.triggerAutoSave(); }
                        }
                    }

                    // Widget Spacing
                    Column {
                        width: parent.width
                        spacing: 4
                        RowLayout {
                            width: parent.width
                            Text { text: "Widget Capsule Spacing"; color: Theme.foreground; font.pixelSize: 12 }
                            Item { Layout.fillWidth: true }
                            Text { text: root.widgetSpacing + " px"; color: Theme.accent; font.bold: true; font.pixelSize: 12 }
                        }
                        ModernSlider {
                            width: parent.width
                            from: 2
                            to: 24
                            stepSize: 1
                            value: root.widgetSpacing
                            onMoved: { root.widgetSpacing = Math.round(value); root.triggerAutoSave(); }
                        }
                    }

                    // Bar Opacity
                    Column {
                        width: parent.width
                        spacing: 4
                        RowLayout {
                            width: parent.width
                            Text { text: "Bar Background Opacity"; color: Theme.foreground; font.pixelSize: 12 }
                            Item { Layout.fillWidth: true }
                            Text { text: Math.round(root.barOpacity * 100) + " %"; color: Theme.accent; font.bold: true; font.pixelSize: 12 }
                        }
                        ModernSlider {
                            width: parent.width
                            from: 0.10
                            to: 1.0
                            stepSize: 0.05
                            value: root.barOpacity
                            onMoved: { root.barOpacity = parseFloat(value.toFixed(2)); root.triggerAutoSave(); }
                        }
                    }
                }
            }

            // ── BEHAVIOR OPTIONS ────────────────────────────────────────────
            SettingCard {
                title: "Behavior & Package Updates"
                description: "Optional visibility controls for modules"

                RowLayout {
                    width: parent.width
                    Column {
                        Layout.fillWidth: true
                        Text { text: "Hide Package Updates Pill When 0"; color: Theme.foreground; font.pixelSize: 13 }
                        Text { text: "Only show the update indicator when pending packages exist"; color: Theme.muted; font.pixelSize: 11 }
                    }
                    CapsuleSwitch {
                        checked: root.hidePkgWhenEmpty
                        onToggled: {
                            root.hidePkgWhenEmpty = checked
                            root.triggerAutoSave()
                        }
                    }
                }
            }
        }
    }

    // ── ADD MODULE MODAL DIALOG ─────────────────────────────────────────────
    Rectangle {
        id: addDialog
        visible: root.showAddDialog
        anchors.fill: parent
        color: "#90000000"
        z: 99

        MouseArea {
            anchors.fill: parent
            onClicked: root.showAddDialog = false
        }

        Rectangle {
            width: 530
            height: 620
            radius: 16
            color: Theme.alpha(Theme.surface, 0.98)
            border.width: 1
            border.color: Theme.alpha(Theme.accent, 0.45)
            anchors.centerIn: parent

            MouseArea { anchors.fill: parent } // Prevent click-through

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                // ── Dialog Header ───────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        width: 36; height: 36; radius: 10
                        color: Theme.alpha(Theme.accent, 0.20)
                        border.width: 1; border.color: Theme.accent
                        Image {
                            anchors.centerIn: parent
                            width: 18; height: 18
                            source: root.plusSvg
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: "Add Widget to " + (root.addTargetZone === "start" ? "Start (Left)" : (root.addTargetZone === "center" ? "Center" : "End (Right)"))
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.bold: true
                            font.pixelSize: 16
                        }
                        Text {
                            text: "Select a module from the 21-widget catalog to append to this zone"
                            color: Theme.alpha(Theme.foreground, 0.60)
                            font.family: "Outfit"
                            font.pixelSize: 11
                        }
                    }

                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: closeMouse.containsMouse ? Theme.alpha(Theme.error, 0.30) : Theme.alpha(Theme.surface, 0.8)
                        border.width: 1; border.color: Theme.alpha(Theme.foreground, 0.15)
                        Text { anchors.centerIn: parent; text: "✕"; color: closeMouse.containsMouse ? Theme.error : Theme.muted; font.pixelSize: 12 }
                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showAddDialog = false
                        }
                    }
                }

                // ── Search Bar ──────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 10
                    color: Theme.alpha(Theme.background, 0.85)
                    border.width: 1
                    border.color: searchInput.activeFocus ? Theme.accent : Theme.alpha(Theme.accent, 0.25)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Image {
                            width: 14; height: 14
                            source: root.searchSvg
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            text: root.addSearchQuery
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 12
                            clip: true
                            selectByMouse: true
                            onTextChanged: root.addSearchQuery = text

                            Text {
                                anchors.fill: parent
                                text: "Search by name, description, or category..."
                                color: Theme.alpha(Theme.foreground, 0.35)
                                font.family: "Outfit"
                                font.pixelSize: 12
                                visible: !searchInput.text && !searchInput.activeFocus
                            }
                        }

                        Rectangle {
                            width: 20; height: 20; radius: 10
                            color: "transparent"
                            visible: root.addSearchQuery.length > 0
                            Text { anchors.centerIn: parent; text: "✕"; color: Theme.muted; font.pixelSize: 10 }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.addSearchQuery = ""
                                    searchInput.text = ""
                                }
                            }
                        }
                    }
                }

                // ── Category Filter Pills ───────────────────────────────────
                Flickable {
                    Layout.fillWidth: true
                    height: 30
                    contentWidth: catRow.implicitWidth
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: catRow
                        spacing: 6

                        Repeater {
                            model: root.categoryList
                            delegate: Rectangle {
                                required property string modelData
                                readonly property bool isSelected: root.addSelectedCategory === modelData
                                height: 28
                                implicitWidth: catText.implicitWidth + 18
                                radius: 14
                                color: isSelected
                                    ? Theme.accent
                                    : (catMouse.containsMouse ? Theme.alpha(Theme.accent, 0.18) : Theme.alpha(Theme.surface, 0.60))
                                border.width: 1
                                border.color: isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    id: catText
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: isSelected ? Theme.on_primary : Theme.foreground
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    font.weight: isSelected ? Font.DemiBold : Font.Normal
                                }

                                MouseArea {
                                    id: catMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.addSelectedCategory = modelData
                                }
                            }
                        }
                    }
                }

                // ── Scrollable Widget List ──────────────────────────────────
                ListView {
                    id: widgetListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 8
                    model: root.filteredWidgets

                    // Empty State indicator
                    Item {
                        anchors.centerIn: parent
                        width: parent.width
                        height: 100
                        visible: widgetListView.count === 0

                        Column {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "No widgets match your search"
                                color: Theme.alpha(Theme.foreground, 0.50)
                                font.family: "Outfit"
                                font.pixelSize: 13
                                font.bold: true
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Try clearing search filters or selecting 'All'"
                                color: Theme.alpha(Theme.foreground, 0.35)
                                font.family: "Outfit"
                                font.pixelSize: 11
                            }
                        }
                    }

                    delegate: Rectangle {
                        id: widgetDelegate
                        required property var modelData
                        readonly property bool inThisZone: root.isWidgetInZone(modelData.id, root.addTargetZone)
                        readonly property string inOtherZone: root.getWidgetZone(modelData.id)

                        width: ListView.view.width
                        height: 56
                        radius: 12
                        color: itemMouse.containsMouse ? Theme.alpha(Theme.accent, 0.15) : Theme.alpha(Theme.surface, 0.70)
                        border.width: 1
                        border.color: itemMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.10)
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            // Widget Icon Badge
                            Rectangle {
                                width: 36; height: 36; radius: 9
                                color: Theme.alpha(Theme.accent, 0.20)
                                border.width: 1; border.color: Theme.alpha(Theme.accent, 0.38)
                                Image {
                                    anchors.centerIn: parent
                                    width: 18; height: 18
                                    source: root.getWidgetSvg(modelData.id)
                                }
                            }

                            // Widget Info
                            Column {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    spacing: 6
                                    Text {
                                        text: modelData.name
                                        color: Theme.foreground
                                        font.family: "Outfit"
                                        font.bold: true
                                        font.pixelSize: 13
                                    }

                                    // NEW Badge
                                    Rectangle {
                                        visible: !!modelData.isNew
                                        width: 34; height: 16; radius: 8
                                        color: Theme.accent
                                        Text {
                                            anchors.centerIn: parent
                                            text: "NEW"
                                            color: Theme.on_primary
                                            font.family: "Outfit"
                                            font.pixelSize: 8
                                            font.bold: true
                                        }
                                    }
                                }

                                Text {
                                    width: parent.width
                                    text: modelData.desc
                                    color: Theme.alpha(Theme.foreground, 0.60)
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }
                            }

                            // Placement Status Indicator
                            Rectangle {
                                visible: widgetDelegate.inThisZone || widgetDelegate.inOtherZone.length > 0
                                height: 22
                                implicitWidth: statusTxt.implicitWidth + 12
                                radius: 6
                                color: widgetDelegate.inThisZone ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.90)
                                border.width: 1
                                border.color: widgetDelegate.inThisZone ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)

                                Text {
                                    id: statusTxt
                                    anchors.centerIn: parent
                                    text: widgetDelegate.inThisZone ? "In This Zone" : ("In " + widgetDelegate.inOtherZone)
                                    color: widgetDelegate.inThisZone ? Theme.accent : Theme.alpha(Theme.foreground, 0.60)
                                    font.family: "Outfit"
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }

                            // Add Button
                            Rectangle {
                                width: 66
                                height: 30
                                radius: 8
                                color: btnMouse.containsMouse ? Theme.primary : Theme.accent
                                Behavior on color { ColorAnimation { duration: 100 } }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Image {
                                        width: 10; height: 10
                                        source: root.plusOnAccentSvg
                                    }
                                    Text {
                                        text: "Add"
                                        color: Theme.on_primary
                                        font.family: "Outfit"
                                        font.bold: true
                                        font.pixelSize: 11
                                    }
                                }

                                MouseArea {
                                    id: btnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.addWidget(root.addTargetZone, modelData.id)
                                }
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            z: -1
                            onClicked: root.addWidget(root.addTargetZone, modelData.id)
                        }
                    }
                }

                // ── Dialog Footer ───────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        Layout.fillWidth: true
                        text: widgetListView.count + " modules available • Click Add or any row to append"
                        color: Theme.alpha(Theme.foreground, 0.40)
                        font.family: "Outfit"
                        font.pixelSize: 10
                    }
                    Text {
                        text: "Hyprconf v1.0.2"
                        color: Theme.alpha(Theme.accent, 0.50)
                        font.family: "Outfit"
                        font.pixelSize: 10
                    }
                }
            }
        }
    }
}
