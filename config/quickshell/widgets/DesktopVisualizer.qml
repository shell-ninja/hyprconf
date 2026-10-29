import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "."

Item {
    id: root

    property var widgetConfig: ({
        bar_count: 12,
        style: "bars",
        show_background: true,
        glass_opacity: 0.55
    })
    property bool editMode: false

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    implicitWidth: 520
    implicitHeight: 90
    width: implicitWidth
    height: implicitHeight

    // Default 12 bars exactly corresponding to the 12-element pattern: aabbccccbbaa
    readonly property int activeBarCount: (root.widgetConfig && root.widgetConfig.bar_count) ? root.widgetConfig.bar_count : 12
    property var liveBars: []
    property bool hasActiveAudio: false

    // Check MPRIS playing state
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
            return 1.00 - 0.15 * (u / 0.35) // Tier 'a': 1.00 -> 0.85 (tallest peak)
        } else if (u <= 0.70) {
            return 0.85 - 0.33 * ((u - 0.35) / 0.35) // Tier 'b': 0.85 -> 0.52 (mid-slope)
        } else {
            return 0.52 - 0.24 * ((u - 0.70) / 0.30) // Tier 'c': 0.52 -> 0.28 (center valley)
        }
    }

    // Linear frequency interpolation across CAVA spectrum: edge (bass) to center (treble)
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

    // Process to read real-time CAVA stream
    Process {
        id: cavaProc
        command: ["cava", "-p", root.homeDir + "/.hyprconf/hypr/.cache/cava-island.conf"]
        running: !root.editMode && (root.widgetConfig ? root.widgetConfig.enabled !== false : true) && root.visible && (root.isMediaPlaying || root.hasActiveAudio)
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
                if (sum > 0.05) {
                    root.hasActiveAudio = true
                    audioTimeout.restart()
                }
            }
        }
    }

    Timer {
        id: audioTimeout
        interval: 1500
        repeat: false
        onTriggered: {
            root.hasActiveAudio = false
        }
    }

    // Idle harmonic breathing animation when no audio is playing
    property real phase: 0.0
    NumberAnimation on phase {
        from: 0.0
        to: Math.PI * 2
        duration: 3200
        loops: Animation.Infinite
        running: !root.hasActiveAudio && !root.isMediaPlaying && root.visible && (root.widgetConfig ? root.widgetConfig.enabled !== false : true)
    }

    // Background Obsidian Glass Card
    Rectangle {
        id: bgCard
        anchors.fill: parent
        radius: 20
        visible: (root.widgetConfig && root.widgetConfig.show_background !== undefined) ? (root.widgetConfig.show_background !== false) : true
        color: Theme.alpha(Theme.background, (root.widgetConfig && root.widgetConfig.glass_opacity !== undefined) ? root.widgetConfig.glass_opacity : 0.55)
        border.width: 1
        border.color: Theme.alpha(Theme.foreground, 0.12)

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            height: 1
            color: Theme.alpha(Theme.foreground, 0.12)
        }
    }

    // Audio Visualizer Spectrum Container
    Item {
        id: vizContainer
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.topMargin: 16
        anchors.bottomMargin: 16

        readonly property real computedSpacing: Math.max(3, Math.min(8, Math.floor((vizContainer.width * 0.12) / Math.max(1, root.activeBarCount - 1))))
        readonly property real computedBarWidth: Math.max(4, Math.min(28, Math.floor((vizContainer.width - (root.activeBarCount - 1) * computedSpacing) / root.activeBarCount)))

        Row {
            anchors.centerIn: parent
            spacing: vizContainer.computedSpacing
            height: parent.height

            Repeater {
                model: root.activeBarCount

                Item {
                    id: barItem
                    readonly property int barIndex: index
                    readonly property real barVal: {
                        var bCount = root.activeBarCount
                        var u = root.getU(index, bCount)
                        var tier = root.getTierMultiplier(u)

                        if (root.editMode) {
                            return Math.max(0.14, 0.92 * tier)
                        }
                        if (root.hasActiveAudio && root.liveBars && root.liveBars.length > 0) {
                            var raw = root.sampleLiveCava(u)
                            var curved = Math.pow(Math.min(1.0, raw * 1.35), 0.85)
                            return Math.max(0.08 * tier, Math.min(1.0, curved * tier))
                        }
                        // Idle harmonic breathing synced to aaabbbccccbbbaaa pattern
                        var breath = 0.25 + 0.15 * Math.sin(root.phase + u * Math.PI)
                        return Math.max(0.06, breath * tier)
                    }

                    width: vizContainer.computedBarWidth
                    height: parent.height

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        height: Math.max(4, Math.round(parent.height * barItem.barVal))
                        radius: (root.widgetConfig && root.widgetConfig.style === "wave") ? width / 2 : Math.min(3, width / 2)

                        gradient: Gradient {
                            GradientStop {
                                position: 0.0
                                color: Theme.accent
                            }
                            GradientStop {
                                position: 1.0
                                color: Theme.alpha(Theme.secondary, 0.70)
                            }
                        }

                        Behavior on height {
                            NumberAnimation { duration: 65; easing.type: Easing.OutQuad }
                        }
                    }
                }
            }
        }
    }
}
