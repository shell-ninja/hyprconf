#!/bin/bash

scripts_dir="$HOME/.config/hypr/scripts"
themes_dir="$HOME/.config/hypr/.cache/colors"
cache_dir="$HOME/.config/hypr/.cache"
engine_file="$cache_dir/.engine"
wallCache="$cache_dir/.wallpaper"
wallpaper_dir="$HOME/.config/hypr/Wallpaper"
engine=$(cat "$engine_file")

[[ ! -f "$wallCache" ]] && touch "$wallCache"
[[ ! -d "$themes_dir" ]] && mkdir -p "$themes_dir"

if [[ "$engine" == "swww" ]]; then

        PICS=($(find ${wallpaper_dir} -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \)))
        wallpaper=${PICS[ $RANDOM % ${#PICS[@]} ]}


        # Transition config
        FPS=60
        TYPE="random"
        DURATION=1
        BEZIER=".43,1.19,1,.4"
        SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

        notify-send --replace-id=1 -i "${wallpaper}" "Changing wallpaper" -h int:value:75
        swww query || swww init && swww img ${wallpaper} $SWWW_PARAMS

        ln -sf "$wallpaper" "$cache_dir/current_wallpaper.png"

        baseName="$(basename $wallpaper)"
        wallName=${baseName%.*}
        echo "$wallName" > "$wallCache"

        if [[ ! -d "${themes_dir}/${wallName}-colors" ]]; then 
            wal -q -i "$wallpaper"
            mv "$HOME/.cache/wal" "${themes_dir}/${wallName}-colors"
        fi
        # rm -rf "$HOME/.cache/wal"

elif [[ "$engine" == "hyprpaper" ]]; then

        # Get a random wallpaper from the directory
        wallpaper=$(find "$wallpaper_dir" -type f | shuf -n 1)

        # Check if a wallpaper was found
        if [ -z "$wallpaper" ]; then
        echo "No wallpapers found in $wallpaper_dir"
        exit 1
        fi

        # Ensure hyprpaper is running
        if ! pgrep -x hyprpaper > /dev/null; then
        hyprpaper -c ~/.config/hypr/hyprpaper.conf &
        sleep 2  # give hyprpaper some time to start
        fi

        # Preload the wallpaper
        hyprctl hyprpaper preload "$wallpaper"
        if [ $? -ne 0 ]; then
        echo "Failed to preload wallpaper"
        exit 1
        fi

        # Set the wallpaper using hyprpaper
        notify-send --replace-id=1 -i "${wallpaper}" "Changing wallpaper" -h int:value:75
        hyprctl hyprpaper wallpaper " ,$wallpaper"
        ln -sf "$wallpaper" "$cache_dir/current_wallpaper.png"
        
        baseName="$(basename $wallpaper)"
        wallName=${baseName%.*}
        echo "$wallName" > "$wallCache"

        if [[ ! -d "${themes_dir}/${wallName}-colors" ]]; then 
            wal -q -i "$wallpaper"
            cp -r "$HOME/.cache/wal" "${themes_dir}/${wallName}-colors"
        fi
        # rm -rf "$HOME/.cache/wal"

        hyprctl reload
        if [ $? -ne 0 ]; then
        echo "Failed to set wallpaper"
        exit 1
        fi
fi

sleep 0.5
"$scripts_dir/wallcache.sh"
"$scripts_dir/pywal.sh"
