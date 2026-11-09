import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
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

    readonly property bool hasFrame: (typeof bar !== "undefined" && bar && (bar.capsuleStyle === "glass" || bar.enableScreenFrame))
    readonly property int frameThickness: hasFrame ? bar.frameThickness : 0
    readonly property int frameCornerRadius: hasFrame ? bar.frameCornerRadius : 0

    // Smooth rounded fillets where the notification attaches to the vertical frame (matching tooltips)
    readonly property int fT: hasFrame ? 12 : 0
    readonly property int fB: hasFrame ? 12 : 0
    readonly property int r: 16

    readonly property int bodyWidth: (root.notifItem && root.notifItem.body && (root.notifItem.body.indexOf("╭") >= 0 || root.notifItem.body.indexOf("┌") >= 0)) ? 430 : 340
    readonly property int bodyHeight: mainCol.implicitHeight + 24

    // Geometry: Positioned at the bottom-right, strictly bounded by the frame area
    readonly property int bottomMargin: hasFrame ? (frameThickness + frameCornerRadius + 8 - fB) : 16
    anchors.bottom: parent ? parent.bottom : undefined
    anchors.bottomMargin: bottomMargin

    width: bodyWidth
    implicitHeight: bodyHeight + fT + fB
    height: implicitHeight
    z: 100

    // Positioned flush with the inner edge of the right frame
    x: parent ? (hasFrame ? (parent.width - frameThickness - width) : (parent.width - width - 16)) : 0

    // CRITICAL: Clip strictly at the frame boundary so notification contents can NEVER bleed into or slide across the frame area
    clip: true

    visible: cardSurface.opacity > 0.001

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

    // Sliding Card Surface (slides horizontally behind the frame boundary, clipped by root)
    Item {
        id: cardSurface
        anchors.fill: parent

        // When shown: x = 0 (docked flush against the right frame)
        // When dismissed: x animates to width + 10 (retracting smoothly into the frame boundary, clipped out)
        x: root.shown ? 0 : (root.width + 10)
        opacity: root.shown ? 1.0 : 0.0

        Behavior on x {
            NumberAnimation {
                duration: root.shown ? 320 : 220
                easing.type: root.shown ? Easing.OutBack : Easing.OutCubic
                easing.overshoot: 1.15
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        // 1. Attached Monolithic Glass Background with Inverted Rounded Fillets (Glass / Screen Frame mode)
        Shape {
            id: attachedBg
            visible: root.hasFrame
            anchors.fill: parent
            layer.enabled: true
            layer.samples: 4

            readonly property int w: root.width
            readonly property int h: root.height
            readonly property int fT: root.fT
            readonly property int fB: root.fB
            readonly property int r: root.r
            readonly property int bodyHeight: root.bodyHeight
            readonly property color surfaceFill: (typeof bar !== "undefined" && bar) ? Theme.alpha(Theme.surface, bar.barOpacity) : Theme.alpha(Theme.surface, 0.90)

            // Monolithic Fill (closed on right against the frame)
            ShapePath {
                fillColor: attachedBg.surfaceFill
                strokeColor: "transparent"
                strokeWidth: 0

                startX: attachedBg.w
                startY: 0

                // Top fillet curving from the vertical right frame into the top edge
                PathArc {
                    x: attachedBg.w - attachedBg.fT
                    y: attachedBg.fT
                    radiusX: Math.max(1, attachedBg.fT)
                    radiusY: Math.max(1, attachedBg.fT)
                    direction: PathArc.Clockwise
                }

                // Top horizontal line of card body
                PathLine {
                    x: attachedBg.r
                    y: attachedBg.fT
                }

                // Top-left rounded corner
                PathArc {
                    x: 0
                    y: attachedBg.fT + attachedBg.r
                    radiusX: attachedBg.r
                    radiusY: attachedBg.r
                    direction: PathArc.Counterclockwise
                }

                // Left vertical edge of card body
                PathLine {
                    x: 0
                    y: Math.max(attachedBg.fT + attachedBg.r, attachedBg.fT + attachedBg.bodyHeight - attachedBg.r)
                }

                // Bottom-left rounded corner
                PathArc {
                    x: attachedBg.r
                    y: attachedBg.fT + attachedBg.bodyHeight
                    radiusX: attachedBg.r
                    radiusY: attachedBg.r
                    direction: PathArc.Counterclockwise
                }

                // Bottom horizontal line of card body
                PathLine {
                    x: attachedBg.w - attachedBg.fB
                    y: attachedBg.fT + attachedBg.bodyHeight
                }

                // Bottom fillet curving from the bottom edge into the vertical right frame
                PathArc {
                    x: attachedBg.w
                    y: attachedBg.fT + attachedBg.bodyHeight + attachedBg.fB
                    radiusX: Math.max(1, attachedBg.fB)
                    radiusY: Math.max(1, attachedBg.fB)
                    direction: PathArc.Clockwise
                }

                // Close along the right frame seam
                PathLine {
                    x: attachedBg.w
                    y: 0
                }
            }
        }

        // 2. Floating Glass Card Background (Islands mode)
        Rectangle {
            id: floatingBg
            visible: !root.hasFrame
            anchors.fill: parent
            radius: 16
            color: (typeof bar !== "undefined" && bar) ? Theme.alpha(Theme.surface, bar.barOpacity) : Theme.alpha(Theme.surface, 0.90)
            border.width: 1
            border.color: hoverHandler.hovered ? Theme.alpha(Theme.accent, 0.45) : Theme.alpha(Theme.accent, 0.28)
        }

        // Card Content Container
        Item {
            id: contentHolder
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: root.fT
            height: root.bodyHeight

            // Glass highlight line at top (floating mode only, matching Bar.qml)
            Rectangle {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.80
                height: 1
                color: Theme.alpha(Theme.foreground, 0.12)
                visible: !root.hasFrame
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
                anchors.rightMargin: root.hasFrame ? 16 : 14
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
                    font.pixelSize: isMonoBox ? 10 : 11
                    color: Theme.alpha(Theme.foreground, 0.85)
                    wrapMode: isMonoBox ? Text.NoWrap : Text.Wrap
                    maximumLineCount: isMonoBox ? 16 : 4
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
                anchors.bottomMargin: 2
                anchors.left: parent.left
                anchors.leftMargin: root.hasFrame ? 14 : 12
                height: 2
                width: (parent.width - (root.hasFrame ? 26 : 24)) * Math.max(0.0, Math.min(1.0, root.remainingTime / root.totalDuration))
                color: Theme.accent
                radius: 1

                Behavior on width {
                    NumberAnimation { duration: 100; easing.type: Easing.Linear }
                }
            }
        }
    }
}
