#!/usr/bin/env bash
# qs-logout.sh — Cleanly exit Hyprland session

# Dismiss active island dropdown/power menu if open
dismiss_menus() {
    if pgrep -f "qs -c island" >/dev/null 2>&1; then
        qs ipc -c island call island collapse >/dev/null 2>&1 || true
    fi
    if pgrep -f "qs -c bar" >/dev/null 2>&1; then
        qs ipc -c bar call bar closePower >/dev/null 2>&1 || true
    fi
}

exit_session_now() {
    # 1. Native Hyprland Lua dispatcher exit
    if hyprctl eval "hl.dispatch(hl.dsp.exit())" >/dev/null 2>&1; then
        exit 0
    fi

    # 2. Hyprctl dispatch exit fallback
    if hyprctl dispatch exit >/dev/null 2>&1; then
        exit 0
    fi

    # 3. Systemd logind user termination fallback
    if loginctl terminate-user "$USER" >/dev/null 2>&1; then
        exit 0
    fi

    # 4. Process kill fallback
    pkill -KILL -u "$USER" -x Hyprland 2>/dev/null || true
}

if [[ "${1:-}" == "--now" ]]; then
    exit_session_now
    exit 0
fi

UPTIME_PY="$HOME/.hyprconf/hypr/scripts/py/uptime-tracker.py"
if command -v python3 >/dev/null 2>&1 && [[ -f "$UPTIME_PY" ]]; then
    exec python3 "$UPTIME_PY" --logout
fi

# Fallback if python tracker is unavailable
dismiss_menus
if command -v notify-send >/dev/null 2>&1; then
    UP_SEC=$(awk '{print int($1)}' /proc/uptime 2>/dev/null || echo 0)
    H=$(( UP_SEC / 3600 ))
    M=$(( (UP_SEC % 3600) / 60 ))
    S=$(( UP_SEC % 60 ))
    notify-send -a "Hyprconf Power" -i system-log-out -t 6500 \
        "Pc Usage $(date +%d-%m-%Y)" \
        "$(printf '%dh %02dm %02ds' "$H" "$M" "$S")" 2>/dev/null || true
fi
"$HOME/.hyprconf/hypr/scripts/sh/notification.sh" logout 2>/dev/null &

sleep 1
exit_session_now
