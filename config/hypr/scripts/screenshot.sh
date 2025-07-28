#!/bin/bash

if [ -z "$XDG_PICTURES_DIR" ] ; then
    XDG_PICTURES_DIR="$HOME/Pictures"
fi

sound_file="/usr/share/sounds/freedesktop/stereo/screen-capture.oga"
save_dir="${2:-$XDG_PICTURES_DIR/Screenshots}"
save_file=$(date +'screenshot_%y%m%d_%H%M%S.png')
temp_screenshot="/tmp/screenshot.png" # Satty can also read from stdin, but using a temp file fits your current script structure

mkdir -p "$save_dir"

ss_sound() {
    paplay "$sound_file"
}

option1="Fullscreen (delay 3 sec)"
option2="Selected area"

options="$option1\n$option2"

choice=$(echo -e "$options" | rofi -dmenu -replace -config ~/.config/rofi/themes/rofi-screenshots.rasi -i -no-show-icons -l 2 -width 30 -p)

send_notification() {
    local msg="$1"
    notify-send -e "Taking Screenshot in" "$msg"
    sleep 1
    # pkill dunst
    pkill swaync
}

case $choice in
    $option1)  # full area, 3 sec delay.
        for time in 3 2 1; do
            send_notification "$time"
        done
        sleep 1
        grimblast copysave screen "$temp_screenshot" && ss_sound && \
        satty --filename "$temp_screenshot" --output-filename "$save_dir/$save_file" --early-exit
        ;;
    $option2)  # drag to manually snip an area / click on a window to print it
        sleep 0.5 && killall rofi
        grimblast --freeze copysave area "$temp_screenshot" && ss_sound && \
        satty --filename "$temp_screenshot" --output-filename "$save_dir/$save_file" --early-exit
        ;;
esac

# Satty saves directly to the final path, so we don't need to check for the temp file,
# but we still need to remove it after satty has processed it.
rm "$temp_screenshot"

swaync &
