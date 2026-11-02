import QtQuick
import ".."

Pill {
    id: rootPill
    clickable: true
    hPad: 8
    pillHeight: Math.max(22, (typeof bar !== "undefined" && bar && bar.barH) ? bar.barH - 8 : 28)
    pillRadius: pillHeight / 2
    customBg: hovered ? Theme.alpha(Theme.error, 0.20) : "transparent"

    SvgIcon {
        name: "power"
        size: 15
        color: rootPill.hovered ? Theme.error : Theme.alpha(Theme.foreground, 0.80)
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Component.onCompleted: {
        if (typeof bar !== "undefined" && bar) bar.powerTrigger = rootPill
    }
    Component.onDestruction: {
        if (typeof bar !== "undefined" && bar && bar.powerTrigger === rootPill) bar.powerTrigger = null
    }

    onClicked: {
        if (typeof bar !== "undefined" && bar) bar.togglePower()
    }
}
