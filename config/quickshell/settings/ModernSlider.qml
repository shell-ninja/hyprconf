import QtQuick
import QtQuick.Controls

Slider {
    id: sliderControl
    implicitHeight: 32

    background: Rectangle {
        x: sliderControl.leftPadding
        y: sliderControl.topPadding + sliderControl.availableHeight / 2 - height / 2
        implicitWidth: 200
        implicitHeight: 8
        width: sliderControl.availableWidth
        height: implicitHeight
        radius: 4
        color: Theme.alpha(Theme.surface, 0.90)
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.25)

        Rectangle {
            width: sliderControl.visualPosition * parent.width
            height: parent.height
            color: Theme.accent
            radius: 4
        }
    }

    handle: Rectangle {
        x: sliderControl.leftPadding + sliderControl.visualPosition * (sliderControl.availableWidth - width)
        y: sliderControl.topPadding + sliderControl.availableHeight / 2 - height / 2
        implicitWidth: 20
        implicitHeight: 20
        radius: 10
        color: sliderControl.pressed ? Theme.primary : Theme.accent
        border.width: 2
        border.color: Theme.on_primary

        scale: sliderControl.pressed ? 1.15 : (sliderControl.hovered ? 1.08 : 1.0)
        Behavior on scale { NumberAnimation { duration: 100 } }
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.NoButton
    }
}
