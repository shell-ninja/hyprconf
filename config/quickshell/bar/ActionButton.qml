import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property bool active: false
    property bool vertical: true
    property bool confirm: false   // destructive: first click arms, second click fires
    property bool armed: false
    property int iconSize: 18
    signal clicked()

    implicitWidth: 72
    implicitHeight: vertical ? 64 : 40
    radius: 14

    color: root.armed ? Theme.alpha(Theme.error, 0.35)
        : (root.active ? Theme.alpha(Theme.accent, 0.35)
        : (mouse.containsMouse ? Theme.alpha(Theme.surface, 0.95)
        : Theme.alpha(Theme.surface, 0.70)))

    border.width: (root.armed || root.active || mouse.containsMouse) ? 1 : 0
    border.color: root.armed ? Theme.error
        : (root.active ? Theme.accent
        : (mouse.containsMouse ? Theme.alpha(Theme.accent, 0.45)
        : "transparent"))

    scale: mouse.containsMouse ? (mouse.pressed ? 0.94 : 1.05) : 1.0
    transformOrigin: Item.Center

    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on border.color { ColorAnimation { duration: 160 } }
    Behavior on scale {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutBack
            easing.overshoot: 1.35
        }
    }

    Timer { id: disarm; interval: 3000; onTriggered: root.armed = false }

    GridLayout {
        anchors.centerIn: parent
        columns: root.vertical ? 1 : 2
        rowSpacing: 5
        columnSpacing: 8

        SvgIcon {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            name: root.icon
            size: root.iconSize
            color: root.armed ? Theme.error : (root.active ? Theme.on_primary : Theme.foreground)
        }
        MonoText {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            visible: text !== ""
            text: root.armed ? "Confirm?" : root.label
            font.pixelSize: 11
            color: root.armed ? Theme.error : (root.active ? Theme.on_primary : Theme.foreground)
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.confirm && !root.armed) {
                root.armed = true
                disarm.restart()
            } else {
                root.armed = false
                root.clicked()
            }
        }
    }
}
