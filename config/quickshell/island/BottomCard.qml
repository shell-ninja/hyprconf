import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "."

Rectangle {
    id: root

    implicitWidth: 444
    implicitHeight: 155
    radius: 18

    color: Theme.alpha(Theme.surface, 0.65)
    border.color: Theme.alpha(Theme.foreground, 0.08)
    border.width: 1
    clip: true

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string bellSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>')
    readonly property string trashSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>')
    readonly property string playSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="' + Theme.background + '" stroke="' + Theme.background + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="5 3 19 12 5 21 5 3"/></svg>')
    readonly property string pauseSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="' + Theme.background + '" stroke="' + Theme.background + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="6" y="4" width="4" height="16"/><rect x="14" y="4" width="4" height="16"/></svg>')
    readonly property string prevSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="19 20 9 12 19 4 19 20"/><line x1="5" y1="19" x2="5" y2="5"/></svg>')
    readonly property string nextSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="5 4 15 12 5 20 5 4"/><line x1="19" y1="5" x2="19" y2="19"/></svg>')
    readonly property string musicSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></svg>')
    readonly property string cloudSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"/></svg>')

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : "/home/shell-ninja"
    }

    // ── LIVE WEATHER INTEGRATION ─────────────────────────────────────────────
    property string weatherString: "26°C · Clear sky"

    Process {
        id: weatherReader
        command: ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/weather.py"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0 && !text.includes("Unknown")) {
                    root.weatherString = text.trim()
                }
            }
        }
    }

    Timer {
        interval: 300000 // 5 minutes
        running: true
        repeat: true
        onTriggered: {
            if (!weatherReader.running) weatherReader.running = true
        }
    }

    // ── MPRIS MEDIA STATE ────────────────────────────────────────────────────
    property var activePlayer: {
        var players = Mpris.players ? Mpris.players.values : []
        for (var i = 0; i < players.length; i++) {
            var p = players[i]
            if (p && p.playbackState === MprisPlaybackState.Playing) return p
        }
        if (players.length > 0) return players[0]
        return null
    }

    readonly property bool hasMedia: activePlayer !== null && activePlayer.trackTitle && activePlayer.trackTitle.length > 0
    property int currentTab: (hasMedia && notificationsList.length === 0) ? 1 : 0

    // ── NOTIFICATIONS INTEGRATION ─────────────────────────────────────────────
    property var notificationsList: []
    readonly property bool hasNotifications: notificationsList.length > 0
    signal clearAllNotifications()
    signal dismissNotification(var notifId)

    function handleClearAll() {
        root.clearAllNotifications()
    }

    function handleDismiss(id) {
        root.dismissNotification(id)
    }

    // ── HEADER ROW ───────────────────────────────────────────────────────────
    Item {
        id: headerRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        height: 24

        // Left: Tabs & Badges
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Notifications Tab
            Item {
                width: notifTabRow.width
                height: notifTabRow.height
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    id: notifTabRow
                    spacing: 6
                    anchors.centerIn: parent

                    Image {
                        width: 14; height: 14; source: root.bellSvg; anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Notifications"
                        font.family: "Outfit"
                        font.pixelSize: 12
                        font.weight: (root.currentTab === 0) ? Font.Bold : Font.Medium
                        color: (root.currentTab === 0) ? Theme.foreground : Theme.muted
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.currentTab = 0
                }
            }

            // Notification Count Badge
            Rectangle {
                visible: root.hasNotifications
                height: 16
                width: countText.width + 8
                radius: 8
                color: Theme.alpha(Theme.accent, 0.22)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: root.notificationsList.length.toString()
                    font.family: "Outfit"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: Theme.accent
                }
            }

            // Media & Weather Tab
            Item {
                width: mediaTabRow.width
                height: mediaTabRow.height
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    id: mediaTabRow
                    spacing: 6
                    anchors.centerIn: parent

                    Image {
                        width: 13; height: 13; source: root.hasMedia ? root.musicSvg : root.cloudSvg; anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: root.hasMedia ? "Now Playing" : "Overview"
                        font.family: "Outfit"
                        font.pixelSize: 12
                        font.weight: (root.currentTab === 1) ? Font.Bold : Font.Medium
                        color: (root.currentTab === 1) ? Theme.foreground : Theme.muted
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.currentTab = 1
                }
            }
        }

        // Right: Clear All / Weather Indicator
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Clear All Button (when on Notifications tab & has items)
            Rectangle {
                visible: (root.currentTab === 0 && root.hasNotifications)
                height: 22
                width: 22
                radius: 11
                color: clearMouse.containsMouse ? Theme.alpha(Theme.error, 0.3) : Theme.alpha(Theme.surface, 0.8)
                border.color: clearMouse.containsMouse ? Theme.error : Theme.alpha(Theme.foreground, 0.1)
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter

                Image { anchors.centerIn: parent; width: 12; height: 12; source: root.trashSvg }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.clearAllNotifications()
                }
            }

            // Weather pill
            Rectangle {
                height: 20
                width: weatherText.width + 12
                radius: 10
                color: Theme.alpha(Theme.surface, 0.8)
                border.color: Theme.alpha(Theme.foreground, 0.08)
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: weatherText
                    anchors.centerIn: parent
                    text: "🌤 " + root.weatherString
                    font.family: "Outfit"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: Theme.alpha(Theme.foreground, 0.85)
                }
            }
        }
    }

    // ── NOTIFICATIONS CONTENT ────────────────────────────────────────────────
    Item {
        anchors.top: headerRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10
        anchors.topMargin: 2
        visible: root.currentTab === 0

        // Scrollable list
        ListView {
            id: notifListView
            anchors.fill: parent
            visible: root.hasNotifications
            model: root.notificationsList
            spacing: 6
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                width: notifListView.width
                height: 52
                radius: 12
                color: Theme.alpha(Theme.background, 0.55)
                border.color: Theme.alpha(Theme.foreground, 0.08)
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 10

                    // App Avatar/Initial Badge
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: Theme.alpha(Theme.accent, 0.18)
                        border.color: Theme.alpha(Theme.accent, 0.3)
                        border.width: 1
                        anchors.verticalCenter: parent.verticalCenter
                        clip: true

                        Image {
                            id: notifItemImg
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            fillMode: Image.PreserveAspectFit
                            source: (modelData.icon && modelData.icon.length > 0) ? modelData.icon : ""
                            visible: status === Image.Ready && source != ""
                        }

                        Text {
                            anchors.centerIn: parent
                            text: (modelData.app && modelData.app.length > 0) ? modelData.app.charAt(0).toUpperCase() : "N"
                            font.family: "Outfit"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: Theme.accent
                            visible: !notifItemImg.visible
                        }
                    }

                    // Text column
                    Column {
                        width: parent.width - 28 - 20 - 20
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            text: modelData.summary ? modelData.summary : "Notification"
                            font.family: "Outfit"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: Theme.foreground
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: modelData.body ? modelData.body : ""
                            font.family: "Outfit"
                            font.pixelSize: 10
                            font.weight: Font.Normal
                            color: Theme.alpha(Theme.foreground, 0.70)
                            elide: Text.ElideRight
                            width: parent.width
                            visible: text.length > 0
                        }
                    }

                    // Individual Dismiss Button
                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        color: dismissMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.15) : "transparent"
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            anchors.centerIn: parent
                            width: 10
                            height: 10
                            source: root.trashSvg
                            opacity: dismissMouse.containsMouse ? 1.0 : 0.4
                        }

                        MouseArea {
                            id: dismissMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.handleDismiss(modelData.id)
                        }
                    }
                }
            }
        }

        // Empty state
        Item {
            anchors.fill: parent
            visible: !root.hasNotifications

            Column {
                anchors.centerIn: parent
                spacing: 6

                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Theme.alpha(Theme.accent, 0.15)
                    anchors.horizontalCenter: parent.horizontalCenter
                    Image { anchors.centerIn: parent; width: 16; height: 16; source: root.bellSvg }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "All caught up"
                    font.family: "Outfit"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: Theme.foreground
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No active notifications • Desktop quiet"
                    font.family: "Outfit"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: Theme.alpha(Theme.foreground, 0.5)
                }
            }
        }
    }

    // ── MEDIA PLAYER CONTENT ─────────────────────────────────────────────────
    Item {
        anchors.top: headerRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10
        visible: root.currentTab === 1

        Row {
            anchors.fill: parent
            spacing: 14

            Rectangle {
                width: 64
                height: 64
                radius: 12
                color: Theme.alpha(Theme.surface, 0.9)
                border.color: Theme.alpha(Theme.foreground, 0.1)
                anchors.verticalCenter: parent.verticalCenter
                clip: true

                Image {
                    anchors.fill: parent
                    source: (root.activePlayer && root.activePlayer.trackArtUrl) ? root.activePlayer.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: source.toString().length > 0
                }

                Image {
                    anchors.centerIn: parent
                    width: 26; height: 26
                    source: root.musicSvg
                    visible: !(root.activePlayer && root.activePlayer.trackArtUrl && root.activePlayer.trackArtUrl.length > 0)
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 78
                spacing: 6

                Column {
                    spacing: 2
                    width: parent.width

                    Text {
                        text: (root.activePlayer && root.activePlayer.trackTitle) ? root.activePlayer.trackTitle : "Nothing Playing"
                        font.family: "Outfit"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: Theme.foreground
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        text: (root.activePlayer && root.activePlayer.trackArtist) ? root.activePlayer.trackArtist : "Idle"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Theme.alpha(Theme.foreground, 0.70)
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }

                Row {
                    spacing: 12

                    Rectangle {
                        width: 28; height: 28; radius: 14; color: Theme.alpha(Theme.surface, 0.8)
                        anchors.verticalCenter: parent.verticalCenter
                        Image { anchors.centerIn: parent; width: 12; height: 12; source: root.prevSvg }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.activePlayer && root.activePlayer.canGoPrevious) root.activePlayer.previous()
                        }
                    }

                    Rectangle {
                        width: 32; height: 32; radius: 16; color: Theme.accent
                        anchors.verticalCenter: parent.verticalCenter
                        Image {
                            anchors.centerIn: parent
                            width: 14; height: 14
                            source: (root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing) ? root.pauseSvg : root.playSvg
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.activePlayer) root.activePlayer.togglePlaying()
                        }
                    }

                    Rectangle {
                        width: 28; height: 28; radius: 14; color: Theme.alpha(Theme.surface, 0.8)
                        anchors.verticalCenter: parent.verticalCenter
                        Image { anchors.centerIn: parent; width: 12; height: 12; source: root.nextSvg }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.activePlayer && root.activePlayer.canGoNext) root.activePlayer.next()
                        }
                    }
                }
            }
        }
    }
}
