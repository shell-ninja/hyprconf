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
    readonly property string imageSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/></svg>')
    readonly property string quoteSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 21c3 0 7-1 7-8V5c0-1.25-.756-2.017-2-2H4c-1.25 0-2 .75-2 1.972V11c0 1.25.75 2 2 2 1 0 1 0 1 1v1c0 1-1 2-2 2s-1 .008-1 1.031V20c0 1 0 1 1 1z"/><path d="M15 21c3 0 7-1 7-8V5c0-1.25-.757-2.017-2-2h-4c-1.25 0-2 .75-2 1.972V11c0 1.25.75 2 2 2 1 0 1 0 1 1v1c0 1-1 2-2 2s-1 .008-1 1.031V20c0 1 0 1 1 1z"/></svg>')
    readonly property string cloudSunSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2v2"/><path d="m4.93 4.93 1.41 1.41"/><path d="M20 12h2"/><path d="m19.07 4.93-1.41 1.41"/><path d="M15.947 12.65a4 4 0 0 0-5.925-4.128"/><path d="M13 22H7a5 5 0 1 1 4.9-6H13a3 3 0 0 1 0 6z"/></svg>')
    readonly property string moveSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="5 9 2 12 5 15"/><polyline points="9 5 12 2 15 5"/><polyline points="15 19 12 22 9 19"/><polyline points="19 9 22 12 19 15"/><line x1="2" y1="12" x2="22" y2="12"/><line x1="12" y1="2" x2="12" y2="22"/></svg>')
    readonly property string globeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>')
    readonly property string musicSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></svg>')
    readonly property string chartSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>')
    readonly property string slidersSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="4" y1="21" x2="4" y2="14"/><line x1="4" y1="10" x2="4" y2="3"/><line x1="12" y1="21" x2="12" y2="12"/><line x1="12" y1="8" x2="12" y2="3"/><line x1="20" y1="21" x2="20" y2="16"/><line x1="20" y1="12" x2="20" y2="3"/><line x1="1" y1="14" x2="7" y2="14"/><line x1="9" y1="8" x2="15" y2="8"/><line x1="17" y1="16" x2="23" y2="16"/></svg>')
    readonly property string paletteSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="13.5" cy="6.5" r=".5" fill="' + Theme.accent + '"/><circle cx="17.5" cy="10.5" r=".5" fill="' + Theme.accent + '"/><circle cx="8.5" cy="7.5" r=".5" fill="' + Theme.accent + '"/><circle cx="6.5" cy="12.5" r=".5" fill="' + Theme.accent + '"/><path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.926 0 1.648-.746 1.648-1.688 0-.437-.18-.835-.437-1.125-.29-.289-.438-.652-.438-1.125a1.64 1.64 0 0 1 1.668-1.668h1.996c3.051 0 5.555-2.503 5.555-5.554C21.965 6.012 17.461 2 12 2z"/></svg>')
    readonly property string crossSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>')

    function getTabSvg(tabIdx, isSelected) {
        var stroke = isSelected ? Theme.on_primary : Theme.accent
        if (tabIdx === 0) {
            return svgUrl("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"" + stroke + "\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><rect x=\"3\" y=\"3\" width=\"18\" height=\"18\" rx=\"2\" ry=\"2\"/><line x1=\"3\" y1=\"9\" x2=\"21\" y2=\"9\"/><line x1=\"9\" y1=\"21\" x2=\"9\" y2=\"9\"/></svg>")
        } else if (tabIdx === 1) {
            return svgUrl("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"" + stroke + "\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><circle cx=\"12\" cy=\"12\" r=\"10\"/><polyline points=\"12 6 12 12 16 14\"/></svg>")
        } else if (tabIdx === 2) {
            return svgUrl("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"" + stroke + "\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2\"/><circle cx=\"12\" cy=\"7\" r=\"4\"/></svg>")
        } else if (tabIdx === 3) {
            return svgUrl("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"" + stroke + "\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><rect x=\"3\" y=\"3\" width=\"7\" height=\"7\"/><rect x=\"14\" y=\"3\" width=\"7\" height=\"7\"/><rect x=\"14\" y=\"14\" width=\"7\" height=\"7\"/><rect x=\"3\" y=\"14\" width=\"7\" height=\"7\"/></svg>")
        } else {
            return svgUrl("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"" + stroke + "\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><circle cx=\"13.5\" cy=\"6.5\" r=\".5\" fill=\"" + stroke + "\"/><circle cx=\"17.5\" cy=\"10.5\" r=\".5\" fill=\"" + stroke + "\"/><circle cx=\"8.5\" cy=\"7.5\" r=\".5\" fill=\"" + stroke + "\"/><circle cx=\"6.5\" cy=\"12.5\" r=\".5\" fill=\"" + stroke + "\"/><path d=\"M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.926 0 1.648-.746 1.648-1.688 0-.437-.18-.835-.437-1.125-.29-.289-.438-.652-.438-1.125a1.64 1.64 0 0 1 1.668-1.668h1.996c3.051 0 5.555-2.503 5.555-5.554C21.965 6.012 17.461 2 12 2z\"/></svg>")
        }
    }

    RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            // ==========================================
            // LEFT COLUMN: Live Scaled WYSIWYG Preview
            // ==========================================
            Item {
                Layout.preferredWidth: 380
                Layout.fillHeight: true

                Rectangle {
                    id: previewContainer
                    anchors.fill: parent
                    radius: 16
                    color: Theme.alpha(Theme.surface, 0.55)
                    border.width: 1
                    border.color: Theme.alpha(Theme.accent, 0.30)
                    clip: true

                    // Scaled Wallpaper
                    Image {
                        id: previewWallpaper
                        anchors.fill: parent
                        source: window.wallpaperPath
                        fillMode: Image.PreserveAspectCrop
                        smooth: true

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            blurEnabled: true
                            blur: window.config.backdrop ? window.config.backdrop.blur : 0.65
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

                    // Freeform Canvas Area
                    Item {
                        id: previewCanvas
                        anchors.fill: parent

                        // ========================================================
                        // DRAGGABLE WIDGETS (Interactive Canvas)
                        // ========================================================

                        // 1. Clock & Date
                        DraggableWidget {
                            moduleKey: "clock"
                            title: "Clock & Date"
                            normX: (window.config.positions && window.config.positions.clock) ? window.config.positions.clock.x : 0.50
                            normY: (window.config.positions && window.config.positions.clock) ? window.config.positions.clock.y : 0.20
                            canvasWidth: previewCanvas.width
                            canvasHeight: previewCanvas.height
                            visible: window.config.clock && window.config.clock.enabled
                            onPositionDropped: function(nx, ny) { window.updateWidgetPosition("clock", nx, ny) }

                            Column {
                                spacing: 4
                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 4

                                    Text {
                                        id: previewTimeText
                                        text: {
                                            var d = window.currentTime
                                            var is24h = Boolean(window.config.clock && window.config.clock.format_24h)
                                            if (is24h) {
                                                return Qt.formatDateTime(d, "HH:mm")
                                            }
                                            var h = d.getHours() % 12
                                            if (h === 0) h = 12
                                            var hStr = (h < 10 ? "0" : "") + h
                                            var mStr = (d.getMinutes() < 10 ? "0" : "") + d.getMinutes()
                                            return hStr + ":" + mStr
                                        }
                                        color: Theme.accent
                                        font.family: "Outfit"
                                        font.pixelSize: (window.config.clock ? window.config.clock.size : 84) * 0.52
                                        font.weight: {
                                            var w = window.config.clock ? window.config.clock.weight : "Light"
                                            if (w === "Bold") return Font.Bold
                                            if (w === "Medium") return Font.Medium
                                            return Font.Light
                                        }
                                    }

                                    Text {
                                        anchors.bottom: previewTimeText.bottom
                                        anchors.bottomMargin: 6
                                        text: Qt.formatTime(window.currentTime, "AP")
                                        visible: window.config.clock && !window.config.clock.format_24h && window.config.clock.show_am_pm
                                        color: Theme.alpha(Theme.accent, 0.90)
                                        font.family: "Outfit"
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: {
                                        var d = window.currentTime
                                        if (window.config.date && window.config.date.format === "compact") {
                                            return Qt.formatDate(d, "ddd, MMM d").toUpperCase()
                                        } else {
                                            return Qt.formatDate(d, "dddd, MMMM d").toUpperCase()
                                        }
                                    }
                                    color: Theme.alpha(Theme.foreground, 0.75)
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                    font.letterSpacing: 2
                                    visible: window.config.date && window.config.date.enabled
                                }
                            }
                        }

                        // 2. Identity & Unlock Cluster (Avatar + User + Password Capsule)
                        DraggableWidget {
                            moduleKey: "avatar"
                            title: "Avatar & Auth"
                            normX: (window.config.positions && window.config.positions.avatar) ? window.config.positions.avatar.x : 0.50
                            normY: (window.config.positions && window.config.positions.avatar) ? window.config.positions.avatar.y : 0.52
                            canvasWidth: previewCanvas.width
                            canvasHeight: previewCanvas.height
                            visible: window.config.avatar && window.config.avatar.enabled
                            onPositionDropped: function(nx, ny) { window.updateWidgetPosition("avatar", nx, ny) }

                            Column {
                                id: avatarAuthCol
                                spacing: 10
                                width: 190

                                // Circular Avatar with Breathing & Orbit Satellites
                                Item {
                                    id: avatarHaloBox
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    readonly property real avSize: (window.config.avatar ? window.config.avatar.size : 116) * 0.65
                                    width: avSize + 16
                                    height: avSize + 16

                                    // Ambient Breathing Halo
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: parent.width + 10
                                        height: parent.height + 10
                                        radius: width / 2
                                        color: Theme.alpha(Theme.accent, (window.config.avatar && window.config.avatar.glow_enabled) ? window.glowOpacity : 0.0)
                                        visible: window.config.avatar && window.config.avatar.glow_enabled
                                    }

                                    // Orbit ring & Rotating Satellites
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: parent.width
                                        height: parent.height
                                        radius: width / 2
                                        color: "transparent"
                                        border.width: 1
                                        border.color: Theme.alpha(Theme.accent, 0.40)
                                        visible: window.config.avatar && window.config.avatar.orbit_satellites_enabled
                                        rotation: window.orbitAngle

                                        Rectangle {
                                            width: 5; height: 5; radius: 2.5
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            y: -2.5
                                            color: Theme.accent
                                            border.width: 1; border.color: "#ffffff"
                                        }
                                        Rectangle {
                                            width: 4; height: 4; radius: 2
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            y: parent.height - 2
                                            color: Theme.accent
                                            border.width: 1; border.color: "#ffffff"
                                        }
                                    }

                                    // Truly Circular Masked Avatar Image
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

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: width / 2
                                                color: "#ffffff"
                                                antialiasing: true
                                            }
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
                                                width: parent.width * 0.45
                                                height: parent.height * 0.45
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

                                        // Fine Rim Ring
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: width / 2
                                            color: "transparent"
                                            border.width: 1.5
                                            border.color: Theme.alpha(Theme.accent, 0.85)
                                        }
                                    }
                                }

                                // Display Name & Status
                                Column {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 2
                                    visible: window.config.avatar && window.config.avatar.show_username

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Shell Ninja"
                                        color: Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }

                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 4
                                        visible: window.config.avatar && window.config.avatar.show_status

                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 5; height: 5; radius: 2.5
                                            color: Theme.accent
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "Session Locked"
                                            color: Theme.alpha(Theme.foreground, 0.65)
                                            font.family: "Outfit"
                                            font.pixelSize: 9
                                        }
                                    }
                                }

                                // Password Input Capsule
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 190
                                    height: 32
                                    radius: 16
                                    color: Theme.alpha(Theme.surface, 0.50)
                                    border.width: 1
                                    border.color: Theme.alpha(Theme.accent, 0.45)

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 8
                                        Image {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 12; height: 12
                                            source: window.lockSvg
                                            sourceSize: Qt.size(24, 24)
                                        }
                                        Text {
                                            text: "Enter password"
                                            color: Qt.rgba(1, 1, 1, 0.65)
                                            font.family: "Outfit"
                                            font.pixelSize: 10
                                        }
                                    }
                                }
                            }
                        }

                        // 3. Weather Forecast Capsule (Draggable & Custom Location)
                        DraggableWidget {
                            moduleKey: "weather"
                            title: "Weather Capsule"
                            normX: (window.config.positions && window.config.positions.weather) ? window.config.positions.weather.x : 0.80
                            normY: (window.config.positions && window.config.positions.weather) ? window.config.positions.weather.y : 0.09
                            canvasWidth: previewCanvas.width
                            canvasHeight: previewCanvas.height
                            visible: window.config.modules && window.config.modules.weather_widget
                            onPositionDropped: function(nx, ny) { window.updateWidgetPosition("weather", nx, ny) }

                            Rectangle {
                                width: weatherRow.implicitWidth + 24
                                height: 28
                                radius: 14
                                color: Theme.alpha(Theme.surface, 0.70)
                                border.width: 1
                                border.color: Theme.alpha(Theme.accent, 0.40)

                                Row {
                                    id: weatherRow
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Image {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 13; height: 13
                                        source: window.cloudSunSvg
                                        sourceSize: Qt.size(26, 26)
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
                                        font.pixelSize: 10
                                        font.weight: Font.Medium
                                    }
                                }
                            }
                        }

                        // 4. Inspirational Quote Pill
                        DraggableWidget {
                            moduleKey: "quote"
                            title: "Quote Pill"
                            normX: (window.config.positions && window.config.positions.quote) ? window.config.positions.quote.x : 0.50
                            normY: (window.config.positions && window.config.positions.quote) ? window.config.positions.quote.y : 0.33
                            canvasWidth: previewCanvas.width
                            canvasHeight: previewCanvas.height
                            visible: window.config.modules && window.config.modules.custom_quote
                            onPositionDropped: function(nx, ny) { window.updateWidgetPosition("quote", nx, ny) }

                            Rectangle {
                                width: Math.min(previewCanvas.width - 40, quotePrevText.implicitWidth + 24)
                                height: 24
                                radius: 12
                                color: Theme.alpha(Theme.surface, 0.65)
                                border.width: 1
                                border.color: Theme.alpha(Theme.accent, 0.40)

                                Text {
                                    id: quotePrevText
                                    anchors.centerIn: parent
                                    text: window.liveQuoteText
                                    color: Theme.foreground
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        // 5. Media Player Card
                        DraggableWidget {
                            moduleKey: "media_player"
                            title: "Media Player"
                            normX: (window.config.positions && window.config.positions.media_player) ? window.config.positions.media_player.x : 0.25
                            normY: (window.config.positions && window.config.positions.media_player) ? window.config.positions.media_player.y : 0.88
                            canvasWidth: previewCanvas.width
                            canvasHeight: previewCanvas.height
                            visible: window.config.modules && window.config.modules.media_player
                            onPositionDropped: function(nx, ny) { window.updateWidgetPosition("media_player", nx, ny) }

                            Rectangle {
                                width: 210
                                height: 40
                                radius: 12
                                color: Theme.alpha(Theme.surface, 0.65)
                                border.width: 1
                                border.color: Theme.alpha(Theme.accent, 0.40)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 8

                                    Rectangle {
                                        Layout.preferredWidth: 28
                                        Layout.preferredHeight: 28
                                        radius: 6
                                        color: Theme.alpha(Theme.accent, 0.35)
                                        Image {
                                            anchors.centerIn: parent
                                            width: 14; height: 14
                                            source: window.musicSvg
                                            sourceSize: Qt.size(28, 28)
                                        }
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text {
                                            text: "Midnight City"
                                            color: Theme.foreground
                                            font.family: "Outfit"
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: "M83 — Hurry Up (Auto-hides if stopped)"
                                            color: Theme.alpha(Theme.foreground, 0.60)
                                            font.family: "Outfit"
                                            font.pixelSize: 8
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }

                        // 6. System Stats Badge (Multi-Metric + Units)
                        DraggableWidget {
                            moduleKey: "system_stats"
                            title: "System Stats"
                            normX: (window.config.positions && window.config.positions.system_stats) ? window.config.positions.system_stats.x : 0.50
                            normY: (window.config.positions && window.config.positions.system_stats) ? window.config.positions.system_stats.y : 0.88
                            canvasWidth: previewCanvas.width
                            canvasHeight: previewCanvas.height
                            visible: window.config.modules && window.config.modules.system_stats
                            onPositionDropped: function(nx, ny) { window.updateWidgetPosition("system_stats", nx, ny) }

                            Rectangle {
                                width: Math.min(previewCanvas.width - 24, statsRow.implicitWidth + 24)
                                height: 24
                                radius: 12
                                color: Theme.alpha(Theme.surface, 0.70)
                                border.width: 1
                                border.color: Theme.alpha(Theme.accent, 0.35)

                                Row {
                                    id: statsRow
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Image {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 10; height: 10
                                        source: window.zapSvg
                                        sourceSize: Qt.size(20, 20)
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: window.getSystemStatsString()
                                        color: Theme.alpha(Theme.foreground, 0.85)
                                        font.family: "Outfit"
                                        font.pixelSize: 9
                                        font.weight: Font.Medium
                                    }
                                }
                            }
                        }
                    }

                    // Preview Corner Badges
                    Row {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.margins: 12
                        visible: window.config.layout && window.config.layout.corner_session_badge

                        Rectangle {
                            height: 18
                            width: 76
                            radius: 9
                            color: Theme.alpha(Theme.surface, 0.50)
                            border.width: 1
                            border.color: Theme.alpha(Theme.accent, 0.25)
                            Text {
                                anchors.centerIn: parent
                                text: "Hyprland"
                                color: Theme.alpha(Theme.foreground, 0.70)
                                font.pixelSize: 9
                            }
                        }
                    }

                    Row {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.margins: 12
                        spacing: 6
                        visible: window.config.layout && window.config.layout.corner_power_buttons

                        Rectangle {
                            width: 20; height: 20; radius: 10
                            color: Theme.alpha(Theme.surface, 0.50)
                            border.width: 1; border.color: Theme.alpha(Theme.accent, 0.25)
                            Image {
                                anchors.centerIn: parent
                                width: 10; height: 10
                                source: window.restartSvg
                                sourceSize: Qt.size(20, 20)
                            }
                        }
                        Rectangle {
                            width: 20; height: 20; radius: 10
                            color: Theme.alpha(Theme.surface, 0.50)
                            border.width: 1; border.color: Theme.alpha(Theme.accent, 0.25)
                            Image {
                                anchors.centerIn: parent
                                width: 10; height: 10
                                source: window.powerSvg
                                sourceSize: Qt.size(20, 20)
                            }
                        }
                    }

                    // Top Bar: Watermark + Drag & Drop Status Indicator
                    RowLayout {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 10
                        spacing: 8

                        Rectangle {
                            height: 22
                            width: 105
                            radius: 11
                            color: Theme.alpha(Theme.background, 0.85)
                            border.width: 1
                            border.color: Theme.alpha(Theme.accent, 0.40)
                            Row {
                                anchors.centerIn: parent
                                spacing: 4
                                Image {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 11; height: 11
                                    source: window.moveSvg
                                    sourceSize: Qt.size(22, 22)
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "DRAG CANVAS"
                                    color: Theme.accent
                                    font.family: "Outfit"
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            height: 20
                            width: hintText.implicitWidth + 12
                            radius: 10
                            color: Theme.alpha(Theme.surface, 0.70)
                            border.width: 1
                            border.color: Theme.alpha(Theme.accent, 0.25)
                            Text {
                                id: hintText
                                anchors.centerIn: parent
                                text: "Click & drag widgets"
                                color: Theme.alpha(Theme.foreground, 0.75)
                                font.family: "Outfit"
                                font.pixelSize: 9
                            }
                        }
                    }
                }
            }

            // ==========================================
            // RIGHT COLUMN: Modular Tabbed Controllers
            // ==========================================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                // Tab Bar Selector (Horizontally Scrollable)
                Item {
                    Layout.fillWidth: true
                    height: 40

                    Flickable {
                        id: lockTabFlickable
                        anchors.fill: parent
                        contentWidth: lockTabRow.implicitWidth
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        flickableDirection: Flickable.HorizontalFlick

                        WheelHandler {
                            target: lockTabFlickable
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: function(event) {
                                var delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x
                                lockTabFlickable.contentX = Math.max(0, Math.min(lockTabFlickable.contentWidth - lockTabFlickable.width, lockTabFlickable.contentX - delta))
                            }
                        }

                        Row {
                            id: lockTabRow
                            spacing: 8
                            height: 38

                            Repeater {
                                model: [
                                    { name: "Layout & Placement", tabIndex: 0 },
                                    { name: "Clock & Date", tabIndex: 1 },
                                    { name: "Avatar", tabIndex: 2 },
                                    { name: "Widgets", tabIndex: 3 },
                                    { name: "Backdrop", tabIndex: 4 }
                                ]

                                Rectangle {
                                    height: 38
                                    radius: 19
                                    readonly property bool isSelected: window.activeTab === modelData.tabIndex
                                    implicitWidth: lockTabContent.implicitWidth + 24
                                    color: isSelected
                                        ? Theme.accent
                                        : (tabMouse.containsMouse ? Theme.alpha(Theme.surface, 0.80) : Theme.alpha(Theme.surface, 0.40))
                                    border.width: 1
                                    border.color: isSelected
                                        ? Theme.accent
                                        : Theme.alpha(Theme.accent, 0.25)
                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    Row {
                                        id: lockTabContent
                                        anchors.centerIn: parent
                                        spacing: 8
                                        Image {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 15
                                            height: 15
                                            source: window.getTabSvg(modelData.tabIndex, parent.parent.isSelected)
                                            sourceSize: Qt.size(30, 30)
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.name
                                            color: parent.parent.isSelected ? Theme.on_primary : Theme.foreground
                                            font.family: "Outfit"
                                            font.pixelSize: 12
                                            font.weight: parent.parent.isSelected ? Font.DemiBold : Font.Normal
                                        }
                                    }

                                    MouseArea {
                                        id: tabMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: window.activeTab = modelData.tabIndex
                                    }
                                }
                            }
                        }
                    }
                }

                // Scrollable Content Box for Active Tab
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

                        Column {
                            width: parent.width
                            spacing: 16

                            // ----------------------------------------------------
                            // TAB 0: LAYOUT & POSITIONING
                            // ----------------------------------------------------
                            Column {
                                width: parent.width
                                spacing: 14
                                visible: window.activeTab === 0

                                Text {
                                    text: "Interactive Placement & Canvas"
                                    color: Theme.foreground
                                    font.family: "Outfit"
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                }

                                // Interactive Drag Banner
                                Rectangle {
                                    width: parent.width
                                    height: 48
                                    radius: 12
                                    color: Theme.alpha(Theme.accent, 0.15)
                                    border.width: 1
                                    border.color: Theme.alpha(Theme.accent, 0.45)

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 10

                                        Image {
                                            Layout.preferredWidth: 20
                                            Layout.preferredHeight: 20
                                            source: window.moveSvg
                                            sourceSize: Qt.size(40, 40)
                                        }

                                        Column {
                                            Layout.fillWidth: true
                                            spacing: 1
                                            Text {
                                                text: "Drag & Drop Canvas Enabled"
                                                color: Theme.foreground
                                                font.family: "Outfit"
                                                font.pixelSize: 12
                                                font.weight: Font.DemiBold
                                            }
                                            Text {
                                                text: "Click and drag any module on the Live Preview screen to place it anywhere."
                                                color: Theme.alpha(Theme.foreground, 0.70)
                                                font.family: "Outfit"
                                                font.pixelSize: 10
                                            }
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: 100
                                            Layout.preferredHeight: 28
                                            radius: 14
                                            color: resetPosMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.50)
                                            border.width: 1
                                            border.color: Theme.alpha(Theme.accent, 0.35)

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Reset Positions"
                                                color: Theme.foreground
                                                font.family: "Outfit"
                                                font.pixelSize: 10
                                                font.weight: Font.Medium
                                            }

                                            MouseArea {
                                                id: resetPosMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    window.config.positions = {
                                                        clock: { x: 0.50, y: 0.20, preset: "top-center" },
                                                        quote: { x: 0.50, y: 0.33, preset: "top-center" },
                                                        avatar: { x: 0.50, y: 0.52, preset: "center" },
                                                        weather: { x: 0.80, y: 0.09, preset: "top-right" },
                                                        media_player: { x: 0.25, y: 0.88, preset: "bottom-left" },
                                                        system_stats: { x: 0.50, y: 0.88, preset: "bottom-center" }
                                                    }
                                                    window.markDirty()
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Theme.alpha(Theme.accent, 0.20) }

                                // Quick Placement Presets for Active Elements
                                Text {
                                    text: "Quick Presets for Enabled Modules"
                                    color: Theme.alpha(Theme.foreground, 0.85)
                                    font.family: "Outfit"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                }

                                // Preset grid for each module
                                Repeater {
                                    model: [
                                        { key: "avatar", name: "Avatar & Auth", presets: ["center", "top-center", "bottom-center"] },
                                        { key: "clock", name: "Clock & Date", presets: ["top-left", "top-center", "top-right", "center"] },
                                        { key: "weather", name: "Weather Capsule", presets: ["top-left", "top-right", "bottom-left", "bottom-right"] },
                                        { key: "media_player", name: "Media Player", presets: ["bottom-left", "bottom-right", "center"] },
                                        { key: "quote", name: "Quote / Motto", presets: ["top-center", "center", "bottom-center"] },
                                        { key: "system_stats", name: "System Stats", presets: ["bottom-left", "bottom-center", "bottom-right"] }
                                    ]

                                    RowLayout {
                                        id: modulePresetRow
                                        required property var modelData
                                        readonly property string modKey: modelData.key
                                        width: parent.width
                                        spacing: 12

                                        Text {
                                            text: modulePresetRow.modelData.name + ":"
                                            color: Theme.alpha(Theme.foreground, 0.85)
                                            font.family: "Outfit"
                                            font.pixelSize: 12
                                            Layout.preferredWidth: 110
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 28

                                            Flickable {
                                                id: presetFlickable
                                                anchors.fill: parent
                                                contentWidth: presetRowContent.implicitWidth
                                                clip: true
                                                boundsBehavior: Flickable.StopAtBounds
                                                flickableDirection: Flickable.HorizontalFlick

                                                Row {
                                                    id: presetRowContent
                                                    spacing: 6
                                                    height: parent.height

                                                    Repeater {
                                                        model: (modulePresetRow.modelData && modulePresetRow.modelData.presets) ? modulePresetRow.modelData.presets : []
                                                        Rectangle {
                                                            id: presetBtn
                                                            required property string modelData
                                                            width: presetText.implicitWidth + 14
                                                            height: 26
                                                            radius: 13
                                                            readonly property bool isCurPreset: Boolean(window.config && window.config.positions && window.config.positions[modulePresetRow.modKey] && window.config.positions[modulePresetRow.modKey].preset === presetBtn.modelData)
                                                            color: isCurPreset ? Theme.accent : Theme.alpha(Theme.surface, 0.60)
                                                            border.width: 1
                                                            border.color: isCurPreset ? Theme.accent : Theme.alpha(Theme.accent, 0.25)

                                                            Text {
                                                                id: presetText
                                                                anchors.centerIn: parent
                                                                text: presetBtn.modelData.replace("-", " ")
                                                                color: presetBtn.isCurPreset ? Theme.on_primary : Theme.foreground
                                                                font.family: "Outfit"
                                                                font.pixelSize: 10
                                                                font.weight: presetBtn.isCurPreset ? Font.DemiBold : Font.Normal
                                                                font.capitalization: Font.Capitalize
                                                            }

                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: window.applyPreset(modulePresetRow.modKey, presetBtn.modelData)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Theme.alpha(Theme.accent, 0.20) }

                                // Corner Buttons Toggles
                                RowLayout {
                                    width: parent.width
                                    Text { text: "Show Corner Power / Reboot Buttons"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                                    Item { Layout.fillWidth: true }
                                    CapsuleSwitch {
                                        checked: window.config.layout ? window.config.layout.corner_power_buttons : true
                                        onToggled: {
                                            if (!window.config.layout) window.config.layout = {}
                                            window.config.layout.corner_power_buttons = checked
                                            window.markDirty()
                                        }
                                    }
                                }

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Show Bottom-Left Session Badge"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                                    Item { Layout.fillWidth: true }
                                    CapsuleSwitch {
                                        checked: window.config.layout ? window.config.layout.corner_session_badge : true
                                        onToggled: {
                                            if (!window.config.layout) window.config.layout = {}
                                            window.config.layout.corner_session_badge = checked
                                            window.markDirty()
                                        }
                                    }
                                }
                            }

                            // ----------------------------------------------------
                            // TAB 1: CLOCK & DATE
                            // ----------------------------------------------------
                            Column {
                                width: parent.width
                                spacing: 14
                                visible: window.activeTab === 1

                                Text {
                                    text: "Clock & Date Formatting"
                                    color: Theme.foreground
                                    font.family: "Outfit"
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                }

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Enable Clock"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                                    Item { Layout.fillWidth: true }
                                    CapsuleSwitch {
                                        checked: window.config.clock ? window.config.clock.enabled : true
                                        onToggled: {
                                            if (!window.config.clock) window.config.clock = {}
                                            window.config.clock.enabled = checked
                                            window.markDirty()
                                        }
                                    }
                                }

                                RowLayout {
                                    width: parent.width
                                    Text { text: "24-Hour Military Format (HH:mm)"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                                    Item { Layout.fillWidth: true }
                                    CapsuleSwitch {
                                        checked: window.config.clock ? window.config.clock.format_24h : false
                                        onToggled: {
                                            if (!window.config.clock) window.config.clock = {}
                                            window.config.clock.format_24h = checked
                                            window.markDirty()
                                        }
                                    }
                                }

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Show AM/PM Period Badge"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                                    Item { Layout.fillWidth: true }
                                    CapsuleSwitch {
                                        checked: window.config.clock ? window.config.clock.show_am_pm : true
                                        enabled: window.config.clock && !window.config.clock.format_24h
                                        onToggled: {
                                            if (!window.config.clock) window.config.clock = {}
                                            window.config.clock.show_am_pm = checked
                                            window.markDirty()
                                        }
                                    }
                                }

                                // Clock Font Weight Selector
                                RowLayout {
                                    width: parent.width
                                    Text { text: "Clock Typography Weight:"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                                    Item { Layout.fillWidth: true }
                                    Row {
                                        spacing: 6
                                        Repeater {
                                            model: [
                                                { label: "Light", val: "Light" },
                                                { label: "Medium", val: "Medium" },
                                                { label: "Bold", val: "Bold" }
                                            ]
                                            Rectangle {
                                                id: weightBtn
                                                width: 68; height: 30; radius: 15
                                                readonly property bool isSelected: (window.config.clock && window.config.clock.weight === modelData.val)
                                                color: weightBtn.isSelected ? Theme.accent : Theme.alpha(Theme.surface, 0.65)
                                                border.width: 1
                                                border.color: weightBtn.isSelected ? Theme.accent : Theme.alpha(Theme.accent, 0.25)
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.label
                                                    color: weightBtn.isSelected ? Theme.on_primary : Theme.foreground
                                                    font.family: "Outfit"
                                                    font.pixelSize: 11
                                                    font.weight: weightBtn.isSelected ? Font.DemiBold : Font.Normal
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (!window.config.clock) window.config.clock = {}
                                                        window.config.clock.weight = modelData.val
                                                        window.markDirty()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Clock Size Slider
                                Column {
                                    width: parent.width
                                    spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Clock Size:"; color: Theme.alpha(Theme.foreground, 0.85); font.family: "Outfit"; font.pixelSize: 13 }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: Math.round(clockSizeSlider.value) + " px"
                                            color: Theme.accent
                                            font.family: "Outfit"
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                    ModernSlider {
                                        id: clockSizeSlider
                                        width: parent.width
                                        from: 56
                                        to: 112
                                        stepSize: 4
                                        value: window.config.clock ? window.config.clock.size : 84
                                        onMoved: {
                                            if (!window.config.clock) window.config.clock = {}
                                            window.config.clock.size = Math.round(value)
                                            window.markDirty()
                                        }
                                    }
                                }

                                // Date Settings
                                Rectangle { width: parent.width; height: 1; color: Theme.alpha(Theme.accent, 0.20) }

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Enable Date Line"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                                    Item { Layout.fillWidth: true }
                                    CapsuleSwitch {
                                        checked: window.config.date ? window.config.date.enabled : true
                                        onToggled: {
                                            if (!window.config.date) window.config.date = {}
                                            window.config.date.enabled = checked
                                            window.markDirty()
                                        }
                                    }
                                }

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Date Style"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                                    Item { Layout.fillWidth: true }
                                    Row {
                                        spacing: 8
                                        Rectangle {
                                            id: longDateBtn
                                            width: 84; height: 30; radius: 15
                                            readonly property bool isSelected: (window.config.date && window.config.date.format === "long")
                                            color: longDateBtn.isSelected ? Theme.accent : Theme.alpha(Theme.surface, 0.65)
                                            border.width: 1
                                            border.color: longDateBtn.isSelected ? Theme.accent : Theme.alpha(Theme.accent, 0.25)
                                            Text {
                                                anchors.centerIn: parent
                                                text: "Long Format"
                                                color: longDateBtn.isSelected ? Theme.on_primary : Theme.foreground
                                                font.family: "Outfit"
                                                font.pixelSize: 11
                                                font.weight: longDateBtn.isSelected ? Font.DemiBold : Font.Normal
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (!window.config.date) window.config.date = {}
                                                    window.config.date.format = "long"
                                                    window.markDirty()
                                                }
                                            }
                                        }
                                        Rectangle {
                                            id: compactDateBtn
                                            width: 84; height: 30; radius: 15
                                            readonly property bool isSelected: (window.config.date && window.config.date.format === "compact")
                                            color: compactDateBtn.isSelected ? Theme.accent : Theme.alpha(Theme.surface, 0.65)
                                            border.width: 1
                                            border.color: compactDateBtn.isSelected ? Theme.accent : Theme.alpha(Theme.accent, 0.25)
                                            Text {
                                                anchors.centerIn: parent
                                                text: "Compact"
                                                color: compactDateBtn.isSelected ? Theme.on_primary : Theme.foreground
                                                font.family: "Outfit"
                                                font.pixelSize: 11
                                                font.weight: compactDateBtn.isSelected ? Font.DemiBold : Font.Normal
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (!window.config.date) window.config.date = {}
                                                    window.config.date.format = "compact"
                                                    window.markDirty()
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // ----------------------------------------------------
                            // TAB 2: AVATAR & IDENTITY
                            // ----------------------------------------------------
                            Column {
                                width: parent.width
                                spacing: 14
                                visible: window.activeTab === 2

                                Text {
                                    text: "User Avatar & Animation Dynamics"
                                    color: Theme.foreground
                                    font.family: "Outfit"
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                }

                                // Profile Picture / Avatar Image Selector Card (XDG Desktop Portal)
                                Rectangle {
                                    width: parent.width
                                    height: avatarPickerRow.implicitHeight + 24
                                    radius: 14
                                    color: Theme.alpha(Theme.surface, 0.55)
                                    border.width: 1
                                    border.color: Theme.alpha(Theme.accent, 0.35)

                                    RowLayout {
                                        id: avatarPickerRow
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 14

                                        // Circular Avatar Thumbnail with Mask
                                        Item {
                                            Layout.preferredWidth: 50
                                            Layout.preferredHeight: 50

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: width / 2
                                                color: Theme.alpha(Theme.accent, 0.20)
                                                border.width: 1.5
                                                border.color: Theme.accent

                                                Item {
                                                    id: pickerMask
                                                    anchors.fill: parent
                                                    layer.enabled: true
                                                    visible: false
                                                    Rectangle { anchors.fill: parent; radius: width / 2; color: "#ffffff" }
                                                }

                                                Image {
                                                    id: pickerAvatarImg
                                                    anchors.fill: parent
                                                    source: window.avatarPath
                                                    sourceSize: Qt.size(128, 128)
                                                    fillMode: Image.PreserveAspectCrop
                                                    visible: false
                                                }

                                                MultiEffect {
                                                    anchors.fill: parent
                                                    source: pickerAvatarImg
                                                    maskEnabled: true
                                                    maskSource: pickerMask
                                                    maskThresholdMin: 0.5
                                                    maskSpreadAtMin: 1.0
                                                }
                                            }
                                        }

                                        // Label & Description
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 3

                                            Text {
                                                text: "Profile Picture (XDG Portal)"
                                                color: Theme.foreground
                                                font.family: "Outfit"
                                                font.pixelSize: 13
                                                font.weight: Font.DemiBold
                                            }

                                            Text {
                                                text: pickAvatarProc.running
                                                    ? "Waiting for file selection in desktop portal..."
                                                    : "Select image via desktop file chooser (PNG, JPG, WEBP)"
                                                color: pickAvatarProc.running ? Theme.accent : Theme.alpha(Theme.foreground, 0.65)
                                                font.family: "Outfit"
                                                font.pixelSize: 11
                                            }
                                        }

                                        // Browse Avatar Button
                                        Rectangle {
                                            Layout.preferredHeight: 34
                                            Layout.preferredWidth: browseRow.implicitWidth + 24
                                            radius: 17
                                            color: browseMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.accent, 0.25)
                                            border.width: 1
                                            border.color: Theme.accent
                                            scale: browseMouse.pressed ? 0.94 : (browseMouse.containsMouse ? 1.03 : 1.0)
                                            Behavior on scale { NumberAnimation { duration: 120 } }
                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            Row {
                                                id: browseRow
                                                anchors.centerIn: parent
                                                spacing: 6

                                                Image {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: 14; height: 14
                                                    source: window.imageSvg
                                                    sourceSize: Qt.size(28, 28)
                                                }

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: "Select Image"
                                                    color: browseMouse.containsMouse ? Theme.on_primary : Theme.foreground
                                                    font.family: "Outfit"
                                                    font.pixelSize: 12
                                                    font.weight: Font.DemiBold
                                                }
                                            }

                                            MouseArea {
                                                id: browseMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (!pickAvatarProc.running) {
                                                        pickAvatarProc.running = true
                                                    }
                                                }
                                            }
                                        }

                                        // Reset Button
                                        Rectangle {
                                            Layout.preferredHeight: 34
                                            Layout.preferredWidth: 34
                                            radius: 17
                                            color: resetAvMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.45)
                                            border.width: 1
                                            border.color: Theme.alpha(Theme.foreground, 0.25)
                                            scale: resetAvMouse.pressed ? 0.93 : 1.0
                                            Behavior on scale { NumberAnimation { duration: 100 } }

                                            Image {
                                                anchors.centerIn: parent
                                                width: 14; height: 14
                                                source: window.refreshSvg
                                                sourceSize: Qt.size(28, 28)
                                                opacity: 0.85
                                            }

                                            MouseArea {
                                                id: resetAvMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (!resetAvatarProc.running) {
                                                        resetAvatarProc.running = true
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Show Avatar Module"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                                    Item { Layout.fillWidth: true }
                                    CapsuleSwitch {
                                        checked: window.config.avatar ? window.config.avatar.enabled : true
                                        onToggled: {
                                            if (!window.config.avatar) window.config.avatar = {}
                                            window.config.avatar.enabled = checked
                                            window.markDirty()
                                        }
                                    }
                                }

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Continuous Breathing Zoom (Sinusoidal)"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                                    Item { Layout.fillWidth: true }
                                    CapsuleSwitch {
                                        checked: window.config.avatar ? window.config.avatar.breathing_enabled : true
                                        onToggled: {
                                            if (!window.config.avatar) window.config.avatar = {}
                                            window.config.avatar.breathing_enabled = checked
                                            window.markDirty()
                                        }
                                    }
                                }

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Dual Orbiting Celestial Satellites"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                                    Item { Layout.fillWidth: true }
                                    CapsuleSwitch {
                                        checked: window.config.avatar ? window.config.avatar.orbit_satellites_enabled : true
                                        onToggled: {
                                            if (!window.config.avatar) window.config.avatar = {}
                                            window.config.avatar.orbit_satellites_enabled = checked
                                            window.markDirty()
                                        }
                                    }
                                }

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Ambient Halo Glow Bloom"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                                    Item { Layout.fillWidth: true }
                                    CapsuleSwitch {
                                        checked: window.config.avatar ? window.config.avatar.glow_enabled : true
                                        onToggled: {
                                            if (!window.config.avatar) window.config.avatar = {}
                                            window.config.avatar.glow_enabled = checked
                                            window.markDirty()
                                        }
                                    }
                                }

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Show Username Label"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                                    Item { Layout.fillWidth: true }
                                    CapsuleSwitch {
                                        checked: window.config.avatar ? window.config.avatar.show_username : true
                                        onToggled: {
                                            if (!window.config.avatar) window.config.avatar = {}
                                            window.config.avatar.show_username = checked
                                            window.markDirty()
                                        }
                                    }
                                }

                                RowLayout {
                                    width: parent.width
                                    Text { text: "Show Lock Status Tag (Locked / Verifying)"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                                    Item { Layout.fillWidth: true }
                                    CapsuleSwitch {
                                        checked: window.config.avatar ? window.config.avatar.show_status : true
                                        onToggled: {
                                            if (!window.config.avatar) window.config.avatar = {}
                                            window.config.avatar.show_status = checked
                                            window.markDirty()
                                        }
                                    }
                                }

                                // Avatar Size Slider
                                Column {
                                    width: parent.width
                                    spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Avatar Diameter:"; color: Theme.alpha(Theme.foreground, 0.85); font.family: "Outfit"; font.pixelSize: 13 }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: Math.round(avatarSizeSlider.value) + " px"
                                            color: Theme.accent
                                            font.family: "Outfit"
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                    ModernSlider {
                                        id: avatarSizeSlider
                                        width: parent.width
                                        from: 80
                                        to: 140
                                        stepSize: 4
                                        value: window.config.avatar ? window.config.avatar.size : 116
                                        onMoved: {
                                            if (!window.config.avatar) window.config.avatar = {}
                                            window.config.avatar.size = Math.round(value)
                                            window.markDirty()
                                        }
                                    }
                                }

                                // Re-center Avatar Quick Action
                                Rectangle {
                                    width: parent.width
                                    height: 38
                                    radius: 12
                                    color: centerAvMouse.containsMouse ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.60)
                                    border.width: 1
                                    border.color: Theme.alpha(Theme.accent, 0.40)

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 8

                                        Image {
                                            Layout.preferredWidth: 16
                                            Layout.preferredHeight: 16
                                            source: window.refreshSvg
                                            sourceSize: Qt.size(24, 24)
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: "Re-center Avatar & Unlock Capsule to Center"
                                            color: Theme.foreground
                                            font.family: "Outfit"
                                            font.pixelSize: 12
                                            font.weight: Font.Medium
                                        }

                                        Text {
                                            text: "Reset to (50%, 52%)"
                                            color: Theme.accent
                                            font.family: "Outfit"
                                            font.pixelSize: 10
                                        }
                                    }

                                    MouseArea {
                                        id: centerAvMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            window.updateWidgetPosition("avatar", 0.50, 0.52, "center")
                                        }
                                    }
                                }
                            }

                            // ----------------------------------------------------
                            // TAB 3: WIDGETS & ADD-ONS (EXPAND LOCKSCREEN)
                            // ----------------------------------------------------
                            Column {
                                width: parent.width
                                spacing: 14
                                visible: window.activeTab === 3

                                Text {
                                    text: "Optional Modules & Lockscreen Add-ons"
                                    color: Theme.foreground
                                    font.family: "Outfit"
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                }

                                // Weather Widget
                                RowLayout {
                                    width: parent.width
                                    Column {
                                        spacing: 2
                                        Row {
                                            spacing: 8
                                            Image {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 15; height: 15
                                                source: window.cloudSunSvg
                                                sourceSize: Qt.size(30, 30)
                                            }
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Weather Forecast Capsule"
                                                color: Theme.foreground
                                                font.family: "Outfit"
                                                font.pixelSize: 13
                                                font.weight: Font.Medium
                                            }
                                        }
                                        Text { text: "Displays live temperature, condition, and location (draggable on canvas)"; color: Theme.alpha(Theme.foreground, 0.65); font.family: "Outfit"; font.pixelSize: 11 }
                                    }
                                    Item { Layout.fillWidth: true }
                                    CapsuleSwitch {
                                        checked: window.config.modules ? window.config.modules.weather_widget : true
                                        onToggled: {
                                            if (!window.config.modules) window.config.modules = {}
                                            window.config.modules.weather_widget = checked
                                            window.markDirty()
                                        }
                                    }
                                }

                                // Weather city & country input with quick suggestions
                                Column {
                                    width: parent.width
                                    spacing: 8
                                    visible: window.config.modules && window.config.modules.weather_widget

                                    RowLayout {
                                        width: parent.width
                                        spacing: 12

                                        // City Field
                                        Column {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            Text { text: "City / Town:"; color: Theme.alpha(Theme.foreground, 0.85); font.family: "Outfit"; font.pixelSize: 12 }

                                            Rectangle {
                                                width: parent.width
                                                height: 40
                                                radius: 10
                                                color: Theme.alpha(Theme.surface, 0.65)
                                                border.width: 1
                                                border.color: weatherCityInput.activeFocus ? Theme.accent : Theme.alpha(Theme.accent, 0.35)

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 12
                                                    anchors.rightMargin: 8

                                                    TextField {
                                                        id: weatherCityInput
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        verticalAlignment: TextInput.AlignVCenter
                                                        color: Theme.foreground
                                                        font.family: "Outfit"
                                                        font.pixelSize: 13
                                                        text: window.liveWeatherCity
                                                        placeholderText: "City (e.g. London, Tokyo)..."
                                                        placeholderTextColor: Theme.alpha(Theme.foreground, 0.40)
                                                        background: null
                                                        selectByMouse: true

                                                        onTextEdited: {
                                                            window.liveWeatherCity = text
                                                            if (!window.config.modules) window.config.modules = {}
                                                            window.config.modules.weather_city = text
                                                            window.isDirty = true
                                                        }
                                                        onEditingFinished: {
                                                            if (!window.config.modules) window.config.modules = {}
                                                            window.config.modules.weather_city = text
                                                            window.markDirty()
                                                        }
                                                    }

                                                    // Clear Button
                                                    Rectangle {
                                                        Layout.preferredWidth: 24
                                                        Layout.preferredHeight: 24
                                                        radius: 12
                                                        color: Theme.alpha(Theme.surface, 0.50)
                                                        visible: weatherCityInput.text.length > 0

                                                        Image {
                                                            anchors.centerIn: parent
                                                            width: 10; height: 10
                                                            source: window.closeSvg
                                                            sourceSize: Qt.size(20, 20)
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                weatherCityInput.text = ""
                                                                window.liveWeatherCity = ""
                                                                if (!window.config.modules) window.config.modules = {}
                                                                window.config.modules.weather_city = ""
                                                                window.isDirty = true
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        // Country Field
                                        Column {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            Text { text: "Country:"; color: Theme.alpha(Theme.foreground, 0.85); font.family: "Outfit"; font.pixelSize: 12 }

                                            Rectangle {
                                                width: parent.width
                                                height: 40
                                                radius: 10
                                                color: Theme.alpha(Theme.surface, 0.65)
                                                border.width: 1
                                                border.color: weatherCountryInput.activeFocus ? Theme.accent : Theme.alpha(Theme.accent, 0.35)

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 12
                                                    anchors.rightMargin: 8

                                                    TextField {
                                                        id: weatherCountryInput
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        verticalAlignment: TextInput.AlignVCenter
                                                        color: Theme.foreground
                                                        font.family: "Outfit"
                                                        font.pixelSize: 13
                                                        text: window.liveWeatherCountry
                                                        placeholderText: "Country (e.g. United Kingdom, Japan)..."
                                                        placeholderTextColor: Theme.alpha(Theme.foreground, 0.40)
                                                        background: null
                                                        selectByMouse: true

                                                        onTextEdited: {
                                                            window.liveWeatherCountry = text
                                                            if (!window.config.modules) window.config.modules = {}
                                                            window.config.modules.weather_country = text
                                                            window.isDirty = true
                                                        }
                                                        onEditingFinished: {
                                                            if (!window.config.modules) window.config.modules = {}
                                                            window.config.modules.weather_country = text
                                                            window.markDirty()
                                                        }
                                                    }

                                                    // Clear Button
                                                    Rectangle {
                                                        Layout.preferredWidth: 24
                                                        Layout.preferredHeight: 24
                                                        radius: 12
                                                        color: Theme.alpha(Theme.surface, 0.50)
                                                        visible: weatherCountryInput.text.length > 0

                                                        Image {
                                                            anchors.centerIn: parent
                                                            width: 10; height: 10
                                                            source: window.closeSvg
                                                            sourceSize: Qt.size(20, 20)
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                weatherCountryInput.text = ""
                                                                window.liveWeatherCountry = ""
                                                                if (!window.config.modules) window.config.modules = {}
                                                                window.config.modules.weather_country = ""
                                                                window.isDirty = true
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Quick city suggestion pills
                                    Row {
                                        spacing: 6
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "Quick set:"
                                            color: Theme.alpha(Theme.foreground, 0.55)
                                            font.family: "Outfit"
                                            font.pixelSize: 11
                                        }
                                        Repeater {
                                            model: [
                                                { label: "London, UK", city: "London", country: "United Kingdom" },
                                                { label: "Tokyo, JP", city: "Tokyo", country: "Japan" },
                                                { label: "New York, US", city: "New York", country: "USA" },
                                                { label: "Paris, FR", city: "Paris", country: "France" },
                                                { label: "Berlin, DE", city: "Berlin", country: "Germany" },
                                                { label: "Sydney, AU", city: "Sydney", country: "Australia" }
                                            ]
                                            Rectangle {
                                                height: 24
                                                width: cityPillText.implicitWidth + 14
                                                radius: 12
                                                readonly property bool isSelected: window.liveWeatherCity === modelData.city && window.liveWeatherCountry === modelData.country
                                                color: isSelected ? Theme.accent : Theme.alpha(Theme.surface, 0.60)
                                                border.width: 1
                                                border.color: isSelected ? Theme.accent : Theme.alpha(Theme.accent, 0.25)

                                                Text {
                                                    id: cityPillText
                                                    anchors.centerIn: parent
                                                    text: modelData.label
                                                    color: parent.isSelected ? Theme.on_primary : Theme.foreground
                                                    font.family: "Outfit"
                                                    font.pixelSize: 10
                                                    font.weight: parent.isSelected ? Font.DemiBold : Font.Normal
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        weatherCityInput.text = modelData.city
                                                        weatherCountryInput.text = modelData.country
                                                        window.liveWeatherCity = modelData.city
                                                        window.liveWeatherCountry = modelData.country
                                                        if (!window.config.modules) window.config.modules = {}
                                                        window.config.modules.weather_city = modelData.city
                                                        window.config.modules.weather_country = modelData.country
                                                        window.markDirty()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Theme.alpha(Theme.accent, 0.20) }

                                // System Stats Widget
                                RowLayout {
                                    width: parent.width
                                    Column {
                                        spacing: 2
                                        Row {
                                            spacing: 8
                                            Image {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 15; height: 15
                                                source: window.zapSvg
                                                sourceSize: Qt.size(30, 30)
                                            }
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "System Info & Uptime Badge"
                                                color: Theme.foreground
                                                font.family: "Outfit"
                                                font.pixelSize: 13
                                                font.weight: Font.Medium
                                            }
                                        }
                                        Text { text: "Compact badge showing system metrics (uptime, ram, cpu, disk, battery)"; color: Theme.alpha(Theme.foreground, 0.65); font.family: "Outfit"; font.pixelSize: 11 }
                                    }
                                    Item { Layout.fillWidth: true }
                                    CapsuleSwitch {
                                        checked: window.config.modules ? window.config.modules.system_stats : false
                                        onToggled: {
                                            if (!window.config.modules) window.config.modules = {}
                                            window.config.modules.system_stats = checked
                                            window.markDirty()
                                        }
                                    }
                                }

                                // System Stats Config Panel
                                Column {
                                    width: parent.width
                                    spacing: 12
                                    visible: window.config.modules && window.config.modules.system_stats

                                    Rectangle {
                                        width: parent.width
                                        height: statsSettingsCol.implicitHeight + 24
                                        radius: 12
                                        color: Theme.alpha(Theme.surface, 0.60)
                                        border.width: 1
                                        border.color: Theme.alpha(Theme.accent, 0.30)

                                        Column {
                                            id: statsSettingsCol
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            spacing: 12

                                            Text {
                                                text: "Included System Metrics"
                                                color: Theme.alpha(Theme.foreground, 0.85)
                                                font.family: "Outfit"
                                                font.pixelSize: 12
                                                font.weight: Font.DemiBold
                                            }

                                            // 5 Metric Toggles Grid
                                            Flow {
                                                width: parent.width
                                                spacing: 8

                                                Repeater {
                                                    model: [
                                                        { key: "show_uptime", label: "⏱ Uptime" },
                                                        { key: "show_ram", label: "🧠 RAM Memory" },
                                                        { key: "show_cpu", label: "⚡ CPU Load" },
                                                        { key: "show_disk", label: "💾 Disk Space" },
                                                        { key: "show_battery", label: "🔋 Battery" }
                                                    ]

                                                    Rectangle {
                                                        height: 30
                                                        width: metricText.implicitWidth + 24
                                                        radius: 15
                                                        readonly property bool isMetricActive: Boolean(window.config.stats && window.config.stats[modelData.key])
                                                        color: isMetricActive ? Theme.accent : Theme.alpha(Theme.surface, 0.70)
                                                        border.width: 1
                                                        border.color: isMetricActive ? Theme.accent : Theme.alpha(Theme.accent, 0.30)

                                                        Text {
                                                            id: metricText
                                                            anchors.centerIn: parent
                                                            text: modelData.label
                                                            color: parent.isMetricActive ? Theme.on_primary : Theme.foreground
                                                            font.family: "Outfit"
                                                            font.pixelSize: 11
                                                            font.weight: parent.isMetricActive ? Font.DemiBold : Font.Normal
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                if (!window.config.stats) window.config.stats = {}
                                                                window.config.stats[modelData.key] = !parent.isMetricActive
                                                                window.markDirty()
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            Rectangle { width: parent.width; height: 1; color: Theme.alpha(Theme.accent, 0.15) }

                                            // Display Units Selector
                                            RowLayout {
                                                width: parent.width
                                                Text { text: "Units Format (RAM / Usable Disk):"; color: Theme.alpha(Theme.foreground, 0.85); font.family: "Outfit"; font.pixelSize: 12 }
                                                Item { Layout.fillWidth: true }
                                                Row {
                                                    spacing: 6
                                                    Repeater {
                                                        model: [
                                                            { key: "percent", label: "Percent (%)" },
                                                            { key: "gb", label: "GB" },
                                                            { key: "mb", label: "MB" },
                                                            { key: "kb", label: "KB" },
                                                            { key: "detailed", label: "Detailed (Free / Total)" }
                                                        ]
                                                        Rectangle {
                                                            id: unitBtn
                                                            height: 28
                                                            width: unitBtnText.implicitWidth + 16
                                                            radius: 14
                                                            readonly property bool isSelected: Boolean(window.config.stats && (window.config.stats.unit_format === modelData.key || (modelData.key === "gb" && window.config.stats.unit_format === "bytes")))
                                                            color: isSelected ? Theme.accent : Theme.alpha(Theme.surface, 0.65)
                                                            border.width: 1
                                                            border.color: isSelected ? Theme.accent : Theme.alpha(Theme.accent, 0.25)

                                                            Text {
                                                                id: unitBtnText
                                                                anchors.centerIn: parent
                                                                text: modelData.label
                                                                color: unitBtn.isSelected ? Theme.on_primary : Theme.foreground
                                                                font.family: "Outfit"
                                                                font.pixelSize: 10
                                                                font.weight: unitBtn.isSelected ? Font.DemiBold : Font.Normal
                                                            }

                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                    if (!window.config.stats) window.config.stats = {}
                                                                    window.config.stats.unit_format = modelData.key
                                                                    window.markDirty()
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            // Separator Selector
                                            RowLayout {
                                                width: parent.width
                                                Text { text: "Metric Separator:"; color: Theme.alpha(Theme.foreground, 0.85); font.family: "Outfit"; font.pixelSize: 12 }
                                                Item { Layout.fillWidth: true }
                                                Row {
                                                    spacing: 6
                                                    Repeater {
                                                        model: ["•", "|", "/", "—"]
                                                        Rectangle {
                                                            id: sepBtn
                                                            height: 26
                                                            width: 32
                                                            radius: 13
                                                            readonly property bool isSelected: Boolean(window.config.stats && window.config.stats.separator === modelData)
                                                            color: isSelected ? Theme.accent : Theme.alpha(Theme.surface, 0.65)
                                                            border.width: 1
                                                            border.color: isSelected ? Theme.accent : Theme.alpha(Theme.accent, 0.25)

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: modelData
                                                                color: sepBtn.isSelected ? Theme.on_primary : Theme.foreground
                                                                font.family: "Outfit"
                                                                font.pixelSize: 12
                                                                font.weight: sepBtn.isSelected ? Font.Bold : Font.Normal
                                                            }

                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                    if (!window.config.stats) window.config.stats = {}
                                                                    window.config.stats.separator = modelData
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

                                Rectangle { width: parent.width; height: 1; color: Theme.alpha(Theme.accent, 0.20) }

                                // Media Player Widget
                                RowLayout {
                                    width: parent.width
                                    Column {
                                        spacing: 2
                                        Row {
                                            spacing: 8
                                            Image {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 15; height: 15
                                                source: window.musicSvg
                                                sourceSize: Qt.size(30, 30)
                                            }
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Media Player Card"
                                                color: Theme.foreground
                                                font.family: "Outfit"
                                                font.pixelSize: 13
                                                font.weight: Font.Medium
                                            }
                                        }
                                        Text { text: "Displays active media playback (auto-hides on lockscreen when nothing is playing)"; color: Theme.alpha(Theme.foreground, 0.65); font.family: "Outfit"; font.pixelSize: 11 }
                                    }
                                    Item { Layout.fillWidth: true }
                                    CapsuleSwitch {
                                        checked: window.config.modules ? window.config.modules.media_player : false
                                        onToggled: {
                                            if (!window.config.modules) window.config.modules = {}
                                            window.config.modules.media_player = checked
                                            window.markDirty()
                                        }
                                    }
                                }

                                Rectangle { width: parent.width; height: 1; color: Theme.alpha(Theme.accent, 0.20) }

                                // Custom Quote / Motto Widget
                                RowLayout {
                                    width: parent.width
                                    Column {
                                        spacing: 2
                                        Row {
                                            spacing: 8
                                            Image {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 15; height: 15
                                                source: window.quoteSvg
                                                sourceSize: Qt.size(30, 30)
                                            }
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Inspirational Quote / Motto Pill"
                                                color: Theme.foreground
                                                font.family: "Outfit"
                                                font.pixelSize: 13
                                                font.weight: Font.Medium
                                            }
                                        }
                                        Text { text: "Shows a customizable quote or status greeting"; color: Theme.alpha(Theme.foreground, 0.65); font.family: "Outfit"; font.pixelSize: 11 }
                                    }
                                    Item { Layout.fillWidth: true }
                                    CapsuleSwitch {
                                        checked: window.config.modules ? window.config.modules.custom_quote : false
                                        onToggled: {
                                            if (!window.config.modules) window.config.modules = {}
                                            window.config.modules.custom_quote = checked
                                            window.markDirty()
                                        }
                                    }
                                }

                                // Quote text input
                                Column {
                                    width: parent.width
                                    spacing: 6
                                    visible: window.config.modules && window.config.modules.custom_quote

                                    Text { text: "Custom Quote Text:"; color: Theme.alpha(Theme.foreground, 0.85); font.family: "Outfit"; font.pixelSize: 12 }

                                    Rectangle {
                                        width: parent.width
                                        height: 38
                                        radius: 10
                                        color: Theme.alpha(Theme.surface, 0.60)
                                        border.width: 1
                                        border.color: quoteInput.activeFocus ? Theme.accent : Theme.alpha(Theme.accent, 0.35)

                                        TextField {
                                            id: quoteInput
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12
                                            verticalAlignment: TextInput.AlignVCenter
                                            color: Theme.foreground
                                            font.family: "Outfit"
                                            font.pixelSize: 13
                                            text: window.liveQuoteText
                                            placeholderText: "Enter personal motto..."
                                            placeholderTextColor: Theme.alpha(Theme.foreground, 0.40)
                                            background: null
                                            selectByMouse: true

                                            onTextEdited: {
                                                window.liveQuoteText = text
                                                if (!window.config.modules) window.config.modules = {}
                                                window.config.modules.quote_text = text
                                                window.isDirty = true
                                            }
                                            onEditingFinished: {
                                                if (!window.config.modules) window.config.modules = {}
                                                window.config.modules.quote_text = text
                                                window.markDirty()
                                            }
                                        }
                                    }
                                }
                            }

                            // ----------------------------------------------------
                            // TAB 4: BACKDROP & OPTICS
                            // ----------------------------------------------------
                            Column {
                                width: parent.width
                                spacing: 14
                                visible: window.activeTab === 4

                                Text {
                                    text: "Wallpaper Optics & Glass Atmosphere"
                                    color: Theme.foreground
                                    font.family: "Outfit"
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                }

                                // Blur Slider
                                Column {
                                    width: parent.width
                                    spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Wallpaper Blur Strength:"; color: Theme.alpha(Theme.foreground, 0.85); font.family: "Outfit"; font.pixelSize: 13 }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: Math.round(backdropBlurSlider.value * 100) + " %"
                                            color: Theme.accent
                                            font.family: "Outfit"
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                    ModernSlider {
                                        id: backdropBlurSlider
                                        width: parent.width
                                        from: 0.1
                                        to: 1.0
                                        stepSize: 0.05
                                        value: window.config.backdrop ? window.config.backdrop.blur : 0.65
                                        onMoved: {
                                             if (!window.config.backdrop) window.config.backdrop = {}
                                             window.config.backdrop.blur = value
                                             window.markDirty()
                                        }
                                    }
                                }

                                // Vignette Slider
                                Column {
                                    width: parent.width
                                    spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Vignette Darkening:"; color: Theme.alpha(Theme.foreground, 0.85); font.family: "Outfit"; font.pixelSize: 13 }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: Math.round(backdropVignetteSlider.value * 100) + " %"
                                            color: Theme.accent
                                            font.family: "Outfit"
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                    ModernSlider {
                                        id: backdropVignetteSlider
                                        width: parent.width
                                        from: 0.2
                                        to: 0.85
                                        stepSize: 0.05
                                        value: window.config.backdrop ? window.config.backdrop.vignette : 0.65
                                        onMoved: {
                                             if (!window.config.backdrop) window.config.backdrop = {}
                                             window.config.backdrop.vignette = value
                                             window.markDirty()
                                        }
                                    }
                                }

                                // Wallpaper Dimming Slider
                                Column {
                                    width: parent.width
                                    spacing: 6
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "Wallpaper Dimming / Shade:"; color: Theme.alpha(Theme.foreground, 0.85); font.family: "Outfit"; font.pixelSize: 13 }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: Math.round(backdropDimmingSlider.value * 100) + " %"
                                            color: Theme.accent
                                            font.family: "Outfit"
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                    ModernSlider {
                                        id: backdropDimmingSlider
                                        width: parent.width
                                        from: 0.0
                                        to: 0.60
                                        stepSize: 0.05
                                        value: window.config.backdrop && window.config.backdrop.dimming !== undefined ? window.config.backdrop.dimming : 0.20
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
