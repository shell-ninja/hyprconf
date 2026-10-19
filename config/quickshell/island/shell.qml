//@ pragma Env QS_NO_RELOAD_POPUP=1
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.Polkit
import Quickshell.Services.Mpris
import "."

PanelWindow {
    id: root

    // Dynamic layer shell window (top notch or bottom dock)
    anchors.top: root.islandPosition === "top"
    anchors.bottom: root.islandPosition === "bottom"
    anchors.left: true
    anchors.right: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-island"
    WlrLayershell.keyboardFocus: root.expanded ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: (root.islandAutoHide ? 0 : 48)

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    // ── NATIVE POLKIT AGENT ──────────────────────────────────────────────────
    PolkitAgent {
        id: polkitAgent
        onAuthenticationRequestStarted: {
            console.log("[Polkit] Authentication request started:", flow ? flow.actionId : "null")
            root.openPolkit()
        }
        onIsActiveChanged: {
            if (!isActive && expandedContent && expandedContent.currentView === 6) {
                root.closePolkit()
            }
        }
    }

    // ── GEOMETRY PARAMETERS ──────────────────────────────────────────────────
    readonly property real topMargin: 10
    readonly property real normalCollapsedWidth: 312
    readonly property real musicCollapsedWidth: {
        var barsPerWing = Math.max(2, Math.floor(root.visualizerBarCount / 2))
        var vizW = Math.max(20, barsPerWing * (3.2 + 2.4) - 2.4 + 6)
        return Math.ceil(275 + vizW * 2 + 56)
    }
    readonly property real timerCollapsedWidth: 320
    readonly property real notifCollapsedWidth: 470
    readonly property real osdCollapsedWidth: 320
    readonly property real osdCollapsedHeight: 46

    property bool hasOsdPopup: false
    property string osdType: "volume"
    property real osdValue: 0.5
    property string osdLabel: "50%"
    property string osdIcon: "volume"
    property string osdSubLabel: ""

    Timer {
        id: osdTimer
        interval: 1800
        repeat: false
        onTriggered: {
            root.hasOsdPopup = false
        }
    }

    function showOsd(type, value, label, icon, subLabel) {
        root.osdType = type || "volume"
        var numVal = parseFloat(value)
        root.osdValue = isNaN(numVal) ? 0.0 : (numVal > 1.0 ? numVal / 100.0 : numVal)
        root.osdLabel = (label !== undefined && label !== null) ? ("" + label) : ""
        root.osdIcon = icon || root.osdType
        root.osdSubLabel = (subLabel !== undefined && subLabel !== null) ? ("" + subLabel) : ""
        root.hasOsdPopup = true
        osdTimer.restart()
    }

    readonly property real normalCollapsedHeight: {
        if (root.islandStyle === "minimal_rail") return 32
        if (root.islandStyle === "orbital") return 34
        if (root.islandStyle === "split_wings") return 42
        return 36
    }
    // Dynamic notification height: driven by actual content in CollapsedBar, min 56px
    readonly property real notifCollapsedHeight: collapsedBar ? Math.max(56, collapsedBar.notifContentHeight) : 76
    readonly property real collapsedHeight: normalCollapsedHeight

    readonly property real targetCollapsedWidth: {
        if (root.isScreenshotTimerActive && !root.expanded) return timerCollapsedWidth
        if (root.hasNotificationPopup && !root.expanded) return notifCollapsedWidth
        if (root.hasOsdPopup && !root.expanded) return osdCollapsedWidth
        if (root.isAudioPlaying && !root.expanded && root.islandStyle !== "minimal_rail") {
            var req = (collapsedBar && collapsedBar.requiredWidth > 0) ? collapsedBar.requiredWidth : musicCollapsedWidth
            return Math.max(req, musicCollapsedWidth)
        }
        var baseReq = (collapsedBar && collapsedBar.requiredWidth > 0) ? collapsedBar.requiredWidth : normalCollapsedWidth
        return Math.max(baseReq, normalCollapsedWidth)
    }
    property real activeCollapsedWidth: targetCollapsedWidth

    Behavior on activeCollapsedWidth {
        NumberAnimation {
            duration: 320
            easing.type: Easing.OutCubic
        }
    }

    readonly property real targetCollapsedHeight: {
        if (root.hasNotificationPopup && !root.expanded) return notifCollapsedHeight
        if (root.hasOsdPopup && !root.expanded) return osdCollapsedHeight
        return normalCollapsedHeight
    }
    property real activeCollapsedHeight: targetCollapsedHeight

    Behavior on activeCollapsedHeight {
        NumberAnimation {
            duration: 320
            easing.type: Easing.OutCubic
        }
    }

    // ── DYNAMIC ISLAND & VISUALIZER CONFIGURATION ───────────────────────────
    property string islandPosition: "top"
    readonly property bool isBottom: (root.islandPosition === "bottom")
    property bool islandAutoHide: false
    property string islandStyle: "capsule"
    property bool visualizerEnabled: true
    property int visualizerBarCount: 8
    property string visualizerStyle: "wave"
    property bool visualizerMoveOnHover: true
    property bool matrixStreamEnabled: true
    property bool isMinimalClockHovered: false

    Process {
        id: configLoader
        command: ["python3", "-c", "import json, os; p=os.path.expanduser('~/.hyprconf/quickshell/island/config.json'); print(open(p).read() if os.path.exists(p) else '{}')"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var cfg = JSON.parse(text.trim())
                    if (cfg.position) root.islandPosition = cfg.position
                    if (cfg.auto_hide !== undefined) root.islandAutoHide = cfg.auto_hide
                    if (cfg.style) root.islandStyle = cfg.style
                    if (cfg.matrix_stream !== undefined) root.matrixStreamEnabled = cfg.matrix_stream
                    if (cfg.visualizer) {
                        if (cfg.visualizer.enabled !== undefined) root.visualizerEnabled = cfg.visualizer.enabled
                        if (cfg.visualizer.bar_count !== undefined) root.visualizerBarCount = cfg.visualizer.bar_count
                        if (cfg.visualizer.style) root.visualizerStyle = cfg.visualizer.style
                        if (cfg.visualizer.move_to_bottom_on_hover !== undefined) root.visualizerMoveOnHover = cfg.visualizer.move_to_bottom_on_hover
                    }
                } catch(e) {
                    console.log("[Island] Error parsing config.json:", e)
                }
            }
        }
    }

    function reloadConfig() {
        configLoader.running = false
        configLoader.running = true
    }

    // ── AUDIO / MEDIA PLAYBACK STATE ─────────────────────────────────────────
    readonly property bool isMediaPlaying: {
        var players = Mpris.players ? Mpris.players.values : []
        for (var i = 0; i < players.length; i++) {
            var p = players[i]
            if (p && p.playbackState === MprisPlaybackState.Playing) return true
        }
        return false
    }
    property bool isSinkPlaying: false
    readonly property bool isAudioPlaying: isMediaPlaying || isSinkPlaying

    Timer {
        id: sinkCheckTimer
        interval: 500
        repeat: true
        running: !root.isMediaPlaying
        onTriggered: {
            if (!sinkCheckProc.running) sinkCheckProc.running = true
        }
    }

    Process {
        id: sinkCheckProc
        command: ["bash", "-c", "(pactl list sinks short 2>/dev/null | grep -q RUNNING || pactl list sink-inputs 2>/dev/null | grep -q 'Corked: no') && echo 1 || echo 0"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (data && data.length > 0) {
                    root.isSinkPlaying = (data.trim() === "1")
                }
            }
        }
    }

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : "/home/shell-ninja"
    }

    // ── LIVE AUDIO FREQUENCY VISUALIZER (CAVA INTEGRATION) ───────────────────
    property var cavaBars: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

    Process {
        id: cavaProc
        command: ["cava", "-p", root.homeDir + "/.hyprconf/hypr/.cache/cava-island.conf"]
        running: root.isAudioPlaying && root.visualizerEnabled
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (!data || data.length === 0) return
                var str = data.trim()
                var parts = (str.indexOf(";") !== -1) ? str.split(";") : str.split(/\s+/)
                if (parts.length >= 4) {
                    var newBars = []
                    for (var i = 0; i < Math.min(parts.length, 16); i++) {
                        var v = parseInt(parts[i], 10)
                        newBars.push(isNaN(v) ? 0.0 : Math.max(0.0, Math.min(1.0, v / 100.0)))
                    }
                    root.cavaBars = newBars
                }
            }
        }
    }

    // ── INSTANT WALLPAPER RELOAD & CACHE BUSTING ────────────────────────────
    property real wallpaperTimestamp: Date.now()

    function reloadWallpaper() {
        root.wallpaperTimestamp = Date.now()
    }


    // ── SCREENSHOT COUNTDOWN TIMER STATE ────────────────────────────────────
    property bool isScreenshotTimerActive: false
    property int screenshotTimerRemaining: 0
    property int screenshotTimerTotal: 5
    property string screenshotTimerMode: "screen"
    property bool screenshotTimerSatty: true
    property bool screenshotTimerSound: true

    readonly property real defaultExpandedWidth: 480
    readonly property real wallpaperExpandedWidth: 920
    readonly property real screenshotExpandedWidth: 620
    readonly property real polkitExpandedWidth: 520
    readonly property real clipboardExpandedWidth: 780
    readonly property real defaultExpandedHeight: 560
    readonly property real wallpaperExpandedHeight: 380
    readonly property real screenshotExpandedHeight: 380
    readonly property real polkitExpandedHeight: 370
    readonly property real clipboardExpandedHeight: 520

    // Stored view during collapse animation so container shrinks smoothly from exact modal dimensions
    property int closingView: 0

    readonly property real activeExpandedWidth: {
        var v = root.expanded ? (expandedContent ? expandedContent.currentView : 0) : root.closingView
        if (v === 2) return wallpaperExpandedWidth
        if (v === 3) return (expandedContent && expandedContent.launcherView ? expandedContent.launcherView.preferredWidth : 880)
        if (v === 4) return 860
        if (v === 5) return screenshotExpandedWidth
        if (v === 6) return polkitExpandedWidth
        if (v === 7) return clipboardExpandedWidth
        if (v === 8) return (expandedContent && expandedContent.emojiView ? expandedContent.emojiView.preferredWidth : 620)
        return defaultExpandedWidth
    }
    readonly property real activeExpandedHeight: {
        var v = root.expanded ? (expandedContent ? expandedContent.currentView : 0) : root.closingView
        if (v === 2) return wallpaperExpandedHeight
        if (v === 3) return (expandedContent && expandedContent.launcherView ? expandedContent.launcherView.preferredHeight : 420)
        if (v === 4) return 500
        if (v === 5) return screenshotExpandedHeight
        if (v === 6) return polkitExpandedHeight
        if (v === 7) return clipboardExpandedHeight
        if (v === 8) return (expandedContent && expandedContent.emojiView ? expandedContent.emojiView.preferredHeight : 460)
        return defaultExpandedHeight
    }

    // ── EXPANSION & HOVER STATE MACHINE ──────────────────────────────────────
    property bool expanded: false
    property real animProgress: expanded ? 1.0 : 0.0
    property bool isClosingWallpaper: false
    property bool ipcKeepExpanded: false

    onExpandedChanged: {
        if (!root.expanded) {
            root.ipcKeepExpanded = false
        }
        if (root.expanded) {
            shapeContainer.forceActiveFocus()
            root.reloadWallpaper()
            notifPopupTimer.stop()
            root.hasNotificationPopup = false
            root.currentPopupNotification = null
        }
    }

    onAnimProgressChanged: {
        if (animProgress <= 0.001 && !expanded) {
            root.closingView = 0
            root.isClosingWallpaper = false
            if (expandedContent) {
                expandedContent.currentView = 0
                expandedContent.dashboardPage = 0
            }
        }
    }

    Timer {
        id: delayedCollapseTimer
        interval: 80
        repeat: false
        onTriggered: {
            root.expanded = false
        }
    }

    // Ultra-clean non-bouncing cubic deceleration
    Behavior on animProgress {
        NumberAnimation {
            duration: 260
            easing.type: Easing.OutCubic
        }
    }

    // Wayland layer surface geometry (shadow-free clean bounds)
    implicitWidth: Math.max(root.defaultExpandedWidth, Math.max(root.wallpaperExpandedWidth, 880)) + 30
    implicitHeight: Math.max(root.defaultExpandedHeight, Math.max(root.wallpaperExpandedHeight, 580)) + root.topMargin + 20

    function openWallpaper() {
        if (root.expanded && expandedContent && expandedContent.currentView === 2) {
            closeWallpaper()
            return
        }
        root.isClosingWallpaper = false
        hoverIntentTimer.stop()
        closeTimer.stop()
        if (expandedContent) expandedContent.currentView = 2
        root.expanded = true
        if (expandedContent && expandedContent.wallpaperView && typeof expandedContent.wallpaperView.focusWallpaper === "function") {
            expandedContent.wallpaperView.focusWallpaper()
        } else {
            shapeContainer.forceActiveFocus()
        }
    }

    function closeWallpaper() {
        hoverIntentTimer.stop()
        closeTimer.stop()
        root.closingView = 2
        root.isClosingWallpaper = true
        root.expanded = false
        if (expandedContent) expandedContent.currentView = 0
    }

    function openLauncher() {
        if (root.expanded && expandedContent && expandedContent.currentView === 3) {
            closeLauncher()
            return
        }
        root.isClosingWallpaper = false
        hoverIntentTimer.stop()
        closeTimer.stop()
        if (expandedContent) {
            expandedContent.currentView = 3
            if (expandedContent.launcherView && typeof expandedContent.launcherView.focusLauncher === "function") {
                expandedContent.launcherView.focusLauncher()
            }
        }
        root.expanded = true
    }

    function closeLauncher() {
        hoverIntentTimer.stop()
        closeTimer.stop()
        root.closingView = 3
        root.isClosingWallpaper = true
        root.expanded = false
        if (expandedContent) expandedContent.currentView = 0
    }

    function toggleLauncher() {
        if (root.expanded && expandedContent && expandedContent.currentView === 3) {
            closeLauncher()
        } else {
            openLauncher()
        }
    }

    function openThemeSwitcher() {
        if (root.expanded && expandedContent && expandedContent.currentView === 4) {
            closeThemeSwitcher()
            return
        }
        root.isClosingWallpaper = false
        hoverIntentTimer.stop()
        closeTimer.stop()
        if (expandedContent) expandedContent.currentView = 4
        root.expanded = true
        shapeContainer.forceActiveFocus()
    }

    function closeThemeSwitcher() {
        hoverIntentTimer.stop()
        closeTimer.stop()
        root.closingView = 4
        root.isClosingWallpaper = true
        root.expanded = false
        if (expandedContent) expandedContent.currentView = 0
    }

    function toggleThemeSwitcher() {
        if (root.expanded && expandedContent && expandedContent.currentView === 4) {
            closeThemeSwitcher()
        } else {
            openThemeSwitcher()
        }
    }

    function openScreenshot() {
        if (root.expanded && expandedContent && expandedContent.currentView === 5) {
            closeScreenshot()
            return
        }
        root.isClosingWallpaper = false
        hoverIntentTimer.stop()
        closeTimer.stop()
        if (expandedContent) expandedContent.currentView = 5
        root.expanded = true
        shapeContainer.forceActiveFocus()
    }

    function closeScreenshot() {
        hoverIntentTimer.stop()
        closeTimer.stop()
        root.closingView = 5
        root.isClosingWallpaper = true
        root.expanded = false
        if (expandedContent) expandedContent.currentView = 0
    }

    function toggleScreenshot() {
        if (root.expanded && expandedContent && expandedContent.currentView === 5) {
            closeScreenshot()
        } else {
            openScreenshot()
        }
    }

    function startScreenshotTimer(seconds, targetMode, useSatty, playSound) {
        var s = parseInt(seconds, 10)
        root.screenshotTimerTotal = (!isNaN(s) && s > 0) ? s : 5
        root.screenshotTimerRemaining = root.screenshotTimerTotal
        root.screenshotTimerMode = (targetMode && targetMode.length > 0) ? targetMode : "screen"
        root.screenshotTimerSatty = (useSatty !== undefined) ? useSatty : true
        root.screenshotTimerSound = (playSound !== undefined) ? playSound : true
        root.isScreenshotTimerActive = true
        screenshotCountdownTimer.restart()
        console.log("SCREENSHOT_TIMER_STARTED: " + root.screenshotTimerTotal + "s mode=" + root.screenshotTimerMode)
    }

    function cancelScreenshotTimer() {
        screenshotCountdownTimer.stop()
        postTimerCaptureDelay.stop()
        root.isScreenshotTimerActive = false
        root.screenshotTimerRemaining = 0
        console.log("SCREENSHOT_TIMER_CANCELLED")
    }

    function executeTimedScreenshot() {
        console.log("EXECUTE_TIMED_SCREENSHOT: mode=" + root.screenshotTimerMode + " satty=" + root.screenshotTimerSatty + " sound=" + root.screenshotTimerSound)
        if (typeof flashAnim !== "undefined") {
            flashAnim.restart()
        }

        var args = ["bash", root.homeDir + "/.hyprconf/hypr/scripts/sh/screenshot.sh", "--delay", "0"]
        if (!root.screenshotTimerSatty) args.push("--no-satty")
        if (!root.screenshotTimerSound) args.push("--no-sound")
        args.push(root.screenshotTimerMode)

        timedCaptureProc.running = false
        timedCaptureProc.command = args
        timedCaptureProc.running = true
    }

    Timer {
        id: postTimerCaptureDelay
        interval: 380
        repeat: false
        onTriggered: {
            root.executeTimedScreenshot()
        }
    }

    Timer {
        id: screenshotCountdownTimer
        interval: 1000
        repeat: true
        onTriggered: {
            if (root.screenshotTimerRemaining > 1) {
                root.screenshotTimerRemaining -= 1
            } else {
                screenshotCountdownTimer.stop()
                root.screenshotTimerRemaining = 0
                root.isScreenshotTimerActive = false
                postTimerCaptureDelay.restart()
            }
        }
    }

    Process {
        id: timedCaptureProc
        command: []
    }

    function openPolkit() {
        root.isClosingWallpaper = false
        hoverIntentTimer.stop()
        closeTimer.stop()
        if (expandedContent) {
            expandedContent.polkitFlow = polkitAgent.flow
            expandedContent.currentView = 6
        }
        root.expanded = true
        shapeContainer.forceActiveFocus()
        if (expandedContent && expandedContent.polkitView) {
            expandedContent.polkitView.focusInput()
        }
    }

    function closePolkit() {
        hoverIntentTimer.stop()
        closeTimer.stop()
        root.closingView = 6
        root.isClosingWallpaper = true
        root.expanded = false
        if (expandedContent) expandedContent.currentView = 0
    }

    function openClipboard() {
        if (root.expanded && expandedContent && expandedContent.currentView === 7) {
            closeClipboard()
            return
        }
        root.isClosingWallpaper = false
        hoverIntentTimer.stop()
        closeTimer.stop()
        if (expandedContent) {
            expandedContent.currentView = 7
            if (expandedContent.clipboardView && typeof expandedContent.clipboardView.focusSearch === "function") {
                expandedContent.clipboardView.focusSearch()
            }
        }
        root.expanded = true
    }

    function closeClipboard() {
        hoverIntentTimer.stop()
        closeTimer.stop()
        root.closingView = 7
        root.isClosingWallpaper = true
        root.expanded = false
        if (expandedContent) expandedContent.currentView = 0
    }

    function toggleClipboard() {
        if (root.expanded && expandedContent && expandedContent.currentView === 7) {
            closeClipboard()
        } else {
            openClipboard()
        }
    }

    function openEmoji() {
        if (root.expanded && expandedContent && expandedContent.currentView === 8) {
            closeEmoji()
            return
        }
        root.isClosingWallpaper = false
        hoverIntentTimer.stop()
        closeTimer.stop()
        if (expandedContent) {
            expandedContent.currentView = 8
            if (expandedContent.emojiView && typeof expandedContent.emojiView.focusSearch === "function") {
                expandedContent.emojiView.focusSearch()
            }
        }
        root.expanded = true
    }

    function closeEmoji() {
        hoverIntentTimer.stop()
        closeTimer.stop()
        root.closingView = 8
        root.isClosingWallpaper = true
        root.expanded = false
        if (expandedContent) expandedContent.currentView = 0
    }

    function toggleEmoji() {
        if (root.expanded && expandedContent && expandedContent.currentView === 8) {
            closeEmoji()
        } else {
            openEmoji()
        }
    }
    function closeIsland() {
        hoverIntentTimer.stop()
        closeTimer.stop()
        root.ipcKeepExpanded = false
        if (root.isScreenshotTimerActive) {
            root.cancelScreenshotTimer()
            return
        }
        if (expandedContent) {
            if (expandedContent.currentView === 2) {
                root.closeWallpaper()
            } else if (expandedContent.currentView === 3) {
                root.closeLauncher()
            } else if (expandedContent.currentView === 4) {
                root.closeThemeSwitcher()
            } else if (expandedContent.currentView === 5) {
                root.closeScreenshot()
            } else if (expandedContent.currentView === 6) {
                root.closePolkit()
            } else if (expandedContent.currentView === 7) {
                root.closeClipboard()
            } else if (expandedContent.currentView === 8) {
                root.closeEmoji()
            } else {
                root.closingView = expandedContent.currentView
                root.isClosingWallpaper = true
                root.expanded = false
                expandedContent.currentView = 0
            }
        } else {
            root.expanded = false
        }
    }

    // Native IPC handler to allow external script/keybind control (expand, collapse, toggle, wallpaper, launcher, screenshot, polkit)
    IpcHandler {
        target: "island"
        function toggle() {
            root.expanded = !root.expanded
        }
        function expand() {
            root.expanded = true
            if (expandedContent) {
                expandedContent.currentView = 0
                expandedContent.dashboardPage = 0
            }
        }
        function expandPinned() {
            closeTimer.stop()
            root.ipcKeepExpanded = true
            root.expanded = true
            if (expandedContent) {
                expandedContent.currentView = 0
                expandedContent.dashboardPage = 0
            }
        }
        function unpin() {
            root.ipcKeepExpanded = false
            root.expanded = false
        }
        function openStatus() {
            root.expanded = true
            if (expandedContent) {
                expandedContent.currentView = 0
                expandedContent.dashboardPage = 1
            }
        }
        function openProcessNet() {
            root.expanded = true
            if (expandedContent) {
                expandedContent.currentView = 0
                expandedContent.dashboardPage = 2
            }
        }
        function collapse() {
            root.closeIsland()
        }
        function closeIsland() {
            root.closeIsland()
        }
        function power() {
            root.expanded = true
            if (expandedContent) expandedContent.currentView = 1
        }
        function openPower() {
            root.expanded = true
            if (expandedContent) expandedContent.currentView = 1
        }
        function togglePower() {
            if (root.expanded && expandedContent && expandedContent.currentView === 1) {
                root.expanded = false
            } else {
                root.expanded = true
                if (expandedContent) expandedContent.currentView = 1
            }
        }
        function toggleDnd() {
            root.setDnd(!root.dndActive)
        }
        function setDnd(val: bool) {
            root.setDnd(val)
        }
        function openWallpaper() {
            root.openWallpaper()
        }
        function closeWallpaper() {
            root.closeWallpaper()
        }
        function openLauncher() {
            root.openLauncher()
        }
        function closeLauncher() {
            root.closeLauncher()
        }
        function toggleLauncher() {
            root.toggleLauncher()
        }
        function openThemeSwitcher() {
            root.openThemeSwitcher()
        }
        function closeThemeSwitcher() {
            root.closeThemeSwitcher()
        }
        function toggleThemeSwitcher() {
            root.toggleThemeSwitcher()
        }
        function openScreenshot() {
            root.openScreenshot()
        }
        function closeScreenshot() {
            root.closeScreenshot()
        }
        function toggleScreenshot() {
            root.toggleScreenshot()
        }
        function startScreenshotTimer(seconds: string, mode: string) {
            var s = parseInt(seconds, 10)
            if (isNaN(s) || s <= 0) s = 5
            root.startScreenshotTimer(s, (mode && mode.length > 0) ? mode : "screen", true, true)
        }
        function cancelScreenshotTimer() {
            root.cancelScreenshotTimer()
        }
        function openPolkit() {
            root.openPolkit()
        }
        function closePolkit() {
            root.closePolkit()
        }
        function openClipboard() {
            root.openClipboard()
        }
        function closeClipboard() {
            root.closeClipboard()
        }
        function toggleClipboard() {
            root.toggleClipboard()
        }
        function openEmoji() {
            root.openEmoji()
        }
        function closeEmoji() {
            root.closeEmoji()
        }
        function toggleEmoji() {
            root.toggleEmoji()
        }
        function setAudioPlaying(val: bool) {
            root.isSinkPlaying = val
        }
        function toggleAudioPlaying() {
            root.isSinkPlaying = !root.isAudioPlaying
        }
        function nextWallpaper() {
            if (expandedContent && expandedContent.currentView === 2 && expandedContent.wallpaperView) {
                expandedContent.wallpaperView.selectNext()
            }
        }
        function prevWallpaper() {
            if (expandedContent && expandedContent.currentView === 2 && expandedContent.wallpaperView) {
                expandedContent.wallpaperView.selectPrevious()
            }
        }
        function applyWallpaper() {
            if (expandedContent && expandedContent.currentView === 2 && expandedContent.wallpaperView) {
                expandedContent.wallpaperView.confirmSelection()
            }
        }
        function toggleOnline() {
            if (expandedContent && expandedContent.currentView === 2 && expandedContent.wallpaperView) {
                var wv = expandedContent.wallpaperView
                if (wv.activeMode === "local") {
                    wv.activeMode = "online"
                    wv.fetchOnlineWallpapers(1)
                } else {
                    wv.activeMode = "local"
                    wv.refreshWallpapers()
                }
            }
        }
        function openWallpaperDir() {
            if (!root.expanded || !expandedContent || expandedContent.currentView !== 2) {
                root.openWallpaper()
            }
            if (expandedContent && expandedContent.wallpaperView) {
                expandedContent.wallpaperView.openDirBrowser()
            }
        }
        function closeWallpaperDir() {
            if (expandedContent && expandedContent.currentView === 2 && expandedContent.wallpaperView) {
                expandedContent.wallpaperView.closeDirBrowser()
            }
        }
        function status() {
            console.log("ISLAND_STATUS: expanded=" + root.expanded + " Theme.primary=" + Theme.primary)
        }
        function openStatusPage() {
            root.expanded = true
            if (expandedContent) {
                expandedContent.currentView = 0
                expandedContent.dashboardPage = 1
            }
        }
        function reloadWallpaper() {
            root.reloadWallpaper()
        }
        function testNotif(title: string, msg: string) {
            root.handleIncomingNotification({
                id: Date.now(),
                appName: "Test App",
                summary: (title && title.length > 0) ? title : "Notification Title",
                body: (msg && msg.length > 0) ? msg : "This is a test notification message in Dynamic Island.",
                appIcon: "",
                urgency: 1
            })
        }
        function reloadConfig() {
            root.reloadConfig()
        }
        function syncAudio(vol: string, muted: string) {
            if (collapsedBar) {
                var v = parseFloat(vol)
                if (!isNaN(v)) {
                    collapsedBar.currentVolume = (v > 1.0) ? (v / 100.0) : v
                }
                if (muted !== undefined && muted.length > 0) {
                    collapsedBar.isMuted = (muted === "1" || muted === "true")
                }
            }
        }
        function showOsd(type: string, value: string, label: string, icon: string, subLabel: string) {
            root.showOsd(type, value, label, icon, subLabel)
        }
    }

    // Global ESC key shortcut to immediately collapse any expanded view or cancel timer
    Shortcut {
        sequence: "Escape"
        enabled: root.expanded || root.isScreenshotTimerActive
        onActivated: {
            root.closeIsland()
        }
    }

    // Hover intent guard (120ms): Prevents accidental sweeps across screen top from popping open
    Timer {
        id: hoverIntentTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (collapsedBar && collapsedBar.isWorkspaceAreaHovered) {
                return
            }
            var canExpand = (root.islandStyle !== "minimal_rail") ? shapeHover.hovered : root.isMinimalClockHovered
            if (canExpand && !root.expanded && !root.isClosingWallpaper && root.closingView === 0 && (!expandedContent || expandedContent.currentView === 0)) {
                closeTimer.stop()
                if (expandedContent) {
                    expandedContent.currentView = 0
                    expandedContent.dashboardPage = 0
                }
                root.expanded = true
            }
        }
    }

    // Configurable closing delay (400ms) to prevent accidental closure
    Timer {
        id: closeTimer
        interval: 400
        repeat: false
        onTriggered: {
            if (root.ipcKeepExpanded) {
                return
            }
            if (expandedContent && (expandedContent.currentView >= 2 || root.closingView > 0)) {
                return
            }
            if (!shapeHover.hovered && root.expanded) {
                root.expanded = false
            }
        }
    }

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string settingsSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>')
    readonly property string chipSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="4" width="16" height="16" rx="2"/><rect x="9" y="9" width="6" height="6"/><line x1="9" y1="1" x2="9" y2="4"/><line x1="15" y1="1" x2="15" y2="4"/><line x1="9" y1="20" x2="9" y2="23"/><line x1="15" y1="20" x2="15" y2="23"/><line x1="20" y1="9" x2="23" y2="9"/><line x1="20" y1="14" x2="23" y2="14"/><line x1="1" y1="9" x2="4" y2="9"/><line x1="1" y1="14" x2="4" y2="14"/></svg>')

    // ── FREEDESKTOP NOTIFICATION SERVER & STATE ─────────────────────────────
    NotificationServer {
        id: notifServer
        keepOnReload: false
        actionsSupported: true
        imageSupported: true

        onNotification: function(notif) {
            if (notif.lastGeneration) {
                return
            }
            notif.tracked = true
            root.handleIncomingNotification(notif)
        }
    }

    property var notificationList: []
    property var currentPopupNotification: null
    property bool hasNotificationPopup: false
    property bool dndActive: false
    property var seenNotifPopupKeys: ({})

    Process {
        id: dndLoader
        command: ["python3", "-c", "import json, os; p=os.path.expanduser('~/.hyprconf/hypr/.cache/dnd_state.json'); print('true' if os.path.exists(p) and json.load(open(p)).get('dnd') else 'false')"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    root.dndActive = (text.trim() === "true")
                }
            }
        }
    }

    function setDnd(val: bool) {
        root.dndActive = val
        var pyCmd = "import json, os; p=os.path.expanduser('~/.hyprconf/hypr/.cache/dnd_state.json'); os.makedirs(os.path.dirname(p), exist_ok=True); json.dump({'dnd': " + (val ? "True" : "False") + "}, open(p, 'w'))"
        dndSaver.command = ["python3", "-c", pyCmd]
        dndSaver.running = true
    }

    Process { id: dndSaver }

    Timer {
        id: notifPopupTimer
        interval: 4800
        repeat: false
        onTriggered: {
            root.hasNotificationPopup = false
            root.currentPopupNotification = null
        }
    }

    function pauseNotifTimer() {
        notifPopupTimer.stop()
    }

    function resumeNotifTimer() {
        if (root.hasNotificationPopup && !root.expanded) {
            notifPopupTimer.restart()
        }
    }

    function handleIncomingNotification(notif) {
        if (!notif) return

        var iconSource = ""
        if (notif.appIcon && notif.appIcon.length > 0) {
            if (notif.appIcon.indexOf("/") === 0 || notif.appIcon.indexOf("file://") === 0) {
                iconSource = notif.appIcon
            } else {
                var resolved = Quickshell.iconPath(notif.appIcon, true)
                if (resolved && resolved.length > 0) {
                    iconSource = resolved
                }
            }
        }

        var notifId = (notif.id !== undefined && notif.id !== null) ? notif.id : Date.now()
        var summaryText = (notif.summary && notif.summary.length > 0) ? notif.summary : "New Notification"
        var bodyText = notif.body || ""
        var appText = (notif.appName && notif.appName.length > 0) ? notif.appName : "Notification"

        // Collect actions from the raw notification (if any)
        var actionList = []
        try {
            if (notif.actions && notif.actions.length > 0) {
                for (var ai = 0; ai < notif.actions.length; ai++) {
                    var act = notif.actions[ai]
                    // Skip the default "default" action — it's invoked by clicking the body
                    if (act.identifier !== "default") {
                        actionList.push({ text: act.text || act.identifier, action: act })
                    }
                }
            }
        } catch(e) {}

        var item = {
            id: notifId,
            app: appText,
            summary: summaryText,
            body: bodyText,
            icon: iconSource,
            urgency: (notif.urgency !== undefined) ? notif.urgency : 1,
            time: new Date(),
            actions: actionList,
            rawNotif: notif
        }

        // Listen for remote close / dismiss
        if (typeof notif.closed !== "undefined" && typeof notif.closed.connect === "function") {
            try {
                notif.closed.connect(function(reason) {
                    if (root.currentPopupNotification && root.currentPopupNotification.id === notifId) {
                        notifPopupTimer.stop()
                        root.hasNotificationPopup = false
                        root.currentPopupNotification = null
                    }
                })
            } catch(e) {}
        }

        // Deduplicate in notificationList: replace existing notification with same ID if any
        var filteredList = []
        for (var i = 0; i < root.notificationList.length; i++) {
            var existing = root.notificationList[i]
            if (existing && existing.id !== notifId) {
                filteredList.push(existing)
            }
        }
        root.notificationList = [item].concat(filteredList.slice(0, 49))
        root.saveNotificationsToCache()

        // Check if this exact notification content was already shown
        var notifKey = notifId + "::" + appText + "::" + summaryText + "::" + bodyText
        var alreadyShown = (root.seenNotifPopupKeys[notifKey] === true)

        if (!alreadyShown && !root.expanded && !root.dndActive) {
            var updatedKeys = Object.assign({}, root.seenNotifPopupKeys)
            updatedKeys[notifKey] = true
            root.seenNotifPopupKeys = updatedKeys

            root.currentPopupNotification = item
            root.hasNotificationPopup = true
            notifPopupTimer.restart()
        }
    }

    Process {
        id: notifLoader
        command: ["python3", "-c", "import json, os; p=os.path.expanduser('~/.hyprconf/hypr/.cache/notifications.json'); print(open(p).read() if os.path.exists(p) else '[]')"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text) return
                try {
                    var parsed = JSON.parse(text.trim())
                    if (Array.isArray(parsed) && parsed.length > 0 && root.notificationList.length === 0) {
                        root.notificationList = parsed
                    }
                } catch(e) {}
            }
        }
    }

    Process { id: notifSaver }

    function saveNotificationsToCache() {
        var cleanList = []
        for (var i = 0; i < root.notificationList.length; i++) {
            var n = root.notificationList[i]
            if (n) {
                cleanList.push({
                    id: n.id,
                    app: n.app || "",
                    summary: n.summary || "",
                    body: n.body || "",
                    icon: n.icon || "",
                    urgency: n.urgency || 1,
                    time: n.time || new Date()
                })
            }
        }
        var jsonStr = JSON.stringify(cleanList)
        notifSaver.running = false
        notifSaver.command = ["python3", "-c", "import json, os, sys; p=os.path.expanduser('~/.hyprconf/hypr/.cache/notifications.json'); os.makedirs(os.path.dirname(p), exist_ok=True); open(p, 'w').write(sys.argv[1])", jsonStr]
        notifSaver.running = true
    }

    function clearAllNotifications() {
        for (var i = 0; i < root.notificationList.length; i++) {
            var item = root.notificationList[i]
            if (item && item.rawNotif && typeof item.rawNotif.dismiss === "function") {
                try { item.rawNotif.dismiss() } catch(e) {}
            }
        }
        root.notificationList = []
        root.hasNotificationPopup = false
        root.currentPopupNotification = null
        root.seenNotifPopupKeys = {}
        notifPopupTimer.stop()
        root.saveNotificationsToCache()
    }

    function dismissNotification(notifId) {
        var copy = []
        for (var i = 0; i < root.notificationList.length; i++) {
            var item = root.notificationList[i]
            if (item && item.id === notifId) {
                if (item.rawNotif && typeof item.rawNotif.dismiss === "function") {
                    try { item.rawNotif.dismiss() } catch(e) {}
                }
            } else if (item) {
                copy.push(item)
            }
        }
        root.notificationList = copy
        if (root.currentPopupNotification && root.currentPopupNotification.id === notifId) {
            root.hasNotificationPopup = false
            root.currentPopupNotification = null
            notifPopupTimer.stop()
        }
        root.saveNotificationsToCache()
    }

    // ── LIVE TIME, DATE & SYSTEM STATS ───────────────────────────────────────
    property string timeString: "12:00 PM"
    property string dateString: "Fri, 16 Oct"
    property string ramString: "RAM 5.6 GB"
    property string netDownString: "0B"
    property string netUpString: "0B"

    Process {
        id: netSpeedReader
        command: ["python3", "-u", root.homeDir + "/.hyprconf/hypr/scripts/py/network-speed.py"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (!data || data.length === 0) return
                try {
                    var parsed = JSON.parse(data.trim())
                    if (parsed.down !== undefined) root.netDownString = parsed.down
                    if (parsed.up !== undefined) root.netUpString = parsed.up
                } catch(e) {}
            }
        }
    }

    function updateTime() {
        var d = new Date()
        var h = d.getHours() % 12 || 12
        var hStr = h < 10 ? "0" + h : "" + h
        var m = d.getMinutes()
        var mStr = m < 10 ? "0" + m : "" + m
        var ap = d.getHours() >= 12 ? "PM" : "AM"
        root.timeString = hStr + ":" + mStr + " " + ap

        var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        root.dateString = days[d.getDay()] + ", " + d.getDate() + " " + months[d.getMonth()]
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateTime()
    }

    Process {
        id: ramReader
        command: ["bash", "-c", "python3 -c 'with open(\"/proc/meminfo\") as f: l=dict(x.split(\":\") for x in f); t=int(l[\"MemTotal\"].split()[0]); a=int(l[\"MemAvailable\"].split()[0]); print(f\"RAM {((t-a)/(1024*1024)):.1f} GB\")'"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) root.ramString = text.trim()
            }
        }
    }

    Timer {
        interval: 8000
        running: true
        repeat: true
        onTriggered: {
            if (!ramReader.running) ramReader.running = true
        }
    }

    Process {
        id: settingsProc
        command: ["bash", "-c", "$HOME/.hyprconf/hypr/scripts/sh/qs-settings.sh"]
    }

    // ── EDGE SENSOR FOR IDLE AUTO-HIDE ──────────────────────────────────────
    Item {
        id: edgeSensor
        anchors.horizontalCenter: parent.horizontalCenter
        y: (root.islandPosition === "bottom") ? (parent.height - height) : 0
        width: Math.max(root.activeCollapsedWidth, 320)
        height: 12
        visible: root.islandAutoHide && !root.expanded

        HoverHandler {
            id: edgeSensorHover
        }
    }

    readonly property bool isAutoHidden: root.islandAutoHide && !root.expanded && !root.hasNotificationPopup && !root.isScreenshotTimerActive && !root.hasOsdPopup && !shapeHover.hovered && !edgeSensorHover.hovered

    // ── FLOATING ISLAND & DASHBOARD CONTAINER ────────────────────────────────
    Item {
        id: shapeContainer
        anchors.horizontalCenter: parent.horizontalCenter
        y: (root.islandPosition === "bottom")
           ? (parent.height - height - root.topMargin)
           : root.topMargin
        width: root.activeCollapsedWidth + (root.activeExpandedWidth - root.activeCollapsedWidth) * root.animProgress
        height: root.activeCollapsedHeight + (root.activeExpandedHeight - root.activeCollapsedHeight) * root.animProgress
        clip: root.expanded ? ((expandedContent && (expandedContent.currentView >= 2)) ? false : true) : false
        focus: true
        opacity: root.isAutoHidden ? 0.12 : 1.0

        transform: Translate {
            y: root.isAutoHidden ? (root.islandPosition === "top" ? -28 : 28) : 0
            Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        }

        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        // Global keyboard interceptor — BeforeItem priority ensures Escape fires
        // even when a child TextInput (search box) has active focus.
        // For non-Escape keys, event.accepted = false lets the event propagate
        // naturally to whichever child (TextInput, list, etc.) has active focus.
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                // Intercept Escape globally — close whatever is open
                event.accepted = true
                root.closeIsland()
                return
            }

            // For all other keys: let children handle them naturally.
            // View 0 (dashboard home) has no focused TextInput, so we manually
            // forward left/right navigation arrows to it via handleKey().
            event.accepted = false
            if (root.expanded && expandedContent && (expandedContent.currentView === 0 || expandedContent.currentView === 2)) {
                if (expandedContent.handleKey(event)) {
                    event.accepted = true
                }
            }
        }


        // Obsidian floating silhouette (shown for collapsed bar and home/power views)
        IslandShape {
            id: backgroundShape
            anchors.fill: parent
            islandStyle: root.islandStyle
            isBottom: root.isBottom
            animProgress: root.animProgress
            totalWidth: parent.width
            animatedHeight: parent.height
            cornerRadius: {
                if (root.animProgress > 0.001) return 18 + (28 - 18) * root.animProgress
                if (root.hasNotificationPopup || root.hasOsdPopup) return 22
                if (root.islandStyle === "minimal_rail") return 16
                return 18
            }
            visible: {
                if (!expandedContent || (expandedContent.currentView < 2)) {
                    if (root.expanded || root.animProgress > 0.001 || root.hasNotificationPopup || root.isScreenshotTimerActive || root.hasOsdPopup) return true
                    return (root.islandStyle === "capsule")
                }
                return false
            }
        }

        // ── COLLAPSED VIEW (WORKSPACE CLUSTER + CLOCK OR NOTIFICATION BANNER) ──
        CollapsedBar {
            id: collapsedBar
            z: 10
            anchors.fill: parent
            islandStyle: root.islandStyle
            matrixStreamEnabled: root.matrixStreamEnabled
            isBottom: root.isBottom
            timeString: root.timeString
            dateString: root.dateString
            ramString: root.ramString
            netDownString: root.netDownString
            netUpString: root.netUpString
            hasNotification: root.hasNotificationPopup
            currentNotification: root.currentPopupNotification
            notificationCount: (root.notificationList ? root.notificationList.length : 0)
            hasOsd: root.hasOsdPopup
            osdType: root.osdType
            osdValue: root.osdValue
            osdLabel: root.osdLabel
            osdIcon: root.osdIcon
            osdSubLabel: root.osdSubLabel
            onTriggerOsd: function(type, value, label, icon, subLabel) {
                root.showOsd(type, value, label, icon, subLabel)
            }
            isTimerActive: root.isScreenshotTimerActive
            timerRemaining: root.screenshotTimerRemaining
            timerTotal: root.screenshotTimerTotal
            isAudioPlaying: root.isAudioPlaying
            cavaBars: root.cavaBars
            visualizerEnabled: root.visualizerEnabled
            visualizerStyle: root.visualizerStyle
            visualizerBarCount: root.visualizerBarCount
            animProgress: root.animProgress
            opacity: Math.max(0.0, 1.0 - root.animProgress * 3.5)
            visible: opacity > 0.001 && !root.expanded
            onClockClicked: {
                root.expanded = !root.expanded
            }
            onIsWorkspaceAreaHoveredChanged: {
                if (collapsedBar.isWorkspaceAreaHovered && !root.expanded) {
                    hoverIntentTimer.stop()
                } else if (!collapsedBar.isWorkspaceAreaHovered && !root.expanded && shapeHover.hovered && root.islandStyle !== "minimal_rail" && !root.hasNotificationPopup) {
                    hoverIntentTimer.restart()
                }
            }
            onMinimalClockHovered: function(hovered) {
                root.isMinimalClockHovered = hovered
                if (root.islandStyle === "minimal_rail") {
                    if (hovered) {
                        closeTimer.stop()
                        if (!root.expanded && (!expandedContent || expandedContent.currentView === 0) && root.closingView === 0 && !root.isScreenshotTimerActive) {
                            hoverIntentTimer.restart()
                        }
                    } else {
                        hoverIntentTimer.stop()
                        if (root.expanded && (!expandedContent || expandedContent.currentView === 0)) {
                            closeTimer.restart()
                        }
                    }
                }
            }
            onNotificationClicked: {
                // Clicking the notification body just dismisses the popup —
                // it must NOT expand the island home page.
                notifPopupTimer.stop()
                if (root.currentPopupNotification && root.currentPopupNotification.id !== undefined) {
                    root.dismissNotification(root.currentPopupNotification.id)
                }
                root.hasNotificationPopup = false
                root.currentPopupNotification = null
            }
            onDismissNotificationClicked: {
                notifPopupTimer.stop()
                if (root.currentPopupNotification && root.currentPopupNotification.id !== undefined) {
                    root.dismissNotification(root.currentPopupNotification.id)
                }
                root.hasNotificationPopup = false
                root.currentPopupNotification = null
            }
            onNotificationHovered: function(hovered) {
                if (hovered) root.pauseNotifTimer()
                else root.resumeNotifTimer()
            }
            onCancelTimerClicked: {
                root.cancelScreenshotTimer()
            }
        }

        // Shutter flash effect when screenshot captures
        Rectangle {
            id: shutterFlash
            anchors.fill: parent
            radius: 18
            color: "#ffffff"
            opacity: 0.0
            visible: opacity > 0.001
            z: 9999

            SequentialAnimation {
                id: flashAnim
                NumberAnimation { target: shutterFlash; property: "opacity"; to: 0.85; duration: 60; easing.type: Easing.OutQuad }
                NumberAnimation { target: shutterFlash; property: "opacity"; to: 0.0; duration: 240; easing.type: Easing.OutQuad }
            }
        }

        // ── EXPANDED HEADER (TIME, DATE, SYSTEM STATS & SETTINGS) ─────────────
        Item {
            id: expandedHeader
            anchors.top: parent.top
            anchors.topMargin: 14
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            height: 26
            opacity: root.expanded ? (root.animProgress >= 0.70 ? Math.min(1.0, (root.animProgress - 0.70) / 0.30) : 0.0) : 0.0
            visible: (!expandedContent || (expandedContent.currentView < 2)) && opacity > 0.001
            transform: Translate {
                y: (1.0 - root.animProgress) * -4
            }

            // Left: Clock + Date (matching reference image)
            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Text {
                    text: root.timeString
                    color: Theme.accent
                    font.family: "Outfit"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    font.letterSpacing: 0.6
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: root.dateString
                    color: Theme.alpha(Theme.foreground, 0.70)
                    font.family: "Outfit"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Right: Hardware Info Pill + Settings Gear
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                // System Status Badge Pill
                Rectangle {
                    height: 22
                    width: ramRow.width + 12
                    radius: 11
                    color: Theme.alpha(Theme.surface, 0.75)
                    border.color: Theme.alpha(Theme.foreground, 0.10)
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        id: ramRow
                        anchors.centerIn: parent
                        spacing: 4
                        Image { width: 11; height: 11; source: root.chipSvg; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: root.ramString
                            font.family: "Outfit"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Theme.foreground
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Settings Gear Button
                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: gearMouse.containsMouse ? Theme.alpha(Theme.surface, 0.9) : "transparent"
                    border.color: gearMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.15) : "transparent"
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        source: root.settingsSvg
                    }

                    MouseArea {
                        id: gearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            settingsProc.command = ["bash", "-c", "$HOME/.hyprconf/hypr/scripts/sh/qs-settings.sh --island"]
                            settingsProc.running = true
                        }
                    }
                }
            }
        }

        // ── EXPANDED DASHBOARD VIEW (WITH LAZY STAGGERED ENTRANCE) ───────────
        DashboardView {
            id: expandedContent
            wallpaperTimestamp: root.wallpaperTimestamp
            isAudioPlaying: root.isAudioPlaying
            cavaBars: root.cavaBars
            visualizerEnabled: root.visualizerEnabled
            visualizerStyle: root.visualizerStyle
            visualizerBarCount: root.visualizerBarCount
            anchors.top: parent.top
            anchors.topMargin: (expandedContent && (expandedContent.currentView >= 2)) ? 0 : 48
            anchors.left: parent.left
            anchors.leftMargin: (expandedContent && (expandedContent.currentView >= 2)) ? 0 : 18
            anchors.right: parent.right
            anchors.rightMargin: (expandedContent && (expandedContent.currentView >= 2)) ? 0 : 18
            anchors.bottom: parent.bottom
            anchors.bottomMargin: (expandedContent && (expandedContent.currentView >= 2)) ? 0 : 16

            isClosingWallpaper: root.isClosingWallpaper
            animProgress: root.animProgress
            active: (expandedContent && expandedContent.currentView >= 2)
                    ? (root.expanded && !root.isClosingWallpaper)
                    : (root.animProgress >= 0.88 && root.expanded && !root.isClosingWallpaper)
            opacity: {
                if (currentView >= 2) {
                    return (root.expanded || root.animProgress > 0.001) ? 1.0 : 0.0
                }
                return root.expanded ? (root.animProgress >= 0.70 ? Math.min(1.0, (root.animProgress - 0.70) / 0.30) : 0.0) : 0.0
            }
            visible: opacity > 0.001
            notificationList: root.notificationList
            onClearAllNotifications: root.clearAllNotifications()
            onDismissNotification: function(notifId) {
                root.dismissNotification(notifId)
            }

            onCloseRequested: {
                root.closeIsland()
            }

            onLaunchLauncherRequested: {
                root.openLauncher()
            }

            onStartTimerScreenshot: function(seconds, targetMode, useSatty, playSound) {
                root.startScreenshotTimer(seconds, targetMode, useSatty, playSound)
            }
        }

        // ── HOVER & EXPAND HANDLERS ──────────────────────────────────────────
        // Passive HoverHandler: tracks hover across entire shapeContainer without intercepting pointer grabs
        HoverHandler {
            id: shapeHover
            onHoveredChanged: {
                if (hovered) {
                    closeTimer.stop()
                    if (collapsedBar && collapsedBar.isWorkspaceAreaHovered) {
                        return
                    }
                    if (root.islandStyle === "minimal_rail") {
                        // In minimal rail mode, only hovering the center clock capsule expands the island
                        return
                    }
                    if (!root.expanded && (!expandedContent || expandedContent.currentView === 0) && root.closingView === 0 && !root.isScreenshotTimerActive && !root.hasNotificationPopup) {
                        hoverIntentTimer.restart()
                    }
                } else {
                    hoverIntentTimer.stop()
                    if (root.expanded && (!expandedContent || expandedContent.currentView === 0)) {
                        closeTimer.restart()
                    }
                }
            }
        }

        // Expand clicker: only enabled when collapsed so it NEVER steals events when expanded or during notifications
        MouseArea {
            id: expandClicker
            z: 0
            anchors.fill: parent
            enabled: !root.expanded && !root.isScreenshotTimerActive && !root.hasNotificationPopup && (root.islandStyle !== "minimal_rail") && (!collapsedBar || !collapsedBar.isWorkspaceAreaHovered)
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                hoverIntentTimer.stop()
                closeTimer.stop()
                if (expandedContent) {
                    expandedContent.currentView = 0
                    expandedContent.dashboardPage = 0
                }
                root.expanded = true
            }
        }
    }

    // Precise Wayland input mask: clicks outside the visible shape pass directly through to desktop
    mask: Region {
        item: shapeContainer
    }
}
