import QtQuick
import Quickshell
import Quickshell.Io
import "."

Rectangle {
    id: root

    property bool isConnected: true
    property bool isEnabled: true
    property string networkName: "Wired connection 1"
    property string deviceType: "ethernet"

    signal toggleWifi()

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

    readonly property string wifiSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + (root.isEnabled ? Theme.accent : Theme.muted) + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M1.42 9a16 16 0 0 1 21.16 0"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1.2" fill="' + (root.isEnabled ? Theme.accent : Theme.muted) + '"/></svg>')
    readonly property string globeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + (root.isEnabled ? Theme.accent : Theme.muted) + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>')
    readonly property string chevronSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 18 15 12 9 6"/></svg>')

    Process {
        id: netReader
        command: ["bash", "-c", "nmcli -t -f TYPE,STATE,CONNECTION device | head -n 3"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text) return
                var lines = text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(":")
                    if (parts.length >= 3 && parts[1] === "connected") {
                        root.isConnected = true
                        root.networkName = parts[2]
                        root.deviceType = parts[0]
                        return
                    }
                }
            }
        }
    }

    Timer {
        interval: 6000
        running: true
        repeat: true
        onTriggered: {
            if (!netReader.running) netReader.running = true
        }
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
                source: (root.deviceType === "ethernet") ? root.globeSvg : root.wifiSvg
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
                text: root.deviceType === "ethernet" ? "Network" : "Wi-Fi"
                font.family: "Outfit"
                font.pixelSize: 14
                font.weight: Font.Bold
                color: Theme.foreground
            }

            Text {
                text: root.isEnabled ? root.networkName : "Disconnected"
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
                        root.toggleWifi()
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
