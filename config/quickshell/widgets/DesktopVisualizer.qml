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
        return (h && h.length > 0) ? h : "/home/shell-ninja"
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

    // Pattern helper function: maps bar index into 'a', 'b', or 'c'
    // Pattern: ["a", "a", "b", "b", "c", "c", "c", "c", "b", "b", "a", "a"]
    function getPatternTier(index, totalBars) {
        var pattern = ["a", "a", "b", "b", "c", "c", "c", "c", "b", "b", "a", "a"]
        var pIdx = Math.min(11, Math.max(0, Math.floor(index * 12.0 / Math.max(1, totalBars))))
        return pattern[pIdx]
    }

    // Process to read real-time CAVA stream
    Process {
        id: cavaProc
        command: ["cava", "-p", root.homeDir + "/.hyprconf/hypr/.cache/cava-island.conf"]
        running: !root.editMode && (root.widgetConfig ? root.widgetConfig.enabled !== false : true) && root.visible
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

        readonly property real computedBarWidth: Math.max(6, Math.min(22, Math.floor((vizContainer.width * 0.60) / root.activeBarCount)))
        readonly property real computedSpacing: Math.max(4, Math.floor((vizContainer.width - root.activeBarCount * computedBarWidth) / Math.max(1, root.activeBarCount - 1)))

        Row {
            anchors.centerIn: parent
            spacing: Math.max(2, Math.floor((parent.width - root.activeBarCount * 4) / Math.max(1, root.activeBarCount - 1)))
            height: parent.height

            Repeater {
                model: root.activeBarCount

                Item {
                    id: barItem
                    readonly property int barIndex: index
                    readonly property real barVal: {
                        if (root.editMode) {
                            var rel = Math.abs(index - root.activeBarCount / 2) / (root.activeBarCount / 2)
                            return 0.3 + 0.6 * (1.0 - rel)
                        }
                        if (root.hasActiveAudio && root.liveBars && root.liveBars.length > index) {
                            return root.liveBars[index]
                        }
                        // Gentle ambient sine wave harmonic
                        var normI = index / root.activeBarCount
                        var wave = Math.sin(normI * Math.PI * 3 + root.phase)
                        return 0.08 + 0.18 * Math.max(0.0, wave)
                    }

                    width: Math.max(3, Math.min(8, Math.floor(parent.parent.width / root.activeBarCount) - 2))
                    height: parent.height

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        height: Math.max(4, Math.round(parent.height * barItem.barVal))
                        radius: width / 2

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
