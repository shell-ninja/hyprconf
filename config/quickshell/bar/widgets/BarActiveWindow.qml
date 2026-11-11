import QtQuick
import QtQuick.Layouts
import Quickshell
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

    readonly property var activeTl: Hyprland.activeToplevel
    readonly property string windowTitle: (activeTl && activeTl.title) ? activeTl.title : ((activeTl && activeTl.lastIpcObject && activeTl.lastIpcObject.title) ? activeTl.lastIpcObject.title : "")
    readonly property string windowClass: (activeTl && activeTl.lastIpcObject && activeTl.lastIpcObject["class"]) ? activeTl.lastIpcObject["class"] : ""

    visible: true
    implicitWidth: rowContent.implicitWidth + hPad * 2

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() { Hyprland.refreshToplevels() }
        function onRawEvent(event) {
            if (event.name === "activewindow" || event.name === "activewindowv2" || event.name === "windowtitlev2" || event.name === "closewindow") {
                Hyprland.refreshToplevels()
            }
        }
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
