import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import ".."

Pill {
    id: rootPill
    clickable: false
    hPad: 8
    spacing: 6

    readonly property var settings: (typeof bar !== "undefined" && bar && bar.widgetSettings && bar.widgetSettings.active_window) ? bar.widgetSettings.active_window : ({})
    readonly property int maxChars: (settings.max_length !== undefined) ? Math.max(10, Math.min(60, parseInt(settings.max_length, 10))) : 28
    readonly property bool showIcon: settings.show_icon !== false
    readonly property string fallbackText: settings.fallback || "Desktop"

    property string windowTitle: ""
    property string windowClass: ""

    visible: true
    implicitWidth: rowContent.implicitWidth + hPad * 2

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() { if (!winProc.running) winProc.running = true }
        function onRawEvent(event) {
            if (event.name === "activewindow" || event.name === "openwindow" || event.name === "closewindow" || event.name === "workspace") {
                if (!winProc.running) winProc.running = true
            }
        }
    }

    Process {
        id: winProc
        command: ["sh", "-c", "hyprctl activewindow -j 2>/dev/null | python3 -c 'import sys, json; d=json.load(sys.stdin) if not sys.stdin.isatty() else {}; print(json.dumps({\"title\": d.get(\"title\", \"\"), \"class\": d.get(\"class\", \"\")}))'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0) {
                    try {
                        var d = JSON.parse(text.trim())
                        rootPill.windowTitle = d.title || ""
                        rootPill.windowClass = d.class || ""
                    } catch(e) {}
                }
            }
        }
    }

    Timer {
        interval: 800
        running: true
        repeat: true
        onTriggered: if (!winProc.running) winProc.running = true
    }

    RowLayout {
        id: rowContent
        spacing: 6
        Layout.alignment: Qt.AlignVCenter

        SvgIcon {
            visible: rootPill.showIcon
            name: rootPill.windowTitle.length > 0 ? "window" : "layout"
            size: 13
            color: Theme.accent
        }

        Text {
            Layout.maximumWidth: Math.max(80, rootPill.maxChars * 7.5)
            text: rootPill.windowTitle.length > 0 ? rootPill.windowTitle : rootPill.fallbackText
            color: rootPill.windowTitle.length > 0 ? Theme.foreground : Theme.alpha(Theme.foreground, 0.45)
            font.family: "Outfit"
            font.pixelSize: 11
            font.weight: Font.Medium
            elide: Text.ElideRight
        }
    }
}
