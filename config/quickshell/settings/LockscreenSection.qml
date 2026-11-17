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

    function parseFontWeight(w, fallback) {
        if (!w) return fallback !== undefined ? fallback : Font.Normal
        var s = String(w).toLowerCase()
        if (s === "thin" || s === "100") return Font.Thin
        if (s === "extralight" || s === "200") return Font.ExtraLight
        if (s === "light" || s === "300") return Font.Light
        if (s === "medium" || s === "500") return Font.Medium
        if (s === "demibold" || s === "semibold" || s === "600") return Font.DemiBold
        if (s === "bold" || s === "700") return Font.Bold
        if (s === "extrabold" || s === "800") return Font.ExtraBold
        if (s === "black" || s === "900") return Font.Black
        return fallback !== undefined ? fallback : Font.Normal
    }

    function parseToneColor(tone, fallback) {
        if (!tone) return fallback
        var t = String(tone).toLowerCase()
        if (t === "accent") return Theme.accent
        if (t === "primary") return Theme.primary
        if (t === "foreground") return Theme.foreground
        if (t === "muted") return Theme.muted || Theme.alpha(Theme.foreground, 0.60)
        if (t === "on_primary") return Theme.on_primary
        if (t.startsWith("#")) return t
        return fallback
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

                    // Apply & Save Lockscreen Changes
                    Rectangle {
                        height: 32
                        radius: 16
                        implicitWidth: saveLockRow.implicitWidth + 24
                        color: window.isDirty ? (saveLockMouse.containsMouse ? Theme.primary : Theme.accent) : Theme.alpha(Theme.surface, 0.50)
                        border.width: 1
                        border.color: window.isDirty ? Theme.accent : Theme.alpha(Theme.accent, 0.30)
                        opacity: window.isDirty ? 1.0 : 0.8
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            id: saveLockRow
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: window.isDirty ? "💾" : "✓"
                                font.pixelSize: 11
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: window.isDirty ? "Save Changes" : "Saved"
                                color: window.isDirty ? Theme.on_primary : Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                        }

                        MouseArea {
                            id: saveLockMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.applyAllChanges()
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
            // VIEW 1 & 2: PROPORTIONAL CANVAS & ADOBE STUDIO INSPECTOR
            // ─────────────────────────────────────────────────────────────────
            RowLayout {
                anchors.fill: parent
                spacing: 12
                visible: lockscreenRoot.studioMode === 0 || lockscreenRoot.studioMode === 1

                Item {
                    id: canvasViewport
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

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
                    clip: false

                    // Exactly maps 1920x1080 display space to preview dimensions!
                    readonly property real canvasScale: width / 1920.0

                    // Inner clipped container for Wallpaper and Vignette so bezel stays neat
                    Item {
                        anchors.fill: parent
                        clip: true

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
                                id: lockClockPreviewItem

                                property real sepBlinkOpacity: 1.0

                                SequentialAnimation on sepBlinkOpacity {
                                    loops: Animation.Infinite
                                    running: Boolean(window.config && window.config.clock && window.config.clock.separator_blinking)
                                    NumberAnimation { from: 1.0; to: 0.20; duration: 500; easing.type: Easing.InOutQuad }
                                    NumberAnimation { from: 0.20; to: 1.0; duration: 500; easing.type: Easing.InOutQuad }
                                }

                                function parseFontWeight(w, fallback) {
                                    if (!w) return fallback !== undefined ? fallback : Font.Normal
                                    var s = String(w).toLowerCase()
                                    if (s === "thin" || s === "100") return Font.Thin
                                    if (s === "extralight" || s === "200") return Font.ExtraLight
                                    if (s === "light" || s === "300") return Font.Light
                                    if (s === "medium" || s === "500") return Font.Medium
                                    if (s === "demibold" || s === "semibold" || s === "600") return Font.DemiBold
                                    if (s === "bold" || s === "700") return Font.Bold
                                    if (s === "extrabold" || s === "800") return Font.ExtraBold
                                    if (s === "black" || s === "900") return Font.Black
                                    return Font.Normal
                                }

                                function parseToneColor(tone, fallback) {
                                    if (!tone) return fallback
                                    var t = String(tone).toLowerCase()
                                    if (t === "accent") return Theme.accent
                                    if (t === "primary") return Theme.primary
                                    if (t === "foreground") return Theme.foreground
                                    if (t === "muted") return Theme.muted || Theme.alpha(Theme.foreground, 0.60)
                                    if (t === "on_primary") return Theme.on_primary
                                    if (t.startsWith("#")) return t
                                    return fallback
                                }

                                readonly property string activePreset: {
                                    var raw = (window.config.clock && window.config.clock.preset) ? String(window.config.clock.preset).toLowerCase().replace(/\s+/g, "_") : "editorial_split"
                                    if (raw === "classic" || raw === "editorial_split" || raw === "mono_telemetry" || raw === "minimal_pill") return raw
                                    return "editorial_split"
                                }

                                readonly property string hoursStr: {
                                    var d = window.currentTime
                                    var is24h = Boolean(window.config.clock && window.config.clock.format_24h)
                                    var h = is24h ? d.getHours() : ((d.getHours() % 12) || 12)
                                    return (h < 10 ? "0" : "") + h
                                }
                                readonly property string minutesStr: (window.currentTime.getMinutes() < 10 ? "0" : "") + window.currentTime.getMinutes()
                                readonly property string amPmStr: (window.config.clock && window.config.clock.format_24h) ? "" : Qt.formatTime(window.currentTime, "AP")
                                readonly property real clockPx: (window.config.clock && window.config.clock.size) ? window.config.clock.size : 84

                                // Granular Properties
                                readonly property string hFont: (window.config.clock && window.config.clock.hours_font_family) ? window.config.clock.hours_font_family : (activePreset === "mono_telemetry" ? "JetBrainsMono Nerd Font" : "Outfit")
                                readonly property int hWeight: parseFontWeight((window.config.clock && window.config.clock.hours_weight) ? window.config.clock.hours_weight : (activePreset === "editorial_split" ? "Black" : (activePreset === "classic" ? (window.config.clock.weight || "Bold") : "Bold")), Font.Bold)
                                readonly property color hColor: parseToneColor((window.config.clock && window.config.clock.hours_color_mode) ? window.config.clock.hours_color_mode : (activePreset === "classic" ? "accent" : "foreground"), Theme.foreground)
                                readonly property real hSpacing: (window.config.clock && window.config.clock.hours_letter_spacing !== undefined) ? window.config.clock.hours_letter_spacing : (activePreset === "editorial_split" ? -1.5 : (activePreset === "classic" ? 2.0 : 1.0))

                                readonly property string mFont: (window.config.clock && window.config.clock.minutes_font_family) ? window.config.clock.minutes_font_family : hFont
                                readonly property int mWeight: parseFontWeight((window.config.clock && window.config.clock.minutes_weight) ? window.config.clock.minutes_weight : (activePreset === "editorial_split" ? "Light" : (activePreset === "classic" ? (window.config.clock.weight || "Light") : "Light")), Font.Light)
                                readonly property color mColor: parseToneColor((window.config.clock && window.config.clock.minutes_color_mode) ? window.config.clock.minutes_color_mode : "accent", Theme.accent)
                                readonly property real mRatio: (window.config.clock && window.config.clock.minutes_size_ratio !== undefined) ? window.config.clock.minutes_size_ratio : 1.0
                                readonly property real mSpacing: (window.config.clock && window.config.clock.minutes_letter_spacing !== undefined) ? window.config.clock.minutes_letter_spacing : (activePreset === "editorial_split" ? 0.5 : 1.0)

                                readonly property string sepGlyph: (window.config.clock && window.config.clock.separator_glyph !== undefined) ? window.config.clock.separator_glyph : ":"
                                readonly property real sepRatio: (window.config.clock && window.config.clock.separator_size_ratio !== undefined) ? window.config.clock.separator_size_ratio : 0.85
                                readonly property color sepColor: parseToneColor((window.config.clock && window.config.clock.separator_color_mode) ? window.config.clock.separator_color_mode : (activePreset === "mono_telemetry" ? "foreground" : "accent"), Theme.accent)

                                readonly property bool hasLine: (window.config.clock && window.config.clock.show_line !== undefined) ? window.config.clock.show_line : (activePreset === "editorial_split" || activePreset === "mono_telemetry")
                                readonly property string lineOrient: (window.config.clock && window.config.clock.line_orientation) ? window.config.clock.line_orientation : (activePreset === "mono_telemetry" ? "horizontal" : "vertical")
                                readonly property real lineThick: (window.config.clock && window.config.clock.line_thickness !== undefined) ? window.config.clock.line_thickness : (activePreset === "mono_telemetry" ? 1 : 2)
                                readonly property real lineLen: (window.config.clock && window.config.clock.line_length !== undefined) ? window.config.clock.line_length : (activePreset === "mono_telemetry" ? 180 : Math.max(36, clockPx * 0.72))
                                readonly property real lineRad: (window.config.clock && window.config.clock.line_radius !== undefined) ? window.config.clock.line_radius : 1
                                readonly property string lineStyle: (window.config.clock && window.config.clock.line_style) ? window.config.clock.line_style : "gradient"
                                readonly property color lineColor: parseToneColor((window.config.clock && window.config.clock.line_color_mode) ? window.config.clock.line_color_mode : "accent", Theme.accent)

                                readonly property bool hasCircle: (window.config.clock && window.config.clock.show_circle !== undefined) ? window.config.clock.show_circle : (activePreset === "minimal_pill")
                                readonly property real circleSize: (window.config.clock && window.config.clock.circle_size !== undefined) ? window.config.clock.circle_size : 8
                                readonly property string circleStyle: (window.config.clock && window.config.clock.circle_style) ? window.config.clock.circle_style : "solid"
                                readonly property color circleColor: parseToneColor((window.config.clock && window.config.clock.circle_color_mode) ? window.config.clock.circle_color_mode : "accent", Theme.accent)
                                readonly property string circlePos: (window.config.clock && window.config.clock.circle_position) ? window.config.clock.circle_position : "left"

                                readonly property string ampmStyle: (window.config.clock && window.config.clock.am_pm_style) ? window.config.clock.am_pm_style : (activePreset === "mono_telemetry" ? "bracketed" : "text")
                                readonly property string ampmFont: (window.config.clock && window.config.clock.am_pm_font_family) ? window.config.clock.am_pm_font_family : (activePreset === "mono_telemetry" ? "JetBrainsMono Nerd Font" : "Outfit")
                                readonly property int ampmWeight: parseFontWeight((window.config.clock && window.config.clock.am_pm_weight) ? window.config.clock.am_pm_weight : "Bold", Font.Bold)
                                readonly property real ampmSize: (window.config.clock && window.config.clock.am_pm_size !== undefined) ? window.config.clock.am_pm_size : (activePreset === "classic" ? 18 : 12)
                                readonly property color ampmColor: parseToneColor((window.config.clock && window.config.clock.am_pm_color_mode) ? window.config.clock.am_pm_color_mode : "accent", Theme.accent)

                                readonly property string dFmt: (window.config.date && window.config.date.format) ? window.config.date.format : (activePreset === "editorial_split" ? "split_lines" : (activePreset === "mono_telemetry" ? "iso" : (activePreset === "minimal_pill" ? "compact" : "long")))
                                readonly property string dFont: (window.config.date && window.config.date.font_family) ? window.config.date.font_family : (activePreset === "mono_telemetry" ? "JetBrainsMono Nerd Font" : "Outfit")
                                readonly property int dWeight: parseFontWeight((window.config.date && window.config.date.weight) ? window.config.date.weight : "Medium", Font.Medium)
                                readonly property real dSize: (window.config.date && window.config.date.size !== undefined) ? window.config.date.size : (activePreset === "minimal_pill" ? 15 : 13)
                                readonly property real dSpacing: (window.config.date && window.config.date.letter_spacing !== undefined) ? window.config.date.letter_spacing : (activePreset === "editorial_split" ? 2.2 : (activePreset === "classic" ? 4.0 : 1.8))
                                readonly property bool dUpper: (window.config.date && window.config.date.uppercase !== undefined) ? window.config.date.uppercase : (activePreset !== "minimal_pill")
                                readonly property color dColor: parseToneColor((window.config.date && window.config.date.color_mode) ? window.config.date.color_mode : "foreground", Theme.alpha(Theme.foreground, 0.75))

                                readonly property real surfRad: (window.config.clock && window.config.clock.surface_radius !== undefined) ? window.config.clock.surface_radius : (activePreset === "minimal_pill" ? height / 2 : 20)
                                readonly property real surfOp: (window.config.clock && window.config.clock.surface_opacity !== undefined) ? window.config.clock.surface_opacity : 0.55
                                readonly property real surfBw: (window.config.clock && window.config.clock.surface_border_width !== undefined) ? window.config.clock.surface_border_width : 1
                                readonly property bool surfSpec: (window.config.clock && window.config.clock.surface_specular !== undefined) ? window.config.clock.surface_specular : true

                                width: {
                                    if (activePreset === "editorial_split") return previewSplitRow.implicitWidth + 20
                                    if (activePreset === "mono_telemetry") return previewMonoCol.implicitWidth + 24
                                    if (activePreset === "minimal_pill") return previewMinimalRow.implicitWidth + 44
                                    return Math.max(timeRow.implicitWidth, dateText.implicitWidth) + 16
                                }
                                height: {
                                    if (activePreset === "editorial_split") return previewSplitRow.implicitHeight + 16
                                    if (activePreset === "mono_telemetry") return previewMonoCol.implicitHeight + 16
                                    if (activePreset === "minimal_pill") return previewMinimalRow.implicitHeight + 22
                                    return clockCol.implicitHeight + 12
                                }

                                // Obsidian Glass Surface Plate
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: lockClockPreviewItem.activePreset === "minimal_pill" ? 0 : -10
                                    radius: lockClockPreviewItem.surfRad
                                    visible: lockClockPreviewItem.activePreset === "minimal_pill" ? true : lockscreenRoot.getWidgetBackground("clock")
                                    color: Theme.alpha(Theme.mix(Theme.background, Theme.surface, 0.55), lockClockPreviewItem.surfOp)
                                    border.width: lockClockPreviewItem.surfBw
                                    border.color: Theme.alpha(Theme.foreground, 0.16)
                                    clip: true

                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        height: 1
                                        visible: lockClockPreviewItem.surfSpec
                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0.0; color: "transparent" }
                                            GradientStop { position: 0.5; color: Theme.alpha(Theme.foreground, 0.25) }
                                            GradientStop { position: 1.0; color: "transparent" }
                                        }
                                    }
                                }

                                // ── PRESET 1: CLASSIC ────────────────────────
                                Column {
                                    id: clockCol
                                    anchors.centerIn: parent
                                    spacing: 6
                                    visible: lockClockPreviewItem.activePreset === "classic"

                                    Row {
                                        id: timeRow
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 8

                                        // Left Accent Circle
                                        Rectangle {
                                            visible: lockClockPreviewItem.hasCircle && lockClockPreviewItem.circlePos === "left"
                                            width: lockClockPreviewItem.circleSize; height: lockClockPreviewItem.circleSize
                                            radius: width / 2
                                            color: lockClockPreviewItem.circleStyle === "outline" ? "transparent" : lockClockPreviewItem.circleColor
                                            border.width: lockClockPreviewItem.circleStyle === "outline" ? 1.5 : 0
                                            border.color: lockClockPreviewItem.circleColor
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            id: previewHoursClassic
                                            text: lockClockPreviewItem.hoursStr
                                            color: lockClockPreviewItem.hColor
                                            font.family: lockClockPreviewItem.hFont
                                            font.pixelSize: lockClockPreviewItem.clockPx
                                            font.weight: lockClockPreviewItem.hWeight
                                            font.letterSpacing: lockClockPreviewItem.hSpacing
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: lockClockPreviewItem.sepGlyph
                                            color: lockClockPreviewItem.sepColor
                                            font.family: lockClockPreviewItem.hFont
                                            font.pixelSize: Math.round(lockClockPreviewItem.clockPx * lockClockPreviewItem.sepRatio)
                                            font.weight: Font.Light
                                            opacity: lockClockPreviewItem.sepBlinkOpacity
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.verticalCenterOffset: -2
                                            visible: lockClockPreviewItem.sepGlyph.length > 0
                                        }

                                        Text {
                                            id: previewMinsClassic
                                            text: lockClockPreviewItem.minutesStr
                                            color: lockClockPreviewItem.mColor
                                            font.family: lockClockPreviewItem.mFont
                                            font.pixelSize: Math.round(lockClockPreviewItem.clockPx * lockClockPreviewItem.mRatio)
                                            font.weight: lockClockPreviewItem.mWeight
                                            font.letterSpacing: lockClockPreviewItem.mSpacing
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        // Right Accent Circle
                                        Rectangle {
                                            visible: lockClockPreviewItem.hasCircle && lockClockPreviewItem.circlePos === "right"
                                            width: lockClockPreviewItem.circleSize; height: lockClockPreviewItem.circleSize
                                            radius: width / 2
                                            color: lockClockPreviewItem.circleStyle === "outline" ? "transparent" : lockClockPreviewItem.circleColor
                                            border.width: lockClockPreviewItem.circleStyle === "outline" ? 1.5 : 0
                                            border.color: lockClockPreviewItem.circleColor
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        // AM/PM Marker
                                        Rectangle {
                                            visible: Boolean(window.config && window.config.clock && !window.config.clock.format_24h && window.config.clock.show_am_pm)
                                            anchors.bottom: previewHoursClassic.bottom
                                            anchors.bottomMargin: 12
                                            height: lockClockPreviewItem.ampmStyle === "pill" ? 22 : ampmClassicTxt.implicitHeight
                                            width: lockClockPreviewItem.ampmStyle === "pill" ? (ampmClassicTxt.implicitWidth + 14) : ampmClassicTxt.implicitWidth
                                            radius: 11
                                            color: lockClockPreviewItem.ampmStyle === "pill" ? Theme.alpha(lockClockPreviewItem.ampmColor, 0.20) : "transparent"
                                            border.width: lockClockPreviewItem.ampmStyle === "pill" ? 1 : 0
                                            border.color: Theme.alpha(lockClockPreviewItem.ampmColor, 0.50)

                                            Text {
                                                id: ampmClassicTxt
                                                anchors.centerIn: parent
                                                text: lockClockPreviewItem.ampmStyle === "bracketed" ? ("[ " + lockClockPreviewItem.amPmStr + " ]") : lockClockPreviewItem.amPmStr
                                                color: lockClockPreviewItem.ampmColor
                                                font.family: lockClockPreviewItem.ampmFont
                                                font.pixelSize: lockClockPreviewItem.ampmSize
                                                font.weight: lockClockPreviewItem.ampmWeight
                                                font.letterSpacing: 1.5
                                            }
                                        }
                                    }

                                    // Divider Line (horizontal)
                                    Rectangle {
                                        visible: lockClockPreviewItem.hasLine && lockClockPreviewItem.lineOrient === "horizontal"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: lockClockPreviewItem.lineLen
                                        height: lockClockPreviewItem.lineThick
                                        radius: lockClockPreviewItem.lineRad
                                        color: lockClockPreviewItem.lineStyle === "solid" ? lockClockPreviewItem.lineColor : "transparent"
                                        gradient: lockClockPreviewItem.lineStyle === "gradient" ? classicLineGrad : null
                                        Gradient {
                                            id: classicLineGrad
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0.0; color: "transparent" }
                                            GradientStop { position: 0.5; color: lockClockPreviewItem.lineColor }
                                            GradientStop { position: 1.0; color: "transparent" }
                                        }
                                    }

                                    // Date Line
                                    Text {
                                        id: dateText
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        visible: Boolean(window.config && window.config.date && window.config.date.enabled !== false)
                                        text: {
                                            var d = window.currentTime
                                            var isUp = lockClockPreviewItem.dUpper
                                            var fmt = lockClockPreviewItem.dFmt
                                            var str = ""
                                            if (fmt === "compact") str = Qt.formatDate(d, "ddd, MMM d")
                                            else if (fmt === "iso") str = Qt.formatDate(d, "yyyy-MM-dd") + " // " + Qt.formatDate(d, "ddd").toUpperCase()
                                            else if (fmt === "minimal") str = Qt.formatDate(d, "MMM d")
                                            else str = Qt.formatDate(d, "dddd, MMMM d")
                                            return isUp ? str.toUpperCase() : str
                                        }
                                        color: lockClockPreviewItem.dColor
                                        font.family: lockClockPreviewItem.dFont
                                        font.pixelSize: lockClockPreviewItem.dSize
                                        font.weight: lockClockPreviewItem.dWeight
                                        font.letterSpacing: lockClockPreviewItem.dSpacing
                                    }
                                }

                                // ── PRESET 2: EDITORIAL SPLIT ────────────────
                                Row {
                                    id: previewSplitRow
                                    anchors.centerIn: parent
                                    spacing: 16
                                    visible: lockClockPreviewItem.activePreset === "editorial_split"

                                    // Left Circle
                                    Rectangle {
                                        visible: lockClockPreviewItem.hasCircle && lockClockPreviewItem.circlePos === "left"
                                        width: lockClockPreviewItem.circleSize; height: lockClockPreviewItem.circleSize
                                        radius: width / 2
                                        color: lockClockPreviewItem.circleStyle === "outline" ? "transparent" : lockClockPreviewItem.circleColor
                                        border.width: lockClockPreviewItem.circleStyle === "outline" ? 1.5 : 0
                                        border.color: lockClockPreviewItem.circleColor
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4
                                        Text {
                                            text: lockClockPreviewItem.hoursStr
                                            color: lockClockPreviewItem.hColor
                                            font.family: lockClockPreviewItem.hFont
                                            font.pixelSize: lockClockPreviewItem.clockPx
                                            font.weight: lockClockPreviewItem.hWeight
                                            font.letterSpacing: lockClockPreviewItem.hSpacing
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: lockClockPreviewItem.sepGlyph
                                            color: lockClockPreviewItem.sepColor
                                            font.family: lockClockPreviewItem.hFont
                                            font.pixelSize: Math.round(lockClockPreviewItem.clockPx * lockClockPreviewItem.sepRatio)
                                            font.weight: Font.Light
                                            opacity: lockClockPreviewItem.sepBlinkOpacity
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.verticalCenterOffset: -3
                                            visible: lockClockPreviewItem.sepGlyph.length > 0
                                        }
                                        Text {
                                            text: lockClockPreviewItem.minutesStr
                                            color: lockClockPreviewItem.mColor
                                            font.family: lockClockPreviewItem.mFont
                                            font.pixelSize: Math.round(lockClockPreviewItem.clockPx * lockClockPreviewItem.mRatio)
                                            font.weight: lockClockPreviewItem.mWeight
                                            font.letterSpacing: lockClockPreviewItem.mSpacing
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    // Divider Line (vertical)
                                    Rectangle {
                                        visible: lockClockPreviewItem.hasLine
                                        width: lockClockPreviewItem.lineOrient === "vertical" ? lockClockPreviewItem.lineThick : lockClockPreviewItem.lineLen
                                        height: lockClockPreviewItem.lineOrient === "vertical" ? lockClockPreviewItem.lineLen : lockClockPreviewItem.lineThick
                                        radius: lockClockPreviewItem.lineRad
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: lockClockPreviewItem.lineStyle === "solid" ? lockClockPreviewItem.lineColor : "transparent"
                                        gradient: lockClockPreviewItem.lineStyle === "gradient" ? splitVertGrad : null
                                        Gradient {
                                            id: splitVertGrad
                                            orientation: Gradient.Vertical
                                            GradientStop { position: 0.0; color: lockClockPreviewItem.lineColor }
                                            GradientStop { position: 1.0; color: Theme.alpha(lockClockPreviewItem.lineColor, 0.20) }
                                        }
                                    }

                                    // Stacked Side Metadata (AM/PM & Date)
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 3
                                        visible: (Boolean(window.config && window.config.date && window.config.date.enabled !== false)) || (Boolean(window.config && window.config.clock && !window.config.clock.format_24h && window.config.clock.show_am_pm))

                                        // AM/PM
                                        Rectangle {
                                            visible: Boolean(window.config && window.config.clock && !window.config.clock.format_24h && window.config.clock.show_am_pm)
                                            height: lockClockPreviewItem.ampmStyle === "pill" ? 20 : ampmSplitTxt.implicitHeight
                                            width: lockClockPreviewItem.ampmStyle === "pill" ? (ampmSplitTxt.implicitWidth + 12) : ampmSplitTxt.implicitWidth
                                            radius: 10
                                            color: lockClockPreviewItem.ampmStyle === "pill" ? Theme.alpha(lockClockPreviewItem.ampmColor, 0.20) : "transparent"
                                            border.width: lockClockPreviewItem.ampmStyle === "pill" ? 1 : 0
                                            border.color: Theme.alpha(lockClockPreviewItem.ampmColor, 0.50)

                                            Text {
                                                id: ampmSplitTxt
                                                anchors.centerIn: parent
                                                text: lockClockPreviewItem.ampmStyle === "bracketed" ? ("[ " + lockClockPreviewItem.amPmStr + " ]") : lockClockPreviewItem.amPmStr
                                                color: lockClockPreviewItem.ampmColor
                                                font.family: lockClockPreviewItem.ampmFont
                                                font.pixelSize: lockClockPreviewItem.ampmSize
                                                font.weight: lockClockPreviewItem.ampmWeight
                                                font.letterSpacing: 1.5
                                            }
                                        }

                                        // Date Part 1 (Day)
                                        Text {
                                            visible: Boolean(window.config && window.config.date && window.config.date.enabled !== false)
                                            text: {
                                                var d = window.currentTime
                                                var isUp = lockClockPreviewItem.dUpper
                                                var fmt = lockClockPreviewItem.dFmt
                                                if (fmt === "split_lines") {
                                                    return isUp ? Qt.formatDate(d, "dddd").toUpperCase() : Qt.formatDate(d, "dddd")
                                                }
                                                return isUp ? Qt.formatDate(d, "dddd, MMM d").toUpperCase() : Qt.formatDate(d, "dddd, MMM d")
                                            }
                                            color: lockClockPreviewItem.dColor
                                            font.family: lockClockPreviewItem.dFont
                                            font.pixelSize: lockClockPreviewItem.dSize
                                            font.weight: lockClockPreviewItem.dWeight
                                            font.letterSpacing: lockClockPreviewItem.dSpacing
                                        }

                                        // Date Part 2 (Month & Day, for split_lines)
                                        Text {
                                            visible: Boolean(window.config && window.config.date && window.config.date.enabled !== false) && lockClockPreviewItem.dFmt === "split_lines"
                                            text: {
                                                var d = window.currentTime
                                                var isUp = lockClockPreviewItem.dUpper
                                                return isUp ? Qt.formatDate(d, "dd MMM").toUpperCase() : Qt.formatDate(d, "dd MMM")
                                            }
                                            color: Theme.alpha(lockClockPreviewItem.dColor, 0.70)
                                            font.family: lockClockPreviewItem.dFont
                                            font.pixelSize: Math.max(10, lockClockPreviewItem.dSize - 1)
                                            font.weight: Font.Medium
                                            font.letterSpacing: lockClockPreviewItem.dSpacing
                                        }
                                    }

                                    // Right Circle
                                    Rectangle {
                                        visible: lockClockPreviewItem.hasCircle && lockClockPreviewItem.circlePos === "right"
                                        width: lockClockPreviewItem.circleSize; height: lockClockPreviewItem.circleSize
                                        radius: width / 2
                                        color: lockClockPreviewItem.circleStyle === "outline" ? "transparent" : lockClockPreviewItem.circleColor
                                        border.width: lockClockPreviewItem.circleStyle === "outline" ? 1.5 : 0
                                        border.color: lockClockPreviewItem.circleColor
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                // ── PRESET 3: MONO TELEMETRY ─────────────────
                                Column {
                                    id: previewMonoCol
                                    anchors.centerIn: parent
                                    spacing: 6
                                    visible: lockClockPreviewItem.activePreset === "mono_telemetry"

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        visible: Boolean(window.config && window.config.clock && !window.config.clock.format_24h && window.config.clock.show_am_pm)
                                        text: "[ LOCAL // " + lockClockPreviewItem.amPmStr + " ]"
                                        color: Theme.alpha(lockClockPreviewItem.ampmColor, 0.88)
                                        font.family: lockClockPreviewItem.ampmFont
                                        font.pixelSize: lockClockPreviewItem.ampmSize
                                        font.weight: Font.Bold
                                        font.letterSpacing: 1.8
                                    }

                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 2

                                        Text {
                                            text: lockClockPreviewItem.hoursStr
                                            color: lockClockPreviewItem.hColor
                                            font.family: lockClockPreviewItem.hFont
                                            font.pixelSize: lockClockPreviewItem.clockPx
                                            font.weight: lockClockPreviewItem.hWeight
                                            font.letterSpacing: lockClockPreviewItem.hSpacing
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: lockClockPreviewItem.sepGlyph
                                            color: lockClockPreviewItem.sepColor
                                            font.family: lockClockPreviewItem.hFont
                                            font.pixelSize: Math.round(lockClockPreviewItem.clockPx * lockClockPreviewItem.sepRatio)
                                            font.weight: lockClockPreviewItem.hWeight
                                            opacity: lockClockPreviewItem.sepBlinkOpacity
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: lockClockPreviewItem.sepGlyph.length > 0
                                        }
                                        Text {
                                            text: lockClockPreviewItem.minutesStr
                                            color: lockClockPreviewItem.mColor
                                            font.family: lockClockPreviewItem.mFont
                                            font.pixelSize: Math.round(lockClockPreviewItem.clockPx * lockClockPreviewItem.mRatio)
                                            font.weight: lockClockPreviewItem.mWeight
                                            font.letterSpacing: lockClockPreviewItem.mSpacing
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: lockClockPreviewItem.lineLen
                                        height: lockClockPreviewItem.lineThick
                                        visible: lockClockPreviewItem.hasLine
                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0.0; color: "transparent" }
                                            GradientStop { position: 0.5; color: lockClockPreviewItem.lineColor }
                                            GradientStop { position: 1.0; color: "transparent" }
                                        }
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        visible: Boolean(window.config && window.config.date && window.config.date.enabled !== false)
                                        text: {
                                            var d = window.currentTime
                                            return Qt.formatDate(d, "yyyy-MM-dd") + " // " + Qt.formatDate(d, "ddd").toUpperCase()
                                        }
                                        color: lockClockPreviewItem.dColor
                                        font.family: lockClockPreviewItem.dFont
                                        font.pixelSize: lockClockPreviewItem.dSize
                                        font.weight: lockClockPreviewItem.dWeight
                                        font.letterSpacing: lockClockPreviewItem.dSpacing
                                    }
                                }

                                // ── PRESET 4: MINIMAL PILL ───────────────────
                                Row {
                                    id: previewMinimalRow
                                    anchors.centerIn: parent
                                    spacing: 12
                                    visible: lockClockPreviewItem.activePreset === "minimal_pill"

                                    Rectangle {
                                        width: lockClockPreviewItem.circleSize; height: lockClockPreviewItem.circleSize
                                        radius: width / 2
                                        color: lockClockPreviewItem.circleColor
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2
                                        Text {
                                            text: lockClockPreviewItem.hoursStr
                                            color: lockClockPreviewItem.hColor
                                            font.family: lockClockPreviewItem.hFont
                                            font.pixelSize: Math.max(26, Math.round(lockClockPreviewItem.clockPx * 0.52))
                                            font.weight: lockClockPreviewItem.hWeight
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: lockClockPreviewItem.sepGlyph
                                            color: lockClockPreviewItem.sepColor
                                            font.family: lockClockPreviewItem.hFont
                                            font.pixelSize: Math.max(24, Math.round(lockClockPreviewItem.clockPx * 0.48))
                                            font.weight: Font.Light
                                            opacity: lockClockPreviewItem.sepBlinkOpacity
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: lockClockPreviewItem.sepGlyph.length > 0
                                        }
                                        Text {
                                            text: lockClockPreviewItem.minutesStr
                                            color: lockClockPreviewItem.mColor
                                            font.family: lockClockPreviewItem.mFont
                                            font.pixelSize: Math.max(26, Math.round(lockClockPreviewItem.clockPx * 0.52 * lockClockPreviewItem.mRatio))
                                            font.weight: lockClockPreviewItem.mWeight
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Text {
                                        visible: Boolean(window.config && window.config.clock && !window.config.clock.format_24h && window.config.clock.show_am_pm)
                                        text: lockClockPreviewItem.amPmStr
                                        color: lockClockPreviewItem.ampmColor
                                        font.family: lockClockPreviewItem.ampmFont
                                        font.pixelSize: lockClockPreviewItem.ampmSize
                                        font.weight: Font.Bold
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Rectangle {
                                        visible: Boolean(window.config && window.config.date && window.config.date.enabled !== false)
                                        width: 4; height: 4; radius: 2
                                        color: Theme.alpha(Theme.foreground, 0.40)
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        visible: Boolean(window.config && window.config.date && window.config.date.enabled !== false)
                                        text: Qt.formatDate(window.currentTime, "ddd, MMM d")
                                        color: lockClockPreviewItem.dColor
                                        font.family: lockClockPreviewItem.dFont
                                        font.pixelSize: lockClockPreviewItem.dSize
                                        font.weight: lockClockPreviewItem.dWeight
                                        anchors.verticalCenter: parent.verticalCenter
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
                            id: usernameWidget
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

                            readonly property var unStyle: (window.config && window.config.username_style) ? window.config.username_style : {}
                            readonly property string unFont: unStyle.font_family || "Outfit"
                            readonly property int unWeight: lockscreenRoot.parseFontWeight(unStyle.weight, Font.DemiBold)
                            readonly property color unColor: lockscreenRoot.parseToneColor(unStyle.color_mode, Theme.foreground)
                            readonly property real unSize: (unStyle.size !== undefined ? unStyle.size : 18)
                            readonly property real unSpacing: (unStyle.letter_spacing !== undefined ? unStyle.letter_spacing : 2)
                            readonly property bool unUpper: Boolean(unStyle.uppercase)

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
                                    text: usernameWidget.unUpper ? "SHELL NINJA" : "Shell Ninja"
                                    color: usernameWidget.unColor
                                    font.family: usernameWidget.unFont
                                    font.pixelSize: usernameWidget.unSize
                                    font.weight: usernameWidget.unWeight
                                    font.letterSpacing: usernameWidget.unSpacing
                                }
                            }
                        }

                        // 2c. Separated Session Lock Status Widget
                        ResizableDraggableWidget {
                            id: sessionLockWidget
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

                            readonly property var slStyle: (window.config && window.config.session_lock_style) ? window.config.session_lock_style : {}
                            readonly property string slBadge: slStyle.badge_style || "pill"
                            readonly property bool slShowIcon: slStyle.show_icon !== false
                            readonly property string slText: slStyle.text || "Session Locked"

                            Item {
                                width: sessionStatusPreviewRow.implicitWidth + (sessionLockWidget.slBadge === "text" ? 8 : 22)
                                height: sessionStatusPreviewRow.implicitHeight + (sessionLockWidget.slBadge === "text" ? 4 : 10)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: sessionLockWidget.slBadge === "bracketed" ? 4 : height / 2
                                    visible: (sessionLockWidget.slBadge !== "text") && lockscreenRoot.getWidgetBackground("session_lock")
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
                                        visible: sessionLockWidget.slShowIcon && (sessionLockWidget.slBadge !== "bracketed")
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: sessionLockWidget.slBadge === "bracketed" ? ("[ " + sessionLockWidget.slText.toUpperCase() + " ]") : sessionLockWidget.slText
                                        color: Theme.alpha(Theme.foreground, 0.70)
                                        font.family: "Outfit"
                                        font.pixelSize: 11
                                        font.weight: sessionLockWidget.slBadge === "bracketed" ? Font.DemiBold : Font.Normal
                                        font.letterSpacing: 1.2
                                    }
                                }
                            }
                        }

                        // 2d. Separated Password Input Field Widget
                        ResizableDraggableWidget {
                            id: inputFieldWidget
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

                            readonly property var inStyle: (window.config && window.config.input_field_style) ? window.config.input_field_style : {}
                            readonly property real inW: (inStyle.width !== undefined ? inStyle.width : 380)
                            readonly property real inH: (inStyle.height !== undefined ? inStyle.height : 52)
                            readonly property real inRad: (inStyle.radius !== undefined ? inStyle.radius : 26)
                            readonly property real inOp: (inStyle.glass_opacity !== undefined ? inStyle.glass_opacity : 0.45)
                            readonly property bool inIcon: (inStyle.show_icon !== false)
                            readonly property bool inAccentBorder: (inStyle.border_accent !== false)

                            Rectangle {
                                width: inputFieldWidget.inW
                                height: inputFieldWidget.inH
                                radius: inputFieldWidget.inRad
                                color: lockscreenRoot.getWidgetBackground("input_field") ? Theme.alpha(Theme.surface, inputFieldWidget.inOp) : "transparent"
                                border.width: 1.2
                                border.color: inputFieldWidget.inAccentBorder ? Theme.accent : Theme.alpha(Theme.foreground, 0.25)

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
                                        visible: inputFieldWidget.inIcon
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

                        // 3. Audio Visualizer Widget (CAVA Spectrum)
                        ResizableDraggableWidget {
                            id: visualizerWidget
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

                            readonly property var vStyle: (window.config && window.config.visualizer_style) ? window.config.visualizer_style : {}
                            readonly property int vCount: (vStyle.bar_count !== undefined ? vStyle.bar_count : 14)
                            readonly property real vWidth: (vStyle.bar_width !== undefined ? vStyle.bar_width : 4)
                            readonly property real vSpacing: (vStyle.bar_spacing !== undefined ? vStyle.bar_spacing : 4)
                            readonly property real vRadius: (vStyle.bar_radius !== undefined ? vStyle.bar_radius : 2)
                            readonly property color vColor: lockscreenRoot.parseToneColor(vStyle.color_mode, Theme.accent)

                            LockscreenAudioVisualizer {
                                previewMode: true
                                barCount: visualizerWidget.vCount
                                barWidth: visualizerWidget.vWidth
                                barSpacing: visualizerWidget.vSpacing
                                barRadius: visualizerWidget.vRadius
                                barColor: visualizerWidget.vColor
                                showBackground: lockscreenRoot.getWidgetBackground("audio_visualizer")
                            }
                        }

                        // 4. Weather Forecast Capsule
                        ResizableDraggableWidget {
                            id: weatherWidget
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

                            readonly property var wStyle: (window.config && window.config.weather_style) ? window.config.weather_style : {}
                            readonly property string wLayout: wStyle.layout || "pill"
                            readonly property string wFont: wStyle.font_family || "Outfit"
                            readonly property real wTempSize: (wStyle.temp_size !== undefined ? wStyle.temp_size : 14)
                            readonly property bool wShowCity: (wStyle.show_city !== false)
                            readonly property string wUnit: wStyle.unit || "c"

                            Rectangle {
                                width: weatherWidget.wLayout === "card" ? 180 : (weatherRow.implicitWidth + 28)
                                height: weatherWidget.wLayout === "card" ? 56 : 32
                                radius: weatherWidget.wLayout === "card" ? 14 : 16
                                color: lockscreenRoot.getWidgetBackground("weather") ? Theme.alpha(Theme.surface, 0.50) : "transparent"
                                border.width: lockscreenRoot.getWidgetBackground("weather") ? 1 : 0
                                border.color: Theme.alpha(Theme.accent, 0.35)

                                // Card layout
                                ColumnLayout {
                                    anchors.centerIn: parent
                                    visible: weatherWidget.wLayout === "card"
                                    spacing: 2
                                    RowLayout {
                                        spacing: 6
                                        Image {
                                            Layout.preferredWidth: 16; Layout.preferredHeight: 16
                                            source: lockscreenRoot.cloudSunSvg
                                            sourceSize: Qt.size(32, 32)
                                        }
                                        Text {
                                            text: (weatherWidget.wUnit === "f" ? "72°F" : "22°C") + " • Clear"
                                            color: Theme.foreground
                                            font.family: weatherWidget.wFont
                                            font.pixelSize: weatherWidget.wTempSize
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                    Text {
                                        visible: weatherWidget.wShowCity
                                        text: window.liveWeatherCity ? (window.liveWeatherCity + ", " + window.liveWeatherCountry) : "New York, US"
                                        color: Theme.alpha(Theme.foreground, 0.65)
                                        font.family: weatherWidget.wFont
                                        font.pixelSize: 10
                                    }
                                }

                                // Pill layout
                                Row {
                                    id: weatherRow
                                    anchors.centerIn: parent
                                    visible: weatherWidget.wLayout !== "card"
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
                                            var temp = (weatherWidget.wUnit === "f" ? "72°F" : "22°C")
                                            if (!weatherWidget.wShowCity || !c) return temp + "  •  Clear"
                                            return temp + "  •  " + c + ", " + co
                                        }
                                        color: Theme.foreground
                                        font.family: weatherWidget.wFont
                                        font.pixelSize: weatherWidget.wTempSize
                                        font.weight: Font.Medium
                                    }
                                }
                            }
                        }

                        // 5. Inspirational Quote Pill
                        ResizableDraggableWidget {
                            id: quoteWidget
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

                            readonly property var qStyle: (window.config && window.config.quote_style) ? window.config.quote_style : {}
                            readonly property string qFont: qStyle.font_family || "Outfit"
                            readonly property bool qItalic: qStyle.italic !== false
                            readonly property real qSize: (qStyle.size !== undefined ? qStyle.size : 12)
                            readonly property bool qDecorations: qStyle.show_decorations !== false
                            readonly property string qText: (window.config && window.config.modules && window.config.modules.quote_text) ? window.config.modules.quote_text : "Crafting the digital realm."

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
                                    Text {
                                        visible: quoteWidget.qDecorations
                                        text: "❝"
                                        color: Theme.accent
                                        font.pixelSize: 10
                                    }
                                    Text {
                                        id: quotePreviewText
                                        text: quoteWidget.qText
                                        color: Theme.alpha(Theme.foreground, 0.85)
                                        font.family: quoteWidget.qFont
                                        font.pixelSize: quoteWidget.qSize
                                        font.italic: quoteWidget.qItalic
                                    }
                                    Text {
                                        visible: quoteWidget.qDecorations
                                        text: "❞"
                                        color: Theme.accent
                                        font.pixelSize: 10
                                    }
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
                            id: statsWidget
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

                            readonly property var ssStyle: (window.config && window.config.system_stats_style) ? window.config.system_stats_style : {}
                            readonly property string ssMode: ssStyle.display_mode || "graphs"
                            readonly property real ssThick: (ssStyle.graph_thickness !== undefined ? ssStyle.graph_thickness : 2)

                            LockscreenSystemGraph {
                                statsData: window.sysStatsData
                                previewMode: false
                                displayMode: statsWidget.ssMode
                                graphThickness: statsWidget.ssThick
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

                // ── FLOATING QUICK LAYERS RIBBON ─────────────────────────────
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 42
                    width: ribbonRow.implicitWidth + 24
                    radius: 21
                    color: Theme.alpha(Theme.surface, 0.94)
                    border.width: 1
                    border.color: Theme.alpha(Theme.accent, 0.35)
                    visible: lockscreenRoot.studioMode === 0
                    z: 50

                    Row {
                        id: ribbonRow
                        anchors.centerIn: parent
                        spacing: 4

                        Repeater {
                            model: [
                                { key: "clock", name: "Clock", icon: "🕒" },
                                { key: "user_avatar", name: "Avatar", icon: "👤" },
                                { key: "username", name: "User", icon: "🪪" },
                                { key: "input_field", name: "Password", icon: "🔒" },
                                { key: "weather", name: "Weather", icon: "🌤" },
                                { key: "system_stats", name: "Stats", icon: "📊" },
                                { key: "audio_visualizer", name: "Visualizer", icon: "🎵" },
                                { key: "quote", name: "Quote", icon: "💬" },
                                { key: "session_lock", name: "Lock", icon: "🛡" },
                                { key: "backdrop", name: "Backdrop", icon: "🌌" }
                            ]

                            Rectangle {
                                height: 30
                                radius: 15
                                implicitWidth: ribBtnRow.implicitWidth + 14
                                readonly property bool isSelected: lockscreenRoot.selectedModuleKey === modelData.key
                                color: isSelected ? Theme.accent : (ribMouse.containsMouse ? Theme.alpha(Theme.surface, 0.85) : "transparent")
                                border.width: isSelected ? 1 : 0
                                border.color: Theme.accent
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Row {
                                    id: ribBtnRow
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        text: modelData.icon
                                        font.pixelSize: 11
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: modelData.name
                                        color: parent.parent.isSelected ? Theme.on_primary : Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 11
                                        font.weight: parent.parent.isSelected ? Font.Bold : Font.Normal
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    id: ribMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: lockscreenRoot.selectedModuleKey = modelData.key
                                }
                            }
                        }
                    }
                }
            }

            // ── ADOBE-STYLE INSPECTOR PANEL (Docked Right) ───────────────────
            LockscreenInspector {
                id: studioInspector
                Layout.preferredWidth: collapsed ? 44 : 330
                Layout.fillHeight: true
                visible: lockscreenRoot.studioMode === 0
                selectedModuleKey: lockscreenRoot.selectedModuleKey
                onModuleSelected: function(k) { lockscreenRoot.selectedModuleKey = k }
                onConfigModified: window.markDirty()
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
                                        text: "Typography Preset"
                                        color: Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 13
                                    }
                                    ModernDropdown {
                                        implicitWidth: 170
                                        implicitHeight: 32
                                        readonly property var keyToLabel: ({
                                            "editorial_split": "Editorial Split",
                                            "classic": "Classic",
                                            "mono_telemetry": "Mono Telemetry",
                                            "minimal_pill": "Minimal Pill"
                                        })
                                        readonly property var labelToKey: ({
                                            "Editorial Split": "editorial_split",
                                            "Classic": "classic",
                                            "Mono Telemetry": "mono_telemetry",
                                            "Minimal Pill": "minimal_pill"
                                        })
                                        model: ["Editorial Split", "Classic", "Mono Telemetry", "Minimal Pill"]
                                        currentValue: {
                                            var p = (window.config.clock && window.config.clock.preset) ? String(window.config.clock.preset) : "editorial_split"
                                            return keyToLabel[p] || "Editorial Split"
                                        }
                                        onSelected: function(val) {
                                            if (!window.config.clock) window.config.clock = {}
                                            window.config.clock.preset = labelToKey[val] || "editorial_split"
                                            window.markDirty()
                                        }
                                    }
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
