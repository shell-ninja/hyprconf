#!/bin/bash

ICON="$HOME/.hyprconf/hypr/icons/pc.png"

# uptime cache file
uptime_file="$HOME/.config/hypr/.cache/.uptime"
[[ ! -f "$uptime_file" ]] && touch "$uptime_file"

uptime=$(uptime -p | cut -d' ' -f2-)
time=$(date +%d\/%m\/%Y\,\ %I:%M\ %p)

notify-send -i "$ICON" "Pc Usage" "Date: $time\nUsage: $uptime"
echo "$time -> $uptime" >> "$uptime_file"

exit 0
