#!/bin/bash

iDIR="$HOME/.config/hypr/icons/vol"

# Get Volume
get_volume() {
    volume=$(pamixer --get-volume)
    if [[ "$volume" -eq "0" ]]; then
        echo "Muted"
    else
        echo "$volume%"
    fi
}

# Get icons
get_icon() {
    current=$(get_volume)
    if [[ "$current" == "Muted" ]]; then
        echo "$iDIR/muted-speaker.svg"
    else
        echo "$iDIR/vol-${current%\%}.svg"
    fi
}

# Notify using dunst
# notify_user() {
#     if [[ "$(get_volume)" == " " ]]; then
#         notify-send -a -r -h string:x-dunst-stack-tag:volume_notif -i "$(get_icon)" "Volume: Muted"
#     else
#         notify-send -a -r -h string:x-dunst-stack-tag:volume_notif -i "$(get_icon)" "Volume: $(get_volume)"
#     fi
# }

# Notify using swaync
notify_user() {
    if [[ "$(get_volume)" == "Muted" ]]; then
        notify-send -e -h string:x-canonical-private-synchronous:volume_notif -u low -i "$(get_icon)" "Volume: Muted"
    else
        notify-send -e -h int:value:"$(get_volume | sed 's/%//')" -h string:x-canonical-private-synchronous:volume_notif -u low -i "$(get_icon)" "Volume: $(get_volume)"
    fi
}

# Increase Volume
inc_volume() {
    if [ "$(pamixer --get-mute)" == "true" ]; then
        pamixer -u && notify_user
    fi
    pamixer -i 5 && notify_user
}

# Decrease Volume
dec_volume() {
    if [ "$(pamixer --get-mute)" == "true" ]; then
        pamixer -u && notify_user
    fi
    pamixer -d 5 && notify_user
}

# Toggle Mute
toggle_mute() {
    if [ "$(pamixer --get-mute)" == "false" ]; then
        pamixer -m && notify-send -a -h -i "$iDIR/muted-speaker.svg" "Volume Switched OFF"
    elif [ "$(pamixer --get-mute)" == "true" ]; then
        pamixer -u && notify-send -a -h -i "$iDIR/unmuted-speaker.svg" "Volume Switched ON"
    fi
}

# Toggle Mic
toggle_mic() {
    if [ "$(pamixer --default-source --get-mute)" == "false" ]; then
        pamixer --default-source -m && notify-send -e -u low -i "$iDIR/muted-mic.svg" "Microphone Switched OFF"
    elif [ "$(pamixer --default-source --get-mute)" == "true" ]; then
        pamixer --default-source -u && notify-send -e -u low -i "$iDIR/unmuted-mic.svg" "Microphone Switched ON"
    fi
}

# Get Mic Icon
get_mic_icon() {
    current=$(pamixer --default-source --get-volume)
    if [[ "$current" -eq "0" ]]; then
        echo "$iDIR/muted-mic.svg"
    else
        echo "$iDIR/unmuted-mic.svg"
    fi
}

# Get Microphone Volume
get_mic_volume() {
    volume=$(pamixer --default-source --get-volume)
    if [[ "$volume" -eq "0" ]]; then
        echo "Muted"
    else
        echo "$volume%"
    fi
}

# Notify for Microphone
notify_mic_user() {
    volume=$(get_mic_volume)
    icon=$(get_mic_icon)
    notify-send -a -r 91190 -t 800 -i "$icon" "Mic=vel: $volume"
}

# Increase MIC Volume
inc_mic_volume() {
    if [ "$(pamixer --default-source --get-mute)" == "true" ]; then
        pamixer --default-source -u && notify_mic_user
    fi
    pamixer --default-source -i 5 && notify_mic_user
}

# Decrease MIC Volume
dec_mic_volume() {
    if [ "$(pamixer --default-source --get-mute)" == "true" ]; then
        pamixer --default-source -u && notify_mic_user
    fi
    pamixer --default-source -d 5 && notify_mic_user
}

# Execute accordingly
if [[ "$1" == "--get" ]]; then
    get_volume
elif [[ "$1" == "--inc" ]]; then
    inc_volume
elif [[ "$1" == "--dec" ]]; then
    dec_volume
elif [[ "$1" == "--toggle" ]]; then
    toggle_mute
elif [[ "$1" == "--toggle-mic" ]]; then
    toggle_mic
elif [[ "$1" == "--get-icon" ]]; then
    get_icon
elif [[ "$1" == "--get-mic-icon" ]]; then
    get_mic_icon
elif [[ "$1" == "--mic-inc" ]]; then
    inc_mic_volume
elif [[ "$1" == "--mic-dec" ]]; then
    dec_mic_volume
else
    get_volume
fi
