import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "."

Item {
    id: root
    anchors.fill: parent

    // ── Local State ─────────────────────────────────────────────────────────
    property bool isSaving: false
    property bool dockEnabled: true
    property string dockMode: "smart_hide"       // "always_on" | "auto_hide" | "smart_hide"
    property string dockPosition: "bottom"       // "bottom" | "top" | "left" | "right"
    property real dockBgOpacity: 0.85
    property int dockIconSize: 48
    property int dockPadding: 8
    property int dockCornerRadius: 22
    property string dockHoverEffect: "zoom"      // "zoom" | "lift" | "glow" | "subtle" | "none"
    property bool dockShowTooltips: true
    property int dockHideDelay: 350
    property bool dockShowLauncher: true
    property bool dockShowIndicators: true
    property bool dockBorderGlow: true
    property var pinnedApps: []

    // Search and add app modal
    property bool showAddAppDialog: false
    property string appSearchQuery: ""
    property var allAppsList: []

    // ── SVG Helpers ─────────────────────────────────────────────────────────
    function svgUrl(svgString) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgString)
    }

    readonly property string pinSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="17" x2="12" y2="22"/><path d="M5 17h14v-1.76a2 2 0 0 0-1.11-1.79l-1.78-.9A2 2 0 0 1 15 10.76V6h1a1 1 0 0 0 1-1V3a1 1 0 0 0-1-1H8a1 1 0 0 0-1 1v2a1 1 0 0 0 1 1h1v4.76a2 2 0 0 1-1.11 1.79l-1.78.9A2 2 0 0 0 5 15.24Z"/></svg>')
    readonly property string unpinSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="2" y1="2" x2="22" y2="22"/><line x1="12" y1="17" x2="12" y2="22"/><path d="M9 9v1.76a2 2 0 0 1-1.11 1.79l-1.78.9A2 2 0 0 0 5 15.24V17h12"/><path d="M15 9.34V6h1a1 1 0 0 0 1-1V3a1 1 0 0 0-1-1H8"/></svg>')
    readonly property string windowSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="3"/><line x1="3" y1="9" x2="21" y2="9"/><line x1="9" y1="21" x2="9" y2="9"/></svg>')
    readonly property string trashSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.error + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>')
    readonly property string searchSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.alpha(Theme.foreground, 0.50) + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>')
    readonly property string closeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>')
    readonly property string checkSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>')
    readonly property string gridSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/></svg>')
    readonly property string upSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="18 15 12 9 6 15"/></svg>')
    readonly property string downSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg>')
    readonly property string plusSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>')

    // ── Load apps.json ──────────────────────────────────────────────────────
    Process {
        id: appsReader
        command: ["python3", "-c", "import json, os; p=os.path.expanduser('~/.hyprconf/hypr/.cache/apps.json'); print(open(p, encoding='utf-8').read() if os.path.exists(p) else '[]')"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    root.allAppsList = JSON.parse(text.trim())
                } catch(e) {
                    console.log("[DockSection] Error loading apps.json:", e)
                }
            }
        }
    }

    // ── Load dock.json ──────────────────────────────────────────────────────
    property bool isInitialized: false

    Process {
        id: dockReader
        command: ["python3", "-c", "import json, os; p=os.path.expanduser('~/.hyprconf/quickshell/dock/dock.json'); print(open(p, encoding='utf-8').read() if os.path.exists(p) else '{}')"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var data = JSON.parse(text.trim())
                    if (data.enabled !== undefined) root.dockEnabled = data.enabled
                    if (data.mode) root.dockMode = data.mode
                    if (data.position) root.dockPosition = data.position
                    if (data.bg_opacity !== undefined) root.dockBgOpacity = data.bg_opacity
                    if (data.icon_size !== undefined) root.dockIconSize = data.icon_size
                    if (data.dock_padding !== undefined) root.dockPadding = data.dock_padding
                    if (data.corner_radius !== undefined) root.dockCornerRadius = data.corner_radius
                    if (data.hover_effect) root.dockHoverEffect = data.hover_effect
                    if (data.show_tooltips !== undefined) root.dockShowTooltips = data.show_tooltips
                    if (data.hide_delay !== undefined) root.dockHideDelay = data.hide_delay
                    if (data.show_launcher !== undefined) root.dockShowLauncher = data.show_launcher
                    if (data.show_indicators !== undefined) root.dockShowIndicators = data.show_indicators
                    if (data.border_glow !== undefined) root.dockBorderGlow = data.border_glow
                    if (data.pinned_apps) root.pinnedApps = data.pinned_apps
                    root.isInitialized = true
                } catch(e) {
                    console.log("[DockSection] Error loading dock.json:", e)
                }
            }
        }
    }

    // ── Save dock.json & Live Apply via IPC ──────────────────────────────────
    Process {
        id: dockWriter
        onExited: {
            root.isSaving = false
            dockReloader.running = true
        }
    }

    Process {
        id: dockReloader
        command: ["qs", "ipc", "-c", "dock", "call", "dock", "reloadConfig"]
    }

    // Debounced instant live save timer for sliders
    Timer {
        id: autoSaveTimer
        interval: 120
        repeat: false
        onTriggered: root.executeSave()
    }

    function triggerAutoSave() {
        if (!root.isInitialized) return
        root.isSaving = true
        autoSaveTimer.restart()
    }

    function executeSave() {
        var payload = {
            "enabled": root.dockEnabled,
            "mode": root.dockMode,
            "position": root.dockPosition,
            "bg_opacity": root.dockBgOpacity,
            "icon_size": root.dockIconSize,
            "dock_padding": root.dockPadding,
            "corner_radius": root.dockCornerRadius,
            "hover_effect": root.dockHoverEffect,
            "show_tooltips": root.dockShowTooltips,
            "hide_delay": root.dockHideDelay,
            "show_launcher": root.dockShowLauncher,
            "show_indicators": root.dockShowIndicators,
            "border_glow": root.dockBorderGlow,
            "pinned_apps": root.pinnedApps
        }
        var jsonStr = JSON.stringify(payload, null, 2)
        var pyScript = "import json, os; p=os.path.expanduser('~/.hyprconf/quickshell/dock/dock.json'); os.makedirs(os.path.dirname(p), exist_ok=True); open(p, 'w', encoding='utf-8').write('''" + jsonStr + "''')"
        dockWriter.command = ["python3", "-c", pyScript]
        dockWriter.running = true
    }

    function resetDefaults() {
        root.dockEnabled = true
        root.dockMode = "smart_hide"
        root.dockPosition = "bottom"
        root.dockBgOpacity = 0.85
        root.dockIconSize = 48
        root.dockPadding = 8
        root.dockCornerRadius = 22
        root.dockHoverEffect = "zoom"
        root.dockShowTooltips = true
        root.dockHideDelay = 350
        root.dockShowLauncher = true
        root.dockShowIndicators = true
        root.dockBorderGlow = true
        root.triggerAutoSave()
    }

    function isAppPinned(cls, appId) {
        if (!root.pinnedApps) return false
        var clsL = (cls || "").toLowerCase()
        var idL = (appId || "").toLowerCase()
        for (var i = 0; i < root.pinnedApps.length; i++) {
            var p = root.pinnedApps[i]
            var pid = (p.id || "").toLowerCase()
            var pexec = (p.exec || "").toLowerCase()
            var matches = p.match || []
            if (pid === idL || pexec.indexOf(clsL) !== -1 || pid.indexOf(clsL) !== -1) return true
            for (var m = 0; m < matches.length; m++) {
                if (matches[m].toLowerCase() === clsL) return true
            }
        }
        return false
    }

    function pinOpenWindow(win) {
        var cls = (win.lastIpcObject ? win.lastIpcObject["class"] : "") || ""
        var resolved = null
        for (var i = 0; i < root.allAppsList.length; i++) {
            var a = root.allAppsList[i]
            var baseId = (a.id || "").toLowerCase().replace(".desktop", "")
            if (baseId === cls.toLowerCase() || (a.exec || "").toLowerCase().indexOf(cls.toLowerCase()) !== -1) {
                resolved = a
                break
            }
        }

        var newPin = {
            "id": resolved ? resolved.id : (cls.toLowerCase() + ".desktop"),
            "name": resolved ? resolved.name : (cls.charAt(0).toUpperCase() + cls.slice(1)),
            "exec": resolved ? resolved.exec : cls,
            "icon": resolved ? resolved.icon : cls,
            "icon_path": resolved ? resolved.icon_path : "",
            "match": [cls.toLowerCase()]
        }

        var list = [].concat(root.pinnedApps || [])
        list.push(newPin)
        root.pinnedApps = list
        root.executeSave()
    }

    function unpinApp(index) {
        var list = [].concat(root.pinnedApps || [])
        list.splice(index, 1)
        root.pinnedApps = list
        root.executeSave()
    }

    function movePin(index, delta) {
        var newIdx = index + delta
        if (newIdx < 0 || newIdx >= root.pinnedApps.length) return
        var list = [].concat(root.pinnedApps || [])
        var item = list.splice(index, 1)[0]
        list.splice(newIdx, 0, item)
        root.pinnedApps = list
        root.executeSave()
    }

    function addAppToPins(app) {
        var newPin = {
            "id": app.id || (app.name.toLowerCase() + ".desktop"),
            "name": app.name || "App",
            "exec": app.exec || "",
            "icon": app.icon || "",
            "icon_path": app.icon_path || "",
            "match": [app.id.replace(".desktop", ""), app.exec.split(" ")[0]]
        }
        var list = [].concat(root.pinnedApps || [])
        list.push(newPin)
        root.pinnedApps = list
        root.executeSave()
        root.showAddAppDialog = false
    }

    // ── Main Scroll View ────────────────────────────────────────────────────
    ScrollView {
        anchors.fill: parent
        anchors.margins: 18
        contentWidth: availableWidth
        clip: true

        Column {
            width: parent.width
            spacing: 16

            // ── TOP HEADER (WITH LIVE SYNC INDICATOR) ────────────────────────
            Rectangle {
                width: parent.width
                height: 64
                radius: 12
                color: Theme.alpha(Theme.surface, 0.70)
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.25)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Column {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Application Dock Studio"
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 17
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "Dynamic desktop dock with instant live application"
                            color: Theme.alpha(Theme.foreground, 0.60)
                            font.family: "Outfit"
                            font.pixelSize: 11
                        }
                    }

                    // Live Sync Indicator Pill
                    Rectangle {
                        width: 136
                        height: 32
                        radius: 16
                        color: Theme.alpha(Theme.surface, 0.90)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.35)

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            Rectangle {
                                width: 7
                                height: 7
                                radius: 3.5
                                color: root.isSaving ? Theme.accent : "#28c840"
                                anchors.verticalCenter: parent.verticalCenter

                                SequentialAnimation on opacity {
                                    running: root.isSaving
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 0.3; to: 1.0; duration: 400 }
                                    NumberAnimation { from: 1.0; to: 0.3; duration: 400 }
                                }
                            }

                            Text {
                                text: root.isSaving ? "Applying..." : "Live Applied"
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    // Reset Defaults Button
                    Rectangle {
                        width: 110
                        height: 32
                        radius: 8
                        color: Theme.alpha(Theme.surface, 0.85)
                        border.width: 1
                        border.color: Theme.alpha(Theme.foreground, 0.15)

                        Text {
                            anchors.centerIn: parent
                            text: "Reset Defaults"
                            color: Theme.alpha(Theme.foreground, 0.85)
                            font.family: "Outfit"
                            font.pixelSize: 11
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.resetDefaults()
                        }
                    }
                }
            }

            // ── LIVE INTERACTIVE PREVIEW CARD ────────────────────────────────
            SettingCard {
                title: "Live Dock Preview"
                description: "Interactive real-time preview reflecting your active dock settings"

                Rectangle {
                    width: parent.width
                    height: 150
                    radius: 12
                    color: "#080a0e"
                    border.width: 1
                    border.color: Theme.alpha(Theme.accent, 0.20)
                    clip: true

                    // Simulated Window on screen
                    Rectangle {
                        x: 36
                        y: 16
                        width: 200
                        height: 90
                        radius: 6
                        color: Theme.alpha(Theme.surface, 0.65)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.25)
                        visible: root.dockMode !== "auto_hide"

                        Row {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: 6
                            spacing: 4
                            Rectangle { width: 6; height: 6; radius: 3; color: "#fd4663" }
                            Rectangle { width: 6; height: 6; radius: 3; color: "#feb836" }
                            Rectangle { width: 6; height: 6; radius: 3; color: "#28c840" }
                            Text {
                                text: "  Desktop Window"
                                color: Theme.alpha(Theme.foreground, 0.40)
                                font.family: "Outfit"
                                font.pixelSize: 9
                            }
                        }
                    }

                    // The Preview Dock
                    Rectangle {
                        id: previewDockPill
                        radius: Math.min(width / 2, root.dockCornerRadius * 0.70)
                        color: Theme.alpha(Theme.surface, root.dockBgOpacity)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, root.dockBorderGlow ? 0.45 : 0.20)

                        anchors.horizontalCenter: (root.dockPosition === "bottom" || root.dockPosition === "top") ? parent.horizontalCenter : undefined
                        anchors.verticalCenter: (root.dockPosition === "left" || root.dockPosition === "right") ? parent.verticalCenter : undefined
                        anchors.bottom: root.dockPosition === "bottom" ? parent.bottom : undefined
                        anchors.top: root.dockPosition === "top" ? parent.top : undefined
                        anchors.left: root.dockPosition === "left" ? parent.left : undefined
                        anchors.right: root.dockPosition === "right" ? parent.right : undefined
                        anchors.margins: 10

                        width: (root.dockPosition === "bottom" || root.dockPosition === "top") ? (previewRow.implicitWidth + 14) : 42
                        height: (root.dockPosition === "bottom" || root.dockPosition === "top") ? 42 : (previewCol.implicitHeight + 14)

                        // Horizontal preview
                        Row {
                            id: previewRow
                            visible: root.dockPosition === "bottom" || root.dockPosition === "top"
                            anchors.centerIn: parent
                            spacing: 6

                            Image {
                                visible: root.dockShowLauncher
                                source: root.gridSvg
                                width: 15
                                height: 15
                                sourceSize: Qt.size(30, 30)
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                visible: root.dockShowLauncher
                                width: 1
                                height: 14
                                color: Theme.alpha(Theme.foreground, 0.15)
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Repeater {
                                model: Math.min(5, root.pinnedApps.length)
                                Item {
                                    width: 26
                                    height: 26
                                    anchors.verticalCenter: parent.verticalCenter

                                    Image {
                                        anchors.centerIn: parent
                                        width: 22
                                        height: 22
                                        source: root.pinnedApps[index] && root.pinnedApps[index].icon_path ? root.pinnedApps[index].icon_path : ""
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        scale: prevMouse.containsMouse && root.dockHoverEffect === "zoom" ? 1.28 : 1.0
                                        y: prevMouse.containsMouse && root.dockHoverEffect === "lift" ? -4 : 0
                                        Behavior on scale { NumberAnimation { duration: 140 } }
                                        Behavior on y { NumberAnimation { duration: 140 } }
                                    }

                                    Rectangle {
                                        visible: root.dockShowIndicators && index === 0
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 8
                                        height: 2.5
                                        radius: 1.2
                                        color: Theme.accent
                                    }

                                    MouseArea {
                                        id: prevMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                    }
                                }
                            }
                        }

                        // Vertical preview
                        Column {
                            id: previewCol
                            visible: root.dockPosition === "left" || root.dockPosition === "right"
                            anchors.centerIn: parent
                            spacing: 6

                            Image {
                                visible: root.dockShowLauncher
                                source: root.gridSvg
                                width: 15
                                height: 15
                                sourceSize: Qt.size(30, 30)
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Rectangle {
                                visible: root.dockShowLauncher
                                width: 14
                                height: 1
                                color: Theme.alpha(Theme.foreground, 0.15)
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Repeater {
                                model: Math.min(4, root.pinnedApps.length)
                                Item {
                                    width: 26
                                    height: 26
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Image {
                                        anchors.centerIn: parent
                                        width: 22
                                        height: 22
                                        source: root.pinnedApps[index] && root.pinnedApps[index].icon_path ? root.pinnedApps[index].icon_path : ""
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── STAGE / HIDE MODES CARD ──────────────────────────────────────
            SettingCard {
                title: "Dock Stages & Visibility"
                description: "Select how the dock behaves when interacting with open desktop windows"

                RowLayout {
                    width: parent.width
                    spacing: 12

                    // Mode 1: Always On
                    Rectangle {
                        Layout.fillWidth: true
                        height: 84
                        radius: 10
                        color: root.dockMode === "always_on" ? Theme.alpha(Theme.accent, 0.20) : Theme.alpha(Theme.surface, 0.65)
                        border.width: root.dockMode === "always_on" ? 2 : 1
                        border.color: root.dockMode === "always_on" ? Theme.accent : Theme.alpha(Theme.accent, 0.15)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 4

                            RowLayout {
                                width: parent.width
                                spacing: 8

                                Image {
                                    Layout.preferredWidth: 16
                                    Layout.preferredHeight: 16
                                    source: root.pinSvg
                                    sourceSize: Qt.size(32, 32)
                                }

                                Text {
                                    text: "Always Visible"
                                    color: Theme.foreground
                                    font.family: "Outfit"
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Continuously visible on screen with reserved desktop workspace margin."
                                color: Theme.alpha(Theme.foreground, 0.60)
                                font.family: "Outfit"
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.dockMode = "always_on"
                                root.triggerAutoSave()
                            }
                        }
                    }

                    // Mode 2: Auto Hide
                    Rectangle {
                        Layout.fillWidth: true
                        height: 84
                        radius: 10
                        color: root.dockMode === "auto_hide" ? Theme.alpha(Theme.accent, 0.20) : Theme.alpha(Theme.surface, 0.65)
                        border.width: root.dockMode === "auto_hide" ? 2 : 1
                        border.color: root.dockMode === "auto_hide" ? Theme.accent : Theme.alpha(Theme.accent, 0.15)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 4

                            RowLayout {
                                width: parent.width
                                spacing: 8

                                Image {
                                    Layout.preferredWidth: 16
                                    Layout.preferredHeight: 16
                                    source: root.downSvg
                                    sourceSize: Qt.size(32, 32)
                                }

                                Text {
                                    text: "Auto Hide"
                                    color: Theme.foreground
                                    font.family: "Outfit"
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Slides completely off-screen and smoothly reveals when hovering screen edge."
                                color: Theme.alpha(Theme.foreground, 0.60)
                                font.family: "Outfit"
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.dockMode = "auto_hide"
                                root.triggerAutoSave()
                            }
                        }
                    }

                    // Mode 3: Smart Hide (Window Dodge)
                    Rectangle {
                        Layout.fillWidth: true
                        height: 84
                        radius: 10
                        color: root.dockMode === "smart_hide" ? Theme.alpha(Theme.accent, 0.20) : Theme.alpha(Theme.surface, 0.65)
                        border.width: root.dockMode === "smart_hide" ? 2 : 1
                        border.color: root.dockMode === "smart_hide" ? Theme.accent : Theme.alpha(Theme.accent, 0.15)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 4

                            RowLayout {
                                width: parent.width
                                spacing: 8

                                Image {
                                    Layout.preferredWidth: 16
                                    Layout.preferredHeight: 16
                                    source: root.windowSvg
                                    sourceSize: Qt.size(32, 32)
                                }

                                Text {
                                    text: "Smart Hide"
                                    color: Theme.foreground
                                    font.family: "Outfit"
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Always open on empty desktops; hides when windows are opened; appears on hover."
                                color: Theme.alpha(Theme.foreground, 0.60)
                                font.family: "Outfit"
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.dockMode = "smart_hide"
                                root.triggerAutoSave()
                            }
                        }
                    }
                }
            }

            // ── POSITION & SCREEN EDGE CARD ──────────────────────────────────
            SettingCard {
                title: "Screen Position"
                description: "Select which screen edge the dock anchors to"

                RowLayout {
                    width: parent.width
                    spacing: 12

                    Repeater {
                        model: [
                            { id: "bottom", label: "Bottom", icon: root.downSvg },
                            { id: "top", label: "Top", icon: root.upSvg },
                            { id: "left", label: "Left", icon: root.svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="15 18 9 12 15 6"/></svg>') },
                            { id: "right", label: "Right", icon: root.svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 18 15 12 9 6"/></svg>') }
                        ]

                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            height: 44
                            radius: 8
                            color: root.dockPosition === modelData.id ? Theme.accent : Theme.alpha(Theme.surface, 0.80)
                            border.width: 1
                            border.color: root.dockPosition === modelData.id ? Theme.accent : Theme.alpha(Theme.accent, 0.18)

                            Row {
                                anchors.centerIn: parent
                                spacing: 8

                                Image {
                                    source: modelData.icon
                                    width: 14
                                    height: 14
                                    sourceSize: Qt.size(28, 28)
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: modelData.label
                                    color: root.dockPosition === modelData.id ? Theme.on_primary : Theme.foreground
                                    font.family: "Outfit"
                                    font.pixelSize: 12
                                    font.weight: root.dockPosition === modelData.id ? Font.DemiBold : Font.Normal
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.dockPosition = modelData.id
                                    root.triggerAutoSave()
                                }
                            }
                        }
                    }
                }
            }

            // ── APPEARANCE & SIZING SLIDERS ──────────────────────────────────
            SettingCard {
                title: "Appearance & Sizing"
                description: "Adjust background opacity, icon dimensions, corner radius, and auto-hide timing"

                Column {
                    width: parent.width
                    spacing: 14

                    // Slider 1: Background Opacity
                    Column {
                        width: parent.width
                        spacing: 4

                        RowLayout {
                            width: parent.width
                            Text {
                                text: "Background Opacity"
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 13
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: Math.round(root.dockBgOpacity * 100) + "%"
                                color: Theme.accent
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                        }

                        ModernSlider {
                            width: parent.width
                            from: 0.10
                            to: 1.00
                            stepSize: 0.05
                            value: root.dockBgOpacity
                            onValueChanged: {
                                if (Math.abs(root.dockBgOpacity - value) > 0.01) {
                                    root.dockBgOpacity = value
                                    root.triggerAutoSave()
                                }
                            }
                        }
                    }

                    // Slider 2: Icon Size
                    Column {
                        width: parent.width
                        spacing: 4

                        RowLayout {
                            width: parent.width
                            Text {
                                text: "Icon Dimensions"
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 13
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: root.dockIconSize + " px"
                                color: Theme.accent
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                        }

                        ModernSlider {
                            width: parent.width
                            from: 32
                            to: 64
                            stepSize: 2
                            value: root.dockIconSize
                            onValueChanged: {
                                if (root.dockIconSize !== Math.round(value)) {
                                    root.dockIconSize = Math.round(value)
                                    root.triggerAutoSave()
                                }
                            }
                        }
                    }

                    // Slider 3: Corner Radius
                    Column {
                        width: parent.width
                        spacing: 4

                        RowLayout {
                            width: parent.width
                            Text {
                                text: "Corner Radius"
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 13
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: root.dockCornerRadius + " px"
                                color: Theme.accent
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                        }

                        ModernSlider {
                            width: parent.width
                            from: 8
                            to: 32
                            stepSize: 2
                            value: root.dockCornerRadius
                            onValueChanged: {
                                if (root.dockCornerRadius !== Math.round(value)) {
                                    root.dockCornerRadius = Math.round(value)
                                    root.triggerAutoSave()
                                }
                            }
                        }
                    }

                    // Slider 4: Auto-Hide Grace Delay
                    Column {
                        width: parent.width
                        spacing: 4

                        RowLayout {
                            width: parent.width
                            Text {
                                text: "Auto-Hide Grace Delay"
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 13
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: root.dockHideDelay + " ms"
                                color: Theme.accent
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                        }

                        ModernSlider {
                            width: parent.width
                            from: 150
                            to: 800
                            stepSize: 50
                            value: root.dockHideDelay
                            onValueChanged: {
                                if (root.dockHideDelay !== Math.round(value)) {
                                    root.dockHideDelay = Math.round(value)
                                    root.triggerAutoSave()
                                }
                            }
                        }
                    }
                }
            }

            // ── HOVER EFFECTS CARD ───────────────────────────────────────────
            SettingCard {
                title: "Hover Effects"
                description: "Select the animation physics when moving cursor over dock icons"

                RowLayout {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: [
                            { id: "zoom", label: "Parabolic Zoom", desc: "Magnification (1.28x)" },
                            { id: "lift", label: "Float & Lift", desc: "Spring elevation" },
                            { id: "glow", label: "Accent Glow", desc: "Radial aura" },
                            { id: "subtle", label: "Subtle Micro", desc: "Scale (1.10x)" },
                            { id: "none", label: "Minimal", desc: "Flat static" }
                        ]

                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            height: 54
                            radius: 8
                            color: root.dockHoverEffect === modelData.id ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.75)
                            border.width: 1
                            border.color: root.dockHoverEffect === modelData.id ? Theme.accent : Theme.alpha(Theme.accent, 0.18)

                            Column {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.label
                                    color: root.dockHoverEffect === modelData.id ? Theme.accent : Theme.foreground
                                    font.family: "Outfit"
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.desc
                                    color: Theme.alpha(Theme.foreground, 0.50)
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.dockHoverEffect = modelData.id
                                    root.triggerAutoSave()
                                }
                            }
                        }
                    }
                }
            }

            // ── DOCK SWITCHES & TOGGLES ──────────────────────────────────────
            SettingCard {
                title: "Dock Elements & Badges"
                description: "Toggle optional controls and indicators on the dock"

                Column {
                    width: parent.width
                    spacing: 12

                    RowLayout {
                        width: parent.width
                        Column {
                            Layout.fillWidth: true
                            Text { text: "Quick App Launcher Button"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                            Text { text: "Dedicated application launcher button at the edge of the dock"; color: Theme.alpha(Theme.foreground, 0.50); font.family: "Outfit"; font.pixelSize: 11 }
                        }
                        CapsuleSwitch {
                            checked: root.dockShowLauncher
                            onToggled: { root.dockShowLauncher = checked; root.triggerAutoSave(); }
                        }
                    }

                    RowLayout {
                        width: parent.width
                        Column {
                            Layout.fillWidth: true
                            Text { text: "Running App Indicators"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                            Text { text: "Active dots and capsules beneath currently opened apps"; color: Theme.alpha(Theme.foreground, 0.50); font.family: "Outfit"; font.pixelSize: 11 }
                        }
                        CapsuleSwitch {
                            checked: root.dockShowIndicators
                            onToggled: { root.dockShowIndicators = checked; root.triggerAutoSave(); }
                        }
                    }

                    RowLayout {
                        width: parent.width
                        Column {
                            Layout.fillWidth: true
                            Text { text: "App Name Tooltips"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                            Text { text: "Show title capsule when hovering over dock icons"; color: Theme.alpha(Theme.foreground, 0.50); font.family: "Outfit"; font.pixelSize: 11 }
                        }
                        CapsuleSwitch {
                            checked: root.dockShowTooltips
                            onToggled: { root.dockShowTooltips = checked; root.triggerAutoSave(); }
                        }
                    }

                    RowLayout {
                        width: parent.width
                        Column {
                            Layout.fillWidth: true
                            Text { text: "Border Glow & Rim Accent"; color: Theme.foreground; font.family: "Outfit"; font.pixelSize: 13 }
                            Text { text: "Accent outline along the perimeter of the dock"; color: Theme.alpha(Theme.foreground, 0.50); font.family: "Outfit"; font.pixelSize: 11 }
                        }
                        CapsuleSwitch {
                            checked: root.dockBorderGlow
                            onToggled: { root.dockBorderGlow = checked; root.triggerAutoSave(); }
                        }
                    }
                }
            }

            // ── CURRENTLY OPEN WINDOWS (1-CLICK PIN) ──────────────────────────
            SettingCard {
                title: "Currently Open Windows"
                description: "Live detection of running applications with one-click pin to dock"

                Column {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: Hyprland.toplevels ? Hyprland.toplevels.values : []

                        Rectangle {
                            required property var modelData
                            width: parent.width
                            height: 46
                            radius: 8
                            color: Theme.alpha(Theme.surface, 0.60)
                            border.width: 1
                            border.color: Theme.alpha(Theme.accent, 0.15)

                            readonly property string winClass: (modelData.lastIpcObject ? modelData.lastIpcObject["class"] : "") || ""
                            readonly property bool pinned: root.isAppPinned(winClass, "")

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                Image {
                                    Layout.preferredWidth: 16
                                    Layout.preferredHeight: 16
                                    source: root.windowSvg
                                    sourceSize: Qt.size(32, 32)
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.title || "Window"
                                        color: Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: "Class: " + (modelData.lastIpcObject ? modelData.lastIpcObject["class"] : "unknown") + " • Workspace " + (modelData.workspace ? modelData.workspace.id : "1")
                                        color: Theme.alpha(Theme.foreground, 0.50)
                                        font.family: "Outfit"
                                        font.pixelSize: 10
                                    }
                                }

                                // Pin Button or Pinned Pill
                                Rectangle {
                                    width: pinned ? 72 : 92
                                    height: 26
                                    radius: 6
                                    color: pinned ? Theme.alpha(Theme.surface, 0.90) : Theme.accent
                                    border.width: pinned ? 1 : 0
                                    border.color: Theme.alpha(Theme.accent, 0.35)

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Image {
                                            visible: pinned
                                            source: root.checkSvg
                                            width: 12
                                            height: 12
                                            sourceSize: Qt.size(24, 24)
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Image {
                                            visible: !pinned
                                            source: root.svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.on_primary + '" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>')
                                            width: 11
                                            height: 11
                                            sourceSize: Qt.size(22, 22)
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: pinned ? "Pinned" : "Pin"
                                            color: pinned ? Theme.foreground : Theme.on_primary
                                            font.family: "Outfit"
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: !pinned
                                        cursorShape: pinned ? Qt.ArrowCursor : Qt.PointingHandCursor
                                        onClicked: root.pinOpenWindow(modelData)
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: !Hyprland.toplevels || Hyprland.toplevels.values.length === 0
                        text: "No open windows detected on active workspaces"
                        color: Theme.alpha(Theme.foreground, 0.40)
                        font.family: "Outfit"
                        font.pixelSize: 11
                    }
                }
            }

            // ── PINNED APPLICATIONS MANAGER ──────────────────────────────────
            SettingCard {
                title: "Pinned Applications"
                description: "Reorder, remove, or pin applications to the dock"

                Column {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: root.pinnedApps

                        Rectangle {
                            required property var modelData
                            required property int index
                            width: parent.width
                            height: 44
                            radius: 8
                            color: Theme.alpha(Theme.surface, 0.65)
                            border.width: 1
                            border.color: Theme.alpha(Theme.accent, 0.16)

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 10

                                Image {
                                    Layout.preferredWidth: 22
                                    Layout.preferredHeight: 22
                                    source: modelData.icon_path || ""
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: modelData.name || "App"
                                        color: Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: modelData.exec || modelData.id || ""
                                        color: Theme.alpha(Theme.foreground, 0.45)
                                        font.family: "Outfit"
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                    }
                                }

                                // Move Up Button
                                Rectangle {
                                    width: 26
                                    height: 26
                                    radius: 6
                                    color: upMouse.containsMouse ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surface, 0.85)
                                    visible: index > 0

                                    Image {
                                        anchors.centerIn: parent
                                        source: root.upSvg
                                        width: 12
                                        height: 12
                                        sourceSize: Qt.size(24, 24)
                                    }

                                    MouseArea {
                                        id: upMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.movePin(index, -1)
                                    }
                                }

                                // Move Down Button
                                Rectangle {
                                    width: 26
                                    height: 26
                                    radius: 6
                                    color: downMouse.containsMouse ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surface, 0.85)
                                    visible: index < root.pinnedApps.length - 1

                                    Image {
                                        anchors.centerIn: parent
                                        source: root.downSvg
                                        width: 12
                                        height: 12
                                        sourceSize: Qt.size(24, 24)
                                    }

                                    MouseArea {
                                        id: downMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.movePin(index, 1)
                                    }
                                }

                                // Remove Button
                                Rectangle {
                                    width: 26
                                    height: 26
                                    radius: 6
                                    color: trashMouse.containsMouse ? Theme.alpha(Theme.error, 0.25) : Theme.alpha(Theme.surface, 0.85)

                                    Image {
                                        anchors.centerIn: parent
                                        source: root.trashSvg
                                        width: 13
                                        height: 13
                                        sourceSize: Qt.size(26, 26)
                                    }

                                    MouseArea {
                                        id: trashMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.unpinApp(index)
                                    }
                                }
                            }
                        }
                    }

                    // Add Application Button
                    Rectangle {
                        width: parent.width
                        height: 38
                        radius: 8
                        color: addMouse.containsMouse ? Theme.alpha(Theme.accent, 0.18) : "transparent"
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.30)

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            Image {
                                source: root.plusSvg
                                width: 13
                                height: 13
                                sourceSize: Qt.size(26, 26)
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "Pin Application..."
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: addMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showAddAppDialog = true
                        }
                    }
                }
            }

            Item { width: 1; height: 28 }
        }
    }

    // ── SEARCHABLE ADD APPLICATION MODAL ────────────────────────────────────
    Rectangle {
        id: addAppModal
        anchors.fill: parent
        visible: root.showAddAppDialog
        color: Theme.alpha(Theme.background, 0.85)
        z: 99999

        MouseArea {
            anchors.fill: parent
            onClicked: root.showAddAppDialog = false
        }

        Rectangle {
            anchors.centerIn: parent
            width: 500
            height: 440
            radius: 14
            color: Theme.alpha(Theme.surface, 0.98)
            border.width: 1
            border.color: Theme.alpha(Theme.accent, 0.35)

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Pin Application"
                        color: Theme.foreground
                        font.family: "Outfit"
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 26
                        height: 26
                        radius: 13
                        color: Theme.alpha(Theme.surface, 0.90)

                        Image {
                            anchors.centerIn: parent
                            source: root.closeSvg
                            width: 11
                            height: 11
                            sourceSize: Qt.size(22, 22)
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showAddAppDialog = false
                        }
                    }
                }

                // Search field
                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 8
                    color: Theme.alpha(Theme.background, 0.70)
                    border.width: 1
                    border.color: searchInput.activeFocus ? Theme.accent : Theme.alpha(Theme.accent, 0.25)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Image {
                            source: root.searchSvg
                            width: 14
                            height: 14
                            sourceSize: Qt.size(28, 28)
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            text: root.appSearchQuery
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 12
                            clip: true
                            onTextChanged: root.appSearchQuery = text

                            Text {
                                text: "Search applications..."
                                color: Theme.alpha(Theme.foreground, 0.40)
                                font.family: "Outfit"
                                font.pixelSize: 12
                                visible: !searchInput.text && !searchInput.activeFocus
                            }
                        }
                    }
                }

                // Apps List
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    Column {
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: {
                                var q = (root.appSearchQuery || "").toLowerCase()
                                return root.allAppsList.filter(function(a) {
                                    if (!q) return true
                                    var n = (a.name || "").toLowerCase()
                                    var e = (a.exec || "").toLowerCase()
                                    var id = (a.id || "").toLowerCase()
                                    return n.indexOf(q) !== -1 || e.indexOf(q) !== -1 || id.indexOf(q) !== -1
                                })
                            }

                            Rectangle {
                                required property var modelData
                                width: parent.width
                                height: 40
                                radius: 6
                                color: appRowMouse.containsMouse ? Theme.alpha(Theme.accent, 0.18) : Theme.alpha(Theme.surface, 0.45)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 10

                                    Image {
                                        Layout.preferredWidth: 22
                                        Layout.preferredHeight: 22
                                        source: modelData.icon_path || ""
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            text: modelData.name || "App"
                                            color: Theme.foreground
                                            font.family: "Outfit"
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: modelData.comment || modelData.exec || ""
                                            color: Theme.alpha(Theme.foreground, 0.45)
                                            font.family: "Outfit"
                                            font.pixelSize: 9
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Text {
                                        text: "Pin"
                                        color: Theme.accent
                                        font.family: "Outfit"
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                }

                                MouseArea {
                                    id: appRowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.addAppToPins(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
