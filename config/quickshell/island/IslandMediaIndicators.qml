import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import "."

Item {
    id: root

    property bool isScreenRecording: false
    property bool isMicActive: false
    property int recordingElapsedSeconds: 0

    onIsScreenRecordingChanged: {
        recordingElapsedSeconds = 0
    }

    Timer {
        id: recTimer
        interval: 1000
        repeat: true
        running: root.isScreenRecording
        onTriggered: {
            root.recordingElapsedSeconds += 1
        }
    }

    readonly property string recTimeString: {
        var s = root.recordingElapsedSeconds
        var hrs = Math.floor(s / 3600)
        var mins = Math.floor((s % 3600) / 60)
        var secs = s % 60
        var mStr = (mins < 10 ? "0" : "") + mins
        var sStr = (secs < 10 ? "0" : "") + secs
        if (hrs > 0) {
            var hStr = (hrs < 10 ? "0" : "") + hrs
            return hStr + ":" + mStr + ":" + sStr
        }
        return mStr + ":" + sStr
    }

    readonly property bool anyActive: isScreenRecording || isMicActive

    visible: anyActive
    implicitWidth: visible ? indicatorRow.implicitWidth : 0
    implicitHeight: 22

    Behavior on implicitWidth {
        NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
    }
    Behavior on opacity {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    function svgUrl(content) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(content)
    }

    // Screen recorder monitor SVG
    readonly property string screenRecSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/></svg>')

    // Microphone SVG
    readonly property string micActiveSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3z"/><path d="M19 10v2a7 7 0 0 1-14 0v-2"/><line x1="12" y1="19" x2="12" y2="23"/><line x1="8" y1="23" x2="16" y2="23"/></svg>')

    Row {
        id: indicatorRow
        spacing: 6
        anchors.verticalCenter: parent.verticalCenter

        // ═════════════════════════════════════════════════════════════════════
        // 1. SCREEN RECORDING INDICATOR PILL
        // ═════════════════════════════════════════════════════════════════════
        Rectangle {
            id: recPill
            visible: root.isScreenRecording
            opacity: root.isScreenRecording ? 1.0 : 0.0
            height: 20
            width: root.isScreenRecording ? (recContentRow.implicitWidth + 14) : 0
            radius: 10
            color: Theme.alpha("#ef4444", 0.16)
            border.color: Theme.alpha("#ef4444", 0.50)
            border.width: 1
            clip: true
            anchors.verticalCenter: parent.verticalCenter

            Behavior on width {
                NumberAnimation { duration: 260; easing.type: Easing.OutBack }
            }
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            Row {
                id: recContentRow
                spacing: 4
                anchors.centerIn: parent

                // Monitor SVG Icon
                Image {
                    width: 13
                    height: 13
                    source: root.screenRecSvg
                    sourceSize.width: 26
                    sourceSize.height: 26
                    smooth: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Pulsing Red Radar Dot Container
                Item {
                    width: 8
                    height: 8
                    anchors.verticalCenter: parent.verticalCenter

                    // Expanding Radar Ripple
                    Rectangle {
                        id: rippleCircle
                        anchors.centerIn: parent
                        width: 6
                        height: 6
                        radius: 3
                        color: "transparent"
                        border.color: "#ef4444"
                        border.width: 1.2

                        SequentialAnimation on scale {
                            running: root.isScreenRecording
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 2.4; duration: 1200; easing.type: Easing.OutQuad }
                        }
                        SequentialAnimation on opacity {
                            running: root.isScreenRecording
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.95; to: 0.0; duration: 1200; easing.type: Easing.OutQuad }
                        }
                    }

                    // Solid Breathing Core Dot
                    Rectangle {
                        anchors.centerIn: parent
                        width: 5
                        height: 5
                        radius: 2.5
                        color: "#ef4444"

                        SequentialAnimation on opacity {
                            running: root.isScreenRecording
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
                        }
                    }
                }

                // "REC" Label
                Text {
                    text: "REC"
                    font.family: "Outfit"
                    font.pixelSize: 9
                    font.weight: Font.Black
                    font.letterSpacing: 0.4
                    color: "#ef4444"
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Live Recording Timer (e.g. 00:24)
                Text {
                    text: root.recTimeString
                    font.family: "Outfit"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 0.3
                    color: "#ef4444"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // ═════════════════════════════════════════════════════════════════════
        // 2. MICROPHONE INPUT CAPTURED INDICATOR PILL
        // ═════════════════════════════════════════════════════════════════════
        Rectangle {
            id: micPill
            visible: root.isMicActive
            opacity: root.isMicActive ? 1.0 : 0.0
            height: 20
            width: root.isMicActive ? (micContentRow.implicitWidth + 14) : 0
            radius: 10
            color: Theme.alpha("#f59e0b", 0.16)
            border.color: Theme.alpha("#f59e0b", 0.50)
            border.width: 1
            clip: true
            anchors.verticalCenter: parent.verticalCenter

            Behavior on width {
                NumberAnimation { duration: 260; easing.type: Easing.OutBack }
            }
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            Row {
                id: micContentRow
                spacing: 4
                anchors.centerIn: parent

                // Mic SVG Icon
                Image {
                    width: 13
                    height: 13
                    source: root.micActiveSvg
                    sourceSize.width: 26
                    sourceSize.height: 26
                    smooth: true
                    anchors.verticalCenter: parent.verticalCenter

                    SequentialAnimation on opacity {
                        running: root.isMicActive
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.6; duration: 900; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                    }
                }

                // Animated Live Soundwave Micro-Bars
                Row {
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter

                    // Wave Bar 1
                    Rectangle {
                        width: 2
                        height: 4
                        radius: 1
                        color: "#f59e0b"
                        anchors.verticalCenter: parent.verticalCenter

                        SequentialAnimation on height {
                            running: root.isMicActive
                            loops: Animation.Infinite
                            NumberAnimation { to: 9; duration: 320; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 3; duration: 280; easing.type: Easing.InOutQuad }
                        }
                    }

                    // Wave Bar 2 (center tallest)
                    Rectangle {
                        width: 2
                        height: 7
                        radius: 1
                        color: "#f59e0b"
                        anchors.verticalCenter: parent.verticalCenter

                        SequentialAnimation on height {
                            running: root.isMicActive
                            loops: Animation.Infinite
                            NumberAnimation { to: 12; duration: 420; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 4; duration: 380; easing.type: Easing.InOutQuad }
                        }
                    }

                    // Wave Bar 3
                    Rectangle {
                        width: 2
                        height: 5
                        radius: 1
                        color: "#f59e0b"
                        anchors.verticalCenter: parent.verticalCenter

                        SequentialAnimation on height {
                            running: root.isMicActive
                            loops: Animation.Infinite
                            NumberAnimation { to: 8; duration: 360; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 3; duration: 340; easing.type: Easing.InOutQuad }
                        }
                    }
                }
            }
        }
    }
}

