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

    // System Stats Poller
    Process {
        id: statsProc
        command: ["python3", "-c", "import os, sys, json, shutil\n" +
            "def get_cpu():\n" +
            "    try:\n" +
            "        with open('/proc/stat') as f: line = f.readline()\n" +
            "        fields = [float(x) for x in line.split()[1:8]]\n" +
            "        idle, total = fields[3] + fields[4], sum(fields)\n" +
            "        return idle, total\n" +
            "    except: return 0, 1\n" +
            "i1, t1 = get_cpu()\n" +
            "import time; time.sleep(0.15)\n" +
            "i2, t2 = get_cpu()\n" +
            "cpu_pct = int(100 * (1.0 - (i2 - i1) / max(0.001, t2 - t1)))\n" +
            "# RAM\n" +
            "mem = {}\n" +
            "try:\n" +
            "    for l in open('/proc/meminfo'):\n" +
            "        p = l.split(':')\n" +
            "        if len(p) == 2: mem[p[0].strip()] = int(p[1].strip().split()[0])\n" +
            "    tot = mem.get('MemTotal', 1) / (1024*1024)\n" +
            "    avail = mem.get('MemAvailable', 0) / (1024*1024)\n" +
            "    used = tot - avail\n" +
            "    ram_pct = int(100 * used / tot)\n" +
            "except: tot, used, ram_pct = 16.0, 4.0, 25\n" +
            "# Disk free on /\n" +
            "try:\n" +
            "    usage = shutil.disk_usage('/')\n" +
            "    disk_free = usage.free / (1024**3)\n" +
            "    disk_tot = usage.total / (1024**3)\n" +
            "    disk_pct = int(100 * (usage.used / usage.total))\n" +
            "except: disk_free, disk_tot, disk_pct = 80, 256, 30\n" +
            "# Temp\n" +
            "temp_str = '48°C'\n" +
            "try:\n" +
            "    for d in os.listdir('/sys/class/thermal'):\n" +
            "        tp = os.path.join('/sys/class/thermal', d, 'temp')\n" +
            "        if os.path.exists(tp):\n" +
            "            t = int(open(tp).read().strip()) // 1000\n" +
            "            if 20 <= t <= 110: temp_str = f'{t}°C'; break\n" +
            "except: pass\n" +
            "print(json.dumps({'cpu': cpu_pct, 'ram_used': round(used, 1), 'ram_tot': round(tot, 1), 'ram_pct': ram_pct, 'disk_free': round(disk_free, 1), 'disk_tot': round(disk_tot, 1), 'disk_pct': disk_pct, 'temp': temp_str}))"
        ]
        running: !root.editMode && (root.widgetConfig ? root.widgetConfig.enabled !== false : true) && root.visible
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var d = JSON.parse(text.trim())
                    if (d.cpu !== undefined) root.cpuPercent = d.cpu
                    if (d.ram_used !== undefined) root.ramUsedGb = d.ram_used
                    if (d.ram_tot !== undefined) root.ramTotalGb = d.ram_tot
                    if (d.ram_pct !== undefined) root.ramPercent = d.ram_pct
                    if (d.disk_free !== undefined) root.diskFreeGb = d.disk_free
                    if (d.disk_tot !== undefined) root.diskTotalGb = d.disk_tot
                    if (d.disk_pct !== undefined) root.diskPercent = d.disk_pct
                    if (d.temp !== undefined) root.cpuTemp = d.temp
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 4000
        repeat: true
        running: !root.editMode && (root.widgetConfig ? root.widgetConfig.enabled !== false : true) && root.visible
        onTriggered: {
            if (!statsProc.running) statsProc.running = true
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
