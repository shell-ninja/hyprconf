#!/usr/bin/env bash
# qs-launcher.sh — Transform Quickshell Dynamic Island into App Launcher

export QS_NO_RELOAD_POPUP=1

cache_dir="$HOME/.local/share/hyprconf/.cache"
[[ ! -d "$cache_dir" ]] && cache_dir="$HOME/.hyprconf/hypr/.cache"
if [[ ! -f "$cache_dir/wall.quad" ]]; then
    "$HOME/.hyprconf/hypr/scripts/sh/wallcache.sh" &>/dev/null &
fi

exec "$HOME/.hyprconf/hypr/scripts/sh/qs-island.sh" --launcher "$@"
