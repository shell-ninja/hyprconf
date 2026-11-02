import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "."

Item {
    id: root
    width: parent ? parent.width : 400
    implicitHeight: cardRect.implicitHeight + 8

    property string role: "assistant" // "user" | "assistant" | "system" | "command"
    property string content: ""
    property string engineName: "OpenCode"
    property string timestamp: ""
    property bool isStreaming: false
    property bool isError: false
    property bool isCopied: false

    function svgUrl(svgString) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgString)
    }

    readonly property string userSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>')
    readonly property string terminalSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg>')
    readonly property string copySvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.alpha(Theme.foreground, 0.6) + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>')
    readonly property string checkSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>')

    Timer {
        id: copyTimer
        interval: 1600
        repeat: false
        onTriggered: root.isCopied = false
    }

    Rectangle {
        id: cardRect
        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: mainCol.implicitHeight + 20
        radius: 8

        color: {
            if (root.role === "user") return Theme.alpha(Theme.surface, 0.60)
            if (root.isError) return Theme.alpha(Theme.error, 0.10)
            if (root.role === "command") return Theme.alpha(Theme.accent, 0.10)
            return Theme.alpha(Theme.background, 0.70)
        }

        border.width: 1
        border.color: {
            if (root.role === "user") return Theme.alpha(Theme.foreground, 0.12)
            if (root.isError) return Theme.alpha(Theme.error, 0.35)
            if (root.role === "command") return Theme.alpha(Theme.accent, 0.35)
            return Theme.alpha(Theme.accent, 0.22)
        }

        ColumnLayout {
            id: mainCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 8

            // Header Row: Badge, Sender, Streaming Indicator, Timestamp, Copy Button
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Terminal / User Avatar
                Rectangle {
                    width: 22; height: 22; radius: 5
                    color: root.role === "user" ? Theme.alpha(Theme.foreground, 0.10) : Theme.alpha(Theme.accent, 0.18)
                    border.width: 1
                    border.color: root.role === "user" ? Theme.alpha(Theme.foreground, 0.20) : Theme.accent

                    Image {
                        anchors.centerIn: parent
                        width: 12; height: 12
                        source: root.role === "user" ? root.userSvg : root.terminalSvg
                    }
                }

                // Sender Label
                Text {
                    text: root.role === "user" ? "USER" : (root.role === "command" ? "COMMAND" : root.engineName.toUpperCase())
                    font.family: "JetBrainsMono Nerd Font, monospace"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: root.role === "user" ? Theme.foreground : Theme.accent
                }

                // Streaming Dot & Text
                Rectangle {
                    visible: root.isStreaming
                    width: 6; height: 6; radius: 3
                    color: Theme.accent

                    SequentialAnimation on opacity {
                        running: root.isStreaming
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.2; to: 1.0; duration: 380; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 1.0; to: 0.2; duration: 380; easing.type: Easing.InOutQuad }
                    }
                }

                Text {
                    visible: root.isStreaming
                    text: "running..."
                    font.family: "JetBrainsMono Nerd Font, monospace"
                    font.pixelSize: 10
                    color: Theme.alpha(Theme.foreground, 0.45)
                }

                Item { Layout.fillWidth: true }

                // Timestamp
                Text {
                    visible: root.timestamp.length > 0
                    text: root.timestamp
                    font.family: "JetBrainsMono Nerd Font, monospace"
                    font.pixelSize: 10
                    color: Theme.alpha(Theme.foreground, 0.40)
                }

                // Copy Button
                Rectangle {
                    width: 22; height: 22; radius: 4
                    color: copyMouse.containsMouse ? Theme.alpha(Theme.accent, 0.20) : "transparent"
                    border.width: 1
                    border.color: copyMouse.containsMouse ? Theme.accent : "transparent"

                    Image {
                        anchors.centerIn: parent
                        width: 12; height: 12
                        source: root.isCopied ? root.checkSvg : root.copySvg
                    }

                    MouseArea {
                        id: copyMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["wl-copy", root.content])
                            root.isCopied = true
                            copyTimer.restart()
                        }
                    }
                }
            }

            // Message Body: Monospace Text
            TextEdit {
                Layout.fillWidth: true
                text: root.content + (root.isStreaming ? " ▮" : "")
                readOnly: true
                selectByMouse: true
                wrapMode: TextEdit.Wrap
                color: root.isError ? Theme.error : Theme.foreground
                font.family: "JetBrainsMono Nerd Font, monospace"
                font.pixelSize: 12
                selectedTextColor: Theme.on_primary
                selectionColor: Theme.accent
            }
        }
    }
}
