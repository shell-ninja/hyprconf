#!/usr/bin/env bash
# WallpaperSelect.sh — Select a wallpaper and apply it.
# Uses Noctalia's built-in wallpaper panel when noctalia is running, or falls back to interactive selector.

scripts_dir="$HOME/.hyprconf/hypr/scripts"
wallDIR="$HOME/.hyprconf/hypr/Wallpaper"

# ── If Noctalia is running, delegate to its native wallpaper panel ─────────────
if pgrep -x "noctalia" > /dev/null 2>&1; then
    noctalia msg panel-toggle wallpaper
    exit 0
fi

# ── Fallback when Noctalia is not running ─────────────────────────────────────
mapfile -d '' _PICS_FULL < <(
    find "$wallDIR" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) \
    -print0
)
[[ ${#_PICS_FULL[@]} -eq 0 ]] && { notify-send "Wallpaper Error" "No wallpapers found in $wallDIR"; exit 1; }

# Rofi, Fuzzel, or random fallback
if command -v rofi >/dev/null 2>&1; then
    menu_items=()
    for p in "${_PICS_FULL[@]}"; do
        base="$(basename "$p")"
        stem="${base%.*}"
        menu_items+=("$stem\x00icon\x1f$p")
    done
    menu_items+=("Random Wallpaper")

    chosen=$(printf "%b\n" "${menu_items[@]}" | rofi -dmenu -i -p "Select Wallpaper")
    [[ -z "$chosen" ]] && exit 0

    if [[ "$chosen" == "Random Wallpaper" ]]; then
        "$scripts_dir/Wallpaper.sh"
    else
        for p in "${_PICS_FULL[@]}"; do
            base="$(basename "$p")"
            stem="${base%.*}"
            if [[ "$stem" == "$chosen" ]]; then
                "$scripts_dir/Wallpaper.sh" "$p"
                exit 0
            fi
        done
    fi
elif command -v fuzzel >/dev/null 2>&1; then
    names=()
    for p in "${_PICS_FULL[@]}"; do
        names+=("$(basename "$p")")
    done
    names+=("Random")

    chosen=$(printf "%s\n" "${names[@]}" | fuzzel -d -p "Wallpaper: ")
    [[ -z "$chosen" ]] && exit 0

    if [[ "$chosen" == "Random" ]]; then
        "$scripts_dir/Wallpaper.sh"
    else
        for p in "${_PICS_FULL[@]}"; do
            if [[ "$(basename "$p")" == "$chosen" ]]; then
                "$scripts_dir/Wallpaper.sh" "$p"
                exit 0
            fi
        done
    fi
else
    # Default: pick random
    "$scripts_dir/Wallpaper.sh"
fi
