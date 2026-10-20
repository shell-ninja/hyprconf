#!/usr/bin/env bash
# brightness.sh — Adjust monitor brightness with notify-send / OSD support.
#
# Usage:
#   brightness.sh up   [step]   Increase brightness (default step: 10)
#   brightness.sh down [step]   Decrease brightness (default step: 10)
#   brightness.sh get           Print current brightness percentage
#   brightness.sh osd           Show OSD for current value without changing

STEP="${2:-10}"

is_laptop() {
    [[ -d "/sys/class/power_supply/BAT0" ]]
}

has_cmd() {
    command -v "$1" &>/dev/null
}

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

notify_osd() {
    local pct="$1"
    qs ipc -c island call island showOsd "brightness" "$pct" "${pct}%" "brightness" "" >/dev/null 2>&1 &
}

change_brightness() {
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

case "${1:-}" in
    up)
        change_brightness up "$STEP"
        ;;
    down)
        change_brightness down "$STEP"
        ;;
    set)
        new_val="${2:-50}"
        (( new_val > 100 )) && new_val=100
        (( new_val < 0   )) && new_val=0
        if is_laptop && has_cmd brightnessctl; then
            brightnessctl set "${new_val}%" -q
        elif has_cmd ddcutil; then
            ddcutil --sleep-multiplier=0 setvcp 10 "$new_val" &>/dev/null
        fi
        notify_osd "$new_val"
        ;;
    --get|get)
        get_brightness
        ;;
    osd)
        pct=$(get_brightness)
        notify_osd "$pct"
        ;;
    *)
        echo "Usage: $0 {up|down|get|set <0-100>|osd} [step]"
        exit 1
        ;;
esac
