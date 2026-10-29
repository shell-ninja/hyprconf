#!/usr/bin/env bash
# qs-widgets.sh — Manage Quickshell Desktop Widgets daemon

export QS_NO_RELOAD_POPUP=1

# Auto-link ~/.config/quickshell if missing
if [[ ! -e "$HOME/.config/quickshell" && -d "$HOME/.hyprconf/quickshell" ]]; then
    mkdir -p "$HOME/.config"
    ln -sfn "$HOME/.hyprconf/quickshell" "$HOME/.config/quickshell"
fi

if [[ "$1" == "--start" ]]; then
    cfg="$HOME/.hyprconf/quickshell/widgets/widgets.json"
    if [[ -f "$cfg" ]]; then
        enabled=$(python3 -c "import json; print(json.load(open('$cfg')).get('enabled', False))" 2>/dev/null || echo "False")
        if [[ "$enabled" != "True" ]]; then
            exit 0
        fi
    fi
    if ! pgrep -f "qs -c widgets" >/dev/null 2>&1; then
        exec qs -c widgets -d
    fi
    exit 0
fi

if [[ "$1" == "--restart" ]]; then
    pkill -f "qs -c widgets" 2>/dev/null || true
    sleep 0.3
    exec qs -c widgets -d
fi

if [[ "$1" == "--stop" ]]; then
    pkill -f "qs -c widgets" 2>/dev/null || true
    exit 0
fi

if [[ "$1" == "--reload" ]]; then
    if pgrep -f "qs -c widgets" >/dev/null 2>&1; then
        qs ipc -c widgets call widgets reloadConfig 2>/dev/null || true
    else
        exec qs -c widgets -d
    fi
    exit 0
fi

if [[ "$1" == "--toggle" ]]; then
    if pgrep -f "qs -c widgets" >/dev/null 2>&1; then
        qs ipc -c widgets call widgets toggle 2>/dev/null || true
    else
        exec qs -c widgets -d
    fi
    exit 0
fi

# Default: start if not running, or reload
if pgrep -f "qs -c widgets" >/dev/null 2>&1; then
    qs ipc -c widgets call widgets reloadConfig 2>/dev/null || true
else
    exec qs -c widgets -d
fi
