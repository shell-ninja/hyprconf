#!/usr/bin/env bash
# ==============================================================================
# system-mode.sh — Tri-State Desktop Environment Engine
#
# Modes:
#   0 : Normal Mode (Obsidian Glass, Animations, DND Off, Sleep/Idle Active, Balanced)
#   1 : Game Mode (Ultra-low latency, 0ms direct scanout, 100% opacity, No anim/blur, Perf)
#   2 : Presentation / Study / Class Mode (DND On, Inhibit Sleep/Dimming, No Tearing, Balanced/Quiet)
# ==============================================================================

set -euo pipefail

cache_dir="$HOME/.local/share/hyprconf/.cache"
mkdir -p "$cache_dir"
state_file="$cache_dir/system_mode.state"
game_state_file="$cache_dir/gamemode.state"
scripts_dir="$HOME/.hyprconf/hypr/scripts/sh"
dnd_file="$HOME/.hyprconf/hypr/.cache/dnd_state.json"

get_mode() {
    if [[ -f "$state_file" ]]; then
        cat "$state_file" 2>/dev/null || echo "0"
    elif [[ -f "$game_state_file" ]]; then
        g=$(cat "$game_state_file" 2>/dev/null || echo "0")
        if [[ "$g" == "1" ]]; then echo "1"; else echo "0"; fi
    else
        echo "0"
    fi
}

set_mode() {
    local target="$1"

    case "$target" in
        0|normal|default)
            # ── MODE 0: Normal Mode ──────────────────────────────────────────
            # 1. Restore Hyprland obsidian glass, animations & user opacity
            hyprctl eval "pcall(dofile, os.getenv('HOME') .. '/.hyprconf/hypr/configs/configs.lua') hl.config({ general = { allow_tearing = false }, decoration = { blur = { enabled = true }, shadow = { enabled = true }, active_opacity = opacity_act or 0.9, inactive_opacity = opacity_deact or 0.85 }, animations = { enabled = true } }) hl.window_rule({ match = { tag = 'file-manager' }, opacity = string.format('%.2f %.2f', opacity_act or 0.9, opacity_deact or 0.85) }) hl.window_rule({ match = { tag = 'browser' }, opacity = string.format('1.0 %.2f', opacity_deact or 0.85) })" >/dev/null 2>&1 || true

            # 2. DND OFF
            python3 -c "import json, os; p='$dnd_file'; os.makedirs(os.path.dirname(p), exist_ok=True); json.dump({'dnd': False}, open(p, 'w'))" 2>/dev/null || true

            # 3. Caffeine OFF (allow idle/sleep)
            if [[ -x "$scripts_dir/caffeine-manager.sh" ]]; then
                QUIET=1 bash "$scripts_dir/caffeine-manager.sh" off >/dev/null 2>&1 || true
            fi

            # 4. Power profile balanced
            if command -v powerprofilesctl >/dev/null 2>&1; then
                powerprofilesctl set balanced 2>/dev/null || true
            fi

            # 5. Persist state
            echo "0" > "$state_file"
            echo "0" > "$game_state_file"

            # 6. Unified OSD
            if [[ -x "$scripts_dir/osd-notify.sh" ]]; then
                bash "$scripts_dir/osd-notify.sh" "system_mode" "0" "Normal Mode" "desktop" "Obsidian Glass • Standard Notifications" >/dev/null 2>&1 || true
            else
                notify-send -a "Hyprconf System Mode" -t 2500 "Normal Mode" "Obsidian Glass • Standard Notifications" 2>/dev/null || true
            fi
            ;;

        1|game|gaming)
            # ── MODE 1: Game Mode ────────────────────────────────────────────
            # 1. Hyprland: 100% opacity, 0ms direct scanout tearing, disable blur/shadows/anim
            hyprctl eval "hl.config({ general = { allow_tearing = true }, decoration = { blur = { enabled = false }, shadow = { enabled = false }, active_opacity = 1.0, inactive_opacity = 1.0 }, animations = { enabled = false } }) hl.window_rule({ match = { tag = 'file-manager' }, opacity = '1.0 1.0' }) hl.window_rule({ match = { tag = 'browser' }, opacity = '1.0 1.0' })" >/dev/null 2>&1 || true

            # 2. DND OFF
            python3 -c "import json, os; p='$dnd_file'; os.makedirs(os.path.dirname(p), exist_ok=True); json.dump({'dnd': False}, open(p, 'w'))" 2>/dev/null || true

            # 3. Caffeine ON (inhibit screen sleep)
            if [[ -x "$scripts_dir/caffeine-manager.sh" ]]; then
                QUIET=1 bash "$scripts_dir/caffeine-manager.sh" on >/dev/null 2>&1 || true
            fi

            # 4. Power profile performance
            if command -v powerprofilesctl >/dev/null 2>&1; then
                powerprofilesctl set performance 2>/dev/null || true
            fi

            # 5. Persist state
            echo "1" > "$state_file"
            echo "1" > "$game_state_file"

            # 6. Unified OSD
            if [[ -x "$scripts_dir/osd-notify.sh" ]]; then
                bash "$scripts_dir/osd-notify.sh" "system_mode" "1" "Game Mode" "gamepad" "100% Opacity • 0ms Latency • Blur Off" >/dev/null 2>&1 || true
            else
                notify-send -a "Hyprconf System Mode" -t 2500 "Game Mode Enabled" "100% Opacity • 0ms Latency • Blur Off" 2>/dev/null || true
            fi
            ;;

        2|presentation|study|class|focus|meeting)
            # ── MODE 2: Presentation / Study / Class Mode ───────────────────
            # 1. Hyprland: Clean obsidian glass, no tearing (smooth screen share / call video), normal opacity
            hyprctl eval "pcall(dofile, os.getenv('HOME') .. '/.hyprconf/hypr/configs/configs.lua') hl.config({ general = { allow_tearing = false }, decoration = { blur = { enabled = true }, shadow = { enabled = true }, active_opacity = opacity_act or 0.9, inactive_opacity = opacity_deact or 0.85 }, animations = { enabled = true } }) hl.window_rule({ match = { tag = 'file-manager' }, opacity = string.format('%.2f %.2f', opacity_act or 0.9, opacity_deact or 0.85) }) hl.window_rule({ match = { tag = 'browser' }, opacity = string.format('1.0 %.2f', opacity_deact or 0.85) })" >/dev/null 2>&1 || true

            # 2. DND ON (silence notification popups and toasts)
            python3 -c "import json, os; p='$dnd_file'; os.makedirs(os.path.dirname(p), exist_ok=True); json.dump({'dnd': True}, open(p, 'w'))" 2>/dev/null || true

            # 3. Caffeine ON (inhibit screen sleep / dimming / screenlock during presentations/classes)
            if [[ -x "$scripts_dir/caffeine-manager.sh" ]]; then
                QUIET=1 bash "$scripts_dir/caffeine-manager.sh" on >/dev/null 2>&1 || true
            fi

            # 4. Power profile balanced (quiet fans so microphone stays crystal clear)
            if command -v powerprofilesctl >/dev/null 2>&1; then
                powerprofilesctl set balanced 2>/dev/null || true
            fi

            # 5. Persist state
            echo "2" > "$state_file"
            echo "0" > "$game_state_file"

            # 6. Unified OSD
            if [[ -x "$scripts_dir/osd-notify.sh" ]]; then
                bash "$scripts_dir/osd-notify.sh" "system_mode" "2" "Presentation Mode" "presentation" "DND Active • Inhibit Sleep • Silent Fans" >/dev/null 2>&1 || true
            else
                notify-send -a "Hyprconf System Mode" -t 2500 "Presentation Mode" "DND Active • Inhibit Sleep • Silent Fans" 2>/dev/null || true
            fi
            ;;

        *)
            echo "Usage: $0 {--get|--cycle|--set <0|1|2>|--normal|--game|--presentation}" >&2
            exit 1
            ;;
    esac
}

cycle_mode() {
    local cur
    cur=$(get_mode)
    local next=$(( (cur + 1) % 3 ))
    set_mode "$next"
}

cmd="${1:---cycle}"

case "$cmd" in
    --get|get|--status|status)
        get_mode
        ;;
    --set|set)
        set_mode "${2:-0}"
        ;;
    --normal|normal|0)
        set_mode 0
        ;;
    --game|game|1)
        set_mode 1
        ;;
    --presentation|presentation|--class|class|--study|study|2)
        set_mode 2
        ;;
    --cycle|cycle|--toggle|toggle|*)
        cycle_mode
        ;;
esac
