import QtQuick
import "."

// Inline-SVG icon. No emojis, no glyph fonts, no icon packs.
// Every icon is a 24x24 stroke drawing: stroke-width 1.8, round caps/joins.
Item {
    id: root

    property string name: ""
    property color color: Theme.foreground
    property real size: 16
    property real strokeWidth: 1.8
    property bool filled: false

    implicitWidth: size
    implicitHeight: size

    readonly property var shapes: ({
        grid: '<rect x="3" y="3" width="7" height="7" rx="1.6"/><rect x="14" y="3" width="7" height="7" rx="1.6"/><rect x="3" y="14" width="7" height="7" rx="1.6"/><rect x="14.5" y="14.5" width="6" height="6" rx="1.2" transform="rotate(45 17.5 17.5)"/>',
        chevronDown: '<path d="M6 9l6 6 6-6"/>',
        moon: '<path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z"/>',
        moonStar: '<path d="M20 14.5A8 8 0 1 1 9.5 4a6.2 6.2 0 0 0 10.5 10.5z"/><path d="M18 2.5v4M16 4.5h4"/>',
        bolt: '<path d="M13 2L4 14h7l-1 8 9-12h-7l1-8z"/>',
        bell: '<path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 0 1-3.4 0"/>',
        coffee: '<path d="M5 9h12v5a5 5 0 0 1-5 5h-2a5 5 0 0 1-5-5V9z"/><path d="M17 11h1.5a2.5 2.5 0 0 1 0 5H17"/><path d="M8 3v3M12 3v3"/>',
        clipboard: '<rect x="5" y="4" width="14" height="17" rx="2"/><rect x="9" y="2.5" width="6" height="3.5" rx="1"/><path d="M9 12h6M9 16h4"/>',
        gauge: '<path d="M3.5 17.5a9 9 0 1 1 17 0"/><path d="M12 15l4-5"/><circle cx="12" cy="15" r="1"/>',
        volume: '<path d="M11 5L6 9H3v6h3l5 4V5z"/><path d="M15.5 8.5a5 5 0 0 1 0 7"/><path d="M18.5 5.5a9 9 0 0 1 0 13"/>',
        volumeMute: '<path d="M11 5L6 9H3v6h3l5 4V5z"/><path d="M16 9.5l5 5M21 9.5l-5 5"/>',
        power: '<path d="M12 3v9"/><path d="M6.4 6.6a8 8 0 1 0 11.2 0"/>',
        search: '<circle cx="11" cy="11" r="7"/><path d="M20.5 20.5L16 16"/>',
        lock: '<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
        logout: '<path d="M9 4H5a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h4"/><path d="M16 17l5-5-5-5M21 12H9"/>',
        reboot: '<path d="M20 11a8 8 0 1 0-2.3 5.7"/><path d="M20 4v7h-7"/>',
        x: '<path d="M6 6l12 12M18 6L6 18"/>',
        play: '<path d="M7 4.5v15l12-7.5z"/>',
        pause: '<path d="M8 5v14M16 5v14"/>',
        next: '<path d="M5 5l10 7-10 7z"/><path d="M19 5v14"/>',
        prev: '<path d="M19 5L9 12l10 7z"/><path d="M5 5v14"/>',
        cpu: '<rect x="6" y="6" width="12" height="12" rx="2"/><rect x="9.5" y="9.5" width="5" height="5"/><path d="M9 2v4M15 2v4M9 18v4M15 18v4M2 9h4M2 15h4M18 9h4M18 15h4"/>',
        ram: '<rect x="2.5" y="7" width="19" height="10" rx="1.5"/><path d="M6.5 17v2.5M10.5 17v2.5M14.5 17v2.5M18 17v2.5"/><path d="M6 11h3M11 11h3M16 11h2"/>',
        disk: '<ellipse cx="12" cy="6" rx="8" ry="3"/><path d="M4 6v12c0 1.7 3.6 3 8 3s8-1.3 8-3V6"/><path d="M4 12c0 1.7 3.6 3 8 3s8-1.3 8-3"/>',
        sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
        cloud: '<path d="M7 18a4.5 4.5 0 0 1-.5-9 6 6 0 0 1 11.5 1.5A3.8 3.8 0 0 1 17.5 18z"/>',
        cloudSun: '<circle cx="8" cy="8" r="3"/><path d="M8 2v1.5M2 8h1.5M3.8 3.8l1 1M12.2 3.8l-1 1"/><path d="M9 20a4 4 0 0 1-.4-8 5 5 0 0 1 9.6 1.3A3.4 3.4 0 0 1 17 20z"/>',
        rain: '<path d="M7 15a4.5 4.5 0 0 1-.5-9 6 6 0 0 1 11.5 1.5A3.8 3.8 0 0 1 17.5 15z"/><path d="M8 18v3M12 18v3M16 18v3"/>',
        wifi: '<path d="M2 9a15 15 0 0 1 20 0"/><path d="M5.5 12.5a10 10 0 0 1 13 0"/><path d="M9 16a5 5 0 0 1 6 0"/><circle cx="12" cy="19.5" r="0.8"/>',
        bluetooth: '<path d="M7 7l10 10-5 4V3l5 4L7 17"/>',
        folder: '<path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>',
        camera: '<path d="M4 8h3l2-3h6l2 3h3v11H4z"/><circle cx="12" cy="13" r="3.5"/>',
        leaf: '<path d="M5 19C5 10 10 5 20 4c0 10-4 15-12 15"/><path d="M5 19c2-5 5-8 9-10"/>',
        app: '<rect x="4" y="4" width="16" height="16" rx="4"/><path d="M9 12h6"/>'
    })

    function rgb(c) {
        return "rgb(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + ")"
    }

    readonly property string svgSource: {
        const inner = shapes[name]
        if (!inner)
            return ""
        const col = rgb(color)
        const doc = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"'
            + ' fill="' + (filled ? col : "none") + '" stroke="' + col + '" stroke-opacity="' + color.a + '"'
            + ' stroke-width="' + strokeWidth + '" stroke-linecap="round" stroke-linejoin="round">'
            + inner + '</svg>'
        return "data:image/svg+xml;utf8," + encodeURIComponent(doc)
    }

    Image {
        anchors.fill: parent
        source: root.svgSource
        sourceSize.width: Math.ceil(root.size * 3)
        sourceSize.height: Math.ceil(root.size * 3)
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }
}
