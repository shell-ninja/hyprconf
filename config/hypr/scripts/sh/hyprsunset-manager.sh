#!/usr/bin/env bash
# hyprsunset-manager.sh — 3-Stage Night Light Manager (Off, Always On, Scheduled)

STATE_FILE="$HOME/.hyprconf/hypr/.cache/nightlight_state.json"
SCHEDULER_PID_FILE="/tmp/hyprsunset_scheduler.pid"
mkdir -p "$HOME/.hyprconf/hypr/.cache"

is_hyprsunset_running() {
    pgrep -x "hyprsunset" >/dev/null 2>&1
}

kill_scheduler() {
    if [[ -f "$SCHEDULER_PID_FILE" ]]; then
        local pid
        pid=$(cat "$SCHEDULER_PID_FILE" 2>/dev/null)
        if [[ -n "$pid" ]]; then
            kill "$pid" 2>/dev/null
        fi
        rm -f "$SCHEDULER_PID_FILE"
    fi
    pkill -f "hyprsunset-manager.sh --daemon" 2>/dev/null
}

kill_hyprsunset() {
    pkill -x "hyprsunset" 2>/dev/null
}

start_hyprsunset() {
    if ! is_hyprsunset_running; then
        setsid -f hyprsunset -t 4500 </dev/null >/dev/null 2>&1
    fi
}

run_scheduler_daemon() {
    echo $$ > "$SCHEDULER_PID_FILE"
    while true; do
        local cur_hour
        cur_hour=$(date +%-H)
        # Night schedule: 19:00 (7 PM) to 06:59 (7 AM)
        if (( cur_hour >= 19 || cur_hour < 7 )); then
            if ! is_hyprsunset_running; then
                setsid -f hyprsunset -t 4500 </dev/null >/dev/null 2>&1
            fi
        else
            if is_hyprsunset_running; then
                kill_hyprsunset
            fi
        fi
        sleep 60
    done
}

get_mode() {
    if [[ -f "$STATE_FILE" ]]; then
        local mode
        mode=$(grep -oP '"mode"\s*:\s*"\K[^"]+' "$STATE_FILE" 2>/dev/null)
        if [[ -n "$mode" ]]; then
            echo "$mode"
            return 0
        fi
    fi
    if is_hyprsunset_running; then
        echo "on"
    else
        echo "off"
    fi
}

set_mode() {
    local target="$1"
    case "$target" in
        "on")
            kill_scheduler
            start_hyprsunset
            echo '{"mode": "on"}' > "$STATE_FILE"
            echo "on"
            ;;
        "scheduled")
            kill_scheduler
            local cur_hour
            cur_hour=$(date +%-H)
            if (( cur_hour >= 19 || cur_hour < 7 )); then
                start_hyprsunset
            else
                kill_hyprsunset
            fi
            setsid -f "$0" --daemon </dev/null >/dev/null 2>&1
            echo '{"mode": "scheduled"}' > "$STATE_FILE"
            echo "scheduled"
            ;;
        "off"|*)
            kill_scheduler
            kill_hyprsunset
            echo '{"mode": "off"}' > "$STATE_FILE"
            echo "off"
            ;;
    esac
}

toggle_mode() {
    local cur
    cur=$(get_mode)
    case "$cur" in
        "off")
            set_mode "on"
            ;;
        "on")
            set_mode "scheduled"
            ;;
        "scheduled")
            set_mode "off"
            ;;
        *)
            set_mode "on"
            ;;
    esac
}

case "$1" in
    "get")
        get_mode
        ;;
    "set")
        set_mode "$2"
        ;;
    "toggle")
        toggle_mode
        ;;
    "--daemon")
        run_scheduler_daemon
        ;;
    *)
        get_mode
        ;;
esac
