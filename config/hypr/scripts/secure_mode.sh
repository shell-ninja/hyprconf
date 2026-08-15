#!/bin/bash

# secure_mode — applies a neutral/nature wallpaper immediately.

if ! command -v awww &>/dev/null; then
    notify-send "Bro,,, Where is a wallpaper daemon?"
    exit 1
fi

scripts_dir="$HOME/.hyprconf/hypr/scripts"
cache_dir="$HOME/.hyprconf/hypr/.cache"
Wallpaper="$HOME/.hyprconf/hypr/Wallpaper/crime.jpg"

# Transition config
FPS=30
TYPE="left"
DURATION=0.2
BEZIER=".28,.58,.99,.37"
AWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# Start daemon only if not already running
if ! pgrep -x "awww-daemon" >/dev/null; then
    awww-daemon &>/dev/null &
    disown
    sleep 0.3
fi

awww img "${Wallpaper}" $AWWW_PARAMS

ln -sf "$Wallpaper" "$cache_dir/current_wallpaper.png"

sleep 0.5
"$scripts_dir/wallcache.sh"
"$scripts_dir/pywal.sh"
