//@ pragma Env QS_NO_RELOAD_POPUP=1
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "."

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : "/home/shell-ninja"
    }

    readonly property string configPath: homeDir + "/.hyprconf/quickshell/widgets/widgets.json"
    property var widgetsConfig: ({})

    // Load widgets configuration
    Process {
        id: configLoader
        command: ["python3", "-c", "import json, os; p=os.path.expanduser('~/.hyprconf/quickshell/widgets/widgets.json'); print(open(p, encoding='utf-8').read() if os.path.exists(p) else '{}')"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    root.widgetsConfig = JSON.parse(text.trim())
                } catch(e) {
                    console.log("[Widgets] Error parsing widgets.json:", e)
                }
            }
        }
    }

    function reloadConfig() {
        configLoader.running = false
        configLoader.running = true
    }

    // Native IPC Handler
    IpcHandler {
        target: "widgets"
        function reloadConfig() {
            root.reloadConfig()
        }
        function toggle() {
            if (root.widgetsConfig) {
                root.widgetsConfig.enabled = !root.widgetsConfig.enabled
            }
        }
    }

    // Desktop Widgets Container
    Item {
        id: widgetsCanvas
        anchors.fill: parent
        visible: root.widgetsConfig ? (root.widgetsConfig.enabled !== false) : true

        // 1. Clock Widget
        DesktopClock {
            id: clockWidget
            readonly property var cfg: (root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.clock) ? root.widgetsConfig.widgets.clock : null
            visible: cfg ? (cfg.enabled !== false) : false
            widgetConfig: cfg || ({})
            scale: cfg && cfg.scale ? cfg.scale : 1.0
            transformOrigin: Item.Center

            x: cfg ? Math.round(cfg.x * root.width - width / 2) : 100
            y: cfg ? Math.round(cfg.y * root.height - height / 2) : 100
        }

        // 2. Audio Visualizer Widget
        DesktopVisualizer {
            id: visualizerWidget
            readonly property var cfg: (root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.visualizer) ? root.widgetsConfig.widgets.visualizer : null
            visible: cfg ? (cfg.enabled !== false) : false
            widgetConfig: cfg || ({})
            scale: cfg && cfg.scale ? cfg.scale : 1.0
            transformOrigin: Item.Center

            x: cfg ? Math.round(cfg.x * root.width - width / 2) : 100
            y: cfg ? Math.round(cfg.y * root.height - height / 2) : 300
        }

        // 3. System Monitor Widget
        DesktopSystemMonitor {
            id: systemMonitorWidget
            readonly property var cfg: (root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.system_monitor) ? root.widgetsConfig.widgets.system_monitor : null
            visible: cfg ? (cfg.enabled !== false) : false
            widgetConfig: cfg || ({})
            scale: cfg && cfg.scale ? cfg.scale : 1.0
            transformOrigin: Item.Center

            x: cfg ? Math.round(cfg.x * root.width - width / 2) : 500
            y: cfg ? Math.round(cfg.y * root.height - height / 2) : 100
        }

        // 4. Audio Player Widget
        DesktopAudioPlayer {
            id: audioPlayerWidget
            readonly property var cfg: (root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.audio_player) ? root.widgetsConfig.widgets.audio_player : null
            visible: cfg ? (cfg.enabled !== false) : false
            widgetConfig: cfg || ({})
            scale: cfg && cfg.scale ? cfg.scale : 1.0
            transformOrigin: Item.Center

            x: cfg ? Math.round(cfg.x * root.width - width / 2) : 100
            y: cfg ? Math.round(cfg.y * root.height - height / 2) : 500
        }

        // 5. Weather Widget
        DesktopWeather {
            id: weatherWidget
            readonly property var cfg: (root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.weather) ? root.widgetsConfig.widgets.weather : null
            visible: cfg ? (cfg.enabled !== false) : false
            widgetConfig: cfg || ({})
            scale: cfg && cfg.scale ? cfg.scale : 1.0
            transformOrigin: Item.Center

            x: cfg ? Math.round(cfg.x * root.width - width / 2) : 100
            y: cfg ? Math.round(cfg.y * root.height - height / 2) : 650
        }
    }
}
