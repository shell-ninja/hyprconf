pragma Singleton
import QtQuick

QtObject {
    // Noctalia Dynamic Palette
    readonly property color primary: "#67aae4"
    readonly property color secondary: "#5c60d6"
    readonly property color accent: "#67aae4"
    readonly property color surface: "#161f27"
    readonly property color background: "#161f27"
    readonly property color foreground: "#f2f2f3"
    readonly property color on_primary: "#e8f2fa"
    readonly property color on_secondary: "#e8f2fa"
    readonly property color on_surface: "#f2f2f3"
    readonly property color error: "#fd4663"
    readonly property color on_error: "#181f25"
    readonly property color muted: "#616a71"

    // Color helper functions
    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }
}
