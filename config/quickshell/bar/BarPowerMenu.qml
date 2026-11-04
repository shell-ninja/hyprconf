import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root

    required property var bar

    property bool shown: false
    property var triggerItem: null

    width: 410
    height: 350
    z: 9999

    readonly property bool isGlass: (bar && bar.capsuleStyle === "glass")
    readonly property int fT: 14
    readonly property int fB: 14
    readonly property int rL: 16

    // Centered along the right frame of the screen
    anchors.right: parent ? parent.right : undefined
    anchors.rightMargin: root.isGlass ? Math.max(0, bar.frameThickness - 1) : 12
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    // ── BUBBLY POPPING ANIMATION (Anchored & Expanding from Right Frame) ────
    property real animTranslateX: shown ? 0 : 45
    property real animScale: shown ? 1.0 : 0.84
    property real animOpacity: shown ? 1.0 : 0.0

    opacity: animOpacity
    visible: opacity > 0.005

    Behavior on animTranslateX {
        NumberAnimation {
            duration: root.shown ? 270 : 150
            easing.type: root.shown ? Easing.OutBack : Easing.InQuad
            easing.overshoot: 1.20
        }
    }
    Behavior on animScale {
        NumberAnimation {
            duration: root.shown ? 260 : 150
            easing.type: root.shown ? Easing.OutBack : Easing.InQuad
            easing.overshoot: 1.35
        }
    }
    Behavior on animOpacity {
        NumberAnimation {
            duration: root.shown ? 180 : 130
            easing.type: root.shown ? Easing.OutQuad : Easing.InQuad
        }
    }

    transform: [
        Translate { x: root.animTranslateX },
        Scale {
            origin.x: root.width
            origin.y: root.height / 2
            xScale: root.animScale
            yScale: root.animScale
        }
    ]

    readonly property bool isHovered: panelMouse.containsMouse || frameBridgeMouse.containsMouse
    readonly property string homeDir: bar ? bar.homeDir : (Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user"))
    readonly property string userName: (Quickshell.env("USER") || "user") + "@" + (Quickshell.env("HOSTNAME") || "hyprconf")

    // Countdown timer state for power actions (3-second delay, matching Island)
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

    // Timer for counting down 3 seconds
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

    // Grace timer to close when cursor leaves menu and triggers (only if opened via hover)
    property bool isHoverOpened: false

    Timer {
        id: hoverCloseTimer
        interval: 350
        repeat: false
        onTriggered: {
            if (!root.isHovered && (!root.triggerItem || !root.triggerItem.isHovered) && !root.isCountingDown && root.isHoverOpened) {
                root.closeMenu()
            }
        }
    }

    function checkHoverState() {
        if (root.isHovered || (root.triggerItem && root.triggerItem.isHovered)) {
            hoverCloseTimer.stop()
        } else {
            if (!root.isCountingDown && root.shown && root.isHoverOpened) {
                hoverCloseTimer.restart()
            }
        }
    }

    onIsHoveredChanged: checkHoverState()

    Connections {
        target: root.triggerItem
        function onIsHoveredChanged() {
            root.checkHoverState()
        }
    }

    function openFromHover() {
        hoverCloseTimer.stop()
        root.isHoverOpened = true
        root.shown = true
        Qt.callLater(root.checkHoverState)
    }

    function openMenu() {
        hoverCloseTimer.stop()
        root.isHoverOpened = false
        root.shown = true
    }

    function closeMenu() {
        root.cancelCountdown()
        root.isHoverOpened = false
        root.shown = false
    }

    function toggleMenu() {
        if (root.shown) {
            closeMenu()
        } else {
            openMenu()
        }
    }

    function triggerAction(actionName) {
        if (actionName === "lock") {
            cancelCountdown()
            closeMenu()
            Quickshell.execDetached([root.homeDir + "/.hyprconf/hypr/scripts/sh/qs-lock.sh"])
            return
        }

        // If clicking the pending action again, execute immediately
        if (root.pendingAction === actionName) {
            executePendingAction()
            return
        }

        // Start 3-second countdown
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

        closeMenu()

        if (act === "shutdown") {
            Quickshell.execDetached(["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/uptime-tracker.py", "--shutdown"])
        } else if (act === "reboot") {
            Quickshell.execDetached(["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/uptime-tracker.py", "--reboot"])
        } else if (act === "logout") {
            Quickshell.execDetached([root.homeDir + "/.hyprconf/hypr/scripts/sh/qs-logout.sh"])
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

    onShownChanged: {
        if (!shown) cancelCountdown()
    }

    // Keyboard Shortcuts when menu is open
    Shortcut {
        sequence: "1"
        enabled: root.shown
        onActivated: root.triggerAction("lock")
    }
    Shortcut {
        sequence: "l"
        enabled: root.shown
        onActivated: root.triggerAction("lock")
    }
    Shortcut {
        sequence: "2"
        enabled: root.shown
        onActivated: root.triggerAction("logout")
    }
    Shortcut {
        sequence: "e"
        enabled: root.shown
        onActivated: root.triggerAction("logout")
    }
    Shortcut {
        sequence: "3"
        enabled: root.shown
        onActivated: root.triggerAction("reboot")
    }
    Shortcut {
        sequence: "r"
        enabled: root.shown
        onActivated: root.triggerAction("reboot")
    }
    Shortcut {
        sequence: "4"
        enabled: root.shown
        onActivated: root.triggerAction("shutdown")
    }
    Shortcut {
        sequence: "s"
        enabled: root.shown
        onActivated: root.triggerAction("shutdown")
    }
    Shortcut {
        sequence: "Return"
        enabled: root.shown && root.isCountingDown
        onActivated: root.executePendingAction()
    }
    Shortcut {
        sequence: "Enter"
        enabled: root.shown && root.isCountingDown
        onActivated: root.executePendingAction()
    }
    Shortcut {
        sequence: "Escape"
        enabled: root.shown
        onActivated: {
            if (root.isCountingDown) {
                root.cancelCountdown()
            } else {
                root.closeMenu()
            }
        }
    }

    // ── ATTACHED OBSIDIAN GLASS FRAME MONOLITHIC SHAPE (Glass Mode) ───────────
    Shape {
        id: attachedShape
        visible: root.isGlass
        anchors.right: parent.right
        anchors.rightMargin: -2
        y: -root.fT
        width: root.width + 2
        height: root.height + root.fT + root.fB
        layer.enabled: true
        layer.samples: 4

        readonly property color surfaceFill: Theme.alpha(Theme.surface, (bar && bar.barOpacity > 0.05) ? bar.barOpacity : 0.95)
        property color strokeColor: root.isCountingDown
                                     ? root.pendingActionColor
                                     : Theme.alpha(Theme.accent, 0.35)
        Behavior on strokeColor { ColorAnimation { duration: 220 } }

        // 1. Closed Fill Path (Seamless fusion into the right frame)
        ShapePath {
            fillColor: attachedShape.surfaceFill
            strokeColor: "transparent"
            strokeWidth: 0

            startX: attachedShape.width
            startY: 0

            PathLine { x: root.width; y: 0 }
            PathArc {
                x: root.width - root.fT
                y: root.fT
                radiusX: root.fT
                radiusY: root.fT
                direction: PathArc.Clockwise
            }
            PathLine { x: root.rL; y: root.fT }
            PathArc {
                x: 0
                y: root.fT + root.rL
                radiusX: root.rL
                radiusY: root.rL
                direction: PathArc.Counterclockwise
            }
            PathLine { x: 0; y: root.fT + root.height - root.rL }
            PathArc {
                x: root.rL
                y: root.fT + root.height
                radiusX: root.rL
                radiusY: root.rL
                direction: PathArc.Counterclockwise
            }
            PathLine { x: root.width - root.fB; y: root.fT + root.height }
            PathArc {
                x: root.width
                y: root.fT + root.height + root.fB
                radiusX: root.fB
                radiusY: root.fB
                direction: PathArc.Clockwise
            }
            PathLine { x: attachedShape.width; y: root.fT + root.height + root.fB }
            PathLine { x: attachedShape.width; y: 0 }
        }

        // 2. Open Perimeter Stroke (NO stroke across right frame seam — 100% attached)
        ShapePath {
            fillColor: "transparent"
            strokeColor: attachedShape.strokeColor
            strokeWidth: 1.2
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            startX: root.width
            startY: 0

            PathArc {
                x: root.width - root.fT
                y: root.fT
                radiusX: root.fT
                radiusY: root.fT
                direction: PathArc.Clockwise
            }
            PathLine { x: root.rL; y: root.fT }
            PathArc {
                x: 0
                y: root.fT + root.rL
                radiusX: root.rL
                radiusY: root.rL
                direction: PathArc.Counterclockwise
            }
            PathLine { x: 0; y: root.fT + root.height - root.rL }
            PathArc {
                x: root.rL
                y: root.fT + root.height
                radiusX: root.rL
                radiusY: root.rL
                direction: PathArc.Counterclockwise
            }
            PathLine { x: root.width - root.fB; y: root.fT + root.height }
            PathArc {
                x: root.width
                y: root.fT + root.height + root.fB
                radiusX: root.fB
                radiusY: root.fB
                direction: PathArc.Clockwise
            }
        }
    }

    // ── FLOATING OBSIDIAN GLASS CARD (Islands Mode) ───────────────────────────
    Rectangle {
        id: floatingCard
        visible: !root.isGlass
        anchors.fill: parent
        radius: 16
        color: Theme.alpha(Theme.surface, 0.95)
        border.width: 1.2
        border.color: root.isCountingDown
                      ? root.pendingActionColor
                      : Theme.alpha(Theme.accent, 0.35)
        Behavior on border.color { ColorAnimation { duration: 220 } }
    }

    // Top Inner Glass Rim
    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: 1
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        height: 1
        color: Theme.alpha(Theme.foreground, 0.15)
    }

    MouseArea {
        id: panelMouse
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: -8
        hoverEnabled: true
        onEntered: root.checkHoverState()
        onExited: root.checkHoverState()
    }

    // Frame hover extension bridge (covers right frame directly adjacent to power panel)
    MouseArea {
        id: frameBridgeMouse
        anchors.left: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Math.max(18, (bar && bar.frameThickness) ? bar.frameThickness : 18) + 6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        z: 2
        onEntered: root.checkHoverState()
        onExited: root.checkHoverState()
        onClicked: {
            if (root.isCountingDown) root.cancelCountdown()
            else root.closeMenu()
        }
    }

    // ── INNER CONTENT CONTAINER ───────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 9

        // ── TOP HEADER: Icon, Title, Countdown Status & User Badge ────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Circular Power Icon Container
            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 17
                color: root.isCountingDown
                       ? Theme.alpha(root.pendingActionColor, 0.22)
                       : Theme.alpha(Theme.error, 0.18)
                border.width: 1
                border.color: root.isCountingDown
                              ? root.pendingActionColor
                              : Theme.alpha(Theme.error, 0.40)
                Behavior on color { ColorAnimation { duration: 180 } }
                Behavior on border.color { ColorAnimation { duration: 180 } }

                SvgIcon {
                    anchors.centerIn: parent
                    name: "power"
                    size: 15
                    color: root.isCountingDown ? root.pendingActionColor : Theme.error
                    Behavior on color { ColorAnimation { duration: 180 } }
                }
            }

            // Title & Subtitle
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Power Menu"
                    font.family: "Outfit"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: Theme.foreground
                }

                Text {
                    Layout.fillWidth: true
                    text: root.isCountingDown
                          ? (root.pendingActionLabel + " in " + root.countdownSeconds + "s — Enter to confirm, Esc to cancel")
                          : "Hotkeys: [1] Lock  [2] Logout  [3] Reboot  [4] Power"
                    font.family: "Outfit"
                    font.pixelSize: 10
                    font.weight: root.isCountingDown ? Font.Bold : Font.Normal
                    color: root.isCountingDown ? root.pendingActionColor : Theme.muted
                    elide: Text.ElideRight
                }
            }

            // User Session Badge
            Rectangle {
                Layout.preferredHeight: 24
                Layout.preferredWidth: userRow.implicitWidth + 14
                radius: 12
                color: Theme.alpha(Theme.surface, 0.70)
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.25)

                RowLayout {
                    id: userRow
                    anchors.centerIn: parent
                    spacing: 5

                    Rectangle {
                        width: 5
                        height: 5
                        radius: 2.5
                        color: Theme.accent
                    }

                    Text {
                        text: root.userName
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: Theme.alpha(Theme.foreground, 0.80)
                    }
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.alpha(Theme.foreground, 0.08)
        }

        // ── 2x2 ACTION TILES (Lock, Logout, Reboot, Shutdown) ─────────────────
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            rowSpacing: 8
            columnSpacing: 8

            // 1. LOCK (Instant, no delay)
            Rectangle {
                id: lockTile
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 13
                color: lockTileMouse.containsMouse
                       ? Theme.alpha(Theme.surface, 0.90)
                       : Theme.alpha(Theme.surface, 0.65)
                border.width: lockTileMouse.containsMouse ? 1.5 : 1
                border.color: lockTileMouse.containsMouse
                              ? Theme.primary
                              : Theme.alpha(Theme.foreground, 0.12)
                scale: lockTileMouse.pressed ? 0.97 : (lockTileMouse.containsMouse ? 1.02 : 1.0)

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 5

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 38
                        height: 38
                        radius: 19
                        color: Theme.alpha(Theme.primary, 0.18)
                        border.width: 1
                        border.color: Theme.alpha(Theme.primary, 0.40)

                        SvgIcon {
                            anchors.centerIn: parent
                            name: "lock"
                            size: 16
                            color: Theme.primary
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Lock Screen"
                        font.family: "Outfit"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: Theme.foreground
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Secure session [1 / L]"
                        font.family: "Outfit"
                        font.pixelSize: 10
                        color: Theme.muted
                    }
                }

                MouseArea {
                    id: lockTileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.triggerAction("lock")
                }
            }

            // 2. LOGOUT (3s delay timer with progress bar)
            Rectangle {
                id: logoutTile
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 13
                color: root.pendingAction === "logout"
                       ? Theme.alpha(Theme.secondary, 0.28)
                       : (logoutTileMouse.containsMouse
                          ? Theme.alpha(Theme.surface, 0.90)
                          : Theme.alpha(Theme.surface, 0.65))
                border.width: root.pendingAction === "logout" ? 2.0 : (logoutTileMouse.containsMouse ? 1.5 : 1)
                border.color: root.pendingAction === "logout"
                              ? Theme.secondary
                              : (logoutTileMouse.containsMouse
                                 ? Theme.alpha(Theme.secondary, 0.60)
                                 : Theme.alpha(Theme.foreground, 0.12))
                scale: logoutTileMouse.pressed ? 0.97 : (logoutTileMouse.containsMouse ? 1.02 : 1.0)

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 5

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 38
                        height: 38
                        radius: 19
                        color: root.pendingAction === "logout"
                               ? Theme.alpha(Theme.secondary, 0.40)
                               : Theme.alpha(Theme.secondary, 0.18)
                        border.width: 1
                        border.color: root.pendingAction === "logout"
                                      ? Theme.secondary
                                      : Theme.alpha(Theme.secondary, 0.40)

                        SvgIcon {
                            anchors.centerIn: parent
                            name: "logout"
                            size: 16
                            color: Theme.secondary
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.pendingAction === "logout"
                              ? ("Logging out (" + root.countdownSeconds + "s)")
                              : "Logout"
                        font.family: "Outfit"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: Theme.foreground
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.pendingAction === "logout"
                              ? "Click / Enter to confirm now"
                              : "Exit session [2 / E]"
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: root.pendingAction === "logout" ? Font.Bold : Font.Normal
                        color: root.pendingAction === "logout" ? Theme.secondary : Theme.muted
                    }
                }

                // Countdown Progress Bar
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 20
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
                    id: logoutTileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.triggerAction("logout")
                }
            }

            // 3. REBOOT (3s delay timer with progress bar)
            Rectangle {
                id: rebootTile
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 13
                color: root.pendingAction === "reboot"
                       ? Theme.alpha("#f59e0b", 0.28)
                       : (rebootTileMouse.containsMouse
                          ? Theme.alpha(Theme.surface, 0.90)
                          : Theme.alpha(Theme.surface, 0.65))
                border.width: root.pendingAction === "reboot" ? 2.0 : (rebootTileMouse.containsMouse ? 1.5 : 1)
                border.color: root.pendingAction === "reboot"
                              ? "#f59e0b"
                              : (rebootTileMouse.containsMouse
                                 ? Theme.alpha("#f59e0b", 0.60)
                                 : Theme.alpha(Theme.foreground, 0.12))
                scale: rebootTileMouse.pressed ? 0.97 : (rebootTileMouse.containsMouse ? 1.02 : 1.0)

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 5

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 38
                        height: 38
                        radius: 19
                        color: root.pendingAction === "reboot"
                               ? Theme.alpha("#f59e0b", 0.40)
                               : Theme.alpha("#f59e0b", 0.18)
                        border.width: 1
                        border.color: root.pendingAction === "reboot"
                                      ? "#f59e0b"
                                      : Theme.alpha("#f59e0b", 0.40)

                        SvgIcon {
                            anchors.centerIn: parent
                            name: "reboot"
                            size: 16
                            color: "#f59e0b"
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.pendingAction === "reboot"
                              ? ("Rebooting (" + root.countdownSeconds + "s)")
                              : "Reboot"
                        font.family: "Outfit"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: Theme.foreground
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.pendingAction === "reboot"
                              ? "Click / Enter to confirm now"
                              : "Restart system [3 / R]"
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: root.pendingAction === "reboot" ? Font.Bold : Font.Normal
                        color: root.pendingAction === "reboot" ? "#f59e0b" : Theme.muted
                    }
                }

                // Countdown Progress Bar
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 20
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
                    id: rebootTileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.triggerAction("reboot")
                }
            }

            // 4. SHUTDOWN (3s delay timer with progress bar)
            Rectangle {
                id: shutdownTile
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 13
                color: root.pendingAction === "shutdown"
                       ? Theme.alpha(Theme.error, 0.28)
                       : (shutdownTileMouse.containsMouse
                          ? Theme.alpha(Theme.surface, 0.90)
                          : Theme.alpha(Theme.surface, 0.65))
                border.width: root.pendingAction === "shutdown" ? 2.0 : (shutdownTileMouse.containsMouse ? 1.5 : 1)
                border.color: root.pendingAction === "shutdown"
                              ? Theme.error
                              : (shutdownTileMouse.containsMouse
                                 ? Theme.alpha(Theme.error, 0.60)
                                 : Theme.alpha(Theme.foreground, 0.12))
                scale: shutdownTileMouse.pressed ? 0.97 : (shutdownTileMouse.containsMouse ? 1.02 : 1.0)

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 5

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 38
                        height: 38
                        radius: 19
                        color: root.pendingAction === "shutdown"
                               ? Theme.alpha(Theme.error, 0.40)
                               : Theme.alpha(Theme.error, 0.18)
                        border.width: 1
                        border.color: root.pendingAction === "shutdown"
                                      ? Theme.error
                                      : Theme.alpha(Theme.error, 0.40)

                        SvgIcon {
                            anchors.centerIn: parent
                            name: "power"
                            size: 16
                            color: Theme.error
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.pendingAction === "shutdown"
                              ? ("Shutting down (" + root.countdownSeconds + "s)")
                              : "Shutdown"
                        font.family: "Outfit"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: Theme.foreground
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.pendingAction === "shutdown"
                              ? "Click / Enter to confirm now"
                              : "Power off [4 / S]"
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: root.pendingAction === "shutdown" ? Font.Bold : Font.Normal
                        color: root.pendingAction === "shutdown" ? Theme.error : Theme.muted
                    }
                }

                // Countdown Progress Bar
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 20
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
                    id: shutdownTileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.triggerAction("shutdown")
                }
            }
        }

        // ── BOTTOM CANCEL / DISMISS BUTTON ────────────────────────────────────
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.isCountingDown ? 240 : 150
            Layout.preferredHeight: 28
            radius: 14
            color: root.isCountingDown
                   ? (cancelBtnMouse.containsMouse ? Theme.alpha(Theme.error, 0.30) : Theme.alpha(Theme.error, 0.18))
                   : (cancelBtnMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.50))
            border.width: root.isCountingDown ? 1.5 : 1
            border.color: root.isCountingDown
                          ? Theme.error
                          : (cancelBtnMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.20) : Theme.alpha(Theme.foreground, 0.10))

            Behavior on Layout.preferredWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: root.isCountingDown
                      ? ("Cancel Countdown (" + root.countdownSeconds + "s) [Esc]")
                      : "Close [Esc]"
                font.family: "Outfit"
                font.pixelSize: 11
                font.weight: Font.Medium
                color: root.isCountingDown ? Theme.error : Theme.alpha(Theme.foreground, 0.75)
            }

            MouseArea {
                id: cancelBtnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.isCountingDown) {
                        root.cancelCountdown()
                    } else {
                        root.closeMenu()
                    }
                }
            }
        }
    }
}
