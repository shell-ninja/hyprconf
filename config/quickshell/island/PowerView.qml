import QtQuick
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root

    implicitWidth: 444
    implicitHeight: 456

    property bool active: false
    signal backClicked()

    Shortcut {
        sequence: "Escape"
        enabled: root.active
        onActivated: root.backClicked()
    }

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string backSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>')
    readonly property string lockSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.primary + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>')
    readonly property string logoutSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.secondary + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>')
    readonly property string rebootSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="23 4 23 10 17 10"/><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/></svg>')
    readonly property string shutdownSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.error + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18.36 6.64a9 9 0 1 1-12.73 0"/><line x1="12" y1="2" x2="12" y2="12"/></svg>')

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : "/home/shell-ninja"
    }

    Process { id: powerProc }

    function executePowerAction(cmd) {
        powerProc.running = false
        powerProc.command = ["bash", "-c", cmd]
        powerProc.running = true
    }

    Column {
        anchors.fill: parent
        spacing: 16

        // ── TOP HEADER / NAVIGATION BAR ──────────────────────────────────────
        Item {
            width: parent.width
            height: 34

            // Back button pill
            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                height: 32
                width: backRow.width + 18
                radius: 16
                color: backMouse.containsMouse ? Theme.alpha(Theme.surface, 0.95) : Theme.alpha(Theme.surface, 0.65)
                border.color: backMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.25) : Theme.alpha(Theme.foreground, 0.10)
                border.width: 1

                Row {
                    id: backRow
                    anchors.centerIn: parent
                    spacing: 6
                    Image { width: 14; height: 14; source: root.backSvg; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: "Back"
                        font.family: "Outfit"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: Theme.foreground
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backClicked()
                }
            }

            // Center Title
            Text {
                anchors.centerIn: parent
                text: "Power Menu"
                font.family: "Outfit"
                font.pixelSize: 15
                font.weight: Font.Bold
                color: Theme.foreground
            }

            // User session tag
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 24
                width: userRow.width + 14
                radius: 12
                color: Theme.alpha(Theme.surface, 0.5)
                border.color: Theme.alpha(Theme.foreground, 0.08)
                border.width: 1

                Row {
                    id: userRow
                    anchors.centerIn: parent
                    spacing: 5
                    Rectangle { width: 5; height: 5; radius: 2.5; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: "shell-ninja"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Theme.alpha(Theme.foreground, 0.70)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        // ── 2x2 POWER ACTIONS GRID ───────────────────────────────────────────
        Grid {
            width: parent.width
            height: 324
            columns: 2
            spacing: 14

            // 1. LOCK
            Rectangle {
                id: lockCard
                width: 215
                height: 155
                radius: 18
                color: lockMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.65)
                border.color: lockMouse.containsMouse ? Theme.primary : Theme.alpha(Theme.foreground, 0.10)
                border.width: lockMouse.containsMouse ? 1.5 : 1
                scale: lockMouse.pressed ? 0.97 : (lockMouse.containsMouse ? 1.02 : 1.0)

                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Column {
                    anchors.centerIn: parent
                    spacing: 10

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 48
                        height: 48
                        radius: 24
                        color: Theme.alpha(Theme.primary, 0.15)
                        border.color: Theme.alpha(Theme.primary, 0.35)
                        border.width: 1

                        Image {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            source: root.lockSvg
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Lock"
                        font.family: "Outfit"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: Theme.foreground
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Lock session"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Normal
                        color: Theme.alpha(Theme.foreground, 0.60)
                    }
                }

                MouseArea {
                    id: lockMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.backClicked()
                        root.executePowerAction(root.homeDir + "/.hyprconf/hypr/scripts/sh/qs-lock.sh")
                    }
                }
            }

            // 2. LOGOUT
            Rectangle {
                id: logoutCard
                width: 215
                height: 155
                radius: 18
                color: logoutMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.65)
                border.color: logoutMouse.containsMouse ? Theme.secondary : Theme.alpha(Theme.foreground, 0.10)
                border.width: logoutMouse.containsMouse ? 1.5 : 1
                scale: logoutMouse.pressed ? 0.97 : (logoutMouse.containsMouse ? 1.02 : 1.0)

                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Column {
                    anchors.centerIn: parent
                    spacing: 10

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 48
                        height: 48
                        radius: 24
                        color: Theme.alpha(Theme.secondary, 0.15)
                        border.color: Theme.alpha(Theme.secondary, 0.35)
                        border.width: 1

                        Image {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            source: root.logoutSvg
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Logout"
                        font.family: "Outfit"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: Theme.foreground
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Exit Hyprland"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Normal
                        color: Theme.alpha(Theme.foreground, 0.60)
                    }
                }

                MouseArea {
                    id: logoutMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.backClicked()
                        root.executePowerAction(root.homeDir + "/.hyprconf/hypr/scripts/sh/qs-logout.sh")
                    }
                }
            }

            // 3. REBOOT
            Rectangle {
                id: rebootCard
                width: 215
                height: 155
                radius: 18
                color: rebootMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.65)
                border.color: rebootMouse.containsMouse ? "#f59e0b" : Theme.alpha(Theme.foreground, 0.10)
                border.width: rebootMouse.containsMouse ? 1.5 : 1
                scale: rebootMouse.pressed ? 0.97 : (rebootMouse.containsMouse ? 1.02 : 1.0)

                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Column {
                    anchors.centerIn: parent
                    spacing: 10

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 48
                        height: 48
                        radius: 24
                        color: Theme.alpha("#f59e0b", 0.15)
                        border.color: Theme.alpha("#f59e0b", 0.35)
                        border.width: 1

                        Image {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            source: root.rebootSvg
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Reboot"
                        font.family: "Outfit"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: Theme.foreground
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Restart system"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Normal
                        color: Theme.alpha(Theme.foreground, 0.60)
                    }
                }

                MouseArea {
                    id: rebootMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.backClicked()
                        root.executePowerAction("systemctl reboot")
                    }
                }
            }

            // 4. SHUTDOWN
            Rectangle {
                id: shutdownCard
                width: 215
                height: 155
                radius: 18
                color: shutdownMouse.containsMouse ? Theme.alpha(Theme.error, 0.18) : Theme.alpha(Theme.surface, 0.65)
                border.color: shutdownMouse.containsMouse ? Theme.error : Theme.alpha(Theme.foreground, 0.10)
                border.width: shutdownMouse.containsMouse ? 1.5 : 1
                scale: shutdownMouse.pressed ? 0.97 : (shutdownMouse.containsMouse ? 1.02 : 1.0)

                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Column {
                    anchors.centerIn: parent
                    spacing: 10

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 48
                        height: 48
                        radius: 24
                        color: Theme.alpha(Theme.error, 0.15)
                        border.color: Theme.alpha(Theme.error, 0.40)
                        border.width: 1

                        Image {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            source: root.shutdownSvg
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Shutdown"
                        font.family: "Outfit"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: Theme.foreground
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Power off completely"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Normal
                        color: Theme.alpha(Theme.foreground, 0.60)
                    }
                }

                MouseArea {
                    id: shutdownMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.backClicked()
                        root.executePowerAction("systemctl poweroff")
                    }
                }
            }
        }

        // ── BOTTOM CANCEL BUTTON ─────────────────────────────────────────────
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 180
            height: 32
            radius: 16
            color: cancelMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.50)
            border.color: cancelMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.20) : Theme.alpha(Theme.foreground, 0.08)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "Cancel"
                font.family: "Outfit"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Theme.alpha(Theme.foreground, 0.75)
            }

            MouseArea {
                id: cancelMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.backClicked()
            }
        }
    }
}
