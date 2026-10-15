import QtQuick

Rectangle {
    id: root

    default property alias content: innerContent.data
    property string title: ""
    property string description: ""

    width: parent ? parent.width : 200
    implicitHeight: mainLayout.implicitHeight + 28
    height: implicitHeight
    radius: 14
    color: Theme.alpha(Theme.surface, 0.45)
    border.width: 1
    border.color: Theme.alpha(Theme.accent, 0.20)

    Column {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 12

        Column {
            width: parent.width
            spacing: 2
            visible: root.title.length > 0

            Text {
                text: root.title
                color: Theme.foreground
                font.family: "Outfit"
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }

            Text {
                text: root.description
                color: Theme.alpha(Theme.foreground, 0.60)
                font.family: "Outfit"
                font.pixelSize: 11
                visible: root.description.length > 0
            }
        }

        Column {
            id: innerContent
            width: parent.width
            spacing: 10
        }
    }
}
