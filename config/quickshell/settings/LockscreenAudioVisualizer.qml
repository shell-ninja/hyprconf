import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "."

Item {
    id: root

    property bool previewMode: false
    property int barCount: 14
    property bool showBackground: true

    implicitWidth: 260
    implicitHeight: 52
    width: implicitWidth
    height: implicitHeight

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    property var liveBars: []
    property bool hasActiveAudio: false

    // Check MPRIS media playback
    readonly property bool isMediaPlaying: {
        var players = Mpris.players ? Mpris.players.values : []
        for (var i = 0; i < players.length; i++) {
            var p = players[i]
            if (p && p.playbackState === MprisPlaybackState.Playing) return true
        }
        return false
    }

    // Normalized distance from edge to center: 0.0 at outer edges, 1.0 at center
    function getU(index, totalBars) {
        if (totalBars <= 1) return 0.0
        var maxDist = (totalBars - 1) / 2.0
        var distFromEdge = Math.min(index, totalBars - 1 - index)
        return maxDist > 0 ? (distFromEdge / maxDist) : 0.0
    }

    // aaabbbccccbbbaaa Symmetrical Tier Multiplier Curve
    function getTierMultiplier(u) {
        if (u <= 0.35) {
            return 1.00 - 0.15 * (u / 0.35) // Tier 'a': 1.00 -> 0.85 (peaks at edges)
        } else if (u <= 0.70) {
            return 0.85 - 0.33 * ((u - 0.35) / 0.35) // Tier 'b': 0.85 -> 0.52 (mid-slope)
        } else {
            return 0.52 - 0.24 * ((u - 0.70) / 0.30) // Tier 'c': 0.52 -> 0.28 (center valley)
        }
    }

    // Frequency interpolation across CAVA spectrum
    function sampleLiveCava(u) {
        if (!root.liveBars || root.liveBars.length === 0) return 0.0
        var maxIdx = root.liveBars.length - 1
        var fIdx = Math.max(0.0, Math.min(maxIdx, u * maxIdx))
        var idx0 = Math.floor(fIdx)
        var idx1 = Math.min(maxIdx, idx0 + 1)
        var frac = fIdx - idx0
        var v0 = (root.liveBars[idx0] !== undefined) ? root.liveBars[idx0] : 0.0
        var v1 = (root.liveBars[idx1] !== undefined) ? root.liveBars[idx1] : 0.0
        return v0 * (1.0 - frac) + v1 * frac
    }

    // CAVA process stream reader
    Process {
        id: cavaProc
        command: ["cava", "-p", root.homeDir + "/.hyprconf/hypr/.cache/cava-island.conf"]
        running: !root.previewMode && root.visible && (root.isMediaPlaying || root.hasActiveAudio)
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (!data || data.length === 0) return
                var values = data.trim().split(";")
                var newBars = []
                var sum = 0
                for (var i = 0; i < 16; i++) {
                    var raw = (i < values.length) ? parseInt(values[i], 10) : 0
                    var val = isNaN(raw) ? 0.0 : Math.min(1.0, Math.max(0.0, raw / 100.0))
                    newBars.push(val)
                    sum += val
                }
                root.liveBars = newBars
                if (sum > 0.04) {
                    root.hasActiveAudio = true
                    audioTimeout.restart()
                }
            }
        }
    }

    Timer {
        id: audioTimeout
        interval: 1400
        repeat: false
        onTriggered: root.hasActiveAudio = false
    }

    // Idle organic harmonic breathing animation (only in preview/interactive mode)
    property real phase: 0.0
    NumberAnimation on phase {
        from: 0.0
        to: Math.PI * 2
        duration: 3200
        loops: Animation.Infinite
        running: root.previewMode && root.visible
    }

    // Obsidian Glass Container
    Rectangle {
        anchors.fill: parent
        radius: 16
        visible: root.showBackground
        color: Theme.alpha(Theme.surface, 0.50)
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.32)

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            height: 1
            color: Theme.alpha(Theme.foreground, 0.12)
        }
    }

    // Bars Row
    Row {
        anchors.centerIn: parent
        spacing: Math.max(3, Math.min(8, Math.floor((root.width - 40 - (root.barCount * 8)) / Math.max(1, root.barCount - 1))))
        height: parent.height - 18

        Repeater {
            model: root.barCount

            Item {
                id: barItem
                readonly property int barIndex: index
                readonly property real u: root.getU(index, root.barCount)
                readonly property real tier: root.getTierMultiplier(u)

                readonly property real barHeightFactor: {
                    if (root.previewMode) {
                        var pBreath = 0.40 + 0.35 * Math.sin(root.phase + u * Math.PI)
                        return Math.max(0.12, pBreath * tier)
                    }
                    if (root.hasActiveAudio && root.liveBars && root.liveBars.length > 0) {
                        var raw = root.sampleLiveCava(u)
                        var curved = Math.pow(Math.min(1.0, raw * 1.35), 0.85)
                        return Math.max(0.08 * tier, Math.min(1.0, curved * tier))
                    }
                    return 0.08 * tier
                }

                width: 8
                height: parent.height

                // Individual Rounded Bar
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    height: Math.max(parent.width, Math.round(parent.height * barItem.barHeightFactor))
                    radius: width / 2 // Rounded corners!

                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: Theme.accent
                        }
                        GradientStop {
                            position: 1.0
                            color: Theme.alpha(Theme.secondary, 0.75)
                        }
                    }

                    Behavior on height {
                        enabled: root.hasActiveAudio || root.isMediaPlaying || root.previewMode
                        NumberAnimation { duration: 65; easing.type: Easing.OutQuad }
                    }
                }
            }
        }
    }
}
