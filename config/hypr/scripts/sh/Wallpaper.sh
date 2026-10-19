#!/usr/bin/env bash
# Wallpaper.sh — Set a specific wallpaper or pick a random one, and apply everywhere.

scripts_dir="$HOME/.hyprconf/hypr/scripts"
sh_dir="$scripts_dir/sh"
py_dir="$scripts_dir/py"
cache_dir="$HOME/.hyprconf/hypr/.cache"
wallCache="$cache_dir/.wallpaper"
liveWallCache="$cache_dir/.live_wallpaper"
wallpaper_dir="$HOME/.hyprconf/hypr/Wallpaper"
config_file="$cache_dir/wallpaper_config.json"
if [[ -f "$config_file" ]]; then
    saved_dir=$(grep -oP '"wallpaper_dir"\s*:\s*"\K[^"]+' "$config_file" 2>/dev/null || true)
    if [[ -n "$saved_dir" && -d "$saved_dir" ]]; then
        wallpaper_dir="$saved_dir"
    fi
fi

mkdir -p "$cache_dir"
[[ ! -f "$wallCache" ]] && touch "$wallCache"

# Detect static wallpaper engine
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

# Parse arguments
target_wallpaper=""
live_mode=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --live|live|-l)
            live_mode=1
            shift
            ;;
        --static|static|-s)
            live_mode=0
            shift
            ;;
        --engine|-e)
            if [[ "$2" == "mpvpaper" ]]; then
                live_mode=1
            fi
            shift 2
            ;;
        set)
            target_wallpaper="$2"
            shift 2
            ;;
        restore)
            if [[ -f "$liveWallCache" ]]; then
                live_target=$(cat "$liveWallCache" 2>/dev/null)
                if [[ -n "$live_target" && -f "$live_target" ]]; then
                    target_wallpaper="$live_target"
                    live_mode=1
                fi
            fi
            if [[ -z "$target_wallpaper" && -f "$cache_dir/current_wallpaper.png" ]]; then
                target_wallpaper="$cache_dir/current_wallpaper.png"
            fi
            shift
            ;;
        *)
            if [[ -z "$target_wallpaper" ]]; then
                target_wallpaper="$1"
            fi
            shift
            ;;
    esac
done

# Expand tilde if present
target_wallpaper="${target_wallpaper/#\~/$HOME}"

# If no valid target specified, pick a random wallpaper
if [[ -z "$target_wallpaper" || ! -f "$target_wallpaper" ]]; then
    if [[ $live_mode -eq 1 ]]; then
        live_dir=$(grep -oP '"live_dir"\s*:\s*"\K[^"]+' "$config_file" 2>/dev/null || true)
        [[ -z "$live_dir" || ! -d "$live_dir" ]] && live_dir="$HOME/.hyprconf/hypr/Wallpaper/Live"
        [[ ! -d "$live_dir" ]] && live_dir="$wallpaper_dir"
        mapfile -d '' PICS < <(
            find "$live_dir" -maxdepth 1 -type f \
            \( -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" -o -iname "*.gif" \) \
            -print0
        )
    else
        mapfile -d '' PICS < <(
            find "$wallpaper_dir" -maxdepth 1 -type f \
            \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
            -print0
        )
    fi

    if [[ ${#PICS[@]} -eq 0 ]]; then
        notify-send "Wallpaper Error" "No wallpapers found in directory"
        exit 1
    fi

    target_wallpaper="${PICS[RANDOM % ${#PICS[@]}]}"
fi

# Detect if target is video/animated format
filename="$(basename "$target_wallpaper")"
ext="${filename##*.}"
ext_lower="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"

if [[ "$ext_lower" =~ ^(mp4|mkv|webm|avi|mov|flv)$ ]]; then
    live_mode=1
elif [[ "$ext_lower" == "gif" && $live_mode -eq 1 ]]; then
    live_mode=1
fi

# Start daemon if not already running
start_daemon() {
    if ! pgrep -x "${ENGINE}-daemon" >/dev/null 2>&1; then
        ${ENGINE}-daemon &>/dev/null &
        disown
        sleep 0.5
    fi
}

if [[ $live_mode -eq 1 ]]; then
    # ── LIVE / VIDEO / MP4 / GIF WALLPAPER VIA MPVPAPER ──────────────────────
    if ! command -v mpvpaper >/dev/null 2>&1; then
        notify-send "Live Wallpaper Error" "mpvpaper is not installed on this system."
        exit 1
    fi

    # 1. Terminate any previous mpvpaper processes or units
    systemctl --user stop mpvpaper 2>/dev/null || true
    pkill -x mpvpaper 2>/dev/null || true

    # 2. Extract snapshot frame to current_wallpaper.png for system color palettes & fallback
    if [[ "$ext_lower" =~ ^(mp4|mkv|webm|avi|mov|flv)$ ]]; then
        ffmpeg -y -ss 00:00:01 -i "$target_wallpaper" -frames:v 1 -q:v 2 "$cache_dir/current_wallpaper.png" &>/dev/null || \
        ffmpeg -y -i "$target_wallpaper" -frames:v 1 -q:v 2 "$cache_dir/current_wallpaper.png" &>/dev/null
    elif [[ "$ext_lower" == "gif" ]]; then
        ffmpeg -y -i "$target_wallpaper" -frames:v 1 -q:v 2 "$cache_dir/current_wallpaper.png" &>/dev/null || \
        magick "${target_wallpaper}[0]" "$cache_dir/current_wallpaper.png" &>/dev/null
    fi

    # 3. Update cache indicators
    baseName="${filename%.*}"
    echo "$baseName" > "$wallCache"
    echo "$target_wallpaper" > "$liveWallCache"

    # Persist in config JSON
    python3 -c "
import json, os
p = os.path.expanduser('~/.hyprconf/hypr/.cache/wallpaper_config.json')
try:
    d = json.load(open(p)) if os.path.exists(p) else {}
except Exception:
    d = {}
d['mode'] = 'live'
d['live_wallpaper'] = '''$target_wallpaper'''
with open(p, 'w') as f:
    json.dump(d, f, indent=2)
" 2>/dev/null || true

    # 4. Display the static frame in background via awww/swww so underlying layer is clean
    start_daemon
    if [[ -f "$cache_dir/current_wallpaper.png" ]]; then
        ${ENGINE} img "$cache_dir/current_wallpaper.png" $AWWW_PARAMS &>/dev/null || true
    fi

    # 5. Launch mpvpaper via systemd-run or background with auto-pause on occlusion and hardware acceleration
    if command -v systemd-run >/dev/null 2>&1; then
        systemd-run --user --unit=mpvpaper mpvpaper -p -o "no-audio --loop-playlist --hwdec=auto" '*' "$target_wallpaper" &>/dev/null
    else
        nohup mpvpaper -p -o "no-audio --loop-playlist --hwdec=auto" '*' "$target_wallpaper" &>/dev/null &
        disown
    fi

    # 6. Synchronize theme colors and caches
    if [[ -f "$cache_dir/current_wallpaper.png" ]]; then
        "$sh_dir/wallcache.sh" &>/dev/null &
        "$py_dir/hypr-colors.py" "$cache_dir/current_wallpaper.png"
    fi

    qs ipc -c island call island reloadWallpaper 2>/dev/null || true
    notify-send -a "Wallpaper" -i "video-x-generic" "Live Wallpaper Applied" "$filename"

else
    # ── STATIC WALLPAPER VIA AWWW / SWWW ─────────────────────────────────────
    # Kill any active mpvpaper instance or systemd unit
    systemctl --user stop mpvpaper 2>/dev/null || true
    pkill -x mpvpaper 2>/dev/null || true
    rm -f "$liveWallCache"

    # Persist in config JSON
    python3 -c "
import json, os
p = os.path.expanduser('~/.hyprconf/hypr/.cache/wallpaper_config.json')
try:
    d = json.load(open(p)) if os.path.exists(p) else {}
except Exception:
    d = {}
d['mode'] = 'static'
d['live_wallpaper'] = ''
with open(p, 'w') as f:
    json.dump(d, f, indent=2)
" 2>/dev/null || true

    start_daemon
    ${ENGINE} img "$target_wallpaper" $AWWW_PARAMS

    # Update cache and symlink
    ln -sf "$target_wallpaper" "$cache_dir/current_wallpaper.png"
    baseName="${filename%.*}"
    echo "$baseName" > "$wallCache"

    # Generate thumbnail and quad cache in background
    "$sh_dir/wallcache.sh" &>/dev/null &

    # Synchronize theme colors across Quickshell projects, Hyprland, Kitty & Qt (SYNCHRONOUS)
    "$py_dir/hypr-colors.py" "$target_wallpaper"

    # Trigger instant wallpaper reload in running Quickshell Island
    qs ipc -c island call island reloadWallpaper 2>/dev/null || true
    notify-send -a "Wallpaper" -i "$cache_dir/current_wallpaper.png" "Wallpaper Applied" "$filename"
fi
