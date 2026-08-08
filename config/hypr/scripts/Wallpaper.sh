#!/bin/bash
# Wallpaper.sh — Pick a random wallpaper and apply it.

scripts_dir="$HOME/.hyprconf/hypr/scripts"
cache_dir="$HOME/.hyprconf/hypr/.cache"
wallCache="$cache_dir/.wallpaper"
wallpaper_dir="$HOME/.hyprconf/hypr/Wallpaper"

[[ ! -f "$wallCache" ]] && touch "$wallCache"

# Detect wallpaper engine
if command -v awww >/dev/null 2>&1; then
    ENGINE="awww"
elif command -v swww >/dev/null 2>&1; then
    ENGINE="swww"
else
    notify-send "Wallpaper Error" "Neither awww nor swww is installed."
    exit 1
fi

# Use mapfile+find to correctly handle filenames with spaces
mapfile -d '' PICS < <(
    find "$wallpaper_dir" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) -print0
)

# No wallpapers found
if [[ ${#PICS[@]} -eq 0 ]]; then
    notify-send "Wallpaper Error" "No wallpapers found in $wallpaper_dir"
    exit 1
fi

wallpaper="${PICS[RANDOM % ${#PICS[@]}]}"

# Transition config
FPS=120
TYPE="any"
DURATION=1
BEZIER=".28,.58,.99,.37"

AWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# Start daemon if needed
start_daemon() {
    if ! pgrep -x "${ENGINE}-daemon" >/dev/null; then
        ${ENGINE}-daemon &>/dev/null &
        disown
        sleep 0.5
    fi
}

# Apply wallpaper
set_wallpaper() {
    local img="$1"

    ${ENGINE} img "$img" $AWWW_PARAMS

    ln -sf "$img" "$cache_dir/current_wallpaper.png"

    baseName="$(basename "$img")"
    wallName="${baseName%.*}"

    echo "$wallName" > "$wallCache"
}

start_daemon
set_wallpaper "$wallpaper"

"$scripts_dir/wallcache.sh" &
"$scripts_dir/pywal.sh"
