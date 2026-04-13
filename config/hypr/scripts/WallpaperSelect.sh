#!/bin/bash
# WallpaperSelect.sh — Select a wallpaper via rofi and apply it.

scripts_dir="$HOME/.config/hypr/scripts"
wallDIR="$HOME/.config/hypr/Wallpaper"
cache_dir="$HOME/.config/hypr/.cache"
wallCache="$cache_dir/.wallpaper"
engine_file="$cache_dir/.engine"
engine=$(cat "$engine_file" 2>/dev/null)

[[ ! -f "$wallCache" ]] && touch "$wallCache"

# Transition config
FPS=120
TYPE="any"
DURATION=1
BEZIER=".28,.58,.99,.37"
AWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# Safely retrieve image files (handles spaces via find + NUL delimiters)
mapfile -d '' _PICS_FULL < <(find "$wallDIR" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) -print0)

# Build basename-only array for display (rofi operates on names)
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
esac

# No choice → exit
[[ -z "$choice" ]] && exit 0

if ! pgrep -x "awww-daemon" > /dev/null; then
    awww-daemon &>/dev/null &
    disown
    sleep 0.5
fi

# Random choice
if [[ "$choice" == "$RANDOM_PIC_NAME" ]]; then
    awww img "$RANDOM_PIC" $AWWW_PARAMS
    ln -sf "$RANDOM_PIC" "$cache_dir/current_wallpaper.png"
    baseName="$(basename "$RANDOM_PIC")"
    wallName="${baseName%.*}"
    echo "$wallName" > "$wallCache"
else
    # Match by stem (name without extension)
    selected_full=""
    for i in "${!PICS[@]}"; do
        stem="${PICS[$i]%.*}"
        if [[ "$stem" == "$choice" ]]; then
            selected_full="${_PICS_FULL[$i]}"
            break
        fi
    done

    if [[ -z "$selected_full" ]]; then
        echo "Image not found."
        exit 1
    fi

    awww img "$selected_full" $AWWW_PARAMS
    ln -sf "$selected_full" "$cache_dir/current_wallpaper.png"
    baseName="$(basename "$selected_full")"
    wallName="${baseName%.*}"
    echo "$wallName" > "$wallCache"
fi

"$scripts_dir/wallcache.sh" &
"$scripts_dir/pywal.sh"
