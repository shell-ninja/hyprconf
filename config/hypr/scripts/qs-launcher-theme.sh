#!/usr/bin/env bash
# qs-launcher-theme.sh — Toggle Quickshell Launcher Theme Selector

if pkill -f "qs -c launcher-theme" 2>/dev/null; then
    exit 0
fi

exec qs -c launcher-theme "$@"
