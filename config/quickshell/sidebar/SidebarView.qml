import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "."

Rectangle {
    id: root

    property bool shown: false
    property bool isBusy: runnerProcess.running
    property string activeEngine: "opencode"
    property var engineCatalog: ({})
    property string activeModel: "opencode/deepseek-v4.1-flash-free"
    property var availableModels: []
    property bool modelSelectorOpen: false
    property var chatHistory: [
        {
            role: "assistant",
            content: "Hyprconf Agent Console [v1.0.2]\nConnected Engine: OpenCode (v2.2.5)\nBinary: ~/.opencode/bin/opencode\n\nAgent CLI ready for instructions. Select a command chip below or enter a prompt.",
            timestamp: "Ready",
            isStreaming: false,
            isError: false
        }
    ]
    property string streamingBuffer: ""
    property bool autoApprove: true

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    // Margins matching Hyprland window tiling gap (general:gaps_out = 8, gap = 10)
    property int topMargin: 10
    property int bottomMargin: 10
    property int leftMargin: 10
    property int rightMargin: 10

    // Geometry matching Hyprland window tile (40% width, full window height)
    x: root.leftMargin
    width: parent ? (parent.width - root.leftMargin - root.rightMargin) : 600
    height: parent ? Math.max(300, parent.height - root.topMargin - root.bottomMargin) : 1000
    radius: 12

    // Obsidian Theme Glassmorphic Surface
    color: Theme.alpha(Theme.surface, 0.95)
    border.width: 1.2
    border.color: root.isBusy ? Theme.accent : Theme.alpha(Theme.accent, 0.30)

    // Appearance Animation: Physical Spring Physics Sliding In From Bottom
    y: root.shown ? root.topMargin : (parent ? (parent.height + 50) : 1100)
    opacity: root.shown ? 1.0 : 0.0
    visible: opacity > 0.001

    Behavior on y {
        SpringAnimation {
            spring: 4.5
            damping: 0.75
            epsilon: 0.25
        }
    }
    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
    }
    Behavior on border.color {
        ColorAnimation { duration: 180 }
    }

    // ── Vector SVGs (100% inline, zero emojis) ──────────────────────────────
    function svgUrl(svgString) {
        return "data:image/svg+xml;utf8," + encodeURIComponent(svgString)
    }

    readonly property string terminalSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.accent + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg>')
    readonly property string enterSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.on_primary + '" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 10 4 15 9 20"/><path d="M20 4v7a4 4 0 0 1-4 4H4"/></svg>')
    readonly property string stopSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.error + '" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><rect x="5" y="5" width="14" height="14" rx="2"/></svg>')
    readonly property string clearSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.alpha(Theme.foreground, 0.6) + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>')
    readonly property string minimizeSvg: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + Theme.alpha(Theme.foreground, 0.7) + '" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg>')

    // ── Agent Detection Process ─────────────────────────────────────────────
    Process {
        id: detectorProc
        command: ["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/ai-assistant.py"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0) {
                    try {
                        var parsed = JSON.parse(text.trim())
                        root.engineCatalog = parsed.engines || {}
                        var targetEng = parsed.active_engine || root.activeEngine
                        var engInfo = root.engineCatalog[targetEng]
                        if (engInfo && engInfo.installed) {
                            root.activeEngine = targetEng
                        } else {
                            for (var k in root.engineCatalog) {
                                if (root.engineCatalog[k] && root.engineCatalog[k].installed) {
                                    root.activeEngine = k
                                    break
                                }
                            }
                        }
                        root.syncModelFromCatalog()
                    } catch(e) {}
                }
            }
        }
    }

    onActiveEngineChanged: {
        root.syncModelFromCatalog()
        Quickshell.execDetached(["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/ai-assistant.py", "--set-engine", root.activeEngine])
    }

    function syncModelFromCatalog() {
        var eng = (root.engineCatalog && root.engineCatalog[root.activeEngine]) ? root.engineCatalog[root.activeEngine] : null
        if (eng) {
            root.availableModels = eng.models || []
            if (eng.active_model) {
                root.activeModel = eng.active_model
            } else if (root.availableModels.length > 0) {
                root.activeModel = root.availableModels[0]
            }

            if (root.chatHistory.length === 1 && root.chatHistory[0].timestamp === "Ready") {
                var arr = root.chatHistory.slice()
                arr[0].content = "Hyprconf Agent Console [v1.0.2]\n" +
                                 "Connected Engine: " + (eng.name || root.activeEngine) + " (" + (eng.version || "") + ")\n" +
                                 "Active Model: " + root.activeModel + "\n\n" +
                                 "Agent CLI ready. Click the MODEL bar above or type /models to switch models."
                root.chatHistory = arr
            }
        }
    }

    function switchModel(modelName) {
        if (!modelName || modelName.trim().length === 0) return false
        var target = modelName.trim()
        var match = ""
        for (var i = 0; i < root.availableModels.length; i++) {
            var m = root.availableModels[i]
            if (m.toLowerCase() === target.toLowerCase()) {
                match = m
                break
            }
        }
        if (!match) {
            for (var j = 0; j < root.availableModels.length; j++) {
                var m2 = root.availableModels[j]
                if (m2.toLowerCase().includes(target.toLowerCase())) {
                    match = m2
                    break
                }
            }
        }

        if (match) {
            root.activeModel = match
            if (root.engineCatalog && root.engineCatalog[root.activeEngine]) {
                root.engineCatalog[root.activeEngine].active_model = match
            }
            Quickshell.execDetached(["python3", root.homeDir + "/.hyprconf/hypr/scripts/py/ai-assistant.py", "--set-model", root.activeEngine, match])

            var now = Qt.formatTime(new Date(), "hh:mm AP")
            var arr = root.chatHistory.slice()
            arr.push({
                role: "assistant",
                content: "✓ Active model switched to: " + match + "\nAll subsequent prompts will use this model.",
                timestamp: now,
                isStreaming: false,
                isError: false
            })
            root.chatHistory = arr
            root.modelSelectorOpen = false
            return true
        }
        return false
    }

    // ── Command / Agent Execution Process ───────────────────────────────────
    Process {
        id: runnerProcess

        stdout: StdioCollector {
            onTextChanged: {
                root.streamingBuffer = text
                if (root.chatHistory.length > 0) {
                    var arr = root.chatHistory.slice()
                    var last = arr[arr.length - 1]
                    if (last && last.role === "assistant" && last.isStreaming) {
                        last.content = text
                        root.chatHistory = arr
                    }
                }
            }
        }

        stderr: StdioCollector {
            onTextChanged: {
                if (text && text.trim().length > 0) {
                    console.log("[Agent Runner stderr]:", text)
                }
            }
        }

        onExited: function(exitCode) {
            var arr = root.chatHistory.slice()
            if (arr.length > 0) {
                var last = arr[arr.length - 1]
                if (last && last.role === "assistant") {
                    last.isStreaming = false
                    last.content = root.streamingBuffer.trim().length > 0
                        ? root.streamingBuffer
                        : (exitCode === 0 ? "Execution completed successfully." : "Process exited with code " + exitCode)
                    last.isError = (exitCode !== 0 && root.streamingBuffer.trim().length === 0)
                    root.chatHistory = arr
                }
            }
            root.streamingBuffer = ""

            // Background completion notification
            if (!root.shown) {
                var osdCmd = root.homeDir + "/.hyprconf/hypr/scripts/sh/osd-notify.sh"
                Quickshell.execDetached([osdCmd, "terminal", "1", "Agent Console", "terminal", "Task finished in background (Super+A to view)"])
            }
        }
    }

    function executeRawCommand(cmdArgs, displayTitle) {
        var now = Qt.formatTime(new Date(), "hh:mm AP")
        var history = root.chatHistory.slice()

        history.push({
            role: "command",
            content: "$ " + displayTitle,
            timestamp: now,
            isStreaming: false,
            isError: false
        })

        history.push({
            role: "assistant",
            content: "",
            timestamp: now,
            isStreaming: true,
            isError: false
        })

        root.chatHistory = history
        root.streamingBuffer = ""

        // Wrap execution with bash -c 'exec "$@" </dev/null' -- to prevent blocking on stdin pipe
        var wrapped = ["bash", "-c", 'exec "$@" </dev/null', "--"].concat(cmdArgs)
        runnerProcess.command = wrapped
        runnerProcess.running = true
    }

    function executePrompt(promptText) {
        if (!promptText || promptText.trim().length === 0) return
        var cleaned = promptText.trim()
        var now = Qt.formatTime(new Date(), "hh:mm AP")

        var engInfo = (root.engineCatalog && root.engineCatalog[root.activeEngine]) ? root.engineCatalog[root.activeEngine] : null
        var binaryPath = engInfo && engInfo.path ? engInfo.path : (root.activeEngine === "opencode" ? (root.homeDir + "/.opencode/bin/opencode") : root.activeEngine)

        // Check if user entered a direct CLI command or subcommand
        if (cleaned === "--help" || cleaned === "-h" || cleaned === "help" || cleaned === "/help") {
            executeRawCommand([binaryPath, "--help"], binaryPath + " --help")
            promptInput.text = ""
            return
        }

        // Check if user entered /models or /model with no args
        if (cleaned === "models" || cleaned === "/models" || cleaned === "model" || cleaned === "/model") {
            var engName = engInfo ? engInfo.name : root.activeEngine
            var listText = "── Active AI Model ──\n"
            listText += "Current: " + root.activeModel + " (" + engName + ")\n\n"
            listText += "── Available Models (" + root.availableModels.length + ") ──\n"
            for (var k = 0; k < root.availableModels.length; k++) {
                var mod = root.availableModels[k]
                var isCur = (mod === root.activeModel)
                listText += (isCur ? " ● " : "   ") + mod + (isCur ? " [ACTIVE]" : "") + "\n"
            }
            listText += "\nTip: To switch model, type: /model <name> (e.g. /model " + (root.availableModels.length > 1 ? root.availableModels[1] : "flint") + ") or select from the MODEL drawer above."

            var histModels = root.chatHistory.slice()
            histModels.push({
                role: "command",
                content: "$ /models",
                timestamp: now,
                isStreaming: false,
                isError: false
            })
            histModels.push({
                role: "assistant",
                content: listText,
                timestamp: now,
                isStreaming: false,
                isError: false
            })
            root.chatHistory = histModels
            promptInput.text = ""
            root.modelSelectorOpen = true
            return
        }

        // Check if user entered /model <name> or /models <name> or /switch <name>
        var modelCmdMatch = cleaned.match(/^(?:\/models?|\/switch|switch|model)\s+(.+)$/i)
        if (modelCmdMatch) {
            var targetQuery = modelCmdMatch[1].trim()
            var histSwitch = root.chatHistory.slice()
            histSwitch.push({
                role: "command",
                content: "$ /model " + targetQuery,
                timestamp: now,
                isStreaming: false,
                isError: false
            })
            root.chatHistory = histSwitch
            promptInput.text = ""

            var success = root.switchModel(targetQuery)
            if (!success) {
                var hErr = root.chatHistory.slice()
                hErr.push({
                    role: "assistant",
                    content: "Model matching '" + targetQuery + "' not found.\nType /models to view all " + root.availableModels.length + " available models.",
                    timestamp: now,
                    isStreaming: false,
                    isError: true
                })
                root.chatHistory = hErr
            }
            return
        }

        if (root.activeEngine === "claude" && (cleaned === "doctor" || cleaned === "/doctor")) {
            executeRawCommand([binaryPath, "doctor"], "claude doctor")
            promptInput.text = ""
            return
        }

        // Standard Prompt Flow
        var history = root.chatHistory.slice()
        history.push({
            role: "user",
            content: cleaned,
            timestamp: now,
            isStreaming: false,
            isError: false
        })

        history.push({
            role: "assistant",
            content: "",
            timestamp: now,
            isStreaming: true,
            isError: false
        })
        root.chatHistory = history
        root.streamingBuffer = ""

        var cmdArgs = []
        if (root.activeEngine === "opencode") {
            cmdArgs = [binaryPath, "run"]
            if (root.autoApprove) cmdArgs.push("--auto")
            if (root.activeModel && root.activeModel.length > 0) cmdArgs.push("-m", root.activeModel)
            cmdArgs.push(cleaned)
        } else if (root.activeEngine === "claude") {
            cmdArgs = [binaryPath]
            if (root.activeModel && root.activeModel.length > 0) cmdArgs.push("--model", root.activeModel)
            cmdArgs.push("-p", cleaned)
        } else if (root.activeEngine === "gemini") {
            cmdArgs = [binaryPath]
            if (root.activeModel && root.activeModel.length > 0) cmdArgs.push("--model", root.activeModel)
            cmdArgs.push(cleaned)
        } else {
            cmdArgs = ["sh", "-c", cleaned]
        }

        // Wrap execution with bash -c 'exec "$@" </dev/null' -- to prevent blocking on stdin pipe
        var wrapped = ["bash", "-c", 'exec "$@" </dev/null', "--"].concat(cmdArgs)
        runnerProcess.command = wrapped
        runnerProcess.running = true
        promptInput.text = ""
    }

    function handleChipSelection(cmdItem) {
        if (!cmdItem) return
        var engInfo = (root.engineCatalog && root.engineCatalog[root.activeEngine]) ? root.engineCatalog[root.activeEngine] : null
        var binaryPath = engInfo && engInfo.path ? engInfo.path : (root.activeEngine === "opencode" ? (root.homeDir + "/.opencode/bin/opencode") : root.activeEngine)

        if (cmdItem.cmd === "/models" || cmdItem.action === "/models" || cmdItem.action === "models") {
            executePrompt("/models")
            return
        }

        if (cmdItem.is_subcmd) {
            executeRawCommand([binaryPath, cmdItem.action], (engInfo ? engInfo.name : root.activeEngine) + " " + cmdItem.action)
        } else {
            executePrompt(cmdItem.action)
        }
    }

    function abortExecution() {
        if (runnerProcess.running) {
            runnerProcess.running = false
            var arr = root.chatHistory.slice()
            if (arr.length > 0) {
                var last = arr[arr.length - 1]
                if (last && last.role === "assistant") {
                    last.isStreaming = false
                    last.content += "\n\n[Terminated by user]"
                    root.chatHistory = arr
                }
            }
        }
    }

    function setInputText(str) {
        promptInput.text = str
        promptInput.cursorPosition = str.length
    }

    function toggleShown() {
        if (!root.shown) {
            root.shown = true
            promptInput.forceActiveFocus()
        } else {
            // Disappear window while preserving running process in background
            root.shown = false
            if (root.isBusy) {
                var osdCmd = root.homeDir + "/.hyprconf/hypr/scripts/sh/osd-notify.sh"
                Quickshell.execDetached([osdCmd, "terminal", "1", "Agent Console", "terminal", "Process continuing in background • Super+A to view"])
            }
        }
    }

    // ── MAIN LAYOUT CONTAINER ───────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // ── TOP HEADER: CONSOLE IDENTITY & CONTROLS ─────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Console Monospace Badge
            Rectangle {
                width: 32; height: 32; radius: 8
                color: Theme.alpha(Theme.accent, 0.18)
                border.width: 1; border.color: Theme.accent
                Image {
                    anchors.centerIn: parent
                    width: 16; height: 16
                    source: root.terminalSvg
                }
            }

            Column {
                spacing: 1
                Text {
                    text: "Agent Console"
                    font.family: "JetBrainsMono Nerd Font, monospace"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: Theme.foreground
                }
                Text {
                    text: "OpenCode · Claude · Gemini"
                    font.family: "Outfit, sans-serif"
                    font.pixelSize: 10
                    color: Theme.alpha(Theme.foreground, 0.55)
                }
            }

            Item { Layout.fillWidth: true }

            // Status Badge (Running vs Ready)
            Rectangle {
                height: 24
                implicitWidth: statusRow.implicitWidth + 14
                radius: 12
                color: root.isBusy ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.60)
                border.width: 1
                border.color: root.isBusy ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)

                RowLayout {
                    id: statusRow
                    anchors.centerIn: parent
                    spacing: 6

                    Rectangle {
                        width: 6; height: 6; radius: 3
                        color: root.isBusy ? Theme.accent : "#10b981"
                        SequentialAnimation on opacity {
                            running: root.isBusy
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.2; to: 1.0; duration: 400 }
                            NumberAnimation { from: 1.0; to: 0.2; duration: 400 }
                        }
                    }

                    Text {
                        text: root.isBusy ? "RUNNING" : "READY"
                        font.family: "JetBrainsMono Nerd Font, monospace"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: root.isBusy ? Theme.accent : Theme.alpha(Theme.foreground, 0.70)
                    }
                }
            }

            // Clear Output Button
            Rectangle {
                width: 28; height: 28; radius: 6
                color: clearMouse.containsMouse ? Theme.alpha(Theme.surface, 0.9) : "transparent"
                border.width: 1; border.color: clearMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.2) : "transparent"
                Image {
                    anchors.centerIn: parent
                    width: 14; height: 14
                    source: root.clearSvg
                }
                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.chatHistory = []
                }
            }

            // Minimize / Background Chevron
            Rectangle {
                width: 28; height: 28; radius: 6
                color: minMouse.containsMouse ? Theme.alpha(Theme.surface, 0.9) : "transparent"
                border.width: 1; border.color: minMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.2) : "transparent"
                Image {
                    anchors.centerIn: parent
                    width: 14; height: 14
                    source: root.minimizeSvg
                }
                MouseArea {
                    id: minMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleShown()
                }
            }
        }

        // ── ENGINE SELECTOR TABS ────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: 8
            color: Theme.alpha(Theme.surface, 0.60)
            border.width: 1
            border.color: Theme.alpha(Theme.foreground, 0.12)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 4

                Repeater {
                    model: [
                        { id: "opencode", name: "OpenCode" },
                        { id: "claude", name: "Claude Code" },
                        { id: "gemini", name: "Gemini CLI" }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 6

                        readonly property bool isSelected: root.activeEngine === modelData.id
                        readonly property var info: root.engineCatalog ? root.engineCatalog[modelData.id] : null
                        readonly property bool isInstalled: Boolean(info && info.installed)

                        // Dim uninstalled or unavailable providers
                        opacity: isInstalled ? 1.0 : 0.35
                        Behavior on opacity { NumberAnimation { duration: 180 } }

                        color: isSelected
                            ? Theme.alpha(Theme.accent, 0.22)
                            : (tabMouse.containsMouse && isInstalled ? Theme.alpha(Theme.surface, 0.8) : "transparent")
                        border.width: isSelected ? 1 : 0
                        border.color: Theme.accent

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            // Status Dot (Green = Installed, Muted = Missing / Disabled)
                            Rectangle {
                                width: 5; height: 5; radius: 2.5
                                color: isInstalled ? "#10b981" : Theme.alpha(Theme.foreground, 0.25)
                            }

                            Text {
                                text: modelData.name
                                font.family: "JetBrainsMono Nerd Font, monospace"
                                font.pixelSize: 11
                                font.weight: isSelected ? Font.Bold : Font.Medium
                                color: isSelected
                                    ? Theme.accent
                                    : (isInstalled ? Theme.foreground : Theme.alpha(Theme.foreground, 0.45))
                            }
                        }

                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: isInstalled
                            enabled: isInstalled
                            cursorShape: isInstalled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (isInstalled) {
                                    root.activeEngine = modelData.id
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── ACTIVE MODEL RIBBON ─────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            radius: 6
            color: modelRibbonMouse.containsMouse ? Theme.alpha(Theme.surface, 0.75) : Theme.alpha(Theme.surface, 0.45)
            border.width: 1
            border.color: root.modelSelectorOpen ? Theme.accent : Theme.alpha(Theme.accent, 0.25)
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: "MODEL"
                    font.family: "JetBrainsMono Nerd Font, monospace"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: Theme.alpha(Theme.foreground, 0.50)
                }

                Rectangle {
                    width: 3; height: 3; radius: 1.5
                    color: Theme.accent
                }

                Text {
                    Layout.fillWidth: true
                    text: root.activeModel || "Select Model"
                    font.family: "JetBrainsMono Nerd Font, monospace"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Theme.accent
                    elide: Text.ElideRight
                }

                Rectangle {
                    height: 16
                    implicitWidth: modelCountText.implicitWidth + 8
                    radius: 4
                    color: Theme.alpha(Theme.surface, 0.7)
                    border.width: 1
                    border.color: Theme.alpha(Theme.foreground, 0.12)
                    Text {
                        id: modelCountText
                        anchors.centerIn: parent
                        text: (root.availableModels ? root.availableModels.length : 0) + " models"
                        font.family: "JetBrainsMono Nerd Font, monospace"
                        font.pixelSize: 8
                        color: Theme.alpha(Theme.foreground, 0.60)
                    }
                }

                Text {
                    text: root.modelSelectorOpen ? "▲" : "▼"
                    font.family: "JetBrainsMono Nerd Font, monospace"
                    font.pixelSize: 9
                    color: root.modelSelectorOpen ? Theme.accent : Theme.alpha(Theme.foreground, 0.60)
                }
            }

            MouseArea {
                id: modelRibbonMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.modelSelectorOpen = !root.modelSelectorOpen
                    if (root.modelSelectorOpen) {
                        modelSearchInput.forceActiveFocus()
                    }
                }
            }
        }

        // ── EXPANDABLE MODEL SELECTOR DRAWER ─────────────────────────────────
        Rectangle {
            id: modelDrawer
            Layout.fillWidth: true
            visible: root.modelSelectorOpen
            Layout.preferredHeight: root.modelSelectorOpen ? 210 : 0
            radius: 8
            color: Theme.alpha(Theme.background, 0.95)
            border.width: 1
            border.color: Theme.alpha(Theme.accent, 0.40)
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                // Search / Filter Input
                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 6
                    color: Theme.alpha(Theme.surface, 0.70)
                    border.width: 1
                    border.color: modelSearchInput.activeFocus ? Theme.accent : Theme.alpha(Theme.foreground, 0.15)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        Text {
                            text: "/"
                            font.family: "JetBrainsMono Nerd Font, monospace"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: Theme.accent
                        }

                        TextInput {
                            id: modelSearchInput
                            Layout.fillWidth: true
                            font.family: "JetBrainsMono Nerd Font, monospace"
                            font.pixelSize: 11
                            color: Theme.foreground
                            selectByMouse: true
                            selectedTextColor: Theme.on_primary
                            selectionColor: Theme.accent

                            Text {
                                anchors.fill: parent
                                visible: !modelSearchInput.text && !modelSearchInput.activeFocus
                                text: "Filter models (e.g. flint, deepseek, flash)..."
                                font.family: "JetBrainsMono Nerd Font, monospace"
                                font.pixelSize: 11
                                color: Theme.alpha(Theme.foreground, 0.40)
                            }

                            Keys.onEscapePressed: {
                                root.modelSelectorOpen = false
                            }
                        }

                        // Clear filter button
                        Text {
                            visible: modelSearchInput.text.length > 0
                            text: "✕"
                            font.pixelSize: 10
                            color: Theme.alpha(Theme.foreground, 0.5)
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelSearchInput.text = ""
                            }
                        }
                    }
                }

                // Filtered Models List
                ListView {
                    id: modelListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 3
                    boundsBehavior: Flickable.StopAtBounds

                    readonly property var filteredList: {
                        var q = modelSearchInput.text.toLowerCase().trim()
                        var all = root.availableModels || []
                        if (!q) return all
                        return all.filter(m => m.toLowerCase().includes(q))
                    }

                    model: filteredList

                    delegate: Rectangle {
                        required property string modelData
                        width: ListView.view.width
                        height: 28
                        radius: 5
                        readonly property bool isCurrent: root.activeModel === modelData
                        color: isCurrent
                            ? Theme.alpha(Theme.accent, 0.28)
                            : (itemMouse.containsMouse ? Theme.alpha(Theme.surface, 0.80) : "transparent")
                        border.width: isCurrent ? 1 : 0
                        border.color: Theme.accent

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Rectangle {
                                width: 5; height: 5; radius: 2.5
                                color: isCurrent ? Theme.accent : Theme.alpha(Theme.foreground, 0.25)
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData
                                font.family: "JetBrainsMono Nerd Font, monospace"
                                font.pixelSize: 10
                                font.weight: isCurrent ? Font.Bold : Font.Normal
                                color: isCurrent ? Theme.accent : (itemMouse.containsMouse ? Theme.foreground : Theme.alpha(Theme.foreground, 0.85))
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                visible: isCurrent
                                height: 16
                                implicitWidth: activeBadgeText.implicitWidth + 8
                                radius: 3
                                color: Theme.accent
                                Text {
                                    id: activeBadgeText
                                    anchors.centerIn: parent
                                    text: "ACTIVE"
                                    font.family: "JetBrainsMono Nerd Font, monospace"
                                    font.pixelSize: 8
                                    font.weight: Font.Bold
                                    color: Theme.on_primary
                                }
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.switchModel(modelData)
                            }
                        }
                    }
                }
            }
        }

        // ── QUICK COMMAND CHIPS RIBBON ──────────────────────────────────────
        AiCommandPalette {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            commands: {
                var info = (root.engineCatalog && root.engineCatalog[root.activeEngine]) ? root.engineCatalog[root.activeEngine] : null
                return (info && info.commands) ? info.commands : []
            }
            onCommandSelected: function(cmdItem) {
                root.handleChipSelection(cmdItem)
            }
        }

        // ── OUTPUT TERMINAL / STREAMING VIEW ────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 8
            color: Theme.alpha(Theme.background, 0.65)
            border.width: 1
            border.color: Theme.alpha(Theme.accent, 0.15)
            clip: true

            ScrollView {
                id: chatScroll
                anchors.fill: parent
                anchors.margins: 8

                ScrollBar.vertical: ScrollBar {
                    id: chatVBar
                    parent: chatScroll
                    anchors.top: chatScroll.top
                    anchors.right: chatScroll.right
                    anchors.bottom: chatScroll.bottom
                    width: 5
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 5
                        radius: 2.5
                        color: chatVBar.pressed ? Theme.accent : Theme.alpha(Theme.foreground, 0.20)
                    }
                }

                ListView {
                    id: chatListView
                    width: chatScroll.width - 12
                    spacing: 8
                    model: root.chatHistory

                    delegate: AiChatMessage {
                        width: chatListView.width
                        role: modelData.role || "assistant"
                        content: modelData.content || ""
                        engineName: {
                            var info = (root.engineCatalog && root.engineCatalog[root.activeEngine]) ? root.engineCatalog[root.activeEngine] : null
                            return info ? info.name : root.activeEngine
                        }
                        timestamp: modelData.timestamp || ""
                        isStreaming: !!modelData.isStreaming
                        isError: !!modelData.isError
                    }

                    onCountChanged: {
                        Qt.callLater(function() {
                            chatListView.positionViewAtEnd()
                        })
                    }
                }
            }
        }

        // ── BOTTOM COMMAND INPUT BAR ────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            radius: 10
            color: Theme.alpha(Theme.background, 0.90)
            border.width: promptInput.activeFocus ? 1.5 : 1
            border.color: promptInput.activeFocus ? Theme.accent : Theme.alpha(Theme.accent, 0.28)
            Behavior on border.color { ColorAnimation { duration: 150 } }

            // Inner subtle top glow
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: promptInput.activeFocus ? Theme.alpha(Theme.accent, 0.35) : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                anchors.topMargin: 4
                anchors.bottomMargin: 4
                spacing: 8

                // Monospace Terminal Prompt Symbol
                Text {
                    text: ">_"
                    font.family: "JetBrainsMono Nerd Font, monospace"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: Theme.accent
                }

                // Interactive Text Input Container (with strict clipping to prevent overflow)
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    TextInput {
                        id: promptInput
                        anchors.fill: parent
                        clip: true
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: "JetBrainsMono Nerd Font, monospace"
                        font.pixelSize: 12
                        color: Theme.foreground
                        selectByMouse: true
                        selectedTextColor: Theme.on_primary
                        selectionColor: Theme.accent

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            visible: !promptInput.text && !promptInput.activeFocus
                            text: "Enter command or prompt (e.g. /review, /models, /help)..."
                            font.family: "JetBrainsMono Nerd Font, monospace"
                            font.pixelSize: 12
                            color: Theme.alpha(Theme.foreground, 0.38)
                        }

                        Keys.onReturnPressed: function(event) {
                            if (root.isBusy) return
                            root.executePrompt(promptInput.text)
                        }

                        Keys.onEscapePressed: function(event) {
                            root.toggleShown()
                        }
                    }
                }

                // Auto-Approve Toggle Pill (for opencode --auto flag)
                Rectangle {
                    visible: root.activeEngine === "opencode"
                    height: 24
                    implicitWidth: autoText.implicitWidth + 14
                    radius: 5
                    color: root.autoApprove ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.70)
                    border.width: 1
                    border.color: root.autoApprove ? Theme.accent : Theme.alpha(Theme.foreground, 0.20)

                    Text {
                        id: autoText
                        anchors.centerIn: parent
                        text: root.autoApprove ? "AUTO" : "MANUAL"
                        font.family: "JetBrainsMono Nerd Font, monospace"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: root.autoApprove ? Theme.accent : Theme.alpha(Theme.foreground, 0.50)
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.autoApprove = !root.autoApprove
                    }
                }

                // Stop / Abort Button (when busy)
                Rectangle {
                    visible: root.isBusy
                    width: 32; height: 32; radius: 6
                    color: stopMouse.containsMouse ? Theme.alpha(Theme.error, 0.28) : Theme.alpha(Theme.error, 0.14)
                    border.width: 1; border.color: Theme.error

                    Image {
                        anchors.centerIn: parent
                        width: 14; height: 14
                        source: root.stopSvg
                    }

                    MouseArea {
                        id: stopMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.abortExecution()
                    }
                }

                // Execute / Run Button (when idle)
                Rectangle {
                    visible: !root.isBusy
                    width: 32; height: 32; radius: 6
                    color: sendMouse.containsMouse ? Theme.primary : Theme.accent

                    Image {
                        anchors.centerIn: parent
                        width: 14; height: 14
                        source: root.enterSvg
                    }

                    MouseArea {
                        id: sendMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.executePrompt(promptInput.text)
                    }
                }
            }
        }
    }
}
