import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

Pill {
    id: rootPill
    hPad: 4
    spacing: 3
    clickable: false

    // Game Mode
    Rectangle {
        id: gameModeBtn
        implicitWidth: 26
        implicitHeight: 26
        radius: 13
        color: (typeof bar !== "undefined" && bar && bar.gameModeActive)
               ? Theme.accent
               : (gameMouse.containsMouse ? Theme.alpha(Theme.accent, 0.18) : "transparent")
        scale: gameMouse.containsMouse ? (gameMouse.pressed ? 0.90 : 1.12) : 1.0
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }

        SvgIcon {
            anchors.centerIn: parent
            name: "zap"
            size: 13
            color: (typeof bar !== "undefined" && bar && bar.gameModeActive)
                   ? Theme.background
                   : (gameMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.75))
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        MouseArea {
            id: gameMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (typeof bar !== "undefined" && bar) bar.toggleGameMode()
        }
    }

    // Caffeine
    Rectangle {
        id: caffeineBtn
        implicitWidth: 26
        implicitHeight: 26
        radius: 13
        color: (typeof bar !== "undefined" && bar && bar.caffeine)
               ? Theme.accent
               : (caffeineMouse.containsMouse ? Theme.alpha(Theme.accent, 0.18) : "transparent")
        scale: caffeineMouse.containsMouse ? (caffeineMouse.pressed ? 0.90 : 1.12) : 1.0
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }

        SvgIcon {
            anchors.centerIn: parent
            name: "coffee"
            size: 13
            color: (typeof bar !== "undefined" && bar && bar.caffeine)
                   ? Theme.background
                   : (caffeineMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.75))
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        MouseArea {
            id: caffeineMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (typeof bar !== "undefined" && bar) bar.toggleCaffeine()
        }
    }

    // Night Light
    Rectangle {
        id: nightLightBtn
        implicitWidth: 26
        implicitHeight: 26
        radius: 13
        color: (typeof bar !== "undefined" && bar && bar.nightLight)
               ? Theme.accent
               : (nightLightMouse.containsMouse ? Theme.alpha(Theme.accent, 0.18) : "transparent")
        scale: nightLightMouse.containsMouse ? (nightLightMouse.pressed ? 0.90 : 1.12) : 1.0
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }

        SvgIcon {
            anchors.centerIn: parent
            name: "moonStar"
            size: 13
            color: (typeof bar !== "undefined" && bar && bar.nightLight)
                   ? Theme.background
                   : (nightLightMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.75))
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        MouseArea {
            id: nightLightMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (typeof bar !== "undefined" && bar) bar.toggleNightLight()
        }
    }

    // Clipboard
    Rectangle {
        id: clipBtn
        implicitWidth: clipRow.implicitWidth + 10
        implicitHeight: 26
        radius: 13
        color: clipMouse.containsMouse ? Theme.alpha(Theme.accent, 0.18) : "transparent"
        scale: clipMouse.containsMouse ? (clipMouse.pressed ? 0.90 : 1.10) : 1.0
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }

        RowLayout {
            id: clipRow
            anchors.centerIn: parent
            spacing: 4

            SvgIcon {
                name: "clipboard"
                size: 13
                color: clipMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.75)
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Text {
                text: ((typeof bar !== "undefined" && bar) ? bar.clipCount : 0).toString()
                font.family: "Outfit"
                font.pixelSize: 10
                font.weight: Font.Bold
                color: clipMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.65)
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
        MouseArea {
            id: clipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (typeof bar !== "undefined" && bar) bar.toggleClipboard(clipBtn)
        }
    }

    Component.onCompleted: {
        if (typeof bar !== "undefined" && bar) bar.togglesTrigger = rootPill
    }
    Component.onDestruction: {
        if (typeof bar !== "undefined" && bar && bar.togglesTrigger === rootPill) bar.togglesTrigger = null
    }
}
