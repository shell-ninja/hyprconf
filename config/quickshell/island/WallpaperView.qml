import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root

    property bool active: false
    property bool isClosing: false
    property real animProgress: 1.0
    signal backClicked()

    implicitWidth: 920
    implicitHeight: 370

    // ── DATA MODELS & STATE ──────────────────────────────────────────────────
    property var allWallpapers: []
    property var filteredWallpapers: []
    property int selectedIndex: 0
    property real visualPosition: 0.0

    onSelectedIndexChanged: {
        visualPosition = selectedIndex
    }

    property string currentWallpaperPath: ""
    property string selectedWallpaperTitle: {
        if (root.isSearchingOnline) {
            return "Searching Wallhaven..."
        }
        if (filteredWallpapers.length === 0 || selectedIndex < 0 || selectedIndex >= filteredWallpapers.length) {
            return root.activeMode === "wallhaven" ? "No Wallpapers Found" : "No Wallpapers"
        }
        return filteredWallpapers[selectedIndex].title || ""
    }

    // Filter controls
    property string activeSort: "toplist"
    property bool catGeneral: true
    property bool catAnime: false
    property bool catPeople: false
    property string activeRes: "All Res"
    property string activeMode: "wallpaper" // "wallpaper", "live", "wallhaven"
    property string searchQuery: ""
    property int onlinePage: 1
    property bool isSearchingOnline: false

    // Smooth visual gliding animation
    Behavior on visualPosition {
        id: visualAnim
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    // Concentric rippling aura phase
    property real glowPhase: 0.0
    NumberAnimation on glowPhase {
        from: 0.0
        to: 6.28318
        duration: 3200
        loops: Animation.Infinite
        running: root.active
    }

    // ── ACTIVE WALLPAPER DIRECTORIES & CONFIG ───────────────────────────────
    property string currentWallpaperDir: Quickshell.env("HOME") + "/.hyprconf/hypr/Wallpaper"
    property string currentLiveDir: Quickshell.env("HOME") + "/.hyprconf/hypr/Wallpaper/Live"
    property string colorVariant: "vibrant"
    property bool isVariantUpdating: false

    Process {
        id: configReader
        command: ["python3", Quickshell.env("HOME") + "/.hyprconf/hypr/scripts/py/pick-wallpaper-dir.py", "--config"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var cfg = JSON.parse(text.trim())
                    if (cfg.wallpaper_dir) root.currentWallpaperDir = cfg.wallpaper_dir
                    if (cfg.live_dir) root.currentLiveDir = cfg.live_dir
                    if (cfg.color_variant) root.colorVariant = cfg.color_variant
                    root.refreshWallpapers()
                } catch(e) {}
            }
        }
    }

    Process {
        id: variantUpdater
        property string targetVariant: ""
        command: []
        running: false
        onExited: {
            root.isVariantUpdating = false
        }
    }

    function setColorVariant(newVariant) {
        if (!newVariant || newVariant === root.colorVariant) return
        root.colorVariant = newVariant
        root.isVariantUpdating = true

        // Persist variant via pick-wallpaper-dir.py using Quickshell.execDetached
        Quickshell.execDetached([
            "python3",
            Quickshell.env("HOME") + "/.hyprconf/hypr/scripts/py/pick-wallpaper-dir.py",
            "--set-variant", newVariant
        ])

        // Immediately trigger live desktop & quickshell palette update
        var wallPath = ""
        if (root.filteredWallpapers.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.filteredWallpapers.length) {
            wallPath = root.filteredWallpapers[root.selectedIndex].path || ""
        }
        variantUpdater.running = false
        if (wallPath && wallPath.length > 0 && wallPath.indexOf("http") !== 0) {
            variantUpdater.command = [
                "python3",
                Quickshell.env("HOME") + "/.hyprconf/hypr/scripts/py/hypr-colors.py",
                wallPath,
                "--variant", newVariant
            ]
        } else {
            variantUpdater.command = [
                "python3",
                Quickshell.env("HOME") + "/.hyprconf/hypr/scripts/py/hypr-colors.py",
                "--variant", newVariant
            ]
        }
        variantUpdater.running = true
    }

    // ── DIRECTORY BROWSER STATE & PROCESSES ─────────────────────────────────
    property bool isBrowsingDirs: false
    property string browsingPath: root.currentWallpaperDir
    property string browsingParentPath: ""
    property int browsingCurrentWallCount: 0
    property int browsingCurrentVideoCount: 0
    property var browsingSubdirs: []
    property var browsingVideos: []
    property var browsingBookmarks: []
    property int dirSelectedIndex: 0
    property int videoSelectedIndex: 0
    property string dirBrowserTab: "folders" // "folders" or "videos"
    property bool isDirLoading: false

    Process {
        id: dirListerProc
        property string targetPath: ""
        command: [
            "python3",
            Quickshell.env("HOME") + "/.hyprconf/hypr/scripts/py/list-wallpaper-dirs.py",
            "--path", targetPath
        ]
        running: false
        stdout: StdioCollector {
            onTextChanged: {
                root.isDirLoading = false
                if (!text || text.trim().length === 0) return
                try {
                    var res = JSON.parse(text.trim())
                    if (res.status === "success") {
                        root.browsingPath = res.current_path
                        root.browsingParentPath = res.parent_path || ""
                        root.browsingCurrentWallCount = res.current_wall_count || 0
                        root.browsingCurrentVideoCount = res.current_video_count || 0
                        root.browsingSubdirs = res.directories || []
                        root.browsingVideos = res.videos || []
                        root.browsingBookmarks = res.bookmarks || []
                        root.dirSelectedIndex = 0
                        root.videoSelectedIndex = 0
                        if (root.browsingSubdirs.length === 0 && root.browsingVideos.length > 0) {
                            root.dirBrowserTab = "videos"
                        }
                    }
                } catch(e) {
                    console.error("Error parsing directory list:", e)
                }
            }
        }
    }

    Process {
        id: dirSaverProc
        property string pathToSave: ""
        command: [
            "python3",
            Quickshell.env("HOME") + "/.hyprconf/hypr/scripts/py/pick-wallpaper-dir.py",
            "--set", pathToSave
        ]
        running: false
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var parsed = JSON.parse(text.trim())
                    if (parsed.status === "success" && parsed.path) {
                        if (root.activeMode === "live") {
                            root.currentLiveDir = parsed.path
                        } else {
                            root.currentWallpaperDir = parsed.path
                        }
                        root.refreshWallpapers()
                    }
                } catch(e) {}
            }
        }
    }

    Process {
        id: videoChooserProc
        command: [
            "python3",
            Quickshell.env("HOME") + "/.hyprconf/hypr/scripts/py/pick-wallpaper-dir.py",
            "--pick-video"
        ]
        running: false
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var res = JSON.parse(text.trim())
                    if (res.status === "success" && res.file) {
                        root.closeDirBrowser()
                        root.backClicked()
                        root.refreshWallpapers()
                    }
                } catch(e) {}
            }
        }
    }

    // ── WALLPAPER SCANNING PROCESS (WALLPAPER & LIVE) ────────────────────────
    Process {
        id: wallScanner
        running: false
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var parsed = JSON.parse(text.trim())
                    if (Array.isArray(parsed) && (root.activeMode === "wallpaper" || root.activeMode === "live")) {
                        root.allWallpapers = parsed
                        root.applyFilter()
                        root.selectedIndex = 0
                        root.visualPosition = 0
                        if (root.activeMode === "wallpaper") {
                            root.detectCurrentWallpaper()
                        } else if (root.activeMode === "live") {
                            root.detectCurrentLiveWallpaper()
                        }
                    }
                } catch(e) {
                    console.error("Error parsing wallpapers JSON:", e)
                }
            }
        }
    }

    Process {
        id: currentWallReader
        command: ["bash", "-c", "cat \"$HOME/.hyprconf/hypr/.cache/.wallpaper\" 2>/dev/null || true"]
        running: false
        stdout: StdioCollector {
            onTextChanged: {
                if (!text) return
                var activeName = text.trim()
                if (activeName.length > 0 && root.allWallpapers.length > 0 && root.activeMode === "wallpaper") {
                    for (var i = 0; i < root.allWallpapers.length; i++) {
                        if (root.allWallpapers[i].title && root.allWallpapers[i].title.toLowerCase() === activeName.toLowerCase()) {
                            root.selectedIndex = i
                            root.visualPosition = i
                            break
                        }
                    }
                }
            }
        }
    }

    Process {
        id: currentLiveReader
        command: ["bash", "-c", "cat \"$HOME/.hyprconf/hypr/.cache/.live_wallpaper\" 2>/dev/null || true"]
        running: false
        stdout: StdioCollector {
            onTextChanged: {
                if (!text) return
                var activePath = text.trim()
                if (activePath.length > 0 && root.allWallpapers.length > 0 && root.activeMode === "live") {
                    for (var i = 0; i < root.allWallpapers.length; i++) {
                        if (root.allWallpapers[i].path === activePath || root.allWallpapers[i].filename === activePath) {
                            root.selectedIndex = i
                            root.visualPosition = i
                            break
                        }
                    }
                }
            }
        }
    }

    // ── WALLHAVEN ONLINE API PROCESS ─────────────────────────────────────────
    Process {
        id: onlineScanner
        running: false
        stdout: StdioCollector {
            onTextChanged: {
                root.isSearchingOnline = false
                if (!text || text.trim().length === 0) return
                try {
                    var parsed = JSON.parse(text.trim())
                    if (Array.isArray(parsed) && parsed.length > 0) {
                        if (root.onlinePage > 1) {
                            root.allWallpapers = root.allWallpapers.concat(parsed)
                        } else {
                            root.allWallpapers = parsed
                        }
                        root.applyFilter()
                        if (root.onlinePage === 1) {
                            root.selectedIndex = 0
                            root.visualPosition = 0
                        }
                    }
                } catch(e) {
                    console.error("Wallhaven JSON parse error:", e)
                }
            }
        }
    }

    Timer {
        id: applyTimer
        interval: 220
        repeat: false
        onTriggered: {
            if (applyProc.targetPath && applyProc.targetPath.length > 0) {
                if (applyProc.targetPath.indexOf("http://") === 0 || applyProc.targetPath.indexOf("https://") === 0) {
                    applyProc.command = [
                        "python3",
                        Quickshell.env("HOME") + "/.hyprconf/hypr/scripts/py/wallhaven-bridge.py",
                        "apply",
                        "--url", applyProc.targetPath
                    ]
                } else {
                    var applyArgs = [
                        "bash",
                        Quickshell.env("HOME") + "/.hyprconf/hypr/scripts/sh/Wallpaper.sh",
                        applyProc.isLive ? "--live" : "--static"
                    ]
                    if (root.colorVariant && root.colorVariant.length > 0) {
                        applyArgs.push("--variant")
                        applyArgs.push(root.colorVariant)
                    }
                    applyArgs.push(applyProc.targetPath)
                    applyProc.command = applyArgs
                }
                applyProc.running = true
            }
        }
    }

    Process {
        id: applyProc
        running: false
        property string targetPath: ""
        property bool isLive: false
        onExited: {
            applyBtn.isApplying = false
        }
    }

    function refreshWallpapers() {
        if (root.activeMode === "wallhaven") {
            root.fetchOnlineWallpapers(1)
            return
        }
        var targetDir = (root.activeMode === "live") ? root.currentLiveDir : root.currentWallpaperDir
        var scanType = (root.activeMode === "live") ? "live" : "wallpaper"
        wallScanner.running = false
        wallScanner.command = [
            "python3",
            Quickshell.env("HOME") + "/.hyprconf/hypr/scripts/py/scan-wallpapers.py",
            "--dir", targetDir,
            "--type", scanType,
            "--depth", "1"
        ]
        wallScanner.running = true
    }

    function applyVideoWallpaper(path) {
        if (!path) return
        applyBtn.isApplying = true
        applyProc.targetPath = path
        applyProc.isLive = true
        root.closeDirBrowser()
        root.backClicked()
        applyTimer.restart()
    }

    function fetchOnlineWallpapers(page) {
        if (page === undefined) page = 1
        root.onlinePage = page
        root.isSearchingOnline = true
        var q = root.searchQuery.trim()
        var sort = root.activeSort
        var cat = (root.catGeneral ? "1" : "0") + (root.catAnime ? "1" : "0") + (root.catPeople ? "1" : "0")
        var res = root.activeRes
        onlineScanner.running = false
        onlineScanner.command = [
            "python3",
            root.homeDir + "/.hyprconf/hypr/scripts/py/wallhaven-bridge.py",
            "search",
            "--query", q,
            "--sorting", sort,
            "--categories", cat,
            "--resolution", res,
            "--page", page.toString()
        ]
        onlineScanner.running = true
    }

    function detectCurrentWallpaper() {
        if (!currentWallReader.running) currentWallReader.running = true
    }

    function detectCurrentLiveWallpaper() {
        if (!currentLiveReader.running) currentLiveReader.running = true
    }

    function openDirBrowser() {
        root.isBrowsingDirs = true
        root.browsingPath = (root.activeMode === "live") ? root.currentLiveDir : root.currentWallpaperDir
        root.dirBrowserTab = (root.activeMode === "live") ? "videos" : "folders"
        root.dirSelectedIndex = 0
        root.videoSelectedIndex = 0
        root.fetchDirectory(root.browsingPath)
    }

    function closeDirBrowser() {
        root.isBrowsingDirs = false
        root.focusWallpaper()
    }

    function fetchDirectory(path) {
        if (!path || path.trim().length === 0) return
        root.isDirLoading = true
        dirListerProc.running = false
        dirListerProc.targetPath = path
        dirListerProc.command = [
            "python3",
            Quickshell.env("HOME") + "/.hyprconf/hypr/scripts/py/list-wallpaper-dirs.py",
            "--path", path
        ]
        dirListerProc.running = true
    }

    function selectCurrentDirectory(path) {
        var p = (path && path.trim().length > 0) ? path : root.browsingPath
        if (!p) return
        dirSaverProc.running = false
        dirSaverProc.pathToSave = p
        if (root.activeMode === "live") {
            dirSaverProc.command = [
                "python3",
                Quickshell.env("HOME") + "/.hyprconf/hypr/scripts/py/pick-wallpaper-dir.py",
                "--set-live", p
            ]
            root.currentLiveDir = p
        } else {
            dirSaverProc.command = [
                "python3",
                Quickshell.env("HOME") + "/.hyprconf/hypr/scripts/py/pick-wallpaper-dir.py",
                "--set", p
            ]
            root.currentWallpaperDir = p
        }
        dirSaverProc.running = true
        root.isBrowsingDirs = false
        root.refreshWallpapers()
        root.focusWallpaper()
    }

    onActiveChanged: {
        if (active) {
            if (activeMode === "wallhaven") {
                fetchOnlineWallpapers(1)
            } else {
                refreshWallpapers()
            }
            focusTimer.restart()
        } else {
            searchQuery = ""
            searchEntry.text = ""
            isBrowsingDirs = false
        }
    }

    onIsBrowsingDirsChanged: {
        if (isBrowsingDirs) {
            if (dirKeySink) dirKeySink.forceActiveFocus()
        } else {
            root.focusWallpaper()
        }
    }

    Timer {
        id: focusTimer
        interval: 100
        repeat: false
        onTriggered: root.focusWallpaper()
    }

    function focusWallpaper() {
        if (root.isBrowsingDirs) {
            if (dirKeySink) dirKeySink.forceActiveFocus()
        } else {
            if (keySink && !searchEntry.activeFocus) {
                keySink.forceActiveFocus()
            }
        }
    }

    onAnimProgressChanged: {
        if (animProgress >= 0.85 && active && !isClosing && !searchEntry.activeFocus) {
            root.focusWallpaper()
        }
    }

    Component.onCompleted: {
        refreshWallpapers()
    }

    function applyFilter() {
        if (root.activeMode === "wallhaven") {
            root.filteredWallpapers = root.allWallpapers
            if (root.selectedIndex >= root.filteredWallpapers.length) {
                root.selectedIndex = Math.max(0, root.filteredWallpapers.length - 1)
            }
            visualAnim.enabled = false
            root.visualPosition = root.selectedIndex
            visualAnim.enabled = true
            return
        }

        var q = root.searchQuery.trim().toLowerCase()
        var src = root.allWallpapers
        var res = []
        for (var i = 0; i < src.length; i++) {
            var it = src[i]
            var t = (it.title || it.filename || "").toLowerCase()
            var matchSearch = (!q) || (t.indexOf(q) !== -1)
            var matchCat = true
            if (root.catAnime) {
                matchCat = t.indexOf("anime") !== -1 || t.indexOf("girl") !== -1 || t.indexOf("landscape") !== -1
            }
            if (matchSearch && matchCat) {
                res.push(it)
            }
        }
        root.filteredWallpapers = res
        if (root.selectedIndex >= root.filteredWallpapers.length) {
            root.selectedIndex = Math.max(0, root.filteredWallpapers.length - 1)
        }
        visualAnim.enabled = false
        root.visualPosition = root.selectedIndex
        visualAnim.enabled = true
    }

    function selectPrevious() {
        if (root.filteredWallpapers.length === 0) return
        visualAnim.enabled = true
        root.selectedIndex = Math.max(0, root.selectedIndex - 1)
    }

    function selectNext() {
        if (root.filteredWallpapers.length === 0) return
        visualAnim.enabled = true
        root.selectedIndex = Math.min(root.filteredWallpapers.length - 1, root.selectedIndex + 1)
    }

    function confirmSelection() {
        if (applyProc.running || applyBtn.isApplying) return
        if (root.filteredWallpapers.length === 0 || root.selectedIndex < 0 || root.selectedIndex >= root.filteredWallpapers.length) return
        var item = root.filteredWallpapers[root.selectedIndex]
        applyBtn.isApplying = true
        applyProc.targetPath = item.path
        applyProc.isLive = (root.activeMode === "live") || (item.is_video === true)

        // 1. Collapse the wallpaper menu first
        root.backClicked()

        // 2. Apply the wallpaper once collapse animation is initiated
        applyTimer.restart()
    }

    // ── VIM & ARROW KEYBOARD INTERCEPTOR ─────────────────────────────────────
    function handleKey(event) {
        // Handle Directory Browser navigation when active
        if (root.isBrowsingDirs) {
            if (event.key === Qt.Key_Escape) {
                event.accepted = true
                root.closeDirBrowser()
                return true
            }
            // Tab or t key: toggle between folders and videos tabs
            if (event.key === Qt.Key_Tab || event.key === Qt.Key_T) {
                event.accepted = true
                root.dirBrowserTab = (root.dirBrowserTab === "folders") ? "videos" : "folders"
                return true
            }
            if (event.key === Qt.Key_Backspace || event.key === Qt.Key_U) {
                event.accepted = true
                if (root.browsingParentPath && root.browsingParentPath.length > 0 && root.browsingParentPath !== root.browsingPath) {
                    root.fetchDirectory(root.browsingParentPath)
                }
                return true
            }
            if (root.dirBrowserTab === "videos") {
                var totalVids = root.browsingVideos ? root.browsingVideos.length : 0
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    event.accepted = true
                    if (totalVids > 0 && root.videoSelectedIndex >= 0 && root.videoSelectedIndex < totalVids) {
                        root.applyVideoWallpaper(root.browsingVideos[root.videoSelectedIndex].path)
                    }
                    return true
                }
                var vcols = 3
                if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                    event.accepted = true
                    root.videoSelectedIndex = Math.max(0, root.videoSelectedIndex - 1)
                    return true
                } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                    event.accepted = true
                    root.videoSelectedIndex = Math.min(totalVids - 1, root.videoSelectedIndex + 1)
                    return true
                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                    event.accepted = true
                    root.videoSelectedIndex = Math.max(0, root.videoSelectedIndex - vcols)
                    return true
                } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                    event.accepted = true
                    root.videoSelectedIndex = Math.min(totalVids - 1, root.videoSelectedIndex + vcols)
                    return true
                }
                return false
            }
            // Space or Ctrl+Enter: confirm directory selection
            if ((event.key === Qt.Key_Return && (event.modifiers & Qt.ControlModifier)) || event.key === Qt.Key_Space) {
                event.accepted = true
                root.selectCurrentDirectory(root.browsingPath)
                return true
            }
            // Enter key: enter highlighted directory or select current if empty
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                event.accepted = true
                if (root.browsingSubdirs && root.browsingSubdirs.length > 0 &&
                    root.dirSelectedIndex >= 0 && root.dirSelectedIndex < root.browsingSubdirs.length) {
                    var target = root.browsingSubdirs[root.dirSelectedIndex].path
                    root.fetchDirectory(target)
                } else {
                    root.selectCurrentDirectory(root.browsingPath)
                }
                return true
            }
            // Arrow & vim navigation in directory grid (3 columns)
            var total = root.browsingSubdirs ? root.browsingSubdirs.length : 0
            if (total > 0) {
                var cols = 3
                if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                    event.accepted = true
                    root.dirSelectedIndex = Math.max(0, root.dirSelectedIndex - 1)
                    return true
                } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                    event.accepted = true
                    root.dirSelectedIndex = Math.min(total - 1, root.dirSelectedIndex + 1)
                    return true
                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                    event.accepted = true
                    root.dirSelectedIndex = Math.max(0, root.dirSelectedIndex - cols)
                    return true
                } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                    event.accepted = true
                    root.dirSelectedIndex = Math.min(total - 1, root.dirSelectedIndex + cols)
                    return true
                }
            }
            return false
        }

        if (searchEntry.activeFocus) {
            if (event.key === Qt.Key_Escape) {
                event.accepted = true
                if (searchEntry.text.length > 0) {
                    searchEntry.text = ""
                } else {
                    root.focusWallpaper()
                }
                return true
            }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                event.accepted = true
                if (root.activeMode === "wallhaven") {
                    root.fetchOnlineWallpapers(1)
                } else {
                    root.confirmSelection()
                }
                return true
            }
            if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                event.accepted = true
                root.selectPrevious()
                return true
            }
            if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                event.accepted = true
                root.selectNext()
                return true
            }
            return false
        }

        // Global Vim Navigation: h/Left/k/Up, l/Right/j/Down
        if (event.key === Qt.Key_Left || event.key === Qt.Key_H || event.key === Qt.Key_K || event.key === Qt.Key_Up) {
            event.accepted = true
            root.selectPrevious()
            return true
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L || event.key === Qt.Key_J || event.key === Qt.Key_Down) {
            event.accepted = true
            root.selectNext()
            return true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            event.accepted = true
            root.confirmSelection()
            return true
        } else if (event.key === Qt.Key_Slash) {
            event.accepted = true
            searchEntry.forceActiveFocus()
            searchEntry.selectAll()
            return true
        } else if (event.key === Qt.Key_V) {
            event.accepted = true
            var variants = ["vibrant", "muted", "original", "warm", "cool", "pastel"]
            var curIdx = variants.indexOf(root.colorVariant)
            var nextIdx = (curIdx + 1) % variants.length
            root.setColorVariant(variants[nextIdx])
            return true
        } else if (event.key === Qt.Key_Escape) {
            event.accepted = true
            if (variantSelector.isDropdownOpen) {
                variantSelector.isDropdownOpen = false
                return true
            }
            applyTimer.stop()
            applyBtn.isApplying = false
            root.backClicked()
            return true
        }
        return false
    }


    // ── MAIN OBSIDIAN BACKGROUND PANEL ───────────────────────────────────────
    // Remains visible and expands/collapses with the window while preview items fade in/out
    Rectangle {
        id: mainPanelBg
        anchors.top: parent.top
        anchors.topMargin: 35 * root.animProgress
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        radius: 18 + (24 - 18) * root.animProgress
        color: Theme.alpha(Theme.background, 0.88)
        border.color: Theme.alpha(Theme.foreground, 0.14)
        border.width: 1.5
    }

    // ── GLOBAL MOUSE WHEEL SCROLLING HANDLER ─────────────────────────────────
    // Accepts no buttons so clicks pass freely to buttons, but captures wheel events anywhere!
    MouseArea {
        id: globalWheelCatcher
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        enabled: !root.isBrowsingDirs
        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0 || wheel.angleDelta.x < 0) {
                root.selectPrevious()
            } else if (wheel.angleDelta.y < 0 || wheel.angleDelta.x > 0) {
                root.selectNext()
            }
            wheel.accepted = true
        }
    }

    // ── PREVIEW CONTENT (CAROUSEL, FILTER BAR, SEARCH & CONTROLS) ────────────
    // Smoothly fades in after window expansion, and vanishes first on close or when browsing dirs
    Item {
        id: previewContent
        anchors.fill: parent
        opacity: (!root.isClosing && root.animProgress >= 0.88 && !root.isBrowsingDirs) ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: root.isClosing ? 90 : 150
                easing.type: Easing.OutCubic
            }
        }
        visible: opacity > 0.001

        // Keyboard Sink
        Item {
            id: keySink
            anchors.fill: parent
            focus: true
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: function(event) {
                if (root.handleKey(event)) {
                    event.accepted = true
                }
            }
        }

        // ── COVERFLOW VIEWPORT ───────────────────────────────────────────────
        // Anchored with -48px top headroom so hero card + aura float unclipped,
        // and 20px left/right margins with clip: true and opacity fade to strictly prevent border overflow
        Item {
            id: coverflowViewport
            anchors.top: parent.top
            anchors.topMargin: -48
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 20
            height: 288
            clip: true

            // CoverFlow cards (15 circular dynamic slots with jump-free continuous mapping)
            Repeater {
                model: 15
                Item {
                    id: slotItem
                    property int centerBase: Math.round(root.visualPosition)
                    property int delta: ((index - (centerBase % 15) + 15 + 7) % 15) - 7
                    property int cardIndex: centerBase + delta
                    property bool isValid: cardIndex >= 0 && cardIndex < root.filteredWallpapers.length
                    property var cardData: isValid ? root.filteredWallpapers[cardIndex] : null
                    property real effectiveOffset: isValid ? (cardIndex - root.visualPosition) : 0.0
                    property real dist: Math.abs(effectiveOffset)

                    // Mathematical Coverflow Transform directly replicating WallpaperSelect.py
                    property real calcScale: {
                        if (dist < 1.0) {
                            var t = (1.0 + Math.cos(dist * Math.PI)) / 2.0
                            return 0.86 + t * 0.54 // 1.40 at dist=0, 0.86 at dist=1
                        } else {
                            return Math.max(0.48, 0.86 - (dist - 1.0) * 0.13)
                        }
                    }
                    property real yLift: {
                        if (dist < 1.0) {
                            var t = (1.0 + Math.cos(dist * Math.PI)) / 2.0
                            return t * -28.0
                        }
                        return 0.0
                    }
                    property real calcShear: {
                        if (dist < 0.001) return 0.0
                        return (effectiveOffset > 0 ? 0.50 : -0.50) * Math.min(1.0, dist)
                    }

                    // Smooth opacity dropoff: cards smoothly dissolve to 0 before reaching the border!
                    property real calcOpacity: {
                        if (dist > 2.3) return 0.0
                        if (dist > 1.6) {
                            var factor = (2.3 - dist) / (2.3 - 1.6)
                            return (0.20 + (1.0 - 1.6 * 0.18) * 0.8) * Math.max(0.0, Math.min(1.0, factor))
                        }
                        return Math.max(0.20, 1.0 - dist * 0.18)
                    }

                    // Strictly visible only when inside bounds (max 5 cards: hero, 2 left, 2 right)
                    visible: isValid && dist <= 2.3 && calcOpacity > 0.005

                    // Layout coordinates
                    width: 196
                    height: 112
                    x: (coverflowViewport.width / 2) + (effectiveOffset * 155) - (width / 2)
                    y: 164 + yLift - (height / 2)
                    z: Math.round(100 - dist * 8)
                    opacity: calcOpacity
                    scale: calcScale

                    // 2D Cairo-equivalent Shear Matrix
                    transform: Matrix4x4 {
                        matrix: Qt.matrix4x4(1, slotItem.calcShear, 0, 0,
                                             0, 1,                  0, 0,
                                             0, 0,                  1, 0,
                                             0, 0,                  0, 1)
                    }

                    // ── MULTI-RING PULSATING LUMINOUS AURA (FOR HERO CARD) ────
                    Repeater {
                        model: (slotItem.dist < 0.5) ? [
                            { pad: 26, baseAlpha: 0.035 },
                            { pad: 19, baseAlpha: 0.065 },
                            { pad: 13, baseAlpha: 0.110 },
                            { pad: 8,  baseAlpha: 0.170 },
                            { pad: 3,  baseAlpha: 0.250 }
                        ] : []

                        Rectangle {
                            property real wave: 0.5 + 0.5 * Math.sin(root.glowPhase - index * 0.9)
                            property real alpha: modelData.baseAlpha * (0.6 + 0.4 * wave)
                            property real padAnim: modelData.pad + wave * 4.0
                            anchors.centerIn: parent
                            width: parent.width + padAnim * 2
                            height: parent.height + padAnim * 2
                            radius: 14 + padAnim / 2
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, alpha)
                            border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, Math.min(1.0, alpha * 1.5))
                            border.width: 1.0
                            z: -1
                        }
                    }

                    // ── CARD CONTAINER WITH TRUE ANTI-ALIASED ROUNDED CORNER MASK ──
                    Rectangle {
                        id: cardFrame
                        anchors.fill: parent
                        radius: 14
                        color: Theme.surface
                        border.width: slotItem.dist < 0.5 ? 2.8 : (cardMouse.containsMouse ? 2.0 : 1.2)
                        border.color: slotItem.dist < 0.5 ? Theme.accent : (cardMouse.containsMouse ? Theme.alpha(Theme.accent, 0.6) : Theme.alpha(Theme.foreground, 0.18))

                        // Masked Thumbnail with anti-aliased 12px rounded corners
                        Item {
                            id: imgContainer
                            anchors.fill: parent
                            anchors.margins: 2

                            Image {
                                id: cardImg
                                anchors.fill: parent
                                source: slotItem.cardData ? slotItem.cardData.source : ""
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                                asynchronous: true
                                sourceSize: Qt.size(392, 224)
                                visible: false
                            }

                            Item {
                                id: imgMaskItem
                                anchors.fill: parent
                                layer.enabled: true
                                layer.smooth: true
                                visible: false

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 12
                                    color: "#ffffff"
                                    antialiasing: true
                                }
                            }

                            MultiEffect {
                                anchors.fill: parent
                                source: cardImg
                                visible: cardImg.status === Image.Ready
                                maskEnabled: true
                                maskSource: imgMaskItem
                                autoPaddingEnabled: false
                                maskThresholdMin: 0.5
                                maskSpreadAtMin: 1.0
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                color: "#000000"
                                opacity: slotItem.dist < 0.5 ? 0.0 : Math.min(0.40, slotItem.dist * 0.12)
                            }
                        }

                        // Video / GIF Tag Badge
                        Rectangle {
                            id: videoCardBadge
                            visible: slotItem.cardData && slotItem.cardData.is_video
                            anchors.top: parent.top
                            anchors.topMargin: 6
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            height: 18
                            width: videoBadgeRow.implicitWidth + 10
                            radius: 5
                            color: Theme.alpha(Theme.background, 0.88)
                            border.color: Theme.accent
                            border.width: 1
                            z: 30

                            Row {
                                id: videoBadgeRow
                                anchors.centerIn: parent
                                spacing: 3
                                Text {
                                    text: "▶"
                                    font.pixelSize: 8
                                    color: Theme.accent
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: slotItem.cardData ? (slotItem.cardData.ext || "LIVE") : "LIVE"
                                    font.family: "Outfit"
                                    font.pixelSize: 8
                                    font.weight: Font.Bold
                                    color: Theme.foreground
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onWheel: function(wheel) {
                                if (wheel.angleDelta.y > 0 || wheel.angleDelta.x < 0) {
                                    root.selectPrevious()
                                } else if (wheel.angleDelta.y < 0 || wheel.angleDelta.x > 0) {
                                    root.selectNext()
                                }
                                wheel.accepted = true
                            }
                            onClicked: {
                                if (root.selectedIndex === slotItem.cardIndex) {
                                    root.confirmSelection()
                                } else {
                                    root.selectedIndex = slotItem.cardIndex
                                }
                            }
                        }
                    }
                }
            }

            // ── SELECTED WALLPAPER TITLE PILL ────────────────────────────────
            Rectangle {
                id: titlePill
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 196
                height: 24
                width: Math.max(80, titleText.implicitWidth + 24)
                radius: 12
                color: Theme.alpha(Theme.surface, 0.92)
                border.color: Theme.alpha(Theme.accent, 0.55)
                border.width: 1.2
                z: 110
                visible: root.filteredWallpapers.length > 0 || root.isSearchingOnline

                Text {
                    id: titleText
                    anchors.centerIn: parent
                    text: {
                        var base = root.selectedWallpaperTitle
                        if (root.filteredWallpapers.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.filteredWallpapers.length) {
                            var cur = root.filteredWallpapers[root.selectedIndex]
                            if (cur && cur.is_video) {
                                return "▶ " + base + " • LIVE"
                            }
                        }
                        return base
                    }
                    font.family: "Outfit"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: root.isSearchingOnline ? Theme.accent : Theme.foreground
                }
            }
        }

        // ── FILTER TOOLBAR ───────────────────────────────────────────────────
        Rectangle {
            id: filterBar
            anchors.top: coverflowViewport.bottom
            anchors.topMargin: -8
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24
            height: 32
            color: "transparent"

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                // 1. Sorting Group (Wallhaven Mode)
                Repeater {
                    model: (root.activeMode === "wallhaven") ? [
                        { id: "toplist", name: "Toplist" },
                        { id: "hot", name: "Hot" },
                        { id: "latest", name: "Latest" },
                        { id: "random", name: "Random" }
                    ] : []
                    Rectangle {
                        property bool isSelected: root.activeSort === modelData.id
                        width: sortText.implicitWidth + 18
                        height: 26
                        radius: 7
                        color: isSelected ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.50)
                        border.color: isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.10)
                        border.width: 1

                        Text {
                            id: sortText
                            anchors.centerIn: parent
                            text: modelData.name
                            font.family: "Outfit"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: parent.isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.75)
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.activeSort = modelData.id
                                root.fetchOnlineWallpapers(1)
                            }
                        }
                    }
                }

                // Divider 1 (Wallhaven Mode)
                Rectangle {
                    visible: root.activeMode === "wallhaven"
                    width: 1
                    height: 16
                    color: Theme.alpha(Theme.foreground, 0.15)
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Local Location & Count Pill (Wallpaper & Live Modes)
                Rectangle {
                    visible: root.activeMode === "wallpaper" || root.activeMode === "live"
                    height: 26
                    width: dirBadgeContent.implicitWidth + 20
                    radius: 7
                    color: dirBadgeMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.50)
                    border.color: dirBadgeMouse.containsMouse ? Theme.alpha(Theme.accent, 0.5) : Theme.alpha(Theme.foreground, 0.10)
                    border.width: 1

                    Row {
                        id: dirBadgeContent
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: root.activeMode === "live" ? "󰕧" : "󰉋"
                            font.pixelSize: 11
                            color: Theme.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: {
                                var p = (root.activeMode === "live") ? root.currentLiveDir : root.currentWallpaperDir
                                if (!p) return ""
                                var clean = p.replace(/\/+$/, "")
                                var slash = clean.lastIndexOf("/")
                                var base = (slash >= 0) ? clean.substring(slash + 1) : clean
                                var count = root.filteredWallpapers.length
                                return base + "  •  " + count + (root.activeMode === "live" ? (count === 1 ? " video" : " videos") : (count === 1 ? " wallpaper" : " wallpapers"))
                            }
                            font.family: "Outfit"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: Theme.alpha(Theme.foreground, 0.85)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: dirBadgeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openDirBrowser()
                    }
                }

                // 2. Online Mode: Categories Group (General, Anime, People)
                Rectangle {
                    visible: root.activeMode === "wallhaven"
                    property bool isSelected: root.catGeneral
                    width: catGeneralText.implicitWidth + 18
                    height: 26
                    radius: 7
                    color: isSelected ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.50)
                    border.color: isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.10)
                    border.width: 1

                    Text {
                        id: catGeneralText
                        anchors.centerIn: parent
                        text: "General"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: parent.isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.75)
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.catGeneral = !root.catGeneral
                            root.fetchOnlineWallpapers(1)
                        }
                    }
                }

                Rectangle {
                    visible: root.activeMode === "wallhaven"
                    property bool isSelected: root.catAnime
                    width: catAnimeText.implicitWidth + 18
                    height: 26
                    radius: 7
                    color: isSelected ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.50)
                    border.color: isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.10)
                    border.width: 1

                    Text {
                        id: catAnimeText
                        anchors.centerIn: parent
                        text: "Anime"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: parent.isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.75)
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.catAnime = !root.catAnime
                            root.fetchOnlineWallpapers(1)
                        }
                    }
                }

                Rectangle {
                    visible: root.activeMode === "wallhaven"
                    property bool isSelected: root.catPeople
                    width: catPeopleText.implicitWidth + 18
                    height: 26
                    radius: 7
                    color: isSelected ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.50)
                    border.color: isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.10)
                    border.width: 1

                    Text {
                        id: catPeopleText
                        anchors.centerIn: parent
                        text: "People"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: parent.isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.75)
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.catPeople = !root.catPeople
                            root.fetchOnlineWallpapers(1)
                        }
                    }
                }

                // Divider 2 (Wallhaven Mode)
                Rectangle {
                    visible: root.activeMode === "wallhaven"
                    width: 1
                    height: 16
                    color: Theme.alpha(Theme.foreground, 0.15)
                    anchors.verticalCenter: parent.verticalCenter
                }

                // 3. Resolution Selector (Wallhaven Mode)
                Rectangle {
                    visible: root.activeMode === "wallhaven"
                    width: resText.implicitWidth + 18
                    height: 26
                    radius: 7
                    color: Theme.alpha(Theme.surface, 0.50)
                    border.color: Theme.alpha(Theme.foreground, 0.10)
                    border.width: 1

                    Text {
                        id: resText
                        anchors.centerIn: parent
                        text: root.activeRes
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Theme.alpha(Theme.foreground, 0.75)
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var list = ["All Res", "1080p+", "1440p+", "4K+", "21:9 Ultrawide"]
                            var idx = list.indexOf(root.activeRes)
                            root.activeRes = list[(idx + 1) % list.length]
                            root.fetchOnlineWallpapers(1)
                        }
                    }
                }
            }

            // 4. Load More / Shuffle Button
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: loadMoreText.implicitWidth + 18
                height: 26
                radius: 7
                color: loadMoreMouse.containsMouse ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surface, 0.50)
                border.color: loadMoreMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.10)
                border.width: 1

                Row {
                    id: loadMoreText
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: root.activeMode === "wallhaven" ? "✦" : "🎲"
                        font.pixelSize: 11
                        color: Theme.accent
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: root.activeMode === "wallhaven" ? "+24 More" : "Shuffle"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Theme.alpha(Theme.foreground, 0.85)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: loadMoreMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.activeMode === "wallhaven") {
                            root.fetchOnlineWallpapers(root.onlinePage + 1)
                        } else {
                            var copy = root.filteredWallpapers.slice()
                            copy.sort(function() { return 0.5 - Math.random() })
                            root.filteredWallpapers = copy
                            root.selectedIndex = 0
                        }
                    }
                }
            }
        }

        // ── BOTTOM CONTROL BAR ───────────────────────────────────────────────
        Item {
            id: bottomBar
            anchors.top: filterBar.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24
            height: 38

            // 3-Way Mode Segment Bar (󰸉 Wallpapers | 󰕧 Live | ★ Wallhaven)
            Rectangle {
                id: modeSegmentBar
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                height: 36
                width: modeSegmentRow.implicitWidth + 8
                radius: 10
                color: Theme.alpha(Theme.surface, 0.65)
                border.color: Theme.alpha(Theme.foreground, 0.12)
                border.width: 1

                Row {
                    id: modeSegmentRow
                    anchors.centerIn: parent
                    spacing: 3

                    // Segment: Wallpapers (Static Images)
                    Rectangle {
                        property bool isCurrent: root.activeMode === "wallpaper"
                        height: 28
                        width: segWallContent.implicitWidth + 14
                        radius: 8
                        color: isCurrent ? Theme.alpha(Theme.accent, 0.26) : (segWallMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.08) : "transparent")
                        border.color: isCurrent ? Theme.accent : "transparent"
                        border.width: 1

                        Row {
                            id: segWallContent
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: "󰸉"
                                font.pixelSize: 11
                                color: parent.parent.isCurrent ? Theme.accent : Theme.alpha(Theme.foreground, 0.65)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Wallpapers"
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                color: parent.parent.isCurrent ? Theme.accent : Theme.alpha(Theme.foreground, 0.75)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: segWallMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.activeMode !== "wallpaper") {
                                    root.activeMode = "wallpaper"
                                    root.refreshWallpapers()
                                }
                            }
                        }
                    }

                    // Segment: Live Wallpapers (mpvpaper videos)
                    Rectangle {
                        property bool isCurrent: root.activeMode === "live"
                        height: 28
                        width: segLiveContent.implicitWidth + 14
                        radius: 8
                        color: isCurrent ? Theme.alpha(Theme.accent, 0.26) : (segLiveMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.08) : "transparent")
                        border.color: isCurrent ? Theme.accent : "transparent"
                        border.width: 1

                        Row {
                            id: segLiveContent
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: "󰕧"
                                font.pixelSize: 11
                                color: parent.parent.isCurrent ? Theme.accent : Theme.alpha(Theme.foreground, 0.65)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Live"
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                color: parent.parent.isCurrent ? Theme.accent : Theme.alpha(Theme.foreground, 0.75)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: segLiveMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.activeMode !== "live") {
                                    root.activeMode = "live"
                                    root.refreshWallpapers()
                                }
                            }
                        }
                    }

                    // Segment: Wallhaven (Online)
                    Rectangle {
                        property bool isCurrent: root.activeMode === "wallhaven"
                        height: 28
                        width: segHavenContent.implicitWidth + 14
                        radius: 8
                        color: isCurrent ? Theme.alpha(Theme.accent, 0.26) : (segHavenMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.08) : "transparent")
                        border.color: isCurrent ? Theme.accent : "transparent"
                        border.width: 1

                        Row {
                            id: segHavenContent
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: "★"
                                font.pixelSize: 11
                                color: parent.parent.isCurrent ? Theme.accent : Theme.alpha(Theme.foreground, 0.65)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Wallhaven"
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                color: parent.parent.isCurrent ? Theme.accent : Theme.alpha(Theme.foreground, 0.75)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: segHavenMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.activeMode !== "wallhaven") {
                                    root.activeMode = "wallhaven"
                                    root.fetchOnlineWallpapers(1)
                                }
                            }
                        }
                    }
                }
            }

            // Choose Directory Button (active in wallpaper & live modes)
            Rectangle {
                id: dirBtn
                anchors.left: modeSegmentBar.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: visible ? (dirContent.implicitWidth + 20) : 0
                height: 36
                radius: 10
                color: dirMouse.containsMouse ? Theme.alpha(Theme.surface, 0.95) : Theme.alpha(Theme.surface, 0.70)
                border.color: root.isBrowsingDirs ? Theme.accent : (dirMouse.containsMouse ? Theme.alpha(Theme.accent, 0.5) : Theme.alpha(Theme.foreground, 0.14))
                border.width: 1
                visible: root.activeMode === "wallpaper" || root.activeMode === "live"
                clip: true

                Row {
                    id: dirContent
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        text: root.activeMode === "live" ? "󰕧" : "󰉋"
                        font.pixelSize: 13
                        color: Theme.accent
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: {
                            var p = (root.activeMode === "live") ? root.currentLiveDir : root.currentWallpaperDir
                            if (!p) return "Folder"
                            var clean = p.replace(/\/+$/, "")
                            var slash = clean.lastIndexOf("/")
                            var base = (slash >= 0) ? clean.substring(slash + 1) : clean
                            return base || "Folder"
                        }
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Theme.foreground
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: dirMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.openDirBrowser()
                    }
                }
            }

            // Pick Video File Direct Button (active in live mode)
            Rectangle {
                id: pickVideoBtn
                anchors.left: dirBtn.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: visible ? (pickVideoContent.implicitWidth + 18) : 0
                height: 36
                radius: 10
                color: pickVideoMouse.containsMouse ? Theme.alpha(Theme.surface, 0.95) : Theme.alpha(Theme.surface, 0.70)
                border.color: pickVideoMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.accent, 0.40)
                border.width: 1
                visible: root.activeMode === "live"

                Row {
                    id: pickVideoContent
                    anchors.centerIn: parent
                    spacing: 5
                    Text {
                        text: "󰕧"
                        font.pixelSize: 12
                        color: Theme.accent
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Pick File..."
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Theme.foreground
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: pickVideoMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        videoChooserProc.running = false
                        videoChooserProc.running = true
                    }
                }
            }

            // Search Input Bar
            Rectangle {
                id: searchBarContainer
                anchors.left: (pickVideoBtn.visible ? pickVideoBtn.right : (dirBtn.visible ? dirBtn.right : modeSegmentBar.right))
                anchors.leftMargin: 8
                anchors.right: variantSelector.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                height: 36
                radius: 10
                color: Theme.alpha(Theme.surface, 0.70)
                border.color: searchEntry.activeFocus ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                border.width: 1

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.right: clearBtn.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        text: root.isSearchingOnline ? "󰑮" : "🔍"
                        font.pixelSize: 11
                        color: root.isSearchingOnline ? Theme.accent : Theme.alpha(Theme.foreground, 0.50)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    TextInput {
                        id: searchEntry
                        width: parent.width - 24
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: "Outfit"
                        font.pixelSize: 12
                        color: Theme.foreground
                        clip: true
                        selectByMouse: true

                        Text {
                            anchors.fill: parent
                            text: root.activeMode === "wallhaven" ? ">search wallhaven" : (root.activeMode === "live" ? ">search live" : ">search wallpapers")
                            font.family: "Outfit"
                            font.pixelSize: 12
                            color: Theme.alpha(Theme.foreground, 0.35)
                            visible: parent.text.length === 0
                        }

                        onTextChanged: {
                            root.searchQuery = text
                            if (root.activeMode === "wallhaven") {
                                searchDebounce.restart()
                            } else {
                                root.applyFilter()
                            }
                        }

                        Keys.onPressed: function(event) {
                            if (root.handleKey(event)) {
                                event.accepted = true
                            }
                        }
                    }
                }

                // Debounce timer for online search
                Timer {
                    id: searchDebounce
                    interval: 500
                    repeat: false
                    onTriggered: {
                        if (root.activeMode === "wallhaven") {
                            root.fetchOnlineWallpapers(1)
                        }
                    }
                }

                // Clear Button (✕)
                Rectangle {
                    id: clearBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    height: 20
                    radius: 10
                    color: clearMouse.containsMouse ? Theme.alpha(Theme.surface, 0.95) : "transparent"
                    visible: searchEntry.text.length > 0

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 10
                        color: Theme.alpha(Theme.foreground, 0.6)
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchEntry.text = ""
                            if (root.activeMode === "wallhaven") {
                                root.fetchOnlineWallpapers(1)
                            } else {
                                searchEntry.forceActiveFocus()
                            }
                        }
                    }
                }
            }

            // Color Format Variant Selector (Noctalia Shell style Dropdown List)
            Item {
                id: variantSelector
                anchors.right: hubBtn.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                height: 36
                width: variantButton.width
                z: variantDropdown.visible ? 1000 : 1

                property bool isDropdownOpen: false

                Rectangle {
                    id: variantButton
                    anchors.verticalCenter: parent.verticalCenter
                    height: 36
                    width: variantContentRow.implicitWidth + 20
                    radius: 10
                    color: (variantSelector.isDropdownOpen || variantMouse.containsMouse) ? Theme.alpha(Theme.surface, 0.95) : Theme.alpha(Theme.surface, 0.70)
                    border.color: variantSelector.isDropdownOpen ? Theme.accent : (root.isVariantUpdating ? Theme.accent : (variantMouse.containsMouse ? Theme.alpha(Theme.accent, 0.6) : Theme.alpha(Theme.foreground, 0.14)))
                    border.width: 1

                    Row {
                        id: variantContentRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: root.isVariantUpdating ? "󰑮" : "󰏘"
                            font.pixelSize: 12
                            color: Theme.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: {
                                var v = root.colorVariant || "vibrant"
                                return v.charAt(0).toUpperCase() + v.slice(1)
                            }
                            font.family: "Outfit"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: Theme.foreground
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: variantSelector.isDropdownOpen ? "▴" : "▾"
                            font.pixelSize: 9
                            color: Theme.alpha(Theme.foreground, 0.50)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: variantMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            variantSelector.isDropdownOpen = !variantSelector.isDropdownOpen
                        }
                    }
                }

                // Dropdown menu (expands upward seamlessly from the bottom control bar)
                Rectangle {
                    id: variantDropdown
                    visible: variantSelector.isDropdownOpen
                    anchors.bottom: variantButton.top
                    anchors.bottomMargin: 8
                    anchors.left: variantButton.left
                    width: Math.max(160, variantButton.width)
                    height: dropdownColumn.implicitHeight + 12
                    radius: 12
                    color: Theme.alpha(Theme.surface, 0.96)
                    border.color: Theme.alpha(Theme.accent, 0.40)
                    border.width: 1.5
                    clip: true

                    Column {
                        id: dropdownColumn
                        anchors.top: parent.top
                        anchors.topMargin: 6
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        spacing: 2

                        Repeater {
                            model: [
                                { id: "vibrant", name: "Vibrant", desc: "Punchy, saturated", icon: "󰏘" },
                                { id: "muted", name: "Muted", desc: "Soft & calm", icon: "󰏘" },
                                { id: "expressive", name: "Expressive", desc: "Contrasting pop", icon: "󰏘" },
                                { id: "warm", name: "Warm", desc: "Amber & gold", icon: "󰏘" },
                                { id: "cool", name: "Cool", desc: "Cyan & cobalt", icon: "󰏘" },
                                { id: "pastel", name: "Pastel", desc: "Airy & bright", icon: "󰏘" },
                                { id: "original", name: "Original", desc: "Natural sampled", icon: "󰏘" }
                            ]

                            Rectangle {
                                width: parent.width
                                height: 32
                                radius: 8
                                readonly property bool isSelected: root.colorVariant === modelData.id
                                color: isSelected
                                    ? Theme.alpha(Theme.accent, 0.28)
                                    : (itemMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.08) : "transparent")
                                border.color: isSelected ? Theme.accent : "transparent"
                                border.width: 1

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    anchors.right: checkIcon.left
                                    anchors.rightMargin: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 8

                                    Text {
                                        text: modelData.icon
                                        font.pixelSize: 11
                                        color: parent.parent.isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.60)
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: modelData.name
                                        font.family: "Outfit"
                                        font.pixelSize: 11
                                        font.weight: parent.parent.isSelected ? Font.Bold : Font.Medium
                                        color: parent.parent.isSelected ? Theme.accent : Theme.foreground
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "• " + modelData.desc
                                        font.family: "Outfit"
                                        font.pixelSize: 9
                                        color: Theme.alpha(Theme.foreground, 0.38)
                                        anchors.verticalCenter: parent.verticalCenter
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    id: checkIcon
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "✓"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Theme.accent
                                    visible: parent.isSelected
                                }

                                MouseArea {
                                    id: itemMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        variantSelector.isDropdownOpen = false
                                        root.setColorVariant(modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Hub Button (📖 Hub)
            Rectangle {
                id: hubBtn
                anchors.right: applyBtn.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: hubContent.implicitWidth + 20
                height: 36
                radius: 10
                color: hubMouse.containsMouse ? Theme.alpha(Theme.surface, 0.95) : Theme.alpha(Theme.surface, 0.70)
                border.color: Theme.alpha(Theme.accent, 0.35)
                border.width: 1

                Row {
                    id: hubContent
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        text: "📖"
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Hub"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Theme.foreground
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: hubMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["xdg-open", root.activeMode === "live" ? root.currentLiveDir : (root.activeMode === "wallhaven" ? Quickshell.env("HOME") + "/.hyprconf/hypr/Wallpaper/wallhaven" : root.currentWallpaperDir)])
                    }
                }
            }

            // Apply Button (✓ Apply / ▶ Set Live)
            Rectangle {
                id: applyBtn
                property bool isApplying: false
                property bool isCurrentVideo: root.filteredWallpapers.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.filteredWallpapers.length && (root.filteredWallpapers[root.selectedIndex].is_video || root.activeType === "live")
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: applyContent.implicitWidth + 24
                height: 36
                radius: 10
                color: isApplying ? Theme.alpha(Theme.accent, 0.70) : (applyMouse.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent)

                Row {
                    id: applyContent
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        text: applyBtn.isApplying ? "󰑮" : (applyBtn.isCurrentVideo ? "▶" : "✓")
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.on_primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: applyBtn.isApplying ? "Applying..." : (applyBtn.isCurrentVideo ? "Set Live (mpvpaper)" : "Apply")
                        font.family: "Outfit"
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.on_primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: applyMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.confirmSelection()
                }
            }
        }
    }

    // ── DIRECTORY BROWSER PAGE (IN-APP NAVIGATION) ───────────────────────────
    Item {
        id: dirBrowserContent
        anchors.fill: parent
        anchors.topMargin: 44 * root.animProgress
        anchors.bottomMargin: 14
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        opacity: (!root.isClosing && root.animProgress >= 0.88 && root.isBrowsingDirs) ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: root.isClosing ? 90 : 160
                easing.type: Easing.OutCubic
            }
        }
        visible: opacity > 0.001

        // Keyboard Sink for Directory Browser
        Item {
            id: dirKeySink
            anchors.fill: parent
            focus: root.isBrowsingDirs
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: function(event) {
                if (root.handleKey(event)) {
                    event.accepted = true
                }
            }
        }

        // 1. TOP HEADER BAR
        Item {
            id: dirHeaderBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 36

            // Back to Wallpapers Button (← Wallpapers)
            Rectangle {
                id: dirBackBtn
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: dirBackContent.implicitWidth + 20
                height: 36
                radius: 10
                color: dirBackMouse.containsMouse ? Theme.alpha(Theme.surface, 0.95) : Theme.alpha(Theme.surface, 0.70)
                border.color: dirBackMouse.containsMouse ? Theme.alpha(Theme.accent, 0.5) : Theme.alpha(Theme.foreground, 0.14)
                border.width: 1

                Row {
                    id: dirBackContent
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        text: "←"
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.accent
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Wallpapers"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Theme.foreground
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: dirBackMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeDirBrowser()
                }
            }

            // Up / Parent Directory Button (↑ Up)
            Rectangle {
                id: dirUpBtn
                anchors.left: dirBackBtn.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: visible ? (dirUpContent.implicitWidth + 18) : 0
                height: 36
                radius: 10
                visible: root.browsingParentPath && root.browsingParentPath.length > 0 && root.browsingParentPath !== root.browsingPath
                color: dirUpMouse.containsMouse ? Theme.alpha(Theme.surface, 0.95) : Theme.alpha(Theme.surface, 0.70)
                border.color: dirUpMouse.containsMouse ? Theme.alpha(Theme.accent, 0.5) : Theme.alpha(Theme.foreground, 0.14)
                border.width: 1

                Row {
                    id: dirUpContent
                    anchors.centerIn: parent
                    spacing: 5
                    Text {
                        text: "↑"
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.accent
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Up"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Theme.foreground
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: dirUpMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.browsingParentPath) {
                            root.fetchDirectory(root.browsingParentPath)
                        }
                    }
                }
            }

            // Breadcrumb / Current Path Display Pill
            Rectangle {
                id: dirPathPill
                anchors.left: dirUpBtn.visible ? dirUpBtn.right : dirBackBtn.right
                anchors.leftMargin: 8
                anchors.right: dirPickVideoBtn.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                height: 36
                radius: 10
                color: Theme.alpha(Theme.surface, 0.55)
                border.color: Theme.alpha(Theme.accent, 0.30)
                border.width: 1
                clip: true

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.right: (dirVideoCountBadge.visible ? dirVideoCountBadge.left : dirCountBadge.left)
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        text: "󰉋"
                        font.pixelSize: 13
                        color: Theme.accent
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        width: parent.width - 24
                        text: {
                            var home = Quickshell.env("HOME") || ""
                            var p = root.browsingPath || ""
                            if (home.length > 0 && p.indexOf(home) === 0) {
                                return "~" + p.substring(home.length)
                            }
                            return p || "/"
                        }
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Theme.foreground
                        elide: Text.ElideMiddle
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Video Count Badge
                Rectangle {
                    id: dirVideoCountBadge
                    anchors.right: dirCountBadge.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    height: 22
                    width: dirVideoCountText.implicitWidth + 14
                    radius: 6
                    color: Theme.alpha(Theme.accent, 0.22)
                    border.color: Theme.accent
                    border.width: 1
                    visible: root.browsingCurrentVideoCount > 0

                    Row {
                        id: dirVideoCountText
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "▶"
                            font.pixelSize: 8
                            color: Theme.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: root.browsingCurrentVideoCount + (root.browsingCurrentVideoCount === 1 ? " video" : " videos")
                            font.family: "Outfit"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Theme.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Wallpaper Count Badge
                Rectangle {
                    id: dirCountBadge
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    height: 22
                    width: dirCountText.implicitWidth + 14
                    radius: 6
                    color: Theme.alpha(Theme.accent, 0.16)
                    border.color: Theme.alpha(Theme.accent, 0.35)
                    border.width: 1

                    Row {
                        id: dirCountText
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "󰸉"
                            font.pixelSize: 10
                            color: Theme.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: root.browsingCurrentWallCount + (root.browsingCurrentWallCount === 1 ? " wall" : " walls")
                            font.family: "Outfit"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Theme.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // Pick Video File Button (󰕧 Pick Video...)
            Rectangle {
                id: dirPickVideoBtn
                anchors.right: dirSelectCurrentBtn.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: dirPickVideoContent.implicitWidth + 20
                height: 36
                radius: 10
                color: dirPickVideoMouse.containsMouse ? Theme.alpha(Theme.surface, 0.95) : Theme.alpha(Theme.surface, 0.70)
                border.color: dirPickVideoMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.accent, 0.40)
                border.width: 1

                Row {
                    id: dirPickVideoContent
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        text: "󰕧"
                        font.pixelSize: 13
                        color: Theme.accent
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Pick Video..."
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Theme.foreground
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: dirPickVideoMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        videoChooserProc.running = false
                        videoChooserProc.running = true
                    }
                }
            }

            // Select Current Folder Action Button (✓ Use This Folder)
            Rectangle {
                id: dirSelectCurrentBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: dirSelectContent.implicitWidth + 24
                height: 36
                radius: 10
                color: dirSelectMouse.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent

                Row {
                    id: dirSelectContent
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        text: "✓"
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.on_primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: root.activeMode === "live" ? "Use for Live Wallpapers" : "Use for Wallpapers"
                        font.family: "Outfit"
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.on_primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: dirSelectMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selectCurrentDirectory(root.browsingPath)
                }
            }
        }

        // 2. QUICK BOOKMARKS BAR
        Item {
            id: dirBookmarksBar
            anchors.top: dirHeaderBar.bottom
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.right: parent.right
            height: 28

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    text: "QUICK JUMP:"
                    font.family: "Outfit"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: Theme.alpha(Theme.foreground, 0.40)
                    anchors.verticalCenter: parent.verticalCenter
                }

                Repeater {
                    model: root.browsingBookmarks
                    Rectangle {
                        property bool isCurrent: root.browsingPath === modelData.path
                        width: bmContent.implicitWidth + 18
                        height: 26
                        radius: 7
                        color: isCurrent ? Theme.alpha(Theme.accent, 0.22) : (bmMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.50))
                        border.color: isCurrent ? Theme.accent : (bmMouse.containsMouse ? Theme.alpha(Theme.accent, 0.40) : Theme.alpha(Theme.foreground, 0.10))
                        border.width: 1

                        Row {
                            id: bmContent
                            anchors.centerIn: parent
                            spacing: 5
                            Text {
                                text: modelData.icon || "󰉋"
                                font.pixelSize: 11
                                color: parent.parent.isCurrent ? Theme.accent : Theme.alpha(Theme.foreground, 0.70)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: modelData.name
                                font.family: "Outfit"
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: parent.parent.isCurrent ? Theme.accent : Theme.alpha(Theme.foreground, 0.85)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: bmMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.fetchDirectory(modelData.path)
                        }
                    }
                }
            }
        }

        // 2.5 TAB SELECTOR (Folders vs Video Wallpapers)
        Item {
            id: dirTabSelector
            anchors.top: dirBookmarksBar.bottom
            anchors.topMargin: 6
            anchors.left: parent.left
            anchors.right: parent.right
            height: 28

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Rectangle {
                    property bool isSelected: root.dirBrowserTab === "folders"
                    width: tabFoldersContent.implicitWidth + 18
                    height: 26
                    radius: 7
                    color: isSelected ? Theme.alpha(Theme.accent, 0.24) : Theme.alpha(Theme.surface, 0.50)
                    border.color: isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                    border.width: 1

                    Row {
                        id: tabFoldersContent
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            text: "󰉋"
                            font.pixelSize: 12
                            color: parent.parent.isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.6)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Folders (" + (root.browsingSubdirs ? root.browsingSubdirs.length : 0) + ")"
                            font.family: "Outfit"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: parent.parent.isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.85)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dirBrowserTab = "folders"
                    }
                }

                Rectangle {
                    property bool isSelected: root.dirBrowserTab === "videos"
                    width: tabVideosContent.implicitWidth + 18
                    height: 26
                    radius: 7
                    color: isSelected ? Theme.alpha(Theme.accent, 0.24) : Theme.alpha(Theme.surface, 0.50)
                    border.color: isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
                    border.width: 1

                    Row {
                        id: tabVideosContent
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            text: "󰕧"
                            font.pixelSize: 12
                            color: parent.parent.isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.6)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Video Wallpapers (" + (root.browsingVideos ? root.browsingVideos.length : 0) + ")"
                            font.family: "Outfit"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: parent.parent.isSelected ? Theme.accent : Theme.alpha(Theme.foreground, 0.85)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dirBrowserTab = "videos"
                    }
                }
            }
        }

        // 3. CONTENT AREA (SUBDIRECTORIES OR VIDEO WALLPAPERS)
        Item {
            id: dirContentArea
            anchors.top: dirTabSelector.bottom
            anchors.topMargin: 8
            anchors.bottom: dirFooterBar.top
            anchors.bottomMargin: 6
            anchors.left: parent.left
            anchors.right: parent.right

            // Populated Subdirectories Grid
            Flickable {
                id: dirFlick
                anchors.fill: parent
                contentWidth: width
                contentHeight: dirGrid.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                visible: root.dirBrowserTab === "folders" && root.browsingSubdirs && root.browsingSubdirs.length > 0

                Grid {
                    id: dirGrid
                    columns: 3
                    spacing: 8
                    width: parent.width

                    Repeater {
                        model: root.browsingSubdirs
                        Rectangle {
                            id: folderCard
                            property bool isHighlighted: root.dirSelectedIndex === index
                            width: Math.floor((dirGrid.width - 16) / 3)
                            height: 52
                            radius: 10
                            color: isHighlighted ? Theme.alpha(Theme.accent, 0.22) : (cardMouse.containsMouse ? Theme.alpha(Theme.surface, 0.90) : Theme.alpha(Theme.surface, 0.50))
                            border.color: isHighlighted ? Theme.accent : (cardMouse.containsMouse ? Theme.alpha(Theme.accent, 0.45) : Theme.alpha(Theme.foreground, 0.12))
                            border.width: isHighlighted ? 1.8 : 1.0

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Text {
                                    text: (modelData.video_count > 0) ? "󰕧" : ((modelData.wall_count > 0) ? "󰉍" : "󰉋")
                                    font.pixelSize: 20
                                    color: folderCard.isHighlighted ? Theme.accent : (cardMouse.containsMouse ? Qt.lighter(Theme.accent, 1.2) : Theme.accent)
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Column {
                                    width: parent.width - 60
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        width: parent.width
                                        text: modelData.name
                                        font.family: "Outfit"
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                        color: Theme.foreground
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: {
                                            if (modelData.video_count > 0 && modelData.wall_count > 0) {
                                                return modelData.wall_count + " walls • " + modelData.video_count + " videos"
                                            } else if (modelData.video_count > 0) {
                                                return modelData.video_count + (modelData.video_count === 1 ? " video wallpaper" : " video wallpapers")
                                            } else if (modelData.wall_count > 0) {
                                                return modelData.wall_count + (modelData.wall_count === 1 ? " wallpaper" : " wallpapers")
                                            }
                                            return modelData.has_sub ? "Contains folders" : "Empty folder"
                                        }
                                        font.family: "Outfit"
                                        font.pixelSize: 10
                                        color: (modelData.video_count > 0 || modelData.wall_count > 0) ? Theme.accent : Theme.alpha(Theme.foreground, 0.45)
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    text: "→"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: folderCard.isHighlighted ? Theme.accent : (cardMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.25))
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.dirSelectedIndex = index
                                    root.fetchDirectory(modelData.path)
                                }
                            }
                        }
                    }
                }
            }

            // Populated Video Wallpapers Grid (Videos Tab)
            Flickable {
                id: videoFlick
                anchors.fill: parent
                contentWidth: width
                contentHeight: videoGrid.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                visible: root.dirBrowserTab === "videos" && root.browsingVideos && root.browsingVideos.length > 0

                Grid {
                    id: videoGrid
                    columns: 3
                    spacing: 8
                    width: parent.width

                    Repeater {
                        model: root.browsingVideos
                        Rectangle {
                            id: videoCard
                            property bool isHighlighted: root.videoSelectedIndex === index
                            width: Math.floor((videoGrid.width - 16) / 3)
                            height: 108
                            radius: 12
                            color: Theme.surface
                            border.color: isHighlighted ? Theme.accent : (videoCardMouse.containsMouse ? Theme.alpha(Theme.accent, 0.5) : Theme.alpha(Theme.foreground, 0.15))
                            border.width: isHighlighted ? 2.0 : 1.0
                            clip: true

                            // Masked Thumbnail
                            Item {
                                anchors.fill: parent
                                anchors.margins: 2

                                Image {
                                    id: videoThumbImg
                                    anchors.fill: parent
                                    source: modelData.thumb || modelData.source || ""
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                    asynchronous: true
                                    visible: false
                                }

                                Item {
                                    id: videoThumbMask
                                    anchors.fill: parent
                                    layer.enabled: true
                                    visible: false
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 10
                                        color: "#ffffff"
                                    }
                                }

                                MultiEffect {
                                    anchors.fill: parent
                                    source: videoThumbImg
                                    visible: videoThumbImg.status === Image.Ready
                                    maskEnabled: true
                                    maskSource: videoThumbMask
                                    autoPaddingEnabled: false
                                }

                                // Dark gradient scrim for legibility
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 10
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "transparent" }
                                        GradientStop { position: 0.4; color: "transparent" }
                                        GradientStop { position: 1.0; color: Theme.alpha(Theme.background, 0.90) }
                                    }
                                }
                            }

                            // Top-right Tag (▶ MP4, ▶ GIF, etc.)
                            Rectangle {
                                anchors.top: parent.top
                                anchors.topMargin: 6
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                height: 18
                                width: videoBadgeTxt.implicitWidth + 10
                                radius: 5
                                color: Theme.alpha(Theme.background, 0.88)
                                border.color: Theme.accent
                                border.width: 1

                                Row {
                                    id: videoBadgeTxt
                                    anchors.centerIn: parent
                                    spacing: 3
                                    Text {
                                        text: "▶"
                                        font.pixelSize: 8
                                        color: Theme.accent
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: modelData.ext || "LIVE"
                                        font.family: "Outfit"
                                        font.pixelSize: 8
                                        font.weight: Font.Bold
                                        color: Theme.foreground
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            // Bottom Title & Size Banner
                            Column {
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 6
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                spacing: 1

                                Text {
                                    width: parent.width
                                    text: modelData.title || modelData.name
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    color: Theme.foreground
                                    elide: Text.ElideRight
                                }

                                Row {
                                    spacing: 6
                                    Text {
                                        text: modelData.size_mb ? (modelData.size_mb + " MB") : ""
                                        font.family: "Outfit"
                                        font.pixelSize: 9
                                        color: Theme.alpha(Theme.foreground, 0.6)
                                    }
                                    Text {
                                        text: "•"
                                        font.pixelSize: 9
                                        color: Theme.alpha(Theme.foreground, 0.3)
                                    }
                                    Text {
                                        text: "mpvpaper"
                                        font.family: "Outfit"
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                        color: Theme.accent
                                    }
                                }
                            }

                            // Hover Action Bar
                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                color: Theme.alpha(Theme.background, 0.75)
                                visible: videoCardMouse.containsMouse
                                z: 50

                                Rectangle {
                                    anchors.centerIn: parent
                                    height: 28
                                    width: playBtnContent.implicitWidth + 16
                                    radius: 8
                                    color: Theme.accent

                                    Row {
                                        id: playBtnContent
                                        anchors.centerIn: parent
                                        spacing: 5
                                        Text {
                                            text: "▶"
                                            font.pixelSize: 10
                                            color: Theme.on_primary
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: "Set Live (mpvpaper)"
                                            font.family: "Outfit"
                                            font.pixelSize: 10
                                            font.weight: Font.Bold
                                            color: Theme.on_primary
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: videoCardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.videoSelectedIndex = index
                                    root.applyVideoWallpaper(modelData.path)
                                }
                            }
                        }
                    }
                }
            }

            // Empty State Box (when folder has 0 subdirectories in Folders Tab)
            Rectangle {
                anchors.centerIn: parent
                width: 440
                height: 140
                radius: 14
                color: Theme.alpha(Theme.surface, 0.60)
                border.color: Theme.alpha(Theme.foreground, 0.12)
                border.width: 1
                visible: root.dirBrowserTab === "folders" && !root.isDirLoading && (!root.browsingSubdirs || root.browsingSubdirs.length === 0)

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "󰉋"
                        font.pixelSize: 32
                        color: Theme.alpha(Theme.accent, 0.80)
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No subdirectories in this location"
                        font.family: "Outfit"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: Theme.foreground
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: {
                            if (root.browsingCurrentVideoCount > 0 && root.browsingCurrentWallCount > 0) {
                                return "Found " + root.browsingCurrentWallCount + " wallpapers and " + root.browsingCurrentVideoCount + " videos here."
                            } else if (root.browsingCurrentVideoCount > 0) {
                                return "Found " + root.browsingCurrentVideoCount + " video wallpapers here. Check the Videos tab!"
                            } else if (root.browsingCurrentWallCount > 0) {
                                return "Found " + root.browsingCurrentWallCount + " wallpapers here. Ready to use!"
                            }
                            return "Navigate up or select a quick bookmark above."
                        }
                        font.family: "Outfit"
                        font.pixelSize: 10
                        color: Theme.alpha(Theme.foreground, 0.60)
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        Rectangle {
                            width: emptyBtnText.implicitWidth + 24
                            height: 28
                            radius: 8
                            color: emptyMouse.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
                            visible: root.browsingCurrentWallCount > 0

                            Text {
                                id: emptyBtnText
                                anchors.centerIn: parent
                                text: root.activeMode === "live" ? "✓ Use for Live Wallpapers" : "✓ Use for Wallpapers"
                                font.family: "Outfit"
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.on_primary
                            }

                            MouseArea {
                                id: emptyMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectCurrentDirectory(root.browsingPath)
                            }
                        }

                        Rectangle {
                            width: emptyTabBtnText.implicitWidth + 24
                            height: 28
                            radius: 8
                            color: Theme.alpha(Theme.accent, 0.25)
                            border.color: Theme.accent
                            border.width: 1
                            visible: root.browsingCurrentVideoCount > 0

                            Text {
                                id: emptyTabBtnText
                                anchors.centerIn: parent
                                text: "▶ View " + root.browsingCurrentVideoCount + " Videos"
                                font.family: "Outfit"
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.accent
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.dirBrowserTab = "videos"
                            }
                        }
                    }
                }
            }

            // Empty State Box (when folder has 0 videos in Videos Tab)
            Rectangle {
                anchors.centerIn: parent
                width: 440
                height: 140
                radius: 14
                color: Theme.alpha(Theme.surface, 0.60)
                border.color: Theme.alpha(Theme.foreground, 0.12)
                border.width: 1
                visible: root.dirBrowserTab === "videos" && !root.isDirLoading && (!root.browsingVideos || root.browsingVideos.length === 0)

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "󰕧"
                        font.pixelSize: 32
                        color: Theme.alpha(Theme.accent, 0.80)
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No video wallpapers in this location"
                        font.family: "Outfit"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: Theme.foreground
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Navigate to ~/Videos or ~/Downloads, or pick any video file directly."
                        font.family: "Outfit"
                        font.pixelSize: 10
                        color: Theme.alpha(Theme.foreground, 0.60)
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: emptyVideoBtnText.implicitWidth + 24
                        height: 28
                        radius: 8
                        color: emptyVideoMouse.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent

                        Row {
                            id: emptyVideoBtnText
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "󰕧"
                                font.pixelSize: 11
                                color: Theme.on_primary
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Browse Video File..."
                                font.family: "Outfit"
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.on_primary
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: emptyVideoMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                videoChooserProc.running = false
                                videoChooserProc.running = true
                            }
                        }
                    }
                }
            }
        }

        // 4. FOOTER HINTS & STATUS BAR
        Item {
            id: dirFooterBar
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 24

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Text {
                    text: "[hjkl / Arrows] Navigate  •  [Tab / t] Folders/Videos  •  [Enter / Space] Select  •  [Backspace / u] Up  •  [Esc] Cancel"
                    font.family: "Outfit"
                    font.pixelSize: 10
                    color: Theme.alpha(Theme.foreground, 0.40)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Text {
                    text: {
                        if (root.isDirLoading) return "󰑮 Loading..."
                        if (root.dirBrowserTab === "videos") {
                            return (root.browsingVideos ? root.browsingVideos.length : 0) + " videos"
                        }
                        return (root.browsingSubdirs ? root.browsingSubdirs.length : 0) + " subfolders"
                    }
                    font.family: "Outfit"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: root.isDirLoading ? Theme.accent : Theme.alpha(Theme.foreground, 0.50)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
