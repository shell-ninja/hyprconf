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
    WlrLayershell.namespace: "quickshell-wallpaper"

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
            duration: 280
            easing.type: Easing.OutBack
            easing.overshoot: 1.25
        }
        NumberAnimation {
            target: root
            property: "animOpacity"
            from: 0.0
            to: 1.0
            duration: 200
            easing.type: Easing.OutQuad
        }
    }

    ParallelAnimation {
        id: closeAnim
        NumberAnimation {
            target: root
            property: "animScale"
            to: 0.88
            duration: 180
            easing.type: Easing.InBack
            easing.overshoot: 1.10
        }
        NumberAnimation {
            target: root
            property: "animOpacity"
            to: 0.0
            duration: 160
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

    // Transparent click-outside-to-dismiss area (leaves desktop completely unblurred)
    MouseArea {
        anchors.fill: parent
        onClicked: root.closeWindow()
    }

    // ── CENTERED OBSIDIAN GLASS WALLPAPER CONTAINER ──────────────────────────
    Item {
        id: modalContainer
        anchors.centerIn: parent
        width: 980
        height: 420
        scale: root.animScale
        opacity: root.animOpacity
        transformOrigin: Item.Center

        // Prevent click-through from closing when clicking inside
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
        }

        WallpaperView {
            id: wallpaperView
            anchors.fill: parent
            active: true
            animProgress: 1.0
            onBackClicked: root.closeWindow()
        }
    }

    // ── KEYBOARD SHORTCUTS & IPC ─────────────────────────────────────────────
    Shortcut {
        sequence: "Escape"
        onActivated: root.closeWindow()
    }

    Shortcut {
        sequence: "Ctrl+L"
        onActivated: {
            if (wallpaperView && typeof wallpaperView.focusSearch === "function") {
                wallpaperView.focusSearch()
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+F"
        onActivated: {
            if (wallpaperView && typeof wallpaperView.focusSearch === "function") {
                wallpaperView.focusSearch()
            }
        }
    }

    IpcHandler {
        target: "wallpaper"
        function close() {
            root.closeWindow()
        }
        function toggle() {
            root.closeWindow()
        }
    }

    Timer {
        id: initFocusTimer
        interval: 100
        running: true
        repeat: false
        onTriggered: {
            if (wallpaperView && typeof wallpaperView.focusWallpaper === "function") {
                wallpaperView.focusWallpaper()
            }
        }
    }
}
