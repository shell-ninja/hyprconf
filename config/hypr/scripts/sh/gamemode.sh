#!/usr/bin/env bash
# ==============================================================================
# gamemode.sh — Hyprland Ultra-Low-Latency Game Mode Engine
# Backwards-compatible shim delegating to system-mode.sh
# ==============================================================================

set -euo pipefail

scripts_dir="$HOME/.hyprconf/hypr/scripts/sh"
sys_mode="$scripts_dir/system-mode.sh"

get_state() {
    if [[ -x "$sys_mode" ]]; then
        cur=$(bash "$sys_mode" --get)
        if [[ "$cur" == "1" ]]; then echo "1"; else echo "0"; fi
    else
        echo "0"
    fi
}

cmd="${1:---toggle}"

case "$cmd" in
    --on|--enable|on|enable)
        bash "$sys_mode" --game
        ;;
    --off|--disable|off|disable)
        bash "$sys_mode" --normal
        ;;
    --status|status)
        get_state
        ;;
    --toggle|toggle|*)
        cur=$(get_state)
        if [[ "$cur" == "1" ]]; then
            bash "$sys_mode" --normal
        else
            bash "$sys_mode" --game
        fi
        ;;
esac
