#!/usr/bin/env bash
# ==============================================================================
# qs-dock.sh — Quickshell Application Dock Daemon Manager
# Usage:
#   qs-dock.sh --start    → Start dock daemon in background
#   qs-dock.sh --stop     → Cleanly terminate dock daemon
#   qs-dock.sh --restart  → Restart dock daemon
#   qs-dock.sh --toggle   → Toggle dock enabled state via IPC
#   qs-dock.sh --status   → Check if dock is currently active
# ==============================================================================

set -euo pipefail

export QS_NO_RELOAD_POPUP=1

# Auto-link ~/.config/quickshell if missing
if [[ ! -e "$HOME/.config/quickshell" && -d "$HOME/.hyprconf/quickshell" ]]; then
    mkdir -p "$HOME/.config"
    ln -sfn "$HOME/.hyprconf/quickshell" "$HOME/.config/quickshell"
fi

ACTION="${1:---start}"

is_running() {
    pgrep -f "qs.*-c.*dock|quickshell.*-c.*dock" >/dev/null 2>&1
}

case "$ACTION" in
    --start|-s)
        if is_running; then
            exit 0
        fi
        qs -c dock -d
        ;;

    --stop|-k)
        pkill -f "qs.*-c.*dock|quickshell.*-c.*dock" 2>/dev/null || true
        ;;

    --restart|-r)
        pkill -f "qs.*-c.*dock|quickshell.*-c.*dock" 2>/dev/null || true
        for _ in {1..20}; do
            is_running || break
            sleep 0.05
        done
        qs -c dock -d
        ;;

    --toggle|-t)
        if is_running; then
            qs ipc -c dock call dock toggle 2>/dev/null || {
                pkill -f "qs.*-c.*dock|quickshell.*-c.*dock" 2>/dev/null || true
            }
        else
            nohup qs -c dock -d >/dev/null 2>&1 &
        fi
        ;;

    --status)
        if is_running; then
            echo "Dock: RUNNING"
            exit 0
        else
            echo "Dock: STOPPED"
            exit 1
        fi
        ;;

    *)
        echo "Usage: $0 {--start|--stop|--restart|--toggle|--status}"
        exit 1
        ;;
esac
