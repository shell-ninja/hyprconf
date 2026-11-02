import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import "."

// Spotlight: Raycast-style Omnibar (Apps, Calculator, Currency Converter, Emojis, AI Prompt & System Actions)
Rectangle {
    id: card

    required property var rootWindow

    readonly property bool isIsland: Boolean(rootWindow && rootWindow.isIslandView)

    width: isIsland ? parent.width : 680
    height: isIsland ? parent.height : Math.min(560, mainLayout.implicitHeight + 24)
    anchors.fill: isIsland ? parent : undefined
    anchors.centerIn: isIsland ? undefined : parent
    radius: isIsland ? 0 : 16
    color: isIsland ? "transparent" : Theme.alpha(Theme.surface, 0.96)
    border.width: isIsland ? 0 : 1.2
    border.color: Theme.alpha(Theme.accent, 0.35)
    clip: true

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    // Top Inner Glass Rim Highlight (only for standalone mode)
    Rectangle {
        visible: !card.isIsland
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        height: 1
        color: Theme.alpha(Theme.foreground, 0.15)
    }

    focus: true

    function focusInput() {
        searchInput.forceActiveFocus()
        searchInput.selectAll()
    }

    Timer {
        interval: 50
        running: true
        repeat: false
        onTriggered: focusInput()
    }

    Component.onCompleted: focusInput()

    Connections {
        target: rootWindow
        function onSearchQueryChanged() {
            if (rootWindow && searchInput && searchInput.text !== rootWindow.searchQuery) {
                searchInput.text = rootWindow.searchQuery
            }
        }
    }

    function triggerClose() {
        if (rootWindow) {
            if (typeof rootWindow.closeRequested === "function") rootWindow.closeRequested()
            else if (typeof rootWindow.requestClose === "function") rootWindow.requestClose()
            else Qt.quit()
        }
    }

    readonly property string queryText: (searchInput && searchInput.text) ? searchInput.text : (rootWindow ? rootWindow.searchQuery : "")

    // ── 1. CALCULATION ENGINE ───────────────────────────────────────────────
    readonly property var mathResult: {
        var q = card.queryText.trim()
        if (q.length < 2) return null
        if (/^[\d\s+\-*/%().^]+$/.test(q) && /[\d]/.test(q) && /[+\-*/%^]/.test(q)) {
            try {
                var safeExpr = q.replace(/\^/g, "**")
                var res = Function('"use strict"; return (' + safeExpr + ')')()
                if (typeof res === "number" && !isNaN(res) && isFinite(res)) {
                    return res
                }
            } catch(e) {}
        }
        return null
    }

    // ── 2. DAILY CURRENCY CONVERTER ─────────────────────────────────────────
    property var currencyRates: ({
        "USD": 1.0, "EUR": 0.8961, "GBP": 0.7725, "JPY": 152.3, "CAD": 1.391,
        "AUD": 1.518, "CHF": 0.867, "CNY": 7.125, "INR": 84.08, "BDT": 119.5,
        "BRL": 5.86, "RUB": 97.2, "KRW": 1378.0, "MXN": 20.25, "SGD": 1.321,
        "NZD": 1.674, "HKD": 7.773, "TRY": 34.35, "ZAR": 17.65, "AED": 3.672,
        "SAR": 3.753, "SEK": 10.68, "NOK": 10.98, "DKK": 6.89, "PLN": 4.02, "THB": 33.78
    })

    Process {
        id: currencyLoader
        command: ["python3", "-c", "import json, os; p=os.path.expanduser('~/.local/share/hyprconf/.cache/currency_rates.json'); print(open(p, encoding='utf-8').read() if os.path.exists(p) else '{}')"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var parsed = JSON.parse(text.trim())
                    if (parsed && parsed.rates) {
                        card.currencyRates = parsed.rates
                    }
                } catch(e) {}
            }
        }
    }

    readonly property var currencyResult: {
        var q = card.queryText.trim()
        if (q.length < 3 || !card.currencyRates) return null

        var regex = /^([$€£¥₹৳₽₩₺฿]|R\$)?\s*([0-9]+(?:\.[0-9]+)?)\s*([A-Za-z]{3})?\s*(?:to|in|=|->|\s)\s*([A-Za-z]{3})$/i
        var match = q.match(regex)
        if (!match) return null

        var sym = match[1] || ""
        var amtStr = match[2]
        var srcCode = match[3] || ""
        var targetCode = match[4] ? match[4].toUpperCase() : ""

        if (!srcCode && sym) {
            var symMap = { "$": "USD", "€": "EUR", "£": "GBP", "¥": "JPY", "₹": "INR", "৳": "BDT", "₽": "RUB", "₩": "KRW", "₺": "TRY", "฿": "THB", "R$": "BRL" }
            srcCode = symMap[sym] || "USD"
        } else if (srcCode) {
            srcCode = srcCode.toUpperCase()
        } else {
            return null
        }

        if (!srcCode || !targetCode || srcCode === targetCode) return null
        var rFrom = card.currencyRates[srcCode]
        var rTo = card.currencyRates[targetCode]
        if (!rFrom || !rTo) return null

        var amount = parseFloat(amtStr)
        if (isNaN(amount) || amount <= 0) return null

        var amountUsd = amount / rFrom
        var targetVal = amountUsd * rTo
        var unitRate = rTo / rFrom

        return {
            amount: amount,
            from: srcCode,
            to: targetCode,
            result: targetVal.toFixed(2),
            rate: unitRate.toFixed(4),
            formatted: amount.toLocaleString("en-US", {minimumFractionDigits: 2, maximumFractionDigits: 2}) + " " + srcCode + " = " + targetVal.toLocaleString("en-US", {minimumFractionDigits: 2, maximumFractionDigits: 2}) + " " + targetCode,
            rateStr: "1 " + srcCode + " = " + unitRate.toFixed(4) + " " + targetCode + " (Daily Exchange Rate)",
            copyVal: targetVal.toFixed(2) + " " + targetCode
        }
    }

    // ── 3. EMOJIS SEARCH ENGINE ─────────────────────────────────────────────
    property var allEmojis: []

    Process {
        id: emojiLoader
        command: ["python3", "-c", "import json, os; p=os.path.expanduser('~/.hyprconf/quickshell/island/emojis.json'); print(open(p, encoding='utf-8').read() if os.path.exists(p) else '[]')"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                if (!text || text.trim().length === 0) return
                try {
                    var parsed = JSON.parse(text.trim())
                    if (Array.isArray(parsed)) card.allEmojis = parsed
                } catch(e) {}
            }
        }
    }

    readonly property var matchedEmojis: {
        var q = card.queryText.toLowerCase().trim()
        if (q.length < 2 || !card.allEmojis || card.allEmojis.length === 0) return []
        if (card.isAiQuery || card.mathResult !== null || card.currencyResult !== null) return []

        var isExplicit = q.startsWith(":") || q.startsWith("emoji ")
        var cleanQ = q
        if (cleanQ.startsWith(":") && cleanQ.length >= 2) {
            cleanQ = cleanQ.slice(1).replace(/:$/, "")
        } else if (cleanQ.startsWith("emoji ")) {
            cleanQ = cleanQ.slice(6).trim()
        }

        var matches = []
        for (var i = 0; i < card.allEmojis.length; i++) {
            var em = card.allEmojis[i]
            var name = (em.name || "").toLowerCase()
            var keywords = em.keywords || []
            var score = 0
            if (name === cleanQ) {
                score = 100
            } else if (name.startsWith(cleanQ)) {
                score = 50
            } else if (isExplicit && name.indexOf(cleanQ) !== -1) {
                score = 30
            } else if (isExplicit) {
                for (var k = 0; k < keywords.length; k++) {
                    var kw = keywords[k].toLowerCase()
                    if (kw === cleanQ) {
                        score = 40
                        break
                    } else if (kw.indexOf(cleanQ) !== -1) {
                        score = 20
                        break
                    }
                }
            }
            if (score > 0) {
                matches.push({ item: em, score: score })
            }
        }
        matches.sort(function(a, b) { return b.score - a.score })
        var res = []
        for (var m = 0; m < Math.min(8, matches.length); m++) {
            res.push(matches[m].item)
        }
        return res
    }

    function copyEmoji(glyph, name) {
        Quickshell.execDetached(["wl-copy", glyph])
        var osdCmd = card.homeDir + "/.hyprconf/hypr/scripts/sh/osd-notify.sh"
        Quickshell.execDetached([osdCmd, "smile", "1", "Emoji Copied", "smile", glyph + " (" + name + ") copied to clipboard!"])
        card.triggerClose()
    }

    // ── 4. AI PROMPT DETECTION ──────────────────────────────────────────────
    readonly property bool isAiQuery: {
        var q = card.queryText.trim()
        return q.startsWith(">") || q.toLowerCase().startsWith("ai ")
    }

    readonly property string aiPromptText: {
        var q = card.queryText.trim()
        if (q.startsWith(">")) return q.slice(1).trim()
        if (q.toLowerCase().startsWith("ai ")) return q.slice(3).trim()
        return ""
    }

    // ── 5. SYSTEM COMMANDS CATALOG ──────────────────────────────────────────
    readonly property var systemActions: [
        { id: "gamemode", name: "Game Mode", desc: "Toggle Gaming Mode (0ms Latency & Max Perf)", cmd: "gamemode.sh --toggle", icon: "zap" },
        { id: "lock", name: "Lock Screen", desc: "Launch PAM Lockscreen", cmd: "qs-lock.sh", icon: "lock" },
        { id: "sleep", name: "Sleep / Suspend", desc: "Suspend system to RAM", cmd: "systemctl suspend", icon: "moon" },
        { id: "caffeine", name: "Toggle Caffeine", desc: "Inhibit display sleep & idle", cmd: "caffeine-manager.sh", icon: "coffee" },
        { id: "nightlight", name: "Toggle Night Light", desc: "Blue light filter (hyprsunset)", cmd: "hyprsunset-manager.sh", icon: "moonStar" },
        { id: "settings", name: "Settings Studio", desc: "Unified Quickshell Settings", cmd: "qs-settings.sh", icon: "settings" },
        { id: "updater", name: "Package Updater", desc: "Check and apply system upgrades", cmd: "qs-updater.sh", icon: "download" },
        { id: "reload", name: "Reload Quickshell", desc: "Restart desktop shell processes", cmd: "qs-reload.sh", icon: "refresh" },
        { id: "screenshot", name: "Screenshot Studio", desc: "Interactive screen capture", cmd: "qs-screenshot.sh", icon: "camera" },
        { id: "agent", name: "Agent Console", desc: "Open CLI AI Assistant drawer", cmd: "qs-sidebar.sh --toggle", icon: "terminal" }
    ]

    readonly property var matchedActions: {
        var q = card.queryText.toLowerCase().trim()
        if (q.length === 0 || card.isAiQuery || card.mathResult !== null || card.currencyResult !== null) return []
        var res = []
        for (var i = 0; i < systemActions.length; i++) {
            var act = systemActions[i]
            if (act.name.toLowerCase().indexOf(q) !== -1 || act.id.indexOf(q) !== -1 || act.desc.toLowerCase().indexOf(q) !== -1) {
                res.push(act)
            }
        }
        return res
    }

    // ── KEYBOARD INTERCEPT ──────────────────────────────────────────────────
    Keys.priority: Keys.BeforeItem
    Keys.onEscapePressed: function(event) {
        event.accepted = true
        card.triggerClose()
    }

    Keys.onDownPressed: function(event) {
        event.accepted = true
        if (rootWindow) {
            var total = (rootWindow.filteredApps ? rootWindow.filteredApps.length : 0) + matchedActions.length
            if (total > 0) {
                rootWindow.selectedIndex = Math.min(total - 1, rootWindow.selectedIndex + 1)
            }
        }
    }

    Keys.onUpPressed: function(event) {
        event.accepted = true
        if (rootWindow) {
            rootWindow.selectedIndex = Math.max(0, rootWindow.selectedIndex - 1)
        }
    }

    Keys.onReturnPressed: function(event) {
        event.accepted = true
        card.executeCurrent()
    }

    function executeCurrent() {
        // 1. Currency conversion result
        if (card.currencyResult !== null) {
            var currVal = card.currencyResult.copyVal
            Quickshell.execDetached(["wl-copy", currVal])
            var osdCmd1 = card.homeDir + "/.hyprconf/hypr/scripts/sh/osd-notify.sh"
            Quickshell.execDetached([osdCmd1, "currency", "1", "Currency Converted", "currency", card.currencyResult.formatted + " copied!"])
            card.triggerClose()
            return
        }

        // 2. Math calculation result
        if (card.mathResult !== null) {
            var strVal = card.mathResult.toString()
            Quickshell.execDetached(["wl-copy", strVal])
            var osdCmd2 = card.homeDir + "/.hyprconf/hypr/scripts/sh/osd-notify.sh"
            Quickshell.execDetached([osdCmd2, "calculator", "1", "Calculator Result", "calculator", strVal + " copied to clipboard!"])
            card.triggerClose()
            return
        }

        // 3. AI Prompt
        if (card.isAiQuery && card.aiPromptText.length > 0) {
            var sideCmd = card.homeDir + "/.hyprconf/hypr/scripts/sh/qs-sidebar.sh"
            Quickshell.execDetached([sideCmd, "--open"])
            Quickshell.execDetached(["qs", "ipc", "-c", "sidebar", "call", "sidebar", "runTestCommand", card.aiPromptText])
            card.triggerClose()
            return
        }

        // 4. Emoji search (if starts with : or emoji )
        if (card.matchedEmojis.length > 0) {
            var q = card.queryText.trim()
            if (q.startsWith(":") || q.startsWith("emoji ")) {
                card.copyEmoji(card.matchedEmojis[0].emoji, card.matchedEmojis[0].name)
                return
            }
        }

        // 5. System Action
        if (matchedActions.length > 0 && rootWindow.selectedIndex < matchedActions.length) {
            var act = matchedActions[rootWindow.selectedIndex]
            var shDir = card.homeDir + "/.hyprconf/hypr/scripts/sh"
            Quickshell.execDetached(["bash", "-c", shDir + "/" + act.cmd + " 2>/dev/null || " + act.cmd])
            card.triggerClose()
            return
        }

        // 6. Application
        var appIdx = rootWindow.selectedIndex - matchedActions.length
        if (rootWindow && rootWindow.filteredApps && appIdx >= 0 && appIdx < rootWindow.filteredApps.length) {
            rootWindow.launchApp(rootWindow.filteredApps[appIdx])
        }
    }

    // ── MAIN CONTENT LAYOUT ─────────────────────────────────────────────────
    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: card.isIsland ? 12 : 14
        spacing: 12

        // ── TOP SEARCH INPUT ROW ────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 48
            radius: 10
            color: Theme.alpha(Theme.background, 0.85)
            border.width: 1
            border.color: searchInput.activeFocus ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)
            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                // Prompt glyph
                Text {
                    text: {
                        if (card.currencyResult !== null) return "󰚥"
                        if (card.isAiQuery) return ">_"
                        if (card.mathResult !== null) return "="
                        if (card.matchedEmojis.length > 0 && (searchInput.text.startsWith(":") || searchInput.text.startsWith("emoji "))) return "󰞅"
                        return "󰍉"
                    }
                    font.family: "JetBrainsMono Nerd Font, monospace"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    color: Theme.accent
                }

                // Interactive Text Input
                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: "JetBrainsMono Nerd Font, monospace"
                    font.pixelSize: 14
                    color: Theme.foreground
                    selectByMouse: true
                    selectedTextColor: Theme.on_primary
                    selectionColor: Theme.accent
                    text: rootWindow ? rootWindow.searchQuery : ""
                    onTextChanged: {
                        if (rootWindow) {
                            rootWindow.searchQuery = text
                            rootWindow.updateFilteredApps()
                        }
                    }

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        visible: !searchInput.text && !searchInput.activeFocus
                        text: "Search apps, calculate, 100 USD to EUR, :emoji, or >ask AI..."
                        font.family: "Outfit, sans-serif"
                        font.pixelSize: 13
                        color: Theme.alpha(Theme.foreground, 0.38)
                    }
                }

                // Mode Indicator Badge
                Rectangle {
                    height: 22
                    implicitWidth: modeText.implicitWidth + 12
                    radius: 5
                    color: {
                        if (card.currencyResult !== null) return Theme.alpha(Theme.accent, 0.25)
                        if (card.mathResult !== null) return Theme.alpha(Theme.accent, 0.22)
                        if (card.isAiQuery) return Theme.alpha(Theme.accent, 0.30)
                        if (matchedActions.length > 0) return Theme.alpha(Theme.secondary, 0.20)
                        return Theme.alpha(Theme.surface, 0.80)
                    }
                    border.width: 1
                    border.color: Theme.alpha(Theme.foreground, 0.15)

                    Text {
                        id: modeText
                        anchors.centerIn: parent
                        text: {
                            if (card.currencyResult !== null) return "CURRENCY"
                            if (card.mathResult !== null) return "CALC"
                            if (card.isAiQuery) return "AI AGENT"
                            if (matchedActions.length > 0) return "ACTION"
                            return "OMNIBAR"
                        }
                        font.family: "JetBrainsMono Nerd Font, monospace"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: (card.currencyResult !== null || card.mathResult !== null || card.isAiQuery) ? Theme.accent : Theme.alpha(Theme.foreground, 0.65)
                    }
                }

                // Esc Badge
                Rectangle {
                    width: 32; height: 20; radius: 4
                    color: Theme.alpha(Theme.foreground, 0.08)
                    border.width: 1; border.color: Theme.alpha(Theme.foreground, 0.15)
                    Text {
                        anchors.centerIn: parent
                        text: "ESC"
                        font.family: "JetBrainsMono Nerd Font, monospace"
                        font.pixelSize: 9; font.bold: true
                        color: Theme.alpha(Theme.foreground, 0.50)
                    }
                }
            }
        }

        // ── INLINE RESULT CARDS ─────────────────────────────────────────────

        // 1. Currency Conversion Result Card
        Rectangle {
            visible: card.currencyResult !== null
            Layout.fillWidth: true
            height: 58
            radius: 8
            color: Theme.alpha(Theme.accent, 0.15)
            border.width: 1
            border.color: Theme.accent

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Text {
                    text: "󰚥"
                    font.family: "JetBrainsMono Nerd Font, monospace"
                    font.pixelSize: 18
                    color: Theme.accent
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: card.currencyResult ? card.currencyResult.formatted : ""
                        font.family: "Outfit"; font.pixelSize: 15; font.weight: Font.Bold
                        color: Theme.foreground
                    }
                    Text {
                        text: card.currencyResult ? card.currencyResult.rateStr : ""
                        font.family: "Outfit"; font.pixelSize: 10
                        color: Theme.alpha(Theme.foreground, 0.60)
                    }
                }

                Rectangle {
                    height: 24; implicitWidth: currEnterText.implicitWidth + 12; radius: 5
                    color: Theme.accent
                    Text {
                        id: currEnterText
                        anchors.centerIn: parent
                        text: "↵ Copy Result"
                        font.family: "Outfit"; font.pixelSize: 10; font.bold: true; color: Theme.on_primary
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: card.executeCurrent()
            }
        }

        // 2. Math Calculation Result Card
        Rectangle {
            visible: card.mathResult !== null && card.currencyResult === null
            Layout.fillWidth: true
            height: 54
            radius: 8
            color: Theme.alpha(Theme.accent, 0.15)
            border.width: 1
            border.color: Theme.accent

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Text {
                    text: card.queryText.trim() + "  ="
                    font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 13
                    color: Theme.alpha(Theme.foreground, 0.70)
                }

                Text {
                    text: card.mathResult !== null ? card.mathResult.toString() : ""
                    font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 16; font.weight: Font.Bold
                    color: Theme.accent
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    height: 24; implicitWidth: calcEnterText.implicitWidth + 12; radius: 5
                    color: Theme.accent
                    Text {
                        id: calcEnterText
                        anchors.centerIn: parent
                        text: "↵ Copy Result"
                        font.family: "Outfit"; font.pixelSize: 10; font.bold: true; color: Theme.on_primary
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: card.executeCurrent()
            }
        }

        // 3. AI Prompt Dispatch Card
        Rectangle {
            visible: card.isAiQuery && card.aiPromptText.length > 0
            Layout.fillWidth: true
            height: 54
            radius: 8
            color: Theme.alpha(Theme.accent, 0.15)
            border.width: 1
            border.color: Theme.accent

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Text {
                    text: "󰚩"
                    font.family: "JetBrainsMono Nerd Font, monospace"
                    font.pixelSize: 16
                    color: Theme.accent
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: "Ask AI Agent"
                        font.family: "Outfit"; font.pixelSize: 11; font.weight: Font.Bold
                        color: Theme.accent
                    }
                    Text {
                        text: '"' + card.aiPromptText + '"'
                        font.family: "Outfit"; font.pixelSize: 12
                        color: Theme.foreground
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    height: 24; implicitWidth: aiEnterText.implicitWidth + 12; radius: 5
                    color: Theme.accent
                    Text {
                        id: aiEnterText
                        anchors.centerIn: parent
                        text: "↵ Run Agent"
                        font.family: "Outfit"; font.pixelSize: 10; font.bold: true; color: Theme.on_primary
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: card.executeCurrent()
            }
        }

        // 4. Emojis Quick Picker Row
        ColumnLayout {
            visible: card.matchedEmojis.length > 0 && card.currencyResult === null && card.mathResult === null && !card.isAiQuery
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "EMOJIS (CLICK TO COPY)"
                font.family: "JetBrainsMono Nerd Font, monospace"
                font.pixelSize: 9
                font.weight: Font.Bold
                color: Theme.alpha(Theme.foreground, 0.45)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: card.matchedEmojis
                    Rectangle {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 38
                        radius: 8
                        color: emMouse.containsMouse ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.background, 0.80)
                        border.width: 1
                        border.color: emMouse.containsMouse ? Theme.accent : Theme.alpha(Theme.foreground, 0.12)

                        Text {
                            anchors.centerIn: parent
                            text: modelData.emoji
                            font.pixelSize: 18
                        }

                        MouseArea {
                            id: emMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: card.copyEmoji(modelData.emoji, modelData.name)
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }

        // ── 5. RESULTS LIST (ACTIONS & APPS) ─────────────────────────────────
        ListView {
            id: resultsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            boundsBehavior: Flickable.StopAtBounds

            model: {
                if (card.mathResult !== null || card.currencyResult !== null || card.isAiQuery) return []
                var list = []
                for (var a = 0; a < card.matchedActions.length; a++) {
                    list.push({ type: "action", data: card.matchedActions[a] })
                }
                var apps = rootWindow ? (rootWindow.filteredApps || []) : []
                for (var i = 0; i < apps.length; i++) {
                    list.push({ type: "app", data: apps[i] })
                }
                return list
            }

            delegate: Rectangle {
                id: rowDelegate
                required property var modelData
                required property int index

                width: resultsList.width
                height: 48
                radius: 8

                readonly property bool isSelected: rootWindow && (rootWindow.selectedIndex === index)

                color: isSelected ? Theme.alpha(Theme.accent, 0.22) : (rowMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.06) : "transparent")
                border.width: isSelected ? 1 : 0
                border.color: Theme.alpha(Theme.accent, 0.50)

                Behavior on color { ColorAnimation { duration: 100 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    // Icon Container
                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 7
                        color: Theme.alpha(Theme.surface, 0.85)
                        border.width: 1
                        border.color: Theme.alpha(Theme.foreground, 0.10)

                        Image {
                            anchors.fill: parent
                            anchors.margins: 4
                            source: (modelData && modelData.type === "app" && modelData.data) ? (modelData.data.icon_path || "") : ""
                            fillMode: Image.PreserveAspectFit
                            visible: modelData && modelData.type === "app" && source.toString().length > 0 && status === Image.Ready
                        }

                        Rectangle {
                            visible: !modelData || modelData.type === "action" || (!modelData.data.icon_path)
                            anchors.fill: parent
                            radius: 6
                            color: Theme.alpha(Theme.accent, 0.18)
                            Text {
                                anchors.centerIn: parent
                                text: (modelData && modelData.type === "action") ? "⚡" : "󰵆"
                                font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 12
                                color: Theme.accent
                            }
                        }
                    }

                    // Title & Description
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            text: (modelData && modelData.data && modelData.data.name) ? modelData.data.name : ""
                            font.family: "Outfit"; font.pixelSize: 13; font.weight: Font.DemiBold
                            color: rowDelegate.isSelected ? Theme.accent : Theme.foreground
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: (modelData && modelData.type === "action") ? (modelData.data.desc || "") : ((modelData && modelData.data) ? (modelData.data.comment || modelData.data.exec || "") : "")
                            font.family: "Outfit"; font.pixelSize: 10
                            color: Theme.alpha(Theme.foreground, 0.55)
                            elide: Text.ElideRight
                        }
                    }

                    // Category Pill or Action Badge
                    Rectangle {
                        Layout.preferredHeight: 18
                        Layout.preferredWidth: catLabel.implicitWidth + 12
                        Layout.alignment: Qt.AlignVCenter
                        radius: 4
                        color: Theme.alpha(Theme.surface, 0.6)
                        border.width: 1
                        border.color: Theme.alpha(Theme.foreground, 0.10)
                        Text {
                            id: catLabel
                            anchors.centerIn: parent
                            text: (modelData && modelData.type === "action") ? "SYSTEM" : ((modelData && modelData.data && modelData.data.categories && modelData.data.categories.length > 0) ? modelData.data.categories[0] : "APP")
                            font.family: "JetBrainsMono Nerd Font, monospace"; font.pixelSize: 8; font.bold: true
                            color: Theme.alpha(Theme.foreground, 0.55)
                        }
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: if (rootWindow) rootWindow.selectedIndex = rowDelegate.index
                    onClicked: {
                        if (rootWindow) rootWindow.selectedIndex = rowDelegate.index
                        card.executeCurrent()
                    }
                }
            }
        }
    }
}
