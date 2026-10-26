import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root

    anchors.fill: parent
    z: 100
    visible: opacity > 0.001
    opacity: 0.0
    enabled: isOpen

    property bool isOpen: false
    property var networks: []
    property bool isScanning: false
    property bool wifiEnabled: true

    // Auth modal state
    property bool authModalOpen: false
    property string selectedSsid: ""
    property string selectedSecurity: ""
    property string authPassword: ""
    property bool showPassword: false
    property bool authConnecting: false
    property string authError: ""

    signal closed()

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : "/home/shell-ninja"
    }

    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    // ── ICONS ────────────────────────────────────────────────────────────────
    readonly property string arrowLeftSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>')
    readonly property string refreshSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M21.5 2v6h-6M21.34 15.57a10 10 0 1 1-.57-8.38l5.67-5.67"/></svg>')
    readonly property string lockSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.muted + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>')
    readonly property string shieldSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>')
    readonly property string checkSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>')
    readonly property string eyeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>')
    readonly property string eyeOffSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>')
    readonly property string alertSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>')
    readonly property string wifiOffSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.muted + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="1" y1="1" x2="23" y2="23"/><path d="M16.72 11.06A10.94 10.94 0 0 1 19 12.55"/><path d="M5 12.55a10.94 10.94 0 0 1 5.17-2.39"/><path d="M10.71 5.05A16 16 0 0 1 22.58 9"/><path d="M1.42 9a15.91 15.91 0 0 1 4.7-2.88"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1.2" fill="' + Theme.muted + '"/></svg>')

    function getSignalSvg(signal, isConnected) {
        var color = isConnected ? Theme.accent : (signal >= 75 ? "#10b981" : (signal >= 45 ? Theme.foreground : "#f59e0b"))
        if (signal >= 75) {
            return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + color + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M1.42 9a16 16 0 0 1 21.16 0"/><path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1.2" fill="' + color + '"/></svg>')
        } else if (signal >= 50) {
            return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + color + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1.2" fill="' + color + '"/></svg>')
        } else if (signal >= 25) {
            return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + color + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1.2" fill="' + color + '"/></svg>')
        } else {
            return svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + color + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="20" r="1.8" fill="' + color + '"/></svg>')
        }
    }

    // ── PROCESSES ────────────────────────────────────────────────────────────
    Process {
        id: scanProcess
        command: ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/island-network.py", "list"]
        stdout: StdioCollector {
            onTextChanged: {
                root.isScanning = false
                if (!text || text.trim().length === 0) return
                try {
                    var parsed = JSON.parse(text.trim())
                    root.wifiEnabled = (parsed.wifi_enabled !== undefined) ? parsed.wifi_enabled : true
                    root.networks = parsed.networks || []
                } catch (e) {
                    console.error("[WifiDialog] Failed to parse network list:", e)
                }
            }
        }
        onExited: function() {
            root.isScanning = false
        }
    }

    Process {
        id: connectProcess
        stdout: StdioCollector {
            onTextChanged: {
                root.authConnecting = false
                if (!text || text.trim().length === 0) return
                try {
                    var parsed = JSON.parse(text.trim())
                    if (parsed.success) {
                        root.authModalOpen = false
                        root.authError = ""
                        root.scan()
                    } else {
                        root.authError = parsed.message || "Connection failed. Please check the password."
                        shakeAnim.restart()
                    }
                } catch (e) {
                    root.authError = "Connection error occurred"
                    shakeAnim.restart()
                }
            }
        }
        onExited: function() {
            root.authConnecting = false
        }
    }

    Process {
        id: actionProcess
        onExited: function() {
            root.scan()
        }
    }

    // ── METHODS ──────────────────────────────────────────────────────────────
    function open() {
        root.isOpen = true
        root.authModalOpen = false
        root.authError = ""
        root.authConnecting = false
        root.scan()
    }

    function close() {
        root.isOpen = false
        root.authModalOpen = false
        root.closed()
    }

    function scan() {
        if (!scanProcess.running) {
            root.isScanning = true
            scanProcess.running = true
        }
    }

    function toggleWifiRadio() {
        actionProcess.command = ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/island-network.py", "toggle-wifi"]
        actionProcess.running = true
    }

    function disconnectCurrent() {
        actionProcess.command = ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/island-network.py", "disconnect"]
        actionProcess.running = true
    }

    function handleNetworkClick(net) {
        if (!net || !net.ssid) return

        if (net.is_connected) {
            return
        }

        // If open or already saved connection, connect directly
        if (!net.is_secured || net.is_saved) {
            root.authConnecting = true
            connectProcess.command = ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/island-network.py", "connect", net.ssid]
            connectProcess.running = true
            return
        }

        // Otherwise open Authentication Prompt Modal
        root.selectedSsid = net.ssid
        root.selectedSecurity = net.security || "WPA2"
        root.authPassword = ""
        root.authError = ""
        root.showPassword = false
        root.authConnecting = false
        root.authModalOpen = true
        passwordFocusTimer.restart()
    }

    function submitPassword() {
        if (!root.selectedSsid) return
        root.authConnecting = true
        root.authError = ""
        connectProcess.command = ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/island-network.py", "connect", root.selectedSsid, root.authPassword]
        connectProcess.running = true
    }

    Timer {
        id: passwordFocusTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (passwordInput) passwordInput.forceActiveFocus()
        }
    }

    // ── ANIMATIONS ───────────────────────────────────────────────────────────
    Behavior on opacity {
        NumberAnimation { duration: root.isOpen ? 220 : 150; easing.type: Easing.OutCubic }
    }

    transform: Translate {
        id: sheetTranslate
        y: root.isOpen ? 0 : 20
        Behavior on y {
            NumberAnimation { duration: root.isOpen ? 240 : 150; easing.type: Easing.OutCubic }
        }
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: authCard; property: "x"; to: -12; duration: 40; easing.type: Easing.OutQuad }
        NumberAnimation { target: authCard; property: "x"; to: 12; duration: 40; easing.type: Easing.OutQuad }
        NumberAnimation { target: authCard; property: "x"; to: -8; duration: 40; easing.type: Easing.OutQuad }
        NumberAnimation { target: authCard; property: "x"; to: 8; duration: 40; easing.type: Easing.OutQuad }
        NumberAnimation { target: authCard; property: "x"; to: 0; duration: 40; easing.type: Easing.OutQuad }
    }

    // ── MAIN DIALOG CONTAINER ────────────────────────────────────────────────
    Rectangle {
        id: mainPanel
        anchors.fill: parent
        radius: 20
        color: Theme.alpha(Theme.background, 0.96)
        border.width: 1
        border.color: Theme.alpha(Theme.foreground, 0.12)
        clip: true

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // 1. HEADER ROW: Back button, Title, Rescan, Wi-Fi Toggle
            RowLayout {
                width: parent.width
                height: 38
                spacing: 10

                // Back / Close Button
                Rectangle {
                    width: 34
                    height: 34
                    radius: 17
                    color: backMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.14) : Theme.alpha(Theme.surface, 0.6)
                    border.width: 1
                    border.color: Theme.alpha(Theme.foreground, 0.08)
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Image {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        source: root.arrowLeftSvg
                    }

                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }

                // Title & Network Count
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Wi-Fi Networks"
                        font.family: "Outfit"
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        color: Theme.foreground
                    }

                    Text {
                        text: !root.wifiEnabled ? "Wi-Fi is turned off" : (root.isScanning ? "Scanning nearby networks..." : (root.networks.length + " networks found"))
                        font.family: "Outfit"
                        font.pixelSize: 11
                        color: Theme.muted
                    }
                }

                // Rescan Button
                Rectangle {
                    width: 34
                    height: 34
                    radius: 17
                    color: scanMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.14) : Theme.alpha(Theme.surface, 0.6)
                    border.width: 1
                    border.color: Theme.alpha(Theme.foreground, 0.08)
                    visible: root.wifiEnabled
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Image {
                        id: refreshIcon
                        anchors.centerIn: parent
                        width: 15
                        height: 15
                        source: root.refreshSvg
                        rotation: root.isScanning ? 360 : 0
                        Behavior on rotation {
                            NumberAnimation { duration: 700; loops: Animation.Infinite; running: root.isScanning }
                        }
                    }

                    MouseArea {
                        id: scanMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.scan()
                    }
                }

                // Wi-Fi Power Capsule Toggle Switch
                Rectangle {
                    width: 44
                    height: 24
                    radius: 12
                    color: root.wifiEnabled ? Theme.accent : Theme.alpha(Theme.muted, 0.35)
                    border.width: 1
                    border.color: Theme.alpha(Theme.foreground, 0.15)
                    Behavior on color { ColorAnimation { duration: 180 } }

                    Rectangle {
                        width: 18
                        height: 18
                        radius: 9
                        color: Theme.foreground
                        anchors.verticalCenter: parent.verticalCenter
                        x: root.wifiEnabled ? (parent.width - width - 3) : 3
                        Behavior on x {
                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleWifiRadio()
                    }
                }
            }

            // Divider
            Rectangle {
                width: parent.width
                height: 1
                color: Theme.alpha(Theme.foreground, 0.06)
            }

            // 2. BODY CONTENT
            Item {
                width: parent.width
                height: parent.height - 62

                // State A: Wi-Fi Disabled
                Column {
                    anchors.centerIn: parent
                    spacing: 12
                    visible: !root.wifiEnabled

                    Rectangle {
                        width: 60
                        height: 60
                        radius: 30
                        color: Theme.alpha(Theme.surface, 0.6)
                        border.width: 1
                        border.color: Theme.alpha(Theme.foreground, 0.08)
                        anchors.horizontalCenter: parent.horizontalCenter

                        Image {
                            anchors.centerIn: parent
                            width: 28
                            height: 28
                            source: root.wifiOffSvg
                        }
                    }

                    Text {
                        text: "Wi-Fi is Turned Off"
                        font.family: "Outfit"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: Theme.foreground
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "Enable Wi-Fi to scan and connect to nearby networks"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        color: Theme.muted
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Rectangle {
                        width: 140
                        height: 36
                        radius: 10
                        color: Theme.accent
                        anchors.horizontalCenter: parent.horizontalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "Turn On Wi-Fi"
                            font.family: "Outfit"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: Theme.background
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleWifiRadio()
                        }
                    }
                }

                // State B: Wi-Fi Enabled & Network List
                Column {
                    anchors.fill: parent
                    spacing: 8
                    visible: root.wifiEnabled

                    // Scrollable List of Available Networks
                    ListView {
                        id: networkListView
                        width: parent.width
                        height: parent.height
                        clip: true
                        spacing: 6
                        boundsBehavior: Flickable.StopAtBounds
                        model: root.networks

                        delegate: Rectangle {
                            id: netRow
                            width: networkListView.width
                            height: 52
                            radius: 12
                            color: modelData.is_connected
                                ? Theme.alpha(Theme.accent, 0.16)
                                : (rowMouse.containsMouse ? Theme.alpha(Theme.surface, 0.75) : Theme.alpha(Theme.surface, 0.35))
                            border.width: 1
                            border.color: modelData.is_connected
                                ? Theme.alpha(Theme.accent, 0.45)
                                : (rowMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.14) : Theme.alpha(Theme.foreground, 0.05))

                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                // Left Signal Icon
                                Image {
                                    width: 20
                                    height: 20
                                    source: root.getSignalSvg(modelData.signal, modelData.is_connected)
                                }

                                // Center SSID & Metadata
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    RowLayout {
                                        spacing: 6

                                        Text {
                                            text: modelData.ssid
                                            font.family: "Outfit"
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                            color: modelData.is_connected ? Theme.accent : Theme.foreground
                                            elide: Text.ElideRight
                                            Layout.maximumWidth: 190
                                        }

                                        // Connected Badge
                                        Rectangle {
                                            visible: modelData.is_connected
                                            width: 68
                                            height: 18
                                            radius: 9
                                            color: Theme.alpha(Theme.accent, 0.2)
                                            border.width: 1
                                            border.color: Theme.alpha(Theme.accent, 0.4)

                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 4

                                                Rectangle {
                                                    width: 6
                                                    height: 6
                                                    radius: 3
                                                    color: "#10b981"
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }

                                                Text {
                                                    text: "Connected"
                                                    font.family: "Outfit"
                                                    font.pixelSize: 9
                                                    font.weight: Font.Bold
                                                    color: Theme.accent
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }
                                        }

                                        // Saved Badge
                                        Rectangle {
                                            visible: modelData.is_saved && !modelData.is_connected
                                            width: 44
                                            height: 16
                                            radius: 8
                                            color: Theme.alpha(Theme.foreground, 0.08)

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Saved"
                                                font.family: "Outfit"
                                                font.pixelSize: 9
                                                font.weight: Font.Medium
                                                color: Theme.muted
                                            }
                                        }
                                    }

                                    RowLayout {
                                        spacing: 8

                                        Text {
                                            text: modelData.security
                                            font.family: "Outfit"
                                            font.pixelSize: 10
                                            color: Theme.muted
                                        }

                                        Text {
                                            text: "•"
                                            font.pixelSize: 8
                                            color: Theme.alpha(Theme.foreground, 0.25)
                                        }

                                        Text {
                                            text: modelData.signal + "% signal"
                                            font.family: "Outfit"
                                            font.pixelSize: 10
                                            color: Theme.muted
                                        }
                                    }
                                }

                                // Right: Lock icon or Disconnect button
                                Item {
                                    width: 28
                                    height: 28

                                    Image {
                                        anchors.centerIn: parent
                                        width: 14
                                        height: 14
                                        source: root.lockSvg
                                        visible: modelData.is_secured && !modelData.is_connected
                                    }

                                    // Disconnect button for active network
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 24
                                        height: 24
                                        radius: 12
                                        color: disMouse.containsMouse ? Theme.alpha("#ef4444", 0.25) : Theme.alpha("#ef4444", 0.12)
                                        border.width: 1
                                        border.color: Theme.alpha("#ef4444", 0.3)
                                        visible: modelData.is_connected

                                        Text {
                                            anchors.centerIn: parent
                                            text: "✕"
                                            font.pixelSize: 10
                                            color: "#ef4444"
                                            font.weight: Font.Bold
                                        }

                                        MouseArea {
                                            id: disMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.disconnectCurrent()
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.handleNetworkClick(modelData)
                            }
                        }
                    }

                    // Empty / Scanning state indicator
                    Item {
                        width: parent.width
                        height: 200
                        visible: root.networks.length === 0

                        Column {
                            anchors.centerIn: parent
                            spacing: 10

                            Image {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 24
                                height: 24
                                source: root.refreshSvg
                                rotation: root.isScanning ? 360 : 0
                                Behavior on rotation {
                                    NumberAnimation { duration: 700; loops: Animation.Infinite; running: root.isScanning }
                                }
                            }

                            Text {
                                text: root.isScanning ? "Scanning for Wi-Fi networks..." : "No Wi-Fi networks found"
                                font.family: "Outfit"
                                font.pixelSize: 12
                                color: Theme.muted
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
            }
        }
    }

    // ── 3. AUTHENTICATION REQUIRED MODAL (POLKIT AGENT STYLE) ────────────────
    Rectangle {
        id: authOverlay
        anchors.fill: parent
        color: Theme.alpha(Theme.background, 0.75)
        visible: root.authModalOpen
        opacity: root.authModalOpen ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (!root.authConnecting) root.authModalOpen = false
            }
        }

        Rectangle {
            id: authCard
            width: parent.width - 48
            height: 290
            radius: 18
            color: Theme.alpha(Theme.background, 0.94)
            border.width: 1
            border.color: root.authError ? Theme.alpha("#ef4444", 0.6) : Theme.alpha(Theme.accent, 0.4)
            anchors.centerIn: parent
            clip: true

            Behavior on border.color { ColorAnimation { duration: 150 } }

            MouseArea {
                // Prevent clickthrough to overlay
                anchors.fill: parent
            }

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                // Header Row: Shield + Titles
                RowLayout {
                    width: parent.width
                    height: 38
                    spacing: 12

                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: Theme.alpha(Theme.accent, 0.16)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.35)

                        Image {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            source: root.shieldSvg
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: "AUTHENTICATION REQUIRED"
                            font.family: "Outfit"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.1
                            color: Theme.foreground
                        }

                        Text {
                            text: "Wi-Fi Network Authorization"
                            font.family: "Outfit"
                            font.pixelSize: 10
                            color: Theme.muted
                        }
                    }
                }

                // SSID details badge
                Rectangle {
                    width: parent.width
                    height: 40
                    radius: 10
                    color: Theme.alpha(Theme.surface, 0.5)
                    border.width: 1
                    border.color: Theme.alpha(Theme.foreground, 0.08)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Image {
                            width: 15
                            height: 15
                            source: root.lockSvg
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Connect to \"" + root.selectedSsid + "\""
                            font.family: "Outfit"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: Theme.foreground
                            elide: Text.ElideRight
                        }

                        Text {
                            text: root.selectedSecurity
                            font.family: "Outfit"
                            font.pixelSize: 10
                            color: Theme.muted
                        }
                    }
                }

                // Password Input Field
                Rectangle {
                    width: parent.width
                    height: 42
                    radius: 10
                    color: Theme.alpha(Theme.surface, 0.6)
                    border.width: 1
                    border.color: passwordInput.activeFocus ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        spacing: 8

                        Image {
                            width: 14
                            height: 14
                            source: root.lockSvg
                        }

                        TextInput {
                            id: passwordInput
                            Layout.fillWidth: true
                            echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                            font.family: "Outfit"
                            font.pixelSize: 12
                            color: Theme.foreground
                            selectByMouse: true
                            clip: true

                            Text {
                                anchors.fill: parent
                                text: "Enter Wi-Fi password..."
                                font.family: "Outfit"
                                font.pixelSize: 12
                                color: Theme.alpha(Theme.foreground, 0.35)
                                visible: !passwordInput.text && !passwordInput.activeFocus
                                verticalAlignment: Text.AlignVCenter
                            }

                            onTextChanged: {
                                root.authPassword = text
                            }

                            onAccepted: {
                                if (passwordInput.text.length > 0 && !root.authConnecting) {
                                    root.submitPassword()
                                }
                            }
                        }

                        // Eye toggle button
                        Rectangle {
                            width: 26
                            height: 26
                            radius: 13
                            color: eyeMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.1) : "transparent"

                            Image {
                                anchors.centerIn: parent
                                width: 14
                                height: 14
                                source: root.showPassword ? root.eyeOffSvg : root.eyeSvg
                            }

                            MouseArea {
                                id: eyeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.showPassword = !root.showPassword
                            }
                        }
                    }
                }

                // Error / Connecting status message
                Item {
                    width: parent.width
                    height: 24

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        visible: root.authConnecting

                        Text {
                            text: "Connecting to " + root.selectedSsid + "..."
                            font.family: "Outfit"
                            font.pixelSize: 11
                            color: Theme.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        visible: !root.authConnecting && root.authError.length > 0

                        Image {
                            width: 14
                            height: 14
                            source: root.alertSvg
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: root.authError
                            font.family: "Outfit"
                            font.pixelSize: 11
                            color: "#ef4444"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Buttons: Cancel & Connect
                RowLayout {
                    width: parent.width
                    height: 38
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: 10
                        color: cancelMouse.containsMouse ? Theme.alpha(Theme.surface, 0.8) : Theme.alpha(Theme.surface, 0.45)
                        border.width: 1
                        border.color: Theme.alpha(Theme.foreground, 0.1)

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.family: "Outfit"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Theme.foreground
                        }

                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!root.authConnecting) {
                                    root.authModalOpen = false
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: 10
                        color: root.authConnecting ? Theme.alpha(Theme.accent, 0.5) : (connectMouse.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent)
                        border.width: 1
                        border.color: Theme.accent

                        Text {
                            anchors.centerIn: parent
                            text: root.authConnecting ? "Connecting..." : "Connect"
                            font.family: "Outfit"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: Theme.background
                        }

                        MouseArea {
                            id: connectMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: !root.authConnecting && root.authPassword.length > 0
                            onClicked: root.submitPassword()
                        }
                    }
                }
            }
        }
    }
}
