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
    readonly property var wsLabels: {
        if (wsStyle === "number") return ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
        if (wsStyle === "glyph") return ["✦", "◈", "◆", "❖", "⬡", "▲", "●", "★", "■", "⬢"]
        if (wsStyle === "dot") return ["•", "•", "•", "•", "•", "•", "•", "•", "•", "•"]
        return ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
    }

    function switchWorkspace(id) {
        Quickshell.execDetached(["hyprctl", "eval", "hl.dispatch(hl.dsp.focus({ workspace = " + id + " }))"])
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
                            pid: c.pid
                        })
                    }
                    rootPill.occupiedWorkspaces = occ
                    rootPill.windowsByWs = byWs
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 8000
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
        implicitWidth: rootPill.maxSlots * 26 + (rootPill.maxSlots - 1) * 4
        implicitHeight: rootPill.pillHeight

        // Sliding Glowing Medallion for Active Workspace
        Rectangle {
            id: activeMedallion
            readonly property int targetIndex: Math.max(0, Math.min(rootPill.maxSlots - 1, rootPill.activeWs - 1))
            width: 26
            height: parent.height - 4
            radius: height / 2
            color: Theme.accent
            y: 2
            z: 2
            visible: rootPill.activeWs >= 1 && rootPill.activeWs <= rootPill.maxSlots
            x: targetIndex * (26 + 4)

            Behavior on x {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.25
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

            // Contrasting active numeral
            Text {
                anchors.centerIn: parent
                text: (activeMedallion.targetIndex >= 0 && activeMedallion.targetIndex < rootPill.wsLabels.length)
                      ? rootPill.wsLabels[activeMedallion.targetIndex]
                      : rootPill.activeWs.toString()
                font.family: "Outfit"
                font.pixelSize: 13
                font.weight: Font.Bold
                color: Theme.background
            }
        }

        // Workspace Slots
        Repeater {
            model: rootPill.maxSlots
            delegate: Item {
                id: slotItem
                required property int index
                readonly property int wsId: index + 1
                readonly property bool isActive: (rootPill.activeWs === wsId)
                readonly property bool isOccupied: (rootPill.occupiedWorkspaces && rootPill.occupiedWorkspaces.indexOf(wsId) !== -1)
                readonly property string labelText: (index >= 0 && index < rootPill.wsLabels.length) ? rootPill.wsLabels[index] : wsId.toString()

                x: index * (26 + 4)
                width: 26
                height: parent.height
                z: 1

                // Inactive text label
                Text {
                    anchors.centerIn: parent
                    text: slotItem.labelText
                    font.family: "Outfit"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: slotItem.isOccupied ? Theme.secondary : Theme.foreground
                    opacity: slotItem.isActive ? 0.0 : (slotMouse.containsMouse ? 1.0 : (slotItem.isOccupied ? 0.90 : 0.45))
                    scale: slotMouse.containsMouse ? 1.15 : 1.0

                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                    Behavior on color { ColorAnimation { duration: 160 } }
                }

                // Occupied micro-dot indicator
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 1
                    width: 3
                    height: 3
                    radius: 1.5
                    color: Theme.secondary
                    visible: slotItem.isOccupied && !slotItem.isActive
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

        // Rich Hover Tooltip displaying open windows on hovered workspace
        Rectangle {
            id: wsTooltip
            readonly property var winList: rootPill.getWsWindows(rootPill.hoveredWsId)
            visible: rootPill.hoveredWsId > 0 && winList.length > 0
            z: 999
            x: Math.max(-10, Math.min(wsCluster.width - width + 10, (rootPill.hoveredWsId - 1) * 30 - width / 2 + 13))
            y: parent.height + 8
            width: Math.max(140, Math.min(260, tooltipCol.implicitWidth + 20))
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
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            width: 3; height: 3; radius: 1.5
                            color: Theme.alpha(Theme.foreground, 0.40)
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.title || modelData.class
                            font.family: "Outfit"; font.pixelSize: 10
                            color: Theme.foreground
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    WheelHandler {
        onWheel: function(e) {
            var cur = rootPill.activeWs
            var nextWs = e.angleDelta.y < 0 ? Math.min(5, cur + 1) : Math.max(1, cur - 1)
            if (nextWs !== cur) {
                rootPill.switchWorkspace(nextWs)
            }
        }
    }
}
