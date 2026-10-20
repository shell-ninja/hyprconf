import QtQuick
import QtQuick.Controls

Item {
    id: root

    property var model: []
    property string currentValue: ""
    property string placeholder: "Select..."
    signal selected(string value, int index)

    implicitWidth: 180
    implicitHeight: 34

    property real lastCloseTime: 0

    Rectangle {
        id: buttonBox
        anchors.fill: parent
        radius: 8
        color: btnMouse.containsMouse ? Theme.alpha(Theme.surface, 0.85) : Theme.alpha(Theme.surface, 0.55)
        border.width: 1
        border.color: popup.visible ? Theme.accent : Theme.alpha(Theme.accent, 0.25)

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: arrowText.left
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            text: root.currentValue ? root.currentValue : root.placeholder
            color: root.currentValue ? Theme.foreground : Theme.alpha(Theme.foreground, 0.45)
            font.family: "Outfit"
            font.pixelSize: 11
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        Text {
            id: arrowText
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: popup.visible ? "▲" : "▼"
            color: Theme.accent
            font.pixelSize: 9
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                var elapsed = Date.now() - root.lastCloseTime
                if (popup.visible) {
                    popup.close()
                } else if (elapsed > 200) {
                    popup.open()
                }
            }
        }
    }

    Popup {
        id: popup
        y: root.height + 4
        width: Math.max(root.width, 160)
        implicitHeight: Math.min(220, listCol.implicitHeight + 16)
        padding: 4
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        onAboutToHide: root.lastCloseTime = Date.now()
        onClosed: root.lastCloseTime = Date.now()

        background: Rectangle {
            radius: 10
            color: Theme.alpha(Theme.surface, 0.96)
            border.width: 1
            border.color: Theme.alpha(Theme.accent, 0.40)
        }

        contentItem: ScrollView {
            clip: true
            contentWidth: availableWidth

            Column {
                id: listCol
                width: parent.width
                spacing: 2

                Repeater {
                    model: root.model

                    Rectangle {
                        width: parent.width
                        height: 30
                        radius: 6
                        readonly property string itemText: (typeof modelData === "object" && modelData.text !== undefined) ? modelData.text : String(modelData)
                        readonly property string itemVal: (typeof modelData === "object" && modelData.value !== undefined) ? modelData.value : String(modelData)
                        readonly property bool isCurrent: root.currentValue === itemVal

                        color: isCurrent
                            ? Theme.alpha(Theme.accent, 0.30)
                            : (itemMouse.containsMouse ? Theme.alpha(Theme.surface, 0.70) : "transparent")

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.itemText
                            color: parent.isCurrent ? Theme.accent : Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 12
                            font.weight: parent.isCurrent ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.currentValue = parent.itemVal
                                root.selected(parent.itemVal, index)
                                popup.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
