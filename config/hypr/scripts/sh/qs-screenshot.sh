#!/usr/bin/env bash
# ==============================================================================
# qs-screenshot.sh — Adaptive Screenshot Studio Launcher
# - In Dynamic Island mode: opens inside the island notch
# - In Full Top Bar mode: toggles standalone centered obsidian modal (no island daemon)
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
    if pgrep -f "qs -c screenshot" >/dev/null 2>&1; then
        pkill -f "qs -c screenshot" 2>/dev/null || true
        exit 0
    else
        exec qs -c screenshot "$@"
    fi
else
    if pgrep -f "qs -c island" >/dev/null 2>&1; then
        exec qs ipc -c island call island toggleScreenshot
    else
        qs -c island -d
        sleep 0.35
        exec qs ipc -c island call island openScreenshot
    fi
fi
