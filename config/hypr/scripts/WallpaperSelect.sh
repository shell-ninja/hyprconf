#!/bin/bash
# WallpaperSelect.sh — Select a wallpaper via rofi and apply it.

scripts_dir="$HOME/.config/hypr/scripts"
wallDIR="$HOME/.config/hypr/Wallpaper"
cache_dir="$HOME/.config/hypr/.cache"
wallCache="$cache_dir/.wallpaper"

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

# Safely retrieve image files
mapfile -d '' _PICS_FULL < <(
    find "$wallDIR" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) -print0
)

# Exit if no wallpapers found
[[ ${#_PICS_FULL[@]} -eq 0 ]] && exit 1

# Build basename-only array
PICS=()
for p in "${_PICS_FULL[@]}"; do
    PICS+=("$(basename "$p")")
done

RANDOM_PIC="${_PICS_FULL[RANDOM % ${#_PICS_FULL[@]}]}"
RANDOM_PIC_NAME="${#PICS[@]}. random"

# Rofi commands
rofi_command1="rofi -show -dmenu -config ~/.config/rofi/themes/rofi-wall.rasi"
rofi_command2="rofi -show -dmenu -config ~/.config/rofi/themes/rofi-wall-2.rasi"

menu() {
    for i in "${!PICS[@]}"; do
        name="${PICS[$i]}"
        full="${_PICS_FULL[$i]}"

        if [[ "$name" != *.gif ]]; then
            printf "%s\x00icon\x1f%s\n" "${name%.*}" "$full"
        else
            printf "%s\n" "$name"
        fi
    done

    printf "%s\n" "$RANDOM_PIC_NAME"
}

case $1 in
    thm1) choice=$(menu | ${rofi_command1}) ;;
    thm2) choice=$(menu | ${rofi_command2}) ;;
    *) choice=$(menu | ${rofi_command1}) ;;
esac

# No choice → exit
[[ -z "$choice" ]] && exit 0

# Start daemon if needed
start_daemon() {
    if ! pgrep -x ${ENGINE}-daemon >/dev/null; then
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

# Random choice
if [[ "$choice" == "$RANDOM_PIC_NAME" ]]; then
    set_wallpaper "$RANDOM_PIC"
else
    # Match by stem
    selected_full=""

    for i in "${!PICS[@]}"; do
        stem="${PICS[$i]%.*}"

        if [[ "$stem" == "$choice" ]]; then
            selected_full="${_PICS_FULL[$i]}"
            break
        fi
    done

    if [[ -z "$selected_full" ]]; then
        notify-send "Wallpaper Error" "Image not found."
        exit 1
    fi

    set_wallpaper "$selected_full"
fi

"$scripts_dir/wallcache.sh" &
"$scripts_dir/pywal.sh"
