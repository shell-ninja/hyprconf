import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

Pill {
    id: rootPill
    clickable: true
    hPad: 8
    spacing: 5

    readonly property var settings: (typeof bar !== "undefined" && bar && bar.widgetSettings && bar.widgetSettings.pkg_update) ? bar.widgetSettings.pkg_update : ({})
    readonly property int count: (typeof bar !== "undefined" && bar) ? bar.pkgCount : 0
    readonly property bool hideEmpty: (settings.hide_when_zero !== undefined) ? !!settings.hide_when_zero : ((typeof bar !== "undefined" && bar) ? bar.hidePkgWhenEmpty : false)

    visible: !(hideEmpty && count === 0)

    SvgIcon {
        name: "package"
        size: 15
        color: rootPill.count > 0 ? Theme.accent : (rootPill.hovered ? Theme.accent : Theme.alpha(Theme.foreground, 0.70))
        Behavior on color { ColorAnimation { duration: 140 } }
    }

    Text {
        text: rootPill.count.toString()
        color: rootPill.count > 0 ? Theme.accent : (rootPill.hovered ? Theme.accent : Theme.alpha(Theme.foreground, 0.70))
        font.family: "Outfit"
        font.pixelSize: 11
        font.weight: Font.Bold
        Behavior on color { ColorAnimation { duration: 140 } }
    }

    Component.onCompleted: {
        if (typeof bar !== "undefined" && bar) bar.pkgTrigger = rootPill
    }
    Component.onDestruction: {
        if (typeof bar !== "undefined" && bar && bar.pkgTrigger === rootPill) bar.pkgTrigger = null
    }

    onClicked: {
        if (typeof bar !== "undefined" && bar) bar.togglePkg()
    }
}
