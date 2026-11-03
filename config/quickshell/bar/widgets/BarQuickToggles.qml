import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

Pill {
    id: rootPill
    hPad: 4
    spacing: 3
    clickable: false

    // Game Mode
    Rectangle {
        id: gameModeBtn
        implicitWidth: 26
        implicitHeight: 26
        radius: 13
        z: isHovered ? 1000 : 1
        readonly property bool isHovered: gameHover.hovered || gameMouse.containsMouse

        color: (typeof bar !== "undefined" && bar && bar.gameModeActive)
               ? Theme.accent
               : (isHovered ? Theme.alpha(Theme.accent, 0.18) : "transparent")
        scale: isHovered ? (gameMouse.pressed ? 0.90 : 1.12) : 1.0
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }

        SvgIcon {
            anchors.centerIn: parent
            name: "gamepad"
            size: 13
            color: (typeof bar !== "undefined" && bar && bar.gameModeActive)
                   ? Theme.background
                   : (gameModeBtn.isHovered ? Theme.accent : Theme.alpha(Theme.foreground, 0.75))
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        HoverHandler {
            id: gameHover
        }

        MouseArea {
            id: gameMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (typeof bar !== "undefined" && bar) bar.toggleGameMode()
        }

        // Obsidian Glass Hover Tooltip
        Rectangle {
            id: gameTooltip
            z: 9999
            visible: gameModeBtn.isHovered || opacity > 0.01
            opacity: gameModeBtn.isHovered ? 1.0 : 0.0
            scale: gameModeBtn.isHovered ? 1.0 : 0.90
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

            anchors.top: parent.bottom
            anchors.topMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            width: 250
            height: tooltipCol.implicitHeight + 20
            radius: 12
            color: Theme.alpha(Theme.surface, 0.96)
            border.width: 1
            border.color: (typeof bar !== "undefined" && bar && bar.gameModeActive)
                          ? Theme.alpha(Theme.accent, 0.45)
                          : Theme.alpha(Theme.accent, 0.25)

            // Inner subtle top glass rim
            Rectangle {
                anchors.top: parent.top
                anchors.topMargin: 1
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 24
                height: 1
                color: Theme.alpha(Theme.foreground, 0.12)
            }

            ColumnLayout {
                id: tooltipCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 10
                spacing: 6

                // Header: Icon + Title + Status Badge
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    SvgIcon {
                        name: "gamepad"
                        size: 14
                        color: (typeof bar !== "undefined" && bar && bar.gameModeActive) ? Theme.accent : Theme.foreground
                    }

                    Text {
                        text: "Game Mode"
                        font.family: "Outfit"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: Theme.foreground
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: badgeText.implicitWidth + 12
                        implicitHeight: 18
                        radius: 9
                        color: (typeof bar !== "undefined" && bar && bar.gameModeActive)
                               ? Theme.alpha(Theme.accent, 0.25)
                               : Theme.alpha(Theme.foreground, 0.10)
                        border.width: 1
                        border.color: (typeof bar !== "undefined" && bar && bar.gameModeActive)
                                      ? Theme.alpha(Theme.accent, 0.50)
                                      : Theme.alpha(Theme.foreground, 0.15)

                        Text {
                            id: badgeText
                            anchors.centerIn: parent
                            text: (typeof bar !== "undefined" && bar && bar.gameModeActive) ? "ACTIVE" : "OFF"
                            font.family: "Outfit"
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            color: (typeof bar !== "undefined" && bar && bar.gameModeActive) ? Theme.accent : Theme.alpha(Theme.foreground, 0.60)
                        }
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.alpha(Theme.accent, 0.15)
                }

                // Bullet 1: 0ms Latency
                RowLayout {
                    spacing: 6
                    Rectangle { width: 4; height: 4; radius: 2; color: Theme.accent }
                    Text {
                        text: "0ms tearing latency (direct scanout)"
                        font.family: "Outfit"
                        font.pixelSize: 10
                        color: Theme.alpha(Theme.foreground, 0.85)
                    }
                }

                // Bullet 2: Full Opacity
                RowLayout {
                    spacing: 6
                    Rectangle { width: 4; height: 4; radius: 2; color: Theme.accent }
                    Text {
                        text: "100% window opacity (no glass)"
                        font.family: "Outfit"
                        font.pixelSize: 10
                        color: Theme.alpha(Theme.foreground, 0.85)
                    }
                }

                // Bullet 3: Blur & animations off
                RowLayout {
                    spacing: 6
                    Rectangle { width: 4; height: 4; radius: 2; color: Theme.accent }
                    Text {
                        text: "Compositor blur & animations disabled"
                        font.family: "Outfit"
                        font.pixelSize: 10
                        color: Theme.alpha(Theme.foreground, 0.85)
                    }
                }

                // Bullet 4: Max Performance Profile
                RowLayout {
                    spacing: 6
                    Rectangle { width: 4; height: 4; radius: 2; color: Theme.accent }
                    Text {
                        text: "Max performance CPU profile"
                        font.family: "Outfit"
                        font.pixelSize: 10
                        color: Theme.alpha(Theme.foreground, 0.85)
                    }
                }
            }
        }
    }

    // Caffeine
    Rectangle {
        id: caffeineBtn
        implicitWidth: 26
        implicitHeight: 26
        radius: 13
        color: (typeof bar !== "undefined" && bar && bar.caffeine)
               ? Theme.accent
               : (caffeineMouse.containsMouse ? Theme.alpha(Theme.accent, 0.18) : "transparent")
        scale: caffeineMouse.containsMouse ? (caffeineMouse.pressed ? 0.90 : 1.12) : 1.0
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }

        SvgIcon {
            anchors.centerIn: parent
            name: "coffee"
            size: 13
            color: (typeof bar !== "undefined" && bar && bar.caffeine)
                   ? Theme.background
                   : (caffeineMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.75))
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        MouseArea {
            id: caffeineMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (typeof bar !== "undefined" && bar) bar.toggleCaffeine()
        }
    }

    // Night Light
    Rectangle {
        id: nightLightBtn
        implicitWidth: 26
        implicitHeight: 26
        radius: 13
        color: (typeof bar !== "undefined" && bar && bar.nightLight)
               ? Theme.accent
               : (nightLightMouse.containsMouse ? Theme.alpha(Theme.accent, 0.18) : "transparent")
        scale: nightLightMouse.containsMouse ? (nightLightMouse.pressed ? 0.90 : 1.12) : 1.0
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }

        SvgIcon {
            anchors.centerIn: parent
            name: "moonStar"
            size: 13
            color: (typeof bar !== "undefined" && bar && bar.nightLight)
                   ? Theme.background
                   : (nightLightMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.75))
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        MouseArea {
            id: nightLightMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (typeof bar !== "undefined" && bar) bar.toggleNightLight()
        }
    }

    // Clipboard
    Rectangle {
        id: clipBtn
        implicitWidth: clipRow.implicitWidth + 10
        implicitHeight: 26
        radius: 13
        color: clipMouse.containsMouse ? Theme.alpha(Theme.accent, 0.18) : "transparent"
        scale: clipMouse.containsMouse ? (clipMouse.pressed ? 0.90 : 1.10) : 1.0
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }

        RowLayout {
            id: clipRow
            anchors.centerIn: parent
            spacing: 4

            SvgIcon {
                name: "clipboard"
                size: 13
                color: clipMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.75)
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Text {
                text: ((typeof bar !== "undefined" && bar) ? bar.clipCount : 0).toString()
                font.family: "Outfit"
                font.pixelSize: 10
                font.weight: Font.Bold
                color: clipMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.65)
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
        MouseArea {
            id: clipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (typeof bar !== "undefined" && bar) bar.toggleClipboard(clipBtn)
        }
    }

    Component.onCompleted: {
        if (typeof bar !== "undefined" && bar) bar.togglesTrigger = rootPill
    }
    Component.onDestruction: {
        if (typeof bar !== "undefined" && bar && bar.togglesTrigger === rootPill) bar.togglesTrigger = null
    }
}
