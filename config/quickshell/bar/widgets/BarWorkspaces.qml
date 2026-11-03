import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
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

    function getAppIconSource(cls, title) {
        var c = (cls || "").toLowerCase()
        if (c.indexOf("brave") !== -1) {
            return "file:///home/shell-ninja/.local/share/icons/kora/apps/scalable/brave-desktop.svg"
        }
        return ""
    }

    function getAppGlyph(cls, title) {
        var c = (cls || "").toLowerCase()
        var t = (title || "").toLowerCase()
        if (c.indexOf("kitty") !== -1 || c.indexOf("alacritty") !== -1 || c.indexOf("foot") !== -1 || c.indexOf("terminal") !== -1) return "󰞷"
        if (c.indexOf("nvim") !== -1 || c.indexOf("code") !== -1 || c.indexOf("vim") !== -1 || c.indexOf("sublime") !== -1 || c.indexOf("antigravity") !== -1) return "󰅩"
        if (c.indexOf("brave") !== -1) return "󰖟"
        if (c.indexOf("firefox") !== -1 || c.indexOf("zen") !== -1) return "󰈹"
        if (c.indexOf("chrome") !== -1 || c.indexOf("chromium") !== -1) return ""
        if (c.indexOf("edge") !== -1) return "󰇩"
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
                    width: Math.max(28, 28 + visibleAppCount * 19)

                    Behavior on width {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: (slotItem.visibleAppCount > 0) ? 6 : 0
                        anchors.rightMargin: (slotItem.visibleAppCount > 0) ? 6 : 0
                        spacing: 5

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
                            delegate: Item {
                                required property int index
                                readonly property var appWin: slotItem.winList[index]
                                readonly property string iconPath: rootPill.getAppIconSource(appWin ? appWin.class : "", appWin ? appWin.title : "")
                                readonly property string glyphStr: rootPill.getAppGlyph(appWin ? appWin.class : "", appWin ? appWin.title : "")

                                Layout.alignment: Qt.AlignVCenter
                                implicitWidth: 15
                                implicitHeight: 15

                                Image {
                                    anchors.centerIn: parent
                                    width: 15
                                    height: 15
                                    source: parent.iconPath
                                    fillMode: Image.PreserveAspectFit
                                    visible: parent.iconPath.length > 0
                                    asynchronous: true
                                    smooth: true
                                    mipmap: true
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: parent.glyphStr
                                    font.family: "JetBrainsMono Nerd Font, monospace"
                                    font.pixelSize: 14
                                    color: slotItem.isActive ? Theme.background : Theme.accent
                                    opacity: slotItem.isActive ? 0.95 : 0.85
                                    visible: parent.iconPath.length === 0
                                }

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
        Item {
            id: wsTooltip
            readonly property var winList: rootPill.getWsWindows(rootPill.hoveredWsId)
            visible: rootPill.hoveredWsId > 0 && winList.length > 0
            z: 999

            readonly property bool isGlass: (typeof bar !== "undefined" && bar && bar.capsuleStyle === "glass")
            readonly property int fL: isGlass ? 10 : 0
            readonly property int fR: isGlass ? 10 : 0
            readonly property int br: 10
            readonly property int bodyWidth: Math.max(160, Math.min(280, tooltipCol.implicitWidth + 24))
            readonly property int w: bodyWidth
            readonly property int h: height
            readonly property color surface: (typeof bar !== "undefined" && bar) ? Theme.alpha(Theme.surface, bar.barOpacity) : Theme.alpha(Theme.surface, 0.90)
            readonly property color strokeColor: Theme.alpha(Theme.accent, 0.35)

            x: {
                var item = (rootPill.hoveredWsId >= 1 && rootPill.hoveredWsId <= rootPill.maxSlots && slotsRepeater.count >= rootPill.hoveredWsId)
                    ? slotsRepeater.itemAt(rootPill.hoveredWsId - 1)
                    : null
                if (!item) return 0
                var idealBodyX = item.x + item.width / 2 - bodyWidth / 2
                try {
                    var screenClusterX = wsCluster.mapToItem(null, 0, 0).x
                    var minScreenX = isGlass ? (bar.frameThickness + 4) : 8
                    var maxScreenX = isGlass ? (bar.width - bar.frameThickness - 4) : (bar.width - 8)
                    var clampedBodyX = Math.max(minScreenX - screenClusterX, Math.min(maxScreenX - bodyWidth - screenClusterX, idealBodyX))
                    return clampedBodyX - fL
                } catch(e) {
                    return idealBodyX - fL
                }
            }
            y: isGlass ? Math.round((bar.barH + wsCluster.height) / 2 - 1) : (parent.height + 6)
            width: bodyWidth + fL + fR
            height: tooltipCol.implicitHeight + 16

            // Glass Attached Monolithic Shape
            Shape {
                anchors.fill: parent
                layer.enabled: true
                layer.samples: 4
                visible: wsTooltip.isGlass

                // 1. Fill Path (Closed across top)
                ShapePath {
                    fillColor: wsTooltip.surface
                    strokeColor: "transparent"
                    strokeWidth: 0

                    startX: 0
                    startY: 0

                    PathArc {
                        x: wsTooltip.fL
                        y: wsTooltip.fL
                        radiusX: Math.max(1, wsTooltip.fL)
                        radiusY: Math.max(1, wsTooltip.fL)
                        direction: PathArc.Clockwise
                    }
                    PathLine { x: wsTooltip.fL; y: Math.max(wsTooltip.fL, wsTooltip.h - wsTooltip.br) }
                    PathArc {
                        x: wsTooltip.fL + wsTooltip.br
                        y: wsTooltip.h
                        radiusX: wsTooltip.br
                        radiusY: wsTooltip.br
                        direction: PathArc.Counterclockwise
                    }
                    PathLine { x: wsTooltip.fL + wsTooltip.w - wsTooltip.br; y: wsTooltip.h }
                    PathArc {
                        x: wsTooltip.fL + wsTooltip.w
                        y: Math.max(wsTooltip.fL, wsTooltip.h - wsTooltip.br)
                        radiusX: wsTooltip.br
                        radiusY: wsTooltip.br
                        direction: PathArc.Counterclockwise
                    }
                    PathLine { x: wsTooltip.fL + wsTooltip.w; y: wsTooltip.fR }
                    PathArc {
                        x: wsTooltip.fL + wsTooltip.w + wsTooltip.fR
                        y: 0
                        radiusX: Math.max(1, wsTooltip.fR)
                        radiusY: Math.max(1, wsTooltip.fR)
                        direction: PathArc.Clockwise
                    }
                    PathLine { x: 0; y: 0 }
                }

                // 2. Stroke Path (Open across top — zero-seam glass attachment)
                ShapePath {
                    fillColor: "transparent"
                    strokeColor: wsTooltip.strokeColor
                    strokeWidth: 1

                    startX: 0
                    startY: 0

                    PathArc {
                        x: wsTooltip.fL
                        y: wsTooltip.fL
                        radiusX: Math.max(1, wsTooltip.fL)
                        radiusY: Math.max(1, wsTooltip.fL)
                        direction: PathArc.Clockwise
                    }
                    PathLine { x: wsTooltip.fL; y: Math.max(wsTooltip.fL, wsTooltip.h - wsTooltip.br) }
                    PathArc {
                        x: wsTooltip.fL + wsTooltip.br
                        y: wsTooltip.h
                        radiusX: wsTooltip.br
                        radiusY: wsTooltip.br
                        direction: PathArc.Counterclockwise
                    }
                    PathLine { x: wsTooltip.fL + wsTooltip.w - wsTooltip.br; y: wsTooltip.h }
                    PathArc {
                        x: wsTooltip.fL + wsTooltip.w
                        y: Math.max(wsTooltip.fL, wsTooltip.h - wsTooltip.br)
                        radiusX: wsTooltip.br
                        radiusY: wsTooltip.br
                        direction: PathArc.Counterclockwise
                    }
                    PathLine { x: wsTooltip.fL + wsTooltip.w; y: wsTooltip.fR }
                    PathArc {
                        x: wsTooltip.fL + wsTooltip.w + wsTooltip.fR
                        y: 0
                        radiusX: Math.max(1, wsTooltip.fR)
                        radiusY: Math.max(1, wsTooltip.fR)
                        direction: PathArc.Clockwise
                    }
                }
            }

            // Floating Card Background (Islands style)
            Rectangle {
                anchors.fill: parent
                visible: !wsTooltip.isGlass
                radius: wsTooltip.br
                color: wsTooltip.surface
                border.width: 1
                border.color: wsTooltip.strokeColor
            }

            ColumnLayout {
                id: tooltipCol
                x: wsTooltip.fL + 8
                y: 8
                width: wsTooltip.bodyWidth - 16
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

                            Item {
                                Layout.alignment: Qt.AlignVCenter
                                implicitWidth: 16
                                implicitHeight: 16
                                readonly property string tipIcon: rootPill.getAppIconSource(modelData.class, modelData.title)

                                Image {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    source: parent.tipIcon
                                    fillMode: Image.PreserveAspectFit
                                    visible: parent.tipIcon.length > 0
                                    asynchronous: true
                                    smooth: true
                                    mipmap: true
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: rootPill.getAppGlyph(modelData.class, modelData.title)
                                    font.family: "JetBrainsMono Nerd Font, monospace"
                                    font.pixelSize: 14
                                    color: Theme.accent
                                    visible: parent.tipIcon.length === 0
                                }
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
