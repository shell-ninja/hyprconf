#!/usr/bin/env bash
# ==============================================================================
# noctalia-bar.sh — Bar Layout Switcher for Noctalia Shell
# Usage:
#   noctalia-bar.sh              → open Noctalia launcher at /cmd picker
#   noctalia-bar.sh <layout>     → apply <layout> directly (called by launcher)
# ==============================================================================

set -euo pipefail

noctalia_dir="$HOME/.config/noctalia"
bars_dir="$noctalia_dir/bars"
active_bar="$noctalia_dir/20-bar.toml"

if [[ ! -d "$bars_dir" ]]; then
    notify-send "Noctalia Error" "Bars directory not found: $bars_dir"
    exit 1
fi

# ── Mode 1: Apply a named layout directly (called from launcher /bar exec) ─────
if [[ -n "${1:-}" ]]; then
    # Strip "Bar: " prefix if passed from noctalia launcher selection
    layout_name="${1#Bar: }"
    selected_file="$bars_dir/${layout_name}.toml"
    if [[ ! -f "$selected_file" ]]; then
        notify-send "Noctalia Error" "Preset not found: ${layout_name}"
        exit 1
    fi
    cp "$selected_file" "$active_bar"
    # Reload noctalia config so the bar change takes effect immediately
    noctalia msg config-reload &>/dev/null || true
    notify-send -t 2000 -i "preferences-desktop-theme" "Bar Layout" "Applied: ${layout_name}"
    exit 0
fi

# ── Mode 2: Open dedicated bar layout picker via noctalia launcher /bar ─────────
if pgrep -x "noctalia" > /dev/null 2>&1; then
    noctalia msg panel-open launcher ">bar"
    exit 0
fi

# ── Fallback: start noctalia and then open launcher ───────────────────────────
mapfile -t layouts < <(find "$bars_dir" -maxdepth 1 -name "*.toml" -exec basename -s .toml {} \; | sort)
if [[ ${#layouts[@]} -eq 0 ]]; then
    notify-send "Noctalia Error" "No bar presets found."
    exit 1
fi

# Last resort: apply first available and notify
choice="${layouts[0]}"
cp "$bars_dir/${choice}.toml" "$active_bar"
notify-send -t 3000 -i "preferences-desktop-theme" "Bar Layout" "Noctalia not running. Applied default: ${choice}"
exit 0
