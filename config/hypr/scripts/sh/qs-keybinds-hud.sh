#!/usr/bin/env bash
# qs-keybinds-hud.sh — Interactive Keyboard Shortcuts HUD Cheatsheet
set -euo pipefail

export QS_NO_RELOAD_POPUP=1

if pgrep -f "qs.*-c.*keybinds" >/dev/null 2>&1 || pgrep -f "keybinds/shell.qml" >/dev/null 2>&1; then
    pkill -f "qs.*-c.*keybinds" 2>/dev/null || true
    pkill -f "keybinds/shell.qml" 2>/dev/null || true
    exit 0
fi

exec qs -c keybinds
