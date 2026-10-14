#!/usr/bin/env bash
# qs-launcher.sh — Toggle Quickshell App Launcher

if pkill -f "qs -c launcher" 2>/dev/null; then
    exit 0
fi

# Ensure quad image is up to date if missing
if [[ ! -f "$HOME/.hyprconf/hypr/.cache/wall.quad" ]]; then
    "$HOME/.hyprconf/hypr/scripts/wallcache.sh" &>/dev/null &
fi

exec qs -c launcher "$@"
