import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import ".."

Pill {
    id: rootPill
    hPad: 4
    clickable: false

    readonly property int activeWs: (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 0) ? Hyprland.focusedWorkspace.id : 1
    property var occupiedWorkspaces: []
    property var windowsByWs: ({})
    property int hoveredWsId: 0

    function getWsWindows(wid) {
        return (rootPill.windowsByWs && rootPill.windowsByWs[wid]) ? rootPill.windowsByWs[wid] : []
    }

    readonly property var settings: (typeof bar !== "undefined" && bar && bar.widgetSettings && bar.widgetSettings.workspaces) ? bar.widgetSettings.workspaces : ({})
    readonly property string wsStyle: (settings.style !== undefined) ? settings.style : ((typeof bar !== "undefined" && bar && bar.workspaceStyle) ? bar.workspaceStyle : "kanji")
    readonly property int maxSlots: (settings.count !== undefined) ? Math.max(3, Math.min(10, parseInt(settings.count, 10))) : 5
    readonly property bool showAppIcons: (settings.show_app_icons !== undefined) ? settings.show_app_icons : true

    readonly property var wsLabels: {
        if (wsStyle === "number") return ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
        if (wsStyle === "glyph") return ["✦", "◈", "◆", "❖", "⬡", "▲", "●", "★", "■", "⬢"]
        if (wsStyle === "dot") return ["•", "•", "•", "•", "•", "•", "•", "•", "•", "•"]
        return ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
    }

    function switchWorkspace(id) {
        Quickshell.execDetached(["hyprctl", "eval", "hl.dispatch(hl.dsp.focus({ workspace = " + id + " }))"])
    }

    function focusWindow(addr) {
        if (!addr) return
        Quickshell.execDetached(["hyprctl", "eval", "hl.dispatch(hl.dsp.focus({ window = 'address:" + addr + "' }))"])
    }

    function getAppGlyph(cls, title) {
        var c = (cls || "").toLowerCase()
        var t = (title || "").toLowerCase()
        if (c.indexOf("kitty") !== -1 || c.indexOf("alacritty") !== -1 || c.indexOf("foot") !== -1 || c.indexOf("terminal") !== -1) return "󰞷"
        if (c.indexOf("nvim") !== -1 || c.indexOf("code") !== -1 || c.indexOf("vim") !== -1 || c.indexOf("sublime") !== -1 || c.indexOf("antigravity") !== -1) return "󰅩"
        if (c.indexOf("brave") !== -1 || c.indexOf("firefox") !== -1 || c.indexOf("chrome") !== -1 || c.indexOf("chromium") !== -1 || c.indexOf("edge") !== -1 || c.indexOf("zen") !== -1) return "󰈹"
        if (c.indexOf("thunar") !== -1 || c.indexOf("dolphin") !== -1 || c.indexOf("nautilus") !== -1 || c.indexOf("yazi") !== -1 || c.indexOf("files") !== -1) return "󰉋"
        if (c.indexOf("discord") !== -1 || c.indexOf("telegram") !== -1 || c.indexOf("slack") !== -1 || c.indexOf("signal") !== -1 || c.indexOf("wechat") !== -1) return "󰭹"
        if (c.indexOf("spotify") !== -1 || c.indexOf("music") !== -1 || c.indexOf("mpd") !== -1 || c.indexOf("vlc") !== -1) return "󰝚"
        if (c.indexOf("gimp") !== -1 || c.indexOf("inkscape") !== -1 || c.indexOf("krita") !== -1 || c.indexOf("figma") !== -1 || c.indexOf("blender") !== -1) return "󰽉"
        if (c.indexOf("steam") !== -1 || c.indexOf("heroic") !== -1 || c.indexOf("lutris") !== -1 || c.indexOf("game") !== -1) return "󰊴"
        if (c.indexOf("settings") !== -1 || c.indexOf("control") !== -1 || c.indexOf("pavucontrol") !== -1) return "󰒓"
        return "󰍹"
    }

    // Dynamic occupied workspace & window detection via hyprctl clients
    Process {
        id: occProc
        command: ["hyprctl", "clients", "-j"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var parsed = JSON.parse(text.trim())
                    var occ = []
                    var byWs = {}
                    for (var i = 0; i < parsed.length; i++) {
                        var c = parsed[i]
                        if (!c || !c.workspace || c.workspace.id <= 0) continue
                        var wid = c.workspace.id
                        if (occ.indexOf(wid) === -1) occ.push(wid)
                        if (!byWs[wid]) byWs[wid] = []
                        byWs[wid].push({
                            title: c.title || c.initialTitle || "Window",
                            class: c.class || c.initialClass || "app",
                            pid: c.pid,
                            address: c.address
                        })
                    }
                    rootPill.occupiedWorkspaces = occ
                    rootPill.windowsByWs = byWs
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 6000
        repeat: true
        running: true
        onTriggered: if (!occProc.running) occProc.running = true
    }

    Connections {
        target: Hyprland

        function onFocusedWorkspaceChanged() {
            if (!occProc.running) occProc.running = true
        }

        function onRawEvent(event) {
            if (event.name === "workspace" || event.name === "workspacev2" ||
                event.name === "openwindow" || event.name === "closewindow" ||
                event.name === "movewindow" || event.name === "createworkspace" ||
                event.name === "destroyworkspace") {
                if (!occProc.running) occProc.running = true
            }
        }
    }

    Item {
        id: wsCluster
        implicitWidth: slotsRow.implicitWidth
        implicitHeight: rootPill.pillHeight

        // Sliding Glowing Medallion for Active Workspace
        Rectangle {
            id: activeMedallion
            readonly property Item targetItem: (rootPill.activeWs >= 1 && rootPill.activeWs <= rootPill.maxSlots && slotsRepeater.count >= rootPill.activeWs)
                ? slotsRepeater.itemAt(rootPill.activeWs - 1)
                : null

            x: targetItem ? targetItem.x : 0
            width: targetItem ? targetItem.width : 26
            height: parent.height - 4
            radius: height / 2
            color: Theme.accent
            y: 2
            z: 0
            visible: rootPill.activeWs >= 1 && rootPill.activeWs <= rootPill.maxSlots

            Behavior on x {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on width {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            // Outer subtle accent glow
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 4
                height: parent.height + 4
                radius: width / 2
                color: Theme.alpha(Theme.accent, 0.22)
                z: -1
            }
        }

        // Workspace Slots
        Row {
            id: slotsRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            z: 1

            Repeater {
                id: slotsRepeater
                model: rootPill.maxSlots
                delegate: Item {
                    id: slotItem
                    required property int index
                    readonly property int wsId: index + 1
                    readonly property bool isActive: (rootPill.activeWs === wsId)
                    readonly property var winList: rootPill.getWsWindows(wsId)
                    readonly property bool isOccupied: (winList && winList.length > 0)
                    readonly property string labelText: (index >= 0 && index < rootPill.wsLabels.length) ? rootPill.wsLabels[index] : wsId.toString()
                    readonly property int visibleAppCount: (rootPill.showAppIcons && winList) ? Math.min(2, winList.length) : 0

                    height: wsCluster.height
                    width: Math.max(26, 26 + visibleAppCount * 14)

                    Behavior on width {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: (slotItem.visibleAppCount > 0) ? 6 : 0
                        anchors.rightMargin: (slotItem.visibleAppCount > 0) ? 6 : 0
                        spacing: 4

                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillWidth: (slotItem.visibleAppCount === 0)
                            horizontalAlignment: (slotItem.visibleAppCount === 0) ? Text.AlignHCenter : Text.AlignLeft
                            text: slotItem.labelText
                            font.family: "Outfit"
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            color: slotItem.isActive ? Theme.background : (slotItem.isOccupied ? Theme.secondary : Theme.foreground)
                            opacity: slotItem.isActive ? 1.0 : (slotMouse.containsMouse ? 1.0 : (slotItem.isOccupied ? 0.90 : 0.45))
                            scale: slotMouse.containsMouse ? 1.15 : 1.0

                            Behavior on opacity { NumberAnimation { duration: 160 } }
                            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                            Behavior on color { ColorAnimation { duration: 160 } }
                        }

                        // Mini App Icons
                        Repeater {
                            model: slotItem.visibleAppCount
                            delegate: Text {
                                required property int index
                                readonly property var appWin: slotItem.winList[index]
                                Layout.alignment: Qt.AlignVCenter
                                text: appWin ? rootPill.getAppGlyph(appWin.class, appWin.title) : ""
                                font.family: "JetBrainsMono Nerd Font, monospace"
                                font.pixelSize: 11
                                color: slotItem.isActive ? Theme.background : Theme.accent
                                opacity: slotItem.isActive ? 0.95 : 0.85

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (appWin && appWin.address) {
                                            rootPill.focusWindow(appWin.address)
                                        } else {
                                            rootPill.switchWorkspace(slotItem.wsId)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Occupied micro-dot indicator (if no app icons shown)
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 1
                        width: 3
                        height: 3
                        radius: 1.5
                        color: Theme.secondary
                        visible: slotItem.isOccupied && !slotItem.isActive && slotItem.visibleAppCount === 0
                        opacity: visible ? 0.9 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 160 } }
                    }

                    MouseArea {
                        id: slotMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: rootPill.hoveredWsId = slotItem.wsId
                        onExited: {
                            if (rootPill.hoveredWsId === slotItem.wsId) {
                                rootPill.hoveredWsId = 0
                            }
                        }
                        onClicked: {
                            rootPill.switchWorkspace(slotItem.wsId)
                        }
                    }
                }
            }
        }

        // Rich Hover Tooltip displaying open windows on hovered workspace
        Rectangle {
            id: wsTooltip
            readonly property var winList: rootPill.getWsWindows(rootPill.hoveredWsId)
            visible: rootPill.hoveredWsId > 0 && winList.length > 0
            z: 999
            x: {
                var item = (rootPill.hoveredWsId >= 1 && rootPill.hoveredWsId <= rootPill.maxSlots && slotsRepeater.count >= rootPill.hoveredWsId)
                    ? slotsRepeater.itemAt(rootPill.hoveredWsId - 1)
                    : null
                if (!item) return 0
                return Math.max(-10, Math.min(wsCluster.width - width + 10, item.x + item.width / 2 - width / 2))
            }
            y: parent.height + 8
            width: Math.max(160, Math.min(280, tooltipCol.implicitWidth + 24))
            implicitHeight: tooltipCol.implicitHeight + 16
            radius: 8
            color: Theme.alpha(Theme.surface, 0.96)
            border.width: 1
            border.color: Theme.alpha(Theme.accent, 0.40)

            ColumnLayout {
                id: tooltipCol
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                RowLayout {
                    spacing: 5
                    Rectangle { width: 5; height: 5; radius: 2.5; color: Theme.accent }
                    Text {
                        text: "WORKSPACE " + rootPill.hoveredWsId
                        font.family: "Outfit"; font.bold: true; font.pixelSize: 9
                        color: Theme.accent; font.letterSpacing: 0.6
                    }
                }

                Repeater {
                    model: wsTooltip.winList
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        height: 22
                        radius: 4
                        color: tipMouse.containsMouse ? Theme.alpha(Theme.accent, 0.20) : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6; anchors.rightMargin: 6
                            spacing: 6

                            Text {
                                text: rootPill.getAppGlyph(modelData.class, modelData.title)
                                font.family: "JetBrainsMono Nerd Font, monospace"
                                font.pixelSize: 11
                                color: Theme.accent
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.title || modelData.class
                                font.family: "Outfit"; font.pixelSize: 10
                                color: Theme.foreground
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: tipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.address) {
                                    rootPill.focusWindow(modelData.address)
                                } else {
                                    rootPill.switchWorkspace(rootPill.hoveredWsId)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    WheelHandler {
        onWheel: function(e) {
            var cur = rootPill.activeWs
            var nextWs = e.angleDelta.y < 0 ? Math.min(rootPill.maxSlots, cur + 1) : Math.max(1, cur - 1)
            if (nextWs !== cur) {
                rootPill.switchWorkspace(nextWs)
            }
        }
    }
}
