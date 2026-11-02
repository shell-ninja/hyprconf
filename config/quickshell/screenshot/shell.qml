//@ pragma Env QS_NO_RELOAD_POPUP=1
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "."

PanelWindow {
    id: root

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    onClosed: Qt.quit()

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "screenshot-studio"

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    // ── ANIMATION & EXIT STATE ───────────────────────────────────────────────
    property real animScale: 0.86
    property real animOpacity: 0.0
    property bool isExiting: false

    ParallelAnimation {
        id: openAnim
        running: true
        NumberAnimation {
            target: root
            property: "animScale"
            from: 0.86
            to: 1.0
            duration: 260
            easing.type: Easing.OutBack
            easing.overshoot: 1.25
        }
        NumberAnimation {
            target: root
            property: "animOpacity"
            from: 0.0
            to: 1.0
            duration: 190
            easing.type: Easing.OutQuad
        }
    }

    ParallelAnimation {
        id: closeAnim
        NumberAnimation {
            target: root
            property: "animScale"
            to: 0.88
            duration: 170
            easing.type: Easing.InBack
            easing.overshoot: 1.10
        }
        NumberAnimation {
            target: root
            property: "animOpacity"
            to: 0.0
            duration: 150
            easing.type: Easing.InQuad
        }
        onFinished: {
            Qt.quit()
        }
    }

    function closeWindow() {
        if (root.isExiting) return
        root.isExiting = true
        openAnim.stop()
        closeAnim.restart()
    }

    // Transparent click-outside-to-dismiss area (keeps desktop completely unblurred)
    MouseArea {
        anchors.fill: parent
        onClicked: root.closeWindow()
    }

    // ── CENTERED OBSIDIAN GLASS SCREENSHOT CONTAINER ─────────────────────────
    Rectangle {
        id: modalCard
        anchors.centerIn: parent
        width: 660
        height: 410
        radius: 18
        color: Theme.alpha(Theme.surface, 0.94)
        border.width: 1.5
        border.color: Theme.alpha(Theme.accent, 0.35)
        scale: root.animScale
        opacity: root.animOpacity
        transformOrigin: Item.Center

        // Prevent click-through from closing when clicking inside
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
        }

        ScreenshotView {
            id: screenshotView
            anchors.fill: parent
            anchors.margins: 12
            active: true
            onCloseRequested: root.closeWindow()
            onStartTimerScreenshot: function(seconds, targetMode, useSatty, playSound) {
                root.closeWindow()
                var args = [
                    "bash",
                    root.homeDir + "/.hyprconf/hypr/scripts/sh/screenshot.sh",
                    "--delay",
                    seconds.toString()
                ]
                if (!useSatty) args.push("--no-satty")
                if (!playSound) args.push("--no-sound")
                args.push(targetMode)
                Quickshell.execDetached(args)
            }
        }
    }

    // ── KEYBOARD SHORTCUTS & IPC ─────────────────────────────────────────────
    Shortcut {
        sequence: "Escape"
        onActivated: root.closeWindow()
    }

    IpcHandler {
        target: "screenshot"
        function close() {
            root.closeWindow()
        }
        function toggle() {
            root.closeWindow()
        }
    }

    // Forward key events to ScreenshotView
    Item {
        focus: true
        Keys.onPressed: function(event) {
            if (screenshotView && typeof screenshotView.handleKey === "function") {
                if (screenshotView.handleKey(event)) {
                    event.accepted = true
                }
            }
        }
    }
}
