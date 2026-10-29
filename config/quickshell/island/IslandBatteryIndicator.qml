import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import "."

Item {
    id: root

    property bool hasBattery: false
    property int batteryPct: -1
    property string batteryStatus: "Discharging" // "Charging", "Discharging", "Full", "Not charging"
    property bool isCharging: {
        var s = (root.batteryStatus || "").toLowerCase().trim()
        return s === "charging" || (s.indexOf("charging") !== -1 && s.indexOf("dis") === -1 && s.indexOf("not") === -1)
    }
    readonly property bool isCritical: !root.isCharging && root.batteryPct < 15 && root.batteryPct >= 0
    property bool showPercent: true

    // User-specified Color Ranges:
    // 100 - 70%: Green
    // 69 - 30%: Blue / Cyan
    // 29 - 15%: Yellow
    // Below 15%: Red
    readonly property color stageColor: {
        if (root.isCharging) return "#10b981"        // Charging Emerald Green
        if (root.batteryPct >= 70) return "#10b981"  // 100 - 70%: Green
        if (root.batteryPct >= 30) return "#06b6d4"  // 69 - 30%: Blue / Cyan
        if (root.batteryPct >= 15) return "#f59e0b"  // 29 - 15%: Yellow
        return "#ef4444"                             // Below 15%: Red
    }

    signal clicked()

    visible: root.hasBattery && root.batteryPct >= 0
    implicitWidth: visible ? (batRow.implicitWidth + (batHover.hovered ? 6 : 0)) : 0
    implicitHeight: 22

    Behavior on implicitWidth {
        NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
    }
    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    function svgUrl(content) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(content)
    }

    // Charging Voltage Lightning Bolt SVG (ONLY used when isCharging is true!)
    readonly property string boltSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="' + root.stageColor + '"><polygon points="13 2 4 14 11 14 9 22 20 10 13 10 15 2"/></svg>')

    Rectangle {
        id: batBg
        anchors.fill: parent
        radius: height / 2
        color: batHover.hovered ? Theme.alpha(root.stageColor, 0.14) : "transparent"
        border.color: batHover.hovered ? Theme.alpha(root.stageColor, 0.35) : "transparent"
        border.width: 1

        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on border.color { ColorAnimation { duration: 160 } }
    }

    Row {
        id: batRow
        spacing: 5
        anchors.centerIn: parent

        // Vector Battery Gauge Container
        Item {
            width: 23
            height: 14
            anchors.verticalCenter: parent.verticalCenter

            // Charging Breathing Glow Ring (ONLY active while charging)
            Rectangle {
                id: chargeGlow
                anchors.centerIn: parent
                width: parent.width + 4
                height: parent.height + 4
                radius: height / 2
                color: "transparent"
                border.color: Theme.alpha(root.stageColor, 0.45)
                border.width: 1
                visible: root.isCharging

                SequentialAnimation on scale {
                    running: root.isCharging
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.95; to: 1.12; duration: 1000; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1.12; to: 0.95; duration: 1000; easing.type: Easing.InOutSine }
                }
                SequentialAnimation on opacity {
                    running: root.isCharging
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.30; to: 0.85; duration: 1000; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.85; to: 0.30; duration: 1000; easing.type: Easing.InOutSine }
                }
            }

            // Main Vector Battery Icon Body
            Item {
                id: batBody
                anchors.fill: parent

                // Critical Low Alert Warning Pulse (ONLY active when below 15% and discharging)
                SequentialAnimation on opacity {
                    running: root.isCritical
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.30; duration: 550; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 550; easing.type: Easing.InOutSine }
                }

                // 1. Battery Shell Frame
                Rectangle {
                    id: batShell
                    x: 0
                    width: 20
                    height: 12
                    radius: 3
                    color: "transparent"
                    border.color: root.stageColor
                    border.width: 1.4
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    // Proportional Inner Fill Bar (ONLY visible when discharging/idle — NO voltage icon!)
                    Rectangle {
                        id: batFill
                        x: 2
                        y: 2
                        height: 8
                        radius: 1.5
                        color: root.stageColor
                        visible: !root.isCharging
                        width: {
                            var pct = Math.max(0, Math.min(100, root.batteryPct))
                            // Maximum inner width is 16px (20px - 2*2px borders/margins)
                            return Math.max(1.5, Math.min(16, (16.0 * pct) / 100.0))
                        }

                        Behavior on width {
                            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
                        }
                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }
                    }

                    // 2. Centered Voltage Lightning Bolt (ONLY visible when CHARGING!)
                    Image {
                        id: boltIcon
                        anchors.centerIn: parent
                        width: 9
                        height: 9
                        source: root.boltSvg
                        sourceSize.width: 18
                        sourceSize.height: 18
                        visible: root.isCharging
                        smooth: true

                        SequentialAnimation on opacity {
                            running: root.isCharging
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.40; duration: 800; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                        }
                    }
                }

                // 3. Battery Terminal Positive Nub
                Rectangle {
                    id: batNub
                    x: 20.5
                    width: 2
                    height: 5
                    radius: 0.8
                    color: root.stageColor
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        // Percentage Text
        Text {
            id: pctText
            text: (root.batteryPct >= 0 ? root.batteryPct : 0) + "%"
            font.family: "Outfit"
            font.pixelSize: 11
            font.weight: Font.Bold
            color: root.stageColor
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showPercent

            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }

    HoverHandler {
        id: batHover
        cursorShape: Qt.PointingHandCursor
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
