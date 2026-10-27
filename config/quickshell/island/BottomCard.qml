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

    signal openWeatherRequested()

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

    readonly property string packageSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m16.5 9.4-9-5.19M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg>')
    readonly property string terminalSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg>')
    readonly property string alertSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.error + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>')
    readonly property string chatSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>')
    readonly property string globeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>')
    readonly property string codeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>')

    function formatNotifTime(timeVal) {
        if (!timeVal) return "Just now"
        var d = new Date(timeVal)
        if (isNaN(d.getTime())) return "Recent"
        var now = new Date()
        var diffSec = Math.floor((now.getTime() - d.getTime()) / 1000)
        if (diffSec < 60) return "Just now"
        if (diffSec < 3600) return Math.floor(diffSec / 60) + "m ago"
        if (diffSec < 86400) return Math.floor(diffSec / 3600) + "h ago"
        var hours = d.getHours().toString().padStart(2, '0')
        var mins = d.getMinutes().toString().padStart(2, '0')
        return hours + ":" + mins
    }

    function getNotificationIcon(rawIcon, app, summary) {
        if (rawIcon && typeof rawIcon === "string" && rawIcon.trim().length > 0) {
            var iconTrim = rawIcon.trim()
            if (iconTrim.indexOf("/") === 0 || iconTrim.indexOf("file://") === 0 || iconTrim.indexOf("image://") === 0) {
                return iconTrim
            }
            try {
                var resolved = Quickshell.iconPath(iconTrim, true)
                if (resolved && resolved.length > 0) return resolved
            } catch(e) {}
        }

        var appStr = (app || "").toLowerCase()
        var sumStr = (summary || "").toLowerCase()
        var combo = appStr + " " + sumStr

        if (appStr.length > 0) {
            try {
                var appRes = Quickshell.iconPath(appStr.replace(/\s+/g, "-"), true)
                if (appRes && appRes.length > 0) return appRes
            } catch(e) {}
        }

        if (combo.includes("package") || combo.includes("update") || combo.includes("pacman") || combo.includes("paru") || combo.includes("aur") || combo.includes("upgrade")) {
            try {
                var pkgIcon = Quickshell.iconPath("system-software-update", true) || Quickshell.iconPath("package-x-generic", true) || Quickshell.iconPath("package", true)
                if (pkgIcon && pkgIcon.length > 0) return pkgIcon
            } catch(e) {}
            return root.packageSvg
        }

        if (combo.includes("terminal") || combo.includes("kitty") || combo.includes("alacritty") || combo.includes("bash") || combo.includes("fish")) {
            return root.terminalSvg
        }

        if (combo.includes("code") || combo.includes("ide") || combo.includes("nvim") || combo.includes("antigravity")) {
            return root.codeSvg
        }

        if (combo.includes("discord") || combo.includes("telegram") || combo.includes("chat") || combo.includes("message")) {
            return root.chatSvg
        }

        if (combo.includes("firefox") || combo.includes("chrome") || combo.includes("brave") || combo.includes("browser")) {
            return root.globeSvg
        }

        if (combo.includes("music") || combo.includes("spotify") || combo.includes("audio") || combo.includes("song")) {
            return root.musicSvg
        }

        if (combo.includes("error") || combo.includes("fail") || combo.includes("warn") || combo.includes("alert")) {
            return root.alertSvg
        }

        return root.bellSvg
    }

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

            // Weather pill (Clickable to open Weather Page)
            Rectangle {
                height: 20
                width: weatherRow.width + 16
                radius: 10
                color: weatherMouse.containsMouse ? Theme.alpha(Theme.accent, 0.20) : Theme.alpha(Theme.surface, 0.8)
                border.color: weatherMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.08)
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter
                scale: weatherMouse.pressed ? 0.95 : (weatherMouse.containsMouse ? 1.04 : 1.0)
                Behavior on scale { NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Row {
                    id: weatherRow
                    anchors.centerIn: parent
                    spacing: 5

                    Image {
                        width: 11
                        height: 11
                        source: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + (weatherMouse.containsMouse ? Theme.accent : Theme.foreground) + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9z"/></svg>')
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        id: weatherText
                        text: root.weatherString
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: weatherMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.85)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: weatherMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openWeatherRequested()
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
                id: notifCard
                width: notifListView.width
                implicitHeight: Math.max(56, contentCol.implicitHeight + 18)
                height: implicitHeight
                radius: 12
                color: itemHoverArea.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.background, 0.55)
                border.color: itemHoverArea.containsMouse ? Theme.alpha(Theme.accent, 0.35) : Theme.alpha(Theme.foreground, 0.08)
                border.width: 1

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                MouseArea {
                    id: itemHoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.rawNotif && typeof modelData.rawNotif.invoke === "function") {
                            try { modelData.rawNotif.invoke("default") } catch(e) {}
                        }
                    }
                }

                // App / Category Icon Squircle
                Rectangle {
                    id: notifIconBox
                    width: 32
                    height: 32
                    radius: 10
                    color: Theme.alpha(Theme.accent, 0.14)
                    border.color: Theme.alpha(Theme.accent, 0.28)
                    border.width: 1
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.top: parent.top
                    anchors.topMargin: 10
                    clip: true

                    Image {
                        id: notifItemImg
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        fillMode: Image.PreserveAspectFit
                        source: root.getNotificationIcon(modelData.icon, modelData.app, modelData.summary)
                        sourceSize: Qt.size(36, 36)
                    }
                }

                // Individual Dismiss Button
                Rectangle {
                    id: notifDismissBtn
                    width: 22
                    height: 22
                    radius: 11
                    z: 5
                    color: dismissMouse.containsMouse ? Theme.alpha(Theme.error, 0.25) : "transparent"
                    border.color: dismissMouse.containsMouse ? Theme.alpha(Theme.error, 0.40) : "transparent"
                    border.width: 1
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.top: parent.top
                    anchors.topMargin: 9

                    Image {
                        anchors.centerIn: parent
                        width: 11
                        height: 11
                        source: root.trashSvg
                        opacity: dismissMouse.containsMouse ? 1.0 : 0.40
                    }

                    MouseArea {
                        id: dismissMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.handleDismiss(modelData.id)
                    }
                }

                // Content Column (dynamically expands with content)
                Column {
                    id: contentCol
                    anchors.left: notifIconBox.right
                    anchors.leftMargin: 10
                    anchors.right: notifDismissBtn.left
                    anchors.rightMargin: 6
                    anchors.top: parent.top
                    anchors.topMargin: 9
                    spacing: 2

                    // Meta Row: App name & Timestamp
                    Row {
                        width: parent.width
                        spacing: 5

                        Text {
                            text: (modelData.app && modelData.app.length > 0) ? modelData.app : "System"
                            font.family: "Outfit"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            color: Theme.accent
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        Text {
                            text: "•"
                            font.pixelSize: 9
                            color: Theme.alpha(Theme.foreground, 0.30)
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: root.formatNotifTime(modelData.time)
                            font.family: "Outfit"
                            font.pixelSize: 9
                            font.weight: Font.Normal
                            color: Theme.alpha(Theme.foreground, 0.45)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Summary / Title
                    Text {
                        text: modelData.summary ? modelData.summary : "Notification"
                        font.family: "Outfit"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: Theme.foreground
                        wrapMode: Text.Wrap
                        width: parent.width
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }

                    // Body
                    Text {
                        text: modelData.body ? modelData.body : ""
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Normal
                        color: Theme.alpha(Theme.foreground, 0.78)
                        lineHeight: 1.25
                        wrapMode: Text.Wrap
                        width: parent.width
                        maximumLineCount: 6
                        elide: Text.ElideRight
                        visible: text.length > 0
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
