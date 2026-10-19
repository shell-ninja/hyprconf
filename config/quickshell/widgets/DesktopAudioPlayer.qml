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
        glass_opacity: 0.65
    })
    property bool editMode: false

    implicitWidth: 340
    implicitHeight: 150
    width: implicitWidth
    height: implicitHeight

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
    readonly property string artUrl: activePlayer ? (activePlayer.trackArtUrl || "") : ""
    readonly property real trackLength: activePlayer ? (activePlayer.length || 0) : 0
    readonly property real trackPosition: activePlayer ? (activePlayer.position || 0) : 0

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

    // Glassmorphic Obsidian Background Card
    Rectangle {
        id: bgCard
        anchors.fill: parent
        radius: 20
        visible: (root.widgetConfig && root.widgetConfig.show_background !== undefined) ? (root.widgetConfig.show_background !== false) : true
        color: Theme.alpha(Theme.background, (root.widgetConfig && root.widgetConfig.glass_opacity !== undefined) ? root.widgetConfig.glass_opacity : 0.65)
        border.width: 1
        border.color: Theme.alpha(Theme.foreground, 0.12)

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            height: 1
            color: Theme.alpha(Theme.foreground, 0.14)
        }
    }

    // Main Layout
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // Top Row: Album Art + Track Info + Controls
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Album Art Thumbnail
            Rectangle {
                width: 64
                height: 64
                radius: 14
                color: Theme.alpha(Theme.surface, 0.80)
                border.width: 1
                border.color: Theme.alpha(Theme.foreground, 0.12)
                clip: true

                Image {
                    id: albumArtImg
                    anchors.fill: parent
                    source: root.artUrl
                    fillMode: Image.PreserveAspectCrop
                    visible: root.artUrl.length > 0 && status === Image.Ready
                }

                // Fallback Note
                Image {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    source: root.musicNoteSvg
                    visible: !albumArtImg.visible
                }
            }

            // Title, Artist and Transport Controls
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                // Track Title
                Text {
                    Layout.fillWidth: true
                    text: root.editMode ? "Starboy (feat. Daft Punk)" : root.trackTitle
                    color: Theme.foreground
                    font.family: "Outfit"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                // Artist Name
                Text {
                    Layout.fillWidth: true
                    text: root.editMode ? "The Weeknd" : root.trackArtist
                    color: Theme.alpha(Theme.foreground, 0.65)
                    font.family: "Outfit"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                // Controls Row
                Row {
                    spacing: 10
                    Layout.topMargin: 4

                    // Previous Button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: prevMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : "transparent"

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

                    // Play / Pause Button
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: Theme.accent

                        Image {
                            anchors.centerIn: parent
                            width: 14; height: 14
                            source: root.isPlaying ? root.pauseSvg : root.playSvg
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
                        width: 28
                        height: 28
                        radius: 14
                        color: nextMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : "transparent"

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

        // Bottom: Progress Scrubber
        Column {
            Layout.fillWidth: true
            spacing: 3

            Rectangle {
                width: parent.width
                height: 4
                radius: 2
                color: Theme.alpha(Theme.surface, 0.70)

                Rectangle {
                    height: parent.height
                    radius: 2
                    color: Theme.accent
                    width: {
                        if (root.editMode) return parent.width * 0.45
                        if (root.trackLength > 0) {
                            return Math.max(4, Math.round(parent.width * (root.trackPosition / root.trackLength)))
                        }
                        return 0
                    }
                }
            }

            // Timestamps
            RowLayout {
                width: parent.width

                Text {
                    text: root.editMode ? "01:24" : root.formatTime(root.trackPosition)
                    color: Theme.alpha(Theme.foreground, 0.50)
                    font.family: "Outfit"
                    font.pixelSize: 10
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.editMode ? "03:50" : root.formatTime(root.trackLength)
                    color: Theme.alpha(Theme.foreground, 0.50)
                    font.family: "Outfit"
                    font.pixelSize: 10
                }
            }
        }
    }
}
