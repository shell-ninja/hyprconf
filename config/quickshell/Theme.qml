pragma Singleton
import QtQuick

QtObject {
    // Dynamic Obsidian Glassmorphism Palette
    readonly property color primary: "#f82506"
    readonly property color secondary: "#564c7f"
    readonly property color accent: "#f82506"
    readonly property color surface: "#201817"
    readonly property color background: "#150f0e"
    readonly property color foreground: "#f2f2f3"
    readonly property color on_primary: "#12151c"
    readonly property color on_secondary: "#12151c"
    readonly property color on_surface: "#f2f2f3"
    readonly property color error: "#fd4663"
    readonly property color on_error: "#181f25"
    readonly property color muted: "#6b6372"

    // Color helper functions
    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }
}
