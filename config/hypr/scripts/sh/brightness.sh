#!/usr/bin/env bash
# brightness.sh — Adjust monitor brightness with notify-send / OSD support.
#
# Usage:
#   brightness.sh up   [step]   Increase brightness (default step: 10)
#   brightness.sh down [step]   Decrease brightness (default step: 10)
#   brightness.sh get           Print current brightness percentage
#   brightness.sh set  <0-100>  Set brightness to specific percentage
#   brightness.sh osd           Show OSD for current value without changing

STEP="${2:-10}"

has_cmd() {
    command -v "$1" &>/dev/null
}

has_backlight() {
    compgen -G "/sys/class/backlight/*" >/dev/null
}

is_laptop() {
    has_backlight || \
    compgen -G "/sys/class/power_supply/BAT*" >/dev/null || \
    compgen -G "/sys/class/power_supply/BATT*" >/dev/null || \
    [[ -d "/sys/class/power_supply/BAT0" ]] || \
    {
        local c
        c=$(cat /sys/class/dmi/id/chassis_type 2>/dev/null)
        [[ "$c" =~ ^(8|9|10|11|14|31|32)$ ]]
    }
}

get_brightness_laptop() {
    # 1. Try brightnessctl targeting backlight class
    if has_cmd brightnessctl; then
        local pct
        pct=$(brightnessctl -c backlight -m 2>/dev/null | head -n 1 | cut -d, -f4 | tr -d '%')
        if [[ -z "$pct" ]]; then
            pct=$(brightnessctl -m 2>/dev/null | awk -F, '$2=="backlight" {print $4; exit}' | tr -d '%')
        fi
        if [[ -z "$pct" ]]; then
            pct=$(brightnessctl -m 2>/dev/null | head -n 1 | cut -d, -f4 | tr -d '%')
        fi
        if [[ -n "$pct" && "$pct" =~ ^[0-9]+$ ]]; then
            echo "$pct"
            return 0
        fi
    fi

    # 2. Try light
    if has_cmd light; then
        local l_val
        l_val=$(light -G 2>/dev/null | cut -d. -f1)
        if [[ -n "$l_val" && "$l_val" =~ ^[0-9]+$ ]]; then
            echo "$l_val"
            return 0
        fi
    fi

    # 3. Direct sysfs read (works on all Linux kernels with backlight driver)
    local bl_dir
    bl_dir=$(ls -d /sys/class/backlight/* 2>/dev/null | head -n 1)
    if [[ -n "$bl_dir" && -f "$bl_dir/brightness" && -f "$bl_dir/max_brightness" ]]; then
        local cur max
        cur=$(<"$bl_dir/brightness")
        max=$(<"$bl_dir/max_brightness")
        if (( max > 0 )); then
            echo $(( (cur * 100) / max ))
            return 0
        fi
    fi

    echo "50"
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
    if has_backlight || is_laptop; then
        get_brightness_laptop
    else
        get_brightness_desktop
    fi
}

notify_osd() {
    local pct="$1"
    qs ipc -c island call island showOsd "brightness" "$pct" "${pct}%" "brightness" "" >/dev/null 2>&1 &
}

set_brightness_laptop() {
    local val="$1"
    if has_cmd brightnessctl; then
        brightnessctl -c backlight set "${val}%" -q 2>/dev/null || brightnessctl set "${val}%" -q 2>/dev/null
    elif has_cmd light; then
        light -S "$val" 2>/dev/null
    elif has_cmd brillo; then
        brillo -q -S "$val" 2>/dev/null
    else
        # Try direct sysfs write
        local bl_dir
        bl_dir=$(ls -d /sys/class/backlight/* 2>/dev/null | head -n 1)
        if [[ -n "$bl_dir" && -w "$bl_dir/brightness" && -f "$bl_dir/max_brightness" ]]; then
            local max target
            max=$(<"$bl_dir/max_brightness")
            target=$(( (val * max) / 100 ))
            echo "$target" > "$bl_dir/brightness" 2>/dev/null
        fi
    fi
}

change_brightness() {
    local direction="$1"
    local step="$2"

    if has_backlight || is_laptop; then
        if has_cmd brightnessctl; then
            if [[ "$direction" == "up" ]]; then
                brightnessctl -c backlight set "${step}%+" -n -q 2>/dev/null || brightnessctl set "${step}%+" -n -q 2>/dev/null
            else
                brightnessctl -c backlight set "${step}%-" -n -q 2>/dev/null || brightnessctl set "${step}%-" -n -q 2>/dev/null
            fi
        elif has_cmd light; then
            if [[ "$direction" == "up" ]]; then
                light -A "$step" 2>/dev/null
            else
                light -U "$step" 2>/dev/null
            fi
        elif has_cmd brillo; then
            if [[ "$direction" == "up" ]]; then
                brillo -q -A "$step" 2>/dev/null
            else
                brillo -q -U "$step" 2>/dev/null
            fi
        else
            local cur
            cur=$(get_brightness_laptop)
            local target
            if [[ "$direction" == "up" ]]; then
                target=$(( cur + step ))
            else
                target=$(( cur - step ))
            fi
            (( target > 100 )) && target=100
            (( target < 0   )) && target=0
            set_brightness_laptop "$target"
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
        echo "Error: no supported brightness tool found (brightnessctl / light / ddcutil)." >&2
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

        if has_backlight || is_laptop; then
            set_brightness_laptop "$new_val"
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
