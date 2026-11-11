import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

Item {
    id: root

    property var widgetConfig: ({
        format_24h: false,
        show_seconds: false,
        show_date: true,
        show_greeting: true,
        preset: "editorial_split",
        glass_opacity: 0.65
    })
    property bool editMode: false

    readonly property real clockFontSize: (root.widgetConfig && root.widgetConfig.font_size !== undefined) ? root.widgetConfig.font_size : 44
    readonly property string clockFontFamily: (root.widgetConfig && root.widgetConfig.font_family) ? root.widgetConfig.font_family : "Outfit"
    readonly property string clockPreset: {
        var raw = (root.widgetConfig && root.widgetConfig.preset) ? String(root.widgetConfig.preset).toLowerCase().replace(/\s+/g, "_") : "editorial_split"
        if (raw === "classic" || raw === "editorial_split" || raw === "mono_telemetry" || raw === "minimal_pill") return raw
        return "editorial_split"
    }

    implicitWidth: {
        if (clockPreset === "editorial_split") return Math.max(380, splitRow.implicitWidth + 68)
        if (clockPreset === "mono_telemetry") return Math.max(370, monoCol.implicitWidth + 68)
        if (clockPreset === "minimal_pill") return Math.max(320, minimalRow.implicitWidth + 56)
        return Math.max(360, timeRow.implicitWidth + 80)
    }
    implicitHeight: {
        if (clockPreset === "editorial_split") return Math.max(122, splitWrapper.implicitHeight + 34)
        if (clockPreset === "mono_telemetry") return Math.max(124, monoCol.implicitHeight + 34)
        if (clockPreset === "minimal_pill") return Math.max(76, minimalRow.implicitHeight + 32)
        return Math.max(130, mainCol.implicitHeight + 36)
    }
    width: implicitWidth
    height: implicitHeight

    property string currentTimeString: ""
    property string hoursString: "00"
    property string minutesString: "00"
    property string currentDateString: ""
    property string dayUpperString: ""
    property string monthDayString: ""
    property string isoDateString: ""
    property string shortDateString: ""
    property string amPmString: ""
    property string secondsString: ""
    property string greetingString: "Welcome"

    property int clockIntervalMs: 1000

    function msToNextMinute() {
        var now = new Date()
        return Math.max(500, (60 - now.getSeconds()) * 1000 - now.getMilliseconds() + 30)
    }

    function updateTime() {
        var d = new Date()
        var h = d.getHours()
        var m = d.getMinutes()
        var s = d.getSeconds()

        // Greeting calculation
        if (h >= 5 && h < 12) root.greetingString = "Good Morning"
        else if (h >= 12 && h < 17) root.greetingString = "Good Afternoon"
        else if (h >= 17 && h < 22) root.greetingString = "Good Evening"
        else root.greetingString = "Good Night"

        // Format 12h vs 24h
        var hStr = ""
        var mStr = (m < 10 ? "0" : "") + m
        if (widgetConfig && widgetConfig.format_24h) {
            hStr = (h < 10 ? "0" : "") + h
            root.amPmString = ""
        } else {
            var h12 = (h % 12) || 12
            hStr = (h12 < 10 ? "0" : "") + h12
            root.amPmString = h >= 12 ? "PM" : "AM"
        }
        root.hoursString = hStr
        root.minutesString = mStr
        root.currentTimeString = hStr + ":" + mStr

        root.secondsString = (s < 10 ? "0" + s : s).toString()

        var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        var daysShort = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
        var months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
        var monthsShort = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        root.currentDateString = days[d.getDay()] + ", " + d.getDate() + " " + months[d.getMonth()] + " " + d.getFullYear()
        root.dayUpperString = days[d.getDay()].toUpperCase()
        root.monthDayString = (d.getDate() < 10 ? "0" + d.getDate() : d.getDate()) + " " + monthsShort[d.getMonth()].toUpperCase()
        root.shortDateString = daysShort[d.getDay()] + ", " + monthsShort[d.getMonth()] + " " + d.getDate()
        var moNum = (d.getMonth() + 1 < 10 ? "0" : "") + (d.getMonth() + 1)
        var dayNum = (d.getDate() < 10 ? "0" : "") + d.getDate()
        root.isoDateString = d.getFullYear() + "-" + moNum + "-" + dayNum + " // " + daysShort[d.getDay()]

        if (!(widgetConfig && widgetConfig.show_seconds)) {
            root.clockIntervalMs = root.msToNextMinute()
        }
    }

    Timer {
        interval: (root.widgetConfig && root.widgetConfig.show_seconds) ? 1000 : root.clockIntervalMs
        running: root.visible && (root.widgetConfig ? root.widgetConfig.enabled !== false : true)
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateTime()
    }

    // Glassmorphic Obsidian Background Card
    Rectangle {
        id: bgCard
        anchors.fill: parent
        radius: root.clockPreset === "minimal_pill" ? height / 2 : 20
        clip: true
        visible: (root.widgetConfig && root.widgetConfig.show_background !== undefined) ? (root.widgetConfig.show_background !== false) : true
        color: Theme.alpha(Theme.mix(Theme.background, Theme.surface, 0.45), (root.widgetConfig && root.widgetConfig.glass_opacity !== undefined) ? root.widgetConfig.glass_opacity : 0.65)
        border.width: 1
        border.color: Theme.alpha(Theme.foreground, 0.12)

        // Directional Top Specular Rim Reflection
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: root.clockPreset === "minimal_pill" ? 28 : 20
            anchors.rightMargin: root.clockPreset === "minimal_pill" ? 28 : 20
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.25; color: Theme.alpha(Theme.foreground, 0.10) }
                GradientStop { position: 0.50; color: Theme.alpha(Theme.foreground, 0.22) }
                GradientStop { position: 0.75; color: Theme.alpha(Theme.foreground, 0.10) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    // ── PRESET 1: CLASSIC ────────────────────────────────────────────────────
    Column {
        id: mainCol
        anchors.centerIn: parent
        spacing: 4
        visible: root.clockPreset === "classic"

        // Greeting Pill Header
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            visible: root.widgetConfig ? (root.widgetConfig.show_greeting !== false) : true

            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: Theme.accent
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.greetingString
                color: Theme.alpha(Theme.foreground, 0.70)
                font.family: "Outfit"
                font.pixelSize: 11
                font.weight: Font.Medium
                font.letterSpacing: 0.8
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Time Row (Clock + AM/PM + Seconds)
        Row {
            id: timeRow
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            Text {
                text: root.currentTimeString
                color: Theme.accent
                font.family: root.clockFontFamily
                font.pixelSize: root.clockFontSize
                font.weight: Font.Bold
                font.letterSpacing: 1.5
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                // AM / PM Pill
                Rectangle {
                    visible: root.amPmString.length > 0
                    width: amPmText.implicitWidth + 8
                    height: 18
                    radius: 9
                    color: Theme.alpha(Theme.accent, 0.18)
                    border.width: 1
                    border.color: Theme.alpha(Theme.accent, 0.35)

                    Text {
                        id: amPmText
                        anchors.centerIn: parent
                        text: root.amPmString
                        color: Theme.accent
                        font.family: "Outfit"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }

                // Seconds Text
                Text {
                    visible: root.widgetConfig ? (root.widgetConfig.show_seconds === true) : false
                    text: ":" + root.secondsString
                    color: Theme.alpha(Theme.foreground, 0.45)
                    font.family: "Outfit"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
            }
        }

        // Date String
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.widgetConfig ? (root.widgetConfig.show_date !== false) : true
            text: root.currentDateString
            color: Theme.alpha(Theme.foreground, 0.65)
            font.family: "Outfit"
            font.pixelSize: 12
            font.weight: Font.Medium
            font.letterSpacing: 0.5
        }
    }

    // ── PRESET 2: EDITORIAL SPLIT ────────────────────────────────────────────
    Column {
        id: splitWrapper
        anchors.centerIn: parent
        spacing: 4
        visible: root.clockPreset === "editorial_split"

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            visible: root.widgetConfig ? (root.widgetConfig.show_greeting !== false) : true

            Rectangle {
                width: 14
                height: 1
                color: Theme.accent
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.greetingString.toUpperCase()
                color: Theme.alpha(Theme.foreground, 0.68)
                font.family: "Outfit"
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 2.0
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 14
                height: 1
                color: Theme.accent
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            id: splitRow
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: root.hoursString
                    color: Theme.foreground
                    font.family: root.clockFontFamily
                    font.pixelSize: root.clockFontSize
                    font.weight: Font.Black
                    font.letterSpacing: -1.0
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: ":"
                    color: Theme.alpha(Theme.accent, 0.72)
                    font.family: root.clockFontFamily
                    font.pixelSize: Math.round(root.clockFontSize * 0.85)
                    font.weight: Font.Light
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -2
                }

                Text {
                    text: root.minutesString
                    color: Theme.accent
                    font.family: root.clockFontFamily
                    font.pixelSize: root.clockFontSize
                    font.weight: Font.Light
                    font.letterSpacing: 0.5
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Crisp Vertical Accent Rule
            Rectangle {
                width: 2
                height: Math.max(28, root.clockFontSize * 0.76)
                radius: 1
                visible: (root.widgetConfig ? (root.widgetConfig.show_date !== false) : true) || root.amPmString.length > 0 || Boolean(root.widgetConfig && root.widgetConfig.show_seconds)
                anchors.verticalCenter: parent.verticalCenter
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Theme.accent }
                    GradientStop { position: 1.0; color: Theme.alpha(Theme.primary, 0.25) }
                }
            }

            // Editorial Right Metadata Column
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                visible: (root.widgetConfig ? (root.widgetConfig.show_date !== false) : true) || root.amPmString.length > 0 || Boolean(root.widgetConfig && root.widgetConfig.show_seconds)

                Row {
                    spacing: 6
                    visible: root.amPmString.length > 0 || Boolean(root.widgetConfig && root.widgetConfig.show_seconds)

                    Text {
                        visible: root.amPmString.length > 0
                        text: root.amPmString
                        color: Theme.accent
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        font.letterSpacing: 1.2
                    }

                    Text {
                        visible: Boolean(root.widgetConfig && root.widgetConfig.show_seconds)
                        text: ":" + root.secondsString
                        color: Theme.alpha(Theme.foreground, 0.55)
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }
                }

                Text {
                    visible: root.widgetConfig ? (root.widgetConfig.show_date !== false) : true
                    text: root.dayUpperString
                    color: Theme.foreground
                    font.family: "Outfit"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.letterSpacing: 1.6
                }

                Text {
                    visible: root.widgetConfig ? (root.widgetConfig.show_date !== false) : true
                    text: root.monthDayString
                    color: Theme.alpha(Theme.foreground, 0.62)
                    font.family: "Outfit"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    font.letterSpacing: 1.4
                }
            }
        }
    }

    // ── PRESET 3: MONO TELEMETRY ─────────────────────────────────────────────
    Column {
        id: monoCol
        anchors.centerIn: parent
        spacing: 5
        visible: root.clockPreset === "mono_telemetry"

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            visible: (root.widgetConfig ? (root.widgetConfig.show_greeting !== false) : true) || root.amPmString.length > 0

            Text {
                text: "[ " + ((root.widgetConfig && root.widgetConfig.show_greeting !== false) ? root.greetingString.toUpperCase() : "LOCAL TIME") + " ]"
                color: Theme.alpha(Theme.accent, 0.85)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 1.2
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                visible: root.amPmString.length > 0
                text: "// " + root.amPmString
                color: Theme.alpha(Theme.foreground, 0.58)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.currentTimeString + ((root.widgetConfig && root.widgetConfig.show_seconds) ? (":" + root.secondsString) : "")
            color: Theme.foreground
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: root.clockFontSize
            font.weight: Font.DemiBold
            font.letterSpacing: 1.0
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.max(160, isoText.implicitWidth + 24)
            height: 1
            visible: root.widgetConfig ? (root.widgetConfig.show_date !== false) : true
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Theme.alpha(Theme.accent, 0.60) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Text {
            id: isoText
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.widgetConfig ? (root.widgetConfig.show_date !== false) : true
            text: root.isoDateString
            color: Theme.alpha(Theme.foreground, 0.65)
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            font.weight: Font.Medium
            font.letterSpacing: 1.2
        }
    }

    // ── PRESET 4: MINIMAL PILL ───────────────────────────────────────────────
    Row {
        id: minimalRow
        anchors.centerIn: parent
        spacing: 12
        visible: root.clockPreset === "minimal_pill"

        Rectangle {
            width: 7
            height: 7
            radius: 3.5
            color: Theme.accent
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.currentTimeString + ((root.widgetConfig && root.widgetConfig.show_seconds) ? (":" + root.secondsString) : "")
            color: Theme.foreground
            font.family: root.clockFontFamily
            font.pixelSize: Math.max(24, Math.round(root.clockFontSize * 0.72))
            font.weight: Font.Bold
            font.letterSpacing: 0.8
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.amPmString.length > 0
            text: root.amPmString
            color: Theme.accent
            font.family: "Outfit"
            font.pixelSize: 11
            font.weight: Font.Bold
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            visible: root.widgetConfig ? (root.widgetConfig.show_date !== false) : true
            width: 3
            height: 3
            radius: 1.5
            color: Theme.alpha(Theme.foreground, 0.40)
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.widgetConfig ? (root.widgetConfig.show_date !== false) : true
            text: root.shortDateString
            color: Theme.alpha(Theme.foreground, 0.72)
            font.family: "Outfit"
            font.pixelSize: 13
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
