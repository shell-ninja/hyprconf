import QtQuick
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root

    property bool active: false
    // 0: HomePage, 1: PowerView, 2: WallpaperView, 3: LauncherView, 4: ThemeSwitcherView, 5: ScreenshotView, 6: PolkitView, 7: ClipboardView
    property int currentView: 0
    signal closeRequested()
    signal launchLauncherRequested()
    signal startTimerScreenshot(int seconds, string targetMode, bool useSatty, bool playSound)

    property var notificationList: []
    signal clearAllNotifications()
    signal dismissNotification(var notifId)

    property var polkitFlow: null

    implicitWidth: {
        if (currentView === 2) return 920
        if (currentView === 3) return launcherView ? launcherView.preferredWidth : 880
        if (currentView === 4) return 860
        if (currentView === 5) return 620
        if (currentView === 6) return 520
        if (currentView === 7) return clipboardView ? clipboardView.preferredWidth : 780
        if (currentView === 8) return emojiView ? emojiView.preferredWidth : 620
        if (currentView === 9) return keybindsView ? keybindsView.preferredWidth : 780
        return 444
    }
    implicitHeight: {
        if (currentView === 2) return 370
        if (currentView === 3) return launcherView ? launcherView.preferredHeight : 420
        if (currentView === 4) return 500
        if (currentView === 5) return 380
        if (currentView === 6) return 370
        if (currentView === 7) return clipboardView ? clipboardView.preferredHeight : 520
        if (currentView === 8) return emojiView ? emojiView.preferredHeight : 460
        if (currentView === 9) return keybindsView ? keybindsView.preferredHeight : 520
        return 496
    }

    // For currentView === 0 (Main Dashboard):
    // 0: HomePage (Page 1), 1: StatusPage (Page 2), 2: NetworkDetailPage (Page 3)
    property int dashboardPage: 0

    function handleKey(event) {
        if (root.currentView === 1) {
            if (powerView && typeof powerView.handleKey === "function") {
                if (powerView.handleKey(event)) {
                    event.accepted = true
                    return true
                }
            }
        } else if (root.currentView === 5) {
            if (screenshotView && typeof screenshotView.handleKey === "function") {
                if (screenshotView.handleKey(event)) {
                    event.accepted = true
                    return true
                }
            }
        } else if (root.currentView === 2) {
            if (wallpaperView && typeof wallpaperView.handleKey === "function") {
                if (wallpaperView.handleKey(event)) {
                    event.accepted = true
                    return true
                }
            }
        } else if (root.currentView === 0) {
            if (event.key === Qt.Key_Right) {
                if (root.dashboardPage === 0) {
                    event.accepted = true
                    root.dashboardPage = 1
                    return true
                } else if (root.dashboardPage === 1) {
                    event.accepted = true
                    root.dashboardPage = 2
                    return true
                }
            } else if (event.key === Qt.Key_Left) {
                if (root.dashboardPage === 2) {
                    event.accepted = true
                    root.dashboardPage = 1
                    return true
                } else if (root.dashboardPage === 1) {
                    event.accepted = true
                    root.dashboardPage = 0
                    return true
                }
            }
        } else if (root.currentView === 3) {
            if (launcherView && typeof launcherView.handleKey === "function") {
                if (launcherView.handleKey(event)) {
                    event.accepted = true
                    return true
                }
            }
        } else if (root.currentView === 4) {
            if (themeSwitcherView && typeof themeSwitcherView.handleKey === "function") {
                if (themeSwitcherView.handleKey(event)) {
                    event.accepted = true
                    return true
                }
            }
        } else if (root.currentView === 6) {
            if (polkitView && typeof polkitView.handleKey === "function") {
                if (polkitView.handleKey(event)) {
                    event.accepted = true
                    return true
                }
            }
        } else if (root.currentView === 7) {
            if (clipboardView && typeof clipboardView.handleKey === "function") {
                if (clipboardView.handleKey(event)) {
                    event.accepted = true
                    return true
                }
            }
        } else if (root.currentView === 8) {
            if (emojiView && typeof emojiView.handleKey === "function") {
                if (emojiView.handleKey(event)) {
                    event.accepted = true
                    return true
                }
            }
        } else if (root.currentView === 9) {
            if (keybindsView && typeof keybindsView.handleKey === "function") {
                if (keybindsView.handleKey(event)) {
                    event.accepted = true
                    return true
                }
            }
        }

        if (event.key === Qt.Key_Escape) {
            event.accepted = true
            root.closeRequested()
            return true
        }
        return false
    }

    onCurrentViewChanged: {
        if (currentView !== 1 && powerView && typeof powerView.cancelCountdown === "function") {
            powerView.cancelCountdown()
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.active && !root.isClosingWallpaper && !(root.currentView === 2 && wallpaperView && wallpaperView.isBrowsingDirs)
        onActivated: root.closeRequested()
    }

    property alias homePage: homePage
    property alias statusPage: statusPage
    property alias networkDetailPage: networkDetailPage
    property alias wallpaperView: wallpaperView
    property alias launcherView: launcherView
    property alias themeSwitcherView: themeSwitcherView
    property alias screenshotView: screenshotView
    property alias polkitView: polkitView
    property alias clipboardView: clipboardView
    property alias emojiView: emojiView

    property bool isClosingWallpaper: false
    property real animProgress: 1.0
    property real wallpaperTimestamp: Date.now()

    // Visualizer configuration passed from shell
    property bool isAudioPlaying: false
    property var cavaBars: []
    property bool visualizerEnabled: true
    property string visualizerStyle: "wave"
    property int visualizerBarCount: 8

    property int systemBrightness: -1
    property int systemVolume: -1

    // ── 1. HOME DASHBOARD PAGE (PAGE 1) ──────────────────────────────────────
    HomePage {
        id: homePage
        wallpaperTimestamp: root.wallpaperTimestamp
        anchors.fill: parent
        active: root.active && root.currentView === 0 && root.dashboardPage === 0
        visible: opacity > 0.001
        opacity: (root.currentView === 0 && root.dashboardPage === 0) ? 1.0 : 0.0
        scale: (root.currentView === 0 && root.dashboardPage === 0) ? 1.0 : 0.95
        x: (root.dashboardPage === 0) ? 0 : -28

        externalBrightness: root.systemBrightness
        externalVolume: root.systemVolume

        isAudioPlaying: root.isAudioPlaying
        cavaBars: root.cavaBars
        visualizerEnabled: root.visualizerEnabled
        visualizerStyle: root.visualizerStyle
        visualizerBarCount: root.visualizerBarCount
        animProgress: root.animProgress

        notificationList: root.notificationList
        onClearAllNotifications: root.clearAllNotifications()
        onDismissNotification: function(notifId) {
            root.dismissNotification(notifId)
        }

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on x {
            NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }

        onPowerClicked: {
            root.currentView = 1
        }
        onNavigateToPage2: {
            root.dashboardPage = 1
        }
        onNavigateToPage3: {
            root.dashboardPage = 2
        }
    }

    // ── 1B. SYSTEM STATUS PAGE (PAGE 2) ──────────────────────────────────────
    StatusPage {
        id: statusPage
        anchors.fill: parent
        active: root.active && root.currentView === 0 && root.dashboardPage === 1
        visible: opacity > 0.001
        opacity: (root.currentView === 0 && root.dashboardPage === 1) ? 1.0 : 0.0
        scale: (root.currentView === 0 && root.dashboardPage === 1) ? 1.0 : 0.95
        x: (root.dashboardPage === 1) ? 0 : ((root.dashboardPage === 0) ? 28 : -28)

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on x {
            NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }

        onBackClicked: {
            root.dashboardPage = 0
        }
        onOpenNetworkDetail: {
            root.dashboardPage = 2
        }
        onPageDotClicked: function(pageIdx) {
            root.dashboardPage = pageIdx
        }
    }

    // ── 1C. PER-PROCESS NETWORK DETAIL PAGE (PAGE 3) ─────────────────────────
    NetworkDetailPage {
        id: networkDetailPage
        anchors.fill: parent
        active: root.active && root.currentView === 0 && root.dashboardPage === 2
        visible: opacity > 0.001
        opacity: (root.currentView === 0 && root.dashboardPage === 2) ? 1.0 : 0.0
        scale: (root.currentView === 0 && root.dashboardPage === 2) ? 1.0 : 0.95
        x: (root.dashboardPage === 2) ? 0 : 28

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on x {
            NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }

        onBackClicked: {
            root.dashboardPage = 1
        }
        onPageDotClicked: function(pageIdx) {
            root.dashboardPage = pageIdx
        }
    }

    // ── 2. POWER CONTROL PAGE ────────────────────────────────────────────────
    PowerView {
        id: powerView
        anchors.fill: parent
        active: root.active && root.currentView === 1
        visible: opacity > 0.001
        opacity: root.currentView === 1 ? 1.0 : 0.0
        scale: root.currentView === 1 ? 1.0 : 0.94

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        onBackClicked: {
            root.currentView = 0
        }
    }

    // ── 3. WALLPAPER SELECTOR PAGE ───────────────────────────────────────────
    WallpaperView {
        id: wallpaperView
        anchors.fill: parent
        active: root.active && root.currentView === 2
        isClosing: root.isClosingWallpaper
        animProgress: root.animProgress
        visible: root.currentView === 2
        opacity: root.currentView === 2 ? 1.0 : 0.0
        scale: root.currentView === 2 ? 1.0 : 0.94

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        onBackClicked: {
            root.closeRequested()
        }
    }

    // ── 4. APP LAUNCHER PAGE (SUPER + D / SUPER + SPACE) ─────────────────────
    LauncherView {
        id: launcherView
        wallpaperTimestamp: root.wallpaperTimestamp
        anchors.fill: parent
        active: root.active && root.currentView === 3
        isClosing: root.isClosingWallpaper
        animProgress: root.animProgress
        visible: root.currentView === 3
        opacity: root.currentView === 3 ? 1.0 : 0.0
        scale: root.currentView === 3 ? 1.0 : 0.94

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        onCloseRequested: {
            root.closeRequested()
        }
        onOpenThemeSwitcherRequested: {
            root.currentView = 4
        }
    }

    // ── 5. LAUNCHER THEME SELECTOR (SUPER + ALT + D) ─────────────────────────
    ThemeSwitcherView {
        id: themeSwitcherView
        wallpaperTimestamp: root.wallpaperTimestamp
        anchors.fill: parent
        active: root.active && root.currentView === 4
        isClosing: root.isClosingWallpaper
        animProgress: root.animProgress
        visible: root.currentView === 4
        opacity: root.currentView === 4 ? 1.0 : 0.0
        scale: root.currentView === 4 ? 1.0 : 0.94

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        onCloseRequested: {
            root.closeRequested()
        }
        onLaunchLauncherRequested: {
            root.launchLauncherRequested()
        }
    }

    // ── 6. SCREENSHOT STUDIO PAGE (PRINT / QS-SCREENSHOT.SH) ──────────────────
    ScreenshotView {
        id: screenshotView
        anchors.fill: parent
        active: root.active && root.currentView === 5
        isClosing: root.isClosingWallpaper
        animProgress: root.animProgress
        visible: root.currentView === 5
        opacity: root.currentView === 5 ? 1.0 : 0.0
        scale: root.currentView === 5 ? 1.0 : 0.94

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        onCloseRequested: {
            root.closeRequested()
        }
        onStartTimerScreenshot: function(seconds, targetMode, useSatty, playSound) {
            root.startTimerScreenshot(seconds, targetMode, useSatty, playSound)
        }
    }

    // ── 7. POLKIT AUTHENTICATION AGENT (AUTOMATIC SYSTEM PROMPT) ────────────
    PolkitView {
        id: polkitView
        anchors.fill: parent
        active: root.active && root.currentView === 6
        isClosing: root.isClosingWallpaper
        animProgress: root.animProgress
        flow: root.polkitFlow
        visible: root.currentView === 6
        opacity: root.currentView === 6 ? 1.0 : 0.0
        scale: root.currentView === 6 ? 1.0 : 0.94

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        onCloseRequested: {
            root.closeRequested()
        }
    }

    // ── 8. CLIPBOARD MANAGER (SUPER + V) ────────────────────────────────────
    ClipboardView {
        id: clipboardView
        anchors.fill: parent
        active: root.active && root.currentView === 7
        isClosing: root.isClosingWallpaper
        animProgress: root.animProgress
        visible: root.currentView === 7
        opacity: root.currentView === 7 ? 1.0 : 0.0
        scale: root.currentView === 7 ? 1.0 : 0.94

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        onCloseRequested: {
            root.closeRequested()
        }
    }

    // ── 9. EMOJI STUDIO PICKER (SUPER + SHIFT + D) ──────────────────────────
    EmojiView {
        id: emojiView
        anchors.fill: parent
        active: root.active && root.currentView === 8
        isClosing: root.isClosingWallpaper
        animProgress: root.animProgress
        visible: root.currentView === 8
        opacity: root.currentView === 8 ? 1.0 : 0.0
        scale: root.currentView === 8 ? 1.0 : 0.94

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        onCloseRequested: {
            root.closeRequested()
        }
        onEmojiSelected: function(emoji) {
            root.closeRequested()
        }
    }

    // ── 10. KEYBINDS LAUNCHER (SUPER + SHIFT + H) ───────────────────────────
    KeybindsView {
        id: keybindsView
        anchors.fill: parent
        active: root.active && root.currentView === 9
        isClosing: root.isClosingWallpaper
        animProgress: root.animProgress
        visible: root.currentView === 9
        opacity: root.currentView === 9 ? 1.0 : 0.0
        scale: root.currentView === 9 ? 1.0 : 0.94

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        onCloseRequested: {
            root.closeRequested()
        }
    }
}
