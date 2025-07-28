#!/bin/bash

mode_file="$HOME/.config/hypr/.cache/.current_mode"
next_mode_file="$HOME/.config/hypr/.cache/.next_mode"
scripts_dir="$HOME/.config/hypr/scripts"
cache_dir="$HOME/.config/hypr/.cache"
engine_file="$cache_dir/.engine"

# Create the mode file if it doesn't exist
[[ ! -f "$mode_file" ]] && touch "$mode_file" && echo "dark" > "$mode_file"
[[ ! -f "$next_mode_file" ]] && touch "$next_mode_file" && echo "light" > "$next_mode_file"

# Transition config
FPS=60
TYPE="outer"
DURATION=2
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# Read the current mode and wallpaper engine
current_mode=$(cat "$mode_file")
next_mode=$(cat "$next_mode_file")
walldir="$HOME/.config/hypr/Wallpaper/${next_mode}"
wallName=$(cat "$HOME/.config/hypr/.cache/.wallpaper")

set_wallpaper() {
    wallpaper_files=("$1"/*)
    if [[ -f "${walldir}/${wallName}" ]]; then
        wallpaper="${walldir}/${wallName}"
    else
        wallpaper="${wallpaper_files[RANDOM % ${#wallpaper_files[@]}]}"
    fi

    swww query || swww init && swww img ${wallpaper} $SWWW_PARAMS

    ln -sf "$wallpaper" "$HOME/.config/hypr/.cache/current_wallpaper.png"

    baseName="$(basename $wallpaper)"
    wallpaperName=${baseName%.*}
    echo "${next_mode}_$wallpaperName" > "$HOME/.config/hypr/.cache/.wallpaper"
}


if [ "$next_mode" == "light" ]; then
    # Switch to light mode
    
    notify-send "Mode" "changing to Light" -t 1500

    # setting neovim and waybar colors
    sed -i 's/mocha/latte/g' "$HOME/.config/nvim/lua/shell-ninja/plugins/colorscheme.lua"
    sed -i 's/rgba(0, 0, 0, 0.5)/rgba(255, 255, 255, 0.5)/g' "$HOME/.config/waybar/style/fancy-top.css"
    sed -i 's/rgba(0, 0, 0, 0.5)/rgba(255, 255, 255, 0.5)/g' "$HOME/.config/waybar/style/full-top.css"

    # gtk theme
    gsettings set org.gnome.desktop.interface gtk-theme "Religh"
    crudini --set "$HOME/.config/Kvantum/kvantum.kvconfig" General theme "Relax-Light-Kvantum"


    # switch wallpaper
    set_wallpaper "$walldir"
    echo "dark" > "$next_mode_file"
    echo "light" > "$mode_file"

elif [[ "$next_mode" == "dark" ]]; then
    # Switch to dark mode

    notify-send "Mode" "changing to Dark" -t 1500

    # setting neovim and waybar colors
    sed -i 's/latte/mocha/g' "$HOME/.config/nvim/lua/shell-ninja/plugins/colorscheme.lua"
    sed -i 's/rgba(255, 255, 255, 0.5)/rgba(0, 0, 0, 0.5)/g' "$HOME/.config/waybar/style/fancy-top.css"
    sed -i 's/rgba(255, 255, 255, 0.5)/rgba(0, 0, 0, 0.5)/g' "$HOME/.config/waybar/style/full-top.css"

    # gtk theme
    gsettings set org.gnome.desktop.interface gtk-theme "TokyoNight"
    crudini --set "$HOME/.config/Kvantum/kvantum.kvconfig" General theme "Dracula"

    # switch wallpaper
    set_wallpaper "$walldir"
    echo "light" > "$next_mode_file"
    echo "dark" > "$mode_file"
fi

sleep 0.5
"$scripts_dir/wallcache.sh"
"$scripts_dir/pywal.sh"
