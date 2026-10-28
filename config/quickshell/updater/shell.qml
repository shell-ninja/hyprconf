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
        return (h && h.length > 0) ? h : "/home/shell-ninja"
    }

    // ── STATE VARIABLES ──────────────────────────────────────────────────────
    property bool isChecking: true
    property bool isUpdating: false
    property bool updateCompleted: false
    property int updateExitCode: 0

    property var osInfo: ({ name: "Arch Linux", id: "arch" })
    property int totalUpdates: 0
    property int pacmanCount: 0
    property int aurCount: 0
    property int flatpakCount: 0

    property var pacmanPkgs: []
    property var aurPkgs: []
    property var flatpakPkgs: []

    property bool pacmanChecked: true
    property bool aurChecked: true
    property bool flatpakChecked: false

    property bool aurAvailable: false
    property string aurHelper: "paru"
    property bool flatpakAvailable: false

    // Bottom View Tab: 0 = Pending Packages Preview, 1 = Live Terminal Output
    property int activeBottomTab: 0
    property string searchFilter: ""

    // Computed total selected updates
    readonly property int selectedCount: {
        var cnt = 0
        if (pacmanChecked) cnt += pacmanCount
        if (aurChecked) cnt += aurCount
        if (flatpakChecked) cnt += flatpakCount
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

    function appendLog(line) {
        logModel.append({ "line": line })
        if (logListView.count > 0) {
            logListView.positionViewAtEnd()
        }
    }

    function clearLog() {
        logModel.clear()
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

                    if (data.pacman) {
                        window.pacmanCount = data.pacman.count || 0
                        window.pacmanPkgs = data.pacman.packages || []
                    }
                    if (data.aur) {
                        window.aurAvailable = data.aur.available || false
                        window.aurHelper = data.aur.helper || "paru"
                        window.aurCount = data.aur.count || 0
                        window.aurPkgs = data.aur.packages || []
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
        if (pacmanChecked && pacmanCount > 0) args.push("--pacman")
        if (aurChecked && aurCount > 0) args.push("--aur")
        if (flatpakChecked && flatpakCount > 0) args.push("--flatpak")

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
                            font.family: "Inter"
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
                        font.family: "Inter"
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
                        font.family: "Inter"
                        font.letterSpacing: -0.3
                        color: Theme.foreground
                    }

                    Text {
                        text: "Review package updates from all configured sources and apply them securely via Polkit."
                        font.pixelSize: 12
                        font.family: "Inter"
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

                    // Stat Card: Pacman
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
                                text: window.isChecking ? "…" : window.pacmanCount.toString()
                                font.pixelSize: 22
                                font.bold: true
                                color: window.pacmanCount > 0 ? Theme.accent : Theme.muted
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "PACMAN"
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.8
                                color: Theme.muted
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    // Stat Card: AUR
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

                    // 1. Pacman Card
                    Rectangle {
                        Layout.fillWidth: true
                        height: 62
                        radius: 12
                        color: pacmanArea.containsMouse
                               ? Theme.alpha(Theme.surface, 0.90)
                               : (window.pacmanChecked ? Theme.alpha(Theme.accent, 0.06) : Theme.alpha(Theme.surface, 0.50))
                        border.color: window.pacmanChecked
                                      ? Theme.alpha(Theme.accent, 0.40)
                                      : Theme.alpha(Theme.foreground, 0.08)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12

                            // Pacman SVG icon container
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
                                    source: window.pacmanSvg
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    spacing: 8
                                    Text {
                                        text: "Pacman"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.foreground
                                    }
                                    Rectangle {
                                        height: 16
                                        implicitWidth: pacBadge.implicitWidth + 8
                                        radius: 8
                                        color: window.pacmanCount > 0 ? Theme.alpha(Theme.accent, 0.20) : Theme.alpha("#22c55e", 0.15)
                                        Text {
                                            id: pacBadge
                                            anchors.centerIn: parent
                                            text: window.isChecking ? "checking" : (window.pacmanCount > 0 ? (window.pacmanCount + " updates") : "up to date")
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: window.pacmanCount > 0 ? Theme.accent : "#22c55e"
                                        }
                                    }
                                }

                                Text {
                                    text: "Official Arch Linux repositories"
                                    font.pixelSize: 10
                                    color: Theme.muted
                                }
                            }

                            // Custom Obsidian Checkbox
                            Rectangle {
                                width: 22
                                height: 22
                                radius: 6
                                color: window.pacmanChecked ? Theme.accent : "transparent"
                                border.color: window.pacmanChecked ? Theme.accent : Theme.alpha(Theme.foreground, 0.30)
                                border.width: 1.5

                                Image {
                                    anchors.centerIn: parent
                                    width: 12
                                    height: 12
                                    source: window.checkSvg
                                    visible: window.pacmanChecked
                                }
                            }
                        }

                        MouseArea {
                            id: pacmanArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                window.pacmanChecked = !window.pacmanChecked
                            }
                        }
                    }

                    // 2. AUR Card
                    Rectangle {
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
                        font.family: "Inter"
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

                            // Tab Switcher: [ Pending Packages ] | [ Live Output ]
                            RowLayout {
                                spacing: 4

                                // Tab 0: Pending Packages
                                Rectangle {
                                    height: 24
                                    implicitWidth: tab0Text.implicitWidth + 16
                                    radius: 6
                                    color: window.activeBottomTab === 0
                                           ? Theme.alpha(Theme.accent, 0.20)
                                           : (tab0Area.containsMouse ? Theme.alpha(Theme.foreground, 0.06) : "transparent")
                                    border.color: window.activeBottomTab === 0 ? Theme.alpha(Theme.accent, 0.40) : "transparent"
                                    border.width: 1

                                    Text {
                                        id: tab0Text
                                        anchors.centerIn: parent
                                        text: "Pending Packages (" + window.totalUpdates + ")"
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: window.activeBottomTab === 0 ? Theme.accent : Theme.muted
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
                                    height: 24
                                    implicitWidth: tab1Text.implicitWidth + 16
                                    radius: 6
                                    color: window.activeBottomTab === 1
                                           ? Theme.alpha(Theme.accent, 0.20)
                                           : (tab1Area.containsMouse ? Theme.alpha(Theme.foreground, 0.06) : "transparent")
                                    border.color: window.activeBottomTab === 1 ? Theme.alpha(Theme.accent, 0.40) : "transparent"
                                    border.width: 1

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 5
                                        Image {
                                            width: 11
                                            height: 11
                                            source: window.terminalSvg
                                        }
                                        Text {
                                            id: tab1Text
                                            text: "Live Output"
                                            font.pixelSize: 10
                                            font.bold: true
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
                                for (var i = 0; i < window.pacmanPkgs.length; i++) {
                                    res.push({
                                        source: "pacman",
                                        sourceLabel: "PACMAN",
                                        name: window.pacmanPkgs[i].name,
                                        oldVersion: window.pacmanPkgs[i].old,
                                        newVersion: window.pacmanPkgs[i].new
                                    })
                                }
                                for (var j = 0; j < window.aurPkgs.length; j++) {
                                    res.push({
                                        source: "aur",
                                        sourceLabel: "AUR",
                                        name: window.aurPkgs[j].name,
                                        oldVersion: window.aurPkgs[j].old,
                                        newVersion: window.aurPkgs[j].new
                                    })
                                }
                                for (var k = 0; k < window.flatpakPkgs.length; k++) {
                                    res.push({
                                        source: "flatpak",
                                        sourceLabel: "FLATPAK",
                                        name: window.flatpakPkgs[k].name,
                                        oldVersion: window.flatpakPkgs[k].old,
                                        newVersion: window.flatpakPkgs[k].new
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
                                    text: "Your Arch Linux system has no pending updates right now."
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
                                            font.family: "JetBrains Mono, Fira Code, monospace"
                                            color: Theme.foreground
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        // Old Version
                                        Text {
                                            text: modelData.oldVersion.length > 0 ? modelData.oldVersion : "current"
                                            font.pixelSize: 11
                                            font.family: "JetBrains Mono, Fira Code, monospace"
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
                                            font.family: "JetBrains Mono, Fira Code, monospace"
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
                                font.family: "JetBrains Mono, monospace"
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
                                    font.pixelSize: 11
                                    font.family: "JetBrains Mono, Fira Code, monospace"
                                    color: {
                                        var l = model.line
                                        if (l.indexOf("✓") !== -1 || l.indexOf("successfully") !== -1) return "#22c55e"
                                        if (l.indexOf("✗") !== -1 || l.indexOf("failed") !== -1 || l.indexOf("error") !== -1) return "#ef4444"
                                        if (l.indexOf("::") === 0 || l.indexOf("==") === 0) return Theme.accent
                                        if (l.indexOf("━") !== -1) return Theme.alpha(Theme.foreground, 0.20)
                                        return Theme.alpha(Theme.foreground, 0.85)
                                    }
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
