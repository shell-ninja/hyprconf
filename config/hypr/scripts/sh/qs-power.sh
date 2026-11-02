#!/usr/bin/env bash
# ==============================================================================
# qs-power.sh — Adaptive Power Menu Launcher
# - In Dynamic Island mode: opens inside the island notch
# - In Full Top Bar mode: toggles the native Bar power dropdown popup
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
    if pgrep -f "qs -c bar" >/dev/null 2>&1; then
        exec qs ipc -c bar call bar togglePower
    else
        # Fallback to island if bar daemon is not running
        exec "$HOME/.hyprconf/hypr/scripts/sh/qs-island.sh" --power "$@"
    fi
else
    exec "$HOME/.hyprconf/hypr/scripts/sh/qs-island.sh" --power "$@"
fi
