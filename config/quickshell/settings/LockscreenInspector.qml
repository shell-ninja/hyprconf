import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import "."

Item {
    id: inspectorRoot

    property string selectedModuleKey: "clock"
    property bool collapsed: false
    signal moduleSelected(string key)
    signal configModified()

    implicitWidth: collapsed ? 44 : 340
    implicitHeight: 600

    Behavior on implicitWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property var fontFamilies: [
        "Outfit",
        "JetBrainsMono Nerd Font",
        "CaskaydiaCove Nerd Font",
        "Iosevka Nerd Font",
        "DejaVu Sans",
        "DejaVu Serif"
    ]

    readonly property var fontWeights: [
        "Thin",
        "Light",
        "Normal",
        "Medium",
        "DemiBold",
        "Bold",
        "ExtraBold",
        "Black"
    ]

    readonly property var colorModes: [
        "Foreground",
        "Accent",
        "Primary",
        "Muted"
    ]

    readonly property var layerList: [
        { key: "clock", name: "Clock & Date", icon: "🕒" },
        { key: "user_avatar", name: "User Avatar", icon: "👤" },
        { key: "username", name: "Username", icon: "🪪" },
        { key: "input_field", name: "Password Input", icon: "🔒" },
        { key: "weather", name: "Weather Capsule", icon: "🌤" },
        { key: "system_stats", name: "System Stats", icon: "📊" },
        { key: "audio_visualizer", name: "Audio Visualizer", icon: "🎵" },
        { key: "quote", name: "Quote Pill", icon: "💬" },
        { key: "session_lock", name: "Session Lock", icon: "🛡" },
        { key: "backdrop", name: "Atmosphere & Backdrop", icon: "🌌" }
    ]

    function getLayerMeta(key) {
        for (var i = 0; i < layerList.length; i++) {
            if (layerList[i].key === key) return layerList[i]
        }
        return { key: key, name: key.toUpperCase(), icon: "◆" }
    }

    // Helper functions for reading & mutating window.config
    function getModuleEnabled(key) {
        if (!window.config) return true
        if (key === "clock") return window.config.clock ? (window.config.clock.enabled !== false) : true
        if (key === "backdrop") return true
        return window.config.modules ? (window.config.modules[key] !== false) : true
    }

    function setModuleEnabled(key, val) {
        if (!window.config) window.config = {}
        if (key === "clock") {
            if (!window.config.clock) window.config.clock = {}
            window.config.clock.enabled = val
        } else if (key !== "backdrop") {
            if (!window.config.modules) window.config.modules = {}
            window.config.modules[key] = val
        }
        notifyDirty()
    }

    function getWidgetBackground(key) {
        if (!window.config || !window.config.widget_backgrounds) return false
        return window.config.widget_backgrounds[key] !== undefined ? window.config.widget_backgrounds[key] : false
    }

    function setWidgetBackground(key, val) {
        if (!window.config) window.config = {}
        if (!window.config.widget_backgrounds) window.config.widget_backgrounds = {}
        window.config.widget_backgrounds[key] = val
        notifyDirty()
    }

    function getClockProp(prop, fallback) {
        if (!window.config || !window.config.clock) return fallback
        return window.config.clock[prop] !== undefined ? window.config.clock[prop] : fallback
    }

    function setClockProp(prop, val) {
        if (!window.config) window.config = {}
        if (!window.config.clock) window.config.clock = {}
        window.config.clock[prop] = val
        notifyDirty()
    }

    function getDateProp(prop, fallback) {
        if (!window.config || !window.config.date) return fallback
        return window.config.date[prop] !== undefined ? window.config.date[prop] : fallback
    }

    function setDateProp(prop, val) {
        if (!window.config) window.config = {}
        if (!window.config.date) window.config.date = {}
        window.config.date[prop] = val
        notifyDirty()
    }

    function getAvatarProp(prop, fallback) {
        if (!window.config || !window.config.avatar) return fallback
        return window.config.avatar[prop] !== undefined ? window.config.avatar[prop] : fallback
    }

    function setAvatarProp(prop, val) {
        if (!window.config) window.config = {}
        if (!window.config.avatar) window.config.avatar = {}
        window.config.avatar[prop] = val
        notifyDirty()
    }

    function getSubStyleProp(subObj, prop, fallback) {
        if (!window.config || !window.config[subObj]) return fallback
        return window.config[subObj][prop] !== undefined ? window.config[subObj][prop] : fallback
    }

    function setSubStyleProp(subObj, prop, val) {
        if (!window.config) window.config = {}
        if (!window.config[subObj]) window.config[subObj] = {}
        window.config[subObj][prop] = val
        notifyDirty()
    }

    function getBackdropProp(prop, fallback) {
        if (!window.config || !window.config.backdrop) return fallback
        return window.config.backdrop[prop] !== undefined ? window.config.backdrop[prop] : fallback
    }

    function setBackdropProp(prop, val) {
        if (!window.config) window.config = {}
        if (!window.config.backdrop) window.config.backdrop = {}
        window.config.backdrop[prop] = val
        notifyDirty()
    }

    function notifyDirty() {
        if (typeof window.markDirty === "function") {
            window.markDirty()
        }
        inspectorRoot.configModified()
    }

    function applyClockPreset(presetName) {
        if (!window.config) window.config = {}
        if (!window.config.clock) window.config.clock = {}
        if (!window.config.date) window.config.date = {}
        if (!window.config.widget_backgrounds) window.config.widget_backgrounds = {}

        window.config.clock.preset = presetName

        if (presetName === "editorial_split") {
            window.config.clock.hours_font_family = "Outfit"
            window.config.clock.hours_weight = "Black"
            window.config.clock.hours_color_mode = "foreground"
            window.config.clock.hours_letter_spacing = -1.5
            window.config.clock.minutes_font_family = "Outfit"
            window.config.clock.minutes_weight = "Light"
            window.config.clock.minutes_color_mode = "accent"
            window.config.clock.minutes_letter_spacing = 0.5
            window.config.clock.minutes_size_ratio = 1.0
            window.config.clock.separator_glyph = ":"
            window.config.clock.separator_size_ratio = 0.85
            window.config.clock.separator_color_mode = "accent"
            window.config.clock.separator_blinking = false
            window.config.clock.show_line = true
            window.config.clock.line_orientation = "vertical"
            window.config.clock.line_thickness = 2
            window.config.clock.line_length = 64
            window.config.clock.line_radius = 1
            window.config.clock.line_style = "gradient"
            window.config.clock.line_color_mode = "accent"
            window.config.clock.show_circle = false
            window.config.clock.am_pm_style = "text"
            window.config.clock.am_pm_font_family = "JetBrainsMono Nerd Font"
            window.config.clock.am_pm_weight = "Bold"
            window.config.clock.am_pm_size = 12
            window.config.clock.am_pm_color_mode = "accent"
            window.config.date.format = "split_lines"
            window.config.date.font_family = "Outfit"
            window.config.date.weight = "Bold"
            window.config.date.size = 13
            window.config.date.letter_spacing = 2.2
            window.config.date.uppercase = true
            window.config.date.color_mode = "foreground"
            window.config.widget_backgrounds.clock = false
        } else if (presetName === "classic") {
            window.config.clock.hours_font_family = "Outfit"
            window.config.clock.hours_weight = "Bold"
            window.config.clock.hours_color_mode = "accent"
            window.config.clock.hours_letter_spacing = 2.0
            window.config.clock.minutes_font_family = "Outfit"
            window.config.clock.minutes_weight = "Bold"
            window.config.clock.minutes_color_mode = "accent"
            window.config.clock.minutes_letter_spacing = 2.0
            window.config.clock.minutes_size_ratio = 1.0
            window.config.clock.separator_glyph = ":"
            window.config.clock.separator_size_ratio = 1.0
            window.config.clock.separator_color_mode = "accent"
            window.config.clock.separator_blinking = false
            window.config.clock.show_line = false
            window.config.clock.show_circle = false
            window.config.clock.am_pm_style = "text"
            window.config.clock.am_pm_font_family = "Outfit"
            window.config.clock.am_pm_weight = "DemiBold"
            window.config.clock.am_pm_size = 18
            window.config.clock.am_pm_color_mode = "accent"
            window.config.date.format = "long"
            window.config.date.font_family = "Outfit"
            window.config.date.weight = "Medium"
            window.config.date.size = 13
            window.config.date.letter_spacing = 4.0
            window.config.date.uppercase = true
            window.config.date.color_mode = "foreground"
            window.config.widget_backgrounds.clock = false
        } else if (presetName === "mono_telemetry") {
            window.config.clock.hours_font_family = "JetBrainsMono Nerd Font"
            window.config.clock.hours_weight = "DemiBold"
            window.config.clock.hours_color_mode = "foreground"
            window.config.clock.hours_letter_spacing = 1.5
            window.config.clock.minutes_font_family = "JetBrainsMono Nerd Font"
            window.config.clock.minutes_weight = "DemiBold"
            window.config.clock.minutes_color_mode = "foreground"
            window.config.clock.minutes_letter_spacing = 1.5
            window.config.clock.minutes_size_ratio = 1.0
            window.config.clock.separator_glyph = ":"
            window.config.clock.separator_size_ratio = 1.0
            window.config.clock.separator_color_mode = "foreground"
            window.config.clock.separator_blinking = false
            window.config.clock.show_line = true
            window.config.clock.line_orientation = "horizontal"
            window.config.clock.line_thickness = 1
            window.config.clock.line_length = 180
            window.config.clock.line_radius = 0
            window.config.clock.line_style = "gradient"
            window.config.clock.line_color_mode = "accent"
            window.config.clock.show_circle = false
            window.config.clock.am_pm_style = "bracketed"
            window.config.clock.am_pm_font_family = "JetBrainsMono Nerd Font"
            window.config.clock.am_pm_weight = "Bold"
            window.config.clock.am_pm_size = 11
            window.config.clock.am_pm_color_mode = "accent"
            window.config.date.format = "iso"
            window.config.date.font_family = "JetBrainsMono Nerd Font"
            window.config.date.weight = "Medium"
            window.config.date.size = 12
            window.config.date.letter_spacing = 1.8
            window.config.date.uppercase = true
            window.config.date.color_mode = "foreground"
            window.config.widget_backgrounds.clock = false
        } else if (presetName === "minimal_pill") {
            window.config.clock.hours_font_family = "Outfit"
            window.config.clock.hours_weight = "Bold"
            window.config.clock.hours_color_mode = "foreground"
            window.config.clock.hours_letter_spacing = 0.5
            window.config.clock.minutes_font_family = "Outfit"
            window.config.clock.minutes_weight = "Bold"
            window.config.clock.minutes_color_mode = "foreground"
            window.config.clock.minutes_letter_spacing = 0.5
            window.config.clock.minutes_size_ratio = 1.0
            window.config.clock.separator_glyph = ":"
            window.config.clock.separator_size_ratio = 1.0
            window.config.clock.separator_color_mode = "foreground"
            window.config.clock.separator_blinking = false
            window.config.clock.show_line = false
            window.config.clock.show_circle = true
            window.config.clock.circle_position = "left"
            window.config.clock.circle_size = 8
            window.config.clock.circle_style = "solid"
            window.config.clock.circle_color_mode = "accent"
            window.config.clock.am_pm_style = "text"
            window.config.clock.am_pm_font_family = "Outfit"
            window.config.clock.am_pm_weight = "Bold"
            window.config.clock.am_pm_size = 13
            window.config.clock.am_pm_color_mode = "accent"
            window.config.date.format = "compact"
            window.config.date.font_family = "Outfit"
            window.config.date.weight = "Medium"
            window.config.date.size = 15
            window.config.date.letter_spacing = 1.0
            window.config.date.uppercase = false
            window.config.date.color_mode = "foreground"
            window.config.widget_backgrounds.clock = true
            window.config.clock.surface_radius = 24
            window.config.clock.surface_opacity = 0.55
            window.config.clock.surface_border_width = 1
        }
        notifyDirty()
    }

    // Outer Obsidian Glass Container
    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Theme.alpha(Theme.surface, 0.75)
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.30)
        clip: true

        // Top specular edge highlight
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Theme.alpha(Theme.accent, 0.40) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // =====================================================================
        // COLLAPSED STRIP VIEW (When user clicks toggle)
        // =====================================================================
        ColumnLayout {
            anchors.fill: parent
            visible: inspectorRoot.collapsed
            spacing: 12

            Item { Layout.fillHeight: true }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 32; height: 32; radius: 16
                color: expandMouse.containsMouse ? Theme.alpha(Theme.accent, 0.35) : Theme.alpha(Theme.surface, 0.60)
                border.width: 1; border.color: Theme.accent
                Text {
                    anchors.centerIn: parent
                    text: "⇥"
                    color: Theme.accent
                    font.pixelSize: 14
                    font.weight: Font.Bold
                }
                MouseArea {
                    id: expandMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: inspectorRoot.collapsed = false
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "INSPECTOR"
                color: Theme.alpha(Theme.foreground, 0.60)
                font.family: "Outfit"
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 2
                rotation: 90
            }

            Item { Layout.fillHeight: true }
        }

        // =====================================================================
        // EXPANDED ADOBE-STYLE INSPECTOR PANEL
        // =====================================================================
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            visible: !inspectorRoot.collapsed
            spacing: 10

            // ── HEADER: TITLE & COLLAPSE / RESET ─────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    width: 26; height: 26; radius: 13
                    color: Theme.alpha(Theme.accent, 0.20)
                    border.width: 1; border.color: Theme.accent
                    Text {
                        anchors.centerIn: parent
                        text: inspectorRoot.getLayerMeta(inspectorRoot.selectedModuleKey).icon
                        font.pixelSize: 12
                    }
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: "STUDIO INSPECTOR"
                        color: Theme.alpha(Theme.accent, 0.85)
                        font.family: "Outfit"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        font.letterSpacing: 1.5
                    }
                    Text {
                        text: inspectorRoot.getLayerMeta(inspectorRoot.selectedModuleKey).name
                        color: Theme.foreground
                        font.family: "Outfit"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }

                // Collapse Button
                Rectangle {
                    width: 28; height: 28; radius: 14
                    color: collapseMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.40)
                    border.width: 1; border.color: Theme.alpha(Theme.accent, 0.25)
                    Text {
                        anchors.centerIn: parent
                        text: "⇤"
                        color: Theme.foreground
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }
                    MouseArea {
                        id: collapseMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: inspectorRoot.collapsed = true
                    }
                }
            }

            // ── QUICK LAYER SELECTOR DROPDOWN ────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "Layer:"
                    color: Theme.alpha(Theme.foreground, 0.60)
                    font.family: "Outfit"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }

                ModernDropdown {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    model: [
                        "Clock & Date",
                        "User Avatar",
                        "Username",
                        "Password Input",
                        "Weather Capsule",
                        "System Stats",
                        "Audio Visualizer",
                        "Quote Pill",
                        "Session Lock",
                        "Atmosphere & Backdrop"
                    ]
                    currentValue: inspectorRoot.getLayerMeta(inspectorRoot.selectedModuleKey).name
                    onSelected: function(val) {
                        for (var i = 0; i < inspectorRoot.layerList.length; i++) {
                            if (inspectorRoot.layerList[i].name === val) {
                                inspectorRoot.selectedModuleKey = inspectorRoot.layerList[i].key
                                inspectorRoot.moduleSelected(inspectorRoot.selectedModuleKey)
                                break
                            }
                        }
                    }
                }
            }

            // ── MODULE QUICK ACTIONS (Visible, Background, Center X) ─────────
            Rectangle {
                Layout.fillWidth: true
                height: 38
                radius: 10
                color: Theme.alpha(Theme.surface, 0.50)
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.20)
                visible: inspectorRoot.selectedModuleKey !== "backdrop"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    // Visibility toggle
                    Row {
                        spacing: 6
                        Layout.alignment: Qt.AlignVCenter
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Visible"
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }
                        Switch {
                            anchors.verticalCenter: parent.verticalCenter
                            scale: 0.75
                            checked: inspectorRoot.getModuleEnabled(inspectorRoot.selectedModuleKey)
                            onToggled: inspectorRoot.setModuleEnabled(inspectorRoot.selectedModuleKey, checked)
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Card Background toggle
                    Rectangle {
                        height: 24
                        radius: 12
                        implicitWidth: bgRow.implicitWidth + 14
                        readonly property bool bgOn: inspectorRoot.getWidgetBackground(inspectorRoot.selectedModuleKey)
                        color: bgOn ? Theme.alpha(Theme.accent, 0.35) : Theme.alpha(Theme.surface, 0.60)
                        border.width: 1
                        border.color: bgOn ? Theme.accent : Theme.alpha(Theme.accent, 0.25)

                        Row {
                            id: bgRow
                            anchors.centerIn: parent
                            spacing: 4
                            Text { text: "🪟"; font.pixelSize: 9 }
                            Text {
                                text: "Glass BG"
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
                                var curr = inspectorRoot.getWidgetBackground(inspectorRoot.selectedModuleKey)
                                inspectorRoot.setWidgetBackground(inspectorRoot.selectedModuleKey, !curr)
                            }
                        }
                    }

                    // Center X button
                    Rectangle {
                        height: 24
                        radius: 12
                        implicitWidth: centerXRow.implicitWidth + 14
                        color: cXMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.60)
                        border.width: 1; border.color: Theme.alpha(Theme.accent, 0.30)

                        Row {
                            id: centerXRow
                            anchors.centerIn: parent
                            spacing: 3
                            Text { text: "⌖"; color: Theme.accent; font.pixelSize: 10 }
                            Text { text: "Center"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 10 }
                        }

                        MouseArea {
                            id: cXMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (window.config && window.config.positions && window.config.positions[inspectorRoot.selectedModuleKey]) {
                                    window.updateWidgetPosition(inspectorRoot.selectedModuleKey, 0.50, window.config.positions[inspectorRoot.selectedModuleKey].y)
                                } else {
                                    window.updateWidgetPosition(inspectorRoot.selectedModuleKey, 0.50, 0.50)
                                }
                            }
                        }
                    }
                }
            }

            // ── SCROLLABLE ACCORDION SECTIONS ────────────────────────────────
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth

                ColumnLayout {
                    width: parent.width
                    spacing: 10

                    // =========================================================
                    // 1. CLOCK & DATE GRANULAR STUDIO
                    // =========================================================
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        visible: inspectorRoot.selectedModuleKey === "clock"

                        // Presets Quick Starts
                        Rectangle {
                            Layout.fillWidth: true
                            height: 64
                            radius: 10
                            color: Theme.alpha(Theme.surface, 0.40)
                            border.width: 1; border.color: Theme.alpha(Theme.accent, 0.18)

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 4

                                Text {
                                    text: "PRESET TEMPLATES"
                                    color: Theme.alpha(Theme.accent, 0.90)
                                    font.family: "Outfit"
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.2
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Repeater {
                                        model: [
                                            { id: "editorial_split", label: "Split" },
                                            { id: "classic", label: "Classic" },
                                            { id: "mono_telemetry", label: "Mono" },
                                            { id: "minimal_pill", label: "Pill" }
                                        ]

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 24
                                            radius: 6
                                            readonly property bool isCurrent: inspectorRoot.getClockProp("preset", "editorial_split") === modelData.id
                                            color: isCurrent ? Theme.accent : (pMouse.containsMouse ? Theme.alpha(Theme.surface, 0.80) : Theme.alpha(Theme.surface, 0.40))
                                            border.width: 1
                                            border.color: isCurrent ? Theme.accent : Theme.alpha(Theme.accent, 0.20)

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.label
                                                color: parent.isCurrent ? Theme.on_primary : Theme.foreground
                                                font.family: "Outfit"
                                                font.pixelSize: 10
                                                font.weight: parent.isCurrent ? Font.Bold : Font.Normal
                                            }

                                            MouseArea {
                                                id: pMouse
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: inspectorRoot.applyClockPreset(modelData.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ── SECTION: HOURS TYPOGRAPHY ────────────────────────
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: hoursCol.implicitHeight + 16
                            radius: 10
                            color: Theme.alpha(Theme.surface, 0.40)
                            border.width: 1; border.color: Theme.alpha(Theme.accent, 0.18)

                            ColumnLayout {
                                id: hoursCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Text {
                                    text: "HOURS TYPOGRAPHY"
                                    color: Theme.accent
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.2
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.preferredWidth: 80; text: "Font Family"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    ModernDropdown {
                                        Layout.fillWidth: true; implicitHeight: 28
                                        model: inspectorRoot.fontFamilies
                                        currentValue: inspectorRoot.getClockProp("hours_font_family", "Outfit")
                                        onSelected: function(v) { inspectorRoot.setClockProp("hours_font_family", v) }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.preferredWidth: 80; text: "Font Weight"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    ModernDropdown {
                                        Layout.fillWidth: true; implicitHeight: 28
                                        model: inspectorRoot.fontWeights
                                        currentValue: inspectorRoot.getClockProp("hours_weight", "Black")
                                        onSelected: function(v) { inspectorRoot.setClockProp("hours_weight", v) }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.preferredWidth: 80; text: "Color Tone"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    ModernDropdown {
                                        Layout.fillWidth: true; implicitHeight: 28
                                        model: inspectorRoot.colorModes
                                        currentValue: {
                                            var c = inspectorRoot.getClockProp("hours_color_mode", "foreground")
                                            return c.charAt(0).toUpperCase() + c.slice(1)
                                        }
                                        onSelected: function(v) { inspectorRoot.setClockProp("hours_color_mode", v.toLowerCase()) }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    RowLayout {
                                        Text { text: "Base Size"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                        Item { Layout.fillWidth: true }
                                        Text { text: Math.round(hoursSizeSlider.value) + " px"; color: Theme.accent; font.pixelSize: 11; font.family: "Outfit"; font.weight: Font.Bold }
                                    }
                                    ModernSlider {
                                        id: hoursSizeSlider
                                        Layout.fillWidth: true
                                        from: 36; to: 160
                                        value: inspectorRoot.getClockProp("size", 96)
                                        onMoved: inspectorRoot.setClockProp("size", Math.round(value))
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    RowLayout {
                                        Text { text: "Letter Spacing"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                        Item { Layout.fillWidth: true }
                                        Text { text: hoursSpacingSlider.value.toFixed(1) + " px"; color: Theme.accent; font.pixelSize: 11; font.family: "Outfit"; font.weight: Font.Bold }
                                    }
                                    ModernSlider {
                                        id: hoursSpacingSlider
                                        Layout.fillWidth: true
                                        from: -3.0; to: 8.0
                                        value: inspectorRoot.getClockProp("hours_letter_spacing", -1.5)
                                        onMoved: inspectorRoot.setClockProp("hours_letter_spacing", Number(value.toFixed(1)))
                                    }
                                }
                            }
                        }

                        // ── SECTION: MINUTES TYPOGRAPHY ──────────────────────
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: minsCol.implicitHeight + 16
                            radius: 10
                            color: Theme.alpha(Theme.surface, 0.40)
                            border.width: 1; border.color: Theme.alpha(Theme.accent, 0.18)

                            ColumnLayout {
                                id: minsCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Text {
                                    text: "MINUTES TYPOGRAPHY"
                                    color: Theme.accent
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.2
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.preferredWidth: 80; text: "Font Family"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    ModernDropdown {
                                        Layout.fillWidth: true; implicitHeight: 28
                                        model: inspectorRoot.fontFamilies
                                        currentValue: inspectorRoot.getClockProp("minutes_font_family", "Outfit")
                                        onSelected: function(v) { inspectorRoot.setClockProp("minutes_font_family", v) }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.preferredWidth: 80; text: "Font Weight"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    ModernDropdown {
                                        Layout.fillWidth: true; implicitHeight: 28
                                        model: inspectorRoot.fontWeights
                                        currentValue: inspectorRoot.getClockProp("minutes_weight", "Light")
                                        onSelected: function(v) { inspectorRoot.setClockProp("minutes_weight", v) }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.preferredWidth: 80; text: "Color Tone"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    ModernDropdown {
                                        Layout.fillWidth: true; implicitHeight: 28
                                        model: inspectorRoot.colorModes
                                        currentValue: {
                                            var c = inspectorRoot.getClockProp("minutes_color_mode", "accent")
                                            return c.charAt(0).toUpperCase() + c.slice(1)
                                        }
                                        onSelected: function(v) { inspectorRoot.setClockProp("minutes_color_mode", v.toLowerCase()) }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    RowLayout {
                                        Text { text: "Size Scale Ratio"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                        Item { Layout.fillWidth: true }
                                        Text { text: Math.round(minsRatioSlider.value * 100) + "%"; color: Theme.accent; font.pixelSize: 11; font.family: "Outfit"; font.weight: Font.Bold }
                                    }
                                    ModernSlider {
                                        id: minsRatioSlider
                                        Layout.fillWidth: true
                                        from: 0.50; to: 1.20
                                        value: inspectorRoot.getClockProp("minutes_size_ratio", 1.0)
                                        onMoved: inspectorRoot.setClockProp("minutes_size_ratio", Number(value.toFixed(2)))
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    RowLayout {
                                        Text { text: "Letter Spacing"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                        Item { Layout.fillWidth: true }
                                        Text { text: minsSpacingSlider.value.toFixed(1) + " px"; color: Theme.accent; font.pixelSize: 11; font.family: "Outfit"; font.weight: Font.Bold }
                                    }
                                    ModernSlider {
                                        id: minsSpacingSlider
                                        Layout.fillWidth: true
                                        from: -3.0; to: 8.0
                                        value: inspectorRoot.getClockProp("minutes_letter_spacing", 0.5)
                                        onMoved: inspectorRoot.setClockProp("minutes_letter_spacing", Number(value.toFixed(1)))
                                    }
                                }
                            }
                        }

                        // ── SECTION: SEPARATOR & COLON ───────────────────────
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: sepCol.implicitHeight + 16
                            radius: 10
                            color: Theme.alpha(Theme.surface, 0.40)
                            border.width: 1; border.color: Theme.alpha(Theme.accent, 0.18)

                            ColumnLayout {
                                id: sepCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Text {
                                    text: "SEPARATOR & COLON"
                                    color: Theme.accent
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.2
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.preferredWidth: 80; text: "Glyph"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    ModernDropdown {
                                        Layout.fillWidth: true; implicitHeight: 28
                                        readonly property var glyphMap: ({
                                            ":": "Colon ( : )",
                                            "•": "Dot ( • )",
                                            "/": "Slash ( / )",
                                            "-": "Dash ( - )",
                                            "|": "Bar ( | )",
                                            " ": "Space ( )",
                                            "": "None"
                                        })
                                        model: ["Colon ( : )", "Dot ( • )", "Slash ( / )", "Dash ( - )", "Bar ( | )", "Space ( )", "None"]
                                        currentValue: {
                                            var g = inspectorRoot.getClockProp("separator_glyph", ":")
                                            return glyphMap[g] || "Colon ( : )"
                                        }
                                        onSelected: function(v) {
                                            var map = {
                                                "Colon ( : )": ":",
                                                "Dot ( • )": "•",
                                                "Slash ( / )": "/",
                                                "Dash ( - )": "-",
                                                "Bar ( | )": "|",
                                                "Space ( )": " ",
                                                "None": ""
                                            }
                                            inspectorRoot.setClockProp("separator_glyph", map[v] !== undefined ? map[v] : ":")
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.preferredWidth: 80; text: "Color Tone"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    ModernDropdown {
                                        Layout.fillWidth: true; implicitHeight: 28
                                        model: inspectorRoot.colorModes
                                        currentValue: {
                                            var c = inspectorRoot.getClockProp("separator_color_mode", "accent")
                                            return c.charAt(0).toUpperCase() + c.slice(1)
                                        }
                                        onSelected: function(v) { inspectorRoot.setClockProp("separator_color_mode", v.toLowerCase()) }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    RowLayout {
                                        Text { text: "Size Ratio"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                        Item { Layout.fillWidth: true }
                                        Text { text: Math.round(sepRatioSlider.value * 100) + "%"; color: Theme.accent; font.pixelSize: 11; font.family: "Outfit"; font.weight: Font.Bold }
                                    }
                                    ModernSlider {
                                        id: sepRatioSlider
                                        Layout.fillWidth: true
                                        from: 0.40; to: 1.20
                                        value: inspectorRoot.getClockProp("separator_size_ratio", 0.85)
                                        onMoved: inspectorRoot.setClockProp("separator_size_ratio", Number(value.toFixed(2)))
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: "Subtle Pulse Animation"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    Switch {
                                        checked: inspectorRoot.getClockProp("separator_blinking", false)
                                        onToggled: inspectorRoot.setClockProp("separator_blinking", checked)
                                    }
                                }
                            }
                        }

                        // ── SECTION: DIVIDER LINES ───────────────────────────
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: linesCol.implicitHeight + 16
                            radius: 10
                            color: Theme.alpha(Theme.surface, 0.40)
                            border.width: 1; border.color: Theme.alpha(Theme.accent, 0.18)

                            ColumnLayout {
                                id: linesCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        Layout.fillWidth: true
                                        text: "DIVIDER LINES"
                                        color: Theme.accent
                                        font.family: "Outfit"
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        font.letterSpacing: 1.2
                                    }
                                    Switch {
                                        checked: inspectorRoot.getClockProp("show_line", true)
                                        onToggled: inspectorRoot.setClockProp("show_line", checked)
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    visible: inspectorRoot.getClockProp("show_line", true)

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { Layout.preferredWidth: 80; text: "Orientation"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                        ModernDropdown {
                                            Layout.fillWidth: true; implicitHeight: 28
                                            model: ["Vertical", "Horizontal"]
                                            currentValue: {
                                                var o = inspectorRoot.getClockProp("line_orientation", "vertical")
                                                return o.charAt(0).toUpperCase() + o.slice(1)
                                            }
                                            onSelected: function(v) { inspectorRoot.setClockProp("line_orientation", v.toLowerCase()) }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { Layout.preferredWidth: 80; text: "Line Style"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                        ModernDropdown {
                                            Layout.fillWidth: true; implicitHeight: 28
                                            model: ["Gradient Fade", "Solid Fill"]
                                            currentValue: inspectorRoot.getClockProp("line_style", "gradient") === "solid" ? "Solid Fill" : "Gradient Fade"
                                            onSelected: function(v) { inspectorRoot.setClockProp("line_style", v === "Solid Fill" ? "solid" : "gradient") }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        RowLayout {
                                            Text { text: "Thickness"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                            Item { Layout.fillWidth: true }
                                            Text { text: Math.round(lineThickSlider.value) + " px"; color: Theme.accent; font.pixelSize: 11; font.family: "Outfit"; font.weight: Font.Bold }
                                        }
                                        ModernSlider {
                                            id: lineThickSlider
                                            Layout.fillWidth: true
                                            from: 1; to: 6
                                            value: inspectorRoot.getClockProp("line_thickness", 2)
                                            onMoved: inspectorRoot.setClockProp("line_thickness", Math.round(value))
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        RowLayout {
                                            Text { text: "Length / Span"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                            Item { Layout.fillWidth: true }
                                            Text { text: Math.round(lineLenSlider.value) + " px"; color: Theme.accent; font.pixelSize: 11; font.family: "Outfit"; font.weight: Font.Bold }
                                        }
                                        ModernSlider {
                                            id: lineLenSlider
                                            Layout.fillWidth: true
                                            from: 20; to: 220
                                            value: inspectorRoot.getClockProp("line_length", 64)
                                            onMoved: inspectorRoot.setClockProp("line_length", Math.round(value))
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        RowLayout {
                                            Text { text: "Corner Radius"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                            Item { Layout.fillWidth: true }
                                            Text { text: Math.round(lineRadSlider.value) + " px"; color: Theme.accent; font.pixelSize: 11; font.family: "Outfit"; font.weight: Font.Bold }
                                        }
                                        ModernSlider {
                                            id: lineRadSlider
                                            Layout.fillWidth: true
                                            from: 0; to: 4
                                            value: inspectorRoot.getClockProp("line_radius", 1)
                                            onMoved: inspectorRoot.setClockProp("line_radius", Math.round(value))
                                        }
                                    }
                                }
                            }
                        }

                        // ── SECTION: CIRCLES & GEOMETRIC ACCENTS ─────────────
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: circCol.implicitHeight + 16
                            radius: 10
                            color: Theme.alpha(Theme.surface, 0.40)
                            border.width: 1; border.color: Theme.alpha(Theme.accent, 0.18)

                            ColumnLayout {
                                id: circCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        Layout.fillWidth: true
                                        text: "CIRCLES & DOTS"
                                        color: Theme.accent
                                        font.family: "Outfit"
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        font.letterSpacing: 1.2
                                    }
                                    Switch {
                                        checked: inspectorRoot.getClockProp("show_circle", false)
                                        onToggled: inspectorRoot.setClockProp("show_circle", checked)
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    visible: inspectorRoot.getClockProp("show_circle", false)

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { Layout.preferredWidth: 80; text: "Position"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                        ModernDropdown {
                                            Layout.fillWidth: true; implicitHeight: 28
                                            model: ["Left", "Center", "Right"]
                                            currentValue: {
                                                var p = inspectorRoot.getClockProp("circle_position", "left")
                                                return p.charAt(0).toUpperCase() + p.slice(1)
                                            }
                                            onSelected: function(v) { inspectorRoot.setClockProp("circle_position", v.toLowerCase()) }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { Layout.preferredWidth: 80; text: "Circle Style"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                        ModernDropdown {
                                            Layout.fillWidth: true; implicitHeight: 28
                                            model: ["Solid Fill", "Outline Ring", "Glowing Pulse"]
                                            currentValue: {
                                                var s = inspectorRoot.getClockProp("circle_style", "solid")
                                                if (s === "outline") return "Outline Ring"
                                                if (s === "pulse") return "Glowing Pulse"
                                                return "Solid Fill"
                                            }
                                            onSelected: function(v) {
                                                if (v === "Outline Ring") inspectorRoot.setClockProp("circle_style", "outline")
                                                else if (v === "Glowing Pulse") inspectorRoot.setClockProp("circle_style", "pulse")
                                                else inspectorRoot.setClockProp("circle_style", "solid")
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        RowLayout {
                                            Text { text: "Diameter"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                            Item { Layout.fillWidth: true }
                                            Text { text: Math.round(circSizeSlider.value) + " px"; color: Theme.accent; font.pixelSize: 11; font.family: "Outfit"; font.weight: Font.Bold }
                                        }
                                        ModernSlider {
                                            id: circSizeSlider
                                            Layout.fillWidth: true
                                            from: 4; to: 20
                                            value: inspectorRoot.getClockProp("circle_size", 8)
                                            onMoved: inspectorRoot.setClockProp("circle_size", Math.round(value))
                                        }
                                    }
                                }
                            }
                        }

                        // ── SECTION: DATE DISPLAY ────────────────────────────
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: dateCol.implicitHeight + 16
                            radius: 10
                            color: Theme.alpha(Theme.surface, 0.40)
                            border.width: 1; border.color: Theme.alpha(Theme.accent, 0.18)

                            ColumnLayout {
                                id: dateCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        Layout.fillWidth: true
                                        text: "DATE & CALENDAR"
                                        color: Theme.accent
                                        font.family: "Outfit"
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        font.letterSpacing: 1.2
                                    }
                                    Switch {
                                        checked: inspectorRoot.getDateProp("enabled", true)
                                        onToggled: inspectorRoot.setDateProp("enabled", checked)
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    visible: inspectorRoot.getDateProp("enabled", true)

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { Layout.preferredWidth: 80; text: "Format"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                        ModernDropdown {
                                            Layout.fillWidth: true; implicitHeight: 28
                                            readonly property var fmtMap: ({
                                                "long": "Editorial Long",
                                                "compact": "Compact",
                                                "iso": "ISO Telemetry",
                                                "split_lines": "Split Two-Line",
                                                "minimal": "Minimal"
                                            })
                                            model: ["Editorial Long", "Compact", "ISO Telemetry", "Split Two-Line", "Minimal"]
                                            currentValue: {
                                                var f = inspectorRoot.getDateProp("format", "long")
                                                return fmtMap[f] || "Editorial Long"
                                            }
                                            onSelected: function(v) {
                                                var map = {
                                                    "Editorial Long": "long",
                                                    "Compact": "compact",
                                                    "ISO Telemetry": "iso",
                                                    "Split Two-Line": "split_lines",
                                                    "Minimal": "minimal"
                                                }
                                                inspectorRoot.setDateProp("format", map[v] || "long")
                                            }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { Layout.preferredWidth: 80; text: "Font Family"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                        ModernDropdown {
                                            Layout.fillWidth: true; implicitHeight: 28
                                            model: inspectorRoot.fontFamilies
                                            currentValue: inspectorRoot.getDateProp("font_family", "Outfit")
                                            onSelected: function(v) { inspectorRoot.setDateProp("font_family", v) }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { Layout.preferredWidth: 80; text: "Font Weight"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                        ModernDropdown {
                                            Layout.fillWidth: true; implicitHeight: 28
                                            model: ["Light", "Normal", "Medium", "DemiBold", "Bold"]
                                            currentValue: inspectorRoot.getDateProp("weight", "Medium")
                                            onSelected: function(v) { inspectorRoot.setDateProp("weight", v) }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { Layout.fillWidth: true; text: "All-Caps Uppercase"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                        Switch {
                                            checked: inspectorRoot.getDateProp("uppercase", true)
                                            onToggled: inspectorRoot.setDateProp("uppercase", checked)
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        RowLayout {
                                            Text { text: "Font Size"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                            Item { Layout.fillWidth: true }
                                            Text { text: Math.round(dateSizeSlider.value) + " px"; color: Theme.accent; font.pixelSize: 11; font.family: "Outfit"; font.weight: Font.Bold }
                                        }
                                        ModernSlider {
                                            id: dateSizeSlider
                                            Layout.fillWidth: true
                                            from: 10; to: 24
                                            value: inspectorRoot.getDateProp("size", 13)
                                            onMoved: inspectorRoot.setDateProp("size", Math.round(value))
                                        }
                                    }
                                }
                            }
                        }

                        // ── SECTION: AM/PM MARKER ────────────────────────────
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: ampmCol.implicitHeight + 16
                            radius: 10
                            color: Theme.alpha(Theme.surface, 0.40)
                            border.width: 1; border.color: Theme.alpha(Theme.accent, 0.18)

                            ColumnLayout {
                                id: ampmCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Text {
                                    text: "AM / PM MARKER & 24H"
                                    color: Theme.accent
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.2
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: "24-Hour Time Format"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    Switch {
                                        checked: inspectorRoot.getClockProp("format_24h", false)
                                        onToggled: inspectorRoot.setClockProp("format_24h", checked)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: !inspectorRoot.getClockProp("format_24h", false)
                                    Text { Layout.fillWidth: true; text: "Show AM/PM Marker"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    Switch {
                                        checked: inspectorRoot.getClockProp("show_am_pm", true)
                                        onToggled: inspectorRoot.setClockProp("show_am_pm", checked)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: !inspectorRoot.getClockProp("format_24h", false) && inspectorRoot.getClockProp("show_am_pm", true)
                                    Text { Layout.preferredWidth: 80; text: "Marker Style"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    ModernDropdown {
                                        Layout.fillWidth: true; implicitHeight: 28
                                        model: ["Minimal Text", "Pill Capsule", "Bracketed Telemetry"]
                                        currentValue: {
                                            var s = inspectorRoot.getClockProp("am_pm_style", "text")
                                            if (s === "pill") return "Pill Capsule"
                                            if (s === "bracketed") return "Bracketed Telemetry"
                                            return "Minimal Text"
                                        }
                                        onSelected: function(v) {
                                            if (v === "Pill Capsule") inspectorRoot.setClockProp("am_pm_style", "pill")
                                            else if (v === "Bracketed Telemetry") inspectorRoot.setClockProp("am_pm_style", "bracketed")
                                            else inspectorRoot.setClockProp("am_pm_style", "text")
                                        }
                                    }
                                }
                            }
                        }

                        // ── SECTION: OBSIDIAN GLASS SURFACE PLATE ────────────
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: surfCol.implicitHeight + 16
                            radius: 10
                            color: Theme.alpha(Theme.surface, 0.40)
                            border.width: 1; border.color: Theme.alpha(Theme.accent, 0.18)

                            ColumnLayout {
                                id: surfCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        Layout.fillWidth: true
                                        text: "OBSIDIAN GLASS PLATE"
                                        color: Theme.accent
                                        font.family: "Outfit"
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        font.letterSpacing: 1.2
                                    }
                                    Switch {
                                        checked: inspectorRoot.getWidgetBackground("clock")
                                        onToggled: inspectorRoot.setWidgetBackground("clock", checked)
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    visible: inspectorRoot.getWidgetBackground("clock")

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        RowLayout {
                                            Text { text: "Corner Radius"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                            Item { Layout.fillWidth: true }
                                            Text { text: Math.round(clockSurfRadSlider.value) + " px"; color: Theme.accent; font.pixelSize: 11; font.family: "Outfit"; font.weight: Font.Bold }
                                        }
                                        ModernSlider {
                                            id: clockSurfRadSlider
                                            Layout.fillWidth: true
                                            from: 0; to: 36
                                            value: inspectorRoot.getClockProp("surface_radius", 20)
                                            onMoved: inspectorRoot.setClockProp("surface_radius", Math.round(value))
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        RowLayout {
                                            Text { text: "Glass Fill Opacity"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                            Item { Layout.fillWidth: true }
                                            Text { text: Math.round(clockSurfOpSlider.value * 100) + "%"; color: Theme.accent; font.pixelSize: 11; font.family: "Outfit"; font.weight: Font.Bold }
                                        }
                                        ModernSlider {
                                            id: clockSurfOpSlider
                                            Layout.fillWidth: true
                                            from: 0.10; to: 0.90
                                            value: inspectorRoot.getClockProp("surface_opacity", 0.55)
                                            onMoved: inspectorRoot.setClockProp("surface_opacity", Number(value.toFixed(2)))
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { Layout.fillWidth: true; text: "Top Specular Highlight Line"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                        Switch {
                                            checked: inspectorRoot.getClockProp("surface_specular", true)
                                            onToggled: inspectorRoot.setClockProp("surface_specular", checked)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // 2. USER AVATAR STUDIO
                    // =========================================================
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        visible: inspectorRoot.selectedModuleKey === "user_avatar"

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: avCol.implicitHeight + 16
                            radius: 10
                            color: Theme.alpha(Theme.surface, 0.40)
                            border.width: 1; border.color: Theme.alpha(Theme.accent, 0.18)

                            ColumnLayout {
                                id: avCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Text {
                                    text: "AVATAR SIZE & CELESTIAL AURA"
                                    color: Theme.accent
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.2
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    RowLayout {
                                        Text { text: "Diameter"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                        Item { Layout.fillWidth: true }
                                        Text { text: Math.round(avDiamSlider.value) + " px"; color: Theme.accent; font.pixelSize: 11; font.family: "Outfit"; font.weight: Font.Bold }
                                    }
                                    ModernSlider {
                                        id: avDiamSlider
                                        Layout.fillWidth: true
                                        from: 60; to: 200
                                        value: inspectorRoot.getAvatarProp("size", 116)
                                        onMoved: inspectorRoot.setAvatarProp("size", Math.round(value))
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: "Breathing Pulse Animation"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    Switch {
                                        checked: inspectorRoot.getAvatarProp("breathing_enabled", true)
                                        onToggled: inspectorRoot.setAvatarProp("breathing_enabled", checked)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: "Celestial Orbit Ring & Satellites"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    Switch {
                                        checked: inspectorRoot.getAvatarProp("orbit_satellites_enabled", true)
                                        onToggled: inspectorRoot.setAvatarProp("orbit_satellites_enabled", checked)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: "Luminescent Aurora Halo Glow"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    Switch {
                                        checked: inspectorRoot.getAvatarProp("glow_enabled", true)
                                        onToggled: inspectorRoot.setAvatarProp("glow_enabled", checked)
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // 3. USERNAME TYPOGRAPHY
                    // =========================================================
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        visible: inspectorRoot.selectedModuleKey === "username"

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: unCol.implicitHeight + 16
                            radius: 10
                            color: Theme.alpha(Theme.surface, 0.40)
                            border.width: 1; border.color: Theme.alpha(Theme.accent, 0.18)

                            ColumnLayout {
                                id: unCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Text {
                                    text: "USERNAME TYPOGRAPHY"
                                    color: Theme.accent
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.2
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.preferredWidth: 80; text: "Font Family"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    ModernDropdown {
                                        Layout.fillWidth: true; implicitHeight: 28
                                        model: inspectorRoot.fontFamilies
                                        currentValue: inspectorRoot.getSubStyleProp("username_style", "font_family", "Outfit")
                                        onSelected: function(v) { inspectorRoot.setSubStyleProp("username_style", "font_family", v) }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.preferredWidth: 80; text: "Font Weight"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    ModernDropdown {
                                        Layout.fillWidth: true; implicitHeight: 28
                                        model: inspectorRoot.fontWeights
                                        currentValue: inspectorRoot.getSubStyleProp("username_style", "weight", "DemiBold")
                                        onSelected: function(v) { inspectorRoot.setSubStyleProp("username_style", "weight", v) }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    RowLayout {
                                        Text { text: "Font Size"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                        Item { Layout.fillWidth: true }
                                        Text { text: Math.round(unSizeSlider.value) + " px"; color: Theme.accent; font.pixelSize: 11; font.family: "Outfit"; font.weight: Font.Bold }
                                    }
                                    ModernSlider {
                                        id: unSizeSlider
                                        Layout.fillWidth: true
                                        from: 12; to: 36
                                        value: inspectorRoot.getSubStyleProp("username_style", "size", 18)
                                        onMoved: inspectorRoot.setSubStyleProp("username_style", "size", Math.round(value))
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: "All-Caps Uppercase"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    Switch {
                                        checked: inspectorRoot.getSubStyleProp("username_style", "uppercase", false)
                                        onToggled: inspectorRoot.setSubStyleProp("username_style", "uppercase", checked)
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // 4. PASSWORD INPUT FIELD
                    // =========================================================
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        visible: inspectorRoot.selectedModuleKey === "input_field"

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: inCol.implicitHeight + 16
                            radius: 10
                            color: Theme.alpha(Theme.surface, 0.40)
                            border.width: 1; border.color: Theme.alpha(Theme.accent, 0.18)

                            ColumnLayout {
                                id: inCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Text {
                                    text: "PASSWORD INPUT CAPSULE"
                                    color: Theme.accent
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.2
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    RowLayout {
                                        Text { text: "Capsule Width"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                        Item { Layout.fillWidth: true }
                                        Text { text: Math.round(inWidthSlider.value) + " px"; color: Theme.accent; font.pixelSize: 11; font.family: "Outfit"; font.weight: Font.Bold }
                                    }
                                    ModernSlider {
                                        id: inWidthSlider
                                        Layout.fillWidth: true
                                        from: 200; to: 420
                                        value: inspectorRoot.getSubStyleProp("input_field_style", "width", 300)
                                        onMoved: inspectorRoot.setSubStyleProp("input_field_style", "width", Math.round(value))
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    RowLayout {
                                        Text { text: "Capsule Height"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                        Item { Layout.fillWidth: true }
                                        Text { text: Math.round(inHeightSlider.value) + " px"; color: Theme.accent; font.pixelSize: 11; font.family: "Outfit"; font.weight: Font.Bold }
                                    }
                                    ModernSlider {
                                        id: inHeightSlider
                                        Layout.fillWidth: true
                                        from: 36; to: 60
                                        value: inspectorRoot.getSubStyleProp("input_field_style", "height", 46)
                                        onMoved: inspectorRoot.setSubStyleProp("input_field_style", "height", Math.round(value))
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    RowLayout {
                                        Text { text: "Corner Radius"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                        Item { Layout.fillWidth: true }
                                        Text { text: Math.round(inRadSlider.value) + " px"; color: Theme.accent; font.pixelSize: 11; font.family: "Outfit"; font.weight: Font.Bold }
                                    }
                                    ModernSlider {
                                        id: inRadSlider
                                        Layout.fillWidth: true
                                        from: 8; to: 30
                                        value: inspectorRoot.getSubStyleProp("input_field_style", "radius", 23)
                                        onMoved: inspectorRoot.setSubStyleProp("input_field_style", "radius", Math.round(value))
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // 5. WEATHER CAPSULE
                    // =========================================================
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        visible: inspectorRoot.selectedModuleKey === "weather"

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: wtCol.implicitHeight + 16
                            radius: 10
                            color: Theme.alpha(Theme.surface, 0.40)
                            border.width: 1; border.color: Theme.alpha(Theme.accent, 0.18)

                            ColumnLayout {
                                id: wtCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Text {
                                    text: "WEATHER CAPSULE"
                                    color: Theme.accent
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.2
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.preferredWidth: 80; text: "Layout Style"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    ModernDropdown {
                                        Layout.fillWidth: true; implicitHeight: 28
                                        model: ["Compact Pill", "Detailed Card"]
                                        currentValue: inspectorRoot.getSubStyleProp("weather_style", "layout", "pill") === "card" ? "Detailed Card" : "Compact Pill"
                                        onSelected: function(v) { inspectorRoot.setSubStyleProp("weather_style", "layout", v === "Detailed Card" ? "card" : "pill") }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: "Show Location City"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    Switch {
                                        checked: inspectorRoot.getSubStyleProp("weather_style", "show_city", true)
                                        onToggled: inspectorRoot.setSubStyleProp("weather_style", "show_city", checked)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.preferredWidth: 80; text: "Temperature Unit"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    ModernDropdown {
                                        Layout.fillWidth: true; implicitHeight: 28
                                        model: ["Celsius (°C)", "Fahrenheit (°F)"]
                                        currentValue: inspectorRoot.getSubStyleProp("weather_style", "unit", "c") === "f" ? "Fahrenheit (°F)" : "Celsius (°C)"
                                        onSelected: function(v) { inspectorRoot.setSubStyleProp("weather_style", "unit", v.indexOf("°F") !== -1 ? "f" : "c") }
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // 6. AUDIO VISUALIZER
                    // =========================================================
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        visible: inspectorRoot.selectedModuleKey === "audio_visualizer"

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: vizCol.implicitHeight + 16
                            radius: 10
                            color: Theme.alpha(Theme.surface, 0.40)
                            border.width: 1; border.color: Theme.alpha(Theme.accent, 0.18)

                            ColumnLayout {
                                id: vizCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Text {
                                    text: "AUDIO VISUALIZER"
                                    color: Theme.accent
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.2
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.preferredWidth: 80; text: "Spectrum Bars"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    ModernDropdown {
                                        Layout.fillWidth: true; implicitHeight: 28
                                        model: ["8 Bars", "12 Bars", "14 Bars", "16 Bars", "20 Bars", "24 Bars"]
                                        currentValue: inspectorRoot.getSubStyleProp("visualizer_style", "bar_count", 14) + " Bars"
                                        onSelected: function(v) {
                                            var num = parseInt(v.split(" ")[0])
                                            inspectorRoot.setSubStyleProp("visualizer_style", "bar_count", num)
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    RowLayout {
                                        Text { text: "Bar Width"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                        Item { Layout.fillWidth: true }
                                        Text { text: Math.round(barWidthSlider.value) + " px"; color: Theme.accent; font.pixelSize: 11; font.family: "Outfit"; font.weight: Font.Bold }
                                    }
                                    ModernSlider {
                                        id: barWidthSlider
                                        Layout.fillWidth: true
                                        from: 2; to: 10
                                        value: inspectorRoot.getSubStyleProp("visualizer_style", "bar_width", 4)
                                        onMoved: inspectorRoot.setSubStyleProp("visualizer_style", "bar_width", Math.round(value))
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    RowLayout {
                                        Text { text: "Bar Spacing"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                        Item { Layout.fillWidth: true }
                                        Text { text: Math.round(barSpaceSlider.value) + " px"; color: Theme.accent; font.pixelSize: 11; font.family: "Outfit"; font.weight: Font.Bold }
                                    }
                                    ModernSlider {
                                        id: barSpaceSlider
                                        Layout.fillWidth: true
                                        from: 2; to: 8
                                        value: inspectorRoot.getSubStyleProp("visualizer_style", "bar_spacing", 4)
                                        onMoved: inspectorRoot.setSubStyleProp("visualizer_style", "bar_spacing", Math.round(value))
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: "Symmetrical Spectrum Curve"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    Switch {
                                        checked: inspectorRoot.getSubStyleProp("visualizer_style", "symmetrical", true)
                                        onToggled: inspectorRoot.setSubStyleProp("visualizer_style", "symmetrical", checked)
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // 7. SYSTEM STATS GRAPH
                    // =========================================================
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        visible: inspectorRoot.selectedModuleKey === "system_stats"

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: statsCol.implicitHeight + 16
                            radius: 10
                            color: Theme.alpha(Theme.surface, 0.40)
                            border.width: 1; border.color: Theme.alpha(Theme.accent, 0.18)

                            ColumnLayout {
                                id: statsCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Text {
                                    text: "SYSTEM STATS GRAPH"
                                    color: Theme.accent
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.2
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.preferredWidth: 80; text: "Display Mode"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    ModernDropdown {
                                        Layout.fillWidth: true; implicitHeight: 28
                                        model: ["Sparkline Graphs", "Telemetry Badges", "Minimalist Chips"]
                                        currentValue: {
                                            var m = inspectorRoot.getSubStyleProp("system_stats_style", "display_mode", "graphs")
                                            if (m === "telemetry") return "Telemetry Badges"
                                            if (m === "minimal") return "Minimalist Chips"
                                            return "Sparkline Graphs"
                                        }
                                        onSelected: function(v) {
                                            if (v === "Telemetry Badges") inspectorRoot.setSubStyleProp("system_stats_style", "display_mode", "telemetry")
                                            else if (v === "Minimalist Chips") inspectorRoot.setSubStyleProp("system_stats_style", "display_mode", "minimal")
                                            else inspectorRoot.setSubStyleProp("system_stats_style", "display_mode", "graphs")
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: "Show CPU Sparkline"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    Switch {
                                        checked: window.config && window.config.stats ? window.config.stats.show_cpu : true
                                        onToggled: {
                                            if (!window.config) window.config = {}
                                            if (!window.config.stats) window.config.stats = {}
                                            window.config.stats.show_cpu = checked
                                            inspectorRoot.notifyDirty()
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: "Show RAM Sparkline"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    Switch {
                                        checked: window.config && window.config.stats ? window.config.stats.show_ram : true
                                        onToggled: {
                                            if (!window.config) window.config = {}
                                            if (!window.config.stats) window.config.stats = {}
                                            window.config.stats.show_ram = checked
                                            inspectorRoot.notifyDirty()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // 8. QUOTE / MOTTO PILL
                    // =========================================================
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        visible: inspectorRoot.selectedModuleKey === "quote"

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: quoteCol.implicitHeight + 16
                            radius: 10
                            color: Theme.alpha(Theme.surface, 0.40)
                            border.width: 1; border.color: Theme.alpha(Theme.accent, 0.18)

                            ColumnLayout {
                                id: quoteCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Text {
                                    text: "INSPIRATIONAL QUOTE"
                                    color: Theme.accent
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.2
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Text { text: "Quote Text:"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 34
                                        radius: 6
                                        color: Theme.alpha(Theme.surface, 0.60)
                                        border.width: 1; border.color: Theme.alpha(Theme.accent, 0.30)
                                        TextInput {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8; anchors.rightMargin: 8
                                            verticalAlignment: TextInput.AlignVCenter
                                            color: Theme.foreground
                                            font.family: "Outfit"
                                            font.pixelSize: 12
                                            text: (window.config && window.config.modules && window.config.modules.quote_text) ? window.config.modules.quote_text : "So, Welcome Back"
                                            onTextEdited: {
                                                if (!window.config) window.config = {}
                                                if (!window.config.modules) window.config.modules = {}
                                                window.config.modules.quote_text = text
                                                inspectorRoot.notifyDirty()
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: "Italic Font Style"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    Switch {
                                        checked: inspectorRoot.getSubStyleProp("quote_style", "italic", true)
                                        onToggled: inspectorRoot.setSubStyleProp("quote_style", "italic", checked)
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: "Quotation Marks Decoration"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    Switch {
                                        checked: inspectorRoot.getSubStyleProp("quote_style", "show_decorations", true)
                                        onToggled: inspectorRoot.setSubStyleProp("quote_style", "show_decorations", checked)
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // 9. SESSION LOCK BADGE
                    // =========================================================
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        visible: inspectorRoot.selectedModuleKey === "session_lock"

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: lockCol.implicitHeight + 16
                            radius: 10
                            color: Theme.alpha(Theme.surface, 0.40)
                            border.width: 1; border.color: Theme.alpha(Theme.accent, 0.18)

                            ColumnLayout {
                                id: lockCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Text {
                                    text: "SESSION LOCK BADGE"
                                    color: Theme.accent
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.2
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.preferredWidth: 80; text: "Badge Style"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    ModernDropdown {
                                        Layout.fillWidth: true; implicitHeight: 28
                                        model: ["Pill Capsule", "Minimalist Text", "Bracketed"]
                                        currentValue: {
                                            var b = inspectorRoot.getSubStyleProp("session_lock_style", "badge_style", "pill")
                                            if (b === "bracketed") return "Bracketed"
                                            if (b === "text") return "Minimalist Text"
                                            return "Pill Capsule"
                                        }
                                        onSelected: function(v) {
                                            if (v === "Bracketed") inspectorRoot.setSubStyleProp("session_lock_style", "badge_style", "bracketed")
                                            else if (v === "Minimalist Text") inspectorRoot.setSubStyleProp("session_lock_style", "badge_style", "text")
                                            else inspectorRoot.setSubStyleProp("session_lock_style", "badge_style", "pill")
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: "Show Lock Icon"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                    Switch {
                                        checked: inspectorRoot.getSubStyleProp("session_lock_style", "show_icon", true)
                                        onToggled: inspectorRoot.setSubStyleProp("session_lock_style", "show_icon", checked)
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // 10. ATMOSPHERE & BACKDROP BLUR
                    // =========================================================
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        visible: inspectorRoot.selectedModuleKey === "backdrop"

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: bdCol.implicitHeight + 16
                            radius: 10
                            color: Theme.alpha(Theme.surface, 0.40)
                            border.width: 1; border.color: Theme.alpha(Theme.accent, 0.18)

                            ColumnLayout {
                                id: bdCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Text {
                                    text: "BACKDROP ATMOSPHERE"
                                    color: Theme.accent
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.2
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    RowLayout {
                                        Text { text: "Gaussian Blur"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                        Item { Layout.fillWidth: true }
                                        Text { text: Math.round(bdBlurSlider.value * 100) + "%"; color: Theme.accent; font.pixelSize: 11; font.family: "Outfit"; font.weight: Font.Bold }
                                    }
                                    ModernSlider {
                                        id: bdBlurSlider
                                        Layout.fillWidth: true
                                        from: 0.0; to: 1.0
                                        value: inspectorRoot.getBackdropProp("blur", 0.65)
                                        onMoved: inspectorRoot.setBackdropProp("blur", Number(value.toFixed(2)))
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    RowLayout {
                                        Text { text: "Vignette Falloff"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                        Item { Layout.fillWidth: true }
                                        Text { text: Math.round(bdVigSlider.value * 100) + "%"; color: Theme.accent; font.pixelSize: 11; font.family: "Outfit"; font.weight: Font.Bold }
                                    }
                                    ModernSlider {
                                        id: bdVigSlider
                                        Layout.fillWidth: true
                                        from: 0.0; to: 1.0
                                        value: inspectorRoot.getBackdropProp("vignette", 0.60)
                                        onMoved: inspectorRoot.setBackdropProp("vignette", Number(value.toFixed(2)))
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    RowLayout {
                                        Text { text: "Dimming Opacity"; color: Theme.foreground; font.pixelSize: 11; font.family: "Outfit" }
                                        Item { Layout.fillWidth: true }
                                        Text { text: Math.round(bdDimSlider.value * 100) + "%"; color: Theme.accent; font.pixelSize: 11; font.family: "Outfit"; font.weight: Font.Bold }
                                    }
                                    ModernSlider {
                                        id: bdDimSlider
                                        Layout.fillWidth: true
                                        from: 0.0; to: 0.80
                                        value: inspectorRoot.getBackdropProp("dimming", 0.20)
                                        onMoved: inspectorRoot.setBackdropProp("dimming", Number(value.toFixed(2)))
                                    }
                                }
                            }
                        }
                    }

                    // Bottom Padding
                    Item { height: 16 }
                }
            }
        }
    }
}
