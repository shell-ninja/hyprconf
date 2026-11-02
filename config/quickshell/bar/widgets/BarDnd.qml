import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Pill {
    id: rootPill
    clickable: true
    hPad: 8
    spacing: 5

    readonly property var settings: (typeof bar !== "undefined" && bar && bar.widgetSettings && bar.widgetSettings.dnd) ? bar.widgetSettings.dnd : ({})
    readonly property string labelMode: settings.label_mode || "full" // "full" | "compact" | "icon_only"
    readonly property bool showIcon: settings.show_icon !== false

    property bool dndActive: false

    Process {
        id: dndLoader
        command: ["python3", "-c", "import json, os; p=os.path.expanduser('~/.hyprconf/hypr/.cache/dnd_state.json'); print('true' if os.path.exists(p) and json.load(open(p)).get('dnd') else 'false')"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0) {
                    rootPill.dndActive = (text.trim() === "true")
                }
            }
        }
    }

    RowLayout {
        spacing: 5
        Layout.alignment: Qt.AlignVCenter

        SvgIcon {
            visible: rootPill.showIcon
            name: rootPill.dndActive ? "dnd" : "bell"
            size: 14
            color: rootPill.dndActive ? Theme.accent : (rootPill.hovered ? Theme.accent : Theme.alpha(Theme.foreground, 0.60))
            Behavior on color { ColorAnimation { duration: 140 } }
        }

        Text {
            visible: rootPill.labelMode !== "icon_only"
            text: {
                if (rootPill.labelMode === "compact") {
                    return rootPill.dndActive ? "ON" : "OFF"
                }
                return rootPill.dndActive ? "DND ON" : "DND"
            }
            color: rootPill.dndActive ? Theme.accent : (rootPill.hovered ? Theme.accent : Theme.alpha(Theme.foreground, 0.60))
            font.family: "Outfit"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            Behavior on color { ColorAnimation { duration: 140 } }
        }
    }

    onClicked: {
        rootPill.dndActive = !rootPill.dndActive
        var pyCmd = "import json, os; p=os.path.expanduser('~/.hyprconf/hypr/.cache/dnd_state.json'); os.makedirs(os.path.dirname(p), exist_ok=True); json.dump({'dnd': " + (rootPill.dndActive ? "True" : "False") + "}, open(p, 'w'))"
        Quickshell.execDetached(["python3", "-c", pyCmd])
        Quickshell.execDetached(["qs-settings.sh", "--dnd", rootPill.dndActive ? "1" : "0"])
        if (typeof osd !== "undefined" && osd) {
            osd.show("caffeine", rootPill.dndActive ? "1" : "0", rootPill.dndActive ? "DND Active" : "DND Disabled", "bell", rootPill.dndActive ? "Notification toasts silenced" : "Notifications enabled")
        }
    }
}
