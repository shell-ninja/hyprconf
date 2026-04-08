#!/bin/bash
# volumecontrol.sh — Volume and microphone control with notifications.

iDIR="$HOME/.hyprconf/hypr/icons/vol"

# ── Speakers ──────────────────────────────────────────────────────────────────

get_volume() {
    pamixer --get-volume
}

is_muted() {
    [[ "$(pamixer --get-mute)" == "true" ]]
}

get_icon() {
    local vol
    vol=$(get_volume)
    if [[ "$vol" -eq 0 ]] || is_muted; then
        echo "$iDIR/muted-speaker.svg"
    else
        echo "$iDIR/vol-${vol}.svg"
    fi
}

get_volume_label() {
    if is_muted; then
        echo "Muted"
    else
        echo "$(get_volume)%"
    fi
}

notify_user() {
    local vol icon label
    vol=$(get_volume)
    label=$(get_volume_label)
    icon=$(get_icon)
    notify-send -e \
        -h string:x-canonical-private-synchronous:volume_notif \
        -u low -i "$icon" "Volume: $label"
}

inc_volume() {
    # Unmute first if muted, then increase
    is_muted && pamixer -u
    pamixer -i 5
    notify_user
}

dec_volume() {
    # Unmute first if muted, then decrease
    is_muted && pamixer -u
    pamixer -d 5
    notify_user
}

toggle_mute() {
    if is_muted; then
        pamixer -u
        notify-send -e -i "$iDIR/unmuted-speaker.svg" "Volume Switched ON"
    else
        pamixer -m
        notify-send -e -i "$iDIR/muted-speaker.svg" "Volume Switched OFF"
    fi
}

# ── Microphone ────────────────────────────────────────────────────────────────

is_mic_muted() {
    [[ "$(pamixer --default-source --get-mute)" == "true" ]]
}

get_mic_volume() {
    pamixer --default-source --get-volume
}

get_mic_label() {
    local vol
    vol=$(get_mic_volume)
    [[ "$vol" -eq 0 ]] || is_mic_muted && echo "Muted" || echo "${vol}%"
}

get_mic_icon() {
    if is_mic_muted; then
        echo "$iDIR/muted-mic.svg"
    else
        echo "$iDIR/unmuted-mic.svg"
    fi
}

notify_mic_user() {
    notify-send -r 91190 -t 800 \
        -i "$(get_mic_icon)" "Mic level: $(get_mic_label)"
}

inc_mic_volume() {
    is_mic_muted && pamixer --default-source -u
    pamixer --default-source -i 5
    notify_mic_user
}

dec_mic_volume() {
    is_mic_muted && pamixer --default-source -u
    pamixer --default-source -d 5
    notify_mic_user
}

toggle_mic() {
    if is_mic_muted; then
        pamixer --default-source -u
        notify-send -e -u low -i "$iDIR/unmuted-mic.svg" "Microphone Switched ON"
    else
        pamixer --default-source -m
        notify-send -e -u low -i "$iDIR/muted-mic.svg" "Microphone Switched OFF"
    fi
}

# ── Dispatch ──────────────────────────────────────────────────────────────────
case "$1" in
    --get)          get_volume_label ;;
    --inc)          inc_volume ;;
    --dec)          dec_volume ;;
    --toggle)       toggle_mute ;;
    --toggle-mic)   toggle_mic ;;
    --get-icon)     get_icon ;;
    --get-mic-icon) get_mic_icon ;;
    --mic-inc)      inc_mic_volume ;;
    --mic-dec)      dec_mic_volume ;;
    *)              get_volume_label ;;
esac
