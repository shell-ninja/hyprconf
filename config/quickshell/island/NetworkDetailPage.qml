import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root

    implicitWidth: 444
    implicitHeight: 496

    property bool active: false
    signal backClicked()
    signal pageDotClicked(int pageIndex)

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : "/home/shell-ninja"
    }

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string arrowLeftSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>')
    readonly property string downSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#06b6d4" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="7 13 12 18 17 13"/><line x1="12" y1="6" x2="12" y2="18"/></svg>')
    readonly property string upSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="17 11 12 6 7 11"/><line x1="12" y1="18" x2="12" y2="6"/></svg>')
    readonly property string netSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>')
    
    // Process category icons
    readonly property string browserSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#38bdf8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="4"/><line x1="4.93" y1="4.93" x2="9.17" y2="9.17"/><line x1="14.83" y1="14.83" x2="19.07" y2="19.07"/><line x1="14.83" y1="9.17" x2="19.07" y2="4.93"/><line x1="4.93" y1="19.07" x2="9.17" y2="14.83"/></svg>')
    readonly property string chatSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#a855f7" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>')
    readonly property string codeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#10b981" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>')
    readonly property string mediaSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></svg>')
    readonly property string downloadSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>')
    readonly property string systemSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="4" width="16" height="16" rx="2"/><rect x="9" y="9" width="6" height="6"/><line x1="9" y1="1" x2="9" y2="4"/><line x1="15" y1="1" x2="15" y2="4"/><line x1="9" y1="20" x2="9" y2="23"/><line x1="15" y1="20" x2="15" y2="23"/><line x1="20" y1="9" x2="23" y2="9"/><line x1="20" y1="14" x2="23" y2="14"/><line x1="1" y1="9" x2="4" y2="9"/><line x1="1" y1="14" x2="4" y2="14"/></svg>')

    function getIconForType(iconType) {
        if (iconType === "browser") return root.browserSvg
        if (iconType === "chat") return root.chatSvg
        if (iconType === "code") return root.codeSvg
        if (iconType === "media") return root.mediaSvg
        if (iconType === "download") return root.downloadSvg
        if (iconType === "system") return root.systemSvg
        return root.netSvg
    }

    // ── STATE ────────────────────────────────────────────────────────────────
    property string totalDownStr: "0 B/s"
    property string totalUpStr: "0 B/s"
    property int totalDownBps: 0
    property int totalUpBps: 0
    property int activeProcCount: 0
    property int totalProcCount: 0
    property var processList: []

    // ── PROCESS MONITOR RUNNER ───────────────────────────────────────────────
    Process {
        id: procNetProcess
        command: ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/island-process-net.py"]
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var parsed = JSON.parse(text.trim())
                    if (parsed.total_down_str !== undefined) root.totalDownStr = parsed.total_down_str
                    if (parsed.total_up_str !== undefined) root.totalUpStr = parsed.total_up_str
                    if (parsed.total_down_bps !== undefined) root.totalDownBps = parsed.total_down_bps
                    if (parsed.total_up_bps !== undefined) root.totalUpBps = parsed.total_up_bps
                    if (parsed.active_proc_count !== undefined) root.activeProcCount = parsed.active_proc_count
                    if (parsed.total_proc_count !== undefined) root.totalProcCount = parsed.total_proc_count
                    if (parsed.processes && Array.isArray(parsed.processes)) {
                        root.processList = parsed.processes
                    }
                } catch(e) {}
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 1000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: {
            if (!procNetProcess.running) {
                procNetProcess.running = true
            }
        }
    }

    onActiveChanged: {
        if (root.active && !procNetProcess.running) {
            procNetProcess.running = true
        }
    }

    // ── MAIN CONTENT ─────────────────────────────────────────────────────────
    Column {
        anchors.fill: parent
        spacing: 9

        // ── 1. HEADER ROW ────────────────────────────────────────────────────
        RowLayout {
            width: parent.width
            height: 32
            spacing: 10

            // Left: Back button to return to System Status (Page 2)
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: backMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.16) : Theme.alpha(Theme.surface, 0.65)
                border.width: 1
                border.color: backMouse.containsMouse ? Theme.alpha(Theme.accent, 0.45) : Theme.alpha(Theme.foreground, 0.12)
                scale: backMouse.pressed ? 0.94 : (backMouse.containsMouse ? 1.05 : 1.0)
                Behavior on scale { NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 120 } }

                Image {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    source: root.arrowLeftSvg
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backClicked()
                }
            }

            // Title & Pulsing Live Indicator
            Row {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 8

                Text {
                    text: "PROCESS NETWORK TRAFFIC"
                    font.family: "Outfit"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    font.letterSpacing: 1.1
                    color: Theme.foreground
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: 7
                    height: 7
                    radius: 3.5
                    color: "#06b6d4"
                    anchors.verticalCenter: parent.verticalCenter

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: root.active
                        NumberAnimation { to: 0.3; duration: 800; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                    }
                }
            }

            // Right: Active Apps Count Badge
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                height: 26
                width: appsCountTxt.width + 16
                radius: 13
                color: Theme.alpha("#06b6d4", 0.18)
                border.width: 1
                border.color: Theme.alpha("#06b6d4", 0.45)

                Text {
                    id: appsCountTxt
                    anchors.centerIn: parent
                    text: root.totalProcCount + " Sockets"
                    font.family: "Outfit"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: "#06b6d4"
                }
            }
        }

        // ── 2. LIVE THROUGHPUT HERO CARD ─────────────────────────────────────
        Rectangle {
            width: parent.width
            height: 52
            radius: 14
            color: Theme.alpha(Theme.surface, 0.55)
            border.width: 1
            border.color: Theme.alpha(Theme.foreground, 0.12)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14

                // Total Download
                Row {
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: Theme.alpha("#06b6d4", 0.16)
                        Image { anchors.centerIn: parent; width: 14; height: 14; source: root.downSvg }
                    }
                    Column {
                        spacing: 1
                        Text {
                            text: "Total Download"
                            font.family: "Outfit"
                            font.pixelSize: 10
                            color: Theme.muted
                        }
                        Text {
                            text: root.totalDownStr
                            font.family: "Outfit"
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            color: "#06b6d4"
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Divider line
                Rectangle {
                    width: 1
                    height: 28
                    color: Theme.alpha(Theme.foreground, 0.10)
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                // Total Upload
                Row {
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: Theme.alpha("#f59e0b", 0.16)
                        Image { anchors.centerIn: parent; width: 14; height: 14; source: root.upSvg }
                    }
                    Column {
                        spacing: 1
                        Text {
                            text: "Total Upload"
                            font.family: "Outfit"
                            font.pixelSize: 10
                            color: Theme.muted
                        }
                        Text {
                            text: root.totalUpStr
                            font.family: "Outfit"
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            color: "#f59e0b"
                        }
                    }
                }
            }
        }

        // ── 3. LIST OF PROGRAMS / PROCESSES ──────────────────────────────────
        Rectangle {
            width: parent.width
            height: 334
            radius: 16
            color: Theme.alpha(Theme.surface, 0.40)
            border.width: 1
            border.color: Theme.alpha(Theme.foreground, 0.10)
            clip: true

            // Empty state placeholder if no processes found
            Item {
                anchors.fill: parent
                visible: root.processList.length === 0

                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 32
                        height: 32
                        source: root.netSvg
                        opacity: 0.45
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Scanning socket connections..."
                        font.family: "Outfit"
                        font.pixelSize: 12
                        color: Theme.muted
                    }
                }
            }

            // Scrollable List of Applications
            Flickable {
                anchors.fill: parent
                anchors.margins: 8
                contentWidth: width
                contentHeight: processColumn.height
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                Column {
                    id: processColumn
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: root.processList

                        Rectangle {
                            width: processColumn.width
                            height: 48
                            radius: 12
                            readonly property bool isProcActive: modelData.active === true
                            color: itemMouse.containsMouse 
                                ? Theme.alpha(Theme.foreground, 0.12)
                                : (isProcActive ? Theme.alpha(Theme.surface, 0.70) : Theme.alpha(Theme.background, 0.50))
                            border.width: 1
                            border.color: itemMouse.containsMouse 
                                ? Theme.alpha(Theme.accent, 0.45) 
                                : (isProcActive ? Theme.alpha("#06b6d4", 0.28) : Theme.alpha(Theme.foreground, 0.08))

                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 10

                                // App Icon Badge
                                Rectangle {
                                    width: 30
                                    height: 30
                                    radius: 8
                                    color: itemMouse.containsMouse ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.85)
                                    border.width: 1
                                    border.color: Theme.alpha(Theme.foreground, 0.10)

                                    Image {
                                        anchors.centerIn: parent
                                        width: 16
                                        height: 16
                                        source: root.getIconForType(modelData.icon)
                                    }
                                }

                                // Process Info (Name & PID)
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Row {
                                        spacing: 6
                                        Text {
                                            text: modelData.name
                                            font.family: "Outfit"
                                            font.pixelSize: 12
                                            font.weight: Font.Bold
                                            color: Theme.foreground
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                        }

                                        // Active traffic pulsing dot
                                        Rectangle {
                                            width: 6
                                            height: 6
                                            radius: 3
                                            color: Theme.accent
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: modelData.active
                                        }
                                    }

                                    Text {
                                        text: "PID " + modelData.pid + " • " + modelData.raw_name + (modelData.ext_conns > 0 ? (" • " + modelData.ext_conns + " connections") : "")
                                        font.family: "Outfit"
                                        font.pixelSize: 9
                                        color: Theme.muted
                                        elide: Text.ElideRight
                                    }
                                }

                                // Right: Bandwidth Speeds
                                Column {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                                    // Download Speed
                                    Row {
                                        anchors.right: parent.right
                                        spacing: 4
                                        Image { width: 11; height: 11; source: root.downSvg; anchors.verticalCenter: parent.verticalCenter }
                                        Text {
                                            text: modelData.down_str
                                            font.family: "Outfit"
                                            font.pixelSize: 11
                                            font.weight: Font.Bold
                                            color: (modelData.down_bps > 0) ? "#06b6d4" : Theme.muted
                                        }
                                    }

                                    // Upload Speed
                                    Row {
                                        anchors.right: parent.right
                                        spacing: 4
                                        Image { width: 11; height: 11; source: root.upSvg; anchors.verticalCenter: parent.verticalCenter }
                                        Text {
                                            text: modelData.up_str
                                            font.family: "Outfit"
                                            font.pixelSize: 10
                                            font.weight: Font.Medium
                                            color: (modelData.up_bps > 0) ? "#f59e0b" : Theme.muted
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                    }
                }
            }
        }

        // ── 4. PAGINATION DOTS PILL ──────────────────────────────────────────
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            // Dot 1: Page 1 (Weather)
            Rectangle {
                width: 6
                height: 5
                radius: 2.5
                color: dot1Mouse.containsMouse ? "#38bdf8" : Theme.alpha(Theme.foreground, 0.25)
                Behavior on color { ColorAnimation { duration: 150 } }

                MouseArea {
                    id: dot1Mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pageDotClicked(0)
                }
            }

            // Dot 2: Page 2 (Control Center)
            Rectangle {
                width: 6
                height: 5
                radius: 2.5
                color: dot2Mouse.containsMouse ? Theme.foreground : Theme.alpha(Theme.foreground, 0.35)
                Behavior on color { ColorAnimation { duration: 150 } }

                MouseArea {
                    id: dot2Mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pageDotClicked(1)
                }
            }

            // Dot 3: Page 3 (System Info / App Speeds) - Active
            Rectangle {
                width: 18
                height: 5
                radius: 2.5
                color: "#06b6d4"
                Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }
        }
    }
}
