#!/usr/bin/env bash
# ==============================================================================
# noctalia-launcher.sh — Launcher Theme Switcher for Noctalia Shell
# Usage:
#   noctalia-launcher.sh              → open Noctalia launcher at /cmd picker
#   noctalia-launcher.sh <style>      → apply <style> directly (from launcher)
# ==============================================================================

set -euo pipefail

noctalia_dir="$HOME/.config/noctalia"
launchers_dir="$noctalia_dir/launchers"
active_launcher="$noctalia_dir/30-launcher.toml"

if [[ ! -d "$launchers_dir" ]]; then
    notify-send "Noctalia Error" "Launchers directory not found: $launchers_dir"
    exit 1
fi

# ── Mode 1: Apply a named style directly (called from launcher cmd exec) ───────
if [[ -n "${1:-}" ]]; then
    # Strip "Launcher: " prefix if passed from noctalia launcher selection
    style_name="${1#Launcher: }"
    selected_file="$launchers_dir/${style_name}.toml"
    if [[ ! -f "$selected_file" ]]; then
        notify-send "Noctalia Error" "Launcher preset not found: ${style_name}"
        exit 1
    fi
    cp "$selected_file" "$active_launcher"
    notify-send -t 2000 -i "preferences-desktop-theme" "Launcher Style" "Applied: ${style_name}"
    exit 0
fi

# ── Mode 2: Open noctalia launcher at /cmd for interactive picking ─────────────
if pgrep -x "noctalia" > /dev/null 2>&1; then
    noctalia msg panel-open launcher "/cmd"
    exit 0
fi

# ── Fallback: apply first available and notify ─────────────────────────────────
mapfile -t themes < <(find "$launchers_dir" -maxdepth 1 -name "*.toml" -exec basename -s .toml {} \; | sort)
if [[ ${#themes[@]} -eq 0 ]]; then
    notify-send "Noctalia Error" "No launcher presets found."
    exit 1
fi

choice="${themes[0]}"
cp "$launchers_dir/${choice}.toml" "$active_launcher"
notify-send -t 3000 -i "preferences-desktop-theme" "Launcher Style" "Noctalia not running. Applied default: ${choice}"
exit 0
