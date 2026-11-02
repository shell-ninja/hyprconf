import QtQuick
import Quickshell.Services.Mpris
import ".."

Pill {
    id: rootPill
    clickable: true
    hPad: 8
    spacing: 6

    readonly property var player: (typeof bar !== "undefined" && bar) ? bar.player : null
    readonly property bool isPlaying: player && player.playbackState === MprisPlaybackState.Playing

    readonly property var settings: (typeof bar !== "undefined" && bar && bar.widgetSettings && bar.widgetSettings.visualizer) ? bar.widgetSettings.visualizer : ({})
    readonly property int barCount: (settings.bars !== undefined) ? Math.max(4, Math.min(16, parseInt(settings.bars, 10))) : 8
    readonly property real barW: (settings.bar_width !== undefined) ? Math.max(2.0, Math.min(6.0, parseFloat(settings.bar_width))) : 3.0
    readonly property real barGap: (settings.spacing !== undefined) ? Math.max(1.5, Math.min(6.0, parseFloat(settings.spacing))) : 2.5
    readonly property string vizMode: settings.alignment || "bottom" // "bottom" (upwards), "center", "top"
    readonly property bool hideWhenIdle: !!settings.hide_when_idle
    readonly property real maxH: 18

    visible: !hideWhenIdle || isPlaying
    implicitWidth: visible ? (vizContainer.implicitWidth + hPad * 2) : 0

    Item {
        id: vizContainer
        anchors.centerIn: parent
        implicitWidth: barCount * barW + (barCount - 1) * barGap
        height: rootPill.maxH

        Row {
            anchors.fill: parent
            spacing: rootPill.barGap

            Repeater {
                model: rootPill.barCount
                Item {
                    width: rootPill.barW
                    height: rootPill.maxH

                    Rectangle {
                        id: vizBar
                        width: parent.width
                        radius: width / 2
                        anchors.bottom: (rootPill.vizMode === "top") ? undefined : ((rootPill.vizMode === "center") ? undefined : parent.bottom)
                        anchors.top: (rootPill.vizMode === "top") ? parent.top : undefined
                        anchors.verticalCenter: (rootPill.vizMode === "center") ? parent.verticalCenter : undefined

                        color: rootPill.hovered
                            ? Theme.accent
                            : (rootPill.isPlaying ? ((index % 2 === 0) ? Theme.accent : Theme.secondary) : Theme.alpha(Theme.foreground, 0.30))

                        property real targetH: rootPill.isPlaying ? 4 : 3
                        height: rootPill.isPlaying ? targetH : 3

                        Behavior on height {
                            NumberAnimation { duration: 110; easing.type: Easing.OutSine }
                        }
                        Behavior on color {
                            ColorAnimation { duration: 180 }
                        }

                        Timer {
                            interval: 75 + (index * 22) % 85
                            running: rootPill.isPlaying
                            repeat: true
                            onTriggered: {
                                var pattern = [6, 12, 16, 14, 18, 15, 10, 5, 8, 14, 17, 13, 9, 6, 11, 7]
                                var base = pattern[index % pattern.length]
                                var jitter = (Math.random() * 6 - 3)
                                vizBar.targetH = Math.max(3, Math.min(rootPill.maxH, base + jitter))
                            }
                        }
                    }
                }
            }
        }
    }

    onClicked: {
        if (rootPill.player) {
            rootPill.player.togglePlaying()
        }
    }
}
