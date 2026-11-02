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

    // ── External Data Bindings ───────────────────────────────────────────────
    readonly property var keybindsData: (typeof window !== "undefined" && window.liveKeybinds) ? window.liveKeybinds : []
    readonly property var pendingEdits: (typeof window !== "undefined" && window.pendingHyprChanges && window.pendingHyprChanges.keybind_edit) ? window.pendingHyprChanges.keybind_edit : ({})
    readonly property var pendingRemoves: (typeof window !== "undefined" && window.pendingHyprChanges && window.pendingHyprChanges.keybind_remove) ? window.pendingHyprChanges.keybind_remove : []
    readonly property var pendingAdds: (typeof window !== "undefined" && window.pendingHyprChanges && window.pendingHyprChanges.keybind_add) ? window.pendingHyprChanges.keybind_add : []

    readonly property int modifiedCount: Object.keys(pendingEdits).length
    readonly property int removedCount: pendingRemoves.length
    readonly property int addedCount: pendingAdds.length
    readonly property int totalPending: modifiedCount + removedCount + addedCount

    // ── Filter & Search State ────────────────────────────────────────────────
    property string searchQuery: ""
    property string selectedCategory: "All"
    readonly property var categoryList: [
        "All",
        "Apps & Launchers",
        "Window Management",
        "Workspaces",
        "Media & Hardware",
        "System"
    ]

    // ── Modal State ──────────────────────────────────────────────────────────
    property bool showModal: false
    property bool isEditing: false
    property string targetOriginalRaw: ""
    property string targetOriginalCombo: ""

    // Modal Form Fields
    property bool formModSuper: true
    property bool formModCtrl: false
    property bool formModAlt: false
    property bool formModShift: false
    property string formKey: ""
    property string formActionType: "exec" // "exec", "window", "workspace", "custom"
    property string formCommand: ""
    property string formWindowSubAction: "close" // "close", "float", "fullscreen", "pseudo", "cycle"
    property int formWorkspaceNum: 1
    property string formWorkspaceSubAction: "switch" // "switch", "move"
    property string formCustomLua: ""
    property string conflictWarning: ""

    // ── SVG Icons ────────────────────────────────────────────────────────────
    function svgUrl(svgString) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgString)
    }

    readonly property string searchSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.alpha(Theme.foreground, 0.50) + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>')
    readonly property string plusSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.on_primary + '" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>')
    readonly property string checkSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.on_primary + '" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>')
    readonly property string editSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>')
    readonly property string trashSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.error + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>')
    readonly property string undoSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 1 0 2.13-9.36L1 10"/></svg>')
    readonly property string playSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="' + Theme.accent + '" stroke="none"><polygon points="5 3 19 12 5 21 5 3"/></svg>')
    readonly property string closeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>')
    readonly property string keySvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="4" width="20" height="16" rx="2"></rect><line x1="6" y1="8" x2="6" y2="8"></line><line x1="10" y1="8" x2="10" y2="8"></line><line x1="14" y1="8" x2="14" y2="8"></line><line x1="18" y1="8" x2="18" y2="8"></line><line x1="6" y1="12" x2="6" y2="12"></line><line x1="10" y1="12" x2="10" y2="12"></line><line x1="14" y1="12" x2="14" y2="12"></line><line x1="18" y1="12" x2="18" y2="12"></line><line x1="7" y1="16" x2="17" y2="16"></line></svg>')
    readonly property string warnSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.error + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>')

    // ── Generator & Validator Functions ──────────────────────────────────────
    function getDisplayCombo() {
        var m = []
        if (formModSuper) m.push("SUPER")
        if (formModCtrl) m.push("CTRL")
        if (formModAlt) m.push("ALT")
        if (formModShift) m.push("SHIFT")
        var k = formKey.trim()
        if (!k) return m.join(" + ")
        return (m.length > 0 ? (m.join(" + ") + " + ") : "") + k
    }

    // Accurately formats ANY combination of SUPER, CTRL, ALT, SHIFT into standard Lua string syntax
    function generateLuaCombo() {
        var k = formKey.trim()
        if (!k) return '""'

        var modParts = []
        if (formModCtrl) modParts.push("CTRL")
        if (formModAlt) modParts.push("ALT")
        if (formModShift) modParts.push("SHIFT")

        if (formModSuper) {
            if (modParts.length > 0) {
                return 'mainMod .. " + ' + modParts.join(" + ") + ' + ' + k + '"'
            } else {
                return 'mainMod .. " + ' + k + '"'
            }
        } else {
            if (modParts.length > 0) {
                return '"' + modParts.join(" + ") + ' + ' + k + '"'
            } else {
                return '"' + k + '"'
            }
        }
    }

    function generateLuaAction() {
        if (formActionType === "exec") {
            var cmd = formCommand.trim()
            return 'hl.dsp.exec_cmd("' + cmd.replace(/"/g, '\\"') + '")'
        } else if (formActionType === "window") {
            if (formWindowSubAction === "close") return "hl.dsp.window.close()"
            if (formWindowSubAction === "float") return 'hl.dsp.window.float({ action = "toggle" })'
            if (formWindowSubAction === "fullscreen") return "hl.dsp.window.fullscreen()"
            if (formWindowSubAction === "pseudo") return "hl.dsp.window.pseudo()"
            if (formWindowSubAction === "cycle") return "hl.dsp.window.cycle_next()"
            return "hl.dsp.window.close()"
        } else if (formActionType === "workspace") {
            if (formWorkspaceSubAction === "switch") {
                return "hl.dsp.focus({ workspace = " + formWorkspaceNum + " })"
            } else {
                return "hl.dsp.window.move({ workspace = " + formWorkspaceNum + " })"
            }
        } else {
            return formCustomLua.trim() || 'hl.dsp.exec_cmd("")'
        }
    }

    function generateFullLuaStatement() {
        return "hl.bind(" + generateLuaCombo() + ", " + generateLuaAction() + ")"
    }

    function updateConflictWarning() {
        var currentCombo = getDisplayCombo().trim().toLowerCase()
        if (!currentCombo || !formKey.trim()) {
            conflictWarning = ""
            return
        }
        for (var i = 0; i < keybindsData.length; i++) {
            var item = keybindsData[i]
            if (isEditing && item.raw === targetOriginalRaw) continue
            var itemCombo = (item.combo || "").trim().toLowerCase()
            if (itemCombo === currentCombo) {
                conflictWarning = "Conflicts with: " + (item.title || item.action || item.raw)
                return
            }
        }
        conflictWarning = ""
    }

    onFormModSuperChanged: updateConflictWarning()
    onFormModCtrlChanged: updateConflictWarning()
    onFormModAltChanged: updateConflictWarning()
    onFormModShiftChanged: updateConflictWarning()
    onFormKeyChanged: updateConflictWarning()

    function openAddModal() {
        isEditing = false
        targetOriginalRaw = ""
        targetOriginalCombo = ""
        formModSuper = true
        formModCtrl = false
        formModAlt = false
        formModShift = false
        formKey = ""
        formActionType = "exec"
        formCommand = ""
        formWindowSubAction = "close"
        formWorkspaceNum = 1
        formWorkspaceSubAction = "switch"
        formCustomLua = ""
        conflictWarning = ""
        showModal = true
    }

    function openEditModal(item) {
        isEditing = true
        targetOriginalRaw = item.raw
        targetOriginalCombo = item.combo
        var mods = item.mods || []
        formModSuper = mods.indexOf("SUPER") !== -1
        formModCtrl = mods.indexOf("CTRL") !== -1
        formModAlt = mods.indexOf("ALT") !== -1
        formModShift = mods.indexOf("SHIFT") !== -1
        formKey = item.key || ""
        
        if (item.action_type === "exec") {
            formActionType = "exec"
            formCommand = item.command || ""
        } else if (item.action_type && item.action_type.indexOf("window") !== -1) {
            formActionType = "window"
            if (item.action_type === "window_float") formWindowSubAction = "float"
            else if (item.action_type === "window_fullscreen") formWindowSubAction = "fullscreen"
            else if (item.action_type === "window_pseudo") formWindowSubAction = "pseudo"
            else formWindowSubAction = "close"
        } else if (item.action_type === "workspace") {
            formActionType = "workspace"
            formWorkspaceSubAction = "switch"
            formWorkspaceNum = 1
        } else {
            formActionType = "custom"
            formCustomLua = item.raw_action || item.action || ""
        }
        updateConflictWarning()
        showModal = true
    }

    function saveModal() {
        if (!formKey.trim()) return
        var newStatement = generateFullLuaStatement()

        if (isEditing) {
            var edits = Object.assign({}, pendingEdits)
            edits[targetOriginalRaw] = newStatement
            if (typeof window !== "undefined") window.markHypr("keybind_edit", edits)
        } else {
            var adds = pendingAdds.slice()
            adds.push(newStatement)
            if (typeof window !== "undefined") window.markHypr("keybind_add", adds)
        }

        showModal = false
        if (typeof window !== "undefined") {
            window.toastMessage = isEditing ? "Keybind edit queued! Click Apply to save." : "New keybind queued! Click Apply to save."
            window.showSaveToast = true
            if (typeof toastTimer !== "undefined") toastTimer.restart()
        }
    }

    function toggleRemove(item) {
        var removes = pendingRemoves.slice()
        var idx = removes.indexOf(item.raw)
        if (idx === -1) {
            removes.push(item.raw)
        } else {
            removes.splice(idx, 1)
        }
        if (typeof window !== "undefined") window.markHypr("keybind_remove", removes)
    }

    function undoEdit(item) {
        var edits = Object.assign({}, pendingEdits)
        delete edits[item.raw]
        if (typeof window !== "undefined") window.markHypr("keybind_edit", edits)
    }

    function removeAddedBind(rawStatement) {
        var adds = pendingAdds.slice()
        var idx = adds.indexOf(rawStatement)
        if (idx !== -1) {
            adds.splice(idx, 1)
            if (typeof window !== "undefined") window.markHypr("keybind_add", adds)
        }
    }

    function runCommand(cmd) {
        if (!cmd || cmd.trim().length === 0) return
        Quickshell.execDetached(["bash", "-c", cmd])
        if (typeof window !== "undefined") {
            window.toastMessage = "Executed: " + cmd.substring(0, 40)
            window.showSaveToast = true
            if (typeof toastTimer !== "undefined") toastTimer.restart()
        }
    }

    function openIslandKeybindsCheatsheet() {
        Quickshell.execDetached(["bash", "-c", root.homeDir + "/.hyprconf/hypr/scripts/sh/qs-keybinds.sh"])
        if (typeof window !== "undefined") {
            window.toastMessage = "Opening Keybinds Shortcut Viewer (SUPER + SHIFT + H)..."
            window.showSaveToast = true
            if (typeof toastTimer !== "undefined") toastTimer.restart()
        }
    }

    // ── Main UI Layout ───────────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        anchors.margins: 18

        ColumnLayout {
            anchors.fill: parent
            spacing: 14

            // 1. TOP HEADER & STATISTICS BAR
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 72
                radius: 14
                color: Theme.alpha(Theme.surface, 0.50)
                border.width: 1
                border.color: Theme.alpha(Theme.accent, 0.20)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    spacing: 14

                    Image {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        source: root.keySvg
                        sourceSize: Qt.size(64, 64)
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        RowLayout {
                            spacing: 8
                            Text {
                                text: "Hyprland Keybindings Manager"
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                            }

                            // Total Count Pill
                            Rectangle {
                                Layout.preferredHeight: 20
                                Layout.preferredWidth: countTxt.implicitWidth + 14
                                radius: 10
                                color: Theme.alpha(Theme.accent, 0.18)
                                border.width: 1
                                border.color: Theme.alpha(Theme.accent, 0.40)
                                Text {
                                    id: countTxt
                                    anchors.centerIn: parent
                                    text: (root.keybindsData.length + root.addedCount) + " Keybinds"
                                    color: Theme.accent
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }
                            }

                            // Pending Changes Pill
                            Rectangle {
                                visible: root.totalPending > 0
                                Layout.preferredHeight: 20
                                Layout.preferredWidth: pendingTxt.implicitWidth + 14
                                radius: 10
                                color: Theme.alpha(Theme.primary, 0.20)
                                border.width: 1
                                border.color: Theme.primary
                                Text {
                                    id: pendingTxt
                                    anchors.centerIn: parent
                                    text: "• " + root.totalPending + " Pending Changes"
                                    color: Theme.primary
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }
                            }
                        }

                        Text {
                            text: "Add, rebind, customize, or search shortcuts. Live reload applies instantly on save."
                            color: Theme.alpha(Theme.foreground, 0.65)
                            font.family: "Outfit"
                            font.pixelSize: 11
                        }
                    }

                    // Open Cheatsheet / Viewer Button (Bound to SUPER + SHIFT + H)
                    Rectangle {
                        Layout.preferredHeight: 36
                        Layout.preferredWidth: viewerBtnContent.implicitWidth + 24
                        radius: 8
                        color: viewerMouse.containsMouse ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surface, 0.60)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.40)
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            id: viewerBtnContent
                            anchors.centerIn: parent
                            spacing: 7
                            Text {
                                text: "󰌌"
                                font.pixelSize: 13
                                color: Theme.accent
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Cheatsheet (SUPER+SHIFT+H)"
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: viewerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openIslandKeybindsCheatsheet()
                        }
                    }

                    // Apply Pending Button
                    Rectangle {
                        visible: root.totalPending > 0
                        Layout.preferredHeight: 36
                        Layout.preferredWidth: applyBtnContent.implicitWidth + 24
                        radius: 8
                        color: applyMouse.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            id: applyBtnContent
                            anchors.centerIn: parent
                            spacing: 7
                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 14
                                height: 14
                                source: root.checkSvg
                                sourceSize: Qt.size(28, 28)
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Apply Changes"
                                color: Theme.on_primary
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                        }

                        MouseArea {
                            id: applyMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof window !== "undefined") window.applyAllChanges()
                            }
                        }
                    }

                    // Add Keybind Button
                    Rectangle {
                        Layout.preferredHeight: 36
                        Layout.preferredWidth: addBtnContent.implicitWidth + 24
                        radius: 8
                        color: addMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.60)
                        border.width: 1
                        border.color: Theme.accent
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            id: addBtnContent
                            anchors.centerIn: parent
                            spacing: 7
                            Text {
                                text: "+"
                                font.family: "Outfit"
                                font.pixelSize: 16
                                font.weight: Font.Bold
                                color: Theme.accent
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Add Keybind"
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
                            onClicked: root.openAddModal()
                        }
                    }
                }
            }

            // 2. SEARCH BAR & CATEGORY FILTER ROW
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Search Input Box
                Rectangle {
                    Layout.preferredWidth: 320
                    Layout.preferredHeight: 38
                    radius: 10
                    color: Theme.alpha(Theme.surface, 0.60)
                    border.width: 1
                    border.color: searchInput.activeFocus ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)
                    Behavior on border.color { ColorAnimation { duration: 120 } }

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
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 12
                            text: root.searchQuery
                            onTextChanged: root.searchQuery = text
                            clip: true

                            Text {
                                anchors.fill: parent
                                text: "Search shortcut, action, command..."
                                color: Theme.alpha(Theme.foreground, 0.40)
                                font.family: "Outfit"
                                font.pixelSize: 12
                                visible: !parent.text && !parent.activeFocus
                            }
                        }

                        // Clear Button
                        Text {
                            visible: root.searchQuery.length > 0
                            text: "✕"
                            color: Theme.alpha(Theme.foreground, 0.50)
                            font.pixelSize: 12
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.searchQuery = ""
                                    searchInput.text = ""
                                }
                            }
                        }
                    }
                }

                // Category Chips
                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    contentWidth: categoryRow.implicitWidth
                    contentHeight: height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: categoryRow
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter

                        Repeater {
                            model: root.categoryList

                            Rectangle {
                                readonly property bool isSelected: root.selectedCategory === modelData
                                height: 32
                                implicitWidth: catTxt.implicitWidth + 22
                                radius: 16
                                color: isSelected ? Theme.alpha(Theme.accent, 0.22) : (catMouse.containsMouse ? Theme.alpha(Theme.surface, 0.85) : Theme.alpha(Theme.surface, 0.40))
                                border.width: 1
                                border.color: isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    id: catTxt
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: parent.isSelected ? Theme.accent : Theme.foreground
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    font.weight: parent.isSelected ? Font.DemiBold : Font.Normal
                                }

                                MouseArea {
                                    id: catMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectedCategory = modelData
                                }
                            }
                        }
                    }
                }
            }

            // 3. KEYBINDINGS LIST VIEW
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth

                Column {
                    width: parent.width
                    spacing: 8

                    // A. Newly Added Keybinds (Pending)
                    Repeater {
                        model: root.pendingAdds

                        Rectangle {
                            width: parent.width
                            height: 62
                            radius: 12
                            color: Theme.alpha(Theme.surface, 0.70)
                            border.width: 1.5
                            border.color: Theme.primary

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 14
                                spacing: 14

                                // Status Badge
                                Rectangle {
                                    Layout.preferredHeight: 22
                                    Layout.preferredWidth: newBadgeTxt.implicitWidth + 12
                                    radius: 6
                                    color: Theme.alpha(Theme.primary, 0.25)
                                    border.width: 1
                                    border.color: Theme.primary
                                    Text {
                                        id: newBadgeTxt
                                        anchors.centerIn: parent
                                        text: "NEW"
                                        color: Theme.primary
                                        font.family: "Outfit"
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3

                                    Text {
                                        text: "New Custom Keybind Statement"
                                        color: Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: modelData
                                        color: Theme.accent
                                        font.family: "monospace"
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                // Cancel Addition Button
                                Rectangle {
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    radius: 8
                                    color: Theme.alpha(Theme.surface, 0.80)
                                    border.width: 1
                                    border.color: Theme.alpha(Theme.foreground, 0.20)

                                    Image {
                                        anchors.centerIn: parent
                                        width: 14
                                        height: 14
                                        source: root.closeSvg
                                        sourceSize: Qt.size(28, 28)
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.removeAddedBind(modelData)
                                    }
                                }
                            }
                        }
                    }

                    // B. Main Keybindings List
                    Repeater {
                        model: {
                            var q = root.searchQuery.trim().toLowerCase()
                            var cat = root.selectedCategory
                            var list = []

                            for (var i = 0; i < root.keybindsData.length; i++) {
                                var it = root.keybindsData[i]
                                var itemCat = it.category || "General"

                                // Category filter
                                if (cat !== "All") {
                                    if (cat === "Apps & Launchers" && itemCat !== "Apps & Launchers" && itemCat !== "Apps" && itemCat !== "Applications") continue
                                    else if (cat === "Window Management" && itemCat !== "Window Management" && itemCat !== "Windows") continue
                                    else if (cat === "Workspaces" && itemCat !== "Workspaces") continue
                                    else if (cat === "Media & Hardware" && itemCat !== "Media & Hardware" && itemCat !== "Media" && itemCat !== "Audio") continue
                                    else if (cat === "System" && itemCat !== "System") continue
                                }

                                // Search query filter
                                if (q.length > 0) {
                                    var matchCombo = (it.combo || "").toLowerCase().indexOf(q) !== -1
                                    var matchTitle = (it.title || "").toLowerCase().indexOf(q) !== -1
                                    var matchAction = (it.action || "").toLowerCase().indexOf(q) !== -1
                                    var matchCommand = (it.command || "").toLowerCase().indexOf(q) !== -1
                                    var matchDesc = (it.desc || "").toLowerCase().indexOf(q) !== -1
                                    if (!matchCombo && !matchTitle && !matchAction && !matchCommand && !matchDesc) continue
                                }

                                list.push(it)
                            }
                            return list
                        }

                        Rectangle {
                            id: cardRect
                            width: parent.width
                            height: 66
                            radius: 12

                            readonly property bool isModified: root.pendingEdits && (root.pendingEdits[modelData.raw] !== undefined)
                            readonly property bool isRemoved: root.pendingRemoves.indexOf(modelData.raw) !== -1
                            readonly property string activeCombo: isModified ? root.getComboFromRaw(root.pendingEdits[modelData.raw]) : modelData.combo

                            color: isRemoved
                                ? Theme.alpha(Theme.error, 0.12)
                                : (isModified ? Theme.alpha(Theme.accent, 0.16) : (cardMouse.containsMouse ? Theme.alpha(Theme.surface, 0.75) : Theme.alpha(Theme.surface, 0.45)))
                            border.width: (isModified || isRemoved) ? 1.5 : 1
                            border.color: isRemoved
                                ? Theme.alpha(Theme.error, 0.60)
                                : (isModified ? Theme.accent : (cardMouse.containsMouse ? Theme.alpha(Theme.accent, 0.40) : Theme.alpha(Theme.foreground, 0.10)))

                            opacity: isRemoved ? 0.45 : 1.0
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 14
                                spacing: 14

                                // 1. KEY COMBO BADGES
                                Row {
                                    spacing: 5
                                    Layout.preferredWidth: 240
                                    Layout.alignment: Qt.AlignVCenter

                                    Repeater {
                                        model: (cardRect.activeCombo || "").split("+")

                                        Row {
                                            spacing: 5
                                            Rectangle {
                                                readonly property string part: modelData.trim()
                                                readonly property bool isMod: part === "SUPER" || part === "CTRL" || part === "ALT" || part === "SHIFT"
                                                height: 28
                                                width: partTxt.implicitWidth + 14
                                                radius: 6
                                                color: isMod ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.90)
                                                border.width: 1
                                                border.color: isMod ? Theme.accent : Theme.alpha(Theme.foreground, 0.20)

                                                Text {
                                                    id: partTxt
                                                    anchors.centerIn: parent
                                                    text: parent.part
                                                    color: parent.isMod ? Theme.accent : Theme.foreground
                                                    font.family: "Outfit"
                                                    font.pixelSize: 11
                                                    font.weight: Font.DemiBold
                                                }
                                            }

                                            Text {
                                                visible: index < (cardRect.activeCombo.split("+").length - 1)
                                                text: "+"
                                                color: Theme.alpha(Theme.foreground, 0.40)
                                                font.pixelSize: 11
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                    }
                                }

                                // Vertical Divider
                                Rectangle {
                                    Layout.preferredWidth: 1
                                    Layout.preferredHeight: 32
                                    color: Theme.alpha(Theme.foreground, 0.10)
                                }

                                // 2. ACTION & DESCRIPTION
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3

                                    RowLayout {
                                        spacing: 8
                                        Text {
                                            text: modelData.title || modelData.action || "Custom Action"
                                            color: Theme.foreground
                                            font.family: "Outfit"
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        // Category Pill
                                        Rectangle {
                                            Layout.preferredHeight: 18
                                            Layout.preferredWidth: catBadgeTxt.implicitWidth + 10
                                            radius: 5
                                            color: Theme.alpha(Theme.foreground, 0.08)
                                            border.width: 1
                                            border.color: Theme.alpha(Theme.foreground, 0.12)
                                            Text {
                                                id: catBadgeTxt
                                                anchors.centerIn: parent
                                                text: modelData.category || "General"
                                                color: Theme.alpha(Theme.foreground, 0.65)
                                                font.family: "Outfit"
                                                font.pixelSize: 9
                                            }
                                        }

                                        // Modified Badge
                                        Rectangle {
                                            visible: cardRect.isModified
                                            Layout.preferredHeight: 18
                                            Layout.preferredWidth: modBadgeTxt.implicitWidth + 10
                                            radius: 5
                                            color: Theme.accent
                                            Text {
                                                id: modBadgeTxt
                                                anchors.centerIn: parent
                                                text: "MODIFIED"
                                                color: Theme.on_primary
                                                font.family: "Outfit"
                                                font.pixelSize: 8
                                                font.weight: Font.Bold
                                            }
                                        }

                                        // Removed Badge
                                        Rectangle {
                                            visible: cardRect.isRemoved
                                            Layout.preferredHeight: 18
                                            Layout.preferredWidth: remBadgeTxt.implicitWidth + 10
                                            radius: 5
                                            color: Theme.error
                                            Text {
                                                id: remBadgeTxt
                                                anchors.centerIn: parent
                                                text: "QUEUED FOR REMOVAL"
                                                color: Theme.on_primary
                                                font.family: "Outfit"
                                                font.pixelSize: 8
                                                font.weight: Font.Bold
                                            }
                                        }
                                    }

                                    // Action Details / Command / Code
                                    Text {
                                        text: {
                                            if (cardRect.isModified) {
                                                return "New: " + root.pendingEdits[modelData.raw]
                                            }
                                            if (modelData.command && modelData.command.length > 0) {
                                                return modelData.command
                                            }
                                            return modelData.desc || modelData.action
                                        }
                                        color: cardRect.isModified ? Theme.accent : Theme.alpha(Theme.foreground, 0.55)
                                        font.family: (modelData.command || cardRect.isModified) ? "monospace" : "Outfit"
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                // 3. ACTION BUTTONS
                                Row {
                                    spacing: 8
                                    Layout.alignment: Qt.AlignVCenter

                                    // Run / Test Button (Available for command actions)
                                    Rectangle {
                                        visible: modelData.command && modelData.command.length > 0 && !cardRect.isRemoved
                                        width: 32
                                        height: 32
                                        radius: 8
                                        color: runMouse.containsMouse ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surface, 0.60)
                                        border.width: 1
                                        border.color: runMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)

                                        Image {
                                            anchors.centerIn: parent
                                            width: 12
                                            height: 12
                                            source: root.playSvg
                                            sourceSize: Qt.size(24, 24)
                                        }

                                        MouseArea {
                                            id: runMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.runCommand(modelData.command)
                                        }
                                    }

                                    // Edit Button
                                    Rectangle {
                                        visible: !cardRect.isRemoved
                                        width: 32
                                        height: 32
                                        radius: 8
                                        color: editMouse.containsMouse ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surface, 0.60)
                                        border.width: 1
                                        border.color: editMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)

                                        Image {
                                            anchors.centerIn: parent
                                            width: 13
                                            height: 13
                                            source: root.editSvg
                                            sourceSize: Qt.size(26, 26)
                                        }

                                        MouseArea {
                                            id: editMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.openEditModal(modelData)
                                        }
                                    }

                                    // Revert / Undo Edit Button
                                    Rectangle {
                                        visible: cardRect.isModified
                                        width: 32
                                        height: 32
                                        radius: 8
                                        color: undoMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.60)
                                        border.width: 1
                                        border.color: Theme.alpha(Theme.foreground, 0.20)

                                        Image {
                                            anchors.centerIn: parent
                                            width: 13
                                            height: 13
                                            source: root.undoSvg
                                            sourceSize: Qt.size(26, 26)
                                        }

                                        MouseArea {
                                            id: undoMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.undoEdit(modelData)
                                        }
                                    }

                                    // Delete / Undo Delete Button
                                    Rectangle {
                                        width: 32
                                        height: 32
                                        radius: 8
                                        color: cardRect.isRemoved
                                            ? (delMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.60))
                                            : (delMouse.containsMouse ? Theme.alpha(Theme.error, 0.25) : Theme.alpha(Theme.surface, 0.60))
                                        border.width: 1
                                        border.color: cardRect.isRemoved ? Theme.alpha(Theme.foreground, 0.20) : (delMouse.containsMouse ? Theme.error : Theme.alpha(Theme.foreground, 0.15))

                                        Image {
                                            anchors.centerIn: parent
                                            width: 13
                                            height: 13
                                            source: cardRect.isRemoved ? root.undoSvg : root.trashSvg
                                            sourceSize: Qt.size(26, 26)
                                        }

                                        MouseArea {
                                            id: delMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.toggleRemove(modelData)
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                propagateComposedEvents: true
                                z: -1
                            }
                        }
                    }

                    // Empty State Card
                    Rectangle {
                        visible: root.keybindsData.length === 0
                        width: parent.width
                        height: 120
                        radius: 12
                        color: Theme.alpha(Theme.surface, 0.40)
                        border.width: 1
                        border.color: Theme.alpha(Theme.foreground, 0.10)

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "No keybindings loaded"
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Ensure keybinds.lua exists in ~/.hyprconf/hypr/configs/"
                                color: Theme.alpha(Theme.foreground, 0.50)
                                font.family: "Outfit"
                                font.pixelSize: 11
                            }
                        }
                    }
                }
            }
        }
    }

    // Helper to parse combo from raw statement
    function getComboFromRaw(raw) {
        if (!raw) return ""
        try {
            var m = raw.match(/hl\.bind\s*\(([^,]+)/)
            if (m && m[1]) {
                var c = m[1].trim()
                c = c.replace(/\.\.\s*"/g, "+ ").replace(/\.\.\s*'/g, "+ ").replace(/"/g, "").replace(/'/g, "")
                c = c.replace(/mainMod/g, "SUPER").replace(/ctrl/g, "CTRL").replace(/alt/g, "ALT").replace(/shift/g, "SHIFT")
                c = c.replace(/\+\s*\+/g, "+").trim()
                return c
            }
        } catch(e) {}
        return ""
    }

    // ── MODAL DIALOG (ADD / EDIT KEYBINDING) ──────────────────────────────────
    Rectangle {
        id: modalScrim
        anchors.fill: parent
        color: Theme.alpha("#000000", 0.70)
        visible: root.showModal
        z: 100

        MouseArea {
            anchors.fill: parent
            onClicked: {
                keyRecordBox.isRecording = false
                root.showModal = false
            }
        }

        Rectangle {
            id: modalCard
            width: 660
            height: 600
            radius: 16
            color: Theme.background
            border.width: 1.5
            border.color: Theme.alpha(Theme.accent, 0.40)
            anchors.centerIn: parent

            MouseArea {
                anchors.fill: parent
                // Stop click propagation
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 14

                // Modal Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Image {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        source: root.isEditing ? root.editSvg : root.plusSvg
                        sourceSize: Qt.size(40, 40)
                    }

                    Text {
                        text: root.isEditing ? ("Edit Keybinding (" + root.targetOriginalCombo + ")") : "Add New Keybinding"
                        color: Theme.foreground
                        font.family: "Outfit"
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 7
                        color: closeMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.50)

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: Theme.foreground
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                keyRecordBox.isRecording = false
                                root.showModal = false
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.alpha(Theme.foreground, 0.10)
                }

                // Modal Body (Scrollable)
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: availableWidth

                    ColumnLayout {
                        width: parent.width
                        spacing: 14

                        // 1. KEY COMBINATION & RECORDER
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "1. Key Combination (Hold any combination of Super, Ctrl, Alt, Shift)"
                                color: Theme.accent
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            // Interactive Keyboard Capture Box
                            Rectangle {
                                id: keyRecordBox
                                Layout.fillWidth: true
                                Layout.preferredHeight: 46
                                radius: 10
                                color: isRecording ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.70)
                                border.width: isRecording ? 2 : 1
                                border.color: isRecording ? Theme.accent : Theme.alpha(Theme.accent, 0.30)
                                clip: true

                                property bool isRecording: false

                                focus: isRecording

                                Keys.onPressed: function(event) {
                                    if (!isRecording) return

                                    // 1. Detect held modifier keys
                                    if (event.modifiers & Qt.MetaModifier) root.formModSuper = true
                                    if (event.modifiers & Qt.ControlModifier) root.formModCtrl = true
                                    if (event.modifiers & Qt.AltModifier) root.formModAlt = true
                                    if (event.modifiers & Qt.ShiftModifier) root.formModShift = true

                                    var k = event.key
                                    // Check if the pressed key itself is a modifier
                                    if (k === Qt.Key_Meta || k === Qt.Key_Super_L || k === Qt.Key_Super_R) {
                                        root.formModSuper = true
                                        event.accepted = true
                                        return
                                    }
                                    if (k === Qt.Key_Control) {
                                        root.formModCtrl = true
                                        event.accepted = true
                                        return
                                    }
                                    if (k === Qt.Key_Alt || k === Qt.Key_AltGr) {
                                        root.formModAlt = true
                                        event.accepted = true
                                        return
                                    }
                                    if (k === Qt.Key_Shift) {
                                        root.formModShift = true
                                        event.accepted = true
                                        return
                                    }

                                    // 2. Identify the key
                                    var keyName = ""
                                    if (k === Qt.Key_Return || k === Qt.Key_Enter) keyName = "Return"
                                    else if (k === Qt.Key_Space) keyName = "Space"
                                    else if (k === Qt.Key_Tab) keyName = "Tab"
                                    else if (k === Qt.Key_Escape) keyName = "Escape"
                                    else if (k === Qt.Key_Backspace) keyName = "BackSpace"
                                    else if (k === Qt.Key_Delete) keyName = "Delete"
                                    else if (k === Qt.Key_Left) keyName = "left"
                                    else if (k === Qt.Key_Right) keyName = "right"
                                    else if (k === Qt.Key_Up) keyName = "up"
                                    else if (k === Qt.Key_Down) keyName = "down"
                                    else if (k === Qt.Key_Backslash) keyName = "backslash"
                                    else if (k === Qt.Key_Comma) keyName = "comma"
                                    else if (k === Qt.Key_Period) keyName = "period"
                                    else if (k === Qt.Key_Slash) keyName = "slash"
                                    else if (k === Qt.Key_Minus) keyName = "minus"
                                    else if (k === Qt.Key_Equal) keyName = "equal"
                                    else if (k === Qt.Key_Print) keyName = "print"
                                    else if (k === Qt.Key_Home) keyName = "home"
                                    else if (k === Qt.Key_End) keyName = "end"
                                    else if (k >= Qt.Key_F1 && k <= Qt.Key_F12) keyName = "F" + (k - Qt.Key_F1 + 1)
                                    else if (event.text && event.text.length > 0) {
                                        var ch = event.text.toUpperCase()
                                        if (ch >= " " && ch <= "~") keyName = ch
                                    }

                                    if (keyName.length > 0) {
                                        root.formKey = keyName
                                        isRecording = false
                                        event.accepted = true
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    spacing: 12

                                    Text {
                                        text: keyRecordBox.isRecording ? "󰑮" : "󰌌"
                                        font.pixelSize: 16
                                        color: keyRecordBox.isRecording ? Theme.accent : Theme.alpha(Theme.foreground, 0.70)
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: keyRecordBox.isRecording
                                                ? "Recording combination... Hold modifiers & press key (e.g. Super+Shift+H)"
                                                : (root.getDisplayCombo() ? ("Assigned Combination: " + root.getDisplayCombo()) : "Click 'Record Shortcut' or choose modifiers below")
                                            color: keyRecordBox.isRecording ? Theme.accent : Theme.foreground
                                            font.family: "Outfit"
                                            font.pixelSize: 11
                                            font.weight: keyRecordBox.isRecording ? Font.DemiBold : Font.Normal
                                        }

                                        Text {
                                            text: keyRecordBox.isRecording
                                                ? "Release or press key to lock in"
                                                : "Supports any combination of SUPER, CTRL, ALT, and SHIFT"
                                            color: Theme.alpha(Theme.foreground, 0.50)
                                            font.family: "Outfit"
                                            font.pixelSize: 10
                                        }
                                    }

                                    Rectangle {
                                        Layout.preferredHeight: 28
                                        Layout.preferredWidth: recordBtnTxt.implicitWidth + 18
                                        radius: 6
                                        color: keyRecordBox.isRecording ? Theme.error : Theme.alpha(Theme.accent, 0.20)
                                        border.width: 1
                                        border.color: keyRecordBox.isRecording ? Theme.error : Theme.accent

                                        Text {
                                            id: recordBtnTxt
                                            anchors.centerIn: parent
                                            text: keyRecordBox.isRecording ? "Stop Recording" : "● Record Shortcut"
                                            color: keyRecordBox.isRecording ? Theme.on_primary : Theme.accent
                                            font.family: "Outfit"
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                keyRecordBox.isRecording = !keyRecordBox.isRecording
                                                if (keyRecordBox.isRecording) {
                                                    keyRecordBox.forceActiveFocus()
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Modifiers Manual Toggles Row
                            RowLayout {
                                spacing: 8
                                Text {
                                    text: "Modifiers:"
                                    color: Theme.alpha(Theme.foreground, 0.70)
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    Layout.preferredWidth: 64
                                }

                                // SUPER
                                Rectangle {
                                    Layout.preferredHeight: 30
                                    Layout.preferredWidth: 70
                                    radius: 7
                                    color: root.formModSuper ? Theme.accent : Theme.alpha(Theme.surface, 0.70)
                                    border.width: 1
                                    border.color: root.formModSuper ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)
                                    Text {
                                        anchors.centerIn: parent
                                        text: "SUPER"
                                        color: root.formModSuper ? Theme.on_primary : Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.formModSuper = !root.formModSuper
                                    }
                                }

                                // CTRL
                                Rectangle {
                                    Layout.preferredHeight: 30
                                    Layout.preferredWidth: 64
                                    radius: 7
                                    color: root.formModCtrl ? Theme.accent : Theme.alpha(Theme.surface, 0.70)
                                    border.width: 1
                                    border.color: root.formModCtrl ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)
                                    Text {
                                        anchors.centerIn: parent
                                        text: "CTRL"
                                        color: root.formModCtrl ? Theme.on_primary : Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.formModCtrl = !root.formModCtrl
                                    }
                                }

                                // ALT
                                Rectangle {
                                    Layout.preferredHeight: 30
                                    Layout.preferredWidth: 64
                                    radius: 7
                                    color: root.formModAlt ? Theme.accent : Theme.alpha(Theme.surface, 0.70)
                                    border.width: 1
                                    border.color: root.formModAlt ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)
                                    Text {
                                        anchors.centerIn: parent
                                        text: "ALT"
                                        color: root.formModAlt ? Theme.on_primary : Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.formModAlt = !root.formModAlt
                                    }
                                }

                                // SHIFT
                                Rectangle {
                                    Layout.preferredHeight: 30
                                    Layout.preferredWidth: 64
                                    radius: 7
                                    color: root.formModShift ? Theme.accent : Theme.alpha(Theme.surface, 0.70)
                                    border.width: 1
                                    border.color: root.formModShift ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)
                                    Text {
                                        anchors.centerIn: parent
                                        text: "SHIFT"
                                        color: root.formModShift ? Theme.on_primary : Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.formModShift = !root.formModShift
                                    }
                                }
                            }

                            // Key Input Row
                            RowLayout {
                                spacing: 8
                                Text {
                                    text: "Key:"
                                    color: Theme.alpha(Theme.foreground, 0.70)
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    Layout.preferredWidth: 64
                                }

                                Rectangle {
                                    Layout.preferredWidth: 160
                                    Layout.preferredHeight: 34
                                    radius: 8
                                    color: Theme.alpha(Theme.surface, 0.80)
                                    border.width: 1
                                    border.color: keyField.activeFocus ? Theme.accent : Theme.alpha(Theme.foreground, 0.20)

                                    TextInput {
                                        id: keyField
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        text: root.formKey
                                        color: Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        onTextChanged: root.formKey = text
                                        clip: true

                                        Text {
                                            anchors.fill: parent
                                            text: "e.g. Return, Q, H, Space..."
                                            color: Theme.alpha(Theme.foreground, 0.35)
                                            font.family: "Outfit"
                                            font.pixelSize: 11
                                            visible: !parent.text && !parent.activeFocus
                                        }
                                    }
                                }

                                // Quick Key Chips
                                Flickable {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 34
                                    contentWidth: keyPresetsRow.implicitWidth
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds

                                    Row {
                                        id: keyPresetsRow
                                        spacing: 6
                                        anchors.verticalCenter: parent.verticalCenter

                                        Repeater {
                                            model: ["Return", "Space", "Tab", "Escape", "H", "W", "Q", "E", "R", "T", "B", "C", "V", "D", "F", "1", "2", "3", "F11"]

                                            Rectangle {
                                                height: 26
                                                width: pKeyTxt.implicitWidth + 14
                                                radius: 6
                                                color: root.formKey === modelData ? Theme.alpha(Theme.accent, 0.30) : Theme.alpha(Theme.surface, 0.50)
                                                border.width: 1
                                                border.color: root.formKey === modelData ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)

                                                Text {
                                                    id: pKeyTxt
                                                    anchors.centerIn: parent
                                                    text: modelData
                                                    color: root.formKey === modelData ? Theme.accent : Theme.foreground
                                                    font.family: "Outfit"
                                                    font.pixelSize: 10
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.formKey = modelData
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Conflict Warning Banner
                            Rectangle {
                                visible: root.conflictWarning.length > 0
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                radius: 8
                                color: Theme.alpha(Theme.error, 0.14)
                                border.width: 1
                                border.color: Theme.alpha(Theme.error, 0.50)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8
                                    Image {
                                        Layout.preferredWidth: 14
                                        Layout.preferredHeight: 14
                                        source: root.warnSvg
                                        sourceSize: Qt.size(28, 28)
                                    }
                                    Text {
                                        text: root.conflictWarning
                                        color: Theme.error
                                        font.family: "Outfit"
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Theme.alpha(Theme.foreground, 0.08)
                        }

                        // 2. ACTION TYPE SELECTION
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "2. Action Type"
                                color: Theme.accent
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            RowLayout {
                                spacing: 8
                                Layout.fillWidth: true

                                Repeater {
                                    model: [
                                        { id: "exec", label: "Launch Command" },
                                        { id: "window", label: "Window Action" },
                                        { id: "workspace", label: "Workspace" },
                                        { id: "custom", label: "Custom Lua" }
                                    ]

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 32
                                        radius: 8
                                        color: root.formActionType === modelData.id ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.60)
                                        border.width: 1
                                        border.color: root.formActionType === modelData.id ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            color: root.formActionType === modelData.id ? Theme.accent : Theme.foreground
                                            font.family: "Outfit"
                                            font.pixelSize: 11
                                            font.weight: root.formActionType === modelData.id ? Font.DemiBold : Font.Normal
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.formActionType = modelData.id
                                        }
                                    }
                                }
                            }
                        }

                        // 3. ACTION DETAILS FORM
                        // Mode A: Exec Command
                        ColumnLayout {
                            visible: root.formActionType === "exec"
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "Command / Application to Run:"
                                color: Theme.alpha(Theme.foreground, 0.70)
                                font.family: "Outfit"
                                font.pixelSize: 11
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                radius: 8
                                color: Theme.alpha(Theme.surface, 0.80)
                                border.width: 1
                                border.color: cmdField.activeFocus ? Theme.accent : Theme.alpha(Theme.foreground, 0.20)

                                TextInput {
                                    id: cmdField
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    text: root.formCommand
                                    color: Theme.foreground
                                    font.family: "monospace"
                                    font.pixelSize: 11
                                    onTextChanged: root.formCommand = text
                                    clip: true

                                    Text {
                                        anchors.fill: parent
                                        text: "e.g. qs-keybinds.sh, kitty, brave, dolphin, pkill waybar..."
                                        color: Theme.alpha(Theme.foreground, 0.35)
                                        font.family: "monospace"
                                        font.pixelSize: 11
                                        visible: !parent.text && !parent.activeFocus
                                    }
                                }
                            }

                            // Quick App Preset Chips
                            RowLayout {
                                spacing: 6
                                Text {
                                    text: "Presets:"
                                    color: Theme.alpha(Theme.foreground, 0.50)
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                }

                                Flickable {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                    contentWidth: presetRow.implicitWidth
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds

                                    Row {
                                        id: presetRow
                                        spacing: 6
                                        anchors.verticalCenter: parent.verticalCenter

                                        Repeater {
                                            model: [
                                                { label: "Shortcuts Cheatsheet", cmd: "~/.hyprconf/hypr/scripts/sh/qs-keybinds.sh" },
                                                { label: "Wallpaper Selector", cmd: "~/.hyprconf/hypr/scripts/sh/qs-wallpaper.sh" },
                                                { label: "Screenshot Studio", cmd: "~/.hyprconf/hypr/scripts/sh/qs-screenshot.sh" },
                                                { label: "Clipboard History", cmd: "~/.hyprconf/hypr/scripts/sh/qs-clipboard.sh" },
                                                { label: "Emoji Studio", cmd: "~/.hyprconf/hypr/scripts/sh/qs-emoji.sh" },
                                                { label: "Power Menu", cmd: "~/.hyprconf/hypr/scripts/sh/qs-power.sh" },
                                                { label: "App Launcher", cmd: "~/.hyprconf/hypr/scripts/sh/qs-launcher.sh" },
                                                { label: "Settings Studio", cmd: "~/.hyprconf/hypr/scripts/sh/qs-settings.sh" },
                                                { label: "Kitty Terminal", cmd: "kitty" },
                                                { label: "Dolphin Files", cmd: "dolphin" },
                                                { label: "Default Browser", cmd: "~/.hyprconf/hypr/scripts/sh/browser.sh op" },
                                                { label: "VS Code", cmd: "code" }
                                            ]

                                            Rectangle {
                                                height: 24
                                                width: pCmdTxt.implicitWidth + 14
                                                radius: 6
                                                color: Theme.alpha(Theme.surface, 0.50)
                                                border.width: 1
                                                border.color: Theme.alpha(Theme.foreground, 0.12)

                                                Text {
                                                    id: pCmdTxt
                                                    anchors.centerIn: parent
                                                    text: modelData.label
                                                    color: Theme.foreground
                                                    font.family: "Outfit"
                                                    font.pixelSize: 10
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.formCommand = modelData.cmd
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Mode B: Window Action
                        ColumnLayout {
                            visible: root.formActionType === "window"
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "Select Window Dispatcher:"
                                color: Theme.alpha(Theme.foreground, 0.70)
                                font.family: "Outfit"
                                font.pixelSize: 11
                            }

                            RowLayout {
                                spacing: 8
                                Layout.fillWidth: true

                                Repeater {
                                    model: [
                                        { id: "close", label: "Close Window" },
                                        { id: "float", label: "Toggle Float" },
                                        { id: "fullscreen", label: "Toggle Fullscreen" },
                                        { id: "pseudo", label: "Toggle Pseudo" },
                                        { id: "cycle", label: "Cycle Next" }
                                    ]

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 32
                                        radius: 8
                                        color: root.formWindowSubAction === modelData.id ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surface, 0.60)
                                        border.width: 1
                                        border.color: root.formWindowSubAction === modelData.id ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            color: root.formWindowSubAction === modelData.id ? Theme.accent : Theme.foreground
                                            font.family: "Outfit"
                                            font.pixelSize: 10
                                            font.weight: root.formWindowSubAction === modelData.id ? Font.DemiBold : Font.Normal
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.formWindowSubAction = modelData.id
                                        }
                                    }
                                }
                            }
                        }

                        // Mode C: Workspace Action
                        ColumnLayout {
                            visible: root.formActionType === "workspace"
                            Layout.fillWidth: true
                            spacing: 8

                            RowLayout {
                                spacing: 12
                                Layout.fillWidth: true

                                Text {
                                    text: "Action:"
                                    color: Theme.alpha(Theme.foreground, 0.70)
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                }

                                Rectangle {
                                    Layout.preferredHeight: 30
                                    Layout.preferredWidth: 140
                                    radius: 7
                                    color: root.formWorkspaceSubAction === "switch" ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surface, 0.60)
                                    border.width: 1
                                    border.color: root.formWorkspaceSubAction === "switch" ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Switch Workspace"
                                        color: root.formWorkspaceSubAction === "switch" ? Theme.accent : Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 11
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.formWorkspaceSubAction = "switch"
                                    }
                                }

                                Rectangle {
                                    Layout.preferredHeight: 30
                                    Layout.preferredWidth: 150
                                    radius: 7
                                    color: root.formWorkspaceSubAction === "move" ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surface, 0.60)
                                    border.width: 1
                                    border.color: root.formWorkspaceSubAction === "move" ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Move to Workspace"
                                        color: root.formWorkspaceSubAction === "move" ? Theme.accent : Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 11
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.formWorkspaceSubAction = "move"
                                    }
                                }
                            }

                            // Workspace Number Selector (1-10)
                            RowLayout {
                                spacing: 6
                                Text {
                                    text: "Target Workspace:"
                                    color: Theme.alpha(Theme.foreground, 0.70)
                                    font.family: "Outfit"
                                    font.pixelSize: 11
                                    Layout.preferredWidth: 120
                                }

                                Repeater {
                                    model: 10

                                    Rectangle {
                                        readonly property int wsNum: index + 1
                                        Layout.preferredHeight: 28
                                        Layout.preferredWidth: 28
                                        radius: 6
                                        color: root.formWorkspaceNum === wsNum ? Theme.accent : Theme.alpha(Theme.surface, 0.60)
                                        border.width: 1
                                        border.color: root.formWorkspaceNum === wsNum ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)

                                        Text {
                                            anchors.centerIn: parent
                                            text: parent.wsNum
                                            color: root.formWorkspaceNum === parent.wsNum ? Theme.on_primary : Theme.foreground
                                            font.family: "Outfit"
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.formWorkspaceNum = parent.wsNum
                                        }
                                    }
                                }
                            }
                        }

                        // Mode D: Custom Lua
                        ColumnLayout {
                            visible: root.formActionType === "custom"
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "Raw Lua Dispatcher / Expression:"
                                color: Theme.alpha(Theme.foreground, 0.70)
                                font.family: "Outfit"
                                font.pixelSize: 11
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 60
                                radius: 8
                                color: Theme.alpha(Theme.surface, 0.80)
                                border.width: 1
                                border.color: luaField.activeFocus ? Theme.accent : Theme.alpha(Theme.foreground, 0.20)

                                TextInput {
                                    id: luaField
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    text: root.formCustomLua
                                    color: Theme.foreground
                                    font.family: "monospace"
                                    font.pixelSize: 11
                                    onTextChanged: root.formCustomLua = text
                                    clip: true

                                    Text {
                                        anchors.fill: parent
                                        text: "e.g. hl.dsp.exec_cmd('my_script.sh') or function() ... end"
                                        color: Theme.alpha(Theme.foreground, 0.35)
                                        font.family: "monospace"
                                        font.pixelSize: 11
                                        visible: !parent.text && !parent.activeFocus
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Theme.alpha(Theme.foreground, 0.08)
                        }

                        // 4. LIVE LUA STATEMENT PREVIEW
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "3. Generated Lua Statement (writes to keybinds.lua):"
                                color: Theme.alpha(Theme.foreground, 0.70)
                                font.family: "Outfit"
                                font.pixelSize: 11
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                radius: 8
                                color: Theme.alpha(Theme.surface, 0.95)
                                border.width: 1
                                border.color: Theme.alpha(Theme.accent, 0.30)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    Text {
                                        text: root.generateFullLuaStatement()
                                        color: Theme.accent
                                        font.family: "monospace"
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }
                }

                // Modal Footer Buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: 84
                        Layout.preferredHeight: 34
                        radius: 8
                        color: cancelModalMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.50)
                        border.width: 1
                        border.color: Theme.alpha(Theme.foreground, 0.20)

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: cancelModalMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                keyRecordBox.isRecording = false
                                root.showModal = false
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 34
                        radius: 8
                        color: saveModalMouse.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
                        opacity: root.formKey.trim().length > 0 ? 1.0 : 0.5

                        Text {
                            anchors.centerIn: parent
                            text: root.isEditing ? "Save Edit" : "Add Keybind"
                            color: Theme.on_primary
                            font.family: "Outfit"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: saveModalMouse
                            anchors.fill: parent
                            enabled: root.formKey.trim().length > 0
                            hoverEnabled: true
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.saveModal()
                        }
                    }
                }
            }
        }
    }
}
