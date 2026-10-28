#!/usr/bin/env bash
# =============================================================================
#  qs-updater.sh — Quickshell System Package Updater supervisor
# =============================================================================
export QS_NO_RELOAD_POPUP=1

# Auto-link ~/.config/quickshell if missing
if [[ ! -e "$HOME/.config/quickshell" && -d "$HOME/.hyprconf/quickshell" ]]; then
    mkdir -p "$HOME/.config"
    ln -sfn "$HOME/.hyprconf/quickshell" "$HOME/.config/quickshell"
fi

# Single instance check
if pgrep -f "qs -c updater" >/dev/null 2>&1; then
    qs ipc -c updater call updater raise 2>/dev/null && exit 0
fi

pkill -f "qs -c updater" 2>/dev/null
sleep 0.05
exec qs -c updater "$@"
