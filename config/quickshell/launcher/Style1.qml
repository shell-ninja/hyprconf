import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import "."

// Style 1: Slanted Split Quad Launcher (Widescreen 880x420)
ClippingRectangle {
    id: card
    width: (rootWindow && rootWindow.isIslandView && parent) ? parent.width : 880
    height: (rootWindow && rootWindow.isIslandView && parent) ? parent.height : 420
    anchors.fill: (rootWindow && rootWindow.isIslandView) ? parent : undefined
    anchors.centerIn: (rootWindow && rootWindow.isIslandView) ? undefined : parent
    radius: (rootWindow && rootWindow.isIslandView && rootWindow.animProgress !== undefined)
            ? (18 + (20 - 18) * rootWindow.animProgress) : 20
    color: (rootWindow && rootWindow.isIslandView) ? "transparent" : Theme.alpha(Theme.background, 0.78)
    border.width: (rootWindow && rootWindow.isIslandView) ? 0 : 1
    border.color: Theme.alpha(Theme.accent, 0.35)

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

    // Prevent background click from dismissing when clicking inside card
    MouseArea {
        anchors.fill: parent
        onClicked: {}
    }

    // =========================================================================
    // LEFT SECTION: Wallpaper Quad Image + Slanted Polygon Transition
    // =========================================================================
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
            property bool useFallback: false
            source: useFallback ? rootWindow.fallbackWallPath : rootWindow.quadWallPath
            fillMode: Image.Stretch
            smooth: true
            mipmap: true
            cache: false
            asynchronous: true

            onStatusChanged: {
                if (status === Image.Error && !useFallback) {
                    useFallback = true
                } else if (status === Image.Ready) {
                    useFallback = false
                }
            }

            Connections {
                target: rootWindow
                function onQuadWallPathChanged() {
                    quadImage.useFallback = false
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

    // =========================================================================
    // RIGHT SECTION: Search Box, Categories, Application List
    // =========================================================================
    Item {
        id: rightSection
        x: 438
        width: card.width - x - 20
        height: parent.height - 30
        anchors.verticalCenter: parent.verticalCenter

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            // ── Search Input Box ─────────────────────────────────────────────
            Rectangle {
                id: searchBox
                Layout.fillWidth: true
                height: 44
                radius: 12
                color: Theme.alpha(Theme.background, 0.90)
                border.width: 1.5
                border.color: searchInput.activeFocus ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                Behavior on border.color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 10
                    spacing: 8

                    Image {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        source: rootWindow.searchSvg
                        fillMode: Image.PreserveAspectFit
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.family: "Outfit"
                        font.pixelSize: 13
                        font.weight: Font.Normal
                        color: Theme.foreground
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.on_primary
                        selectByMouse: true
                        activeFocusOnTab: true
                        clip: true
                        focus: true

                        Text {
                            anchors.fill: parent
                            text: "Type to search..."
                            font: parent.font
                            color: Theme.muted
                            visible: parent.text.length === 0
                            verticalAlignment: Text.AlignVCenter
                        }

                        onTextChanged: {
                            rootWindow.searchQuery = text
                            rootWindow.updateFilteredApps()
                        }

                        Keys.onDownPressed: {
                            if (appListView.count > 0) {
                                rootWindow.selectedIndex = Math.min(appListView.count - 1, rootWindow.selectedIndex + 1)
                                appListView.positionViewAtIndex(rootWindow.selectedIndex, ListView.Contain)
                            }
                        }

                        Keys.onUpPressed: {
                            if (appListView.count > 0) {
                                rootWindow.selectedIndex = Math.max(0, rootWindow.selectedIndex - 1)
                                appListView.positionViewAtIndex(rootWindow.selectedIndex, ListView.Contain)
                            }
                        }

                        Keys.onReturnPressed: rootWindow.launchCurrent()

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

                    // Clear search button
                    Rectangle {
                        visible: searchInput.text.length > 0
                        width: 20
                        height: 20
                        radius: 10
                        color: clearMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.15) : "transparent"

                        Image {
                            anchors.centerIn: parent
                            width: 12
                            height: 12
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

                    // Theme selector quick button
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 6
                        color: themeBtnMouse.containsMouse ? Theme.alpha(Theme.accent, 0.20) : "transparent"
                        border.width: 1
                        border.color: themeBtnMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.10)

                        Image {
                            anchors.centerIn: parent
                            width: 14
                            height: 14
                            source: rootWindow.paletteSvg
                            fillMode: Image.PreserveAspectFit
                        }

                        MouseArea {
                            id: themeBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rootWindow.openThemeSwitcher()
                        }
                    }

                    // Dedicated Close button (✕)
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 6
                        color: closeBtnMouse.containsMouse ? Theme.alpha("#ef4444", 0.25) : "transparent"
                        border.width: 1
                        border.color: closeBtnMouse.containsMouse ? "#ef4444" : Theme.alpha(Theme.foreground, 0.10)

                        Image {
                            anchors.centerIn: parent
                            width: 11
                            height: 11
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

            // ── Category Filter Pills ────────────────────────────────────────
            Row {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: ["All", "Internet", "Development", "Media", "System"]

                    Rectangle {
                        height: 24
                        radius: 12
                        implicitWidth: catText.implicitWidth + 18
                        color: rootWindow.activeCategory === modelData
                            ? Theme.accent
                            : (catMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.12) : Theme.alpha(Theme.foreground, 0.05))
                        border.width: 1
                        border.color: rootWindow.activeCategory === modelData
                            ? Theme.accent
                            : Theme.alpha(Theme.foreground, 0.08)
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            id: catText
                            anchors.centerIn: parent
                            text: modelData
                            font.family: "Outfit"
                            font.pixelSize: 10
                            font.weight: rootWindow.activeCategory === modelData ? Font.DemiBold : Font.Normal
                            color: rootWindow.activeCategory === modelData ? Theme.on_primary : Theme.foreground
                        }

                        MouseArea {
                            id: catMouse
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

            // ── Application List View ────────────────────────────────────────
            ListView {
                id: appListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: rootWindow.filteredApps
                spacing: 4
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    id: scrollBar
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: Theme.alpha(Theme.accent, 0.40)
                    }
                }

                delegate: Rectangle {
                    id: itemDelegate
                    width: appListView.width - 6
                    height: 48
                    radius: 10
                    readonly property bool isSelected: index === rootWindow.selectedIndex

                    color: isSelected
                        ? Theme.alpha(Theme.accent, 0.15)
                        : (itemMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.06) : "transparent")
                    border.width: 1
                    border.color: isSelected ? Theme.alpha(Theme.accent, 0.40) : "transparent"
                    Behavior on color { ColorAnimation { duration: 80 } }

                    // Accent left indicator bar
                    Rectangle {
                        visible: itemDelegate.isSelected
                        width: 3
                        height: 24
                        radius: 1.5
                        color: Theme.accent
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        // Application Icon
                        Item {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28

                            Image {
                                id: appIconImg
                                anchors.fill: parent
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

                        // App Name and Generic Description
                        Column {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: modelData.name || "Application"
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: itemDelegate.isSelected ? Font.DemiBold : Font.Normal
                                color: itemDelegate.isSelected ? Theme.accent : Theme.foreground
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: modelData.generic_name || modelData.comment || modelData.exec || ""
                                font.family: "Outfit"
                                font.pixelSize: 10
                                color: Theme.muted
                                elide: Text.ElideRight
                                width: parent.width
                                visible: text.length > 0
                            }
                        }

                        // Launch icon indicator
                        Image {
                            visible: itemDelegate.isSelected
                            Layout.preferredWidth: 14
                            Layout.preferredHeight: 14
                            source: rootWindow.enterKeySvg
                            fillMode: Image.PreserveAspectFit
                            opacity: 0.85
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: rootWindow.selectedIndex = index
                        onClicked: rootWindow.launchApp(modelData)
                    }
                }

                // Empty state when search yields no results
                Item {
                    anchors.centerIn: parent
                    width: parent.width
                    height: 100
                    visible: rootWindow.filteredApps.length === 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No applications found"
                            font.family: "Outfit"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: Theme.muted
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Try searching with different keywords"
                            font.family: "Outfit"
                            font.pixelSize: 10
                            color: Theme.alpha(Theme.muted, 0.70)
                        }
                    }
                }
            }

            // ── Keyboard Hints Footer ────────────────────────────────────────
            RowLayout {
                id: hintsRow
                Layout.fillWidth: true
                height: 20

                Text {
                    text: rootWindow.filteredApps.length + " apps"
                    font.family: "Outfit"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: Theme.alpha(Theme.foreground, 0.40)
                    Layout.fillWidth: true
                }

                Row {
                    spacing: 12

                    Row {
                        spacing: 4
                        Text { text: "↑↓"; font.pixelSize: 10; color: Theme.accent; font.weight: Font.Bold }
                        Text { text: "navigate"; font.family: "Outfit"; font.pixelSize: 10; color: Theme.muted }
                    }

                    Row {
                        spacing: 4
                        Text { text: "↵"; font.pixelSize: 10; color: Theme.accent; font.weight: Font.Bold }
                        Text { text: "launch"; font.family: "Outfit"; font.pixelSize: 10; color: Theme.muted }
                    }

                    Row {
                        spacing: 4
                        Text { text: "esc"; font.family: "Outfit"; font.pixelSize: 10; color: Theme.accent; font.weight: Font.Bold }
                        Text { text: "close"; font.family: "Outfit"; font.pixelSize: 10; color: Theme.muted }
                    }
                }
            }
        }
    }
}
