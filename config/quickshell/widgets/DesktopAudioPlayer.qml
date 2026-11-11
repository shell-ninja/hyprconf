import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "."

Item {
    id: root

    property var widgetConfig: ({
        compact: false,
        show_background: true,
        glass_opacity: 0.65,
        show_vinyl: true,
        show_visualizer: true,
        hide_when_idle: false
    })
    property bool editMode: false

    readonly property bool isCompact: Boolean(widgetConfig && widgetConfig.compact)
    readonly property bool showVinyl: (widgetConfig && widgetConfig.show_vinyl !== undefined) ? Boolean(widgetConfig.show_vinyl) : true
    readonly property bool showVisualizer: (widgetConfig && widgetConfig.show_visualizer !== undefined) ? Boolean(widgetConfig.show_visualizer) : true
    readonly property bool hideWhenIdle: Boolean(widgetConfig && widgetConfig.hide_when_idle)

    implicitWidth: isCompact ? 320 : 380
    implicitHeight: isCompact ? 108 : 148
    width: implicitWidth
    height: implicitHeight

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    // Active MPRIS Player
    readonly property var activePlayer: {
        var players = Mpris.players ? Mpris.players.values : []
        for (var i = 0; i < players.length; i++) {
            var p = players[i]
            if (p && p.playbackState === MprisPlaybackState.Playing) return p
        }
        return (players && players.length > 0) ? players[0] : null
    }

    readonly property bool isPlaying: activePlayer ? (activePlayer.playbackState === MprisPlaybackState.Playing) : false
    readonly property string trackTitle: activePlayer ? (activePlayer.trackTitle || "No Media Playing") : "No Media Playing"
    readonly property string trackArtist: activePlayer ? (activePlayer.trackArtist || "Offline") : "Offline"
    readonly property string trackAlbum: activePlayer ? (activePlayer.trackAlbum || "") : ""
    readonly property string playerName: activePlayer ? (activePlayer.identity || "Media") : "Media"
    readonly property string artUrl: activePlayer ? (activePlayer.trackArtUrl || "") : ""
    readonly property real trackLength: activePlayer ? (activePlayer.length || 0) : 0
    readonly property real trackPosition: activePlayer ? (activePlayer.position || 0) : 0

    // Auto-hide when idle calculation
    readonly property bool isIdle: !isPlaying && !editMode && (artUrl.length === 0 && trackTitle === "No Media Playing")
    readonly property bool shouldHide: hideWhenIdle && isIdle

    opacity: shouldHide ? 0.0 : 1.0
    scale: shouldHide ? 0.94 : 1.0
    visible: opacity > 0.01

    Behavior on opacity {
        NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
    }
    Behavior on scale {
        SpringAnimation { spring: 3.2; damping: 0.38 }
    }

    function formatTime(seconds) {
        if (!seconds || isNaN(seconds) || seconds < 0) return "00:00"
        var s = Math.floor(seconds)
        var m = Math.floor(s / 60)
        s = s % 60
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s)
    }

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string playSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="' + Theme.background + '"><polygon points="6 3 20 12 6 21 6 3"/></svg>')
    readonly property string pauseSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="' + Theme.background + '"><rect x="6" y="4" width="4" height="16"/><rect x="14" y="4" width="4" height="16"/></svg>')
    readonly property string prevSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="19 20 9 12 19 4 19 20"/><line x1="5" y1="19" x2="5" y2="5"/></svg>')
    readonly property string nextSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="5 4 15 12 5 20 5 4"/><line x1="19" y1="5" x2="19" y2="19"/></svg>')
    readonly property string musicNoteSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></svg>')

    // Seeking command runner
    Process {
        id: seekProc
    }

    function seekToFraction(fraction) {
        var dur = root.editMode ? 230 : root.trackLength
        if (dur <= 0) return
        var targetSec = Math.max(0, Math.min(dur, fraction * dur))
        seekProc.command = ["playerctl", "position", Math.round(targetSec).toString()]
        seekProc.running = true
    }

    // Mini Cava / Frequency Generator for embedded audio waves
    property var liveWaveBars: [0.3, 0.6, 0.8, 0.4, 0.7, 0.9, 0.5, 0.3, 0.8, 0.6, 0.4, 0.7]
    property real wavePhase: 0.0

    Timer {
        interval: 80
        repeat: true
        running: (root.isPlaying || root.editMode) && root.showVisualizer && root.visible
        onTriggered: {
            root.wavePhase = (root.wavePhase + 0.35) % (Math.PI * 2)
            var newBars = []
            var count = 12
            for (var i = 0; i < count; i++) {
                var wave1 = Math.sin(root.wavePhase + i * 0.55)
                var wave2 = Math.cos(root.wavePhase * 0.7 + i * 0.3)
                var val = 0.25 + 0.45 * Math.abs(wave1 * 0.6 + wave2 * 0.4)
                newBars.push(Math.max(0.12, Math.min(1.0, val)))
            }
            root.liveWaveBars = newBars
        }
    }

    // Glassmorphic Obsidian Background Card
    Rectangle {
        id: bgCard
        anchors.fill: parent
        radius: 20
        clip: true
        visible: (root.widgetConfig && root.widgetConfig.show_background !== undefined) ? (root.widgetConfig.show_background !== false) : true
        color: Theme.alpha(Theme.mix(Theme.background, Theme.surface, 0.45), (root.widgetConfig && root.widgetConfig.glass_opacity !== undefined) ? root.widgetConfig.glass_opacity : 0.65)
        border.width: 1
        border.color: Theme.alpha(Theme.foreground, 0.12)

        // Top Glass Rim Reflection
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.25; color: Theme.alpha(Theme.foreground, 0.10) }
                GradientStop { position: 0.50; color: Theme.alpha(Theme.foreground, 0.22) }
                GradientStop { position: 0.75; color: Theme.alpha(Theme.foreground, 0.10) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    // Main Content
    RowLayout {
        anchors.fill: parent
        anchors.margins: root.isCompact ? 10 : 14
        spacing: root.isCompact ? 10 : 14

        // ── LEFT: VINYL TURNTABLE OR SQUARE ALBUM COVER ──────────────────────
        Item {
            id: mediaArtContainer
            Layout.preferredWidth: root.isCompact ? 80 : 108
            Layout.preferredHeight: root.isCompact ? 80 : 108
            Layout.alignment: Qt.AlignVCenter

            // Mode 1: SPINNING VINYL RECORD DISC
            Item {
                id: vinylWrapper
                anchors.fill: parent
                visible: root.showVinyl

                // The spinning vinyl disc item
                Item {
                    id: vinylDisc
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) - 4
                    height: width

                    // Rotation Animation
                    NumberAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 7500
                        loops: Animation.Infinite
                        running: (root.isPlaying || root.editMode)
                    }

                    // Vinyl Outer Base
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "#0c0d11"
                        border.width: 1
                        border.color: Theme.alpha(Theme.foreground, 0.18)

                        // Outer Vinyl Grooves (Concentric Circles)
                        Repeater {
                            model: [4, 8, 13, 18, 23, 28]
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width - (modelData * 2)
                                height: width
                                radius: width / 2
                                color: "transparent"
                                border.width: 1
                                border.color: (index % 2 === 0) ? Theme.alpha(Theme.foreground, 0.05) : Theme.alpha(Theme.foreground, 0.025)
                            }
                        }

                        // Vinyl Light Sheen (Conical/Diagonal Glare Simulation)
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width * 0.90
                            height: 2
                            rotation: 45
                            color: Theme.alpha(Theme.foreground, 0.06)
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width * 0.90
                            height: 2
                            rotation: -45
                            color: Theme.alpha(Theme.foreground, 0.04)
                        }

                        // Center Vinyl Label Sticker (Album Art)
                        Rectangle {
                            id: vinylCenterLabel
                            anchors.centerIn: parent
                            width: Math.round(parent.width * 0.44)
                            height: width
                            radius: width / 2
                            color: Theme.alpha(Theme.surface, 0.95)
                            border.width: 1.5
                            border.color: Theme.alpha(Theme.accent, 0.40)
                            clip: true

                            Image {
                                id: vinylAlbumImg
                                anchors.fill: parent
                                source: root.editMode ? "" : root.artUrl
                                fillMode: Image.PreserveAspectCrop
                                visible: root.artUrl.length > 0 && status === Image.Ready && !root.editMode
                            }

                            // Fallback editMode/no-art label with accent tones
                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                visible: !vinylAlbumImg.visible
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: Theme.alpha(Theme.accent, 0.35) }
                                    GradientStop { position: 1.0; color: Theme.alpha(Theme.surface, 0.95) }
                                }

                                Image {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.45
                                    height: width
                                    source: root.musicNoteSvg
                                }
                            }

                            // Center Spindle Pin Hole
                            Rectangle {
                                anchors.centerIn: parent
                                width: 8
                                height: 8
                                radius: 4
                                color: "#060608"
                                border.width: 1
                                border.color: Theme.alpha(Theme.foreground, 0.45)
                            }
                        }
                    }
                }

                // Turntable Tonearm Stylus
                Item {
                    id: toneArm
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 2
                    anchors.rightMargin: 2
                    width: 16
                    height: parent.height * 0.75
                    transformOrigin: Item.TopRight

                    rotation: (root.isPlaying || root.editMode) ? 18 : 0

                    Behavior on rotation {
                        SpringAnimation { spring: 2.8; damping: 0.40 }
                    }

                    // Pivot Base Pin
                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        width: 8
                        height: 8
                        radius: 4
                        color: Theme.alpha(Theme.foreground, 0.40)
                        border.width: 1
                        border.color: Theme.alpha(Theme.foreground, 0.70)
                    }

                    // Arm Rod
                    Rectangle {
                        anchors.top: parent.top
                        anchors.topMargin: 4
                        anchors.right: parent.right
                        anchors.rightMargin: 3
                        width: 2
                        height: parent.height - 10
                        radius: 1
                        color: Theme.alpha(Theme.foreground, 0.35)
                    }

                    // Stylus Head Cartridge
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.rightMargin: 1
                        width: 6
                        height: 10
                        radius: 2
                        color: Theme.accent
                        border.width: 1
                        border.color: Theme.alpha(Theme.foreground, 0.50)
                    }
                }
            }

            // Mode 2: SQUARE ALBUM ART CARD
            Rectangle {
                id: squareAlbumCard
                anchors.fill: parent
                radius: 14
                visible: !root.showVinyl
                color: Theme.alpha(Theme.surface, 0.85)
                border.width: 1
                border.color: Theme.alpha(Theme.foreground, 0.14)
                clip: true

                Image {
                    id: squareArtImg
                    anchors.fill: parent
                    source: root.editMode ? "" : root.artUrl
                    fillMode: Image.PreserveAspectCrop
                    visible: root.artUrl.length > 0 && status === Image.Ready && !root.editMode
                }

                // Fallback note
                Rectangle {
                    anchors.fill: parent
                    visible: !squareArtImg.visible
                    color: Theme.alpha(Theme.surface, 0.90)

                    Image {
                        anchors.centerIn: parent
                        width: 28; height: 28
                        source: root.musicNoteSvg
                    }
                }
            }
        }

        // ── RIGHT: METADATA, VISUALIZER, SCRUBBER, CONTROLS ──────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.isCompact ? 4 : 6

            // Header Tag: Player App & Live Waveform Badge
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // Status Dot
                Rectangle {
                    width: 6; height: 6; radius: 3
                    color: (root.isPlaying || root.editMode) ? Theme.accent : Theme.alpha(Theme.foreground, 0.30)

                    SequentialAnimation on opacity {
                        running: root.isPlaying || root.editMode
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.4; to: 1.0; duration: 900; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 1.0; to: 0.4; duration: 900; easing.type: Easing.InOutQuad }
                    }
                }

                // Player Identity Label
                Text {
                    text: (root.editMode ? "SPOTIFY" : root.playerName).toUpperCase()
                    color: Theme.alpha(Theme.foreground, 0.55)
                    font.family: "Fira Code"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.letterSpacing: 1.0
                }

                Item { Layout.fillWidth: true }

                // Embedded Wave Bars (Right-aligned in header)
                Row {
                    spacing: 2
                    visible: root.showVisualizer
                    height: 12
                    Layout.alignment: Qt.AlignVCenter

                    Repeater {
                        model: root.liveWaveBars
                        Rectangle {
                            width: 2
                            height: Math.max(2, Math.round(12 * modelData))
                            radius: 1
                            anchors.bottom: parent.bottom
                            color: Theme.accent
                            opacity: (root.isPlaying || root.editMode) ? (0.45 + 0.55 * modelData) : 0.20

                            Behavior on height {
                                NumberAnimation { duration: 70; easing.type: Easing.OutQuad }
                            }
                        }
                    }
                }
            }

            // Track Title
            Text {
                Layout.fillWidth: true
                text: root.editMode ? "Starboy (feat. Daft Punk)" : root.trackTitle
                color: Theme.foreground
                font.family: "Outfit"
                font.pixelSize: root.isCompact ? 12 : 14
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            // Artist Name
            Text {
                Layout.fillWidth: true
                text: root.editMode ? "The Weeknd" : root.trackArtist
                color: Theme.alpha(Theme.foreground, 0.65)
                font.family: "Outfit"
                font.pixelSize: root.isCompact ? 10 : 11
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            // Interactive Progress Scrubber
            Column {
                Layout.fillWidth: true
                spacing: 3
                Layout.topMargin: root.isCompact ? 1 : 3

                // Track Bar with Scrubber Handle
                Rectangle {
                    id: scrubTrack
                    width: parent.width
                    height: scrubMouse.containsMouse ? 6 : 4
                    radius: height / 2
                    color: Theme.alpha(Theme.surface, 0.85)

                    Behavior on height {
                        NumberAnimation { duration: 120 }
                    }

                    // Progress Fill
                    Rectangle {
                        height: parent.height
                        radius: height / 2
                        color: Theme.accent
                        width: {
                            if (root.editMode) return parent.width * 0.45
                            if (root.trackLength > 0) {
                                return Math.max(4, Math.min(parent.width, Math.round(parent.width * (root.trackPosition / root.trackLength))))
                            }
                            return 0
                        }
                    }

                    // Scrubber Thumb Handle (Reveals on hover)
                    Rectangle {
                        width: scrubMouse.containsMouse ? 10 : 0
                        height: width
                        radius: width / 2
                        color: "#ffffff"
                        anchors.verticalCenter: parent.verticalCenter
                        x: {
                            var pWidth = scrubTrack.width
                            if (root.editMode) return Math.max(0, pWidth * 0.45 - width / 2)
                            if (root.trackLength > 0) {
                                return Math.max(0, Math.min(pWidth - width, (pWidth * (root.trackPosition / root.trackLength)) - width / 2))
                            }
                            return 0
                        }
                        opacity: scrubMouse.containsMouse ? 1.0 : 0.0

                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }
                    }

                    MouseArea {
                        id: scrubMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            var frac = mouse.x / width
                            root.seekToFraction(frac)
                        }
                        onPositionChanged: mouse => {
                            if (pressed) {
                                var frac = mouse.x / width
                                root.seekToFraction(frac)
                            }
                        }
                    }
                }

                // Timestamps Row
                RowLayout {
                    width: parent.width

                    Text {
                        text: root.editMode ? "01:24" : root.formatTime(root.trackPosition)
                        color: Theme.alpha(Theme.foreground, 0.45)
                        font.family: "Outfit"
                        font.pixelSize: 9
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.editMode ? "03:50" : root.formatTime(root.trackLength)
                        color: Theme.alpha(Theme.foreground, 0.45)
                        font.family: "Outfit"
                        font.pixelSize: 9
                    }
                }
            }

            // Transport Control Buttons
            Row {
                spacing: 12
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: root.isCompact ? 1 : 3

                // Previous Button
                Rectangle {
                    width: 28; height: 28; radius: 14
                    color: prevMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : "transparent"
                    scale: prevMouse.pressed ? 0.90 : (prevMouse.containsMouse ? 1.12 : 1.0)

                    Behavior on scale {
                        SpringAnimation { spring: 3.5; damping: 0.35 }
                    }

                    Image {
                        anchors.centerIn: parent
                        width: 14; height: 14
                        source: root.prevSvg
                    }

                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.activePlayer && typeof root.activePlayer.previous === "function") {
                                root.activePlayer.previous()
                            }
                        }
                    }
                }

                // Play / Pause Button with Accent Glow
                Rectangle {
                    width: root.isCompact ? 28 : 32
                    height: width
                    radius: width / 2
                    color: Theme.accent
                    scale: playMouse.pressed ? 0.88 : (playMouse.containsMouse ? 1.10 : 1.0)

                    Behavior on scale {
                        SpringAnimation { spring: 4.0; damping: 0.32 }
                    }

                    Image {
                        anchors.centerIn: parent
                        width: 13; height: 13
                        source: (root.isPlaying || root.editMode) ? root.pauseSvg : root.playSvg
                    }

                    MouseArea {
                        id: playMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.activePlayer && typeof root.activePlayer.togglePlaying === "function") {
                                root.activePlayer.togglePlaying()
                            }
                        }
                    }
                }

                // Next Button
                Rectangle {
                    width: 28; height: 28; radius: 14
                    color: nextMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : "transparent"
                    scale: nextMouse.pressed ? 0.90 : (nextMouse.containsMouse ? 1.12 : 1.0)

                    Behavior on scale {
                        SpringAnimation { spring: 3.5; damping: 0.35 }
                    }

                    Image {
                        anchors.centerIn: parent
                        width: 14; height: 14
                        source: root.nextSvg
                    }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.activePlayer && typeof root.activePlayer.next === "function") {
                                root.activePlayer.next()
                            }
                        }
                    }
                }
            }
        }
    }
}
