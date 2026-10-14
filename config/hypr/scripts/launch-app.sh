#!/usr/bin/env bash
# launch-app.sh — Robust detached application launcher for Quickshell Launcher

app_id="$1"
exec_cmd="$2"

if [ -z "$app_id" ] && [ -z "$exec_cmd" ]; then
    exit 1
fi

# 1. Try launching with gtk-launch if desktop entry ID is provided
if [ -n "$app_id" ]; then
    if gtk-launch "$app_id" >/dev/null 2>&1; then
        exit 0
    fi
fi

# 2. Try launching via Hyprland IPC if running in Hyprland
if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] && [ -n "$exec_cmd" ]; then
    if hyprctl eval "hl.dispatch(hl.dsp.exec_cmd([[$exec_cmd]]))" >/dev/null 2>&1; then
        exit 0
    fi
fi

# 3. Fallback: launch detached via setsid in background
if [ -n "$exec_cmd" ]; then
    setsid -f sh -c "$exec_cmd" >/dev/null 2>&1 &
    exit 0
fi

exit 1
