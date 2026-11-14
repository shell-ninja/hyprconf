import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root
    anchors.fill: parent

    readonly property string homeDir: (typeof window !== "undefined" && window.homeDir) ? window.homeDir : (Quickshell.env("HOME") || "/home/" + Quickshell.env("USER"))

    property bool isChecking: false
    property string lastCheckedStr: "Just now"
    property var updateInfo: ({
        "status": "idle",
        "local": "v1.0.2",
        "remote": "v1.0.2",
        "has_update": false,
        "release_name": "v1.0.2",
        "published_at": "",
        "title": "What's New in Hyprconf",
        "subtitle": "Performance enhancements, updated obsidian aesthetics, and system refinements.",
        "keybinds_notice": "",
        "features": []
    })
    property string errorMessage: ""

    function svgUrl(content) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(content)
    }

    // ── SVG Icons ────────────────────────────────────────────────────────────
    readonly property string refreshSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21.5 2v6h-6M21.34 15.57a10 10 0 1 1-.57-8.38l5.67-5.67"/></svg>')
    readonly property string downloadSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.on_primary + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>')
    readonly property string checkSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>')
    readonly property string starSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>')
    readonly property string gitSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="18" cy="18" r="3"/><circle cx="6" cy="6" r="3"/><path d="M13 6h3a2 2 0 0 1 2 2v7"/><line x1="6" y1="9" x2="6" y2="21"/></svg>')
    readonly property string keyboardSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="M6 8h.01M10 8h.01M14 8h.01M18 8h.01M8 12h.01M12 12h.01M16 12h.01M7 16h10"/></svg>')
    readonly property string shieldSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>')
    readonly property string terminalSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg>')
    readonly property string externalLinkSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg>')
    readonly property string bookSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20"/></svg>')

    function getFeatureSvg(iconName) {
        var s = Theme.accent
        if (iconName === "clipboard") return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + s + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="8" y="2" width="8" height="4" rx="1" ry="1"/><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/></svg>')
        if (iconName === "sliders") return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + s + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="4" y1="21" x2="4" y2="14"/><line x1="4" y1="10" x2="4" y2="3"/><line x1="12" y1="21" x2="12" y2="12"/><line x1="12" y1="8" x2="12" y2="3"/><line x1="20" y1="21" x2="20" y2="16"/><line x1="20" y1="12" x2="20" y2="3"/><line x1="1" y1="14" x2="7" y2="14"/><line x1="9" y1="8" x2="15" y2="8"/><line x1="17" y1="16" x2="23" y2="16"/></svg>')
        if (iconName === "spark") return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + s + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m12 3-1.912 5.813a2 2 0 0 1-1.275 1.275L3 12l5.813 1.912a2 2 0 0 1 1.275 1.275L12 21l1.912-5.813a2 2 0 0 1 1.275-1.275L21 12l-5.813-1.912a2 2 0 0 1-1.275-1.275L12 3Z"/></svg>')
        if (iconName === "speed") return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + s + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>')
        return starSvg
    }

    // ── Update Discovery Process ─────────────────────────────────────────────
    Process {
        id: checkProc
        command: ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/check-update-info.py"]
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                root.isChecking = false
                try {
                    var parsed = JSON.parse(text.trim())
                    if (parsed && parsed.local) {
                        root.updateInfo = parsed
                        var d = new Date()
                        root.lastCheckedStr = d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
                        root.errorMessage = ""
                    }
                } catch (e) {
                    root.errorMessage = "Failed parsing update response: " + e
                }
            }
        }
        onExited: function(code) {
            root.isChecking = false
        }
    }

    function checkUpdatesNow() {
        if (root.isChecking) return
        root.isChecking = true
        checkProc.running = true
    }

    Component.onCompleted: {
        checkUpdatesNow()
    }

    // ── MAIN SCROLL AREA ─────────────────────────────────────────────────────
    ScrollView {
        anchors.fill: parent
        anchors.margins: 18
        contentWidth: availableWidth
        clip: true

        Column {
            width: parent.width
            spacing: 16

            // =================================================================
            // 1. HERO UPDATE STATUS BANNER
            // =================================================================
            Rectangle {
                width: parent.width
                implicitHeight: heroContentRow.implicitHeight + 36
                radius: 16
                color: Theme.glassCard
                border.width: 1
                border.color: root.updateInfo.has_update
                    ? Theme.accent
                    : Theme.alpha(Theme.foreground, 0.12)

                // Top Specular Rim
                Rectangle {
                    z: 2
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    height: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.25; color: Theme.glassRimTop }
                        GradientStop { position: 0.5; color: root.updateInfo.has_update ? Theme.accent : Theme.alpha("#ffffff", 0.28) }
                        GradientStop { position: 0.75; color: Theme.glassRimTop }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                RowLayout {
                    id: heroContentRow
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 18
                    }
                    spacing: 16

                    // Left: Status Text & Info
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Status Pill Badge
                        RowLayout {
                            spacing: 8

                            Rectangle {
                                implicitWidth: statusBadgeRow.implicitWidth + 16
                                height: 26
                                radius: 13
                                color: root.isChecking
                                    ? Theme.alpha(Theme.foreground, 0.12)
                                    : (root.updateInfo.has_update
                                        ? Theme.accent
                                        : Theme.alpha(Theme.accent, 0.16))
                                border.width: 1
                                border.color: root.updateInfo.has_update
                                    ? Theme.accent
                                    : Theme.alpha(Theme.accent, 0.35)

                                RowLayout {
                                    id: statusBadgeRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Image {
                                        Layout.preferredWidth: 12
                                        Layout.preferredHeight: 12
                                        source: root.isChecking
                                            ? root.refreshSvg
                                            : (root.updateInfo.has_update ? root.downloadSvg : root.checkSvg)
                                        sourceSize: Qt.size(24, 24)
                                    }

                                    Text {
                                        text: root.isChecking
                                            ? "Checking for Updates…"
                                            : (root.updateInfo.has_update
                                                ? ("Update Available: " + root.updateInfo.remote)
                                                : ("Hyprconf is Up to Date (" + root.updateInfo.local + ")"))
                                        font.pixelSize: 11
                                        font.bold: true
                                        font.family: "Outfit"
                                        color: root.updateInfo.has_update ? Theme.on_primary : Theme.foreground
                                    }
                                }
                            }

                            // Branch / Channel Pill
                            Rectangle {
                                implicitWidth: branchBadgeText.implicitWidth + 14
                                height: 26
                                radius: 13
                                color: Theme.alpha(Theme.surface, 0.50)
                                border.width: 1
                                border.color: Theme.alpha(Theme.foreground, 0.10)

                                Text {
                                    id: branchBadgeText
                                    anchors.centerIn: parent
                                    text: "main branch • GitHub"
                                    font.pixelSize: 10
                                    font.family: "JetBrains Mono, monospace"
                                    color: Theme.alpha(Theme.foreground, 0.65)
                                }
                            }
                        }

                        // Headline Title
                        Text {
                            text: root.updateInfo.has_update
                                ? ("New Release " + root.updateInfo.remote + " is Ready!")
                                : "Your Hyprconf Dotfiles are Up to Date"
                            font.pixelSize: 18
                            font.bold: true
                            font.family: "Outfit"
                            color: Theme.foreground
                        }

                        // Description
                        Text {
                            Layout.fillWidth: true
                            text: root.updateInfo.has_update
                                ? ("Version " + root.updateInfo.remote + " includes performance enhancements, Quickshell improvements, and refined obsidian aesthetics. Click Update Now to safely fast-forward your configuration.")
                                : ("You are currently running " + root.updateInfo.local + ". All Quickshell modules, shaders, and configs match the official upstream repository. Last checked at " + root.lastCheckedStr + ".")
                            font.pixelSize: 12
                            font.family: "Outfit"
                            color: Theme.alpha(Theme.foreground, 0.72)
                            wrapMode: Text.WordWrap
                        }
                    }

                    // Right: Primary Action Buttons
                    ColumnLayout {
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        spacing: 8

                        // Update Now (or Reapply) Button
                        Rectangle {
                            implicitWidth: 160
                            height: 38
                            radius: 10
                            color: root.updateInfo.has_update
                                ? (updMa.containsMouse ? Theme.alpha(Theme.accent, 0.85) : Theme.accent)
                                : (updMa.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.60))
                            border.width: 1
                            border.color: root.updateInfo.has_update ? Theme.accent : Theme.alpha(Theme.accent, 0.35)

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Image {
                                    Layout.preferredWidth: 14
                                    Layout.preferredHeight: 14
                                    source: root.updateInfo.has_update ? root.downloadSvg : root.terminalSvg
                                    sourceSize: Qt.size(28, 28)
                                }
                                Text {
                                    text: root.updateInfo.has_update ? "Update Dotfiles Now" : "Reapply / Sync"
                                    font.pixelSize: 12
                                    font.bold: true
                                    font.family: "Outfit"
                                    color: root.updateInfo.has_update ? Theme.on_primary : Theme.foreground
                                }
                            }

                            MouseArea {
                                id: updMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached([
                                        root.homeDir + "/.hyprconf/hypr/scripts/sh/hyprconf.sh",
                                        "--hyprconf"
                                    ])
                                }
                            }
                        }

                        // Check for Updates Button
                        Rectangle {
                            implicitWidth: 160
                            height: 34
                            radius: 10
                            color: chkMa.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.40)
                            border.width: 1
                            border.color: Theme.alpha(Theme.foreground, 0.12)

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Image {
                                    Layout.preferredWidth: 12
                                    Layout.preferredHeight: 12
                                    source: root.refreshSvg
                                    sourceSize: Qt.size(24, 24)

                                    NumberAnimation on rotation {
                                        from: 0
                                        to: 360
                                        duration: 900
                                        loops: Animation.Infinite
                                        running: root.isChecking
                                    }
                                }
                                Text {
                                    text: root.isChecking ? "Checking…" : "Check for Updates"
                                    font.pixelSize: 11
                                    font.family: "Outfit"
                                    color: Theme.foreground
                                }
                            }

                            MouseArea {
                                id: chkMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.checkUpdatesNow()
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 2. VERSION & SYSTEM METRICS (4 CARDS)
            // =================================================================
            RowLayout {
                width: parent.width
                spacing: 12

                // Card A: Current Version
                Rectangle {
                    Layout.fillWidth: true
                    height: 80
                    radius: 12
                    color: Theme.glassCard
                    border.width: 1
                    border.color: Theme.alpha(Theme.foreground, 0.10)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 38
                            Layout.preferredHeight: 38
                            radius: 10
                            color: Theme.alpha(Theme.accent, 0.16)
                            Image {
                                anchors.centerIn: parent
                                width: 18; height: 18
                                source: root.gitSvg
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                text: "INSTALLED VERSION"
                                font.pixelSize: 10
                                font.bold: true
                                font.family: "Outfit"
                                color: Theme.alpha(Theme.foreground, 0.50)
                            }
                            Text {
                                text: root.updateInfo.local || "v1.0.2"
                                font.pixelSize: 16
                                font.bold: true
                                font.family: "JetBrains Mono, monospace"
                                color: Theme.accent
                            }
                            Text {
                                text: "Current active build"
                                font.pixelSize: 10
                                font.family: "Outfit"
                                color: Theme.alpha(Theme.foreground, 0.50)
                            }
                        }
                    }
                }

                // Card B: Remote Release
                Rectangle {
                    Layout.fillWidth: true
                    height: 80
                    radius: 12
                    color: Theme.glassCard
                    border.width: 1
                    border.color: Theme.alpha(Theme.foreground, 0.10)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 38
                            Layout.preferredHeight: 38
                            radius: 10
                            color: root.updateInfo.has_update
                                ? Theme.accent
                                : Theme.alpha(Theme.accent, 0.16)
                            Image {
                                anchors.centerIn: parent
                                width: 18; height: 18
                                source: root.updateInfo.has_update ? root.downloadSvg : root.checkSvg
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                text: "LATEST REMOTE"
                                font.pixelSize: 10
                                font.bold: true
                                font.family: "Outfit"
                                color: Theme.alpha(Theme.foreground, 0.50)
                            }
                            Text {
                                text: root.updateInfo.remote || root.updateInfo.local || "v1.0.2"
                                font.pixelSize: 16
                                font.bold: true
                                font.family: "JetBrains Mono, monospace"
                                color: root.updateInfo.has_update ? Theme.accent : Theme.foreground
                            }
                            Text {
                                text: root.updateInfo.has_update ? "New version ready" : "Matches installed release"
                                font.pixelSize: 10
                                font.family: "Outfit"
                                color: root.updateInfo.has_update ? Theme.accent : Theme.alpha(Theme.foreground, 0.50)
                            }
                        }
                    }
                }

                // Card C: Keyboard Shortcut
                Rectangle {
                    Layout.fillWidth: true
                    height: 80
                    radius: 12
                    color: Theme.glassCard
                    border.width: 1
                    border.color: Theme.alpha(Theme.foreground, 0.10)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 38
                            Layout.preferredHeight: 38
                            radius: 10
                            color: Theme.alpha(Theme.accent, 0.16)
                            Image {
                                anchors.centerIn: parent
                                width: 18; height: 18
                                source: root.keyboardSvg
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                text: "UPDATE SHORTCUT"
                                font.pixelSize: 10
                                font.bold: true
                                font.family: "Outfit"
                                color: Theme.alpha(Theme.foreground, 0.50)
                            }
                            Text {
                                text: "SUPER + SHIFT + U"
                                font.pixelSize: 13
                                font.bold: true
                                font.family: "JetBrains Mono, monospace"
                                color: Theme.foreground
                            }
                            Text {
                                text: "Opens this manager instantly"
                                font.pixelSize: 10
                                font.family: "Outfit"
                                color: Theme.alpha(Theme.foreground, 0.50)
                            }
                        }
                    }
                }

                // Card D: State Protection
                Rectangle {
                    Layout.fillWidth: true
                    height: 80
                    radius: 12
                    color: Theme.glassCard
                    border.width: 1
                    border.color: Theme.alpha(Theme.foreground, 0.10)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 38
                            Layout.preferredHeight: 38
                            radius: 10
                            color: Theme.alpha(Theme.accent, 0.16)
                            Image {
                                anchors.centerIn: parent
                                width: 18; height: 18
                                source: root.shieldSvg
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                text: "USER STATE"
                                font.pixelSize: 10
                                font.bold: true
                                font.family: "Outfit"
                                color: Theme.alpha(Theme.foreground, 0.50)
                            }
                            Text {
                                text: "100% Isolated"
                                font.pixelSize: 14
                                font.bold: true
                                font.family: "Outfit"
                                color: "#22c55e"
                            }
                            Text {
                                text: "Wallpapers & binds safe"
                                font.pixelSize: 10
                                font.family: "Outfit"
                                color: Theme.alpha(Theme.foreground, 0.50)
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 3. WHAT'S NEW & RELEASE HIGHLIGHTS
            // =================================================================
            SettingCard {
                title: root.updateInfo.title || ("What's New in " + (root.updateInfo.remote || root.updateInfo.local || "Hyprconf"))
                description: root.updateInfo.subtitle || "Key architectural features, user interface enhancements, and performance refinements."

                Column {
                    width: parent.width
                    spacing: 12

                    // Keybinds Preservation Notice Banner
                    Rectangle {
                        width: parent.width
                        implicitHeight: kbBannerRow.implicitHeight + 20
                        radius: 10
                        visible: root.updateInfo.keybinds_notice && root.updateInfo.keybinds_notice.length > 0
                        color: Theme.alpha(Theme.accent, 0.10)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.30)

                        RowLayout {
                            id: kbBannerRow
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: 14
                                rightMargin: 14
                            }
                            spacing: 12

                            Image {
                                Layout.preferredWidth: 18
                                Layout.preferredHeight: 18
                                source: root.keyboardSvg
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: "Personal Keybindings Preserved"
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.family: "Outfit"
                                    color: Theme.foreground
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.updateInfo.keybinds_notice || ""
                                    font.pixelSize: 10
                                    font.family: "Outfit"
                                    color: Theme.alpha(Theme.foreground, 0.75)
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Rectangle {
                                implicitWidth: openKbText.implicitWidth + 18
                                height: 28
                                radius: 7
                                color: openKbMa.containsMouse ? Theme.alpha(Theme.accent, 0.30) : Theme.alpha(Theme.accent, 0.16)
                                border.width: 1
                                border.color: Theme.alpha(Theme.accent, 0.40)

                                Text {
                                    id: openKbText
                                    anchors.centerIn: parent
                                    text: "Open Keybinds"
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.family: "Outfit"
                                    color: Theme.accent
                                }

                                MouseArea {
                                    id: openKbMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (typeof window !== "undefined") {
                                            window.activeRootNav = 0
                                            window.activeSection = 6
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Feature Cards Grid
                    Column {
                        width: parent.width
                        spacing: 10

                        Repeater {
                            model: (root.updateInfo.features && root.updateInfo.features.length > 0) ? root.updateInfo.features : []

                            Rectangle {
                                width: parent.width
                                implicitHeight: featRow.implicitHeight + 24
                                radius: 10
                                color: Theme.alpha(Theme.surface, 0.50)
                                border.width: 1
                                border.color: Theme.alpha(Theme.foreground, 0.08)

                                RowLayout {
                                    id: featRow
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: 14
                                        rightMargin: 14
                                    }
                                    spacing: 14

                                    Rectangle {
                                        Layout.preferredWidth: 36
                                        Layout.preferredHeight: 36
                                        radius: 9
                                        color: Theme.alpha(Theme.accent, 0.16)

                                        Image {
                                            anchors.centerIn: parent
                                            width: 18; height: 18
                                            source: root.getFeatureSvg(modelData.icon || "spark")
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 3

                                        RowLayout {
                                            spacing: 8

                                            Text {
                                                text: modelData.title || ""
                                                font.pixelSize: 13
                                                font.bold: true
                                                font.family: "Outfit"
                                                color: Theme.foreground
                                            }

                                            Rectangle {
                                                implicitWidth: featTagText.implicitWidth + 10
                                                height: 18
                                                radius: 4
                                                color: Theme.alpha(Theme.accent, 0.16)
                                                visible: (modelData.tag && modelData.tag.length > 0)

                                                Text {
                                                    id: featTagText
                                                    anchors.centerIn: parent
                                                    text: modelData.tag || ""
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    font.family: "Outfit"
                                                    color: Theme.accent
                                                }
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.description || ""
                                            font.pixelSize: 11
                                            font.family: "Outfit"
                                            color: Theme.alpha(Theme.foreground, 0.70)
                                            wrapMode: Text.WordWrap
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 4. UPDATE PIPELINE & ACTIONS
            // =================================================================
            SettingCard {
                title: "Dotfile Update Pipeline & Integrity"
                description: "Hyprconf safely separates upstream dotfiles from your personal customizations."

                Column {
                    width: parent.width
                    spacing: 14

                    // Explanation Points
                    Column {
                        width: parent.width
                        spacing: 8

                        RowLayout {
                            width: parent.width
                            spacing: 10
                            Rectangle { width: 6; height: 6; radius: 3; color: Theme.accent }
                            Text {
                                Layout.fillWidth: true
                                text: "Git Fast-Forward: Safe clean fetch from GitHub without overriding local working modifications."
                                font.pixelSize: 11
                                font.family: "Outfit"
                                color: Theme.alpha(Theme.foreground, 0.75)
                                wrapMode: Text.WordWrap
                            }
                        }

                        RowLayout {
                            width: parent.width
                            spacing: 10
                            Rectangle { width: 6; height: 6; radius: 3; color: Theme.accent }
                            Text {
                                Layout.fillWidth: true
                                text: "User State Segregation: Wallpapers, pinned dock applications, custom keybinds, and monitor setups in ~/.local/share/hyprconf/ remain 100% untouched."
                                font.pixelSize: 11
                                font.family: "Outfit"
                                color: Theme.alpha(Theme.foreground, 0.75)
                                wrapMode: Text.WordWrap
                            }
                        }

                        RowLayout {
                            width: parent.width
                            spacing: 10
                            Rectangle { width: 6; height: 6; radius: 3; color: Theme.accent }
                            Text {
                                Layout.fillWidth: true
                                text: "Live Shader & Module Sync: Precompiled Qt6 RHI shader binaries and Theme singletons recompile and reload dynamically."
                                font.pixelSize: 11
                                font.family: "Outfit"
                                color: Theme.alpha(Theme.foreground, 0.75)
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    // Bottom Action Buttons
                    RowLayout {
                        width: parent.width
                        spacing: 10

                        // Terminal Updater
                        Rectangle {
                            Layout.fillWidth: true
                            height: 38
                            radius: 10
                            color: termUpdMa.containsMouse ? Theme.alpha(Theme.accent, 0.85) : Theme.accent
                            border.width: 1
                            border.color: Theme.accent

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Image {
                                    Layout.preferredWidth: 14
                                    Layout.preferredHeight: 14
                                    source: root.terminalSvg
                                    sourceSize: Qt.size(28, 28)
                                }
                                Text {
                                    text: "Launch Dotfile Terminal Updater"
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.family: "Outfit"
                                    color: Theme.on_primary
                                }
                            }

                            MouseArea {
                                id: termUpdMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached([
                                    root.homeDir + "/.hyprconf/hypr/scripts/sh/hyprconf.sh",
                                    "--hyprconf"
                                ])
                            }
                        }

                        // Release Notes Markdown
                        Rectangle {
                            Layout.fillWidth: true
                            height: 38
                            radius: 10
                            color: relNotesMa.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.50)
                            border.width: 1
                            border.color: Theme.alpha(Theme.foreground, 0.12)

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Image {
                                    Layout.preferredWidth: 14
                                    Layout.preferredHeight: 14
                                    source: root.bookSvg
                                    sourceSize: Qt.size(28, 28)
                                }
                                Text {
                                    text: "View Full Release Notes"
                                    font.pixelSize: 11
                                    font.family: "Outfit"
                                    color: Theme.foreground
                                }
                            }

                            MouseArea {
                                id: relNotesMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var noteFile = root.homeDir + "/.hyprconf/RELEASE_NOTES_v1.0.2.md"
                                    Quickshell.execDetached(["xdg-open", noteFile])
                                }
                            }
                        }

                        // GitHub Releases
                        Rectangle {
                            Layout.preferredWidth: 140
                            height: 38
                            radius: 10
                            color: ghMa.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.50)
                            border.width: 1
                            border.color: Theme.alpha(Theme.foreground, 0.12)

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Image {
                                    Layout.preferredWidth: 12
                                    Layout.preferredHeight: 12
                                    source: root.externalLinkSvg
                                    sourceSize: Qt.size(24, 24)
                                }
                                Text {
                                    text: "GitHub Releases"
                                    font.pixelSize: 11
                                    font.family: "Outfit"
                                    color: Theme.foreground
                                }
                            }

                            MouseArea {
                                id: ghMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached([
                                    "xdg-open",
                                    "https://github.com/shell-ninja/hyprconf/releases"
                                ])
                            }
                        }
                    }
                }
            }

            // Bottom Spacing buffer
            Item {
                width: parent.width
                height: 20
            }
        }
    }
}
