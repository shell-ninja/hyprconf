//@ pragma Env QS_NO_RELOAD_POPUP=1
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "."

ShellRoot {
    id: root

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    readonly property string dockConfigPath: homeDir + "/.hyprconf/quickshell/dock/dock.json"
    readonly property string appsCachePath: homeDir + "/.hyprconf/hypr/.cache/apps.json"

    // ── DOCK CONFIGURATION STATE ─────────────────────────────────────────────
    property var config: ({
        "enabled": true,
        "mode": "smart_hide",       // "always_on" | "auto_hide" | "smart_hide"
        "position": "bottom",       // "bottom" | "top" | "left" | "right"
        "bg_opacity": 0.85,
        "icon_size": 48,
        "dock_padding": 8,
        "corner_radius": 22,
        "hover_effect": "zoom",     // "zoom" | "lift" | "glow" | "subtle" | "none"
        "show_tooltips": true,
        "hide_delay": 350,
        "show_launcher": true,
        "show_indicators": true,
        "border_glow": true,
        "pinned_apps": []
    })

    property var allApps: []
    property var pinnedItems: []
    property var unpinnedItems: []
    property int currentWsWindowCount: 0
    property int activeWorkspaceId: 1
    signal closeAllMenus()

    onActiveWorkspaceIdChanged: {
        root.updateDockItems()
    }

    Process {
        id: initWsLoader
        command: ["hyprctl", "activeworkspace", "-j"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var obj = JSON.parse(text.trim())
                    if (obj && obj.id !== undefined && obj.id > 0) {
                        root.activeWorkspaceId = obj.id
                    }
                } catch(e) {}
            }
        }
    }

    // ── READ APPS CACHE ──────────────────────────────────────────────────────
    Process {
        id: appsLoader
        command: ["python3", "-c", "import json, os; p=os.path.expanduser('~/.hyprconf/hypr/.cache/apps.json'); print(open(p, encoding='utf-8').read() if os.path.exists(p) else '[]')"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    root.allApps = JSON.parse(text.trim())
                    root.updateDockItems()
                } catch(e) {
                    console.log("[dock] Failed to parse apps.json:", e)
                }
            }
        }
    }

    // ── READ DOCK CONFIG ─────────────────────────────────────────────────────
    Process {
        id: configReader
        command: ["python3", "-c", "import json, os; p1=os.path.expanduser('~/.local/share/hyprconf/dock.json'); p2=os.path.expanduser('~/.hyprconf/quickshell/dock/dock.json'); p=p1 if os.path.exists(p1) else p2; print(open(p, encoding='utf-8').read() if os.path.exists(p) else '{}')"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var parsed = JSON.parse(text.trim())
                    var cfg = Object.assign({}, root.config, parsed)
                    if (cfg.enabled === undefined) cfg.enabled = true
                    if (!cfg.pinned_apps) cfg.pinned_apps = []
                    root.config = cfg
                    root.updateDockItems()
                } catch(e) {
                    console.log("[dock] Failed to parse dock.json:", e)
                }
            }
        }
    }

    // ── SAVE DOCK CONFIG ─────────────────────────────────────────────────────
    Process {
        id: configWriter
        onExited: {
            root.updateDockItems()
        }
    }

    function saveDockConfig(newConfig) {
        root.config = newConfig
        var jsonStr = JSON.stringify(newConfig, null, 2)
        var pyScript = "import json, os\nfor p in [os.path.expanduser('~/.local/share/hyprconf/dock.json'), os.path.expanduser('~/.hyprconf/quickshell/dock/dock.json')]:\n    try:\n        os.makedirs(os.path.dirname(p), exist_ok=True)\n        with open(p, 'w', encoding='utf-8') as f: f.write('''" + jsonStr + "''')\n    except Exception as e: print(e)\n"
        configWriter.command = ["python3", "-c", pyScript]
        configWriter.running = true
    }

    // ── IPC HANDLER FOR REMOTE RELOAD / TOGGLE ──────────────────────────────
    IpcHandler {
        target: "dock"
        property int activeWs: root.activeWorkspaceId
        property int wsWinCount: root.currentWsWindowCount

        function reloadConfig() {
            configReader.running = true
            appsLoader.running = true
            Hyprland.refreshToplevels()
            Hyprland.refreshWorkspaces()
            Hyprland.refreshMonitors()
        }
        function toggle() {
            var c = Object.assign({}, root.config)
            c.enabled = !c.enabled
            root.saveDockConfig(c)
        }
    }

    // ── LAUNCH DETACHED APPLICATION ─────────────────────────────────────────
    Process {
        id: appLauncherProc
    }

    function launchApp(appId, execCmd) {
        appLauncherProc.command = [homeDir + "/.hyprconf/hypr/scripts/sh/launch-app.sh", appId || "", execCmd || ""]
        appLauncherProc.running = true
    }

    // ── TOGGLE QUICK APP LAUNCHER ───────────────────────────────────────────
    Process {
        id: qsLauncherProc
        command: [homeDir + "/.hyprconf/hypr/scripts/sh/qs-launcher.sh"]
    }

    function openLauncher() {
        qsLauncherProc.running = true
    }

    // ── MATCH HYPRLAND TOPLEVEL TO INSTALLED APPS ───────────────────────────
    function findAppForClass(cls, title) {
        if (!cls) return null
        var clsLower = cls.toLowerCase()

        // 1. Exact desktop file match
        for (var i = 0; i < root.allApps.length; i++) {
            var a = root.allApps[i]
            var baseId = (a.id || "").toLowerCase().replace(".desktop", "")
            if (baseId === clsLower) return a
        }

        // 2. Icon name match
        for (var i = 0; i < root.allApps.length; i++) {
            var a = root.allApps[i]
            if ((a.icon || "").toLowerCase() === clsLower) return a
        }

        // 3. Executable match
        for (var i = 0; i < root.allApps.length; i++) {
            var a = root.allApps[i]
            var ex = (a.exec || "").trim().split(/\s+/)[0].toLowerCase()
            var exBase = ex.split("/").pop()
            if (exBase === clsLower) return a
        }

        // 4. Substring in id or exec
        for (var i = 0; i < root.allApps.length; i++) {
            var a = root.allApps[i]
            var baseId = (a.id || "").toLowerCase().replace(".desktop", "")
            if (clsLower.indexOf(baseId) !== -1 || baseId.indexOf(clsLower) !== -1) return a
        }

        return null
    }

    function getActiveWorkspaceId() {
        if (root.activeWorkspaceId > 0) {
            return root.activeWorkspaceId
        }
        var mons = Hyprland.monitors ? Hyprland.monitors.values : []
        for (var i = 0; i < mons.length; i++) {
            var m = mons[i]
            var obj = m.lastIpcObject
            if (obj && (obj.focused || mons.length === 1)) {
                if (obj.activeWorkspace && obj.activeWorkspace.id !== undefined) {
                    return obj.activeWorkspace.id
                }
            }
        }
        return 1
    }

    // ── UPDATE DOCK ITEMS (PINNED + RUNNING) ─────────────────────────────────
    function resolveAppIcon(p) {
        var raw = p.icon_path || ""
        if (raw) {
            if (raw.indexOf("/home/") !== -1) {
                return raw.replace(/file:\/\/\/home\/[^\/]+/, "file://" + root.homeDir).replace(/\/home\/[^\/]+/, root.homeDir)
            }
            if (raw.startsWith("file://~") || raw.startsWith("~")) {
                return "file://" + root.homeDir + raw.replace(/^file:\/\/~/, "").replace(/^~/, "")
            }
            return raw
        }
        var resolved = findAppForClass((p.id || "").replace(".desktop", ""), p.name)
        return resolved && resolved.icon_path ? resolved.icon_path : ""
    }

    function updateDockItems() {
        var pinnedList = root.config.pinned_apps || []
        var pItems = []

        // Initialize pinned items
        for (var i = 0; i < pinnedList.length; i++) {
            var p = pinnedList[i]
            pItems.push({
                id: p.id || "",
                name: p.name || "App",
                exec: p.exec || "",
                icon: p.icon || "",
                icon_path: resolveAppIcon(p),
                match: p.match || [(p.id || "").replace(".desktop", ""), (p.exec || "").split(" ")[0]],
                isPinned: true,
                isRunning: false,
                isActive: false,
                windowCount: 0,
                windows: []
            })
        }

        var unpinnedMap = {}
        var toplevels = Hyprland.toplevels ? Hyprland.toplevels.values : []
        var activeWsId = root.getActiveWorkspaceId()
        var wsWinCount = 0

        for (var t = 0; t < toplevels.length; t++) {
            var tl = toplevels[t]
            var addr = tl.address
            var title = tl.title || ""
            var obj = tl.lastIpcObject
            var cls = (obj ? obj["class"] : "") || ""
            var initialCls = (obj ? obj["initialClass"] : "") || ""
            var activated = tl.activated
            var wsId = (obj && obj.workspace) ? obj.workspace.id : (tl.workspace ? tl.workspace.id : null)

            if (wsId === activeWsId && (!obj || (!obj.hidden && obj.mapped !== false))) {
                wsWinCount++
            }

            var clsLower = cls.toLowerCase()
            var initLower = initialCls.toLowerCase()

            // Check if this toplevel matches any pinned item
            var matchedPinned = false
            for (var p = 0; p < pItems.length; p++) {
                var item = pItems[p]
                var matches = item.match || []
                var isMatch = false

                for (var m = 0; m < matches.length; m++) {
                    var mat = matches[m].toLowerCase()
                    if (mat.length > 0 && (clsLower.indexOf(mat) !== -1 || initLower.indexOf(mat) !== -1 || mat.indexOf(clsLower) !== -1)) {
                        isMatch = true
                        break
                    }
                }

                if (!isMatch && item.name && clsLower.indexOf(item.name.toLowerCase()) !== -1) {
                    isMatch = true
                }

                if (isMatch) {
                    item.isRunning = true
                    item.windowCount++
                    item.windows.push({ address: addr, title: title, activated: activated, workspace: wsId })
                    if (activated) item.isActive = true
                    matchedPinned = true
                    break
                }
            }

            // If not matched to any pinned app, group into unpinned running items
            if (!matchedPinned && cls.length > 0) {
                var key = clsLower
                if (!unpinnedMap[key]) {
                    var resolved = root.findAppForClass(cls, title)
                    unpinnedMap[key] = {
                        id: resolved ? resolved.id : cls,
                        name: resolved ? resolved.name : (cls.charAt(0).toUpperCase() + cls.slice(1)),
                        exec: resolved ? resolved.exec : cls,
                        icon: resolved ? resolved.icon : cls,
                        icon_path: resolved ? resolved.icon_path : "",
                        match: [clsLower],
                        isPinned: false,
                        isRunning: true,
                        isActive: activated,
                        windowCount: 1,
                        windows: [{ address: addr, title: title, activated: activated, workspace: wsId }]
                    }
                } else {
                    unpinnedMap[key].windowCount++
                    unpinnedMap[key].windows.push({ address: addr, title: title, activated: activated, workspace: wsId })
                    if (activated) unpinnedMap[key].isActive = true
                }
            }
        }

        var uItems = []
        for (var k in unpinnedMap) {
            uItems.push(unpinnedMap[k])
        }

        root.pinnedItems = pItems
        root.unpinnedItems = uItems
        root.currentWsWindowCount = wsWinCount
    }

    // ── PIN / UNPIN TOGGLE ──────────────────────────────────────────────────
    function togglePinApp(itemData) {
        if (!itemData) return
        var pinnedList = [].concat(root.config.pinned_apps || [])

        if (itemData.isPinned) {
            // Remove pin
            pinnedList = pinnedList.filter(function(p) {
                return (p.id !== itemData.id && p.name !== itemData.name)
            })
        } else {
            // Add pin
            var newPin = {
                id: itemData.id || (itemData.name.toLowerCase() + ".desktop"),
                name: itemData.name || "App",
                exec: itemData.exec || itemData.name.toLowerCase(),
                icon: itemData.icon || itemData.name.toLowerCase(),
                icon_path: itemData.icon_path || "",
                match: itemData.match || [itemData.id.replace(".desktop", ""), itemData.exec.split(" ")[0]]
            }
            pinnedList.push(newPin)
        }

        var newCfg = Object.assign({}, root.config, { pinned_apps: pinnedList })
        root.saveDockConfig(newCfg)
    }

    // ── HYPRLAND CONNECTIONS & REAL-TIME TOPLEVEL TRACKING ───────────────────
    Component.onCompleted: {
        Hyprland.refreshToplevels()
        Hyprland.refreshWorkspaces()
        root.updateDockItems()
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "workspace" || event.name === "workspacev2") {
                var ws = parseInt(event.data, 10)
                if (!isNaN(ws) && ws > 0) {
                    root.activeWorkspaceId = ws
                }
            } else if (event.name === "focusedmon") {
                var parts = event.data.split(",")
                if (parts.length > 1) {
                    var mws = parseInt(parts[1], 10)
                    if (!isNaN(mws) && mws > 0) {
                        root.activeWorkspaceId = mws
                    }
                }
            }
            Hyprland.refreshToplevels()
            Hyprland.refreshWorkspaces()
            Hyprland.refreshMonitors()
            root.updateDockItems()
        }
        function onFocusedWorkspaceChanged() {
            root.closeAllMenus()
            Hyprland.refreshToplevels()
            Hyprland.refreshWorkspaces()
            Hyprland.refreshMonitors()
            root.updateDockItems()
        }
        function onActiveToplevelChanged() {
            root.closeAllMenus()
            Hyprland.refreshToplevels()
            Hyprland.refreshWorkspaces()
            Hyprland.refreshMonitors()
            root.updateDockItems()
        }
    }

    // Watchdog fallback sync (events handle real-time updates)
    Timer {
        interval: 6000
        running: true
        repeat: true
        onTriggered: {
            Hyprland.refreshToplevels()
            Hyprland.refreshWorkspaces()
            Hyprland.refreshMonitors()
            root.updateDockItems()
        }
    }

    // ── WINDOW FOCUS & LIFECYCLE DISPATCHERS ─────────────────────────────────
    function focusAppWindow(itemData) {
        if (!itemData || !itemData.windows || itemData.windows.length === 0) {
            root.launchApp(itemData ? itemData.id : "", itemData ? itemData.exec : "")
            return
        }

        var wins = itemData.windows
        var targetWin = wins[0]

        // If multiple windows and one is already active, cycle to next
        if (wins.length > 1) {
            var activeIdx = -1
            for (var i = 0; i < wins.length; i++) {
                if (wins[i].activated) {
                    activeIdx = i
                    break
                }
            }
            if (activeIdx !== -1) {
                targetWin = wins[(activeIdx + 1) % wins.length]
            }
        }

        var addr = targetWin.address
        if (!addr) return
        var hexAddr = addr.toString()
        if (!hexAddr.startsWith("0x")) {
            hexAddr = "0x" + hexAddr
        }
        Hyprland.dispatch("hl.dsp.focus({ window = 'address:" + hexAddr + "' })")
    }

    function closeAppWindow(itemData) {
        if (!itemData || !itemData.windows || itemData.windows.length === 0) return
        var addr = itemData.windows[0].address
        if (!addr) return
        var hexAddr = addr.toString()
        if (!hexAddr.startsWith("0x")) {
            hexAddr = "0x" + hexAddr
        }
        Hyprland.dispatch("hl.dsp.window.close({ window = 'address:" + hexAddr + "' })")
    }

    // ── PINNED APP REORDERING (DRAG TO PLACE) ───────────────────────────────
    function movePinnedApp(fromIdx, toIdx) {
        if (fromIdx === toIdx || fromIdx < 0 || toIdx < 0) return
        var list = [].concat(root.config.pinned_apps || [])
        if (fromIdx >= list.length || toIdx >= list.length) return
        var item = list.splice(fromIdx, 1)[0]
        list.splice(toIdx, 0, item)
        var c = Object.assign({}, root.config)
        c.pinned_apps = list
        root.saveDockConfig(c)
    }

    readonly property string pos: root.config.position || "bottom"
    readonly property bool isHorizontal: pos === "bottom" || pos === "top"
    readonly property real iconSz: root.config.icon_size || 48
    readonly property real dockPad: root.config.dock_padding || 8
    readonly property real dockRadius: root.config.corner_radius || 22
    readonly property string hoverFx: root.config.hover_effect || "zoom"
    readonly property bool showTips: root.config.show_tooltips !== false
    readonly property bool showInds: root.config.show_indicators !== false

    function svgUrl(svgString) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgString)
    }

    readonly property string launcherGridSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/></svg>')
    readonly property string launcherGridHoverSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/></svg>')

    // ── MULTI-SCREEN DOCK WINDOW INSTANTIATION ───────────────────────────────
    Variants {
        model: Quickshell.screens

        Scope {
            id: screenScope
            required property var modelData

            Loader {
                id: dockWinLoader
                active: true
                property string currentPos: root.pos
                onCurrentPosChanged: {
                    active = false
                    active = true
                }

                sourceComponent: Component {
                    PanelWindow {
                        id: dockWin
                        screen: screenScope.modelData

                // Dynamic window expansion:
                // When dock is hidden → window is only 3px at the screen edge (cursor must reach the very edge)
                // When dock is open → window expands to full size for dock interaction
                // collapseDelay keeps window expanded during the 220ms slide-out animation
                property bool isWindowExpanded: isDockOpen || collapseDelay.running
                Timer {
                    id: collapseDelay
                    interval: 240  // slightly longer than the 220ms slide animation
                    repeat: false
                }
                onIsDockOpenChanged: {
                    if (!isDockOpen) collapseDelay.restart()
                }

                // Full sizes for expanded state
                readonly property int fullWidth: iconSz + dockPad * 2 + 100
                readonly property int fullHeight: iconSz + dockPad * 2 + 56

                // Anchors according to position
                anchors {
                    top: isHorizontal ? (pos === "top") : true
                    bottom: isHorizontal ? (pos === "bottom") : true
                    left: isHorizontal ? true : (pos === "left")
                    right: isHorizontal ? true : (pos === "right")
                }

                // Dynamic window size: 3px trigger strip when hidden, full when open
                implicitWidth: isHorizontal ? screen.width : (isWindowExpanded ? fullWidth : 3)
                implicitHeight: isHorizontal ? (isWindowExpanded ? fullHeight : 3) : screen.height

                color: "transparent"
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "dock"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                // Reserved workspace margin in Always On mode
                exclusiveZone: {
                    if (root.config.mode === "always_on" && root.config.enabled !== false) {
                        return (isHorizontal ? dockContainer.height : dockContainer.width) + 12
                    }
                    return 0
                }

                Binding on exclusionMode {
                    value: (root.config.mode === "always_on" && root.config.enabled !== false) ? ExclusionMode.Normal : ExclusionMode.Ignore
                    delayed: true
                }

                visible: root.config.enabled !== false

                // Input mask: edgeTrigger always active (for 3px hover detection),
                // dockContainer added when expanded (for app interaction)
                mask: Region {
                    Region { item: (root.config.enabled !== false) ? edgeTrigger : null }
                    Region { item: (root.config.enabled !== false && isWindowExpanded) ? dockContainer : null }
                }

                // ── VISIBILITY & STAGE MECHANICS ────────────────────────────
                Connections {
                    target: root
                    function onCloseAllMenus() {
                        contextMenu.close()
                    }
                }

                readonly property bool isHovered: (edgeHH.hovered || dockHH.hovered || (contextMenu.visible && contextMenu.isHovered)) && (root.config.enabled !== false)

                // Accurately detect if focused workspace has any open windows
                readonly property bool hasWindowsOnWorkspace: root.currentWsWindowCount > 0

                readonly property bool shouldBeVisible: {
                    if (root.config.enabled === false) return false

                    // Stage 1: Always On
                    if (root.config.mode === "always_on") {
                        return true
                    }
                    // Stage 2: Auto Hide
                    if (root.config.mode === "auto_hide") {
                        return dockWin.isHovered
                    }
                    // Stage 3: Smart Hide (window dodge)
                    // "always open but hidden when a window is opened, should appear on hover"
                    if (root.config.mode === "smart_hide") {
                        if (!dockWin.hasWindowsOnWorkspace) {
                            return true
                        } else {
                            return dockWin.isHovered
                        }
                    }
                    return true
                }

                // Hide grace delay timer to prevent fluttering
                Timer {
                    id: hideTimer
                    interval: Math.max(260, root.config.hide_delay || 350)
                    repeat: false
                }

                onIsHoveredChanged: {
                    if (!dockWin.isHovered) {
                        hideTimer.restart()
                    } else {
                        hideTimer.stop()
                    }
                }

                readonly property bool isDockOpen: (root.config.enabled !== false) && (dockWin.shouldBeVisible || hideTimer.running)

                // ── EDGE TRIGGER SENSOR (STRICTLY 3PX AT SCREEN EDGE, SIZED TO DOCK) ─────────
                Item {
                    id: edgeTrigger
                    z: 99

                    anchors.top: isHorizontal ? (pos === "top" ? parent.top : undefined) : undefined
                    anchors.bottom: isHorizontal ? (pos === "bottom" ? parent.bottom : undefined) : undefined
                    anchors.left: !isHorizontal ? (pos === "left" ? parent.left : undefined) : undefined
                    anchors.right: !isHorizontal ? (pos === "right" ? parent.right : undefined) : undefined

                    anchors.horizontalCenter: isHorizontal ? parent.horizontalCenter : undefined
                    anchors.verticalCenter: !isHorizontal ? parent.verticalCenter : undefined

                    width: isHorizontal ? Math.max(160, dockContainer.width + 32) : 3
                    height: isHorizontal ? 3 : Math.max(160, dockContainer.height + 32)

                    HoverHandler {
                        id: edgeHH
                        enabled: root.config.enabled !== false
                    }
                }

                // ── DOCK MAIN PILL CONTAINER ────────────────────────────────
                Rectangle {
                    id: dockContainer
                    z: 10

                    // Dynamic dimensions based on orientation and contents
                    width: isHorizontal ? (dockContentRow.implicitWidth + dockPad * 2) : (iconSz + dockPad * 2 + 16)
                    height: isHorizontal ? (iconSz + dockPad * 2 + 16) : (dockContentCol.implicitHeight + dockPad * 2)

                    radius: dockRadius
                    color: Theme.alpha(Theme.surface, root.config.bg_opacity !== undefined ? root.config.bg_opacity : 0.85)
                    border.width: 1
                    border.color: Theme.alpha(Theme.accent, root.config.border_glow ? 0.38 : 0.20)

                    // Centering & Sliding Animation
                    // Uses fullWidth/fullHeight for hidden position so the dock
                    // slides from the correct edge even when window is collapsed to 3px
                    x: {
                        if (isHorizontal) {
                            return (dockWin.width - width) / 2
                        } else if (pos === "left") {
                            return dockWin.isDockOpen ? 10 : (-width - 15)
                        } else if (pos === "right") {
                            return dockWin.isDockOpen ? (dockWin.fullWidth - width - 10) : (dockWin.fullWidth + 15)
                        }
                        return 0
                    }

                    y: {
                        if (!isHorizontal) {
                            return (dockWin.height - height) / 2
                        } else if (pos === "bottom") {
                            return dockWin.isDockOpen ? (dockWin.fullHeight - height - 10) : (dockWin.fullHeight + 15)
                        } else if (pos === "top") {
                            return dockWin.isDockOpen ? 10 : (-height - 15)
                        }
                        return 0
                    }

                    Behavior on x {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                    Behavior on y {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }

                    HoverHandler {
                        id: dockHH
                        enabled: root.config.enabled !== false
                    }

                    // Background click dismisser for context menu & clicks
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: {
                            contextMenu.close()
                        }
                    }

                    // ── HORIZONTAL DOCK LAYOUT (BOTTOM / TOP) ────────────────
                    Row {
                        id: dockContentRow
                        visible: isHorizontal
                        anchors.centerIn: parent
                        spacing: 4

                        // 1. Quick App Launcher Button
                        Item {
                            visible: root.config.show_launcher !== false
                            width: iconSz + 16
                            height: iconSz + 16

                            Rectangle {
                                anchors.centerIn: parent
                                width: iconSz
                                height: iconSz
                                radius: iconSz / 2
                                color: launcherMouse.containsMouse ? Theme.alpha(Theme.accent, 0.25) : "transparent"
                                border.width: 1
                                border.color: launcherMouse.containsMouse ? Theme.accent : "transparent"

                                Image {
                                    anchors.centerIn: parent
                                    width: iconSz * 0.44
                                    height: iconSz * 0.44
                                    source: launcherMouse.containsMouse ? root.launcherGridHoverSvg : root.launcherGridSvg
                                    sourceSize: Qt.size(48, 48)
                                    smooth: true
                                }
                            }

                            MouseArea {
                                id: launcherMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    contextMenu.close()
                                    root.openLauncher()
                                }
                            }
                        }

                        // Divider after launcher
                        Rectangle {
                            visible: root.config.show_launcher !== false && (root.pinnedItems.length > 0 || root.unpinnedItems.length > 0)
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1
                            height: iconSz * 0.55
                            color: Theme.alpha(Theme.foreground, 0.15)
                        }

                        // 2. Pinned Apps
                        Repeater {
                            model: root.pinnedItems

                            DockItem {
                                required property var modelData
                                required property int index
                                itemData: modelData
                                itemIndex: index
                                pinnedCount: root.pinnedItems.length
                                dockPosition: pos
                                iconSize: iconSz
                                hoverEffect: hoverFx
                                showTooltips: showTips && !contextMenu.visible
                                showIndicators: showInds

                                onItemClicked: {
                                    contextMenu.close()
                                    root.focusAppWindow(modelData)
                                }

                                onReorderPinned: (fromIdx, toIdx) => {
                                    root.movePinnedApp(fromIdx, toIdx)
                                }

                                onItemRightClicked: (visualItem) => {
                                    if (contextMenu.visible && contextMenu.targetItem && contextMenu.targetItem.id === modelData.id) {
                                        contextMenu.close()
                                        return
                                    }
                                    contextMenu.open(modelData, visualItem, pos, dockWin)
                                }
                            }
                        }

                        // 3. Divider between Pinned and Unpinned Running Apps
                        Rectangle {
                            visible: root.pinnedItems.length > 0 && root.unpinnedItems.length > 0
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1
                            height: iconSz * 0.55
                            color: Theme.alpha(Theme.foreground, 0.15)
                        }

                        // 4. Currently Running Unpinned Apps
                        Repeater {
                            model: root.unpinnedItems

                            DockItem {
                                required property var modelData
                                itemData: modelData
                                dockPosition: pos
                                iconSize: iconSz
                                hoverEffect: hoverFx
                                showTooltips: showTips && !contextMenu.visible
                                showIndicators: showInds

                                onItemClicked: {
                                    contextMenu.close()
                                    root.focusAppWindow(modelData)
                                }

                                onItemRightClicked: (visualItem) => {
                                    if (contextMenu.visible && contextMenu.targetItem && contextMenu.targetItem.id === modelData.id) {
                                        contextMenu.close()
                                        return
                                    }
                                    contextMenu.open(modelData, visualItem, pos, dockWin)
                                }
                            }
                        }
                    }

                    // ── VERTICAL DOCK LAYOUT (LEFT / RIGHT) ──────────────────
                    Column {
                        id: dockContentCol
                        visible: !isHorizontal
                        anchors.centerIn: parent
                        spacing: 4

                        // 1. Quick App Launcher Button
                        Item {
                            visible: root.config.show_launcher !== false
                            width: iconSz + 16
                            height: iconSz + 16

                            Rectangle {
                                anchors.centerIn: parent
                                width: iconSz
                                height: iconSz
                                radius: iconSz / 2
                                color: launcherMouseV.containsMouse ? Theme.alpha(Theme.accent, 0.25) : "transparent"
                                border.width: 1
                                border.color: launcherMouseV.containsMouse ? Theme.accent : "transparent"

                                Image {
                                    anchors.centerIn: parent
                                    width: iconSz * 0.44
                                    height: iconSz * 0.44
                                    source: launcherMouseV.containsMouse ? root.launcherGridHoverSvg : root.launcherGridSvg
                                    sourceSize: Qt.size(48, 48)
                                    smooth: true
                                }
                            }

                            MouseArea {
                                id: launcherMouseV
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    contextMenu.close()
                                    root.openLauncher()
                                }
                            }
                        }

                        // Divider after launcher
                        Rectangle {
                            visible: root.config.show_launcher !== false && (root.pinnedItems.length > 0 || root.unpinnedItems.length > 0)
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: iconSz * 0.55
                            height: 1
                            color: Theme.alpha(Theme.foreground, 0.15)
                        }

                        // 2. Pinned Apps
                        Repeater {
                            model: root.pinnedItems

                            DockItem {
                                required property var modelData
                                required property int index
                                itemData: modelData
                                itemIndex: index
                                pinnedCount: root.pinnedItems.length
                                dockPosition: pos
                                iconSize: iconSz
                                hoverEffect: hoverFx
                                showTooltips: showTips && !contextMenu.visible
                                showIndicators: showInds

                                onItemClicked: {
                                    contextMenu.close()
                                    root.focusAppWindow(modelData)
                                }

                                onReorderPinned: (fromIdx, toIdx) => {
                                    root.movePinnedApp(fromIdx, toIdx)
                                }

                                onItemRightClicked: (visualItem) => {
                                    if (contextMenu.visible && contextMenu.targetItem && contextMenu.targetItem.id === modelData.id) {
                                        contextMenu.close()
                                        return
                                    }
                                    contextMenu.open(modelData, visualItem, pos, dockWin)
                                }
                            }
                        }

                        // 3. Divider between Pinned and Unpinned Running Apps
                        Rectangle {
                            visible: root.pinnedItems.length > 0 && root.unpinnedItems.length > 0
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: iconSz * 0.55
                            height: 1
                            color: Theme.alpha(Theme.foreground, 0.15)
                        }

                        // 4. Currently Running Unpinned Apps
                        Repeater {
                            model: root.unpinnedItems

                            DockItem {
                                required property var modelData
                                itemData: modelData
                                dockPosition: pos
                                iconSize: iconSz
                                hoverEffect: hoverFx
                                showTooltips: showTips && !contextMenu.visible
                                showIndicators: showInds

                                onItemClicked: {
                                    contextMenu.close()
                                    root.focusAppWindow(modelData)
                                }

                                onItemRightClicked: (visualItem) => {
                                    if (contextMenu.visible && contextMenu.targetItem && contextMenu.targetItem.id === modelData.id) {
                                        contextMenu.close()
                                        return
                                    }
                                    contextMenu.open(modelData, visualItem, pos, dockWin)
                                }
                            }
                        }
                    }
                }

                // ── CONTEXT MENU POPUP (POPOVER) ────────────────────────────
                DockContextMenu {
                    id: contextMenu
                    dockHovered: edgeHH.hovered || dockHH.hovered

                    onPinToggled: (itemData) => {
                        root.togglePinApp(itemData)
                    }

                    onNewInstance: (itemData) => {
                        root.launchApp(itemData.id, itemData.exec)
                    }

                    onCloseWindow: (itemData) => {
                        root.closeAppWindow(itemData)
                    }
                }
            }
        }
    }
}
}
}

