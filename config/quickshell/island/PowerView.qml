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

    // 0: Lock, 1: Logout, 2: Reboot, 3: Shutdown
    property int selectedIndex: 0

    // Countdown timer state for power actions (3-second delay)
    property string pendingAction: ""
    property int countdownSeconds: 3
    readonly property bool isCountingDown: pendingAction !== ""
    property real countdownProgress: 1.0
    property real pulseGlow: 0.8

    readonly property string pendingActionLabel: {
        if (pendingAction === "shutdown") return "Power Off"
        if (pendingAction === "reboot") return "Reboot"
        if (pendingAction === "logout") return "Logout"
        return ""
    }

    readonly property color pendingActionColor: {
        if (pendingAction === "shutdown") return Theme.error
        if (pendingAction === "reboot") return "#f59e0b"
        if (pendingAction === "logout") return Theme.secondary
        return Theme.accent
    }

    Timer {
        id: countdownSecTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            if (root.countdownSeconds > 1) {
                root.countdownSeconds -= 1
            } else {
                countdownSecTimer.stop()
                progressAnim.stop()
                root.executePendingAction()
            }
        }
    }

    NumberAnimation {
        id: progressAnim
        target: root
        property: "countdownProgress"
        from: 1.0
        to: 0.0
        duration: 3000
        easing.type: Easing.Linear
    }

    SequentialAnimation {
        running: root.isCountingDown
        loops: Animation.Infinite
        NumberAnimation { target: root; property: "pulseGlow"; from: 0.40; to: 1.0; duration: 450; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "pulseGlow"; from: 1.0; to: 0.40; duration: 450; easing.type: Easing.InOutQuad }
    }

    function triggerAction(actionName) {
        if (actionName === "lock") {
            cancelCountdown()
            root.backClicked()
            root.executePowerAction(root.homeDir + "/.hyprconf/hypr/scripts/sh/qs-lock.sh")
            return
        }

        // If clicking the currently pending action again, execute immediately without waiting
        if (root.pendingAction === actionName) {
            executePendingAction()
            return
        }

        // Start 3-second countdown for logout, reboot, or shutdown
        root.pendingAction = actionName
        root.countdownSeconds = 3
        root.countdownProgress = 1.0
        countdownSecTimer.restart()
        progressAnim.restart()
    }

    function executePendingAction() {
        countdownSecTimer.stop()
        progressAnim.stop()
        var act = root.pendingAction
        root.pendingAction = ""
        root.countdownSeconds = 3
        root.countdownProgress = 1.0

        root.backClicked()

        if (act === "shutdown") {
            root.executePowerAction("systemctl poweroff")
        } else if (act === "reboot") {
            root.executePowerAction("systemctl reboot")
        } else if (act === "logout") {
            root.executePowerAction(root.homeDir + "/.hyprconf/hypr/scripts/sh/qs-logout.sh")
        }
    }

    function cancelCountdown() {
        if (countdownSecTimer.running || root.pendingAction !== "") {
            countdownSecTimer.stop()
            progressAnim.stop()
            root.pendingAction = ""
            root.countdownSeconds = 3
            root.countdownProgress = 1.0
            return true
        }
        return false
    }

    onActiveChanged: {
        if (!active) {
            cancelCountdown()
        }
    }

    // Forward keyboard events
    function handleKey(event) {
        var k = event.key
        var t = (event.text || "").toLowerCase()

        // 1. If currently in countdown, Escape/Space/Backspace cancels, Enter executes immediately
        if (root.isCountingDown) {
            if (k === Qt.Key_Escape || k === Qt.Key_Space || k === Qt.Key_Backspace) {
                event.accepted = true
                cancelCountdown()
                return true
            }
            if (k === Qt.Key_Return || k === Qt.Key_Enter) {
                event.accepted = true
                executePendingAction()
                return true
            }
            // If pressing the hotkey of the pending action, execute immediately
            if (root.pendingAction === "logout" && (k === Qt.Key_2 || t === "2" || k === Qt.Key_E || t === "e" || k === Qt.Key_O || t === "o")) {
                event.accepted = true
                executePendingAction()
                return true
            }
            if (root.pendingAction === "reboot" && (k === Qt.Key_3 || t === "3" || k === Qt.Key_R || t === "r")) {
                event.accepted = true
                executePendingAction()
                return true
            }
            if (root.pendingAction === "shutdown" && (k === Qt.Key_4 || t === "4" || k === Qt.Key_S || t === "s" || k === Qt.Key_P || t === "p")) {
                event.accepted = true
                executePendingAction()
                return true
            }
        }

        // 2. Direct hotkeys [1 - 4] and letter mnemonics
        if (k === Qt.Key_1 || t === "1" || k === Qt.Key_L || t === "l") {
            event.accepted = true
            root.selectedIndex = 0
            triggerAction("lock")
            return true
        }
        if (k === Qt.Key_2 || t === "2" || k === Qt.Key_E || t === "e" || k === Qt.Key_O || t === "o") {
            event.accepted = true
            root.selectedIndex = 1
            triggerAction("logout")
            return true
        }
        if (k === Qt.Key_3 || t === "3" || k === Qt.Key_R || t === "r") {
            event.accepted = true
            root.selectedIndex = 2
            triggerAction("reboot")
            return true
        }
        if (k === Qt.Key_4 || t === "4" || k === Qt.Key_S || t === "s" || k === Qt.Key_P || t === "p") {
            event.accepted = true
            root.selectedIndex = 3
            triggerAction("shutdown")
            return true
        }

        // 3. Arrow / Tab navigation
        if (k === Qt.Key_Left) {
            event.accepted = true
            if (root.selectedIndex === 1) root.selectedIndex = 0
            else if (root.selectedIndex === 3) root.selectedIndex = 2
            return true
        }
        if (k === Qt.Key_Right) {
            event.accepted = true
            if (root.selectedIndex === 0) root.selectedIndex = 1
            else if (root.selectedIndex === 2) root.selectedIndex = 3
            return true
        }
        if (k === Qt.Key_Up) {
            event.accepted = true
            if (root.selectedIndex === 2) root.selectedIndex = 0
            else if (root.selectedIndex === 3) root.selectedIndex = 1
            return true
        }
        if (k === Qt.Key_Down) {
            event.accepted = true
            if (root.selectedIndex === 0) root.selectedIndex = 2
            else if (root.selectedIndex === 1) root.selectedIndex = 3
            return true
        }
        if (k === Qt.Key_Tab) {
            event.accepted = true
            root.selectedIndex = (root.selectedIndex + 1) % 4
            return true
        }
        if (k === Qt.Key_Backtab) {
            event.accepted = true
            root.selectedIndex = (root.selectedIndex + 3) % 4
            return true
        }

        // 4. Enter/Return triggers currently selected card
        if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) {
            event.accepted = true
            if (root.selectedIndex === 0) triggerAction("lock")
            else if (root.selectedIndex === 1) triggerAction("logout")
            else if (root.selectedIndex === 2) triggerAction("reboot")
            else if (root.selectedIndex === 3) triggerAction("shutdown")
            return true
        }

        // 5. Backspace navigates back to dashboard home
        if (k === Qt.Key_Backspace) {
            event.accepted = true
            root.backClicked()
            return true
        }

        return false
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.active && !root.isCountingDown
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
        spacing: 12

        // ── TOP HEADER / NAVIGATION BAR ──────────────────────────────────────
        Item {
            width: parent.width
            height: 38

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
                    onClicked: {
                        root.cancelCountdown()
                        root.backClicked()
                    }
                }
            }

            // Center Title & Live Countdown Indicator
            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Power Menu"
                    font.family: "Outfit"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    color: Theme.foreground
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.isCountingDown
                          ? (root.pendingActionLabel + " in " + root.countdownSeconds + "s — Esc to cancel, Enter to confirm")
                          : "Hotkeys: [1] Lock  [2] Logout  [3] Reboot  [4] Power"
                    font.family: "Outfit"
                    font.pixelSize: 10
                    font.weight: root.isCountingDown ? Font.Bold : Font.Normal
                    color: root.isCountingDown ? root.pendingActionColor : Theme.muted
                }
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
            height: 320
            columns: 2
            spacing: 14

            // 1. LOCK (Instant, no delay)
            Rectangle {
                id: lockCard
                width: 215
                height: 152
                radius: 18
                color: (lockMouse.containsMouse || root.selectedIndex === 0)
                       ? Theme.alpha(Theme.surface, 0.90)
                       : Theme.alpha(Theme.surface, 0.65)
                border.color: (lockMouse.containsMouse || root.selectedIndex === 0)
                              ? Theme.primary
                              : Theme.alpha(Theme.foreground, 0.10)
                border.width: (lockMouse.containsMouse || root.selectedIndex === 0) ? 1.5 : 1
                scale: lockMouse.pressed ? 0.97 : ((lockMouse.containsMouse || root.selectedIndex === 0) ? 1.02 : 1.0)

                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                // Hotkey badge
                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    width: 22
                    height: 20
                    radius: 6
                    color: Theme.alpha(Theme.surface, 0.70)
                    border.color: Theme.alpha(Theme.foreground, 0.12)
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "1"
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Theme.alpha(Theme.foreground, 0.60)
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 46
                        height: 46
                        radius: 23
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
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        color: Theme.foreground
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Lock session [1 / L]"
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
                    onEntered: root.selectedIndex = 0
                    onClicked: root.triggerAction("lock")
                }
            }

            // 2. LOGOUT (3s delay timer)
            Rectangle {
                id: logoutCard
                width: 215
                height: 152
                radius: 18
                color: root.pendingAction === "logout"
                       ? Theme.alpha(Theme.secondary, 0.22)
                       : ((logoutMouse.containsMouse || root.selectedIndex === 1)
                          ? Theme.alpha(Theme.surface, 0.90)
                          : Theme.alpha(Theme.surface, 0.65))
                border.color: root.pendingAction === "logout"
                              ? Theme.alpha(Theme.secondary, root.pulseGlow)
                              : ((logoutMouse.containsMouse || root.selectedIndex === 1)
                                 ? Theme.secondary
                                 : Theme.alpha(Theme.foreground, 0.10))
                border.width: root.pendingAction === "logout" ? 2.0 : ((logoutMouse.containsMouse || root.selectedIndex === 1) ? 1.5 : 1)
                scale: logoutMouse.pressed ? 0.97 : ((logoutMouse.containsMouse || root.selectedIndex === 1) ? 1.02 : 1.0)

                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                // Hotkey badge
                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    width: 22
                    height: 20
                    radius: 6
                    color: root.pendingAction === "logout" ? Theme.alpha(Theme.secondary, 0.40) : Theme.alpha(Theme.surface, 0.70)
                    border.color: root.pendingAction === "logout" ? Theme.secondary : Theme.alpha(Theme.foreground, 0.12)
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "2"
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: root.pendingAction === "logout" ? Theme.foreground : Theme.alpha(Theme.foreground, 0.60)
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 46
                        height: 46
                        radius: 23
                        color: Theme.alpha(Theme.secondary, 0.18)
                        border.color: Theme.alpha(Theme.secondary, 0.40)
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
                        text: root.pendingAction === "logout"
                              ? ("Logging out (" + root.countdownSeconds + "s)")
                              : "Logout"
                        font.family: "Outfit"
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        color: Theme.foreground
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.pendingAction === "logout"
                              ? "Click / Enter to confirm now"
                              : "Exit Hyprland [2 / E]"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: root.pendingAction === "logout" ? Font.Bold : Font.Normal
                        color: root.pendingAction === "logout" ? Theme.secondary : Theme.alpha(Theme.foreground, 0.60)
                    }
                }

                // Countdown Progress Bar
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 24
                    height: 3
                    radius: 1.5
                    color: Theme.alpha(Theme.surface, 0.8)
                    visible: root.pendingAction === "logout"

                    Rectangle {
                        height: parent.height
                        radius: 1.5
                        width: parent.width * root.countdownProgress
                        color: Theme.secondary
                    }
                }

                MouseArea {
                    id: logoutMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selectedIndex = 1
                    onClicked: root.triggerAction("logout")
                }
            }

            // 3. REBOOT (3s delay timer)
            Rectangle {
                id: rebootCard
                width: 215
                height: 152
                radius: 18
                color: root.pendingAction === "reboot"
                       ? Theme.alpha("#f59e0b", 0.22)
                       : ((rebootMouse.containsMouse || root.selectedIndex === 2)
                          ? Theme.alpha(Theme.surface, 0.90)
                          : Theme.alpha(Theme.surface, 0.65))
                border.color: root.pendingAction === "reboot"
                              ? Theme.alpha("#f59e0b", root.pulseGlow)
                              : ((rebootMouse.containsMouse || root.selectedIndex === 2)
                                 ? "#f59e0b"
                                 : Theme.alpha(Theme.foreground, 0.10))
                border.width: root.pendingAction === "reboot" ? 2.0 : ((rebootMouse.containsMouse || root.selectedIndex === 2) ? 1.5 : 1)
                scale: rebootMouse.pressed ? 0.97 : ((rebootMouse.containsMouse || root.selectedIndex === 2) ? 1.02 : 1.0)

                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                // Hotkey badge
                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    width: 22
                    height: 20
                    radius: 6
                    color: root.pendingAction === "reboot" ? Theme.alpha("#f59e0b", 0.40) : Theme.alpha(Theme.surface, 0.70)
                    border.color: root.pendingAction === "reboot" ? "#f59e0b" : Theme.alpha(Theme.foreground, 0.12)
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "3"
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: root.pendingAction === "reboot" ? Theme.foreground : Theme.alpha(Theme.foreground, 0.60)
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 46
                        height: 46
                        radius: 23
                        color: Theme.alpha("#f59e0b", 0.18)
                        border.color: Theme.alpha("#f59e0b", 0.40)
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
                        text: root.pendingAction === "reboot"
                              ? ("Rebooting (" + root.countdownSeconds + "s)")
                              : "Reboot"
                        font.family: "Outfit"
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        color: Theme.foreground
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.pendingAction === "reboot"
                              ? "Click / Enter to confirm now"
                              : "Restart system [3 / R]"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: root.pendingAction === "reboot" ? Font.Bold : Font.Normal
                        color: root.pendingAction === "reboot" ? "#f59e0b" : Theme.alpha(Theme.foreground, 0.60)
                    }
                }

                // Countdown Progress Bar
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 24
                    height: 3
                    radius: 1.5
                    color: Theme.alpha(Theme.surface, 0.8)
                    visible: root.pendingAction === "reboot"

                    Rectangle {
                        height: parent.height
                        radius: 1.5
                        width: parent.width * root.countdownProgress
                        color: "#f59e0b"
                    }
                }

                MouseArea {
                    id: rebootMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selectedIndex = 2
                    onClicked: root.triggerAction("reboot")
                }
            }

            // 4. SHUTDOWN (3s delay timer)
            Rectangle {
                id: shutdownCard
                width: 215
                height: 152
                radius: 18
                color: root.pendingAction === "shutdown"
                       ? Theme.alpha(Theme.error, 0.24)
                       : ((shutdownMouse.containsMouse || root.selectedIndex === 3)
                          ? Theme.alpha(Theme.error, 0.16)
                          : Theme.alpha(Theme.surface, 0.65))
                border.color: root.pendingAction === "shutdown"
                              ? Theme.alpha(Theme.error, root.pulseGlow)
                              : ((shutdownMouse.containsMouse || root.selectedIndex === 3)
                                 ? Theme.error
                                 : Theme.alpha(Theme.foreground, 0.10))
                border.width: root.pendingAction === "shutdown" ? 2.0 : ((shutdownMouse.containsMouse || root.selectedIndex === 3) ? 1.5 : 1)
                scale: shutdownMouse.pressed ? 0.97 : ((shutdownMouse.containsMouse || root.selectedIndex === 3) ? 1.02 : 1.0)

                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                // Hotkey badge
                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    width: 22
                    height: 20
                    radius: 6
                    color: root.pendingAction === "shutdown" ? Theme.alpha(Theme.error, 0.40) : Theme.alpha(Theme.surface, 0.70)
                    border.color: root.pendingAction === "shutdown" ? Theme.error : Theme.alpha(Theme.foreground, 0.12)
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "4"
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: root.pendingAction === "shutdown" ? Theme.foreground : Theme.alpha(Theme.foreground, 0.60)
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 46
                        height: 46
                        radius: 23
                        color: Theme.alpha(Theme.error, 0.18)
                        border.color: Theme.alpha(Theme.error, 0.45)
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
                        text: root.pendingAction === "shutdown"
                              ? ("Shutting down (" + root.countdownSeconds + "s)")
                              : "Shutdown"
                        font.family: "Outfit"
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        color: Theme.foreground
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.pendingAction === "shutdown"
                              ? "Click / Enter to confirm now"
                              : "Power off [4 / S]"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: root.pendingAction === "shutdown" ? Font.Bold : Font.Normal
                        color: root.pendingAction === "shutdown" ? Theme.error : Theme.alpha(Theme.foreground, 0.60)
                    }
                }

                // Countdown Progress Bar
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 24
                    height: 3
                    radius: 1.5
                    color: Theme.alpha(Theme.surface, 0.8)
                    visible: root.pendingAction === "shutdown"

                    Rectangle {
                        height: parent.height
                        radius: 1.5
                        width: parent.width * root.countdownProgress
                        color: Theme.error
                    }
                }

                MouseArea {
                    id: shutdownMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selectedIndex = 3
                    onClicked: root.triggerAction("shutdown")
                }
            }
        }

        // ── BOTTOM CANCEL BUTTON ─────────────────────────────────────────────
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.isCountingDown ? 260 : 180
            height: 34
            radius: 17
            color: root.isCountingDown
                   ? (cancelMouse.containsMouse ? Theme.alpha(Theme.error, 0.30) : Theme.alpha(Theme.error, 0.18))
                   : (cancelMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.50))
            border.color: root.isCountingDown
                          ? Theme.error
                          : (cancelMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.20) : Theme.alpha(Theme.foreground, 0.08))
            border.width: root.isCountingDown ? 1.5 : 1

            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: root.isCountingDown
                      ? ("Cancel Countdown (" + root.countdownSeconds + "s) [Esc]")
                      : "Cancel [Esc]"
                font.family: "Outfit"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: root.isCountingDown ? Theme.error : Theme.alpha(Theme.foreground, 0.75)
            }

            MouseArea {
                id: cancelMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.isCountingDown) {
                        root.cancelCountdown()
                    } else {
                        root.backClicked()
                    }
                }
            }
        }
    }
}
