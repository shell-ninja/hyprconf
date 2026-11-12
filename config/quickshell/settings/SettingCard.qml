import QtQuick

Rectangle {
    id: root

    default property alias content: innerContent.data
    property string title: ""
    property string description: ""

    width: parent ? parent.width : 200
    implicitHeight: mainLayout.implicitHeight + 28
    height: implicitHeight
    radius: 15
    clip: true
    color: Theme.glassCard
    border.width: 1
    border.color: Theme.alpha(Theme.foreground, 0.11)

    // Specular top rim hairline
    Rectangle {
        z: 2
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.25; color: Theme.glassRimTop }
            GradientStop { position: 0.5; color: Theme.alpha("#ffffff", 0.28) }
            GradientStop { position: 0.75; color: Theme.glassRimTop }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

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
