#!/bin/bash
# brightness.sh — Adjust screen brightness for laptop or desktop.

iDIR="$HOME/.config/hypr/icons/brightness"
notification_timeout=1000

# Detect device type once
if [[ -d "/sys/class/power_supply/BAT0" ]]; then
    device="Laptop"
else
    device="Desktop"
fi

# Get brightness value (returns a plain number/percent string)
get_backlight() {
    if [[ "$device" == "Laptop" ]]; then
        brightnessctl -m | cut -d, -f4
    else
        ddcutil --sleep-multiplier=0 getvcp 10 2>/dev/null | awk '{print $9}' | tr -d ','
    fi
}

# Get icon path based on current brightness
get_icon() {
    local current
    current=$(get_backlight)
    current="${current//%/}"  # strip trailing % if present
    echo "$iDIR/brightness-${current}.png"
}

# Send notification
notify_user() {
    local current icon
    current=$(get_backlight)
    icon=$(get_icon)
    notify-send -e \
        -h string:x-canonical-private-synchronous:brightness_notif \
        -u low -i "$icon" "Brightness: $current"
}

# Change brightness
change_backlight() {
    if [[ "$device" == "Laptop" ]]; then
        brightnessctl set "$1" -n
        notify_user
    elif [[ -n "$(command -v ddcutil)" ]]; then
        # Read current level
        local current new
        current=$(ddcutil --sleep-multiplier=0 getvcp 10 2>/dev/null | awk '{print $9}' | tr -d ',')
        current="${current//%/}"
        if ! [[ "$current" =~ ^[0-9]+$ ]]; then
            current=50
        fi

        # Calculate new level
        if [[ "$1" == +* ]]; then
            new=$(( current + ${1#+} ))
        elif [[ "$1" == -* ]]; then
            new=$(( current - ${1#-} ))
        else
            new=$1
        fi

        # Clamp to [0, 100]
        (( new > 100 )) && new=100
        (( new < 0   )) && new=0

        ddcutil --sleep-multiplier=0 setvcp 10 "$new"
        notify-send -e \
            -h string:x-canonical-private-synchronous:brightness_notif \
            -u low -i "$iDIR/brightness-${new}.png" "Brightness: ${new}%"
    fi
}

# Dispatch
case "$1" in
    --get) get_backlight ;;
    up)
        [[ "$device" == "Laptop" ]] && change_backlight "+10%" || change_backlight "+10"
        ;;
    down)
        [[ "$device" == "Laptop" ]] && change_backlight "10%-" || change_backlight "-10"
        ;;
    *)
        get_backlight
        ;;
esac
