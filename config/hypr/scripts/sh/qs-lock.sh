#!/usr/bin/env bash
# qs-lock.sh — Safely lock screen via Quickshell

export QS_NO_RELOAD_POPUP=1

# Don't spawn multiple lockscreen instances
if pgrep -f "qs -c lockscreen" >/dev/null 2>&1; then
    exit 0
fi

# Dismiss active island dropdown/power menu if open
if pgrep -f "qs -c island" >/dev/null 2>&1; then
    qs ipc -c island call island close 2>/dev/null || true
fi

# Broadcast lock signal to systemd-logind
loginctl lock-session 2>/dev/null || true

# Launch Quickshell Lockscreen
exec qs -c lockscreen
