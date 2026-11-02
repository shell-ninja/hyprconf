#!/usr/bin/env bash
# ==============================================================================
# qs-emoji.sh — Adaptive Emoji Picker Launcher
# - In Dynamic Island mode: transforms Dynamic Island notch into Emoji Picker
# - In Full Top Bar mode: toggles standalone Quickshell emoji picker overlay
# ==============================================================================

set -euo pipefail

export QS_NO_RELOAD_POPUP=1

# Ensure cache directory exists
mkdir -p "$HOME/.hyprconf/hypr/.cache"

# Capture currently active window so we can refocus and auto-paste when emoji is selected
hyprctl activewindow -j > "$HOME/.hyprconf/hypr/.cache/emoji_target.json" 2>/dev/null || true

bar_cfg="$HOME/.local/share/hyprconf/bar.json"
is_bar_mode=false

if [[ -f "$bar_cfg" ]] && grep -q '"top_panel":\s*"bar"' "$bar_cfg" 2>/dev/null; then
    is_bar_mode=true
elif pgrep -f "qs -c bar" >/dev/null 2>&1 && ! pgrep -f "qs -c island" >/dev/null 2>&1; then
    is_bar_mode=true
fi

if [[ "$is_bar_mode" == "true" ]]; then
    if pgrep -f "qs -c emoji" >/dev/null 2>&1; then
        pkill -f "qs -c emoji" 2>/dev/null || true
        exit 0
    else
        exec qs -c emoji
    fi
else
    exec "$HOME/.hyprconf/hypr/scripts/sh/qs-island.sh" --emoji "$@"
fi
