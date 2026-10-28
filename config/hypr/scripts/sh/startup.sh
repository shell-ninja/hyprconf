#!/usr/bin/env bash

scripts_dir="$HOME/.hyprconf/hypr/scripts"
sh_dir="$scripts_dir/sh"
py_dir="$scripts_dir/py"
cache_dir="$HOME/.local/share/hyprconf/.cache"
[[ ! -d "$cache_dir" && -d "$HOME/.hyprconf/hypr/.cache" ]] && cache_dir="$HOME/.hyprconf/hypr/.cache"
wallpaper="$cache_dir/current_wallpaper.png"
welcome_app="$sh_dir/qs-welcome.sh"

# Transition config
FPS=120
TYPE="any"
DURATION=1
BEZIER=".28,.58,.99,.37"
AWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

if command -v awww &> /dev/null; then
    ENGINE=awww
elif command -v swww &> /dev/null; then
    ENGINE=swww
fi


if [[ -f "$welcome_app" ]]; then
    "$welcome_app" --autostart &
fi

if [[ -f "$cache_dir/.live_wallpaper" ]]; then
    live_wall=$(cat "$cache_dir/.live_wallpaper" 2>/dev/null)
    if [[ -n "$live_wall" && -f "$live_wall" ]]; then
        "$sh_dir/Wallpaper.sh" --live "$live_wall"
    elif [[ -f "$wallpaper" ]]; then
        ${ENGINE}-daemon &
        ${ENGINE} img $wallpaper $AWWW_PARAMS
    else
        "$sh_dir/Wallpaper.sh"
    fi
elif [[ -f "$wallpaper" ]]; then
    ${ENGINE}-daemon &
    ${ENGINE} img $wallpaper $AWWW_PARAMS
else
    "$sh_dir/Wallpaper.sh"
fi

# if openbangla keyboard is installed, the
if [[ -d "/usr/share/openbangla-keyboard" ]]; then
    fcitx5 &> /dev/null
fi


"$sh_dir/notification.sh" sys

# Start clipboard history daemon with cliphist
if command -v wl-paste &>/dev/null && command -v cliphist &>/dev/null; then
    if ! pgrep -f "cliphist store" >/dev/null 2>&1; then
        wl-paste --watch cliphist store &>/dev/null &
        wl-paste --type image --watch cliphist store &>/dev/null &
    fi
fi

