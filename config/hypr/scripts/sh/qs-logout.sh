#!/usr/bin/env bash
# qs-logout.sh — Cleanly exit Hyprland session

# Dismiss active island dropdown/power menu if open
if pgrep -f "qs -c island" >/dev/null 2>&1; then
    qs ipc -c island call island close 2>/dev/null || true
fi

# Play logout notification sound in background
"$HOME/.hyprconf/hypr/scripts/sh/notification.sh" logout 2>/dev/null &

sleep 0.2

# 1. Native Hyprland Lua dispatcher exit
if hyprctl eval "hl.dispatch(hl.dsp.exit())" >/dev/null 2>&1; then
    exit 0
fi

# 2. Hyprctl dispatch exit fallback
if hyprctl dispatch exit >/dev/null 2>&1; then
    exit 0
fi

# 3. Systemd logind user termination fallback
if loginctl terminate-user "$USER" >/dev/null 2>&1; then
    exit 0
fi

# 4. Process kill fallback
pkill -KILL -u "$USER" -x Hyprland 2>/dev/null || true
