import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Pill {
    id: rootPill
    clickable: true
    hPad: 8
    spacing: 5

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    readonly property string statePath: rootPill.homeDir + "/.local/share/hyprconf/.cache/media_downloader_state.json"

    property string dlStatus: "idle"
    property real dlPercent: 0.0

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stateReader.running = true
        }
    }

    Process {
        id: stateReader
        command: ["cat", rootPill.statePath]
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    try {
                        var d = JSON.parse(text.trim())
                        if (d.status) rootPill.dlStatus = d.status
                        if (d.percent !== undefined) rootPill.dlPercent = d.percent
                    } catch(e) {}
                }
            }
        }
    }

    readonly property bool isDownloading: rootPill.dlStatus === "downloading" || rootPill.dlStatus === "processing"

    SvgIcon {
        name: "download"
        size: 15
        color: rootPill.isDownloading ? Theme.accent : (rootPill.hovered ? Theme.accent : Theme.alpha(Theme.foreground, 0.70))
        Behavior on color { ColorAnimation { duration: 140 } }
    }

    Text {
        text: rootPill.isDownloading ? (Math.round(rootPill.dlPercent) + "%") : "Media"
        color: rootPill.isDownloading ? Theme.accent : (rootPill.hovered ? Theme.accent : Theme.alpha(Theme.foreground, 0.70))
        font.family: "Outfit"
        font.pixelSize: 11
        font.weight: rootPill.isDownloading ? Font.Bold : Font.Medium
        visible: rootPill.isDownloading || rootPill.hovered
        Behavior on color { ColorAnimation { duration: 140 } }
    }

    Component.onCompleted: {
        if (typeof bar !== "undefined" && bar) bar.mediaTrigger = rootPill
    }
    Component.onDestruction: {
        if (typeof bar !== "undefined" && bar && bar.mediaTrigger === rootPill) bar.mediaTrigger = null
    }

    onClicked: {
        if (typeof bar !== "undefined" && bar) {
            bar.toggleMediaDownloader()
        }
    }
}
