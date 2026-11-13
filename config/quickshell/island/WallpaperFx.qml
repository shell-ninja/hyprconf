// WallpaperFx.qml — native Quickshell wallpaper transitions (GLSL ShaderEffect).
//
// Renders dynamic, non-traditional wallpaper transitions directly on the desktop shell
// (WlrLayer.Bottom, above awww and below windows).
//
// Modes:
//   contagio (0): Ragged 4px pixel colonies eat through the old wallpaper along
//                 a noise field, burning in the theme's vibrant accent color.
//   perfil   (1): On character wallpapers, the old wallpaper dims to B&W, a thin
//                 vector line traces the character's outline from the top, the character
//                 fills in, and the rest of the new wallpaper spreads outward from it.
//
// When transition ends at t=1.0, awww switches silently underneath with transition-type none.

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import ".."

Scope {
    id: root

    readonly property string onlyScreen: Quickshell.env("WALLFX_ONLY") || ""
    readonly property bool dry: Quickshell.env("WALLFX_DRY") === "1"

    // ─── Tuning ───
    property int msContagio: 1100
    property int msPerfil: 1400
    property int msFade: 0
    property real glow: 0.9
    property real lineW: 2.2

    // ─── One change ───
    property string oldPath: ""
    property string newPath: ""
    property string kind: "contagio"
    property string fieldPath: ""
    property string linePath: ""
    property bool autoGo: true
    property string phase: "idle"
    property real t: 0
    property real fade: 0
    property bool swapped: false
    property int gen: 0
    property int swapGen: -1
    property color ember: Theme.accent
    property color ink: Theme.foreground
    property real seed: 0
    property int readyCount: 0
    readonly property int screenCount: screens.instances.length
    readonly property bool active: phase !== "idle"

    function lifted(c) {
        return Qt.hsla(c.hslHue, Math.max(c.hslSaturation, 0.55),
                       Math.min(Math.max(c.hslLightness, 0.62), 0.82), 1)
    }

    function prepare(o, n, k, f, l, go) {
        if (root.active) root.finish()
        root.oldPath = o
        root.newPath = n
        root.kind = k === "perfil" ? "perfil" : "contagio"
        root.fieldPath = f
        root.linePath = l || f
        root.autoGo = go
        root.t = 0
        root.fade = 0
        root.readyCount = 0
        root.swapped = false
        root.gen++
        root.phase = "loading"
        watchdog.restart()
    }

    function screenReady() {
        if (root.phase !== "loading") return
        root.readyCount++
        if (root.readyCount < root.screenCount) return
        watchdog.stop()
        if (root.dry) { root.fade = 1; root.phase = "ready"; if (root.autoGo) root.go(); return }
        root.go()
    }

    function go() {
        if (root.phase !== "ready" && root.phase !== "loading") return
        root.ember = root.lifted(Theme.accent)
        root.ink = Theme.foreground
        root.seed = Math.random() * 100
        root.phase = "run"
        root.fade = 1.0
        run.duration = root.kind === "perfil" ? root.msPerfil : root.msContagio
        run.restart()
        root.swap()
        if (!root.dry) fadeIn.restart()
    }

    function maybeFinish() {
        if (root.dry) { if (!run.running) root.phase = "done"; return }
        if (run.running) return
        if (!root.swapped) { root.phase = "held"; watchdog.restart(); return }
        root.finish()
    }

    function awwwImg(path, extra) {
        return ["awww", "img", path].concat(root.onlyScreen ? ["--outputs", root.onlyScreen] : [], extra)
    }

    function swap() {
        root.swapGen = root.gen
        awww.command = root.awwwImg(root.newPath, ["--transition-type", "none"])
        awww.running = true
    }

    function finish() {
        fadeIn.stop(); run.stop(); fadeOut.stop(); watchdog.stop(); settle.stop()
        root.phase = "idle"; root.fade = 0; root.t = 0
        root.oldPath = ""; root.newPath = ""; root.fieldPath = ""; root.linePath = ""
    }

    NumberAnimation {
        id: fadeIn
        target: root; property: "fade"; from: 0; to: 1
        duration: 40; easing.type: Easing.OutQuad
    }

    NumberAnimation {
        id: run
        target: root; property: "t"; from: 0; to: 1
        easing.type: Easing.Linear
        onFinished: root.maybeFinish()
    }

    NumberAnimation {
        id: fadeOut
        target: root; property: "fade"; from: 1; to: 0
        duration: root.msFade; easing.type: Easing.OutQuad
        onFinished: root.finish()
    }

    Process {
        id: awww
        onExited: (code) => {
            if (root.swapGen !== root.gen) return
            if (code === 0) { settle.restart(); return }
            const n = root.newPath
            root.finish()
            Quickshell.execDetached(root.awwwImg(n, ["--transition-type", "none"]))
        }
    }

    Timer { id: settle; interval: 40; onTriggered: { root.swapped = true; root.maybeFinish() } }

    Timer {
        id: watchdog; interval: 6000
        onTriggered: {
            const n = root.newPath, loading = root.phase === "loading"
            root.finish()
            if (loading && !root.dry && n)
                Quickshell.execDetached(root.awwwImg(n, ["--transition-type", "none"]))
        }
    }

    IpcHandler {
        target: "wallfx"
        function play(oldImg: string, newImg: string, kind: string, field: string, line: string): string {
            root.prepare(oldImg, newImg, kind, field, line, true)
            return "ok"
        }
        function prepare(oldImg: string, newImg: string, kind: string, field: string, line: string): string {
            root.prepare(oldImg, newImg, kind, field, line, false)
            return "ok"
        }
        function go(): string { root.go(); return root.phase }
        function state(): string { return root.phase }
        function stop(): string { root.finish(); return "ok" }
    }

    Variants {
        id: screens
        model: Quickshell.screens.filter(s => !root.onlyScreen || s.name === root.onlyScreen)

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: root.active
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "quickshell:wallfx"

            readonly property bool loaded: oldImg.status === Image.Ready && newImg.status === Image.Ready
                && fieldImg.status === Image.Ready && lineImg.status === Image.Ready
            onLoadedChanged: if (loaded) root.screenReady()

            Image {
                id: oldImg
                visible: false
                asynchronous: true
                cache: false
                source: root.oldPath ? ("file://" + root.oldPath) : ""
                fillMode: Image.PreserveAspectCrop
            }

            Image {
                id: newImg
                visible: false
                asynchronous: true
                cache: false
                source: root.newPath ? ("file://" + root.newPath) : ""
                fillMode: Image.PreserveAspectCrop
            }

            Image {
                id: fieldImg
                visible: false
                cache: false
                smooth: root.kind === "perfil"
                source: root.fieldPath ? ("file://" + root.fieldPath) : ""
            }

            Image {
                id: lineImg
                visible: false
                cache: false
                source: root.linePath ? ("file://" + root.linePath) : ""
            }

            function crop(img) {
                const iw = Math.max(img.implicitWidth, 1), ih = Math.max(img.implicitHeight, 1)
                const s = Math.max(win.width / iw, win.height / ih)
                const w = win.width / (iw * s), h = win.height / (ih * s)
                return Qt.vector4d((1 - w) / 2, (1 - h) / 2, w, h)
            }

            ShaderEffect {
                anchors.fill: parent
                visible: win.loaded
                opacity: root.fade
                property var oldTex: oldImg
                property var newTex: newImg
                property var fieldTex: fieldImg
                property var lineTex: lineImg
                property real t: root.t
                property real mode: root.kind === "perfil" ? 1 : 0
                property real sw: win.width
                property real sh: win.height
                property real fw: Math.max(fieldImg.implicitWidth, 1)
                property real fh: Math.max(fieldImg.implicitHeight, 1)
                property real lw: Math.max(lineImg.implicitWidth, 1)
                property real lh: Math.max(lineImg.implicitHeight, 1)
                property real glow: root.glow
                property real lineW: root.lineW
                property real sdRange: 16
                property real seed: root.seed
                property vector4d cropOld: win.crop(oldImg)
                property vector4d cropNew: win.crop(newImg)
                property color ember: root.ember
                property color ink: root.ink
                vertexShader: Qt.resolvedUrl("shaders/wallfx.vert.qsb")
                fragmentShader: Qt.resolvedUrl("shaders/wallfx.frag.qsb")
            }
        }
    }
}
