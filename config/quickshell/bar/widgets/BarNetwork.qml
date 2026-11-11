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

    property real _prevRxBytes: -1
    property real _prevTxBytes: -1
    property double _prevTickMs: 0
    readonly property bool netPopupOpen: (typeof bar !== "undefined" && bar && bar.isNetOpen) ? true : false

    function formatRate(bps) {
        if (bps >= 1048576) return (bps / 1048576).toFixed(1) + " MB/s"
        if (bps >= 1024) return Math.round(bps / 1024) + " KB/s"
        return Math.round(bps) + " B/s"
    }

    function parseNetDev(txt) {
        if (!txt) return
        var lines = txt.split("\n")
        var totalRx = 0
        var totalTx = 0
        var detectedType = ""
        for (var i = 2; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line.length === 0) continue
            var colonIdx = line.indexOf(":")
            if (colonIdx <= 0) continue
            var iface = line.substring(0, colonIdx).trim()
            if (iface === "lo" || iface.indexOf("veth") === 0 || iface.indexOf("docker") === 0 || iface.indexOf("br-") === 0) continue
            var cols = line.substring(colonIdx + 1).trim().split(/\s+/)
            if (cols.length < 9) continue
            var rx = parseFloat(cols[0]) || 0
            var tx = parseFloat(cols[8]) || 0
            totalRx += rx
            totalTx += tx
            if (iface.indexOf("wl") === 0) {
                if (!detectedType) detectedType = "wifi"
            } else if (iface.indexOf("en") === 0 || iface.indexOf("eth") === 0) {
                detectedType = "ethernet"
            }
        }
        if (detectedType) rootPill.ifaceType = detectedType
        var now = Date.now()
        if (rootPill._prevRxBytes >= 0 && now > rootPill._prevTickMs) {
            var dt = (now - rootPill._prevTickMs) / 1000.0
            var dRx = Math.max(0, (totalRx - rootPill._prevRxBytes) / dt)
            var dTx = Math.max(0, (totalTx - rootPill._prevTxBytes) / dt)
            rootPill.downStr = rootPill.formatRate(dRx)
            rootPill.upStr = rootPill.formatRate(dTx)
            if (typeof bar !== "undefined" && bar) {
                bar.netDownStr = rootPill.downStr
                bar.netUpStr = rootPill.upStr
            }
        }
        rootPill._prevRxBytes = totalRx
        rootPill._prevTxBytes = totalTx
        rootPill._prevTickMs = now
    }

    FileView {
        id: netDevView
        path: "/proc/net/dev"
        onLoaded: rootPill.parseNetDev(text())
    }

    // Event-driven connectivity & interface type check (replaces 2s python nmcli fork)
    Process {
        id: ifaceStatusProc
        command: ["sh", "-c", "ip -o link show up 2>/dev/null | awk -F': ' '$2 != \"lo\" {print $2}' | head -n 5"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var ifaces = (text || "").trim()
                rootPill.isConnected = ifaces.length > 0
                if (ifaces.indexOf("en") !== -1 || ifaces.indexOf("eth") !== -1) {
                    rootPill.ifaceType = "ethernet"
                } else if (ifaces.indexOf("wl") !== -1) {
                    rootPill.ifaceType = "wifi"
                }
            }
        }
    }

    Process {
        id: nmMonitorProc
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line && line.trim().length > 0 && !ifaceStatusProc.running) {
                    ifaceStatusProc.running = true
                }
            }
        }
    }

    // Heavy per-process ss + /proc parser ONLY runs while the network popup is actually open
    Process {
        id: netProc
        command: ["python3", Quickshell.env("HOME") + "/.hyprconf/hypr/scripts/py/island-process-net.py"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0) {
                    try {
                        var d = JSON.parse(text.trim())
                        if (typeof bar !== "undefined" && bar) {
                            bar.netProcesses = d.processes || []
                        }
                    } catch(e) {}
                }
            }
        }
    }

    onNetPopupOpenChanged: {
        if (netPopupOpen && !netProc.running) netProc.running = true
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            netDevView.reload()
            if (rootPill.netPopupOpen && !netProc.running) netProc.running = true
        }
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
