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

# Get icons
get_icon() {
    current=$(get_volume)
    if [[ "$current" == "Muted" ]]; then
        echo "$iDIR/muted-speaker.svg"
    else
        echo "$iDIR/vol-${current%\%}.svg"
    fi
}

get_volume_label() {
    if is_muted; then
        echo "Muted"
    else
        echo "$(get_volume)%"
    fi
}


inc_volume() {
    # Unmute first if muted, then increase
    is_muted && pamixer -u
    pamixer -i 5
}

dec_volume() {
    # Unmute first if muted, then decrease
    is_muted && pamixer -u
    pamixer -d 5
}

toggle_mute() {
    if is_muted; then
        pamixer -u
    else
        pamixer -m
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
}

dec_mic_volume() {
    is_mic_muted && pamixer --default-source -u
    pamixer --default-source -d 5
}

toggle_mic() {
    if is_mic_muted; then
        pamixer --default-source -u
    else
        pamixer --default-source -m
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
