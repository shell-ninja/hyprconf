pragma Singleton
import QtQuick

QtObject {
    // Noctalia Dynamic Palette
    readonly property color primary: "#c358f3"
    readonly property color secondary: "#f358d5"
    readonly property color accent: "#c358f3"
    readonly property color surface: "#290439"
    readonly property color background: "#290439"
    readonly property color foreground: "#f2f2f3"
    readonly property color on_primary: "#211825"
    readonly property color on_secondary: "#211825"
    readonly property color on_surface: "#f2f2f3"
    readonly property color error: "#fd4663"
    readonly property color on_error: "#211825"
    readonly property color muted: "#6a606f"

    // Color helper functions
    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }
}
