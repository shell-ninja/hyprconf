import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "."

PanelWindow {
    id: rootWindow

    anchors {
        left: true
        top: true
        bottom: true
    }

    // Exactly 40% of Screen Width as requested
    implicitWidth: Math.round((screen ? screen.width : 1920) * 0.40)
    implicitHeight: screen ? screen.height : 1080
    color: "transparent"

    // Wayland Layer Shell Configuration
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: sidebarView.shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Precise Wayland input mask: clicks pass through when closed
    mask: Region {
        item: sidebarView.shown ? sidebarView : null
    }

    SidebarView {
        id: sidebarView
    }

    IpcHandler {
        target: "sidebar"

        function ping() {
            return "pong"
        }

        function toggle() {
            sidebarView.toggleShown()
        }

        function openSidebar() {
            sidebarView.shown = true
        }

        function closeSidebar() {
            if (sidebarView.isBusy) {
                sidebarView.shown = false
                var h = Quickshell.env("HOME") || "/home"
                Quickshell.execDetached([h + "/.hyprconf/hypr/scripts/sh/osd-notify.sh", "terminal", "1", "Agent Console", "terminal", "Task continuing in background • Super+A to view"])
            } else {
                sidebarView.shown = false
            }
        }

        function isBusy() {
            return sidebarView.isBusy
        }

        function isShown() {
            return sidebarView.shown
        }

        function getMetrics() {
            var msg = "METRICS: x=" + sidebarView.x + " y=" + sidebarView.y + " w=" + sidebarView.width + " h=" + sidebarView.height + " parentH=" + (sidebarView.parent ? sidebarView.parent.height : -1) + " parentW=" + (sidebarView.parent ? sidebarView.parent.width : -1)
            console.log(msg)
            return msg
        }

        function getLastMessage() {
            var h = sidebarView.chatHistory
            if (h && h.length > 0) {
                var last = h[h.length - 1]
                return JSON.stringify(last)
            }
            return ""
        }

        function runTestCommand(cmd: string) {
            sidebarView.executePrompt(cmd)
        }

        function setInputText(str: string) {
            sidebarView.setInputText(str)
        }
    }
}
