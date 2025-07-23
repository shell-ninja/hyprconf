#!/bin/bash

SCRIPTSDIR=$HOME/.config/hypr/scripts

# Define file_exists function
file_exists() {
    if [ -e "$1" ]; then
        return 0  # File exists
    else
        return 1  # File does not exist
    fi
}

# Kill already running processes
_ps=(
    dunst
    swaync
    rofi
    # waybar
)
for _prs in "${_ps[@]}"; do
    if pidof "${_prs}" &> /dev/null; then
        pkill "${_prs}"
    fi
done

sleep 0.1
if [[ -n "$(command -v swaync)" ]]; then
    swaync &
elif [[ -n "$(command -v dunst)" ]]; then
    dunst &
fi

sleep 1
hyprctl reload

exit 0
