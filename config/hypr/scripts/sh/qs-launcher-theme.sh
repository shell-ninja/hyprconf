#!/usr/bin/env bash
# qs-launcher-theme.sh — Toggle Quickshell Launcher Theme Selector via Dynamic Island

export QS_NO_RELOAD_POPUP=1

if [[ "$1" == "--standalone" ]]; then
    if pkill -f "qs -c launcher-theme" 2>/dev/null; then
        exit 0
    fi
    exec qs -c launcher-theme "$@"
fi

if pgrep -f "qs -c island" >/dev/null 2>&1; then
    qs ipc -c island call island toggleThemeSwitcher
    exit 0
else
    qs -c island -d
    sleep 0.35
    qs ipc -c island call island openThemeSwitcher
    exit 0
fi

