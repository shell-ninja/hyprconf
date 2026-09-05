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
widgets_dir="$noctalia_dir/widgets"
active_bar="$noctalia_dir/20-bar.toml"
active_widgets="$noctalia_dir/70-widgets.toml"

if [[ ! -d "$bars_dir" ]]; then
    notify-send "Noctalia Error" "Bars directory not found: $bars_dir"
    exit 1
fi

clean_state_overrides() {
    local state_settings="$HOME/.local/state/noctalia/settings.toml"
    if [[ -f "$state_settings" ]]; then
        python3 -c "
import os, re
path = os.path.expanduser('~/.local/state/noctalia/settings.toml')
if os.path.isfile(path):
    with open(path, 'r') as f:
        lines = f.readlines()
    new_lines = []
    skipping = False
    for line in lines:
        m = re.match(r'^\s*(\[+)([a-zA-Z0-9_.\"]+)(\]+)', line)
        if m:
            sec = m.group(2).strip('\"')
            skipping = sec.startswith('bar') or sec.startswith('widget')
        if not skipping:
            new_lines.append(line)
    with open(path, 'w') as f:
        f.writelines(new_lines)
" 2>/dev/null || true
    fi
}

# ── Mode 1: Apply a named layout directly (called from launcher /bar exec) ─────
if [[ -n "${1:-}" ]]; then
    # Strip "Bar: " prefix if passed from noctalia launcher selection
    layout_name="${1#Bar: }"
    selected_bar="$bars_dir/${layout_name}.toml"
    selected_widgets="$widgets_dir/${layout_name}.toml"

    if [[ ! -f "$selected_bar" ]]; then
        notify-send "Noctalia Error" "Preset not found: ${layout_name}"
        exit 1
    fi

    # Apply bar configuration
    cp "$selected_bar" "$active_bar"

    # Apply matching widget configuration
    if [[ -f "$selected_widgets" ]]; then
        cp "$selected_widgets" "$active_widgets"
    elif [[ -f "$widgets_dir/${layout_name}-widgets.toml" ]]; then
        cp "$widgets_dir/${layout_name}-widgets.toml" "$active_widgets"
    fi

    # Clear conflicting state overrides so the preset's exact settings apply
    clean_state_overrides

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
if [[ -f "$widgets_dir/${choice}.toml" ]]; then
    cp "$widgets_dir/${choice}.toml" "$active_widgets"
fi
clean_state_overrides
notify-send -t 3000 -i "preferences-desktop-theme" "Bar Layout" "Noctalia not running. Applied default: ${choice}"
exit 0

