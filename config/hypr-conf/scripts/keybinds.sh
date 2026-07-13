#!/bin/bash

# Kill existing rofi instance if running
if pidof rofi > /dev/null; then
  pkill rofi
fi

# Define the keybinds file
KEYBINDS_FILE="$HOME/.config/hypr/.keybinds"

# Check if the file exists
if [[ ! -f "$KEYBINDS_FILE" ]]; then
    notify-send "Keybinds file not found: $KEYBINDS_FILE"
    exit 1
fi

# Format the keybinds for Rofi (replace ' | ' with a proper separator)
formatted_keybinds=$(sed 's/ | /  󰶻  /g' "$KEYBINDS_FILE")

# Show in Rofi as a single-line list
keybinds=$(echo -e "$formatted_keybinds" | rofi -dmenu -markup -theme ~/.config/rofi/themes/rofi-keybinds.rasi -p "Keybinds")

# Check if user selected a keybind
if [[ -z "$keybinds" ]]; then
    echo ">< No keybind selected."
    exit 1
fi
