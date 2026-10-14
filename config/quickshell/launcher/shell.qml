import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Widgets

PanelWindow {
    id: root

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    onClosed: Qt.quit()

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-launcher"

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : "/home/shell-ninja"
    }

    readonly property string quadWallPath: "file://" + homeDir + "/.hyprconf/hypr/.cache/wall.quad"
    readonly property string fallbackWallPath: "file://" + homeDir + "/.hyprconf/hypr/.cache/current_wallpaper.png"

    // Model and filtering state
    property var allApps: []
    property var filteredApps: []
    property string activeCategory: "All"
    property int selectedIndex: 0
    property string searchQuery: ""

    // SVG icon helpers
    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string searchSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>')
    readonly property string clearSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.muted + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>')
    readonly property string defaultAppSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect><circle cx="8.5" cy="8.5" r="1.5"></circle><polyline points="21 15 16 10 5 21"></polyline></svg>')
    readonly property string enterKeySvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 10 4 15 9 20"></polyline><path d="M20 4v7a4 4 0 0 1-4 4H4"></path></svg>')

    // Filter applications based on search text and active category
    function updateFilteredApps() {
        var q = searchQuery.toLowerCase().trim()
        var cat = activeCategory
        var res = []

        for (var i = 0; i < allApps.length; i++) {
            var app = allApps[i]

            // Category match
            if (cat !== "All") {
                var categories = app.categories || []
                var catMatched = false
                for (var c = 0; c < categories.length; c++) {
                    var curCat = categories[c].toLowerCase()
                    if (cat === "Internet" && (curCat.indexOf("network") !== -1 || curCat.indexOf("web") !== -1 || curCat.indexOf("browser") !== -1)) {
                        catMatched = true; break
                    } else if (cat === "Development" && (curCat.indexOf("development") !== -1 || curCat.indexOf("ide") !== -1 || curCat.indexOf("programming") !== -1)) {
                        catMatched = true; break
                    } else if (cat === "Media" && (curCat.indexOf("audio") !== -1 || curCat.indexOf("video") !== -1 || curCat.indexOf("graphics") !== -1 || curCat.indexOf("media") !== -1)) {
                        catMatched = true; break
                    } else if (cat === "System" && (curCat.indexOf("system") !== -1 || curCat.indexOf("utility") !== -1 || curCat.indexOf("settings") !== -1)) {
                        catMatched = true; break
                    }
                }
                if (!catMatched) continue
            }

            // Search query match
            if (q.length === 0) {
                res.push(app)
            } else {
                var key = (app.search_key || "").toLowerCase()
                var name = (app.name || "").toLowerCase()
                var cmd = (app.exec || "").toLowerCase()

                if (name.indexOf(q) !== -1 || key.indexOf(q) !== -1 || cmd.indexOf(q) !== -1) {
                    res.push(app)
                }
            }
        }

        filteredApps = res
        selectedIndex = 0
        if (appListView.count > 0) {
            appListView.positionViewAtIndex(0, ListView.Beginning)
        }
    }

    // Launch application and exit cleanly
    Process {
        id: execProc
        onRunningChanged: {
            if (!running) {
                Qt.quit()
            }
        }
    }

    Timer {
        id: quitTimer
        interval: 180
        repeat: false
        onTriggered: Qt.quit()
    }

    function launchApp(app) {
        if (!app) return
        var script = homeDir + "/.hyprconf/hypr/scripts/launch-app.sh"
        execProc.command = [script, app.id || "", app.exec || ""]
        execProc.running = true
        root.visible = false
        quitTimer.start()
    }

    function launchCurrent() {
        if (filteredApps && filteredApps.length > 0 && selectedIndex >= 0 && selectedIndex < filteredApps.length) {
            launchApp(filteredApps[selectedIndex])
        }
    }

    // Load applications index
    Process {
        id: indexerProc
        command: [homeDir + "/.hyprconf/hypr/scripts/app-launcher-index.py"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(text)
                        root.allApps = parsed
                        root.updateFilteredApps()
                    } catch(e) {
                        console.log("[launcher] Failed to parse apps JSON:", e)
                    }
                }
            }
        }
    }

    // Global keyboard navigation
    Shortcut {
        sequence: "Escape"
        onActivated: Qt.quit()
    }

    // 100% transparent click-outside-to-dismiss area (NO screen dimming or tint)
    MouseArea {
        anchors.fill: parent
        onClicked: Qt.quit()
    }

    // =========================================================================
    // Central Launcher Card (ClippingRectangle ensures left corners are rounded!)
    // Dimensions proportioned to 58em x 28em: width 880px, height 420px
    // =========================================================================
    ClippingRectangle {
        id: card
        width: 880
        height: 420
        anchors.centerIn: parent
        radius: 20
        color: Theme.alpha(Theme.surface, 0.98)
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.35)

        // Catch clicks inside card so they don't dismiss the launcher
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        // =====================================================================
        // LEFT SECTION (1 & 3): Wallpaper Quad Image + Slanted Transition
        // Takes ~49% of width (430px out of 880px), matching Rofi's 28.5em / 58em
        // =====================================================================
        Item {
            id: leftSection
            width: 415
            height: parent.height
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            Image {
                id: quadImage
                anchors.fill: parent
                source: root.quadWallPath
                fillMode: Image.Stretch
                smooth: true
                mipmap: true
                asynchronous: true

                onStatusChanged: {
                    if (status === Image.Error) {
                        source = root.fallbackWallPath
                    }
                }
            }

            // Subtle gradient for contrast on top brand text
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.alpha(Theme.background, 0.20) }
                    GradientStop { position: 0.35; color: "transparent" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // Brand / Title Overlay at Top Left of Image
            RowLayout {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 18
                spacing: 8

                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: Theme.accent
                }

                Text {
                    text: "APPLICATIONS"
                    font.family: "Outfit"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.5
                    color: Theme.alpha(Theme.foreground, 0.90)
                }
            }
        }

        // =====================================================================
        // RIGHT SECTION (2): Search Box, Categories, Application List
        // Positioned cleanly off the quad image transition band
        // =====================================================================
        Item {
            id: rightSection
            x: 438
            width: card.width - x - 20
            height: parent.height - 30
            anchors.verticalCenter: parent.verticalCenter

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                // ── Search Bar ───────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: 12
                    color: Theme.alpha(Theme.background, 0.75)
                    border.width: searchInput.activeFocus ? 1.5 : 1
                    border.color: searchInput.activeFocus ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)

                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        spacing: 8

                        Image {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            source: root.searchSvg
                            sourceSize: Qt.size(32, 32)
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            font.family: "Outfit"
                            font.pixelSize: 14
                            color: Theme.foreground
                            selectByMouse: true
                            selectionColor: Theme.alpha(Theme.accent, 0.40)
                            selectedTextColor: Theme.foreground
                            focus: true

                            Text {
                                text: "Type to search applications..."
                                font.family: "Outfit"
                                font.pixelSize: 13
                                color: Theme.alpha(Theme.foreground, 0.40)
                                visible: !searchInput.text && !searchInput.inputMethodComposing
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            onTextChanged: {
                                root.searchQuery = text
                                root.updateFilteredApps()
                            }

                            Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_Down) {
                                    if (root.filteredApps.length > 0) {
                                        root.selectedIndex = Math.min(root.selectedIndex + 1, root.filteredApps.length - 1)
                                        appListView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Up) {
                                    if (root.filteredApps.length > 0) {
                                        root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
                                        appListView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                                    }
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.launchCurrent()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Escape) {
                                    Qt.quit()
                                    event.accepted = true
                                }
                            }
                        }

                        // Clear input button
                        Rectangle {
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 18
                            radius: 9
                            color: clearMouse.containsMouse ? Theme.alpha(Theme.surface, 0.8) : "transparent"
                            visible: searchInput.text.length > 0

                            Image {
                                anchors.centerIn: parent
                                width: 11
                                height: 11
                                source: root.clearSvg
                                sourceSize: Qt.size(22, 22)
                            }

                            MouseArea {
                                id: clearMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    searchInput.text = ""
                                    searchInput.forceActiveFocus()
                                }
                            }
                        }
                    }
                }

                // ── Category Pills ───────────────────────────────────────────
                Row {
                    Layout.fillWidth: true
                    spacing: 5

                    Repeater {
                        model: ["All", "Internet", "Development", "Media", "System"]

                        Rectangle {
                            height: 24
                            width: catText.implicitWidth + 16
                            radius: 12
                            color: root.activeCategory === modelData
                                ? Theme.alpha(Theme.accent, 0.25)
                                : (catMouse.containsMouse ? Theme.alpha(Theme.surface, 0.70) : Theme.alpha(Theme.surface, 0.40))
                            border.width: 1
                            border.color: root.activeCategory === modelData
                                ? Theme.alpha(Theme.accent, 0.60)
                                : Theme.alpha(Theme.accent, 0.12)

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                id: catText
                                anchors.centerIn: parent
                                text: modelData
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: root.activeCategory === modelData ? Font.DemiBold : Font.Normal
                                color: root.activeCategory === modelData ? Theme.accent : Theme.alpha(Theme.foreground, 0.80)
                            }

                            MouseArea {
                                id: catMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.activeCategory = modelData
                                    root.updateFilteredApps()
                                    searchInput.forceActiveFocus()
                                }
                            }
                        }
                    }
                }

                // ── Application List ─────────────────────────────────────────
                ListView {
                    id: appListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    spacing: 4
                    model: root.filteredApps

                    delegate: Rectangle {
                        id: delegateItem
                        width: appListView.width
                        height: 44
                        radius: 10

                        readonly property bool isSelected: index === root.selectedIndex
                        readonly property bool isHovered: itemMouse.containsMouse

                        color: isSelected
                            ? Theme.alpha(Theme.accent, 0.22)
                            : (isHovered ? Theme.alpha(Theme.surface, 0.50) : "transparent")

                        border.width: isSelected ? 1 : (isHovered ? 1 : 0)
                        border.color: isSelected
                            ? Theme.alpha(Theme.accent, 0.55)
                            : Theme.alpha(Theme.accent, 0.18)

                        Behavior on color { ColorAnimation { duration: 120 } }

                        // Left Active Glow Indicator Strip
                        Rectangle {
                            width: 3
                            height: 18
                            radius: 1.5
                            anchors.left: parent.left
                            anchors.leftMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.accent
                            visible: delegateItem.isSelected
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            // App Icon
                            Rectangle {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                radius: 7
                                color: Theme.alpha(Theme.surface, 0.65)
                                border.width: 1
                                border.color: Theme.alpha(Theme.foreground, 0.08)

                                Image {
                                    anchors.centerIn: parent
                                    width: 22
                                    height: 22
                                    source: (modelData.icon_path && modelData.icon_path.length > 0)
                                        ? modelData.icon_path
                                        : root.defaultAppSvg
                                    sourceSize: Qt.size(44, 44)
                                    smooth: true
                                    mipmap: true

                                    onStatusChanged: {
                                        if (status === Image.Error) {
                                            source = root.defaultAppSvg
                                        }
                                    }
                                }
                            }

                            // App Title and Description
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name || ""
                                    font.family: "Outfit"
                                    font.pixelSize: 13
                                    font.weight: delegateItem.isSelected ? Font.DemiBold : Font.Medium
                                    color: delegateItem.isSelected ? Theme.accent : Theme.foreground
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.comment || modelData.generic_name || modelData.exec || ""
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    color: Theme.alpha(Theme.foreground, 0.50)
                                    elide: Text.ElideRight
                                    visible: text.length > 0
                                }
                            }

                            // Launch Hint Indicator (when selected)
                            Image {
                                Layout.preferredWidth: 13
                                Layout.preferredHeight: 13
                                source: root.enterKeySvg
                                sourceSize: Qt.size(26, 26)
                                visible: delegateItem.isSelected
                                opacity: 0.85
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.selectedIndex = index
                            onClicked: {
                                var target = (root.filteredApps && root.filteredApps.length > index) ? root.filteredApps[index] : modelData
                                root.launchApp(target)
                            }
                        }
                    }

                    // Empty State Message
                    Item {
                        anchors.fill: parent
                        visible: root.filteredApps.length === 0

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "No matching applications"
                                font.family: "Outfit"
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: Theme.alpha(Theme.foreground, 0.70)
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: "Try searching with a different term"
                                font.family: "Outfit"
                                font.pixelSize: 11
                                color: Theme.alpha(Theme.foreground, 0.40)
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }

                // ── Footer Keyboard Navigation Hints ─────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: root.filteredApps.length + " of " + root.allApps.length + " apps"
                        font.family: "Outfit"
                        font.pixelSize: 10
                        color: Theme.alpha(Theme.foreground, 0.45)
                    }

                    Item { Layout.fillWidth: true }

                    Row {
                        spacing: 8

                        Row {
                            spacing: 3
                            Rectangle { width: 14; height: 14; radius: 3; color: Theme.alpha(Theme.surface, 0.6); Text { text: "↑↓"; font.pixelSize: 9; color: Theme.muted; anchors.centerIn: parent } }
                            Text { text: "navigate"; font.family: "Outfit"; font.pixelSize: 10; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                        }

                        Row {
                            spacing: 3
                            Rectangle { width: 14; height: 14; radius: 3; color: Theme.alpha(Theme.surface, 0.6); Text { text: "↵"; font.pixelSize: 9; color: Theme.muted; anchors.centerIn: parent } }
                            Text { text: "launch"; font.family: "Outfit"; font.pixelSize: 10; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                        }

                        Row {
                            spacing: 3
                            Rectangle { width: 14; height: 14; radius: 3; color: Theme.alpha(Theme.surface, 0.6); Text { text: "esc"; font.pixelSize: 9; color: Theme.muted; anchors.centerIn: parent } }
                            Text { text: "close"; font.family: "Outfit"; font.pixelSize: 10; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                }
            }
        }
    }
}
