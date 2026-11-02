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

    readonly property var settings: (typeof bar !== "undefined" && bar && bar.widgetSettings && bar.widgetSettings.battery) ? bar.widgetSettings.battery : ({})
    readonly property bool showPercent: settings.show_percent !== false
    readonly property bool showOnDesktop: settings.show_on_desktop !== false

    property bool hasBattery: false
    property int batteryPct: -1
    property string batteryStatus: "Discharging"
    property bool isCharging: {
        var s = (batteryStatus || "").toLowerCase().trim()
        return s === "charging" || (s.indexOf("charging") !== -1 && s.indexOf("dis") === -1 && s.indexOf("not") === -1)
    }

    readonly property bool isCritical: !isCharging && batteryPct < 15 && batteryPct >= 0

    readonly property color stageColor: {
        if (!rootPill.hasBattery) return Theme.accent
        if (rootPill.isCharging) return "#10b981"
        if (rootPill.batteryPct >= 70) return "#10b981"
        if (rootPill.batteryPct >= 30) return "#06b6d4"
        if (rootPill.batteryPct >= 15) return "#f59e0b"
        return "#ef4444"
    }

    visible: rootPill.hasBattery || rootPill.showOnDesktop
    implicitWidth: visible ? (rowContent.implicitWidth + hPad * 2) : 0

    Process {
        id: batProc
        command: ["python3", Quickshell.env("HOME") + "/.hyprconf/hypr/scripts/py/island-battery.py"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0) {
                    try {
                        var d = JSON.parse(text.trim())
                        rootPill.hasBattery = Boolean(d.has_battery)
                        rootPill.batteryPct = (d.percent !== undefined) ? d.percent : -1
                        rootPill.batteryStatus = d.status || "Discharging"
                    } catch(e) {}
                }
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: if (!batProc.running) batProc.running = true
    }

    RowLayout {
        id: rowContent
        spacing: 6
        Layout.alignment: Qt.AlignVCenter

        // Vector Battery Icon
        Item {
            Layout.preferredWidth: rootPill.hasBattery ? 22 : 14
            Layout.preferredHeight: 14
            Layout.alignment: Qt.AlignVCenter

            // Desktop AC Power Plug / Bolt Icon
            SvgIcon {
                anchors.centerIn: parent
                size: 13
                name: "bolt"
                color: Theme.accent
                visible: !rootPill.hasBattery
            }

            // Battery Body
            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 19
                height: 12
                radius: 3
                color: "transparent"
                border.color: rootPill.stageColor
                border.width: 1.4
                visible: rootPill.hasBattery

                // Fill Bar (Discharging)
                Rectangle {
                    x: 2; y: 2
                    height: 8
                    radius: 1.5
                    color: rootPill.stageColor
                    visible: !rootPill.isCharging
                    width: Math.max(1.5, Math.min(15, (15.0 * Math.max(0, Math.min(100, rootPill.batteryPct))) / 100.0))

                    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                // Bolt Icon (Charging)
                SvgIcon {
                    anchors.centerIn: parent
                    size: 8
                    name: "zap"
                    color: rootPill.stageColor
                    visible: rootPill.isCharging
                }
            }

            // Battery Tip (Nub)
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 2.2
                height: 5
                radius: 0.8
                color: rootPill.stageColor
                visible: rootPill.hasBattery
            }
        }

        // Percentage / Status Text
        Text {
            visible: rootPill.hasBattery ? rootPill.showPercent : true
            text: rootPill.hasBattery ? ((rootPill.batteryPct >= 0 ? rootPill.batteryPct : 0) + "%") : "AC"
            color: rootPill.hovered ? Theme.accent : rootPill.stageColor
            font.family: "Outfit"
            font.pixelSize: 11
            font.weight: Font.Bold
            Behavior on color { ColorAnimation { duration: 140 } }
        }
    }

    onClicked: {
        if (typeof bar !== "undefined" && bar && bar.perfTrigger) {
            bar.togglePower()
        }
    }
}
