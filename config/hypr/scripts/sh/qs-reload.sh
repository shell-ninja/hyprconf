#!/usr/bin/env bash
# ==============================================================================
# qs-reload.sh — Cleanly terminate and reload Quickshell (Dynamic Island + Desktop Widgets)
# Usage:
#   qs-reload.sh          → Terminate and restart all Quickshell components
#   qs-reload.sh --quiet  → Reload silently without notification
# ==============================================================================

set -euo pipefail

export QS_NO_RELOAD_POPUP=1

scripts_dir="$HOME/.hyprconf/hypr/scripts"
sh_dir="$scripts_dir/sh"
py_dir="$scripts_dir/py"

# Auto-link ~/.config/quickshell if missing or broken
if [[ ! -e "$HOME/.config/quickshell" && -d "$HOME/.hyprconf/quickshell" ]]; then
    mkdir -p "$HOME/.config"
    ln -sfn "$HOME/.hyprconf/quickshell" "$HOME/.config/quickshell"
fi

# 1. Terminate running Quickshell instances and children cleanly
pkill -x qs 2>/dev/null || true
pkill -x quickshell 2>/dev/null || true
pkill -9 -f "[a]udio-monitor.py" 2>/dev/null || true
pkill -9 -f "[n]etwork-speed.py" 2>/dev/null || true
pkill -9 -f "[p]actl subscribe" 2>/dev/null || true
pkill -x cava 2>/dev/null || true

# Wait until processes have fully terminated to avoid race condition on restart
for _ in {1..15}; do
    if ! pgrep -x qs >/dev/null 2>&1 && ! pgrep -x quickshell >/dev/null 2>&1; then
        break
    fi
    sleep 0.1
done

# If any process is still hanging, force terminate
if pgrep -x qs >/dev/null 2>&1 || pgrep -x quickshell >/dev/null 2>&1; then
    killall -9 qs quickshell 2>/dev/null || true
    sleep 0.15
fi

# 2. Relaunch Quickshell Dynamic Island daemon
if [[ -f "$sh_dir/qs-island.sh" ]]; then
    nohup bash "$sh_dir/qs-island.sh" --start >/dev/null 2>&1 &
fi

# 3. Relaunch Quickshell Desktop Widgets daemon (if enabled)
if [[ -f "$sh_dir/qs-widgets.sh" ]]; then
    nohup bash "$sh_dir/qs-widgets.sh" --start >/dev/null 2>&1 &
fi

# 4. Relaunch Quickshell Dock daemon (if enabled)
if [[ -f "$sh_dir/qs-dock.sh" ]]; then
    nohup bash "$sh_dir/qs-dock.sh" --start >/dev/null 2>&1 &
fi

# 5. Notify user of successful reload
if [[ "${1:-}" != "--quiet" && "${1:-}" != "-q" ]]; then
    notify-send -a "Quickshell" \
        -i preferences-desktop-theme \
        -t 2200 \
        -h string:x-canonical-private-synchronous:qs-reload \
        "Quickshell Reloaded" \
        "Dynamic Island and desktop widgets reloaded successfully." 2>/dev/null || true
fi
