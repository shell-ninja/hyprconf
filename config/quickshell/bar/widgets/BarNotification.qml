import QtQuick
import QtQuick.Layouts
import ".."

Pill {
    id: rootPill
    clickable: true
    hPad: 8
    spacing: 5

    readonly property int notifCount: (typeof bar !== "undefined" && bar) ? bar.notifCount : 0

    SvgIcon {
        name: "bell"
        size: 15
        color: (rootPill.notifCount > 0) ? Theme.accent : (rootPill.hovered ? Theme.accent : Theme.foreground)
        Behavior on color { ColorAnimation { duration: 140 } }
    }

    // Glowing unread badge
    Rectangle {
        visible: rootPill.notifCount > 0
        implicitWidth: Math.max(16, badgeText.implicitWidth + 8)
        implicitHeight: 16
        radius: 8
        color: Theme.accent
        Layout.alignment: Qt.AlignVCenter

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: rootPill.notifCount.toString()
            font.family: "Outfit"
            font.pixelSize: 10
            font.weight: Font.Bold
            color: Theme.background
        }
    }

    Component.onCompleted: {
        if (typeof bar !== "undefined" && bar) bar.notifTrigger = rootPill
    }
    Component.onDestruction: {
        if (typeof bar !== "undefined" && bar && bar.notifTrigger === rootPill) bar.notifTrigger = null
    }

    onClicked: {
        if (typeof bar !== "undefined" && bar) bar.toggleNotif()
    }
}
