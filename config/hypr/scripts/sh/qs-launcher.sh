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

if [[ -f "$bar_cfg" ]]; then
    if grep -q '"capsule_style":\s*"glass"' "$bar_cfg" 2>/dev/null || grep -q '"screen_frame":\s*true' "$bar_cfg" 2>/dev/null; then
        export QS_LAUNCHER_HAS_FRAME="1"
    else
        export QS_LAUNCHER_HAS_FRAME="0"
    fi
    ft=$(grep -oP '"frame_thickness":\s*\K[0-9]+' "$bar_cfg" 2>/dev/null || echo "18")
    export QS_LAUNCHER_FRAME_THICKNESS="${ft:-18}"
    op=$(grep -oP '"opacity":\s*\K[0-9.]+' "$bar_cfg" 2>/dev/null || echo "0.85")
    export QS_LAUNCHER_BAR_OPACITY="${op:-0.85}"
else
    export QS_LAUNCHER_HAS_FRAME="0"
    export QS_LAUNCHER_FRAME_THICKNESS="18"
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
