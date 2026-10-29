import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root

    property bool active: false
    property bool isClosing: false
    property real animProgress: 1.0
    signal closeRequested()

    readonly property bool isIslandView: true

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    readonly property real preferredWidth: 780
    readonly property real preferredHeight: 520
    implicitWidth: preferredWidth
    implicitHeight: preferredHeight

    // State
    property var allKeybinds: []
    property var filteredKeybinds: []
    property string activeCategory: "All"
    property int selectedIndex: 0
    property string searchQuery: ""

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string keyboardSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="4" width="20" height="16" rx="2" ry="2"></rect><line x1="6" y1="8" x2="6" y2="8"></line><line x1="10" y1="8" x2="10" y2="8"></line><line x1="14" y1="8" x2="14" y2="8"></line><line x1="18" y1="8" x2="18" y2="8"></line><line x1="6" y1="12" x2="6" y2="12"></line><line x1="10" y1="12" x2="10" y2="12"></line><line x1="14" y1="12" x2="14" y2="12"></line><line x1="18" y1="12" x2="18" y2="12"></line><line x1="7" y1="16" x2="17" y2="16"></line></svg>')
    readonly property string searchSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>')
    readonly property string clearSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.muted + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>')
    readonly property string closeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>')
    readonly property string playSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="5 3 19 12 5 21 5 3"></polygon></svg>')
    readonly property string infoSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>')

    // ── DATA LOADER ──────────────────────────────────────────────────────────
    Process {
        id: catalogLoader
        command: ["bash", "-c", "$HOME/.hyprconf/hypr/scripts/sh/keybinds.sh --json"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(text.trim())
                        root.allKeybinds = parsed
                        root.updateFilteredKeybinds()
                    } catch(e) {
                        console.log("[KeybindsView] Failed to parse JSON:", e)
                    }
                }
            }
        }
    }

    // ── ACTION EXECUTOR ──────────────────────────────────────────────────────
    Process { id: execProc }

    function executeKeybind(item) {
        if (!item) return
        var act = item.action || ""
        execProc.command = ["bash", "-c", "$HOME/.hyprconf/hypr/scripts/sh/keybinds.sh \"" + act + "\""]
        execProc.running = false
        execProc.running = true
        root.closeRequested()
    }

    // ── FILTERING LOGIC ──────────────────────────────────────────────────────
    function updateFilteredKeybinds() {
        var q = searchQuery.toLowerCase().trim()
        var cat = activeCategory
        var list = []

        for (var i = 0; i < allKeybinds.length; i++) {
            var item = allKeybinds[i]
            var itemCat = item.category || "General"

            // Category filter
            if (cat !== "All" && itemCat.toLowerCase() !== cat.toLowerCase()) {
                continue
            }

            // Search query filter (matches combo, action name, or description)
            if (q.length > 0) {
                var comboStr = (item.combo || "").toLowerCase()
                var actStr = (item.action || "").toLowerCase()
                var descStr = (item.desc || "").toLowerCase()
                if (comboStr.indexOf(q) === -1 && actStr.indexOf(q) === -1 && descStr.indexOf(q) === -1) {
                    continue
                }
            }

            list.push(item)
        }

        filteredKeybinds = list
        if (selectedIndex >= filteredKeybinds.length) {
            selectedIndex = Math.max(0, filteredKeybinds.length - 1)
        }
    }

    function refreshCatalog() {
        catalogLoader.running = false
        catalogLoader.running = true
    }

    function focusInput() {
        searchField.forceActiveFocus()
    }

    function focusSearch() {
        focusInput()
    }

    function handleKey(event) {
        if (event.key === Qt.Key_Escape) {
            event.accepted = true
            root.closeRequested()
            return true
        }
        if (event.key === Qt.Key_Down) {
            if (filteredKeybinds.length > 0) {
                selectedIndex = Math.min(filteredKeybinds.length - 1, selectedIndex + 1)
                keybindsListView.positionViewAtIndex(selectedIndex, ListView.Contain)
                return true
            }
        } else if (event.key === Qt.Key_Up) {
            if (filteredKeybinds.length > 0) {
                selectedIndex = Math.max(0, selectedIndex - 1)
                keybindsListView.positionViewAtIndex(selectedIndex, ListView.Contain)
                return true
            }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (filteredKeybinds.length > 0 && selectedIndex >= 0 && selectedIndex < filteredKeybinds.length) {
                executeKeybind(filteredKeybinds[selectedIndex])
                return true
            }
        }
        return false
    }

    Timer {
        id: focusTimer
        interval: 90
        repeat: false
        onTriggered: root.focusInput()
    }

    onActiveChanged: {
        if (active) {
            root.searchQuery = ""
            root.activeCategory = "All"
            root.selectedIndex = 0
            refreshCatalog()
            focusTimer.restart()
        }
    }

    onAnimProgressChanged: {
        if (animProgress >= 0.75 && active && !isClosing) {
            root.focusInput()
        }
    }


    // ── EXPANDING OBSIDIAN ISLAND CONTAINER BACKGROUND ──────────────────────
    Rectangle {
        id: islandMorphBg
        anchors.fill: parent
        radius: 18 + (24 - 18) * root.animProgress
        color: Theme.alpha(Theme.background, 0.88)
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.35)
    }

    // ── MAIN CONTENT ────────────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        anchors.margins: 16
        opacity: (!root.isClosing && root.animProgress >= 0.65) ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: root.isClosing ? 80 : 160; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            // ── TOP HEADER ROW: TITLE, SEARCH, CLOSE BUTTON ─────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Icon + Title Badge
                Row {
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        color: Theme.alpha(Theme.accent, 0.15)
                        border.color: Theme.alpha(Theme.accent, 0.30)
                        border.width: 1

                        Image {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            source: root.keyboardSvg
                            sourceSize: Qt.size(36, 36)
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            text: "Keybindings"
                            font.family: "Outfit"
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            color: Theme.foreground
                        }

                        Text {
                            text: "Super + Shift + H"
                            font.family: "Outfit"
                            font.pixelSize: 10
                            color: Theme.muted
                        }
                    }
                }

                // Search Bar Input
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 10
                    color: Theme.alpha(Theme.foreground, 0.06)
                    border.color: searchField.activeFocus ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        spacing: 8

                        Image {
                            width: 15
                            height: 15
                            source: root.searchSvg
                            sourceSize: Qt.size(30, 30)
                        }

                        TextInput {
                            id: searchField
                            Layout.fillWidth: true
                            font.family: "Outfit"
                            font.pixelSize: 12
                            color: Theme.foreground
                            selectByMouse: true
                            clip: true

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Search shortcut, key combo, or action..."
                                font.family: "Outfit"
                                font.pixelSize: 12
                                color: Theme.muted
                                visible: !searchField.text && !searchField.activeFocus
                            }

                            onTextChanged: {
                                root.searchQuery = text
                                root.updateFilteredKeybinds()
                            }

                            // Intercept Escape key directly inside TextInput
                            Keys.priority: Keys.BeforeItem
                            Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_Escape) {
                                    event.accepted = true
                                    root.closeRequested()
                                    return
                                }
                                if (event.key === Qt.Key_Down || event.key === Qt.Key_Up || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    if (root.handleKey(event)) {
                                        event.accepted = true
                                        return
                                    }
                                }
                            }
                        }

                        // Clear Button
                        Rectangle {
                            visible: searchField.text.length > 0
                            width: 22
                            height: 22
                            radius: 11
                            color: clearMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.15) : "transparent"

                            Image {
                                anchors.centerIn: parent
                                width: 12
                                height: 12
                                source: root.clearSvg
                                sourceSize: Qt.size(24, 24)
                            }

                            MouseArea {
                                id: clearMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    searchField.text = ""
                                    searchField.forceActiveFocus()
                                }
                            }
                        }
                    }
                }

                // Dedicated Close Button (✕)
                Rectangle {
                    width: 34
                    height: 34
                    radius: 10
                    color: closeMouse.containsMouse ? Theme.alpha("#ef4444", 0.22) : Theme.alpha(Theme.foreground, 0.08)
                    border.color: closeMouse.containsMouse ? Theme.alpha("#ef4444", 0.50) : Theme.alpha(Theme.foreground, 0.12)
                    border.width: 1

                    Image {
                        anchors.centerIn: parent
                        width: 12
                        height: 12
                        source: root.closeSvg
                        sourceSize: Qt.size(24, 24)
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
            }

            // ── CATEGORY PILLS FILTER BAR ───────────────────────────────────
            Flickable {
                Layout.fillWidth: true
                height: 28
                contentWidth: categoryRow.width
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Row {
                    id: categoryRow
                    spacing: 6

                    readonly property var categories: ["All", "Apps", "Windows", "Workspaces", "Quickshell", "Media", "System"]

                    Repeater {
                        model: categoryRow.categories

                        Rectangle {
                            readonly property bool isSelected: root.activeCategory === modelData
                            height: 26
                            radius: 13
                            width: catText.implicitWidth + 20
                            color: isSelected ? Theme.accent : (catMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.12) : Theme.alpha(Theme.foreground, 0.06))
                            border.color: isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.10)
                            border.width: 1

                            Text {
                                id: catText
                                anchors.centerIn: parent
                                text: modelData
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: isSelected ? Font.Bold : Font.Normal
                                color: isSelected ? Theme.background : Theme.foreground
                            }

                            MouseArea {
                                id: catMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.activeCategory = modelData
                                    root.selectedIndex = 0
                                    root.updateFilteredKeybinds()
                                }
                            }
                        }
                    }
                }
            }

            // ── KEYBINDINGS LIST VIEW ───────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: Theme.alpha(Theme.foreground, 0.03)
                border.color: Theme.alpha(Theme.foreground, 0.08)
                border.width: 1
                clip: true

                ListView {
                    id: keybindsListView
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 6
                    model: root.filteredKeybinds
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: itemCard
                        readonly property bool isCurrent: index === root.selectedIndex
                        readonly property var itemData: modelData
                        width: keybindsListView.width
                        height: 52
                        radius: 10
                        color: isCurrent
                               ? Theme.alpha(Theme.accent, 0.18)
                               : (itemMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.07) : Theme.alpha(Theme.foreground, 0.02))
                        border.color: isCurrent
                                      ? Theme.alpha(Theme.accent, 0.55)
                                      : (itemMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.16) : Theme.alpha(Theme.foreground, 0.05))
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            // Left: Action Name & Description
                            Column {
                                Layout.fillWidth: true
                                spacing: 2

                                Row {
                                    spacing: 8

                                    Text {
                                        text: itemData.action || ""
                                        font.family: "Outfit"
                                        font.pixelSize: 13
                                        font.weight: Font.Bold
                                        color: itemCard.isCurrent ? Theme.accent : Theme.foreground
                                        elide: Text.ElideRight
                                    }

                                    // Category Tag
                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: 16
                                        radius: 4
                                        width: tagText.implicitWidth + 8
                                        color: Theme.alpha(Theme.accent, 0.12)

                                        Text {
                                            id: tagText
                                            anchors.centerIn: parent
                                            text: itemData.category || "General"
                                            font.family: "Outfit"
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                            color: Theme.accent
                                        }
                                    }
                                }

                                Text {
                                    text: itemData.desc || ""
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    color: Theme.muted
                                    elide: Text.ElideRight
                                }
                            }

                            // Right: Styled Keycap Badges
                            Row {
                                spacing: 4
                                Layout.alignment: Qt.AlignVCenter

                                readonly property var keyParts: {
                                    var raw = (itemData.combo || "").trim()
                                    // Split on " + " while preserving spaces
                                    return raw.split(/\s*\+\s*/)
                                }

                                Repeater {
                                    model: parent.keyParts

                                    Row {
                                        spacing: 4

                                        Rectangle {
                                            height: 24
                                            radius: 6
                                            width: Math.max(26, keyLabel.implicitWidth + 12)
                                            color: itemCard.isCurrent
                                                   ? Theme.alpha(Theme.accent, 0.30)
                                                   : Theme.alpha(Theme.foreground, 0.10)
                                            border.color: itemCard.isCurrent
                                                          ? Theme.accent
                                                          : Theme.alpha(Theme.foreground, 0.20)
                                            border.width: 1

                                            Text {
                                                id: keyLabel
                                                anchors.centerIn: parent
                                                text: modelData
                                                font.family: "Outfit"
                                                font.pixelSize: 10
                                                font.weight: Font.Bold
                                                color: itemCard.isCurrent ? Theme.accent : Theme.foreground
                                            }
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "+"
                                            font.family: "Outfit"
                                            font.pixelSize: 11
                                            font.weight: Font.Bold
                                            color: Theme.muted
                                            visible: index < parent.parent.keyParts.length - 1
                                        }
                                    }
                                }
                            }

                            // Run Button Indicator
                            Rectangle {
                                width: 26
                                height: 26
                                radius: 13
                                color: itemCard.isCurrent ? Theme.alpha(Theme.accent, 0.25) : "transparent"
                                visible: itemMouse.containsMouse || itemCard.isCurrent

                                Image {
                                    anchors.centerIn: parent
                                    width: 10
                                    height: 10
                                    source: root.playSvg
                                    sourceSize: Qt.size(20, 20)
                                }
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedIndex = index
                                root.executeKeybind(itemData)
                            }
                        }
                    }
                }

                // Empty State
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: root.filteredKeybinds.length === 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No keybindings found"
                        font.family: "Outfit"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: Theme.muted
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Try a different search term or category filter"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        color: Theme.alpha(Theme.muted, 0.70)
                    }
                }
            }

            // ── BOTTOM FOOTER ROW: CHEATSHEET HINTS ─────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Showing " + root.filteredKeybinds.length + " of " + root.allKeybinds.length + " shortcuts"
                    font.family: "Outfit"
                    font.pixelSize: 11
                    color: Theme.muted
                }

                Item { Layout.fillWidth: true }

                Row {
                    spacing: 6

                    Rectangle {
                        height: 20
                        radius: 4
                        width: h1.implicitWidth + 8
                        color: Theme.alpha(Theme.foreground, 0.08)
                        Text { id: h1; anchors.centerIn: parent; text: "↑ / ↓ Navigate"; font.family: "Outfit"; font.pixelSize: 10; color: Theme.muted }
                    }

                    Rectangle {
                        height: 20
                        radius: 4
                        width: h2.implicitWidth + 8
                        color: Theme.alpha(Theme.foreground, 0.08)
                        Text { id: h2; anchors.centerIn: parent; text: "↵ Execute"; font.family: "Outfit"; font.pixelSize: 10; color: Theme.muted }
                    }

                    Rectangle {
                        height: 20
                        radius: 4
                        width: h3.implicitWidth + 8
                        color: Theme.alpha(Theme.foreground, 0.08)
                        Text { id: h3; anchors.centerIn: parent; text: "Esc / ✕ Close"; font.family: "Outfit"; font.pixelSize: 10; color: Theme.muted }
                    }
                }
            }
        }
    }
}
