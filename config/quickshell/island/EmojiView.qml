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
    signal emojiSelected(string emoji)

    readonly property bool isIslandView: true

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    readonly property real preferredWidth: 620
    readonly property real preferredHeight: 510
    implicitWidth: preferredWidth
    implicitHeight: preferredHeight

    readonly property string emojisJsonPath: homeDir + "/.hyprconf/quickshell/island/emojis.json"
    readonly property string recentJsonPath: homeDir + "/.hyprconf/hypr/.cache/recent_emojis.json"

    property var allEmojis: []
    property var recentEmojiChars: []
    property var filteredEmojis: []
    property string activeCategory: "all"
    property string searchQuery: ""
    property int selectedIndex: 0
    property var hoveredEmojiData: null

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string searchSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>')
    readonly property string clearSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.muted + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>')
    readonly property string closeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>')

    // ── DATA LOADERS ─────────────────────────────────────────────────────────
    Process {
        id: recentLoader
        command: ["python3", "-c", "import json, os; p=os.path.expanduser('~/.hyprconf/hypr/.cache/recent_emojis.json'); print(open(p, encoding='utf-8').read() if os.path.exists(p) else '[]')"]
        stdout: StdioCollector {
            onTextChanged: {
                if (!text) return
                try {
                    var parsed = JSON.parse(text.trim())
                    if (Array.isArray(parsed)) {
                        root.recentEmojiChars = parsed
                        root.updateFilter()
                    }
                } catch(e) {}
            }
        }
    }

    Process {
        id: emojiLoader
        command: ["cat", root.emojisJsonPath]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text) return
                try {
                    var parsed = JSON.parse(text.trim())
                    if (Array.isArray(parsed)) {
                        root.allEmojis = parsed
                        root.updateFilter()
                    }
                } catch(e) {}
            }
        }
    }

    // Refresh recent list whenever view activates
    onActiveChanged: {
        if (active) {
            recentLoader.running = true
            searchField.text = ""
            root.searchQuery = ""
            root.selectedIndex = 0
            root.updateFilter()
            focusTimer.restart()
        }
    }

    onAnimProgressChanged: {
        if (animProgress >= 0.75 && active && !isClosing) {
            root.focusInput()
        }
    }

    Timer {
        id: focusTimer
        interval: 60
        repeat: false
        onTriggered: root.focusInput()
    }

    function focusInput() {
        searchField.forceActiveFocus()
    }

    function focusSearch() {
        focusInput()
    }

    // ── FILTERING ENGINE ─────────────────────────────────────────────────────
    function updateFilter() {
        if (!root.allEmojis || root.allEmojis.length === 0) {
            root.filteredEmojis = []
            return
        }

        var q = root.searchQuery.trim().toLowerCase()
        var cat = root.activeCategory
        var results = []

        if (cat === "recent") {
            var charMap = {}
            for (var r = 0; r < root.allEmojis.length; r++) {
                charMap[root.allEmojis[r].emoji] = root.allEmojis[r]
            }
            for (var i = 0; i < root.recentEmojiChars.length; i++) {
                var c = root.recentEmojiChars[i]
                if (charMap[c]) {
                    if (q.length === 0 || matchesQuery(charMap[c], q)) {
                        results.push(charMap[c])
                    }
                }
            }
            root.filteredEmojis = results
            root.selectedIndex = 0
            return
        }

        for (var idx = 0; idx < root.allEmojis.length; idx++) {
            var item = root.allEmojis[idx]

            if (cat !== "all") {
                if (cat === "nature") {
                    if (item.category !== "nature" && item.category !== "animals") continue
                } else if (item.category !== cat) {
                    continue
                }
            }

            if (q.length > 0) {
                if (!matchesQuery(item, q)) continue
            }

            results.push(item)
        }

        root.filteredEmojis = results
        root.selectedIndex = 0
    }

    function matchesQuery(item, q) {
        if (item.emoji === q) return true
        if (item.name && item.name.toLowerCase().indexOf(q) !== -1) return true
        if (item.keywords && Array.isArray(item.keywords)) {
            for (var k = 0; k < item.keywords.length; k++) {
                if (item.keywords[k].toLowerCase().indexOf(q) !== -1) return true
            }
        }
        return false
    }

    // ── DISPATCH COPY & AUTO-PASTE ───────────────────────────────────────────
    Process {
        id: pasteProc
    }

    function selectEmoji(emojiChar) {
        if (!emojiChar || emojiChar.length === 0) return
        root.emojiSelected(emojiChar)
        pasteProc.command = ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/paste-emoji.py", emojiChar]
        pasteProc.running = true
        root.closeRequested()
    }

    function handleKey(event) {
        if (event.key === Qt.Key_Escape) {
            event.accepted = true
            root.closeRequested()
            return true
        }
        var cols = 10
        if (event.key === Qt.Key_Right) {
            if (filteredEmojis.length > 0) {
                selectedIndex = Math.min(filteredEmojis.length - 1, selectedIndex + 1)
                emojiGrid.positionViewAtIndex(selectedIndex, GridView.Contain)
                root.hoveredEmojiData = filteredEmojis[selectedIndex]
                return true
            }
        } else if (event.key === Qt.Key_Left) {
            if (filteredEmojis.length > 0) {
                selectedIndex = Math.max(0, selectedIndex - 1)
                emojiGrid.positionViewAtIndex(selectedIndex, GridView.Contain)
                root.hoveredEmojiData = filteredEmojis[selectedIndex]
                return true
            }
        } else if (event.key === Qt.Key_Down) {
            if (filteredEmojis.length > 0) {
                selectedIndex = Math.min(filteredEmojis.length - 1, selectedIndex + cols)
                emojiGrid.positionViewAtIndex(selectedIndex, GridView.Contain)
                root.hoveredEmojiData = filteredEmojis[selectedIndex]
                return true
            }
        } else if (event.key === Qt.Key_Up) {
            if (filteredEmojis.length > 0) {
                selectedIndex = Math.max(0, selectedIndex - cols)
                emojiGrid.positionViewAtIndex(selectedIndex, GridView.Contain)
                root.hoveredEmojiData = filteredEmojis[selectedIndex]
                return true
            }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (filteredEmojis.length > 0 && selectedIndex >= 0 && selectedIndex < filteredEmojis.length) {
                selectEmoji(filteredEmojis[selectedIndex].emoji)
                return true
            }
        }
        return false
    }


    // ── EXPANDING OBSIDIAN ISLAND CONTAINER BACKGROUND ──────────────────────
    Rectangle {
        id: islandMorphBg
        anchors.fill: parent
        radius: 18 + (24 - 18) * root.animProgress
        color: Theme.alpha(Theme.background, 0.86)
        border.width: 1
        border.color: Theme.alpha(Theme.foreground, 0.14)

        // Subtle top specular highlight
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            height: 1
            color: Theme.alpha(Theme.foreground, 0.12)
        }
    }

    // ── MAIN CONTENT (FADES IN ON EXPANSION) ─────────────────────────────────
    Item {
        anchors.fill: parent
        anchors.margins: 16
        opacity: (!root.isClosing && root.animProgress >= 0.75) ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: root.isClosing ? 90 : 160; easing.type: Easing.OutCubic }
        }

        Column {
            anchors.fill: parent
            spacing: 10

            // ── TOP HEADER: SEARCH PILL & QUICK CLOSE BUTTON ─────────────────
            RowLayout {
                width: parent.width
                height: 38
                spacing: 10

                // Sleek Minimal Search Pill
                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 19
                    color: Theme.alpha(Theme.surface, 0.70)
                    border.color: searchField.activeFocus ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                    border.width: searchField.activeFocus ? 1.5 : 1

                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        spacing: 8

                        Image {
                            width: 15
                            height: 15
                            source: root.searchSvg
                            sourceSize: Qt.size(30, 30)
                            opacity: searchField.activeFocus ? 0.95 : 0.55
                        }

                        TextField {
                            id: searchField
                            Layout.fillWidth: true
                            font.family: "Outfit"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Theme.foreground
                            placeholderText: "Search 1,900+ emojis (fire, laugh, rocket)..."
                            placeholderTextColor: Theme.alpha(Theme.foreground, 0.38)
                            background: null
                            selectByMouse: true

                            onTextChanged: {
                                root.searchQuery = text
                                root.updateFilter()
                            }

                            Keys.onDownPressed: function(event) {
                                if (root.filteredEmojis.length > 0) {
                                    event.accepted = true
                                    root.selectedIndex = Math.min(root.filteredEmojis.length - 1, root.selectedIndex + 10)
                                    emojiGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
                                    root.hoveredEmojiData = root.filteredEmojis[root.selectedIndex]
                                }
                            }
                            Keys.onUpPressed: function(event) {
                                if (root.filteredEmojis.length > 0) {
                                    event.accepted = true
                                    root.selectedIndex = Math.max(0, root.selectedIndex - 10)
                                    emojiGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
                                    root.hoveredEmojiData = root.filteredEmojis[root.selectedIndex]
                                }
                            }

                            Keys.onReturnPressed: {
                                if (root.filteredEmojis.length > 0) {
                                    var idx = (root.selectedIndex >= 0 && root.selectedIndex < root.filteredEmojis.length) ? root.selectedIndex : 0;
                                    root.selectEmoji(root.filteredEmojis[idx].emoji)
                                }
                            }
                            Keys.onEnterPressed: {
                                if (root.filteredEmojis.length > 0) {
                                    var idx = (root.selectedIndex >= 0 && root.selectedIndex < root.filteredEmojis.length) ? root.selectedIndex : 0;
                                    root.selectEmoji(root.filteredEmojis[idx].emoji)
                                }
                            }
                            Keys.onEscapePressed: function(event) {
                                event.accepted = true
                                root.closeRequested()
                            }
                        }

                        // Clear Query Button
                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            visible: searchField.text.length > 0
                            color: clearMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.20) : Theme.alpha(Theme.foreground, 0.10)

                            Image {
                                anchors.centerIn: parent
                                width: 9
                                height: 9
                                source: root.clearSvg
                                sourceSize: Qt.size(18, 18)
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

                // Close Button (✕)
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: closeMouse.containsMouse ? Theme.alpha("#ef4444", 0.20) : Theme.alpha(Theme.foreground, 0.08)
                    border.color: closeMouse.containsMouse ? Theme.alpha("#ef4444", 0.40) : "transparent"
                    border.width: 1

                    Image {
                        anchors.centerIn: parent
                        width: 11
                        height: 11
                        source: root.closeSvg
                        sourceSize: Qt.size(22, 22)
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

            // ── CATEGORIES ROW (FLICKABLE PILLS) ─────────────────────────────
            Flickable {
                id: catFlick
                width: parent.width
                height: 28
                contentWidth: catRow.width
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Row {
                    id: catRow
                    spacing: 5

                    readonly property var categories: [
                        { id: "recent", label: "Recent", icon: "⭐" },
                        { id: "all", label: "All", icon: "🌐" },
                        { id: "people", label: "Smileys", icon: "😀" },
                        { id: "nature", label: "Nature", icon: "🌿" },
                        { id: "food", label: "Food", icon: "🍔" },
                        { id: "activity", label: "Activity", icon: "⚽" },
                        { id: "travel", label: "Travel", icon: "🚀" },
                        { id: "objects", label: "Objects", icon: "💡" },
                        { id: "symbols", label: "Symbols", icon: "❤️" },
                        { id: "flags", label: "Flags", icon: "🚩" }
                    ]

                    Repeater {
                        model: catRow.categories

                        delegate: Rectangle {
                            id: catPill
                            height: 28
                            width: catText.implicitWidth + 24
                            radius: 14
                            color: {
                                if (root.activeCategory === modelData.id) return Theme.alpha(Theme.accent, 0.24)
                                if (pillMouse.containsMouse) return Theme.alpha(Theme.foreground, 0.10)
                                return Theme.alpha(Theme.foreground, 0.04)
                            }
                            border.color: (root.activeCategory === modelData.id) ? Theme.accent : "transparent"
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 110 } }
                            Behavior on border.color { ColorAnimation { duration: 110 } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    text: modelData.icon
                                    font.family: "Noto Color Emoji"
                                    font.pixelSize: 13
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    id: catText
                                    text: modelData.label
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    font.weight: (root.activeCategory === modelData.id) ? Font.Bold : Font.Medium
                                    color: (root.activeCategory === modelData.id) ? Theme.foreground : Theme.alpha(Theme.foreground, 0.65)
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: pillMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.activeCategory = modelData.id
                                    root.updateFilter()
                                    emojiGrid.contentY = 0
                                }
                            }
                        }
                    }
                }

                WheelHandler {
                    target: catFlick
                    orientation: Qt.Horizontal
                    onWheel: function(event) {
                        var delta = event.angleDelta.y || event.angleDelta.x
                        catFlick.contentX = Math.max(0, Math.min(catFlick.contentWidth - catFlick.width, catFlick.contentX - delta * 0.8))
                    }
                }
            }

            // ── MAIN EMOJI GRID ──────────────────────────────────────────────
            Item {
                width: parent.width
                height: 345
                clip: true

                GridView {
                    id: emojiGrid
                    anchors.fill: parent
                    cellWidth: 58
                    cellHeight: 58
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.filteredEmojis

                    ScrollBar.vertical: ScrollBar {
                        width: 4
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: Item {
                        width: 58
                        height: 58

                        required property var modelData
                        required property int index

                        readonly property bool isSelected: root.selectedIndex === index

                        Rectangle {
                            id: tileRect
                            anchors.centerIn: parent
                            width: 50
                            height: 50
                            radius: 12
                            color: {
                                if (isSelected) return Theme.alpha(Theme.accent, 0.30)
                                if (tileMouse.containsMouse) return Theme.alpha(Theme.accent, 0.18)
                                return "transparent"
                            }
                            border.color: {
                                if (isSelected) return Theme.accent
                                if (tileMouse.containsMouse) return Theme.alpha(Theme.accent, 0.45)
                                return "transparent"
                            }
                            border.width: 1
                            scale: tileMouse.pressed ? 0.90 : (tileMouse.containsMouse || isSelected ? 1.14 : 1.0)

                            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 110 } }
                            Behavior on border.color { ColorAnimation { duration: 110 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.emoji || ""
                                font.family: "Noto Color Emoji"
                                font.pixelSize: 30
                            }

                            MouseArea {
                                id: tileMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: {
                                    root.selectedIndex = index
                                    root.hoveredEmojiData = modelData
                                }
                                onClicked: {
                                    root.selectEmoji(modelData.emoji)
                                }
                            }
                        }
                    }
                }

                // Empty state
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: root.filteredEmojis.length === 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: (root.activeCategory === "recent" && root.recentEmojiChars.length === 0) ? "⭐" : "🔍"
                        font.pixelSize: 32
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: (root.activeCategory === "recent" && root.recentEmojiChars.length === 0)
                              ? "No recently picked emojis yet"
                              : "No emojis matching \"" + root.searchQuery + "\""
                        font.family: "Outfit"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: Theme.alpha(Theme.foreground, 0.70)
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: (root.activeCategory === "recent" && root.recentEmojiChars.length === 0)
                              ? "Pick any emoji and it will instantly appear in Recent"
                              : "Try typing a different keyword or check other categories"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        color: Theme.alpha(Theme.foreground, 0.40)
                    }
                }
            }

            // ── BOTTOM DETAIL / PREVIEW STATUS ROW ───────────────────────────
            Rectangle {
                width: parent.width
                height: 42
                radius: 10
                color: Theme.alpha(Theme.foreground, 0.035)
                border.color: Theme.alpha(Theme.foreground, 0.07)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    // Hovered Icon
                    Text {
                        text: root.hoveredEmojiData ? root.hoveredEmojiData.emoji : "✨"
                        font.family: "Noto Color Emoji"
                        font.pixelSize: 26
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Hovered Details
                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            text: {
                                if (root.hoveredEmojiData) {
                                    var n = root.hoveredEmojiData.name || "Emoji"
                                    return n.charAt(0).toUpperCase() + n.slice(1)
                                }
                                return "Hover over any emoji for preview"
                            }
                            font.family: "Outfit"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: Theme.foreground
                            elide: Text.ElideRight
                        }

                        Text {
                            text: {
                                if (root.hoveredEmojiData && root.hoveredEmojiData.keywords) {
                                    return root.hoveredEmojiData.category + " • " + root.hoveredEmojiData.keywords.slice(0, 3).join(", ")
                                }
                                return "Press Super + Shift + D anytime to toggle"
                            }
                            font.family: "Outfit"
                            font.pixelSize: 10
                            color: Theme.alpha(Theme.foreground, 0.45)
                            elide: Text.ElideRight
                        }
                    }

                    // Paste Hint Pill
                    Rectangle {
                        height: 24
                        width: pasteText.implicitWidth + 16
                        radius: 12
                        color: Theme.alpha(Theme.accent, 0.18)
                        border.color: Theme.alpha(Theme.accent, 0.35)
                        border.width: 1

                        Text {
                            id: pasteText
                            anchors.centerIn: parent
                            text: "Click to Paste ↵"
                            font.family: "Outfit"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Theme.accent
                        }
                    }
                }
            }
        }
    }
}
