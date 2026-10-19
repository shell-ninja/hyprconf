#!/usr/bin/env bash
# qs-screenshot.sh — Toggle Quickshell Dynamic Island Screenshot Launcher

export QS_NO_RELOAD_POPUP=1

if pgrep -f "qs -c island" >/dev/null 2>&1; then
    qs ipc -c island call island toggleScreenshot
    exit 0
else
    qs -c island -d
    sleep 0.35
    qs ipc -c island call island openScreenshot
    exit 0
fi
