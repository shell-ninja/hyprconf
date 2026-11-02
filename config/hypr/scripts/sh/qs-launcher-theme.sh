#!/usr/bin/env bash
# ==============================================================================
# qs-launcher-theme.sh — Adaptive Launcher Theme Selector
# - In Dynamic Island mode: opens inside the island notch
# - In Full Top Bar mode: toggles standalone Quickshell launcher-theme overlay
# ==============================================================================

set -euo pipefail

export QS_NO_RELOAD_POPUP=1

if [[ "${1:-}" == "--standalone" ]]; then
    if pkill -f "qs -c launcher-theme" 2>/dev/null; then
        exit 0
    fi
    exec qs -c launcher-theme
fi

bar_cfg="$HOME/.local/share/hyprconf/bar.json"
is_bar_mode=false

if [[ -f "$bar_cfg" ]] && grep -q '"top_panel":\s*"bar"' "$bar_cfg" 2>/dev/null; then
    is_bar_mode=true
elif pgrep -f "qs -c bar" >/dev/null 2>&1 && ! pgrep -f "qs -c island" >/dev/null 2>&1; then
    is_bar_mode=true
fi

if [[ "$is_bar_mode" == "true" ]]; then
    if pgrep -f "qs -c launcher-theme" >/dev/null 2>&1; then
        pkill -f "qs -c launcher-theme" 2>/dev/null || true
        exit 0
    else
        exec qs -c launcher-theme "$@"
    fi
else
    if pgrep -f "qs -c island" >/dev/null 2>&1; then
        exec qs ipc -c island call island toggleThemeSwitcher
    else
        qs -c island -d
        sleep 0.35
        exec qs ipc -c island call island openThemeSwitcher
    fi
fi
