#!/usr/bin/env bash
# qs-clipboard.sh — Transform Quickshell Dynamic Island into Clipboard Launcher
export QS_NO_RELOAD_POPUP=1

# Ensure clipboard daemon is active
python3 "$HOME/.hyprconf/hypr/scripts/py/clipboard.py" --daemon &>/dev/null &

exec "$HOME/.hyprconf/hypr/scripts/sh/qs-island.sh" --clipboard "$@"
