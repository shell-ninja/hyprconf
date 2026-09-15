#!/bin/bash
# brightness.sh — Adjust monitor brightness with Noctalia OSD support.
#
# Usage:
#   brightness.sh up   [step]   Increase brightness (default step: 10)
#   brightness.sh down [step]   Decrease brightness (default step: 10)
#   brightness.sh get           Print current brightness percentage
#   brightness.sh osd           Show OSD for current value without changing
#
# Strategy:
#   1. Primary:  noctalia msg brightness-{up,down,set}   (handles OSD natively)
#   2. Fallback: brightnessctl (laptop) or ddcutil (desktop) + manual OSD notify

STEP="${2:-10}"

# ── Helper: detect device type ───────────────────────────────────────────────

is_laptop() {
    [[ -d "/sys/class/power_supply/BAT0" ]]
}

has_cmd() {
    command -v "$1" &>/dev/null
}

# ── Brightness getters ────────────────────────────────────────────────────────

get_brightness_laptop() {
    brightnessctl -m | cut -d, -f4 | tr -d '%'
}

get_brightness_desktop() {
    local raw
    raw=$(ddcutil --sleep-multiplier=0 getvcp 10 2>/dev/null | awk '{print $9}' | tr -d ',')
    raw="${raw%\%}"
    if [[ "$raw" =~ ^[0-9]+$ ]]; then
        echo "$raw"
    else
        echo "50"
    fi
}

get_brightness() {
    if is_laptop; then
        get_brightness_laptop
    else
        get_brightness_desktop
    fi
}

# ── Manual OSD via notify-send (fallback when noctalia not running) ───────────

notify_osd() {
    local pct="$1"
    # Use -r 91191 so repeated calls replace the same notification bubble
    notify-send -r 91191 -t 1200 \
        -h "int:value:${pct}" \
        -h "string:x-dunst-stack-tag:brightness" \
        "Brightness" "${pct}%"
}

# ── Primary: delegate fully to noctalia (OSD included) ───────────────────────

noctalia_change() {
    local direction="$1"   # "up" or "down"
    local step="$2"
    noctalia msg "brightness-${direction}" "" "$step" 2>/dev/null
}

# ── Fallback: change via system tools + show OSD manually ────────────────────

fallback_change() {
    local direction="$1"
    local step="$2"

    if is_laptop && has_cmd brightnessctl; then
        if [[ "$direction" == "up" ]]; then
            brightnessctl set "${step}%+" -n -q
        else
            brightnessctl set "${step}%-" -n -q
        fi
        local pct
        pct=$(get_brightness_laptop)
        notify_osd "$pct"

    elif has_cmd ddcutil; then
        local current new
        current=$(get_brightness_desktop)

        if [[ "$direction" == "up" ]]; then
            new=$(( current + step ))
        else
            new=$(( current - step ))
        fi
        (( new > 100 )) && new=100
        (( new < 0   )) && new=0

        ddcutil --sleep-multiplier=0 setvcp 10 "$new" &>/dev/null
        notify_osd "$new"
    else
        echo "Error: no supported brightness tool found (brightnessctl / ddcutil)." >&2
        exit 1
    fi
}

# ── Main: try noctalia first, fall back on failure ────────────────────────────

change_brightness() {
    local direction="$1"
    local step="$2"

    if has_cmd noctalia && noctalia msg brightness-"$direction" "" "$step" 2>/dev/null; then
        return 0
    fi
    # noctalia not running / failed → use system tools + notify-send OSD
    fallback_change "$direction" "$step"
}

# ── Dispatch ──────────────────────────────────────────────────────────────────

case "${1:-}" in
    up)
        change_brightness up "$STEP"
        ;;
    down)
        change_brightness down "$STEP"
        ;;
    --get|get)
        get_brightness
        ;;
    osd)
        pct=$(get_brightness)
        if has_cmd noctalia; then
            noctalia msg brightness-osd "$pct" 2>/dev/null || notify_osd "$pct"
        else
            notify_osd "$pct"
        fi
        ;;
    *)
        echo "Usage: $(basename "$0") {up|down|get|osd} [step]" >&2
        exit 1
        ;;
esac
