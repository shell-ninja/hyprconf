import QtQuick
import ".."

Pill {
    id: rootPill
    clickable: true
    hPad: 8
    pillHeight: Math.max(22, (typeof bar !== "undefined" && bar && bar.barH) ? bar.barH - 8 : 28)
    pillRadius: pillHeight / 2
    customBg: (hovered || (typeof bar !== "undefined" && bar && bar.rightPowerMenuShown)) ? Theme.alpha(Theme.error, 0.20) : "transparent"

    SvgIcon {
        name: "power"
        size: 15
        color: (rootPill.hovered || (typeof bar !== "undefined" && bar && bar.rightPowerMenuShown)) ? Theme.error : Theme.alpha(Theme.foreground, 0.80)
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Component.onCompleted: {
        if (typeof bar !== "undefined" && bar) bar.powerTrigger = rootPill
    }
    Component.onDestruction: {
        if (typeof bar !== "undefined" && bar && bar.powerTrigger === rootPill) bar.powerTrigger = null
    }

    onHoveredChanged: {
        if (hovered && typeof bar !== "undefined" && bar) bar.openPowerFromHover()
    }

    onClicked: {
        if (typeof bar !== "undefined" && bar) bar.togglePower()
    }
}
