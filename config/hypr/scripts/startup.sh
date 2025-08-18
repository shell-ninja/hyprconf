#!/bin/bash

scripts_dir="$HOME/.hyprconf/hypr/scripts"
wallpaper="$HOME/.hyprconf/hypr/.cache/current_wallpaper.png"
monitor_config="$HOME/.hyprconf/hypr/configs/monitor.conf"

# Transition config
FPS=120
TYPE="any"
DURATION=1
BEZIER=".28,.58,.99,.37"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

if [[ -f "$wallpaper" ]]; then
    swww-daemon &
    swww img $wallpaper $SWWW_PARAMS
else
    "$scripts_dir/Wallpaper.sh"
fi

# if openbangla keyboard is installed, the
if [[ -d "/usr/share/openbangla-keyboard" ]]; then
    fcitx5 &> /dev/null
fi


"$scripts_dir/notification.sh" sys
"$scripts_dir/wallcache.sh"
"$scripts_dir/pywal.sh"
"$scripts_dir/system.sh" run &


#_____ setup monitor ( updated teh monitor.conf for the high resolution and higher refresh rate )

monitor_setting=$(cat $monitor_config | grep "monitor")
monitor_icon="$HOME/.hyprconf/hypr/icons/monitor.png"
if [[ "$monitor_setting" == "monitor=,preferred, auto, 1" ]]; then
    notify-send -i "$monitor_icon" "Monitor Setup" "A popup for your monitor configuration will appear within 5 seconds." && sleep 5
    kitty --title monitor sh -c "$scripts_dir/monitor.sh"
fi

sleep 3

"$scripts_dir/default_browser.sh"
