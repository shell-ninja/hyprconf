#!/usr/bin/env bash
# =============================================================================
#  qs-welcome.sh — Quickshell Welcome to Hyprconf supervisor
# =============================================================================
export QS_NO_RELOAD_POPUP=1

# Check autostart setting
if [ "$1" = "--autostart" ]; then
    state_file="$HOME/.local/share/hyprconf/welcome-app.json"
    if [[ ! -f "$state_file" && -f "$HOME/.hyprconf/hypr/welcome-app.json" ]]; then
        state_file="$HOME/.hyprconf/hypr/welcome-app.json"
    fi
    if [[ -f "$state_file" ]]; then
        if grep -q '"show_on_startup": false' "$state_file" 2>/dev/null; then
            exit 0
        fi
    fi
    shift
fi

# Auto-link ~/.config/quickshell if missing
if [[ ! -e "$HOME/.config/quickshell" && -d "$HOME/.hyprconf/quickshell" ]]; then
    mkdir -p "$HOME/.config"
    ln -sfn "$HOME/.hyprconf/quickshell" "$HOME/.config/quickshell"
fi

# Single instance check
if pgrep -f "qs -c welcome" >/dev/null 2>&1; then
    qs ipc -c welcome call welcome raise 2>/dev/null && exit 0
fi

pkill -f "qs -c welcome" 2>/dev/null
sleep 0.05
exec qs -c welcome "$@"
