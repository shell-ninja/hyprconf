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
    readonly property string cameraSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/><circle cx="12" cy="13" r="4"/></svg>')
    readonly property string cameraMiniSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.background + '" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/><circle cx="12" cy="13" r="4"/></svg>')

    // Live Uptime Reader
    Process {
        id: uptimeReader
        command: ["bash", "-c", "python3 -c 'with open(\"/proc/uptime\") as f: s=float(f.read().split()[0]); h=int(s//3600); m=int((s%3600)//60); print(f\"Uptime – {h} hours {m} minutes\")'"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) root.uptimeString = text.trim()
            }
        }
    }

    Timer {
        interval: 30000
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
        source: "file://" + root.homeDir + "/.hyprconf/hypr/.cache/current_wallpaper.png"
        fillMode: Image.PreserveAspectCrop
        cache: false
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

    // Frosted dark overlay
    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.background, 0.78)
        radius: 18

        // Top specular line
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            height: 1
            color: Theme.alpha(Theme.foreground, 0.22)
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
                    sourceSize: Qt.size(256, 256)
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

        // Quick Action Buttons (Settings & Power)
        Row {
            id: actionsRow
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 2
            spacing: 8

            // Settings button
            Rectangle {
                width: 30
                height: 30
                radius: 15
                color: setMouse.containsMouse ? Theme.alpha(Theme.surface, 0.9) : Theme.alpha(Theme.surface, 0.5)
                border.color: setMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.2) : Theme.alpha(Theme.foreground, 0.08)
                border.width: 1

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
                color: pwrMouse.containsMouse ? Theme.alpha(Theme.error, 0.25) : Theme.alpha(Theme.surface, 0.5)
                border.color: pwrMouse.containsMouse ? Theme.error : Theme.alpha(Theme.foreground, 0.08)
                border.width: 1

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
