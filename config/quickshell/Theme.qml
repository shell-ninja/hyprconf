pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // Dynamic Obsidian Glassmorphism Palette (auto-updated from colors.json without restarting Quickshell)
    property var _palette: ({
        primary: "#48bbf2",
        secondary: "#676fac",
        tertiary: "#e96779",
        accent: "#48bbf2",
        surface: "#171d20",
        background: "#0e1315",
        foreground: "#f2f2f3",
        on_primary: "#12151c",
        on_secondary: "#12151c",
        on_surface: "#f2f2f3",
        error: "#fd4663",
        on_error: "#181f25",
        muted: "#6b6372",
        variant: "vibrant"
    })

    readonly property color primary: _palette.primary || "#48bbf2"
    readonly property color secondary: _palette.secondary || "#676fac"
    readonly property color tertiary: _palette.tertiary || _palette.secondary || "#e96779"
    readonly property color accent: _palette.accent || _palette.primary || "#48bbf2"
    readonly property color surface: _palette.surface || "#171d20"
    readonly property color background: _palette.background || "#0e1315"
    readonly property color foreground: _palette.foreground || "#f2f2f3"
    readonly property color on_primary: _palette.on_primary || "#12151c"
    readonly property color on_secondary: _palette.on_secondary || "#12151c"
    readonly property color on_surface: _palette.on_surface || "#f2f2f3"
    readonly property color error: _palette.error || "#fd4663"
    readonly property color on_error: _palette.on_error || "#181f25"
    readonly property color muted: _palette.muted || "#6b6372"
    readonly property string variant: _palette.variant || "vibrant"

    readonly property string _colorsPath: {
        var h = Quickshell.env("HOME")
        if (h && h.length > 0) return h + "/.hyprconf/quickshell/colors.json"
        var u = Qt.resolvedUrl("colors.json").toString()
        return u.indexOf("file://") === 0 ? decodeURIComponent(u.slice(7)) : u
    }

    function _applyColorsJson(txt) {
        if (!txt || txt.trim().length === 0) return
        try {
            var parsed = JSON.parse(txt.trim())
            if (parsed && typeof parsed === "object" && parsed.primary) {
                root._palette = parsed
            }
        } catch (e) {}
    }

    readonly property FileView _colorsWatcher: FileView {
        id: colorsFileView
        path: root._colorsPath
        watchChanges: true
        onLoaded: root._applyColorsJson(text())
        onFileChanged: reload()
    }

    // Color helper functions
    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }

    function mix(c1, c2, ratio) {
        var t = Math.max(0.0, Math.min(1.0, ratio))
        return Qt.rgba(
            c1.r + (c2.r - c1.r) * t,
            c1.g + (c2.g - c1.g) * t,
            c1.b + (c2.b - c1.b) * t,
            c1.a + (c2.a - c1.a) * t
        )
    }

    // Unified Obsidian Frosted Glass Tokens (zero-cost reactive palette derivatives)
    readonly property color glassBase: Qt.rgba(background.r, background.g, background.b, 0.82)
    readonly property color glassElevated: Qt.rgba(surface.r, surface.g, surface.b, 0.72)
    readonly property color glassCard: Qt.rgba(surface.r, surface.g, surface.b, 0.56)
    readonly property color glassWell: Qt.rgba(background.r, background.g, background.b, 0.52)
    readonly property color glassRimTop: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.16)
    readonly property color glassRimMid: Qt.rgba(accent.r, accent.g, accent.b, 0.20)
    readonly property color glassRimBottom: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.04)
    readonly property color glassShadow: Qt.rgba(0, 0, 0, 0.48)
    readonly property color accentSoft: Qt.rgba(accent.r, accent.g, accent.b, 0.16)
    readonly property color accentGlow: Qt.rgba(accent.r, accent.g, accent.b, 0.34)
    readonly property color primarySoft: Qt.rgba(primary.r, primary.g, primary.b, 0.16)

    readonly property int radiusModal: 22
    readonly property int radiusCard: 16
    readonly property int radiusTile: 13
    readonly property int radiusPill: 999
}
