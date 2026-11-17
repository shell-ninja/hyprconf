import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root
    anchors.fill: parent

    readonly property string homeDir: (typeof window !== "undefined" && window.homeDir) ? window.homeDir : (Quickshell.env("HOME") || "/home/" + Quickshell.env("USER"))

    property bool isLoading: false
    property string activeTab: "installed" // "installed" | "available"
    property var installedList: []
    property var availableList: []
    property var selectedPlugin: null // Non-null when viewing detail page
    property string statusMessage: ""
    property bool isError: false
    property bool isDragging: false

    function svgUrl(content) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(content)
    }

    // ── SVG Icons ────────────────────────────────────────────────────────────
    readonly property string refreshSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21.5 2v6h-6M21.34 15.57a10 10 0 1 1-.57-8.38l5.67-5.67"/></svg>')
    readonly property string downloadSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.on_primary + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>')
    readonly property string trashSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + (Theme.error || "#ef4444") + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>')
    readonly property string dropIconSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 14.899A7 7 0 1 1 15.71 8h1.79a4.5 4.5 0 0 1 2.5 8.242"/><path d="M12 12v9"/><path d="m8 17 4 4 4-4"/></svg>')
    readonly property string backArrowSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="m12 19-7-7 7-7"/><path d="M19 12H5"/></svg>')
    readonly property string checkSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>')
    readonly property string checkCircleSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>')
    readonly property string lightningSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>')
    readonly property string folderSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20h16a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.93a2 2 0 0 1-1.66-.9l-.82-1.2A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13c0 1.1.9 2 2 2Z"/></svg>')

    function getPluginSvg(iconName, color) {
        var c = color || Theme.accent
        if (iconName === "palette" || iconName === "theme") {
            return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + c + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="13.5" cy="6.5" r=".5" fill="' + c + '"/><circle cx="17.5" cy="10.5" r=".5" fill="' + c + '"/><circle cx="8.5" cy="7.5" r=".5" fill="' + c + '"/><circle cx="6.5" cy="12.5" r=".5" fill="' + c + '"/><path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.926 0 1.648-.746 1.648-1.688 0-.437-.18-.835-.437-1.125-.29-.289-.438-.652-.438-1.125a1.64 1.64 0 0 1 1.668-1.668h1.996c3.051 0 5.555-2.503 5.555-5.554C21.965 6.012 17.461 2 12 2z"/></svg>')
        }
        if (iconName === "terminal" || iconName === "sh") {
            return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + c + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg>')
        }
        // Default: Sleek jigsaw puzzle piece
        return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + c + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 7h3a1 1 0 0 0 1-1v-1a2 2 0 0 1 4 0v1a1 1 0 0 0 1 1h3a1 1 0 0 1 1 1v3a1 1 0 0 0 1 1h1a2 2 0 0 1 0 4h-1a1 1 0 0 0-1 1v3a1 1 0 0 1-1 1h-3a1 1 0 0 1-1-1v-1a2 2 0 0 0-4 0v1a1 1 0 0 1-1 1h-3a1 1 0 0 1-1-1v-3a1 1 0 0 1 1-1h1a2 2 0 0 0 0-4h-1a1 1 0 0 1-1-1v-3a1 1 0 0 1 1-1"/></svg>')
    }

    function getPluginIconSource(plugin) {
        if (!plugin) return ""
        if (plugin.icon_url && plugin.icon_url.length > 0) {
            return plugin.icon_url
        }
        return root.getPluginSvg(plugin.icon || plugin.id, Theme.accent)
    }

    function updateSelectedPlugin() {
        if (!root.selectedPlugin) return
        var pid = root.selectedPlugin.id
        for (var i = 0; i < root.installedList.length; i++) {
            if (root.installedList[i].id === pid) {
                root.selectedPlugin = root.installedList[i]
                return
            }
        }
        for (var j = 0; j < root.availableList.length; j++) {
            if (root.availableList[j].id === pid) {
                root.selectedPlugin = root.availableList[j]
                return
            }
        }
    }

    function openPluginDetailById(id) {
        for (var i = 0; i < root.installedList.length; i++) {
            if (root.installedList[i].id === id) {
                root.selectedPlugin = root.installedList[i]
                return
            }
        }
        for (var j = 0; j < root.availableList.length; j++) {
            if (root.availableList[j].id === id) {
                root.selectedPlugin = root.availableList[j]
                return
            }
        }
    }

    onInstalledListChanged: {
        var req = Quickshell.env("QS_SETTINGS_PLUGIN")
        if (req && req.length > 0 && !root.selectedPlugin) {
            root.openPluginDetailById(req)
        }
    }

    onAvailableListChanged: {
        var req = Quickshell.env("QS_SETTINGS_PLUGIN")
        if (req && req.length > 0 && !root.selectedPlugin) {
            root.openPluginDetailById(req)
        }
    }

    // ── Load Plugins Process ──────────────────────────────────────────────────
    Process {
        id: loadProc
        command: ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/hyprconf-plugin.py", "json"]
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var data = JSON.parse(text.trim())
                    root.installedList = data.installed || []
                    root.availableList = data.available || []
                    root.updateSelectedPlugin()
                    root.isLoading = false
                } catch (e) {
                    root.isLoading = false
                }
            }
        }
        onExited: {
            root.isLoading = false
        }
    }

    // ── Action Process (install/remove/toggle/install-path) ────────────────────
    Process {
        id: actionProc
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    root.statusMessage = text.trim().split("\n").pop()
                    root.isError = false
                }
            }
        }
        stderr: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    root.statusMessage = text.trim().split("\n").pop()
                    root.isError = true
                }
            }
        }
        onExited: {
            root.refresh()
            toastTimer.restart()
        }
    }

    Timer {
        id: toastTimer
        interval: 4000
        onTriggered: root.statusMessage = ""
    }

    function refresh() {
        root.isLoading = true
        loadProc.running = true
    }

    function installPlugin(id) {
        root.isLoading = true
        root.statusMessage = "Installing " + id + "..."
        root.isError = false
        actionProc.command = ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/hyprconf-plugin.py", "install", id]
        actionProc.running = true
    }

    function uninstallPlugin(id) {
        root.isLoading = true
        root.statusMessage = "Uninstalling " + id + "..."
        root.isError = false
        actionProc.command = ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/hyprconf-plugin.py", "uninstall", id]
        actionProc.running = true
    }

    function togglePlugin(id, enable) {
        root.isLoading = true
        root.statusMessage = (enable ? "Enabling " : "Disabling ") + id + "..."
        root.isError = false
        actionProc.command = ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/hyprconf-plugin.py", enable ? "enable" : "disable", id]
        actionProc.running = true
    }

    function installFromPath(path) {
        root.isLoading = true
        root.statusMessage = "Installing plugin from " + path + "..."
        root.isError = false
        actionProc.command = ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/hyprconf-plugin.py", "install-path", path]
        actionProc.running = true
    }

    Component.onCompleted: {
        refresh()
    }

    // ── Main Layout ──────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 20

        // ── TOP HEADER / NAVIGATION ──────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            // Dynamic header content based on view
            Item {
                Layout.fillWidth: true
                implicitHeight: headerCol.implicitHeight

                // Grid view title
                Column {
                    id: headerCol
                    anchors.fill: parent
                    spacing: 4
                    visible: root.selectedPlugin === null

                    Text {
                        text: "Plugins & Extensions"
                        color: Theme.foreground
                        font.family: "Outfit"
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: "Browse verified integrations, manage active modules, or drag and drop to install."
                        color: Theme.alpha(Theme.foreground, 0.60)
                        font.family: "Outfit"
                        font.pixelSize: 13
                    }
                }

                // Detail view breadcrumb & back button
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    visible: root.selectedPlugin !== null

                    Rectangle {
                        width: backBtnRow.implicitWidth + 24
                        height: 36
                        radius: 18
                        color: backMouse.containsMouse ? Theme.alpha(Theme.surface, 0.85) : Theme.alpha(Theme.surface, 0.50)
                        border.color: backMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.accent, 0.25)
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        Row {
                            id: backBtnRow
                            anchors.centerIn: parent
                            spacing: 8

                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 14
                                height: 14
                                source: root.backArrowSvg
                                sourceSize: Qt.size(28, 28)
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Back to Plugins"
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                        }

                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedPlugin = null
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "•"
                        color: Theme.alpha(Theme.foreground, 0.35)
                        font.family: "Outfit"
                        font.pixelSize: 14
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.selectedPlugin ? root.selectedPlugin.name : ""
                        color: Theme.foreground
                        font.family: "Outfit"
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }
                }
            }

            // Status feedback pill
            Rectangle {
                visible: root.statusMessage.length > 0
                height: 32
                width: statusText.implicitWidth + 24
                radius: 16
                color: root.isError ? Theme.alpha(Theme.error || "#ef4444", 0.20) : Theme.alpha(Theme.accent, 0.20)
                border.color: root.isError ? (Theme.error || "#ef4444") : Theme.accent
                border.width: 1

                Text {
                    id: statusText
                    anchors.centerIn: parent
                    text: root.statusMessage
                    color: root.isError ? (Theme.error || "#ef4444") : Theme.accent
                    font.family: "Outfit"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
            }

            // Refresh Button
            Rectangle {
                width: 36
                height: 36
                radius: 10
                color: refreshMouse.containsMouse ? Theme.alpha(Theme.surface, 0.85) : Theme.alpha(Theme.surface, 0.45)
                border.color: refreshMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.accent, 0.20)
                border.width: 1

                Image {
                    id: refreshIcon
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: root.refreshSvg
                    sourceSize: Qt.size(32, 32)

                    RotationAnimation on rotation {
                        running: root.isLoading
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 800
                    }
                }

                MouseArea {
                    id: refreshMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.refresh()
                }
            }
        }

        // ══════════════════════════════════════════════════════════════════════
        // VIEW 1: PLUGINS GRID VIEW
        // ══════════════════════════════════════════════════════════════════════
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16
            visible: root.selectedPlugin === null

            // ── Drag & Drop Installation Target ──────────────────────────────
            DropArea {
                id: dropArea
                Layout.fillWidth: true
                implicitHeight: 84

                onEntered: root.isDragging = true
                onExited: root.isDragging = false
                onDropped: function(drop) {
                    root.isDragging = false
                    if (drop.hasUrls && drop.urls.length > 0) {
                        var fileUrl = drop.urls[0].toString()
                        var filePath = fileUrl.replace(/^file:\/\//, "")
                        root.installFromPath(filePath)
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: root.isDragging ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surface, 0.35)
                    border.color: root.isDragging ? Theme.accent : Theme.alpha(Theme.accent, 0.25)
                    border.width: root.isDragging ? 2 : 1

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 14

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 44
                            height: 44
                            radius: 12
                            color: Theme.alpha(Theme.accent, 0.18)

                            Image {
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                source: root.dropIconSvg
                                sourceSize: Qt.size(44, 44)
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Text {
                                text: root.isDragging ? "Release to Install Plugin" : "Drag and drop plugin directory or archive here to install"
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "Supports any local folder or .tar.gz archive containing a valid plugin.json manifest"
                                color: Theme.alpha(Theme.foreground, 0.55)
                                font.family: "Outfit"
                                font.pixelSize: 11
                            }
                        }
                    }
                }
            }

            // ── Section Tabs ─────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Installed Tab
                Rectangle {
                    height: 34
                    width: tabInstalledRow.implicitWidth + 24
                    radius: 17
                    color: root.activeTab === "installed" ? Theme.accent : Theme.alpha(Theme.surface, 0.50)
                    border.color: root.activeTab === "installed" ? Theme.accent : Theme.alpha(Theme.accent, 0.20)
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 140 } }

                    Row {
                        id: tabInstalledRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Installed"
                            color: root.activeTab === "installed" ? Theme.on_primary : Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 13
                            font.weight: root.activeTab === "installed" ? Font.DemiBold : Font.Normal
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            height: 18
                            width: countText.implicitWidth + 10
                            radius: 9
                            color: root.activeTab === "installed" ? Theme.alpha(Theme.on_primary, 0.25) : Theme.alpha(Theme.foreground, 0.15)

                            Text {
                                id: countText
                                anchors.centerIn: parent
                                text: root.installedList.length.toString()
                                color: root.activeTab === "installed" ? Theme.on_primary : Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: Font.Bold
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeTab = "installed"
                    }
                }

                // Available Catalog Tab
                Rectangle {
                    height: 34
                    width: tabAvailRow.implicitWidth + 24
                    radius: 17
                    color: root.activeTab === "available" ? Theme.accent : Theme.alpha(Theme.surface, 0.50)
                    border.color: root.activeTab === "available" ? Theme.accent : Theme.alpha(Theme.accent, 0.20)
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 140 } }

                    Row {
                        id: tabAvailRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Available Catalog"
                            color: root.activeTab === "available" ? Theme.on_primary : Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 13
                            font.weight: root.activeTab === "available" ? Font.DemiBold : Font.Normal
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            height: 18
                            width: availCountText.implicitWidth + 10
                            radius: 9
                            color: root.activeTab === "available" ? Theme.alpha(Theme.on_primary, 0.25) : Theme.alpha(Theme.foreground, 0.15)

                            Text {
                                id: availCountText
                                anchors.centerIn: parent
                                text: root.availableList.length.toString()
                                color: root.activeTab === "available" ? Theme.on_primary : Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: Font.Bold
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeTab = "available"
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // ── Scrollable Card Grid ─────────────────────────────────────────
            Flickable {
                id: gridFlickable
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: cardFlow.implicitHeight + 40
                clip: true

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                Flow {
                    id: cardFlow
                    width: parent.width
                    spacing: 16

                    readonly property int colCount: Math.max(1, Math.floor((width + spacing) / (320 + spacing)))
                    readonly property real cardW: Math.floor((width - (colCount - 1) * spacing) / colCount)

                    Repeater {
                        model: root.activeTab === "installed" ? root.installedList : root.availableList

                        delegate: Rectangle {
                            id: pluginCard
                            width: cardFlow.cardW
                            height: 295
                            radius: 16
                            color: cardMouse.containsMouse ? Theme.alpha(Theme.surface, 0.70) : Theme.alpha(Theme.surface, 0.38)
                            border.color: cardMouse.containsMouse ? Theme.alpha(Theme.accent, 0.45) : Theme.alpha(Theme.accent, 0.16)
                            border.width: 1
                            clip: true

                            scale: cardMouse.containsMouse ? 1.01 : 1.0
                            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            // ── Top Box: Preview / Hero Banner ───────────────
                            Rectangle {
                                id: cardBanner
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 10
                                height: 126
                                radius: 12
                                clip: true
                                border.width: 1
                                border.color: cardMouse.containsMouse ? Theme.alpha(Theme.accent, 0.35) : Theme.alpha(Theme.accent, 0.15)

                                gradient: Gradient {
                                    orientation: Gradient.Vertical
                                    GradientStop { position: 0.0; color: Theme.alpha(Theme.accent, 0.22) }
                                    GradientStop { position: 1.0; color: Theme.alpha(Theme.surface, 0.45) }
                                }

                                // Ambient soft glow
                                Rectangle {
                                    width: 110
                                    height: 110
                                    radius: 55
                                    anchors.centerIn: parent
                                    color: Theme.alpha(Theme.accent, 0.15)
                                }

                                // Centered Meaningful Plugin Icon
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 64
                                    height: 64
                                    radius: 16
                                    color: "transparent"
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        source: root.getPluginIconSource(modelData)
                                        sourceSize: Qt.size(128, 128)
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        mipmap: true
                                    }
                                }

                                // Top-Left Category Badge
                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.margins: 8
                                    height: 20
                                    width: catLabel.implicitWidth + 14
                                    radius: 6
                                    color: Theme.alpha(Theme.background, 0.70)
                                    border.color: Theme.alpha(Theme.foreground, 0.15)
                                    border.width: 1

                                    Text {
                                        id: catLabel
                                        anchors.centerIn: parent
                                        text: modelData.category || "Plugin"
                                        color: Theme.alpha(Theme.foreground, 0.85)
                                        font.family: "Outfit"
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                    }
                                }

                                // Top-Right Status Badge
                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 8
                                    height: 20
                                    width: statusBadgeRow.implicitWidth + 14
                                    radius: 6
                                    color: Theme.alpha(Theme.background, 0.70)
                                    border.color: modelData.installed ? (modelData.enabled ? Theme.alpha("#22c55e", 0.40) : Theme.alpha(Theme.foreground, 0.20)) : Theme.alpha(Theme.accent, 0.30)
                                    border.width: 1

                                    Row {
                                        id: statusBadgeRow
                                        anchors.centerIn: parent
                                        spacing: 5

                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 6
                                            height: 6
                                            radius: 3
                                            color: modelData.installed ? (modelData.enabled ? "#22c55e" : Theme.alpha(Theme.foreground, 0.40)) : Theme.accent
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.installed ? (modelData.enabled ? "Active" : "Disabled") : "Catalog"
                                            color: Theme.foreground
                                            font.family: "Outfit"
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                }
                            }

                            // ── Middle: Title & Meta ─────────────────────────
                            Column {
                                id: cardMidCol
                                anchors.top: cardBanner.bottom
                                anchors.topMargin: 10
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 14
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: modelData.name || modelData.id
                                    color: Theme.foreground
                                    font.family: "Outfit"
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: "by " + (modelData.author || "Community") + " • v" + (modelData.version || "1.0.0")
                                    color: Theme.alpha(Theme.foreground, 0.50)
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }

                            // ── Bottom: Description ──────────────────────────
                            Text {
                                id: cardDesc
                                anchors.top: cardMidCol.bottom
                                anchors.topMargin: 8
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 14
                                text: modelData.description || ""
                                color: Theme.alpha(Theme.foreground, 0.68)
                                font.family: "Outfit"
                                font.pixelSize: 12
                                lineHeight: 1.25
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }

                            // ── Footer: Action Row ───────────────────────────
                            RowLayout {
                                z: 5
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 12
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 14

                                // View Details link
                                Text {
                                    text: "View Details →"
                                    color: cardMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.45)
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                }

                                Item { Layout.fillWidth: true }

                                // Quick Action: Toggle switch if installed, Install button if available
                                Loader {
                                    active: modelData.installed
                                    sourceComponent: CapsuleSwitch {
                                        checked: modelData.enabled
                                        onToggled: root.togglePlugin(modelData.id, checked)
                                    }
                                }

                                Loader {
                                    active: !modelData.installed
                                    sourceComponent: Rectangle {
                                        height: 28
                                        width: quickInstallRow.implicitWidth + 18
                                        radius: 8
                                        color: quickInstallMouse.containsMouse ? Theme.alpha(Theme.accent, 0.85) : Theme.accent

                                        Row {
                                            id: quickInstallRow
                                            anchors.centerIn: parent
                                            spacing: 4

                                            Image {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 12
                                                height: 12
                                                source: root.downloadSvg
                                                sourceSize: Qt.size(24, 24)
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Get"
                                                color: Theme.on_primary
                                                font.family: "Outfit"
                                                font.pixelSize: 11
                                                font.weight: Font.DemiBold
                                            }
                                        }

                                        MouseArea {
                                            id: quickInstallMouse
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.installPlugin(modelData.id)
                                        }
                                    }
                                }
                            }

                            // Card click to open Detail Page
                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedPlugin = modelData
                            }
                        }
                    }

                    // Empty State Card
                    Rectangle {
                        width: parent.width
                        height: 140
                        radius: 16
                        visible: (root.activeTab === "installed" ? root.installedList.length : root.availableList.length) === 0
                        color: Theme.alpha(Theme.surface, 0.30)
                        border.color: Theme.alpha(Theme.accent, 0.15)
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.activeTab === "installed" ? "No plugins installed yet" : "All catalog plugins are installed"
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 15
                                font.weight: Font.Medium
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.activeTab === "installed" ? "Explore the Available Catalog tab or drag and drop a plugin folder above." : "Check back later for newly published community extensions."
                                color: Theme.alpha(Theme.foreground, 0.50)
                                font.family: "Outfit"
                                font.pixelSize: 12
                            }
                        }
                    }
                }
            }
        }

        // ══════════════════════════════════════════════════════════════════════
        // VIEW 2: PLUGIN DETAIL PAGE
        // ══════════════════════════════════════════════════════════════════════
        Flickable {
            id: detailFlickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: detailCol.implicitHeight + 60
            clip: true
            visible: root.selectedPlugin !== null

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            ColumnLayout {
                id: detailCol
                width: parent.width
                spacing: 20

                // ── Hero Banner Card ─────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: heroRow.implicitHeight + 40
                    radius: 18
                    color: Theme.alpha(Theme.surface, 0.48)
                    border.color: Theme.alpha(Theme.accent, 0.22)
                    border.width: 1
                    clip: true

                    // Ambient glow backdrop
                    Rectangle {
                        width: 200
                        height: 200
                        radius: 100
                        x: -50
                        y: -50
                        color: Theme.alpha(Theme.accent, 0.10)
                    }

                    RowLayout {
                        id: heroRow
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 20

                        // Large Plugin Icon
                        Rectangle {
                            width: 76
                            height: 76
                            radius: 18
                            color: "transparent"
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: root.selectedPlugin ? root.getPluginIconSource(root.selectedPlugin) : ""
                                sourceSize: Qt.size(152, 152)
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                            }
                        }

                        // Title & Meta Info
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: root.selectedPlugin ? root.selectedPlugin.name : ""
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 22
                                font.weight: Font.Bold
                            }

                            // Meta Chips Row
                            Row {
                                spacing: 8

                                // Category Chip
                                Rectangle {
                                    height: 22
                                    width: detCatText.implicitWidth + 14
                                    radius: 6
                                    color: Theme.alpha(Theme.accent, 0.18)

                                    Text {
                                        id: detCatText
                                        anchors.centerIn: parent
                                        text: root.selectedPlugin ? (root.selectedPlugin.category || "Extension") : ""
                                        color: Theme.accent
                                        font.family: "Outfit"
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                }

                                // Version Chip
                                Rectangle {
                                    height: 22
                                    width: detVerText.implicitWidth + 14
                                    radius: 6
                                    color: Theme.alpha(Theme.surface, 0.80)

                                    Text {
                                        id: detVerText
                                        anchors.centerIn: parent
                                        text: "v" + (root.selectedPlugin ? (root.selectedPlugin.version || "1.0.0") : "1.0.0")
                                        color: Theme.alpha(Theme.foreground, 0.75)
                                        font.family: "Outfit"
                                        font.pixelSize: 11
                                    }
                                }

                                // Author Chip
                                Rectangle {
                                    height: 22
                                    width: detAuthorText.implicitWidth + 14
                                    radius: 6
                                    color: Theme.alpha(Theme.surface, 0.80)

                                    Text {
                                        id: detAuthorText
                                        anchors.centerIn: parent
                                        text: "by " + (root.selectedPlugin ? (root.selectedPlugin.author || "Community") : "")
                                        color: Theme.alpha(Theme.foreground, 0.75)
                                        font.family: "Outfit"
                                        font.pixelSize: 11
                                    }
                                }
                            }

                            // Tagline
                            Text {
                                Layout.fillWidth: true
                                text: root.selectedPlugin ? (root.selectedPlugin.tagline || root.selectedPlugin.description || "") : ""
                                color: Theme.alpha(Theme.foreground, 0.75)
                                font.family: "Outfit"
                                font.pixelSize: 13
                                wrapMode: Text.WordWrap
                            }
                        }

                        // Hero Action Area
                        Column {
                            spacing: 10
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                            // If installed: Switch + Uninstall button
                            Row {
                                spacing: 12
                                visible: root.selectedPlugin && root.selectedPlugin.installed

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        text: root.selectedPlugin && root.selectedPlugin.enabled ? "Active" : "Disabled"
                                        color: root.selectedPlugin && root.selectedPlugin.enabled ? "#22c55e" : Theme.alpha(Theme.foreground, 0.50)
                                        font.family: "Outfit"
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }

                                CapsuleSwitch {
                                    anchors.verticalCenter: parent.verticalCenter
                                    checked: root.selectedPlugin ? root.selectedPlugin.enabled : false
                                    onToggled: {
                                        if (root.selectedPlugin) root.togglePlugin(root.selectedPlugin.id, checked)
                                    }
                                }

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 36
                                    height: 36
                                    radius: 10
                                    color: detTrashMouse.containsMouse ? Theme.alpha(Theme.error || "#ef4444", 0.30) : Theme.alpha(Theme.surface, 0.60)
                                    border.color: detTrashMouse.containsMouse ? (Theme.error || "#ef4444") : Theme.alpha(Theme.foreground, 0.15)
                                    border.width: 1

                                    Image {
                                        anchors.centerIn: parent
                                        width: 16
                                        height: 16
                                        source: root.trashSvg
                                        sourceSize: Qt.size(32, 32)
                                    }

                                    MouseArea {
                                        id: detTrashMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.selectedPlugin) root.uninstallPlugin(root.selectedPlugin.id)
                                        }
                                    }
                                }
                            }

                            // If available: Install Button
                            Rectangle {
                                visible: root.selectedPlugin && !root.selectedPlugin.installed
                                height: 40
                                width: detInstallRow.implicitWidth + 32
                                radius: 12
                                color: detInstallMouse.containsMouse ? Theme.alpha(Theme.accent, 0.85) : Theme.accent
                                border.color: Theme.alpha(Theme.foreground, 0.20)
                                border.width: 1

                                Row {
                                    id: detInstallRow
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Image {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 16
                                        height: 16
                                        source: root.downloadSvg
                                        sourceSize: Qt.size(32, 32)
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Install Plugin"
                                        color: Theme.on_primary
                                        font.family: "Outfit"
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                    }
                                }

                                MouseArea {
                                    id: detInstallMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.selectedPlugin) root.installPlugin(root.selectedPlugin.id)
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Overview & About Card ────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: aboutCol.implicitHeight + 36
                    radius: 16
                    color: Theme.alpha(Theme.surface, 0.40)
                    border.color: Theme.alpha(Theme.accent, 0.18)
                    border.width: 1

                    ColumnLayout {
                        id: aboutCol
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 12

                        Text {
                            text: "About this Plugin"
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.selectedPlugin ? root.selectedPlugin.description : ""
                            color: Theme.alpha(Theme.foreground, 0.80)
                            font.family: "Outfit"
                            font.pixelSize: 13
                            lineHeight: 1.35
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                // ── Key Features Card ────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: featuresCol.implicitHeight + 36
                    radius: 16
                    color: Theme.alpha(Theme.surface, 0.40)
                    border.color: Theme.alpha(Theme.accent, 0.18)
                    border.width: 1
                    visible: root.selectedPlugin && root.selectedPlugin.features && root.selectedPlugin.features.length > 0

                    ColumnLayout {
                        id: featuresCol
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 14

                        Text {
                            text: "Key Features & Capabilities"
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }

                        Repeater {
                            model: root.selectedPlugin ? (root.selectedPlugin.features || []) : []

                            delegate: RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                Rectangle {
                                    width: 22
                                    height: 22
                                    radius: 11
                                    color: Theme.alpha(Theme.accent, 0.20)

                                    Image {
                                        anchors.centerIn: parent
                                        width: 12
                                        height: 12
                                        source: root.checkSvg
                                        sourceSize: Qt.size(24, 24)
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData
                                    color: Theme.alpha(Theme.foreground, 0.85)
                                    font.family: "Outfit"
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }

                // ── Supported Environments & Targets ─────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: targetsCol.implicitHeight + 36
                    radius: 16
                    color: Theme.alpha(Theme.surface, 0.40)
                    border.color: Theme.alpha(Theme.accent, 0.18)
                    border.width: 1
                    visible: root.selectedPlugin && root.selectedPlugin.targets && root.selectedPlugin.targets.length > 0

                    ColumnLayout {
                        id: targetsCol
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 14

                        Text {
                            text: "Supported Applications & Targets"
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 10

                            Repeater {
                                model: root.selectedPlugin ? (root.selectedPlugin.targets || []) : []

                                delegate: Rectangle {
                                    height: 32
                                    width: targetItemRow.implicitWidth + 24
                                    radius: 10
                                    color: Theme.alpha(Theme.surface, 0.70)
                                    border.color: Theme.alpha(Theme.accent, 0.25)
                                    border.width: 1

                                    Row {
                                        id: targetItemRow
                                        anchors.centerIn: parent
                                        spacing: 8

                                        Image {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 14
                                            height: 14
                                            source: root.checkCircleSvg
                                            sourceSize: Qt.size(28, 28)
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData
                                            color: Theme.foreground
                                            font.family: "Outfit"
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Technical Metadata & Hooks ───────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: metaGridCol.implicitHeight + 36
                    radius: 16
                    color: Theme.alpha(Theme.surface, 0.40)
                    border.color: Theme.alpha(Theme.accent, 0.18)
                    border.width: 1

                    ColumnLayout {
                        id: metaGridCol
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 14

                        Text {
                            text: "Integration & Technical Details"
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }

                        GridLayout {
                            columns: 2
                            rowSpacing: 10
                            columnSpacing: 20
                            Layout.fillWidth: true

                            Text {
                                text: "Plugin Identifier:"
                                color: Theme.alpha(Theme.foreground, 0.50)
                                font.family: "Outfit"
                                font.pixelSize: 12
                            }
                            Text {
                                text: root.selectedPlugin ? root.selectedPlugin.id : ""
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "Desktop Compatibility:"
                                color: Theme.alpha(Theme.foreground, 0.50)
                                font.family: "Outfit"
                                font.pixelSize: 12
                            }
                            Text {
                                text: "Hyprconf " + (root.selectedPlugin ? (root.selectedPlugin.min_version || "v1.0.3+") : "v1.0.3+")
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "Lifecycle Hooks:"
                                color: Theme.alpha(Theme.foreground, 0.50)
                                font.family: "Outfit"
                                font.pixelSize: 12
                            }
                            Text {
                                text: root.selectedPlugin && root.selectedPlugin.hooks ? Object.keys(root.selectedPlugin.hooks).join(", ") : "on_wallpaper_change, on_color_change"
                                color: Theme.accent
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "Installation Path:"
                                color: Theme.alpha(Theme.foreground, 0.50)
                                font.family: "Outfit"
                                font.pixelSize: 12
                            }
                            Text {
                                text: "~/.local/share/hyprconf/plugins/" + (root.selectedPlugin ? root.selectedPlugin.id : "")
                                color: Theme.alpha(Theme.foreground, 0.70)
                                font.family: "Outfit"
                                font.pixelSize: 11
                            }
                        }
                    }
                }
            }
        }
    }
}
