//@ pragma Env QS_NO_RELOAD_POPUP=1
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Widgets
import "."

PanelWindow {
    id: root

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    onClosed: Qt.quit()

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-launcher-theme"

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    readonly property string configPath: homeDir + "/.hyprconf/quickshell/launcher/config.json"
    property real wallpaperTimestamp: Date.now()
    readonly property string quadWallPath: "file://" + homeDir + "/.hyprconf/hypr/.cache/wall.quad"
    readonly property string wallpaperPath: "file://" + homeDir + "/.hyprconf/hypr/.cache/current_wallpaper.png"

    property string currentTheme: "style-1"
    property string toastText: ""
    property bool showToast: false

    // Read current theme from config.json
    Process {
        id: configReader
        command: ["cat", root.configPath]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(text.trim())
                        if (parsed.theme) {
                            root.currentTheme = parsed.theme
                        }
                    } catch(e) {}
                }
            }
        }
    }

    Process {
        id: themeWriter
        command: []
    }

    // Save chosen theme to config.json
    function setTheme(themeId) {
        root.currentTheme = themeId
        var jsonStr = JSON.stringify({ "theme": themeId }, null, 2)
        themeWriter.command = ["bash", "-c", "echo '" + jsonStr + "' > " + root.configPath]
        themeWriter.running = true
        root.toastText = "Launcher theme set to " + (themeId === "style-1" ? "Style 1 (Slanted Split)" : "Style 2 (Panoramic Grid)")
        root.showToast = true
        autoCloseTimer.restart()
    }

    Process {
        id: launcherStarter
        command: []
    }

    function launchCurrentTheme() {
        var script = homeDir + "/.hyprconf/hypr/scripts/sh/qs-launcher.sh"
        launcherStarter.command = ["bash", "-c", "pkill -f 'qs -c launcher' || true; sleep 0.1; " + script]
        launcherStarter.running = true
        root.visible = false
        autoCloseTimer.restart()
    }

    Timer {
        id: autoCloseTimer
        interval: 380
        repeat: false
        onTriggered: {
            root.visible = false
            Qt.quit()
        }
    }

    // ── BUBBLY OPENING / CLOSING ANIMATIONS ────────────────────────────────
    property real animScale: 0.82
    property real animOpacity: 0.0
    property bool isExiting: false

    ParallelAnimation {
        id: openAnim
        running: true
        NumberAnimation {
            target: root
            property: "animScale"
            from: 0.82
            to: 1.0
            duration: 300
            easing.type: Easing.OutBack
            easing.overshoot: 1.35
        }
        NumberAnimation {
            target: root
            property: "animOpacity"
            from: 0.0
            to: 1.0
            duration: 200
            easing.type: Easing.OutQuad
        }
    }

    ParallelAnimation {
        id: closeAnim
        NumberAnimation {
            target: root
            property: "animScale"
            to: 0.86
            duration: 190
            easing.type: Easing.InBack
            easing.overshoot: 1.15
        }
        NumberAnimation {
            target: root
            property: "animOpacity"
            to: 0.0
            duration: 170
            easing.type: Easing.InQuad
        }
        onFinished: {
            Qt.quit()
        }
    }

    function requestClose() {
        if (root.isExiting) return
        root.isExiting = true
        openAnim.stop()
        closeAnim.restart()
    }

    IpcHandler {
        target: "launcher-theme"
        function close() {
            root.requestClose()
        }
    }

    // Dismiss on Escape
    Shortcut {
        sequence: "Escape"
        onActivated: root.requestClose()
    }

    // Transparent click-outside-to-dismiss area (unblurred desktop)
    MouseArea {
        anchors.fill: parent
        onClicked: root.requestClose()
    }

    // Central Theme Switcher Card
    Rectangle {
        id: card
        width: 860
        height: 500
        anchors.centerIn: parent
        scale: root.animScale
        opacity: root.animOpacity
        transformOrigin: Item.Center
        radius: 28
        color: Theme.alpha(Theme.background, 0.82)
        border.width: 1
        border.color: Theme.alpha(Theme.foreground, 0.14)

        // Catch clicks inside card
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 20

            // ── Header ───────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Rectangle {
                        width: 10
                        height: 10
                        radius: 5
                        color: Theme.accent
                    }
                    Text {
                        text: "CHOOSE LAUNCHER THEME"
                        font.family: "Outfit"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        font.letterSpacing: 1.5
                        color: Theme.foreground
                    }
                }

                // Close Button (✕)
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: closeMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.15) : Theme.alpha(Theme.surface, 0.60)
                    border.width: 1
                    border.color: Theme.alpha(Theme.foreground, 0.10)

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 12
                        color: Theme.foreground
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.requestClose()
                    }
                }
            }

            // ── Theme Preview Cards (Side by Side) ───────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 22

                // =============================================================
                // CARD 1: Style 1 — Slanted Split (Quad Art)
                // =============================================================
                Rectangle {
                    id: cardStyle1
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 20
                    readonly property bool isActive: root.currentTheme === "style-1"

                    color: isActive
                        ? Theme.alpha(Theme.surface, 0.95)
                        : (mouse1.containsMouse ? Theme.alpha(Theme.surface, 0.75) : Theme.alpha(Theme.surface, 0.40))
                    border.width: isActive ? 2 : 1
                    border.color: isActive ? Theme.accent : (mouse1.containsMouse ? Theme.alpha(Theme.accent, 0.50) : Theme.alpha(Theme.foreground, 0.12))
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    Behavior on color { ColorAnimation { duration: 140 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 12

                        // Mockup Preview Frame
                        ClippingRectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 205
                            radius: 12
                            color: Theme.alpha(Theme.background, 0.80)
                            border.width: 1
                            border.color: Theme.alpha(Theme.foreground, 0.15)

                            Row {
                                anchors.fill: parent

                                // Left 48%: Slanted Quad Wallpaper
                                Item {
                                    width: parent.width * 0.48
                                    height: parent.height

                                    Image {
                                        anchors.fill: parent
                                        source: root.quadWallPath
                                        fillMode: Image.Stretch
                                    }

                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.margins: 8
                                        width: 6
                                        height: 6
                                        radius: 3
                                        color: Theme.accent
                                    }
                                }

                                // Right 52%: App list preview mockup
                                Item {
                                    width: parent.width * 0.52
                                    height: parent.height

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 6

                                        // Mini search bar
                                        Rectangle {
                                            width: parent.width
                                            height: 18
                                            radius: 6
                                            color: Theme.alpha(Theme.background, 0.90)
                                            border.width: 1
                                            border.color: Theme.alpha(Theme.foreground, 0.15)
                                        }

                                        // Mini category pills
                                        Row {
                                            spacing: 4
                                            Rectangle { width: 24; height: 10; radius: 5; color: Theme.accent }
                                            Rectangle { width: 30; height: 10; radius: 5; color: Theme.alpha(Theme.foreground, 0.15) }
                                            Rectangle { width: 28; height: 10; radius: 5; color: Theme.alpha(Theme.foreground, 0.15) }
                                        }

                                        // Mini items
                                        Column {
                                            width: parent.width
                                            spacing: 4
                                            Repeater {
                                                model: 3
                                                Rectangle {
                                                    width: parent.width
                                                    height: 22
                                                    radius: 5
                                                    color: index === 0 ? Theme.alpha(Theme.accent, 0.20) : Theme.alpha(Theme.foreground, 0.05)
                                                    border.width: index === 0 ? 1 : 0
                                                    border.color: Theme.accent
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Theme Title & Status Badge
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: "Style 1: Slanted Split"
                                font.family: "Outfit"
                                font.pixelSize: 14
                                font.weight: Font.Bold
                                color: Theme.foreground
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                visible: cardStyle1.isActive
                                height: 20
                                radius: 10
                                implicitWidth: activeLabel1.implicitWidth + 14
                                color: Theme.accent
                                Text {
                                    id: activeLabel1
                                    anchors.centerIn: parent
                                    text: "✓ ACTIVE"
                                    font.family: "Outfit"
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    color: Theme.on_primary
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        // Select / Action Button
                        Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            radius: 10
                            color: cardStyle1.isActive
                                ? Theme.accent
                                : (mouse1.containsMouse ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surface, 0.80))
                            border.width: 1
                            border.color: cardStyle1.isActive ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)

                            Text {
                                anchors.centerIn: parent
                                text: cardStyle1.isActive ? "Selected" : "Select Style 1"
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: cardStyle1.isActive ? Theme.on_primary : Theme.foreground
                            }
                        }
                    }

                    MouseArea {
                        id: mouse1
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setTheme("style-1")
                    }
                }

                // =============================================================
                // CARD 2: Style 2 — Panoramic Grid (Wallpaper Banner & Grid)
                // =============================================================
                Rectangle {
                    id: cardStyle2
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 20
                    readonly property bool isActive: root.currentTheme === "style-2"

                    color: isActive
                        ? Theme.alpha(Theme.surface, 0.95)
                        : (mouse2.containsMouse ? Theme.alpha(Theme.surface, 0.75) : Theme.alpha(Theme.surface, 0.40))
                    border.width: isActive ? 2 : 1
                    border.color: isActive ? Theme.accent : (mouse2.containsMouse ? Theme.alpha(Theme.accent, 0.50) : Theme.alpha(Theme.foreground, 0.12))
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    Behavior on color { ColorAnimation { duration: 140 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 12

                        // Mockup Preview Frame
                        ClippingRectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 205
                            radius: 12
                            color: Theme.alpha(Theme.background, 0.80)
                            border.width: 1
                            border.color: Theme.alpha(Theme.foreground, 0.15)

                            Column {
                                anchors.fill: parent

                                // Top 46%: Panoramic Wallpaper Banner + Floating Search
                                Item {
                                    width: parent.width
                                    height: parent.height * 0.46

                                    Image {
                                        anchors.fill: parent
                                        source: root.wallpaperPath
                                        fillMode: Image.PreserveAspectCrop
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        color: Theme.alpha(Theme.background, 0.35)
                                    }

                                    // Floating search bar pill mockup
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: parent.width - 24
                                        height: 18
                                        radius: 9
                                        color: Theme.alpha(Theme.background, 0.90)
                                        border.width: 1
                                        border.color: Theme.accent
                                    }
                                }

                                // Bottom 54%: 6x2 App Grid Mockup + 3 Mode Pills
                                Item {
                                    width: parent.width
                                    height: parent.height * 0.54

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 6

                                        // 6-column dots mockup
                                        Grid {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            columns: 6
                                            spacing: 12

                                            Repeater {
                                                model: 12
                                                Column {
                                                    spacing: 2
                                                    Rectangle {
                                                        width: 14
                                                        height: 14
                                                        radius: 7
                                                        color: index === 0 ? Theme.accent : Theme.alpha(Theme.foreground, 0.20)
                                                    }
                                                    Rectangle {
                                                        width: 14
                                                        height: 3
                                                        radius: 1.5
                                                        color: Theme.alpha(Theme.foreground, 0.15)
                                                    }
                                                }
                                            }
                                        }

                                        Item { Layout.fillHeight: true }

                                        // 3 Mode switcher pill buttons
                                        Row {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            spacing: 6

                                            Rectangle { width: 44; height: 12; radius: 6; color: Theme.accent }
                                            Rectangle { width: 44; height: 12; radius: 6; color: Theme.alpha(Theme.foreground, 0.15) }
                                            Rectangle { width: 44; height: 12; radius: 6; color: Theme.alpha(Theme.foreground, 0.15) }
                                        }
                                    }
                                }
                            }
                        }

                        // Theme Title & Status Badge
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: "Style 2: Panoramic Grid"
                                font.family: "Outfit"
                                font.pixelSize: 14
                                font.weight: Font.Bold
                                color: Theme.foreground
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                visible: cardStyle2.isActive
                                height: 20
                                radius: 10
                                implicitWidth: activeLabel2.implicitWidth + 14
                                color: Theme.accent
                                Text {
                                    id: activeLabel2
                                    anchors.centerIn: parent
                                    text: "✓ ACTIVE"
                                    font.family: "Outfit"
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    color: Theme.on_primary
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        // Select / Action Button
                        Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            radius: 10
                            color: cardStyle2.isActive
                                ? Theme.accent
                                : (mouse2.containsMouse ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surface, 0.80))
                            border.width: 1
                            border.color: cardStyle2.isActive ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)

                            Text {
                                anchors.centerIn: parent
                                text: cardStyle2.isActive ? "Selected" : "Select Style 2"
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: cardStyle2.isActive ? Theme.on_primary : Theme.foreground
                            }
                        }
                    }

                    MouseArea {
                        id: mouse2
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setTheme("style-2")
                    }
                }
            }

            // ── Footer ────────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Tip: Press SUPER + Space to open the active launcher at any time"
                    font.family: "Outfit"
                    font.pixelSize: 10
                    color: Theme.alpha(Theme.foreground, 0.40)
                    Layout.fillWidth: true
                }

                Rectangle {
                    height: 32
                    radius: 8
                    implicitWidth: launchNowText.implicitWidth + 24
                    color: launchMouse.containsMouse ? Theme.primary : Theme.accent
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        id: launchNowText
                        anchors.centerIn: parent
                        text: "Launch Active Theme"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: Theme.on_primary
                    }

                    MouseArea {
                        id: launchMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.launchCurrentTheme()
                    }
                }
            }
        }

        // Notification Toast
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.showToast
            height: 32
            radius: 16
            implicitWidth: toastLabel.implicitWidth + 28
            color: Theme.surface
            border.width: 1
            border.color: Theme.accent

            Text {
                id: toastLabel
                anchors.centerIn: parent
                text: root.toastText
                font.family: "Outfit"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: Theme.foreground
            }
        }
    }
}
