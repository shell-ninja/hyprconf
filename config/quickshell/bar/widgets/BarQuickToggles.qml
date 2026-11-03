import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

Pill {
    id: rootPill
    hPad: 4
    spacing: 3
    clickable: false

    // System Mode (Tri-State: 0 Normal, 1 Game, 2 Presentation)
    Rectangle {
        id: systemModeBtn
        implicitWidth: 26
        implicitHeight: 26
        radius: 13
        z: isHovered ? 1000 : 1
        readonly property bool isHovered: modeHover.hovered || modeMouse.containsMouse
        readonly property int currentMode: (typeof bar !== "undefined" && bar) ? bar.systemMode : 0

        color: currentMode === 1
               ? Theme.accent
               : (currentMode === 2
                  ? Theme.secondary
                  : (isHovered ? Theme.alpha(Theme.accent, 0.18) : "transparent"))
        scale: isHovered ? (modeMouse.pressed ? 0.90 : 1.12) : 1.0
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }

        SvgIcon {
            anchors.centerIn: parent
            name: systemModeBtn.currentMode === 1 ? "gamepad" : (systemModeBtn.currentMode === 2 ? "presentation" : "spark")
            size: 13
            color: (systemModeBtn.currentMode === 1 || systemModeBtn.currentMode === 2)
                   ? Theme.background
                   : (systemModeBtn.isHovered ? Theme.accent : Theme.alpha(Theme.foreground, 0.75))
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        HoverHandler {
            id: modeHover
        }

        MouseArea {
            id: modeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (typeof bar !== "undefined" && bar) bar.cycleSystemMode()
        }

        // Obsidian Glass Hover Tooltip
        Rectangle {
            id: modeTooltip
            z: 9999
            visible: systemModeBtn.isHovered || opacity > 0.01
            opacity: systemModeBtn.isHovered ? 1.0 : 0.0
            scale: systemModeBtn.isHovered ? 1.0 : 0.90
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

            anchors.top: parent.bottom
            anchors.topMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            width: 260
            height: tooltipCol.implicitHeight + 20
            radius: 12
            color: Theme.alpha(Theme.surface, 0.96)
            border.width: 1
            border.color: systemModeBtn.currentMode === 1
                          ? Theme.alpha(Theme.accent, 0.45)
                          : (systemModeBtn.currentMode === 2
                             ? Theme.alpha(Theme.secondary, 0.45)
                             : Theme.alpha(Theme.accent, 0.25))

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
                        name: systemModeBtn.currentMode === 1 ? "gamepad" : (systemModeBtn.currentMode === 2 ? "presentation" : "spark")
                        size: 14
                        color: systemModeBtn.currentMode === 1 ? Theme.accent : (systemModeBtn.currentMode === 2 ? Theme.secondary : Theme.foreground)
                    }

                    Text {
                        text: systemModeBtn.currentMode === 1 ? "Game Mode" : (systemModeBtn.currentMode === 2 ? "Presentation Mode" : "Normal Mode")
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
                        color: systemModeBtn.currentMode === 1
                               ? Theme.alpha(Theme.accent, 0.25)
                               : (systemModeBtn.currentMode === 2
                                  ? Theme.alpha(Theme.secondary, 0.25)
                                  : Theme.alpha(Theme.foreground, 0.10))
                        border.width: 1
                        border.color: systemModeBtn.currentMode === 1
                                      ? Theme.alpha(Theme.accent, 0.50)
                                      : (systemModeBtn.currentMode === 2
                                         ? Theme.alpha(Theme.secondary, 0.50)
                                         : Theme.alpha(Theme.foreground, 0.15))

                        Text {
                            id: badgeText
                            anchors.centerIn: parent
                            text: systemModeBtn.currentMode === 1 ? "GAME ON" : (systemModeBtn.currentMode === 2 ? "PRESENTING" : "STANDARD")
                            font.family: "Outfit"
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            color: systemModeBtn.currentMode === 1 ? Theme.accent : (systemModeBtn.currentMode === 2 ? Theme.secondary : Theme.alpha(Theme.foreground, 0.60))
                        }
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.alpha(Theme.accent, 0.15)
                }

                // Normal Mode (0)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    visible: systemModeBtn.currentMode === 0

                    RowLayout {
                        spacing: 6
                        Rectangle { width: 4; height: 4; radius: 2; color: Theme.accent }
                        Text {
                            text: "Obsidian glass & window blur active"
                            font.family: "Outfit"; font.pixelSize: 10
                            color: Theme.alpha(Theme.foreground, 0.85)
                        }
                    }
                    RowLayout {
                        spacing: 6
                        Rectangle { width: 4; height: 4; radius: 2; color: Theme.accent }
                        Text {
                            text: "Smooth spring physics animations"
                            font.family: "Outfit"; font.pixelSize: 10
                            color: Theme.alpha(Theme.foreground, 0.85)
                        }
                    }
                    RowLayout {
                        spacing: 6
                        Rectangle { width: 4; height: 4; radius: 2; color: Theme.accent }
                        Text {
                            text: "Desktop notifications & toasts active"
                            font.family: "Outfit"; font.pixelSize: 10
                            color: Theme.alpha(Theme.foreground, 0.85)
                        }
                    }
                    RowLayout {
                        spacing: 6
                        Rectangle { width: 4; height: 4; radius: 2; color: Theme.accent }
                        Text {
                            text: "Standard sleep & balanced power"
                            font.family: "Outfit"; font.pixelSize: 10
                            color: Theme.alpha(Theme.foreground, 0.85)
                        }
                    }
                }

                // Game Mode (1)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    visible: systemModeBtn.currentMode === 1

                    RowLayout {
                        spacing: 6
                        Rectangle { width: 4; height: 4; radius: 2; color: Theme.accent }
                        Text {
                            text: "100% opacity on all windows"
                            font.family: "Outfit"; font.pixelSize: 10
                            color: Theme.alpha(Theme.foreground, 0.85)
                        }
                    }
                    RowLayout {
                        spacing: 6
                        Rectangle { width: 4; height: 4; radius: 2; color: Theme.accent }
                        Text {
                            text: "0ms latency direct scanout tearing"
                            font.family: "Outfit"; font.pixelSize: 10
                            color: Theme.alpha(Theme.foreground, 0.85)
                        }
                    }
                    RowLayout {
                        spacing: 6
                        Rectangle { width: 4; height: 4; radius: 2; color: Theme.accent }
                        Text {
                            text: "Blur, window shadows & anim off"
                            font.family: "Outfit"; font.pixelSize: 10
                            color: Theme.alpha(Theme.foreground, 0.85)
                        }
                    }
                    RowLayout {
                        spacing: 6
                        Rectangle { width: 4; height: 4; radius: 2; color: Theme.accent }
                        Text {
                            text: "Max performance CPU profile"
                            font.family: "Outfit"; font.pixelSize: 10
                            color: Theme.alpha(Theme.foreground, 0.85)
                        }
                    }
                }

                // Presentation Mode (2)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    visible: systemModeBtn.currentMode === 2

                    RowLayout {
                        spacing: 6
                        Rectangle { width: 4; height: 4; radius: 2; color: Theme.secondary }
                        Text {
                            text: "Do Not Disturb (DND) — popups silenced"
                            font.family: "Outfit"; font.pixelSize: 10
                            color: Theme.alpha(Theme.foreground, 0.85)
                        }
                    }
                    RowLayout {
                        spacing: 6
                        Rectangle { width: 4; height: 4; radius: 2; color: Theme.secondary }
                        Text {
                            text: "Display sleep & lock inhibited (Caffeine)"
                            font.family: "Outfit"; font.pixelSize: 10
                            color: Theme.alpha(Theme.foreground, 0.85)
                        }
                    }
                    RowLayout {
                        spacing: 6
                        Rectangle { width: 4; height: 4; radius: 2; color: Theme.secondary }
                        Text {
                            text: "No tearing for clean video / screen share"
                            font.family: "Outfit"; font.pixelSize: 10
                            color: Theme.alpha(Theme.foreground, 0.85)
                        }
                    }
                    RowLayout {
                        spacing: 6
                        Rectangle { width: 4; height: 4; radius: 2; color: Theme.secondary }
                        Text {
                            text: "Quiet fan acoustics (Balanced power)"
                            font.family: "Outfit"; font.pixelSize: 10
                            color: Theme.alpha(Theme.foreground, 0.85)
                        }
                    }
                }

                // Footer: Click hint
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.alpha(Theme.foreground, 0.08)
                }

                Text {
                    text: systemModeBtn.currentMode === 0
                          ? "Click to switch to Game Mode"
                          : (systemModeBtn.currentMode === 1
                             ? "Click to switch to Presentation Mode"
                             : "Click to switch to Normal Mode")
                    font.family: "Outfit"
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    color: Theme.alpha(Theme.foreground, 0.50)
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
