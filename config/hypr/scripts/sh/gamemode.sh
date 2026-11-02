#!/usr/bin/env bash
# ==============================================================================
# gamemode.sh — Hyprland Ultra-Low-Latency Game Mode Engine
#
# Toggles or controls gaming optimizations:
#  - Enables immediate screen tearing (0ms latency direct scanout)
#  - Disables compositor animations (free up compositor frame time)
#  - Disables blur and window shadows (maximum GPU fill-rate)
#  - Switches CPU governor to performance via power-profiles-daemon
#  - Inhibits display idle / sleep (caffeine)
# ==============================================================================

set -euo pipefail

cache_dir="$HOME/.local/share/hyprconf/.cache"
mkdir -p "$cache_dir"
state_file="$cache_dir/gamemode.state"
scripts_dir="$HOME/.hyprconf/hypr/scripts/sh"

get_state() {
    if [[ -f "$state_file" ]]; then
        cat "$state_file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

enable_gamemode() {
    # 1. Apply Hyprland runtime settings via native Lua API:
    #    - Opacity 1.0 for all windows (active & inactive)
    #    - allow_tearing = true for 0ms direct scanout
    #    - animations = false, blur & shadow = false
    hyprctl eval "hl.config({ general = { allow_tearing = true }, decoration = { blur = { enabled = false }, shadow = { enabled = false }, active_opacity = 1.0, inactive_opacity = 1.0 }, animations = { enabled = false } }) hl.window_rule({ match = { tag = 'file-manager' }, opacity = '1.0 1.0' }) hl.window_rule({ match = { tag = 'browser' }, opacity = '1.0 1.0' })" >/dev/null 2>&1 || true

    # 2. Switch power profile to performance
    if command -v powerprofilesctl >/dev/null 2>&1; then
        powerprofilesctl set performance 2>/dev/null || true
    fi

    # 3. Inhibit screen sleep / idle
    if [[ -x "$scripts_dir/caffeine-manager.sh" ]]; then
        bash "$scripts_dir/caffeine-manager.sh" --enable >/dev/null 2>&1 || true
    fi

    # 4. Save state
    echo "1" > "$state_file"

    # 5. OSD Notification
    if [[ -x "$scripts_dir/osd-notify.sh" ]]; then
        bash "$scripts_dir/osd-notify.sh" "gamepad" "1" "Game Mode ON" "gamepad" "100% Opacity • 0ms Latency • Blur & Anim Off" >/dev/null 2>&1 || true
    else
        notify-send -a "Hyprconf Game Mode" -t 2500 "Game Mode Enabled" "100% Opacity • 0ms Latency • Blur & Anim Off" 2>/dev/null || true
    fi
}

disable_gamemode() {
    # 1. Restore Hyprland obsidian glass and user's actual opacity settings via native Lua API
    hyprctl eval "pcall(dofile, os.getenv('HOME') .. '/.hyprconf/hypr/configs/configs.lua') hl.config({ general = { allow_tearing = false }, decoration = { blur = { enabled = true }, shadow = { enabled = true }, active_opacity = opacity_act or 0.9, inactive_opacity = opacity_deact or 0.85 }, animations = { enabled = true } }) hl.window_rule({ match = { tag = 'file-manager' }, opacity = string.format('%.2f %.2f', opacity_act or 0.9, opacity_deact or 0.85) }) hl.window_rule({ match = { tag = 'browser' }, opacity = string.format('1.0 %.2f', opacity_deact or 0.85) })" >/dev/null 2>&1 || true

    # 2. Restore power profile to balanced
    if command -v powerprofilesctl >/dev/null 2>&1; then
        powerprofilesctl set balanced 2>/dev/null || true
    fi

    # 3. Restore screen sleep / idle
    if [[ -x "$scripts_dir/caffeine-manager.sh" ]]; then
        bash "$scripts_dir/caffeine-manager.sh" --disable >/dev/null 2>&1 || true
    fi

    # 4. Save state
    echo "0" > "$state_file"

    # 5. OSD Notification
    if [[ -x "$scripts_dir/osd-notify.sh" ]]; then
        bash "$scripts_dir/osd-notify.sh" "gamepad" "0" "Game Mode OFF" "gamepad" "Actual Opacity Restored • Obsidian Glass Active" >/dev/null 2>&1 || true
    else
        notify-send -a "Hyprconf Game Mode" -t 2500 "Game Mode Disabled" "Actual Opacity Restored • Obsidian Glass Active" 2>/dev/null || true
    fi
}

toggle_gamemode() {
    cur=$(get_state)
    if [[ "$cur" == "1" ]]; then
        disable_gamemode
    else
        enable_gamemode
    fi
}

cmd="${1:---toggle}"

case "$cmd" in
    --on|--enable|on|enable)
        enable_gamemode
        ;;
    --off|--disable|off|disable)
        disable_gamemode
        ;;
    --status|status)
        get_state
        ;;
    --toggle|toggle|*)
        toggle_gamemode
        ;;
esac
