#!/usr/bin/env bash
# qs-emoji.sh — Transform Quickshell Dynamic Island into Emoji Picker
# Bound to SUPER + SHIFT + D

export QS_NO_RELOAD_POPUP=1

# Ensure cache directory exists
mkdir -p "$HOME/.hyprconf/hypr/.cache"

# Capture currently active window so we can refocus and auto-paste when emoji is selected
hyprctl activewindow -j > "$HOME/.hyprconf/hypr/.cache/emoji_target.json" 2>/dev/null || true

# Forward to Dynamic Island
exec "$HOME/.hyprconf/hypr/scripts/sh/qs-island.sh" --emoji "$@"
