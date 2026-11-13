import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "."

Rectangle {
    id: root

    implicitWidth: 444
    implicitHeight: 104
    radius: 18
    color: "transparent"

    property string uptimeString: "Uptime - 5 hours"
    property real wallpaperTimestamp: Date.now()
    property real avatarTimestamp: Date.now()

    readonly property string userName: {
        var u = Quickshell.env("USER")
        return (u && u.length > 0) ? u : "user"
    }

    property string hostName: "archlinux"

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : ("/home/" + root.userName)
    }

    // Dynamic Hostname Reader
    Process {
        id: hostReader
        command: ["bash", "-c", "cat /etc/hostname 2>/dev/null || hostname 2>/dev/null || uname -n"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) root.hostName = text.trim()
            }
        }
    }


    signal powerClicked()

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string settingsSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>')
    readonly property string powerSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.error + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M18.36 6.64a9 9 0 1 1-12.73 0"/><line x1="12" y1="2" x2="12" y2="12"/></svg>')
    readonly property string desktopSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>')
    readonly property string gamepadSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="6" x2="10" y1="12" y2="12"/><line x1="8" x2="8" y1="10" y2="14"/><line x1="15" x2="15.01" y1="13" y2="13"/><line x1="18" x2="18.01" y1="11" y2="11"/><path d="M17.32 5H6.68a4 4 0 0 0-3.98 3.59C2.6 9.42 2 14.46 2 16a3 3 0 0 0 3 3c1 0 1.5-.5 2-1l1.41-1.41A2 2 0 0 1 9.83 16h4.34a2 2 0 0 1 1.41.59L17 18c.5.5 1 1 2 1a3 3 0 0 0 3-3c0-1.55-.6-6.58-.69-7.26A4 4 0 0 0 17.32 5z"/></svg>')
    readonly property string presentationSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.secondary + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 3h20"/><path d="M21 3v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V3"/><path d="m7 21 5-5 5 5"/></svg>')
    readonly property string cameraSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/><circle cx="12" cy="13" r="4"/></svg>')
    readonly property string cameraMiniSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.background + '" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/><circle cx="12" cy="13" r="4"/></svg>')

    property int systemMode: 0

    Process {
        id: modeReader
        command: ["sh", "-c", "cat " + root.homeDir + "/.local/share/hyprconf/.cache/system_mode.state 2>/dev/null || cat " + root.homeDir + "/.local/share/hyprconf/.cache/gamemode.state 2>/dev/null || echo '0'"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text) return
                var m = parseInt(text.trim())
                if (!isNaN(m)) root.systemMode = m
            }
            onStreamFinished: {
                if (!text) return
                var m = parseInt(text.trim())
                if (!isNaN(m)) root.systemMode = m
            }
        }
    }

    Timer {
        interval: 5000
        running: root.opacity > 0.05
        repeat: true
        onTriggered: {
            if (!modeReader.running) modeReader.running = true
        }
    }

    function refreshMode() {
        modeReader.running = false
        modeReader.running = true
    }

    function cycleSystemMode() {
        var nextMode = (root.systemMode + 1) % 3
        root.systemMode = nextMode
        actionProc.command = ["bash", "-c", "$HOME/.hyprconf/hypr/scripts/sh/system-mode.sh --set " + nextMode]
        actionProc.running = true
    }

    // Live Uptime Reader (direct awk on /proc/uptime, zero-overhead)
    Process {
        id: uptimeReader
        command: ["awk", "{s=int($1); h=int(s/3600); m=int((s%3600)/60); printf \"Uptime – %d hours %d minutes\", h, m}", "/proc/uptime"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) root.uptimeString = text.trim()
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            if (!uptimeReader.running) uptimeReader.running = true
        }
    }

    // Avatar Picker Process
    Process {
        id: avatarPicker
        command: ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/pick-avatar.py"]
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var res = JSON.parse(text.trim())
                    if (res.status === "success") {
                        root.avatarTimestamp = Date.now()
                    }
                } catch(e) {}
            }
        }
        onExited: function() {
            root.avatarTimestamp = Date.now()
        }
    }

    // Avatar Reset Process
    Process {
        id: avatarResetter
        command: ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/pick-avatar.py", "--reset"]
        onExited: function() {
            root.avatarTimestamp = Date.now()
        }
    }

    Process { id: actionProc }

    // ── WALLPAPER BACKGROUND WITH TRUE ALPHA MASK (RADIUS: 18) ───────────────
    readonly property FileView _wallWatcher: FileView {
        path: root.homeDir + "/.hyprconf/hypr/.cache/.wallpaper"
        watchChanges: true
        onFileChanged: {
            root.wallpaperTimestamp = Date.now()
        }
    }

    Item {
        id: bannerMask
        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: "#ffffff"
            antialiasing: true
        }
    }

    Image {
        id: rawWallBg
        anchors.fill: parent
        source: "file://" + root.homeDir + "/.hyprconf/hypr/.cache/current_wallpaper.png?t=" + root.wallpaperTimestamp
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(444, 120)
        cache: false
        asynchronous: false
        smooth: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: rawWallBg
        visible: rawWallBg.status === Image.Ready
        autoPaddingEnabled: false
        maskEnabled: true
        maskSource: bannerMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    // Frosted dark gradient scrim (lighter top to showcase wallpaper rim, richer bottom for legibility)
    Rectangle {
        anchors.fill: parent
        radius: 18
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.alpha(Theme.background, 0.70) }
            GradientStop { position: 1.0; color: Theme.alpha(Theme.background, 0.86) }
        }

        GlassRim {
            horizontalInset: 18
            peakOpacity: 1.35
        }
    }

    // Dedicated crisp aesthetic border framing the wallpaper image
    Rectangle {
        anchors.fill: parent
        radius: 18
        color: "transparent"
        border.color: Theme.alpha(Theme.accent, 0.45)
        border.width: 1.5
        z: 2
    }

    // ── CONTENT ROW ──────────────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        anchors.margins: 16

        // User Avatar with circular alpha mask, hover camera overlay & mini edit badge
        Item {
            id: avatarContainer
            width: 66
            height: 66
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                id: avatarFrame
                anchors.fill: parent
                radius: 33
                color: Theme.surface
                border.color: avatarMouse.containsMouse ? Qt.lighter(Theme.accent, 1.25) : Theme.accent
                border.width: avatarMouse.containsMouse ? 2.5 : 2
                scale: avatarMouse.containsMouse ? 1.04 : 1.0

                Behavior on border.color { ColorAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                Item {
                    id: avatarMask
                    anchors.centerIn: parent
                    width: 60
                    height: 60
                    layer.enabled: true
                    layer.smooth: true
                    visible: false

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "#ffffff"
                        antialiasing: true
                    }
                }

                Image {
                    id: rawAvatar
                    anchors.centerIn: parent
                    width: 60
                    height: 60
                    source: "file://" + root.homeDir + "/.hyprconf/hypr/.cache/.face?t=" + root.avatarTimestamp
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    mipmap: true
                    sourceSize: Qt.size(120, 120)
                    visible: false
                }

                MultiEffect {
                    anchors.centerIn: parent
                    width: 60
                    height: 60
                    source: rawAvatar
                    visible: rawAvatar.status === Image.Ready
                    autoPaddingEnabled: false
                    maskEnabled: true
                    maskSource: avatarMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                }

                // Dark frosted glass camera overlay on hover
                Rectangle {
                    anchors.centerIn: parent
                    width: 60
                    height: 60
                    radius: 30
                    color: Theme.alpha(Theme.background, 0.65)
                    opacity: avatarMouse.containsMouse ? 1.0 : 0.0
                    clip: true

                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Image {
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        source: root.cameraSvg
                    }
                }
            }

            // Bottom-right floating mini edit badge
            Rectangle {
                width: 22
                height: 22
                radius: 11
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: -1
                anchors.bottomMargin: -1
                color: avatarMouse.containsMouse ? Qt.lighter(Theme.accent, 1.15) : Theme.accent
                border.color: Theme.background
                border.width: 2
                z: 4

                Behavior on color { ColorAnimation { duration: 150 } }

                Image {
                    anchors.centerIn: parent
                    width: 11
                    height: 11
                    source: root.cameraMiniSvg
                }
            }

            MouseArea {
                id: avatarMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                z: 5
                onClicked: function(mouse) {
                    if (mouse.button === Qt.RightButton) {
                        avatarResetter.running = false
                        avatarResetter.running = true
                    } else {
                        avatarPicker.running = false
                        avatarPicker.running = true
                    }
                }
            }
        }

        // User & System Info Column
        Column {
            anchors.left: avatarContainer.right
            anchors.leftMargin: 16
            anchors.right: actionsRow.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                text: root.userName
                font.family: "Outfit"
                font.pixelSize: 16
                font.weight: Font.Bold
                color: Theme.foreground
                elide: Text.ElideRight
            }

            Text {
                text: root.userName + "@" + root.hostName
                font.family: "Outfit"
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Theme.alpha(Theme.foreground, 0.65)
                elide: Text.ElideRight
            }

            Text {
                text: root.uptimeString
                font.family: "Outfit"
                font.pixelSize: 11
                font.weight: Font.Normal
                color: Theme.alpha(Theme.foreground, 0.85)
            }
        }

        // Quick Action Buttons (Mode, Settings & Power)
        Row {
            id: actionsRow
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 2
            spacing: 8

            // System Mode Switcher Capsule (0 Normal, 1 Game, 2 Presentation)
            Rectangle {
                id: modeBtn
                height: 30
                width: modeRow.implicitWidth + 20
                radius: 15
                readonly property int currentMode: root.systemMode
                color: modeMouse.containsMouse
                       ? (currentMode === 1 ? Theme.alpha(Theme.accent, 0.35) : (currentMode === 2 ? Theme.alpha(Theme.secondary, 0.35) : Theme.alpha(Theme.surface, 0.9)))
                       : (currentMode === 1 ? Theme.alpha(Theme.accent, 0.22) : (currentMode === 2 ? Theme.alpha(Theme.secondary, 0.22) : Theme.alpha(Theme.surface, 0.5)))
                border.color: modeMouse.containsMouse
                              ? (currentMode === 1 ? Theme.accent : (currentMode === 2 ? Theme.secondary : Theme.alpha(Theme.foreground, 0.2)))
                              : (currentMode === 1 ? Theme.alpha(Theme.accent, 0.6) : (currentMode === 2 ? Theme.alpha(Theme.secondary, 0.6) : Theme.alpha(Theme.foreground, 0.08)))
                border.width: 1
                scale: modeMouse.pressed ? 0.93 : (modeMouse.containsMouse ? 1.04 : 1.0)
                Behavior on scale { NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Row {
                    id: modeRow
                    anchors.centerIn: parent
                    spacing: 6

                    Image {
                        width: 13
                        height: 13
                        anchors.verticalCenter: parent.verticalCenter
                        source: modeBtn.currentMode === 1 ? root.gamepadSvg : (modeBtn.currentMode === 2 ? root.presentationSvg : root.desktopSvg)
                    }

                    Text {
                        text: modeBtn.currentMode === 1 ? "Game" : (modeBtn.currentMode === 2 ? "Class" : "Normal")
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: modeBtn.currentMode === 1 ? Theme.accent : (modeBtn.currentMode === 2 ? Theme.secondary : Theme.foreground)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: modeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cycleSystemMode()
                }
            }

            // Settings button
            Rectangle {
                width: 30
                height: 30
                radius: 15
                color: setMouse.containsMouse ? Theme.alpha(Theme.surface, 0.92) : Theme.alpha(Theme.surface, 0.55)
                border.color: setMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.24) : Theme.alpha(Theme.foreground, 0.10)
                border.width: 1
                scale: setMouse.pressed ? 0.92 : (setMouse.containsMouse ? 1.06 : 1.0)
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                Image { anchors.centerIn: parent; width: 15; height: 15; source: root.settingsSvg }

                MouseArea {
                    id: setMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        actionProc.command = ["bash", "-c", "$HOME/.hyprconf/hypr/scripts/sh/qs-settings.sh --island"]
                        actionProc.running = true
                    }
                }
            }

            // Power button
            Rectangle {
                width: 30
                height: 30
                radius: 15
                color: pwrMouse.containsMouse ? Theme.alpha(Theme.error, 0.28) : Theme.alpha(Theme.surface, 0.55)
                border.color: pwrMouse.containsMouse ? Theme.error : Theme.alpha(Theme.foreground, 0.10)
                border.width: 1
                scale: pwrMouse.pressed ? 0.92 : (pwrMouse.containsMouse ? 1.06 : 1.0)
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                Image { anchors.centerIn: parent; width: 15; height: 15; source: root.powerSvg }

                MouseArea {
                    id: pwrMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.powerClicked()
                }
            }
        }
    }
}
