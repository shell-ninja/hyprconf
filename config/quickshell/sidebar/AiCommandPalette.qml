import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

Item {
    id: root
    width: parent ? parent.width : 400
    implicitHeight: 28

    property var commands: []
    signal commandSelected(var cmdItem)

    ScrollView {
        id: chipScroll
        anchors.fill: parent
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff

        RowLayout {
            spacing: 6

            Repeater {
                model: root.commands
                delegate: Rectangle {
                    required property var modelData
                    height: 26
                    implicitWidth: cmdRow.implicitWidth + 16
                    radius: 6

                    color: chipMouse.containsMouse ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.70)
                    border.width: 1
                    border.color: chipMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.accent, 0.20)

                    RowLayout {
                        id: cmdRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: modelData.cmd
                            font.family: "JetBrainsMono Nerd Font, monospace"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Theme.accent
                        }

                        Text {
                            text: modelData.name || ""
                            font.family: "Outfit"
                            font.pixelSize: 10
                            color: Theme.alpha(Theme.foreground, 0.75)
                        }
                    }

                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.commandSelected(modelData)
                        }
                    }
                }
            }
        }
    }
}
