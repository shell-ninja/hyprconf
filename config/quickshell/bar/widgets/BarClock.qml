import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

Pill {
    id: rootPill
    clickable: true
    hPad: 10
    spacing: 7

    readonly property var settings: (typeof bar !== "undefined" && bar && bar.widgetSettings && bar.widgetSettings.clock) ? bar.widgetSettings.clock : ({})
    readonly property bool format24h: !!settings.format_24h
    readonly property bool showSeconds: !!settings.show_seconds
    readonly property bool showDate: (settings.show_date !== undefined) ? !!settings.show_date : true

    SystemClock {
        id: sysClock
        precision: rootPill.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    function formatTime(d) {
        if (!d) return ""
        if (rootPill.format24h) {
            return Qt.formatDateTime(d, rootPill.showSeconds ? "HH:mm:ss" : "HH:mm")
        }
        var h = d.getHours() % 12 || 12
        var hStr = (h < 10 ? "0" : "") + h
        var m = d.getMinutes()
        var mStr = (m < 10 ? "0" : "") + m
        if (rootPill.showSeconds) {
            var s = d.getSeconds()
            var sStr = (s < 10 ? "0" : "") + s
            return hStr + ":" + mStr + ":" + sStr
        }
        return hStr + ":" + mStr
    }

    RowLayout {
        spacing: 5
        Layout.alignment: Qt.AlignVCenter

        // Time
        Text {
            text: rootPill.formatTime(sysClock.date)
            font.family: "Outfit"
            font.pixelSize: 13
            font.weight: Font.Bold
            color: Theme.foreground
        }

        // AM/PM badge
        Text {
            visible: !rootPill.format24h
            text: sysClock.date ? (sysClock.date.getHours() >= 12 ? "PM" : "AM") : ""
            font.family: "Outfit"
            font.pixelSize: 10
            font.weight: Font.Bold
            color: Theme.accent
        }

        // Subtle pulsing second indicator dot
        Rectangle {
            visible: rootPill.showDate
            width: 3
            height: 3
            radius: 1.5
            color: Theme.accent
            opacity: 0.8
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 2
            Layout.rightMargin: 2

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 1000; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 0.9; duration: 1000; easing.type: Easing.InOutQuad }
            }
        }

        // Date chip
        Text {
            visible: rootPill.showDate
            text: Qt.formatDateTime(sysClock.date, "ddd, MMM d")
            font.family: "Outfit"
            font.pixelSize: 11
            font.weight: Font.Medium
            color: rootPill.hovered ? Theme.accent : Theme.alpha(Theme.foreground, 0.70)
            Behavior on color { ColorAnimation { duration: 140 } }
        }
    }

    Component.onCompleted: {
        if (typeof bar !== "undefined" && bar) bar.clockTrigger = rootPill
    }
    Component.onDestruction: {
        if (typeof bar !== "undefined" && bar && bar.clockTrigger === rootPill) bar.clockTrigger = null
    }

    onClicked: {
        if (typeof bar !== "undefined" && bar) bar.toggleClock()
    }
}
