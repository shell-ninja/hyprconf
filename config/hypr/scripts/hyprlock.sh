#!/bin/bash

# hyprlock dir
themes="$HOME/.config/hypr/lockscreens"
rofi_command="rofi -show -dmenu -config ~/.config/rofi/themes/rofi-hyprlock-theme.rasi"
destination="$HOME/.config/hypr/hyprlock.conf"


# fn set lockscreen 
set_lockscreen() {
    local theme=$1
    local dest="$destination"

    ln -sf "$theme" "$dest"
}

# styles
styles() {
    echo "Style-1"
    echo "Style-2"
    echo "Style-3"
}

# choice
choice=$(styles | ${rofi_command})

case "$choice" in
    Style-1)
        set_lockscreen "$themes/hyprlock-1.conf"
        ;;
    Style-2)
        set_lockscreen "$themes/hyprlock-2.conf"
        ;;
    Style-3)
        set_lockscreen "$themes/hyprlock-3.conf"
        ;;
esac

