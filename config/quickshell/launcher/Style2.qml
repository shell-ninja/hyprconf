import QtQuick.Shapes
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import "."

// Style 2: Panoramic Grid Launcher (820x560 with wallpaper banner, compact 6x2 grid & 3-pill mode switcher)
ClippingRectangle {
    id: card
    width: (rootWindow && rootWindow.isIslandView && parent) ? parent.width : 820
    height: (rootWindow && rootWindow.isIslandView && parent) ? parent.height : 560
    anchors.fill: (rootWindow && rootWindow.isIslandView) ? parent : undefined
    anchors.centerIn: (rootWindow && rootWindow.isIslandView) ? undefined : parent
    radius: (rootWindow && rootWindow.isIslandView && rootWindow.animProgress !== undefined)
            ? (18 + (26 - 18) * rootWindow.animProgress) : 26
    color: "transparent"
    border.width: (rootWindow && rootWindow.isIslandView) ? 0 : 1
    border.color: Theme.alpha(Theme.foreground, 0.14)

    readonly property real splitY: 240
    readonly property real cornerR: 24

    required property var rootWindow

    focus: true

    function focusInput() {
        searchInput.forceActiveFocus()
        searchInput.selectAll()
    }

    Timer {
        id: autoFocusTimer
        interval: 60
        running: true
        repeat: false
        onTriggered: focusInput()
    }

    Component.onCompleted: {
        focusInput()
    }

    function triggerClose() {
        if (rootWindow) {
            if (typeof rootWindow.closeRequested === "function") rootWindow.closeRequested()
            else if (typeof rootWindow.requestClose === "function") rootWindow.requestClose()
        }
    }

    // BeforeItem: card-level Escape intercept fires before Qt native handling
    Keys.priority: Keys.BeforeItem
    Keys.onEscapePressed: function(event) {
        event.accepted = true
        card.triggerClose()
    }
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            event.accepted = true
            card.triggerClose()
            return
        }
    }

    // Active Mode: 0: "drun" (Applications), 1: "categories" (Category Filter), 2: "window" (Active Windows)
    property int activeMode: 0

    onActiveModeChanged: {
        if (activeMode === 0) {
            rootWindow.activeCategory = "All"
            rootWindow.updateFilteredApps()
        } else if (activeMode === 2) {
            windowsFetcher.running = true
            filterWindows()
        }
        focusInput()
    }

    // Running Windows State for Mode 2
    property var activeWindows: []
    property var filteredWindows: []

    function filterWindows() {
        var q = (rootWindow.searchQuery || "").toLowerCase().trim()
        if (!activeWindows || activeWindows.length === 0) {
            filteredWindows = []
            return
        }
        if (q.length === 0) {
            filteredWindows = activeWindows
            if (windowsGrid) windowsGrid.currentIndex = 0
            return
        }

        var tokens = q.split(/\s+/).filter(function(t) { return t.length > 0 })
        var scored = []

        for (var i = 0; i < activeWindows.length; i++) {
            var w = activeWindows[i]
            var title = (w.title || "").toLowerCase()
            var wclass = (w.class || "").toLowerCase()
            var initClass = (w.initialClass || "").toLowerCase()
            var initTitle = (w.initialTitle || "").toLowerCase()
            var ws = (w.workspace ? (w.workspace.name || "") : "").toLowerCase()
            var fullBlob = title + " " + wclass + " " + initClass + " " + initTitle + " " + ws

            var allMatch = true
            for (var t = 0; t < tokens.length; t++) {
                if (fullBlob.indexOf(tokens[t]) === -1) {
                    allMatch = false
                    break
                }
            }
            if (!allMatch) continue

            var score = 0
            if (title === q || wclass === q) score += 10000
            else if (title.startsWith(q) || wclass.startsWith(q)) score += 6000
            else if (title.indexOf(" " + q) !== -1 || wclass.indexOf("-" + q) !== -1) score += 4000
            else if (title.indexOf(q) !== -1 || wclass.indexOf(q) !== -1) score += 2000

            for (var t = 0; t < tokens.length; t++) {
                var tok = tokens[t]
                if (title.startsWith(tok) || wclass.startsWith(tok)) score += 1000
                else if (title.indexOf(tok) !== -1 || wclass.indexOf(tok) !== -1) score += 400
            }

            scored.push({ win: w, score: score })
        }

        scored.sort(function(a, b) {
            return b.score - a.score
        })

        var res = []
        for (var s = 0; s < scored.length; s++) {
            res.push(scored[s].win)
        }
        filteredWindows = res
        if (windowsGrid) windowsGrid.currentIndex = 0
    }

    onActiveWindowsChanged: filterWindows()

    Process {
        id: windowsFetcher
        command: ["hyprctl", "clients", "-j"]
        running: card.activeMode === 2
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(text)
                        var valid = []
                        for (var i = 0; i < parsed.length; i++) {
                            var w = parsed[i]
                            if (w.mapped && !w.hidden && w.title) {
                                valid.push(w)
                            }
                        }
                        card.activeWindows = valid
                    } catch(e) {}
                }
            }
        }
    }

    Process {
        id: windowFocuser
        command: []
    }

    function focusWindow(address) {
        if (!address) return
        windowFocuser.command = ["hyprctl", "dispatch", "focuswindow", "address:" + address]
        windowFocuser.running = true
        if (rootWindow && rootWindow.isIslandView) {
            rootWindow.closeRequested()
        } else {
            rootWindow.visible = false
            Qt.quit()
        }
    }

    // Catch clicks inside card
    MouseArea {
        anchors.fill: parent
        onClicked: {}
    }

    // ── TOP SECTION: Panoramic Wallpaper Banner (Image in top side of launcher) ──
    Item {
        id: wallBannerContainer
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: card.splitY + card.cornerR

        // Raw Wallpaper Source Image
        Image {
            id: rawWallBanner
            anchors.fill: parent
            source: rootWindow.fallbackWallPath
            fillMode: Image.PreserveAspectCrop
            smooth: true
            mipmap: true
            cache: false
            asynchronous: true
            visible: false
        }

        // Top Banner Mask: Matches downward rounded corners at split
        Item {
            id: bannerMask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            layer.smooth: true

            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    ctx.fillStyle = "#ffffff"
                    ctx.beginPath()
                    ctx.moveTo(0, 0)
                    ctx.lineTo(width, 0)
                    ctx.lineTo(width, card.splitY + card.cornerR)
                    ctx.arcTo(width, card.splitY, width - card.cornerR, card.splitY, card.cornerR)
                    ctx.lineTo(card.cornerR, card.splitY)
                    ctx.arcTo(0, card.splitY, 0, card.splitY + card.cornerR, card.cornerR)
                    ctx.lineTo(0, card.splitY + card.cornerR)
                    ctx.closePath()
                    ctx.fill()
                }
            }
        }

        // Masked Banner Image
        MultiEffect {
            anchors.fill: parent
            source: rawWallBanner
            visible: rawWallBanner.status === Image.Ready
            autoPaddingEnabled: false
            maskEnabled: true
            maskSource: bannerMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }

        // ── Floating Inputbar (Search Bar) ───────────────────────────────
        Rectangle {
            id: inputbar
            anchors.top: parent.top
            anchors.topMargin: 18
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 48
            height: 48
            radius: 24
            color: Theme.alpha(Theme.background, 0.92)
            border.width: 1.5
            border.color: searchInput.activeFocus ? Theme.accent : Theme.alpha(Theme.foreground, 0.18)
            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 16
                spacing: 12

                // Vector Search Icon
                Image {
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    source: rootWindow.searchSvg
                    fillMode: Image.PreserveAspectFit
                }

                // Search TextInput
                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    font.family: "Outfit"
                    font.pixelSize: 14
                    color: Theme.foreground
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.on_primary
                    clip: true
                    focus: true

                    Text {
                        anchors.fill: parent
                        text: card.activeMode === 2 ? "Search open windows..." : "Search applications..."
                        font: parent.font
                        color: Theme.muted
                        visible: parent.text.length === 0
                        verticalAlignment: Text.AlignVCenter
                    }

                    onTextChanged: {
                        rootWindow.searchQuery = text
                        if (card.activeMode === 2) {
                            card.filterWindows()
                        } else {
                            rootWindow.updateFilteredApps()
                        }
                    }

                    Keys.onDownPressed: {
                        if (card.activeMode === 2) {
                            if (windowsGrid.count > 0) {
                                windowsGrid.currentIndex = Math.min(windowsGrid.count - 1, windowsGrid.currentIndex + 3)
                            }
                        } else {
                            if (appGrid.count > 0) {
                                rootWindow.selectedIndex = Math.min(appGrid.count - 1, rootWindow.selectedIndex + 6)
                                appGrid.positionViewAtIndex(rootWindow.selectedIndex, GridView.Contain)
                            }
                        }
                    }

                    Keys.onUpPressed: {
                        if (card.activeMode === 2) {
                            if (windowsGrid.count > 0) {
                                windowsGrid.currentIndex = Math.max(0, windowsGrid.currentIndex - 3)
                            }
                        } else {
                            if (appGrid.count > 0) {
                                rootWindow.selectedIndex = Math.max(0, rootWindow.selectedIndex - 6)
                                appGrid.positionViewAtIndex(rootWindow.selectedIndex, GridView.Contain)
                            }
                        }
                    }

                    Keys.onRightPressed: {
                        if (card.activeMode === 2) {
                            if (windowsGrid.count > 0) {
                                windowsGrid.currentIndex = Math.min(windowsGrid.count - 1, windowsGrid.currentIndex + 1)
                            }
                        } else {
                            if (appGrid.count > 0) {
                                rootWindow.selectedIndex = Math.min(appGrid.count - 1, rootWindow.selectedIndex + 1)
                                appGrid.positionViewAtIndex(rootWindow.selectedIndex, GridView.Contain)
                            }
                        }
                    }

                    Keys.onLeftPressed: {
                        if (card.activeMode === 2) {
                            if (windowsGrid.count > 0) {
                                windowsGrid.currentIndex = Math.max(0, windowsGrid.currentIndex - 1)
                            }
                        } else {
                            if (appGrid.count > 0) {
                                rootWindow.selectedIndex = Math.max(0, rootWindow.selectedIndex - 1)
                                appGrid.positionViewAtIndex(rootWindow.selectedIndex, GridView.Contain)
                            }
                        }
                    }

                    Keys.onTabPressed: {
                        card.activeMode = (card.activeMode + 1) % 3
                    }

                    Keys.onReturnPressed: {
                        if (card.activeMode === 2) {
                            if (card.filteredWindows.length > 0 && windowsGrid.currentIndex >= 0 && windowsGrid.currentIndex < card.filteredWindows.length) {
                                card.focusWindow(card.filteredWindows[windowsGrid.currentIndex].address)
                            }
                        } else {
                            rootWindow.launchCurrent()
                        }
                    }

                    // BeforeItem: fires BEFORE Qt's native TextInput C++ handler
                    // which may internally accept/consume Escape (for IME cancellation)
                    Keys.priority: Keys.BeforeItem
                    Keys.onEscapePressed: function(event) {
                        event.accepted = true
                        card.triggerClose()
                    }
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Escape) {
                            event.accepted = true
                            card.triggerClose()
                            return
                        }
                    }
                }

                // Clear button
                Rectangle {
                    visible: searchInput.text.length > 0
                    width: 22
                    height: 22
                    radius: 11
                    color: clearMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.15) : "transparent"

                    Image {
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        source: rootWindow.clearSvg
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

                // Theme selector button
                Rectangle {
                    width: 28
                    height: 28
                    radius: 8
                    color: themeMouse.containsMouse ? Theme.alpha(Theme.accent, 0.20) : "transparent"
                    border.width: 1
                    border.color: themeMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)

                    Image {
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        source: rootWindow.paletteSvg
                        fillMode: Image.PreserveAspectFit
                    }

                    MouseArea {
                        id: themeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rootWindow.openThemeSwitcher()
                    }
                }

                // Dedicated Close button (✕)
                Rectangle {
                    width: 28
                    height: 28
                    radius: 8
                    color: closeBtnMouse.containsMouse ? Theme.alpha("#ef4444", 0.25) : "transparent"
                    border.width: 1
                    border.color: closeBtnMouse.containsMouse ? "#ef4444" : Theme.alpha(Theme.foreground, 0.12)

                    Image {
                        anchors.centerIn: parent
                        width: 12
                        height: 12
                        source: rootWindow.closeSvg
                        fillMode: Image.PreserveAspectFit
                    }

                    MouseArea {
                        id: closeBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (rootWindow && typeof rootWindow.closeRequested === "function") {
                                rootWindow.closeRequested()
                            }
                        }
                    }
                }
            }
        }
    }

    // ── BOTTOM SECTION: App Menu (Matching image width, 65% opacity, blur bg) ─
    Item {
        id: listbox
        anchors.top: parent.top
        anchors.topMargin: card.splitY
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        // Obsidian Glass Background with downward-curved corners + plain border line
        Canvas {
            id: listboxBg
            anchors.fill: parent
            layer.enabled: true
            layer.smooth: true

            Connections {
                target: Theme
                function onBackgroundChanged() { listboxBg.requestPaint() }
                function onForegroundChanged() { listboxBg.requestPaint() }
            }

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()

                // Frosted obsidian glass fill (65% opacity)
                ctx.fillStyle = Theme.alpha(Theme.background, 0.65)
                ctx.beginPath()
                ctx.moveTo(0, card.cornerR)
                ctx.arcTo(0, 0, card.cornerR, 0, card.cornerR)
                ctx.lineTo(width - card.cornerR, 0)
                ctx.arcTo(width, 0, width, card.cornerR, card.cornerR)
                ctx.lineTo(width, height)
                ctx.lineTo(0, height)
                ctx.closePath()
                ctx.fill()

                // Plain border separation line at junction
                ctx.strokeStyle = Theme.alpha(Theme.foreground, 0.18)
                ctx.lineWidth = 1.5
                ctx.beginPath()
                ctx.moveTo(0, card.cornerR)
                ctx.arcTo(0, 0, card.cornerR, 0, card.cornerR)
                ctx.lineTo(width - card.cornerR, 0)
                ctx.arcTo(width, 0, width, card.cornerR, card.cornerR)
                ctx.stroke()
            }
        }

        // Category Bar overlay when in Mode 1 (Categories)
        Row {
            id: categoryBar
            visible: card.activeMode === 1
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            Repeater {
                model: ["All", "Internet", "Development", "Media", "System"]

                Rectangle {
                    height: 28
                    radius: 14
                    implicitWidth: catText2.implicitWidth + 20
                    color: rootWindow.activeCategory === modelData
                        ? Theme.accent
                        : (catMouse2.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.65))
                    border.width: 1
                    border.color: rootWindow.activeCategory === modelData
                        ? Theme.accent
                        : Theme.alpha(Theme.foreground, 0.15)

                    Text {
                        id: catText2
                        anchors.centerIn: parent
                        text: modelData
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: rootWindow.activeCategory === modelData ? Font.DemiBold : Font.Normal
                        color: rootWindow.activeCategory === modelData ? Theme.on_primary : Theme.foreground
                    }

                    MouseArea {
                        id: catMouse2
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            rootWindow.activeCategory = modelData
                            rootWindow.updateFilteredApps()
                            searchInput.forceActiveFocus()
                        }
                    }
                }
            }
        }

        // Middle Content Area: Mode 0 & 1 (Apps Grid) or Mode 2 (Windows Grid)
        Item {
            id: contentArea
            anchors.top: categoryBar.visible ? categoryBar.bottom : parent.top
            anchors.topMargin: categoryBar.visible ? 4 : 6
            anchors.bottom: modeSwitcherBar.top
            anchors.bottomMargin: 6
            anchors.left: parent.left
            anchors.right: parent.right

            // Mode 0 & 1: 6-Column x 2-Row Application Grid
            GridView {
                id: appGrid
                visible: card.activeMode !== 2
                anchors.centerIn: parent
                width: 720
                height: cellHeight * 2
                clip: true
                cellWidth: width / 6
                cellHeight: 112
                model: rootWindow.filteredApps
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: Theme.alpha(Theme.accent, 0.40)
                    }
                }

                delegate: Item {
                    width: appGrid.cellWidth
                    height: appGrid.cellHeight

                    Rectangle {
                        id: appTile
                        width: Math.min(parent.width - 10, 98)
                        height: 100
                        anchors.centerIn: parent
                        radius: 16
                        readonly property bool isSelected: index === rootWindow.selectedIndex

                        color: isSelected
                            ? Theme.alpha(Theme.accent, 0.16)
                            : (tileMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.06) : "transparent")
                        border.width: isSelected ? 1.5 : (tileMouse.containsMouse ? 1 : 0)
                        border.color: isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                        Behavior on color { ColorAnimation { duration: 90 } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 6
                            width: parent.width - 8

                            // Circular App Icon Container
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 46
                                height: 46
                                radius: 23
                                color: appTile.isSelected
                                    ? Theme.alpha(Theme.accent, 0.25)
                                    : (tileMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.10) : Theme.alpha(Theme.surface, 0.60))
                                border.width: 1
                                border.color: appTile.isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.10)

                                Image {
                                    anchors.centerIn: parent
                                    width: 30
                                    height: 30
                                    source: modelData.icon_path || ""
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    mipmap: true
                                    asynchronous: true

                                    onStatusChanged: {
                                        if (status === Image.Error || !modelData.icon_path) {
                                            source = rootWindow.defaultAppSvg
                                        }
                                    }
                                }
                            }

                            // App Name Text (Pill highlight on selection as in Rasi element-text selected)
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: Math.min(parent.width, appNameText.implicitWidth + 14)
                                height: 20
                                radius: 10
                                color: appTile.isSelected ? Theme.accent : "transparent"
                                Behavior on color { ColorAnimation { duration: 90 } }

                                Text {
                                    id: appNameText
                                    anchors.centerIn: parent
                                    text: modelData.name || "App"
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    font.weight: appTile.isSelected ? Font.DemiBold : Font.Normal
                                    color: appTile.isSelected ? Theme.on_primary : Theme.foreground
                                    elide: Text.ElideRight
                                    width: parent.parent.width - 6
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }

                        MouseArea {
                            id: tileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: rootWindow.selectedIndex = index
                            onClicked: rootWindow.launchApp(modelData)
                        }
                    }
                }

                // Empty state
                Item {
                    anchors.centerIn: parent
                    visible: rootWindow.filteredApps.length === 0
                    Column {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No applications found"
                            font.family: "Outfit"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: Theme.muted
                        }
                    }
                }
            }

            // Mode 2: Active Open Windows Grid
            GridView {
                id: windowsGrid
                visible: card.activeMode === 2
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                anchors.topMargin: 4
                anchors.bottomMargin: 4
                clip: true
                cellWidth: width / 3
                cellHeight: 74
                model: card.filteredWindows
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    width: windowsGrid.cellWidth
                    height: windowsGrid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 12
                        readonly property bool isSelected: index === windowsGrid.currentIndex
                        color: isSelected
                            ? Theme.alpha(Theme.accent, 0.18)
                            : (winMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.08) : Theme.alpha(Theme.surface, 0.50))
                        border.width: 1
                        border.color: isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.10)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                radius: 18
                                color: Theme.alpha(Theme.accent, 0.20)
                                Image {
                                    anchors.centerIn: parent
                                    width: 18
                                    height: 18
                                    source: rootWindow.windowSvg
                                    fillMode: Image.PreserveAspectFit
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: modelData.title || modelData.class || "Window"
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: Theme.foreground
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: (modelData.class || "") + " • Workspace " + (modelData.workspace ? modelData.workspace.name : "1")
                                    font.family: "Outfit"
                                    font.pixelSize: 9
                                    color: Theme.muted
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }
                        }

                        MouseArea {
                            id: winMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: card.focusWindow(modelData.address)
                        }
                    }
                }
            }
        }

        // Bottom Section: Mode Switcher (3 Horizontal Pill Buttons as in wireframe)
        Item {
            id: modeSwitcherBar
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            height: 38

            RowLayout {
                anchors.centerIn: parent
                width: parent.width - 60
                spacing: 16

                // Mode Button 1: Applications (drun)
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 18
                    readonly property bool isSelected: card.activeMode === 0
                    color: isSelected
                        ? Theme.accent
                        : (m1Mouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.45))
                    border.width: 1
                    border.color: isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Applications"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: parent.isSelected ? Font.Bold : Font.DemiBold
                        color: parent.isSelected ? Theme.on_primary : Theme.foreground
                    }

                    MouseArea {
                        id: m1Mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            card.activeMode = 0
                            searchInput.forceActiveFocus()
                        }
                    }
                }

                // Mode Button 2: Categories (filebrowser / category filter)
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 18
                    readonly property bool isSelected: card.activeMode === 1
                    color: isSelected
                        ? Theme.accent
                        : (m2Mouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.45))
                    border.width: 1
                    border.color: isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Categories"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: parent.isSelected ? Font.Bold : Font.DemiBold
                        color: parent.isSelected ? Theme.on_primary : Theme.foreground
                    }

                    MouseArea {
                        id: m2Mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            card.activeMode = 1
                            searchInput.forceActiveFocus()
                        }
                    }
                }

                // Mode Button 3: Windows (Active Hyprland Windows)
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 18
                    readonly property bool isSelected: card.activeMode === 2
                    color: isSelected
                        ? Theme.accent
                        : (m3Mouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.45))
                    border.width: 1
                    border.color: isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Windows"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: parent.isSelected ? Font.Bold : Font.DemiBold
                        color: parent.isSelected ? Theme.on_primary : Theme.foreground
                    }

                    MouseArea {
                        id: m3Mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            card.activeMode = 2
                            windowsFetcher.running = true
                            searchInput.forceActiveFocus()
                        }
                    }
                }
            }
        }
    }
}
