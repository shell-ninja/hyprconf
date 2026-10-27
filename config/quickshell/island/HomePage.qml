import QtQuick
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root

    implicitWidth: 444
    implicitHeight: 496

    property bool active: false
    signal powerClicked()
    signal navigateToWeather()
    signal navigateToPage2()

    property var notificationList: []
    property real wallpaperTimestamp: Date.now()
    signal clearAllNotifications()
    signal dismissNotification(var notifId)

    property bool isAudioPlaying: false
    property var cavaBars: []
    property bool visualizerEnabled: true
    property string visualizerStyle: "wave"
    property int visualizerBarCount: 8
    property real animProgress: 1.0

    property alias isWifiDialogOpen: wifiDialog.isOpen
    function openWifiDialog() { wifiDialog.open() }
    function closeWifiDialog() { wifiDialog.close() }

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string arrowRightSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>')
    readonly property string arrowLeftSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>')
    readonly property string volumeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14M15.54 8.46a5 5 0 0 1 0 7.07"/></svg>')
    readonly property string muteSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.error + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><line x1="23" y1="9" x2="17" y2="15"/><line x1="17" y1="9" x2="23" y2="15"/></svg>')
    readonly property string brightnessSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>')

    // ── AUDIO INTEGRATION ────────────────────────────────────────────────────
    property int currentVolume: 50
    property bool isMuted: false

    Process {
        id: volReader
        command: ["bash", "-c", "echo $(pamixer --get-volume):$(pamixer --get-mute)"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text) return
                var parts = text.trim().split(":")
                if (parts.length >= 2) {
                    var v = parseInt(parts[0], 10)
                    if (!isNaN(v)) root.currentVolume = v
                    root.isMuted = (parts[1].trim() === "true")
                }
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            if (!volReader.running) volReader.running = true
        }
    }

    Process { id: volSetter }

    Timer {
        id: volDebounceTimer
        interval: 30
        repeat: false
        onTriggered: {
            volSetter.running = false
            volSetter.command = ["pamixer", "--set-volume", root.currentVolume.toString()]
            volSetter.running = true
        }
    }

    function setVolume(val) {
        root.currentVolume = val
        root.isMuted = false
        volDebounceTimer.restart()
    }

    function toggleMute() {
        volSetter.running = false
        volSetter.command = ["pamixer", "-t"]
        volSetter.running = true
        root.isMuted = !root.isMuted
    }

    // ── DESKTOP BRIGHTNESS (ddcutil) ─────────────────────────────────────────
    property int currentBrightness: 50
    property int externalBrightness: -1
    onExternalBrightnessChanged: {
        if (externalBrightness >= 0 && externalBrightness !== root.currentBrightness) {
            root.currentBrightness = externalBrightness
        }
    }

    property int externalVolume: -1
    onExternalVolumeChanged: {
        if (externalVolume >= 0 && externalVolume !== root.currentVolume) {
            root.currentVolume = externalVolume
        }
    }

    Process {
        id: brightReader
        command: ["bash", "-c", "$HOME/.hyprconf/hypr/scripts/sh/brightness.sh get"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text) return
                var val = parseInt(text.trim(), 10)
                if (!isNaN(val) && val >= 0 && val <= 100) {
                    root.currentBrightness = val
                }
            }
        }
    }

    Process { id: brightSetter }

    Timer {
        id: brightDebounceTimer
        interval: 40
        repeat: false
        onTriggered: {
            brightSetter.running = false
            brightSetter.command = ["bash", "-c", "$HOME/.hyprconf/hypr/scripts/sh/brightness.sh set " + root.currentBrightness]
            brightSetter.running = true
        }
    }

    function setBrightness(val) {
        root.currentBrightness = val
        brightDebounceTimer.restart()
    }

    // ── STAGGERED "LAZY LOAD" ENTRANCE / EXIT CASCADES ───────────────────────
    Component.onCompleted: {
        if (active) cascadeEnterAnim.start()
    }

    onActiveChanged: {
        if (active) {
            cascadeExitAnim.stop()
            cascadeEnterAnim.start()
            if (!brightReader.running) {
                brightReader.running = true
            } else {
                brightReader.running = false
                brightReader.running = true
            }
            if (!volReader.running) {
                volReader.running = true
            } else {
                volReader.running = false
                volReader.running = true
            }
        } else {
            cascadeEnterAnim.stop()
            cascadeExitAnim.start()
        }
    }

    ParallelAnimation {
        id: cascadeEnterAnim

        // 1. Profile Banner (delay: 0ms)
        SequentialAnimation {
            PauseAnimation { duration: 0 }
            ParallelAnimation {
                NumberAnimation { target: card0; property: "opacity"; to: 1.0; duration: 220; easing.type: Easing.OutCubic }
                NumberAnimation { target: t0; property: "y"; to: 0; duration: 240; easing.type: Easing.OutCubic }
            }
        }

        // 2. Quick Toggles & Sliders (delay: 70ms)
        SequentialAnimation {
            PauseAnimation { duration: 70 }
            ParallelAnimation {
                NumberAnimation { target: card1; property: "opacity"; to: 1.0; duration: 220; easing.type: Easing.OutCubic }
                NumberAnimation { target: t1; property: "y"; to: 0; duration: 240; easing.type: Easing.OutCubic }
            }
        }

        // 3. Bottom Card (delay: 140ms)
        SequentialAnimation {
            PauseAnimation { duration: 140 }
            ParallelAnimation {
                NumberAnimation { target: card2; property: "opacity"; to: 1.0; duration: 220; easing.type: Easing.OutCubic }
                NumberAnimation { target: t2; property: "y"; to: 0; duration: 240; easing.type: Easing.OutCubic }
            }
        }

        // 4. Pagination Dots (delay: 200ms)
        SequentialAnimation {
            PauseAnimation { duration: 200 }
            NumberAnimation { target: card3; property: "opacity"; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
        }
    }

    ParallelAnimation {
        id: cascadeExitAnim
        NumberAnimation { target: card0; property: "opacity"; to: 0.0; duration: 100 }
        NumberAnimation { target: card1; property: "opacity"; to: 0.0; duration: 100 }
        NumberAnimation { target: card2; property: "opacity"; to: 0.0; duration: 100 }
        NumberAnimation { target: card3; property: "opacity"; to: 0.0; duration: 100 }
        NumberAnimation { target: bottomVisualizerBar; property: "opacity"; to: 0.0; duration: 100 }
        NumberAnimation { target: t0; property: "y"; to: 14; duration: 50 }
        NumberAnimation { target: t1; property: "y"; to: 18; duration: 50 }
        NumberAnimation { target: t2; property: "y"; to: 22; duration: 50 }
    }

    // ── MAIN CONTENT COLUMN ──────────────────────────────────────────────────
    Column {
        anchors.fill: parent
        spacing: 10

        // 1. Profile Banner Card
        ProfileBanner {
            id: card0
            width: parent.width
            height: 104
            wallpaperTimestamp: root.wallpaperTimestamp
            opacity: 0.0
            transform: Translate { id: t0; y: 14 }
            onPowerClicked: root.powerClicked()
        }

        // 2. Middle Row: Quick Toggles (280) + Sliders (150) = 444
        Row {
            id: card1
            width: parent.width
            spacing: 14
            opacity: 0.0
            transform: Translate { id: t1; y: 18 }

            // Left: 6 Quick Toggles Grid
            QuickToggles {
                id: quickToggles
                width: 280
                height: 165
                onOpenWifiDialogRequested: {
                    wifiDialog.open()
                }
            }

            // Right: Sliders Column
            Row {
                spacing: 10

                // Brightness Slider
                VerticalSlider {
                    id: brightnessSlider
                    width: 70
                    height: 165
                    title: "Brightness"
                    value: root.currentBrightness
                    fillColor: Theme.primary
                    iconSvg: root.brightnessSvg
                    onSliderMoved: function(newVal) {
                        root.setBrightness(newVal)
                    }
                }

                // Volume Slider
                VerticalSlider {
                    id: volumeSlider
                    width: 70
                    height: 165
                    title: "Volume"
                    value: root.currentVolume
                    isMuted: root.isMuted
                    fillColor: Theme.accent
                    iconSvg: root.isMuted ? root.muteSvg : root.volumeSvg
                    onSliderMoved: function(newVal) {
                        root.setVolume(newVal)
                    }
                    onIconClicked: {
                        root.toggleMute()
                    }
                }
            }
        }

        // 3. Bottom Row: Interactive Notification & Media Hub
        BottomCard {
            id: card2
            width: parent.width
            height: {
                if (root.isAudioPlaying && root.visualizerEnabled) return 130
                if (root.notificationList && root.notificationList.length > 0) return 172
                return 160
            }
            opacity: 0.0
            transform: Translate { id: t2; y: 22 }

            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            notificationsList: root.notificationList
            onClearAllNotifications: root.clearAllNotifications()
            onDismissNotification: function(notifId) {
                root.dismissNotification(notifId)
            }
            onOpenWeatherRequested: root.navigateToWeather()
        }

        // 4. Pagination & Navigation Bar
        Item {
            id: card3
            width: parent.width
            height: 24
            opacity: 0.0

            // Left: Prev Page Button (← Weather, switches to 1st page)
            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                height: 24
                width: weatherBtnRow.width + 16
                radius: 12
                color: weatherBtnMouse.containsMouse ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.6)
                border.width: 1
                border.color: weatherBtnMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                scale: weatherBtnMouse.pressed ? 0.94 : (weatherBtnMouse.containsMouse ? 1.05 : 1.0)
                Behavior on scale { NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Row {
                    id: weatherBtnRow
                    anchors.centerIn: parent
                    spacing: 4

                    Image {
                        width: 10
                        height: 10
                        source: root.arrowLeftSvg
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Weather"
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: weatherBtnMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.8)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: weatherBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.navigateToWeather()
                }
            }

            // Centered 3 Pagination Dots (1: Weather, 2: Control Center [Active], 3: System Info)
            Row {
                anchors.centerIn: parent
                spacing: 8

                // Dot 1: Weather (Page 1) - Clickable
                Rectangle {
                    width: 6
                    height: 5
                    radius: 2.5
                    color: dot1Mouse.containsMouse ? "#38bdf8" : Theme.alpha(Theme.foreground, 0.25)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    MouseArea {
                        id: dot1Mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.navigateToWeather()
                    }
                }

                // Dot 2: Control Center (Page 2) - ACTIVE
                Rectangle {
                    width: 18
                    height: 5
                    radius: 2.5
                    color: Theme.accent
                    Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }

                // Dot 3: System Info (Page 3) - Clickable
                Rectangle {
                    width: 6
                    height: 5
                    radius: 2.5
                    color: dot3Mouse.containsMouse ? Theme.foreground : Theme.alpha(Theme.foreground, 0.35)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    MouseArea {
                        id: dot3Mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.navigateToPage2()
                    }
                }
            }

            // Right: Next Page Arrow Button (→)
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 24
                width: nextRow.width + 16
                radius: 12
                color: nextMouse.containsMouse ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.6)
                border.width: 1
                border.color: nextMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                scale: nextMouse.pressed ? 0.94 : (nextMouse.containsMouse ? 1.05 : 1.0)
                Behavior on scale { NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Row {
                    id: nextRow
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "System"
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: nextMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.8)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Image {
                        width: 10
                        height: 10
                        source: root.arrowRightSvg
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.navigateToPage2()
                }
            }
        }

        // 5. Bottom Live Audio Spectrum Bar (Smoothly glides into place on hover when playing music)
        Rectangle {
            id: bottomVisualizerBar
            width: parent.width
            height: (root.isAudioPlaying && root.visualizerEnabled) ? 46 : 0
            radius: 16
            color: Theme.alpha(Theme.surface, 0.65)
            border.color: Theme.alpha(Theme.accent, 0.35)
            border.width: (root.isAudioPlaying && root.visualizerEnabled) ? 1 : 0
            visible: (root.isAudioPlaying && root.visualizerEnabled)
            clip: true

            opacity: (root.isAudioPlaying && root.visualizerEnabled) ? Math.min(1.0, Math.max(0.0, (root.animProgress - 0.25) / 0.75)) : 0.0

            Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

            AudioVisualizer {
                anchors.centerIn: parent
                active: root.isAudioPlaying && root.visualizerEnabled
                wingMode: "full"
                barCount: root.visualizerBarCount
                style: root.visualizerStyle
                cavaValues: root.cavaBars
                height: 26
                barW: (root.visualizerStyle === "cava" ? 5.0 : 4.2)
                gap: 3.8
            }
        }
    }

    // ── WI-FI NETWORKS DIALOGUE OVERLAY ──────────────────────────────────────
    WifiNetworkDialog {
        id: wifiDialog
    }
}
