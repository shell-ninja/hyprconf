import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "."

Rectangle {
    id: root

    readonly property bool isIslandView: true
    readonly property real preferredWidth: 620
    readonly property real preferredHeight: 460
    implicitWidth: preferredWidth
    implicitHeight: preferredHeight

    radius: Theme.radiusCard || 20
    color: Theme.alpha(Theme.surface, 0.94)
    border.width: 1
    border.color: Theme.alpha(Theme.accent, 0.35)
    clip: true

    signal closeRequested()

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    readonly property string pythonBin: {
        var venvPy = root.homeDir + "/.local/share/hyprconf/venv/bin/python3"
        return venvPy
    }

    readonly property string scriptPath: {
        var p1 = root.homeDir + "/.local/share/hyprconf/plugins/media-downloader/bin/downloader.py"
        return p1
    }

    // State properties
    property string activeUrl: ""
    property string downloadMode: "video" // "video" | "audio"
    property string videoQuality: "best"  // "best" | "1080p" | "720p"
    property string audioFormat: "mp3"    // "mp3" | "m4a" | "flac"

    property string status: "idle" // "idle" | "fetching_info" | "downloading" | "processing" | "complete" | "error"
    property real percent: 0.0
    property string speedStr: "-- MB/s"
    property string etaStr: "--:--"
    property string currentTitle: ""
    property string currentThumbnail: ""
    property string currentUploader: ""
    property string currentFilepath: ""
    property string errorMessage: ""

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string downloadSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>')
    readonly property string videoSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="23 7 16 12 23 17 23 7"/><rect x="1" y="5" width="15" height="14" rx="2" ry="2"/></svg>')
    readonly property string musicSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></svg>')
    readonly property string pasteSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/><rect x="8" y="2" width="8" height="4" rx="1" ry="1"/></svg>')
    readonly property string checkSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>')
    readonly property string folderSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20h16a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.93a2 2 0 0 1-1.66-.9l-.82-1.2A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13c0 1.1.9 2 2 2Z"/></svg>')
    readonly property string playSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.on_primary + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><polygon points="5 3 19 12 5 21 5 3"/></svg>')
    readonly property string closeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>')

    // Forward keyboard events
    function handleKey(event) {
        if (event.key === Qt.Key_Escape) {
            event.accepted = true
            root.closeRequested()
            return true
        }
        return false
    }

    // Process for executing download
    Process {
        id: dlProcess
        stdout: SplitParser {
            onRead: function(line) {
                if (!line || line.trim().length === 0) return
                try {
                    var data = JSON.parse(line.trim())
                    if (data.status) root.status = data.status
                    if (data.percent !== undefined) root.percent = data.percent
                    if (data.speed) root.speedStr = data.speed
                    if (data.eta) root.etaStr = data.eta
                    if (data.title) root.currentTitle = data.title
                    if (data.thumbnail) root.currentThumbnail = data.thumbnail
                    if (data.uploader) root.currentUploader = data.uploader
                    if (data.filepath) root.currentFilepath = data.filepath
                    if (data.error) root.errorMessage = data.error
                } catch(e) {}
            }
        }
        onExited: {
            if (root.status === "downloading" || root.status === "processing") {
                // If it exited while downloading without complete status
                if (root.percent >= 99.0) {
                    root.status = "complete"
                } else if (root.status !== "complete") {
                    root.status = "error"
                    root.errorMessage = "Process terminated unexpectedly."
                }
            }
        }
    }

    // Process for fetching clipboard content
    Process {
        id: pasteProc
        command: ["wl-paste", "--no-newline"]
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    urlInput.text = text.trim()
                    root.activeUrl = text.trim()
                }
            }
        }
    }

    // Process for cancellation
    Process {
        id: cancelProc
        command: [root.pythonBin, root.scriptPath, "cancel"]
    }

    function startDownload() {
        var u = urlInput.text.trim()
        if (!u || u.length === 0) return
        root.activeUrl = u
        root.status = "downloading"
        root.percent = 0.0
        root.speedStr = "-- MB/s"
        root.etaStr = "--:--"
        root.errorMessage = ""

        var cmd = [root.pythonBin, root.scriptPath, "download", u, "--mode", root.downloadMode]
        if (root.downloadMode === "video") {
            cmd.push("--quality")
            cmd.push(root.videoQuality)
        } else {
            cmd.push("--audio-format")
            cmd.push(root.audioFormat)
        }
        dlProcess.command = cmd
        dlProcess.running = true
    }

    function cancelDownload() {
        cancelProc.running = true
        if (dlProcess.running) dlProcess.kill()
        root.status = "idle"
        root.percent = 0.0
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // ── TOP HEADER ──────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                width: 36
                height: 36
                radius: 18
                color: Theme.alpha(Theme.accent, 0.20)
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.50)

                Image {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: root.downloadSvg
                    sourceSize: Qt.size(24, 24)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: "Media Downloader"
                    color: Theme.foreground
                    font.family: "Outfit"
                    font.pixelSize: 17
                    font.weight: Font.Bold
                }
                Text {
                    text: "Universal Video & Audio Grabber • 1,800+ Sites"
                    color: Theme.alpha(Theme.foreground, 0.60)
                    font.family: "Outfit"
                    font.pixelSize: 11
                }
            }

            // Close button
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: closeMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.15) : "transparent"
                border.width: 1
                border.color: Theme.alpha(Theme.foreground, 0.20)

                Image {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    source: root.closeSvg
                    sourceSize: Qt.size(24, 24)
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.closeRequested()
                }
            }
        }

        // ── URL INPUT BOX WITH INTEGRATED PASTE ──────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 48
            radius: 14
            color: Theme.alpha(Theme.surface, 0.90)
            border.width: urlInput.activeFocus ? 1.5 : 1
            border.color: urlInput.activeFocus ? Theme.accent : Theme.alpha(Theme.foreground, 0.18)
            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 6
                spacing: 8

                TextInput {
                    id: urlInput
                    Layout.fillWidth: true
                    color: Theme.foreground
                    font.family: "Outfit"
                    font.pixelSize: 13
                    clip: true
                    selectByMouse: true
                    onAccepted: root.startDownload()

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Paste video/audio link (YouTube, Instagram, Reddit, TikTok, X...)"
                        color: Theme.alpha(Theme.foreground, 0.40)
                        font.family: "Outfit"
                        font.pixelSize: 13
                        visible: !urlInput.text && !urlInput.activeFocus
                    }
                }

                // Clear button
                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: "transparent"
                    visible: urlInput.text.length > 0

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: Theme.alpha(Theme.foreground, 0.60)
                        font.pixelSize: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            urlInput.text = ""
                            root.activeUrl = ""
                            root.status = "idle"
                        }
                    }
                }

                // Paste Button
                Rectangle {
                    width: 78
                    height: 36
                    radius: 10
                    color: pasteMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.accent, 0.20)
                    border.width: 1
                    border.color: Theme.accent
                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Image {
                            width: 14
                            height: 14
                            source: root.pasteSvg
                            sourceSize: Qt.size(24, 24)
                        }
                        Text {
                            text: "Paste"
                            color: pasteMouse.containsMouse ? Theme.on_primary : Theme.accent
                            font.family: "Outfit"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                    }

                    MouseArea {
                        id: pasteMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: pasteProc.running = true
                    }
                }
            }
        }

        // ── FORMAT & QUALITY SELECTOR CHIPS ──────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Mode Toggle: Video vs Audio
            Rectangle {
                height: 38
                width: 190
                radius: 12
                color: Theme.alpha(Theme.surface, 0.80)
                border.width: 1
                border.color: Theme.alpha(Theme.foreground, 0.15)

                Row {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 4

                    // Video Chip
                    Rectangle {
                        width: (parent.width - 4) / 2
                        height: parent.height
                        radius: 9
                        color: root.downloadMode === "video" ? Theme.accent : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            Image {
                                width: 14
                                height: 14
                                source: root.videoSvg
                                sourceSize: Qt.size(24, 24)
                            }
                            Text {
                                text: "Video"
                                color: root.downloadMode === "video" ? Theme.on_primary : Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: root.downloadMode === "video" ? Font.Bold : Font.Normal
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.downloadMode = "video"
                        }
                    }

                    // Audio Chip
                    Rectangle {
                        width: (parent.width - 4) / 2
                        height: parent.height
                        radius: 9
                        color: root.downloadMode === "audio" ? Theme.accent : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            Image {
                                width: 14
                                height: 14
                                source: root.musicSvg
                                sourceSize: Qt.size(24, 24)
                            }
                            Text {
                                text: "Audio"
                                color: root.downloadMode === "audio" ? Theme.on_primary : Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: root.downloadMode === "audio" ? Font.Bold : Font.Normal
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.downloadMode = "audio"
                        }
                    }
                }
            }

            // Quality / Format Sub-options
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: root.downloadMode === "video" ? [
                        { key: "best", label: "Best (1080p+)" },
                        { key: "1080p", label: "1080p" },
                        { key: "720p", label: "720p" }
                    ] : [
                        { key: "mp3", label: "MP3 (320k)" },
                        { key: "m4a", label: "M4A" },
                        { key: "flac", label: "FLAC" }
                    ]

                    Rectangle {
                        height: 38
                        implicitWidth: optText.implicitWidth + 24
                        radius: 12
                        readonly property bool isSelected: root.downloadMode === "video" ? root.videoQuality === modelData.key : root.audioFormat === modelData.key
                        color: isSelected ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surface, 0.60)
                        border.width: 1
                        border.color: isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            id: optText
                            anchors.centerIn: parent
                            text: modelData.label
                            color: parent.isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.70)
                            font.family: "Outfit"
                            font.pixelSize: 12
                            font.weight: parent.isSelected ? Font.Bold : Font.Normal
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.downloadMode === "video") root.videoQuality = modelData.key
                                else root.audioFormat = modelData.key
                            }
                        }
                    }
                }
            }
        }

        // ── LIVE DOWNLOAD & STATUS CONTAINER ─────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 16
            color: Theme.alpha(Theme.surface, 0.75)
            border.width: 1
            border.color: Theme.alpha(Theme.foreground, 0.12)
            clip: true

            // 1. Idle View (Instructions & Supported Platforms)
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10
                visible: root.status === "idle"

                Image {
                    Layout.alignment: Qt.AlignHCenter
                    width: 42
                    height: 42
                    source: root.downloadSvg
                    sourceSize: Qt.size(48, 48)
                    opacity: 0.80
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Ready to Download"
                    color: Theme.foreground
                    font.family: "Outfit"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Paste any video or audio URL above and hit Download"
                    color: Theme.alpha(Theme.foreground, 0.50)
                    font.family: "Outfit"
                    font.pixelSize: 12
                }

                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12
                    Layout.topMargin: 8
                    Repeater {
                        model: ["YouTube", "Reddit", "Instagram", "TikTok", "X / Twitter", "SoundCloud"]
                        Rectangle {
                            height: 22
                            implicitWidth: chipT.implicitWidth + 14
                            radius: 11
                            color: Theme.alpha(Theme.surface, 0.90)
                            border.width: 1
                            border.color: Theme.alpha(Theme.foreground, 0.12)
                            Text {
                                id: chipT
                                anchors.centerIn: parent
                                text: modelData
                                color: Theme.alpha(Theme.foreground, 0.60)
                                font.family: "Outfit"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                            }
                        }
                    }
                }
            }

            // 2. Active Downloading & Processing View
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12
                visible: root.status === "downloading" || root.status === "processing"

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    // Thumbnail Preview
                    Rectangle {
                        width: 80
                        height: 56
                        radius: 8
                        color: Theme.alpha(Theme.surface, 0.95)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.30)
                        clip: true

                        Image {
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            source: root.currentThumbnail
                            visible: root.currentThumbnail.length > 0
                        }

                        Image {
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            source: root.downloadMode === "video" ? root.videoSvg : root.musicSvg
                            sourceSize: Qt.size(24, 24)
                            visible: !root.currentThumbnail || root.currentThumbnail.length === 0
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            Layout.fillWidth: true
                            text: root.currentTitle || "Downloading stream..."
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }
                        Text {
                            text: (root.currentUploader ? (root.currentUploader + " • ") : "") + (root.downloadMode === "video" ? ("MP4 (" + root.videoQuality + ")") : (root.audioFormat.toUpperCase()))
                            color: Theme.alpha(Theme.foreground, 0.55)
                            font.family: "Outfit"
                            font.pixelSize: 11
                        }
                    }

                    // Cancel button
                    Rectangle {
                        width: 72
                        height: 32
                        radius: 8
                        color: cancelMouse.containsMouse ? Theme.alpha(Theme.error, 0.25) : Theme.alpha(Theme.surface, 0.80)
                        border.width: 1
                        border.color: Theme.alpha(Theme.error, 0.50)

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Theme.error
                            font.family: "Outfit"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: root.cancelDownload()
                        }
                    }
                }

                // Progress Bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 10
                    radius: 5
                    color: Theme.alpha(Theme.foreground, 0.12)
                    clip: true

                    Rectangle {
                        height: parent.height
                        radius: 5
                        width: parent.width * (Math.max(0.0, Math.min(100.0, root.percent)) / 100.0)
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Theme.accent }
                            GradientStop { position: 1.0; color: Theme.primary }
                        }
                        Behavior on width { NumberAnimation { duration: 150 } }
                    }
                }

                // Metrics Row
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: root.status === "processing" ? "Processing & Converting..." : (root.percent.toFixed(1) + "%")
                        color: Theme.accent
                        font.family: "Outfit"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "Speed: " + root.speedStr
                        color: Theme.alpha(Theme.foreground, 0.70)
                        font.family: "Outfit"
                        font.pixelSize: 11
                        visible: root.status === "downloading"
                    }
                    Text {
                        text: " • ETA: " + root.etaStr
                        color: Theme.alpha(Theme.foreground, 0.70)
                        font.family: "Outfit"
                        font.pixelSize: 11
                        visible: root.status === "downloading"
                    }
                }
            }

            // 3. Complete View
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12
                visible: root.status === "complete"

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 52
                    height: 52
                    radius: 26
                    color: Theme.alpha("#22c55e", 0.18)
                    border.width: 1.5
                    border.color: "#22c55e"

                    Image {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        source: root.checkSvg
                        sourceSize: Qt.size(24, 24)
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Download Complete!"
                    color: Theme.foreground
                    font.family: "Outfit"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.currentTitle
                    color: Theme.alpha(Theme.foreground, 0.75)
                    font.family: "Outfit"
                    font.pixelSize: 12
                    Layout.maximumWidth: 500
                    elide: Text.ElideMiddle
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12
                    Layout.topMargin: 6

                    // Open Folder
                    Rectangle {
                        height: 36
                        implicitWidth: 120
                        radius: 10
                        color: Theme.alpha(Theme.surface, 0.90)
                        border.width: 1
                        border.color: Theme.alpha(Theme.foreground, 0.20)

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Image {
                                width: 14
                                height: 14
                                source: root.folderSvg
                                sourceSize: Qt.size(24, 24)
                            }
                            Text {
                                text: "Open Folder"
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var dir = root.downloadMode === "audio" ? (root.homeDir + "/Music") : (root.homeDir + "/Downloads")
                                Quickshell.execDetached(["xdg-open", dir])
                            }
                        }
                    }

                    // Play File
                    Rectangle {
                        height: 36
                        implicitWidth: 110
                        radius: 10
                        color: Theme.accent

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Image {
                                width: 14
                                height: 14
                                source: root.playSvg
                                sourceSize: Qt.size(24, 24)
                            }
                            Text {
                                text: "Play"
                                color: Theme.on_primary
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.currentFilepath.length > 0) {
                                    Quickshell.execDetached(["xdg-open", root.currentFilepath])
                                }
                            }
                        }
                    }

                    // Another download
                    Rectangle {
                        height: 36
                        implicitWidth: 120
                        radius: 10
                        color: Theme.alpha(Theme.foreground, 0.10)

                        Text {
                            anchors.centerIn: parent
                            text: "Download More"
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 12
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.status = "idle"
                                urlInput.text = ""
                                root.activeUrl = ""
                            }
                        }
                    }
                }
            }

            // 4. Error View
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10
                visible: root.status === "error"

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Download Failed"
                    color: Theme.error
                    font.family: "Outfit"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.maximumWidth: 480
                    text: root.errorMessage || "Unknown error occurred while downloading."
                    color: Theme.alpha(Theme.foreground, 0.65)
                    font.family: "Outfit"
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    height: 32
                    implicitWidth: 100
                    radius: 8
                    color: Theme.alpha(Theme.foreground, 0.15)
                    Text {
                        anchors.centerIn: parent
                        text: "Try Again"
                        color: Theme.foreground
                        font.family: "Outfit"
                        font.pixelSize: 12
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.status = "idle"
                    }
                }
            }
        }

        // ── BOTTOM ACTION BAR ────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: "Files saved to " + (root.downloadMode === "audio" ? "~/Music" : "~/Downloads")
                color: Theme.alpha(Theme.foreground, 0.45)
                font.family: "Outfit"
                font.pixelSize: 11
            }

            Item { Layout.fillWidth: true }

            // Download Trigger Button
            Rectangle {
                width: 150
                height: 42
                radius: 12
                color: (urlInput.text.trim().length > 0 && root.status !== "downloading" && root.status !== "processing") ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)
                opacity: (urlInput.text.trim().length > 0 && root.status !== "downloading") ? 1.0 : 0.5
                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Image {
                        width: 16
                        height: 16
                        source: root.downloadSvg
                        sourceSize: Qt.size(24, 24)
                    }
                    Text {
                        text: root.status === "downloading" ? "Downloading..." : "Start Download"
                        color: Theme.on_primary
                        font.family: "Outfit"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: (urlInput.text.trim().length > 0 && root.status !== "downloading") ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: urlInput.text.trim().length > 0 && root.status !== "downloading" && root.status !== "processing"
                    onClicked: root.startDownload()
                }
            }
        }
    }
}
