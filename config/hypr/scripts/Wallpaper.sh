#!/bin/bash

scripts_dir="$HOME/.config/hypr/scripts"
themes_dir="$HOME/.config/hypr/.cache/colors"
cache_dir="$HOME/.config/hypr/.cache"
wallCache="$cache_dir/.wallpaper"
wallpaper_dir="$HOME/.config/hypr/Wallpaper"

[[ ! -f "$wallCache" ]] && touch "$wallCache"

PICS=($(find ${wallpaper_dir} -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \)))
wallpaper=${PICS[ $RANDOM % ${#PICS[@]} ]}

# Transition config
FPS=120
TYPE="any"
DURATION=1
BEZIER=".28,.58,.99,.37"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

swww-daemon &
swww img ${wallpaper} $SWWW_PARAMS

ln -sf "$wallpaper" "$cache_dir/current_wallpaper.png"

baseName="$(basename $wallpaper)"
wallName=${baseName%.*}
echo "$wallName" > "$wallCache"

sleep 0.5
"$scripts_dir/wallcache.sh"
"$scripts_dir/pywal.sh"
