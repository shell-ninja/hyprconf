#!/usr/bin/env bash
# qs-launcher.sh — Transform Quickshell Dynamic Island into App Launcher

export QS_NO_RELOAD_POPUP=1

# Ensure quad image is up to date if missing
if [[ ! -f "$HOME/.hyprconf/hypr/.cache/wall.quad" ]]; then
    "$HOME/.hyprconf/hypr/scripts/sh/wallcache.sh" &>/dev/null &
fi

exec "$HOME/.hyprconf/hypr/scripts/sh/qs-island.sh" --launcher "$@"
