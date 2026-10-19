#!/usr/bin/env bash

scriptsDir="$HOME/.hyprconf/hypr/scripts/py"
cacheDir="$HOME/.hyprconf/hypr/.cache"
icon="$HOME/.hyprconf/hypr/icons/colors.png"
msg="Re-generating Colors"

notify-send "Colors" -i "$icon" "$msg"
currentWall="$cacheDir/current_wallpaper.png"
if [[ -f "$currentWall" ]]; then
    "$scriptsDir/hypr-colors.py" "$currentWall"
else
    "$scriptsDir/hypr-colors.py"
fi
