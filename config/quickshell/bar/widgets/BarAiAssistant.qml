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

    property bool isBusy: false

    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: {
            if (!checkProc.running) checkProc.running = true
        }
    }

    Process {
        id: checkProc
        command: ["sh", "-c", "qs ipc -c sidebar call sidebar isBusy 2>/dev/null || echo false"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0) {
                    rootPill.isBusy = (text.trim() === "true")
                }
            }
        }
    }

    RowLayout {
        spacing: 5
        Layout.alignment: Qt.AlignVCenter

        SvgIcon {
            name: "terminal"
            size: 14
            color: rootPill.isBusy ? Theme.accent : (rootPill.hovered ? Theme.accent : Theme.foreground)
            Behavior on color { ColorAnimation { duration: 140 } }
        }

        Text {
            text: rootPill.isBusy ? "BUSY" : "AGENT"
            color: rootPill.isBusy ? Theme.accent : (rootPill.hovered ? Theme.accent : Theme.foreground)
            font.family: "JetBrainsMono Nerd Font, monospace"
            font.pixelSize: 10
            font.weight: Font.Bold
            Behavior on color { ColorAnimation { duration: 140 } }
        }

        Rectangle {
            visible: rootPill.isBusy
            width: 6; height: 6; radius: 3
            color: Theme.accent
            SequentialAnimation on opacity {
                running: rootPill.isBusy
                loops: Animation.Infinite
                NumberAnimation { from: 0.2; to: 1.0; duration: 400 }
                NumberAnimation { from: 1.0; to: 0.2; duration: 400 }
            }
        }
    }

    onClicked: {
        var h = Quickshell.env("HOME") || "/home"
        Quickshell.execDetached([h + "/.hyprconf/hypr/scripts/sh/qs-sidebar.sh", "--toggle"])
    }
}
