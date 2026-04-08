#!/bin/bash
# Wallpaper.sh — Pick a random wallpaper and apply it.

scripts_dir="$HOME/.config/hypr/scripts"
cache_dir="$HOME/.config/hypr/.cache"
wallCache="$cache_dir/.wallpaper"
wallpaper_dir="$HOME/.config/hypr/Wallpaper"

[[ ! -f "$wallCache" ]] && touch "$wallCache"

# Use mapfile+find to correctly handle filenames with spaces
mapfile -d '' PICS < <(find "$wallpaper_dir" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) -print0)

if [[ ${#PICS[@]} -eq 0 ]]; then
    echo "No wallpapers found in $wallpaper_dir"
    exit 1
fi

wallpaper="${PICS[RANDOM % ${#PICS[@]}]}"

# Transition config
FPS=120
TYPE="any"
DURATION=1
BEZIER=".28,.58,.99,.37"
AWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# Ensure awww daemon is running
awww-daemon &>/dev/null &
sleep 0.1
awww img "$wallpaper" $AWWW_PARAMS

ln -sf "$wallpaper" "$cache_dir/current_wallpaper.png"

baseName="$(basename "$wallpaper")"
wallName="${baseName%.*}"
echo "$wallName" > "$wallCache"

sleep 0.3
"$scripts_dir/wallcache.sh"
"$scripts_dir/pywal.sh"
