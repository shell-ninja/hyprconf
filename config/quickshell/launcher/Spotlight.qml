import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import "."

// Spotlight: Raycast-style Omnibar (Apps, Calculator, Currency Converter, Emojis, AI Prompt & System Actions)
Rectangle {
    id: card

    required property var rootWindow

    readonly property bool isIsland: Boolean(rootWindow && rootWindow.isIslandView)
    readonly property bool isBottomAttached: Boolean(rootWindow && rootWindow.isBottomAttached)

    implicitWidth: 680
    implicitHeight: Math.min(560, mainLayout.implicitHeight + (card.isBottomAttached ? 18 : 24))
    width: isIsland ? parent.width : implicitWidth
    height: isIsland ? parent.height : implicitHeight
    anchors.fill: isIsland ? parent : undefined
    anchors.centerIn: (isIsland || isBottomAttached) ? undefined : parent
    radius: (isIsland || isBottomAttached) ? 0 : 16
    color: (isIsland || isBottomAttached) ? "transparent" : Theme.alpha(Theme.surface, 0.96)
    border.width: (isIsland || isBottomAttached) ? 0 : 1.2
    border.color: Theme.alpha(Theme.accent, 0.35)
    clip: false

    readonly property string homeDir: {
        var h = Quickshell.env("HOME")
        return (h && h.length > 0) ? h : (Quickshell.env("USER") ? ("/home/" + Quickshell.env("USER")) : "/home")
    }

    // Attached Bottom Glass Frame Monolithic Shape
    Shape {
        id: bottomAttachedBg
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: card.width + fL + fR
        layer.enabled: true
        layer.samples: 4
        visible: card.isBottomAttached

        readonly property color surfaceFill: (rootWindow && rootWindow.barOpacity !== undefined)
                                             ? Theme.alpha(Theme.surface, rootWindow.barOpacity)
                                             : Theme.alpha(Theme.surface, 0.96)
        readonly property color strokeColor: Theme.alpha(Theme.accent, 0.35)
        readonly property int fL: 14
        readonly property int fR: 14
        readonly property int tr: 16
        readonly property int w: card.width
        readonly property int h: card.height

        // 1. Closed Fill Path (Seamless fusion with bottom frame)
        ShapePath {
            fillColor: bottomAttachedBg.surfaceFill
            strokeColor: "transparent"
            strokeWidth: 0

            startX: 0
            startY: bottomAttachedBg.h + 2

            // Edge from below frame up to bottom frame seam
            PathLine { x: 0; y: bottomAttachedBg.h }

            // Fillet curve from bottom frame into left edge
            PathArc {
                x: bottomAttachedBg.fL
                y: bottomAttachedBg.h - bottomAttachedBg.fL
                radiusX: bottomAttachedBg.fL
                radiusY: bottomAttachedBg.fL
                direction: PathArc.Counterclockwise
            }
            // Left vertical edge up to top-left corner
            PathLine { x: bottomAttachedBg.fL; y: bottomAttachedBg.tr }
            // Top-left rounded corner
            PathArc {
                x: bottomAttachedBg.fL + bottomAttachedBg.tr
                y: 0
                radiusX: bottomAttachedBg.tr
                radiusY: bottomAttachedBg.tr
                direction: PathArc.Clockwise
            }
            // Top horizontal edge
            PathLine { x: bottomAttachedBg.fL + bottomAttachedBg.w - bottomAttachedBg.tr; y: 0 }
            // Top-right rounded corner
            PathArc {
                x: bottomAttachedBg.fL + bottomAttachedBg.w
                y: bottomAttachedBg.tr
                radiusX: bottomAttachedBg.tr
                radiusY: bottomAttachedBg.tr
                direction: PathArc.Clockwise
            }
            // Right vertical edge down to right fillet
            PathLine { x: bottomAttachedBg.fL + bottomAttachedBg.w; y: bottomAttachedBg.h - bottomAttachedBg.fR }
            // Fillet curve from right edge into bottom frame
            PathArc {
                x: bottomAttachedBg.fL + bottomAttachedBg.w + bottomAttachedBg.fR
                y: bottomAttachedBg.h
                radiusX: bottomAttachedBg.fR
                radiusY: bottomAttachedBg.fR
                direction: PathArc.Counterclockwise
            }
            // Edge down 2px into bottom frame
            PathLine { x: bottomAttachedBg.fL + bottomAttachedBg.w + bottomAttachedBg.fR; y: bottomAttachedBg.h + 2 }
            // Close across bottom line inside bottom frame
            PathLine { x: 0; y: bottomAttachedBg.h + 2 }
        }

        // 2. Open Perimeter Stroke (NO stroke across bottom seam — seamless attachment)
        ShapePath {
            fillColor: "transparent"
            strokeColor: bottomAttachedBg.strokeColor
            strokeWidth: 1.2
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            startX: 0
            startY: bottomAttachedBg.h

            PathArc {
                x: bottomAttachedBg.fL
                y: bottomAttachedBg.h - bottomAttachedBg.fL
                radiusX: bottomAttachedBg.fL
                radiusY: bottomAttachedBg.fL
                direction: PathArc.Counterclockwise
            }
            PathLine { x: bottomAttachedBg.fL; y: bottomAttachedBg.tr }
            PathArc {
                x: bottomAttachedBg.fL + bottomAttachedBg.tr
                y: 0
                radiusX: bottomAttachedBg.tr
                radiusY: bottomAttachedBg.tr
                direction: PathArc.Clockwise
            }
            PathLine { x: bottomAttachedBg.fL + bottomAttachedBg.w - bottomAttachedBg.tr; y: 0 }
            PathArc {
                x: bottomAttachedBg.fL + bottomAttachedBg.w
                y: bottomAttachedBg.tr
                radiusX: bottomAttachedBg.tr
                radiusY: bottomAttachedBg.tr
                direction: PathArc.Clockwise
            }
            PathLine { x: bottomAttachedBg.fL + bottomAttachedBg.w; y: bottomAttachedBg.h - bottomAttachedBg.fR }
            PathArc {
                x: bottomAttachedBg.fL + bottomAttachedBg.w + bottomAttachedBg.fR
                y: bottomAttachedBg.h
                radiusX: bottomAttachedBg.fR
                radiusY: bottomAttachedBg.fR
                direction: PathArc.Counterclockwise
            }
        }
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

    Component.onCompleted: {
        focusInput()
    }

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

    // ── 2b. COMPREHENSIVE UNIT CONVERTER ─────────────────────────────────────────
    readonly property var unitResult: {
        var q = card.queryText.trim()
        if (q.length < 3 || card.isAiQuery || card.currencyResult !== null) return null

        var parts = q.split(/\s+to\s+|\s+in\s+|\s*->\s*|\s*=\s*/i)
        var val = NaN
        var uFromRaw = ""
        var uToRaw = ""

        if (parts.length === 2) {
            var m = parts[0].trim().match(/^([0-9]+(?:\.[0-9]+)?)\s*(.+)$/)
            if (!m) return null
            val = parseFloat(m[1])
            uFromRaw = m[2].trim().toLowerCase()
            uToRaw = parts[1].trim().toLowerCase()
        } else {
            var m2 = q.match(/^([0-9]+(?:\.[0-9]+)?)\s*([a-zA-Z°µ"'/²³]+)\s+([a-zA-Z°µ"'/²³]+)$/)
            if (!m2) return null
            val = parseFloat(m2[1])
            uFromRaw = m2[2].trim().toLowerCase()
            uToRaw = m2[3].trim().toLowerCase()
        }

        if (isNaN(val) || !uFromRaw || !uToRaw || uFromRaw === uToRaw) return null

        var unitsTable = {
            length: {
                name: "Length",
                icon: "󰆞",
                units: {
                    "m": { rate: 1.0, sym: "m" }, "meter": { rate: 1.0, sym: "m" }, "meters": { rate: 1.0, sym: "m" }, "metre": { rate: 1.0, sym: "m" }, "metres": { rate: 1.0, sym: "m" },
                    "km": { rate: 1000.0, sym: "km" }, "kilometer": { rate: 1000.0, sym: "km" }, "kilometers": { rate: 1000.0, sym: "km" }, "kilometre": { rate: 1000.0, sym: "km" }, "kilometres": { rate: 1000.0, sym: "km" },
                    "cm": { rate: 0.01, sym: "cm" }, "centimeter": { rate: 0.01, sym: "cm" }, "centimeters": { rate: 0.01, sym: "cm" }, "centimetre": { rate: 0.01, sym: "cm" }, "centimetres": { rate: 0.01, sym: "cm" },
                    "mm": { rate: 0.001, sym: "mm" }, "millimeter": { rate: 0.001, sym: "mm" }, "millimeters": { rate: 0.001, sym: "mm" }, "millimetre": { rate: 0.001, sym: "mm" }, "millimetres": { rate: 0.001, sym: "mm" },
                    "um": { rate: 1e-6, sym: "µm" }, "µm": { rate: 1e-6, sym: "µm" }, "micrometer": { rate: 1e-6, sym: "µm" }, "micrometers": { rate: 1e-6, sym: "µm" }, "micron": { rate: 1e-6, sym: "µm" }, "microns": { rate: 1e-6, sym: "µm" },
                    "nm": { rate: 1e-9, sym: "nm" }, "nanometer": { rate: 1e-9, sym: "nm" }, "nanometers": { rate: 1e-9, sym: "nm" },
                    "in": { rate: 0.0254, sym: "in" }, "inch": { rate: 0.0254, sym: "in" }, "inches": { rate: 0.0254, sym: "in" }, "\"": { rate: 0.0254, sym: "in" },
                    "ft": { rate: 0.3048, sym: "ft" }, "foot": { rate: 0.3048, sym: "ft" }, "feet": { rate: 0.3048, sym: "ft" }, "'": { rate: 0.3048, sym: "ft" },
                    "yd": { rate: 0.9144, sym: "yd" }, "yard": { rate: 0.9144, sym: "yd" }, "yards": { rate: 0.9144, sym: "yd" },
                    "mi": { rate: 1609.344, sym: "mi" }, "mile": { rate: 1609.344, sym: "mi" }, "miles": { rate: 1609.344, sym: "mi" },
                    "nmi": { rate: 1852.0, sym: "nmi" }, "nauticalmile": { rate: 1852.0, sym: "nmi" }, "nauticalmiles": { rate: 1852.0, sym: "nmi" }
                }
            },
            mass: {
                name: "Mass & Weight",
                icon: "󰚥",
                units: {
                    "kg": { rate: 1.0, sym: "kg" }, "kilo": { rate: 1.0, sym: "kg" }, "kilos": { rate: 1.0, sym: "kg" }, "kilogram": { rate: 1.0, sym: "kg" }, "kilograms": { rate: 1.0, sym: "kg" },
                    "g": { rate: 0.001, sym: "g" }, "gram": { rate: 0.001, sym: "g" }, "grams": { rate: 0.001, sym: "g" },
                    "mg": { rate: 1e-6, sym: "mg" }, "milligram": { rate: 1e-6, sym: "mg" }, "milligrams": { rate: 1e-6, sym: "mg" },
                    "ug": { rate: 1e-9, sym: "µg" }, "µg": { rate: 1e-9, sym: "µg" }, "microgram": { rate: 1e-9, sym: "µg" }, "micrograms": { rate: 1e-9, sym: "µg" },
                    "t": { rate: 1000.0, sym: "t" }, "ton": { rate: 1000.0, sym: "t" }, "tons": { rate: 1000.0, sym: "t" }, "tonne": { rate: 1000.0, sym: "t" }, "tonnes": { rate: 1000.0, sym: "t" },
                    "lb": { rate: 0.45359237, sym: "lbs" }, "lbs": { rate: 0.45359237, sym: "lbs" }, "pound": { rate: 0.45359237, sym: "lbs" }, "pounds": { rate: 0.45359237, sym: "lbs" },
                    "oz": { rate: 0.028349523125, sym: "oz" }, "ounce": { rate: 0.028349523125, sym: "oz" }, "ounces": { rate: 0.028349523125, sym: "oz" },
                    "st": { rate: 6.35029318, sym: "st" }, "stone": { rate: 6.35029318, sym: "st" }
                }
            },
            temperature: {
                name: "Temperature",
                icon: "󰔏",
                isTemp: true,
                units: {
                    "c": { sym: "°C" }, "celsius": { sym: "°C" }, "°c": { sym: "°C" }, "deg c": { sym: "°C" },
                    "f": { sym: "°F" }, "fahrenheit": { sym: "°F" }, "°f": { sym: "°F" }, "deg f": { sym: "°F" },
                    "k": { sym: "K" }, "kelvin": { sym: "K" }
                }
            },
            area: {
                name: "Area",
                icon: "󱁕",
                units: {
                    "sqm": { rate: 1.0, sym: "m²" }, "m2": { rate: 1.0, sym: "m²" }, "m²": { rate: 1.0, sym: "m²" }, "sq m": { rate: 1.0, sym: "m²" },
                    "sqkm": { rate: 1e6, sym: "km²" }, "km2": { rate: 1e6, sym: "km²" }, "km²": { rate: 1e6, sym: "km²" }, "sq km": { rate: 1e6, sym: "km²" },
                    "sqcm": { rate: 1e-4, sym: "cm²" }, "cm2": { rate: 1e-4, sym: "cm²" }, "cm²": { rate: 1e-4, sym: "cm²" }, "sq cm": { rate: 1e-4, sym: "cm²" },
                    "sqmm": { rate: 1e-6, sym: "mm²" }, "mm2": { rate: 1e-6, sym: "mm²" }, "mm²": { rate: 1e-6, sym: "mm²" }, "sq mm": { rate: 1e-6, sym: "mm²" },
                    "sqft": { rate: 0.09290304, sym: "sq ft" }, "ft2": { rate: 0.09290304, sym: "sq ft" }, "ft²": { rate: 0.09290304, sym: "sq ft" }, "sq ft": { rate: 0.09290304, sym: "sq ft" },
                    "sqin": { rate: 0.00064516, sym: "sq in" }, "in2": { rate: 0.00064516, sym: "sq in" }, "in²": { rate: 0.00064516, sym: "sq in" }, "sq in": { rate: 0.00064516, sym: "sq in" },
                    "sqyd": { rate: 0.83612736, sym: "sq yd" }, "yd2": { rate: 0.83612736, sym: "sq yd" }, "yd²": { rate: 0.83612736, sym: "sq yd" }, "sq yd": { rate: 0.83612736, sym: "sq yd" },
                    "sqmi": { rate: 2589988.110336, sym: "sq mi" }, "mi2": { rate: 2589988.110336, sym: "sq mi" }, "mi²": { rate: 2589988.110336, sym: "sq mi" }, "sq mi": { rate: 2589988.110336, sym: "sq mi" },
                    "ha": { rate: 10000.0, sym: "ha" }, "hectare": { rate: 10000.0, sym: "ha" }, "hectares": { rate: 10000.0, sym: "ha" },
                    "acre": { rate: 4046.8564224, sym: "acres" }, "acres": { rate: 4046.8564224, sym: "acres" }
                }
            },
            volume: {
                name: "Volume",
                icon: "󰈢",
                units: {
                    "l": { rate: 1.0, sym: "L" }, "liter": { rate: 1.0, sym: "L" }, "liters": { rate: 1.0, sym: "L" }, "litre": { rate: 1.0, sym: "L" }, "litres": { rate: 1.0, sym: "L" },
                    "ml": { rate: 0.001, sym: "mL" }, "milliliter": { rate: 0.001, sym: "mL" }, "milliliters": { rate: 0.001, sym: "mL" }, "millilitre": { rate: 0.001, sym: "mL" }, "millilitres": { rate: 0.001, sym: "mL" },
                    "cl": { rate: 0.01, sym: "cL" }, "dl": { rate: 0.1, sym: "dL" },
                    "m3": { rate: 1000.0, sym: "m³" }, "m³": { rate: 1000.0, sym: "m³" },
                    "gal": { rate: 3.785411784, sym: "gal" }, "gallon": { rate: 3.785411784, sym: "gal" }, "gallons": { rate: 3.785411784, sym: "gal" },
                    "qt": { rate: 0.946352946, sym: "qt" }, "quart": { rate: 0.946352946, sym: "qt" }, "quarts": { rate: 0.946352946, sym: "qt" },
                    "pt": { rate: 0.473176473, sym: "pt" }, "pint": { rate: 0.473176473, sym: "pt" }, "pints": { rate: 0.473176473, sym: "pt" },
                    "cup": { rate: 0.2365882365, sym: "cup" }, "cups": { rate: 0.2365882365, sym: "cup" },
                    "floz": { rate: 0.0295735295625, sym: "fl oz" }, "fl oz": { rate: 0.0295735295625, sym: "fl oz" }, "fluid ounce": { rate: 0.0295735295625, sym: "fl oz" },
                    "tbsp": { rate: 0.01478676478125, sym: "tbsp" }, "tablespoon": { rate: 0.01478676478125, sym: "tbsp" },
                    "tsp": { rate: 0.00492892159375, sym: "tsp" }, "teaspoon": { rate: 0.00492892159375, sym: "tsp" },
                    "cuft": { rate: 28.316846592, sym: "cu ft" }, "ft3": { rate: 28.316846592, sym: "cu ft" },
                    "cuin": { rate: 0.016387064, sym: "cu in" }, "in3": { rate: 0.016387064, sym: "cu in" }
                }
            },
            speed: {
                name: "Speed",
                icon: "󱓞",
                units: {
                    "m/s": { rate: 1.0, sym: "m/s" }, "mps": { rate: 1.0, sym: "m/s" },
                    "km/h": { rate: 1.0 / 3.6, sym: "km/h" }, "kmh": { rate: 1.0 / 3.6, sym: "km/h" }, "kph": { rate: 1.0 / 3.6, sym: "km/h" },
                    "mph": { rate: 0.44704, sym: "mph" },
                    "knot": { rate: 0.514444, sym: "kn" }, "knots": { rate: 0.514444, sym: "kn" }, "kn": { rate: 0.514444, sym: "kn" },
                    "ft/s": { rate: 0.3048, sym: "ft/s" }, "fps": { rate: 0.3048, sym: "ft/s" }
                }
            },
            data: {
                name: "Digital Data",
                icon: "󰈀",
                units: {
                    "b": { rate: 0.125, sym: "b" }, "bit": { rate: 0.125, sym: "b" }, "bits": { rate: 0.125, sym: "b" },
                    "byte": { rate: 1.0, sym: "B" }, "bytes": { rate: 1.0, sym: "B" },
                    "kb": { rate: 125.0, sym: "kb" }, "kbit": { rate: 125.0, sym: "kb" },
                    "kib": { rate: 1024.0, sym: "KiB" },
                    "mb": { rate: 1e6, sym: "MB" }, "megabyte": { rate: 1e6, sym: "MB" }, "megabytes": { rate: 1e6, sym: "MB" },
                    "mib": { rate: 1048576.0, sym: "MiB" },
                    "gb": { rate: 1e9, sym: "GB" }, "gigabyte": { rate: 1e9, sym: "GB" }, "gigabytes": { rate: 1e9, sym: "GB" },
                    "gib": { rate: 1073741824.0, sym: "GiB" },
                    "tb": { rate: 1e12, sym: "TB" }, "terabyte": { rate: 1e12, sym: "TB" }, "terabytes": { rate: 1e12, sym: "TB" },
                    "tib": { rate: 1099511627776.0, sym: "TiB" },
                    "pb": { rate: 1e15, sym: "PB" }, "petabyte": { rate: 1e15, sym: "PB" }
                }
            },
            time: {
                name: "Time",
                icon: "󱎫",
                units: {
                    "ms": { rate: 0.001, sym: "ms" }, "millisecond": { rate: 0.001, sym: "ms" }, "milliseconds": { rate: 0.001, sym: "ms" },
                    "s": { rate: 1.0, sym: "s" }, "sec": { rate: 1.0, sym: "s" }, "secs": { rate: 1.0, sym: "s" }, "second": { rate: 1.0, sym: "s" }, "seconds": { rate: 1.0, sym: "s" },
                    "min": { rate: 60.0, sym: "min" }, "mins": { rate: 60.0, sym: "min" }, "minute": { rate: 60.0, sym: "min" }, "minutes": { rate: 60.0, sym: "min" },
                    "h": { rate: 3600.0, sym: "hr" }, "hr": { rate: 3600.0, sym: "hr" }, "hrs": { rate: 3600.0, sym: "hr" }, "hour": { rate: 3600.0, sym: "hr" }, "hours": { rate: 3600.0, sym: "hr" },
                    "d": { rate: 86400.0, sym: "days" }, "day": { rate: 86400.0, sym: "days" }, "days": { rate: 86400.0, sym: "days" },
                    "wk": { rate: 604800.0, sym: "wks" }, "wks": { rate: 604800.0, sym: "wks" }, "week": { rate: 604800.0, sym: "wks" }, "weeks": { rate: 604800.0, sym: "wks" },
                    "mo": { rate: 2629800.0, sym: "months" }, "month": { rate: 2629800.0, sym: "months" }, "months": { rate: 2629800.0, sym: "months" },
                    "yr": { rate: 31557600.0, sym: "yrs" }, "year": { rate: 31557600.0, sym: "yrs" }, "years": { rate: 31557600.0, sym: "yrs" }
                }
            },
            pressure: {
                name: "Pressure",
                icon: "󱠤",
                units: {
                    "pa": { rate: 1.0, sym: "Pa" }, "pascal": { rate: 1.0, sym: "Pa" },
                    "kpa": { rate: 1000.0, sym: "kPa" },
                    "mpa": { rate: 1e6, sym: "MPa" },
                    "bar": { rate: 100000.0, sym: "bar" }, "bars": { rate: 100000.0, sym: "bar" },
                    "mbar": { rate: 100.0, sym: "mbar" },
                    "psi": { rate: 6894.757293168, sym: "psi" },
                    "atm": { rate: 101325.0, sym: "atm" },
                    "torr": { rate: 133.322368421, sym: "Torr" }, "mmhg": { rate: 133.322368421, sym: "mmHg" }
                }
            },
            energy: {
                name: "Energy & Power",
                icon: "󱐋",
                units: {
                    "j": { rate: 1.0, sym: "J" }, "joule": { rate: 1.0, sym: "J" }, "joules": { rate: 1.0, sym: "J" },
                    "kj": { rate: 1000.0, sym: "kJ" },
                    "mj": { rate: 1e6, sym: "MJ" },
                    "cal": { rate: 4.184, sym: "cal" }, "calorie": { rate: 4.184, sym: "cal" }, "calories": { rate: 4.184, sym: "cal" },
                    "kcal": { rate: 4184.0, sym: "kcal" },
                    "wh": { rate: 3600.0, sym: "Wh" },
                    "kwh": { rate: 3.6e6, sym: "kWh" },
                    "btu": { rate: 1055.05585, sym: "BTU" },
                    "ev": { rate: 1.602176634e-19, sym: "eV" },
                    "w": { rate: 1.0, sym: "W" }, "watt": { rate: 1.0, sym: "W" }, "watts": { rate: 1.0, sym: "W" },
                    "kw": { rate: 1000.0, sym: "kW" }, "kilowatt": { rate: 1000.0, sym: "kW" },
                    "hp": { rate: 745.699872, sym: "hp" }, "horsepower": { rate: 745.699872, sym: "hp" }
                }
            }
        }

        for (var catKey in unitsTable) {
            var cat = unitsTable[catKey]
            if (cat.isTemp) {
                var u1 = cat.units[uFromRaw]
                var u2 = cat.units[uToRaw]
                if (u1 && u2) {
                    var s1 = u1.sym
                    var s2 = u2.sym
                    var cVal = (s1 === "°C") ? val : (s1 === "°F") ? (val - 32) * 5 / 9 : (val - 273.15)
                    var target = (s2 === "°C") ? cVal : (s2 === "°F") ? (cVal * 9 / 5 + 32) : (cVal + 273.15)
                    var tFormatted = (Math.round(target * 10000) / 10000).toLocaleString("en-US", { maximumFractionDigits: 4 })
                    return {
                        amount: val,
                        fromSym: s1,
                        toSym: s2,
                        target: target,
                        formatted: val + " " + s1 + " = " + tFormatted + " " + s2,
                        rateStr: cat.name + " Conversion",
                        copyVal: tFormatted + " " + s2,
                        icon: cat.icon
                    }
                }
            } else {
                var u1n = cat.units[uFromRaw]
                var u2n = cat.units[uToRaw]
                if (u1n && u2n) {
                    var baseVal = val * u1n.rate
                    var targetVal = baseVal / u2n.rate
                    var unitRate = u1n.rate / u2n.rate
                    var tFormattedVal = (Math.round(targetVal * 100000) / 100000).toLocaleString("en-US", { maximumFractionDigits: 5 })
                    var rFormatted = (Math.round(unitRate * 100000) / 100000).toLocaleString("en-US", { maximumFractionDigits: 5 })
                    return {
                        amount: val,
                        fromSym: u1n.sym,
                        toSym: u2n.sym,
                        target: targetVal,
                        formatted: val + " " + u1n.sym + " = " + tFormattedVal + " " + u2n.sym,
                        rateStr: "1 " + u1n.sym + " = " + rFormatted + " " + u2n.sym + " (" + cat.name + ")",
                        copyVal: tFormattedVal + " " + u2n.sym,
                        icon: cat.icon
                    }
                }
            }
        }
        return null
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
        if (card.isAiQuery || card.mathResult !== null || card.currencyResult !== null || card.unitResult !== null) return []

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
        Quickshell.execDetached(["wl-copy", "--", glyph])
        Quickshell.execDetached(["wl-copy", "--primary", "--", glyph])
        Quickshell.execDetached(["python3", card.homeDir + "/.hyprconf/hypr/scripts/py/paste-emoji.py", glyph])
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
        { id: "gamemode", name: "Game Mode", desc: "Toggle Gaming Mode (0ms Latency & Max Perf)", cmd: "gamemode.sh --toggle", icon: "gamepad" },
        { id: "lock", name: "Lock Screen", desc: "Launch PAM Lockscreen", cmd: "qs-lock.sh", icon: "lock" },
        { id: "sleep", name: "Sleep / Suspend", desc: "Suspend system to RAM", cmd: "systemctl suspend", icon: "moon" },
        { id: "caffeine", name: "Toggle Caffeine", desc: "Inhibit display sleep & idle", cmd: "caffeine-manager.sh", icon: "coffee" },
        { id: "nightlight", name: "Toggle Night Light", desc: "Blue light filter (hyprsunset)", cmd: "hyprsunset-manager.sh", icon: "moonStar" },
        { id: "settings", name: "Settings Studio", desc: "Unified Quickshell Settings", cmd: "qs-settings.sh", icon: "settings" },
        { id: "updater", name: "Package Updater", desc: "Check and apply system upgrades", cmd: "qs-updater.sh", icon: "download" },
        { id: "reload", name: "Reload Quickshell", desc: "Restart desktop shell processes", cmd: "qs-reload.sh", icon: "refresh" },
        { id: "screenshot", name: "Screenshot Studio", desc: "Interactive screen capture", cmd: "qs-screenshot.sh", icon: "camera" }
    ]

    function getActionGlyph(iconName) {
        switch (iconName) {
            case "gamepad": return "󰊴"
            case "lock": return "󰌾"
            case "moon": return "󰤄"
            case "coffee": return "󰅶"
            case "moonStar": return "󰖔"
            case "settings": return "󰒓"
            case "download": return "󰇚"
            case "refresh": return "󰑐"
            case "camera": return "󰄀"
            default: return "󰵆"
        }
    }

    readonly property var matchedActions: {
        var q = card.queryText.toLowerCase().trim()
        if (q.length === 0 || card.isAiQuery || card.mathResult !== null || card.currencyResult !== null || card.unitResult !== null) return []
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
        // 0. Unit conversion result
        if (card.unitResult !== null) {
            var unitVal = card.unitResult.copyVal
            Quickshell.execDetached(["wl-copy", "--", unitVal])
            Quickshell.execDetached(["wl-copy", "--primary", "--", unitVal])
            var osdCmdU = card.homeDir + "/.hyprconf/hypr/scripts/sh/osd-notify.sh"
            Quickshell.execDetached([osdCmdU, "calculator", "1", "Unit Converted", "calculator", card.unitResult.formatted + " copied!"])
            card.triggerClose()
            return
        }

        // 1. Currency conversion result
        if (card.currencyResult !== null) {
            var currVal = card.currencyResult.copyVal
            Quickshell.execDetached(["wl-copy", "--", currVal])
            Quickshell.execDetached(["wl-copy", "--primary", "--", currVal])
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

        // 3. AI Prompt (open in user's terminal)
        if (card.isAiQuery && card.aiPromptText.length > 0) {
            Quickshell.execDetached(["kitty", "--title", "opencode", "bash", "-c", "opencode " + JSON.stringify(card.aiPromptText) + " || $SHELL"])
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
        anchors.leftMargin: card.isIsland ? 12 : 14
        anchors.rightMargin: card.isIsland ? 12 : 14
        anchors.topMargin: card.isIsland ? 12 : 14
        anchors.bottomMargin: card.isBottomAttached ? 6 : (card.isIsland ? 12 : 14)
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
                        text: "Search apps, calculate, 10 cm to in, 100 USD to EUR, :emoji, or >ask AI..."
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
                        if (card.unitResult !== null) return Theme.alpha(Theme.accent, 0.25)
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
                            if (card.unitResult !== null) return "CONVERT"
                            if (card.mathResult !== null) return "CALC"
                            if (card.isAiQuery) return "AI AGENT"
                            if (matchedActions.length > 0) return "ACTION"
                            return "OMNIBAR"
                        }
                        font.family: "JetBrainsMono Nerd Font, monospace"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: (card.currencyResult !== null || card.unitResult !== null || card.mathResult !== null || card.isAiQuery) ? Theme.accent : Theme.alpha(Theme.foreground, 0.65)
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

        // 1b. Unit Conversion Result Card
        Rectangle {
            visible: card.unitResult !== null && card.currencyResult === null
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
                    text: card.unitResult ? card.unitResult.icon : "󰆞"
                    font.family: "JetBrainsMono Nerd Font, monospace"
                    font.pixelSize: 18
                    color: Theme.accent
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: card.unitResult ? card.unitResult.formatted : ""
                        font.family: "Outfit"; font.pixelSize: 15; font.weight: Font.Bold
                        color: Theme.foreground
                    }
                    Text {
                        text: card.unitResult ? card.unitResult.rateStr : ""
                        font.family: "Outfit"; font.pixelSize: 10
                        color: Theme.alpha(Theme.foreground, 0.60)
                    }
                }

                Rectangle {
                    height: 24; implicitWidth: unitEnterText.implicitWidth + 12; radius: 5
                    color: Theme.accent
                    Text {
                        id: unitEnterText
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
            visible: card.mathResult !== null && card.currencyResult === null && card.unitResult === null
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
                                text: (modelData && modelData.type === "action" && modelData.data) ? card.getActionGlyph(modelData.data.icon) : "󰵆"
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
