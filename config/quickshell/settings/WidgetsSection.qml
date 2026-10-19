import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root
    anchors.fill: parent

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : "/home/shell-ninja"
    }

    readonly property string configPath: homeDir + "/.hyprconf/quickshell/widgets/widgets.json"

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string clockSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>')
    readonly property string waveSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 10v3"/><path d="M6 6v11"/><path d="M10 3v18"/><path d="M14 8v7"/><path d="M18 5v13"/><path d="M22 10v3"/></svg>')
    readonly property string cpuSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="4" width="16" height="16" rx="2"/><rect x="9" y="9" width="6" height="6"/><path d="M9 1v3"/><path d="M15 1v3"/><path d="M9 20v3"/><path d="M15 20v3"/><path d="M20 9h3"/><path d="M20 14h3"/><path d="M1 9h3"/><path d="M1 14h3"/></svg>')
    readonly property string musicSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></svg>')
    readonly property string weatherSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"/></svg>')
    readonly property string moveSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="5 9 2 12 5 15"/><polyline points="9 5 12 2 15 5"/><polyline points="15 19 12 22 9 19"/><polyline points="19 9 22 12 19 15"/><line x1="2" y1="12" x2="22" y2="12"/><line x1="12" y1="2" x2="12" y2="22"/></svg>')
    readonly property string checkSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>')

    function tabLibrarySvg(isSelected) {
        var c = isSelected ? Theme.on_primary : Theme.foreground
        return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="' + c + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/></svg>')
    }

    function tabCustomizerSvg(isSelected) {
        var c = isSelected ? Theme.on_primary : Theme.foreground
        return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="' + c + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="4" y1="21" x2="4" y2="14"/><line x1="4" y1="10" x2="4" y2="3"/><line x1="12" y1="21" x2="12" y2="12"/><line x1="12" y1="8" x2="12" y2="3"/><line x1="20" y1="21" x2="20" y2="16"/><line x1="20" y1="12" x2="20" y2="3"/><line x1="1" y1="14" x2="7" y2="14"/><line x1="9" y1="8" x2="15" y2="8"/><line x1="17" y1="16" x2="23" y2="16"/></svg>')
    }

    function tabGlobalSvg(isSelected) {
        var c = isSelected ? Theme.on_primary : Theme.foreground
        return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="' + c + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>')
    }

    property var widgetsConfig: ({
        enabled: true,
        global_glass_opacity: 0.65,
        widgets: {
            clock: { id: "clock", type: "clock", title: "Desktop Clock", enabled: true, x: 0.50, y: 0.28, width: 360, height: 130, scale: 1.0, format_24h: false, show_seconds: false, show_date: true, show_greeting: true, font_size: 44, font_family: "Outfit", show_background: true, glass_opacity: 0.65 },
            visualizer: { id: "visualizer", type: "visualizer", title: "Audio Visualizer", enabled: true, x: 0.50, y: 0.74, width: 520, height: 90, scale: 1.0, bar_count: 12, style: "bars", show_background: true, glass_opacity: 0.55 },
            system_monitor: { id: "system_monitor", type: "system_monitor", title: "System Monitor", enabled: true, x: 0.84, y: 0.34, width: 280, height: 230, scale: 1.0, show_cpu: true, show_ram: true, show_disk: true, show_temp: true, show_background: true, glass_opacity: 0.65 },
            audio_player: { id: "audio_player", type: "audio_player", title: "Audio Player", enabled: true, x: 0.16, y: 0.34, width: 340, height: 150, scale: 1.0, compact: false, show_background: true, glass_opacity: 0.65 },
            weather: { id: "weather", type: "weather", title: "Weather Forecast", enabled: true, x: 0.16, y: 0.65, width: 320, height: 125, scale: 1.0, show_background: true, use_fahrenheit: false, show_details: true, show_location: true, glass_opacity: 0.65 }
        }
    })

    property string selectedWidgetId: "clock"
    property int activeTab: 0 // 0: Library, 1: Properties, 2: Global
    property bool isDirty: false

    // Load widgets.json
    Process {
        id: jsonReader
        command: ["python3", "-c", "import json, os; p=os.path.expanduser('~/.hyprconf/quickshell/widgets/widgets.json'); print(open(p, encoding='utf-8').read() if os.path.exists(p) else '{}')"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var parsed = JSON.parse(text.trim())
                    if (parsed && parsed.widgets) {
                        root.widgetsConfig = parsed
                        root.isDirty = false
                    }
                } catch(e) {}
            }
        }
    }

    // Save Process
    Process {
        id: jsonWriter
    }

    function saveWidgetsConfig() {
        var jsonStr = JSON.stringify(root.widgetsConfig, null, 2)
        jsonWriter.running = false
        jsonWriter.command = [
            "python3", "-c",
            "import sys, os, subprocess\n" +
            "p = os.path.expanduser('~/.hyprconf/quickshell/widgets/widgets.json')\n" +
            "os.makedirs(os.path.dirname(p), exist_ok=True)\n" +
            "with open(p, 'w', encoding='utf-8') as f:\n" +
            "    f.write(sys.argv[1])\n" +
            "p_git = os.path.expanduser('~/hyprconf/config/quickshell/widgets/widgets.json')\n" +
            "if os.path.exists(os.path.dirname(p_git)):\n" +
            "    with open(p_git, 'w', encoding='utf-8') as f:\n" +
            "        f.write(sys.argv[1])\n" +
            "subprocess.run(['qs', 'ipc', '-c', 'widgets', 'call', 'widgets', 'reloadConfig'], stderr=subprocess.DEVNULL)",
            jsonStr
        ]
        jsonWriter.running = true
        root.isDirty = false
        if (typeof window !== "undefined") {
            window.isDirty = false
            window.toastMessage = "Desktop Widgets Saved & Applied"
            window.showSaveToast = true
            toastHideTimer.restart()
        }
    }

    function reloadConfig() {
        jsonReader.running = false
        jsonReader.running = true
        root.isDirty = false
        if (typeof window !== "undefined" && window.activeRootNav === 3) {
            window.isDirty = false
        }
    }

    onIsDirtyChanged: {
        if (typeof window !== "undefined" && window.activeRootNav === 3) {
            window.isDirty = root.isDirty
        }
    }

    Timer {
        id: toastHideTimer
        interval: 2200
        repeat: false
        onTriggered: window.showSaveToast = false
    }

    function updateWidgetPosition(key, newX, newY) {
        if (!root.widgetsConfig || !root.widgetsConfig.widgets || !root.widgetsConfig.widgets[key]) return
        var copy = JSON.parse(JSON.stringify(root.widgetsConfig))
        copy.widgets[key].x = Math.round(newX * 1000) / 1000
        copy.widgets[key].y = Math.round(newY * 1000) / 1000
        root.widgetsConfig = copy
        root.isDirty = true
    }

    function updateWidgetScale(key, newScale) {
        if (!root.widgetsConfig || !root.widgetsConfig.widgets || !root.widgetsConfig.widgets[key]) return
        var copy = JSON.parse(JSON.stringify(root.widgetsConfig))
        copy.widgets[key].scale = Math.round(newScale * 100) / 100
        root.widgetsConfig = copy
        root.isDirty = true
    }

    function setWidgetEnabled(key, val) {
        if (!root.widgetsConfig || !root.widgetsConfig.widgets || !root.widgetsConfig.widgets[key]) return
        var copy = JSON.parse(JSON.stringify(root.widgetsConfig))
        copy.widgets[key].enabled = val
        root.widgetsConfig = copy
        root.isDirty = true
    }

    function updateWidgetOption(key, prop, val) {
        if (!root.widgetsConfig || !root.widgetsConfig.widgets || !root.widgetsConfig.widgets[key]) return
        var copy = JSON.parse(JSON.stringify(root.widgetsConfig))
        copy.widgets[key][prop] = val
        root.widgetsConfig = copy
        root.isDirty = true
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // ═════════════════════════════════════════════════════════════════════
        // LEFT COLUMN: Interactive WYSIWYG Desktop Canvas
        // ═════════════════════════════════════════════════════════════════════
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                // Canvas Header
                RowLayout {
                    Layout.fillWidth: true

                    Row {
                        spacing: 8
                        Layout.alignment: Qt.AlignVCenter

                        Image {
                            width: 16; height: 16
                            source: root.moveSvg
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "DESKTOP CANVAS (DRAG & RESIZE)"
                            color: Theme.alpha(Theme.foreground, 0.85)
                            font.family: "Outfit"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            font.letterSpacing: 0.8
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Reset Positions Button
                    Rectangle {
                        width: resetBtnText.implicitWidth + 16
                        height: 24
                        radius: 12
                        color: resetMouse.containsMouse ? Theme.alpha(Theme.surface, 0.95) : Theme.alpha(Theme.surface, 0.60)
                        border.width: 1
                        border.color: Theme.alpha(Theme.foreground, 0.12)

                        Text {
                            id: resetBtnText
                            anchors.centerIn: parent
                            text: "Reset Layout"
                            color: Theme.alpha(Theme.foreground, 0.80)
                            font.family: "Outfit"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: resetMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var copy = JSON.parse(JSON.stringify(root.widgetsConfig))
                                if (copy.widgets.clock) { copy.widgets.clock.x = 0.50; copy.widgets.clock.y = 0.28; copy.widgets.clock.scale = 1.0; }
                                if (copy.widgets.visualizer) { copy.widgets.visualizer.x = 0.50; copy.widgets.visualizer.y = 0.74; copy.widgets.visualizer.scale = 1.0; }
                                if (copy.widgets.system_monitor) { copy.widgets.system_monitor.x = 0.84; copy.widgets.system_monitor.y = 0.34; copy.widgets.system_monitor.scale = 1.0; }
                                if (copy.widgets.audio_player) { copy.widgets.audio_player.x = 0.16; copy.widgets.audio_player.y = 0.34; copy.widgets.audio_player.scale = 1.0; }
                                if (copy.widgets.weather) { copy.widgets.weather.x = 0.16; copy.widgets.weather.y = 0.65; copy.widgets.weather.scale = 1.0; }
                                root.widgetsConfig = copy
                                root.isDirty = true
                            }
                        }
                    }
                }

                // 16:9 Desktop Preview Area Container
                Item {
                    id: canvasWrapper
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Rectangle {
                        id: previewContainer
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height * 16.0 / 9.0)
                        height: width * 9.0 / 16.0
                        radius: 16
                        color: Theme.alpha(Theme.surface, 0.55)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.30)
                        clip: true

                        // Scaled Real Wallpaper
                        Image {
                            id: previewWallpaper
                            anchors.fill: parent
                            source: window.wallpaperPath
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                        }

                        // Subtle Grid Overlay (Crosshairs & Alignment Guides)
                        Item {
                            anchors.fill: parent
                            opacity: 0.18

                            // Center Vertical Line
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 1
                                height: parent.height
                                color: Theme.accent
                            }
                            // Center Horizontal Line
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                height: 1
                                width: parent.width
                                color: Theme.accent
                            }
                        }

                        // Freeform Interactive Canvas Area
                        Item {
                            id: previewCanvas
                            anchors.fill: parent
                            readonly property real canvasScale: Math.max(0.1, previewCanvas.width / 1920.0)

                            // 1. Clock Widget
                            ResizableDraggableWidget {
                                moduleKey: "clock"
                                title: "Clock"
                                readonly property var cfg: (root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.clock) ? root.widgetsConfig.widgets.clock : null
                                visible: cfg ? (cfg.enabled !== false) : false
                                normX: cfg ? cfg.x : 0.50
                                normY: cfg ? cfg.y : 0.28
                                widgetScale: cfg && cfg.scale ? cfg.scale : 1.0
                                previewScale: previewCanvas.canvasScale
                                canvasWidth: previewCanvas.width
                                canvasHeight: previewCanvas.height
                                isSelected: root.selectedWidgetId === "clock"

                                onPositionDropped: function(nx, ny) { root.updateWidgetPosition("clock", nx, ny) }
                                onScaleModified: function(s) { root.updateWidgetScale("clock", s) }
                                onWidgetSelected: function(key) { root.selectedWidgetId = "clock"; root.activeTab = 1 }

                                DesktopClock {
                                    editMode: true
                                    widgetConfig: parent.cfg || ({})
                                }
                            }

                            // 2. Audio Visualizer Widget
                            ResizableDraggableWidget {
                                moduleKey: "visualizer"
                                title: "Visualizer"
                                readonly property var cfg: (root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.visualizer) ? root.widgetsConfig.widgets.visualizer : null
                                visible: cfg ? (cfg.enabled !== false) : false
                                normX: cfg ? cfg.x : 0.50
                                normY: cfg ? cfg.y : 0.74
                                widgetScale: cfg && cfg.scale ? cfg.scale : 1.0
                                previewScale: previewCanvas.canvasScale
                                canvasWidth: previewCanvas.width
                                canvasHeight: previewCanvas.height
                                isSelected: root.selectedWidgetId === "visualizer"

                                onPositionDropped: function(nx, ny) { root.updateWidgetPosition("visualizer", nx, ny) }
                                onScaleModified: function(s) { root.updateWidgetScale("visualizer", s) }
                                onWidgetSelected: function(key) { root.selectedWidgetId = "visualizer"; root.activeTab = 1 }

                                DesktopVisualizer {
                                    editMode: true
                                    widgetConfig: parent.cfg || ({})
                                }
                            }

                            // 3. System Monitor Widget
                            ResizableDraggableWidget {
                                moduleKey: "system_monitor"
                                title: "System Monitor"
                                readonly property var cfg: (root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.system_monitor) ? root.widgetsConfig.widgets.system_monitor : null
                                visible: cfg ? (cfg.enabled !== false) : false
                                normX: cfg ? cfg.x : 0.84
                                normY: cfg ? cfg.y : 0.34
                                widgetScale: cfg && cfg.scale ? cfg.scale : 1.0
                                previewScale: previewCanvas.canvasScale
                                canvasWidth: previewCanvas.width
                                canvasHeight: previewCanvas.height
                                isSelected: root.selectedWidgetId === "system_monitor"

                                onPositionDropped: function(nx, ny) { root.updateWidgetPosition("system_monitor", nx, ny) }
                                onScaleModified: function(s) { root.updateWidgetScale("system_monitor", s) }
                                onWidgetSelected: function(key) { root.selectedWidgetId = "system_monitor"; root.activeTab = 1 }

                                DesktopSystemMonitor {
                                    editMode: true
                                    widgetConfig: parent.cfg || ({})
                                }
                            }

                            // 4. Audio Player Widget
                            ResizableDraggableWidget {
                                moduleKey: "audio_player"
                                title: "Audio Player"
                                readonly property var cfg: (root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.audio_player) ? root.widgetsConfig.widgets.audio_player : null
                                visible: cfg ? (cfg.enabled !== false) : false
                                normX: cfg ? cfg.x : 0.16
                                normY: cfg ? cfg.y : 0.34
                                widgetScale: cfg && cfg.scale ? cfg.scale : 1.0
                                previewScale: previewCanvas.canvasScale
                                canvasWidth: previewCanvas.width
                                canvasHeight: previewCanvas.height
                                isSelected: root.selectedWidgetId === "audio_player"

                                onPositionDropped: function(nx, ny) { root.updateWidgetPosition("audio_player", nx, ny) }
                                onScaleModified: function(s) { root.updateWidgetScale("audio_player", s) }
                                onWidgetSelected: function(key) { root.selectedWidgetId = "audio_player"; root.activeTab = 1 }

                                DesktopAudioPlayer {
                                    editMode: true
                                    widgetConfig: parent.cfg || ({})
                                }
                            }

                            // 5. Weather Forecast Widget
                            ResizableDraggableWidget {
                                moduleKey: "weather"
                                title: "Weather"
                                readonly property var cfg: (root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.weather) ? root.widgetsConfig.widgets.weather : null
                                visible: cfg ? (cfg.enabled !== false) : false
                                normX: cfg ? cfg.x : 0.16
                                normY: cfg ? cfg.y : 0.65
                                widgetScale: cfg && cfg.scale ? cfg.scale : 1.0
                                previewScale: previewCanvas.canvasScale
                                canvasWidth: previewCanvas.width
                                canvasHeight: previewCanvas.height
                                isSelected: root.selectedWidgetId === "weather"

                                onPositionDropped: function(nx, ny) { root.updateWidgetPosition("weather", nx, ny) }
                                onScaleModified: function(s) { root.updateWidgetScale("weather", s) }
                                onWidgetSelected: function(key) { root.selectedWidgetId = "weather"; root.activeTab = 1 }

                                DesktopWeather {
                                    editMode: true
                                    widgetConfig: parent.cfg || ({})
                                }
                            }
                        }
                    }
                }
            }
        }

        // ═════════════════════════════════════════════════════════════════════
        // RIGHT COLUMN: Widget Library & Customizer Inspector
        // ═════════════════════════════════════════════════════════════════════
        Item {
            Layout.preferredWidth: 420
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 12

                // Top Tab Switcher (Library / Properties / Global)
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 20
                    color: Theme.alpha(Theme.surface, 0.70)
                    border.width: 1
                    border.color: Theme.alpha(Theme.foreground, 0.10)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 4

                        // Tab 0: Library
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 17
                            color: root.activeTab === 0 ? Theme.accent : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                Image {
                                    width: 14; height: 14
                                    source: root.tabLibrarySvg(root.activeTab === 0)
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "Library"
                                    color: root.activeTab === 0 ? Theme.on_primary : Theme.foreground
                                    font.family: "Outfit"
                                    font.pixelSize: 12
                                    font.weight: root.activeTab === 0 ? Font.Bold : Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeTab = 0
                            }
                        }

                        // Tab 1: Properties
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 17
                            color: root.activeTab === 1 ? Theme.accent : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                Image {
                                    width: 14; height: 14
                                    source: root.tabCustomizerSvg(root.activeTab === 1)
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "Customizer"
                                    color: root.activeTab === 1 ? Theme.on_primary : Theme.foreground
                                    font.family: "Outfit"
                                    font.pixelSize: 12
                                    font.weight: root.activeTab === 1 ? Font.Bold : Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeTab = 1
                            }
                        }

                        // Tab 2: Global
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 17
                            color: root.activeTab === 2 ? Theme.accent : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                Image {
                                    width: 14; height: 14
                                    source: root.tabGlobalSvg(root.activeTab === 2)
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "Global"
                                    color: root.activeTab === 2 ? Theme.on_primary : Theme.foreground
                                    font.family: "Outfit"
                                    font.pixelSize: 12
                                    font.weight: root.activeTab === 2 ? Font.Bold : Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeTab = 2
                            }
                        }
                    }
                }

                // Scrollable Content Inspector
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: inspectorColumn.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: inspectorColumn
                        width: parent.width
                        spacing: 12

                        // ─────────────────────────────────────────────────────
                        // TAB 0: WIDGET LIBRARY
                        // ─────────────────────────────────────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            visible: root.activeTab === 0

                            // 1. Clock Card
                            Rectangle {
                                Layout.fillWidth: true
                                height: 72
                                radius: 14
                                color: Theme.alpha(Theme.surface, 0.75)
                                border.width: 1
                                border.color: root.selectedWidgetId === "clock" ? Theme.accent : Theme.alpha(Theme.foreground, 0.10)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12

                                    Image {
                                        width: 24; height: 24
                                        source: root.clockSvg
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            text: "Desktop Clock"
                                            color: Theme.foreground
                                            font.family: "Outfit"
                                            font.pixelSize: 13
                                            font.weight: Font.Bold
                                        }
                                        Text {
                                            text: "Large bold typography, date & greeting"
                                            color: Theme.alpha(Theme.foreground, 0.55)
                                            font.family: "Outfit"
                                            font.pixelSize: 10
                                        }
                                    }

                                    CapsuleSwitch {
                                        id: swClock
                                        checked: Boolean(root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.clock && root.widgetsConfig.widgets.clock.enabled !== false)
                                        onToggled: {
                                            root.setWidgetEnabled("clock", swClock.checked)
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.rightMargin: 60
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectedWidgetId = "clock"
                                        root.activeTab = 1
                                    }
                                }
                            }

                            // 2. Visualizer Card
                            Rectangle {
                                Layout.fillWidth: true
                                height: 72
                                radius: 14
                                color: Theme.alpha(Theme.surface, 0.75)
                                border.width: 1
                                border.color: root.selectedWidgetId === "visualizer" ? Theme.accent : Theme.alpha(Theme.foreground, 0.10)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12

                                    Image {
                                        width: 24; height: 24
                                        source: root.waveSvg
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            text: "Audio Visualizer"
                                            color: Theme.foreground
                                            font.family: "Outfit"
                                            font.pixelSize: 13
                                            font.weight: Font.Bold
                                        }
                                        Text {
                                            text: "CAVA kinetic audio spectrum bars"
                                            color: Theme.alpha(Theme.foreground, 0.55)
                                            font.family: "Outfit"
                                            font.pixelSize: 10
                                        }
                                    }

                                    CapsuleSwitch {
                                        id: swVisualizer
                                        checked: Boolean(root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.visualizer && root.widgetsConfig.widgets.visualizer.enabled !== false)
                                        onToggled: {
                                            root.setWidgetEnabled("visualizer", swVisualizer.checked)
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.rightMargin: 60
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectedWidgetId = "visualizer"
                                        root.activeTab = 1
                                    }
                                }
                            }

                            // 3. System Monitor Card
                            Rectangle {
                                Layout.fillWidth: true
                                height: 72
                                radius: 14
                                color: Theme.alpha(Theme.surface, 0.75)
                                border.width: 1
                                border.color: root.selectedWidgetId === "system_monitor" ? Theme.accent : Theme.alpha(Theme.foreground, 0.10)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12

                                    Image {
                                        width: 24; height: 24
                                        source: root.cpuSvg
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            text: "System Monitor"
                                            color: Theme.foreground
                                            font.family: "Outfit"
                                            font.pixelSize: 13
                                            font.weight: Font.Bold
                                        }
                                        Text {
                                            text: "CPU, RAM, Usable Storage & Temp gauges"
                                            color: Theme.alpha(Theme.foreground, 0.55)
                                            font.family: "Outfit"
                                            font.pixelSize: 10
                                        }
                                    }

                                    CapsuleSwitch {
                                        id: swSysMon
                                        checked: Boolean(root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.system_monitor && root.widgetsConfig.widgets.system_monitor.enabled !== false)
                                        onToggled: {
                                            root.setWidgetEnabled("system_monitor", swSysMon.checked)
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.rightMargin: 60
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectedWidgetId = "system_monitor"
                                        root.activeTab = 1
                                    }
                                }
                            }

                            // 4. Audio Player Card
                            Rectangle {
                                Layout.fillWidth: true
                                height: 72
                                radius: 14
                                color: Theme.alpha(Theme.surface, 0.75)
                                border.width: 1
                                border.color: root.selectedWidgetId === "audio_player" ? Theme.accent : Theme.alpha(Theme.foreground, 0.10)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12

                                    Image {
                                        width: 24; height: 24
                                        source: root.musicSvg
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            text: "Audio Player"
                                            color: Theme.foreground
                                            font.family: "Outfit"
                                            font.pixelSize: 13
                                            font.weight: Font.Bold
                                        }
                                        Text {
                                            text: "Album artwork, track info & transport controls"
                                            color: Theme.alpha(Theme.foreground, 0.55)
                                            font.family: "Outfit"
                                            font.pixelSize: 10
                                        }
                                    }

                                    CapsuleSwitch {
                                        id: swAudioPlayer
                                        checked: Boolean(root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.audio_player && root.widgetsConfig.widgets.audio_player.enabled !== false)
                                        onToggled: {
                                            root.setWidgetEnabled("audio_player", swAudioPlayer.checked)
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.rightMargin: 60
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectedWidgetId = "audio_player"
                                        root.activeTab = 1
                                    }
                                }
                            }

                            // 5. Weather Forecast Card
                            Rectangle {
                                Layout.fillWidth: true
                                height: 72
                                radius: 14
                                color: Theme.alpha(Theme.surface, 0.75)
                                border.width: 1
                                border.color: root.selectedWidgetId === "weather" ? Theme.accent : Theme.alpha(Theme.foreground, 0.10)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12

                                    Image {
                                        width: 24; height: 24
                                        source: root.weatherSvg
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            text: "Weather Forecast"
                                            color: Theme.foreground
                                            font.family: "Outfit"
                                            font.pixelSize: 13
                                            font.weight: Font.Bold
                                        }
                                        Text {
                                            text: "Live condition icon, temperature, humidity & wind"
                                            color: Theme.alpha(Theme.foreground, 0.55)
                                            font.family: "Outfit"
                                            font.pixelSize: 10
                                        }
                                    }

                                    CapsuleSwitch {
                                        id: swWeather
                                        checked: Boolean(root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.weather && root.widgetsConfig.widgets.weather.enabled !== false)
                                        onToggled: {
                                            root.setWidgetEnabled("weather", swWeather.checked)
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.rightMargin: 60
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectedWidgetId = "weather"
                                        root.activeTab = 1
                                    }
                                }
                            }
                        }

                        // ─────────────────────────────────────────────────────
                        // TAB 1: PROPERTIES (SELECTED WIDGET CUSTOMIZER)
                        // ─────────────────────────────────────────────────────
                        ColumnLayout {
                            id: customizerTab
                            Layout.fillWidth: true
                            spacing: 12
                            visible: root.activeTab === 1

                            readonly property var activeCfg: (root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets[root.selectedWidgetId])
                                ? root.widgetsConfig.widgets[root.selectedWidgetId]
                                : null

                            // Header Badge
                            Rectangle {
                                Layout.fillWidth: true
                                height: 38
                                radius: 12
                                color: Theme.alpha(Theme.accent, 0.15)
                                border.width: 1
                                border.color: Theme.alpha(Theme.accent, 0.35)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12

                                    Text {
                                        text: (customizerTab.activeCfg ? customizerTab.activeCfg.title : "Widget")
                                        color: Theme.accent
                                        font.family: "Outfit"
                                        font.pixelSize: 13
                                        font.weight: Font.Bold
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: "Active"
                                        color: Theme.alpha(Theme.foreground, 0.65)
                                        font.family: "Outfit"
                                        font.pixelSize: 10
                                        font.weight: Font.Medium
                                    }
                                }
                            }

                            // 1. Size & Scale Card
                            SettingCard {
                                Layout.fillWidth: true
                                title: "Size & Scale"
                                description: "Resize widget smoothly across desktop"

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: "Scale Factor"
                                            color: Theme.alpha(Theme.foreground, 0.70)
                                            font.family: "Outfit"
                                            font.pixelSize: 11
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: ((customizerTab.activeCfg && customizerTab.activeCfg.scale !== undefined) ? customizerTab.activeCfg.scale.toFixed(2) : "1.00") + "x"
                                            color: Theme.accent
                                            font.family: "Outfit"
                                            font.pixelSize: 11
                                            font.weight: Font.Bold
                                        }
                                    }

                                    ModernSlider {
                                        Layout.fillWidth: true
                                        from: 0.60
                                        to: 1.80
                                        value: (customizerTab.activeCfg && customizerTab.activeCfg.scale !== undefined) ? customizerTab.activeCfg.scale : 1.0
                                        onMoved: function() {
                                            root.updateWidgetScale(root.selectedWidgetId, value)
                                        }
                                    }

                                    // Quick Preset Scale Pills
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Repeater {
                                            model: [
                                                { label: "0.8x", scale: 0.8 },
                                                { label: "1.0x", scale: 1.0 },
                                                { label: "1.2x", scale: 1.2 },
                                                { label: "1.4x", scale: 1.4 }
                                            ]

                                            Rectangle {
                                                Layout.fillWidth: true
                                                height: 24
                                                radius: 12
                                                color: (customizerTab.activeCfg && Math.abs(customizerTab.activeCfg.scale - modelData.scale) < 0.05)
                                                    ? Theme.accent
                                                    : Theme.alpha(Theme.surface, 0.85)
                                                border.width: 1
                                                border.color: Theme.alpha(Theme.foreground, 0.10)

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.label
                                                    color: (customizerTab.activeCfg && Math.abs(customizerTab.activeCfg.scale - modelData.scale) < 0.05)
                                                        ? Theme.on_primary
                                                        : Theme.foreground
                                                    font.family: "Outfit"
                                                    font.pixelSize: 10
                                                    font.weight: Font.Medium
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.updateWidgetScale(root.selectedWidgetId, modelData.scale)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Widget Appearance / Background Card
                            SettingCard {
                                Layout.fillWidth: true
                                title: "Widget Appearance"
                                description: "Configure background container surface"

                                RowLayout {
                                    Layout.fillWidth: true
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            text: "Glass Background Card"
                                            color: Theme.foreground
                                            font.family: "Outfit"
                                            font.pixelSize: 11
                                            font.weight: Font.Medium
                                        }
                                        Text {
                                            text: "Toggle frosted obsidian container frame"
                                            color: Theme.alpha(Theme.foreground, 0.50)
                                            font.family: "Outfit"
                                            font.pixelSize: 9
                                        }
                                    }
                                    CapsuleSwitch {
                                        id: optShowBg
                                        checked: Boolean(!customizerTab.activeCfg || customizerTab.activeCfg.show_background !== false)
                                        onToggled: root.updateWidgetOption(root.selectedWidgetId, "show_background", optShowBg.checked)
                                    }
                                }
                            }

                            // 2. Position Alignment Card
                            SettingCard {
                                Layout.fillWidth: true
                                title: "Quick Alignment"
                                description: "Instantly place widget at key canvas anchors"

                                    Grid {
                                        width: parent.width
                                        columns: 3
                                        spacing: 6

                                        Repeater {
                                            model: [
                                                { label: "Top Left", x: 0.16, y: 0.20 },
                                                { label: "Top Center", x: 0.50, y: 0.20 },
                                                { label: "Top Right", x: 0.84, y: 0.20 },
                                                { label: "Mid Left", x: 0.16, y: 0.50 },
                                                { label: "Center", x: 0.50, y: 0.50 },
                                                { label: "Mid Right", x: 0.84, y: 0.50 },
                                                { label: "Bottom Left", x: 0.16, y: 0.80 },
                                                { label: "Bottom Center", x: 0.50, y: 0.78 },
                                                { label: "Bottom Right", x: 0.84, y: 0.80 }
                                            ]

                                            Rectangle {
                                                width: Math.floor((parent.width - 12) / 3)
                                                height: 28
                                                radius: 8
                                                color: alignMouse.containsMouse ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surface, 0.85)
                                                border.width: 1
                                                border.color: Theme.alpha(Theme.foreground, 0.10)

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.label
                                                    color: Theme.foreground
                                                    font.family: "Outfit"
                                                    font.pixelSize: 10
                                                    font.weight: Font.Medium
                                                }

                                                MouseArea {
                                                    id: alignMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.updateWidgetPosition(root.selectedWidgetId, modelData.x, modelData.y)
                                                }
                                            }
                                        }
                                    }
                            }

                            // 3. Widget Specific Options Card
                            SettingCard {
                                Layout.fillWidth: true
                                title: "Widget Configuration"
                                description: "Fine-tune display options"

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    // Clock Options
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        visible: root.selectedWidgetId === "clock"

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "24-Hour Format"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 11 }
                                            Item { Layout.fillWidth: true }
                                            CapsuleSwitch {
                                                id: optClock24h
                                                checked: Boolean(customizerTab.activeCfg && customizerTab.activeCfg.format_24h)
                                                onToggled: root.updateWidgetOption("clock", "format_24h", optClock24h.checked)
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Show Seconds"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 11 }
                                            Item { Layout.fillWidth: true }
                                            CapsuleSwitch {
                                                id: optClockSec
                                                checked: Boolean(customizerTab.activeCfg && customizerTab.activeCfg.show_seconds)
                                                onToggled: root.updateWidgetOption("clock", "show_seconds", optClockSec.checked)
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Show Date"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 11 }
                                            Item { Layout.fillWidth: true }
                                            CapsuleSwitch {
                                                id: optClockDate
                                                checked: Boolean(customizerTab.activeCfg && customizerTab.activeCfg.show_date !== false)
                                                onToggled: root.updateWidgetOption("clock", "show_date", optClockDate.checked)
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Show Greeting Tag"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 11 }
                                            Item { Layout.fillWidth: true }
                                            CapsuleSwitch {
                                                id: optClockGreet
                                                checked: Boolean(customizerTab.activeCfg && customizerTab.activeCfg.show_greeting !== false)
                                                onToggled: root.updateWidgetOption("clock", "show_greeting", optClockGreet.checked)
                                            }
                                        }

                                        // Clock Font Family
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text {
                                                text: "Font Family"
                                                color: Theme.foreground
                                                font.family: "Outfit"
                                                font.pixelSize: 11
                                            }
                                            Item { Layout.fillWidth: true }
                                            ModernDropdown {
                                                implicitWidth: 170
                                                implicitHeight: 30
                                                model: ["Outfit", "JetBrainsMono Nerd Font", "Cascadia Code", "DejaVu Sans", "DejaVu Sans Mono"]
                                                currentValue: (customizerTab.activeCfg && customizerTab.activeCfg.font_family) ? customizerTab.activeCfg.font_family : "Outfit"
                                                onSelected: function(val) {
                                                    root.updateWidgetOption("clock", "font_family", val)
                                                }
                                            }
                                        }

                                        // Clock Font Size
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 4

                                            RowLayout {
                                                Layout.fillWidth: true
                                                Text {
                                                    text: "Clock Font Size"
                                                    color: Theme.foreground
                                                    font.family: "Outfit"
                                                    font.pixelSize: 11
                                                }
                                                Item { Layout.fillWidth: true }
                                                Text {
                                                    text: ((customizerTab.activeCfg && customizerTab.activeCfg.font_size !== undefined) ? customizerTab.activeCfg.font_size : 44) + " px"
                                                    color: Theme.accent
                                                    font.family: "Outfit"
                                                    font.pixelSize: 11
                                                    font.weight: Font.Bold
                                                }
                                            }

                                            ModernSlider {
                                                Layout.fillWidth: true
                                                from: 24
                                                to: 72
                                                stepSize: 1
                                                value: (customizerTab.activeCfg && customizerTab.activeCfg.font_size !== undefined) ? customizerTab.activeCfg.font_size : 44
                                                onMoved: function() {
                                                    root.updateWidgetOption("clock", "font_size", Math.round(value))
                                                }
                                            }

                                            // Quick Preset Font Sizes
                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 6

                                                Repeater {
                                                    model: [
                                                        { label: "32px", size: 32 },
                                                        { label: "44px", size: 44 },
                                                        { label: "56px", size: 56 },
                                                        { label: "68px", size: 68 }
                                                    ]

                                                    Rectangle {
                                                        Layout.fillWidth: true
                                                        height: 22
                                                        radius: 11
                                                        color: (customizerTab.activeCfg && customizerTab.activeCfg.font_size === modelData.size)
                                                            ? Theme.accent
                                                            : Theme.alpha(Theme.surface, 0.85)
                                                        border.width: 1
                                                        border.color: Theme.alpha(Theme.foreground, 0.10)

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: modelData.label
                                                            color: (customizerTab.activeCfg && customizerTab.activeCfg.font_size === modelData.size)
                                                                ? Theme.on_primary
                                                                : Theme.foreground
                                                            font.family: "Outfit"
                                                            font.pixelSize: 9
                                                            font.weight: Font.Medium
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: root.updateWidgetOption("clock", "font_size", modelData.size)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Visualizer Options
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        visible: root.selectedWidgetId === "visualizer"

                                        // Pattern Information Badge
                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 28
                                            radius: 8
                                            color: Theme.alpha(Theme.accent, 0.12)
                                            border.width: 1
                                            border.color: Theme.alpha(Theme.accent, 0.28)

                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 6

                                                Image {
                                                    width: 13; height: 13
                                                    source: root.waveSvg
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }

                                                Text {
                                                    text: "Harmonic Pattern: aabbccccbbaa"
                                                    color: Theme.accent
                                                    font.family: "Outfit"
                                                    font.pixelSize: 10
                                                    font.weight: Font.Bold
                                                    font.letterSpacing: 0.8
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Spectrum Bar Count"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 11 }
                                            Item { Layout.fillWidth: true }
                                            Text {
                                                text: ((customizerTab.activeCfg && customizerTab.activeCfg.bar_count !== undefined) ? customizerTab.activeCfg.bar_count : 12) + " Bars"
                                                color: Theme.accent
                                                font.family: "Outfit"
                                                font.pixelSize: 11
                                                font.weight: Font.Bold
                                            }
                                        }

                                        ModernSlider {
                                            Layout.fillWidth: true
                                            from: 12
                                            to: 36
                                            stepSize: 12
                                            value: (customizerTab.activeCfg && customizerTab.activeCfg.bar_count !== undefined) ? customizerTab.activeCfg.bar_count : 12
                                            onMoved: function() {
                                                root.updateWidgetOption("visualizer", "bar_count", Math.round(value))
                                            }
                                        }

                                        // Quick Presets (Multiples of 12)
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            Repeater {
                                                model: [
                                                    { label: "12 Bars", count: 12 },
                                                    { label: "24 Bars", count: 24 },
                                                    { label: "36 Bars", count: 36 }
                                                ]

                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    height: 24
                                                    radius: 12
                                                    color: (customizerTab.activeCfg && customizerTab.activeCfg.bar_count === modelData.count)
                                                        ? Theme.accent
                                                        : Theme.alpha(Theme.surface, 0.85)
                                                    border.width: 1
                                                    border.color: Theme.alpha(Theme.foreground, 0.10)

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: modelData.label
                                                        color: (customizerTab.activeCfg && customizerTab.activeCfg.bar_count === modelData.count)
                                                            ? Theme.on_primary
                                                            : Theme.foreground
                                                        font.family: "Outfit"
                                                        font.pixelSize: 9
                                                        font.weight: Font.Medium
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: root.updateWidgetOption("visualizer", "bar_count", modelData.count)
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // System Monitor Options
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        visible: root.selectedWidgetId === "system_monitor"

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Show CPU Usage"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 11 }
                                            Item { Layout.fillWidth: true }
                                            CapsuleSwitch {
                                                id: optSysCpu
                                                checked: Boolean(customizerTab.activeCfg && customizerTab.activeCfg.show_cpu !== false)
                                                onToggled: root.updateWidgetOption("system_monitor", "show_cpu", optSysCpu.checked)
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Show RAM Usage"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 11 }
                                            Item { Layout.fillWidth: true }
                                            CapsuleSwitch {
                                                id: optSysRam
                                                checked: Boolean(customizerTab.activeCfg && customizerTab.activeCfg.show_ram !== false)
                                                onToggled: root.updateWidgetOption("system_monitor", "show_ram", optSysRam.checked)
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Show Storage Usage"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 11 }
                                            Item { Layout.fillWidth: true }
                                            CapsuleSwitch {
                                                id: optSysDisk
                                                checked: Boolean(customizerTab.activeCfg && customizerTab.activeCfg.show_disk !== false)
                                                onToggled: root.updateWidgetOption("system_monitor", "show_disk", optSysDisk.checked)
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Show Temperature Badge"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 11 }
                                            Item { Layout.fillWidth: true }
                                            CapsuleSwitch {
                                                id: optSysTemp
                                                checked: Boolean(customizerTab.activeCfg && customizerTab.activeCfg.show_temp !== false)
                                                onToggled: root.updateWidgetOption("system_monitor", "show_temp", optSysTemp.checked)
                                            }
                                        }
                                    }

                                    // Audio Player Options
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        visible: root.selectedWidgetId === "audio_player"

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Compact Mode"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 11 }
                                            Item { Layout.fillWidth: true }
                                            CapsuleSwitch {
                                                id: optAudioCompact
                                                checked: Boolean(customizerTab.activeCfg && customizerTab.activeCfg.compact === true)
                                                onToggled: root.updateWidgetOption("audio_player", "compact", optAudioCompact.checked)
                                            }
                                        }
                                    }

                                    // Weather Options
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        visible: root.selectedWidgetId === "weather"

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Use Fahrenheit (°F)"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 11 }
                                            Item { Layout.fillWidth: true }
                                            CapsuleSwitch {
                                                id: optWeatherFahr
                                                checked: Boolean(customizerTab.activeCfg && (customizerTab.activeCfg.use_fahrenheit === true || customizerTab.activeCfg.unit === "F"))
                                                onToggled: {
                                                    root.updateWidgetOption("weather", "use_fahrenheit", optWeatherFahr.checked)
                                                    root.updateWidgetOption("weather", "unit", optWeatherFahr.checked ? "F" : "C")
                                                }
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Show Location Name"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 11 }
                                            Item { Layout.fillWidth: true }
                                            CapsuleSwitch {
                                                id: optWeatherLoc
                                                checked: Boolean(!customizerTab.activeCfg || customizerTab.activeCfg.show_location !== false)
                                                onToggled: root.updateWidgetOption("weather", "show_location", optWeatherLoc.checked)
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Show Atmospheric Details"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 11 }
                                            Item { Layout.fillWidth: true }
                                            CapsuleSwitch {
                                                id: optWeatherDetails
                                                checked: Boolean(!customizerTab.activeCfg || customizerTab.activeCfg.show_details !== false)
                                                onToggled: root.updateWidgetOption("weather", "show_details", optWeatherDetails.checked)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ─────────────────────────────────────────────────────
                        // TAB 2: GLOBAL DESKTOP WIDGET SETTINGS
                        // ─────────────────────────────────────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            visible: root.activeTab === 2

                            SettingCard {
                                Layout.fillWidth: true
                                title: "Master Toggle"
                                description: "Enable or disable all desktop widgets"

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Desktop Widgets Layer"
                                        color: Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 12
                                    }
                                    Item { Layout.fillWidth: true }
                                    CapsuleSwitch {
                                        id: swMasterWidgets
                                        checked: Boolean(root.widgetsConfig && root.widgetsConfig.enabled !== false)
                                        onToggled: {
                                            var copy = JSON.parse(JSON.stringify(root.widgetsConfig))
                                            copy.enabled = swMasterWidgets.checked
                                            root.widgetsConfig = copy
                                            root.isDirty = true
                                        }
                                    }
                                }
                            }

                            SettingCard {
                                Layout.fillWidth: true
                                title: "Global Backgrounds"
                                description: "Toggle glass backdrops for all widgets simultaneously"

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "All Widget Glass Frames"
                                        color: Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 12
                                    }
                                    Item { Layout.fillWidth: true }
                                    CapsuleSwitch {
                                        id: swGlobalBg
                                        checked: {
                                            if (!root.widgetsConfig || !root.widgetsConfig.widgets) return true
                                            var w = root.widgetsConfig.widgets
                                            for (var k in w) {
                                                if (w[k].show_background === false) return false
                                            }
                                            return true
                                        }
                                        onToggled: {
                                            var copy = JSON.parse(JSON.stringify(root.widgetsConfig))
                                            for (var k in copy.widgets) {
                                                copy.widgets[k].show_background = swGlobalBg.checked
                                            }
                                            root.widgetsConfig = copy
                                            root.isDirty = true
                                        }
                                    }
                                }
                            }

                            SettingCard {
                                Layout.fillWidth: true
                                title: "Daemon Management"
                                description: "Control background desktop widget process"

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 32
                                        radius: 16
                                        color: Theme.alpha(Theme.surface, 0.85)
                                        border.width: 1
                                        border.color: Theme.alpha(Theme.foreground, 0.12)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Restart Desktop Widgets Daemon"
                                            color: Theme.accent
                                            font.family: "Outfit"
                                            font.pixelSize: 11
                                            font.weight: Font.Bold
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.saveWidgetsConfig()
                                                daemonRestartProc.running = false
                                                daemonRestartProc.command = ["bash", "-c", "$HOME/.hyprconf/hypr/scripts/sh/qs-widgets.sh --restart"]
                                                daemonRestartProc.running = true
                                            }
                                        }
                                    }
                                }
                            }

                            Process {
                                id: daemonRestartProc
                            }
                        }
                    }
                }

                // ═════════════════════════════════════════════════════════════
                // BOTTOM BAR: Apply & Save Action Button
                // ═════════════════════════════════════════════════════════════
                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 22
                    color: root.isDirty ? Theme.accent : Theme.alpha(Theme.surface, 0.70)
                    border.width: 1
                    border.color: root.isDirty ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)

                    Behavior on color { ColorAnimation { duration: 160 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16; height: 16
                            source: root.checkSvg
                            visible: root.isDirty
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.isDirty ? "Apply & Save to Desktop" : "Desktop Widgets Synced"
                            color: root.isDirty ? Theme.on_primary : Theme.alpha(Theme.foreground, 0.55)
                            font.family: "Outfit"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            font.letterSpacing: 0.5
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: root.isDirty ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (root.isDirty) {
                                root.saveWidgetsConfig()
                            }
                        }
                    }
                }
            }
        }
    }
}
