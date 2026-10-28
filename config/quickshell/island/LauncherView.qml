import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "."

Item {
    id: root

    property bool active: false
    property bool isClosing: false
    property real animProgress: 1.0
    signal closeRequested()
    signal openThemeSwitcherRequested()

    readonly property bool isIslandView: true

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : "/home/shell-ninja"
    }

    readonly property string configPath: homeDir + "/.local/share/hyprconf/launcher.json"
    property real wallpaperTimestamp: Date.now()
    readonly property string quadWallPath: "file://" + homeDir + "/.hyprconf/hypr/.cache/wall.quad"
    readonly property string fallbackWallPath: "file://" + homeDir + "/.hyprconf/hypr/.cache/current_wallpaper.png"

    // Active Theme: "style-1" (Slanted Split 880x420) or "style-2" (Panoramic Grid 820x560)
    property string currentTheme: "style-1"

    readonly property real preferredWidth: (currentTheme === "style-2") ? 820 : 880
    readonly property real preferredHeight: (currentTheme === "style-2") ? 560 : 420
    implicitWidth: preferredWidth
    implicitHeight: preferredHeight

    // Model and filtering state
    property var allApps: []
    property var filteredApps: []
    property string activeCategory: "All"
    property int selectedIndex: 0
    property string searchQuery: ""

    // Read active launcher theme from config.json
    Process {
        id: configReader
        command: ["cat", root.configPath]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(text.trim())
                        if (parsed.theme && parsed.theme !== root.currentTheme) {
                            root.currentTheme = parsed.theme
                        }
                    } catch(e) {}
                }
            }
        }
    }

    // SVG icon helpers
    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    readonly property string searchSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>')
    readonly property string clearSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.muted + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>')
    readonly property string defaultAppSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect><circle cx="8.5" cy="8.5" r="1.5"></circle><polyline points="21 15 16 10 5 21"></polyline></svg>')
    readonly property string enterKeySvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 10 4 15 9 20"></polyline><path d="M20 4v7a4 4 0 0 1-4 4H4"></path></svg>')
    readonly property string paletteSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="13.5" cy="6.5" r=".5" fill="' + Theme.foreground + '"/><circle cx="17.5" cy="10.5" r=".5" fill="' + Theme.foreground + '"/><circle cx="8.5" cy="7.5" r=".5" fill="' + Theme.foreground + '"/><circle cx="6.5" cy="12.5" r=".5" fill="' + Theme.foreground + '"/><path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.926 0 1.648-.746 1.648-1.688 0-.437-.18-.835-.437-1.125-.29-.289-.438-.652-.438-1.125a1.64 1.64 0 0 1 1.668-1.668h1.996c3.051 0 5.555-2.503 5.555-5.554C21.965 6.012 17.461 2 12 2z"/></svg>')
    readonly property string windowSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><line x1="3" y1="9" x2="21" y2="9"/><line x1="9" y1="21" x2="9" y2="9"/></svg>')
    readonly property string closeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>')

    // ── APPLICATION SEARCH & RELEVANCE SCORING ENGINE ─────────────────────────
    function updateFilteredApps() {
        var q = searchQuery.toLowerCase().trim()
        var cat = activeCategory

        if (q.length === 0) {
            if (cat === "All") {
                filteredApps = allApps
            } else {
                var catOnly = []
                for (var i = 0; i < allApps.length; i++) {
                    var a = allApps[i]
                    var categories = a.categories || []
                    var matched = false
                    for (var c = 0; c < categories.length; c++) {
                        var curCat = categories[c].toLowerCase()
                        if (cat === "Internet" && (curCat.indexOf("network") !== -1 || curCat.indexOf("web") !== -1 || curCat.indexOf("browser") !== -1)) {
                            matched = true; break
                        } else if (cat === "Development" && (curCat.indexOf("development") !== -1 || curCat.indexOf("ide") !== -1 || curCat.indexOf("programming") !== -1)) {
                            matched = true; break
                        } else if (cat === "Media" && (curCat.indexOf("audio") !== -1 || curCat.indexOf("video") !== -1 || curCat.indexOf("graphics") !== -1 || curCat.indexOf("media") !== -1)) {
                            matched = true; break
                        } else if (cat === "System" && (curCat.indexOf("system") !== -1 || curCat.indexOf("utility") !== -1 || curCat.indexOf("settings") !== -1)) {
                            matched = true; break
                        }
                    }
                    if (matched) catOnly.push(a)
                }
                filteredApps = catOnly
            }
            selectedIndex = 0
            return
        }

        var tokens = q.split(/\s+/).filter(function(t) { return t.length > 0 })
        var scored = []

        for (var i = 0; i < allApps.length; i++) {
            var app = allApps[i]

            if (cat !== "All") {
                var categories = app.categories || []
                var catMatched = false
                for (var c = 0; c < categories.length; c++) {
                    var curCat = categories[c].toLowerCase()
                    if (cat === "Internet" && (curCat.indexOf("network") !== -1 || curCat.indexOf("web") !== -1 || curCat.indexOf("browser") !== -1)) {
                        catMatched = true; break
                    } else if (cat === "Development" && (curCat.indexOf("development") !== -1 || curCat.indexOf("ide") !== -1 || curCat.indexOf("programming") !== -1)) {
                        catMatched = true; break
                    } else if (cat === "Media" && (curCat.indexOf("audio") !== -1 || curCat.indexOf("video") !== -1 || curCat.indexOf("graphics") !== -1 || curCat.indexOf("media") !== -1)) {
                        catMatched = true; break
                    } else if (cat === "System" && (curCat.indexOf("system") !== -1 || curCat.indexOf("utility") !== -1 || curCat.indexOf("settings") !== -1)) {
                        catMatched = true; break
                    }
                }
                if (!catMatched) continue
            }

            var name = (app.name || "").toLowerCase()
            var cmd = (app.exec || "").toLowerCase()
            var id = (app.id || "").toLowerCase()
            var gen = (app.generic_name || "").toLowerCase()
            var comment = (app.comment || "").toLowerCase()
            var cats = (app.categories ? app.categories.join(" ").toLowerCase() : "")
            var fullBlob = name + " " + gen + " " + cmd + " " + id + " " + comment + " " + cats

            var allTokensMatch = true
            for (var t = 0; t < tokens.length; t++) {
                if (fullBlob.indexOf(tokens[t]) === -1) {
                    allTokensMatch = false
                    break
                }
            }
            if (!allTokensMatch) continue

            var score = 0
            if (name === q) score += 20000
            else if (id === q || id === (q + ".desktop")) score += 16000
            else if (cmd === q || cmd.startsWith(q + " ")) score += 14000

            if (name.startsWith(q)) score += 10000
            else if (name.indexOf(" " + q) !== -1 || name.indexOf("-" + q) !== -1) score += 7000
            else if (name.indexOf(q) !== -1) score += 4500

            if (cmd.startsWith(q)) score += 6000
            else if (cmd.indexOf(" " + q) !== -1 || cmd.indexOf("/" + q) !== -1) score += 4000
            else if (cmd.indexOf(q) !== -1) score += 2000

            if (id.startsWith(q)) score += 5000
            else if (id.indexOf(q) !== -1) score += 2500

            if (gen === q || gen.startsWith(q)) score += 3500
            else if (gen.indexOf(q) !== -1) score += 1800

            for (var t = 0; t < tokens.length; t++) {
                var tok = tokens[t]
                if (name.startsWith(tok)) score += 1500
                else if (name.indexOf(" " + tok) !== -1 || name.indexOf("-" + tok) !== -1) score += 1000
                else if (name.indexOf(tok) !== -1) score += 600

                if (cmd.startsWith(tok) || cmd.indexOf("/" + tok) !== -1) score += 800
                else if (cmd.indexOf(tok) !== -1) score += 300
            }

            var lengthPenalty = Math.min(name.length, 50) * 4
            score -= lengthPenalty

            scored.push({ app: app, score: score })
        }

        scored.sort(function(a, b) {
            if (b.score !== a.score) return b.score - a.score
            return a.app.name.localeCompare(b.app.name)
        })

        var res = []
        for (var s = 0; s < scored.length; s++) {
            res.push(scored[s].app)
        }

        filteredApps = res
        selectedIndex = 0
    }

    // ── APPLICATION EXECUTION ────────────────────────────────────────────────
    Process {
        id: execProc
    }

    function launchApp(app) {
        if (!app) return
        var script = homeDir + "/.hyprconf/hypr/scripts/sh/launch-app.sh"
        execProc.command = [script, app.id || "", app.exec || ""]
        execProc.running = true
        root.closeRequested()
    }

    function launchCurrent() {
        if (filteredApps && filteredApps.length > 0 && selectedIndex >= 0 && selectedIndex < filteredApps.length) {
            launchApp(filteredApps[selectedIndex])
        }
    }

    function openThemeSwitcher() {
        root.openThemeSwitcherRequested()
    }

    // ── APPLICATIONS INDEXER ─────────────────────────────────────────────────
    Process {
        id: indexerProc
        command: [homeDir + "/.hyprconf/hypr/scripts/py/app-launcher-index.py"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(text)
                        root.allApps = parsed
                        root.updateFilteredApps()
                    } catch(e) {
                        console.log("[LauncherView] Failed to parse apps JSON:", e)
                    }
                }
            }
        }
    }

    // Forward keyboard events
    function handleKey(event) {
        if (event.key === Qt.Key_Escape) {
            event.accepted = true
            root.closeRequested()
            return true
        }
        return false
    }

    Timer {
        id: focusTimer
        interval: 80
        repeat: false
        onTriggered: root.focusLauncher()
    }

    Timer {
        id: focusTimerSecond
        interval: 180
        repeat: false
        onTriggered: root.focusLauncher()
    }

    function focusLauncher() {
        if (themeLoader.item && typeof themeLoader.item.focusInput === "function") {
            themeLoader.item.focusInput()
        }
    }


    onActiveChanged: {
        if (active) {
            root.wallpaperTimestamp = Date.now()
            if (configReader.running === false) {
                configReader.running = true
            }
            root.searchQuery = ""
            root.activeCategory = "All"
            root.updateFilteredApps()
            if (indexerProc.running === false) {
                indexerProc.running = true
            }
            root.focusLauncher()
            focusTimer.restart()
            focusTimerSecond.restart()
        }
    }

    onAnimProgressChanged: {
        if (animProgress >= 0.75 && active && !isClosing) {
            root.focusLauncher()
        }
    }

    // ── EXPANDING OBSIDIAN ISLAND CONTAINER BACKGROUND ──────────────────────
    Rectangle {
        id: islandMorphBg
        anchors.fill: parent
        radius: (root.currentTheme === "style-2")
                ? (18 + (26 - 18) * root.animProgress)
                : (18 + (20 - 18) * root.animProgress)
        color: Theme.alpha(Theme.background, 0.78)
        border.width: 1
        border.color: (root.currentTheme === "style-2")
                ? Theme.alpha(Theme.foreground, 0.14)
                : Theme.alpha(Theme.accent, 0.35)
    }

    // ── THEME LOADER (FILLS THE EXPANDING ISLAND PANEL) ──────────────────────
    Loader {
        id: themeLoader
        anchors.fill: parent
        focus: true
        opacity: (!root.isClosing && root.animProgress >= 0.75) ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: root.isClosing ? 90 : 150; easing.type: Easing.OutCubic }
        }
        sourceComponent: (root.currentTheme === "style-2") ? style2Component : style1Component

        onLoaded: {
            if (item && typeof item.focusInput === "function") {
                item.focusInput()
            }
        }
    }

    Component {
        id: style1Component
        Style1 {
            rootWindow: root
        }
    }

    Component {
        id: style2Component
        Style2 {
            rootWindow: root
        }
    }
}
