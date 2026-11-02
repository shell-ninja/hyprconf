import QtQuick
import QtQuick.Layouts
import "."

Item {
    id: root

    property var bar: null

    property bool shown: false
    property bool instantHide: false
    property string osdType: "volume"        // "volume" | "mic" | "brightness" | "power" | "caffeine" | "nightlight" | "input" | "capslock" | "numlock" | "screenshot"
    property real osdValue: 0.5             // 0.0 to 1.0 (or up to 1.5)
    property string osdLabel: ""
    property string osdSubLabel: ""
    property string osdIcon: ""

    // Calculated state
    readonly property bool isMuted: {
        if (osdType === "volume" || osdType === "mic") {
            return osdIcon.indexOf("mute") !== -1 || osdLabel.toLowerCase().indexOf("mute") !== -1 || (osdValue === 0 && osdType === "volume")
        }
        return false
    }

    readonly property bool isAlert: isMuted

    readonly property string displayTitle: {
        switch (osdType) {
            case "volume": return "Master Volume"
            case "mic": return "Microphone"
            case "brightness": return "Display Brightness"
            case "power":
            case "power_profile": return "Power Profile"
            case "caffeine": return "Caffeine Mode"
            case "nightlight":
            case "sunset": return "Night Light"
            case "input": return "Input Method"
            case "capslock": return "Caps Lock"
            case "numlock": return "Num Lock"
            case "screenshot":
            case "timer": return "Screenshot Timer"
            default: return "System Setting"
        }
    }

    readonly property string iconName: {
        if (osdType === "screenshot" || osdType === "timer") return "camera"
        if (osdType === "volume") {
            if (isMuted) return "volumeMute"
            if (osdValue <= 0.33) return "speakerLow"
            return "volume"
        }
        if (osdType === "mic") {
            return isMuted ? "micMute" : "mic"
        }
        if (osdType === "brightness") return "sun"
        if (osdType === "power" || osdType === "power_profile") {
            if (osdValue >= 0.7 || osdLabel.toLowerCase().indexOf("perf") !== -1) return "bolt"
            if (osdValue <= 0.3 || osdLabel.toLowerCase().indexOf("save") !== -1) return "leaf"
            return "gauge"
        }
        if (osdType === "caffeine") return "coffee"
        if (osdType === "nightlight" || osdType === "sunset") return "moon"
        if (osdType === "input") return "keyboard"
        if (osdType === "capslock" || osdType === "numlock") return "lock"
        return "bolt"
    }

    function show(type, value, label, icon, subLabel) {
        instantHide = false
        osdType = type || "volume"
        var numVal = parseFloat(value)
        if (isNaN(numVal)) numVal = 0.0

        if (osdType === "brightness" || osdType === "volume" || osdType === "mic" || osdType === "screenshot" || osdType === "timer") {
            var normalized = (numVal > 0.0 && numVal <= 1.0) ? numVal : (numVal / 100.0)
            osdValue = Math.max(0.0, Math.min(1.5, normalized))
        } else if (osdType === "power" || osdType === "power_profile") {
            if (value === "0" || value === 0 || ("" + label).toLowerCase().indexOf("perf") !== -1) osdValue = 1.0
            else if (value === "2" || value === 2 || ("" + label).toLowerCase().indexOf("save") !== -1) osdValue = 0.1
            else osdValue = 0.5
        } else {
            osdValue = numVal > 0 ? 1.0 : 0.0
        }

        osdLabel = (label !== undefined && label !== null && ("" + label).length > 0) ? ("" + label) : (Math.round(osdValue * 100) + "%")
        osdIcon = icon || osdType
        osdSubLabel = (subLabel !== undefined && subLabel !== null) ? ("" + subLabel) : ""

        hideTimer.interval = (osdType === "screenshot" || osdType === "timer") ? 2200 : 1800
        shown = true
        hideTimer.restart()
    }

    function close(immediate) {
        if (immediate !== false) {
            instantHide = true
        }
        shown = false
        hideTimer.stop()
        if (instantHide) {
            resetInstantTimer.restart()
        }
    }

    Timer {
        id: resetInstantTimer
        interval: 120
        repeat: false
        onTriggered: root.instantHide = false
    }

    Timer {
        id: hideTimer
        interval: 1800
        repeat: false
        onTriggered: root.shown = false
    }

    // Geometry & Positioning: centered under the bar
    anchors.horizontalCenter: parent.horizontalCenter
    y: (typeof bar !== "undefined" && bar) ? (bar.marginTop + bar.barH + 14) : 56
    width: 280
    height: 52
    z: 99

    opacity: shown ? 1.0 : 0.0
    scale: shown ? 1.0 : 0.92
    transformOrigin: Item.Center

    Behavior on opacity {
        NumberAnimation {
            duration: root.shown ? 180 : (root.instantHide ? 0 : 180)
            easing.type: Easing.OutCubic
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: root.shown ? 220 : (root.instantHide ? 0 : 160)
            easing.type: root.shown ? Easing.OutBack : Easing.OutCubic
            easing.overshoot: 1.25
        }
    }

    visible: !instantHide && shown && opacity > 0.001

    // Capsule background
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 16
        color: Theme.alpha(Theme.surface, 0.92)
        border.width: 1
        border.color: root.isAlert ? Theme.alpha(Theme.error, 0.45) : Theme.alpha(Theme.accent, 0.35)

        // Glass highlight line at top
        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.75
            height: 1
            color: Theme.alpha(Theme.foreground, 0.12)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            // Icon Badge
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 10
                color: root.isAlert ? Theme.alpha(Theme.error, 0.18) : Theme.alpha(Theme.accent, 0.16)
                border.width: 1
                border.color: root.isAlert ? Theme.alpha(Theme.error, 0.40) : Theme.alpha(Theme.accent, 0.32)

                SvgIcon {
                    anchors.centerIn: parent
                    size: 16
                    name: root.iconName
                    color: root.isAlert ? Theme.error : Theme.accent
                }
            }

            // Info Column
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                // Top row: Title and Value
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: root.displayTitle
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: Theme.foreground
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.osdLabel
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: root.isAlert ? Theme.error : Theme.accent
                    }
                }

                // Bottom row: Range bar or sublabel
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6

                    // Range Bar (Volume / Mic / Brightness / Screenshot)
                    Rectangle {
                        anchors.fill: parent
                        radius: 3
                        color: Theme.alpha(Theme.foreground, 0.12)
                        visible: root.osdType === "volume" || root.osdType === "mic" || root.osdType === "brightness" || root.osdType === "screenshot" || root.osdType === "timer"

                        Rectangle {
                            height: parent.height
                            width: Math.max(0, Math.min(parent.width, parent.width * Math.min(1.0, root.osdValue)))
                            radius: 3
                            color: root.isAlert ? Theme.error : Theme.accent

                            Behavior on width {
                                NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    // Stepped meter for Power Profile (3 segments)
                    RowLayout {
                        anchors.fill: parent
                        spacing: 4
                        visible: root.osdType === "power" || root.osdType === "power_profile"

                        Repeater {
                            model: 3
                            Rectangle {
                                Layout.fillWidth: true
                                height: 5
                                radius: 2.5
                                readonly property bool active: {
                                    // 0: saver, 1: balanced, 2: perf
                                    if (root.osdValue <= 0.3) return index === 0
                                    if (root.osdValue <= 0.7) return index <= 1
                                    return true
                                }
                                color: active
                                    ? ((index === 2) ? Theme.accent : (index === 1 ? Theme.secondary : Theme.primary))
                                    : Theme.alpha(Theme.foreground, 0.14)
                            }
                        }
                    }

                    // Subtitle for binary toggles (caffeine, nightlight, input, lock)
                    Text {
                        anchors.fill: parent
                        anchors.topMargin: -3
                        text: root.osdSubLabel.length > 0 ? root.osdSubLabel : (root.osdValue > 0 ? "Enabled" : "Disabled")
                        font.family: "Outfit"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: Theme.alpha(Theme.foreground, 0.55)
                        elide: Text.ElideRight
                        visible: root.osdType !== "volume" && root.osdType !== "mic" && root.osdType !== "brightness" && root.osdType !== "power" && root.osdType !== "power_profile"
                    }
                }
            }
        }
    }
}
