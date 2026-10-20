//@ pragma Env QS_NO_RELOAD_POPUP=1
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.Mpris
import Quickshell.Io

Scope {
    id: root

    readonly property string userName: {
        var u = Quickshell.env("USER")
        return (u && u.length > 0) ? u : "user"
    }

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : ("/home/" + userName)
    }

    readonly property string configPath: homeDir + "/.hyprconf/quickshell/lockscreen.json"

    function getDefaultConfig() {
        return {
            layout: {
                mode: "freeform",
                alignment: "center",
                vertical_offset: 0,
                module_spacing: 20,
                corner_power_buttons: true,
                corner_session_badge: true
            },
            positions: {
                clock: { x: 0.50, y: 0.18, scale: 1.0, preset: "top-center" },
                quote: { x: 0.50, y: 0.20, scale: 1.0, preset: "top-center" },
                user_avatar: { x: 0.50, y: 0.38, scale: 1.0, preset: "center" },
                username: { x: 0.50, y: 0.49, scale: 1.0, preset: "center" },
                session_lock: { x: 0.50, y: 0.53, scale: 1.0, preset: "center" },
                input_field: { x: 0.50, y: 0.60, scale: 1.0, preset: "center" },
                avatar: { x: 0.50, y: 0.52, scale: 1.0, preset: "center" },
                audio_visualizer: { x: 0.50, y: 0.72, scale: 1.0, preset: "bottom-center" },
                weather: { x: 0.50, y: 0.84, scale: 1.0, preset: "custom" },
                media_player: { x: 0.25, y: 0.88, scale: 1.0, preset: "bottom-left" },
                system_stats: { x: 0.50, y: 0.92, scale: 1.0, preset: "bottom-center" }
            },
            clock: {
                enabled: true,
                format_24h: false,
                show_am_pm: true,
                size: 84,
                weight: "Light"
            },
            date: {
                enabled: true,
                format: "long"
            },
            avatar: {
                enabled: true,
                size: 116,
                breathing_enabled: true,
                orbit_satellites_enabled: true,
                glow_enabled: true,
                show_username: true,
                show_status: true
            },
            modules: {
                user_avatar: true,
                username: true,
                session_lock: true,
                input_field: true,
                audio_visualizer: true,
                media_player: false,
                custom_quote: false,
                quote_text: "Crafting the digital realm.",
                system_stats: true,
                weather_widget: true,
                weather_city: "",
                weather_country: ""
            },
            stats: {
                show_uptime: true,
                show_ram: true,
                show_cpu: true,
                show_disk: false,
                show_battery: true,
                unit_format: "percent",
                separator: "•"
            },
            backdrop: {
                blur: 0.65,
                vignette: 0.60,
                dimming: 0.20
            },
            widget_backgrounds: {
                clock: false,
                quote: true,
                user_avatar: true,
                username: false,
                session_lock: true,
                input_field: true,
                audio_visualizer: true,
                weather: true,
                media_player: true,
                system_stats: true
            }
        }
    }

    function mergeConfig(dest, src) {
        for (var k in src) {
            if (typeof src[k] === "object" && src[k] !== null && !Array.isArray(src[k])) {
                if (!dest[k]) dest[k] = {}
                mergeConfig(dest[k], src[k])
            } else {
                dest[k] = src[k]
            }
        }
    }

    // Dynamic reactive configuration model
    property var cfg: getDefaultConfig()

    readonly property bool isFreeform: Boolean(root.cfg && root.cfg.layout && root.cfg.layout.mode === "freeform" && root.cfg.positions)

    function getModuleNormX(key, defaultNormX) {
        return (root.cfg && root.cfg.positions && root.cfg.positions[key] && root.cfg.positions[key].x !== undefined) ? root.cfg.positions[key].x : defaultNormX
    }

    function getModuleNormY(key, defaultNormY) {
        return (root.cfg && root.cfg.positions && root.cfg.positions[key] && root.cfg.positions[key].y !== undefined) ? root.cfg.positions[key].y : defaultNormY
    }

    property var sysStatsData: null

    Process {
        id: sysStatsProc
        command: ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/system-stats.py"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    try {
                        root.sysStatsData = JSON.parse(text.trim())
                    } catch(e) {}
                }
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            if (!sysStatsProc.running) {
                sysStatsProc.running = true
            }
        }
    }

    // Formatted System Stats string
    function getSystemStatsString() {
        var parts = []
        var s = (root.cfg && root.cfg.stats) ? root.cfg.stats : {}
        var unit = s.unit_format || "percent"
        var sep = s.separator || "•"
        var d = root.sysStatsData

        if (s.show_uptime !== false) {
            parts.push("Up: " + (d && d.uptime ? d.uptime : "1h 55m"))
        }
        if (s.show_cpu !== false) {
            parts.push("CPU: " + (d && d.cpu_pct !== undefined ? d.cpu_pct + "%" : "14%"))
        }
        if (s.show_ram !== false) {
            var rUsedGb = d ? (d.ram_used_bytes / (1024*1024*1024)).toFixed(1) : "3.8"
            var rTotGb = d ? (d.ram_total_bytes / (1024*1024*1024)).toFixed(1) : "16.0"
            var rMb = d ? Math.round(d.ram_used_bytes / (1024*1024)) : 3891
            var rKb = d ? Math.round(d.ram_used_bytes / 1024) : 3984384
            var rPct = d ? d.ram_pct : 24

            if (unit === "gb" || unit === "bytes") {
                parts.push("RAM: " + rUsedGb + " GB")
            } else if (unit === "mb") {
                parts.push("RAM: " + rMb + " MB")
            } else if (unit === "kb") {
                parts.push("RAM: " + rKb + " KB")
            } else if (unit === "detailed") {
                parts.push("RAM: " + rUsedGb + " / " + rTotGb + " GB")
            } else {
                parts.push("RAM: " + rPct + "%")
            }
        }
        if (s.show_disk) {
            var dFreeGb = d ? Math.round(d.disk_free_bytes / (1024*1024*1024)) : 94
            var dTotGb = d ? Math.round(d.disk_total_bytes / (1024*1024*1024)) : 119
            var dFreeMb = d ? Math.round(d.disk_free_bytes / (1024*1024)) : 95765
            var dFreeKb = d ? Math.round(d.disk_free_bytes / 1024) : 98063360
            var dFreePct = d ? d.disk_free_pct : 79

            if (unit === "gb" || unit === "bytes") {
                parts.push("Disk: " + dFreeGb + " GB free")
            } else if (unit === "mb") {
                parts.push("Disk: " + dFreeMb + " MB free")
            } else if (unit === "kb") {
                parts.push("Disk: " + dFreeKb + " KB free")
            } else if (unit === "detailed") {
                parts.push("Disk: " + dFreeGb + " GB free / " + dTotGb + " GB")
            } else {
                parts.push("Disk: " + dFreePct + "% free")
            }
        }
        if (s.show_battery !== false) {
            if (d && d.battery_pct >= 0) {
                parts.push("Bat: " + d.battery_pct + "%")
            } else if (!d) {
                parts.push("Bat: 85%")
            }
        }

        if (parts.length === 0) {
            return "System Online"
        }
        return parts.join("  " + sep + "  ")
    }

    // Load configuration from JSON
    Process {
        id: loadCfgProc
        command: ["cat", root.configPath]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(text)
                        var base = root.getDefaultConfig()
                        root.mergeConfig(base, parsed)
                        root.cfg = base
                    } catch(e) {
                        console.log("[lockscreen] Failed to parse config JSON:", e)
                    }
                }
            }
        }
    }

    Timer {
        id: reloadCfgTimer
        interval: 2000
        repeat: true
        running: true
        onTriggered: {
            if (!loadCfgProc.running) {
                loadCfgProc.running = true
            }
        }
    }

    readonly property string displayName: {
        var name = (userName && userName.length > 0) ? userName : "User"
        return name.split(/[-_]/).map(function(w) {
            return w.charAt(0).toUpperCase() + w.slice(1).toLowerCase()
        }).join(" ")
    }

    readonly property string primaryAvatar: "file://" + homeDir + "/.hyprconf/hypr/.cache/.face"
    readonly property string secondaryAvatar: "file:///var/lib/AccountsService/icons/" + userName

    property bool avatarFallback: false
    property bool verifying: false
    property bool authError: false
    property bool unlocked: false
    property string statusMessage: ""
    property string passwordBuffer: ""

    // Micro-interactions
    property real keypressBounce: 0.0

    // Continuous Avatar Breathing & Orbit properties
    property real avatarBreath: 0.0
    property real ringGlowPulse: 0.0
    property real avatarRippleScale: 1.0
    property real avatarRippleOpacity: 0.0

    // ── DYNAMIC ISLAND MORPH GEOMETRY & ANIMATION STATES ──────────────────
    readonly property real islandCollapsedWidth: 312
    readonly property real islandCollapsedHeight: 36
    readonly property real islandTopMargin: 10
    readonly property real islandRadius: 18

    // islandEntranceProgress: 0.0 (collapsed island) -> 1.0 (fully expanded lockscreen)
    property real islandEntranceProgress: 0.0
    // unlockShrinkProgress: 0.0 (expanded lockscreen) -> 1.0 (collapsed back into island)
    property real unlockShrinkProgress: 0.0

    // Unified morph progression: 0.0 = collapsed island notch, 1.0 = fully expanded lockscreen
    readonly property real islandProgress: root.unlocked ? Math.max(0.0, 1.0 - root.unlockShrinkProgress) : root.islandEntranceProgress
    property alias entranceProgress: root.islandEntranceProgress

    readonly property real screenW: (typeof surface !== "undefined" && surface && surface.width > 0) ? surface.width : 1920
    readonly property real screenH: (typeof surface !== "undefined" && surface && surface.height > 0) ? surface.height : 1080

    readonly property real islandCurrentWidth: islandCollapsedWidth + (screenW - islandCollapsedWidth) * islandProgress
    readonly property real islandCurrentHeight: islandCollapsedHeight + (screenH - islandCollapsedHeight) * islandProgress
    readonly property real islandCurrentY: islandTopMargin * (1.0 - islandProgress)
    readonly property real islandCurrentRadius: islandRadius * (1.0 - islandProgress)

    // Active Media Player Helpers
    readonly property var activePlayer: {
        if (!Mpris.players || !Mpris.players.values || Mpris.players.values.length === 0) return null
        for (var i = 0; i < Mpris.players.values.length; i++) {
            var p = Mpris.players.values[i]
            if (p && p.isPlaying) return p
        }
        return Mpris.players.values[0]
    }
    readonly property bool isMediaPlaying: Boolean(
        activePlayer &&
        activePlayer.isPlaying &&
        activePlayer.trackTitle &&
        activePlayer.trackTitle.trim().length > 0 &&
        activePlayer.trackTitle !== "No Media Playing"
    )
    readonly property string activeTrackTitle: (activePlayer && activePlayer.trackTitle && activePlayer.trackTitle.length > 0)
        ? activePlayer.trackTitle
        : "No Media Playing"
    readonly property string activeTrackArtist: (activePlayer && activePlayer.trackArtist && activePlayer.trackArtist.length > 0)
        ? activePlayer.trackArtist
        : "Paused"

    // Wrong-password animation properties
    property real pillShake: 0
    property real pillScale: 1.0
    property real lockRotation: 0
    property real errorFlash: 0.0

    property real uiHideProgress: 0.0
    property real sceneFadeOut: 1.0

    signal clearAndFocusPassword()

    // Inline SVG Helper
    function svgUrl(svgContent) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgContent)
    }

    // High-res Lock Body SVG tinted with dynamic Theme colors
    readonly property string lockBodySvg: svgUrl(
        '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">' +
        '<rect x="3.5" y="11" width="17" height="10.5" rx="3" ry="3" fill="' + Theme.alpha(Theme.surface, 0.40) + '"/>' +
        '<circle cx="12" cy="15.5" r="1.3" fill="' + Theme.accent + '"/>' +
        '<path d="M12 16.8v2.2" stroke-width="1.8" stroke="' + Theme.accent + '"/>' +
        '</svg>'
    )

    // High-res Lock Shackle SVG
    readonly property string lockShackleSvg: svgUrl(
        '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">' +
        '<path d="M7.2 11V7.2a4.8 4.8 0 0 1 9.6 0V11"/>' +
        '</svg>'
    )

    // High-res Unlocked Lock SVG tinted with dynamic Theme accent
    readonly property string unlockedSvg: svgUrl(
        '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">' +
        '<rect x="3.5" y="11" width="17" height="10.5" rx="3" ry="3" fill="' + Theme.alpha(Theme.accent, 0.25) + '"/>' +
        '<circle cx="12" cy="15.5" r="1.3" fill="' + Theme.accent + '"/>' +
        '<path d="M12 16.8v2.2" stroke-width="1.8" stroke="' + Theme.accent + '"/>' +
        '<path d="M7.2 11V7.2a4.8 4.8 0 0 1 9.6 0"/>' +
        '</svg>'
    )

    readonly property string eyeSvg: svgUrl(
        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">' +
        '<path d="M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0"/>' +
        '<circle cx="12" cy="12" r="3"/>' +
        '</svg>'
    )

    readonly property string eyeOffSvg: svgUrl(
        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">' +
        '<path d="M10.733 5.076a10.744 10.744 0 0 1 11.205 6.575 1 1 0 0 1 0 .696 10.747 10.747 0 0 1-1.444 2.49"/>' +
        '<path d="M14.084 14.158a3 3 0 0 1-4.242-4.242"/>' +
        '<path d="M17.479 17.499a10.75 10.75 0 0 1-15.417-5.151 1 1 0 0 1 0-.696 10.75 10.75 0 0 1 4.446-5.143"/>' +
        '<path d="m2 2 20 20"/>' +
        '</svg>'
    )

    readonly property string arrowRightSvg: svgUrl(
        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' +
        '<path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>' +
        '</svg>'
    )

    readonly property string alertSvg: svgUrl(
        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.error + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' +
        '<circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>' +
        '</svg>'
    )

    readonly property string powerSvg: svgUrl(
        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' +
        '<path d="M12 2v10"/><path d="M18.4 6.6a9 9 0 1 1-12.77.04"/>' +
        '</svg>'
    )

    readonly property string restartSvg: svgUrl(
        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.foreground + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' +
        '<path d="M21 12a9 9 0 0 0-9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/>' +
        '<path d="M3 3v5h5"/>' +
        '<path d="M3 12a9 9 0 0 0 9 9 9.75 9.75 0 0 0 6.74-2.74L21 16"/>' +
        '<path d="M21 21v-5h-5"/>' +
        '</svg>'
    )

    readonly property string spinnerSvg: svgUrl(
        '<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.5" stroke-linecap="round">' +
        '<path d="M12 2a10 10 0 0 1 10 10" stroke-opacity="0.95"/>' +
        '<path d="M12 2a10 10 0 1 0 0 20" stroke-opacity="0.2"/>' +
        '</svg>'
    )

    readonly property string userSvg: svgUrl(
        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.muted + '" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">' +
        '<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>' +
        '</svg>'
    )

    readonly property string musicSvg: svgUrl(
        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' +
        '<path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/>' +
        '</svg>'
    )

    readonly property string cloudSunSvg: svgUrl(
        "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"" + Theme.accent + "\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\">" +
        "<path d=\"M12 2v2\"/><path d=\"m4.93 4.93 1.41 1.41\"/><path d=\"M20 12h2\"/><path d=\"m19.07 4.93-1.41 1.41\"/><path d=\"M15.947 12.65a4 4 0 0 0-5.925-4.128\"/><path d=\"M13 22H7a5 5 0 1 1 4.9-6H13a3 3 0 0 1 0 6z\"/>" +
        "</svg>"
    )

    readonly property string zapSvg: svgUrl(
        "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"" + Theme.accent + "\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\">" +
        "<polygon points=\"13 2 3 14 12 14 11 22 21 10 12 10 13 2\"/>" +
        "</svg>"
    )

    // Dynamic 12-hour/date clock
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property date now: clock.date
    readonly property string timeStr: {
        var is24h = Boolean(root.cfg && root.cfg.clock && root.cfg.clock.format_24h)
        if (is24h) {
            return Qt.formatDateTime(now, "HH:mm")
        }
        var h = now.getHours() % 12
        if (h === 0) h = 12
        var hStr = (h < 10 ? "0" : "") + h
        var mStr = (now.getMinutes() < 10 ? "0" : "") + now.getMinutes()
        return hStr + ":" + mStr
    }
    readonly property string amPmStr: Qt.formatDateTime(now, "AP")
    readonly property string dateStr: (root.cfg.date && root.cfg.date.format === "compact")
        ? Qt.formatDateTime(now, "ddd, MMM d")
        : Qt.formatDateTime(now, "dddd, MMMM d")

    PamContext {
        id: pam
        user: root.userName
        configDirectory: "pam"
        config: "password"

        onPamMessage: {
            if (pam.responseRequired) {
                pam.respond(root.passwordBuffer)
            }
        }

        onCompleted: function(result) {
            root.verifying = false
            if (result === PamResult.Success) {
                root.authError = false
                root.statusMessage = ""
                root.passwordBuffer = ""
                root.unlocked = true
                unlockShrinkAnim.start()
            } else {
                root.authError = true
                root.statusMessage = "INCORRECT PASSWORD — TRY AGAIN"
                wrongPasswordAnim.restart()
                root.passwordBuffer = ""
                root.clearAndFocusPassword()
            }
        }

        onError: function(err) {
            root.verifying = false
            root.authError = true
            root.statusMessage = "PAM ERROR: " + PamError.toString(err)
            wrongPasswordAnim.restart()
            root.passwordBuffer = ""
            root.clearAndFocusPassword()
        }
    }

    // Micro tactile bounce on lock icon when typing
    SequentialAnimation {
        id: bounceAnim
        NumberAnimation { target: root; property: "keypressBounce"; to: -2.5; duration: 40; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "keypressBounce"; to: 0.0; duration: 60; easing.type: Easing.OutBounce }
    }

    // Continuous Organic Avatar Breathing & Halo Glow Pulse (runs all the time)
    SequentialAnimation {
        running: true
        loops: Animation.Infinite
        ParallelAnimation {
            NumberAnimation { target: root; property: "avatarBreath"; to: 1.0; duration: 3200; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "ringGlowPulse"; to: 1.0; duration: 3200; easing.type: Easing.InOutSine }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "avatarBreath"; to: 0.0; duration: 3200; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "ringGlowPulse"; to: 0.0; duration: 3200; easing.type: Easing.InOutSine }
        }
    }

    // Keystroke resonance ripple across the avatar ring
    ParallelAnimation {
        id: avatarRippleAnim
        NumberAnimation { target: root; property: "avatarRippleScale"; from: 1.0; to: 1.28; duration: 380; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "avatarRippleOpacity"; from: 0.75; to: 0.0; duration: 380; easing.type: Easing.OutQuad }
    }

    // ── EXPANSION FROM DYNAMIC ISLAND ON ENTRANCE ─────────────────────────────
    SequentialAnimation {
        id: islandEntranceAnim
        running: true
        PauseAnimation { duration: 25 }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "islandEntranceProgress"
                from: 0.0
                to: 1.0
                duration: 480
                easing.type: Easing.OutCubic
            }
        }
        ScriptAction {
            script: {
                passwordField.forceActiveFocus()
            }
        }
    }

    // Snappy Damped Wrong-Password Animation
    ParallelAnimation {
        id: wrongPasswordAnim

        SequentialAnimation {
            NumberAnimation { target: root; property: "pillShake"; to: -16; duration: 42; easing.type: Easing.OutQuad }
            NumberAnimation { target: root; property: "pillShake"; to: 14; duration: 48; easing.type: Easing.InOutQuad }
            NumberAnimation { target: root; property: "pillShake"; to: -10; duration: 48; easing.type: Easing.InOutQuad }
            NumberAnimation { target: root; property: "pillShake"; to: 6; duration: 48; easing.type: Easing.InOutQuad }
            NumberAnimation { target: root; property: "pillShake"; to: -2; duration: 42; easing.type: Easing.InOutQuad }
            NumberAnimation { target: root; property: "pillShake"; to: 0; duration: 45; easing.type: Easing.OutSine }
        }

        SequentialAnimation {
            NumberAnimation { target: root; property: "pillScale"; to: 0.95; duration: 55; easing.type: Easing.OutQuad }
            NumberAnimation { target: root; property: "pillScale"; to: 1.02; duration: 90; easing.type: Easing.OutBack }
            NumberAnimation { target: root; property: "pillScale"; to: 1.0; duration: 85; easing.type: Easing.OutSine }
        }

        SequentialAnimation {
            NumberAnimation { target: root; property: "lockRotation"; to: -18; duration: 45; easing.type: Easing.OutQuad }
            NumberAnimation { target: root; property: "lockRotation"; to: 16; duration: 52; easing.type: Easing.InOutQuad }
            NumberAnimation { target: root; property: "lockRotation"; to: -8; duration: 52; easing.type: Easing.InOutQuad }
            NumberAnimation { target: root; property: "lockRotation"; to: 0; duration: 60; easing.type: Easing.OutBack }
        }

        SequentialAnimation {
            NumberAnimation { target: root; property: "errorFlash"; to: 1.0; duration: 60; easing.type: Easing.OutQuad }
            NumberAnimation { target: root; property: "errorFlash"; to: 0.25; duration: 320; easing.type: Easing.OutCubic }
        }
    }

    // ── SHRINKING TO DYNAMIC ISLAND ON UNLOCK ────────────────────────────────
    SequentialAnimation {
        id: unlockShrinkAnim

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "unlockShrinkProgress"
                from: 0.0
                to: 1.0
                duration: 440
                easing.type: Easing.InOutCubic
            }
        }

        ScriptAction {
            script: {
                sessionLock.locked = false
                quitTimer.start()
            }
        }
    }

    Timer {
        id: quitTimer
        interval: 35
        repeat: false
        onTriggered: Qt.quit()
    }

    function attemptUnlock() {
        if (root.verifying || root.unlocked) return
        if (root.passwordBuffer.length === 0) {
            root.authError = true
            root.statusMessage = "PLEASE ENTER YOUR PASSWORD"
            wrongPasswordAnim.restart()
            return
        }
        root.authError = false
        root.errorFlash = 0.0
        root.statusMessage = ""
        root.verifying = true

        if (pam.active) {
            pam.abort()
        }

        if (!pam.start()) {
            root.verifying = false
            root.authError = true
            root.statusMessage = "COULD NOT START AUTHENTICATION"
            wrongPasswordAnim.restart()
        }
    }

    Process {
        id: powerProc
        command: ["systemctl", "poweroff"]
    }

    Process {
        id: rebootProc
        command: ["systemctl", "reboot"]
    }

    WlSessionLock {
        id: sessionLock
        locked: true

        WlSessionLockSurface {
            id: surface
            color: "transparent"

            Item {
                id: scene
                anchors.fill: parent
                opacity: root.sceneFadeOut

                MouseArea {
                    anchors.fill: parent
                    onClicked: passwordField.forceActiveFocus()
                }

                // ── DYNAMIC ISLAND EXPANDING / SHRINKING PORTAL ──────────────────
                Item {
                    id: islandMorphCard
                    x: Math.round((surface.width - root.islandCurrentWidth) / 2)
                    y: Math.round(root.islandCurrentY)
                    width: Math.round(root.islandCurrentWidth)
                    height: Math.round(root.islandCurrentHeight)
                    clip: true

                    // Solid Obsidian Background of the Dynamic Island (visible when collapsed or near-collapsed)
                    Rectangle {
                        id: islandBackground
                        anchors.fill: parent
                        radius: root.islandCurrentRadius
                        color: Theme.alpha(Theme.surface, 0.96)
                        opacity: Math.max(0.0, 1.0 - root.islandProgress * 3.0)
                        antialiasing: true
                    }

                    // Content viewport anchored to full screen coordinate space
                    Item {
                        id: contentWrapper
                        x: -islandMorphCard.x
                        y: -islandMorphCard.y
                        width: (typeof surface !== "undefined" && surface && surface.width > 0) ? surface.width : 1920
                        height: (typeof surface !== "undefined" && surface && surface.height > 0) ? surface.height : 1080

                        // Cached Static Wallpaper Backdrop with subtle zoom and dynamic blur
                        Item {
                            id: backdrop
                            anchors.fill: parent
                            layer.enabled: true
                            opacity: root.unlocked
                                ? Math.max(0.0, 1.0 - root.unlockShrinkProgress * 2.2)
                                : root.islandProgress

                            Rectangle {
                                anchors.fill: parent
                                color: Theme.background
                            }

                            Image {
                                id: wallpaperImage
                                anchors.fill: parent
                                source: "file://" + root.homeDir + "/.hyprconf/hypr/.cache/current_wallpaper.png"
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                                asynchronous: true
                                scale: 1.05 - (root.entranceProgress * 0.05)
                                Behavior on scale { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

                                onStatusChanged: {
                                    if (status === Image.Ready) {
                                        glassCapture.scheduleUpdate()
                                    }
                                }

                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    saturation: -0.20
                                    blurEnabled: true
                                    blur: ((root.cfg && root.cfg.backdrop && root.cfg.backdrop.blur !== undefined) ? root.cfg.backdrop.blur : 0.55) * root.islandProgress
                                    blurMax: 42
                                    brightness: -0.15
                                    contrast: 0.08
                                }
                            }

                            // Multi-stop cinematic dark vignette
                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.40) }
                                    GradientStop { position: 0.45; color: Qt.rgba(0, 0, 0, 0.12) }
                                    GradientStop {
                                        position: 1.0
                                        color: Qt.rgba(0, 0, 0, (root.cfg && root.cfg.backdrop && root.cfg.backdrop.vignette !== undefined) ? root.cfg.backdrop.vignette : 0.60)
                                    }
                                }
                            }
                        }

                // Bottom-Left Session Badge
                Row {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.margins: 32
                    spacing: 8
                    visible: (root.cfg && root.cfg.layout) ? root.cfg.layout.corner_session_badge : true
                    opacity: (1.0 - root.uiHideProgress) * (root.unlocked ? Math.max(0.0, 1.0 - root.unlockShrinkProgress * 3.5) : root.islandEntranceProgress)

                    Rectangle {
                        height: 32
                        width: sessionRow.implicitWidth + 24
                        radius: 16
                        color: Theme.alpha(Theme.surface, 0.50)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.30)

                        Row {
                            id: sessionRow
                            anchors.centerIn: parent
                            spacing: 8

                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 13
                                height: 13
                                source: root.lockBodySvg
                                sourceSize: Qt.size(26, 26)
                                opacity: 0.85
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Hyprland  •  Wayland"
                                color: Theme.alpha(Theme.foreground, 0.75)
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                font.letterSpacing: 1.2
                            }
                        }
                    }
                }

                // Bottom-Right Power & Restart Buttons
                Row {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: 32
                    spacing: 12
                    visible: (root.cfg && root.cfg.layout) ? root.cfg.layout.corner_power_buttons : true
                    opacity: (1.0 - root.uiHideProgress) * (root.unlocked ? Math.max(0.0, 1.0 - root.unlockShrinkProgress * 3.5) : root.islandEntranceProgress)

                    // Reboot Button
                    Rectangle {
                        width: 42
                        height: 42
                        radius: 21
                        color: restartMouse.containsMouse
                            ? Theme.alpha(Theme.accent, 0.35)
                            : Theme.alpha(Theme.surface, 0.45)
                        border.width: 1
                        border.color: restartMouse.containsMouse
                            ? Theme.alpha(Theme.accent, 0.70)
                            : Theme.alpha(Theme.accent, 0.25)
                        scale: restartMouse.pressed ? 0.94 : (restartMouse.containsMouse ? 1.06 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 120 } }
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        Image {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            source: root.restartSvg
                            sourceSize: Qt.size(36, 36)
                            opacity: 0.9
                        }

                        MouseArea {
                            id: restartMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rebootProc.running = true
                        }
                    }

                    // Power Button
                    Rectangle {
                        width: 42
                        height: 42
                        radius: 21
                        color: powerMouse.containsMouse
                            ? Theme.alpha(Theme.error, 0.40)
                            : Theme.alpha(Theme.surface, 0.45)
                        border.width: 1
                        border.color: powerMouse.containsMouse
                            ? Theme.alpha(Theme.error, 0.85)
                            : Theme.alpha(Theme.accent, 0.25)
                        scale: powerMouse.pressed ? 0.94 : (powerMouse.containsMouse ? 1.06 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 120 } }
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        Image {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            source: root.powerSvg
                            sourceSize: Qt.size(36, 36)
                            opacity: 0.9
                        }

                        MouseArea {
                            id: powerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: powerProc.running = true
                        }
                    }
                }

                // Modules Area Container (Freeform & Reactive Placement)
                Item {
                    id: modulesContainer
                    anchors.fill: parent
                    opacity: (1.0 - root.uiHideProgress) * (root.unlocked ? Math.max(0.0, 1.0 - root.unlockShrinkProgress * 2.5) : Math.max(0.0, (root.islandEntranceProgress - 0.15) / 0.85))
                    visible: opacity > 0.01

                    transform: [
                        Translate {
                            y: root.unlocked
                                ? (-root.unlockShrinkProgress * 120)
                                : ((1.0 - root.islandEntranceProgress) * -40)
                        },
                        Scale {
                            origin.x: ((typeof surface !== "undefined" && surface && surface.width > 0) ? surface.width : 1920) / 2
                            origin.y: root.islandCollapsedHeight / 2 + root.islandTopMargin
                            xScale: root.unlocked ? Math.max(0.60, 1.0 - root.unlockShrinkProgress * 0.40) : (0.92 + root.islandEntranceProgress * 0.08)
                            yScale: root.unlocked ? Math.max(0.60, 1.0 - root.unlockShrinkProgress * 0.40) : (0.92 + root.islandEntranceProgress * 0.08)
                        }
                    ]

                    readonly property real containerW: modulesContainer.width > 0 ? modulesContainer.width : ((typeof surface !== "undefined" && surface && surface.width > 0) ? surface.width : 1920)
                    readonly property real containerH: modulesContainer.height > 0 ? modulesContainer.height : ((typeof surface !== "undefined" && surface && surface.height > 0) ? surface.height : 1080)

                    function getModuleX(key, defaultNormX, itemWidth) {
                        var p = (root.cfg && root.cfg.positions && root.cfg.positions[key]) ? root.cfg.positions[key] : null
                        var nx = (p && p.x !== undefined) ? p.x : defaultNormX
                        return Math.max(16, Math.min(containerW - itemWidth - 16, Math.round(nx * containerW - itemWidth / 2)))
                    }

                    function getModuleY(key, defaultNormY, itemHeight) {
                        var p = (root.cfg && root.cfg.positions && root.cfg.positions[key]) ? root.cfg.positions[key] : null
                        var ny = (p && p.y !== undefined) ? p.y : defaultNormY
                        return Math.max(16, Math.min(containerH - itemHeight - 16, Math.round(ny * containerH - itemHeight / 2)))
                    }

                    function getModuleScale(key, defaultScale) {
                        var p = (root.cfg && root.cfg.positions && root.cfg.positions[key]) ? root.cfg.positions[key] : null
                        var sc = (p && p.scale !== undefined && p.scale > 0) ? p.scale : (defaultScale || 1.0)
                        return Math.max(0.4, Math.min(3.0, sc))
                    }

                    // 1. Clock & AM/PM & Date Module
                    Item {
                        id: clockModule
                        width: Math.max(timeRow.implicitWidth, dateText.implicitWidth)
                        height: timeRow.implicitHeight + (dateText.visible ? (dateText.implicitHeight + 4) : 0)
                        x: modulesContainer.getModuleX("clock", 0.50, width)
                        y: modulesContainer.getModuleY("clock", 0.18, height)
                        scale: modulesContainer.getModuleScale("clock", 1.0)
                        transformOrigin: Item.Center
                        visible: (root.cfg && root.cfg.clock) ? root.cfg.clock.enabled : true

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -12
                            radius: 20
                            visible: Boolean(root.cfg && root.cfg.widget_backgrounds && root.cfg.widget_backgrounds.clock)
                            color: Theme.alpha(Theme.surface, 0.45)
                            border.width: 1
                            border.color: Theme.alpha(Theme.accent, 0.30)
                            z: -1
                        }

                        Column {
                            id: clockCol
                            anchors.fill: parent
                            spacing: 4

                            Row {
                                id: timeRow
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 8

                                Text {
                                    id: timeText
                                    text: root.timeStr
                                    color: Theme.accent
                                    font.family: "Outfit"
                                    font.pixelSize: (root.cfg && root.cfg.clock && root.cfg.clock.size) ? root.cfg.clock.size : 84
                                    font.weight: (root.cfg && root.cfg.clock && root.cfg.clock.weight === "Bold") ? Font.Bold : ((root.cfg && root.cfg.clock && root.cfg.clock.weight === "Medium") ? Font.Medium : Font.Light)
                                    font.letterSpacing: 2
                                }

                                Text {
                                    anchors.bottom: timeText.bottom
                                    anchors.bottomMargin: 14
                                    text: root.amPmStr
                                    visible: (root.cfg && root.cfg.clock) ? (!root.cfg.clock.format_24h && root.cfg.clock.show_am_pm) : true
                                    color: Theme.alpha(Theme.accent, 0.90)
                                    font.family: "Outfit"
                                    font.pixelSize: 18
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 2
                                }
                            }

                            // Refined Date Line
                            Text {
                                id: dateText
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: (root.cfg && root.cfg.date) ? root.cfg.date.enabled : true
                                text: root.dateStr.toUpperCase()
                                color: Theme.alpha(Theme.foreground, 0.75)
                                font.family: "Outfit"
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                font.letterSpacing: 4
                            }
                        }
                    }

                    // 2a. User Avatar Module (Continuous Breathing, Glowing Halo & Celestial Orbit)
                    Item {
                        id: userAvatarModule
                        readonly property real baseSize: (root.cfg && root.cfg.avatar && root.cfg.avatar.size) ? root.cfg.avatar.size : 116
                        width: baseSize + 40
                        height: baseSize + 40
                        x: modulesContainer.getModuleX("user_avatar", 0.50, width)
                        y: modulesContainer.getModuleY("user_avatar", 0.38, height)
                        scale: modulesContainer.getModuleScale("user_avatar", 1.0)
                        transformOrigin: Item.Center
                        visible: ((root.cfg && root.cfg.avatar) ? root.cfg.avatar.enabled : true) &&
                                 ((root.cfg && root.cfg.modules) ? (root.cfg.modules.user_avatar !== false) : true)

                        Item {
                            id: avatarSection
                            anchors.centerIn: parent
                            width: userAvatarModule.baseSize + 40
                            height: userAvatarModule.baseSize + 40
                            scale: (0.88 + root.entranceProgress * 0.12) * (avatarHoverArea.containsMouse ? 1.04 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

                            // Layer 1: Ethereal Aurora Bloom (Breathing Glow Halo)
                            Rectangle {
                                anchors.centerIn: parent
                                width: userAvatarModule.baseSize + 20 + (root.ringGlowPulse * 20)
                                height: userAvatarModule.baseSize + 20 + (root.ringGlowPulse * 20)
                                radius: width / 2
                                visible: (root.cfg && root.cfg.avatar) ? root.cfg.avatar.glow_enabled : true
                                opacity: 0.35 + (root.ringGlowPulse * 0.35)
                                color: root.authError
                                    ? Theme.alpha(Theme.error, 0.35 + root.errorFlash * 0.30)
                                    : (root.verifying ? Theme.secondary : Theme.accent)
                                Behavior on color { ColorAnimation { duration: 240 } }
                            }

                            // Layer 2: Keystroke Resonance Ripple Ring
                            Rectangle {
                                anchors.centerIn: parent
                                width: userAvatarModule.baseSize + 16
                                height: userAvatarModule.baseSize + 16
                                radius: width / 2
                                scale: root.avatarRippleScale
                                opacity: root.avatarRippleOpacity
                                color: "transparent"
                                border.width: 2.0
                                border.color: Theme.accent
                            }

                            // Layer 3: Rotating Celestial Orbit Ring with Dual Plasma Satellites
                            Item {
                                anchors.centerIn: parent
                                width: userAvatarModule.baseSize + 24
                                height: userAvatarModule.baseSize + 24
                                visible: (root.cfg && root.cfg.avatar) ? root.cfg.avatar.orbit_satellites_enabled : true

                                RotationAnimation on rotation {
                                    from: 0
                                    to: 360
                                    duration: root.verifying ? 1000 : (avatarHoverArea.containsMouse ? 2800 : 6500)
                                    loops: Animation.Infinite
                                    running: true
                                }

                                // Concentric Orbit Guide Ring
                                Rectangle {
                                    anchors.fill: parent
                                    radius: width / 2
                                    color: "transparent"
                                    border.width: 1.2
                                    border.color: root.authError
                                        ? Theme.alpha(Theme.error, 0.70)
                                        : (root.verifying ? Theme.alpha(Theme.secondary, 0.85) : Theme.alpha(Theme.accent, 0.35 + root.ringGlowPulse * 0.25))
                                    Behavior on border.color { ColorAnimation { duration: 200 } }
                                }

                                // Satellite 1 (North Pole)
                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    x: (parent.width - width) / 2
                                    y: -height / 2
                                    color: root.authError ? Theme.error : Theme.accent
                                    border.width: 1.5
                                    border.color: "#ffffff"
                                }

                                // Satellite 2 (South Pole)
                                Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    x: (parent.width - width) / 2
                                    y: parent.height - height / 2
                                    color: root.authError ? Theme.error : Theme.secondary
                                    border.width: 1
                                    border.color: "#ffffff"
                                }
                            }

                            // Layer 4: Outer Concentric Glass Ring
                            Rectangle {
                                anchors.centerIn: parent
                                width: userAvatarModule.baseSize + 14
                                height: userAvatarModule.baseSize + 14
                                radius: width / 2
                                color: (root.cfg && root.cfg.widget_backgrounds && root.cfg.widget_backgrounds.user_avatar === false)
                                    ? "transparent"
                                    : Theme.alpha(Theme.surface, 0.40)
                                border.width: (root.cfg && root.cfg.widget_backgrounds && root.cfg.widget_backgrounds.user_avatar === false) ? 0 : 1.5
                                border.color: root.authError
                                    ? Theme.alpha(Theme.error, 0.80)
                                    : (root.verifying ? Theme.alpha(Theme.accent, 0.90) : Theme.alpha(Theme.accent, 0.50))
                                Behavior on border.color { ColorAnimation { duration: 200 } }
                            }

                            // Layer 5: Inner Circular Avatar Container with Breathing Zoom
                            Item {
                                id: avatarContainer
                                readonly property real avatarSize: userAvatarModule.baseSize
                                width: avatarSize
                                height: avatarSize
                                anchors.centerIn: parent
                                scale: (root.cfg && root.cfg.avatar && root.cfg.avatar.breathing_enabled) ? (1.0 + (root.avatarBreath * 0.045)) : 1.0

                                Item {
                                    id: avatarMask
                                    width: avatarContainer.avatarSize
                                    height: avatarContainer.avatarSize
                                    layer.enabled: true
                                    layer.smooth: true
                                    visible: false

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: width / 2
                                        color: "#ffffff"
                                        antialiasing: true
                                    }
                                }

                                Image {
                                    id: rawAvatarImg
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                    mipmap: true
                                    sourceSize: Qt.size(256, 256)
                                    source: root.primaryAvatar
                                    visible: false

                                    onStatusChanged: {
                                        if (status === Image.Error) {
                                            if (source == root.primaryAvatar) {
                                                source = root.secondaryAvatar
                                            } else {
                                                root.avatarFallback = true
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: width / 2
                                    color: root.avatarFallback ? Theme.surface : Theme.background
                                    antialiasing: true

                                    Image {
                                        anchors.centerIn: parent
                                        width: parent.width * 0.45
                                        height: parent.height * 0.45
                                        visible: root.avatarFallback
                                        source: root.userSvg
                                        sourceSize: Qt.size(116, 116)
                                    }
                                }

                                MultiEffect {
                                    anchors.fill: parent
                                    source: rawAvatarImg
                                    visible: !root.avatarFallback && rawAvatarImg.status === Image.Ready
                                    autoPaddingEnabled: false
                                    maskEnabled: true
                                    maskSource: avatarMask
                                    maskThresholdMin: 0.5
                                    maskSpreadAtMin: 1.0
                                }

                                // Lens specular crescent highlight
                                Rectangle {
                                    anchors.fill: parent
                                    radius: width / 2
                                    antialiasing: true
                                    gradient: Gradient {
                                        orientation: Gradient.Vertical
                                        GradientStop { position: 0.0; color: Theme.alpha(Theme.foreground, 0.26) }
                                        GradientStop { position: 0.35; color: Theme.alpha(Theme.foreground, 0.05) }
                                        GradientStop { position: 0.70; color: "transparent" }
                                    }
                                }

                                // Inner crisp border
                                Rectangle {
                                    anchors.fill: parent
                                    radius: width / 2
                                    color: "transparent"
                                    antialiasing: true
                                    border.width: 1.6
                                    border.color: root.authError ? Theme.alpha(Theme.error, 0.85) : Theme.alpha(Theme.accent, 0.75)
                                    Behavior on border.color { ColorAnimation { duration: 160 } }
                                }
                            }

                            MouseArea {
                                id: avatarHoverArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: passwordField.forceActiveFocus()
                            }
                        }
                    }

                    // 2b. Separated Username Module
                    Item {
                        id: usernameModule
                        width: usernameText.implicitWidth + 24
                        height: usernameText.implicitHeight + 8
                        x: modulesContainer.getModuleX("username", 0.50, width)
                        y: modulesContainer.getModuleY("username", 0.49, height)
                        scale: modulesContainer.getModuleScale("username", 1.0)
                        transformOrigin: Item.Center
                        visible: ((root.cfg && root.cfg.avatar) ? root.cfg.avatar.show_username : true) &&
                                 ((root.cfg && root.cfg.modules) ? (root.cfg.modules.username !== false) : true)

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            visible: Boolean(root.cfg && root.cfg.widget_backgrounds && root.cfg.widget_backgrounds.username)
                            color: Theme.alpha(Theme.surface, 0.45)
                            border.width: 1
                            border.color: Theme.alpha(Theme.accent, 0.28)
                            z: -1
                        }

                        Text {
                            id: usernameText
                            anchors.centerIn: parent
                            text: root.displayName
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            font.letterSpacing: 2
                        }
                    }

                    // 2c. Separated Session Lock Status Module
                    Item {
                        id: sessionLockModule
                        width: sessionStatusRow.implicitWidth + 20
                        height: sessionStatusRow.implicitHeight + 8
                        x: modulesContainer.getModuleX("session_lock", 0.50, width)
                        y: modulesContainer.getModuleY("session_lock", 0.53, height)
                        scale: modulesContainer.getModuleScale("session_lock", 1.0)
                        transformOrigin: Item.Center
                        visible: ((root.cfg && root.cfg.avatar) ? root.cfg.avatar.show_status : true) &&
                                 ((root.cfg && root.cfg.modules) ? (root.cfg.modules.session_lock !== false) : true)

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            visible: Boolean(root.cfg && root.cfg.widget_backgrounds && root.cfg.widget_backgrounds.session_lock !== false)
                            color: Theme.alpha(Theme.surface, 0.40)
                            border.width: 1
                            border.color: Theme.alpha(Theme.accent, 0.25)
                            z: -1
                        }

                        Row {
                            id: sessionStatusRow
                            anchors.centerIn: parent
                            spacing: 6
                            opacity: 0.85

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 6
                                height: 6
                                radius: 3
                                color: root.authError
                                    ? Theme.error
                                    : (root.verifying ? Theme.secondary : Theme.accent)
                                Behavior on color { ColorAnimation { duration: 180 } }

                                SequentialAnimation on opacity {
                                    running: root.verifying
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 0.4; to: 1.0; duration: 400; easing.type: Easing.InOutQuad }
                                    NumberAnimation { from: 1.0; to: 0.4; duration: 400; easing.type: Easing.InOutQuad }
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.authError
                                    ? "Locked (Authentication Failed)"
                                    : (root.verifying ? "Verifying..." : "Session Locked")
                                color: root.authError
                                    ? Theme.error
                                    : (root.verifying ? Theme.secondary : Theme.alpha(Theme.foreground, 0.70))
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: Font.Normal
                                font.letterSpacing: 1.2
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }
                        }
                    }

                    // 2d. Separated Password Input Field Module (Optical Glass Capsule + Error Badge)
                    Item {
                        id: inputFieldModule
                        width: 380
                        height: 52 + (errorBadgeContainer.visible ? 34 : 0)
                        x: modulesContainer.getModuleX("input_field", 0.50, width)
                        y: modulesContainer.getModuleY("input_field", 0.60, height)
                        scale: modulesContainer.getModuleScale("input_field", 1.0)
                        transformOrigin: Item.Center
                        visible: (root.cfg && root.cfg.modules) ? (root.cfg.modules.input_field !== false) : true

                        onXChanged: glassCapture.scheduleUpdate()
                        onYChanged: glassCapture.scheduleUpdate()

                        // Clear Optical iOS Liquid Glass Capsule
                        Item {
                            id: pillWrapper
                            width: 380
                            height: 52
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter

                            onXChanged: glassCapture.scheduleUpdate()
                            onYChanged: glassCapture.scheduleUpdate()

                            transform: [
                                Scale {
                                    origin.x: pillWrapper.width / 2
                                    origin.y: pillWrapper.height / 2
                                    xScale: root.pillScale
                                    yScale: root.pillScale
                                },
                                Translate { x: root.pillShake }
                            ]

                            ShaderEffectSource {
                                id: glassCapture
                                sourceItem: backdrop
                                anchors.fill: parent
                                visible: false
                                live: false
                                hideSource: false
                                sourceRect: {
                                    var p = pillWrapper.mapToItem(backdrop, 0, 0)
                                    var insetX = pillWrapper.width * 0.05
                                    var insetY = pillWrapper.height * 0.10
                                    return Qt.rect(
                                        p.x + insetX,
                                        p.y + insetY,
                                        pillWrapper.width - insetX * 2,
                                        pillWrapper.height - insetY * 2
                                    )
                                }
                            }

                            Item {
                                id: pillMask
                                anchors.fill: parent
                                layer.enabled: true
                                visible: false

                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: "white"
                                    antialiasing: true
                                }
                            }

                            MultiEffect {
                                anchors.fill: parent
                                source: glassCapture
                                autoPaddingEnabled: false
                                blurEnabled: true
                                blurMax: 24
                                blur: 0.35
                                saturation: 0.55
                                contrast: 0.20
                                brightness: 0.08
                                maskEnabled: true
                                maskSource: pillMask
                                maskThresholdMin: 0.5
                                maskSpreadAtMin: 1.0
                                visible: Boolean(root.cfg && root.cfg.widget_backgrounds ? root.cfg.widget_backgrounds.input_field !== false : true)
                            }

                            // Glass tint
                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                antialiasing: true
                                color: (root.cfg && root.cfg.widget_backgrounds && root.cfg.widget_backgrounds.input_field === false)
                                    ? "transparent"
                                    : (root.authError
                                        ? Theme.alpha(Theme.error, 0.18 + root.errorFlash * 0.20)
                                        : (passwordField.activeFocus
                                            ? Theme.alpha(Theme.accent, 0.12)
                                            : Theme.alpha(Theme.surface, 0.40)))
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            // Vertical specular highlights
                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                antialiasing: true
                                gradient: Gradient {
                                    orientation: Gradient.Vertical
                                    GradientStop { position: 0.0; color: Theme.alpha(Theme.foreground, 0.35) }
                                    GradientStop { position: 0.18; color: Theme.alpha(Theme.foreground, 0.08) }
                                    GradientStop { position: 0.55; color: "transparent" }
                                    GradientStop { position: 0.86; color: Qt.rgba(0, 0, 0, 0.10) }
                                    GradientStop { position: 1.0; color: Theme.alpha(Theme.foreground, 0.18) }
                                }
                            }

                            // Outer border
                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                antialiasing: true
                                color: "transparent"
                                border.width: root.unlocked ? 1.8 : (root.authError ? 1.5 : (passwordField.activeFocus ? 1.4 : 1.1))
                                border.color: root.unlocked
                                    ? Theme.accent
                                    : (root.authError
                                        ? Theme.alpha(Theme.error, 0.85)
                                        : (passwordField.activeFocus ? Theme.alpha(Theme.accent, 0.85) : Theme.alpha(Theme.foreground, 0.30)))
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                Behavior on border.width { NumberAnimation { duration: 150 } }
                            }

                            // Inner bevel border
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1.2
                                radius: height / 2
                                antialiasing: true
                                color: "transparent"
                                border.width: 1
                                border.color: Theme.alpha(Theme.foreground, 0.14)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 18
                                anchors.rightMargin: 12
                                spacing: 12

                                // Lock icon with micro-bounce
                                Item {
                                    Layout.preferredWidth: 22
                                    Layout.preferredHeight: 22
                                    rotation: root.lockRotation

                                    transform: Translate {
                                        y: root.keypressBounce
                                    }

                                    Image {
                                        anchors.fill: parent
                                        source: root.unlocked ? "" : root.lockShackleSvg
                                        sourceSize: Qt.size(44, 44)
                                        opacity: root.verifying ? 0.75 : 0.95
                                        visible: !root.unlocked
                                    }

                                    Image {
                                        anchors.fill: parent
                                        source: root.unlocked ? root.unlockedSvg : root.lockBodySvg
                                        sourceSize: Qt.size(44, 44)
                                        opacity: root.verifying ? 0.75 : 0.95
                                    }
                                }

                                TextField {
                                    id: passwordField
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    focus: true
                                    echoMode: TextInput.Password
                                    passwordCharacter: "●"
                                    placeholderText: root.unlocked ? "Unlocked" : (root.authError ? "Incorrect password" : "Enter password")
                                    placeholderTextColor: root.unlocked ? Theme.accent : (root.authError ? "#fda4af" : Qt.rgba(1, 1, 1, 0.65))
                                    color: "#ffffff"
                                    font.family: (passwordField.echoMode === TextInput.Password)
                                        ? "JetBrainsMono Nerd Font, Noto Sans, Outfit"
                                        : "Outfit, JetBrainsMono Nerd Font, sans-serif"
                                    font.pixelSize: (passwordField.echoMode === TextInput.Password) ? 17 : 15
                                    font.letterSpacing: (passwordField.echoMode === TextInput.Password && text.length > 0) ? 3 : 0.5
                                    selectionColor: Theme.alpha(Theme.accent, 0.45)
                                    selectedTextColor: "#ffffff"
                                    verticalAlignment: TextInput.AlignVCenter
                                    background: null
                                    enabled: !root.verifying && !root.unlocked

                                    onTextChanged: {
                                        root.passwordBuffer = text
                                        if (root.authError && text.length > 0) {
                                            root.authError = false
                                            root.errorFlash = 0.0
                                            root.statusMessage = ""
                                        }
                                        bounceAnim.restart()
                                        avatarRippleAnim.restart()
                                    }

                                    onAccepted: root.attemptUnlock()

                                    Keys.onEscapePressed: {
                                        text = ""
                                        root.passwordBuffer = ""
                                        root.authError = false
                                        root.statusMessage = ""
                                    }

                                    Connections {
                                        target: root
                                        function onClearAndFocusPassword() {
                                            passwordField.text = ""
                                            passwordField.forceActiveFocus()
                                        }
                                    }
                                }

                                // Show/Hide Password Eye Button
                                Item {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    visible: passwordField.text.length > 0 && !root.verifying

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 14
                                        color: eyeMouse.containsMouse ? Theme.alpha(Theme.accent, 0.25) : "transparent"
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    Image {
                                        anchors.centerIn: parent
                                        width: 17
                                        height: 17
                                        source: passwordField.echoMode === TextInput.Password
                                            ? root.eyeSvg
                                            : root.eyeOffSvg
                                        sourceSize: Qt.size(34, 34)
                                        opacity: eyeMouse.containsMouse ? 0.95 : 0.65
                                        Behavior on opacity { NumberAnimation { duration: 120 } }
                                    }

                                    MouseArea {
                                        id: eyeMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            passwordField.echoMode = (passwordField.echoMode === TextInput.Password)
                                                ? TextInput.Normal
                                                : TextInput.Password
                                            passwordField.forceActiveFocus()
                                        }
                                    }
                                }

                                // Spinner while verifying
                                Item {
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    visible: root.verifying

                                    Image {
                                        id: spinnerImg
                                        anchors.centerIn: parent
                                        width: 20
                                        height: 20
                                        source: root.spinnerSvg
                                        sourceSize: Qt.size(40, 40)

                                        RotationAnimation on rotation {
                                            from: 0
                                            to: 360
                                            duration: 800
                                            loops: Animation.Infinite
                                            running: root.verifying
                                        }
                                    }
                                }

                                // Submit Arrow Button
                                Rectangle {
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    radius: 16
                                    color: submitMouse.containsMouse
                                        ? Theme.alpha(Theme.accent, 0.45)
                                        : Theme.alpha(Theme.accent, 0.25)
                                    border.width: 1
                                    border.color: submitMouse.containsMouse
                                        ? Theme.alpha(Theme.accent, 0.85)
                                        : Theme.alpha(Theme.accent, 0.50)
                                    visible: passwordField.text.length > 0 && !root.verifying
                                    scale: submitMouse.pressed ? 0.93 : (submitMouse.containsMouse ? 1.06 : 1.0)
                                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Behavior on border.color { ColorAnimation { duration: 120 } }

                                    Image {
                                        anchors.centerIn: parent
                                        width: 16
                                        height: 16
                                        source: root.arrowRightSvg
                                        sourceSize: Qt.size(32, 32)
                                        opacity: submitMouse.containsMouse ? 1.0 : 0.85
                                    }

                                    MouseArea {
                                        id: submitMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.attemptUnlock()
                                    }
                                }
                            }
                        }

                        // Animated Error Badge Pill
                        Item {
                            id: errorBadgeContainer
                            width: parent.width
                            height: 28
                            anchors.top: pillWrapper.bottom
                            anchors.topMargin: 6
                            visible: root.authError && root.statusMessage.length > 0

                            Rectangle {
                                id: errorBadge
                                width: errorRow.implicitWidth + 24
                                height: 26
                                radius: 13
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: root.authError ? 0 : -6
                                opacity: root.authError && root.statusMessage.length > 0 ? 1.0 : 0.0
                                color: Theme.alpha(Theme.error, 0.25)
                                border.width: 1
                                border.color: Theme.alpha(Theme.error, 0.70)

                                Behavior on opacity { NumberAnimation { duration: 120 } }
                                Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                                Row {
                                    id: errorRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Image {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 13
                                        height: 13
                                        source: root.alertSvg
                                        sourceSize: Qt.size(26, 26)
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.statusMessage
                                        color: Theme.foreground
                                        font.family: "Outfit"
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 1.5
                                    }
                                }
                            }
                        }
                    }

                    // 3. Audio Visualizer Widget (Rounded Bars & Symmetrical CAVA Pattern)
                    Item {
                        id: audioVisualizerModule
                        width: 280
                        height: 52
                        x: modulesContainer.getModuleX("audio_visualizer", 0.50, width)
                        y: modulesContainer.getModuleY("audio_visualizer", 0.72, height)
                        scale: modulesContainer.getModuleScale("audio_visualizer", 1.0)
                        transformOrigin: Item.Center
                        visible: (root.cfg && root.cfg.modules) ? (root.cfg.modules.audio_visualizer !== false) : true

                        LockscreenAudioVisualizer {
                            anchors.centerIn: parent
                            previewMode: false
                            barCount: 16
                            showBackground: Boolean(root.cfg && root.cfg.widget_backgrounds ? root.cfg.widget_backgrounds.audio_visualizer !== false : true)
                        }
                    }

                    // 4. Weather Forecast Capsule Module
                    Rectangle {
                        id: weatherModule
                        height: 32
                        width: weatherRow.implicitWidth + 28
                        radius: 16
                        color: (root.cfg && root.cfg.widget_backgrounds && root.cfg.widget_backgrounds.weather === false)
                            ? "transparent"
                            : Theme.alpha(Theme.surface, 0.50)
                        border.width: (root.cfg && root.cfg.widget_backgrounds && root.cfg.widget_backgrounds.weather === false) ? 0 : 1
                        border.color: Theme.alpha(Theme.accent, 0.35)
                        x: modulesContainer.getModuleX("weather", 0.50, width)
                        y: modulesContainer.getModuleY("weather", 0.84, height)
                        scale: modulesContainer.getModuleScale("weather", 1.0)
                        transformOrigin: Item.Center
                        visible: Boolean(root.cfg && root.cfg.modules && root.cfg.modules.weather_widget)

                        Row {
                            id: weatherRow
                            anchors.centerIn: parent
                            spacing: 8
                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 15; height: 15
                                source: root.cloudSunSvg
                                sourceSize: Qt.size(30, 30)
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: {
                                    var city = (root.cfg && root.cfg.modules && root.cfg.modules.weather_city) ? root.cfg.modules.weather_city : ""
                                    var country = (root.cfg && root.cfg.modules && root.cfg.modules.weather_country) ? root.cfg.modules.weather_country : ""
                                    var loc = (city.length > 0 && country.length > 0) ? (city + ", " + country) : (city.length > 0 ? city : (country.length > 0 ? country : "Weather"))
                                    return "24°C  •  " + loc
                                }
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: Font.Medium
                            }
                        }
                    }

                    // 5. Dynamic Custom Quote / Status Message Module
                    Rectangle {
                        id: quoteModule
                        height: 32
                        width: quoteRow.implicitWidth + 28
                        radius: 16
                        color: (root.cfg && root.cfg.widget_backgrounds && root.cfg.widget_backgrounds.quote === false)
                            ? "transparent"
                            : Theme.alpha(Theme.surface, 0.40)
                        border.width: (root.cfg && root.cfg.widget_backgrounds && root.cfg.widget_backgrounds.quote === false) ? 0 : 1
                        border.color: Theme.alpha(Theme.accent, 0.25)
                        x: modulesContainer.getModuleX("quote", 0.50, width)
                        y: modulesContainer.getModuleY("quote", 0.20, height)
                        scale: modulesContainer.getModuleScale("quote", 1.0)
                        transformOrigin: Item.Center
                        visible: Boolean(root.cfg && root.cfg.modules && root.cfg.modules.custom_quote)

                        Row {
                            id: quoteRow
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "“"
                                color: Theme.accent
                                font.family: "Outfit"
                                font.pixelSize: 14
                                font.weight: Font.Bold
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: (root.cfg && root.cfg.modules && root.cfg.modules.quote_text) ? root.cfg.modules.quote_text : ""
                                color: Theme.alpha(Theme.foreground, 0.85)
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.italic: true
                                font.letterSpacing: 0.8
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "”"
                                color: Theme.accent
                                font.family: "Outfit"
                                font.pixelSize: 14
                                font.weight: Font.Bold
                            }
                        }
                    }

                    // 6. Media Player Widget Module
                    Rectangle {
                        id: mediaModule
                        width: 320
                        height: 48
                        radius: 24
                        color: (root.cfg && root.cfg.widget_backgrounds && root.cfg.widget_backgrounds.media_player === false)
                            ? "transparent"
                            : Theme.alpha(Theme.surface, 0.45)
                        border.width: (root.cfg && root.cfg.widget_backgrounds && root.cfg.widget_backgrounds.media_player === false) ? 0 : 1
                        border.color: Theme.alpha(Theme.accent, 0.35)
                        x: modulesContainer.getModuleX("media_player", 0.25, width)
                        y: modulesContainer.getModuleY("media_player", 0.88, height)
                        scale: modulesContainer.getModuleScale("media_player", 1.0)
                        transformOrigin: Item.Center
                        visible: Boolean(root.cfg && root.cfg.modules && root.cfg.modules.media_player && root.isMediaPlaying)

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10

                            Rectangle {
                                width: 28
                                height: 28
                                radius: 14
                                color: Theme.alpha(Theme.accent, 0.25)
                                border.width: 1
                                border.color: Theme.alpha(Theme.accent, 0.50)

                                Image {
                                    anchors.centerIn: parent
                                    width: 14
                                    height: 14
                                    source: root.musicSvg
                                    sourceSize: Qt.size(28, 28)
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    width: 250
                                    elide: Text.ElideRight
                                    text: root.activeTrackTitle
                                    color: Theme.foreground
                                    font.family: "Outfit"
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    width: 250
                                    elide: Text.ElideRight
                                    text: root.activeTrackArtist
                                    color: Theme.alpha(Theme.foreground, 0.65)
                                    font.family: "Outfit"
                                    font.pixelSize: 10
                                }
                            }
                        }
                    }

                    // 7. System Stats Graph Module (CPU, GPU, RAM Smooth Area Graphs)
                    Item {
                        id: statsModule
                        width: 320
                        height: 76
                        x: modulesContainer.getModuleX("system_stats", 0.50, width)
                        y: modulesContainer.getModuleY("system_stats", 0.92, height)
                        scale: modulesContainer.getModuleScale("system_stats", 1.0)
                        transformOrigin: Item.Center
                        visible: Boolean(root.cfg && root.cfg.modules && root.cfg.modules.system_stats)

                        LockscreenSystemGraph {
                            anchors.fill: parent
                            statsData: root.sysStatsData
                            previewMode: false
                            showBackground: Boolean(root.cfg && root.cfg.widget_backgrounds ? root.cfg.widget_backgrounds.system_stats !== false : true)
                        }
                    }
                }

                    } // close contentWrapper

                    // High-precision Anti-Aliased Island Outer Border
                    Rectangle {
                        id: islandBorder
                        anchors.fill: parent
                        radius: root.islandCurrentRadius
                        color: "transparent"
                        border.width: root.islandProgress >= 0.999 ? 0 : 1.5
                        border.color: root.unlocked
                            ? Theme.alpha(Theme.accent, 0.90)
                            : Theme.alpha(Theme.accent, 0.50)
                        antialiasing: true
                        z: 100
                    }

                    // Mini Dynamic Island Content (Shown when collapsed or near-collapsed)
                    Item {
                        id: compactIslandBar
                        anchors.fill: parent
                        opacity: Math.max(0.0, 1.0 - root.islandProgress * 3.0)
                        visible: opacity > 0.01
                        z: 101

                        Row {
                            anchors.centerIn: parent
                            spacing: 10

                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 14
                                height: 14
                                source: root.unlocked ? root.unlockedSvg : root.lockBodySvg
                                sourceSize: Qt.size(28, 28)
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.unlocked ? "UNLOCKED" : "SYSTEM LOCKED"
                                color: root.unlocked ? Theme.accent : Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                font.letterSpacing: 2
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 6
                                height: 6
                                radius: 3
                                color: root.unlocked ? Theme.accent : Theme.alpha(Theme.accent, 0.70)
                            }
                        }
                    }
                } // close islandMorphCard

                Timer {
                    interval: 40
                    running: true
                    repeat: false
                    onTriggered: {
                        passwordField.forceActiveFocus()
                        glassCapture.scheduleUpdate()
                    }
                }
            }
        }
    }
}
