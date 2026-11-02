import QtQuick
import Quickshell
import ".."

Pill {
    id: rootPill
    clickable: true
    hPad: 8
    pillHeight: Math.max(22, (typeof bar !== "undefined" && bar && bar.barH) ? bar.barH - 8 : 28)
    pillRadius: pillHeight / 2
    customBg: hovered ? Theme.alpha(Theme.accent, 0.20) : "transparent"

    SvgIcon {
        name: "grid"
        size: 16
        color: rootPill.hovered ? Theme.accent : Theme.foreground
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    onClicked: {
        Quickshell.execDetached([bar.homeDir + "/.hyprconf/hypr/scripts/sh/qs-launcher.sh"])
    }
}
