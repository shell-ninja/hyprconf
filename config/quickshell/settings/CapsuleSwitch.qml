import QtQuick
import QtQuick.Controls

Switch {
    id: switchControl
    implicitWidth: 46
    implicitHeight: 24

    indicator: Rectangle {
        implicitWidth: 46
        implicitHeight: 24
        radius: 12
        color: switchControl.checked ? Theme.accent : Theme.alpha(Theme.surface, 0.85)
        border.width: 1
        border.color: switchControl.checked ? Theme.accent : Theme.alpha(Theme.foreground, 0.20)
        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on border.color { ColorAnimation { duration: 160 } }

        Rectangle {
            width: 16
            height: 16
            radius: 8
            color: switchControl.checked ? Theme.on_primary : Theme.alpha(Theme.foreground, 0.85)
            anchors.verticalCenter: parent.verticalCenter
            x: switchControl.checked ? (parent.width - width - 4) : 4

            Behavior on x {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }
            Behavior on color { ColorAnimation { duration: 160 } }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.NoButton
    }
}
