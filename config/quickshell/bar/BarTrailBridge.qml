import QtQuick
import "."

Item {
    id: bridge

    property string theme: (typeof bar !== "undefined" && bar && bar.trailStyle) ? bar.trailStyle : "matrix"
    property bool reverse: false

    visible: theme !== "none" && width > 24
    height: 20
    clip: false

    // =========================================================================
    // THEME 1: MATRIX CYBER STREAM
    // =========================================================================
    Item {
        anchors.fill: parent
        visible: bridge.theme === "matrix"

        // Center hairline rail
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 1.2
            color: Theme.alpha(Theme.accent, 0.24)
        }

        // Static constellation nodes
        Rectangle {
            x: Math.round(parent.width * 0.28 - width / 2)
            anchors.verticalCenter: parent.verticalCenter
            width: 2.5; height: 2.5; radius: 1.25
            color: Theme.alpha(Theme.accent, 0.35)
        }
        Rectangle {
            x: Math.round(parent.width * 0.72 - width / 2)
            anchors.verticalCenter: parent.verticalCenter
            width: 2.5; height: 2.5; radius: 1.25
            color: Theme.alpha(Theme.accent, 0.35)
        }

        // Flowing cybernetic stream particles
        Item {
            id: matrixContainer
            anchors.fill: parent

            property real streamPhase: 0.0
            NumberAnimation on streamPhase {
                from: 0.0
                to: 1.0
                duration: 2200
                loops: Animation.Infinite
                running: bridge.visible && bridge.theme === "matrix"
                easing.type: Easing.Linear
            }

            Repeater {
                model: 3
                Item {
                    readonly property real offset: index * 0.333
                    readonly property real progress: (matrixContainer.streamPhase + offset) % 1.0
                    readonly property real nodeSpan: 22

                    x: bridge.reverse
                       ? ((1.0 - progress) * (bridge.width + nodeSpan) - nodeSpan)
                       : (progress * (bridge.width + nodeSpan) - nodeSpan)

                    anchors.verticalCenter: parent.verticalCenter
                    width: nodeSpan
                    height: 16

                    opacity: {
                        if (progress < 0.15) return progress / 0.15
                        if (progress > 0.85) return (1.0 - progress) / 0.15
                        return 1.0
                    }

                    // Outer halo
                    Rectangle {
                        anchors.centerIn: parent
                        width: (index % 2 === 0) ? 14 : 9
                        height: width
                        radius: width / 2
                        color: Theme.alpha(Theme.accent, (index % 2 === 0) ? 0.25 : 0.18)
                    }

                    // Energetic core
                    Rectangle {
                        anchors.centerIn: parent
                        width: (index % 2 === 0) ? 4 : 2.5
                        height: width
                        radius: width / 2
                        color: Theme.accent
                    }
                }
            }
        }
    }

    // =========================================================================
    // THEME 2: THUNDER STORM SINE WAVE OSCILLATION (Braided Electric Waveform)
    // =========================================================================
    Item {
        id: stormContainer
        anchors.fill: parent
        visible: bridge.theme === "thunder" || bridge.theme === "storm"

        property real wavePhase: 0.0

        NumberAnimation on wavePhase {
            from: 0.0
            to: Math.PI * 2
            duration: 2800
            loops: Animation.Infinite
            running: bridge.visible && (bridge.theme === "thunder" || bridge.theme === "storm")
            easing.type: Easing.Linear
        }

        onWavePhaseChanged: {
            if (waveCanvas.visible) waveCanvas.requestPaint()
        }

        // Atmospheric soft lightning flash behind wave (harmonized with Theme.accent)
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 8
            radius: 4
            color: Theme.alpha(Theme.accent, 0.12)

            SequentialAnimation on opacity {
                running: bridge.visible && (bridge.theme === "thunder" || bridge.theme === "storm")
                loops: Animation.Infinite
                NumberAnimation { from: 0.05; to: 0.45; duration: 50 }
                NumberAnimation { from: 0.45; to: 0.12; duration: 70 }
                NumberAnimation { from: 0.12; to: 0.60; duration: 40 }
                NumberAnimation { from: 0.60; to: 0.05; duration: 240 }
                PauseAnimation { duration: 3200 }
            }
        }

        // Braided Multi-Strand Electric Sine Waveform Canvas
        Canvas {
            id: waveCanvas
            anchors.fill: parent
            antialiasing: true
            smooth: true

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var w = width
                var h = height
                if (w <= 10) return

                var cy = h / 2
                var amp = 4.8 // amplitude
                var wavelength = 58.0 // spacious wavelength with breathing room
                var freq = (Math.PI * 2) / wavelength
                var taperLen = 28.0 // smooth edge taper distance
                var p = bridge.reverse ? -stormContainer.wavePhase : stormContainer.wavePhase

                function getEnv(x) {
                    if (x < taperLen) {
                        return Math.sin((x / taperLen) * (Math.PI / 2))
                    } else if (x > w - taperLen) {
                        return Math.sin(((w - x) / taperLen) * (Math.PI / 2))
                    }
                    return 1.0
                }

                ctx.lineCap = "round"
                ctx.lineJoin = "round"

                // ── STRAND 1: Primary Electric Wave (Theme.accent) ──
                ctx.lineWidth = 1.4
                ctx.strokeStyle = Theme.accent
                ctx.beginPath()
                for (var x1 = 0; x1 <= w; x1 += 2) {
                    var y1 = cy + Math.sin(x1 * freq + p) * amp * getEnv(x1)
                    if (x1 === 0) ctx.moveTo(x1, y1)
                    else ctx.lineTo(x1, y1)
                }
                ctx.stroke()

                // ── STRAND 2: Counter-Phase Braided Plasma Wave (Theme.secondary / Theme.alpha) ──
                ctx.lineWidth = 1.4
                ctx.strokeStyle = Theme.alpha(Theme.secondary, 0.85)
                ctx.beginPath()
                for (var x2 = 0; x2 <= w; x2 += 2) {
                    var y2 = cy + Math.sin(x2 * freq + p + Math.PI) * amp * getEnv(x2)
                    if (x2 === 0) ctx.moveTo(x2, y2)
                    else ctx.lineTo(x2, y2)
                }
                ctx.stroke()
            }
        }

        // Travelling High-Voltage Spark / Plasma Bead on the Wave Crest
        Item {
            id: sparkTraveller
            property real sparkProgress: (stormContainer.wavePhase / (Math.PI * 2))

            readonly property real sparkX: bridge.reverse
                ? (1.0 - sparkProgress) * bridge.width
                : sparkProgress * bridge.width

            readonly property real sparkY: {
                var cy = bridge.height / 2
                var amp = 4.8
                var freq = (Math.PI * 2) / 58.0
                var p = bridge.reverse ? -stormContainer.wavePhase : stormContainer.wavePhase
                var taperLen = 28.0
                var env = 1.0
                if (sparkX < taperLen) env = Math.sin((sparkX / taperLen) * (Math.PI / 2))
                else if (sparkX > bridge.width - taperLen) env = Math.sin(((bridge.width - sparkX) / taperLen) * (Math.PI / 2))
                return cy + Math.sin(sparkX * freq + p) * amp * env
            }

            x: sparkX - width / 2
            y: sparkY - height / 2
            width: 8
            height: 8

            opacity: {
                var pr = sparkTraveller.sparkProgress
                if (pr < 0.1) return pr / 0.1
                if (pr > 0.9) return (1.0 - pr) / 0.1
                return 1.0
            }

            // Outer electric halo (Theme.accent)
            Rectangle {
                anchors.centerIn: parent
                width: 8; height: 8; radius: 4
                color: Theme.alpha(Theme.accent, 0.35)
            }

            // White-hot spark core
            Rectangle {
                anchors.centerIn: parent
                width: 2.5; height: 2.5; radius: 1.25
                color: Theme.on_surface
            }
        }
    }
}
