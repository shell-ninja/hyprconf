import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import ".."

Pill {
    id: rootPill
    clickable: true
    hPad: 8
    spacing: 6

    readonly property var settings: (typeof bar !== "undefined" && bar && bar.widgetSettings && bar.widgetSettings.media) ? bar.widgetSettings.media : ({})
    readonly property int maxChars: (settings.max_length !== undefined) ? Math.max(10, Math.min(60, parseInt(settings.max_length, 10))) : 22
    readonly property bool showArtist: settings.show_artist !== false
    readonly property bool showIcon: settings.show_icon !== false

    readonly property var player: (typeof bar !== "undefined" && bar) ? bar.player : null
    readonly property bool isPlaying: player && player.playbackState === MprisPlaybackState.Playing
    readonly property string trackTitle: player ? (player.trackTitle || "") : ""
    readonly property string trackArtist: player ? (player.trackArtist || "") : ""

    visible: trackTitle.length > 0
    implicitWidth: visible ? (rowContent.implicitWidth + hPad * 2) : 0

    RowLayout {
        id: rowContent
        spacing: 6
        Layout.alignment: Qt.AlignVCenter

        SvgIcon {
            visible: rootPill.showIcon
            name: "musicWave"
            size: 14
            color: rootPill.isPlaying ? Theme.accent : Theme.alpha(Theme.foreground, 0.60)
            Behavior on color { ColorAnimation { duration: 140 } }
        }

        Text {
            Layout.maximumWidth: Math.max(80, rootPill.maxChars * 7.5)
            text: (rootPill.showArtist && rootPill.trackArtist.length > 0) ? (rootPill.trackTitle + " • " + rootPill.trackArtist) : rootPill.trackTitle
            color: rootPill.hovered ? Theme.accent : Theme.foreground
            font.family: "Outfit"
            font.pixelSize: 11
            font.weight: Font.Medium
            elide: Text.ElideRight
            Behavior on color { ColorAnimation { duration: 140 } }
        }
    }

    onClicked: {
        if (rootPill.player) {
            rootPill.player.togglePlaying()
        }
    }
}
