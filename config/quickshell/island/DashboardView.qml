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
    signal dismissAppNotifications(string appName)

    property var polkitFlow: null

    implicitWidth: {
        if (currentView === 2) return 960
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
        if (currentView === 2) return 395
        if (currentView === 3) return launcherView ? launcherView.preferredHeight : 420
        if (currentView === 4) return 500
        if (currentView === 5) return 380
        if (currentView === 6) return 370
        if (currentView === 7) return clipboardView ? clipboardView.preferredHeight : 520
        if (currentView === 8) return emojiView ? emojiView.preferredHeight : 510
        if (currentView === 9) return keybindsView ? keybindsView.preferredHeight : 520
        return 496
    }

    // For currentView === 0 (Main Dashboard):
    // 3 Main Pages: 0: WeatherPage (Page 1), 1: HomePage / Control Center (Page 2, initial on hover), 2: StatusPage (Page 3)
    // Note: Internet speed / process network detail is a subpage of StatusPage.
    property int dashboardPage: 1

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
            if (root.dashboardPage === 1 && homePage.isWifiDialogOpen) {
                if (event.key === Qt.Key_Escape) {
                    homePage.closeWifiDialog()
                    event.accepted = true
                    return true
                }
                return true
            }
            if (root.dashboardPage === 2 && statusPage && statusPage.showingNetworkDetail) {
                if (event.key === Qt.Key_Escape || event.key === Qt.Key_Left) {
                    statusPage.showingNetworkDetail = false
                    event.accepted = true
                    return true
                }
            }
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


    property bool pendingNetworkDetail: false

    property alias homePage: homePage
    readonly property var statusPage: statusLoader.item
    readonly property var networkDetailPage: statusLoader.item ? statusLoader.item.networkDetailPage : null
    readonly property var weatherPage: weatherLoader.item
    readonly property var powerView: powerLoader.item
    readonly property var wallpaperView: wallpaperLoader.item
    readonly property var launcherView: launcherLoader.item
    readonly property var themeSwitcherView: themeSwitcherLoader.item
    readonly property var screenshotView: screenshotLoader.item
    readonly property var polkitView: polkitLoader.item
    readonly property var clipboardView: clipboardLoader.item
    readonly property var emojiView: emojiLoader.item
    readonly property var keybindsView: keybindsLoader.item

    property bool keepWeatherAlive: false
    property bool keepStatusAlive: false
    property bool keepPowerAlive: false

    readonly property bool wantWeather: root.currentView === 0 && root.dashboardPage === 0
    readonly property bool wantStatus: root.currentView === 0 && root.dashboardPage === 2
    readonly property bool wantPower: root.currentView === 1

    onWantWeatherChanged: {
        if (wantWeather) {
            weatherUnloadTimer.stop()
            keepWeatherAlive = true
        } else {
            weatherUnloadTimer.restart()
        }
    }
    onWantStatusChanged: {
        if (wantStatus) {
            statusUnloadTimer.stop()
            keepStatusAlive = true
        } else {
            statusUnloadTimer.restart()
        }
    }
    onWantPowerChanged: {
        if (wantPower) {
            powerUnloadTimer.stop()
            keepPowerAlive = true
        } else {
            powerUnloadTimer.restart()
        }
    }

    Timer { id: weatherUnloadTimer; interval: 280; onTriggered: root.keepWeatherAlive = false }
    Timer { id: statusUnloadTimer; interval: 280; onTriggered: root.keepStatusAlive = false }
    Timer { id: powerUnloadTimer; interval: 280; onTriggered: root.keepPowerAlive = false }

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

    // ── 1A. WEATHER FORECAST PAGE (PAGE 1 / INDEX 0 — LAZY-LOADED) ───────────
    Loader {
        id: weatherLoader
        anchors.fill: parent
        active: root.wantWeather || root.keepWeatherAlive
        visible: opacity > 0.001
        opacity: root.wantWeather ? 1.0 : 0.0
        scale: root.wantWeather ? 1.0 : 0.95
        x: (root.dashboardPage === 0) ? 0 : -28

        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        sourceComponent: Component {
            WeatherPage {
                anchors.fill: parent
                active: root.active && root.currentView === 0 && root.dashboardPage === 0
                onBackClicked: root.dashboardPage = 1
                onNavigateToControl: root.dashboardPage = 1
                onPageDotClicked: function(pageIdx) { root.dashboardPage = pageIdx }
            }
        }
    }

    // ── 1B. HOME / CONTROL CENTER (PAGE 2 / INDEX 1 - INITIAL HOVER PAGE) ────
    HomePage {
        id: homePage
        wallpaperTimestamp: root.wallpaperTimestamp
        anchors.fill: parent
        active: root.active && root.currentView === 0 && root.dashboardPage === 1
        visible: opacity > 0.001
        opacity: (root.currentView === 0 && root.dashboardPage === 1) ? 1.0 : 0.0
        scale: (root.currentView === 0 && root.dashboardPage === 1) ? 1.0 : 0.95
        x: (root.dashboardPage === 1) ? 0 : ((root.dashboardPage === 0) ? 28 : -28)

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
        onDismissAppNotifications: function(appName) {
            root.dismissAppNotifications(appName)
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
        onNavigateToWeather: {
            root.dashboardPage = 0
        }
        onNavigateToPage2: {
            root.dashboardPage = 2
        }
    }

    // ── 1C. SYSTEM STATUS & METRICS (PAGE 3 / INDEX 2 — LAZY-LOADED) ─────────
    Loader {
        id: statusLoader
        anchors.fill: parent
        active: root.wantStatus || root.keepStatusAlive
        visible: opacity > 0.001
        opacity: root.wantStatus ? 1.0 : 0.0
        scale: root.wantStatus ? 1.0 : 0.95
        x: (root.dashboardPage === 2) ? 0 : 28

        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        onLoaded: {
            if (item && root.pendingNetworkDetail) {
                item.showingNetworkDetail = true
                root.pendingNetworkDetail = false
            }
        }

        sourceComponent: Component {
            StatusPage {
                anchors.fill: parent
                active: root.active && root.currentView === 0 && root.dashboardPage === 2
                onBackClicked: root.dashboardPage = 1
                onPageDotClicked: function(pageIdx) { root.dashboardPage = pageIdx }
            }
        }
    }

    // ── 2. POWER CONTROL PAGE (LAZY-LOADED) ──────────────────────────────────
    Loader {
        id: powerLoader
        anchors.fill: parent
        active: root.wantPower || root.keepPowerAlive
        visible: opacity > 0.001
        opacity: root.currentView === 1 ? 1.0 : 0.0
        scale: root.currentView === 1 ? 1.0 : 0.94

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        sourceComponent: Component {
            PowerView {
                anchors.fill: parent
                active: root.active && root.currentView === 1
                onBackClicked: {
                    root.currentView = 0
                }
            }
        }
    }

    // ── 3. WALLPAPER SELECTOR PAGE (LAZY-LOADED) ─────────────────────────────
    Loader {
        id: wallpaperLoader
        anchors.fill: parent
        active: root.currentView === 2
        visible: active
        sourceComponent: Component {
            WallpaperView {
                active: root.active && root.currentView === 2
                isClosing: root.isClosingWallpaper
                animProgress: root.animProgress
                onBackClicked: root.closeRequested()
            }
        }
    }

    // ── 4. APP LAUNCHER PAGE (SUPER + D / SUPER + SPACE) (LAZY-LOADED) ───────
    Loader {
        id: launcherLoader
        anchors.fill: parent
        active: root.currentView === 3
        visible: active
        sourceComponent: Component {
            LauncherView {
                wallpaperTimestamp: root.wallpaperTimestamp
                active: root.active && root.currentView === 3
                isClosing: root.isClosingWallpaper
                animProgress: root.animProgress
                onCloseRequested: root.closeRequested()
                onOpenThemeSwitcherRequested: root.currentView = 4
            }
        }
    }

    // ── 5. LAUNCHER THEME SELECTOR (SUPER + ALT + D) (LAZY-LOADED) ───────────
    Loader {
        id: themeSwitcherLoader
        anchors.fill: parent
        active: root.currentView === 4
        visible: active
        sourceComponent: Component {
            ThemeSwitcherView {
                wallpaperTimestamp: root.wallpaperTimestamp
                active: root.active && root.currentView === 4
                isClosing: root.isClosingWallpaper
                animProgress: root.animProgress
                onCloseRequested: root.closeRequested()
                onLaunchLauncherRequested: root.launchLauncherRequested()
            }
        }
    }

    // ── 6. SCREENSHOT STUDIO PAGE (PRINT / QS-SCREENSHOT.SH) (LAZY-LOADED) ────
    Loader {
        id: screenshotLoader
        anchors.fill: parent
        active: root.currentView === 5
        visible: active
        sourceComponent: Component {
            ScreenshotView {
                active: root.active && root.currentView === 5
                isClosing: root.isClosingWallpaper
                animProgress: root.animProgress
                onCloseRequested: root.closeRequested()
                onStartTimerScreenshot: function(seconds, targetMode, useSatty, playSound) {
                    root.startTimerScreenshot(seconds, targetMode, useSatty, playSound)
                }
            }
        }
    }

    // ── 7. POLKIT AUTHENTICATION AGENT (LAZY-LOADED) ─────────────────────────
    Loader {
        id: polkitLoader
        anchors.fill: parent
        active: root.currentView === 6
        visible: active
        sourceComponent: Component {
            PolkitView {
                active: root.active && root.currentView === 6
                isClosing: root.isClosingWallpaper
                animProgress: root.animProgress
                flow: root.polkitFlow
                onCloseRequested: root.closeRequested()
            }
        }
    }

    // ── 8. CLIPBOARD MANAGER (SUPER + V) (LAZY-LOADED) ───────────────────────
    Loader {
        id: clipboardLoader
        anchors.fill: parent
        active: root.currentView === 7
        visible: active
        sourceComponent: Component {
            ClipboardView {
                active: root.active && root.currentView === 7
                isClosing: root.isClosingWallpaper
                animProgress: root.animProgress
                onCloseRequested: root.closeRequested()
            }
        }
    }

    // ── 9. EMOJI STUDIO PICKER (SUPER + SHIFT + D) (LAZY-LOADED) ────────────
    Loader {
        id: emojiLoader
        anchors.fill: parent
        active: root.currentView === 8
        visible: active
        sourceComponent: Component {
            EmojiView {
                active: root.active && root.currentView === 8
                isClosing: root.isClosingWallpaper
                animProgress: root.animProgress
                onCloseRequested: root.closeRequested()
                onEmojiSelected: function(emoji) {
                    root.closeRequested()
                }
            }
        }
    }

    // ── 10. KEYBINDS LAUNCHER (SUPER + SHIFT + H) (LAZY-LOADED) ─────────────
    Loader {
        id: keybindsLoader
        anchors.fill: parent
        active: root.currentView === 9
        visible: active
        sourceComponent: Component {
            KeybindsView {
                active: root.active && root.currentView === 9
                isClosing: root.isClosingWallpaper
                animProgress: root.animProgress
                onCloseRequested: root.closeRequested()
            }
        }
    }
}
