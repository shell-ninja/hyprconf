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
    for file in "$themes"/hyprlock-*.conf; do
        num=$(basename "$file" .conf | sed 's/hyprlock-//')
        echo "Theme $num"
    done
}

# choice
choice=$(styles | ${rofi_command})

if [[ -n "$choice" ]]; then
    num=$(echo "$choice" | awk '{print $2}')
    set_lockscreen "$themes/hyprlock-$num.conf"
fi

