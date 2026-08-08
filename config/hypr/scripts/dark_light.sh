#!/bin/bash
# dark_light.sh — Toggle between dark and light mode.

mode_file="$HOME/.config/hypr/.cache/.current_mode"
next_mode_file="$HOME/.config/hypr/.cache/.next_mode"
scripts_dir="$HOME/.config/hypr/scripts"
cache_dir="$HOME/.config/hypr/.cache"

# Initialise mode files if missing
[[ ! -f "$mode_file" ]]      && echo "dark"  > "$mode_file"
[[ ! -f "$next_mode_file" ]] && echo "light" > "$next_mode_file"

# Transition config
FPS=60
TYPE="outer"
DURATION=2
BEZIER=".43,1.19,1,.4"
AWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

next_mode=$(cat "$next_mode_file")
walldir="$HOME/.config/hypr/Wallpaper/${next_mode}"
wallName=$(cat "$HOME/.config/hypr/.cache/.wallpaper")

set_wallpaper() {
    local dir="$1"
    local wallpaper

    if [[ -f "${dir}/${wallName}" ]]; then
        wallpaper="${dir}/${wallName}"
    else
        mapfile -d '' wallpaper_files < <(find "$dir" -maxdepth 1 -type f -print0)
        [[ ${#wallpaper_files[@]} -eq 0 ]] && { echo "No wallpapers in $dir"; return 1; }
        wallpaper="${wallpaper_files[RANDOM % ${#wallpaper_files[@]}]}"
    fi

    # Ensure awww daemon is running, then set wallpaper
    awww query &>/dev/null || { awww-daemon &>/dev/null & disown; sleep 0.2; }
    awww img "$wallpaper" $AWWW_PARAMS

    ln -sf "$wallpaper" "$HOME/.config/hypr/.cache/current_wallpaper.png"
    baseName="$(basename "$wallpaper")"
    echo "${next_mode}_${baseName%.*}" > "$HOME/.config/hypr/.cache/.wallpaper"
}

if [[ "$next_mode" == "light" ]]; then
    notify-send "Mode" "Changing to Light" -t 1500

    sed -i \
        -e 's/mocha/latte/g' \
        "$HOME/.config/nvim/lua/shell-ninja/plugins/colorscheme.lua"
    sed -i \
        -e 's/rgba(0, 0, 0, 0.5)/rgba(255, 255, 255, 0.5)/g' \
        "$HOME/.config/waybar/style/fancy-top.css" \
        "$HOME/.config/waybar/style/full-top.css"

    gsettings set org.gnome.desktop.interface gtk-theme "Religh"
    crudini --set "$HOME/.config/Kvantum/kvantum.kvconfig" General theme "Relax-Light-Kvantum"

    set_wallpaper "$walldir"
    echo "dark"  > "$next_mode_file"
    echo "light" > "$mode_file"

elif [[ "$next_mode" == "dark" ]]; then
    notify-send "Mode" "Changing to Dark" -t 1500

    sed -i \
        -e 's/latte/mocha/g' \
        "$HOME/.config/nvim/lua/shell-ninja/plugins/colorscheme.lua"
    sed -i \
        -e 's/rgba(255, 255, 255, 0.5)/rgba(0, 0, 0, 0.5)/g' \
        "$HOME/.config/waybar/style/fancy-top.css" \
        "$HOME/.config/waybar/style/full-top.css"

    gsettings set org.gnome.desktop.interface gtk-theme "TokyoNight"
    crudini --set "$HOME/.config/Kvantum/kvantum.kvconfig" General theme "Dracula"

    set_wallpaper "$walldir"
    echo "light" > "$next_mode_file"
    echo "dark"  > "$mode_file"
fi

"$scripts_dir/wallcache.sh" &
"$scripts_dir/pywal.sh"
