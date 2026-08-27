#!/usr/bin/env bash
# WallpaperSelect.sh — Select a wallpaper and apply it.
# Uses Noctalia's built-in wallpaper panel when noctalia is running.

scripts_dir="$HOME/.hyprconf/hypr/scripts"
wallDIR="$HOME/.hyprconf/hypr/Wallpaper"
cache_dir="$HOME/.hyprconf/hypr/.cache"
wallCache="$cache_dir/.wallpaper"

[[ ! -f "$wallCache" ]] && touch "$wallCache"

# ── If Noctalia is running, delegate to its native wallpaper panel ─────────────
if pgrep -x "noctalia" > /dev/null 2>&1; then
    noctalia msg panel-toggle wallpaper
    exit 0
fi

# ── Fallback: pick manually when noctalia is not running ──────────────────────

# Detect wallpaper engine
if command -v awww > /dev/null 2>&1; then
    ENGINE="awww"
elif command -v swww > /dev/null 2>&1; then
    ENGINE="swww"
else
    notify-send "Wallpaper Error" "Neither awww nor swww is installed."
    exit 1
fi

# Transition config
FPS=120
TYPE="any"
DURATION=1
BEZIER=".28,.58,.99,.37"
AWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# Collect wallpapers
mapfile -d '' _PICS_FULL < <(
    find "$wallDIR" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) \
    -print0
)
[[ ${#_PICS_FULL[@]} -eq 0 ]] && { notify-send "Wallpaper Error" "No wallpapers found."; exit 1; }

# Start daemon if needed
start_daemon() {
    if ! pgrep -x "${ENGINE}-daemon" > /dev/null 2>&1; then
        ${ENGINE}-daemon &>/dev/null &
        disown
        sleep 0.5
    fi
}

# Apply wallpaper
set_wallpaper() {
    local img="$1"
    local base
    base="$(basename "$img")"
    ${ENGINE} img "$img" $AWWW_PARAMS
    ln -sf "$img" "$cache_dir/current_wallpaper.png"
    echo "${base%.*}" > "$wallCache"
}

# Pick a random wallpaper (no UI fallback since rofi is removed)
start_daemon
set_wallpaper "${_PICS_FULL[RANDOM % ${#_PICS_FULL[@]}]}"

# Apply dynamic colors to Kitty, Hyprland, and screen shader
"$scripts_dir/noctalia-colors.sh"
