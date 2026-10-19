#!/usr/bin/env bash
# caffeine-manager.sh — Manage Caffeine Mode bound to hypridle

is_idle_running() {
    pgrep -x "hypridle" >/dev/null 2>&1
}

get_status() {
    # If hypridle is running, Caffeine is OFF (idle is active).
    # If hypridle is NOT running, Caffeine is ON (system stays awake).
    if is_idle_running; then
        echo "off"
    else
        echo "on"
    fi
}

set_status() {
    local target="$1"
    if [[ "$target" == "on" ]]; then
        # Turn caffeine ON -> Kill hypridle so screen/machine doesn't idle
        pkill -x "hypridle" 2>/dev/null
        echo "on"
    else
        # Turn caffeine OFF -> Start hypridle
        if ! is_idle_running; then
            setsid -f hypridle -q </dev/null >/dev/null 2>&1
        fi
        echo "off"
    fi
}

toggle_status() {
    local cur
    cur=$(get_status)
    if [[ "$cur" == "on" ]]; then
        set_status "off"
    else
        set_status "on"
    fi
}

case "$1" in
    "get")
        get_status
        ;;
    "set")
        set_status "$2"
        ;;
    "toggle")
        toggle_status
        ;;
    *)
        get_status
        ;;
esac
