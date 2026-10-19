import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root

    property bool active: false
    property bool isClosing: false
    property real animProgress: 1.0
    property var flow: null

    signal closeRequested()

    readonly property bool isIslandView: true
    readonly property real preferredWidth: 520
    readonly property real preferredHeight: 370
    implicitWidth: preferredWidth
    implicitHeight: preferredHeight

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : "/home/shell-ninja"
    }

    readonly property string avatarPath: "file://" + homeDir + "/.hyprconf/hypr/.cache/.face"

    // Focus password field on active
    onActiveChanged: {
        if (active) {
            passwordInput.text = ""
            focusTimer.restart()
        }
    }

    Timer {
        id: focusTimer
        interval: 100
        repeat: false
        onTriggered: {
            passwordInput.forceActiveFocus()
        }
    }

    function focusInput() {
        passwordInput.forceActiveFocus()
    }

    // Forward keyboard events
    function handleKey(event) {
        if (event.key === Qt.Key_Escape) {
            event.accepted = true
            cancelAuth()
            return true
        }
        return false
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.active && !root.isClosing
        onActivated: cancelAuth()
    }

    function submitAuth() {
        if (flow) {
            flow.submit(passwordInput.text)
            passwordInput.text = ""
        }
    }

    function cancelAuth() {
        if (flow) {
            flow.cancelAuthenticationRequest()
        }
        root.closeRequested()
    }

    // Shake animation on authentication failure
    Connections {
        target: flow
        function onAuthenticationFailed() {
            shakeAnim.restart()
            passwordInput.text = ""
            passwordInput.forceActiveFocus()
        }
        function onAuthenticationSucceeded() {
            root.closeRequested()
        }
        function onAuthenticationRequestCancelled() {
            root.closeRequested()
        }
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: cardBody; property: "x"; to: -14; duration: 40; easing.type: Easing.OutQuad }
        NumberAnimation { target: cardBody; property: "x"; to: 14; duration: 40; easing.type: Easing.OutQuad }
        NumberAnimation { target: cardBody; property: "x"; to: -8; duration: 40; easing.type: Easing.OutQuad }
        NumberAnimation { target: cardBody; property: "x"; to: 8; duration: 40; easing.type: Easing.OutQuad }
        NumberAnimation { target: cardBody; property: "x"; to: 0; duration: 40; easing.type: Easing.OutQuad }
    }

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string shieldSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>')
    readonly property string lockSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>')
    readonly property string alertSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>')
    readonly property string userSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>')

    // ── OBSIDIAN EXPANDING BACKGROUND CONTAINER ─────────────────────────────
    Rectangle {
        id: islandMorphBg
        anchors.fill: parent
        radius: 18 + (24 - 18) * root.animProgress
        color: Theme.alpha(Theme.background, 0.84)
        border.width: 1
        border.color: (flow && (flow.failed || flow.supplementaryIsError)) ? Theme.alpha("#ef4444", 0.65) : Theme.alpha(Theme.accent, 0.35)
        Behavior on border.color { ColorAnimation { duration: 180 } }
    }

    // ── CONTENT CONTAINER ────────────────────────────────────────────────────
    Item {
        id: cardBody
        anchors.fill: parent
        anchors.margins: 22
        opacity: (!root.isClosing && root.animProgress >= 0.75) ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: root.isClosing ? 90 : 150; easing.type: Easing.OutCubic }
        }

        // Header Row
        RowLayout {
            id: headerRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 40
            spacing: 12

            Rectangle {
                width: 36
                height: 36
                radius: 18
                color: Theme.alpha(Theme.accent, 0.16)
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.40)

                Image {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    source: root.shieldSvg
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "AUTHENTICATION REQUIRED"
                    font.family: "Outfit"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.1
                    color: Theme.foreground
                }

                Text {
                    text: (flow && flow.actionId && flow.actionId.length > 0) ? flow.actionId : "System Authorization"
                    font.family: "Outfit"
                    font.pixelSize: 10
                    color: Theme.muted
                    elide: Text.ElideRight
                    Layout.maximumWidth: 380
                }
            }
        }

        // Action Request Message Box
        Rectangle {
            id: messageBox
            anchors.top: headerRow.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.right: parent.right
            height: 52
            radius: 12
            color: Theme.alpha(Theme.surface, 0.45)
            border.width: 1
            border.color: Theme.alpha(Theme.foreground, 0.08)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: (flow && flow.message && flow.message.length > 0) ? flow.message : "Authentication is required to perform privileged system operations."
                    font.family: "Outfit"
                    font.pixelSize: 11
                    font.weight: Font.Normal
                    color: Theme.foreground
                    wrapMode: Text.Wrap
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        // User Identity Row
        RowLayout {
            id: userRow
            anchors.top: messageBox.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.right: parent.right
            height: 36
            spacing: 10

            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: Theme.alpha(Theme.surface, 0.6)
                clip: true

                Image {
                    id: avatarImg
                    anchors.fill: parent
                    source: root.avatarPath
                    fillMode: Image.PreserveAspectCrop
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 16
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.alpha(Theme.accent, 0.4)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "shell-ninja"
                    font.family: "Outfit"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: Theme.foreground
                }

                Text {
                    text: "Root Administrator"
                    font.family: "Outfit"
                    font.pixelSize: 10
                    color: Theme.accent
                }
            }
        }

        // Error message pill (if failure occurred)
        Rectangle {
            id: errorPill
            visible: flow && flow.supplementaryMessage && flow.supplementaryMessage.length > 0
            anchors.top: userRow.bottom
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.right: parent.right
            height: visible ? 28 : 0
            radius: 14
            color: Theme.alpha("#ef4444", 0.15)
            border.width: 1
            border.color: Theme.alpha("#ef4444", 0.4)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 6

                Image {
                    width: 14
                    height: 14
                    source: root.alertSvg
                }

                Text {
                    Layout.fillWidth: true
                    text: flow ? flow.supplementaryMessage : ""
                    font.family: "Outfit"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: "#f87171"
                    elide: Text.ElideRight
                }
            }
        }

        // Password Input Field
        Rectangle {
            id: passwordBox
            anchors.top: errorPill.visible ? errorPill.bottom : userRow.bottom
            anchors.topMargin: errorPill.visible ? 8 : 10
            anchors.left: parent.left
            anchors.right: parent.right
            height: 44
            radius: 22
            color: Theme.alpha(Theme.background, 0.7)
            border.width: 1.5
            border.color: passwordInput.activeFocus ? Theme.accent : Theme.alpha(Theme.foreground, 0.16)
            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10

                Image {
                    width: 16
                    height: 16
                    source: root.lockSvg
                }

                TextInput {
                    id: passwordInput
                    Layout.fillWidth: true
                    font.family: "Outfit"
                    font.pixelSize: 13
                    color: Theme.foreground
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: (flow && flow.responseVisible) ? TextInput.Normal : TextInput.Password
                    focus: true
                    selectByMouse: true

                    Text {
                        anchors.fill: parent
                        text: (flow && flow.inputPrompt && flow.inputPrompt.length > 0) ? flow.inputPrompt.replace(":", "") : "Enter admin password"
                        color: Theme.muted
                        font.family: "Outfit"
                        font.pixelSize: 13
                        verticalAlignment: Text.AlignVCenter
                        visible: passwordInput.text.length === 0
                    }

                    Keys.onReturnPressed: {
                        root.submitAuth()
                    }

                    Keys.onEscapePressed: function(event) {
                        event.accepted = true
                        root.cancelAuth()
                    }
                }
            }
        }

        // Action Buttons Row
        RowLayout {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 38
            spacing: 12

            // Cancel Button
            Rectangle {
                Layout.fillWidth: true
                height: 38
                radius: 19
                color: cancelMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.12) : Theme.alpha(Theme.surface, 0.4)
                border.width: 1
                border.color: cancelMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.25) : Theme.alpha(Theme.foreground, 0.1)

                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    font.family: "Outfit"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: Theme.foreground
                }

                MouseArea {
                    id: cancelMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cancelAuth()
                }
            }

            // Authenticate Button
            Rectangle {
                Layout.fillWidth: true
                height: 38
                radius: 19
                color: authMouse.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
                scale: authMouse.pressed ? 0.98 : 1.0
                Behavior on scale { NumberAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "Authenticate"
                    font.family: "Outfit"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Theme.background
                }

                MouseArea {
                    id: authMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.submitAuth()
                }
            }
        }
    }
}
