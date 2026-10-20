#!/usr/bin/env bash
# qs-keybinds.sh — Transform Quickshell Dynamic Island into Keybinds Launcher
# Bound to SUPER + SHIFT + H

export QS_NO_RELOAD_POPUP=1

exec "$HOME/.hyprconf/hypr/scripts/sh/qs-island.sh" --keybinds "$@"
