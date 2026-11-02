#!/usr/bin/env bash
# ==============================================================================
# qs-launcher.sh — Adaptive App Launcher
# - In Dynamic Island mode: transforms Dynamic Island notch into App Launcher
# - In Full Top Bar mode: toggles standalone Quickshell application launcher
# ==============================================================================

set -euo pipefail

export QS_NO_RELOAD_POPUP=1

# Ensure quad image is up to date if missing
if [[ ! -f "$HOME/.hyprconf/hypr/.cache/wall.quad" ]]; then
    "$HOME/.hyprconf/hypr/scripts/sh/wallcache.sh" &>/dev/null &
fi

if [[ "${1:-}" == "--spotlight" ]]; then
    export QS_LAUNCHER_THEME="spotlight"
fi

bar_cfg="$HOME/.local/share/hyprconf/bar.json"
is_bar_mode=false

if [[ -f "$bar_cfg" ]] && grep -q '"top_panel":\s*"bar"' "$bar_cfg" 2>/dev/null; then
    is_bar_mode=true
elif pgrep -f "qs -c bar" >/dev/null 2>&1 && ! pgrep -f "qs -c island" >/dev/null 2>&1; then
    is_bar_mode=true
fi

if [[ "$is_bar_mode" == "true" ]]; then
    if pgrep -f "qs -c launcher" >/dev/null 2>&1; then
        qs ipc -c launcher call launcher close 2>/dev/null || pkill -f "qs -c launcher" 2>/dev/null || true
        exit 0
    else
        exec qs -c launcher
    fi
else
    if [[ "${1:-}" == "--spotlight" ]]; then
        exec "$HOME/.hyprconf/hypr/scripts/sh/qs-island.sh" --spotlight
    else
        exec "$HOME/.hyprconf/hypr/scripts/sh/qs-island.sh" --launcher "$@"
    fi
fi
