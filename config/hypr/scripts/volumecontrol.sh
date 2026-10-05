#!/usr/bin/env bash
# volumecontrol.sh — Volume and microphone control with notifications.

# ── Speakers ──────────────────────────────────────────────────────────────────

get_volume() {
    pamixer --get-volume
}

is_muted() {
    [[ "$(pamixer --get-mute)" == "true" ]]
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
    --mic-inc)      inc_mic_volume ;;
    --mic-dec)      dec_mic_volume ;;
    *)              get_volume_label ;;
esac

