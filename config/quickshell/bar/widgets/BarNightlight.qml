import QtQuick
import ".."

Pill {
    id: rootPill
    clickable: true
    hPad: 10
    SvgIcon {
        name: "moonStar"
        size: 15
        color: (typeof bar !== "undefined" && bar && bar.nightLight) ? Theme.accent : rootPill.fgColor
    }
    onClicked: if (typeof bar !== "undefined" && bar) bar.toggleNightLight()
}

