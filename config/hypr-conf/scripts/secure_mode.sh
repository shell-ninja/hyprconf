#!/bin/bash

# secure mode conains a nature wallpaper.

if [[ -z "$(command -v awww)" ]]; then
    notify-send "Bro,,, Where is a wallpaper daemon?"
    exit 1
fi

scripts_dir="$HOME/.config/hypr/scripts"
cache_dir="$HOME/.config/hypr/.cache"
Wallpaper="$HOME/.hyprconf/hypr/Wallpaper/crime.jpg"
previous=$(cat "$cache_dir/.wallpaper")

# Transition config
FPS=30
TYPE="left"
DURATION=0.2
BEZIER=".28,.58,.99,.37"
AWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

awww-daemon &
awww img ${Wallpaper} $AWWW_PARAMS

ln -sf "$Wallpaper" "$cache_dir/current_wallpaper.png"

sleep 0.5
"$scripts_dir/wallcache.sh"
"$scripts_dir/pywal.sh"
