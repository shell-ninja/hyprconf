import QtQuick
import QtQuick.Layouts
import Quickshell
import "."

Item {
    id: root

    property var bar: null
    property var notifItem: null
    property bool shown: false

    readonly property int totalDuration: 4500
    property int remainingTime: totalDuration
    property bool isPaused: hoverHandler.hovered

    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: (typeof bar !== "undefined" && bar) ? (bar.marginTop + bar.barH + 12) : 56
    anchors.rightMargin: 16

    width: (root.notifItem && root.notifItem.body && (root.notifItem.body.indexOf("╭") >= 0 || root.notifItem.body.indexOf("┌") >= 0)) ? 410 : 340
    implicitHeight: cardBg.implicitHeight
    height: implicitHeight
    z: 100

    // Smooth slide from right and fade
    x: shown ? (parent.width - width - 16) : (parent.width + 20)
    opacity: shown ? 1.0 : 0.0

    Behavior on x {
        NumberAnimation {
            duration: root.shown ? 320 : 200
            easing.type: root.shown ? Easing.OutBack : Easing.OutCubic
            easing.overshoot: 1.20
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    visible: opacity > 0.001

    function show(item) {
        if (!item) return
        notifItem = item
        remainingTime = totalDuration
        shown = true
        tickTimer.restart()
    }

    function dismiss() {
        shown = false
        tickTimer.stop()
        if (notifItem && notifItem.rawNotif && typeof notifItem.rawNotif.dismiss === "function") {
            try { notifItem.rawNotif.dismiss() } catch(e) {}
        }
    }

    function invokeDefault() {
        if (notifItem && notifItem.rawNotif) {
            try {
                if (notifItem.rawNotif.actions) {
                    for (var i = 0; i < notifItem.rawNotif.actions.length; i++) {
                        var a = notifItem.rawNotif.actions[i]
                        if (a && a.identifier === "default" && typeof a.invoke === "function") {
                            a.invoke()
                            break
                        }
                    }
                }
            } catch(e) {}
        }
        dismiss()
    }

    Timer {
        id: tickTimer
        interval: 100
        repeat: true
        running: root.shown && !root.isPaused
        onTriggered: {
            root.remainingTime -= 100
            if (root.remainingTime <= 0) {
                root.dismiss()
            }
        }
    }

    HoverHandler {
        id: hoverHandler
    }

    // Glass Card Background
    Rectangle {
        id: cardBg
        anchors.fill: parent
        radius: 16
        color: Theme.alpha(Theme.surface, 0.94)
        border.width: 1
        border.color: hoverHandler.hovered ? Theme.alpha(Theme.accent, 0.45) : Theme.alpha(Theme.accent, 0.28)
        clip: true

        implicitHeight: mainCol.implicitHeight + 24

        // Glass highlight line at top
        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.80
            height: 1
            color: Theme.alpha(Theme.foreground, 0.12)
        }

        // Inner Click Area for opening
        MouseArea {
            anchors.fill: parent
            anchors.bottomMargin: 8
            cursorShape: Qt.PointingHandCursor
            onClicked: root.invokeDefault()
        }

        ColumnLayout {
            id: mainCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 14
            spacing: 8

            // Top Header: App Icon, App Name, Time, Dismiss Button
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // App Icon
                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 6
                    color: Theme.alpha(Theme.accent, 0.16)
                    border.width: 1
                    border.color: Theme.alpha(Theme.accent, 0.28)

                    Image {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        source: (root.notifItem && root.notifItem.appIcon)
                                ? ((root.notifItem.appIcon.indexOf("/") === 0 || root.notifItem.appIcon.indexOf("file://") === 0)
                                    ? root.notifItem.appIcon
                                    : Quickshell.iconPath(root.notifItem.appIcon, true))
                                : ""
                        sourceSize: Qt.size(32, 32)
                        visible: status === Image.Ready
                    }

                    SvgIcon {
                        anchors.centerIn: parent
                        size: 14
                        name: "bell"
                        color: Theme.accent
                        visible: parent.children[0].status !== Image.Ready
                    }
                }

                // App Name
                Text {
                    text: root.notifItem ? (root.notifItem.appName || "Notification") : "Notification"
                    font.family: "Outfit"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Theme.alpha(Theme.foreground, 0.85)
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // Time
                Text {
                    text: root.notifItem ? (root.notifItem.time || "Just now") : "Just now"
                    font.family: "Outfit"
                    font.pixelSize: 10
                    color: Theme.alpha(Theme.foreground, 0.45)
                }

                // Dismiss Button (×)
                Rectangle {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    radius: 10
                    color: closeHover.hovered ? Theme.alpha(Theme.error, 0.20) : "transparent"

                    SvgIcon {
                        anchors.centerIn: parent
                        size: 11
                        name: "x"
                        color: closeHover.hovered ? Theme.error : Theme.alpha(Theme.foreground, 0.50)
                    }

                    HoverHandler { id: closeHover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dismiss()
                    }
                }
            }

            // Summary Title
            Text {
                Layout.fillWidth: true
                text: root.notifItem ? (root.notifItem.summary || "") : ""
                font.family: "Outfit"
                font.pixelSize: 12
                font.weight: Font.Bold
                color: Theme.foreground
                elide: Text.ElideRight
                visible: text.length > 0
            }

            // Body Text
            Text {
                readonly property bool isMonoBox: text.indexOf("╭") >= 0 || text.indexOf("┌") >= 0 || text.indexOf("│") >= 0
                Layout.fillWidth: true
                text: root.notifItem ? (root.notifItem.body || "") : ""
                font.family: isMonoBox ? "JetBrainsMono Nerd Font, monospace" : "Outfit"
                font.pixelSize: isMonoBox ? 9.5 : 11
                color: Theme.alpha(Theme.foreground, 0.85)
                wrapMode: isMonoBox ? Text.NoWrap : Text.Wrap
                maximumLineCount: isMonoBox ? 14 : 4
                elide: Text.ElideRight
                lineHeight: isMonoBox ? 1.05 : 1.2
                visible: text.length > 0
            }

            // Action Buttons (if notification provided actions)
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: actionRepeater.count > 0

                Repeater {
                    id: actionRepeater
                    model: (root.notifItem && root.notifItem.rawNotif && root.notifItem.rawNotif.actions)
                           ? root.notifItem.rawNotif.actions.filter(function(a) { return a.identifier !== "default" })
                           : []

                    Rectangle {
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: Math.max(64, btnText.implicitWidth + 16)
                        radius: 12
                        color: btnHover.hovered ? Theme.accent : Theme.alpha(Theme.surface, 0.80)
                        border.width: 1
                        border.color: btnHover.hovered ? Theme.accent : Theme.alpha(Theme.accent, 0.35)

                        HoverHandler { id: btnHover }

                        Text {
                            id: btnText
                            anchors.centerIn: parent
                            text: modelData.text || modelData.identifier
                            font.family: "Outfit"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            color: btnHover.hovered ? Theme.on_primary : Theme.foreground
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                try { modelData.invoke() } catch(e) {}
                                root.dismiss()
                            }
                        }
                    }
                }
            }
        }

        // Bottom Animated Countdown Progress Line
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            height: 2.5
            width: parent.width * Math.max(0.0, Math.min(1.0, root.remainingTime / root.totalDuration))
            color: Theme.accent
            radius: 1

            Behavior on width {
                NumberAnimation { duration: 100; easing.type: Easing.Linear }
            }
        }
    }
}
