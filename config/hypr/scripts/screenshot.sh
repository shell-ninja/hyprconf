#!/usr/bin/env bash

if [ -z "$XDG_PICTURES_DIR" ]; then
    XDG_PICTURES_DIR="$HOME/Pictures"
fi

sound_file="/usr/share/sounds/freedesktop/stereo/screen-capture.oga"
save_dir="$XDG_PICTURES_DIR/Screenshots"
save_file=$(date +'hyprland_screenshot_%y%m%d_%H%M%S.png')
temp_screenshot=$(mktemp --suffix=.png /tmp/screenshot_XXXXXX)

mkdir -p "$save_dir"

ss_sound() {
    [[ -f "$sound_file" ]] && paplay "$sound_file"
}

# Join all arguments or default to "Selected Area" if empty
selection="${*:-Selected Area}"

case "$selection" in
    [Ff]ull*|--full|-f|screen|Screen)
        sleep 0.5
        grimblast copysave screen "$temp_screenshot" && ss_sound && \
        satty --filename "$temp_screenshot" --output-filename "$save_dir/$save_file" --early-exit
        ;;
    [Ss]elect*|[Aa]rea*|--area|-a|--region|-r)
        sleep 0.5
        grimblast --freeze copysave area "$temp_screenshot" && ss_sound && \
        satty --filename "$temp_screenshot" --output-filename "$save_dir/$save_file" --early-exit
        ;;
    *)
        rm -f "$temp_screenshot"
        exit 1
        ;;
esac

[[ -f "$temp_screenshot" ]] && rm -f "$temp_screenshot"

if [ -f "$save_dir/$save_file" ]; then
    notify-send "Screenshot saved in" "$save_dir" -i "$save_dir/$save_file" -r 91190 -t 5000
fi
