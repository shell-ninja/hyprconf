#!/usr/bin/env bash
# ==============================================================================
# shell.sh — Desktop Shell Manager (Quickshell Island Daemon)
# ==============================================================================

set -euo pipefail

SCRIPTS_DIR="$HOME/.hyprconf/hypr/scripts/sh"

start_quickshell() {
    "$SCRIPTS_DIR/qs-island.sh" --start
}

restart_quickshell() {
    "$SCRIPTS_DIR/qs-island.sh" --restart
    notify-send -t 1500 -i "preferences-desktop-theme" "Desktop Shell" "Quickshell Island reloaded"
}

action="${1:---toggle}"

case "$action" in
    --start)
        start_quickshell
        ;;
    --restart|--reload|--toggle|*)
        restart_quickshell
        ;;
esac
