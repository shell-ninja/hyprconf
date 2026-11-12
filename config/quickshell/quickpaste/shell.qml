import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string statePath: homeDir + "/.local/share/hyprconf/.cache/quickpaste_state.json"
    readonly property string quickpastePy: homeDir + "/.hyprconf/hypr/scripts/py/quickpaste.py"

    property bool openRequested: Quickshell.env("QS_QUICKPASTE_OPEN") === "1"
    property bool pendingOpen: false

    property string screenName: ""
    property real cursorLocalX: 0
    property real cursorLocalY: 0
    property real stateMonWidth: 1920
    property real stateMonHeight: 1080
    property var reservedInsets: [0, 0, 0, 0]
    property string targetClass: ""
    property var clipItems: []
    property int selectedIndex: 0

    function toHexRgb(c) {
        function hexByte(v) {
            var n = Math.max(0, Math.min(255, Math.round(v * 255)))
            var s = n.toString(16)
            return s.length < 2 ? "0" + s : s
        }
        return "#" + hexByte(c.r) + hexByte(c.g) + hexByte(c.b)
    }

    function svgUri(inner, strokeColor) {
        // Qt QSvgRenderer rejects 8-digit #AARRGGBB; emit strict #RRGGBB + stroke-opacity.
        var col = toHexRgb(strokeColor)
        var op = Number(strokeColor.a).toFixed(2)
        var xml = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + col + '" stroke-opacity="' + op + '" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round">' + inner + '</svg>'
        return "data:image/svg+xml;utf8," + encodeURIComponent(xml)
    }

    function iconForKind(kind, accentColor) {
        if (kind === "url") {
            return svgUri('<path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/>', accentColor)
        }
        if (kind === "code") {
            return svgUri('<polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/>', accentColor)
        }
        return svgUri('<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/>', accentColor)
    }

    function applyStateJson(rawText) {
        if (!rawText || rawText.trim().length === 0)
            return false
        try {
            var data = JSON.parse(rawText.trim())
            if (!data || typeof data !== "object")
                return false
            root.screenName = data.screenName || ""
            root.cursorLocalX = Number(data.localX || 0)
            root.cursorLocalY = Number(data.localY || 0)
            root.stateMonWidth = Number(data.monWidth || 1920)
            root.stateMonHeight = Number(data.monHeight || 1080)
            root.reservedInsets = Array.isArray(data.reserved) ? data.reserved : [0, 0, 0, 0]
            root.targetClass = data.targetClass || ""
            root.clipItems = Array.isArray(data.items) ? data.items : []
            root.selectedIndex = 0
            return true
        } catch (e) {
            return false
        }
    }

    function findTargetScreen() {
        var screens = Quickshell.screens
        if (!screens || screens.length === 0)
            return null
        if (root.screenName.length > 0) {
            for (var i = 0; i < screens.length; i++) {
                if (screens[i].name === root.screenName)
                    return screens[i]
            }
        }
        return screens[0]
    }

    function showTooltip() {
        root.pendingOpen = false
        var targetScreen = root.findTargetScreen()
        if (targetScreen && overlay.screen !== targetScreen) {
            overlay.screen = targetScreen
        }
        if (clipList.count > 0) {
            clipList.positionViewAtIndex(0, ListView.Beginning)
        }
        revealAnim.stop()
        cardHost.opacity = 0.0
        cardHost.scale = 0.94
        overlay.visible = true
        revealAnim.restart()
        focusScope.forceActiveFocus()
    }

    function openAtCursor() {
        root.pendingOpen = true
        openFallbackTimer.restart()
        stateFile.reload()
    }

    function closeTooltip() {
        root.pendingOpen = false
        openFallbackTimer.stop()
        revealAnim.stop()
        overlay.visible = false
    }

    function toggleAtCursor() {
        if (overlay.visible) {
            closeTooltip()
        } else {
            openAtCursor()
        }
    }

    function pasteIndex(idx) {
        if (idx < 0 || idx >= root.clipItems.length)
            return
        var entry = root.clipItems[idx]
        if (!entry || !entry.raw)
            return
        closeTooltip()
        Quickshell.execDetached(["python3", root.quickpastePy, "--paste", String(entry.raw)])
    }

    Component.onCompleted: {
        if (root.openRequested) {
            root.openAtCursor()
        }
    }

    FileView {
        id: stateFile
        path: root.statePath
        preload: false
        watchChanges: false
        onLoaded: {
            root.applyStateJson(text())
            if (root.pendingOpen || root.openRequested) {
                root.openRequested = false
                openFallbackTimer.stop()
                root.showTooltip()
            }
        }
    }

    Timer {
        id: openFallbackTimer
        interval: 45
        repeat: false
        onTriggered: {
            if (root.pendingOpen) {
                root.applyStateJson(stateFile.text())
                root.showTooltip()
            }
        }
    }

    IpcHandler {
        target: "quickpaste"
        function ping() {
            return "pong"
        }
        function quit() {
            Qt.quit()
        }
        function openAtCursor() {
            root.openAtCursor()
        }
        function close() {
            root.closeTooltip()
        }
        function toggleAtCursor() {
            root.toggleAtCursor()
        }
    }

    PanelWindow {
        id: overlay
        visible: false
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell-quickpaste"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Compute dynamic card size and monitor-clamped cursor coordinates
        readonly property int edgeMargin: 12
        readonly property int cursorOffsetX: 12
        readonly property int cursorOffsetY: 14
        readonly property int cardWidth: 348
        readonly property int headerHeight: 40
        readonly property int footerHeight: 26
        readonly property int rowHeight: 42
        readonly property int rowSpacing: 4
        readonly property int maxVisibleRows: 8
        readonly property int itemCount: root.clipItems.length
        readonly property int visibleRows: Math.min(itemCount, maxVisibleRows)
        readonly property int listHeight: itemCount > 0
            ? (visibleRows * rowHeight + Math.max(0, visibleRows - 1) * rowSpacing)
            : 76
        readonly property int cardHeight: headerHeight + listHeight + footerHeight + 28

        readonly property real screenW: overlay.width > 0 ? overlay.width : root.stateMonWidth
        readonly property real screenH: overlay.height > 0 ? overlay.height : root.stateMonHeight
        readonly property real insLeft: root.reservedInsets.length > 0 ? Number(root.reservedInsets[0] || 0) : 0
        readonly property real insTop: root.reservedInsets.length > 1 ? Number(root.reservedInsets[1] || 0) : 0
        readonly property real insRight: root.reservedInsets.length > 2 ? Number(root.reservedInsets[2] || 0) : 0
        readonly property real insBottom: root.reservedInsets.length > 3 ? Number(root.reservedInsets[3] || 0) : 0

        readonly property real minX: insLeft + edgeMargin
        readonly property real maxX: Math.max(minX, screenW - insRight - edgeMargin - cardWidth)
        readonly property real minY: insTop + edgeMargin
        readonly property real maxY: Math.max(minY, screenH - insBottom - edgeMargin - cardHeight)

        readonly property bool flippedLeft: (root.cursorLocalX + cursorOffsetX + cardWidth > screenW - insRight - edgeMargin)
            && (root.cursorLocalX - cursorOffsetX - cardWidth >= minX)
        readonly property bool flippedUp: (root.cursorLocalY + cursorOffsetY + cardHeight > screenH - insBottom - edgeMargin)
            && (root.cursorLocalY - cursorOffsetY - cardHeight >= minY)

        readonly property real rawX: flippedLeft
            ? (root.cursorLocalX - cursorOffsetX - cardWidth)
            : (root.cursorLocalX + cursorOffsetX)
        readonly property real rawY: flippedUp
            ? (root.cursorLocalY - cursorOffsetY - cardHeight)
            : (root.cursorLocalY + cursorOffsetY)

        readonly property real cardX: Math.max(minX, Math.min(maxX, rawX))
        readonly property real cardY: Math.max(minY, Math.min(maxY, rawY))

        FocusScope {
            id: focusScope
            anchors.fill: parent
            focus: true

            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                    root.closeTooltip()
                    event.accepted = true
                    return
                }
                if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                    if (root.clipItems.length > 0) {
                        root.selectedIndex = (root.selectedIndex + 1) % root.clipItems.length
                        clipList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                    }
                    event.accepted = true
                    return
                }
                if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                    if (root.clipItems.length > 0) {
                        root.selectedIndex = (root.selectedIndex - 1 + root.clipItems.length) % root.clipItems.length
                        clipList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                    }
                    event.accepted = true
                    return
                }
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.pasteIndex(root.selectedIndex)
                    event.accepted = true
                    return
                }
                if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                    var idx = event.key - Qt.Key_1
                    if (idx < root.clipItems.length) {
                        root.pasteIndex(idx)
                    }
                    event.accepted = true
                }
            }

            // Transparent click-outside backdrop (alpha 0.0 avoids Hyprland blur bleed)
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onPressed: root.closeTooltip()
            }

            Item {
                id: cardHost
                x: overlay.cardX
                y: overlay.cardY
                width: overlay.cardWidth
                height: overlay.cardHeight

                transformOrigin: {
                    if (overlay.flippedLeft && overlay.flippedUp) return Item.BottomRight
                    if (overlay.flippedLeft) return Item.TopRight
                    if (overlay.flippedUp) return Item.BottomLeft
                    return Item.TopLeft
                }

                ParallelAnimation {
                    id: revealAnim
                    NumberAnimation {
                        target: cardHost
                        property: "opacity"
                        from: 0.0
                        to: 1.0
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                    SpringAnimation {
                        target: cardHost
                        property: "scale"
                        from: 0.94
                        to: 1.0
                        spring: 5.2
                        damping: 0.45
                        epsilon: 0.005
                    }
                }

                // Consume pointer clicks inside tooltip card so outside-dismiss doesn't fire
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onPressed: function(mouse) { mouse.accepted = true }
                }

                Rectangle {
                    id: tooltipCard
                    anchors.fill: parent
                    radius: Theme.radiusCard
                    color: Theme.glassBase
                    border.width: 1
                    border.color: Theme.glassRimMid
                    clip: true

                    // Top inner obsidian rim highlight
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: Math.max(0, tooltipCard.radius - 1)
                        color: "transparent"
                        border.width: 1
                        border.color: Theme.glassRimTop
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

                        // Compact Header
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: overlay.headerHeight - 6
                            spacing: 8

                            Rectangle {
                                width: 26
                                height: 26
                                radius: 8
                                color: Theme.accentSoft
                                border.width: 1
                                border.color: Theme.alpha(Theme.accent, 0.30)

                                Image {
                                    anchors.centerIn: parent
                                    width: 14
                                    height: 14
                                    sourceSize: Qt.size(14, 14)
                                    source: root.svgUri('<rect x="8" y="2" width="8" height="4" rx="1" ry="1"/><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/>', Theme.mix(Theme.accent, Theme.foreground, 0.25))
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Quick Paste"
                                color: Theme.foreground
                                font.family: "Inter"
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                implicitWidth: countText.implicitWidth + 12
                                implicitHeight: 20
                                radius: Theme.radiusPill
                                color: Theme.glassCard
                                border.width: 1
                                border.color: Theme.alpha(Theme.foreground, 0.08)

                                Text {
                                    id: countText
                                    anchors.centerIn: parent
                                    text: root.clipItems.length + " recent"
                                    color: Theme.alpha(Theme.foreground, 0.62)
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                }
                            }
                        }

                        // Subtle divider
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Theme.alpha(Theme.foreground, 0.08)
                        }

                        // History List
                        ListView {
                            id: clipList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: root.clipItems.length > 0
                            model: root.clipItems
                            spacing: overlay.rowSpacing
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            delegate: Rectangle {
                                id: rowItem
                                required property var modelData
                                required property int index

                                readonly property bool isSelected: index === root.selectedIndex
                                readonly property bool isUrl: (modelData.kind || "") === "url"
                                readonly property bool isColor: (modelData.kind || "") === "color"
                                readonly property bool isHovered: rowMouse.containsMouse

                                width: clipList.width
                                height: overlay.rowHeight
                                radius: 10
                                color: isHovered
                                    ? Theme.alpha(Theme.accent, 0.20)
                                    : (isSelected ? Theme.glassElevated : Theme.alpha(Theme.surface, 0.36))
                                border.width: 1
                                border.color: (isHovered || isSelected)
                                    ? Theme.alpha(Theme.accent, isHovered ? 0.55 : 0.35)
                                    : Theme.alpha(Theme.foreground, 0.05)

                                Behavior on color { ColorAnimation { duration: 90 } }
                                Behavior on border.color { ColorAnimation { duration: 90 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    // Kind Badge / Color Dot
                                    Rectangle {
                                        width: 24
                                        height: 24
                                        radius: 7
                                        color: rowItem.isColor
                                            ? rowItem.modelData.preview
                                            : (rowItem.isUrl ? Theme.accentSoft : Theme.alpha(Theme.foreground, 0.06))
                                        border.width: 1
                                        border.color: rowItem.isColor
                                            ? Theme.alpha(Theme.foreground, 0.25)
                                            : (rowItem.isUrl ? Theme.alpha(Theme.accent, 0.28) : Theme.alpha(Theme.foreground, 0.08))

                                        Image {
                                            visible: !rowItem.isColor
                                            anchors.centerIn: parent
                                            width: 13
                                            height: 13
                                            sourceSize: Qt.size(13, 13)
                                            source: root.iconForKind(
                                                rowItem.modelData.kind || "text",
                                                rowItem.isUrl
                                                    ? Theme.mix(Theme.accent, Theme.foreground, 0.28)
                                                    : Theme.alpha(Theme.foreground, 0.85)
                                            )
                                        }
                                    }

                                    // Text / Link Preview
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            Layout.fillWidth: true
                                            text: rowItem.modelData.preview || ""
                                            color: Theme.foreground
                                            font.family: rowItem.isUrl ? "JetBrains Mono" : "Inter"
                                            font.pixelSize: 12
                                            font.weight: (rowItem.isHovered || rowItem.isSelected) ? Font.Medium : Font.Normal
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                        }

                                        Text {
                                            visible: rowItem.isUrl && (rowItem.modelData.host || "").length > 0
                                            Layout.fillWidth: true
                                            text: rowItem.modelData.host || ""
                                            color: Theme.accent
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: 10
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                        }
                                    }

                                    // Quick Keycap (1..9)
                                    Rectangle {
                                        visible: rowItem.index < 9
                                        implicitWidth: 18
                                        implicitHeight: 18
                                        radius: 5
                                        color: (rowItem.isHovered || rowItem.isSelected)
                                            ? Theme.alpha(Theme.accent, 0.24)
                                            : Theme.alpha(Theme.background, 0.65)
                                        border.width: 1
                                        border.color: Theme.alpha(Theme.foreground, 0.10)

                                        Text {
                                            anchors.centerIn: parent
                                            text: String(rowItem.index + 1)
                                            color: (rowItem.isHovered || rowItem.isSelected) ? Theme.foreground : Theme.alpha(Theme.foreground, 0.62)
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: 10
                                            font.weight: Font.Medium
                                        }
                                    }
                                }

                                MouseArea {
                                    id: rowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.selectedIndex = rowItem.index
                                    onClicked: root.pasteIndex(rowItem.index)
                                }
                            }
                        }

                        // Empty State
                        ColumnLayout {
                            visible: root.clipItems.length === 0
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 4

                            Item { Layout.fillHeight: true }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "No recent text or links"
                                color: Theme.foreground
                                font.family: "Inter"
                                font.pixelSize: 12
                                font.weight: Font.Medium
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Copy text to populate Quick Paste"
                                color: Theme.muted
                                font.family: "Inter"
                                font.pixelSize: 11
                            }
                            Item { Layout.fillHeight: true }
                        }

                        // Compact Footer Hint
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: overlay.footerHeight - 6
                            spacing: 6

                            Text {
                                Layout.fillWidth: true
                                text: "Click or press 1-9 to paste"
                                color: Theme.alpha(Theme.foreground, 0.62)
                                font.family: "Inter"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "Esc"
                                color: Theme.alpha(Theme.foreground, 0.68)
                                font.family: "JetBrains Mono"
                                font.pixelSize: 10
                            }
                        }
                    }
                }
            }
        }
    }
}
