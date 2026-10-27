import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root

    implicitWidth: 444
    implicitHeight: 496

    property bool active: false
    signal backClicked()
    signal navigateToControl()
    signal pageDotClicked(int pageIndex)

    readonly property string userName: {
        var u = Quickshell.env("USER")
        return (u && u.length > 0) ? u : "user"
    }

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : ("/home/" + root.userName)
    }

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    // ── VECTOR ICONS (STRICTLY NO EMOJIS) ────────────────────────────────────
    readonly property string arrowLeftSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>')
    readonly property string arrowRightSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>')
    readonly property string refreshSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21.5 2v6h-6M2.5 22v-6h6M2 11.5a10 10 0 0 1 18.8-4.3M22 12.5a10 10 0 0 1-18.8 4.2"/></svg>')
    readonly property string pinSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>')
    readonly property string calendarSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>')
    readonly property string dropletSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#38bdf8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/></svg>')
    readonly property string windSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#06b6d4" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9.59 4.59A2 2 0 1 1 11 8H2m10.59 11.41A2 2 0 1 0 14 16H2m15.73-8.27A2.5 2.5 0 1 1 19.5 12H2"/></svg>')
    readonly property string uvSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="4"/><path d="M12 2v2m0 16v2M4.93 4.93l1.41 1.41m11.32 11.32l1.41 1.41M2 12h2m16 0h2M4.93 19.07l1.41-1.41m11.32-11.32l1.41-1.41"/></svg>')
    readonly property string pressureSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.primary + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M12 6v6l3 3"/></svg>')

    // Weather condition icons
    readonly property string sunSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>')
    readonly property string moonSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#38bdf8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>')
    readonly property string cloudSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z"/></svg>')
    readonly property string cloudSunSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2v2"/><path d="M4.93 4.93l1.41 1.41"/><path d="M20 12h2"/><path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9z"/></svg>')
    readonly property string rainSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#38bdf8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="16" y1="13" x2="16" y2="21"/><line x1="8" y1="13" x2="8" y2="21"/><line x1="12" y1="15" x2="12" y2="23"/><path d="M20 16.58A5 5 0 0 0 18 7h-1.26A8 8 0 1 0 4 15.25"/></svg>')
    readonly property string drizzleSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#38bdf8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 16.58A5 5 0 0 0 18 7h-1.26A8 8 0 1 0 4 15.25"/><line x1="8" y1="18" x2="8.01" y2="18"/><line x1="12" y1="18" x2="12.01" y2="18"/><line x1="16" y1="18" x2="16.01" y2="18"/></svg>')
    readonly property string snowSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#e2e8f0" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 17.58A5 5 0 0 0 18 8h-1.26A8 8 0 1 0 4 16.25"/><circle cx="8" cy="18" r="1"/><circle cx="12" cy="20" r="1"/><circle cx="16" cy="18" r="1"/></svg>')
    readonly property string thunderSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 16.9A5 5 0 0 0 18 7h-1.26a8 8 0 1 0-11.62 9"/><polyline points="13 11 9 17 15 17 11 23"/></svg>')
    readonly property string fogSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.alpha(Theme.foreground, 0.6) + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="7" x2="21" y2="7"/><line x1="5" y1="12" x2="19" y2="12"/><line x1="3" y1="17" x2="21" y2="17"/></svg>')

    function getConditionIcon(category, code, isDay) {
        var cat = (category || "").toLowerCase()
        if (cat.indexOf("thunder") !== -1 || cat.indexOf("storm") !== -1) return root.thunderSvg
        if (cat.indexOf("snow") !== -1 || cat.indexOf("ice") !== -1) return root.snowSvg
        if (cat.indexOf("rain") !== -1) return root.rainSvg
        if (cat.indexOf("drizzle") !== -1) return root.drizzleSvg
        if (cat.indexOf("fog") !== -1 || cat.indexOf("mist") !== -1 || cat.indexOf("haze") !== -1) return root.fogSvg
        if (cat.indexOf("cloud") !== -1) {
            if (code === "1" || code === "2") return isDay ? root.cloudSunSvg : root.cloudSvg
            return root.cloudSvg
        }
        if (cat.indexOf("sun") !== -1 || cat.indexOf("clear") !== -1) {
            return (isDay === false) ? root.moonSvg : root.sunSvg
        }
        return root.cloudSvg
    }

    // ── WEATHER STATE ────────────────────────────────────────────────────────
    property bool useFahrenheit: false
    property string location: "Loading..."
    property string currentTempC: "--"
    property string currentTempF: "--"
    property string feelsLikeC: "--"
    property string feelsLikeF: "--"
    property string conditionText: "Loading weather..."
    property string weatherCategory: "sunny"
    property string weatherCode: "0"
    property bool isDay: true
    property string humidity: "--"
    property string windSpeed: "--"
    property string windDir: "N"
    property string pressure: "1013"
    property string uvIndex: "--"
    property string sunrise: "--"
    property string sunset: "--"
    property var forecast7Days: []
    property bool isRefreshing: false

    readonly property string displayCurrentTemp: root.useFahrenheit ? (root.currentTempF + "°") : (root.currentTempC + "°")
    readonly property string displayFeelsLike: root.useFahrenheit ? (root.feelsLikeF + "°") : (root.feelsLikeC + "°")

    function applyWeatherData(data) {
        if (!data) return
        if (data.location) root.location = data.location
        else if (data.city) root.location = data.city + (data.country ? (", " + data.country) : "")
        if (data.temp_C !== undefined) root.currentTempC = String(data.temp_C)
        if (data.temp_F !== undefined) root.currentTempF = String(data.temp_F)
        if (data.feels_like_C !== undefined) root.feelsLikeC = String(data.feels_like_C)
        if (data.feels_like_F !== undefined) root.feelsLikeF = String(data.feels_like_F)
        if (data.condition) root.conditionText = String(data.condition).trim()
        if (data.weather_category) root.weatherCategory = String(data.weather_category)
        if (data.weather_code) root.weatherCode = String(data.weather_code)
        if (data.is_day !== undefined) root.isDay = Boolean(data.is_day)
        if (data.humidity !== undefined) root.humidity = String(data.humidity)
        if (data.wind_speed !== undefined) root.windSpeed = String(data.wind_speed)
        if (data.wind_dir) root.windDir = String(data.wind_dir)
        if (data.pressure !== undefined) root.pressure = String(data.pressure)
        if (data.uv_index !== undefined) root.uvIndex = String(data.uv_index)
        if (data.sunrise) root.sunrise = String(data.sunrise)
        if (data.sunset) root.sunset = String(data.sunset)
        if (data.forecast_7days && Array.isArray(data.forecast_7days) && data.forecast_7days.length > 0) {
            root.forecast7Days = data.forecast_7days
        }
    }

    // Immediate Cache Loader (0ms instant display)
    Process {
        id: cacheLoader
        command: ["python3", "-c", "import json, os; p=os.path.expanduser('~/.hyprconf/hypr/.cache/weather_cache.json'); print(open(p, encoding='utf-8').read() if os.path.exists(p) else '{}')"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var parsed = JSON.parse(text.trim())
                    root.applyWeatherData(parsed)
                } catch(e) {}
            }
        }
    }

    // Live Fetcher Process
    Process {
        id: liveFetcher
        command: ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/weather.py", "--force", "--json"]
        stdout: StdioCollector {
            onTextChanged: {
                root.isRefreshing = false
                if (!text || text.trim().length === 0) return
                try {
                    var parsed = JSON.parse(text.trim())
                    root.applyWeatherData(parsed)
                } catch(e) {}
            }
        }
        onExited: {
            root.isRefreshing = false
        }
    }

    function refreshWeather() {
        if (liveFetcher.running) return
        root.isRefreshing = true
        liveFetcher.running = true
    }

    Timer {
        interval: 600000 // 10 minutes auto-refresh
        running: root.active
        repeat: true
        onTriggered: root.refreshWeather()
    }

    onActiveChanged: {
        if (active) {
            cascadeEnterAnim.start()
            if (!cacheLoader.running) {
                cacheLoader.running = true
            }
            if (root.forecast7Days.length < 7) {
                root.refreshWeather()
            }
        } else {
            cascadeEnterAnim.stop()
        }
    }

    ParallelAnimation {
        id: cascadeEnterAnim
        SequentialAnimation {
            PauseAnimation { duration: 0 }
            ParallelAnimation {
                NumberAnimation { target: headerRow; property: "opacity"; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
                NumberAnimation { target: headerTranslate; property: "y"; to: 0; duration: 220; easing.type: Easing.OutCubic }
            }
        }
        SequentialAnimation {
            PauseAnimation { duration: 60 }
            ParallelAnimation {
                NumberAnimation { target: heroCard; property: "opacity"; to: 1.0; duration: 220; easing.type: Easing.OutCubic }
                NumberAnimation { target: heroTranslate; property: "y"; to: 0; duration: 240; easing.type: Easing.OutCubic }
            }
        }
        SequentialAnimation {
            PauseAnimation { duration: 120 }
            ParallelAnimation {
                NumberAnimation { target: forecastCard; property: "opacity"; to: 1.0; duration: 220; easing.type: Easing.OutCubic }
                NumberAnimation { target: forecastTranslate; property: "y"; to: 0; duration: 240; easing.type: Easing.OutCubic }
            }
        }
        SequentialAnimation {
            PauseAnimation { duration: 180 }
            NumberAnimation { target: paginationRow; property: "opacity"; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
        }
    }

    // ── MAIN COLUMN LAYOUT ───────────────────────────────────────────────────
    Column {
        anchors.fill: parent
        spacing: 9

        // ── 1. HEADER ROW ────────────────────────────────────────────────────
        Item {
            id: headerRow
            width: parent.width
            height: 36
            opacity: 0.0
            transform: Translate { id: headerTranslate; y: -8 }

            // Back / Navigate to Control Center Button
            Rectangle {
                id: backBtn
                width: 30
                height: 30
                radius: 15
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: backMouse.containsMouse ? Theme.alpha(Theme.surface, 0.9) : Theme.alpha(Theme.surface, 0.5)
                border.color: backMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.10)
                border.width: 1
                scale: backMouse.pressed ? 0.92 : (backMouse.containsMouse ? 1.05 : 1.0)
                Behavior on scale { NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 120 } }

                Image {
                    anchors.centerIn: parent
                    width: 13
                    height: 13
                    source: root.arrowLeftSvg
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backClicked()
                }
            }

            // Title & Location Header Column (No cramped pill, ample readable space)
            Column {
                anchors.left: backBtn.right
                anchors.leftMargin: 10
                anchors.right: rightControls.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    text: "Weather Forecast"
                    font.family: "Outfit"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: Theme.foreground
                }

                Row {
                    spacing: 4
                    Image {
                        width: 9
                        height: 9
                        source: root.pinSvg
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: root.location
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Theme.alpha(Theme.foreground, 0.70)
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, 210)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Right Controls: Unit Toggle (°C/°F) & Refresh Button
            Row {
                id: rightControls
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                // Unit Toggle Capsule
                Rectangle {
                    width: 48
                    height: 24
                    radius: 12
                    color: unitMouse.containsMouse ? Theme.alpha(Theme.surface, 0.9) : Theme.alpha(Theme.surface, 0.5)
                    border.color: Theme.alpha(Theme.foreground, 0.12)
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            text: "°C"
                            font.family: "Outfit"
                            font.pixelSize: 10
                            font.weight: !root.useFahrenheit ? Font.Bold : Font.Normal
                            color: !root.useFahrenheit ? Theme.accent : Theme.alpha(Theme.foreground, 0.45)
                        }
                        Text {
                            text: "/"
                            font.family: "Outfit"
                            font.pixelSize: 9
                            color: Theme.alpha(Theme.foreground, 0.3)
                        }
                        Text {
                            text: "°F"
                            font.family: "Outfit"
                            font.pixelSize: 10
                            font.weight: root.useFahrenheit ? Font.Bold : Font.Normal
                            color: root.useFahrenheit ? Theme.accent : Theme.alpha(Theme.foreground, 0.45)
                        }
                    }

                    MouseArea {
                        id: unitMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.useFahrenheit = !root.useFahrenheit
                    }
                }

                // Refresh Button
                Rectangle {
                    id: refreshBtn
                    width: 26
                    height: 26
                    radius: 13
                    color: refreshMouse.containsMouse ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.5)
                    border.color: refreshMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.10)
                    border.width: 1
                    scale: refreshMouse.pressed ? 0.90 : (refreshMouse.containsMouse ? 1.06 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 120 } }
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Image {
                        id: refreshImg
                        anchors.centerIn: parent
                        width: 12
                        height: 12
                        source: root.refreshSvg
                        rotation: 0

                        RotationAnimation on rotation {
                            running: root.isRefreshing
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: 700
                        }
                    }

                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.refreshWeather()
                    }
                }
            }
        }

        // ── 2. CURRENT WEATHER HERO CARD ─────────────────────────────────────
        Rectangle {
            id: heroCard
            width: parent.width
            height: 168
            radius: 18
            opacity: 0.0
            transform: Translate { id: heroTranslate; y: 14 }
            color: Theme.alpha(Theme.surface, 0.65)
            border.color: Theme.alpha(Theme.foreground, 0.08)
            border.width: 1
            clip: true

            // Top specular highlight
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                height: 1
                color: Theme.alpha(Theme.foreground, 0.14)
            }

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                // Upper Tier: Temperature + Condition + Atmospheric Emblem
                RowLayout {
                    width: parent.width
                    height: 74
                    spacing: 12

                    // Large Temperature Display (No baseline offset, vertically centered)
                    Text {
                        text: root.displayCurrentTemp
                        font.family: "Outfit"
                        font.pixelSize: 42
                        font.weight: Font.Bold
                        color: Theme.foreground
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Condition, Feels-like & Daily Extremes
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            text: root.conditionText
                            font.family: "Outfit"
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                            color: Theme.foreground
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        Text {
                            readonly property var todayItem: (root.forecast7Days && root.forecast7Days.length > 0) ? root.forecast7Days[0] : null
                            readonly property string hi: todayItem ? (root.useFahrenheit ? todayItem.temp_max_F : todayItem.temp_max_C) : "--"
                            readonly property string lo: todayItem ? (root.useFahrenheit ? todayItem.temp_min_F : todayItem.temp_min_C) : "--"
                            text: "Feels " + root.displayFeelsLike + (todayItem ? (" • H: " + hi + "° L: " + lo + "°") : "")
                            font.family: "Outfit"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: Theme.alpha(Theme.foreground, 0.70)
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    // Right Block: Crisp Weather Vector Archetype Emblem
                    Rectangle {
                        Layout.preferredWidth: 54
                        Layout.preferredHeight: 54
                        Layout.alignment: Qt.AlignVCenter
                        radius: 27
                        color: Theme.alpha(Theme.surface, 0.75)
                        border.color: Theme.alpha(Theme.accent, 0.3)
                        border.width: 1.5

                        Image {
                            anchors.centerIn: parent
                            width: 30
                            height: 30
                            source: root.getConditionIcon(root.weatherCategory, root.weatherCode, root.isDay)
                        }
                    }
                }

                // Lower Tier: 4 Micro-Metric Badges Grid
                Row {
                    width: parent.width
                    spacing: 8

                    // 1. Humidity
                    Rectangle {
                        width: (parent.width - 24) / 4
                        height: 50
                        radius: 12
                        color: Theme.alpha(Theme.surface, 0.55)
                        border.color: Theme.alpha(Theme.foreground, 0.08)
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 3
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 4
                                Image { width: 11; height: 11; source: root.dropletSvg; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "Humidity"; font.family: "Outfit"; font.pixelSize: 10; color: Theme.alpha(Theme.foreground, 0.65); anchors.verticalCenter: parent.verticalCenter }
                            }
                            Text {
                                text: root.humidity + "%"
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: Theme.foreground
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    // 2. Wind
                    Rectangle {
                        width: (parent.width - 24) / 4
                        height: 50
                        radius: 12
                        color: Theme.alpha(Theme.surface, 0.55)
                        border.color: Theme.alpha(Theme.foreground, 0.08)
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 3
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 4
                                Image { width: 11; height: 11; source: root.windSvg; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "Wind"; font.family: "Outfit"; font.pixelSize: 10; color: Theme.alpha(Theme.foreground, 0.65); anchors.verticalCenter: parent.verticalCenter }
                            }
                            Text {
                                text: root.windSpeed + " km/h"
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: Theme.foreground
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    // 3. UV Index
                    Rectangle {
                        width: (parent.width - 24) / 4
                        height: 50
                        radius: 12
                        color: Theme.alpha(Theme.surface, 0.55)
                        border.color: Theme.alpha(Theme.foreground, 0.08)
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 3
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 4
                                Image { width: 11; height: 11; source: root.uvSvg; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "UV Index"; font.family: "Outfit"; font.pixelSize: 10; color: Theme.alpha(Theme.foreground, 0.65); anchors.verticalCenter: parent.verticalCenter }
                            }
                            Text {
                                text: root.uvIndex
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: Theme.foreground
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    // 4. Pressure
                    Rectangle {
                        width: (parent.width - 24) / 4
                        height: 50
                        radius: 12
                        color: Theme.alpha(Theme.surface, 0.55)
                        border.color: Theme.alpha(Theme.foreground, 0.08)
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 3
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 4
                                Image { width: 11; height: 11; source: root.pressureSvg; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "Pressure"; font.family: "Outfit"; font.pixelSize: 10; color: Theme.alpha(Theme.foreground, 0.65); anchors.verticalCenter: parent.verticalCenter }
                            }
                            Text {
                                text: root.pressure + " hPa"
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: Theme.foreground
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
            }
        }

        // ── 3. 7-DAY FORECAST CARD (NEXT 1 WEEK INFO) ────────────────────────
        Rectangle {
            id: forecastCard
            width: parent.width
            height: 234
            radius: 18
            opacity: 0.0
            transform: Translate { id: forecastTranslate; y: 18 }
            color: Theme.alpha(Theme.surface, 0.65)
            border.color: Theme.alpha(Theme.foreground, 0.08)
            border.width: 1
            clip: true

            Column {
                anchors.fill: parent
                anchors.margins: 10
                anchors.topMargin: 8
                spacing: 4

                // Header: Calendar Icon + "7-Day Forecast"
                Row {
                    width: parent.width
                    height: 18
                    spacing: 6

                    Image {
                        width: 12
                        height: 12
                        source: root.calendarSvg
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "7-Day Forecast"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Theme.foreground
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item { Layout.fillWidth: true; width: 1 }

                    Text {
                        text: "Next 7 Days Outlook"
                        font.family: "Outfit"
                        font.pixelSize: 10
                        color: Theme.alpha(Theme.foreground, 0.55)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // 7 Days List
                ListView {
                    id: forecastList
                    width: parent.width
                    height: 198
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: false
                    model: root.forecast7Days

                    delegate: Rectangle {
                        width: forecastList.width
                        height: 28
                        radius: 7
                        color: rowMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.06) : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 6

                            // Day Name (e.g. "Today", "Tomorrow", "Thu", ...)
                            Text {
                                width: 56
                                text: modelData.day
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: (index === 0) ? Font.Bold : Font.DemiBold
                                color: (index === 0) ? Theme.accent : Theme.foreground
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Weather Vector Icon
                            Image {
                                width: 14
                                height: 14
                                source: root.getConditionIcon(modelData.weather_category, modelData.weather_code, true)
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Condition Summary Text
                            Text {
                                width: 100
                                text: modelData.condition
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: Font.Normal
                                color: Theme.alpha(Theme.foreground, 0.85)
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Precipitation chance (e.g. 20%)
                            Item {
                                width: 36
                                height: parent.height
                                anchors.verticalCenter: parent.verticalCenter

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    visible: modelData.pop > 0

                                    Image {
                                        width: 8
                                        height: 8
                                        source: root.dropletSvg
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: modelData.pop + "%"
                                        font.family: "Outfit"
                                        font.pixelSize: 10
                                        font.weight: Font.Medium
                                        color: "#38bdf8"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            // Temperature Range Bar Visualization
                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                // Min Temp
                                Text {
                                    width: 24
                                    horizontalAlignment: Text.AlignRight
                                    text: (root.useFahrenheit ? modelData.temp_min_F : modelData.temp_min_C) + "°"
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    font.weight: Font.Normal
                                    color: Theme.alpha(Theme.foreground, 0.55)
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                // Visual Temperature Bar Pill
                                Rectangle {
                                    width: 46
                                    height: 4
                                    radius: 2
                                    color: Theme.alpha(Theme.foreground, 0.12)
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        radius: 2
                                        width: Math.max(8, parent.width * 0.7)
                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0.0; color: Theme.alpha(Theme.accent, 0.4) }
                                            GradientStop { position: 1.0; color: Theme.accent }
                                        }
                                    }
                                }

                                // Max Temp
                                Text {
                                    width: 24
                                    horizontalAlignment: Text.AlignLeft
                                    text: (root.useFahrenheit ? modelData.temp_max_F : modelData.temp_max_C) + "°"
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: Theme.foreground
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }
            }
        }

        // ── 4. PAGINATION DOTS PILL (3 PAGES: 1=Weather, 2=Control Center, 3=System Info) ────
        Item {
            id: paginationRow
            width: parent.width
            height: 24
            opacity: 0.0

            // Centered 3 Pagination Dots
            Row {
                anchors.centerIn: parent
                spacing: 8

                // Dot 1: Page 1 (Weather) - ACTIVE
                Rectangle {
                    width: 18
                    height: 5
                    radius: 2.5
                    color: "#38bdf8"
                    Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }

                // Dot 2: Page 2 (Control Center) - Clickable
                Rectangle {
                    width: 6
                    height: 5
                    radius: 2.5
                    color: dot2Mouse.containsMouse ? Theme.foreground : Theme.alpha(Theme.foreground, 0.35)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    MouseArea {
                        id: dot2Mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.pageDotClicked(1)
                    }
                }

                // Dot 3: Page 3 (System Info) - Clickable
                Rectangle {
                    width: 6
                    height: 5
                    radius: 2.5
                    color: dot3Mouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.25)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    MouseArea {
                        id: dot3Mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.pageDotClicked(2)
                    }
                }
            }

            // Right: Next Page Arrow Button (Control Center →)
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 24
                width: nextRow.width + 16
                radius: 12
                color: nextMouse.containsMouse ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.6)
                border.width: 1
                border.color: nextMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                scale: nextMouse.pressed ? 0.94 : (nextMouse.containsMouse ? 1.05 : 1.0)
                Behavior on scale { NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Row {
                    id: nextRow
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "Control Center"
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: nextMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.8)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Image {
                        width: 10
                        height: 10
                        source: root.arrowRightSvg
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.navigateToControl()
                }
            }
        }
    }
}
