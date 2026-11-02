import QtQuick
import ".."

Pill {
    id: rootPill
    clickable: true
    hPad: 10

    SvgIcon {
        name: (typeof bar !== "undefined" && bar) ? (bar.profile === 0 ? "bolt" : (bar.profile === 2 ? "leaf" : "gauge")) : "gauge"
        size: 15
        color: {
            if (typeof bar !== "undefined" && bar) {
                if (bar.profile === 0) return Theme.accent
                if (bar.profile === 2) return Theme.secondary
            }
            return rootPill.hovered ? Theme.accent : Theme.foreground
        }
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Component.onCompleted: {
        if (typeof bar !== "undefined" && bar) bar.perfTrigger = rootPill
    }
    Component.onDestruction: {
        if (typeof bar !== "undefined" && bar && bar.perfTrigger === rootPill) bar.perfTrigger = null
    }

    onClicked: {
        if (typeof bar !== "undefined" && bar) bar.cycleProfile()
    }
}

