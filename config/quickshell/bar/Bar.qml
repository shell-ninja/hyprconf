import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "."

PanelWindow {
    id: bar

    // ── Theme tokens (Hyprconf dynamic Obsidian Glassmorphism) ─────
    property color surface: Theme.background
    property color pillColor: Theme.alpha(Theme.surface, 0.88)
    property color pillDark: Theme.accent
    property color pillBorder: Theme.alpha(Theme.accent, 0.40)
    property color fg: Theme.foreground
    property color fgDark: Theme.accent
    property color fgMuted: Theme.alpha(Theme.foreground, 0.60)
    property color accent: Theme.accent
    property color onPrimary: Theme.on_primary

    readonly property int barH: 44
    readonly property int edge: 12
    readonly property int innerRadius: 28

    // ── State ───────────────────────────────────────────────────────
    property bool caffeine: false
    property bool nightLight: false
    property int profile: 1                       // 0 performance, 1 balanced, 2 saver
    property real cpuUsage: 0
    property real memUsedGiB: 0
    property real memTotalGiB: 0
    property real diskUsedGiB: 0
    property real diskTotalGiB: 0
    property var lastCpu: null
    readonly property int activeWs: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    // ── Dynamic Weather State (hyprconf cache) ─────────────────────
    property string weatherTemp: "11"
    property string weatherCond: "Clear"
    property string weatherFeels: "9"
    property string weatherIconName: "moon"
    property string weatherCity: "New York"

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

    readonly property var player: {
        const l = Mpris.players.values
        return l && l.length > 0 ? l[0] : null
    }

    // ── Window setup ────────────────────────────────────────────────
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore           // space is reserved by the Reserve windows in shell.qml
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "bar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // Input only on the bar, the 12px edges and open popups; the centre is click-through.
    mask: Region {
        regions: [
            Region { item: topStrip },
            Region { item: leftStrip },
            Region { item: rightStrip },
            Region { item: bottomStrip },
            Region { item: launcherPop },
            Region { item: trayPop },
            Region { item: weatherPop },
            Region { item: perfPop },
            Region { item: clockPop },
            Region { item: notifPop },
            Region { item: togglesPop },
            Region { item: monitorPop },
            Region { item: volumePop },
            Region { item: powerPop }
        ]
    }

    // Frame outline with a rounded-rectangle hole (even-odd fill).
    readonly property string framePath: {
        const W = bar.width, H = bar.height
        const x0 = edge, y0 = barH
        const w = W - edge * 2, h = H - barH - edge
        const r = Math.max(0, Math.min(innerRadius, w / 2, h / 2))
        return "M 0 0 L " + W + " 0 L " + W + " " + H + " L 0 " + H + " Z "
            + "M " + (x0 + r) + " " + y0
            + " L " + (x0 + w - r) + " " + y0
            + " A " + r + " " + r + " 0 0 1 " + (x0 + w) + " " + (y0 + r)
            + " L " + (x0 + w) + " " + (y0 + h - r)
            + " A " + r + " " + r + " 0 0 1 " + (x0 + w - r) + " " + (y0 + h)
            + " L " + (x0 + r) + " " + (y0 + h)
            + " A " + r + " " + r + " 0 0 1 " + x0 + " " + (y0 + h - r)
            + " L " + x0 + " " + (y0 + r)
            + " A " + r + " " + r + " 0 0 1 " + (x0 + r) + " " + y0 + " Z"
    }

    // ── Services ────────────────────────────────────────────────────
    SystemClock { id: clock; precision: SystemClock.Minutes }
    IdleInhibitor { window: bar; enabled: bar.caffeine }
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    ListModel {
        id: notifs
        ListElement { title: "Network"; body: "Connected to Wi-Fi" }
        ListElement { title: "System"; body: "Updates are available" }
    }
    ListModel { id: clipModel }

    Process {
        id: statProc
        command: ["sh", "-c", "head -1 /proc/stat; awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{print t, t-a}' /proc/meminfo; df -B1 --output=size,used / | tail -1"]
        stdout: StdioCollector { onStreamFinished: bar.parseStats(text) }
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statProc.running = true
    }

    Process {
        id: clipProc
        command: ["sh", "-c", "cliphist list | head -n 12"]
        stdout: StdioCollector {
            onStreamFinished: {
                clipModel.clear()
                const lines = text.split("\n")
                for (const line of lines) {
                    const tab = line.indexOf("\t")
                    if (tab < 1)
                        continue
                    const cid = parseInt(line.slice(0, tab))
                    if (isNaN(cid))
                        continue
                    clipModel.append({ cid: cid, preview: line.slice(tab + 1) })
                }
            }
        }
    }

    Process {
        id: weatherProc
        command: ["sh", "-c", "cat " + Quickshell.env("HOME") + "/.hyprconf/hypr/.cache/weather_cache.json 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    if (data.temp_C) bar.weatherTemp = data.temp_C
                    if (data.condition) bar.weatherCond = data.condition.trim()
                    if (data.feels_like_C) bar.weatherFeels = data.feels_like_C
                    if (data.city) bar.weatherCity = data.city
                    const cat = (data.weather_category || "").toLowerCase()
                    const isDay = data.is_day !== false
                    if (cat.indexOf("rain") !== -1) bar.weatherIconName = "rain"
                    else if (cat.indexOf("cloud") !== -1) bar.weatherIconName = isDay ? "cloudSun" : "cloud"
                    else bar.weatherIconName = isDay ? "sun" : "moon"
                } catch (e) {}
            }
        }
    }
    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherProc.running = true
    }

    Process {
        id: profileProc
        command: ["powerprofilesctl", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim()
                if (p === "performance") bar.profile = 0
                else if (p === "power-saver") bar.profile = 2
                else bar.profile = 1
            }
        }
    }

    function parseStats(txt) {
        const lines = txt.trim().split("\n")
        if (lines.length < 3)
            return
        const f = lines[0].trim().split(/\s+/).slice(1).map(Number)
        const idle = f[3] + f[4]
        let total = 0
        for (let i = 0; i < 8 && i < f.length; i++)
            total += f[i]
        if (lastCpu) {
            const dt = total - lastCpu.total
            const di = idle - lastCpu.idle
            cpuUsage = dt > 0 ? Math.max(0, Math.min(1, 1 - di / dt)) : 0
        }
        lastCpu = { total: total, idle: idle }
        const m = lines[1].trim().split(/\s+/).map(Number)
        memTotalGiB = m[0] / 1048576
        memUsedGiB = m[1] / 1048576
        const d = lines[2].trim().split(/\s+/).map(Number)
        diskTotalGiB = d[0] / 1073741824
        diskUsedGiB = d[1] / 1073741824
    }

    function setVolume(v) {
        if (sink && sink.audio) {
            sink.audio.muted = false
            sink.audio.volume = Math.max(0, Math.min(1, v))
        }
    }

    function toggleMute() {
        if (sink && sink.audio)
            sink.audio.muted = !sink.audio.muted
    }

    function toggleNightLight() {
        nightLight = !nightLight
        Quickshell.execDetached(["sh", "-c", nightLight ? "pkill hyprsunset; hyprsunset -t 4000" : "pkill hyprsunset"])
    }

    function setProfile(i) {
        profile = i
        Quickshell.execDetached(["powerprofilesctl", "set", ["performance", "balanced", "power-saver"][i]])
    }

    // ════════════════════════════════════════════════════════════════
    Item {
        id: frame
        anchors.fill: parent

        // 4-sided matte frame with 4 rounded inner corners
        Shape {
            anchors.fill: parent
            layer.enabled: true
            layer.samples: 4
            ShapePath {
                fillColor: bar.surface
                strokeWidth: -1
                fillRule: ShapePath.OddEvenFill
                PathSvg { path: bar.framePath }
            }
        }


        // Hit areas (used by the input mask)
        Item { id: leftStrip; x: 0; y: bar.barH; width: bar.edge; height: parent.height - bar.barH }
        Item { id: rightStrip; x: parent.width - bar.edge; y: bar.barH; width: bar.edge; height: parent.height - bar.barH }
        Item { id: bottomStrip; x: 0; y: parent.height - bar.edge; width: parent.width; height: bar.edge }

        // ── Top bar ────────────────────────────────────────────────
        Item {
            id: topStrip
            x: 0
            y: 0
            width: parent.width
            height: bar.barH

            // Left zone
            RowLayout {
                anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                spacing: 8

                Pill {
                    id: launcherPill
                    flat: true
                    hPad: 4
                    SvgIcon {
                        name: "grid"
                        size: 20
                        color: launcherPill.hovered ? Theme.accent : Theme.foreground
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }
                }

                Pill {
                    id: trayPill
                    hPad: 10
                    spacing: 6
                    SvgIcon { name: "wifi"; size: 14; color: Theme.foreground }
                    SvgIcon {
                        name: "chevronDown"
                        size: 12
                        color: trayPill.hovered || trayPop.shown ? Theme.accent : Theme.alpha(Theme.foreground, 0.80)
                        rotation: trayPop.shown ? 180 : 0
                        Behavior on rotation {
                            NumberAnimation {
                                duration: 280
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.4
                            }
                        }
                    }
                }

                Pill {
                    id: wsPill
                    hPad: 5
                    Item {
                        implicitWidth: 5 * 24
                        implicitHeight: 20

                        Rectangle {
                            width: 24
                            height: 20
                            radius: 10
                            color: bar.pillDark
                            visible: bar.activeWs >= 1 && bar.activeWs <= 5
                            x: (Math.min(Math.max(bar.activeWs, 1), 5) - 1) * 24
                            Behavior on x {
                                NumberAnimation {
                                    duration: 320
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.35
                                }
                            }
                        }

                        Repeater {
                            model: 5
                            delegate: Item {
                                required property int index
                                x: index * 24
                                width: 24
                                height: 20

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 20
                                    height: 18
                                    radius: 9
                                    color: (index + 1) === bar.activeWs ? "transparent" : (wsMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : "transparent")
                                    scale: wsMouse.containsMouse ? (wsMouse.pressed ? 0.88 : 1.12) : 1.0
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 200
                                            easing.type: Easing.OutBack
                                            easing.overshoot: 1.4
                                        }
                                    }
                                }

                                MonoText {
                                    anchors.centerIn: parent
                                    text: index + 1
                                    font.weight: (index + 1) === bar.activeWs ? Font.Bold : Font.Normal
                                    color: (index + 1) === bar.activeWs ? bar.onPrimary : (wsMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.70))
                                    scale: wsMouse.containsMouse ? (wsMouse.pressed ? 0.90 : 1.15) : 1.0
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 200
                                            easing.type: Easing.OutBack
                                            easing.overshoot: 1.4
                                        }
                                    }
                                }

                                MouseArea {
                                    id: wsMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "workspace", (index + 1).toString()])
                                }
                            }
                        }
                    }
                    WheelHandler {
                        onWheel: e => {
                            const cur = bar.activeWs;
                            const nextWs = e.angleDelta.y < 0 ? Math.min(5, cur + 1) : Math.max(1, cur - 1);
                            if (nextWs !== cur) {
                                Quickshell.execDetached(["hyprctl", "dispatch", "workspace", nextWs.toString()]);
                            }
                        }
                    }
                }

                Pill {
                    id: weatherPill
                    SvgIcon { name: bar.weatherIconName; size: 15; color: weatherPill.hovered ? Theme.accent : Theme.foreground }
                    MonoText { text: bar.weatherTemp + "°C"; color: Theme.foreground }
                }
            }

            // Center zone
            RowLayout {
                anchors.centerIn: parent
                spacing: 8

                Pill {
                    id: perfPill
                    hPad: 10
                    SvgIcon {
                        name: bar.profile === 0 ? "bolt" : (bar.profile === 2 ? "leaf" : "gauge")
                        size: 15
                        color: perfPill.hovered ? Theme.accent : (bar.profile === 0 ? Theme.accent : (bar.profile === 2 ? "#73d216" : Theme.foreground))
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }
                }

                Pill {
                    id: clockPill
                    MonoText { text: Qt.formatDateTime(clock.date, "hh : mm AP \u2022 ddd").toUpperCase(); color: Theme.foreground }
                }

                Pill {
                    id: notifPill
                    hPad: 10
                    Item {
                        implicitWidth: 16
                        implicitHeight: 16
                        SvgIcon { anchors.fill: parent; name: "bell"; size: 16; color: notifPill.hovered ? Theme.accent : Theme.foreground }
                        Rectangle {
                            visible: notifs.count > 0
                            x: 9
                            y: -6
                            width: 12
                            height: 12
                            radius: 6
                            color: bar.pillDark
                            scale: notifs.count > 0 ? 1.0 : 0.0
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.5
                                }
                            }
                            MonoText { anchors.centerIn: parent; text: notifs.count; font.pixelSize: 9; color: bar.onPrimary }
                        }
                    }
                }
            }

            // Right zone
            RowLayout {
                anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                spacing: 8

                Pill {
                    id: togglesPill
                    hPad: 6
                    spacing: 4

                    Rectangle {
                        id: caffeineBtn
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: 13
                        color: bar.caffeine ? Theme.accent : (caffeineMouse.containsMouse ? Theme.alpha(Theme.surface, 0.95) : "transparent")
                        scale: caffeineMouse.containsMouse ? (caffeineMouse.pressed ? 0.88 : 1.15) : 1.0
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.45
                            }
                        }
                        SvgIcon {
                            anchors.centerIn: parent
                            name: "coffee"
                            size: 14
                            color: bar.caffeine ? bar.onPrimary : (caffeineMouse.containsMouse ? Theme.accent : Theme.foreground)
                        }
                        MouseArea {
                            id: caffeineMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bar.caffeine = !bar.caffeine
                        }
                    }

                    Rectangle {
                        id: nightLightBtn
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: 13
                        color: bar.nightLight ? Theme.accent : (nightLightMouse.containsMouse ? Theme.alpha(Theme.surface, 0.95) : "transparent")
                        scale: nightLightMouse.containsMouse ? (nightLightMouse.pressed ? 0.88 : 1.15) : 1.0
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.45
                            }
                        }
                        SvgIcon {
                            anchors.centerIn: parent
                            name: "moonStar"
                            size: 14
                            color: bar.nightLight ? bar.onPrimary : (nightLightMouse.containsMouse ? Theme.accent : Theme.foreground)
                        }
                        MouseArea {
                            id: nightLightMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bar.toggleNightLight()
                        }
                    }

                    Rectangle {
                        id: clipboardBtn
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: 13
                        color: clipMouse.containsMouse ? Theme.alpha(Theme.surface, 0.95) : "transparent"
                        scale: clipMouse.containsMouse ? (clipMouse.pressed ? 0.88 : 1.15) : 1.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.45
                            }
                        }
                        SvgIcon {
                            anchors.centerIn: parent
                            name: "clipboard"
                            size: 14
                            color: clipMouse.containsMouse ? Theme.accent : Theme.foreground
                        }
                        MouseArea {
                            id: clipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: clipProc.running = true
                        }
                    }
                }

                Pill {
                    id: monitorPill
                    SvgIcon { name: "gauge"; size: 15; color: monitorPill.hovered ? Theme.accent : Theme.foreground }
                    MonoText { text: bar.memUsedGiB.toFixed(1) + "/" + Math.round(bar.memTotalGiB) + " GiB"; color: Theme.foreground }
                }

                Pill {
                    id: volumePill
                    SvgIcon { name: bar.muted || bar.volume <= 0 ? "volumeMute" : "volume"; size: 15; color: bar.muted ? Theme.error : (volumePill.hovered ? Theme.accent : Theme.foreground) }
                    MonoText { text: bar.muted ? "MUTED" : Math.round(bar.volume * 100) + "%"; color: bar.muted ? Theme.error : Theme.foreground }
                    WheelHandler { onWheel: e => bar.setVolume(bar.volume + (e.angleDelta.y > 0 ? 0.05 : -0.05)) }
                }

                Pill {
                    id: powerPill
                    hPad: 8
                    SvgIcon { name: "power"; size: 15; color: powerPill.hovered ? Theme.error : Theme.foreground }
                }
            }
        }

        // ════════════════════════════════════════════════════════════
        // Hover popups (flush to the bar, same surface colour)
        // ════════════════════════════════════════════════════════════

        // ── Launcher ────────────────────────────────────────────────
        BarPopup {
            id: launcherPop
            trigger: launcherPill
            align: "left"
            popupWidth: 340
            surface: bar.surface

            property var apps: {
                const q = searchInput.text.trim().toLowerCase()
                const list = DesktopEntries.applications.values
                const out = []
                for (let i = 0; i < list.length; i++) {
                    const a = list[i]
                    if (!a.noDisplay && a.name.toLowerCase().indexOf(q) !== -1)
                        out.push(a)
                }
                out.sort((x, y) => x.name.localeCompare(y.name))
                return out
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 38
                radius: 19
                color: bar.pillColor

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 8
                    SvgIcon { name: "search"; size: 16 }
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 20
                        MonoText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: searchInput.text === ""
                            text: "Search apps"
                            color: Theme.muted
                            font.pixelSize: 13
                        }
                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            color: bar.fg
                            font.family: "JetBrainsMono Nerd Font, monospace"
                            font.pixelSize: 13
                            clip: true
                            selectByMouse: true
                            onAccepted: {
                                if (launcherPop.apps.length > 0) {
                                    launcherPop.apps[0].execute()
                                    searchInput.text = ""
                                    launcherPop.close()
                                }
                            }
                        }
                    }
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: 252
                clip: true
                spacing: 3
                boundsBehavior: Flickable.StopAtBounds
                model: launcherPop.apps

                delegate: Rectangle {
                    id: appRow
                    required property var modelData
                    width: ListView.view.width
                    height: 36
                    radius: 12
                    color: appMouse.containsMouse ? Theme.alpha(Theme.accent, 0.22) : "transparent"
                    scale: appMouse.containsMouse ? (appMouse.pressed ? 0.96 : 1.02) : 1.0
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.30
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10
                        SvgIcon {
                            name: "app"
                            size: 18
                            color: appMouse.containsMouse ? Theme.accent : Theme.foreground
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        MonoText {
                            Layout.fillWidth: true
                            text: appRow.modelData.name
                            color: appMouse.containsMouse ? Theme.foreground : Theme.alpha(Theme.foreground, 0.9)
                            elide: Text.ElideRight
                        }
                    }
                    MouseArea {
                        id: appMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            appRow.modelData.execute()
                            searchInput.text = ""
                            launcherPop.close()
                        }
                    }
                }
            }
        }

        // ── Tray chevron ────────────────────────────────────────────
        BarPopup {
            id: trayPop
            trigger: trayPill
            popupWidth: 300
            surface: bar.surface

            Row {
                spacing: 6
                Rectangle { width: 5; height: 5; radius: 2.5; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                MonoText { text: "SHORTCUTS"; color: Theme.alpha(Theme.foreground, 0.90); font.pixelSize: 10; font.bold: true; font.letterSpacing: 0.8 }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; icon: "wifi"; label: "Wi-Fi"; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
                ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; icon: "bluetooth"; label: "BT"; onClicked: Quickshell.execDetached(["blueman-manager"]) }
                ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; icon: "folder"; label: "Files"; onClicked: Quickshell.execDetached(["xdg-open", Quickshell.env("HOME")]) }
                ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; icon: "camera"; label: "Shot"; onClicked: Quickshell.execDetached(["sh", "-c", "grim -g \"$(slurp)\" - | wl-copy"]) }
            }

            Row {
                spacing: 6
                Rectangle { width: 5; height: 5; radius: 2.5; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                MonoText { text: "BACKGROUND TRAY"; color: Theme.alpha(Theme.foreground, 0.90); font.pixelSize: 10; font.bold: true; font.letterSpacing: 0.8 }
            }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: SystemTray.items
                    delegate: Rectangle {
                        id: trayItem
                        required property var modelData
                        width: trayRow.implicitWidth + 20
                        height: 32
                        radius: 12
                        color: trayMouse.containsMouse ? Theme.alpha(Theme.accent, 0.25) : bar.pillColor
                        border.width: trayMouse.containsMouse ? 1 : 0
                        border.color: Theme.alpha(Theme.accent, 0.45)
                        scale: trayMouse.containsMouse ? (trayMouse.pressed ? 0.94 : 1.05) : 1.0
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.35
                            }
                        }

                        RowLayout {
                            id: trayRow
                            anchors.centerIn: parent
                            spacing: 7
                            SvgIcon { name: "app"; size: 16; color: trayMouse.containsMouse ? Theme.accent : Theme.foreground }
                            MonoText { text: trayItem.modelData.title !== "" ? trayItem.modelData.title : trayItem.modelData.id; font.pixelSize: 11 }
                        }
                        MouseArea {
                            id: trayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => mouse.button === Qt.RightButton ? trayItem.modelData.secondaryActivate() : trayItem.modelData.activate()
                        }
                    }
                }
            }
            MonoText {
                visible: SystemTray.items.values.length === 0
                text: "No background items"
                color: Theme.muted
                font.pixelSize: 11
            }
        }

        // ── Weather ─────────────────────────────────────────────────
        BarPopup {
            id: weatherPop
            trigger: weatherPill
            popupWidth: 340
            surface: bar.surface

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                SvgIcon { name: bar.weatherIconName; size: 38; color: Theme.foreground }
                ColumnLayout {
                    spacing: 2
                    MonoText { text: bar.weatherCity; color: Theme.alpha(Theme.foreground, 0.75); font.pixelSize: 11; font.bold: true }
                    MonoText { text: bar.weatherTemp + "°C"; color: Theme.foreground; font.pixelSize: 22; font.bold: true }
                    MonoText { text: bar.weatherCond + " \u2022 Feels like " + bar.weatherFeels + "°C"; color: Theme.alpha(Theme.foreground, 0.70); font.pixelSize: 11 }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: [
                        { d: "TODAY", i: bar.weatherIconName, t: bar.weatherTemp },
                        { d: "TUE", i: "cloudSun", t: "12" },
                        { d: "WED", i: "sun", t: "14" },
                        { d: "THU", i: "rain", t: "10" },
                        { d: "FRI", i: "cloud", t: "11" }
                    ]
                    delegate: Rectangle {
                        id: dayCard
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: 84
                        radius: 14
                        color: dayMouse.containsMouse ? Theme.alpha(Theme.accent, 0.22) : bar.pillColor
                        border.width: dayMouse.containsMouse ? 1 : 0
                        border.color: Theme.alpha(Theme.accent, 0.45)
                        scale: dayMouse.containsMouse ? 1.05 : 1.0
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.35
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            MonoText { Layout.alignment: Qt.AlignHCenter; text: dayCard.modelData.d; font.pixelSize: 10; color: Theme.muted }
                            SvgIcon { Layout.alignment: Qt.AlignHCenter; name: dayCard.modelData.i; size: 22; color: dayMouse.containsMouse ? Theme.accent : Theme.foreground }
                            MonoText { Layout.alignment: Qt.AlignHCenter; text: dayCard.modelData.t + "°C" }
                        }
                        MouseArea {
                            id: dayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }
            }
        }

        // ── Power profile ───────────────────────────────────────────
        BarPopup {
            id: perfPop
            trigger: perfPill
            popupWidth: 320
            surface: bar.surface

            Row {
                spacing: 6
                Rectangle { width: 5; height: 5; radius: 2.5; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                MonoText { text: "POWER PROFILE"; color: Theme.alpha(Theme.foreground, 0.90); font.pixelSize: 10; font.bold: true; font.letterSpacing: 0.8 }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; icon: "bolt"; label: "Performance"; active: bar.profile === 0; onClicked: bar.setProfile(0) }
                ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; icon: "gauge"; label: "Balanced"; active: bar.profile === 1; onClicked: bar.setProfile(1) }
                ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; icon: "leaf"; label: "Power Saver"; active: bar.profile === 2; onClicked: bar.setProfile(2) }
            }
        }

        // ── Clock / calendar / media ────────────────────────────────
        BarPopup {
            id: clockPop
            trigger: clockPill
            popupWidth: 360
            surface: bar.surface

            property var cells: {
                const d = clock.date
                const y = d.getFullYear(), m = d.getMonth()
                const first = (new Date(y, m, 1).getDay() + 6) % 7   // Monday first
                const n = new Date(y, m + 1, 0).getDate()
                const out = []
                for (let i = 0; i < first; i++)
                    out.push(0)
                for (let i = 1; i <= n; i++)
                    out.push(i)
                return out
            }

            MonoText {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(clock.date, "MMMM yyyy").toUpperCase()
                color: Theme.foreground
                font.bold: true
                font.pixelSize: 13
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 7
                rowSpacing: 2
                columnSpacing: 2

                Repeater {
                    model: ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]
                    delegate: MonoText {
                        required property string modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: Theme.muted
                        font.pixelSize: 10
                        opacity: 0.8
                    }
                }
                Repeater {
                    model: clockPop.cells
                    delegate: Item {
                        id: dayCell
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: 28

                        Rectangle {
                            anchors.centerIn: parent
                            width: 28
                            height: 28
                            radius: 14
                            color: dayCell.modelData === clock.date.getDate() ? bar.pillDark : (cellMouse.containsMouse ? Theme.alpha(Theme.surface, 0.95) : "transparent")
                            scale: cellMouse.containsMouse ? 1.15 : 1.0
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 180
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.4
                                }
                            }
                            visible: dayCell.modelData > 0
                        }
                        MonoText {
                            anchors.centerIn: parent
                            text: dayCell.modelData > 0 ? dayCell.modelData : ""
                            color: dayCell.modelData === clock.date.getDate() ? bar.onPrimary : (cellMouse.containsMouse ? Theme.foreground : bar.fg)
                            font.bold: dayCell.modelData === clock.date.getDate()
                        }
                        MouseArea {
                            id: cellMouse
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 76
                radius: 16
                color: bar.pillColor
                border.width: 0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        MonoText {
                            Layout.fillWidth: true
                            text: bar.player ? bar.player.trackTitle : "Nothing playing"
                            elide: Text.ElideRight
                            font.bold: true
                            color: Theme.foreground
                        }
                        MonoText {
                            Layout.fillWidth: true
                            text: bar.player ? bar.player.trackArtist : ""
                            elide: Text.ElideRight
                            font.pixelSize: 11
                            color: Theme.muted
                        }
                    }

                    Repeater {
                        model: ["prev", "toggle", "next"]
                        delegate: Item {
                            id: mediaBtn
                            required property string modelData
                            implicitWidth: 32
                            implicitHeight: 32
                            scale: mediaMouse.containsMouse ? (mediaMouse.pressed ? 0.88 : 1.15) : 1.0
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.4
                                }
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: 16
                                color: mediaMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.surface, 0.85)
                                border.width: mediaMouse.containsMouse ? 1 : 0
                                border.color: Theme.accent
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            SvgIcon {
                                anchors.centerIn: parent
                                size: 14
                                color: mediaMouse.containsMouse ? Theme.on_primary : Theme.foreground
                                name: mediaBtn.modelData === "toggle" ? (bar.player && bar.player.isPlaying ? "pause" : "play") : mediaBtn.modelData
                            }
                            MouseArea {
                                id: mediaMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!bar.player)
                                        return
                                    if (mediaBtn.modelData === "prev") bar.player.previous()
                                    else if (mediaBtn.modelData === "next") bar.player.next()
                                    else bar.player.togglePlaying()
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Notifications ───────────────────────────────────────────
        BarPopup {
            id: notifPop
            trigger: notifPill
            popupWidth: 340
            surface: bar.surface

            RowLayout {
                Layout.fillWidth: true
                Row {
                    Layout.fillWidth: true
                    spacing: 6
                    Rectangle { width: 5; height: 5; radius: 2.5; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                    MonoText { text: "NOTIFICATIONS"; color: Theme.alpha(Theme.foreground, 0.90); font.pixelSize: 10; font.bold: true; font.letterSpacing: 0.8 }
                }
                Rectangle {
                    implicitWidth: clearLabel.implicitWidth + 20
                    implicitHeight: 24
                    radius: 12
                    color: clearMouse.containsMouse ? Theme.alpha(Theme.error, 0.30) : bar.pillColor
                    border.width: clearMouse.containsMouse ? 1 : 0
                    border.color: Theme.error
                    scale: clearMouse.containsMouse ? (clearMouse.pressed ? 0.92 : 1.06) : 1.0
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.4
                        }
                    }
                    MonoText {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "Clear All"
                        font.pixelSize: 11
                        color: clearMouse.containsMouse ? Theme.error : Theme.foreground
                    }
                    MouseArea { id: clearMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: notifs.clear() }
                }
            }

            Repeater {
                model: notifs
                delegate: Rectangle {
                    id: card
                    required property int index
                    required property string title
                    required property string body
                    Layout.fillWidth: true
                    implicitHeight: 56
                    radius: 14
                    color: bar.pillColor
                    border.width: 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 10
                        spacing: 8
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            MonoText { text: card.title; font.bold: true; color: Theme.foreground }
                            MonoText { Layout.fillWidth: true; text: card.body; font.pixelSize: 11; elide: Text.ElideRight; color: Theme.alpha(Theme.foreground, 0.75) }
                        }
                        Item {
                            implicitWidth: 24
                            implicitHeight: 24
                            scale: xMouse.containsMouse ? (xMouse.pressed ? 0.88 : 1.20) : 1.0
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.4
                                }
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                color: xMouse.containsMouse ? Theme.alpha(Theme.error, 0.30) : bar.pillDark
                                border.width: 1
                                border.color: xMouse.containsMouse ? Theme.error : "transparent"
                            }
                            SvgIcon { anchors.centerIn: parent; name: "x"; size: 12; color: xMouse.containsMouse ? Theme.error : bar.onPrimary }
                            MouseArea { id: xMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: notifs.remove(card.index) }
                        }
                    }
                }
            }

            MonoText {
                visible: notifs.count === 0
                text: "No notifications"
                color: Theme.muted
                font.pixelSize: 11
            }
        }

        // ── Quick toggles ───────────────────────────────────────────
        BarPopup {
            id: togglesPop
            trigger: togglesPill
            popupWidth: 340
            surface: bar.surface
            onShownChanged: if (shown) clipProc.running = true

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; icon: "coffee"; label: "Caffeine"; active: bar.caffeine; onClicked: bar.caffeine = !bar.caffeine }
                ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; icon: "moonStar"; label: "Night Light"; active: bar.nightLight; onClicked: bar.toggleNightLight() }
            }

            Row {
                spacing: 6
                Rectangle { width: 5; height: 5; radius: 2.5; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                MonoText { text: "CLIPBOARD HISTORY"; color: Theme.alpha(Theme.foreground, 0.90); font.pixelSize: 10; font.bold: true; font.letterSpacing: 0.8 }
            }
            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(30, Math.min(clipModel.count * 34, 170))
                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                model: clipModel

                delegate: Rectangle {
                    id: clipRow
                    required property int cid
                    required property string preview
                    width: ListView.view.width
                    height: 32
                    radius: 10
                    color: clipMouse.containsMouse ? Theme.alpha(Theme.accent, 0.22) : "transparent"
                    scale: clipMouse.containsMouse ? (clipMouse.pressed ? 0.96 : 1.02) : 1.0
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.30
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8
                        SvgIcon { name: "clipboard"; size: 14; color: clipMouse.containsMouse ? Theme.accent : Theme.foreground }
                        MonoText { Layout.fillWidth: true; text: clipRow.preview; elide: Text.ElideRight; font.pixelSize: 11; color: clipMouse.containsMouse ? Theme.foreground : Theme.alpha(Theme.foreground, 0.85) }
                    }
                    MouseArea {
                        id: clipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["sh", "-c", "cliphist decode " + clipRow.cid + " | wl-copy"])
                    }
                }
            }
            MonoText {
                visible: clipModel.count === 0
                text: "Empty (needs cliphist)"
                color: Theme.muted
                font.pixelSize: 11
            }
        }

        // ── System monitor ──────────────────────────────────────────
        BarPopup {
            id: monitorPop
            trigger: monitorPill
            popupWidth: 320
            surface: bar.surface

            Row {
                spacing: 6
                Rectangle { width: 5; height: 5; radius: 2.5; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                MonoText { text: "SYSTEM"; color: Theme.alpha(Theme.foreground, 0.90); font.pixelSize: 10; font.bold: true; font.letterSpacing: 0.8 }
            }
            Repeater {
                model: 3
                delegate: ColumnLayout {
                    id: meter
                    required property int index
                    readonly property real frac: index === 0 ? bar.cpuUsage
                        : index === 1 ? (bar.memTotalGiB > 0 ? bar.memUsedGiB / bar.memTotalGiB : 0)
                        : (bar.diskTotalGiB > 0 ? bar.diskUsedGiB / bar.diskTotalGiB : 0)
                    Layout.fillWidth: true
                    spacing: 5

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        SvgIcon { name: ["cpu", "ram", "disk"][meter.index]; size: 16; color: Theme.foreground }
                        MonoText { Layout.fillWidth: true; text: ["CPU", "RAM", "Disk /"][meter.index]; color: Theme.foreground }
                        MonoText { text: Math.round(meter.frac * 100) + "%"; color: Theme.foreground; font.bold: true }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 8
                        radius: 4
                        color: Theme.alpha(Theme.surface, 0.85)
                        border.width: 0
                        Rectangle {
                            width: parent.width * meter.frac
                            height: parent.height
                            radius: 4
                            color: Theme.accent
                            Behavior on width {
                                NumberAnimation {
                                    duration: 350
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.15
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Volume ──────────────────────────────────────────────────
        BarPopup {
            id: volumePop
            trigger: volumePill
            popupWidth: 320
            surface: bar.surface

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    implicitWidth: 38
                    implicitHeight: 38
                    radius: 19
                    color: bar.muted ? Theme.alpha(Theme.error, 0.35) : (muteMouse.containsMouse ? Theme.alpha(Theme.surface, 0.95) : bar.pillColor)
                    border.width: bar.muted ? 1 : (muteMouse.containsMouse ? 1 : 0)
                    border.color: bar.muted ? Theme.error : Theme.accent
                    scale: muteMouse.containsMouse ? (muteMouse.pressed ? 0.88 : 1.12) : 1.0
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.4
                        }
                    }
                    SvgIcon {
                        anchors.centerIn: parent
                        name: bar.muted || bar.volume <= 0 ? "volumeMute" : "volume"
                        size: 18
                        color: bar.muted ? Theme.error : (muteMouse.containsMouse ? Theme.accent : Theme.foreground)
                    }
                    MouseArea { id: muteMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: bar.toggleMute() }
                }

                Item {
                    id: track
                    Layout.fillWidth: true
                    implicitHeight: 28
                    readonly property real knob: 18

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 8
                        radius: 4
                        color: Theme.alpha(Theme.surface, 0.85)
                        border.width: 0
                        Rectangle {
                            width: track.knob / 2 + bar.volume * (track.width - track.knob)
                            height: parent.height
                            radius: 4
                            color: bar.muted ? Theme.muted : Theme.accent
                        }
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: bar.volume * (track.width - track.knob)
                        width: track.knob
                        height: track.knob
                        radius: track.knob / 2
                        color: Theme.foreground
                        border.width: 2
                        border.color: bar.muted ? Theme.muted : Theme.accent
                        scale: trackMouse.pressed ? 1.30 : (trackMouse.containsMouse ? 1.15 : 1.0)
                        Behavior on scale {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.4
                            }
                        }
                    }
                    MouseArea {
                        id: trackMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: mouse => bar.setVolume((mouse.x - track.knob / 2) / (track.width - track.knob))
                        onPositionChanged: mouse => { if (pressed) bar.setVolume((mouse.x - track.knob / 2) / (track.width - track.knob)) }
                    }
                }

                MonoText {
                    text: bar.muted ? "MUTED" : Math.round(bar.volume * 100) + "%"
                    color: bar.muted ? Theme.error : Theme.foreground
                    Layout.preferredWidth: 42
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        // ── Power session ───────────────────────────────────────────
        BarPopup {
            id: powerPop
            trigger: powerPill
            align: "right"
            popupWidth: 300
            surface: bar.surface

            Row {
                spacing: 6
                Rectangle { width: 5; height: 5; radius: 2.5; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                MonoText { text: "SESSION"; color: Theme.alpha(Theme.foreground, 0.90); font.pixelSize: 10; font.bold: true; font.letterSpacing: 0.8 }
            }
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 8
                columnSpacing: 8
                ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; vertical: false; icon: "lock"; label: "Lock"; onClicked: Quickshell.execDetached(["loginctl", "lock-session"]) }
                ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; vertical: false; icon: "logout"; label: "Logout"; confirm: true; onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "exit"]) }
                ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; vertical: false; icon: "reboot"; label: "Reboot"; confirm: true; onClicked: Quickshell.execDetached(["systemctl", "reboot"]) }
                ActionButton { Layout.fillWidth: true; Layout.preferredWidth: 1; vertical: false; icon: "power"; label: "Shutdown"; confirm: true; onClicked: Quickshell.execDetached(["systemctl", "poweroff"]) }
            }
        }
    }
}
