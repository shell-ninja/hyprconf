//@ pragma Env QS_NO_RELOAD_POPUP=1
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "."

FloatingWindow {
    id: window
    title: "Welcome to Hyprconf"
    implicitWidth: 920
    implicitHeight: 660
    color: "transparent"
    onClosed: Qt.quit()

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    readonly property string versionTag: "v1.0.1"

    // Logo & Avatar paths
    readonly property string brandLogoPath: "file://" + homeDir + "/.hyprconf/hypr/.cache/shell-ninja.png"
    readonly property string faceAvatarPath: "file://" + homeDir + "/.hyprconf/hypr/.cache/.face"

    // ── STATE VARIABLES ──────────────────────────────────────────────────────
    property int activePage: 0 // 0: Overview, 1: What's New, 2: Shortcuts, 3: Apps, 4: Finish
    property bool showOnStartup: true
    property string shortcutSearch: ""

    // ── SVG ASSETS ───────────────────────────────────────────────────────────
    function svgUrl(content) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(content)
    }

    readonly property string closeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>')
    readonly property string sparkSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m12 3-1.912 5.813a2 2 0 0 1-1.275 1.275L3 12l5.813 1.912a2 2 0 0 1 1.275 1.275L12 21l1.912-5.813a2 2 0 0 1 1.275-1.275L21 12l-5.813-1.912a2 2 0 0 1-1.275-1.275L12 3Z"/></svg>')
    readonly property string arrowRightSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.background + '" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>')
    readonly property string arrowLeftSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>')
    readonly property string checkSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>')
    readonly property string weatherSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"/></svg>')
    readonly property string packageSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg>')
    readonly property string shieldSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>')
    readonly property string speedSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>')
    readonly property string keyboardSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="M6 8h.01M10 8h.01M14 8h.01M18 8h.01M8 12h.01M12 12h.01M16 12h.01M7 16h10"/></svg>')
    readonly property string slidersSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="21" y1="4" x2="14" y2="4"/><line x1="10" y1="4" x2="3" y2="4"/><line x1="21" y1="12" x2="12" y2="12"/><line x1="8" y1="12" x2="3" y2="12"/><line x1="21" y1="20" x2="16" y2="20"/><line x1="12" y1="20" x2="3" y2="20"/><line x1="14" y1="2" x2="14" y2="6"/><line x1="8" y1="10" x2="8" y2="14"/><line x1="16" y1="18" x2="16" y2="22"/></svg>')
    readonly property string searchSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.muted + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>')
    readonly property string bookSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20"/></svg>')
    readonly property string gitSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="18" cy="18" r="3"/><circle cx="6" cy="6" r="3"/><path d="M13 6h3a2 2 0 0 1 2 2v7"/><line x1="6" y1="9" x2="6" y2="21"/></svg>')
    readonly property string playSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="5 3 19 12 5 21 5 3"/></svg>')

    // ── IPC HANDLER ──────────────────────────────────────────────────────────
    IpcHandler {
        target: "welcome"
        function raise() {
            window.visible = true
        }
        function nextPage() {
            if (window.activePage < 4) window.activePage++
        }
        function prevPage() {
            if (window.activePage > 0) window.activePage--
        }
        function openOverview() { window.activePage = 0 }
        function openWhatsNew() { window.activePage = 1 }
        function openShortcuts() { window.activePage = 2 }
        function openApps() { window.activePage = 3 }
        function openGetStarted() { window.activePage = 4 }
        function close() {
            Qt.quit()
        }
    }

    // ── KEYBOARD SHORTCUTS ───────────────────────────────────────────────────
    Shortcut {
        sequence: "Escape"
        onActivated: Qt.quit()
    }

    Shortcut {
        sequence: "Left"
        onActivated: {
            if (window.activePage > 0) window.activePage--
        }
    }

    Shortcut {
        sequence: "Right"
        onActivated: {
            if (window.activePage < 4) window.activePage++
        }
    }

    // ── STATE PERSISTENCE (welcome-app.json) ──────────────────────────────────
    Process {
        id: stateReader
        command: ["python3", "-c", "import json, os; p1=os.path.expanduser('~/.local/share/hyprconf/welcome-app.json'); p2=os.path.expanduser('~/.hyprconf/hypr/welcome-app.json'); p=p1 if os.path.exists(p1) else (p2 if os.path.exists(p2) else None); print(open(p).read() if p else '{\"show_on_startup\": true}')"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var data = JSON.parse(text.trim())
                    window.showOnStartup = (data.show_on_startup !== false)
                } catch(e) {}
            }
        }
    }

    Process {
        id: stateWriter
    }

    function toggleStartupState(enabled) {
        window.showOnStartup = enabled
        stateWriter.command = [
            "python3", "-c",
            "import json, os; val={'show_on_startup': " + (enabled ? "True" : "False") + "}; " +
            "paths = [os.path.expanduser('~/.local/share/hyprconf/welcome-app.json'), os.path.expanduser('~/.hyprconf/hypr/welcome-app.json')]; " +
            "[os.makedirs(os.path.dirname(p), exist_ok=True) or open(p, 'w').write(json.dumps(val, indent=2)) for p in paths]"
        ]
        stateWriter.running = false
        stateWriter.running = true
    }

    // ── DISPATCH HELPER ──────────────────────────────────────────────────────
    Process {
        id: execDispatcher
    }

    function dispatchCmd(cmd) {
        if (!cmd || cmd.length === 0) return
        execDispatcher.command = ["bash", "-c", cmd]
        execDispatcher.running = false
        execDispatcher.running = true
    }

    // ── MAIN OBSIDIAN GLASS SURFACE ──────────────────────────────────────────
    Rectangle {
        id: rootSurface
        anchors.fill: parent
        color: Theme.alpha(Theme.background, 0.95)
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
            anchors.margins: 20
            spacing: 16

            // ── TOP HEADER / NAV BAR ─────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                spacing: 12

                // Left: Avatar / Brand
                RowLayout {
                    spacing: 10

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: Theme.alpha(Theme.surface, 0.80)
                        border.color: Theme.alpha(Theme.accent, 0.35)
                        border.width: 1

                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: window.brandLogoPath
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                        }
                    }

                    ColumnLayout {
                        spacing: 0
                        RowLayout {
                            spacing: 6
                            Text {
                                text: "Hyprconf"
                                font.pixelSize: 14
                                font.bold: true
                                font.family: "Inter"
                                font.letterSpacing: -0.3
                                color: Theme.foreground
                            }
                            Rectangle {
                                height: 16
                                implicitWidth: verText.implicitWidth + 8
                                radius: 8
                                color: Theme.alpha(Theme.accent, 0.16)
                                border.color: Theme.alpha(Theme.accent, 0.35)
                                border.width: 1
                                Text {
                                    id: verText
                                    anchors.centerIn: parent
                                    text: window.versionTag
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Theme.accent
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Center: Minimal Segmented Navigation Pills
                Rectangle {
                    height: 34
                    implicitWidth: navRow.implicitWidth + 8
                    radius: 10
                    color: Theme.alpha(Theme.surface, 0.60)
                    border.color: Theme.alpha(Theme.foreground, 0.08)
                    border.width: 1

                    RowLayout {
                        id: navRow
                        anchors.centerIn: parent
                        spacing: 2

                        Repeater {
                            model: [
                                { label: "Overview", page: 0 },
                                { label: "What's New", page: 1, isNew: true },
                                { label: "Shortcuts", page: 2 },
                                { label: "Apps", page: 3 },
                                { label: "Get Started", page: 4 }
                            ]

                            Rectangle {
                                height: 28
                                implicitWidth: tabLabel.implicitWidth + (modelData.isNew ? 28 : 20)
                                radius: 8
                                color: window.activePage === modelData.page
                                       ? Theme.alpha(Theme.accent, 0.20)
                                       : (tabHoverArea.containsMouse ? Theme.alpha(Theme.foreground, 0.06) : "transparent")
                                border.color: window.activePage === modelData.page ? Theme.alpha(Theme.accent, 0.40) : "transparent"
                                border.width: 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Text {
                                        id: tabLabel
                                        text: modelData.label
                                        font.pixelSize: 11
                                        font.bold: window.activePage === modelData.page
                                        font.family: "Inter"
                                        color: window.activePage === modelData.page ? Theme.accent : Theme.muted
                                    }

                                    // Glowing "NEW" indicator dot
                                    Rectangle {
                                        visible: modelData.isNew === true
                                        width: 6
                                        height: 6
                                        radius: 3
                                        color: Theme.accent
                                    }
                                }

                                MouseArea {
                                    id: tabHoverArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: window.activePage = modelData.page
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Right: Close Button
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

            // ── PAGE VIEW CONTAINER ──────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                // ═════════════════════════════════════════════════════════════
                // PAGE 0: OVERVIEW
                // ═════════════════════════════════════════════════════════════
                ColumnLayout {
                    anchors.fill: parent
                    visible: window.activePage === 0
                    spacing: 20

                    Item { Layout.fillHeight: true }

                    // Hero Cluster
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 12

                        // Obsidian glowing avatar halo
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 88
                            height: 88
                            radius: 44
                            color: Theme.alpha(Theme.surface, 0.90)
                            border.color: Theme.alpha(Theme.accent, 0.40)
                            border.width: 1.5

                            Rectangle {
                                anchors.centerIn: parent
                                width: 76
                                height: 76
                                radius: 38
                                color: Theme.alpha(Theme.background, 0.80)
                                border.color: Theme.alpha(Theme.accent, 0.20)
                                border.width: 1

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    source: window.brandLogoPath
                                    fillMode: Image.PreserveAspectFit
                                    mipmap: true
                                }
                            }
                        }

                        Text {
                            text: "Welcome to Hyprconf"
                            font.pixelSize: 26
                            font.bold: true
                            font.family: "Inter"
                            font.letterSpacing: -0.5
                            color: Theme.foreground
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "A minimalist, obsidian-themed Hyprland desktop environment built natively with Quickshell."
                            font.pixelSize: 13
                            font.family: "Inter"
                            color: Theme.muted
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            Layout.maximumWidth: 540
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    // 3 Core Pillars Cards
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 120
                        spacing: 14

                        // Pillar 1: Pure Quickshell
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            color: Theme.alpha(Theme.surface, 0.65)
                            border.color: Theme.alpha(Theme.foreground, 0.08)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 8

                                RowLayout {
                                    spacing: 8
                                    Image { width: 16; height: 16; source: window.speedSvg }
                                    Text {
                                        text: "Pure Quickshell"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.foreground
                                    }
                                }
                                Text {
                                    text: "100% native Qt6/QML Wayland layer surfaces for Dynamic Island, Dock, Launcher, and Lockscreen."
                                    font.pixelSize: 11
                                    color: Theme.muted
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        // Pillar 2: Obsidian Palette
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            color: Theme.alpha(Theme.surface, 0.65)
                            border.color: Theme.alpha(Theme.foreground, 0.08)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 8

                                RowLayout {
                                    spacing: 8
                                    Image { width: 16; height: 16; source: window.sparkSvg }
                                    Text {
                                        text: "Obsidian Harmony"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.foreground
                                    }
                                }
                                Text {
                                    text: "Dynamic wallpaper color quantization with 7 Noctalia harmony modes and zero generic emojis."
                                    font.pixelSize: 11
                                    color: Theme.muted
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        // Pillar 3: Physical Springs
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            color: Theme.alpha(Theme.surface, 0.65)
                            border.color: Theme.alpha(Theme.foreground, 0.08)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 8

                                RowLayout {
                                    spacing: 8
                                    Image { width: 16; height: 16; source: window.slidersSvg }
                                    Text {
                                        text: "Spring Physics"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.foreground
                                    }
                                }
                                Text {
                                    text: "Natural physical spring damping on notch expansions, dock slide-outs, and window gestures."
                                    font.pixelSize: 11
                                    color: Theme.muted
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }

                // ═════════════════════════════════════════════════════════════
                // PAGE 1: WHAT'S NEW IN v1.0.1 (USER HIGHLIGHT PAGE)
                // ═════════════════════════════════════════════════════════════
                ColumnLayout {
                    anchors.fill: parent
                    visible: window.activePage === 1
                    spacing: 14

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ColumnLayout {
                            spacing: 2
                            RowLayout {
                                spacing: 8
                                Text {
                                    text: "What's New in v1.0.1"
                                    font.pixelSize: 20
                                    font.bold: true
                                    font.family: "Inter"
                                    font.letterSpacing: -0.3
                                    color: Theme.foreground
                                }
                                Rectangle {
                                    height: 18
                                    implicitWidth: relPill.implicitWidth + 10
                                    radius: 9
                                    color: Theme.alpha(Theme.accent, 0.16)
                                    border.color: Theme.alpha(Theme.accent, 0.35)
                                    border.width: 1
                                    Text {
                                        id: relPill
                                        anchors.centerIn: parent
                                        text: "RELEASE HIGHLIGHTS"
                                        font.pixelSize: 9
                                        font.bold: true
                                        font.letterSpacing: 0.5
                                        color: Theme.accent
                                    }
                                }
                            }
                            Text {
                                text: "Pure Quickshell migration milestones, new desktop modules, and native Polkit authentication."
                                font.pixelSize: 12
                                color: Theme.muted
                            }
                        }
                    }

                    // 4 Feature Highlight Cards (2x2 Grid)
                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 2
                        columnSpacing: 12
                        rowSpacing: 12

                        // Feature 1: Dynamic Island Weather Page
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            color: Theme.alpha(Theme.surface, 0.65)
                            border.color: Theme.alpha(Theme.accent, 0.25)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 6

                                RowLayout {
                                    spacing: 8
                                    Rectangle {
                                        width: 30
                                        height: 30
                                        radius: 8
                                        color: Theme.alpha(Theme.accent, 0.14)
                                        Image { anchors.centerIn: parent; width: 16; height: 16; source: window.weatherSvg }
                                    }
                                    ColumnLayout {
                                        spacing: 1
                                        Text { text: "Island Weather System"; font.pixelSize: 13; font.bold: true; color: Theme.foreground }
                                        Text { text: "Open-Meteo 7-Day Forecast"; font.pixelSize: 10; color: Theme.accent }
                                    }
                                }

                                Text {
                                    text: "Embedded Page 1 of notch carousel. Provides live temperature, 7-day outlook, wind, humidity, and hourly metrics with zero external API key requirements."
                                    font.pixelSize: 11
                                    color: Theme.muted
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        // Feature 2: Native Package Updater
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            color: Theme.alpha(Theme.surface, 0.65)
                            border.color: Theme.alpha(Theme.accent, 0.25)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 6

                                RowLayout {
                                    spacing: 8
                                    Rectangle {
                                        width: 30
                                        height: 30
                                        radius: 8
                                        color: Theme.alpha(Theme.accent, 0.14)
                                        Image { anchors.centerIn: parent; width: 16; height: 16; source: window.packageSvg }
                                    }
                                    ColumnLayout {
                                        spacing: 1
                                        Text { text: "Native Package Updater"; font.pixelSize: 13; font.bold: true; color: Theme.foreground }
                                        Text { text: "Quickshell Desktop App"; font.pixelSize: 10; color: Theme.accent }
                                    }
                                }

                                Text {
                                    text: "Rebuilt from GTK4 into native Quickshell. Scans official Pacman, AUR (paru/yay), and Flatpak in parallel with real-time terminal streaming and package delta inspection."
                                    font.pixelSize: 11
                                    color: Theme.muted
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        // Feature 3: Polkit in Dynamic Island
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            color: Theme.alpha(Theme.surface, 0.65)
                            border.color: Theme.alpha(Theme.accent, 0.25)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 6

                                RowLayout {
                                    spacing: 8
                                    Rectangle {
                                        width: 30
                                        height: 30
                                        radius: 8
                                        color: Theme.alpha(Theme.accent, 0.14)
                                        Image { anchors.centerIn: parent; width: 16; height: 16; source: window.shieldSvg }
                                    }
                                    ColumnLayout {
                                        spacing: 1
                                        Text { text: "Dynamic Island Polkit"; font.pixelSize: 13; font.bold: true; color: Theme.foreground }
                                        Text { text: "Seamless Notch Authentication"; font.pixelSize: 10; color: Theme.accent }
                                    }
                                }

                                Text {
                                    text: "All privileged actions (pkexec, updates, disk managers) invoke Quickshell Island's native PolkitAgent. The notch expands smoothly for password input with physical shake-on-fail."
                                    font.pixelSize: 11
                                    color: Theme.muted
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        // Feature 4: Unified Shortcuts & Physics
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            color: Theme.alpha(Theme.surface, 0.65)
                            border.color: Theme.alpha(Theme.accent, 0.25)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 6

                                RowLayout {
                                    spacing: 8
                                    Rectangle {
                                        width: 30
                                        height: 30
                                        radius: 8
                                        color: Theme.alpha(Theme.accent, 0.14)
                                        Image { anchors.centerIn: parent; width: 16; height: 16; source: window.speedSvg }
                                    }
                                    ColumnLayout {
                                        spacing: 1
                                        Text { text: "Single-Event Escape Logic"; font.pixelSize: 13; font.bold: true; color: Theme.foreground }
                                        Text { text: "Reliable View Dismissal"; font.pixelSize: 10; color: Theme.accent }
                                    }
                                }

                                Text {
                                    text: "Eliminated ambiguous shortcut collisions across nested views. Pressing Esc at any time instantly collapses expanded search inputs, launchers, and full-screen modals."
                                    font.pixelSize: 11
                                    color: Theme.muted
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }

                // ═════════════════════════════════════════════════════════════
                // PAGE 2: SHORTCUTS (INTERACTIVE)
                // ═════════════════════════════════════════════════════════════
                ColumnLayout {
                    anchors.fill: parent
                    visible: window.activePage === 2
                    spacing: 12

                    // Top Search & Title Bar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ColumnLayout {
                            spacing: 1
                            Text {
                                text: "Essential Keybindings"
                                font.pixelSize: 20
                                font.bold: true
                                font.family: "Inter"
                                font.letterSpacing: -0.3
                                color: Theme.foreground
                            }
                            Text {
                                text: "Click any shortcut row to run the command immediately."
                                font.pixelSize: 12
                                color: Theme.muted
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Search Box
                        Rectangle {
                            width: 220
                            height: 32
                            radius: 8
                            color: Theme.alpha(Theme.surface, 0.65)
                            border.color: searchInput.activeFocus ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 6

                                Image { width: 12; height: 12; source: window.searchSvg }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    TextInput {
                                        id: searchInput
                                        anchors.fill: parent
                                        verticalAlignment: TextInput.AlignVCenter
                                        font.pixelSize: 11
                                        font.family: "Inter"
                                        color: Theme.foreground
                                        clip: true
                                        onTextChanged: window.shortcutSearch = text.toLowerCase().trim()
                                    }

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "Search…"
                                        font.pixelSize: 11
                                        color: Theme.muted
                                        visible: searchInput.text.length === 0
                                    }
                                }
                            }
                        }
                    }

                    // Keybinds Model Helper
                    readonly property var rawBinds: [
                        { title: "Terminal", desc: "Open Kitty terminal emulator", keys: ["Super", "Enter"], cmd: "kitty &" },
                        { title: "Floating Terminal", desc: "Open Kitty in a floating window", keys: ["Super", "Shift", "Enter"], cmd: "hyprctl dispatch exec [float] kitty" },
                        { title: "File Manager", desc: "Launch Dolphin file explorer", keys: ["Super", "E"], cmd: "dolphin &" },
                        { title: "Application Launcher", desc: "Toggle Dynamic Island panoramic launcher", keys: ["Super", "D"], cmd: "qs ipc -c island call island toggleLauncher" },
                        { title: "Wallpaper Studio", desc: "Browse and apply wallpapers with live palette generation", keys: ["Super", "Shift", "W"], cmd: "qs ipc -c island call island openWallpaper" },
                        { title: "Settings Studio", desc: "Open Quickshell unified Settings Studio", keys: ["Super", "S"], cmd: "bash ~/.hyprconf/hypr/scripts/sh/qs-settings.sh &" },
                        { title: "Package Updater", desc: "Open native Quickshell package updater", keys: ["Ctrl", "U"], cmd: "bash ~/.hyprconf/hypr/scripts/sh/qs-updater.sh &" },
                        { title: "Keybinds Cheatsheet", desc: "Display full interactive cheatsheet overlay", keys: ["Super", "Shift", "H"], cmd: "qs ipc -c island call island openKeybinds" },
                        { title: "Reload Desktop Shell", desc: "Clean restart Island, Dock, and Widgets in sequence", keys: ["Ctrl", "Esc"], cmd: "bash ~/.hyprconf/hypr/scripts/sh/qs-reload.sh &" }
                    ]

                    readonly property var filteredBinds: {
                        var list = rawBinds
                        if (!window.shortcutSearch || window.shortcutSearch.length === 0) return list
                        var res = []
                        for (var i = 0; i < list.length; i++) {
                            var item = list[i]
                            if (item.title.toLowerCase().indexOf(window.shortcutSearch) !== -1 ||
                                item.desc.toLowerCase().indexOf(window.shortcutSearch) !== -1) {
                                res.push(item)
                            }
                        }
                        return res
                    }

                    // Shortcut List
                    ListView {
                        id: bindListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 6
                        clip: true
                        model: parent.filteredBinds

                        delegate: Rectangle {
                            width: bindListView.width
                            height: 48
                            radius: 10
                            color: bindArea.containsMouse ? Theme.alpha(Theme.surface, 0.85) : Theme.alpha(Theme.surface, 0.40)
                            border.color: bindArea.containsMouse ? Theme.alpha(Theme.accent, 0.35) : Theme.alpha(Theme.foreground, 0.06)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 12

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: modelData.title
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.foreground
                                    }
                                    Text {
                                        text: modelData.desc
                                        font.pixelSize: 10
                                        color: Theme.muted
                                    }
                                }

                                // Keycaps Pill Cluster
                                RowLayout {
                                    spacing: 4

                                    Repeater {
                                        model: modelData.keys

                                        Rectangle {
                                            height: 22
                                            implicitWidth: kbdText.implicitWidth + 12
                                            radius: 6
                                            color: Theme.alpha(Theme.accent, 0.16)
                                            border.color: Theme.alpha(Theme.accent, 0.35)
                                            border.width: 1

                                            Text {
                                                id: kbdText
                                                anchors.centerIn: parent
                                                text: modelData
                                                font.pixelSize: 10
                                                font.bold: true
                                                font.family: "JetBrains Mono, monospace"
                                                color: Theme.accent
                                            }
                                        }
                                    }
                                }

                                // Run Icon
                                Rectangle {
                                    width: 26
                                    height: 26
                                    radius: 6
                                    color: bindArea.containsMouse ? Theme.alpha(Theme.accent, 0.20) : "transparent"
                                    visible: bindArea.containsMouse

                                    Image {
                                        anchors.centerIn: parent
                                        width: 12
                                        height: 12
                                        source: window.playSvg
                                    }
                                }
                            }

                            MouseArea {
                                id: bindArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: window.dispatchCmd(modelData.cmd)
                            }
                        }
                    }
                }

                // ═════════════════════════════════════════════════════════════
                // PAGE 3: APPLICATIONS & DOCS
                // ═════════════════════════════════════════════════════════════
                ColumnLayout {
                    anchors.fill: parent
                    visible: window.activePage === 3
                    spacing: 14

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "Built-in Applications"
                            font.pixelSize: 20
                            font.bold: true
                            font.family: "Inter"
                            font.letterSpacing: -0.3
                            color: Theme.foreground
                        }
                        Text {
                            text: "Native Quickshell desktop utilities included with Hyprconf."
                            font.pixelSize: 12
                            color: Theme.muted
                        }
                    }

                    // 3 Big Application Cards
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 180
                        spacing: 12

                        // App 1: Settings Studio
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            color: Theme.alpha(Theme.surface, 0.65)
                            border.color: Theme.alpha(Theme.foreground, 0.08)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 10

                                RowLayout {
                                    spacing: 8
                                    Rectangle {
                                        width: 32
                                        height: 32
                                        radius: 8
                                        color: Theme.alpha(Theme.accent, 0.14)
                                        Image { anchors.centerIn: parent; width: 16; height: 16; source: window.slidersSvg }
                                    }
                                    Text { text: "Settings Studio"; font.pixelSize: 14; font.bold: true; color: Theme.foreground }
                                }

                                Text {
                                    text: "Configure notch physics, dock pinning & auto-hide, draggable lockscreen widgets, and Noctalia wallpaper palettes."
                                    font.pixelSize: 11
                                    color: Theme.muted
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 30
                                    radius: 7
                                    color: app1Area.containsMouse ? Theme.accent : Theme.alpha(Theme.accent, 0.16)
                                    border.color: Theme.alpha(Theme.accent, 0.35)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Open Settings"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: app1Area.containsMouse ? Theme.background : Theme.accent
                                    }

                                    MouseArea {
                                        id: app1Area
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: window.dispatchCmd("bash ~/.hyprconf/hypr/scripts/sh/qs-settings.sh &")
                                    }
                                }
                            }
                        }

                        // App 2: Package Updater
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            color: Theme.alpha(Theme.surface, 0.65)
                            border.color: Theme.alpha(Theme.foreground, 0.08)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 10

                                RowLayout {
                                    spacing: 8
                                    Rectangle {
                                        width: 32
                                        height: 32
                                        radius: 8
                                        color: Theme.alpha(Theme.accent, 0.14)
                                        Image { anchors.centerIn: parent; width: 16; height: 16; source: window.packageSvg }
                                    }
                                    Text { text: "Package Updater"; font.pixelSize: 14; font.bold: true; color: Theme.foreground }
                                }

                                Text {
                                    text: "Maintain official Pacman packages, AUR packages via paru/yay, and Flatpaks with live output streaming."
                                    font.pixelSize: 11
                                    color: Theme.muted
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 30
                                    radius: 7
                                    color: app2Area.containsMouse ? Theme.accent : Theme.alpha(Theme.accent, 0.16)
                                    border.color: Theme.alpha(Theme.accent, 0.35)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Open Updater"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: app2Area.containsMouse ? Theme.background : Theme.accent
                                    }

                                    MouseArea {
                                        id: app2Area
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: window.dispatchCmd("bash ~/.hyprconf/hypr/scripts/sh/qs-updater.sh &")
                                    }
                                }
                            }
                        }

                        // App 3: Keybinds Cheatsheet
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            color: Theme.alpha(Theme.surface, 0.65)
                            border.color: Theme.alpha(Theme.foreground, 0.08)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 10

                                RowLayout {
                                    spacing: 8
                                    Rectangle {
                                        width: 32
                                        height: 32
                                        radius: 8
                                        color: Theme.alpha(Theme.accent, 0.14)
                                        Image { anchors.centerIn: parent; width: 16; height: 16; source: window.keyboardSvg }
                                    }
                                    Text { text: "Keybinds Cheatsheet"; font.pixelSize: 14; font.bold: true; color: Theme.foreground }
                                }

                                Text {
                                    text: "Interactive, searchable modal displaying all active Hyprland window rules, gestures, and workspace bindings."
                                    font.pixelSize: 11
                                    color: Theme.muted
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 30
                                    radius: 7
                                    color: app3Area.containsMouse ? Theme.accent : Theme.alpha(Theme.accent, 0.16)
                                    border.color: Theme.alpha(Theme.accent, 0.35)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Open Cheatsheet"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: app3Area.containsMouse ? Theme.background : Theme.accent
                                    }

                                    MouseArea {
                                        id: app3Area
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: window.dispatchCmd("qs ipc -c island call island openKeybinds")
                                    }
                                }
                            }
                        }
                    }

                    // Documentation & References Row
                    Text {
                        text: "DOCUMENTATION & LINKS"
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 0.8
                        color: Theme.muted
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Repeater {
                            model: [
                                { label: "Hyprland Wiki", url: "https://wiki.hypr.land/", icon: window.bookSvg },
                                { label: "Quickshell Docs", url: "https://quickshell.outfoxxed.me/", icon: window.bookSvg },
                                { label: "Hyprconf on GitHub", url: "https://github.com/shell-ninja/hyprconf", icon: window.gitSvg }
                            ]

                            Rectangle {
                                Layout.fillWidth: true
                                height: 38
                                radius: 8
                                color: linkArea.containsMouse ? Theme.alpha(Theme.surface, 0.85) : Theme.alpha(Theme.surface, 0.40)
                                border.color: linkArea.containsMouse ? Theme.alpha(Theme.accent, 0.30) : Theme.alpha(Theme.foreground, 0.08)
                                border.width: 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Image { width: 14; height: 14; source: modelData.icon }
                                    Text {
                                        text: modelData.label
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: Theme.foreground
                                    }
                                }

                                MouseArea {
                                    id: linkArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Qt.openUrlExternally(modelData.url)
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }

                // ═════════════════════════════════════════════════════════════
                // PAGE 4: GET STARTED (PREFERENCES & FINISH)
                // ═════════════════════════════════════════════════════════════
                ColumnLayout {
                    anchors.fill: parent
                    visible: window.activePage === 4
                    spacing: 20

                    Item { Layout.fillHeight: true }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 12

                        // Success checkmark halo
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 72
                            height: 72
                            radius: 36
                            color: Theme.alpha("#22c55e", 0.12)
                            border.color: Theme.alpha("#22c55e", 0.35)
                            border.width: 1.5

                            Image {
                                anchors.centerIn: parent
                                width: 32
                                height: 32
                                source: window.checkSvg
                            }
                        }

                        Text {
                            text: "You're All Set!"
                            font.pixelSize: 24
                            font.bold: true
                            font.family: "Inter"
                            font.letterSpacing: -0.4
                            color: Theme.foreground
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "Your obsidian desktop environment is fully configured. Customize preferences below or launch directly into your workflow."
                            font.pixelSize: 12
                            font.family: "Inter"
                            color: Theme.muted
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            Layout.maximumWidth: 500
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    // Startup Preference Card
                    Rectangle {
                        Layout.preferredWidth: 520
                        Layout.alignment: Qt.AlignHCenter
                        height: 64
                        radius: 12
                        color: Theme.alpha(Theme.surface, 0.70)
                        border.color: Theme.alpha(Theme.foreground, 0.08)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 18
                            anchors.rightMargin: 18
                            spacing: 14

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: "Launch Welcome App on Startup"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Theme.foreground
                                }
                                Text {
                                    text: "Show this onboarding guide whenever logging into Hyprland"
                                    font.pixelSize: 10
                                    color: Theme.muted
                                }
                            }

                            // Capsule Switch
                            Rectangle {
                                width: 44
                                height: 24
                                radius: 12
                                color: window.showOnStartup ? Theme.accent : Theme.alpha(Theme.foreground, 0.20)

                                Rectangle {
                                    width: 18
                                    height: 18
                                    radius: 9
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: window.showOnStartup ? parent.width - width - 3 : 3
                                    color: window.showOnStartup ? Theme.background : Theme.foreground
                                    Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: window.toggleStartupState(!window.showOnStartup)
                                }
                            }
                        }
                    }

                    // Action buttons
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 12

                        // Finish button
                        Rectangle {
                            width: 220
                            height: 40
                            radius: 10
                            color: finishArea.containsMouse ? Qt.lighter(Theme.accent, 1.15) : Theme.accent

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Text {
                                    text: "Start Using Hyprconf"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.background
                                }
                                Image { width: 14; height: 14; source: window.arrowRightSvg }
                            }

                            MouseArea {
                                id: finishArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Qt.quit()
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // ── BOTTOM NAVIGATION BAR ─────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                spacing: 12

                // Left: Skip button
                Rectangle {
                    visible: window.activePage < 4
                    Layout.preferredWidth: 80
                    height: 34
                    radius: 8
                    color: skipArea.containsMouse ? Theme.alpha(Theme.surface, 0.85) : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "Skip Guide"
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.muted
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

                // Center: Dot / Pill Page Indicator
                RowLayout {
                    spacing: 6

                    Repeater {
                        model: 5

                        Rectangle {
                            height: 6
                            width: window.activePage === index ? 20 : 6
                            radius: 3
                            color: window.activePage === index ? Theme.accent : Theme.alpha(Theme.foreground, 0.20)
                            Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: window.activePage = index
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Right: Back & Next Buttons
                RowLayout {
                    spacing: 8

                    // Back button
                    Rectangle {
                        visible: window.activePage > 0
                        width: 80
                        height: 34
                        radius: 8
                        color: backArea.containsMouse ? Theme.alpha(Theme.surface, 0.85) : Theme.alpha(Theme.surface, 0.45)
                        border.color: Theme.alpha(Theme.foreground, 0.12)
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Image { width: 12; height: 12; source: window.arrowLeftSvg }
                            Text {
                                text: "Back"
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.foreground
                            }
                        }

                        MouseArea {
                            id: backArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (window.activePage > 0) window.activePage--
                            }
                        }
                    }

                    // Next / Finish button
                    Rectangle {
                        width: window.activePage === 4 ? 100 : 80
                        height: 34
                        radius: 8
                        color: nextArea.containsMouse ? Qt.lighter(Theme.accent, 1.15) : Theme.accent

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: window.activePage === 4 ? "Done" : "Next"
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.background
                            }
                            Image {
                                width: 12
                                height: 12
                                source: window.arrowRightSvg
                                visible: window.activePage < 4
                            }
                        }

                        MouseArea {
                            id: nextArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (window.activePage < 4) {
                                    window.activePage++
                                } else {
                                    Qt.quit()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
