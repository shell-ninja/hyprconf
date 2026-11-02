import QtQuick
import QtQuick.Layouts
import ".."

Pill {
    id: rootPill
    clickable: true
    hPad: 8
    spacing: 6

    readonly property var settings: (typeof bar !== "undefined" && bar && bar.widgetSettings && bar.widgetSettings.weather) ? bar.widgetSettings.weather : ({})
    readonly property bool unitF: !!settings.unit_f
    readonly property bool showCondAlways: !!settings.show_condition_always
    readonly property bool showIcon: settings.show_icon !== false

    readonly property string iconName: (typeof bar !== "undefined" && bar && bar.weatherIconName) ? bar.weatherIconName : "moon"
    readonly property string rawTemp: (typeof bar !== "undefined" && bar && bar.weatherTemp) ? bar.weatherTemp : "24"
    readonly property string condStr: (typeof bar !== "undefined" && bar && bar.weatherCond) ? bar.weatherCond : "Clear"

    readonly property string displayTemp: {
        var t = parseFloat(rootPill.rawTemp)
        if (isNaN(t)) return rootPill.rawTemp || "24"
        if (rootPill.unitF) {
            return Math.round((t * 9.0 / 5.0) + 32.0).toString()
        }
        return Math.round(t).toString()
    }

    SvgIcon {
        visible: rootPill.showIcon
        name: rootPill.iconName
        size: 15
        color: (rootPill.iconName === "sun") ? "#f5a97f" : (rootPill.hovered ? Theme.accent : Theme.foreground)
        Behavior on color { ColorAnimation { duration: 140 } }
    }

    Text {
        text: rootPill.displayTemp + "°" + (rootPill.unitF ? "F" : "")
        color: rootPill.hovered ? Theme.accent : Theme.foreground
        font.family: "Outfit"
        font.pixelSize: 12
        font.weight: Font.Bold
        Behavior on color { ColorAnimation { duration: 140 } }
    }

    Item {
        id: condContainer
        implicitWidth: ((rootPill.hovered || rootPill.showCondAlways) && rootPill.condStr.length > 0) ? (condText.implicitWidth + 4) : 0
        implicitHeight: condText.implicitHeight
        opacity: ((rootPill.hovered || rootPill.showCondAlways) && rootPill.condStr.length > 0) ? 1.0 : 0.0
        clip: true
        Layout.alignment: Qt.AlignVCenter

        Behavior on implicitWidth {
            NumberAnimation {
                duration: 240
                easing.type: Easing.OutBack
                easing.overshoot: 1.15
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutQuad
            }
        }

        Text {
            id: condText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: rootPill.condStr
            color: Theme.alpha(Theme.foreground, 0.75)
            font.family: "Outfit"
            font.pixelSize: 11
            font.weight: Font.Medium
        }
    }

    Component.onCompleted: {
        if (typeof bar !== "undefined" && bar) bar.weatherTrigger = rootPill
    }
    Component.onDestruction: {
        if (typeof bar !== "undefined" && bar && bar.weatherTrigger === rootPill) bar.weatherTrigger = null
    }

    onClicked: {
        if (typeof bar !== "undefined" && bar) bar.toggleWeather()
    }
}
