import QtQuick
import ".."

Pill {
    id: rootPill
    clickable: true
    hPad: 8
    spacing: 5

    SvgIcon {
        name: "clipboard"
        size: 14
        color: rootPill.fgColor
    }

    Text {
        text: ((typeof bar !== "undefined" && bar) ? bar.clipCount : 0).toString()
        font.family: "Outfit"
        font.pixelSize: 11
        font.weight: Font.Bold
        color: rootPill.fgColor
    }
    onClicked: if (typeof bar !== "undefined" && bar) bar.toggleClipboard(rootPill)
}

