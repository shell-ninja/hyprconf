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

cleanup_osd() {
    qs ipc -c bar call bar hideOsd >/dev/null 2>&1
    qs ipc -c island call island hideOsd >/dev/null 2>&1
}
trap cleanup_osd INT TERM

# If delay >= 1s, show countdown in OSD and close immediately before capture
delay_int="${delay%%.*}"
if [[ "$delay_int" =~ ^[0-9]+$ && "$delay_int" -ge 1 ]]; then
    for (( rem=delay_int; rem>=1; rem-- )); do
        pct=$(( (rem * 100) / delay_int ))
        qs ipc -c bar call bar showOsd "screenshot" "$pct" "${rem}s" "camera" "Capturing in ${rem}s..." >/dev/null 2>&1 &
        qs ipc -c island call island showOsd "screenshot" "$pct" "${rem}s" "camera" "Capturing in ${rem}s..." >/dev/null 2>&1 &
        sleep 1
    done
    # Immediately close OSD before capturing so it does not appear in the screenshot
    cleanup_osd
    # Allow 220ms for the compositor to unmap the OSD layer surface
    sleep 0.22
elif [[ -n "$delay" && "$delay" != "0" ]]; then
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

run_satty() {
    if command -v satty >/dev/null 2>&1; then
        # Launch Satty under XWayland to enable GLX hardware-accelerated rendering,
        # completely resolving the GTK4/Wayland "No EGL configuration available" canvas crash
        # while Satty's native wl-copy integration seamlessly populates the Wayland clipboard.
        GDK_BACKEND=x11 satty --filename "$temp_screenshot" --output-filename "$save_dir/$save_file" --early-exit
        local ret=$?
        if [[ -f "$save_dir/$save_file" && -s "$save_dir/$save_file" ]]; then
            return 0
        fi
        return $ret
    fi
    return 127
}

if [[ "$use_satty" == true ]]; then
    run_satty
    satty_code=$?
    # If satty failed to launch or crashed unexpectedly and no output was produced,
    # fall back to preserving the captured raw screenshot
    if [[ ! -f "$save_dir/$save_file" && $satty_code -ne 0 ]]; then
        cp "$temp_screenshot" "$save_dir/$save_file"
    fi
else
    cp "$temp_screenshot" "$save_dir/$save_file"
fi

[[ -f "$temp_screenshot" ]] && rm -f "$temp_screenshot"

# Ensure image is in clipboard and notify
if [[ -f "$save_dir/$save_file" && -s "$save_dir/$save_file" ]]; then
    wl-copy < "$save_dir/$save_file" 2>/dev/null || true
    notify-send "Screenshot saved in" "$save_dir/$save_file" -i "$save_dir/$save_file" -r 91190 -t 5000
fi
