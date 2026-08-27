#!/usr/bin/env bash
# ==============================================================================
# noctalia-lockscreen.sh — Lockscreen Theme Switcher for Noctalia Shell
# Usage:
#   noctalia-lockscreen.sh              → open Noctalia launcher at /lock picker
#   noctalia-lockscreen.sh <preset>     → apply <preset> directly (called by launcher)
# ==============================================================================

set -euo pipefail

noctalia_dir="$HOME/.config/noctalia"
locks_dir="$noctalia_dir/lockscreens"
active_lock="$noctalia_dir/50-lockscreen.toml"

if [[ ! -d "$locks_dir" ]]; then
    notify-send "Noctalia Error" "Lockscreens directory not found: $locks_dir"
    exit 1
fi

# ── Mode 1: Apply a named layout directly (called from launcher /lock exec) ────
if [[ -n "${1:-}" ]]; then
    # Strip "Lock: " prefix if passed from noctalia launcher selection
    preset_name="${1#Lock: }"
    preset_name="${preset_name#Lockscreen: }"
    selected_file="$locks_dir/${preset_name}.toml"
    if [[ ! -f "$selected_file" ]]; then
        notify-send "Noctalia Error" "Lockscreen preset not found: ${preset_name}"
        exit 1
    fi
    cp "$selected_file" "$active_lock"
    # Reload noctalia config so the lockscreen change takes effect immediately
    noctalia msg config-reload &>/dev/null || true
    notify-send -t 2000 -i "preferences-desktop-theme" "Lockscreen Layout" "Applied: ${preset_name}"
    exit 0
fi

# ── Mode 2: Open dedicated lockscreen layout picker via noctalia launcher /lock 
if pgrep -x "noctalia" > /dev/null 2>&1; then
    noctalia msg panel-open launcher "/lock"
    exit 0
fi

# ── Fallback: Apply first available ───────────────────────────────────────────
mapfile -t presets < <(find "$locks_dir" -maxdepth 1 -name "*.toml" -exec basename -s .toml {} \; | sort)
if [[ ${#presets[@]} -eq 0 ]]; then
    notify-send "Noctalia Error" "No lockscreen presets found."
    exit 1
fi

choice="${presets[0]}"
cp "$locks_dir/${choice}.toml" "$active_lock"
notify-send -t 3000 -i "preferences-desktop-theme" "Lockscreen Layout" "Applied default: ${choice}"
exit 0
