#!/bin/bash

scripts_dir="$HOME/.hyprconf/hypr/scripts"
wallpaper="$HOME/.hyprconf/hypr/.cache/current_wallpaper.png"
monitor_config="$HOME/.hyprconf/hypr/configs/monitor.conf"

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

if [[ -f "$wallpaper" ]]; then
    ${ENGINE}-daemon &
    ${ENGINE} img $wallpaper $AWWW_PARAMS
else
    "$scripts_dir/Wallpaper.sh"
fi

# if openbangla keyboard is installed, the
if [[ -d "/usr/share/openbangla-keyboard" ]]; then
    fcitx5 &> /dev/null
fi


"$scripts_dir/notification.sh" sys
"$scripts_dir/wallcache.sh" &
# "$scripts_dir/pywal.sh"
# "$scripts_dir/nightlight.sh"
"$scripts_dir/system.sh" run &

sleep 1

"$scripts_dir/default_browser.sh"