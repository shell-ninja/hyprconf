import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root

    property var widgetConfig: ({
        unit: "C",
        show_background: true,
        show_location: true,
        show_details: true,
        glass_opacity: 0.65
    })
    property bool editMode: false

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    implicitWidth: 320
    implicitHeight: 125
    width: implicitWidth
    height: implicitHeight

    // Weather State
    property string tempC: "11"
    property string tempF: "52"
    property string conditionText: "Overcast"
    property string weatherCategory: "cloudy"
    property string locationText: "London, UK"
    property string humidityText: "61%"
    property string windText: "17 km/h"
    property string feelsLikeC: "8°C"
    property string feelsLikeF: "46°F"

    readonly property string displayTemp: {
        var isF = (root.widgetConfig && (root.widgetConfig.unit === "F" || root.widgetConfig.use_fahrenheit === true))
        return isF ? (root.tempF + "°F") : (root.tempC + "°C")
    }

    readonly property string displayFeelsLike: {
        var isF = (root.widgetConfig && (root.widgetConfig.unit === "F" || root.widgetConfig.use_fahrenheit === true))
        return isF ? root.feelsLikeF : root.feelsLikeC
    }

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    // Weather SVGs
    readonly property string sunSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>')
    readonly property string cloudSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z"/></svg>')
    readonly property string rainSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="16" y1="13" x2="16" y2="21"/><line x1="8" y1="13" x2="8" y2="21"/><line x1="12" y1="15" x2="12" y2="23"/><path d="M20 16.58A5 5 0 0 0 18 7h-1.26A8 8 0 1 0 4 15.25"/></svg>')
    readonly property string snowSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 17.58A5 5 0 0 0 18 8h-1.26A8 8 0 1 0 4 16.25"/><line x1="8" y1="16" x2="8.01" y2="16"/><line x1="8" y1="20" x2="8.01" y2="20"/><line x1="12" y1="18" x2="12.01" y2="18"/><line x1="12" y1="22" x2="12.01" y2="22"/><line x1="16" y1="16" x2="16.01" y2="16"/><line x1="16" y1="20" x2="16.01" y2="20"/></svg>')
    readonly property string stormSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 16.9A5 5 0 0 0 18 7h-1.26a8 8 0 1 0-11.62 9"/><polyline points="13 11 9 17 15 17 11 23"/></svg>')
    readonly property string pinSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="' + Theme.alpha(Theme.foreground, 0.65) + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>')
    readonly property string dropletSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="' + Theme.alpha(Theme.foreground, 0.65) + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/></svg>')
    readonly property string windSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="' + Theme.alpha(Theme.foreground, 0.65) + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9.59 4.59A2 2 0 1 1 11 8H2m10.59 11.41A2 2 0 1 0 14 16H2m15.73-8.27A2.5 2.5 0 1 1 19.5 12H2"/></svg>')

    readonly property string weatherIcon: {
        var cat = root.weatherCategory ? root.weatherCategory.toLowerCase() : ""
        if (cat.indexOf("rain") !== -1 || cat.indexOf("drizzle") !== -1) return root.rainSvg
        if (cat.indexOf("snow") !== -1 || cat.indexOf("ice") !== -1) return root.snowSvg
        if (cat.indexOf("thunder") !== -1 || cat.indexOf("storm") !== -1) return root.stormSvg
        if (cat.indexOf("clear") !== -1 || cat.indexOf("sun") !== -1) return root.sunSvg
        return root.cloudSvg
    }

    // Load weather data from cache
    Process {
        id: weatherLoader
        command: ["python3", "-c", "import json, os; p=os.path.expanduser('~/.hyprconf/hypr/.cache/weather_cache.json'); print(open(p, encoding='utf-8').read() if os.path.exists(p) else '{}')"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var d = JSON.parse(text.trim())
                    if (d.temp_C !== undefined) root.tempC = String(d.temp_C)
                    if (d.temp_F !== undefined) root.tempF = String(d.temp_F)
                    if (d.condition) root.conditionText = String(d.condition).trim()
                    if (d.weather_category) root.weatherCategory = String(d.weather_category)
                    if (d.location) root.locationText = String(d.location)
                    else if (d.city) root.locationText = String(d.city)
                    if (d.humidity) root.humidityText = String(d.humidity) + "%"
                    if (d.wind_speed) root.windText = String(d.wind_speed) + " km/h"
                    if (d.feels_like_C) root.feelsLikeC = String(d.feels_like_C) + "°C"
                } catch(e) {}
            }
        }
    }

    // Refresh weather cache periodically
    Process {
        id: weatherFetcher
        command: ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/weather.py", "--summary"]
        onExited: {
            weatherLoader.running = false
            weatherLoader.running = true
        }
    }

    Timer {
        id: refreshTimer
        interval: 300000 // 5 minutes
        repeat: true
        running: !root.editMode && (root.widgetConfig ? root.widgetConfig.enabled !== false : true) && root.visible
        triggeredOnStart: false
        onTriggered: {
            if (!weatherFetcher.running) weatherFetcher.running = true
        }
    }

    // Glassmorphic Obsidian Background Card
    Rectangle {
        id: bgCard
        anchors.fill: parent
        radius: 20
        visible: (root.widgetConfig && root.widgetConfig.show_background !== undefined) ? (root.widgetConfig.show_background !== false) : true
        color: Theme.alpha(Theme.background, (root.widgetConfig && root.widgetConfig.glass_opacity !== undefined) ? root.widgetConfig.glass_opacity : 0.65)
        border.width: 1
        border.color: Theme.alpha(Theme.foreground, 0.12)

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
    }

    // Interior Layout
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        // Top Row: Weather Icon + Temperature + Condition
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Icon Capsule
            Rectangle {
                width: 44
                height: 44
                radius: 12
                color: Theme.alpha(Theme.surface, 0.75)
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.30)
                Layout.alignment: Qt.AlignVCenter

                Image {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    source: root.weatherIcon
                    sourceSize: Qt.size(48, 48)
                }
            }

            // Temperature & Condition Text
            Column {
                Layout.fillWidth: true
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Row {
                    spacing: 8
                    Text {
                        text: root.displayTemp
                        color: Theme.accent
                        font.family: "Outfit"
                        font.pixelSize: 28
                        font.weight: Font.Bold
                        font.letterSpacing: 0.5
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        visible: (root.widgetConfig && root.widgetConfig.show_details !== false)
                        anchors.verticalCenter: parent.verticalCenter
                        width: feelsText.implicitWidth + 8
                        height: 16
                        radius: 8
                        color: Theme.alpha(Theme.accent, 0.15)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.30)

                        Text {
                            id: feelsText
                            anchors.centerIn: parent
                            text: "Feels " + root.displayFeelsLike
                            color: Theme.accent
                            font.family: "Outfit"
                            font.pixelSize: 9
                            font.weight: Font.Medium
                        }
                    }
                }

                Text {
                    text: root.conditionText
                    color: Theme.foreground
                    font.family: "Outfit"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }
        }

        // Bottom Row: Location Pill + Atmospheric Stats
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Location Badge
            Row {
                visible: (root.widgetConfig && root.widgetConfig.show_location !== false)
                spacing: 4
                Layout.alignment: Qt.AlignVCenter

                Image {
                    width: 12
                    height: 12
                    source: root.pinSvg
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: root.locationText
                    color: Theme.alpha(Theme.foreground, 0.65)
                    font.family: "Outfit"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item { Layout.fillWidth: true }

            // Humidity & Wind Metrics
            Row {
                visible: (root.widgetConfig && root.widgetConfig.show_details !== false)
                spacing: 10
                Layout.alignment: Qt.AlignVCenter

                Row {
                    spacing: 3
                    Image {
                        width: 11
                        height: 11
                        source: root.dropletSvg
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: root.humidityText
                        color: Theme.alpha(Theme.foreground, 0.55)
                        font.family: "Outfit"
                        font.pixelSize: 10
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Row {
                    spacing: 3
                    Image {
                        width: 11
                        height: 11
                        source: root.windSvg
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: root.windText
                        color: Theme.alpha(Theme.foreground, 0.55)
                        font.family: "Outfit"
                        font.pixelSize: 10
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
