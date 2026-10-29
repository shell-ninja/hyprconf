//@ pragma Env QS_NO_RELOAD_POPUP=1
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "."

FloatingWindow {
    id: window
    title: "System Package Updater"
    implicitWidth: 920
    implicitHeight: 740
    color: "transparent"
    onClosed: Qt.quit()

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    // ── STATE VARIABLES ──────────────────────────────────────────────────────
    property bool isChecking: true
    property bool isUpdating: false
    property bool updateCompleted: false
    property int updateExitCode: 0

    property var osInfo: ({ name: "Arch Linux", id: "arch" })
    property int totalUpdates: 0

    property string nativeType: "pacman"
    property string nativeName: "Pacman"
    property string nativeDesc: "Official Arch Linux repositories"
    property int nativeCount: 0
    property var nativePkgs: []
    property bool nativeChecked: true

    // Backwards-compatible pacman aliases
    readonly property int pacmanCount: nativeCount
    readonly property var pacmanPkgs: nativePkgs
    property alias pacmanChecked: window.nativeChecked

    property int aurCount: 0
    property var aurPkgs: []
    property bool aurChecked: true
    property bool aurAvailable: false
    property string aurHelper: "paru"

    property int flatpakCount: 0
    property var flatpakPkgs: []
    property bool flatpakChecked: false
    property bool flatpakAvailable: false

    // Bottom View Tab: 0 = Pending Packages Preview, 1 = Live Terminal Output
    property int activeBottomTab: 0
    property string searchFilter: ""

    // Computed total selected updates
    readonly property int selectedCount: {
        var cnt = 0
        if (nativeChecked) cnt += nativeCount
        if (aurChecked && aurAvailable) cnt += aurCount
        if (flatpakChecked && flatpakAvailable) cnt += flatpakCount
        return cnt
    }

    // ── SVG ASSETS ───────────────────────────────────────────────────────────
    function svgUrl(content) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(content)
    }

    readonly property string refreshSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21.5 2v6h-6M21.34 15.57a10 10 0 1 1-.57-8.38l5.67-5.67"/></svg>')
    readonly property string closeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>')
    readonly property string checkSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.background + '" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>')
    readonly property string updateSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.background + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>')
    readonly property string pacmanSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2a10 10 0 1 0 10 10 10 10 0 0 0-3.3-7.5L12 12l6.7-7.5A10 10 0 0 0 12 2z"/><circle cx="12" cy="7" r="1.5" fill="' + Theme.accent + '"/></svg>')
    readonly property string aurSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg>')
    readonly property string flatpakSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="7" width="20" height="14" rx="2" ry="2"/><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/></svg>')
    readonly property string arrowRightSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>')
    readonly property string terminalSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg>')
    readonly property string searchSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.muted + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>')
    readonly property string trashSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.muted + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>')
    readonly property string shieldSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>')
    readonly property string successCheckSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>')

    readonly property string aptSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M12 2a14.5 14.5 0 0 0 0 20 10 10 0 0 0 9.5-13.5"/></svg>')
    readonly property string dnfSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m12 3-1.9 5.8a2 2 0 0 1-1.28 1.28L3 12l5.8 1.9a2 2 0 0 1 1.28 1.28L12 21l1.9-5.8a2 2 0 0 1 1.28-1.28L21 12l-5.8-1.9a2 2 0 0 1-1.28-1.28L12 3z"/></svg>')
    readonly property string zypperSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><circle cx="12" cy="12" r="3"/></svg>')

    function nativeManagerSvg(type) {
        if (type === "apt") return window.aptSvg
        if (type === "dnf" || type === "dnf5") return window.dnfSvg
        if (type === "zypper") return window.zypperSvg
        return window.pacmanSvg
    }

    function packageTabSvg(active) {
        var col = active ? Theme.accent : Theme.muted
        return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + col + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg>')
    }

    function terminalTabSvg(active) {
        var col = active ? Theme.accent : Theme.muted
        return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + col + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg>')
    }

    // ── IPC HANDLER ──────────────────────────────────────────────────────────
    IpcHandler {
        target: "updater"
        function raise() {
            window.visible = true
        }
        function refresh() {
            checkUpdates()
        }
        function close() {
            Qt.quit()
        }
    }

    // ── SHORTCUTS ────────────────────────────────────────────────────────────
    Shortcut {
        sequence: "Escape"
        enabled: !isUpdating
        onActivated: Qt.quit()
    }

    Shortcut {
        sequence: "Ctrl+R"
        enabled: !isUpdating
        onActivated: checkUpdates()
    }

    Shortcut {
        sequence: "F5"
        enabled: !isUpdating
        onActivated: checkUpdates()
    }

    Shortcut {
        sequence: "Ctrl+U"
        enabled: !isUpdating && selectedCount > 0
        onActivated: startUpdate()
    }

    // ── PROCESS RUNNERS ──────────────────────────────────────────────────────
    ListModel {
        id: logModel
    }

    function color256ToHex(n) {
        n = parseInt(n, 10)
        if (isNaN(n) || n < 0 || n > 255) return "#94a3b8"
        if (n < 16) {
            var std = ["#000000","#ef4444","#22c55e","#eab308","#38bdf8","#a855f7","#06b6d4","#e2e8f0",
                       "#64748b","#f87171","#4ade80","#fde047","#60a5fa","#c084fc","#22d3ee","#ffffff"]
            return std[n]
        }
        if (n >= 232) {
            var g = Math.round((n - 232) * 10 + 8).toString(16)
            if (g.length === 1) g = "0" + g
            return "#" + g + g + g
        }
        var c = n - 16
        var b = (c % 6) * 51
        var g = (Math.floor(c / 6) % 6) * 51
        var r = Math.floor(c / 36) * 51
        var hex = function(v) { var s = v.toString(16); return s.length === 1 ? "0" + s : s }
        return "#" + hex(r) + hex(g) + hex(b)
    }

    function parseAnsi(text) {
        if (!text) return ""

        // 1. Handle carriage returns (pacman progress lines)
        if (text.indexOf("\r") !== -1) {
            var parts = text.split("\r")
            for (var p = parts.length - 1; p >= 0; p--) {
                if (parts[p].trim().length > 0) {
                    text = parts[p]
                    break
                }
            }
        }

        // 2. Strip OSC terminal title/status sequences (\x1b]...\x07 or \x1b]...\x1b\)
        text = text.replace(/\x1b\][^\x07\x1b]*(\x07|\x1b\\)/g, "")

        // 3. Strip non-SGR ANSI escape codes (cursor navigation, clear screen/line, etc.)
        text = text.replace(/\x1b\[\??[0-9;]*[a-ln-zA-LN-Z]/g, "")
        text = text.replace(/\x1b\([a-zA-Z]/g, "")

        // 4. Strip unprintable ASCII control characters (keep tab and newline)
        text = text.replace(/[\x00-\x08\x0b\x0c\x0e-\x1a\x1c-\x1f\x7f]/g, "")

        var hasEscape = text.indexOf("\x1b") !== -1

        // 5. HTML entity escaping before wrapping tags
        text = text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")

        if (!hasEscape) {
            var trimmed = text.trim()
            if (trimmed.indexOf("✓") !== -1 || trimmed.indexOf("successfully") !== -1) {
                return "<font color=\"#22c55e\">" + text + "</font>"
            }
            if (trimmed.indexOf("✗") !== -1 || trimmed.indexOf("failed") !== -1 || trimmed.indexOf("error") !== -1) {
                return "<font color=\"#ef4444\">" + text + "</font>"
            }
            if (trimmed.indexOf("::") === 0 || trimmed.indexOf("==") === 0) {
                return "<font color=\"" + Theme.accent + "\">" + text + "</font>"
            }
            if (trimmed.indexOf("━") !== -1) {
                return "<font color=\"" + Theme.alpha(Theme.foreground, 0.25) + "\">" + text + "</font>"
            }
            return text
        }

        // 6. Parse ANSI SGR codes: \x1b\[([0-9;]*)m
        var regex = /\x1b\[([0-9;]*)m/g
        var result = ""
        var lastIdx = 0
        var isBold = false
        var currentColor = null

        var match
        while ((match = regex.exec(text)) !== null) {
            result += text.substring(lastIdx, match.index)
            lastIdx = regex.lastIndex

            var codeStr = match[1] || "0"
            var codes = codeStr.split(";")

            for (var i = 0; i < codes.length; i++) {
                var c = parseInt(codes[i], 10)
                if (isNaN(c) || c === 0) {
                    if (currentColor) { result += "</font>"; currentColor = null }
                    if (isBold) { result += "</b>"; isBold = false }
                } else if (c === 1) {
                    if (!isBold) { result += "<b>"; isBold = true }
                } else if (c === 22) {
                    if (isBold) { result += "</b>"; isBold = false }
                } else if (c === 38 && codes[i+1] === "5" && codes[i+2]) {
                    var hex256 = color256ToHex(codes[i+2])
                    i += 2
                    if (currentColor) result += "</font>"
                    result += "<font color=\"" + hex256 + "\">"
                    currentColor = hex256
                } else if (c === 38 && codes[i+1] === "2" && codes[i+4]) {
                    var r = Math.min(255, Math.max(0, parseInt(codes[i+2], 10) || 0))
                    var g = Math.min(255, Math.max(0, parseInt(codes[i+3], 10) || 0))
                    var b = Math.min(255, Math.max(0, parseInt(codes[i+4], 10) || 0))
                    var toH = function(n) { var s = n.toString(16); return s.length === 1 ? "0" + s : s }
                    var hexRgb = "#" + toH(r) + toH(g) + toH(b)
                    i += 4
                    if (currentColor) result += "</font>"
                    result += "<font color=\"" + hexRgb + "\">"
                    currentColor = hexRgb
                } else if (c >= 30 && c <= 37) {
                    var standardColors = ["#4b5563", "#ef4444", "#22c55e", "#eab308", "#38bdf8", "#c084fc", "#2dd4bf", "#e2e8f0"]
                    var hexStd = standardColors[c - 30]
                    if (currentColor) result += "</font>"
                    result += "<font color=\"" + hexStd + "\">"
                    currentColor = hexStd
                } else if (c === 39) {
                    if (currentColor) { result += "</font>"; currentColor = null }
                } else if (c >= 90 && c <= 97) {
                    var brightColors = ["#94a3b8", "#f87171", "#4ade80", "#fde047", "#60a5fa", "#e879f9", "#67e8f9", "#ffffff"]
                    var hexBright = brightColors[c - 90]
                    if (currentColor) result += "</font>"
                    result += "<font color=\"" + hexBright + "\">"
                    currentColor = hexBright
                }
            }
        }

        result += text.substring(lastIdx)
        if (currentColor) result += "</font>"
        if (isBold) result += "</b>"

        // 7. Final safety purge of any unhandled escape sequences or control chars
        result = result.replace(/\x1b\[[0-9;]*[a-zA-Z]/g, "").replace(/\x1b/g, "")
        return result
    }

    property bool lastLineWasProgress: false

    function appendLog(line) {
        if (typeof line !== "string") return
        var trimmed = line.trim()
        if (trimmed.length === 0) return

        var formatted = parseAnsi(line)
        if (formatted.length === 0) return

        // Detect if this line is an in-place progress update (curl / pacman / download progress)
        var isProgress = /^\s*\d+\s+\d+[kMGT]?/i.test(trimmed) || 
                         /\[[#\s=-]+\]\s*\d+%/i.test(trimmed) ||
                         /ETA:\s*\d+/i.test(trimmed) ||
                         /^(\d{1,3}%|\(\d+\/\d+\))/i.test(trimmed)

        if (isProgress && lastLineWasProgress && logModel.count > 0) {
            logModel.set(logModel.count - 1, { "line": formatted })
        } else {
            logModel.append({ "line": formatted })
            lastLineWasProgress = isProgress
        }

        if (logListView.count > 0) {
            logListView.positionViewAtEnd()
        }
    }

    function clearLog() {
        logModel.clear()
        lastLineWasProgress = false
    }

    Process {
        id: checkProc
        command: ["python3", homeDir + "/.hyprconf/hypr/scripts/py/pkg-check.py"]
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var data = JSON.parse(text.trim())
                    if (data.os) window.osInfo = data.os
                    window.totalUpdates = data.total || 0

                    if (data.nativeType) window.nativeType = data.nativeType
                    if (data.nativeName) window.nativeName = data.nativeName
                    if (data.nativeDesc) window.nativeDesc = data.nativeDesc

                    if (data.native) {
                        window.nativeCount = data.native.count || 0
                        window.nativePkgs = data.native.packages || []
                    } else if (data.pacman) {
                        window.nativeCount = data.pacman.count || 0
                        window.nativePkgs = data.pacman.packages || []
                    }

                    if (data.aur) {
                        window.aurAvailable = data.aur.available || false
                        window.aurHelper = data.aur.helper || "paru"
                        window.aurCount = data.aur.count || 0
                        window.aurPkgs = data.aur.packages || []
                    } else {
                        window.aurAvailable = false
                        window.aurCount = 0
                        window.aurPkgs = []
                    }

                    if (data.flatpak) {
                        window.flatpakAvailable = data.flatpak.available || false
                        window.flatpakCount = data.flatpak.count || 0
                        window.flatpakPkgs = data.flatpak.packages || []
                    }
                } catch(e) {
                    console.log("[pkg-updater] Error parsing pkg-check JSON:", e)
                }
                window.isChecking = false
            }
        }
        onExited: (code, status) => {
            window.isChecking = false
        }
    }

    function checkUpdates() {
        if (isUpdating) return
        window.isChecking = true
        checkProc.running = false
        checkProc.running = true
    }

    Component.onCompleted: {
        checkUpdates()
    }

    // Process to apply package updates via pkexec / paru / flatpak
    Process {
        id: applyProc
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                appendLog(data)
            }
        }
        stderr: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                appendLog(data)
            }
        }
        onExited: (code, status) => {
            window.isUpdating = false
            window.updateCompleted = true
            window.updateExitCode = code
            // Refresh package count after update
            refreshTimer.restart()
        }
    }

    Timer {
        id: refreshTimer
        interval: 1200
        repeat: false
        onTriggered: checkUpdates()
    }

    function startUpdate() {
        if (isUpdating || selectedCount === 0) return
        window.isUpdating = true
        window.updateCompleted = false
        window.activeBottomTab = 1 // Switch directly to Live Output

        clearLog()
        appendLog(":: Preparing update pipeline...")

        var args = ["stdbuf", "-oL", "-eL", "bash", homeDir + "/.hyprconf/hypr/scripts/sh/pkg-apply.sh"]
        if (nativeChecked && nativeCount > 0) args.push("--" + nativeType)
        if (aurChecked && aurCount > 0 && aurAvailable) args.push("--aur")
        if (flatpakChecked && flatpakCount > 0 && flatpakAvailable) args.push("--flatpak")

        applyProc.command = args
        applyProc.running = false
        applyProc.running = true
    }

    // ── MAIN OBSIDIAN GLASS SURFACE ──────────────────────────────────────────
    Rectangle {
        id: rootSurface
        anchors.fill: parent
        color: Theme.alpha(Theme.background, 0.94)
        border.color: Theme.alpha(Theme.accent, 0.22)
        border.width: 1
        radius: 16
        clip: true

        // Inner shadow / ambient accent glow
        Rectangle {
            anchors.fill: parent
            radius: 16
            color: "transparent"
            border.color: Theme.alpha(Theme.accent, 0.08)
            border.width: 2
            z: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            // ── TOP HEADER BAR ───────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                spacing: 12

                // Refresh button with rotation animation
                Rectangle {
                    width: 36
                    height: 36
                    radius: 10
                    color: refreshArea.containsMouse ? Theme.alpha(Theme.accent, 0.16) : Theme.alpha(Theme.surface, 0.65)
                    border.color: refreshArea.containsMouse ? Theme.alpha(Theme.accent, 0.40) : Theme.alpha(Theme.foreground, 0.08)
                    border.width: 1

                    Image {
                        id: refreshIcon
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        source: window.refreshSvg
                        smooth: true

                        RotationAnimation {
                            target: refreshIcon
                            running: window.isChecking
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: 800
                        }
                    }

                    MouseArea {
                        id: refreshArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.checkUpdates()
                    }
                }

                // Centered App Title & Subtitle
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    RowLayout {
                        spacing: 8
                        Text {
                            text: "System Package Updater"
                            font.pixelSize: 15
                            font.bold: true
                            font.family: "Outfit"
                            color: Theme.foreground
                        }

                        // Status pill badge
                        Rectangle {
                            height: 18
                            implicitWidth: statusText.implicitWidth + 12
                            radius: 9
                            color: {
                                if (window.isUpdating) return Theme.alpha(Theme.accent, 0.20)
                                if (window.isChecking) return Theme.alpha(Theme.foreground, 0.08)
                                if (window.totalUpdates > 0) return Theme.alpha(Theme.accent, 0.15)
                                return Theme.alpha("#22c55e", 0.15)
                            }
                            border.color: {
                                if (window.isUpdating) return Theme.alpha(Theme.accent, 0.45)
                                if (window.isChecking) return Theme.alpha(Theme.foreground, 0.15)
                                if (window.totalUpdates > 0) return Theme.alpha(Theme.accent, 0.35)
                                return Theme.alpha("#22c55e", 0.35)
                            }
                            border.width: 1

                            Text {
                                id: statusText
                                anchors.centerIn: parent
                                text: {
                                    if (window.isUpdating) return "UPDATING"
                                    if (window.isChecking) return "CHECKING"
                                    if (window.totalUpdates > 0) return window.totalUpdates + " AVAILABLE"
                                    return "UP TO DATE"
                                }
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.5
                                color: {
                                    if (window.isUpdating) return Theme.accent
                                    if (window.isChecking) return Theme.muted
                                    if (window.totalUpdates > 0) return Theme.accent
                                    return "#22c55e"
                                }
                            }
                        }
                    }

                    Text {
                        text: window.osInfo.name + " • Quickshell Native Desktop Shell"
                        font.pixelSize: 11
                        font.family: "Outfit"
                        color: Theme.muted
                    }
                }

                // Close Button
                Rectangle {
                    width: 32
                    height: 32
                    radius: 8
                    color: closeArea.containsMouse ? Theme.alpha("#ef4444", 0.20) : Theme.alpha(Theme.surface, 0.65)
                    border.color: closeArea.containsMouse ? Theme.alpha("#ef4444", 0.50) : Theme.alpha(Theme.foreground, 0.08)
                    border.width: 1

                    Image {
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        source: window.closeSvg
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.quit()
                    }
                }
            }

            // ── HERO TITLE & STATS SUMMARY ROW ───────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Left: Hero description
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "Keep your system fresh"
                        font.pixelSize: 20
                        font.bold: true
                        font.family: "Outfit"
                        font.letterSpacing: -0.3
                        color: Theme.foreground
                    }

                    Text {
                        text: "Review package updates from all configured sources and apply them securely via Polkit."
                        font.pixelSize: 12
                        font.family: "Outfit"
                        color: Theme.muted
                        wrapMode: Text.WordWrap
                        Layout.maximumWidth: 380
                    }
                }

                // Right: Metric stat cards (Total, Pacman, AUR, Flatpak)
                RowLayout {
                    spacing: 8

                    // Stat Card: Total
                    Rectangle {
                        width: 90
                        height: 64
                        radius: 12
                        color: Theme.alpha(Theme.surface, 0.70)
                        border.color: Theme.alpha(Theme.accent, 0.25)
                        border.width: 1

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 1

                            Text {
                                text: window.isChecking ? "…" : window.totalUpdates.toString()
                                font.pixelSize: 22
                                font.bold: true
                                color: window.totalUpdates > 0 ? Theme.accent : Theme.muted
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "TOTAL"
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.8
                                color: Theme.muted
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    // Stat Card: Native Manager (Pacman / APT / DNF / Zypper)
                    Rectangle {
                        width: 90
                        height: 64
                        radius: 12
                        color: Theme.alpha(Theme.surface, 0.70)
                        border.color: Theme.alpha(Theme.foreground, 0.08)
                        border.width: 1

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 1

                            Text {
                                text: window.isChecking ? "…" : window.nativeCount.toString()
                                font.pixelSize: 22
                                font.bold: true
                                color: window.nativeCount > 0 ? Theme.accent : Theme.muted
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: window.nativeName.toUpperCase()
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.8
                                color: Theme.muted
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    // Stat Card: AUR (Visible only on Arch)
                    Rectangle {
                        visible: window.aurAvailable
                        width: 90
                        height: 64
                        radius: 12
                        color: Theme.alpha(Theme.surface, 0.70)
                        border.color: Theme.alpha(Theme.foreground, 0.08)
                        border.width: 1

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 1

                            Text {
                                text: window.isChecking ? "…" : window.aurCount.toString()
                                font.pixelSize: 22
                                font.bold: true
                                color: window.aurCount > 0 ? Theme.accent : Theme.muted
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "AUR"
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.8
                                color: Theme.muted
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    // Stat Card: Flatpak (Visible if installed)
                    Rectangle {
                        visible: window.flatpakAvailable || window.flatpakCount > 0
                        width: 90
                        height: 64
                        radius: 12
                        color: Theme.alpha(Theme.surface, 0.70)
                        border.color: Theme.alpha(Theme.foreground, 0.08)
                        border.width: 1

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 1

                            Text {
                                text: window.isChecking ? "…" : window.flatpakCount.toString()
                                font.pixelSize: 22
                                font.bold: true
                                color: window.flatpakCount > 0 ? Theme.accent : Theme.muted
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "FLATPAK"
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.8
                                color: Theme.muted
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
            }

            // ── UPDATE SOURCES SECTION ───────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "UPDATE SOURCES"
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 0.8
                    color: Theme.muted
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    // 1. Native Package Manager Card
                    Rectangle {
                        Layout.fillWidth: true
                        height: 62
                        radius: 12
                        color: nativeArea.containsMouse
                               ? Theme.alpha(Theme.surface, 0.90)
                               : (window.nativeChecked ? Theme.alpha(Theme.accent, 0.06) : Theme.alpha(Theme.surface, 0.50))
                        border.color: window.nativeChecked
                                      ? Theme.alpha(Theme.accent, 0.40)
                                      : Theme.alpha(Theme.foreground, 0.08)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12

                            // Native SVG icon container
                            Rectangle {
                                width: 34
                                height: 34
                                radius: 8
                                color: Theme.alpha(Theme.accent, 0.12)
                                border.color: Theme.alpha(Theme.accent, 0.25)
                                border.width: 1

                                Image {
                                    anchors.centerIn: parent
                                    width: 18
                                    height: 18
                                    source: window.nativeManagerSvg(window.nativeType)
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    spacing: 8
                                    Text {
                                        text: window.nativeName
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.foreground
                                    }
                                    Rectangle {
                                        height: 16
                                        implicitWidth: nativeBadge.implicitWidth + 8
                                        radius: 8
                                        color: window.nativeCount > 0 ? Theme.alpha(Theme.accent, 0.20) : Theme.alpha("#22c55e", 0.15)
                                        Text {
                                            id: nativeBadge
                                            anchors.centerIn: parent
                                            text: window.isChecking ? "checking" : (window.nativeCount > 0 ? (window.nativeCount + " updates") : "up to date")
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: window.nativeCount > 0 ? Theme.accent : "#22c55e"
                                        }
                                    }
                                }

                                Text {
                                    text: window.nativeDesc
                                    font.pixelSize: 10
                                    color: Theme.muted
                                }
                            }

                            // Custom Obsidian Checkbox
                            Rectangle {
                                width: 22
                                height: 22
                                radius: 6
                                color: window.nativeChecked ? Theme.accent : "transparent"
                                border.color: window.nativeChecked ? Theme.accent : Theme.alpha(Theme.foreground, 0.30)
                                border.width: 1.5

                                Image {
                                    anchors.centerIn: parent
                                    width: 12
                                    height: 12
                                    source: window.checkSvg
                                    visible: window.nativeChecked
                                }
                            }
                        }

                        MouseArea {
                            id: nativeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                window.nativeChecked = !window.nativeChecked
                            }
                        }
                    }

                    // 2. AUR Card (Visible only when available)
                    Rectangle {
                        visible: window.aurAvailable
                        Layout.fillWidth: true
                        height: 62
                        radius: 12
                        color: aurArea.containsMouse
                               ? Theme.alpha(Theme.surface, 0.90)
                               : (window.aurChecked ? Theme.alpha(Theme.accent, 0.06) : Theme.alpha(Theme.surface, 0.50))
                        border.color: window.aurChecked
                                      ? Theme.alpha(Theme.accent, 0.40)
                                      : Theme.alpha(Theme.foreground, 0.08)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12

                            // AUR SVG icon container
                            Rectangle {
                                width: 34
                                height: 34
                                radius: 8
                                color: Theme.alpha(Theme.accent, 0.12)
                                border.color: Theme.alpha(Theme.accent, 0.25)
                                border.width: 1

                                Image {
                                    anchors.centerIn: parent
                                    width: 18
                                    height: 18
                                    source: window.aurSvg
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    spacing: 8
                                    Text {
                                        text: "AUR (" + window.aurHelper + ")"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.foreground
                                    }
                                    Rectangle {
                                        height: 16
                                        implicitWidth: aurBadge.implicitWidth + 8
                                        radius: 8
                                        color: window.aurCount > 0 ? Theme.alpha(Theme.accent, 0.20) : Theme.alpha("#22c55e", 0.15)
                                        Text {
                                            id: aurBadge
                                            anchors.centerIn: parent
                                            text: window.isChecking ? "checking" : (window.aurCount > 0 ? (window.aurCount + " updates") : "up to date")
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: window.aurCount > 0 ? Theme.accent : "#22c55e"
                                        }
                                    }
                                }

                                Text {
                                    text: "Arch User Repository via " + window.aurHelper
                                    font.pixelSize: 10
                                    color: Theme.muted
                                }
                            }

                            // Custom Obsidian Checkbox
                            Rectangle {
                                width: 22
                                height: 22
                                radius: 6
                                color: window.aurChecked ? Theme.accent : "transparent"
                                border.color: window.aurChecked ? Theme.accent : Theme.alpha(Theme.foreground, 0.30)
                                border.width: 1.5

                                Image {
                                    anchors.centerIn: parent
                                    width: 12
                                    height: 12
                                    source: window.checkSvg
                                    visible: window.aurChecked
                                }
                            }
                        }

                        MouseArea {
                            id: aurArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                window.aurChecked = !window.aurChecked
                            }
                        }
                    }

                    // 3. Flatpak Card (Optional)
                    Rectangle {
                        visible: window.flatpakAvailable || window.flatpakCount > 0
                        Layout.fillWidth: true
                        height: 62
                        radius: 12
                        color: flatpakArea.containsMouse
                               ? Theme.alpha(Theme.surface, 0.90)
                               : (window.flatpakChecked ? Theme.alpha(Theme.accent, 0.06) : Theme.alpha(Theme.surface, 0.50))
                        border.color: window.flatpakChecked
                                      ? Theme.alpha(Theme.accent, 0.40)
                                      : Theme.alpha(Theme.foreground, 0.08)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12

                            Rectangle {
                                width: 34
                                height: 34
                                radius: 8
                                color: Theme.alpha(Theme.accent, 0.12)
                                border.color: Theme.alpha(Theme.accent, 0.25)
                                border.width: 1

                                Image {
                                    anchors.centerIn: parent
                                    width: 18
                                    height: 18
                                    source: window.flatpakSvg
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    spacing: 8
                                    Text {
                                        text: "Flatpak"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.foreground
                                    }
                                    Rectangle {
                                        height: 16
                                        implicitWidth: flatBadge.implicitWidth + 8
                                        radius: 8
                                        color: window.flatpakCount > 0 ? Theme.alpha(Theme.accent, 0.20) : Theme.alpha("#22c55e", 0.15)
                                        Text {
                                            id: flatBadge
                                            anchors.centerIn: parent
                                            text: window.flatpakCount > 0 ? (window.flatpakCount + " updates") : "up to date"
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: window.flatpakCount > 0 ? Theme.accent : "#22c55e"
                                        }
                                    }
                                }

                                Text {
                                    text: "Flathub application updates"
                                    font.pixelSize: 10
                                    color: Theme.muted
                                }
                            }

                            Rectangle {
                                width: 22
                                height: 22
                                radius: 6
                                color: window.flatpakChecked ? Theme.accent : "transparent"
                                border.color: window.flatpakChecked ? Theme.accent : Theme.alpha(Theme.foreground, 0.30)
                                border.width: 1.5

                                Image {
                                    anchors.centerIn: parent
                                    width: 12
                                    height: 12
                                    source: window.checkSvg
                                    visible: window.flatpakChecked
                                }
                            }
                        }

                        MouseArea {
                            id: flatpakArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                window.flatpakChecked = !window.flatpakChecked
                            }
                        }
                    }
                }
            }

            // ── ACTION BUTTONS ROW ───────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Primary "Update Selected" button
                Rectangle {
                    Layout.preferredWidth: 200
                    height: 38
                    radius: 10
                    enabled: !window.isUpdating && window.selectedCount > 0
                    opacity: enabled ? 1.0 : 0.40
                    color: updateBtnArea.containsMouse ? Qt.lighter(Theme.accent, 1.15) : Theme.accent

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Image {
                            width: 16
                            height: 16
                            source: window.updateSvg
                        }

                        Text {
                            text: window.isUpdating ? "Applying Updates…" : ("Update Selected (" + window.selectedCount + ")")
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.background
                        }
                    }

                    MouseArea {
                        id: updateBtnArea
                        anchors.fill: parent
                        hoverEnabled: parent.enabled
                        cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: window.startUpdate()
                    }
                }

                // "Skip for now" / Close ghost button
                Rectangle {
                    Layout.preferredWidth: 120
                    height: 38
                    radius: 10
                    color: skipArea.containsMouse ? Theme.alpha(Theme.surface, 0.85) : Theme.alpha(Theme.surface, 0.45)
                    border.color: Theme.alpha(Theme.foreground, 0.12)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Skip for now"
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.foreground
                    }

                    MouseArea {
                        id: skipArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.quit()
                    }
                }

                Item { Layout.fillWidth: true }

                // Polkit Notice with Shield Icon
                RowLayout {
                    spacing: 6
                    opacity: 0.70

                    Image {
                        width: 13
                        height: 13
                        source: window.shieldSvg
                    }

                    Text {
                        text: "Polkit island authentication supported"
                        font.pixelSize: 10
                        font.family: "Outfit"
                        color: Theme.muted
                    }
                }
            }

            // ── BOTTOM LOG & PREVIEW TERMINAL FRAME ───────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: "#08080c"
                border.color: Theme.alpha(Theme.foreground, 0.10)
                border.width: 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Terminal Header Bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        color: Theme.alpha(Theme.surface, 0.50)
                        border.color: Theme.alpha(Theme.foreground, 0.08)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            // 3 Mac-style window dots
                            RowLayout {
                                spacing: 6
                                Rectangle { width: 9; height: 9; radius: 5; color: "#ff5f56" }
                                Rectangle { width: 9; height: 9; radius: 5; color: "#ffbd2e" }
                                Rectangle { width: 9; height: 9; radius: 5; color: "#27c93f" }
                            }

                            Item { Layout.fillWidth: true }

                            // Segmented Tab Switcher: [ Pending Packages ] | [ Live Output ]
                            Rectangle {
                                height: 30
                                radius: 8
                                color: Theme.alpha(Theme.surface, 0.45)
                                border.color: Theme.alpha(Theme.foreground, 0.08)
                                border.width: 1
                                implicitWidth: tabRow.implicitWidth + 8

                                Row {
                                    id: tabRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    // Tab 0: Pending Packages
                                    Rectangle {
                                        id: tab0Btn
                                        height: 24
                                        implicitWidth: tab0Content.implicitWidth + 20
                                        radius: 6
                                        color: window.activeBottomTab === 0
                                               ? Theme.alpha(Theme.accent, 0.22)
                                               : (tab0Area.containsMouse ? Theme.alpha(Theme.foreground, 0.06) : "transparent")
                                        border.color: window.activeBottomTab === 0 ? Theme.alpha(Theme.accent, 0.45) : "transparent"
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: 140 } }
                                        Behavior on border.color { ColorAnimation { duration: 140 } }

                                        Row {
                                            id: tab0Content
                                            anchors.centerIn: parent
                                            spacing: 6

                                            Image {
                                                width: 13
                                                height: 13
                                                sourceSize: Qt.size(13, 13)
                                                fillMode: Image.PreserveAspectFit
                                                anchors.verticalCenter: parent.verticalCenter
                                                source: window.packageTabSvg(window.activeBottomTab === 0)
                                            }

                                            Text {
                                                id: tab0Text
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Pending Packages (" + window.totalUpdates + ")"
                                                font.pixelSize: 11
                                                font.family: "Outfit"
                                                font.bold: window.activeBottomTab === 0
                                                color: window.activeBottomTab === 0 ? Theme.accent : Theme.muted
                                            }
                                        }

                                        MouseArea {
                                            id: tab0Area
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: window.activeBottomTab = 0
                                        }
                                    }

                                    // Tab 1: Live Output
                                    Rectangle {
                                        id: tab1Btn
                                        height: 24
                                        implicitWidth: tab1Content.implicitWidth + 20
                                        radius: 6
                                        color: window.activeBottomTab === 1
                                               ? Theme.alpha(Theme.accent, 0.22)
                                               : (tab1Area.containsMouse ? Theme.alpha(Theme.foreground, 0.06) : "transparent")
                                        border.color: window.activeBottomTab === 1 ? Theme.alpha(Theme.accent, 0.45) : "transparent"
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: 140 } }
                                        Behavior on border.color { ColorAnimation { duration: 140 } }

                                        Row {
                                            id: tab1Content
                                            anchors.centerIn: parent
                                            spacing: 6

                                            Image {
                                                width: 13
                                                height: 13
                                                sourceSize: Qt.size(13, 13)
                                                fillMode: Image.PreserveAspectFit
                                                anchors.verticalCenter: parent.verticalCenter
                                                source: window.terminalTabSvg(window.activeBottomTab === 1)
                                            }

                                            Text {
                                                id: tab1Text
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Live Output"
                                                font.pixelSize: 11
                                                font.family: "Outfit"
                                                font.bold: window.activeBottomTab === 1
                                                color: window.activeBottomTab === 1 ? Theme.accent : Theme.muted
                                            }
                                        }

                                        MouseArea {
                                            id: tab1Area
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: window.activeBottomTab = 1
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Action: Clear Terminal (Visible in tab 1)
                            Rectangle {
                                visible: window.activeBottomTab === 1 && logModel.count > 0
                                height: 22
                                implicitWidth: 22
                                radius: 5
                                color: clearArea.containsMouse ? Theme.alpha(Theme.foreground, 0.12) : "transparent"

                                Image {
                                    anchors.centerIn: parent
                                    width: 12
                                    height: 12
                                    source: window.trashSvg
                                }

                                MouseArea {
                                    id: clearArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: window.clearLog()
                                }
                            }
                        }
                    }

                    // ── TAB CONTENT ──────────────────────────────────────────
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        // ── TAB 0: PENDING PACKAGES PREVIEW ──────────────────
                        Item {
                            anchors.fill: parent
                            visible: window.activeBottomTab === 0

                            // Filtered package list helper
                            readonly property var allItems: {
                                var res = []
                                for (var i = 0; i < window.nativePkgs.length; i++) {
                                    res.push({
                                        source: window.nativeType,
                                        sourceLabel: window.nativeName.toUpperCase(),
                                        name: window.nativePkgs[i].name,
                                        oldVersion: window.nativePkgs[i].old || "",
                                        newVersion: window.nativePkgs[i].new || "latest"
                                    })
                                }
                                for (var j = 0; j < window.aurPkgs.length; j++) {
                                    res.push({
                                        source: "aur",
                                        sourceLabel: "AUR",
                                        name: window.aurPkgs[j].name,
                                        oldVersion: window.aurPkgs[j].old || "",
                                        newVersion: window.aurPkgs[j].new || "latest"
                                    })
                                }
                                for (var k = 0; k < window.flatpakPkgs.length; k++) {
                                    res.push({
                                        source: "flatpak",
                                        sourceLabel: "FLATPAK",
                                        name: window.flatpakPkgs[k].name,
                                        oldVersion: window.flatpakPkgs[k].old || "",
                                        newVersion: window.flatpakPkgs[k].new || "latest"
                                    })
                                }
                                return res
                            }

                            // Empty State
                            ColumnLayout {
                                anchors.centerIn: parent
                                visible: parent.allItems.length === 0 && !window.isChecking
                                spacing: 8

                                Image {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 32
                                    height: 32
                                    source: window.successCheckSvg
                                }

                                Text {
                                    text: "All packages are up to date"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Theme.foreground
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Text {
                                    text: "Your " + window.osInfo.name + " system has no pending updates right now."
                                    font.pixelSize: 11
                                    color: Theme.muted
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            // Loading state
                            ColumnLayout {
                                anchors.centerIn: parent
                                visible: window.isChecking
                                spacing: 8

                                Text {
                                    text: "Checking for updates across package sources…"
                                    font.pixelSize: 12
                                    color: Theme.muted
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            // Package List View
                            ListView {
                                id: pkgListView
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 4
                                clip: true
                                visible: parent.allItems.length > 0 && !window.isChecking
                                model: parent.allItems

                                delegate: Rectangle {
                                    width: pkgListView.width
                                    height: 34
                                    radius: 7
                                    color: pkgRowArea.containsMouse ? Theme.alpha(Theme.surface, 0.70) : Theme.alpha(Theme.surface, 0.25)
                                    border.color: pkgRowArea.containsMouse ? Theme.alpha(Theme.accent, 0.30) : Theme.alpha(Theme.foreground, 0.04)
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        spacing: 12

                                        // Source Tag
                                        Rectangle {
                                            width: 58
                                            height: 18
                                            radius: 4
                                            color: modelData.source === "pacman" ? Theme.alpha(Theme.accent, 0.16) : Theme.alpha("#a855f7", 0.16)
                                            border.color: modelData.source === "pacman" ? Theme.alpha(Theme.accent, 0.30) : Theme.alpha("#a855f7", 0.30)
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.sourceLabel
                                                font.pixelSize: 8
                                                font.bold: true
                                                color: modelData.source === "pacman" ? Theme.accent : "#c084fc"
                                            }
                                        }

                                        // Package Name
                                        Text {
                                            text: modelData.name
                                            font.pixelSize: 12
                                            font.bold: true
                                            font.family: "JetBrainsMono Nerd Font"
                                            color: Theme.foreground
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        // Old Version
                                        Text {
                                            text: modelData.oldVersion.length > 0 ? modelData.oldVersion : "current"
                                            font.pixelSize: 11
                                            font.family: "JetBrainsMono Nerd Font"
                                            color: Theme.muted
                                        }

                                        // Arrow
                                        Image {
                                            width: 12
                                            height: 12
                                            source: window.arrowRightSvg
                                        }

                                        // New Version
                                        Text {
                                            text: modelData.newVersion
                                            font.pixelSize: 11
                                            font.bold: true
                                            font.family: "JetBrainsMono Nerd Font"
                                            color: Theme.accent
                                        }
                                    }

                                    MouseArea {
                                        id: pkgRowArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                    }
                                }
                            }
                        }

                        // ── TAB 1: LIVE TERMINAL OUTPUT ──────────────────────
                        Item {
                            anchors.fill: parent
                            visible: window.activeBottomTab === 1

                            // Empty State / Idle info
                            Text {
                                anchors.centerIn: parent
                                visible: logModel.count === 0 && !window.isUpdating
                                text: "Click 'Update Selected' to begin applying package updates."
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"
                                color: Theme.muted
                            }

                            ListView {
                                id: logListView
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 2
                                clip: true
                                model: logModel

                                delegate: Text {
                                    width: logListView.width
                                    text: model.line
                                    textFormat: Text.StyledText
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono Nerd Font Mono, JetBrainsMono Nerd Font, monospace"
                                    renderType: Text.QtRendering
                                    antialiasing: true
                                    lineHeight: 1.25
                                    lineHeightMode: Text.ProportionalHeight
                                    color: Theme.alpha(Theme.foreground, 0.90)
                                    wrapMode: Text.WrapAnywhere
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
