import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root

    property var widgetConfig: ({
        show_cpu: true,
        show_ram: true,
        show_disk: true,
        show_temp: true,
        glass_opacity: 0.65
    })
    property bool editMode: false

    implicitWidth: 280
    implicitHeight: 230
    width: implicitWidth
    height: implicitHeight

    // System Metrics
    property int cpuPercent: 12
    property string cpuTemp: "48°C"
    property real ramUsedGb: 4.8
    property real ramTotalGb: 15.5
    property int ramPercent: 31
    property real diskFreeGb: 92.4
    property real diskTotalGb: 256.0
    property int diskPercent: 64
    property string netDownStr: "1.2 MB/s"
    property string netUpStr: "42 KB/s"

    // Zero-fork native System Stats using /proc + /sys FileViews (60s df -kP / for disk)
    property real _prevIdle: -1
    property real _prevTotal: -1
    property string _thermalPath: "/sys/class/thermal/thermal_zone0/temp"
    readonly property bool _statsActive: !root.editMode && (root.widgetConfig ? root.widgetConfig.enabled !== false : true) && root.visible

    function _parseProcStat(txt) {
        if (!txt) return
        var line = txt.split("\n")[0] || ""
        var parts = line.trim().split(/\s+/)
        if (parts.length < 8) return
        var total = 0
        for (var i = 1; i <= 7; i++) total += parseFloat(parts[i]) || 0
        var idle = (parseFloat(parts[4]) || 0) + (parseFloat(parts[5]) || 0)
        if (root._prevTotal > 0 && total > root._prevTotal) {
            var dTotal = total - root._prevTotal
            var dIdle = idle - root._prevIdle
            root.cpuPercent = Math.max(0, Math.min(100, Math.round(100 * (1.0 - dIdle / dTotal))))
        }
        root._prevIdle = idle
        root._prevTotal = total
    }

    function _parseMeminfo(txt) {
        if (!txt) return
        var totKb = 0
        var availKb = 0
        var lines = txt.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var l = lines[i]
            if (l.indexOf("MemTotal:") === 0) totKb = parseInt(l.replace(/\D+/g, ""), 10) || 0
            else if (l.indexOf("MemAvailable:") === 0) availKb = parseInt(l.replace(/\D+/g, ""), 10) || 0
            if (totKb > 0 && availKb > 0) break
        }
        if (totKb > 0) {
            var totGb = totKb / (1024.0 * 1024.0)
            var usedGb = Math.max(0.0, (totKb - availKb) / (1024.0 * 1024.0))
            root.ramTotalGb = Math.round(totGb * 10) / 10
            root.ramUsedGb = Math.round(usedGb * 10) / 10
            root.ramPercent = Math.max(0, Math.min(100, Math.round(100.0 * usedGb / totGb)))
        }
    }

    FileView {
        id: statFile
        path: "/proc/stat"
        onLoaded: root._parseProcStat(text())
    }

    FileView {
        id: memFile
        path: "/proc/meminfo"
        onLoaded: root._parseMeminfo(text())
    }

    FileView {
        id: tempFile
        path: root._thermalPath
        onLoaded: {
            var raw = parseInt((text() || "").trim(), 10)
            if (!isNaN(raw)) {
                var c = Math.floor(raw / 1000)
                if (c >= 15 && c <= 115) root.cpuTemp = c + "°C"
            }
        }
    }

    Process {
        id: tempDiscoverProc
        command: ["sh", "-c", "for tp in /sys/class/thermal/thermal_zone*/temp /sys/class/hwmon/hwmon*/temp*_input; do [ -r \"$tp\" ] && read -r v < \"$tp\" && [ \"$v\" -ge 20000 ] 2>/dev/null && [ \"$v\" -le 115000 ] 2>/dev/null && { echo \"$tp\"; break; }; done"]
        running: root._statsActive
        stdout: StdioCollector {
            onTextChanged: {
                var p = (text || "").trim()
                if (p.length > 0) {
                    root._thermalPath = p
                    tempFile.reload()
                }
            }
        }
    }

    Process {
        id: diskProc
        command: ["df", "-kP", "/"]
        running: root._statsActive
        stdout: StdioCollector {
            onTextChanged: {
                var lines = (text || "").trim().split("\n")
                if (lines.length < 2) return
                var parts = lines[1].trim().split(/\s+/)
                if (parts.length < 5) return
                var totKb = parseFloat(parts[1]) || 0
                var usedKb = parseFloat(parts[2]) || 0
                var availKb = parseFloat(parts[3]) || 0
                if (totKb > 0) {
                    root.diskTotalGb = Math.round((totKb / (1024 * 1024)) * 10) / 10
                    root.diskFreeGb = Math.round((availKb / (1024 * 1024)) * 10) / 10
                    root.diskPercent = Math.max(0, Math.min(100, Math.round(100 * usedKb / totKb)))
                }
            }
        }
    }

    Timer {
        interval: 4000
        repeat: true
        running: root._statsActive
        onTriggered: {
            statFile.reload()
            memFile.reload()
            tempFile.reload()
        }
    }

    Timer {
        interval: 60000
        repeat: true
        running: root._statsActive
        onTriggered: {
            if (!diskProc.running) diskProc.running = true
        }
    }

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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header: Title + Temperature Badge
        RowLayout {
            Layout.fillWidth: true

            Row {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    width: 7
                    height: 7
                    radius: 3.5
                    color: Theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "SYSTEM MONITOR"
                    color: Theme.alpha(Theme.foreground, 0.85)
                    font.family: "Outfit"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.letterSpacing: 0.8
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item { Layout.fillWidth: true }

            // Temp Pill
            Rectangle {
                visible: root.widgetConfig ? (root.widgetConfig.show_temp !== false) : true
                width: tempText.implicitWidth + 12
                height: 20
                radius: 10
                color: Theme.alpha(Theme.surface, 0.80)
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.35)

                Text {
                    id: tempText
                    anchors.centerIn: parent
                    text: root.cpuTemp
                    color: Theme.accent
                    font.family: "Outfit"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }
            }
        }

        // Metric Rows
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            // 1. CPU Row
            Column {
                Layout.fillWidth: true
                spacing: 4
                visible: root.widgetConfig ? (root.widgetConfig.show_cpu !== false) : true

                RowLayout {
                    width: parent.width
                    Text {
                        text: "CPU"
                        color: Theme.alpha(Theme.foreground, 0.70)
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.cpuPercent + "%"
                        color: Theme.accent
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Theme.alpha(Theme.surface, 0.70)

                    Rectangle {
                        height: parent.height
                        width: Math.max(4, Math.round(parent.width * (root.cpuPercent / 100.0)))
                        radius: 3
                        color: root.cpuPercent > 80 ? "#ef4444" : Theme.accent
                        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    }
                }
            }

            // 2. RAM Row
            Column {
                Layout.fillWidth: true
                spacing: 4
                visible: root.widgetConfig ? (root.widgetConfig.show_ram !== false) : true

                RowLayout {
                    width: parent.width
                    Text {
                        text: "RAM"
                        color: Theme.alpha(Theme.foreground, 0.70)
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.ramUsedGb + " / " + root.ramTotalGb + " GB (" + root.ramPercent + "%)"
                        color: Theme.foreground
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Theme.alpha(Theme.surface, 0.70)

                    Rectangle {
                        height: parent.height
                        width: Math.max(4, Math.round(parent.width * (root.ramPercent / 100.0)))
                        radius: 3
                        color: Theme.secondary
                        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    }
                }
            }

            // 3. Disk Free Row
            Column {
                Layout.fillWidth: true
                spacing: 4
                visible: root.widgetConfig ? (root.widgetConfig.show_disk !== false) : true

                RowLayout {
                    width: parent.width
                    Text {
                        text: "STORAGE"
                        color: Theme.alpha(Theme.foreground, 0.70)
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.diskFreeGb + " GB free"
                        color: Theme.alpha(Theme.foreground, 0.85)
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Theme.alpha(Theme.surface, 0.70)

                    Rectangle {
                        height: parent.height
                        width: Math.max(4, Math.round(parent.width * (root.diskPercent / 100.0)))
                        radius: 3
                        color: Theme.primary
                        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }
}
