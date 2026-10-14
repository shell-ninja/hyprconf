pragma Singleton
import QtQuick

QtObject {
    // Noctalia Dynamic Palette
    readonly property color primary: "#f588a3"
    readonly property color secondary: "#f5a488"
    readonly property color accent: "#f588a3"
    readonly property color surface: "#291419"
    readonly property color background: "#291419"
    readonly property color foreground: "#f3f2f2"
    readonly property color on_primary: "#25181c"
    readonly property color on_secondary: "#25181c"
    readonly property color on_surface: "#f3f2f2"
    readonly property color error: "#f7303a"
    readonly property color on_error: "#23161a"
    readonly property color muted: "#716266"

    // Color helper functions
    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }
}
