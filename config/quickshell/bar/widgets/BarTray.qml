import QtQuick
import ".."

Pill {
    id: rootPill
    clickable: true
    hPad: 7
    spacing: 5

    SvgIcon {
        name: "wifi"
        size: 14
        color: rootPill.fgColor
    }

    SvgIcon {
        name: "chevronDown"
        size: 12
        color: rootPill.fgColor
        rotation: (typeof bar !== "undefined" && bar && bar.trayPopShown) ? 180 : 0
        Behavior on rotation {
            NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
        }
    }

    Component.onCompleted: {
        if (typeof bar !== "undefined" && bar) bar.trayTrigger = rootPill
    }
    Component.onDestruction: {
        if (typeof bar !== "undefined" && bar && bar.trayTrigger === rootPill) bar.trayTrigger = null
    }

    onClicked: {
        if (typeof bar !== "undefined" && bar) bar.toggleTray()
    }
}

