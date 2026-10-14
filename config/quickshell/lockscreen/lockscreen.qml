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
                clock: { x: 0.50, y: 0.18, preset: "top-center" },
                quote: { x: 0.50, y: 0.30, preset: "top-center" },
                avatar: { x: 0.50, y: 0.52, preset: "center" },
                weather: { x: 0.50, y: 0.64, preset: "custom" },
                media_player: { x: 0.25, y: 0.85, preset: "bottom-left" },
                system_stats: { x: 0.50, y: 0.89, preset: "bottom-center" }
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
                media_player: false,
                custom_quote: false,
                quote_text: "Crafting the digital realm.",
                system_stats: true,
                weather_widget: true,
                weather_city: "Dhaka"
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
        command: ["python3", root.homeDir + "/.hyprconf/hypr/scripts/system-stats.py"]
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
        interval: 10000
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

    // Entrance Animation properties
    property real entranceProgress: 0.0

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

    // Full-screen hero unlock animation properties
    property real uiHideProgress: 0.0
    property real heroLockScale: 0.18
    property real heroLockOpacity: 0.0
    property real heroShackleLift: 0.0
    property real heroShackleAngle: 0.0
    property real heroUnlockedGlow: 0.0
    property real shockwaveScale: 0.3
    property real shockwaveOpacity: 0.0
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
                fullScreenUnlockAnim.start()
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

    // Entrance Animation on lock
    SequentialAnimation {
        id: entranceAnim
        running: true
        PauseAnimation { duration: 50 }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "entranceProgress"
                to: 1.0
                duration: 520
                easing.type: Easing.OutCubic
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

    // Cinematic Full-Screen Hero Lock Unlock Animation (~750ms)
    SequentialAnimation {
        id: fullScreenUnlockAnim

        ParallelAnimation {
            NumberAnimation { target: root; property: "uiHideProgress"; to: 1.0; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "heroLockOpacity"; to: 1.0; duration: 180; easing.type: Easing.OutQuad }
            NumberAnimation { target: root; property: "heroLockScale"; from: 0.18; to: 1.0; duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.15 }
        }

        ParallelAnimation {
            NumberAnimation { target: root; property: "heroShackleLift"; to: -36; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
            NumberAnimation { target: root; property: "heroShackleAngle"; to: 28; duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
            NumberAnimation { target: root; property: "heroUnlockedGlow"; to: 1.0; duration: 240; easing.type: Easing.OutQuad }
            NumberAnimation { target: root; property: "heroLockScale"; to: 1.10; duration: 280; easing.type: Easing.OutBack }
            NumberAnimation { target: root; property: "shockwaveOpacity"; from: 0.95; to: 0.0; duration: 380; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "shockwaveScale"; from: 0.45; to: 3.5; duration: 380; easing.type: Easing.OutCubic }
        }

        ParallelAnimation {
            NumberAnimation { target: root; property: "heroLockScale"; to: 4.2; duration: 260; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "heroLockOpacity"; to: 0.0; duration: 240; easing.type: Easing.InQuad }
            NumberAnimation { target: root; property: "sceneFadeOut"; to: 0.0; duration: 260; easing.type: Easing.InQuad }
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
        interval: 40
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

                // Cached Static Wallpaper Backdrop with subtle zoom
                Item {
                    id: backdrop
                    anchors.fill: parent
                    layer.enabled: true

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
                            blur: (root.cfg && root.cfg.backdrop && root.cfg.backdrop.blur !== undefined) ? root.cfg.backdrop.blur : 0.55
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
                    opacity: (1.0 - root.uiHideProgress) * root.entranceProgress

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
                    opacity: (1.0 - root.uiHideProgress) * root.entranceProgress

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
                    opacity: (1.0 - root.uiHideProgress) * root.entranceProgress
                    scale: (1.0 - (root.uiHideProgress * 0.15)) * (0.95 + root.entranceProgress * 0.05)
                    visible: opacity > 0.01

                    readonly property real containerW: modulesContainer.width > 0 ? modulesContainer.width : (surface.screen ? surface.screen.width : 1920)
                    readonly property real containerH: modulesContainer.height > 0 ? modulesContainer.height : (surface.screen ? surface.screen.height : 1080)

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

                    // 1. Clock & AM/PM & Date Module
                    Item {
                        id: clockModule
                        width: Math.max(timeRow.implicitWidth, dateText.implicitWidth)
                        height: timeRow.implicitHeight + (dateText.visible ? (dateText.implicitHeight + 4) : 0)
                        x: modulesContainer.getModuleX("clock", 0.50, width)
                        y: modulesContainer.getModuleY("clock", 0.18, height)
                        visible: (root.cfg && root.cfg.clock) ? root.cfg.clock.enabled : true

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

                    // 2. Identity & Unlock Cluster (Avatar + DisplayName + Password Input Pill)
                    Item {
                        id: avatarAuthCluster
                        width: 380
                        height: avatarAuthCol.implicitHeight
                        x: modulesContainer.getModuleX("avatar", 0.50, width)
                        y: modulesContainer.getModuleY("avatar", 0.52, height)

                        Column {
                            id: avatarAuthCol
                            width: parent.width
                            spacing: (root.cfg && root.cfg.layout && root.cfg.layout.module_spacing !== undefined) ? root.cfg.layout.module_spacing : 20
                            anchors.horizontalCenter: parent.horizontalCenter

                    // Elevated Avatar with Continuous Breathing, Glowing Halo & Celestial Orbit
                    Item {
                        id: avatarSection
                        readonly property real baseSize: (root.cfg && root.cfg.avatar && root.cfg.avatar.size) ? root.cfg.avatar.size : 116
                        width: baseSize + 40
                        height: baseSize + 40
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: (root.cfg && root.cfg.avatar) ? root.cfg.avatar.enabled : true
                        scale: (0.88 + root.entranceProgress * 0.12) * (avatarHoverArea.containsMouse ? 1.04 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

                        // Layer 1: Ethereal Aurora Bloom (Breathing Glow Halo)
                        Rectangle {
                            anchors.centerIn: parent
                            width: avatarSection.baseSize + 20 + (root.ringGlowPulse * 20)
                            height: avatarSection.baseSize + 20 + (root.ringGlowPulse * 20)
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
                            width: avatarSection.baseSize + 16
                            height: avatarSection.baseSize + 16
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
                            width: avatarSection.baseSize + 24
                            height: avatarSection.baseSize + 24
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
                            width: avatarSection.baseSize + 14
                            height: avatarSection.baseSize + 14
                            radius: width / 2
                            color: Theme.alpha(Theme.surface, 0.40)
                            border.width: 1.5
                            border.color: root.authError
                                ? Theme.alpha(Theme.error, 0.80)
                                : (root.verifying ? Theme.alpha(Theme.accent, 0.90) : Theme.alpha(Theme.accent, 0.50))
                            Behavior on border.color { ColorAnimation { duration: 200 } }
                        }

                        // Layer 5: Inner Circular Avatar Container with Breathing Zoom
                        Item {
                            id: avatarContainer
                            readonly property real avatarSize: avatarSection.baseSize
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

                    // User Identity & Status Indicator
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 5
                        visible: (root.cfg && root.cfg.avatar) ? (root.cfg.avatar.show_username || root.cfg.avatar.show_status) : true

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.displayName
                            visible: (root.cfg && root.cfg.avatar) ? root.cfg.avatar.show_username : true
                            color: Theme.foreground
                            font.family: "Outfit"
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            font.letterSpacing: 2
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 6
                            opacity: 0.85
                            visible: (root.cfg && root.cfg.avatar) ? root.cfg.avatar.show_status : true

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

                    // Clear Optical iOS Liquid Glass Capsule
                    Item {
                        id: pillWrapper
                        width: 380
                        height: 52
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
                        }

                        // Glass tint
                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            antialiasing: true
                            color: root.authError
                                ? Theme.alpha(Theme.error, 0.18 + root.errorFlash * 0.20)
                                : (passwordField.activeFocus
                                    ? Theme.alpha(Theme.accent, 0.12)
                                    : Theme.alpha(Theme.surface, 0.40))
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
                            border.width: root.authError ? 1.5 : (passwordField.activeFocus ? 1.4 : 1.1)
                            border.color: root.authError
                                ? Theme.alpha(Theme.error, 0.85)
                                : (passwordField.activeFocus ? Theme.alpha(Theme.accent, 0.85) : Theme.alpha(Theme.foreground, 0.30))
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
                                    source: root.lockShackleSvg
                                    sourceSize: Qt.size(44, 44)
                                    opacity: root.verifying ? 0.75 : 0.95
                                }

                                Image {
                                    anchors.fill: parent
                                    source: root.lockBodySvg
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
                                placeholderText: root.authError ? "Incorrect password" : "Enter password"
                                placeholderTextColor: root.authError ? "#fda4af" : Qt.rgba(1, 1, 1, 0.65)
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
                        width: errorBadge.width
                        height: 28
                        anchors.horizontalCenter: parent.horizontalCenter

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
                }

                    // 3. Weather Forecast Capsule Module
                    Rectangle {
                        id: weatherModule
                        height: 32
                        width: weatherRow.implicitWidth + 28
                        radius: 16
                        color: Theme.alpha(Theme.surface, 0.50)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.35)
                        x: modulesContainer.getModuleX("weather", 0.50, width)
                        y: modulesContainer.getModuleY("weather", 0.64, height)
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
                                text: "24°C  •  " + ((root.cfg && root.cfg.modules && root.cfg.modules.weather_city) ? root.cfg.modules.weather_city : "Munshiganj")
                                color: Theme.foreground
                                font.family: "Outfit"
                                font.pixelSize: 12
                                font.weight: Font.Medium
                            }
                        }
                    }

                    // 4. Dynamic Custom Quote / Status Message Module
                    Rectangle {
                        id: quoteModule
                        height: 32
                        width: quoteRow.implicitWidth + 28
                        radius: 16
                        color: Theme.alpha(Theme.surface, 0.40)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.25)
                        x: modulesContainer.getModuleX("quote", 0.50, width)
                        y: modulesContainer.getModuleY("quote", 0.30, height)
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

                    // 5. Media Player Widget Module
                    Rectangle {
                        id: mediaModule
                        width: 320
                        height: 48
                        radius: 24
                        color: Theme.alpha(Theme.surface, 0.45)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.35)
                        x: modulesContainer.getModuleX("media_player", 0.25, width)
                        y: modulesContainer.getModuleY("media_player", 0.85, height)
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

                    // 6. System Stats Badge Module
                    Rectangle {
                        id: statsModule
                        height: 32
                        width: statsTextRow.implicitWidth + 28
                        radius: 16
                        color: Theme.alpha(Theme.surface, 0.50)
                        border.width: 1
                        border.color: Theme.alpha(Theme.accent, 0.30)
                        x: modulesContainer.getModuleX("system_stats", 0.50, width)
                        y: modulesContainer.getModuleY("system_stats", 0.89, height)
                        visible: Boolean(root.cfg && root.cfg.modules && root.cfg.modules.system_stats)

                        Row {
                            id: statsTextRow
                            anchors.centerIn: parent
                            spacing: 8

                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 13
                                height: 13
                                source: root.zapSvg
                                sourceSize: Qt.size(26, 26)
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.getSystemStatsString()
                                color: Theme.alpha(Theme.foreground, 0.85)
                                font.family: "Outfit"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }
                        }
                    }
                }

                // Full-Screen Hero Lock Unlock Overlay (Themed dynamic unlock colors)
                Item {
                    id: heroUnlockOverlay
                    anchors.fill: parent
                    visible: root.heroLockOpacity > 0.01
                    opacity: root.heroLockOpacity

                    // Dynamic Theme Shockwave Ring (No hardcoded green)
                    Rectangle {
                        width: 300
                        height: 300
                        radius: 150
                        anchors.centerIn: parent
                        scale: root.shockwaveScale
                        opacity: root.shockwaveOpacity
                        color: "transparent"
                        border.width: 2.5
                        border.color: Theme.alpha(Theme.accent, 0.75)
                    }

                    // Dynamic Theme Unlock Aura (No hardcoded green)
                    Rectangle {
                        width: 420
                        height: 420
                        radius: 210
                        anchors.centerIn: parent
                        scale: root.heroLockScale
                        color: Theme.alpha(Theme.accent, 0.20 * root.heroUnlockedGlow)
                        border.width: 1.5
                        border.color: Theme.alpha(Theme.accent, 0.35)
                    }

                    Item {
                        id: giantLockContainer
                        width: 260
                        height: 260
                        anchors.centerIn: parent
                        scale: root.heroLockScale

                        Image {
                            id: heroShackle
                            anchors.fill: parent
                            source: root.lockShackleSvg
                            sourceSize: Qt.size(512, 512)
                            smooth: true

                            transform: [
                                Translate { y: root.heroShackleLift },
                                Rotation {
                                    origin.x: giantLockContainer.width * 0.70
                                    origin.y: giantLockContainer.height * 0.45
                                    angle: root.heroShackleAngle
                                }
                            ]
                        }

                        Image {
                            id: heroBody
                            anchors.fill: parent
                            source: root.lockBodySvg
                            sourceSize: Qt.size(512, 512)
                            smooth: true
                        }

                        // Dynamic Center Keyhole Glow (Themed unlock pip)
                        Rectangle {
                            width: 26
                            height: 26
                            radius: 13
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: parent.height * 0.60
                            opacity: root.heroUnlockedGlow
                            scale: 0.8 + root.heroUnlockedGlow * 0.6
                            color: Theme.accent
                        }
                    }
                }

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
