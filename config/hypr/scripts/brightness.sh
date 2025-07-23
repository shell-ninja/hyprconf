#!/bin/bash

iDIR="$HOME/.config/hypr/icons/brightness"
notification_timeout=1000

if [[ -d "/sys/class/power_supply/BAT0" ]]; then
    device="Laptop"
    
    # get brightness
    get_backlight() {
	    echo $(brightnessctl -m | cut -d, -f4)
    }
    
    # get icon
    get_icon() {
        current=$(get_backlight | sed 's/%//')
        icon="$iDIR/brightness-${current}.png"

    }
else
    device="Desktop"

    # Get brightness
    get_backlight() {
        echo $(ddcutil --sleep-multiplier=0 getvcp 10 | awk '{print $9}' | tr -d ',')
    }
fi

# Notify using dunst
# notify_user() {
# 	notify-send -a -r -h string:x-dunst-stack-tag:brightness_notif -i "$icon" "Brightness: $current%"
# }

# Notify using swaync
notify_user() {
	notify-send -e -h string:x-canonical-private-synchronous:brightness_notif -h int:value:$current -u low -i "$icon" "Brightness : $current%"
}

# Change brightness
change_backlight() {
    if [[ "$device" == "Laptop" ]]; then
        brightnessctl set "$1" -n && get_icon && notify_user
    elif [[ "$device" == "Desktop" && -n "$(command -v ddcutil)" ]]; then
        # Get current brightness once
        current=$(ddcutil --sleep-multiplier=0 getvcp 10 | awk '{print $9}' | tr -d ',')
        current=${current%\%}
        if ! [[ "$current" =~ ^[0-9]+$ ]]; then
            current=50
        fi

        # Calculate new brightness
        if [[ "$1" == +* ]]; then
            new=$((current + ${1#+}))
        elif [[ "$1" == -* ]]; then
            new=$((current - ${1#-}))
        else
            new=$1
        fi

        # Clamp between 0-100
        ((new > 100)) && new=100
        ((new < 0)) && new=0

        # Set brightness
        ddcutil --sleep-multiplier=0 setvcp 10 "$new"

        # Reuse value
        current=$new
        icon="$iDIR/brightness-${current}.png"

        notify_user
    fi
}

# Execute accordingly
if [[ "$device" == "Laptop" ]]; then
    case "$1" in
        "--get")
            get_backlight
            ;;
        "up")
            change_backlight "+10%"
            ;;
        "down")
            change_backlight "10%-"
            ;;
        *)
            get_backlight
            ;;
    esac
else
    case "$1" in
        "--get")
            get_backlight
            ;;
        "up")
            change_backlight "+10"
            ;;
        "down")
            change_backlight "-10"
            ;;
        *)
            get_backlight
            ;;
    esac
fi
