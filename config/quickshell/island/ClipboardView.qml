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
        return (h && h.length > 0) ? h : "/home/shell-ninja"
    }

    readonly property real preferredWidth: 780
    readonly property real preferredHeight: 520
    implicitWidth: preferredWidth
    implicitHeight: preferredHeight

    // State
    property var allClips: []
    property var filteredClips: []
    property string activeCategory: "All"
    property int selectedIndex: 0
    property string searchQuery: ""

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string clipboardSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/><rect x="8" y="2" width="8" height="4" rx="1" ry="1"/></svg>')
    readonly property string searchSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>')
    readonly property string clearSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.muted + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>')
    readonly property string copySvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>')
    readonly property string trashSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>')
    readonly property string linkSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#38bdf8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>')
    readonly property string codeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#a855f7" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="16 18 22 12 16 6"></polyline><polyline points="8 6 2 12 8 18"></polyline></svg>')
    readonly property string textSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>')

    // Filter Logic
    function updateFilteredClips() {
        var q = searchQuery.toLowerCase().trim()
        var cat = activeCategory
        var list = []

        for (var i = 0; i < allClips.length; i++) {
            var item = allClips[i]
            var prev = (item.preview || "").toLowerCase()
            
            // Category check
            if (cat === "Links" && item.type !== "url") continue
            if (cat === "Code" && item.type !== "code") continue
            if (cat === "Colors" && item.type !== "color") continue
            if (cat === "Text" && item.type !== "text") continue

            // Search query check
            if (q.length > 0 && prev.indexOf(q) === -1) continue

            list.push(item)
        }

        filteredClips = list
        if (selectedIndex >= filteredClips.length) {
            selectedIndex = Math.max(0, filteredClips.length - 1)
        }
    }

    // Process to query clipboard list
    Process {
        id: listProc
        command: ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/clipboard.py", "--list"]
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(text.trim())
                        root.allClips = parsed
                        root.updateFilteredClips()
                    } catch(e) {
                        console.log("[ClipboardView] Parse error:", e)
                    }
                }
            }
        }
    }

    // Process to copy
    Process {
        id: copyProc
        onExited: {
            root.closeRequested()
        }
    }

    // Process to delete
    Process {
        id: deleteProc
        onExited: {
            refreshClips()
        }
    }

    // Process to wipe
    Process {
        id: wipeProc
        onExited: {
            refreshClips()
        }
    }

    function refreshClips() {
        listProc.running = true
    }

    function copySelected(item) {
        if (!item) return
        copyProc.command = [
            "python3",
            root.homeDir + "/.hyprconf/hypr/scripts/py/clipboard.py",
            "--copy",
            item.raw
        ]
        copyProc.running = true
    }

    function deleteSelected(item) {
        if (!item) return
        deleteProc.command = [
            "python3",
            root.homeDir + "/.hyprconf/hypr/scripts/py/clipboard.py",
            "--delete",
            item.raw
        ]
        deleteProc.running = true
    }

    function wipeAll() {
        wipeProc.command = [
            "python3",
            root.homeDir + "/.hyprconf/hypr/scripts/py/clipboard.py",
            "--wipe"
        ]
        wipeProc.running = true
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
            if (filteredClips.length > 0) {
                selectedIndex = Math.min(filteredClips.length - 1, selectedIndex + 1)
                clipListView.positionViewAtIndex(selectedIndex, ListView.Contain)
                return true
            }
        } else if (event.key === Qt.Key_Up) {
            if (filteredClips.length > 0) {
                selectedIndex = Math.max(0, selectedIndex - 1)
                clipListView.positionViewAtIndex(selectedIndex, ListView.Contain)
                return true
            }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (filteredClips.length > 0 && selectedIndex >= 0 && selectedIndex < filteredClips.length) {
                copySelected(filteredClips[selectedIndex])
                return true
            }
        } else if (event.key === Qt.Key_Delete) {
            if (filteredClips.length > 0 && selectedIndex >= 0 && selectedIndex < filteredClips.length) {
                deleteSelected(filteredClips[selectedIndex])
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
            refreshClips()
            focusTimer.restart()
        }
    }

    onAnimProgressChanged: {
        if (animProgress >= 0.75 && active && !isClosing) {
            root.focusInput()
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.active && !root.isClosing
        onActivated: root.closeRequested()
    }

    // ── EXPANDING OBSIDIAN ISLAND CONTAINER BACKGROUND ──────────────────────
    Rectangle {
        id: islandMorphBg
        anchors.fill: parent
        radius: 18 + (24 - 18) * root.animProgress
        color: Theme.alpha(Theme.background, 0.85)
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.35)
    }

    // ── MAIN CONTENT (FADES IN ON EXPANSION) ─────────────────────────────────
    Item {
        anchors.fill: parent
        anchors.margins: 18
        opacity: (!root.isClosing && root.animProgress >= 0.75) ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: root.isClosing ? 90 : 160; easing.type: Easing.OutCubic }
        }

        Column {
            anchors.fill: parent
            spacing: 12

            // ── TOP HEADER ROW: ICON, TITLE, SEARCH BAR & WIPE BUTTON ─────────
            Row {
                width: parent.width
                height: 40
                spacing: 14

                // Clipboard Icon & Title
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 22; height: 22
                        source: root.clipboardSvg
                        sourceSize: Qt.size(44, 44)
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Clipboard"
                        color: Theme.foreground
                        font.family: "Outfit"
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                    }
                }

                // Search Bar Pill
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 380
                    height: 38
                    radius: 19
                    color: Theme.alpha(Theme.surface, 0.65)
                    border.width: 1
                    border.color: searchField.activeFocus ? Theme.accent : Theme.alpha(Theme.accent, 0.28)

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        spacing: 8

                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16; height: 16
                            source: root.searchSvg
                            sourceSize: Qt.size(32, 32)
                        }

                        TextField {
                            id: searchField
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 24 - (clearBtn.visible ? 24 : 0)
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 13
                            placeholderText: "Search clipboard history..."
                            placeholderTextColor: Theme.alpha(Theme.foreground, 0.40)
                            background: null
                            selectByMouse: true

                            onTextChanged: {
                                root.searchQuery = text
                                root.updateFilteredClips()
                            }

                            Keys.onDownPressed: {
                                if (root.filteredClips.length > 0) {
                                    root.selectedIndex = Math.min(root.filteredClips.length - 1, root.selectedIndex + 1)
                                    clipListView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                                }
                            }
                            Keys.onUpPressed: {
                                if (root.filteredClips.length > 0) {
                                    root.selectedIndex = Math.max(0, root.selectedIndex - 1)
                                    clipListView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                                }
                            }
                            Keys.onReturnPressed: {
                                if (root.filteredClips.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.filteredClips.length) {
                                    root.copySelected(root.filteredClips[root.selectedIndex])
                                }
                            }
                            Keys.onDeletePressed: {
                                if (root.filteredClips.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.filteredClips.length) {
                                    root.deleteSelected(root.filteredClips[root.selectedIndex])
                                }
                            }
                            Keys.onEscapePressed: function(event) {
                                event.accepted = true
                                root.closeRequested()
                            }
                        }

                        Rectangle {
                            id: clearBtn
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20; height: 20; radius: 10
                            color: Theme.alpha(Theme.surface, 0.80)
                            visible: searchField.text.length > 0

                            Image {
                                anchors.centerIn: parent
                                width: 9; height: 9
                                source: root.clearSvg
                                sourceSize: Qt.size(18, 18)
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    searchField.text = ""
                                    searchField.forceActiveFocus()
                                }
                            }
                        }
                    }
                }

                Item { width: Math.max(10, parent.width - 130 - 380 - 120 - 28); height: 1 }

                // Wipe History Button
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 120
                    height: 34
                    radius: 17
                    color: Theme.alpha("#ef4444", 0.15)
                    border.width: 1
                    border.color: Theme.alpha("#ef4444", 0.35)
                    opacity: wipeMouse.containsMouse ? 1.0 : 0.85

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 13; height: 13
                            source: root.trashSvg
                            sourceSize: Qt.size(26, 26)
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Clear All"
                            color: "#ef4444"
                            font.family: "Outfit"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }
                    }

                    MouseArea {
                        id: wipeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.wipeAll()
                    }
                }
            }

            // ── CATEGORY FILTER PILLS ─────────────────────────────────────────
            Row {
                width: parent.width
                spacing: 8

                Repeater {
                    model: ["All", "Text", "Links", "Code", "Colors"]

                    Rectangle {
                        height: 28
                        width: catText.implicitWidth + 20
                        radius: 14
                        readonly property bool isSelected: root.activeCategory === modelData
                        color: isSelected ? Theme.accent : Theme.alpha(Theme.surface, 0.60)
                        border.width: 1
                        border.color: isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)

                        Text {
                            id: catText
                            anchors.centerIn: parent
                            text: modelData
                            color: parent.isSelected ? Theme.on_primary : Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 11
                            font.weight: parent.isSelected ? Font.DemiBold : Font.Normal
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.activeCategory = modelData
                                root.updateFilteredClips()
                            }
                        }
                    }
                }
            }

            // ── CLIPBOARD ITEMS LIST VIEW ────────────────────────────────────
            Item {
                width: parent.width
                height: parent.height - 40 - 28 - 36 - 24

                ListView {
                    id: clipListView
                    anchors.fill: parent
                    clip: true
                    spacing: 8
                    model: root.filteredClips

                    ScrollBar.vertical: ScrollBar {
                        anchors.right: parent.right
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: Rectangle {
                        id: clipRow
                        width: clipListView.width - (clipListView.contentHeight > clipListView.height ? 10 : 0)
                        height: 64
                        radius: 12
                        readonly property bool isSelected: root.selectedIndex === index

                        color: isSelected ? Theme.alpha(Theme.accent, 0.22) : (rowMouse.containsMouse ? Theme.alpha(Theme.surface, 0.70) : Theme.alpha(Theme.surface, 0.45))
                        border.width: 1
                        border.color: isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.10)
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            // Type Icon Badge
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 38
                                height: 38
                                radius: 10
                                color: {
                                    if (modelData.type === "color") return modelData.preview
                                    if (modelData.type === "url") return Theme.alpha("#38bdf8", 0.18)
                                    if (modelData.type === "code") return Theme.alpha("#a855f7", 0.18)
                                    return Theme.alpha(Theme.accent, 0.18)
                                }
                                border.width: modelData.type === "color" ? 1.5 : 0
                                border.color: "#ffffff"

                                Image {
                                    anchors.centerIn: parent
                                    width: 18; height: 18
                                    visible: modelData.type !== "color"
                                    source: {
                                        if (modelData.type === "url") return root.linkSvg
                                        if (modelData.type === "code") return root.codeSvg
                                        return root.textSvg
                                    }
                                    sourceSize: Qt.size(36, 36)
                                }
                            }

                            // Text Content and Metadata
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 38 - 12 - 140 - 12
                                spacing: 3

                                Text {
                                    text: modelData.preview
                                    color: Theme.foreground
                                    font.family: modelData.type === "code" ? "monospace" : "Outfit"
                                    font.pixelSize: 13
                                    font.weight: clipRow.isSelected ? Font.Medium : Font.Normal
                                    elide: Text.ElideRight
                                    width: parent.width
                                    maximumLineCount: 1
                                }

                                Row {
                                    spacing: 8
                                    // Type Tag Pill
                                    Rectangle {
                                        height: 16
                                        radius: 8
                                        width: typeText.implicitWidth + 10
                                        color: Theme.alpha(Theme.foreground, 0.10)
                                        Text {
                                            id: typeText
                                            anchors.centerIn: parent
                                            text: modelData.type.toUpperCase()
                                            color: Theme.alpha(Theme.foreground, 0.65)
                                            font.family: "Outfit"
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.length + " chars"
                                        color: Theme.alpha(Theme.foreground, 0.45)
                                        font.family: "Outfit"
                                        font.pixelSize: 10
                                    }
                                }
                            }

                            // Quick Action Buttons (Copy / Delete)
                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                // Copy Button
                                Rectangle {
                                    width: 68
                                    height: 30
                                    radius: 15
                                    color: Theme.accent
                                    opacity: copyMouse.containsMouse ? 0.90 : 1.0

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Image {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 12; height: 12
                                            source: root.copySvg
                                            sourceSize: Qt.size(24, 24)
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "Copy"
                                            color: Theme.on_primary
                                            font.family: "Outfit"
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                        }
                                    }

                                    MouseArea {
                                        id: copyMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.copySelected(modelData)
                                    }
                                }

                                // Delete Button
                                Rectangle {
                                    width: 30
                                    height: 30
                                    radius: 15
                                    color: Theme.alpha("#ef4444", 0.15)
                                    border.width: 1
                                    border.color: Theme.alpha("#ef4444", 0.30)

                                    Image {
                                        anchors.centerIn: parent
                                        width: 13; height: 13
                                        source: root.trashSvg
                                        sourceSize: Qt.size(26, 26)
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.deleteSelected(modelData)
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            z: -1
                            onClicked: {
                                root.selectedIndex = index
                                root.copySelected(modelData)
                            }
                        }
                    }
                }

                // Empty State View
                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    visible: root.filteredClips.length === 0

                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 44; height: 44
                        source: root.clipboardSvg
                        sourceSize: Qt.size(88, 88)
                        opacity: 0.4
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.searchQuery.length > 0 ? "No matching clips found" : "No clipboard history recorded yet"
                        color: Theme.alpha(Theme.foreground, 0.65)
                        font.family: "Outfit"
                        font.pixelSize: 14
                        font.weight: Font.Medium
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Copy text, code, or links with Ctrl+C to store them here"
                        color: Theme.alpha(Theme.foreground, 0.40)
                        font.family: "Outfit"
                        font.pixelSize: 11
                    }
                }
            }

            // ── BOTTOM STATUS BAR ─────────────────────────────────────────────
            Row {
                width: parent.width
                height: 24

                Text {
                    id: countText
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.filteredClips.length + " clips available"
                    color: Theme.alpha(Theme.foreground, 0.50)
                    font.family: "Outfit"
                    font.pixelSize: 11
                }

                Item { width: Math.max(10, parent.width - countText.implicitWidth - hintText.implicitWidth); height: 1 }

                Text {
                    id: hintText
                    anchors.verticalCenter: parent.verticalCenter
                    text: "↵ Copy with wl-copy  •  ↑↓ Navigate  •  Del Remove  •  Esc Close"
                    color: Theme.alpha(Theme.foreground, 0.40)
                    font.family: "Outfit"
                    font.pixelSize: 10
                }
            }
        }
    }
}
