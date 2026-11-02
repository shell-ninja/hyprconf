import QtQuick
import ".."

Pill {
    id: rootPill
    clickable: true
    hPad: 10
    SvgIcon {
        name: "coffee"
        size: 15
        color: (typeof bar !== "undefined" && bar && bar.caffeine) ? Theme.accent : rootPill.fgColor
    }
    onClicked: if (typeof bar !== "undefined" && bar) bar.toggleCaffeine()
}

