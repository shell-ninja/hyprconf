#!/usr/bin/env bash
# screenshot.sh — Hyprland obsidian screenshot utility

if [ -z "$XDG_PICTURES_DIR" ]; then
    XDG_PICTURES_DIR="$HOME/Pictures"
fi

sound_file="/usr/share/sounds/freedesktop/stereo/screen-capture.oga"
save_dir="$XDG_PICTURES_DIR/Screenshots"
save_file=$(date +'hyprland_screenshot_%y%m%d_%H%M%S.png')
temp_screenshot=$(mktemp --suffix=.png /tmp/screenshot_XXXXXX)

mkdir -p "$save_dir"

play_sound=true
use_satty=true
delay=0.2

# Parse options
mode="area"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-sound)
            play_sound=false
            shift
            ;;
        --no-satty)
            use_satty=false
            shift
            ;;
        --delay)
            delay="$2"
            shift 2
            ;;
        area|select|--area|-a|--region|-r)
            mode="area"
            shift
            ;;
        active|window|--active|-w)
            mode="active"
            shift
            ;;
        screen|full|--full|-f|Screen)
            mode="screen"
            shift
            ;;
        timer|delay5|5s)
            mode="screen"
            delay=5
            shift
            ;;
        *)
            mode="$1"
            shift
            ;;
    esac
done

ss_sound() {
    if [[ "$play_sound" == true && -f "$sound_file" ]]; then
        paplay "$sound_file" &
    fi
}

# If delay > 1s, send countdown notification
if (( $(echo "$delay > 1" | bc -l 2>/dev/null || [ "$delay" -gt 1 ] 2>/dev/null) )); then
    notify-send "Screenshot in ${delay}s" "Preparing capture..." -i camera-photo -r 91189 -t 2000
    sleep "$delay"
else
    sleep "$delay"
fi

case "$mode" in
    screen|Screen|full|--full)
        grimblast copysave screen "$temp_screenshot"
        ;;
    active|window|--active)
        grimblast copysave active "$temp_screenshot"
        ;;
    area|select|Selected\ Area|--area)
        grimblast --freeze copysave area "$temp_screenshot"
        ;;
    *)
        grimblast --freeze copysave area "$temp_screenshot"
        ;;
esac

# Check if screenshot was captured (temp file has content)
if [[ ! -s "$temp_screenshot" ]]; then
    rm -f "$temp_screenshot"
    exit 0
fi

ss_sound

if [[ "$use_satty" == true ]]; then
    satty --filename "$temp_screenshot" --output-filename "$save_dir/$save_file" --early-exit
else
    cp "$temp_screenshot" "$save_dir/$save_file"
fi

[[ -f "$temp_screenshot" ]] && rm -f "$temp_screenshot"

if [[ -f "$save_dir/$save_file" ]]; then
    notify-send "Screenshot saved in" "$save_dir/$save_file" -i "$save_dir/$save_file" -r 91190 -t 5000
fi
