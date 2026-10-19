#!/usr/bin/env bash
# ==============================================================================
# qs-caelestia.sh — Manage Quickshell Caelestia Bar & Screen Frame Daemon
# ==============================================================================

set -euo pipefail
export QS_NO_RELOAD_POPUP=1

# Auto-link ~/.config/quickshell if missing
if [[ ! -e "$HOME/.config/quickshell" && -d "$HOME/.hyprconf/quickshell" ]]; then
    mkdir -p "$HOME/.config"
    ln -sfn "$HOME/.hyprconf/quickshell" "$HOME/.config/quickshell"
fi

start_bar() {
    if ! pgrep -f "qs -c caelestia" >/dev/null 2>&1; then
        # Stop island if running to cleanly take over the bar space
        pkill -f "qs -c island" 2>/dev/null || true
        sleep 0.2
        exec qs -c caelestia -d
    fi
}

restart_bar() {
    pkill -f "qs -c caelestia" 2>/dev/null || true
    pkill -f "qs -c island" 2>/dev/null || true
    sleep 0.3
    exec qs -c caelestia -d
}

stop_bar() {
    pkill -f "qs -c caelestia" 2>/dev/null || true
}

toggle_launcher() {
    if ! pgrep -f "qs -c caelestia" >/dev/null 2>&1; then
        start_bar
        sleep 0.5
    fi
    quickshell ipc -c caelestia call caelestia toggleLauncher >/dev/null 2>&1 || true
}

open_menu() {
    local menu="${1:-launcher}"
    if ! pgrep -f "qs -c caelestia" >/dev/null 2>&1; then
        start_bar
        sleep 0.5
    fi
    quickshell ipc -c caelestia call caelestia openMenu "\"$menu\"" 8 >/dev/null 2>&1 || true
}

action="${1:---toggle}"

case "$action" in
    --start)
        start_bar
        ;;
    --restart|--reload)
        restart_bar
        ;;
    --stop)
        stop_bar
        ;;
    --launcher|--toggle-launcher)
        toggle_launcher
        ;;
    --menu)
        open_menu "${2:-launcher}"
        ;;
    --toggle|*)
        if pgrep -f "qs -c caelestia" >/dev/null 2>&1; then
            stop_bar
        else
            start_bar
        fi
        ;;
esac
