import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "."

Item {
    id: weatherRoot
    anchors.fill: parent

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string windSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.7 7.7a2.5 2.5 0 1 1 1.8 4.3H2"/><path d="M9.6 4.6A2 2 0 1 1 11 8H2"/><path d="M12.6 19.4A2 2 0 1 0 14 16H2"/></svg>')
    readonly property string dropSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/></svg>')
    readonly property string gaugeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m12 14 4-4"/><path d="M3.34 19a10 10 0 1 1 17.32 0"/></svg>')
    readonly property string sunSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="4"/><path d="M12 2v2"/><path d="M12 20v2"/><path d="m4.93 4.93 1.41 1.41"/><path d="m17.66 17.66 1.41 1.41"/><path d="M2 12h2"/><path d="M20 12h2"/><path d="m6.34 17.66-1.41 1.41"/><path d="m19.07 4.93-1.41 1.41"/></svg>')
    readonly property string compassSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polygon points="16.24 7.76 14.12 14.12 7.76 16.24 9.88 9.88 16.24 7.76"/></svg>')
    readonly property string sunriseSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2v6"/><path d="m4.93 10.93 1.41 1.41"/><path d="M20 18h2"/><path d="m19.07 10.93-1.41 1.41"/><path d="M22 22H2"/><path d="m8 6 4-4 4 4"/><path d="M16 18a4 4 0 0 0-8 0"/></svg>')
    readonly property string sunsetSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 10V2"/><path d="m4.93 10.93 1.41 1.41"/><path d="M20 18h2"/><path d="m19.07 10.93-1.41 1.41"/><path d="M22 22H2"/><path d="m16 6-4 4-4-4"/><path d="M16 18a4 4 0 0 0-8 0"/></svg>')
    readonly property string eyeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>')
    readonly property string zapSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#fbbf24" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>')
    readonly property string snowSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#38bdf8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m10 4 2 2 2-2"/><path d="m10 20 2-2 2 2"/><path d="m4 14 2-2-2-2"/><path d="m20 14-2-2 2-2"/><path d="m7.05 7.05 2.12 2.12"/><path d="m14.83 14.83 2.12 2.12"/><path d="m16.95 7.05-2.12 2.12"/><path d="m9.17 14.83-2.12 2.12"/><path d="M12 2v20"/><path d="M2 12h20"/></svg>')
    readonly property string cloudSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"/></svg>')
    readonly property string rainSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 14.899A7 7 0 1 1 15.71 8h1.79a4.5 4.5 0 0 1 2.5 8.242"/><path d="M16 14v6"/><path d="M8 14v6"/><path d="M12 16v6"/></svg>')

    // ── Live Weather Data Model ──────────────────────────────────────────────
    property var weatherData: ({
        configured: false,
        city: "",
        country: "",
        location: "Location Not Set",
        text: "Please set your location",
        temp_C: "--",
        temp_F: "--",
        feels_like_C: "--",
        condition: "Awaiting location input",
        weather_category: "sunny",
        weather_code: "113",
        humidity: "--",
        wind_speed: "--",
        wind_dir: "--",
        pressure: "--",
        visibility: "--",
        uv_index: "--",
        sunrise: "06:00 AM",
        sunset: "06:00 PM",
        moon_phase: "New Moon",
        day_progress: 0.5,
        is_day: true
    })

    property bool isFetching: false
    property string simulatedCategoryOverride: ""
    property string activeAnimCategory: {
        if (simulatedCategoryOverride.length > 0) return simulatedCategoryOverride
        return (weatherData && weatherData.weather_category) ? weatherData.weather_category : "sunny"
    }

    // Process to query weather.py
    Process {
        id: weatherProc
        command: ["python3", window.homeDir + "/.hyprconf/hypr/scripts/py/weather.py", "--json"]
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(text.trim())
                        weatherRoot.weatherData = parsed
                        if (parsed.city !== undefined && parsed.city.length > 0) {
                            window.liveWeatherCity = parsed.city
                            if (window.config.modules) window.config.modules.weather_city = parsed.city
                        }
                        if (parsed.country !== undefined && parsed.country.length > 0) {
                            window.liveWeatherCountry = parsed.country
                            if (window.config.modules) window.config.modules.weather_country = parsed.country
                        }
                    } catch(e) {
                        console.log("[WeatherSection] Parse error:", e)
                    }
                }
            }
        }
        onRunningChanged: {
            if (!running) {
                weatherRoot.isFetching = false
            }
        }
    }

    Component.onCompleted: {
        weatherRoot.refreshWeather(false)
    }

    function refreshWeather(force) {
        weatherRoot.isFetching = true
        var args = ["python3", window.homeDir + "/.hyprconf/hypr/scripts/py/weather.py", "--json"]
        if (force) args.push("--force")
        if (cityInput.text.trim().length > 0) {
            args.push("--city", cityInput.text.trim())
        }
        if (countryInput.text.trim().length > 0) {
            args.push("--country", countryInput.text.trim())
        }
        weatherProc.command = args
        weatherProc.running = true
    }

    function applyLocation(c, co) {
        cityInput.text = c
        countryInput.text = co
        window.liveWeatherCity = c
        window.liveWeatherCountry = co
        if (!window.config.modules) window.config.modules = {}
        window.config.modules.weather_city = c
        window.config.modules.weather_country = co
        window.markDirty()

        weatherRoot.isFetching = true
        weatherProc.command = [
            "python3",
            window.homeDir + "/.hyprconf/hypr/scripts/py/weather.py",
            "--set-location", c, co,
            "--json"
        ]
        weatherProc.running = true
    }

    // ── Master Simulation Ticker (20s loop) ──────────────────────────────────
    property real animTick: 0
    NumberAnimation on animTick {
        from: 0
        to: 360
        duration: 20000
        loops: Animation.Infinite
        running: true
    }

    // ═════════════════════════════════════════════════════════════════════════
    // ── WINDOW GLASS PERSPECTIVE WEATHER SIMULATOR (PURE QML) ────────────────
    // ═════════════════════════════════════════════════════════════════════════
    Item {
        id: windowGlassViewport
        anchors.fill: parent
        clip: true

        // ─────────────────────────────────────────────────────────────────────
        // LAYER 1: OUTSIDE SKY & ATMOSPHERE (SEEN THROUGH THE WINDOW)
        // ─────────────────────────────────────────────────────────────────────
        Rectangle {
            id: outdoorSky
            anchors.fill: parent

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: {
                        var cat = weatherRoot.activeAnimCategory
                        if (cat === "rain" || cat === "thunder") return "#070b13"
                        if (cat === "snow") return "#0a1320"
                        if (cat === "sunny" || cat === "clear") {
                            return (weatherRoot.weatherData && !weatherRoot.weatherData.is_day) ? "#050810" : "#0d2038"
                        }
                        if (cat === "cloudy") return "#0b1018"
                        if (cat === "fog") return "#0e141d"
                        return Theme.background
                    }
                    Behavior on color { ColorAnimation { duration: 800 } }
                }
                GradientStop {
                    position: 0.60
                    color: {
                        var cat = weatherRoot.activeAnimCategory
                        if (cat === "rain" || cat === "thunder") return "#0e1724"
                        if (cat === "snow") return "#132135"
                        if (cat === "sunny" || cat === "clear") {
                            return (weatherRoot.weatherData && !weatherRoot.weatherData.is_day) ? "#0d1422" : "#173152"
                        }
                        if (cat === "cloudy") return "#131b26"
                        if (cat === "fog") return "#161e29"
                        return Theme.background
                    }
                    Behavior on color { ColorAnimation { duration: 800 } }
                }
                GradientStop {
                    position: 1.0
                    color: {
                        var cat = weatherRoot.activeAnimCategory
                        if (cat === "sunny" && weatherRoot.weatherData && weatherRoot.weatherData.is_day) return "#2c281e"
                        if (cat === "cloudy") return "#18202c"
                        return Theme.background
                    }
                    Behavior on color { ColorAnimation { duration: 800 } }
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────────
        // 1A. OUTDOOR SUNNY: Real Natural Sun in Clear Sky
        // ─────────────────────────────────────────────────────────────────────
        Item {
            id: outdoorSunView
            anchors.fill: parent
            visible: weatherRoot.activeAnimCategory === "sunny" || weatherRoot.activeAnimCategory === "clear"
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 600 } }

            readonly property real sunX: parent.width * 0.86
            readonly property real sunY: 90

            // Wide Sky Ambient Solar Glow
            Rectangle {
                x: outdoorSunView.sunX - width / 2
                y: outdoorSunView.sunY - height / 2
                width: 380; height: 380; radius: 190
                color: Qt.rgba(0.98, 0.74, 0.16, 0.06)

                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    running: outdoorSunView.visible
                    NumberAnimation { from: 0.95; to: 1.05; duration: 4500; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1.05; to: 0.95; duration: 4500; easing.type: Easing.InOutSine }
                }
            }

            // Warm Outer Corona
            Rectangle {
                x: outdoorSunView.sunX - width / 2
                y: outdoorSunView.sunY - height / 2
                width: 170; height: 170; radius: 85
                color: Qt.rgba(0.98, 0.80, 0.22, 0.16)

                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    running: outdoorSunView.visible
                    NumberAnimation { from: 1.04; to: 0.96; duration: 3200; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.96; to: 1.04; duration: 3200; easing.type: Easing.InOutSine }
                }
            }

            // Warm Incandescent Sun Disc
            Rectangle {
                x: outdoorSunView.sunX - width / 2
                y: outdoorSunView.sunY - height / 2
                width: 86; height: 86; radius: 43
                color: Qt.rgba(1.0, 0.94, 0.70, 0.45)
            }

            // Brilliant Pure White Core
            Rectangle {
                x: outdoorSunView.sunX - width / 2
                y: outdoorSunView.sunY - height / 2
                width: 48; height: 48; radius: 24
                color: "#ffffff"
            }

            // Natural Sunlight Beam Shining Through Window into the Room
            Rectangle {
                x: outdoorSunView.sunX - 160
                y: outdoorSunView.sunY - 20
                width: 520
                height: 700
                rotation: 38
                transformOrigin: Item.TopLeft
                opacity: 0.15

                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1.0, 0.92, 0.65, 0.45) }
                    GradientStop { position: 0.4; color: Qt.rgba(1.0, 0.85, 0.50, 0.15) }
                    GradientStop { position: 1.0; color: "transparent" }
                }

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: outdoorSunView.visible
                    NumberAnimation { from: 0.12; to: 0.22; duration: 4200; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.22; to: 0.12; duration: 4200; easing.type: Easing.InOutSine }
                }
            }

            // Dust Motes floating in the sunlight inside the room
            Repeater {
                model: 24
                Rectangle {
                    id: indoorMote
                    width: 2.0 + (index % 3) * 0.8
                    height: width; radius: width / 2
                    color: "#fffbeb"
                    opacity: 0.25 + (index % 5) * 0.12

                    property real originX: (index * (weatherRoot.width / 22) + 60) % weatherRoot.width
                    property real speed: 8200 + (index % 8) * 800

                    x: originX + Math.sin(weatherRoot.animTick * 0.03 + index) * 16

                    SequentialAnimation on y {
                        loops: Animation.Infinite
                        running: outdoorSunView.visible
                        NumberAnimation {
                            from: weatherRoot.height + 20
                            to: -30
                            duration: indoorMote.speed
                            easing.type: Easing.Linear
                        }
                    }
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────────
        // 1B. OUTDOOR CLOUDY: Dark Volumetric Rolling Clouds
        // ─────────────────────────────────────────────────────────────────────
        Item {
            id: outdoorCloudView
            anchors.fill: parent
            visible: weatherRoot.activeAnimCategory === "cloudy"
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 600 } }

            // Dark Rolling Cloud Layers Across the Sky
            Repeater {
                model: [
                    { yPos: 30, w: 480, h: 120, speed: 44000, op: 0.22, col: "#080c14" },
                    { yPos: 90, w: 560, h: 140, speed: 34000, op: 0.28, col: "#0c131e" },
                    { yPos: 150, w: 510, h: 130, speed: 38000, op: 0.20, col: "#090e16" },
                    { yPos: 220, w: 620, h: 150, speed: 28000, op: 0.25, col: "#0d1420" }
                ]

                Rectangle {
                    id: darkCloudBank
                    width: modelData.w
                    height: modelData.h
                    radius: height / 2
                    y: modelData.yPos
                    color: modelData.col
                    opacity: modelData.op

                    // Silver lining edge highlight
                    border.width: 1.0
                    border.color: Qt.rgba(0.65, 0.75, 0.88, 0.08)

                    SequentialAnimation on x {
                        loops: Animation.Infinite
                        running: outdoorCloudView.visible
                        NumberAnimation {
                            from: -darkCloudBank.width
                            to: weatherRoot.width + 60
                            duration: modelData.speed
                            easing.type: Easing.Linear
                        }
                    }
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────────
        // 1C. OUTDOOR RAIN / THUNDER: Distant Rain Falling Outside
        // ─────────────────────────────────────────────────────────────────────
        Item {
            id: outdoorRainView
            anchors.fill: parent
            visible: weatherRoot.activeAnimCategory === "rain" || weatherRoot.activeAnimCategory === "thunder"
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 600 } }

            // Distant Rain Streaks outside the window
            Repeater {
                model: 40
                Rectangle {
                    id: distantRain
                    width: 0.9
                    height: 18 + (index % 10) * 2
                    radius: 0.45
                    color: Qt.rgba(0.65, 0.78, 0.95, 0.16)
                    rotation: -14

                    property real startX: (index * (weatherRoot.width / 38)) % weatherRoot.width
                    property real dropDur: 550 + (index % 8) * 45

                    x: startX

                    SequentialAnimation on y {
                        loops: Animation.Infinite
                        running: outdoorRainView.visible
                        NumberAnimation {
                            from: -30
                            to: weatherRoot.height + 20
                            duration: distantRain.dropDur
                            easing.type: Easing.Linear
                        }
                    }
                }
            }

            // Natural Lightning Discharge Flash Outside
            Rectangle {
                anchors.fill: parent
                color: "#e2e8f8"
                visible: weatherRoot.activeAnimCategory === "thunder"
                opacity: 0.0

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: weatherRoot.activeAnimCategory === "thunder"
                    PauseAnimation { duration: 6800 }
                    NumberAnimation { to: 0.18; duration: 40 }
                    NumberAnimation { to: 0.04; duration: 50 }
                    NumberAnimation { to: 0.42; duration: 65 }
                    NumberAnimation { to: 0.10; duration: 80 }
                    NumberAnimation { to: 0.24; duration: 45 }
                    NumberAnimation { to: 0.0; duration: 260; easing.type: Easing.OutQuad }
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────────
        // 1D. OUTDOOR SNOW: Fluffy Snow Drifting Outside
        // ─────────────────────────────────────────────────────────────────────
        Item {
            id: outdoorSnowView
            anchors.fill: parent
            visible: weatherRoot.activeAnimCategory === "snow"
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 600 } }

            Repeater {
                model: 32
                Rectangle {
                    id: outdoorFlake
                    width: 3.5 + (index % 4)
                    height: width; radius: width / 2
                    color: "#ffffff"
                    opacity: 0.50 + (index % 4) * 0.10

                    property real originX: (index * (weatherRoot.width / 30) + 12) % weatherRoot.width
                    property real speed: 4200 + (index % 8) * 400

                    x: originX + Math.sin(weatherRoot.animTick * 0.05 + index) * 14

                    SequentialAnimation on y {
                        loops: Animation.Infinite
                        running: outdoorSnowView.visible
                        NumberAnimation {
                            from: -20
                            to: weatherRoot.height + 20
                            duration: outdoorFlake.speed
                            easing.type: Easing.Linear
                        }
                    }
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────────
        // 1E. OUTDOOR FOG: Heavy Ambient Misty Atmosphere
        // ─────────────────────────────────────────────────────────────────────
        Rectangle {
            anchors.fill: parent
            visible: weatherRoot.activeAnimCategory === "fog"
            opacity: visible ? 0.35 : 0.0
            Behavior on opacity { NumberAnimation { duration: 600 } }
            color: "#64748b"
        }

        // ═════════════════════════════════════════════════════════════════════
        // LAYER 2: THE WINDOW GLASS PANE (FOREGROUND SURFACE)
        // ═════════════════════════════════════════════════════════════════════
        Item {
            id: windowGlassSurface
            anchors.fill: parent

            // Subtle Architectural Window Frame Bevel Highlight (Outer border)
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.09)
            }

            // Window Glass Perimeter Dark Vignette (Simulates interior room shadow)
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.width: 18
                border.color: Qt.rgba(0, 0, 0, 0.18)
                radius: 12
            }

            // Subtle Diagonal Specular Glass Reflection Sheen
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 1.5
                height: 120
                rotation: -28
                opacity: (weatherRoot.activeAnimCategory === "sunny") ? 0.08 : 0.04

                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: "#ffffff" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // ─────────────────────────────────────────────────────────────────
            // 2A. REALISTIC RAIN DROPS ON GLASS (CLINGING & TRICKLING WATER)
            // ─────────────────────────────────────────────────────────────────
            Item {
                id: glassRainLayer
                anchors.fill: parent
                visible: weatherRoot.activeAnimCategory === "rain" || weatherRoot.activeAnimCategory === "thunder"
                opacity: visible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 500 } }

                // 48 Clinging Water Beads Resting on Glass (Realistic 3D Refraction)
                Repeater {
                    model: [
                        { xP: 0.06, yP: 0.12, s: 7 }, { xP: 0.14, yP: 0.28, s: 9 }, { xP: 0.22, yP: 0.08, s: 6 },
                        { xP: 0.28, yP: 0.42, s: 8 }, { xP: 0.35, yP: 0.18, s: 10 }, { xP: 0.42, yP: 0.65, s: 7 },
                        { xP: 0.49, yP: 0.24, s: 9 }, { xP: 0.56, yP: 0.78, s: 8 }, { xP: 0.63, yP: 0.15, s: 11 },
                        { xP: 0.70, yP: 0.52, s: 7 }, { xP: 0.77, yP: 0.33, s: 9 }, { xP: 0.84, yP: 0.70, s: 8 },
                        { xP: 0.91, yP: 0.18, s: 10 }, { xP: 0.96, yP: 0.45, s: 6 }, { xP: 0.08, yP: 0.60, s: 8 },
                        { xP: 0.18, yP: 0.82, s: 7 }, { xP: 0.26, yP: 0.72, s: 9 }, { xP: 0.38, yP: 0.88, s: 8 },
                        { xP: 0.52, yP: 0.48, s: 10 }, { xP: 0.66, yP: 0.85, s: 7 }, { xP: 0.74, yP: 0.12, s: 8 },
                        { xP: 0.82, yP: 0.58, s: 9 }, { xP: 0.88, yP: 0.82, s: 7 }, { xP: 0.04, yP: 0.38, s: 8 },
                        { xP: 0.12, yP: 0.48, s: 6 }, { xP: 0.32, yP: 0.30, s: 7 }, { xP: 0.46, yP: 0.10, s: 8 },
                        { xP: 0.58, yP: 0.36, s: 9 }, { xP: 0.68, yP: 0.70, s: 6 }, { xP: 0.79, yP: 0.88, s: 8 },
                        { xP: 0.93, yP: 0.62, s: 9 }, { xP: 0.16, yP: 0.70, s: 7 }, { xP: 0.24, yP: 0.55, s: 8 },
                        { xP: 0.36, yP: 0.76, s: 6 }, { xP: 0.44, yP: 0.84, s: 9 }, { xP: 0.62, yP: 0.42, s: 7 },
                        { xP: 0.72, yP: 0.26, s: 8 }, { xP: 0.86, yP: 0.38, s: 10 }, { xP: 0.95, yP: 0.78, s: 7 }
                    ]

                    Item {
                        x: modelData.xP * weatherRoot.width
                        y: modelData.yP * weatherRoot.height
                        width: modelData.s
                        height: modelData.s * 1.15

                        // Translucent water bead body
                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: Qt.rgba(1.0, 1.0, 1.0, 0.18)
                            border.width: 0.8
                            border.color: Qt.rgba(0, 0, 0, 0.32)
                        }

                        // Upper-left specular glint highlight (Light hitting curved water bead)
                        Rectangle {
                            x: parent.width * 0.22
                            y: parent.height * 0.18
                            width: Math.max(1.5, parent.width * 0.28)
                            height: width
                            radius: width / 2
                            color: "#ffffff"
                            opacity: 0.95
                        }

                        // Lower-right meniscus dark shadow curve
                        Rectangle {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 1
                            width: parent.width * 0.50
                            height: parent.height * 0.35
                            radius: width / 2
                            color: Qt.rgba(0, 0, 0, 0.42)
                        }
                    }
                }

                // 8 Trickling Water Droplets Running Down the Glass Pane with Gravity
                Repeater {
                    model: [
                        { xP: 0.11, dur: 4200, delay: 0, s: 8 },
                        { xP: 0.23, dur: 5100, delay: 1400, s: 9 },
                        { xP: 0.37, dur: 4600, delay: 600, s: 10 },
                        { xP: 0.53, dur: 5800, delay: 2200, s: 8 },
                        { xP: 0.67, dur: 4800, delay: 1100, s: 11 },
                        { xP: 0.78, dur: 5400, delay: 1800, s: 9 },
                        { xP: 0.87, dur: 4300, delay: 300, s: 8 },
                        { xP: 0.94, dur: 5200, delay: 2600, s: 10 }
                    ]

                    Item {
                        id: trickleBead
                        x: modelData.xP * weatherRoot.width
                        width: modelData.s
                        height: modelData.s * 1.3

                        // Trailing vertical wet streak left behind on the glass
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.top
                            width: 1.4
                            height: 60
                            color: Qt.rgba(1.0, 1.0, 1.0, 0.20)

                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 1.0; color: Qt.rgba(1.0, 1.0, 1.0, 0.22) }
                            }
                        }

                        // Water drop body
                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: Qt.rgba(1.0, 1.0, 1.0, 0.22)
                            border.width: 0.8
                            border.color: Qt.rgba(0, 0, 0, 0.35)
                        }

                        // Specular glint
                        Rectangle {
                            x: parent.width * 0.22
                            y: parent.height * 0.16
                            width: parent.width * 0.32
                            height: width; radius: width / 2
                            color: "#ffffff"
                        }

                        // Gravity trickling motion down the glass surface
                        SequentialAnimation on y {
                            loops: Animation.Infinite
                            running: glassRainLayer.visible
                            PauseAnimation { duration: modelData.delay }
                            // Step 1: trickle down
                            NumberAnimation { from: -40; to: weatherRoot.height * 0.25; duration: modelData.dur * 0.25; easing.type: Easing.InQuad }
                            // Pause momentarily (surface tension)
                            PauseAnimation { duration: 400 }
                            // Step 2: gather mass & run down faster
                            NumberAnimation { to: weatherRoot.height * 0.60; duration: modelData.dur * 0.35; easing.type: Easing.InOutQuad }
                            PauseAnimation { duration: 250 }
                            // Step 3: rush to the bottom frame
                            NumberAnimation { to: weatherRoot.height + 40; duration: modelData.dur * 0.40; easing.type: Easing.InQuad }
                            PauseAnimation { duration: 800 }
                        }
                    }
                }
            }

            // ─────────────────────────────────────────────────────────────────
            // 2B. REALISTIC SNOW & FROST HAZING ON GLASS
            // ─────────────────────────────────────────────────────────────────
            Item {
                id: glassSnowLayer
                anchors.fill: parent
                visible: weatherRoot.activeAnimCategory === "snow"
                opacity: visible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 600 } }

                // Frost Condensation Hazing over the Window Glass
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0.80, 0.90, 1.0, 0.12)
                }

                // Frost Vignette in the 4 Corners of the Window Frame
                Rectangle {
                    anchors.left: parent.left; anchors.top: parent.top
                    width: 200; height: 160
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Qt.rgba(0.85, 0.93, 1.0, 0.22) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
                Rectangle {
                    anchors.right: parent.right; anchors.top: parent.top
                    width: 200; height: 160
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: Qt.rgba(0.85, 0.93, 1.0, 0.22) }
                    }
                }
                Rectangle {
                    anchors.left: parent.left; anchors.bottom: parent.bottom
                    width: 220; height: 140
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: Qt.rgba(0.85, 0.93, 1.0, 0.25) }
                    }
                }
                Rectangle {
                    anchors.right: parent.right; anchors.bottom: parent.bottom
                    width: 220; height: 140
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: Qt.rgba(0.85, 0.93, 1.0, 0.25) }
                    }
                }

                // Soft Snowflakes Sticking and Slowly Melting on the Cold Glass
                Repeater {
                    model: 16
                    Rectangle {
                        id: stuckFlake
                        x: (index * (weatherRoot.width / 15) + 30) % (weatherRoot.width - 50)
                        width: 8 + (index % 4) * 3
                        height: width
                        radius: width / 2
                        color: "#ffffff"

                        property real baseFadeDur: 4200 + (index % 5) * 600

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: glassSnowLayer.visible
                            PauseAnimation { duration: index * 450 }
                            NumberAnimation { from: 0.0; to: 0.75; duration: 400 }
                            PauseAnimation { duration: 1800 }
                            // Melting on glass
                            NumberAnimation { from: 0.75; to: 0.0; duration: stuckFlake.baseFadeDur * 0.4 }
                            PauseAnimation { duration: 1200 }
                        }

                        SequentialAnimation on y {
                            loops: Animation.Infinite
                            running: glassSnowLayer.visible
                            PauseAnimation { duration: index * 450 }
                            NumberAnimation {
                                from: 40 + (index * 42) % (weatherRoot.height - 180)
                                to: 40 + (index * 42) % (weatherRoot.height - 180) + 12
                                duration: stuckFlake.baseFadeDur
                                easing.type: Easing.InQuad
                            }
                        }
                    }
                }
            }

            // ─────────────────────────────────────────────────────────────────
            // 2C. REALISTIC FOG / STEAM CONDENSATION ON GLASS
            // ─────────────────────────────────────────────────────────────────
            Item {
                id: glassFogLayer
                anchors.fill: parent
                visible: weatherRoot.activeAnimCategory === "fog"
                opacity: visible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 600 } }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0.72, 0.78, 0.88, 0.28)
                }

                // Breathing condensation vapor wave
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.12)

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: glassFogLayer.visible
                        NumberAnimation { from: 0.08; to: 0.18; duration: 4800; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 0.18; to: 0.08; duration: 4800; easing.type: Easing.InOutSine }
                    }
                }
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    // ── MAIN CONTENT SCROLL AREA (FLICKABLE + VERTICAL SCROLLBAR) ────────────
    // ═════════════════════════════════════════════════════════════════════════
    Flickable {
        id: flickableArea
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentCol.implicitHeight + 80
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            anchors.right: parent.right
            anchors.rightMargin: 4
            policy: ScrollBar.AsNeeded
        }

        WheelHandler {
            onWheel: function(event) {
                flickableArea.contentY = Math.max(0, Math.min(flickableArea.contentHeight - flickableArea.height, flickableArea.contentY - event.angleDelta.y))
            }
        }

        Column {
            id: contentCol
            width: Math.min(parent.width - 48, 920)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 20
            spacing: 16

            // ─────────────────────────────────────────────────────────────────
            // CARD 1: LOCATION SETUP, TELEMETRY FETCH & SIMULATION CONTROLS
            // ─────────────────────────────────────────────────────────────────
            Rectangle {
                width: parent.width
                implicitHeight: card1Col.implicitHeight + 36
                height: implicitHeight
                radius: 16
                color: Theme.alpha(Theme.surface, 0.68)
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.24)

                Column {
                    id: card1Col
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 18
                    spacing: 14

                    // Header Row: Title, Subtitle, and Fetch Button
                    Row {
                        width: parent.width
                        spacing: 12

                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24
                            height: 24
                            source: weatherRoot.sunSvg
                            sourceSize: Qt.size(48, 48)
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 24 - 12 - 150 - 12
                            spacing: 2

                            Text {
                                text: "Weather & Atmospheric Telemetry"
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "View live weather streaming through architectural window glass with realistic physics"
                                color: Theme.alpha(Theme.foreground, 0.60)
                                font.family: "Outfit"
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        // Fetch / Refresh Button
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 140
                            height: 36
                            radius: 18
                            color: Theme.accent
                            opacity: weatherRoot.isFetching ? 0.75 : (fetchMouse.containsMouse ? 0.90 : 1.0)
                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 8

                                Image {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 14
                                    height: 14
                                    source: window.refreshSvg
                                    sourceSize: Qt.size(28, 28)

                                    NumberAnimation on rotation {
                                        running: weatherRoot.isFetching
                                        from: 0; to: 360
                                        duration: 900
                                        loops: Animation.Infinite
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: weatherRoot.isFetching ? "Fetching..." : "Fetch Weather"
                                    color: Theme.on_primary
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                }
                            }

                            MouseArea {
                                id: fetchMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: weatherRoot.refreshWeather(true)
                            }
                        }
                    }

                    // Divider Line
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.alpha(Theme.foreground, 0.08)
                    }

                    // Location Input Fields (Two Columns Side-by-Side)
                    Row {
                        width: parent.width
                        spacing: 14

                        // City Input Box
                        Column {
                            width: (parent.width - 14) / 2
                            spacing: 4

                            Text {
                                text: "City / Town:"
                                color: Theme.alpha(Theme.foreground, 0.85)
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }

                            Rectangle {
                                width: parent.width
                                height: 38
                                radius: 10
                                color: Theme.alpha(Theme.background, 0.65)
                                border.width: 1
                                border.color: cityInput.activeFocus ? Theme.accent : Theme.alpha(Theme.accent, 0.28)

                                Item {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 8

                                    TextField {
                                        id: cityInput
                                        anchors.fill: parent
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 12
                                        text: window.liveWeatherCity
                                        placeholderText: "Enter City (e.g. London, Tokyo)..."
                                        placeholderTextColor: Theme.alpha(Theme.foreground, 0.38)
                                        background: null
                                        selectByMouse: true
                                        onAccepted: weatherRoot.refreshWeather(true)
                                    }

                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 20
                                        height: 20
                                        radius: 10
                                        color: Theme.alpha(Theme.surface, 0.60)
                                        visible: cityInput.text.length > 0

                                        Image {
                                            anchors.centerIn: parent
                                            width: 8; height: 8
                                            source: window.closeSvg
                                            sourceSize: Qt.size(16, 16)
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: cityInput.text = ""
                                        }
                                    }
                                }
                            }
                        }

                        // Country Input Box
                        Column {
                            width: (parent.width - 14) / 2
                            spacing: 4

                            Text {
                                text: "Country:"
                                color: Theme.alpha(Theme.foreground, 0.85)
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }

                            Rectangle {
                                width: parent.width
                                height: 38
                                radius: 10
                                color: Theme.alpha(Theme.background, 0.65)
                                border.width: 1
                                border.color: countryInput.activeFocus ? Theme.accent : Theme.alpha(Theme.accent, 0.28)

                                Item {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 8

                                    TextField {
                                        id: countryInput
                                        anchors.fill: parent
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 12
                                        text: window.liveWeatherCountry
                                        placeholderText: "Enter Country (e.g. United Kingdom, Japan)..."
                                        placeholderTextColor: Theme.alpha(Theme.foreground, 0.38)
                                        background: null
                                        selectByMouse: true
                                        onAccepted: weatherRoot.refreshWeather(true)
                                    }

                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 20
                                        height: 20
                                        radius: 10
                                        color: Theme.alpha(Theme.surface, 0.60)
                                        visible: countryInput.text.length > 0

                                        Image {
                                            anchors.centerIn: parent
                                            width: 8; height: 8
                                            source: window.closeSvg
                                            sourceSize: Qt.size(16, 16)
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: countryInput.text = ""
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Row 1: Quick City Presets
                    Row {
                        spacing: 8
                        width: parent.width

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Quick Cities:"
                            color: Theme.alpha(Theme.foreground, 0.55)
                            font.family: "Outfit"
                            font.pixelSize: 11
                        }

                        Repeater {
                            model: [
                                { label: "London", city: "London", country: "United Kingdom" },
                                { label: "Tokyo", city: "Tokyo", country: "Japan" },
                                { label: "New York", city: "New York", country: "USA" },
                                { label: "Paris", city: "Paris", country: "France" },
                                { label: "Oslo", city: "Oslo", country: "Norway" }
                            ]

                            Rectangle {
                                height: 26
                                width: cityPillTxt.implicitWidth + 18
                                radius: 13
                                readonly property bool isSelected: cityInput.text === modelData.city
                                color: isSelected ? Theme.alpha(Theme.accent, 0.35) : Theme.alpha(Theme.surface, 0.65)
                                border.width: 1
                                border.color: isSelected ? Theme.accent : Theme.alpha(Theme.accent, 0.22)

                                Text {
                                    id: cityPillTxt
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: parent.isSelected ? Theme.accent : Theme.foreground
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                    font.weight: parent.isSelected ? Font.DemiBold : Font.Normal
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        weatherRoot.simulatedCategoryOverride = ""
                                        weatherRoot.applyLocation(modelData.city, modelData.country)
                                    }
                                }
                            }
                        }
                    }

                    // Row 2: Atmospheric Condition Simulator & Effects Test
                    Row {
                        spacing: 8
                        width: parent.width

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Window Glass View:"
                            color: Theme.alpha(Theme.foreground, 0.55)
                            font.family: "Outfit"
                            font.pixelSize: 11
                        }

                        Repeater {
                            model: [
                                { label: "⚡ Auto (Live)", cat: "" },
                                { label: "☀️ Clear Sun", cat: "sunny" },
                                { label: "🌧️ Rain on Glass", cat: "rain" },
                                { label: "⛈️ Thunderstorm", cat: "thunder" },
                                { label: "❄️ Snow & Frost", cat: "snow" },
                                { label: "☁️ Dark Clouds", cat: "cloudy" },
                                { label: "🌫️ Glass Fog", cat: "fog" }
                            ]

                            Rectangle {
                                height: 26
                                width: simPillTxt.implicitWidth + 18
                                radius: 13
                                readonly property bool isSelected: {
                                    if (modelData.cat === "") return weatherRoot.simulatedCategoryOverride === ""
                                    return weatherRoot.activeAnimCategory === modelData.cat
                                }
                                color: isSelected ? Theme.accent : Theme.alpha(Theme.surface, 0.50)
                                border.width: 1
                                border.color: isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)

                                Text {
                                    id: simPillTxt
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
                                        weatherRoot.simulatedCategoryOverride = modelData.cat
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ─────────────────────────────────────────────────────────────────
            // CARD 2: HERO LIVE WEATHER OVERVIEW (APPLE WEATHER OBSIDIAN STYLE)
            // ─────────────────────────────────────────────────────────────────
            Rectangle {
                width: parent.width
                implicitHeight: card2Col.implicitHeight + 36
                height: implicitHeight
                radius: 16
                color: Theme.alpha(Theme.surface, 0.68)
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.24)

                Column {
                    id: card2Col
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 18
                    spacing: 10

                    // Top Row: Big Temperature, Condition Badges & Live Status Pill
                    Row {
                        width: parent.width

                        // Left: Temperature and Badges
                        Column {
                            width: parent.width - 240
                            spacing: 6

                            Row {
                                spacing: 14

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: (weatherRoot.weatherData && weatherRoot.weatherData.temp_C !== "--")
                                        ? (weatherRoot.weatherData.temp_C + "°C")
                                        : "--°C"
                                    color: Theme.foreground
                                    font.family: "Outfit"
                                    font.pixelSize: 48
                                    font.weight: Font.Light
                                }

                                // Condition Badge
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 28
                                    radius: 14
                                    width: condBadgeRow.implicitWidth + 20
                                    color: Theme.alpha(Theme.accent, 0.20)
                                    border.width: 1
                                    border.color: Theme.accent

                                    Row {
                                        id: condBadgeRow
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Image {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 14; height: 14
                                            source: {
                                                var c = weatherRoot.activeAnimCategory
                                                if (c === "rain") return weatherRoot.rainSvg
                                                if (c === "thunder") return weatherRoot.zapSvg
                                                if (c === "snow") return weatherRoot.snowSvg
                                                if (c === "cloudy" || c === "fog") return weatherRoot.cloudSvg
                                                return weatherRoot.sunSvg
                                            }
                                            sourceSize: Qt.size(28, 28)
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: {
                                                if (weatherRoot.simulatedCategoryOverride.length > 0) {
                                                    return weatherRoot.simulatedCategoryOverride.toUpperCase() + " (WINDOW VIEW)"
                                                }
                                                return (weatherRoot.weatherData && weatherRoot.weatherData.condition) ? weatherRoot.weatherData.condition : "Awaiting Location"
                                            }
                                            color: Theme.accent
                                            font.family: "Outfit"
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                }

                                // Day/Night Celestial Badge
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 26
                                    radius: 13
                                    width: dayNightRow.implicitWidth + 16
                                    color: Theme.alpha(Theme.surface, 0.60)
                                    border.width: 1
                                    border.color: Theme.alpha(Theme.foreground, 0.15)

                                    Row {
                                        id: dayNightRow
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Image {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 12; height: 12
                                            source: (weatherRoot.weatherData && !weatherRoot.weatherData.is_day) ? weatherRoot.sunsetSvg : weatherRoot.sunSvg
                                            sourceSize: Qt.size(24, 24)
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: (weatherRoot.weatherData && !weatherRoot.weatherData.is_day) ? "Nighttime" : "Daytime"
                                            color: Theme.alpha(Theme.foreground, 0.75)
                                            font.family: "Outfit"
                                            font.pixelSize: 10
                                            font.weight: Font.Medium
                                        }
                                    }
                                }
                            }

                            // Location Name
                            Text {
                                text: (weatherRoot.weatherData && weatherRoot.weatherData.location.length > 0 && weatherRoot.weatherData.configured)
                                    ? weatherRoot.weatherData.location
                                    : (cityInput.text.length > 0 ? (cityInput.text + ", " + countryInput.text) : "Location Not Configured")
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 17
                                font.weight: Font.DemiBold
                            }

                            // Feels Like & Meteorological Summary
                            Text {
                                text: (weatherRoot.weatherData && weatherRoot.weatherData.feels_like_C !== "--")
                                    ? ("Feels like " + weatherRoot.weatherData.feels_like_C + "°C  •  Humidity: " + weatherRoot.weatherData.humidity + "%  •  Wind: " + weatherRoot.weatherData.wind_speed + " km/h " + weatherRoot.weatherData.wind_dir)
                                    : "Enter your City & Country above or select a preset to stream live weather data"
                                color: Theme.alpha(Theme.foreground, 0.65)
                                font.family: "Outfit"
                                font.pixelSize: 12
                            }
                        }

                        // Right: Live Atmospheric Simulation Indicator Badge
                        Column {
                            width: 240
                            spacing: 6

                            Rectangle {
                                anchors.right: parent.right
                                height: 32
                                radius: 16
                                width: animBadgeRow.implicitWidth + 24
                                color: Theme.alpha(Theme.accent, 0.18)
                                border.width: 1
                                border.color: Theme.alpha(Theme.accent, 0.45)

                                Row {
                                    id: animBadgeRow
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 8; height: 8; radius: 4
                                        color: "#22c55e"

                                        SequentialAnimation on opacity {
                                            loops: Animation.Infinite
                                            running: true
                                            NumberAnimation { from: 0.4; to: 1.0; duration: 1100; easing.type: Easing.InOutSine }
                                            NumberAnimation { from: 1.0; to: 0.4; duration: 1100; easing.type: Easing.InOutSine }
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: (weatherRoot.simulatedCategoryOverride.length > 0)
                                            ? ("WINDOW: " + weatherRoot.activeAnimCategory.toUpperCase())
                                            : ("LIVE WINDOW: " + weatherRoot.activeAnimCategory.toUpperCase())
                                        color: Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }

                            Text {
                                anchors.right: parent.right
                                text: "Architectural Window Glass Physics"
                                color: Theme.alpha(Theme.foreground, 0.45)
                                font.family: "Outfit"
                                font.pixelSize: 10
                            }
                        }
                    }
                }
            }

            // ─────────────────────────────────────────────────────────────────
            // CARD 3: CELESTIAL SOLAR TRAJECTORY & HORIZON ARC
            // ─────────────────────────────────────────────────────────────────
            Rectangle {
                width: parent.width
                implicitHeight: 200
                height: implicitHeight
                radius: 16
                color: Theme.alpha(Theme.surface, 0.68)
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.24)
                clip: true

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 10

                    // Card Title Row
                    Row {
                        width: parent.width

                        Column {
                            width: parent.width - 200
                            spacing: 2
                            Text {
                                text: "Solar Trajectory & Celestial Horizon"
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: "Calculated from local astronomical coordinates"
                                color: Theme.alpha(Theme.foreground, 0.50)
                                font.family: "Outfit"
                                font.pixelSize: 11
                            }
                        }

                        // Day progression status badge
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            height: 24
                            radius: 12
                            width: dayProgText.implicitWidth + 18
                            color: Theme.alpha(Theme.surface, 0.60)
                            border.width: 1
                            border.color: Theme.alpha(Theme.foreground, 0.15)

                            Text {
                                id: dayProgText
                                anchors.centerIn: parent
                                text: {
                                    var p = weatherRoot.weatherData ? weatherRoot.weatherData.day_progress : 0.5
                                    var pct = Math.round(p * 100)
                                    return (weatherRoot.weatherData && !weatherRoot.weatherData.is_day) ? "Nighttime Orbit" : ("Daylight Progress: " + pct + "%")
                                }
                                color: Theme.alpha(Theme.foreground, 0.75)
                                font.family: "Outfit"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                            }
                        }
                    }

                    // Arc Canvas Area
                    Item {
                        id: arcContainer
                        width: parent.width
                        height: 115

                        readonly property real leftX: 50
                        readonly property real rightX: arcContainer.width - 50
                        readonly property real arcW: rightX - leftX
                        readonly property real baseY: arcContainer.height - 28
                        readonly property real peakH: 60

                        readonly property real progress: {
                            var p = weatherRoot.weatherData ? weatherRoot.weatherData.day_progress : 0.5
                            return Math.max(0.0, Math.min(1.0, p))
                        }

                        readonly property real sunX: leftX + progress * arcW
                        readonly property real sunY: baseY - 4 * peakH * progress * (1.0 - progress)

                        // Canvas drawing parabolic daylight arc and horizon
                        Canvas {
                            id: arcCanvas
                            anchors.fill: parent
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()

                                var lx = arcContainer.leftX
                                var rx = arcContainer.rightX
                                var by = arcContainer.baseY
                                var h = arcContainer.peakH

                                // Ground Horizon Baseline
                                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.12)
                                ctx.lineWidth = 1.5
                                ctx.beginPath()
                                ctx.moveTo(lx - 25, by)
                                ctx.lineTo(rx + 25, by)
                                ctx.stroke()

                                // Parabolic Daylight Arc Track
                                ctx.strokeStyle = Theme.alpha(Theme.accent, 0.55)
                                ctx.lineWidth = 2
                                ctx.setLineDash([5, 5])
                                ctx.beginPath()
                                ctx.moveTo(lx, by)
                                for (var t = 0.0; t <= 1.0; t += 0.02) {
                                    var x = lx + t * (rx - lx)
                                    var y = by - 4 * h * t * (1.0 - t)
                                    ctx.lineTo(x, y)
                                }
                                ctx.stroke()
                            }
                        }

                        Connections {
                            target: Theme
                            function onAccentChanged() { arcCanvas.requestPaint() }
                        }

                        // Sunrise Marker (Left)
                        Column {
                            x: arcContainer.leftX - width / 2
                            y: arcContainer.baseY + 6
                            spacing: 2

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 4
                                Image {
                                    width: 14; height: 14
                                    source: weatherRoot.sunriseSvg
                                    sourceSize: Qt.size(28, 28)
                                }
                                Text {
                                    text: weatherRoot.weatherData ? weatherRoot.weatherData.sunrise : "06:00 AM"
                                    color: "#f59e0b"
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Sunrise"
                                color: Theme.alpha(Theme.foreground, 0.55)
                                font.family: "Outfit"
                                font.pixelSize: 10
                            }
                        }

                        // Sunset Marker (Right)
                        Column {
                            x: arcContainer.rightX - width / 2
                            y: arcContainer.baseY + 6
                            spacing: 2

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 4
                                Image {
                                    width: 14; height: 14
                                    source: weatherRoot.sunsetSvg
                                    sourceSize: Qt.size(28, 28)
                                }
                                Text {
                                    text: weatherRoot.weatherData ? weatherRoot.weatherData.sunset : "06:00 PM"
                                    color: "#ef4444"
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Sunset"
                                color: Theme.alpha(Theme.foreground, 0.55)
                                font.family: "Outfit"
                                font.pixelSize: 10
                            }
                        }

                        // Dynamic Gliding Celestial Orb
                        Rectangle {
                            id: celestialOrb
                            width: 20
                            height: 20
                            radius: 10
                            color: (weatherRoot.weatherData && !weatherRoot.weatherData.is_day) ? "#e2e8f0" : "#fbbf24"
                            border.width: 2
                            border.color: "#ffffff"

                            x: arcContainer.sunX - width / 2
                            y: arcContainer.sunY - height / 2

                            Behavior on x { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
                            Behavior on y { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }

                            // Ambient pulsing halo
                            Rectangle {
                                anchors.centerIn: parent
                                width: 38
                                height: 38
                                radius: 19
                                color: (weatherRoot.weatherData && !weatherRoot.weatherData.is_day)
                                    ? Qt.rgba(0.88, 0.92, 1.0, 0.22)
                                    : Qt.rgba(0.98, 0.75, 0.14, 0.25)

                                SequentialAnimation on scale {
                                    loops: Animation.Infinite
                                    running: true
                                    NumberAnimation { from: 0.9; to: 1.25; duration: 1800; easing.type: Easing.InOutSine }
                                    NumberAnimation { from: 1.25; to: 0.9; duration: 1800; easing.type: Easing.InOutSine }
                                }
                            }
                        }
                    }
                }
            }

            // ─────────────────────────────────────────────────────────────────
            // CARD 4: 2x2 ATMOSPHERIC METRICS GRID
            // ─────────────────────────────────────────────────────────────────
            Flow {
                width: parent.width
                spacing: 14

                // Metric 1: Wind & Direction
                Rectangle {
                    width: (parent.width - 14) / 2
                    height: 80
                    radius: 14
                    color: Theme.alpha(Theme.surface, 0.65)
                    border.width: 1
                    border.color: Theme.alpha(Theme.accent, 0.22)

                    Row {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 14

                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24; height: 24
                            source: weatherRoot.windSvg
                            sourceSize: Qt.size(48, 48)
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            Text {
                                text: "Wind & Direction"
                                color: Theme.alpha(Theme.foreground, 0.60)
                                font.family: "Outfit"
                                font.pixelSize: 11
                            }
                            Text {
                                text: (weatherRoot.weatherData && weatherRoot.weatherData.wind_speed !== "--")
                                    ? (weatherRoot.weatherData.wind_speed + " km/h " + weatherRoot.weatherData.wind_dir)
                                    : "--"
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }

                // Metric 2: Humidity & Moisture
                Rectangle {
                    width: (parent.width - 14) / 2
                    height: 80
                    radius: 14
                    color: Theme.alpha(Theme.surface, 0.65)
                    border.width: 1
                    border.color: Theme.alpha(Theme.accent, 0.22)

                    Row {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 14

                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24; height: 24
                            source: weatherRoot.dropSvg
                            sourceSize: Qt.size(48, 48)
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            Text {
                                text: "Air Moisture / Humidity"
                                color: Theme.alpha(Theme.foreground, 0.60)
                                font.family: "Outfit"
                                font.pixelSize: 11
                            }
                            Text {
                                text: (weatherRoot.weatherData && weatherRoot.weatherData.humidity !== "--")
                                    ? (weatherRoot.weatherData.humidity + "% Relative")
                                    : "--"
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }

                // Metric 3: Barometric Pressure
                Rectangle {
                    width: (parent.width - 14) / 2
                    height: 80
                    radius: 14
                    color: Theme.alpha(Theme.surface, 0.65)
                    border.width: 1
                    border.color: Theme.alpha(Theme.accent, 0.22)

                    Row {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 14

                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24; height: 24
                            source: weatherRoot.gaugeSvg
                            sourceSize: Qt.size(48, 48)
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            Text {
                                text: "Barometric Pressure"
                                color: Theme.alpha(Theme.foreground, 0.60)
                                font.family: "Outfit"
                                font.pixelSize: 11
                            }
                            Text {
                                text: (weatherRoot.weatherData && weatherRoot.weatherData.pressure !== "--")
                                    ? (weatherRoot.weatherData.pressure + " hPa")
                                    : "--"
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }

                // Metric 4: Visibility & UV Index
                Rectangle {
                    width: (parent.width - 14) / 2
                    height: 80
                    radius: 14
                    color: Theme.alpha(Theme.surface, 0.65)
                    border.width: 1
                    border.color: Theme.alpha(Theme.accent, 0.22)

                    Row {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 14

                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24; height: 24
                            source: weatherRoot.eyeSvg
                            sourceSize: Qt.size(48, 48)
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            Text {
                                text: "Visibility & UV Index"
                                color: Theme.alpha(Theme.foreground, 0.60)
                                font.family: "Outfit"
                                font.pixelSize: 11
                            }
                            Text {
                                text: (weatherRoot.weatherData && weatherRoot.weatherData.visibility !== "--")
                                    ? (weatherRoot.weatherData.visibility + " km  •  UV: " + weatherRoot.weatherData.uv_index)
                                    : "--"
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }
            }

            // Bottom Spacing
            Item { width: parent.width; height: 24 }
        }
    }
}
