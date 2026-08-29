#!/usr/bin/env bash
# ==============================================================================
# shell.sh — Desktop Shell Manager (Noctalia Shell <-> Waybar / SwayNC)
# ==============================================================================

set -euo pipefail

SCRIPTS_DIR="$HOME/.config/hypr/scripts"

start_noctalia() {
    # Terminate conflicting bars/notification daemons
    killall waybar 2>/dev/null || true
    killall swaync 2>/dev/null || true
    killall dunst 2>/dev/null || true
    killall ags 2>/dev/null || true

    if ! pgrep -x "noctalia" >/dev/null 2>&1; then
        noctalia -d &
        disown
    fi
    # notify-send -t 2000 -i "preferences-desktop-theme" "Desktop Shell" "Switched to Noctalia Shell"
}

start_waybar() {
    killall noctalia 2>/dev/null || true

    # Start Waybar and SwayNC
    if ! pgrep -x "waybar" >/dev/null 2>&1; then
        waybar &
        disown
    fi
    if ! pgrep -x "swaync" >/dev/null 2>&1; then
        swaync &
        disown
    fi
    notify-send -t 2000 -i "preferences-desktop-theme" "Desktop Shell" "Switched to Waybar + SwayNC"
}

toggle_shell() {
    if pgrep -x "noctalia" >/dev/null 2>&1; then
        start_waybar
    else
        start_noctalia
    fi
}

reload_shell() {
    if pgrep -x "noctalia" >/dev/null 2>&1; then
        # Noctalia auto-reloads or we can close settings/refresh
        notify-send -t 1500 -i "view-refresh" "Noctalia" "Shell reloaded"
    fi
    if pgrep -x "waybar" >/dev/null 2>&1; then
        killall -SIGUSR2 waybar 2>/dev/null || true
    fi
}

action="${1:---toggle}"

case "$action" in
    --noctalia)
        start_noctalia
        ;;
    --waybar)
        start_waybar
        ;;
    --reload)
        reload_shell
        ;;
    --toggle|*)
        toggle_shell
        ;;
esac

exit 0
