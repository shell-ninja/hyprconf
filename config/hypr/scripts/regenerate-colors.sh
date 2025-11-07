#!/usr/bin/env bash

scriptsDir="$HOME/.hyprconf/hypr/scripts"
icon="$HOME/.hyprconf/hypr/icons/colors.png"
msg="Re-generating Colors"

notify-send "Colors" -i "$icon" "$msg"

"$scriptsDir/pywal.sh"
