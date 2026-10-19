import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "."

Rectangle {
    id: root

    implicitWidth: 444
    implicitHeight: 92
    radius: 18
    color: "transparent"

    property string uptimeString: "Uptime - 5 hours"
    property real wallpaperTimestamp: Date.now()
    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : "/home/shell-ninja"
    }

    signal powerClicked()

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string settingsSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>')
    readonly property string powerSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.error + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M18.36 6.64a9 9 0 1 1-12.73 0"/><line x1="12" y1="2" x2="12" y2="12"/></svg>')

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
        anchors.margins: 14

        // User Avatar with circular alpha mask & glowing border
        Rectangle {
            id: avatarFrame
            width: 52
            height: 52
            radius: 26
            color: Theme.surface
            border.color: Theme.accent
            border.width: 2
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            Item {
                id: avatarMask
                anchors.centerIn: parent
                width: 48
                height: 48
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
                width: 48
                height: 48
                source: "file:///home/shell-ninja/.face"
                fillMode: Image.PreserveAspectCrop
                smooth: true
                mipmap: true
                sourceSize: Qt.size(128, 128)
                visible: false
            }

            MultiEffect {
                anchors.centerIn: parent
                width: 48
                height: 48
                source: rawAvatar
                visible: rawAvatar.status === Image.Ready
                autoPaddingEnabled: false
                maskEnabled: true
                maskSource: avatarMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }
        }

        // User & System Info Column
        Column {
            anchors.left: avatarFrame.right
            anchors.leftMargin: 14
            anchors.right: actionsRow.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                text: "shell-ninja"
                font.family: "Outfit"
                font.pixelSize: 15
                font.weight: Font.Bold
                color: Theme.foreground
            }

            Text {
                text: "shell-ninja@archlinux"
                font.family: "Outfit"
                font.pixelSize: 11
                font.weight: Font.Medium
                color: Theme.alpha(Theme.foreground, 0.65)
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
            spacing: 8

            // Settings button
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: setMouse.containsMouse ? Theme.alpha(Theme.surface, 0.9) : Theme.alpha(Theme.surface, 0.5)
                border.color: setMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.2) : Theme.alpha(Theme.foreground, 0.08)
                border.width: 1

                Image { anchors.centerIn: parent; width: 14; height: 14; source: root.settingsSvg }

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
                width: 28
                height: 28
                radius: 14
                color: pwrMouse.containsMouse ? Theme.alpha(Theme.error, 0.25) : Theme.alpha(Theme.surface, 0.5)
                border.color: pwrMouse.containsMouse ? Theme.error : Theme.alpha(Theme.foreground, 0.08)
                border.width: 1

                Image { anchors.centerIn: parent; width: 14; height: 14; source: root.powerSvg }

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
