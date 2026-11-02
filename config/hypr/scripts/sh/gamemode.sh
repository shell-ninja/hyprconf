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
    # 1. Apply Hyprland runtime settings via native Lua API
    hyprctl eval "hl.config({ general = { allow_tearing = true }, decoration = { blur = { enabled = false }, shadow = { enabled = false } }, animations = { enabled = false } })" >/dev/null 2>&1 || true

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
        bash "$scripts_dir/osd-notify.sh" "gamepad" "1" "Game Mode ON" "gamepad" "0ms Latency • Blur & Anim Off • Performance Profile" >/dev/null 2>&1 || true
    else
        notify-send -a "Hyprconf Game Mode" -t 2500 "Game Mode Enabled" "0ms Latency • Blur & Anim Off • Performance Profile" 2>/dev/null || true
    fi
}

disable_gamemode() {
    # 1. Restore Hyprland obsidian glass settings via native Lua API
    hyprctl eval "hl.config({ general = { allow_tearing = false }, decoration = { blur = { enabled = true }, shadow = { enabled = true } }, animations = { enabled = true } })" >/dev/null 2>&1 || true

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
        bash "$scripts_dir/osd-notify.sh" "gamepad" "0" "Game Mode OFF" "gamepad" "Obsidian Glass Restored • Animations & Blur On" >/dev/null 2>&1 || true
    else
        notify-send -a "Hyprconf Game Mode" -t 2500 "Game Mode Disabled" "Obsidian Glass Restored • Animations & Blur On" 2>/dev/null || true
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
