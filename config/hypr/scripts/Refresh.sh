#!/bin/bash
# Refresh.sh — Restart notification daemon and reload Hyprland.

# Kill running daemons
_ps=(dunst swaync rofi)
for _prs in "${_ps[@]}"; do
    pidof "${_prs}" &>/dev/null && pkill "${_prs}"
done

sleep 0.1

# Start notification daemon
if [[ -n "$(command -v swaync)" ]]; then
    swaync &
elif [[ -n "$(command -v dunst)" ]]; then
    dunst &
fi

sleep 0.3
hyprctl reload

exit 0
