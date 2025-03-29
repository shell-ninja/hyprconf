#!/bin/bash

if [ -z "$XDG_PICTURES_DIR" ] ; then
    XDG_PICTURES_DIR="$HOME/Pictures"
fi

swpy_dir="$HOME/.config/swappy"
save_dir="${2:-$XDG_PICTURES_DIR/Screenshots}"
save_file=$(date +'screenshot_%y%m%d_%H%M%S.png')
temp_screenshot="/tmp/screenshot.png"

mkdir -p $save_dir
mkdir -p $swpy_dir
echo -e "[Default]\nsave_dir=$save_dir\nsave_filename_format=$save_file" > $swpy_dir/config

function print_error
{
cat << "EOF"
    ./screenshot.sh <action>
    ...valid actions are...
        p : print all screens
        s : snip current screen
EOF
}

option1="Fullscreen (delay 3 sec)"
option2="Selected area"

options="$option1\n$option2"

choice=$(echo -e "$options" | rofi -dmenu -replace -config ~/.config/rofi/themes/rofi-screenshots.rasi -i -no-show-icons -l 2 -width 30 -p)

send_notification() {
    local msg="$1"
    notify-send -e "Taking Screenshot in" "$msg"
    sleep 1
    pkill dunst
}

case $choice in
    $option1)  # full area, 3 sec delay.
        for time in 3 2 1; do
            send_notification "$time"
        done
        sleep 1
        grimblast copysave screen $temp_screenshot && swappy -f $temp_screenshot
        ;;
    $option2)  # drag to manually snip an area / click on a window to print it
        grimblast --freeze copysave area $temp_screenshot && swappy -f $temp_screenshot 
        sleep 0.5
        ;;
    *)  # invalid option
        print_error ;;
esac

rm "$temp_screenshot"

if [ -f "$save_dir/$save_file" ] ; then
    notify-send "saved in" "$save_dir" -i "$save_dir/$save_file" -r 91190 -t 2200
fi
