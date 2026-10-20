import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "."

Item {
    id: lockscreenRoot
    anchors.fill: parent

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string lockSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>')
    readonly property string userSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>')
    readonly property string moveSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="5 9 2 12 5 15"/><polyline points="9 5 12 2 15 5"/><polyline points="15 19 12 22 9 19"/><polyline points="19 9 22 12 19 15"/><line x1="2" y1="12" x2="22" y2="12"/><line x1="12" y1="2" x2="12" y2="22"/></svg>')
    readonly property string cloudSunSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2v2"/><path d="m4.93 4.93 1.41 1.41"/><path d="M20 12h2"/><path d="m19.07 4.93-1.41 1.41"/><path d="M15.947 12.65a4 4 0 0 0-5.925-4.128"/><path d="M13 22H7a5 5 0 1 1 4.9-6H13a3 3 0 0 1 0 6z"/></svg>')
    readonly property string musicSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></svg>')
    readonly property string crossSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>')
    readonly property string eyeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>')
    readonly property string editSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 20h9"/><path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"/></svg>')
    readonly property string slidersSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="4" y1="21" x2="4" y2="14"/><line x1="4" y1="10" x2="4" y2="3"/><line x1="12" y1="21" x2="12" y2="12"/><line x1="12" y1="8" x2="12" y2="3"/><line x1="20" y1="21" x2="20" y2="16"/><line x1="20" y1="12" x2="20" y2="3"/><line x1="1" y1="14" x2="7" y2="14"/><line x1="9" y1="8" x2="15" y2="8"/><line x1="17" y1="16" x2="23" y2="16"/></svg>')
    readonly property string layersSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="12 2 2 7 12 12 22 7 12 2"/><polyline points="2 17 12 22 22 17"/><polyline points="2 12 12 17 22 12"/></svg>')
    readonly property string alignSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="2" x2="12" y2="22"/><rect x="4" y="6" width="16" height="4" rx="1"/><rect x="6" y="14" width="12" height="4" rx="1"/></svg>')

    // Studio View Modes: 0 = Canvas Editor, 1 = Clean Live Preview, 2 = Widget Controls & Backgrounds
    property int studioMode: 0
    property string selectedModuleKey: "user_avatar"

    // Settings category tab when in studioMode === 2
    property int controlCategoryTab: 0

    function getWidgetBackground(key) {
        if (!window.config || !window.config.widget_backgrounds) return true
        return window.config.widget_backgrounds[key] !== undefined ? window.config.widget_backgrounds[key] : true
    }

    function alignSelectedToCenter() {
        if (selectedModuleKey && selectedModuleKey.length > 0) {
            var currY = (window.config.positions && window.config.positions[selectedModuleKey]) ? window.config.positions[selectedModuleKey].y : 0.50
            window.updateWidgetPosition(selectedModuleKey, 0.50, currY)
        } else {
            alignAllToCenter()
        }
    }

    function alignAllToCenter() {
        var keys = ["clock", "quote", "user_avatar", "username", "session_lock", "input_field", "audio_visualizer", "weather", "system_stats"]
        for (var i = 0; i < keys.length; i++) {
            var k = keys[i]
            var currY = (window.config.positions && window.config.positions[k]) ? window.config.positions[k].y : 0.50
            window.updateWidgetPosition(k, 0.50, currY)
        }
    }

    function alignAuthStackWithAvatar() {
        var avX = (window.config.positions && window.config.positions.user_avatar) ? window.config.positions.user_avatar.x : 0.85
        // Safe max normX so 380px password capsule fits cleanly without edge overflow
        var targetX = Math.max(0.12, Math.min(0.88, avX))
        var avY = (window.config.positions && window.config.positions.user_avatar) ? window.config.positions.user_avatar.y : 0.40
        var unY = (window.config.positions && window.config.positions.username) ? window.config.positions.username.y : 0.50
        var slY = (window.config.positions && window.config.positions.session_lock) ? window.config.positions.session_lock.y : 0.54
        var inY = (window.config.positions && window.config.positions.input_field) ? window.config.positions.input_field.y : 0.62

        window.updateWidgetPosition("user_avatar", targetX, avY)
        window.updateWidgetPosition("username", targetX, unY)
        window.updateWidgetPosition("session_lock", targetX, slY)
        window.updateWidgetPosition("input_field", targetX, inY)
    }

    function resetLayoutToDefaults() {
        var defs = {
            clock: { x: 0.50, y: 0.12, scale: 1.0 },
            quote: { x: 0.50, y: 0.20, scale: 1.0 },
            user_avatar: { x: 0.50, y: 0.40, scale: 1.0 },
            username: { x: 0.50, y: 0.50, scale: 1.0 },
            session_lock: { x: 0.50, y: 0.54, scale: 1.0 },
            input_field: { x: 0.50, y: 0.62, scale: 1.0 },
            audio_visualizer: { x: 0.50, y: 0.74, scale: 1.0 },
            weather: { x: 0.50, y: 0.85, scale: 1.0 },
            media_player: { x: 0.25, y: 0.88, scale: 1.0 },
            system_stats: { x: 0.50, y: 0.92, scale: 1.0 }
        }
        for (var k in defs) {
            window.updateWidgetPosition(k, defs[k].x, defs[k].y)
            window.updateWidgetScale(k, defs[k].scale)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // =====================================================================
        // TOP STUDIO TOOLBAR & MODE SWITCHER
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            height: 48
            radius: 14
            color: Theme.alpha(Theme.surface, 0.60)
            border.width: 1
            border.color: Theme.alpha(Theme.accent, 0.25)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 12

                // Mode Selector Segmented Pill
                Row {
                    spacing: 6
                    Layout.alignment: Qt.AlignVCenter

                    Repeater {
                        model: [
                            { name: "Canvas Editor", modeIdx: 0, iconSvg: lockscreenRoot.editSvg },
                            { name: "Live Preview", modeIdx: 1, iconSvg: lockscreenRoot.eyeSvg },
                            { name: "Widget Controls & BG", modeIdx: 2, iconSvg: lockscreenRoot.slidersSvg }
                        ]

                        Rectangle {
                            height: 32
                            radius: 16
                            implicitWidth: modeRow.implicitWidth + 24
                            readonly property bool isSelected: lockscreenRoot.studioMode === modelData.modeIdx
                            color: isSelected ? Theme.accent : (modeMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.40))
                            border.width: 1
                            border.color: isSelected ? Theme.accent : Theme.alpha(Theme.accent, 0.25)
                            Behavior on color { ColorAnimation { duration: 130 } }

                            Row {
                                id: modeRow
                                anchors.centerIn: parent
                                spacing: 6
                                Image {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 14; height: 14
                                    source: modelData.iconSvg
                                    sourceSize: Qt.size(28, 28)
                                    opacity: parent.parent.isSelected ? 1.0 : 0.80
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name
                                    color: parent.parent.isSelected ? Theme.on_primary : Theme.foreground
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    font.weight: parent.parent.isSelected ? Font.DemiBold : Font.Normal
                                }
                            }

                            MouseArea {
                                id: modeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: lockscreenRoot.studioMode = modelData.modeIdx
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Quick Action Buttons
                Row {
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter

                    // Align Center X
                    Rectangle {
                        height: 32
                        radius: 16
                        implicitWidth: alignCenterRow.implicitWidth + 20
                        visible: lockscreenRoot.studioMode === 0
                        color: alignCenterMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.45)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.35)

                        Row {
                            id: alignCenterRow
                            anchors.centerIn: parent
                            spacing: 6
                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 13; height: 13
                                source: lockscreenRoot.alignSvg
                                sourceSize: Qt.size(26, 26)
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Center X"
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }
                        }

                        MouseArea {
                            id: alignCenterMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: lockscreenRoot.alignSelectedToCenter()
                        }
                    }

                    // Stack with Avatar X (Fixes avatar and auth field misalignment!)
                    Rectangle {
                        height: 32
                        radius: 16
                        implicitWidth: stackAvatarRow.implicitWidth + 20
                        visible: lockscreenRoot.studioMode === 0
                        color: stackAvatarMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.45)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.35)

                        Row {
                            id: stackAvatarRow
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "⇄"
                                color: Theme.accent
                                font.family: "Outfit"
                                font.pixelSize: 13
                                font.weight: Font.Bold
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Stack with Avatar"
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }
                        }

                        MouseArea {
                            id: stackAvatarMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: lockscreenRoot.alignAuthStackWithAvatar()
                        }
                    }

                    // Reset Positions
                    Rectangle {
                        height: 32
                        radius: 16
                        implicitWidth: resetLayoutRow.implicitWidth + 20
                        visible: lockscreenRoot.studioMode === 0
                        color: resetLayoutMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.45)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.30)

                        Row {
                            id: resetLayoutRow
                            anchors.centerIn: parent
                            spacing: 5
                            Text {
                                text: "↺"
                                color: Theme.accent
                                font.pixelSize: 12
                            }
                            Text {
                                text: "Reset"
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 11
                            }
                        }

                        MouseArea {
                            id: resetLayoutMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: lockscreenRoot.resetLayoutToDefaults()
                        }
                    }

                    // Test Live Lockscreen Action Button
                    Rectangle {
                        height: 32
                        radius: 16
                        implicitWidth: testLockRow.implicitWidth + 20
                        color: testLockMouse.containsMouse ? Theme.alpha(Theme.accent, 0.40) : Theme.alpha(Theme.accent, 0.20)
                        border.width: 1
                        border.color: Theme.accent

                        Row {
                            id: testLockRow
                            anchors.centerIn: parent
                            spacing: 6
                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 13; height: 13
                                source: lockscreenRoot.lockSvg
                                sourceSize: Qt.size(26, 26)
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Test Lockscreen"
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                        }

                        MouseArea {
                            id: testLockMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached(["loginctl", "lock-session"])
                        }
                    }
                }
            }
        }

        // =====================================================================
        // MAIN BODY AREA
        // =====================================================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ─────────────────────────────────────────────────────────────────
            // VIEW 1 & 2: FULL-PAGE 16:9 PROPORTIONAL CANVAS (Editor & Preview)
            // ─────────────────────────────────────────────────────────────────
            Item {
                id: canvasViewport
                anchors.fill: parent
                visible: lockscreenRoot.studioMode === 0 || lockscreenRoot.studioMode === 1

                // 16:9 Landscape Screen Container (Strictly preserves 16:9 aspect ratio)
                Rectangle {
                    id: canvasContainer
                    anchors.centerIn: parent
                    width: Math.min(canvasViewport.width - 24, (canvasViewport.height - 40) * 16.0 / 9.0)
                    height: width * 9.0 / 16.0
                    radius: 18
                    color: Theme.alpha(Theme.surface, 0.60)
                    border.width: 1.5
                    border.color: Theme.alpha(Theme.accent, 0.40)
                    clip: true

                    // Exactly maps 1920x1080 display space to preview dimensions!
                    readonly property real canvasScale: width / 1920.0

                    // Wallpaper with MultiEffect blur & dimming
                    Image {
                        id: previewWallpaper
                        anchors.fill: parent
                        source: window.wallpaperPath
                        fillMode: Image.PreserveAspectCrop
                        smooth: true

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            blurEnabled: true
                            blur: (window.config.backdrop ? window.config.backdrop.blur : 0.65)
                            blurMax: 32
                            brightness: -(window.config.backdrop && window.config.backdrop.dimming !== undefined ? window.config.backdrop.dimming : 0.20)
                        }
                    }

                    // Vignette Overlay
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, (window.config.backdrop ? window.config.backdrop.vignette : 0.65) * 0.75) }
                            GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0.15) }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, window.config.backdrop ? window.config.backdrop.vignette : 0.65) }
                        }
                    }

                    // Center Crosshair Magnetic Alignment Guides (Shown only in Canvas Editor mode)
                    Item {
                        anchors.fill: parent
                        visible: lockscreenRoot.studioMode === 0
                        z: 10

                        // Vertical Center Guide Line
                        Rectangle {
                            x: parent.width / 2
                            width: 1
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            color: Theme.alpha(Theme.accent, 0.25)
                        }

                        // Horizontal Center Guide Line
                        Rectangle {
                            y: parent.height / 2
                            height: 1
                            anchors.left: parent.left
                            anchors.right: parent.right
                            color: Theme.alpha(Theme.accent, 0.20)
                        }

                        // Center 50% Top Badge
                        Rectangle {
                            anchors.top: parent.top
                            anchors.topMargin: 8
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: 18
                            width: 80
                            radius: 9
                            color: Theme.alpha(Theme.background, 0.85)
                            border.width: 1
                            border.color: Theme.alpha(Theme.accent, 0.35)
                            Text {
                                anchors.centerIn: parent
                                text: "CENTER (50%)"
                                color: Theme.accent
                                font.family: "Outfit"
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    // ── FREEFORM INTERACTIVE CANVAS ──────────────────────────
                    Item {
                        id: previewCanvas
                        anchors.fill: parent

                        // 1. Clock & Date Widget
                        ResizableDraggableWidget {
                            moduleKey: "clock"
                            title: "Clock & Date"
                            normX: (window.config.positions && window.config.positions.clock) ? window.config.positions.clock.x : 0.50
                            normY: (window.config.positions && window.config.positions.clock) ? window.config.positions.clock.y : 0.12
                            widgetScale: (window.config.positions && window.config.positions.clock && window.config.positions.clock.scale !== undefined) ? window.config.positions.clock.scale : 1.0
                            previewScale: canvasContainer.canvasScale
                            canvasWidth: canvasContainer.width
                            canvasHeight: canvasContainer.height
                            isSelected: lockscreenRoot.selectedModuleKey === "clock"
                            interactive: lockscreenRoot.studioMode === 0
                            visible: window.config.clock && window.config.clock.enabled
                            onPositionDropped: function(nx, ny) { window.updateWidgetPosition("clock", nx, ny) }
                            onScaleModified: function(s) { window.updateWidgetScale("clock", s) }
                            onWidgetSelected: function(key) { lockscreenRoot.selectedModuleKey = key }

                            Item {
                                width: Math.max(timeRow.implicitWidth, dateText.implicitWidth)
                                height: timeRow.implicitHeight + (dateText.visible ? (dateText.implicitHeight + 4) : 0)

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: -12
                                    radius: 20
                                    visible: lockscreenRoot.getWidgetBackground("clock")
                                    color: Theme.alpha(Theme.surface, 0.45)
                                    border.width: 1
                                    border.color: Theme.alpha(Theme.accent, 0.30)
                                }

                                Column {
                                    id: clockCol
                                    anchors.fill: parent
                                    spacing: 4

                                    Row {
                                        id: timeRow
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 8

                                        Text {
                                            id: previewTimeText
                                            text: {
                                                var d = window.currentTime
                                                var is24h = Boolean(window.config.clock && window.config.clock.format_24h)
                                                if (is24h) return Qt.formatDateTime(d, "HH:mm")
                                                var h = d.getHours() % 12
                                                if (h === 0) h = 12
                                                var hStr = (h < 10 ? "0" : "") + h
                                                var mStr = (d.getMinutes() < 10 ? "0" : "") + d.getMinutes()
                                                return hStr + ":" + mStr
                                            }
                                            color: Theme.accent
                                            font.family: "Outfit"
                                            font.pixelSize: (window.config.clock ? window.config.clock.size : 84)
                                            font.weight: {
                                                var w = window.config.clock ? window.config.clock.weight : "Light"
                                                if (w === "Bold") return Font.Bold
                                                if (w === "Medium") return Font.Medium
                                                return Font.Light
                                            }
                                            font.letterSpacing: 2
                                        }

                                        Text {
                                            anchors.bottom: previewTimeText.bottom
                                            anchors.bottomMargin: 14
                                            text: Qt.formatTime(window.currentTime, "AP")
                                            visible: window.config.clock && !window.config.clock.format_24h && window.config.clock.show_am_pm
                                            color: Theme.alpha(Theme.accent, 0.90)
                                            font.family: "Outfit"
                                            font.pixelSize: 18
                                            font.weight: Font.DemiBold
                                            font.letterSpacing: 2
                                        }
                                    }

                                    Text {
                                        id: dateText
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        visible: window.config.date ? window.config.date.enabled : true
                                        text: {
                                            var d = window.currentTime
                                            if (window.config.date && window.config.date.format === "compact") {
                                                return Qt.formatDate(d, "ddd, MMM d").toUpperCase()
                                            }
                                            return Qt.formatDate(d, "dddd, MMMM d").toUpperCase()
                                        }
                                        color: Theme.alpha(Theme.foreground, 0.75)
                                        font.family: "Outfit"
                                        font.pixelSize: 13
                                        font.weight: Font.Medium
                                        font.letterSpacing: 4
                                    }
                                }
                            }
                        }

                        // 2a. Separated User Avatar Widget
                        ResizableDraggableWidget {
                            moduleKey: "user_avatar"
                            title: "User Avatar"
                            normX: (window.config.positions && window.config.positions.user_avatar) ? window.config.positions.user_avatar.x : ((window.config.positions && window.config.positions.avatar) ? window.config.positions.avatar.x : 0.50)
                            normY: (window.config.positions && window.config.positions.user_avatar) ? window.config.positions.user_avatar.y : 0.38
                            widgetScale: (window.config.positions && window.config.positions.user_avatar && window.config.positions.user_avatar.scale !== undefined) ? window.config.positions.user_avatar.scale : 1.0
                            previewScale: canvasContainer.canvasScale
                            canvasWidth: canvasContainer.width
                            canvasHeight: canvasContainer.height
                            isSelected: lockscreenRoot.selectedModuleKey === "user_avatar"
                            interactive: lockscreenRoot.studioMode === 0
                            visible: (window.config.modules ? (window.config.modules.user_avatar !== false) : true) && (window.config.avatar ? (window.config.avatar.enabled !== false) : true)
                            onPositionDropped: function(nx, ny) { window.updateWidgetPosition("user_avatar", nx, ny) }
                            onScaleModified: function(s) { window.updateWidgetScale("user_avatar", s) }
                            onWidgetSelected: function(key) { lockscreenRoot.selectedModuleKey = key }

                            Item {
                                id: avatarHaloBox
                                readonly property real avSize: (window.config.avatar ? window.config.avatar.size : 116)
                                width: avSize + 40
                                height: avSize + 40

                                // Breathing Halo
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width + (window.glowOpacity * 20)
                                    height: parent.height + (window.glowOpacity * 20)
                                    radius: width / 2
                                    color: Theme.alpha(Theme.accent, (window.config.avatar && window.config.avatar.glow_enabled) ? window.glowOpacity * 0.45 : 0.0)
                                    visible: window.config.avatar && window.config.avatar.glow_enabled
                                }

                                // Orbit ring & Rotating Satellites
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width - 16
                                    height: parent.height - 16
                                    radius: width / 2
                                    color: "transparent"
                                    border.width: 1.2
                                    border.color: Theme.alpha(Theme.accent, 0.40)
                                    visible: window.config.avatar && window.config.avatar.orbit_satellites_enabled
                                    rotation: window.orbitAngle

                                    Rectangle {
                                        width: 8; height: 8; radius: 4
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        y: -4
                                        color: Theme.accent
                                        border.width: 1.5; border.color: "#ffffff"
                                    }
                                    Rectangle {
                                        width: 6; height: 6; radius: 3
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        y: parent.height - 3
                                        color: Theme.secondary
                                        border.width: 1; border.color: "#ffffff"
                                    }
                                }

                                // Outer Concentric Glass Ring (Toggleable Background)
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: avatarHaloBox.avSize + 14
                                    height: avatarHaloBox.avSize + 14
                                    radius: width / 2
                                    visible: lockscreenRoot.getWidgetBackground("user_avatar")
                                    color: Theme.alpha(Theme.surface, 0.40)
                                    border.width: 1.5
                                    border.color: Theme.alpha(Theme.accent, 0.50)
                                }

                                // Circular Masked Avatar Image
                                Item {
                                    id: avatarCircleItem
                                    anchors.centerIn: parent
                                    width: avatarHaloBox.avSize
                                    height: avatarHaloBox.avSize
                                    scale: (window.config.avatar && window.config.avatar.breathing_enabled) ? window.avatarScale : 1.0

                                    Item {
                                        id: avatarMaskShape
                                        width: parent.width
                                        height: parent.height
                                        layer.enabled: true
                                        layer.smooth: true
                                        visible: false
                                        Rectangle { anchors.fill: parent; radius: width / 2; color: "#ffffff"; antialiasing: true }
                                    }

                                    Image {
                                        id: rawAvatarPreview
                                        anchors.fill: parent
                                        source: window.avatarPath
                                        sourceSize: Qt.size(256, 256)
                                        fillMode: Image.PreserveAspectCrop
                                        smooth: true
                                        mipmap: true
                                        visible: false
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: width / 2
                                        color: Theme.surface
                                        antialiasing: true
                                        Image {
                                            anchors.centerIn: parent
                                            width: parent.width * 0.45; height: parent.height * 0.45
                                            source: window.userSvg
                                            sourceSize: Qt.size(64, 64)
                                            visible: rawAvatarPreview.status !== Image.Ready
                                        }
                                    }

                                    MultiEffect {
                                        anchors.fill: parent
                                        source: rawAvatarPreview
                                        visible: rawAvatarPreview.status === Image.Ready
                                        autoPaddingEnabled: false
                                        maskEnabled: true
                                        maskSource: avatarMaskShape
                                        maskThresholdMin: 0.5
                                        maskSpreadAtMin: 1.0
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: width / 2
                                        color: "transparent"
                                        border.width: 1.6
                                        border.color: Theme.alpha(Theme.accent, 0.75)
                                    }
                                }
                            }
                        }

                        // 2b. Separated Username Widget
                        ResizableDraggableWidget {
                            moduleKey: "username"
                            title: "Username"
                            normX: (window.config.positions && window.config.positions.username) ? window.config.positions.username.x : 0.50
                            normY: (window.config.positions && window.config.positions.username) ? window.config.positions.username.y : 0.49
                            widgetScale: (window.config.positions && window.config.positions.username && window.config.positions.username.scale !== undefined) ? window.config.positions.username.scale : 1.0
                            previewScale: canvasContainer.canvasScale
                            canvasWidth: canvasContainer.width
                            canvasHeight: canvasContainer.height
                            isSelected: lockscreenRoot.selectedModuleKey === "username"
                            interactive: lockscreenRoot.studioMode === 0
                            visible: window.config.modules ? (window.config.modules.username !== false) : true
                            onPositionDropped: function(nx, ny) { window.updateWidgetPosition("username", nx, ny) }
                            onScaleModified: function(s) { window.updateWidgetScale("username", s) }
                            onWidgetSelected: function(key) { lockscreenRoot.selectedModuleKey = key }

                            Item {
                                width: usernamePreviewText.implicitWidth + 24
                                height: usernamePreviewText.implicitHeight + 8

                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    visible: lockscreenRoot.getWidgetBackground("username")
                                    color: Theme.alpha(Theme.surface, 0.45)
                                    border.width: 1
                                    border.color: Theme.alpha(Theme.accent, 0.28)
                                }

                                Text {
                                    id: usernamePreviewText
                                    anchors.centerIn: parent
                                    text: "Shell Ninja"
                                    color: Theme.foreground
                                    font.family: "Outfit"
                                    font.pixelSize: 18
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 2
                                }
                            }
                        }

                        // 2c. Separated Session Lock Status Widget
                        ResizableDraggableWidget {
                            moduleKey: "session_lock"
                            title: "Session Lock"
                            normX: (window.config.positions && window.config.positions.session_lock) ? window.config.positions.session_lock.x : 0.50
                            normY: (window.config.positions && window.config.positions.session_lock) ? window.config.positions.session_lock.y : 0.53
                            widgetScale: (window.config.positions && window.config.positions.session_lock && window.config.positions.session_lock.scale !== undefined) ? window.config.positions.session_lock.scale : 1.0
                            previewScale: canvasContainer.canvasScale
                            canvasWidth: canvasContainer.width
                            canvasHeight: canvasContainer.height
                            isSelected: lockscreenRoot.selectedModuleKey === "session_lock"
                            interactive: lockscreenRoot.studioMode === 0
                            visible: window.config.modules ? (window.config.modules.session_lock !== false) : true
                            onPositionDropped: function(nx, ny) { window.updateWidgetPosition("session_lock", nx, ny) }
                            onScaleModified: function(s) { window.updateWidgetScale("session_lock", s) }
                            onWidgetSelected: function(key) { lockscreenRoot.selectedModuleKey = key }

                            Item {
                                width: sessionStatusPreviewRow.implicitWidth + 20
                                height: sessionStatusPreviewRow.implicitHeight + 8

                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    visible: lockscreenRoot.getWidgetBackground("session_lock")
                                    color: Theme.alpha(Theme.surface, 0.40)
                                    border.width: 1
                                    border.color: Theme.alpha(Theme.accent, 0.25)
                                }

                                Row {
                                    id: sessionStatusPreviewRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 6; height: 6; radius: 3
                                        color: Theme.accent
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Session Locked"
                                        color: Theme.alpha(Theme.foreground, 0.70)
                                        font.family: "Outfit"
                                        font.pixelSize: 11
                                        font.weight: Font.Normal
                                        font.letterSpacing: 1.2
                                    }
                                }
                            }
                        }

                        // 2d. Separated Password Input Field Widget
                        ResizableDraggableWidget {
                            moduleKey: "input_field"
                            title: "Password Input"
                            normX: (window.config.positions && window.config.positions.input_field) ? window.config.positions.input_field.x : 0.50
                            normY: (window.config.positions && window.config.positions.input_field) ? window.config.positions.input_field.y : 0.60
                            widgetScale: (window.config.positions && window.config.positions.input_field && window.config.positions.input_field.scale !== undefined) ? window.config.positions.input_field.scale : 1.0
                            previewScale: canvasContainer.canvasScale
                            canvasWidth: canvasContainer.width
                            canvasHeight: canvasContainer.height
                            isSelected: lockscreenRoot.selectedModuleKey === "input_field"
                            interactive: lockscreenRoot.studioMode === 0
                            visible: window.config.modules ? (window.config.modules.input_field !== false) : true
                            onPositionDropped: function(nx, ny) { window.updateWidgetPosition("input_field", nx, ny) }
                            onScaleModified: function(s) { window.updateWidgetScale("input_field", s) }
                            onWidgetSelected: function(key) { lockscreenRoot.selectedModuleKey = key }

                            Rectangle {
                                width: 380
                                height: 52
                                radius: 26
                                color: lockscreenRoot.getWidgetBackground("input_field") ? Theme.alpha(Theme.surface, 0.45) : "transparent"
                                border.width: 1.2
                                border.color: Theme.alpha(Theme.accent, 0.50)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 18
                                    anchors.rightMargin: 16
                                    spacing: 12

                                    Image {
                                        Layout.preferredWidth: 16; Layout.preferredHeight: 16
                                        source: lockscreenRoot.lockSvg
                                        sourceSize: Qt.size(32, 32)
                                        opacity: 0.85
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: "Enter password"
                                        color: Qt.rgba(1, 1, 1, 0.60)
                                        font.family: "Outfit"
                                        font.pixelSize: 14
                                    }
                                }
                            }
                        }

                        // 3. Audio Visualizer Widget (Rounded Bars & Symmetrical CAVA Pattern)
                        ResizableDraggableWidget {
                            moduleKey: "audio_visualizer"
                            title: "Audio Visualizer"
                            normX: (window.config.positions && window.config.positions.audio_visualizer) ? window.config.positions.audio_visualizer.x : 0.50
                            normY: (window.config.positions && window.config.positions.audio_visualizer) ? window.config.positions.audio_visualizer.y : 0.72
                            widgetScale: (window.config.positions && window.config.positions.audio_visualizer && window.config.positions.audio_visualizer.scale !== undefined) ? window.config.positions.audio_visualizer.scale : 1.0
                            previewScale: canvasContainer.canvasScale
                            canvasWidth: canvasContainer.width
                            canvasHeight: canvasContainer.height
                            isSelected: lockscreenRoot.selectedModuleKey === "audio_visualizer"
                            interactive: lockscreenRoot.studioMode === 0
                            visible: window.config.modules ? (window.config.modules.audio_visualizer !== false) : true
                            onPositionDropped: function(nx, ny) { window.updateWidgetPosition("audio_visualizer", nx, ny) }
                            onScaleModified: function(s) { window.updateWidgetScale("audio_visualizer", s) }
                            onWidgetSelected: function(key) { lockscreenRoot.selectedModuleKey = key }

                            LockscreenAudioVisualizer {
                                previewMode: true
                                barCount: 16
                                showBackground: lockscreenRoot.getWidgetBackground("audio_visualizer")
                            }
                        }

                        // 4. Weather Forecast Capsule
                        ResizableDraggableWidget {
                            moduleKey: "weather"
                            title: "Weather Capsule"
                            normX: (window.config.positions && window.config.positions.weather) ? window.config.positions.weather.x : 0.50
                            normY: (window.config.positions && window.config.positions.weather) ? window.config.positions.weather.y : 0.84
                            widgetScale: (window.config.positions && window.config.positions.weather && window.config.positions.weather.scale !== undefined) ? window.config.positions.weather.scale : 1.0
                            previewScale: canvasContainer.canvasScale
                            canvasWidth: canvasContainer.width
                            canvasHeight: canvasContainer.height
                            isSelected: lockscreenRoot.selectedModuleKey === "weather"
                            interactive: lockscreenRoot.studioMode === 0
                            visible: window.config.modules && window.config.modules.weather_widget
                            onPositionDropped: function(nx, ny) { window.updateWidgetPosition("weather", nx, ny) }
                            onScaleModified: function(s) { window.updateWidgetScale("weather", s) }
                            onWidgetSelected: function(key) { lockscreenRoot.selectedModuleKey = key }

                            Rectangle {
                                width: weatherRow.implicitWidth + 28
                                height: 32
                                radius: 16
                                color: lockscreenRoot.getWidgetBackground("weather") ? Theme.alpha(Theme.surface, 0.50) : "transparent"
                                border.width: lockscreenRoot.getWidgetBackground("weather") ? 1 : 0
                                border.color: Theme.alpha(Theme.accent, 0.35)

                                Row {
                                    id: weatherRow
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Image {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 15; height: 15
                                        source: lockscreenRoot.cloudSunSvg
                                        sourceSize: Qt.size(30, 30)
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: {
                                            var c = window.liveWeatherCity
                                            var co = window.liveWeatherCountry
                                            var loc = (c.length > 0 && co.length > 0) ? (c + ", " + co) : (c.length > 0 ? c : (co.length > 0 ? co : "Weather"))
                                            return "24°C  •  " + loc
                                        }
                                        color: Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                    }
                                }
                            }
                        }

                        // 5. Inspirational Quote Pill
                        ResizableDraggableWidget {
                            moduleKey: "quote"
                            title: "Quote Pill"
                            normX: (window.config.positions && window.config.positions.quote) ? window.config.positions.quote.x : 0.50
                            normY: (window.config.positions && window.config.positions.quote) ? window.config.positions.quote.y : 0.20
                            widgetScale: (window.config.positions && window.config.positions.quote && window.config.positions.quote.scale !== undefined) ? window.config.positions.quote.scale : 1.0
                            previewScale: canvasContainer.canvasScale
                            canvasWidth: canvasContainer.width
                            canvasHeight: canvasContainer.height
                            isSelected: lockscreenRoot.selectedModuleKey === "quote"
                            interactive: lockscreenRoot.studioMode === 0
                            visible: window.config.modules && window.config.modules.custom_quote
                            onPositionDropped: function(nx, ny) { window.updateWidgetPosition("quote", nx, ny) }
                            onScaleModified: function(s) { window.updateWidgetScale("quote", s) }
                            onWidgetSelected: function(key) { lockscreenRoot.selectedModuleKey = key }

                            Rectangle {
                                width: quoteRow.implicitWidth + 28
                                height: 32
                                radius: 16
                                color: lockscreenRoot.getWidgetBackground("quote") ? Theme.alpha(Theme.surface, 0.40) : "transparent"
                                border.width: lockscreenRoot.getWidgetBackground("quote") ? 1 : 0
                                border.color: Theme.alpha(Theme.accent, 0.25)

                                Row {
                                    id: quoteRow
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Text { text: "“"; color: Theme.accent; font.family: "Outfit"; font.pixelSize: 14; font.weight: Font.Bold }
                                    Text {
                                        text: window.liveQuoteText
                                        color: Theme.alpha(Theme.foreground, 0.85)
                                        font.family: "Outfit"
                                        font.pixelSize: 12
                                        font.italic: true
                                        font.letterSpacing: 0.8
                                    }
                                    Text { text: "”"; color: Theme.accent; font.family: "Outfit"; font.pixelSize: 14; font.weight: Font.Bold }
                                }
                            }
                        }

                        // 6. Media Player Card
                        ResizableDraggableWidget {
                            moduleKey: "media_player"
                            title: "Media Player"
                            normX: (window.config.positions && window.config.positions.media_player) ? window.config.positions.media_player.x : 0.25
                            normY: (window.config.positions && window.config.positions.media_player) ? window.config.positions.media_player.y : 0.88
                            widgetScale: (window.config.positions && window.config.positions.media_player && window.config.positions.media_player.scale !== undefined) ? window.config.positions.media_player.scale : 1.0
                            previewScale: canvasContainer.canvasScale
                            canvasWidth: canvasContainer.width
                            canvasHeight: canvasContainer.height
                            isSelected: lockscreenRoot.selectedModuleKey === "media_player"
                            interactive: lockscreenRoot.studioMode === 0
                            visible: window.config.modules && window.config.modules.media_player
                            onPositionDropped: function(nx, ny) { window.updateWidgetPosition("media_player", nx, ny) }
                            onScaleModified: function(s) { window.updateWidgetScale("media_player", s) }
                            onWidgetSelected: function(key) { lockscreenRoot.selectedModuleKey = key }

                            Rectangle {
                                width: 320
                                height: 48
                                radius: 24
                                color: lockscreenRoot.getWidgetBackground("media_player") ? Theme.alpha(Theme.surface, 0.45) : "transparent"
                                border.width: lockscreenRoot.getWidgetBackground("media_player") ? 1 : 0
                                border.color: Theme.alpha(Theme.accent, 0.35)

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 10

                                    Rectangle {
                                        width: 28; height: 28; radius: 14
                                        color: Theme.alpha(Theme.accent, 0.25)
                                        border.width: 1; border.color: Theme.alpha(Theme.accent, 0.50)
                                        Image {
                                            anchors.centerIn: parent
                                            width: 14; height: 14
                                            source: lockscreenRoot.musicSvg
                                            sourceSize: Qt.size(28, 28)
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2
                                        Text { text: "Midnight City"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                        Text { text: "M83 — Hurry Up"; color: Theme.alpha(Theme.foreground, 0.65); font.family: "Outfit"; font.pixelSize: 10 }
                                    }
                                }
                            }
                        }

                        // 7. System Stats Graph Widget (CPU, GPU, RAM Smooth Area Graphs)
                        ResizableDraggableWidget {
                            moduleKey: "system_stats"
                            title: "System Stats Graph"
                            normX: (window.config.positions && window.config.positions.system_stats) ? window.config.positions.system_stats.x : 0.50
                            normY: (window.config.positions && window.config.positions.system_stats) ? window.config.positions.system_stats.y : 0.92
                            widgetScale: (window.config.positions && window.config.positions.system_stats && window.config.positions.system_stats.scale !== undefined) ? window.config.positions.system_stats.scale : 1.0
                            previewScale: canvasContainer.canvasScale
                            canvasWidth: canvasContainer.width
                            canvasHeight: canvasContainer.height
                            isSelected: lockscreenRoot.selectedModuleKey === "system_stats"
                            interactive: lockscreenRoot.studioMode === 0
                            visible: window.config.modules && window.config.modules.system_stats
                            onPositionDropped: function(nx, ny) { window.updateWidgetPosition("system_stats", nx, ny) }
                            onScaleModified: function(s) { window.updateWidgetScale("system_stats", s) }
                            onWidgetSelected: function(key) { lockscreenRoot.selectedModuleKey = key }

                            LockscreenSystemGraph {
                                statsData: window.sysStatsData
                                previewMode: false
                                showBackground: lockscreenRoot.getWidgetBackground("system_stats")
                            }
                        }
                    }

                    // Live Clean Preview Watermark Pill
                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 14
                        height: 24
                        width: liveBadgeRow.implicitWidth + 18
                        radius: 12
                        visible: lockscreenRoot.studioMode === 1
                        color: Theme.alpha(Theme.background, 0.85)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.40)

                        Row {
                            id: liveBadgeRow
                            anchors.centerIn: parent
                            spacing: 6
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 7; height: 7; radius: 3.5
                                color: "#10b981"
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "1:1 LIVE LOCKSCREEN PREVIEW"
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1
                            }
                        }
                    }
                }

                // ── FLOATING HUD: SELECTED WIDGET QUICK CONTROLS ─────────────
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 44
                    width: selectedHudRow.implicitWidth + 28
                    radius: 22
                    color: Theme.alpha(Theme.surface, 0.95)
                    border.width: 1.5
                    border.color: Theme.accent
                    visible: lockscreenRoot.studioMode === 0 && lockscreenRoot.selectedModuleKey.length > 0
                    z: 50

                    Row {
                        id: selectedHudRow
                        anchors.centerIn: parent
                        spacing: 12

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Selected: " + lockscreenRoot.selectedModuleKey.toUpperCase()
                            color: Theme.accent
                            font.family: "Outfit"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            font.letterSpacing: 1
                        }

                        // Background Toggle Button
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            height: 28
                            radius: 14
                            implicitWidth: bgHudRow.implicitWidth + 16
                            readonly property bool bgOn: lockscreenRoot.getWidgetBackground(lockscreenRoot.selectedModuleKey)
                            color: bgOn ? Theme.alpha(Theme.accent, 0.35) : Theme.alpha(Theme.surface, 0.60)
                            border.width: 1
                            border.color: bgOn ? Theme.accent : Theme.alpha(Theme.accent, 0.25)

                            Row {
                                id: bgHudRow
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: "🪟"
                                    font.pixelSize: 10
                                }
                                Text {
                                    text: "Background: " + (parent.parent.bgOn ? "ON" : "OFF")
                                    color: parent.parent.bgOn ? Theme.accent : Theme.alpha(Theme.foreground, 0.70)
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var curr = lockscreenRoot.getWidgetBackground(lockscreenRoot.selectedModuleKey)
                                    window.updateWidgetBackground(lockscreenRoot.selectedModuleKey, !curr)
                                }
                            }
                        }

                        // Center Selected X Button
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            height: 28
                            radius: 14
                            implicitWidth: centerHudRow.implicitWidth + 16
                            color: centerHudMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.50)
                            border.width: 1
                            border.color: Theme.alpha(Theme.accent, 0.30)

                            Row {
                                id: centerHudRow
                                anchors.centerIn: parent
                                spacing: 4
                                Text { text: "⌖"; color: Theme.accent; font.pixelSize: 11 }
                                Text { text: "Center X"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 10; font.weight: Font.Medium }
                            }

                            MouseArea {
                                id: centerHudMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: lockscreenRoot.alignSelectedToCenter()
                            }
                        }

                        // Close HUD
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24; height: 24; radius: 12
                            color: closeHudMouse.containsMouse ? Theme.alpha(Theme.error, 0.30) : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: Theme.foreground
                                font.pixelSize: 10
                            }
                            MouseArea {
                                id: closeHudMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: lockscreenRoot.selectedModuleKey = ""
                            }
                        }
                    }
                }
            }

            // ─────────────────────────────────────────────────────────────────
            // VIEW 3: FULL-PAGE MODULAR WIDGET CONTROLS & BACKGROUND TOGGLES
            // ─────────────────────────────────────────────────────────────────
            ColumnLayout {
                anchors.fill: parent
                visible: lockscreenRoot.studioMode === 2
                spacing: 12

                // Sub-category Navigation Tabs
                Row {
                    spacing: 8
                    Layout.alignment: Qt.AlignLeft

                    Repeater {
                        model: [
                            { name: "Widgets & Backgrounds", catIdx: 0 },
                            { name: "Clock & Date", catIdx: 1 },
                            { name: "Avatar Studio", catIdx: 2 },
                            { name: "Atmosphere & Backdrop", catIdx: 3 }
                        ]

                        Rectangle {
                            height: 34
                            radius: 17
                            implicitWidth: catNameText.implicitWidth + 24
                            readonly property bool isSelected: lockscreenRoot.controlCategoryTab === modelData.catIdx
                            color: isSelected ? Theme.accent : (catMouse.containsMouse ? Theme.alpha(Theme.surface, 0.80) : Theme.alpha(Theme.surface, 0.40))
                            border.width: 1
                            border.color: isSelected ? Theme.accent : Theme.alpha(Theme.accent, 0.25)

                            Text {
                                id: catNameText
                                anchors.centerIn: parent
                                text: modelData.name
                                color: parent.isSelected ? Theme.on_primary : Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: parent.isSelected ? Font.DemiBold : Font.Normal
                            }

                            MouseArea {
                                id: catMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: lockscreenRoot.controlCategoryTab = modelData.catIdx
                            }
                        }
                    }
                }

                // Tab Content Viewport
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 16
                    color: Theme.alpha(Theme.surface, 0.45)
                    border.width: 1
                    border.color: Theme.alpha(Theme.accent, 0.25)
                    clip: true

                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 16
                        contentWidth: availableWidth

                        ColumnLayout {
                            width: parent.width
                            spacing: 16

                            // ── SUB-TAB 0: WIDGETS & BACKGROUNDS ─────────────
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 14
                                visible: lockscreenRoot.controlCategoryTab === 0

                                Text {
                                    text: "WIDGET VISIBILITY & BACKGROUND SURFACES"
                                    color: Theme.accent
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.5
                                }

                                Text {
                                    text: "Configure which widgets appear on the lockscreen and toggle the translucent obsidian glass card background on or off for each module."
                                    color: Theme.alpha(Theme.foreground, 0.70)
                                    font.family: "Outfit"
                                    font.pixelSize: 12
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }

                                // Grid of all 10 widgets
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Repeater {
                                        model: [
                                            { key: "clock", name: "Clock & Date Display", desc: "Large digital clock typography with AM/PM pill and date string", configObj: "clock", configProp: "enabled" },
                                            { key: "user_avatar", name: "User Avatar", desc: "Circular user photo with continuous celestial orbit and aura bloom", configObj: "modules", configProp: "user_avatar" },
                                            { key: "username", name: "Username Display", desc: "Active username with modern typography", configObj: "modules", configProp: "username" },
                                            { key: "session_lock", name: "Session Lock Badge", desc: "Session lock status with verifying indicator", configObj: "modules", configProp: "session_lock" },
                                            { key: "input_field", name: "Password Input Field", desc: "Optical glass entry capsule with unlock animation and alerts", configObj: "modules", configProp: "input_field" },
                                            { key: "audio_visualizer", name: "Audio Visualizer Widget", desc: "Real-time symmetrical 16-bar CAVA audio spectrum with rounded bars", configObj: "modules", configProp: "audio_visualizer" },
                                            { key: "weather", name: "Weather Forecast Capsule", desc: "Live ambient temperature, weather conditions, and location", configObj: "modules", configProp: "weather_widget" },
                                            { key: "system_stats", name: "System Stats Graph", desc: "Instantaneous 1-second CPU, GPU, and RAM sparkline area graphs", configObj: "modules", configProp: "system_stats" },
                                            { key: "media_player", name: "Media Player Card", desc: "Active MPRIS media playback pill (auto-hides when nothing is playing)", configObj: "modules", configProp: "media_player" },
                                            { key: "quote", name: "Inspirational Quote / Motto", desc: "Custom status text or personal quote badge", configObj: "modules", configProp: "custom_quote" }
                                        ]

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 64
                                            radius: 12
                                            color: Theme.alpha(Theme.surface, 0.50)
                                            border.width: 1
                                            border.color: Theme.alpha(Theme.accent, 0.20)

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 16
                                                anchors.rightMargin: 16
                                                spacing: 14

                                                Column {
                                                    Layout.fillWidth: true
                                                    spacing: 3
                                                    Text {
                                                        text: modelData.name
                                                        color: Theme.foreground
                                                        font.family: "Outfit"
                                                        font.pixelSize: 13
                                                        font.weight: Font.DemiBold
                                                    }
                                                    Text {
                                                        text: modelData.desc
                                                        color: Theme.alpha(Theme.foreground, 0.60)
                                                        font.family: "Outfit"
                                                        font.pixelSize: 11
                                                        elide: Text.ElideRight
                                                        width: parent.width
                                                    }
                                                }

                                                // Background Surface Toggle
                                                Rectangle {
                                                    height: 30
                                                    radius: 15
                                                    implicitWidth: bgBtnRow.implicitWidth + 18
                                                    readonly property bool bgActive: lockscreenRoot.getWidgetBackground(modelData.key)
                                                    color: bgActive ? Theme.alpha(Theme.accent, 0.35) : Theme.alpha(Theme.surface, 0.70)
                                                    border.width: 1
                                                    border.color: bgActive ? Theme.accent : Theme.alpha(Theme.accent, 0.25)

                                                    Row {
                                                        id: bgBtnRow
                                                        anchors.centerIn: parent
                                                        spacing: 6
                                                        Text { text: "🪟"; font.pixelSize: 10 }
                                                        Text {
                                                            text: "Card BG: " + (parent.parent.bgActive ? "ON" : "OFF")
                                                            color: parent.parent.bgActive ? Theme.accent : Theme.alpha(Theme.foreground, 0.70)
                                                            font.family: "Outfit"
                                                            font.pixelSize: 10
                                                            font.weight: Font.DemiBold
                                                        }
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            var curr = lockscreenRoot.getWidgetBackground(modelData.key)
                                                            window.updateWidgetBackground(modelData.key, !curr)
                                                        }
                                                    }
                                                }

                                                // Main Enabled Switch
                                                Switch {
                                                    checked: {
                                                        if (modelData.configObj === "clock") {
                                                            return window.config.clock ? window.config.clock.enabled : true
                                                        }
                                                        return window.config.modules ? (window.config.modules[modelData.configProp] !== false) : true
                                                    }
                                                    onToggled: {
                                                        if (modelData.configObj === "clock") {
                                                            if (!window.config.clock) window.config.clock = {}
                                                            window.config.clock.enabled = checked
                                                        } else {
                                                            if (!window.config.modules) window.config.modules = {}
                                                            window.config.modules[modelData.configProp] = checked
                                                        }
                                                        window.markDirty()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // ── SUB-TAB 1: CLOCK & DATE SETTINGS ─────────────
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 14
                                visible: lockscreenRoot.controlCategoryTab === 1

                                Text {
                                    text: "CLOCK FORMAT & TYPOGRAPHY"
                                    color: Theme.accent
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.5
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        Layout.fillWidth: true
                                        text: "Use 24-Hour Time Format"
                                        color: Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 13
                                    }
                                    Switch {
                                        checked: Boolean(window.config.clock && window.config.clock.format_24h)
                                        onToggled: {
                                            if (!window.config.clock) window.config.clock = {}
                                            window.config.clock.format_24h = checked
                                            window.markDirty()
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: !Boolean(window.config.clock && window.config.clock.format_24h)
                                    Text {
                                        Layout.fillWidth: true
                                        text: "Show AM / PM Marker"
                                        color: Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 13
                                    }
                                    Switch {
                                        checked: Boolean(window.config.clock && window.config.clock.show_am_pm)
                                        onToggled: {
                                            if (!window.config.clock) window.config.clock = {}
                                            window.config.clock.show_am_pm = checked
                                            window.markDirty()
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    RowLayout {
                                        Text { text: "Clock Font Size"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                                        Item { Layout.fillWidth: true }
                                        Text { text: Math.round(clockSizeSlider.value) + " px"; color: Theme.accent; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    }
                                    Slider {
                                        id: clockSizeSlider
                                        Layout.fillWidth: true
                                        from: 48
                                        to: 140
                                        value: (window.config.clock && window.config.clock.size) ? window.config.clock.size : 84
                                        onMoved: {
                                            if (!window.config.clock) window.config.clock = {}
                                            window.config.clock.size = Math.round(value)
                                            window.markDirty()
                                        }
                                    }
                                }
                            }

                            // ── SUB-TAB 2: AVATAR STUDIO ─────────────────────
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 14
                                visible: lockscreenRoot.controlCategoryTab === 2

                                Text {
                                    text: "AVATAR SIZE & CELESTIAL ANIMATIONS"
                                    color: Theme.accent
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.5
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    RowLayout {
                                        Text { text: "Avatar Base Diameter"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                                        Item { Layout.fillWidth: true }
                                        Text { text: Math.round(avatarSizeSlider.value) + " px"; color: Theme.accent; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    }
                                    Slider {
                                        id: avatarSizeSlider
                                        Layout.fillWidth: true
                                        from: 70
                                        to: 180
                                        value: (window.config.avatar && window.config.avatar.size) ? window.config.avatar.size : 116
                                        onMoved: {
                                            if (!window.config.avatar) window.config.avatar = {}
                                            window.config.avatar.size = Math.round(value)
                                            window.markDirty()
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: "Breathing Pulse Animation"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                                    Switch {
                                        checked: Boolean(window.config.avatar && window.config.avatar.breathing_enabled)
                                        onToggled: {
                                            if (!window.config.avatar) window.config.avatar = {}
                                            window.config.avatar.breathing_enabled = checked
                                            window.markDirty()
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: "Celestial Orbit Ring & Satellites"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                                    Switch {
                                        checked: Boolean(window.config.avatar && window.config.avatar.orbit_satellites_enabled)
                                        onToggled: {
                                            if (!window.config.avatar) window.config.avatar = {}
                                            window.config.avatar.orbit_satellites_enabled = checked
                                            window.markDirty()
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: "Luminescent Aurora Halo Glow"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                                    Switch {
                                        checked: Boolean(window.config.avatar && window.config.avatar.glow_enabled)
                                        onToggled: {
                                            if (!window.config.avatar) window.config.avatar = {}
                                            window.config.avatar.glow_enabled = checked
                                            window.markDirty()
                                        }
                                    }
                                }
                            }

                            // ── SUB-TAB 3: ATMOSPHERE & BACKDROP ─────────────
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 14
                                visible: lockscreenRoot.controlCategoryTab === 3

                                Text {
                                    text: "BACKDROP BLUR & VIGNETTE ATMOSPHERE"
                                    color: Theme.accent
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.5
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    RowLayout {
                                        Text { text: "Wallpaper Gaussian Blur"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                                        Item { Layout.fillWidth: true }
                                        Text { text: Math.round(blurSlider.value * 100) + "%"; color: Theme.accent; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    }
                                    Slider {
                                        id: blurSlider
                                        Layout.fillWidth: true
                                        from: 0.0
                                        to: 1.0
                                        value: (window.config.backdrop && window.config.backdrop.blur !== undefined) ? window.config.backdrop.blur : 0.65
                                        onMoved: {
                                            if (!window.config.backdrop) window.config.backdrop = {}
                                            window.config.backdrop.blur = value
                                            window.markDirty()
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    RowLayout {
                                        Text { text: "Vignette Edge Falloff"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                                        Item { Layout.fillWidth: true }
                                        Text { text: Math.round(vignetteSlider.value * 100) + "%"; color: Theme.accent; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    }
                                    Slider {
                                        id: vignetteSlider
                                        Layout.fillWidth: true
                                        from: 0.0
                                        to: 1.0
                                        value: (window.config.backdrop && window.config.backdrop.vignette !== undefined) ? window.config.backdrop.vignette : 0.60
                                        onMoved: {
                                            if (!window.config.backdrop) window.config.backdrop = {}
                                            window.config.backdrop.vignette = value
                                            window.markDirty()
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    RowLayout {
                                        Text { text: "Atmospheric Dimming"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                                        Item { Layout.fillWidth: true }
                                        Text { text: Math.round(dimmingSlider.value * 100) + "%"; color: Theme.accent; font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    }
                                    Slider {
                                        id: dimmingSlider
                                        Layout.fillWidth: true
                                        from: 0.0
                                        to: 0.80
                                        value: (window.config.backdrop && window.config.backdrop.dimming !== undefined) ? window.config.backdrop.dimming : 0.20
                                        onMoved: {
                                            if (!window.config.backdrop) window.config.backdrop = {}
                                            window.config.backdrop.dimming = value
                                            window.markDirty()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
