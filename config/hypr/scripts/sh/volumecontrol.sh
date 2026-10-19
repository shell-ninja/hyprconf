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


notify_island() {
    local v m label icon
    v=$(pamixer --get-volume 2>/dev/null)
    m=$(pamixer --get-mute 2>/dev/null)
    if [[ -n "$v" ]]; then
        qs ipc -c island call island syncAudio "$v" "$([[ "$m" == "true" ]] && echo 1 || echo 0)" >/dev/null 2>&1 &
        if [[ "$m" == "true" ]]; then
            label="Muted"
            icon="volume-mute"
        else
            label="${v}%"
            icon="volume"
        fi
        qs ipc -c island call island showOsd "volume" "$v" "$label" "$icon" "" >/dev/null 2>&1 &
    fi
}

notify_mic_island() {
    local v m label icon
    v=$(pamixer --default-source --get-volume 2>/dev/null)
    m=$(pamixer --default-source --get-mute 2>/dev/null)
    if [[ -n "$v" ]]; then
        if [[ "$m" == "true" ]]; then
            label="Muted"
            icon="mic-mute"
        else
            label="${v}%"
            icon="mic"
        fi
        qs ipc -c island call island showOsd "mic" "$v" "$label" "$icon" "" >/dev/null 2>&1 &
    fi
}

inc_volume() {
    # Unmute first if muted, then increase
    is_muted && pamixer -u
    pamixer -i 5
    notify_island
}

dec_volume() {
    # Unmute first if muted, then decrease
    is_muted && pamixer -u
    pamixer -d 5
    notify_island
}

toggle_mute() {
    if is_muted; then
        pamixer -u
    else
        pamixer -m
    fi
    notify_island
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
    notify_mic_island
}

dec_mic_volume() {
    is_mic_muted && pamixer --default-source -u
    pamixer --default-source -d 5
    notify_mic_island
}

toggle_mic() {
    if is_mic_muted; then
        pamixer --default-source -u
    else
        pamixer --default-source -m
    fi
    notify_mic_island
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

