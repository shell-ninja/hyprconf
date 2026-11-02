import QtQuick
import QtQuick.Layouts
import ".."

Pill {
    id: rootPill
    clickable: true
    hPad: 8
    spacing: 7

    readonly property var settings: (typeof bar !== "undefined" && bar && bar.widgetSettings && bar.widgetSettings.system_info) ? bar.widgetSettings.system_info : ({})
    readonly property bool showRam: settings.show_ram !== false
    readonly property bool showCpu: settings.show_cpu !== false
    readonly property bool showDisk: !!settings.show_disk
    readonly property bool showIcon: settings.show_icon !== false

    readonly property real cpu: (typeof bar !== "undefined" && bar) ? bar.cpuUsage : 0
    readonly property real ramUsed: (typeof bar !== "undefined" && bar && bar.memUsedGiB) ? bar.memUsedGiB : 0
    readonly property real ramTotal: (typeof bar !== "undefined" && bar && bar.memTotalGiB) ? bar.memTotalGiB : 0
    readonly property real diskUsed: (typeof bar !== "undefined" && bar && bar.diskUsedGiB) ? bar.diskUsedGiB : 0
    readonly property real diskTotal: (typeof bar !== "undefined" && bar && bar.diskTotalGiB) ? bar.diskTotalGiB : 0
    readonly property bool isHeavyLoad: (cpu > 85 || (ramTotal > 0 && (ramUsed / ramTotal) > 0.88))

    SvgIcon {
        visible: rootPill.showIcon
        name: "gauge"
        size: 14
        color: rootPill.isHeavyLoad ? Theme.error : (rootPill.hovered ? Theme.accent : Theme.foreground)
        Behavior on color { ColorAnimation { duration: 140 } }
    }

    RowLayout {
        spacing: 6
        Layout.alignment: Qt.AlignVCenter

        // RAM
        RowLayout {
            visible: rootPill.showRam
            spacing: 3
            Layout.alignment: Qt.AlignVCenter
            Text {
                text: "RAM"
                font.family: "Outfit"
                font.pixelSize: 10
                font.weight: Font.Bold
                color: Theme.alpha(Theme.foreground, 0.55)
            }
            Text {
                text: rootPill.ramUsed > 0 ? (rootPill.ramUsed.toFixed(1) + "G") : "5.1G"
                font.family: "JetBrainsMono Nerd Font, monospace"
                font.pixelSize: 11
                font.weight: Font.Medium
                color: rootPill.isHeavyLoad ? Theme.error : (rootPill.hovered ? Theme.accent : Theme.foreground)
                Behavior on color { ColorAnimation { duration: 140 } }
            }
        }

        // Hairline divider before CPU
        Rectangle {
            visible: rootPill.showRam && rootPill.showCpu
            width: 1
            height: 9
            color: Theme.alpha(Theme.foreground, 0.15)
            Layout.alignment: Qt.AlignVCenter
        }

        // CPU
        RowLayout {
            visible: rootPill.showCpu
            spacing: 3
            Layout.alignment: Qt.AlignVCenter
            Text {
                text: "CPU"
                font.family: "Outfit"
                font.pixelSize: 10
                font.weight: Font.Bold
                color: Theme.alpha(Theme.foreground, 0.55)
            }
            Text {
                text: Math.round(rootPill.cpu) + "%"
                font.family: "JetBrainsMono Nerd Font, monospace"
                font.pixelSize: 11
                font.weight: Font.Medium
                color: rootPill.isHeavyLoad ? Theme.error : (rootPill.hovered ? Theme.accent : Theme.foreground)
                Behavior on color { ColorAnimation { duration: 140 } }
            }
        }

        // Hairline divider before Disk
        Rectangle {
            visible: (rootPill.showRam || rootPill.showCpu) && rootPill.showDisk
            width: 1
            height: 9
            color: Theme.alpha(Theme.foreground, 0.15)
            Layout.alignment: Qt.AlignVCenter
        }

        // DISK
        RowLayout {
            visible: rootPill.showDisk
            spacing: 3
            Layout.alignment: Qt.AlignVCenter
            Text {
                text: "DISK"
                font.family: "Outfit"
                font.pixelSize: 10
                font.weight: Font.Bold
                color: Theme.alpha(Theme.foreground, 0.55)
            }
            Text {
                text: rootPill.diskUsed > 0 ? (rootPill.diskUsed.toFixed(0) + "G") : "48G"
                font.family: "JetBrainsMono Nerd Font, monospace"
                font.pixelSize: 11
                font.weight: Font.Medium
                color: rootPill.hovered ? Theme.accent : Theme.foreground
                Behavior on color { ColorAnimation { duration: 140 } }
            }
        }
    }

    Component.onCompleted: {
        if (typeof bar !== "undefined" && bar) bar.monitorTrigger = rootPill
    }
    Component.onDestruction: {
        if (typeof bar !== "undefined" && bar && bar.monitorTrigger === rootPill) bar.monitorTrigger = null
    }

    onClicked: {
        if (typeof bar !== "undefined" && bar) bar.toggleMonitor()
    }
}
