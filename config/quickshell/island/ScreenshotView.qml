import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root

    property bool active: false
    property bool isClosing: false
    property real animProgress: 1.0
    signal closeRequested()
    signal startTimerScreenshot(int seconds, string targetMode, bool useSatty, bool playSound)

    readonly property bool isIslandView: true
    readonly property real preferredWidth: 620
    readonly property real preferredHeight: 380
    implicitWidth: preferredWidth
    implicitHeight: preferredHeight

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    // Toggle options
    property bool useSatty: true
    property bool playSound: true
    property int delaySeconds: 0

    property int selectedIndex: 0

    // Forward keyboard events
    function handleKey(event) {
        var k = event.key
        var t = (event.text || "").toLowerCase()

        if (k === Qt.Key_Escape) {
            event.accepted = true
            root.closeRequested()
            return true
        } else if (k === Qt.Key_1 || t === "1" || k === Qt.Key_A || t === "a") {
            event.accepted = true
            root.selectedIndex = 0
            captureMode("area")
            return true
        } else if (k === Qt.Key_2 || t === "2" || k === Qt.Key_W || t === "w") {
            event.accepted = true
            root.selectedIndex = 1
            captureMode("active")
            return true
        } else if (k === Qt.Key_3 || t === "3" || k === Qt.Key_F || t === "f") {
            event.accepted = true
            root.selectedIndex = 2
            captureMode("screen")
            return true
        } else if (k === Qt.Key_4 || t === "4" || k === Qt.Key_T || t === "t") {
            event.accepted = true
            root.selectedIndex = 3
            captureMode("timer")
            return true
        } else if (k === Qt.Key_S || t === "s") {
            event.accepted = true
            root.useSatty = !root.useSatty
            return true
        } else if (k === Qt.Key_C || t === "c" || k === Qt.Key_M || t === "m") {
            event.accepted = true
            root.playSound = !root.playSound
            return true
        } else if (k === Qt.Key_Left) {
            event.accepted = true
            root.selectedIndex = (root.selectedIndex <= 0) ? 3 : root.selectedIndex - 1
            return true
        } else if (k === Qt.Key_Right) {
            event.accepted = true
            root.selectedIndex = (root.selectedIndex >= 3) ? 0 : root.selectedIndex + 1
            return true
        } else if (k === Qt.Key_Tab) {
            event.accepted = true
            root.selectedIndex = (root.selectedIndex + 1) % 4
            return true
        } else if (k === Qt.Key_Backtab) {
            event.accepted = true
            root.selectedIndex = (root.selectedIndex + 3) % 4
            return true
        } else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) {
            event.accepted = true
            if (root.selectedIndex === 0) captureMode("area")
            else if (root.selectedIndex === 1) captureMode("active")
            else if (root.selectedIndex === 2) captureMode("screen")
            else if (root.selectedIndex === 3) captureMode("timer")
            return true
        }
        return false
    }


    Shortcut {
        sequence: "1"
        enabled: root.active && !root.isClosing
        onActivated: {
            root.selectedIndex = 0
            root.captureMode("area")
        }
    }

    Shortcut {
        sequence: "2"
        enabled: root.active && !root.isClosing
        onActivated: {
            root.selectedIndex = 1
            root.captureMode("active")
        }
    }

    Shortcut {
        sequence: "3"
        enabled: root.active && !root.isClosing
        onActivated: {
            root.selectedIndex = 2
            root.captureMode("screen")
        }
    }

    Shortcut {
        sequence: "4"
        enabled: root.active && !root.isClosing
        onActivated: {
            root.selectedIndex = 3
            root.captureMode("timer")
        }
    }

    Shortcut {
        sequence: "t"
        enabled: root.active && !root.isClosing
        onActivated: {
            root.selectedIndex = 3
            root.captureMode("timer")
        }
    }

    function captureMode(mode) {
        // If timer screenshot or delayed mode, delegate countdown to Dynamic Island
        if (mode === "timer" || root.delaySeconds > 0) {
            var delay = (mode === "timer") ? 5 : root.delaySeconds
            var target = (mode === "timer") ? "screen" : mode
            root.startTimerScreenshot(delay, target, root.useSatty, root.playSound)
            return
        }

        // Build arguments for immediate capture
        var args = ["bash", root.homeDir + "/.hyprconf/hypr/scripts/sh/screenshot.sh", "--delay", "0"]
        if (!root.useSatty) args.push("--no-satty")
        if (!root.playSound) args.push("--no-sound")

        if (mode === "active") {
            args.push("active")
        } else if (mode === "screen") {
            args.push("screen")
        } else {
            args.push("area")
        }

        // Close island launcher first so it disappears from screen before capture
        root.closeRequested()

        // Spawn after brief delay allowing island collapse animation to clear the screen
        captureProc.command = args
        delayedCaptureTimer.restart()
    }

    Timer {
        id: delayedCaptureTimer
        interval: 280
        repeat: false
        onTriggered: {
            captureProc.running = true
        }
    }

    Process {
        id: captureProc
        command: []
    }

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string cameraSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/><circle cx="12" cy="13" r="4"/></svg>')
    readonly property string areaSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 2v4M18 2v4M2 6h4M2 18h4M22 6h-4M22 18h-4M6 22v-4M18 22v-4"/><rect x="7" y="7" width="10" height="10" rx="2" stroke-dasharray="3 3"/></svg>')
    readonly property string windowSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><line x1="3" y1="9" x2="21" y2="9"/><line x1="9" y1="21" x2="9" y2="9"/></svg>')
    readonly property string monitorSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>')
    readonly property string timerSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>')
    readonly property string closeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.muted + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>')
    readonly property string checkSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>')

    // ── OBSIDIAN EXPANDING BACKGROUND CONTAINER ─────────────────────────────
    Rectangle {
        id: islandMorphBg
        anchors.fill: parent
        radius: 18 + (24 - 18) * root.animProgress
        color: Theme.alpha(Theme.background, 0.82)
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.35)
    }

    // ── CONTENT CONTAINER ────────────────────────────────────────────────────
    Item {
        id: contentContainer
        anchors.fill: parent
        anchors.margins: 22
        opacity: (!root.isClosing && root.animProgress >= 0.75) ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: root.isClosing ? 90 : 150; easing.type: Easing.OutCubic }
        }

        // Header Row
        RowLayout {
            id: headerRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 40
            spacing: 12

            Rectangle {
                width: 36
                height: 36
                radius: 18
                color: Theme.alpha(Theme.accent, 0.16)
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.40)

                Image {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    source: root.cameraSvg
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "SCREENSHOT STUDIO"
                    font.family: "Outfit"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.2
                    color: Theme.foreground
                }

                Text {
                    text: "Select capture target or use quick hotkeys [1 - 4]"
                    font.family: "Outfit"
                    font.pixelSize: 11
                    color: Theme.muted
                }
            }

            // Close button
            Rectangle {
                width: 30
                height: 30
                radius: 15
                color: closeMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.14) : "transparent"
                border.width: 1
                border.color: closeMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.25) : "transparent"

                Image {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    source: root.closeSvg
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }

        // ── 4 CAPTURE MODE CARDS ─────────────────────────────────────────────
        RowLayout {
            id: cardsRow
            anchors.top: headerRow.bottom
            anchors.topMargin: 18
            anchors.left: parent.left
            anchors.right: parent.right
            height: 170
            spacing: 12

            // Card 1: Area Crop
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16
                color: (card1Mouse.containsMouse || root.selectedIndex === 0) ? Theme.alpha(Theme.accent, 0.16) : Theme.alpha(Theme.surface, 0.55)
                border.width: 1
                border.color: (card1Mouse.containsMouse || root.selectedIndex === 0) ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                scale: card1Mouse.pressed ? 0.96 : ((card1Mouse.containsMouse || root.selectedIndex === 0) ? 1.02 : 1.0)
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 44
                        height: 44
                        radius: 22
                        color: Theme.alpha(Theme.accent, 0.18)

                        Image {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            source: root.areaSvg
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Area Crop"
                        font.family: "Outfit"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: Theme.foreground
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Drag rectangle [1]"
                        font.family: "Outfit"
                        font.pixelSize: 10
                        color: Theme.muted
                    }
                }

                MouseArea {
                    id: card1Mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selectedIndex = 0
                    onClicked: root.captureMode("area")
                }
            }

            // Card 2: Active Window
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16
                color: (card2Mouse.containsMouse || root.selectedIndex === 1) ? Theme.alpha(Theme.accent, 0.16) : Theme.alpha(Theme.surface, 0.55)
                border.width: 1
                border.color: (card2Mouse.containsMouse || root.selectedIndex === 1) ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                scale: card2Mouse.pressed ? 0.96 : ((card2Mouse.containsMouse || root.selectedIndex === 1) ? 1.02 : 1.0)
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 44
                        height: 44
                        radius: 22
                        color: Theme.alpha(Theme.accent, 0.18)

                        Image {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            source: root.windowSvg
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Window"
                        font.family: "Outfit"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: Theme.foreground
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Active window [2]"
                        font.family: "Outfit"
                        font.pixelSize: 10
                        color: Theme.muted
                    }
                }

                MouseArea {
                    id: card2Mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selectedIndex = 1
                    onClicked: root.captureMode("active")
                }
            }

            // Card 3: Fullscreen
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16
                color: (card3Mouse.containsMouse || root.selectedIndex === 2) ? Theme.alpha(Theme.accent, 0.16) : Theme.alpha(Theme.surface, 0.55)
                border.width: 1
                border.color: (card3Mouse.containsMouse || root.selectedIndex === 2) ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                scale: card3Mouse.pressed ? 0.96 : ((card3Mouse.containsMouse || root.selectedIndex === 2) ? 1.02 : 1.0)
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 44
                        height: 44
                        radius: 22
                        color: Theme.alpha(Theme.accent, 0.18)

                        Image {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            source: root.monitorSvg
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Fullscreen"
                        font.family: "Outfit"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: Theme.foreground
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "All monitors [3]"
                        font.family: "Outfit"
                        font.pixelSize: 10
                        color: Theme.muted
                    }
                }

                MouseArea {
                    id: card3Mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selectedIndex = 2
                    onClicked: root.captureMode("screen")
                }
            }

            // Card 4: 5s Delay
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16
                color: (card4Mouse.containsMouse || root.selectedIndex === 3) ? Theme.alpha(Theme.accent, 0.16) : Theme.alpha(Theme.surface, 0.55)
                border.width: 1
                border.color: (card4Mouse.containsMouse || root.selectedIndex === 3) ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                scale: card4Mouse.pressed ? 0.96 : ((card4Mouse.containsMouse || root.selectedIndex === 3) ? 1.02 : 1.0)
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 44
                        height: 44
                        radius: 22
                        color: Theme.alpha(Theme.accent, 0.18)

                        Image {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            source: root.timerSvg
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "5s Timer"
                        font.family: "Outfit"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: Theme.foreground
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Countdown [4]"
                        font.family: "Outfit"
                        font.pixelSize: 10
                        color: Theme.muted
                    }
                }

                MouseArea {
                    id: card4Mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selectedIndex = 3
                    onClicked: root.captureMode("timer")
                }
            }
        }

        // ── BOTTOM OPTIONS BAR ───────────────────────────────────────────────
        RowLayout {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 48
            spacing: 12

            // Toggle 1: Satty Annotation
            Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: 20
                color: root.useSatty ? Theme.alpha(Theme.accent, 0.18) : Theme.alpha(Theme.surface, 0.40)
                border.width: 1
                border.color: root.useSatty ? Theme.alpha(Theme.accent, 0.50) : Theme.alpha(Theme.foreground, 0.10)

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        color: root.useSatty ? Theme.accent : "transparent"
                        border.width: 1.5
                        border.color: root.useSatty ? Theme.accent : Theme.muted

                        Image {
                            anchors.centerIn: parent
                            width: 10
                            height: 10
                            source: root.checkSvg
                            visible: root.useSatty
                        }
                    }

                    Text {
                        text: "Annotate (Satty) [S]"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: root.useSatty ? Theme.accent : Theme.muted
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.useSatty = !root.useSatty
                }
            }

            // Toggle 2: Shutter Sound
            Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: 20
                color: root.playSound ? Theme.alpha(Theme.accent, 0.18) : Theme.alpha(Theme.surface, 0.40)
                border.width: 1
                border.color: root.playSound ? Theme.alpha(Theme.accent, 0.50) : Theme.alpha(Theme.foreground, 0.10)

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        color: root.playSound ? Theme.accent : "transparent"
                        border.width: 1.5
                        border.color: root.playSound ? Theme.accent : Theme.muted

                        Image {
                            anchors.centerIn: parent
                            width: 10
                            height: 10
                            source: root.checkSvg
                            visible: root.playSound
                        }
                    }

                    Text {
                        text: "Camera Sound [C]"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: root.playSound ? Theme.accent : Theme.muted
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.playSound = !root.playSound
                }
            }

            // Quick Info Pill
            Rectangle {
                height: 40
                Layout.preferredWidth: 120
                radius: 20
                color: Theme.alpha(Theme.surface, 0.35)
                border.width: 1
                border.color: Theme.alpha(Theme.foreground, 0.08)

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "Auto Copysave"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        color: Theme.muted
                    }
                }
            }
        }
    }
}
