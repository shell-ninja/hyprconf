//@ pragma Env QS_NO_RELOAD_POPUP=1
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "."

Scope {
    id: root

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    readonly property string userConfigPath: homeDir + "/.local/share/hyprconf/widgets.json"
    readonly property string fallbackConfigPath: homeDir + "/.hyprconf/quickshell/widgets/widgets.json"
    property bool usingFallbackConfig: false
    property var widgetsConfig: ({})

    function parseWidgetsText(txt) {
        if (!txt || txt.trim().length === 0) return
        try {
            root.widgetsConfig = JSON.parse(txt.trim())
        } catch(e) {
            console.log("[Widgets] Error parsing widgets.json:", e)
        }
    }

    // Zero-fork reactive config reader via native FileView
    FileView {
        id: configFileView
        path: root.userConfigPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            root.usingFallbackConfig = false
            root.parseWidgetsText(text())
        }
        onLoadFailed: {
            root.usingFallbackConfig = true
            fallbackFileView.reload()
        }
    }

    FileView {
        id: fallbackFileView
        path: root.fallbackConfigPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            if (root.usingFallbackConfig) root.parseWidgetsText(text())
        }
    }

    function reloadConfig() {
        configFileView.reload()
        if (root.usingFallbackConfig) fallbackFileView.reload()
    }

    // Native IPC Handler
    IpcHandler {
        target: "widgets"
        function reloadConfig() {
            root.reloadConfig()
        }
        function setConfig(jsonStr: string) {
            if (jsonStr && jsonStr.length > 0) {
                try {
                    root.widgetsConfig = JSON.parse(jsonStr)
                } catch(e) {
                    console.log("[Widgets] Error parsing setConfig JSON:", e)
                }
            }
        }
        function toggle() {
            if (root.widgetsConfig) {
                var copy = JSON.parse(JSON.stringify(root.widgetsConfig))
                copy.enabled = !copy.enabled
                root.widgetsConfig = copy
            }
        }
        function disable() {
            if (root.widgetsConfig) {
                var copy = JSON.parse(JSON.stringify(root.widgetsConfig))
                copy.enabled = false
                root.widgetsConfig = copy
            }
        }
        function enable() {
            if (root.widgetsConfig) {
                var copy = JSON.parse(JSON.stringify(root.widgetsConfig))
                copy.enabled = true
                root.widgetsConfig = copy
            }
        }
    }

    readonly property bool layerActive: Boolean(root.widgetsConfig && root.widgetsConfig.enabled === true)

    Loader {
        id: widgetsWinLoader
        active: root.layerActive
        sourceComponent: Component {
            PanelWindow {
                id: win

                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true
                color: "transparent"

                Item {
                    id: widgetsCanvas
                    anchors.fill: parent

                    // 1. Clock Widget (lazy-loaded)
                    Loader {
                        readonly property var cfg: (root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.clock) ? root.widgetsConfig.widgets.clock : null
                        active: Boolean(cfg && cfg.enabled !== false)
                        visible: active
                        sourceComponent: Component {
                            DesktopClock {
                                readonly property var cfg: (root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.clock) ? root.widgetsConfig.widgets.clock : null
                                widgetConfig: cfg || ({})
                                scale: cfg && cfg.scale ? cfg.scale : 1.0
                                transformOrigin: Item.Center
                                x: cfg ? Math.round(cfg.x * win.width - width / 2) : 100
                                y: cfg ? Math.round(cfg.y * win.height - height / 2) : 100
                            }
                        }
                    }

                    // 2. Audio Visualizer Widget (lazy-loaded)
                    Loader {
                        readonly property var cfg: (root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.visualizer) ? root.widgetsConfig.widgets.visualizer : null
                        active: Boolean(cfg && cfg.enabled !== false)
                        visible: active
                        sourceComponent: Component {
                            DesktopVisualizer {
                                readonly property var cfg: (root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.visualizer) ? root.widgetsConfig.widgets.visualizer : null
                                widgetConfig: cfg || ({})
                                scale: cfg && cfg.scale ? cfg.scale : 1.0
                                transformOrigin: Item.Center
                                x: cfg ? Math.round(cfg.x * win.width - width / 2) : 100
                                y: cfg ? Math.round(cfg.y * win.height - height / 2) : 300
                            }
                        }
                    }

                    // 3. System Monitor Widget (lazy-loaded)
                    Loader {
                        readonly property var cfg: (root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.system_monitor) ? root.widgetsConfig.widgets.system_monitor : null
                        active: Boolean(cfg && cfg.enabled !== false)
                        visible: active
                        sourceComponent: Component {
                            DesktopSystemMonitor {
                                readonly property var cfg: (root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.system_monitor) ? root.widgetsConfig.widgets.system_monitor : null
                                widgetConfig: cfg || ({})
                                scale: cfg && cfg.scale ? cfg.scale : 1.0
                                transformOrigin: Item.Center
                                x: cfg ? Math.round(cfg.x * win.width - width / 2) : 500
                                y: cfg ? Math.round(cfg.y * win.height - height / 2) : 100
                            }
                        }
                    }

                    // 4. Audio Player Widget (lazy-loaded)
                    Loader {
                        readonly property var cfg: (root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.audio_player) ? root.widgetsConfig.widgets.audio_player : null
                        active: Boolean(cfg && cfg.enabled !== false)
                        visible: active
                        sourceComponent: Component {
                            DesktopAudioPlayer {
                                readonly property var cfg: (root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.audio_player) ? root.widgetsConfig.widgets.audio_player : null
                                widgetConfig: cfg || ({})
                                scale: cfg && cfg.scale ? cfg.scale : 1.0
                                transformOrigin: Item.Center
                                x: cfg ? Math.round(cfg.x * win.width - width / 2) : 100
                                y: cfg ? Math.round(cfg.y * win.height - height / 2) : 500
                            }
                        }
                    }

                    // 5. Weather Widget (lazy-loaded)
                    Loader {
                        readonly property var cfg: (root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.weather) ? root.widgetsConfig.widgets.weather : null
                        active: Boolean(cfg && cfg.enabled !== false)
                        visible: active
                        sourceComponent: Component {
                            DesktopWeather {
                                readonly property var cfg: (root.widgetsConfig && root.widgetsConfig.widgets && root.widgetsConfig.widgets.weather) ? root.widgetsConfig.widgets.weather : null
                                widgetConfig: cfg || ({})
                                scale: cfg && cfg.scale ? cfg.scale : 1.0
                                transformOrigin: Item.Center
                                x: cfg ? Math.round(cfg.x * win.width - width / 2) : 100
                                y: cfg ? Math.round(cfg.y * win.height - height / 2) : 650
                            }
                        }
                    }
                }
            }
        }
    }
}
