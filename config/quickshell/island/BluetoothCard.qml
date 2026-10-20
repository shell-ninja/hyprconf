import QtQuick
import Quickshell
import Quickshell.Io
import "."

Rectangle {
    id: root

    property bool isEnabled: true
    property string statusText: "On"

    signal toggleBluetooth()

    implicitWidth: 270
    implicitHeight: 80
    radius: 18

    color: root.isEnabled ? Theme.alpha(Theme.surface, 0.70) : Theme.alpha(Theme.surface, 0.45)
    border.color: root.isEnabled ? Theme.alpha(Theme.foreground, 0.12) : Theme.alpha(Theme.foreground, 0.06)
    border.width: 1

    Behavior on color { ColorAnimation { duration: 180 } }
    Behavior on border.color { ColorAnimation { duration: 180 } }

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string btSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + (root.isEnabled ? Theme.accent : Theme.muted) + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6.5 6.5 17.5 17.5 12 23 12 1 17.5 6.5 6.5 17.5"/></svg>')
    readonly property string chevronSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 18 15 12 9 6"/></svg>')

    Process {
        id: btReader
        command: ["bash", "-c", "bluetoothctl show | grep -E 'Powered:' | awk '{print $2}'"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text) return
                var p = text.trim().toLowerCase()
                root.isEnabled = (p === "yes")
                root.statusText = root.isEnabled ? "On" : "Off"
            }
        }
    }

    Process {
        id: btToggleProc
        command: ["bash", "-c", "bluetoothctl power " + (root.isEnabled ? "on" : "off")]
    }

    Item {
        anchors.fill: parent
        anchors.margins: 14

        // Left circular icon badge
        Rectangle {
            id: iconBadge
            width: 38
            height: 38
            radius: 19
            color: root.isEnabled ? Theme.alpha(Theme.accent, 0.16) : Theme.alpha(Theme.foreground, 0.05)
            border.color: root.isEnabled ? Theme.alpha(Theme.accent, 0.3) : "transparent"
            border.width: 1
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            Image {
                anchors.centerIn: parent
                width: 18
                height: 18
                sourceSize: Qt.size(36, 36)
                source: root.btSvg
            }
        }

        // Center text info
        Column {
            anchors.left: iconBadge.right
            anchors.leftMargin: 12
            anchors.right: rightControls.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: "Bluetooth"
                font.family: "Outfit"
                font.pixelSize: 14
                font.weight: Font.Bold
                color: Theme.foreground
            }

            Text {
                text: root.statusText
                font.family: "Outfit"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Theme.alpha(Theme.foreground, 0.70)
                elide: Text.ElideRight
                width: parent.width
            }
        }

        // Right side: Capsule switch + chevron
        Row {
            id: rightControls
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Capsule toggle switch
            Rectangle {
                id: togglePill
                width: 40
                height: 24
                radius: 12
                color: root.isEnabled ? Theme.accent : Theme.alpha(Theme.muted, 0.4)
                border.color: Theme.alpha(Theme.foreground, 0.15)
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter

                Behavior on color { ColorAnimation { duration: 180 } }

                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    color: Theme.foreground
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.isEnabled ? (parent.width - width - 3) : 3

                    Behavior on x {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.isEnabled = !root.isEnabled
                        root.statusText = root.isEnabled ? "On" : "Off"
                        btToggleProc.command = ["bash", "-c", "bluetoothctl power " + (root.isEnabled ? "on" : "off")]
                        btToggleProc.running = true
                        root.toggleBluetooth()
                    }
                }
            }

            // Subtle chevron arrow
            Image {
                width: 12
                height: 12
                source: root.chevronSvg
                opacity: 0.35
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
