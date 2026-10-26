import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "."

PopupWindow {
    id: contextMenuRoot
    color: "transparent"
    visible: false

    property var targetItem: null
    property string dockPosition: "bottom"

    signal pinToggled(var itemData)
    signal newInstance(var itemData)
    signal closeWindow(var itemData)
    signal menuDismissed()

    implicitWidth: 196
    implicitHeight: menuCol.implicitHeight + 16

    function svgUrl(svgString) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgString)
    }

    readonly property string pinSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="17" x2="12" y2="22"/><path d="M5 17h14v-1.76a2 2 0 0 0-1.11-1.79l-1.78-.9A2 2 0 0 1 15 10.76V6h1a1 1 0 0 0 1-1V3a1 1 0 0 0-1-1H8a1 1 0 0 0-1 1v2a1 1 0 0 0 1 1h1v4.76a2 2 0 0 1-1.11 1.79l-1.78.9A2 2 0 0 0 5 15.24Z"/></svg>')
    readonly property string unpinSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="2" y1="2" x2="22" y2="22"/><line x1="12" y1="17" x2="12" y2="22"/><path d="M9 9v1.76a2 2 0 0 1-1.11 1.79l-1.78.9A2 2 0 0 0 5 15.24V17h12"/><path d="M15 9.34V6h1a1 1 0 0 0 1-1V3a1 1 0 0 0-1-1H8"/></svg>')
    readonly property string newWindowSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="3"/><line x1="12" y1="8" x2="12" y2="16"/><line x1="8" y1="12" x2="16" y2="12"/></svg>')
    readonly property string closeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.error + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>')
    readonly property string closeIconSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>')
    readonly property string closeIconHoverSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>')

    property bool dockHovered: false
    readonly property bool isHovered: menuHH.hovered

    HoverHandler {
        id: menuHH
    }

    onDockHoveredChanged: checkAutoDismiss()
    onIsHoveredChanged: checkAutoDismiss()

    function checkAutoDismiss() {
        if (!visible) return
        if (!isHovered && !dockHovered) {
            autoDismissTimer.restart()
        } else {
            autoDismissTimer.stop()
        }
    }

    Timer {
        id: autoDismissTimer
        interval: 380
        repeat: false
        onTriggered: {
            if (!contextMenuRoot.isHovered && !contextMenuRoot.dockHovered) {
                contextMenuRoot.close()
            }
        }
    }

    function open(itemData, itemVisual, position, parentWin) {
        if (!itemVisual) return
        targetItem = itemData
        dockPosition = position
        anchor.window = parentWin
        anchor.item = itemVisual

        if (dockPosition === "bottom") {
            anchor.edges = Edges.Top
            anchor.gravity = Edges.Top
            anchor.margins.bottom = 8
            anchor.margins.top = 0
            anchor.margins.left = 0
            anchor.margins.right = 0
        } else if (dockPosition === "top") {
            anchor.edges = Edges.Bottom
            anchor.gravity = Edges.Bottom
            anchor.margins.top = 8
            anchor.margins.bottom = 0
            anchor.margins.left = 0
            anchor.margins.right = 0
        } else if (dockPosition === "left") {
            anchor.edges = Edges.Right
            anchor.gravity = Edges.Right
            anchor.margins.left = 8
            anchor.margins.right = 0
            anchor.margins.top = 0
            anchor.margins.bottom = 0
        } else if (dockPosition === "right") {
            anchor.edges = Edges.Left
            anchor.gravity = Edges.Left
            anchor.margins.right = 8
            anchor.margins.left = 0
            anchor.margins.top = 0
            anchor.margins.bottom = 0
        }

        visible = true
    }

    function close() {
        if (!visible) return
        visible = false
        targetItem = null
        menuDismissed()
    }

    Rectangle {
        id: menuContainer
        anchors.fill: parent
        radius: 12
        color: Theme.alpha(Theme.surface, 0.95)
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.35)

        Column {
            id: menuCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            spacing: 4

            // Header: Icon + Name + Close Button
            RowLayout {
                width: parent.width
                spacing: 8

                Item {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    Layout.leftMargin: 4

                    Image {
                        anchors.fill: parent
                        source: targetItem && targetItem.icon_path ? targetItem.icon_path : ""
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        asynchronous: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: targetItem ? (targetItem.name || "Application") : ""
                        color: Theme.foreground
                        font.family: "Outfit"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: {
                            if (!targetItem) return ""
                            if (targetItem.isRunning) {
                                var count = targetItem.windowCount || 1
                                return count + (count === 1 ? " window" : " windows")
                            }
                            return targetItem.isPinned ? "Pinned" : "Running"
                        }
                        color: targetItem && targetItem.isRunning ? Theme.accent : Theme.alpha(Theme.foreground, 0.45)
                        font.family: "Outfit"
                        font.pixelSize: 10
                    }
                }

                Item {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    Layout.rightMargin: 2

                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: closeBtnMouse.containsMouse ? Theme.alpha(Theme.accent, 0.18) : "transparent"
                        border.width: 1
                        border.color: closeBtnMouse.containsMouse ? Theme.alpha(Theme.accent, 0.35) : "transparent"

                        Image {
                            anchors.centerIn: parent
                            width: 10
                            height: 10
                            source: closeBtnMouse.containsMouse ? contextMenuRoot.closeIconHoverSvg : contextMenuRoot.closeIconSvg
                            sourceSize: Qt.size(20, 20)
                        }

                        MouseArea {
                            id: closeBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: contextMenuRoot.close()
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                width: parent.width - 8
                anchors.horizontalCenter: parent.horizontalCenter
                height: 1
                color: Theme.alpha(Theme.foreground, 0.10)
            }

            // Option 1: Pin / Unpin
            Rectangle {
                width: parent.width
                height: 30
                radius: 6
                color: pinMouse.containsMouse ? Theme.alpha(Theme.accent, 0.18) : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    Image {
                        Layout.preferredWidth: 15
                        Layout.preferredHeight: 15
                        source: targetItem && targetItem.isPinned ? contextMenuRoot.unpinSvg : contextMenuRoot.pinSvg
                        sourceSize: Qt.size(30, 30)
                    }

                    Text {
                        Layout.fillWidth: true
                        text: targetItem && targetItem.isPinned ? "Unpin from Dock" : "Pin to Dock"
                        color: targetItem && targetItem.isPinned ? Theme.foreground : Theme.accent
                        font.family: "Outfit"
                        font.pixelSize: 12
                        font.weight: targetItem && targetItem.isPinned ? Font.Normal : Font.DemiBold
                    }
                }

                MouseArea {
                    id: pinMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var it = targetItem
                        contextMenuRoot.close()
                        contextMenuRoot.pinToggled(it)
                    }
                }
            }

            // Option 2: New Window
            Rectangle {
                width: parent.width
                height: 30
                radius: 6
                color: newMouse.containsMouse ? Theme.alpha(Theme.accent, 0.18) : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    Image {
                        Layout.preferredWidth: 15
                        Layout.preferredHeight: 15
                        source: contextMenuRoot.newWindowSvg
                        sourceSize: Qt.size(30, 30)
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "New Window"
                        color: Theme.foreground
                        font.family: "Outfit"
                        font.pixelSize: 12
                    }
                }

                MouseArea {
                    id: newMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var it = targetItem
                        contextMenuRoot.close()
                        contextMenuRoot.newInstance(it)
                    }
                }
            }

            // Option 3: Close Window (if running)
            Rectangle {
                width: parent.width
                height: 30
                radius: 6
                visible: targetItem && targetItem.isRunning
                color: closeMouse.containsMouse ? Theme.alpha(Theme.error, 0.22) : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    Image {
                        Layout.preferredWidth: 15
                        Layout.preferredHeight: 15
                        source: contextMenuRoot.closeSvg
                        sourceSize: Qt.size(30, 30)
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Close Window"
                        color: closeMouse.containsMouse ? Theme.error : Theme.foreground
                        font.family: "Outfit"
                        font.pixelSize: 12
                    }
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var it = targetItem
                        contextMenuRoot.close()
                        contextMenuRoot.closeWindow(it)
                    }
                }
            }
        }
    }
}
