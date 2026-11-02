import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Pill {
    id: rootPill
    clickable: true
    hPad: 8
    spacing: 6

    readonly property var settings: (typeof bar !== "undefined" && bar && bar.widgetSettings && bar.widgetSettings.network) ? bar.widgetSettings.network : ({})
    readonly property bool showArrows: settings.show_arrows !== false
    readonly property bool compact: !!settings.compact
    readonly property bool showIcon: settings.show_icon !== false

    property string downStr: "0 KB/s"
    property string upStr: "0 KB/s"
    property bool isConnected: true
    property string ifaceType: "wifi" // "wifi" | "ethernet"

    Process {
        id: netProc
        command: ["python3", Quickshell.env("HOME") + "/.hyprconf/hypr/scripts/py/island-process-net.py"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0) {
                    try {
                        var d = JSON.parse(text.trim())
                        rootPill.downStr = d.total_down_str || "0 KB/s"
                        rootPill.upStr = d.total_up_str || "0 KB/s"
                        rootPill.isConnected = (d.active_proc_count !== undefined)
                        if (typeof bar !== "undefined" && bar) {
                            bar.netProcesses = d.processes || []
                            bar.netDownStr = rootPill.downStr
                            bar.netUpStr = rootPill.upStr
                        }
                    } catch(e) {}
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: if (!netProc.running) netProc.running = true
    }

    RowLayout {
        id: rowContent
        spacing: 5
        Layout.alignment: Qt.AlignVCenter

        SvgIcon {
            visible: rootPill.showIcon
            name: rootPill.ifaceType === "ethernet" ? "refresh" : "wifi"
            size: 14
            color: rootPill.isConnected ? (rootPill.hovered ? Theme.accent : Theme.foreground) : Theme.error
            Behavior on color { ColorAnimation { duration: 140 } }
        }

        // Down / Up throughput text
        RowLayout {
            spacing: 4

            Text {
                visible: rootPill.showArrows
                text: "↓"
                color: "#06b6d4"
                font.family: "Outfit"
                font.pixelSize: 10
                font.weight: Font.Bold
            }

            Text {
                text: rootPill.downStr
                color: rootPill.hovered ? Theme.accent : Theme.foreground
                font.family: "Outfit"
                font.pixelSize: 10
                font.weight: Font.Medium
            }

            Text {
                visible: !rootPill.compact && rootPill.showArrows
                text: "↑"
                color: "#f59e0b"
                font.family: "Outfit"
                font.pixelSize: 10
                font.weight: Font.Bold
            }

            Text {
                visible: !rootPill.compact
                text: rootPill.upStr
                color: rootPill.hovered ? Theme.accent : Theme.foreground
                font.family: "Outfit"
                font.pixelSize: 10
                font.weight: Font.Medium
            }
        }
    }

    onClicked: {
        if (typeof bar !== "undefined" && bar) bar.toggleNetwork()
    }

    Component.onCompleted: {
        if (typeof bar !== "undefined" && bar) bar.netTrigger = rootPill
    }
    Component.onDestruction: {
        if (typeof bar !== "undefined" && bar && bar.netTrigger === rootPill) bar.netTrigger = null
    }
}
