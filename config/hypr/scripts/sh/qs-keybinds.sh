#!/usr/bin/env bash
# ==============================================================================
# qs-keybinds.sh — Adaptive Keybinds Cheatsheet Launcher
# - In Dynamic Island mode: transforms Dynamic Island notch into Keybinds Launcher
# - In Full Top Bar mode: opens Settings Studio directly on the Keybinds tab
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
    exec "$HOME/.hyprconf/hypr/scripts/sh/qs-keybinds-hud.sh"
else
    exec "$HOME/.hyprconf/hypr/scripts/sh/qs-island.sh" --keybinds "$@"
fi
