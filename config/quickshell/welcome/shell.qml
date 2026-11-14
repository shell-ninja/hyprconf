//@ pragma Env QS_NO_RELOAD_POPUP=1
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "."

FloatingWindow {
    id: window
    title: "Welcome to Hyprconf"
    implicitWidth: 920
    implicitHeight: 660
    color: "transparent"
    onClosed: Qt.quit()

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    property string versionTag: "qs-v1.0.2"
    property var whatsNewVersions: []
    property int selectedWhatsNewIdx: 0
    readonly property string whatsNewPath: {
        var u = Qt.resolvedUrl("whatsnew.json").toString()
        if (u.indexOf("file://") === 0) return decodeURIComponent(u.slice(7))
        return homeDir + "/.hyprconf/quickshell/welcome/whatsnew.json"
    }

    // Circular-masked Shell Ninja badge shared by navbar and overview hero.
    component BrandLogoBadge : Item {
        id: badgeRoot
        property int badgeSize: 32
        property int imageMargin: 2
        property color ringColor: Theme.alpha(Theme.accent, 0.40)

        readonly property int maskSize: Math.max(16, badgeSize - 2)

        implicitWidth: badgeSize
        implicitHeight: badgeSize
        width: badgeSize
        height: badgeSize

        Rectangle {
            id: logoMask
            anchors.centerIn: parent
            width: badgeRoot.maskSize
            height: badgeRoot.maskSize
            radius: badgeRoot.maskSize / 2
            color: "#ffffff"
            layer.enabled: true
            visible: false
        }

        Rectangle {
            id: logoSource
            anchors.centerIn: parent
            width: badgeRoot.maskSize
            height: badgeRoot.maskSize
            color: "#090516"
            layer.enabled: true
            visible: false

            Image {
                anchors.fill: parent
                anchors.margins: badgeRoot.imageMargin
                source: window.brandLogoPath
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                sourceSize: Qt.size(badgeRoot.maskSize * 2, badgeRoot.maskSize * 2)
            }
        }

        MultiEffect {
            anchors.centerIn: parent
            width: badgeRoot.maskSize
            height: badgeRoot.maskSize
            source: logoSource
            autoPaddingEnabled: false
            maskEnabled: true
            maskSource: logoMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }

        Rectangle {
            z: 2
            anchors.fill: parent
            radius: badgeRoot.badgeSize / 2
            color: "transparent"
            border.color: badgeRoot.ringColor
            border.width: 1
        }
    }

    // Shared reminder banner directing upgrading users to merge keybinds-updated.lua manually.
    component KeybindUpdateBanner : Rectangle {
        id: kbBanner
        property string headline: "Manual Keybind Update Required"
        property string bodyText: "Your ~/.local/share/hyprconf/keybinds.lua is preserved across updates. Copy new version binds from ~/.hyprconf/hypr/configs/keybinds-updated.lua into your keybinds.lua manually to enable new features."

        Layout.fillWidth: true
        implicitHeight: bannerRow.implicitHeight + 16
        radius: 10
        color: Theme.mix(Theme.glassCard, Theme.accent, 0.08)
        border.color: Theme.alpha(Theme.accent, 0.34)
        border.width: 1

        RowLayout {
            id: bannerRow
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 12
                rightMargin: 12
            }
            spacing: 10

            Rectangle {
                width: 28
                height: 28
                radius: 7
                color: Theme.alpha(Theme.accent, 0.16)
                Image {
                    anchors.centerIn: parent
                    width: 15
                    height: 15
                    source: window.keyboardSvg
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: kbBanner.headline
                    font.pixelSize: 11
                    font.bold: true
                    font.family: "Inter"
                    color: Theme.foreground
                }

                Text {
                    Layout.fillWidth: true
                    text: kbBanner.bodyText
                    font.pixelSize: 10
                    font.family: "Inter"
                    color: Theme.alpha(Theme.foreground, 0.72)
                    wrapMode: Text.WordWrap
                }
            }

            Rectangle {
                implicitWidth: openBtnText.implicitWidth + 16
                height: 26
                radius: 7
                color: openBtnMa.containsMouse ? Theme.alpha(Theme.accent, 0.28) : Theme.alpha(Theme.accent, 0.16)
                border.color: Theme.alpha(Theme.accent, 0.42)
                border.width: 1
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    id: openBtnText
                    anchors.centerIn: parent
                    text: "Open keybinds-updated.lua"
                    font.pixelSize: 10
                    font.bold: true
                    font.family: "JetBrains Mono, monospace"
                    color: Theme.accent
                }

                MouseArea {
                    id: openBtnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached([
                        "xdg-open",
                        window.homeDir + "/.hyprconf/hypr/configs/keybinds-updated.lua"
                    ])
                }
            }
        }
    }

    // Logo & Avatar paths
    readonly property string brandLogoPath: "file://" + homeDir + "/.hyprconf/hypr/.cache/shell-ninja.png"
    readonly property string faceAvatarPath: "file://" + homeDir + "/.hyprconf/hypr/.cache/.face"

    // ── STATE VARIABLES ──────────────────────────────────────────────────────
    property int activePage: 0 // 0: Overview, 1: What's New, 2: Shortcuts, 3: Apps, 4: Finish
    property bool showOnStartup: true
    property string shortcutSearch: ""

    // ── KEYBOARD LAYOUT STATE ────────────────────────────────────────────────
    property string currentKbLayout: "us"
    property string currentKbName: "English (US)"
    property bool kbSavedNotification: false
    property bool kbModalOpen: false
    property string kbSearchQuery: ""
    property var kbPopularList: [
        { code: "us", name: "English (US)" },
        { code: "gb", name: "English (UK)" },
        { code: "de", name: "German" },
        { code: "fr", name: "French" },
        { code: "es", name: "Spanish" },
        { code: "it", name: "Italian" },
        { code: "pt", name: "Portuguese" },
        { code: "br", name: "Portuguese (Brazil)" },
        { code: "ru", name: "Russian" },
        { code: "tr", name: "Turkish" },
        { code: "pl", name: "Polish" },
        { code: "se", name: "Swedish" },
        { code: "no", name: "Norwegian" },
        { code: "dk", name: "Danish" },
        { code: "fi", name: "Finnish" },
        { code: "jp", name: "Japanese" },
        { code: "kr", name: "Korean" },
        { code: "ara", name: "Arabic" },
        { code: "bd", name: "Bangla" }
    ]
    property var kbAllList: []
    property var filteredKbLayouts: []

    function updateFilteredLayouts() {
        var q = kbSearchQuery.trim().toLowerCase()
        var source = (kbAllList && kbAllList.length > 0) ? kbAllList : kbPopularList
        if (q.length === 0) {
            filteredKbLayouts = source
            return
        }
        var res = []
        for (var i = 0; i < source.length; i++) {
            var it = source[i]
            if (it.code.toLowerCase().indexOf(q) !== -1 || it.name.toLowerCase().indexOf(q) !== -1) {
                res.push(it)
            }
        }
        filteredKbLayouts = res
    }

    onKbModalOpenChanged: {
        if (kbModalOpen) {
            updateFilteredLayouts()
            focusTimer.restart()
        }
    }

    // ── SVG ASSETS ───────────────────────────────────────────────────────────
    function svgUrl(content) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(content)
    }

    readonly property string closeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>')
    readonly property string sparkSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m12 3-1.912 5.813a2 2 0 0 1-1.275 1.275L3 12l5.813 1.912a2 2 0 0 1 1.275 1.275L12 21l1.912-5.813a2 2 0 0 1 1.275-1.275L21 12l-5.813-1.912a2 2 0 0 1-1.275-1.275L12 3Z"/></svg>')
    readonly property string arrowRightSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.background + '" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>')
    readonly property string arrowLeftSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>')
    readonly property string checkSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>')
    readonly property string weatherSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"/></svg>')
    readonly property string packageSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg>')
    readonly property string shieldSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>')
    readonly property string speedSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>')
    readonly property string keyboardSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="M6 8h.01M10 8h.01M14 8h.01M18 8h.01M8 12h.01M12 12h.01M16 12h.01M7 16h10"/></svg>')
    readonly property string slidersSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="21" y1="4" x2="14" y2="4"/><line x1="10" y1="4" x2="3" y2="4"/><line x1="21" y1="12" x2="12" y2="12"/><line x1="8" y1="12" x2="3" y2="12"/><line x1="21" y1="20" x2="16" y2="20"/><line x1="12" y1="20" x2="3" y2="20"/><line x1="14" y1="2" x2="14" y2="6"/><line x1="8" y1="10" x2="8" y2="14"/><line x1="16" y1="18" x2="16" y2="22"/></svg>')
    readonly property string searchSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.muted + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>')
    readonly property string bookSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20"/></svg>')
    readonly property string gitSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="18" cy="18" r="3"/><circle cx="6" cy="6" r="3"/><path d="M13 6h3a2 2 0 0 1 2 2v7"/><line x1="6" y1="9" x2="6" y2="21"/></svg>')
    readonly property string playSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="5 3 19 12 5 21 5 3"/></svg>')
    readonly property string clipboardSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="8" y="2" width="8" height="4" rx="1" ry="1"/><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/></svg>')
    readonly property string panelSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="2" y1="7" x2="22" y2="7"/><line x1="12" y1="21" x2="12" y2="17"/></svg>')
    readonly property string gridSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg>')

    function whatsNewIcon(name) {
        if (name === "clipboard") return clipboardSvg
        if (name === "sliders") return slidersSvg
        if (name === "spark") return sparkSvg
        if (name === "speed") return speedSvg
        if (name === "weather") return weatherSvg
        if (name === "package") return packageSvg
        if (name === "shield") return shieldSvg
        if (name === "keyboard") return keyboardSvg
        return sparkSvg
    }

    function applyWhatsNewJson(raw) {
        if (!raw || raw.trim().length === 0) return
        try {
            var parsed = JSON.parse(raw.trim())
            if (!parsed || typeof parsed !== "object") return
            if (parsed.latest) window.versionTag = String(parsed.latest)
            if (Array.isArray(parsed.versions) && parsed.versions.length > 0) {
                window.whatsNewVersions = parsed.versions
                if (window.selectedWhatsNewIdx >= parsed.versions.length) {
                    window.selectedWhatsNewIdx = 0
                }
            }
        } catch (e) {}
    }

    FileView {
        id: whatsNewReader
        path: window.whatsNewPath
        preload: true
        watchChanges: true
        onLoaded: window.applyWhatsNewJson(text())
        onFileChanged: reload()
    }

    // ── IPC HANDLER ──────────────────────────────────────────────────────────
    IpcHandler {
        target: "welcome"
        function raise() {
            window.visible = true
        }
        function nextPage() {
            if (window.activePage < 4) window.activePage++
        }
        function prevPage() {
            if (window.activePage > 0) window.activePage--
        }
        function openOverview() { window.activePage = 0 }
        function openWhatsNew() { window.activePage = 1 }
        function openShortcuts() { window.activePage = 2 }
        function openApps() { window.activePage = 3 }
        function openGetStarted() { window.activePage = 4 }
        function openKbModal() {
            window.activePage = 0
            window.kbSearchQuery = ""
            window.updateFilteredLayouts()
            window.kbModalOpen = true
        }
        function selectKbLayout(code: string) {
            window.setKeyboardLayout(code)
        }
        function close() {
            Qt.quit()
        }
    }

    // ── KEYBOARD SHORTCUTS ───────────────────────────────────────────────────
    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (window.kbModalOpen) {
                window.kbModalOpen = false
            } else {
                Qt.quit()
            }
        }
    }

    Shortcut {
        sequence: "Left"
        onActivated: {
            if (window.activePage > 0) window.activePage--
        }
    }

    Shortcut {
        sequence: "Right"
        onActivated: {
            if (window.activePage < 4) window.activePage++
        }
    }

    // ── KEYBOARD LAYOUT BACKEND (set-kb-layout.py) ───────────────────────────
    Process {
        id: kbListReader
        command: ["python3", window.homeDir + "/.hyprconf/hypr/scripts/py/set-kb-layout.py", "--list"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var data = JSON.parse(text.trim())
                    if (data.status === "ok") {
                        if (data.current) {
                            window.currentKbLayout = data.current
                        }
                        if (data.popular && data.popular.length > 0) {
                            window.kbPopularList = data.popular
                        }
                        if (data.all && data.all.length > 0) {
                            window.kbAllList = data.all
                        }
                        var list = data.all || data.popular || []
                        for (var i = 0; i < list.length; i++) {
                            if (list[i].code === window.currentKbLayout) {
                                window.currentKbName = list[i].name
                                break
                            }
                        }
                        window.updateFilteredLayouts()
                    }
                } catch(e) {}
            }
        }
    }

    Process {
        id: kbWriter
    }

    Timer {
        id: kbSavedTimer
        interval: 3200
        onTriggered: window.kbSavedNotification = false
    }

    function setKeyboardLayout(code) {
        if (!code || code.trim().length === 0) return
        code = code.trim().toLowerCase()
        window.currentKbLayout = code

        var all = (window.kbAllList && window.kbAllList.length > 0) ? window.kbAllList : window.kbPopularList
        var name = code.toUpperCase()
        for (var i = 0; i < all.length; i++) {
            if (all[i].code === code) {
                name = all[i].name
                break
            }
        }
        window.currentKbName = name

        kbWriter.command = ["python3", window.homeDir + "/.hyprconf/hypr/scripts/py/set-kb-layout.py", "--set", code]
        kbWriter.running = false
        kbWriter.running = true

        window.kbSavedNotification = true
        kbSavedTimer.restart()
    }

    // ── STATE PERSISTENCE (welcome-app.json) ──────────────────────────────────
    Process {
        id: stateReader
        command: ["python3", "-c", "import json, os; p1=os.path.expanduser('~/.local/share/hyprconf/welcome-app.json'); p2=os.path.expanduser('~/.hyprconf/hypr/welcome-app.json'); p=p1 if os.path.exists(p1) else (p2 if os.path.exists(p2) else None); print(open(p).read() if p else '{\"show_on_startup\": true}')"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var data = JSON.parse(text.trim())
                    window.showOnStartup = (data.show_on_startup !== false)
                } catch(e) {}
            }
        }
    }

    Process {
        id: stateWriter
    }

    function toggleStartupState(enabled) {
        window.showOnStartup = enabled
        stateWriter.command = [
            "python3", "-c",
            "import json, os; val={'show_on_startup': " + (enabled ? "True" : "False") + "}; " +
            "paths = [os.path.expanduser('~/.local/share/hyprconf/welcome-app.json'), os.path.expanduser('~/.hyprconf/hypr/welcome-app.json')]; " +
            "[os.makedirs(os.path.dirname(p), exist_ok=True) or open(p, 'w').write(json.dumps(val, indent=2)) for p in paths]"
        ]
        stateWriter.running = false
        stateWriter.running = true
    }

    // ── DISPATCH HELPER ──────────────────────────────────────────────────────
    Process {
        id: execDispatcher
    }

    function dispatchCmd(cmd) {
        if (!cmd || cmd.length === 0) return
        execDispatcher.command = ["bash", "-c", cmd]
        execDispatcher.running = false
        execDispatcher.running = true
    }

    // ── PERSONALIZATION & SETUP STATE ────────────────────────────────────────
    property string currentTopPanel: "island" // "island" or "bar"
    property string currentIslandStyle: "prism_blade" // "prism_blade", "orbital", "minimal_rail"
    property bool topPanelSavedNotification: false

    property string currentLauncherTheme: "style-2" // "style-2" or "style-1"
    property bool launcherSavedNotification: false

    property string weatherCity: ""
    property string weatherCountry: ""
    property bool weatherSavedNotification: false

    Timer {
        id: topPanelSavedTimer
        interval: 3200
        onTriggered: window.topPanelSavedNotification = false
    }

    Timer {
        id: launcherSavedTimer
        interval: 3200
        onTriggered: window.launcherSavedNotification = false
    }

    Timer {
        id: weatherSavedTimer
        interval: 3500
        onTriggered: window.weatherSavedNotification = false
    }

    // ── CONFIG READERS ───────────────────────────────────────────────────────
    Process {
        id: topPanelReader
        command: ["python3", "-c", "import json, os\n" +
            "bp = os.path.expanduser('~/.local/share/hyprconf/bar.json')\n" +
            "ip = os.path.expanduser('~/.local/share/hyprconf/island.json')\n" +
            "top_panel = 'island'\n" +
            "style = 'prism_blade'\n" +
            "if os.path.exists(bp):\n" +
            "    try: top_panel = json.load(open(bp)).get('top_panel', 'island')\n" +
            "    except: pass\n" +
            "if os.path.exists(ip):\n" +
            "    try: style = json.load(open(ip)).get('style', 'prism_blade')\n" +
            "    except: pass\n" +
            "print(json.dumps({'top_panel': top_panel, 'style': style}))"
        ]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var d = JSON.parse(text.trim())
                    if (d.top_panel) window.currentTopPanel = d.top_panel
                    if (d.style) window.currentIslandStyle = d.style
                } catch(e) {}
            }
        }
    }

    Process {
        id: launcherReader
        command: ["python3", "-c", "import json, os\n" +
            "lp = os.path.expanduser('~/.local/share/hyprconf/launcher.json')\n" +
            "theme = 'style-2'\n" +
            "if os.path.exists(lp):\n" +
            "    try: theme = json.load(open(lp)).get('theme', 'style-2')\n" +
            "    except: pass\n" +
            "print(json.dumps({'theme': theme}))"
        ]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var d = JSON.parse(text.trim())
                    if (d.theme) window.currentLauncherTheme = d.theme
                } catch(e) {}
            }
        }
    }

    Process {
        id: weatherReader
        command: ["python3", "-c", "import json, os\n" +
            "wp = os.path.expanduser('~/.local/share/hyprconf/lockscreen.json')\n" +
            "city = ''\n" +
            "country = ''\n" +
            "if os.path.exists(wp):\n" +
            "    try:\n" +
            "        d = json.load(open(wp)).get('modules', {})\n" +
            "        city = d.get('weather_city', '') or ''\n" +
            "        country = d.get('weather_country', '') or ''\n" +
            "    except: pass\n" +
            "print(json.dumps({'city': city, 'country': country}))"
        ]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var d = JSON.parse(text.trim())
                    window.weatherCity = d.city || ""
                    window.weatherCountry = d.country || ""
                } catch(e) {}
            }
        }
    }

    // ── MUTATION / SWITCH FUNCTIONS ──────────────────────────────────────────
    function setTopInterface(mode, style) {
        window.currentTopPanel = mode
        if (style) window.currentIslandStyle = style
        var py = "import json, os, subprocess, time\n" +
            "bp = os.path.expanduser('~/.local/share/hyprconf/bar.json')\n" +
            "ip = os.path.expanduser('~/.local/share/hyprconf/island.json')\n" +
            "mode = " + JSON.stringify(mode) + "\n" +
            "style = " + JSON.stringify(style || "") + "\n" +
            "try:\n" +
            "    d = json.load(open(bp)) if os.path.exists(bp) else {}\n" +
            "    d['top_panel'] = mode\n" +
            "    with open(bp, 'w') as f: json.dump(d, f, indent=2)\n" +
            "except Exception as e: pass\n" +
            "if mode == 'island' and style:\n" +
            "    try:\n" +
            "        d = json.load(open(ip)) if os.path.exists(ip) else {}\n" +
            "        d['style'] = style\n" +
            "        with open(ip, 'w') as f: json.dump(d, f, indent=2)\n" +
            "    except Exception as e: pass\n" +
            "if mode == 'bar':\n" +
            "    subprocess.run(['pkill', '-9', '-f', 'qs -c island'], stderr=subprocess.DEVNULL)\n" +
            "    subprocess.run(['pkill', '-9', '-f', 'quickshell.*island'], stderr=subprocess.DEVNULL)\n" +
            "    subprocess.run(['bash', os.path.expanduser('~/.hyprconf/hypr/scripts/sh/qs-bar.sh'), '--restart'], stderr=subprocess.DEVNULL)\n" +
            "else:\n" +
            "    subprocess.run(['qs', 'ipc', '-c', 'bar', 'call', 'bar', 'quit'], stderr=subprocess.DEVNULL)\n" +
            "    subprocess.run(['bash', os.path.expanduser('~/.hyprconf/hypr/scripts/sh/qs-bar.sh'), '--stop'], stderr=subprocess.DEVNULL)\n" +
            "    subprocess.run(['pkill', '-9', '-f', '^qs -c bar'], stderr=subprocess.DEVNULL)\n" +
            "    time.sleep(0.1)\n" +
            "    res = subprocess.run(['qs', 'ipc', '-c', 'island', 'call', 'island', 'reloadConfig'], stderr=subprocess.DEVNULL)\n" +
            "    if res.returncode != 0:\n" +
            "        subprocess.run(['bash', os.path.expanduser('~/.hyprconf/hypr/scripts/sh/qs-island.sh'), '--restart'], stderr=subprocess.DEVNULL)\n"
        Quickshell.execDetached(["python3", "-c", py])
        window.topPanelSavedNotification = true
        topPanelSavedTimer.restart()
    }

    function setLauncherTheme(themeId) {
        window.currentLauncherTheme = themeId
        var jsonStr = JSON.stringify({ "theme": themeId }, null, 2)
        var py = "import json, os\n" +
            "for p in [os.path.expanduser('~/.local/share/hyprconf/launcher.json'), os.path.expanduser('~/.hyprconf/quickshell/launcher/config.json')]:\n" +
            "    try:\n" +
            "        os.makedirs(os.path.dirname(p), exist_ok=True)\n" +
            "        with open(p, 'w') as f: f.write('''" + jsonStr + "''')\n" +
            "    except Exception as e: pass\n"
        Quickshell.execDetached(["python3", "-c", py])
        window.launcherSavedNotification = true
        launcherSavedTimer.restart()
    }

    function saveWeatherLocation(city, country) {
        window.weatherCity = (city || "").trim()
        window.weatherCountry = (country || "").trim()
        var py = "import json, os, subprocess\n" +
            "p = os.path.expanduser('~/.local/share/hyprconf/lockscreen.json')\n" +
            "try:\n" +
            "    d = json.load(open(p)) if os.path.exists(p) else {}\n" +
            "    d.setdefault('modules', {})['weather_city'] = " + JSON.stringify(window.weatherCity) + "\n" +
            "    d['modules']['weather_country'] = " + JSON.stringify(window.weatherCountry) + "\n" +
            "    with open(p, 'w') as f: json.dump(d, f, indent=4)\n" +
            "except Exception as e: pass\n" +
            "subprocess.run(['python3', os.path.expanduser('~/.hyprconf/hypr/scripts/py/weather.py'), '--force'], stderr=subprocess.DEVNULL)\n"
        Quickshell.execDetached(["python3", "-c", py])
        window.weatherSavedNotification = true
        weatherSavedTimer.restart()
    }

    // ── MAIN OBSIDIAN GLASS SURFACE ──────────────────────────────────────────
    Rectangle {
        id: rootSurface
        anchors.fill: parent
        color: Theme.glassBase
        border.color: Theme.alpha(Theme.foreground, 0.14)
        border.width: 1
        radius: 16
        clip: true

        // Top specular edge highlight across modal
        Rectangle {
            z: 2
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.2; color: Theme.glassRimTop }
                GradientStop { position: 0.5; color: Theme.alpha("#ffffff", 0.32) }
                GradientStop { position: 0.8; color: Theme.glassRimTop }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            // ── TOP HEADER / NAV BAR ─────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                spacing: 12

                // Left: Avatar / Brand
                RowLayout {
                    spacing: 10

                    BrandLogoBadge {
                        badgeSize: 32
                        imageMargin: 2
                        ringColor: Theme.alpha(Theme.accent, 0.40)
                    }

                    ColumnLayout {
                        spacing: 0
                        RowLayout {
                            spacing: 6
                            Text {
                                text: "Hyprconf"
                                font.pixelSize: 14
                                font.bold: true
                                font.family: "Inter"
                                font.letterSpacing: -0.3
                                color: Theme.foreground
                            }
                            Rectangle {
                                height: 16
                                implicitWidth: verText.implicitWidth + 8
                                radius: 8
                                color: Theme.alpha(Theme.accent, 0.16)
                                border.color: Theme.alpha(Theme.accent, 0.35)
                                border.width: 1
                                Text {
                                    id: verText
                                    anchors.centerIn: parent
                                    text: window.versionTag
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Theme.accent
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Center: Minimal Segmented Navigation Pills
                Rectangle {
                    height: 34
                    implicitWidth: navRow.implicitWidth + 8
                    radius: 10
                    color: Theme.glassCard
                    border.color: Theme.alpha(Theme.foreground, 0.10)
                    border.width: 1

                    RowLayout {
                        id: navRow
                        anchors.centerIn: parent
                        spacing: 2

                        Repeater {
                            model: [
                                { label: "Overview", page: 0 },
                                { label: "What's New", page: 1, isNew: true },
                                { label: "Shortcuts", page: 2 },
                                { label: "Apps", page: 3 },
                                { label: "Get Started", page: 4 }
                            ]

                            Rectangle {
                                height: 28
                                implicitWidth: tabLabel.implicitWidth + (modelData.isNew ? 28 : 20)
                                radius: 8
                                color: window.activePage === modelData.page
                                       ? Theme.alpha(Theme.accent, 0.20)
                                       : (tabHoverArea.containsMouse ? Theme.alpha(Theme.foreground, 0.06) : "transparent")
                                border.color: window.activePage === modelData.page ? Theme.alpha(Theme.accent, 0.42) : "transparent"
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Text {
                                        id: tabLabel
                                        text: modelData.label
                                        font.pixelSize: 11
                                        font.bold: window.activePage === modelData.page
                                        font.family: "Inter"
                                        color: window.activePage === modelData.page ? Theme.accent : Theme.muted
                                    }

                                    // Glowing "NEW" indicator dot
                                    Rectangle {
                                        visible: modelData.isNew === true
                                        width: 6
                                        height: 6
                                        radius: 3
                                        color: Theme.accent
                                    }
                                }

                                MouseArea {
                                    id: tabHoverArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: window.activePage = modelData.page
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Right: Close Button
                Rectangle {
                    width: 32
                    height: 32
                    radius: 8
                    color: closeArea.containsMouse ? Theme.alpha("#ef4444", 0.20) : Theme.glassElevated
                    border.color: closeArea.containsMouse ? Theme.alpha("#ef4444", 0.50) : Theme.alpha(Theme.foreground, 0.12)
                    border.width: 1
                    scale: closeArea.pressed ? 0.94 : (closeArea.containsMouse ? 1.03 : 1.0)
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                    Image {
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        source: window.closeSvg
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.quit()
                    }
                }
            }

            // ── PAGE VIEW CONTAINER ──────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                // ═════════════════════════════════════════════════════════════
                // PAGE 0: OVERVIEW (HOME & PERSONALIZATION)
                // ═════════════════════════════════════════════════════════════
                Flickable {
                    id: overviewFlickable
                    anchors.fill: parent
                    visible: window.activePage === 0
                    contentWidth: width
                    contentHeight: overviewLayout.implicitHeight + 20
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    ColumnLayout {
                        id: overviewLayout
                        width: parent.width - (parent.contentHeight > parent.height ? 10 : 0)
                        spacing: 12

                        // Hero Cluster
                        ColumnLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 8

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 68
                                height: 68
                                radius: 34
                                color: Theme.alpha(Theme.surface, 0.90)
                                border.color: Theme.alpha(Theme.accent, 0.40)
                                border.width: 1.5

                                BrandLogoBadge {
                                    anchors.centerIn: parent
                                    badgeSize: 58
                                    imageMargin: 4
                                    ringColor: Theme.alpha(Theme.accent, 0.28)
                                }
                            }

                            Text {
                                text: "Welcome to Hyprconf"
                                font.pixelSize: 22
                                font.bold: true
                                font.family: "Inter"
                                font.letterSpacing: -0.4
                                color: Theme.foreground
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: "Configure your primary desktop components below. Selections apply immediately."
                                font.pixelSize: 12
                                font.family: "Inter"
                                color: Theme.muted
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                Layout.maximumWidth: 540
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        // ── 1. Top Interface Configuration Card ─────────────
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 68
                            radius: 12
                            clip: true
                            color: Theme.glassCard
                            border.color: Theme.alpha(Theme.foreground, 0.11)
                            border.width: 1

                            Rectangle {
                                z: 2
                                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                                anchors.leftMargin: 16; anchors.rightMargin: 16; height: 1
                                color: Theme.glassRimTop
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 14

                                Rectangle {
                                    width: 36
                                    height: 36
                                    radius: 10
                                    color: Theme.alpha(Theme.accent, 0.14)
                                    border.color: Theme.alpha(Theme.accent, 0.30)
                                    border.width: 1

                                    Image {
                                        anchors.centerIn: parent
                                        width: 18
                                        height: 18
                                        source: window.panelSvg
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3

                                    RowLayout {
                                        spacing: 8
                                        Text {
                                            text: "Top Interface"
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: Theme.foreground
                                        }

                                        Rectangle {
                                            height: 20
                                            implicitWidth: activeTopPanelRow.implicitWidth + 12
                                            radius: 10
                                            color: Theme.alpha(Theme.accent, 0.15)
                                            border.color: Theme.alpha(Theme.accent, 0.35)
                                            border.width: 1

                                            RowLayout {
                                                id: activeTopPanelRow
                                                anchors.centerIn: parent
                                                spacing: 5

                                                Rectangle { width: 6; height: 6; radius: 3; color: "#22c55e" }
                                                Text {
                                                    text: window.currentTopPanel === "bar"
                                                        ? "Top Bar Active"
                                                        : ("Island • " + (window.currentIslandStyle === "orbital" ? "Orbital" : (window.currentIslandStyle === "minimal_rail" ? "Minimal Rail" : "Prism Blade")))
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    color: Theme.accent
                                                }
                                            }
                                        }

                                        RowLayout {
                                            visible: window.topPanelSavedNotification
                                            spacing: 4
                                            Image { width: 12; height: 12; source: window.checkSvg }
                                            Text {
                                                text: "Applied & Switched"
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: "#22c55e"
                                            }
                                        }
                                    }

                                    Text {
                                        text: "Switch seamlessly between Dynamic Island notch styles and Full Top Bar."
                                        font.pixelSize: 11
                                        color: Theme.muted
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                RowLayout {
                                    spacing: 6
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                                    Repeater {
                                        model: [
                                            { id: "prism_blade", mode: "island", label: "Prism Blade" },
                                            { id: "orbital", mode: "island", label: "Orbital" },
                                            { id: "minimal_rail", mode: "island", label: "Minimal Rail" },
                                            { id: "bar", mode: "bar", label: "Top Bar" }
                                        ]

                                        Rectangle {
                                            height: 30
                                            implicitWidth: pillText.implicitWidth + 18
                                            radius: 8
                                            readonly property bool isSelected: modelData.mode === "bar"
                                                ? (window.currentTopPanel === "bar")
                                                : (window.currentTopPanel === "island" && window.currentIslandStyle === modelData.id)
                                            color: isSelected ? Theme.accent : (pMa.containsMouse ? Theme.alpha(Theme.foreground, 0.10) : Theme.alpha(Theme.surface, 0.85))
                                            border.color: isSelected ? Theme.accent : (pMa.containsMouse ? Theme.alpha(Theme.accent, 0.45) : Theme.alpha(Theme.foreground, 0.12))
                                            border.width: 1

                                            Text {
                                                id: pillText
                                                anchors.centerIn: parent
                                                text: modelData.label
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: parent.isSelected ? Theme.background : Theme.foreground
                                            }

                                            MouseArea {
                                                id: pMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: window.setTopInterface(modelData.mode, modelData.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ── 2. App Launcher Configuration Card ──────────────
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 68
                            radius: 12
                            clip: true
                            color: Theme.glassCard
                            border.color: Theme.alpha(Theme.foreground, 0.11)
                            border.width: 1

                            Rectangle {
                                z: 2
                                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                                anchors.leftMargin: 16; anchors.rightMargin: 16; height: 1
                                color: Theme.glassRimTop
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 14

                                Rectangle {
                                    width: 36
                                    height: 36
                                    radius: 10
                                    color: Theme.alpha(Theme.accent, 0.14)
                                    border.color: Theme.alpha(Theme.accent, 0.30)
                                    border.width: 1

                                    Image {
                                        anchors.centerIn: parent
                                        width: 18
                                        height: 18
                                        source: window.gridSvg
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3

                                    RowLayout {
                                        spacing: 8
                                        Text {
                                            text: "App Launcher"
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: Theme.foreground
                                        }

                                        Rectangle {
                                            height: 20
                                            implicitWidth: activeLauncherRow.implicitWidth + 12
                                            radius: 10
                                            color: Theme.alpha(Theme.accent, 0.15)
                                            border.color: Theme.alpha(Theme.accent, 0.35)
                                            border.width: 1

                                            RowLayout {
                                                id: activeLauncherRow
                                                anchors.centerIn: parent
                                                spacing: 5

                                                Rectangle { width: 6; height: 6; radius: 3; color: "#22c55e" }
                                                Text {
                                                    text: window.currentLauncherTheme === "style-1"
                                                        ? "Style 1 • Slanted Split"
                                                        : "Style 2 • Panoramic Grid"
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    color: Theme.accent
                                                }
                                            }
                                        }

                                        RowLayout {
                                            visible: window.launcherSavedNotification
                                            spacing: 4
                                            Image { width: 12; height: 12; source: window.checkSvg }
                                            Text {
                                                text: "Theme Saved"
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: "#22c55e"
                                            }
                                        }
                                    }

                                    Text {
                                        text: "Choose your preferred application launcher layout."
                                        font.pixelSize: 11
                                        color: Theme.muted
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                RowLayout {
                                    spacing: 6
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                                    Repeater {
                                        model: [
                                            { id: "style-2", label: "Style 2: Panoramic" },
                                            { id: "style-1", label: "Style 1: Slanted Split" }
                                        ]

                                        Rectangle {
                                            height: 30
                                            implicitWidth: lText.implicitWidth + 18
                                            radius: 8
                                            readonly property bool isSelected: window.currentLauncherTheme === modelData.id
                                            color: isSelected ? Theme.accent : (lMa.containsMouse ? Theme.alpha(Theme.foreground, 0.10) : Theme.alpha(Theme.surface, 0.85))
                                            border.color: isSelected ? Theme.accent : (lMa.containsMouse ? Theme.alpha(Theme.accent, 0.45) : Theme.alpha(Theme.foreground, 0.12))
                                            border.width: 1

                                            Text {
                                                id: lText
                                                anchors.centerIn: parent
                                                text: modelData.label
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: parent.isSelected ? Theme.background : Theme.foreground
                                            }

                                            MouseArea {
                                                id: lMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: window.setLauncherTheme(modelData.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ── 3. Weather Location Configuration Card ──────────
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 70
                            radius: 12
                            clip: true
                            color: Theme.glassCard
                            border.color: Theme.alpha(Theme.foreground, 0.11)
                            border.width: 1

                            Rectangle {
                                z: 2
                                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                                anchors.leftMargin: 16; anchors.rightMargin: 16; height: 1
                                color: Theme.glassRimTop
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 14

                                Rectangle {
                                    width: 36
                                    height: 36
                                    radius: 10
                                    color: Theme.alpha(Theme.accent, 0.14)
                                    border.color: Theme.alpha(Theme.accent, 0.30)
                                    border.width: 1

                                    Image {
                                        anchors.centerIn: parent
                                        width: 18
                                        height: 18
                                        source: window.weatherSvg
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3

                                    RowLayout {
                                        spacing: 8
                                        Text {
                                            text: "Weather Location"
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: Theme.foreground
                                        }

                                        Rectangle {
                                            height: 20
                                            implicitWidth: activeWeatherRow.implicitWidth + 12
                                            radius: 10
                                            color: Theme.alpha(Theme.accent, 0.15)
                                            border.color: Theme.alpha(Theme.accent, 0.35)
                                            border.width: 1

                                            RowLayout {
                                                id: activeWeatherRow
                                                anchors.centerIn: parent
                                                spacing: 5

                                                Rectangle { width: 6; height: 6; radius: 3; color: "#22c55e" }
                                                Text {
                                                    text: window.weatherCity.length > 0
                                                        ? (window.weatherCity + (window.weatherCountry.length > 0 ? (" • " + window.weatherCountry) : ""))
                                                        : "Not Configured"
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    color: Theme.accent
                                                }
                                            }
                                        }

                                        RowLayout {
                                            visible: window.weatherSavedNotification
                                            spacing: 4
                                            Image { width: 12; height: 12; source: window.checkSvg }
                                            Text {
                                                text: "Saved & Fetched"
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: "#22c55e"
                                            }
                                        }
                                    }

                                    Text {
                                        text: "Set city & country for desktop forecasts, island metrics & lockscreen."
                                        font.pixelSize: 11
                                        color: Theme.muted
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                RowLayout {
                                    spacing: 6
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                                    // City Input
                                    Rectangle {
                                        width: 120
                                        height: 30
                                        radius: 8
                                        color: Theme.alpha(Theme.surface, 0.85)
                                        border.color: cityInput.activeFocus ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                                        border.width: 1

                                        TextInput {
                                            id: cityInput
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            verticalAlignment: TextInput.AlignVCenter
                                            font.pixelSize: 11
                                            font.family: "Inter"
                                            color: Theme.foreground
                                            clip: true
                                            text: window.weatherCity
                                            Binding on text {
                                                when: !cityInput.activeFocus
                                                value: window.weatherCity
                                            }
                                            onAccepted: window.saveWeatherLocation(cityInput.text, countryInput.text)
                                        }

                                        Text {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            verticalAlignment: Text.AlignVCenter
                                            text: "City…"
                                            font.pixelSize: 11
                                            color: Theme.muted
                                            visible: cityInput.text.length === 0 && !cityInput.activeFocus
                                        }
                                    }

                                    // Country Input
                                    Rectangle {
                                        width: 90
                                        height: 30
                                        radius: 8
                                        color: Theme.alpha(Theme.surface, 0.85)
                                        border.color: countryInput.activeFocus ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                                        border.width: 1

                                        TextInput {
                                            id: countryInput
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            verticalAlignment: TextInput.AlignVCenter
                                            font.pixelSize: 11
                                            font.family: "Inter"
                                            color: Theme.foreground
                                            clip: true
                                            text: window.weatherCountry
                                            Binding on text {
                                                when: !countryInput.activeFocus
                                                value: window.weatherCountry
                                            }
                                            onAccepted: window.saveWeatherLocation(cityInput.text, countryInput.text)
                                        }

                                        Text {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            verticalAlignment: Text.AlignVCenter
                                            text: "Country…"
                                            font.pixelSize: 11
                                            color: Theme.muted
                                            visible: countryInput.text.length === 0 && !countryInput.activeFocus
                                        }
                                    }

                                    // Save Button
                                    Rectangle {
                                        height: 30
                                        implicitWidth: saveRow.implicitWidth + 18
                                        radius: 8
                                        color: saveMa.containsMouse ? Theme.accent : Theme.alpha(Theme.accent, 0.18)
                                        border.color: Theme.accent
                                        border.width: 1

                                        RowLayout {
                                            id: saveRow
                                            anchors.centerIn: parent
                                            spacing: 5
                                            Image {
                                                width: 11
                                                height: 11
                                                source: window.checkSvg
                                            }
                                            Text {
                                                text: "Save"
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: saveMa.containsMouse ? Theme.background : Theme.foreground
                                            }
                                        }

                                        MouseArea {
                                            id: saveMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: window.saveWeatherLocation(cityInput.text, countryInput.text)
                                        }
                                    }
                                }
                            }
                        }

                        // ── 4. Keyboard Layout Configuration Card ───────────
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 68
                            radius: 12
                            clip: true
                            color: Theme.glassCard
                            border.color: Theme.alpha(Theme.foreground, 0.11)
                            border.width: 1

                            Rectangle {
                                z: 2
                                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                                anchors.leftMargin: 16; anchors.rightMargin: 16; height: 1
                                color: Theme.glassRimTop
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 14

                                Rectangle {
                                    width: 36
                                    height: 36
                                    radius: 10
                                    color: Theme.alpha(Theme.accent, 0.14)
                                    border.color: Theme.alpha(Theme.accent, 0.30)
                                    border.width: 1

                                    Image {
                                        anchors.centerIn: parent
                                        width: 18
                                        height: 18
                                        source: window.keyboardSvg
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3

                                    RowLayout {
                                        spacing: 8
                                        Text {
                                            text: "Keyboard Layout"
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: Theme.foreground
                                        }

                                        Rectangle {
                                            height: 20
                                            implicitWidth: activeBadgeRow.implicitWidth + 12
                                            radius: 10
                                            color: Theme.alpha(Theme.accent, 0.15)
                                            border.color: Theme.alpha(Theme.accent, 0.35)
                                            border.width: 1

                                            RowLayout {
                                                id: activeBadgeRow
                                                anchors.centerIn: parent
                                                spacing: 5

                                                Rectangle {
                                                    width: 6
                                                    height: 6
                                                    radius: 3
                                                    color: "#22c55e"
                                                }

                                                Text {
                                                    text: window.currentKbLayout.toUpperCase() + " • " + window.currentKbName
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    color: Theme.accent
                                                }
                                            }
                                        }

                                        RowLayout {
                                            visible: window.kbSavedNotification
                                            spacing: 4
                                            Image {
                                                width: 12
                                                height: 12
                                                source: window.checkSvg
                                            }
                                            Text {
                                                text: "Applied & Saved"
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: "#22c55e"
                                            }
                                        }
                                    }

                                    Text {
                                        text: "Choose your preferred layout. Automatically saved to settings.lua and applied live."
                                        font.pixelSize: 11
                                        color: Theme.muted
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                RowLayout {
                                    spacing: 6
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                                    Repeater {
                                        model: [
                                            { code: "us", label: "US" },
                                            { code: "gb", label: "UK" },
                                            { code: "de", label: "DE" },
                                            { code: "fr", label: "FR" },
                                            { code: "es", label: "ES" }
                                        ]

                                        Rectangle {
                                            width: 38
                                            height: 30
                                            radius: 8
                                            readonly property bool isSelected: window.currentKbLayout === modelData.code
                                            color: isSelected ? Theme.accent : (chipMa.containsMouse ? Theme.alpha(Theme.foreground, 0.10) : Theme.alpha(Theme.surface, 0.85))
                                            border.color: isSelected ? Theme.accent : (chipMa.containsMouse ? Theme.alpha(Theme.accent, 0.45) : Theme.alpha(Theme.foreground, 0.12))
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.label
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: parent.isSelected ? Theme.background : Theme.foreground
                                            }

                                            MouseArea {
                                                id: chipMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: window.setKeyboardLayout(modelData.code)
                                            }
                                        }
                                    }

                                    Rectangle {
                                        height: 30
                                        implicitWidth: allLayoutsRow.implicitWidth + 20
                                        radius: 8
                                        readonly property bool isCustomActive: !["us", "gb", "de", "fr", "es"].includes(window.currentKbLayout)
                                        color: isCustomActive
                                            ? Theme.alpha(Theme.accent, 0.25)
                                            : (allMa.containsMouse ? Theme.alpha(Theme.foreground, 0.10) : Theme.alpha(Theme.surface, 0.85))
                                        border.color: isCustomActive ? Theme.accent : (allMa.containsMouse ? Theme.alpha(Theme.accent, 0.45) : Theme.alpha(Theme.foreground, 0.12))
                                        border.width: 1

                                        RowLayout {
                                            id: allLayoutsRow
                                            anchors.centerIn: parent
                                            spacing: 6

                                            Text {
                                                text: parent.parent.isCustomActive ? (window.currentKbLayout.toUpperCase() + " ▾") : "All Layouts... ▾"
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: parent.parent.isCustomActive ? Theme.accent : Theme.foreground
                                            }
                                        }

                                        MouseArea {
                                            id: allMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                window.kbSearchQuery = ""
                                                window.updateFilteredLayouts()
                                                window.kbModalOpen = true
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ── 5. 3 Core Pillars Cards ─────────────────────────
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 100
                            spacing: 12

                            // Pillar 1: Pure Quickshell
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 12
                                clip: true
                                color: Theme.glassCard
                                border.color: Theme.alpha(Theme.foreground, 0.11)
                                border.width: 1

                                Rectangle {
                                    z: 2
                                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                                    anchors.leftMargin: 14; anchors.rightMargin: 14; height: 1
                                    color: Theme.glassRimTop
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 6

                                    RowLayout {
                                        spacing: 8
                                        Image { width: 14; height: 14; source: window.speedSvg }
                                        Text {
                                            text: "Pure Quickshell"
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: Theme.foreground
                                        }
                                    }
                                    Text {
                                        text: "100% native Qt6/QML Wayland layer surfaces for Dynamic Island, Dock, Launcher, and Lockscreen."
                                        font.pixelSize: 10
                                        color: Theme.muted
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            // Pillar 2: Obsidian Palette
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 12
                                clip: true
                                color: Theme.glassCard
                                border.color: Theme.alpha(Theme.foreground, 0.11)
                                border.width: 1

                                Rectangle {
                                    z: 2
                                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                                    anchors.leftMargin: 14; anchors.rightMargin: 14; height: 1
                                    color: Theme.glassRimTop
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 6

                                    RowLayout {
                                        spacing: 8
                                        Image { width: 14; height: 14; source: window.sparkSvg }
                                        Text {
                                            text: "Obsidian Harmony"
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: Theme.foreground
                                        }
                                    }
                                    Text {
                                        text: "Dynamic wallpaper color quantization with 7 Noctalia harmony modes and zero generic emojis."
                                        font.pixelSize: 10
                                        color: Theme.muted
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            // Pillar 3: Physical Springs
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 12
                                clip: true
                                color: Theme.glassCard
                                border.color: Theme.alpha(Theme.foreground, 0.11)
                                border.width: 1

                                Rectangle {
                                    z: 2
                                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                                    anchors.leftMargin: 14; anchors.rightMargin: 14; height: 1
                                    color: Theme.glassRimTop
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 6

                                    RowLayout {
                                        spacing: 8
                                        Image { width: 14; height: 14; source: window.slidersSvg }
                                        Text {
                                            text: "Spring Physics"
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: Theme.foreground
                                        }
                                    }
                                    Text {
                                        text: "Natural physical spring damping on notch expansions, dock slide-outs, and window gestures."
                                        font.pixelSize: 10
                                        color: Theme.muted
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }
                }

                // ═════════════════════════════════════════════════════════════
                // PAGE 1: WHAT'S NEW (LOADED FROM whatsnew.json)
                // ═════════════════════════════════════════════════════════════
                ColumnLayout {
                    id: whatsNewPage
                    anchors.fill: parent
                    visible: window.activePage === 1
                    spacing: 14

                    readonly property var activeRelease: {
                        if (window.whatsNewVersions && window.whatsNewVersions.length > 0) {
                            var idx = Math.max(0, Math.min(window.selectedWhatsNewIdx, window.whatsNewVersions.length - 1))
                            return window.whatsNewVersions[idx]
                        }
                        return {
                            version: window.versionTag,
                            badge: "LATEST RELEASE",
                            title: "What's New in " + window.versionTag,
                            subtitle: "Pure Quickshell desktop enhancements, Quick Paste tooltip, and tuned physics.",
                            features: []
                        }
                    }

                    // Header + Version Selector Pills
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            RowLayout {
                                spacing: 8
                                Text {
                                    text: whatsNewPage.activeRelease.title || ("What's New in " + window.versionTag)
                                    font.pixelSize: 20
                                    font.bold: true
                                    font.family: "Inter"
                                    font.letterSpacing: -0.3
                                    color: Theme.foreground
                                }
                                Rectangle {
                                    height: 18
                                    implicitWidth: relPill.implicitWidth + 10
                                    radius: 9
                                    color: Theme.alpha(Theme.accent, 0.16)
                                    border.color: Theme.alpha(Theme.accent, 0.35)
                                    border.width: 1
                                    Text {
                                        id: relPill
                                        anchors.centerIn: parent
                                        text: whatsNewPage.activeRelease.badge || "RELEASE HIGHLIGHTS"
                                        font.pixelSize: 9
                                        font.bold: true
                                        font.letterSpacing: 0.5
                                        color: Theme.accent
                                    }
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: whatsNewPage.activeRelease.subtitle || ""
                                font.pixelSize: 12
                                color: Theme.muted
                                elide: Text.ElideRight
                            }
                        }

                        // Version switcher
                        Rectangle {
                            visible: window.whatsNewVersions && window.whatsNewVersions.length > 1
                            height: 30
                            implicitWidth: verSwitchRow.implicitWidth + 8
                            radius: 9
                            color: Theme.glassCard
                            border.color: Theme.alpha(Theme.foreground, 0.10)
                            border.width: 1

                            RowLayout {
                                id: verSwitchRow
                                anchors.centerIn: parent
                                spacing: 3

                                Repeater {
                                    model: window.whatsNewVersions

                                    Rectangle {
                                        required property var modelData
                                        required property int index
                                        readonly property bool isActive: window.selectedWhatsNewIdx === index

                                        height: 22
                                        implicitWidth: verBtnLabel.implicitWidth + 14
                                        radius: 6
                                        color: isActive
                                            ? Theme.alpha(Theme.accent, 0.22)
                                            : (verBtnMa.containsMouse ? Theme.alpha(Theme.foreground, 0.08) : "transparent")
                                        border.color: isActive ? Theme.alpha(Theme.accent, 0.45) : "transparent"
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        Text {
                                            id: verBtnLabel
                                            anchors.centerIn: parent
                                            text: modelData.version || ""
                                            font.pixelSize: 10
                                            font.bold: isActive
                                            font.family: "JetBrains Mono, monospace"
                                            color: isActive ? Theme.accent : Theme.muted
                                        }

                                        MouseArea {
                                            id: verBtnMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: window.selectedWhatsNewIdx = index
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Feature Highlight Cards (2x2 Grid driven by whatsnew.json)
                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 2
                        columnSpacing: 12
                        rowSpacing: 12

                        Repeater {
                            model: whatsNewPage.activeRelease.features || []

                            Rectangle {
                                required property var modelData

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 12
                                clip: true
                                color: Theme.mix(Theme.glassCard, Theme.accent, 0.05)
                                border.color: Theme.alpha(Theme.accent, 0.28)
                                border.width: 1

                                Rectangle {
                                    z: 2
                                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                                    anchors.leftMargin: 14; anchors.rightMargin: 14; height: 1
                                    color: Theme.alpha(Theme.accent, 0.35)
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 6

                                    RowLayout {
                                        spacing: 8
                                        Rectangle {
                                            width: 30
                                            height: 30
                                            radius: 8
                                            color: Theme.alpha(Theme.accent, 0.14)
                                            Image {
                                                anchors.centerIn: parent
                                                width: 16
                                                height: 16
                                                source: window.whatsNewIcon(modelData.icon || "")
                                            }
                                        }
                                        ColumnLayout {
                                            spacing: 1
                                            Text {
                                                text: modelData.title || ""
                                                font.pixelSize: 13
                                                font.bold: true
                                                color: Theme.foreground
                                            }
                                            Text {
                                                text: modelData.tag || ""
                                                font.pixelSize: 10
                                                color: Theme.accent
                                            }
                                        }
                                    }

                                    Text {
                                        text: modelData.description || ""
                                        font.pixelSize: 11
                                        color: Theme.muted
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }

                    KeybindUpdateBanner {
                        headline: "Keybinds Updated in " + (whatsNewPage.activeRelease.version || window.versionTag)
                        bodyText: whatsNewPage.activeRelease.keybindsNotice
                            || "Manually copy newly added shortcuts from ~/.hyprconf/hypr/configs/keybinds-updated.lua into ~/.local/share/hyprconf/keybinds.lua to enable them."
                    }
                }

                // ═════════════════════════════════════════════════════════════
                // PAGE 2: SHORTCUTS (INTERACTIVE)
                // ═════════════════════════════════════════════════════════════
                ColumnLayout {
                    anchors.fill: parent
                    visible: window.activePage === 2
                    spacing: 12

                    // Top Search & Title Bar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ColumnLayout {
                            spacing: 1
                            Text {
                                text: "Essential Keybindings"
                                font.pixelSize: 20
                                font.bold: true
                                font.family: "Inter"
                                font.letterSpacing: -0.3
                                color: Theme.foreground
                            }
                            Text {
                                text: "Click any shortcut row to run the command immediately."
                                font.pixelSize: 12
                                color: Theme.muted
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Search Box
                        Rectangle {
                            width: 220
                            height: 32
                            radius: 8
                            color: Theme.glassWell
                            border.color: searchInput.activeFocus ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                            border.width: 1
                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 6

                                Image { width: 12; height: 12; source: window.searchSvg }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    TextInput {
                                        id: searchInput
                                        anchors.fill: parent
                                        verticalAlignment: TextInput.AlignVCenter
                                        font.pixelSize: 11
                                        font.family: "Inter"
                                        color: Theme.foreground
                                        clip: true
                                        onTextChanged: window.shortcutSearch = text.toLowerCase().trim()
                                    }

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "Search…"
                                        font.pixelSize: 11
                                        color: Theme.muted
                                        visible: searchInput.text.length === 0
                                    }
                                }
                            }
                        }
                    }

                    KeybindUpdateBanner {
                        headline: "Manual Keybind Update Required"
                        bodyText: "Upgraded configs keep ~/.local/share/hyprconf/keybinds.lua untouched. Copy the latest " + window.versionTag + " shortcuts from ~/.hyprconf/hypr/configs/keybinds-updated.lua into your keybinds.lua manually to activate new features."
                    }

                    // Keybinds Model Helper
                    readonly property var rawBinds: [
                        { title: "Quick Paste Tooltip", desc: "Cursor popup of recent copied texts & links", keys: ["Super", "V"], cmd: "bash ~/.hyprconf/hypr/scripts/sh/qs-quickpaste.sh &" },
                        { title: "Terminal", desc: "Open Kitty terminal emulator", keys: ["Super", "Enter"], cmd: "kitty &" },
                        { title: "Floating Terminal", desc: "Open Kitty in a floating window", keys: ["Super", "Shift", "Enter"], cmd: "hyprctl dispatch exec [float] kitty" },
                        { title: "File Manager", desc: "Launch Dolphin file explorer", keys: ["Super", "E"], cmd: "dolphin &" },
                        { title: "Application Launcher", desc: "Toggle Dynamic Island panoramic launcher", keys: ["Super", "D"], cmd: "qs ipc -c island call island toggleLauncher" },
                        { title: "Wallpaper Studio", desc: "Browse and apply wallpapers with live palette generation", keys: ["Super", "W"], cmd: "bash ~/.hyprconf/hypr/scripts/sh/qs-wallpaper.sh &" },
                        { title: "Settings Studio", desc: "Open Quickshell unified Settings Studio", keys: ["Super", "S"], cmd: "bash ~/.hyprconf/hypr/scripts/sh/qs-settings.sh &" },
                        { title: "Package Updater", desc: "Open native Quickshell package updater", keys: ["Ctrl", "U"], cmd: "bash ~/.hyprconf/hypr/scripts/sh/qs-updater.sh &" },
                        { title: "Keybinds Cheatsheet", desc: "Display full interactive cheatsheet overlay", keys: ["Super", "Shift", "H"], cmd: "qs ipc -c island call island openKeybinds" },
                        { title: "Toggle Top Bar / Island", desc: "Switch seamlessly between Dynamic Island and Full Top Bar", keys: ["Super", "Ctrl", "B"], cmd: "bash ~/.hyprconf/hypr/scripts/sh/qs-bar.sh --toggle &" },
                        { title: "Reload Desktop Shell", desc: "Clean restart Island, Dock, and Widgets in sequence", keys: ["Ctrl", "Esc"], cmd: "bash ~/.hyprconf/hypr/scripts/sh/qs-reload.sh &" }
                    ]

                    readonly property var filteredBinds: {
                        var list = rawBinds
                        if (!window.shortcutSearch || window.shortcutSearch.length === 0) return list
                        var res = []
                        for (var i = 0; i < list.length; i++) {
                            var item = list[i]
                            if (item.title.toLowerCase().indexOf(window.shortcutSearch) !== -1 ||
                                item.desc.toLowerCase().indexOf(window.shortcutSearch) !== -1) {
                                res.push(item)
                            }
                        }
                        return res
                    }

                    // Shortcut List
                    ListView {
                        id: bindListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 6
                        clip: true
                        model: parent.filteredBinds

                        delegate: Rectangle {
                            width: bindListView.width
                            height: 48
                            radius: 10
                            color: bindArea.containsMouse ? Theme.glassElevated : Theme.glassCard
                            border.color: bindArea.containsMouse ? Theme.alpha(Theme.accent, 0.38) : Theme.alpha(Theme.foreground, 0.09)
                            border.width: 1
                            scale: bindArea.pressed ? 0.99 : 1.0
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }
                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 12

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: modelData.title
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.foreground
                                    }
                                    Text {
                                        text: modelData.desc
                                        font.pixelSize: 10
                                        color: Theme.muted
                                    }
                                }

                                // Keycaps Pill Cluster
                                RowLayout {
                                    spacing: 4

                                    Repeater {
                                        model: modelData.keys

                                        Rectangle {
                                            height: 22
                                            implicitWidth: kbdText.implicitWidth + 12
                                            radius: 6
                                            color: Theme.alpha(Theme.accent, 0.16)
                                            border.color: Theme.alpha(Theme.accent, 0.35)
                                            border.width: 1

                                            Text {
                                                id: kbdText
                                                anchors.centerIn: parent
                                                text: modelData
                                                font.pixelSize: 10
                                                font.bold: true
                                                font.family: "JetBrains Mono, monospace"
                                                color: Theme.accent
                                            }
                                        }
                                    }
                                }

                                // Run Icon
                                Rectangle {
                                    width: 26
                                    height: 26
                                    radius: 6
                                    color: bindArea.containsMouse ? Theme.alpha(Theme.accent, 0.20) : "transparent"
                                    visible: bindArea.containsMouse

                                    Image {
                                        anchors.centerIn: parent
                                        width: 12
                                        height: 12
                                        source: window.playSvg
                                    }
                                }
                            }

                            MouseArea {
                                id: bindArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: window.dispatchCmd(modelData.cmd)
                            }
                        }
                    }
                }

                // ═════════════════════════════════════════════════════════════
                // PAGE 3: APPLICATIONS & DOCS
                // ═════════════════════════════════════════════════════════════
                ColumnLayout {
                    anchors.fill: parent
                    visible: window.activePage === 3
                    spacing: 14

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "Built-in Applications"
                            font.pixelSize: 20
                            font.bold: true
                            font.family: "Inter"
                            font.letterSpacing: -0.3
                            color: Theme.foreground
                        }
                        Text {
                            text: "Native Quickshell desktop utilities included with Hyprconf."
                            font.pixelSize: 12
                            color: Theme.muted
                        }
                    }

                    // 3 Big Application Cards
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 180
                        spacing: 12

                        // App 1: Settings Studio
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            clip: true
                            color: Theme.glassCard
                            border.color: Theme.alpha(Theme.foreground, 0.11)
                            border.width: 1

                            Rectangle {
                                z: 2
                                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                                anchors.leftMargin: 14; anchors.rightMargin: 14; height: 1
                                color: Theme.glassRimTop
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 10

                                RowLayout {
                                    spacing: 8
                                    Rectangle {
                                        width: 32
                                        height: 32
                                        radius: 8
                                        color: Theme.alpha(Theme.accent, 0.14)
                                        Image { anchors.centerIn: parent; width: 16; height: 16; source: window.slidersSvg }
                                    }
                                    Text { text: "Settings Studio"; font.pixelSize: 14; font.bold: true; color: Theme.foreground }
                                }

                                Text {
                                    text: "Configure notch physics, top bar modules & styling, dock pinning & auto-hide, draggable lockscreen widgets, and Noctalia wallpaper palettes."
                                    font.pixelSize: 11
                                    color: Theme.muted
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 30
                                    radius: 7
                                    color: app1Area.containsMouse ? Theme.accent : Theme.alpha(Theme.accent, 0.16)
                                    border.color: Theme.alpha(Theme.accent, 0.38)
                                    border.width: 1
                                    scale: app1Area.pressed ? 0.97 : 1.0
                                    Behavior on color { ColorAnimation { duration: 130 } }
                                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Open Settings"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: app1Area.containsMouse ? Theme.background : Theme.accent
                                    }

                                    MouseArea {
                                        id: app1Area
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: window.dispatchCmd("bash ~/.hyprconf/hypr/scripts/sh/qs-settings.sh &")
                                    }
                                }
                            }
                        }

                        // App 2: Package Updater
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            clip: true
                            color: Theme.glassCard
                            border.color: Theme.alpha(Theme.foreground, 0.11)
                            border.width: 1

                            Rectangle {
                                z: 2
                                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                                anchors.leftMargin: 14; anchors.rightMargin: 14; height: 1
                                color: Theme.glassRimTop
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 10

                                RowLayout {
                                    spacing: 8
                                    Rectangle {
                                        width: 32
                                        height: 32
                                        radius: 8
                                        color: Theme.alpha(Theme.accent, 0.14)
                                        Image { anchors.centerIn: parent; width: 16; height: 16; source: window.packageSvg }
                                    }
                                    Text { text: "Package Updater"; font.pixelSize: 14; font.bold: true; color: Theme.foreground }
                                }

                                Text {
                                    text: "Maintain official Pacman packages, AUR packages via paru/yay, and Flatpaks with live output streaming."
                                    font.pixelSize: 11
                                    color: Theme.muted
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 30
                                    radius: 7
                                    color: app2Area.containsMouse ? Theme.accent : Theme.alpha(Theme.accent, 0.16)
                                    border.color: Theme.alpha(Theme.accent, 0.38)
                                    border.width: 1
                                    scale: app2Area.pressed ? 0.97 : 1.0
                                    Behavior on color { ColorAnimation { duration: 130 } }
                                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Open Updater"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: app2Area.containsMouse ? Theme.background : Theme.accent
                                    }

                                    MouseArea {
                                        id: app2Area
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: window.dispatchCmd("bash ~/.hyprconf/hypr/scripts/sh/qs-updater.sh &")
                                    }
                                }
                            }
                        }

                        // App 3: Keybinds Cheatsheet
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            clip: true
                            color: Theme.glassCard
                            border.color: Theme.alpha(Theme.foreground, 0.11)
                            border.width: 1

                            Rectangle {
                                z: 2
                                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                                anchors.leftMargin: 14; anchors.rightMargin: 14; height: 1
                                color: Theme.glassRimTop
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 10

                                RowLayout {
                                    spacing: 8
                                    Rectangle {
                                        width: 32
                                        height: 32
                                        radius: 8
                                        color: Theme.alpha(Theme.accent, 0.14)
                                        Image { anchors.centerIn: parent; width: 16; height: 16; source: window.keyboardSvg }
                                    }
                                    Text { text: "Keybinds Cheatsheet"; font.pixelSize: 14; font.bold: true; color: Theme.foreground }
                                }

                                Text {
                                    text: "Interactive, searchable modal displaying all active Hyprland window rules, gestures, and workspace bindings."
                                    font.pixelSize: 11
                                    color: Theme.muted
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 30
                                    radius: 7
                                    color: app3Area.containsMouse ? Theme.accent : Theme.alpha(Theme.accent, 0.16)
                                    border.color: Theme.alpha(Theme.accent, 0.38)
                                    border.width: 1
                                    scale: app3Area.pressed ? 0.97 : 1.0
                                    Behavior on color { ColorAnimation { duration: 130 } }
                                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Open Cheatsheet"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: app3Area.containsMouse ? Theme.background : Theme.accent
                                    }

                                    MouseArea {
                                        id: app3Area
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: window.dispatchCmd("qs ipc -c island call island openKeybinds")
                                    }
                                }
                            }
                        }
                    }

                    // Documentation & References Row
                    Text {
                        text: "DOCUMENTATION & LINKS"
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 0.8
                        color: Theme.muted
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Repeater {
                            model: [
                                { label: "Hyprland Wiki", url: "https://wiki.hypr.land/", icon: window.bookSvg },
                                { label: "Quickshell Docs", url: "https://quickshell.outfoxxed.me/", icon: window.bookSvg },
                                { label: "Hyprconf on GitHub", url: "https://github.com/shell-ninja/hyprconf", icon: window.gitSvg }
                            ]

                            Rectangle {
                                Layout.fillWidth: true
                                height: 38
                                radius: 8
                                color: linkArea.containsMouse ? Theme.glassElevated : Theme.glassCard
                                border.color: linkArea.containsMouse ? Theme.alpha(Theme.accent, 0.36) : Theme.alpha(Theme.foreground, 0.10)
                                border.width: 1
                                scale: linkArea.pressed ? 0.97 : 1.0
                                Behavior on color { ColorAnimation { duration: 130 } }
                                Behavior on border.color { ColorAnimation { duration: 130 } }
                                Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Image { width: 14; height: 14; source: modelData.icon }
                                    Text {
                                        text: modelData.label
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: Theme.foreground
                                    }
                                }

                                MouseArea {
                                    id: linkArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Qt.openUrlExternally(modelData.url)
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }

                // ═════════════════════════════════════════════════════════════
                // PAGE 4: GET STARTED (PREFERENCES & FINISH)
                // ═════════════════════════════════════════════════════════════
                ColumnLayout {
                    anchors.fill: parent
                    visible: window.activePage === 4
                    spacing: 20

                    Item { Layout.fillHeight: true }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 12

                        // Success checkmark halo
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 72
                            height: 72
                            radius: 36
                            color: Theme.alpha("#22c55e", 0.12)
                            border.color: Theme.alpha("#22c55e", 0.35)
                            border.width: 1.5

                            Image {
                                anchors.centerIn: parent
                                width: 32
                                height: 32
                                source: window.checkSvg
                            }
                        }

                        Text {
                            text: "You're All Set!"
                            font.pixelSize: 24
                            font.bold: true
                            font.family: "Inter"
                            font.letterSpacing: -0.4
                            color: Theme.foreground
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "Your obsidian desktop environment is fully configured. Customize preferences below or launch directly into your workflow."
                            font.pixelSize: 12
                            font.family: "Inter"
                            color: Theme.muted
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            Layout.maximumWidth: 500
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    // Startup Preference Card
                    Rectangle {
                        Layout.preferredWidth: 520
                        Layout.alignment: Qt.AlignHCenter
                        height: 64
                        radius: 12
                        clip: true
                        color: Theme.glassCard
                        border.color: Theme.alpha(Theme.foreground, 0.11)
                        border.width: 1

                        Rectangle {
                            z: 2
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                            anchors.leftMargin: 16; anchors.rightMargin: 16; height: 1
                            color: Theme.glassRimTop
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 18
                            anchors.rightMargin: 18
                            spacing: 14

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: "Launch Welcome App on Startup"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Theme.foreground
                                }
                                Text {
                                    text: "Show this onboarding guide whenever logging into Hyprland"
                                    font.pixelSize: 10
                                    color: Theme.muted
                                }
                            }

                            // Capsule Switch
                            Rectangle {
                                width: 44
                                height: 24
                                radius: 12
                                color: window.showOnStartup ? Theme.accent : Theme.alpha(Theme.foreground, 0.20)

                                Rectangle {
                                    width: 18
                                    height: 18
                                    radius: 9
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: window.showOnStartup ? parent.width - width - 3 : 3
                                    color: window.showOnStartup ? Theme.background : Theme.foreground
                                    Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: window.toggleStartupState(!window.showOnStartup)
                                }
                            }
                        }
                    }

                    // Action buttons
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 12

                        // Finish button
                        Rectangle {
                            width: 220
                            height: 40
                            radius: 10
                            clip: true
                            color: finishArea.containsMouse ? Qt.lighter(Theme.accent, 1.12) : Theme.accent
                            scale: finishArea.pressed ? 0.97 : (finishArea.containsMouse ? 1.02 : 1.0)
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                            Rectangle {
                                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                                anchors.leftMargin: 14; anchors.rightMargin: 14; height: 1
                                color: Theme.alpha("#ffffff", 0.35)
                            }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Text {
                                    text: "Start Using Hyprconf"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.background
                                }
                                Image { width: 14; height: 14; source: window.arrowRightSvg }
                            }

                            MouseArea {
                                id: finishArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Qt.quit()
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // ── BOTTOM NAVIGATION BAR ─────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                spacing: 12

                // Left: Skip button
                Rectangle {
                    visible: window.activePage < 4
                    Layout.preferredWidth: 80
                    height: 34
                    radius: 8
                    color: skipArea.containsMouse ? Theme.alpha(Theme.surface, 0.85) : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "Skip Guide"
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.muted
                    }

                    MouseArea {
                        id: skipArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.quit()
                    }
                }

                Item { Layout.fillWidth: true }

                // Center: Dot / Pill Page Indicator
                RowLayout {
                    spacing: 6

                    Repeater {
                        model: 5

                        Rectangle {
                            height: 6
                            width: window.activePage === index ? 20 : 6
                            radius: 3
                            color: window.activePage === index ? Theme.accent : Theme.alpha(Theme.foreground, 0.20)
                            Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: window.activePage = index
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Right: Back & Next Buttons
                RowLayout {
                    spacing: 8

                    // Back button
                    Rectangle {
                        visible: window.activePage > 0
                        width: 80
                        height: 34
                        radius: 8
                        color: backArea.containsMouse ? Theme.glassElevated : Theme.glassCard
                        border.color: backArea.containsMouse ? Theme.alpha(Theme.foreground, 0.24) : Theme.alpha(Theme.foreground, 0.12)
                        border.width: 1
                        scale: backArea.pressed ? 0.96 : 1.0
                        Behavior on color { ColorAnimation { duration: 130 } }
                        Behavior on border.color { ColorAnimation { duration: 130 } }
                        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Image { width: 12; height: 12; source: window.arrowLeftSvg }
                            Text {
                                text: "Back"
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.foreground
                            }
                        }

                        MouseArea {
                            id: backArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (window.activePage > 0) window.activePage--
                            }
                        }
                    }

                    // Next / Finish button
                    Rectangle {
                        width: window.activePage === 4 ? 100 : 80
                        height: 34
                        radius: 8
                        clip: true
                        color: nextArea.containsMouse ? Qt.lighter(Theme.accent, 1.12) : Theme.accent
                        scale: nextArea.pressed ? 0.96 : (nextArea.containsMouse ? 1.02 : 1.0)
                        Behavior on color { ColorAnimation { duration: 130 } }
                        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

                        Rectangle {
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                            anchors.leftMargin: 10; anchors.rightMargin: 10; height: 1
                            color: Theme.alpha("#ffffff", 0.35)
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: window.activePage === 4 ? "Done" : "Next"
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.background
                            }
                            Image {
                                width: 12
                                height: 12
                                source: window.arrowRightSvg
                                visible: window.activePage < 4
                            }
                        }

                        MouseArea {
                            id: nextArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (window.activePage < 4) {
                                    window.activePage++
                                } else {
                                    Qt.quit()
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── KEYBOARD LAYOUT SELECTOR MODAL OVERLAY ───────────────────────────
        Rectangle {
            id: kbModalOverlay
            anchors.fill: parent
            visible: window.kbModalOpen
            color: Theme.alpha(Theme.background, 0.82)
            z: 100

            // Backdrop click dismisses
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.ArrowCursor
                onClicked: window.kbModalOpen = false
            }

            Rectangle {
                id: kbModalDialog
                width: 520
                height: 480
                anchors.centerIn: parent
                radius: 16
                color: Theme.glassElevated
                border.color: Theme.alpha(Theme.accent, 0.38)
                border.width: 1.5
                clip: true

                Rectangle {
                    z: 2
                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: 20; anchors.rightMargin: 20; height: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.25; color: Theme.glassRimTop }
                        GradientStop { position: 0.5; color: Theme.alpha("#ffffff", 0.32) }
                        GradientStop { position: 0.75; color: Theme.glassRimTop }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                // Consume clicks inside dialog
                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    // Modal Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            width: 36
                            height: 36
                            radius: 10
                            color: Theme.alpha(Theme.accent, 0.15)
                            border.color: Theme.alpha(Theme.accent, 0.35)
                            border.width: 1

                            Image {
                                anchors.centerIn: parent
                                width: 18
                                height: 18
                                source: window.keyboardSvg
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: "Select Keyboard Layout"
                                font.pixelSize: 15
                                font.bold: true
                                color: Theme.foreground
                            }
                            Text {
                                text: "Choose from 99 system XKB layouts or specify a custom code."
                                font.pixelSize: 11
                                color: Theme.muted
                            }
                        }

                        // Close (X) button
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 7
                            color: modalCloseMa.containsMouse ? Theme.alpha("#ef4444", 0.20) : Theme.alpha(Theme.foreground, 0.06)
                            border.color: modalCloseMa.containsMouse ? Theme.alpha("#ef4444", 0.50) : Theme.alpha(Theme.foreground, 0.10)
                            border.width: 1

                            Image {
                                anchors.centerIn: parent
                                width: 12
                                height: 12
                                source: window.closeSvg
                            }

                            MouseArea {
                                id: modalCloseMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: window.kbModalOpen = false
                            }
                        }
                    }

                    // Search input
                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: 8
                        color: Theme.alpha(Theme.background, 0.85)
                        border.color: kbSearchInput.activeFocus ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Image {
                                width: 14
                                height: 14
                                source: window.searchSvg
                            }

                            TextInput {
                                id: kbSearchInput
                                Layout.fillWidth: true
                                text: window.kbSearchQuery
                                font.pixelSize: 12
                                color: Theme.foreground
                                clip: true
                                verticalAlignment: TextInput.AlignVCenter
                                onTextChanged: {
                                    window.kbSearchQuery = text
                                    window.updateFilteredLayouts()
                                }
                                onAccepted: {
                                    if (customOptionCard.visible) {
                                        window.setKeyboardLayout(customOptionCard.trimmedQuery)
                                        window.kbModalOpen = false
                                    } else if (window.filteredKbLayouts && window.filteredKbLayouts.length > 0) {
                                        window.setKeyboardLayout(window.filteredKbLayouts[0].code)
                                        window.kbModalOpen = false
                                    }
                                }

                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: "Search by language, country, or code (e.g. de, fr, swedish)..."
                                    font.pixelSize: 12
                                    color: Theme.muted
                                    visible: !kbSearchInput.text
                                }
                            }

                            // Clear button
                            Text {
                                visible: kbSearchInput.text.length > 0
                                text: "✕"
                                font.pixelSize: 11
                                color: Theme.muted
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        kbSearchInput.text = ""
                                        kbSearchInput.forceActiveFocus()
                                    }
                                }
                            }
                        }
                    }

                    // Optional Custom Entry Card (if query doesn't match an exact code in filtered list)
                    Rectangle {
                        id: customOptionCard
                        readonly property string trimmedQuery: window.kbSearchQuery.trim().toLowerCase()
                        readonly property bool showCustom: trimmedQuery.length > 0 && !window.filteredKbLayouts.some(function(i){ return i.code.toLowerCase() === trimmedQuery })
                        visible: showCustom
                        Layout.fillWidth: true
                        height: 36
                        radius: 8
                        color: customMa.containsMouse ? Theme.alpha(Theme.accent, 0.20) : Theme.alpha(Theme.accent, 0.08)
                        border.color: Theme.alpha(Theme.accent, 0.35)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text {
                                text: "Custom layout code:"
                                font.pixelSize: 11
                                color: Theme.muted
                            }

                            Rectangle {
                                height: 20
                                implicitWidth: customCodeText.implicitWidth + 10
                                radius: 4
                                color: Theme.alpha(Theme.accent, 0.25)
                                Text {
                                    id: customCodeText
                                    anchors.centerIn: parent
                                    text: customOptionCard.trimmedQuery
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Theme.accent
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: "Apply ↵"
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.accent
                            }
                        }

                        MouseArea {
                            id: customMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                window.setKeyboardLayout(customOptionCard.trimmedQuery)
                                window.kbModalOpen = false
                            }
                        }
                    }

                    // Layouts List
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: Theme.alpha(Theme.background, 0.40)
                        border.color: Theme.alpha(Theme.foreground, 0.06)
                        border.width: 1
                        clip: true

                        ListView {
                            id: kbList
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 2
                            model: window.filteredKbLayouts
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: ScrollBar {
                                active: true
                                policy: ScrollBar.AsNeeded
                            }

                            delegate: Rectangle {
                                width: kbList.width
                                height: 34
                                radius: 6
                                readonly property bool isSelected: window.currentKbLayout === modelData.code
                                color: isSelected
                                    ? Theme.alpha(Theme.accent, 0.22)
                                    : (itemMa.containsMouse ? Theme.alpha(Theme.foreground, 0.06) : "transparent")
                                border.color: isSelected ? Theme.alpha(Theme.accent, 0.40) : "transparent"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 10

                                    // Layout Code Badge
                                    Rectangle {
                                        width: 32
                                        height: 20
                                        radius: 4
                                        color: parent.parent.isSelected ? Theme.accent : Theme.alpha(Theme.surface, 0.90)
                                        border.color: parent.parent.isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.code.toUpperCase()
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: parent.parent.parent.isSelected ? Theme.background : Theme.foreground
                                        }
                                    }

                                    // Full Name
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        font.pixelSize: 12
                                        font.bold: parent.parent.isSelected
                                        color: parent.parent.isSelected ? Theme.accent : Theme.foreground
                                        elide: Text.ElideRight
                                    }

                                    // Checkmark
                                    Image {
                                        visible: parent.parent.isSelected
                                        width: 14
                                        height: 14
                                        source: window.checkSvg
                                    }
                                }

                                MouseArea {
                                    id: itemMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        window.setKeyboardLayout(modelData.code)
                                        window.kbModalOpen = false
                                    }
                                }
                            }

                            // Empty state
                            Text {
                                anchors.centerIn: parent
                                visible: kbList.count === 0 && !customOptionCard.showCustom
                                text: "No matching layouts found"
                                font.pixelSize: 12
                                color: Theme.muted
                            }
                        }
                    }

                    // Modal Footer
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: "Saves to ~/.hyprconf/hypr/configs/settings.lua"
                            font.pixelSize: 10
                            color: Theme.muted
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            width: 76
                            height: 28
                            radius: 6
                            color: closeBtnMa.containsMouse ? Theme.alpha(Theme.foreground, 0.12) : Theme.alpha(Theme.surface, 0.80)
                            border.color: Theme.alpha(Theme.foreground, 0.12)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "Done"
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.foreground
                            }

                            MouseArea {
                                id: closeBtnMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: window.kbModalOpen = false
                            }
                        }
                    }
                }
            }

            Timer {
                id: focusTimer
                interval: 50
                onTriggered: kbSearchInput.forceActiveFocus()
            }
        }
    }
}
