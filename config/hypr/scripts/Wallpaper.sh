#!/usr/bin/env bash
# Wallpaper.sh — Set a specific wallpaper or pick a random one, and apply everywhere.

scripts_dir="$HOME/.hyprconf/hypr/scripts"
cache_dir="$HOME/.hyprconf/hypr/.cache"
wallCache="$cache_dir/.wallpaper"
wallpaper_dir="$HOME/.hyprconf/hypr/Wallpaper"

mkdir -p "$cache_dir"
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

# Transition config
FPS=120
TYPE="any"
DURATION=1
BEZIER=".28,.58,.99,.37"
AWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# Determine target wallpaper
target_wallpaper=""

if [[ "$1" == "set" ]]; then
    if [[ -n "$2" ]]; then
        target_wallpaper="$2"
    elif [[ -n "$NOCTALIA_WALLPAPER_PATH" ]]; then
        target_wallpaper="$NOCTALIA_WALLPAPER_PATH"
    fi
elif [[ -n "$1" && -f "$1" ]]; then
    target_wallpaper="$1"
elif [[ -n "$NOCTALIA_WALLPAPER_PATH" && -f "$NOCTALIA_WALLPAPER_PATH" ]]; then
    target_wallpaper="$NOCTALIA_WALLPAPER_PATH"
fi

# Expand tilde if present
target_wallpaper="${target_wallpaper/#\~/$HOME}"

# If no valid target specified, pick a random wallpaper
if [[ -z "$target_wallpaper" || ! -f "$target_wallpaper" ]]; then
    mapfile -d '' PICS < <(
        find "$wallpaper_dir" -maxdepth 1 -type f \
        \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) \
        -print0
    )

    if [[ ${#PICS[@]} -eq 0 ]]; then
        notify-send "Wallpaper Error" "No wallpapers found in $wallpaper_dir"
        exit 1
    fi

    target_wallpaper="${PICS[RANDOM % ${#PICS[@]}]}"
fi

# Start daemon if not already running
start_daemon() {
    if ! pgrep -x "${ENGINE}-daemon" >/dev/null 2>&1; then
        ${ENGINE}-daemon &>/dev/null &
        disown
        sleep 0.5
    fi
}

# Apply wallpaper with engine
start_daemon
${ENGINE} img "$target_wallpaper" $AWWW_PARAMS

# Update cache and symlink
ln -sf "$target_wallpaper" "$cache_dir/current_wallpaper.png"
baseName="$(basename "$target_wallpaper")"
echo "${baseName%.*}" > "$wallCache"

# Notify Noctalia shell if active (skip if already invoked from Noctalia wallpaper_changed hook)
if pgrep -x "noctalia" >/dev/null 2>&1 && [[ -z "$NOCTALIA_WALLPAPER_PATH" ]]; then
    noctalia msg wallpaper-set "$target_wallpaper" &>/dev/null || true
fi

# Apply dynamic colors to Kitty, Hyprland, etc.
"$scripts_dir/noctalia-colors.py" "$target_wallpaper"
