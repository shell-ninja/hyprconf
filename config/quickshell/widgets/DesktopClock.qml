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
        glass_opacity: 0.65
    })
    property bool editMode: false

    readonly property real clockFontSize: (root.widgetConfig && root.widgetConfig.font_size !== undefined) ? root.widgetConfig.font_size : 44
    readonly property string clockFontFamily: (root.widgetConfig && root.widgetConfig.font_family) ? root.widgetConfig.font_family : "Outfit"

    implicitWidth: Math.max(360, timeRow.implicitWidth + 80)
    implicitHeight: Math.max(130, mainCol.implicitHeight + 36)
    width: implicitWidth
    height: implicitHeight

    property string currentTimeString: ""
    property string currentDateString: ""
    property string amPmString: ""
    property string secondsString: ""
    property string greetingString: "Welcome"

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
        if (widgetConfig && widgetConfig.format_24h) {
            root.currentTimeString = (h < 10 ? "0" + h : h) + ":" + (m < 10 ? "0" + m : m)
            root.amPmString = ""
        } else {
            var h12 = (h % 12) || 12
            root.currentTimeString = (h12 < 10 ? "0" + h12 : h12) + ":" + (m < 10 ? "0" + m : m)
            root.amPmString = h >= 12 ? "PM" : "AM"
        }

        root.secondsString = (s < 10 ? "0" + s : s).toString()

        var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        var months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
        root.currentDateString = days[d.getDay()] + ", " + d.getDate() + " " + months[d.getMonth()] + " " + d.getFullYear()
    }

    Timer {
        interval: 1000
        running: root.visible && (root.widgetConfig ? root.widgetConfig.enabled !== false : true)
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateTime()
    }

    // Glassmorphic Obsidian Background Card
    Rectangle {
        id: bgCard
        anchors.fill: parent
        radius: 20
        visible: (root.widgetConfig && root.widgetConfig.show_background !== undefined) ? (root.widgetConfig.show_background !== false) : true
        color: Theme.alpha(Theme.background, (root.widgetConfig && root.widgetConfig.glass_opacity !== undefined) ? root.widgetConfig.glass_opacity : 0.65)
        border.width: 1
        border.color: Theme.alpha(Theme.foreground, 0.12)

        // Top specular highlight
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            height: 1
            color: Theme.alpha(Theme.foreground, 0.14)
        }
    }

    // Interior Layout
    Column {
        id: mainCol
        anchors.centerIn: parent
        spacing: 4

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
}
