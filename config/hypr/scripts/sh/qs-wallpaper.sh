#!/usr/bin/env bash
# ==============================================================================
# qs-wallpaper.sh — Adaptive Wallpaper Selector
# - In Dynamic Island mode: opens directly inside the notch carousel
# - In Full Top Bar mode: opens standalone centered obsidian modal (no island daemon)
# ==============================================================================

set -euo pipefail

export QS_NO_RELOAD_POPUP=1

bar_cfg="$HOME/.local/share/hyprconf/bar.json"
is_bar_mode=false

if [[ -f "$bar_cfg" ]] && grep -q '"top_panel":\s*"bar"' "$bar_cfg" 2>/dev/null; then
    is_bar_mode=true
elif pgrep -f "qs -c bar" >/dev/null 2>&1 && ! pgrep -f "qs -c island" >/dev/null 2>&1; then
    is_bar_mode=true
fi

if [[ "$is_bar_mode" == "true" ]]; then
    # Standalone centered wallpaper browser modal (does not start or touch Dynamic Island)
    if pgrep -f "qs -c wallpaper" >/dev/null 2>&1; then
        qs ipc -c wallpaper call wallpaper close 2>/dev/null || pkill -f "qs -c wallpaper" 2>/dev/null || true
        exit 0
    else
        exec qs -c wallpaper
    fi
else
    # Dynamic Island notch wallpaper picker
    exec "$HOME/.hyprconf/hypr/scripts/sh/qs-island.sh" --wallpaper "$@"
fi
