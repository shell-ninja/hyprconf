import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
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
    WlrLayershell.namespace: "hyprconf-keybinds-hud"

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    // Catalog state
    property var allKeybinds: []
    property var filteredKeybinds: []
    property string activeCategory: "All"
    property string searchQuery: ""

    // Read Keybinds Catalog from keybinds_catalog.py
    Process {
        id: catalogProc
        command: ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/keybinds_catalog.py"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(text.trim())
                        root.allKeybinds = parsed || []
                        root.updateFilter()
                    } catch(e) {}
                }
            }
        }
    }

    function updateFilter() {
        var q = searchQuery.toLowerCase().trim()
        var cat = activeCategory
        var res = []

        for (var i = 0; i < allKeybinds.length; i++) {
            var item = allKeybinds[i]
            if (cat !== "All" && item.category !== cat) continue

            if (q.length > 0) {
                var comboMatch = (item.combo || "").toLowerCase().indexOf(q) !== -1
                var actionMatch = (item.action || "").toLowerCase().indexOf(q) !== -1
                var descMatch = (item.desc || "").toLowerCase().indexOf(q) !== -1
                var catMatch = (item.category || "").toLowerCase().indexOf(q) !== -1
                if (!comboMatch && !actionMatch && !descMatch && !catMatch) continue
            }
            res.push(item)
        }
        filteredKeybinds = res
    }

    // Close Handler
    function closeHud() {
        Qt.quit()
    }

    Item {
        anchors.fill: parent

        // Dismiss Backdrop
        MouseArea {
            anchors.fill: parent
            onClicked: root.closeHud()
        }

        // ── CENTERED OBSIDIAN GLASS HUD MODAL ────────────────────────────────────
        Rectangle {
            id: modal
            width: 880
            height: 640
            anchors.centerIn: parent
            radius: 16
            color: Theme.alpha(Theme.surface, 0.85)
            border.width: 1.2
            border.color: Theme.alpha(Theme.accent, 0.40)
            clip: true
            focus: true

            Keys.priority: Keys.BeforeItem
            Keys.onEscapePressed: function(event) {
                event.accepted = true
                root.closeHud()
            }

            // Top Subtle Glass Rim Highlight
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            height: 1
            color: Theme.alpha(Theme.foreground, 0.15)
        }

        // Prevent click-through closing inside the card
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            // ── TOP HEADER ROW ───────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Keyboard icon badge
                Rectangle {
                    width: 36; height: 36; radius: 8
                    color: Theme.alpha(Theme.accent, 0.18)
                    border.width: 1; border.color: Theme.accent
                    Text {
                        anchors.centerIn: parent
                        text: "⌨"
                        font.pixelSize: 18
                        color: Theme.accent
                    }
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: "KEYBOARD SHORTCUTS HUD"
                        font.family: "Outfit"; font.pixelSize: 15; font.weight: Font.Bold; font.letterSpacing: 0.8
                        color: Theme.foreground
                    }
                    Text {
                        text: "Interactive Hyprland & Quickshell Cheatsheet • Click any shortcut to test"
                        font.family: "Outfit"; font.pixelSize: 11
                        color: Theme.alpha(Theme.foreground, 0.50)
                    }
                }

                // Close Button
                Rectangle {
                    width: 30; height: 30; radius: 6
                    color: closeMouse.containsMouse ? Theme.alpha(Theme.error, 0.25) : Theme.alpha(Theme.foreground, 0.08)
                    border.width: 1; border.color: closeMouse.containsMouse ? Theme.error : Theme.alpha(Theme.foreground, 0.15)

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 12; font.bold: true
                        color: closeMouse.containsMouse ? Theme.error : Theme.foreground
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeHud()
                    }
                }
            }

            // ── SEARCH & FILTER ROW ──────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Search Input Box
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 8
                    color: Theme.alpha(Theme.background, 0.85)
                    border.width: 1
                    border.color: hudSearchInput.activeFocus ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12; anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: "󰍉"
                            font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 14
                            color: Theme.accent
                        }

                        TextInput {
                            id: hudSearchInput
                            Layout.fillWidth: true
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: "JetBrainsMono Nerd Font, monospace"
                            font.pixelSize: 12
                            color: Theme.foreground
                            selectByMouse: true
                            selectedTextColor: Theme.on_primary
                            selectionColor: Theme.accent

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                visible: !hudSearchInput.text && !hudSearchInput.activeFocus
                                text: "Filter shortcuts (e.g. terminal, screenshot, split, audio, workspace)..."
                                font.family: "Outfit"
                                font.pixelSize: 12
                                color: Theme.alpha(Theme.foreground, 0.38)
                            }

                            onTextChanged: {
                                root.searchQuery = text
                                root.updateFilter()
                            }

                            Component.onCompleted: hudSearchInput.forceActiveFocus()
                        }
                    }
                }

                // Total shortcuts count pill
                Rectangle {
                    height: 40
                    implicitWidth: countText.implicitWidth + 18
                    radius: 8
                    color: Theme.alpha(Theme.surface, 0.8)
                    border.width: 1
                    border.color: Theme.alpha(Theme.foreground, 0.12)

                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: root.filteredKeybinds.length + " shortcuts"
                        font.family: "Outfit"; font.pixelSize: 11; font.weight: Font.Medium
                        color: Theme.muted
                    }
                }
            }

            // ── CATEGORY TABS ────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: ["All", "Apps", "Windows", "Quickshell", "Workspaces", "Media", "System"]
                    delegate: Rectangle {
                        id: catTab
                        required property string modelData
                        height: 28
                        implicitWidth: catTabText.implicitWidth + 16
                        radius: 6

                        readonly property bool isSelected: root.activeCategory === catTab.modelData
                        color: isSelected ? Theme.alpha(Theme.accent, 0.22) : (tabMouse.containsMouse ? Theme.alpha(Theme.surface, 0.8) : "transparent")
                        border.width: isSelected ? 1 : 0
                        border.color: Theme.accent

                        Text {
                            id: catTabText
                            anchors.centerIn: parent
                            text: catTab.modelData
                            font.family: "Outfit"; font.pixelSize: 11
                            font.weight: catTab.isSelected ? Font.Bold : Font.Normal
                            color: catTab.isSelected ? Theme.accent : Theme.foreground
                        }

                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.activeCategory = catTab.modelData
                                root.updateFilter()
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.alpha(Theme.foreground, 0.08)
            }

            // ── 2-COLUMN GRID VIEW OF SHORTCUTS ──────────────────────────────
            ScrollView {
                id: shortcutsScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ScrollBar.vertical: ScrollBar {
                    parent: shortcutsScroll
                    anchors.top: shortcutsScroll.top
                    anchors.right: shortcutsScroll.right
                    anchors.bottom: shortcutsScroll.bottom
                    width: 5
                    policy: ScrollBar.AsNeeded
                }

                GridView {
                    id: shortcutsGrid
                    width: shortcutsScroll.width - 10
                    cellWidth: width / 2
                    cellHeight: 72
                    model: root.filteredKeybinds

                    delegate: Item {
                        id: cardItem
                        required property var modelData
                        width: shortcutsGrid.cellWidth
                        height: shortcutsGrid.cellHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 8
                            color: itemMouse.containsMouse ? Theme.alpha(Theme.accent, 0.16) : Theme.alpha(Theme.surface, 0.40)
                            border.width: 1
                            border.color: itemMouse.containsMouse ? Theme.alpha(Theme.accent, 0.45) : Theme.alpha(Theme.foreground, 0.08)
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 3

                                    Text {
                                        text: cardItem.modelData.action || ""
                                        font.family: "Outfit"; font.pixelSize: 12; font.weight: Font.Bold
                                        color: itemMouse.containsMouse ? Theme.accent : Theme.foreground
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: cardItem.modelData.desc || ""
                                        font.family: "Outfit"; font.pixelSize: 10
                                        color: Theme.alpha(Theme.foreground, 0.50)
                                        elide: Text.ElideRight
                                    }
                                }

                                // Tactile Keycap Badge
                                Rectangle {
                                    height: 26
                                    implicitWidth: comboText.implicitWidth + 14
                                    radius: 5
                                    color: Theme.alpha(Theme.background, 0.90)
                                    border.width: 1
                                    border.color: Theme.alpha(Theme.accent, 0.35)

                                    Text {
                                        id: comboText
                                        anchors.centerIn: parent
                                        text: cardItem.modelData.combo || ""
                                        font.family: "JetBrainsMono Nerd Font, monospace"
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: Theme.accent
                                    }
                                }
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    // Copy combo to clipboard
                                    Quickshell.execDetached(["wl-copy", cardItem.modelData.combo])
                                    var osdCmd = root.homeDir + "/.hyprconf/hypr/scripts/sh/osd-notify.sh"
                                    Quickshell.execDetached([osdCmd, "keyboard", "1", "Shortcut Copied", "keyboard", cardItem.modelData.combo])
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
}
