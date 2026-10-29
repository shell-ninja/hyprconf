//@ pragma Env QS_NO_RELOAD_POPUP=1
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Widgets
import "."

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
    WlrLayershell.namespace: "quickshell-emoji"

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    readonly property string emojisJsonPath: homeDir + "/.hyprconf/quickshell/emoji/emojis.json"
    readonly property string recentJsonPath: homeDir + "/.hyprconf/hypr/.cache/recent_emojis.json"

    property var allEmojis: []
    property var recentEmojiChars: []
    property var filteredEmojis: []
    property string currentCategory: "all" // "recent", "all", "people", "nature", "food", "activity", "travel", "objects", "symbols", "flags"
    property string searchQuery: ""
    property var hoveredEmojiData: null

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string searchSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>')
    readonly property string closeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>')
    readonly property string sparkleSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>')

    // ── DATA LOADERS ─────────────────────────────────────────────────────────
    Process {
        id: recentLoader
        command: ["python3", "-c", "import json, os; p=os.path.expanduser('~/.hyprconf/hypr/.cache/recent_emojis.json'); print(open(p, encoding='utf-8').read() if os.path.exists(p) else '[]')"]
        running: true
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

    // ── FILTERING ENGINE ─────────────────────────────────────────────────────
    function updateFilter() {
        if (!root.allEmojis || root.allEmojis.length === 0) {
            root.filteredEmojis = []
            return
        }

        var q = root.searchQuery.trim().toLowerCase()
        var cat = root.currentCategory
        var results = []

        if (cat === "recent") {
            // Build recent list in order of recentEmojiChars
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
            return
        }

        for (var idx = 0; idx < root.allEmojis.length; idx++) {
            var item = root.allEmojis[idx]

            // Category match
            if (cat !== "all") {
                if (cat === "nature") {
                    if (item.category !== "nature" && item.category !== "animals") continue
                } else if (item.category !== cat) {
                    continue
                }
            }

            // Search query match
            if (q.length > 0) {
                if (!matchesQuery(item, q)) continue
            }

            results.push(item)
        }

        root.filteredEmojis = results
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

    // ── PICK & PASTE DISPATCHER ──────────────────────────────────────────────
    Process {
        id: pasteProc
    }

    function chooseEmoji(emojiChar) {
        if (!emojiChar || emojiChar.length === 0) return
        pasteProc.command = ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/paste-emoji.py", emojiChar]
        pasteProc.running = true
        root.visible = false
        closeTimer.restart()
    }

    Timer {
        id: closeTimer
        interval: 120
        repeat: false
        onTriggered: Qt.quit()
    }

    // ── OUTSIDE DISMISS ──────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        onClicked: Qt.quit()
    }

    Shortcut {
        sequence: "Escape"
        onActivated: Qt.quit()
    }

    // ── MAIN MODAL OBSIDIAN CARD ─────────────────────────────────────────────
    Rectangle {
        id: mainCard
        width: 620
        height: 520
        anchors.centerIn: parent
        radius: 24
        color: Theme.alpha(Theme.background, 0.92)
        border.color: Theme.alpha(Theme.foreground, 0.16)
        border.width: 1
        clip: true

        // Inner soft radial ambient accent glow at top
        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.7
            height: 120
            radius: 60
            color: Theme.alpha(Theme.accent, 0.08)
            opacity: 0.7
        }

        // Prevent outside clicks through card
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // ── 1. HEADER ROW: TITLE & BADGES & CLOSE ────────────────────────
            RowLayout {
                width: parent.width

                Row {
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 8
                        color: Theme.alpha(Theme.accent, 0.18)
                        border.color: Theme.alpha(Theme.accent, 0.35)
                        border.width: 1
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            anchors.centerIn: parent
                            width: 14
                            height: 14
                            source: root.sparkleSvg
                            sourceSize: Qt.size(28, 28)
                        }
                    }

                    Text {
                        text: "EMOJI STUDIO"
                        font.family: "Outfit"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        font.letterSpacing: 1.2
                        color: Theme.foreground
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        width: countText.implicitWidth + 12
                        height: 20
                        radius: 10
                        color: Theme.alpha(Theme.foreground, 0.08)
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: root.filteredEmojis.length + " emojis"
                            font.family: "Outfit"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            color: Theme.alpha(Theme.foreground, 0.60)
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Quick Close Button (✕)
                Rectangle {
                    width: 26
                    height: 26
                    radius: 13
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
                        onClicked: Qt.quit()
                    }
                }
            }

            // ── 2. SEARCH INPUT BAR ──────────────────────────────────────────
            Rectangle {
                id: searchBar
                width: parent.width
                height: 42
                radius: 21
                color: Theme.alpha(Theme.surface, 0.75)
                border.color: searchInput.activeFocus ? Theme.accent : Theme.alpha(Theme.foreground, 0.14)
                border.width: searchInput.activeFocus ? 1.5 : 1

                Behavior on border.color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 12
                    spacing: 8

                    Image {
                        width: 16
                        height: 16
                        source: root.searchSvg
                        sourceSize: Qt.size(32, 32)
                        opacity: searchInput.activeFocus ? 0.9 : 0.5
                    }

                    TextField {
                        id: searchInput
                        Layout.fillWidth: true
                        font.family: "Outfit"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: Theme.foreground
                        placeholderText: "Search emojis by name or keyword (e.g. fire, laugh, rocket)..."
                        placeholderTextColor: Theme.alpha(Theme.foreground, 0.40)
                        background: null
                        selectByMouse: true
                        focus: true

                        onTextChanged: {
                            root.searchQuery = text
                            root.updateFilter()
                        }

                        Keys.onReturnPressed: {
                            if (root.filteredEmojis.length > 0) {
                                root.chooseEmoji(root.filteredEmojis[0].emoji)
                            }
                        }
                        Keys.onEnterPressed: {
                            if (root.filteredEmojis.length > 0) {
                                root.chooseEmoji(root.filteredEmojis[0].emoji)
                            }
                        }
                    }

                    // Clear search button
                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        visible: searchInput.text.length > 0
                        color: clearMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.20) : Theme.alpha(Theme.foreground, 0.10)

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: 10
                            color: Theme.alpha(Theme.foreground, 0.70)
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

            // ── 3. HORIZONTAL CATEGORY PILLS BAR ─────────────────────────────
            Flickable {
                id: catFlickable
                width: parent.width
                height: 32
                contentWidth: catRow.width
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Row {
                    id: catRow
                    spacing: 6

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
                                if (root.currentCategory === modelData.id) return Theme.alpha(Theme.accent, 0.26)
                                if (pillMouse.containsMouse) return Theme.alpha(Theme.foreground, 0.12)
                                return Theme.alpha(Theme.foreground, 0.05)
                            }
                            border.color: {
                                if (root.currentCategory === modelData.id) return Theme.accent
                                if (pillMouse.containsMouse) return Theme.alpha(Theme.foreground, 0.25)
                                return "transparent"
                            }
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    text: modelData.icon
                                    font.family: "Noto Color Emoji"
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    id: catText
                                    text: modelData.label
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    font.weight: (root.currentCategory === modelData.id) ? Font.Bold : Font.Medium
                                    color: (root.currentCategory === modelData.id) ? Theme.foreground : Theme.alpha(Theme.foreground, 0.68)
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: pillMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.currentCategory = modelData.id
                                    root.updateFilter()
                                    grid.contentY = 0
                                }
                            }
                        }
                    }
                }

                WheelHandler {
                    target: catFlickable
                    orientation: Qt.Horizontal
                    onWheel: function(event) {
                        var delta = event.angleDelta.y || event.angleDelta.x
                        catFlickable.contentX = Math.max(0, Math.min(catFlickable.contentWidth - catFlickable.width, catFlickable.contentX - delta * 0.8))
                    }
                }
            }

            // ── 4. EMOJI TILES GRID ──────────────────────────────────────────
            Item {
                width: parent.width
                height: 315
                clip: true

                GridView {
                    id: grid
                    anchors.fill: parent
                    cellWidth: 48
                    cellHeight: 48
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.filteredEmojis

                    ScrollBar.vertical: ScrollBar {
                        width: 4
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: Item {
                        width: 48
                        height: 48

                        required property var modelData

                        Rectangle {
                            id: tile
                            anchors.centerIn: parent
                            width: 42
                            height: 42
                            radius: 10
                            color: tileMouse.containsMouse ? Theme.alpha(Theme.accent, 0.25) : "transparent"
                            border.color: tileMouse.containsMouse ? Theme.alpha(Theme.accent, 0.60) : "transparent"
                            border.width: 1
                            scale: tileMouse.pressed ? 0.90 : (tileMouse.containsMouse ? 1.18 : 1.0)

                            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 110 } }
                            Behavior on border.color { ColorAnimation { duration: 110 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.emoji || ""
                                font.family: "Noto Color Emoji"
                                font.pixelSize: 22
                            }

                            MouseArea {
                                id: tileMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: {
                                    root.hoveredEmojiData = modelData
                                }
                                onClicked: {
                                    root.chooseEmoji(modelData.emoji)
                                }
                            }
                        }
                    }
                }

                // Empty state when search yields no matches
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: root.filteredEmojis.length === 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: (root.currentCategory === "recent" && root.recentEmojiChars.length === 0) ? "⭐" : "🔍"
                        font.pixelSize: 34
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: (root.currentCategory === "recent" && root.recentEmojiChars.length === 0)
                              ? "No recently used emojis yet"
                              : "No emojis matching \"" + root.searchQuery + "\""
                        font.family: "Outfit"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: Theme.alpha(Theme.foreground, 0.70)
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: (root.currentCategory === "recent" && root.recentEmojiChars.length === 0)
                              ? "Pick any emoji from other tabs and it will appear here!"
                              : "Try a different search word or category filter"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        color: Theme.alpha(Theme.foreground, 0.40)
                    }
                }
            }

            // ── 5. BOTTOM DETAIL / ACTION STATUS BAR ─────────────────────────
            Rectangle {
                width: parent.width
                height: 42
                radius: 12
                color: Theme.alpha(Theme.foreground, 0.04)
                border.color: Theme.alpha(Theme.foreground, 0.08)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    // Hovered Emoji Icon
                    Text {
                        text: root.hoveredEmojiData ? root.hoveredEmojiData.emoji : "💡"
                        font.family: "Noto Color Emoji"
                        font.pixelSize: 20
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Hovered Emoji Details
                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 1

                        Text {
                            text: {
                                if (root.hoveredEmojiData) {
                                    var n = root.hoveredEmojiData.name || "Emoji"
                                    return n.charAt(0).toUpperCase() + n.slice(1)
                                }
                                return "Hover over any emoji for preview"
                            }
                            font.family: "Outfit"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: Theme.foreground
                            elide: Text.ElideRight
                        }

                        Text {
                            text: {
                                if (root.hoveredEmojiData && root.hoveredEmojiData.keywords) {
                                    return root.hoveredEmojiData.category + " • " + root.hoveredEmojiData.keywords.slice(0, 4).join(", ")
                                }
                                return "Press Super + Shift + D anytime to open"
                            }
                            font.family: "Outfit"
                            font.pixelSize: 10
                            color: Theme.alpha(Theme.foreground, 0.50)
                            elide: Text.ElideRight
                        }
                    }

                    // Paste Hint Pill
                    Rectangle {
                        height: 24
                        width: pasteHintText.implicitWidth + 16
                        radius: 12
                        color: Theme.alpha(Theme.accent, 0.20)
                        border.color: Theme.alpha(Theme.accent, 0.40)
                        border.width: 1

                        Text {
                            id: pasteHintText
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
