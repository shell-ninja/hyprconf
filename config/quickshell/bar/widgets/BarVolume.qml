import QtQuick
import QtQuick.Layouts
import ".."

Pill {
    id: rootPill
    clickable: true
    hPad: 8
    spacing: 6

    readonly property var settings: (typeof bar !== "undefined" && bar && bar.widgetSettings && bar.widgetSettings.volume) ? bar.widgetSettings.volume : ({})
    readonly property real scrollStep: (settings.scroll_step !== undefined) ? (Math.max(1, Math.min(15, parseInt(settings.scroll_step, 10))) / 100.0) : 0.05
    readonly property bool showPercent: settings.show_percent !== false
    readonly property bool showBar: settings.show_bar !== false
    readonly property bool showIcon: settings.show_icon !== false

    readonly property real vol: (typeof bar !== "undefined" && bar) ? bar.volume : 0.5
    readonly property bool isMuted: (typeof bar !== "undefined" && bar) ? bar.muted : false

    SvgIcon {
        visible: rootPill.showIcon
        name: rootPill.isMuted ? "volumeMute" : (rootPill.vol > 0.5 ? "volume" : "volume")
        size: 15
        color: rootPill.isMuted ? Theme.error : (rootPill.hovered ? Theme.accent : Theme.foreground)
        Behavior on color { ColorAnimation { duration: 140 } }
    }

    Text {
        visible: rootPill.showPercent
        text: rootPill.isMuted ? "MUTED" : Math.round(rootPill.vol * 100) + "%"
        color: rootPill.isMuted ? Theme.error : (rootPill.hovered ? Theme.accent : Theme.foreground)
        font.family: "Outfit"
        font.pixelSize: 11
        font.weight: Font.Bold
        Behavior on color { ColorAnimation { duration: 140 } }
    }

    // Mini Volume Level Bar
    Rectangle {
        visible: rootPill.showBar
        width: 28
        height: 3.5
        radius: 1.75
        color: Theme.alpha(Theme.foreground, 0.15)
        Layout.alignment: Qt.AlignVCenter

        Rectangle {
            width: parent.width * Math.max(0.0, Math.min(1.0, rootPill.vol))
            height: parent.height
            radius: 1.75
            color: rootPill.isMuted ? Theme.error : Theme.accent
        }
    }

    onWheelScrolled: function(wheel) {
        if (typeof bar !== "undefined" && bar) {
            var delta = wheel.angleDelta.y > 0 ? rootPill.scrollStep : -rootPill.scrollStep
            bar.setVolume(bar.volume + delta)
        }
    }

    WheelHandler {
        onWheel: function(e) {
            if (typeof bar !== "undefined" && bar) {
                var delta = e.angleDelta.y > 0 ? rootPill.scrollStep : -rootPill.scrollStep
                bar.setVolume(bar.volume + delta)
            }
        }
    }

    Component.onCompleted: {
        if (typeof bar !== "undefined" && bar) bar.volumeTrigger = rootPill
    }
    Component.onDestruction: {
        if (typeof bar !== "undefined" && bar && bar.volumeTrigger === rootPill) bar.volumeTrigger = null
    }

    onClicked: {
        if (typeof bar !== "undefined" && bar) bar.toggleVolume()
    }
}
