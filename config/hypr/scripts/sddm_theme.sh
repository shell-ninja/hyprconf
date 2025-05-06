#!/bin/bash

# Path to your theme.conf file
THEME_CONF="/usr/share/sddm/themes/sequoia-sddm-theme/theme.conf"

# Wallpaper settings
wallDir="$HOME/.config/hypr/Wallpaper"
currentWall=$(cat "$HOME/.config/hypr/.cache/.wallpaper")

# Match supported image extensions
wallPath=$(find "$wallDir" -maxdepth 1 -type f -iname "${currentWall}.*" | head -n 1)
wallName=$(basename "$wallPath")

if [[ -z "$wallPath" || ! -f "$wallPath" ]]; then
    echo "Wallpaper not found: $wallPath"
    notify-send "SDDM" "❌ Wallpaper not found!"
    exit 1
fi

# Optional: blur logic (disabled)
# blurredWallName="blurred_$wallName"
# blurredWallPath="/tmp/$blurredWallName"
# convert "$wallPath" -blur 0x12 "$blurredWallPath" &>/dev/null || {
#     notify-send "SDDM" "❌ Failed to blur wallpaper!"
#     exit 1
# }

# Extract colors from pywal
FG=$(jq -r '.special.foreground' < ~/.cache/wal/colors.json)
BG=$(jq -r '.special.background' < ~/.cache/wal/colors.json)

# Backup your theme.conf
sudo cp "$THEME_CONF" "${THEME_CONF}.bak"

# Copy wallpaper to SDDM theme backgrounds
sudo cp "$wallPath" "/usr/share/sddm/themes/sequoia-sddm-theme/backgrounds/$wallName"

# Update theme.conf with new wallpaper and colors
sudo sed -i "s|^wallpaper=.*|wallpaper=\"backgrounds/$wallName\"|g" "$THEME_CONF"
sudo sed -i "s|^backgroundColour=.*|backgroundColour=\"$BG\"|g" "$THEME_CONF"
sudo sed -i "s|^accentColour=.*|accentColour=\"$FG\"|g" "$THEME_CONF"
sudo sed -i "s|^primaryColour=.*|primaryColour=\"$FG\"|g" "$THEME_CONF"
sudo sed -i "s|^popupsForegroundColour=.*|popupsForegroundColour=\"$FG\"|g" "$THEME_CONF"
sudo sed -i "s|^popupsBackgroundColour=.*|popupsBackgroundColour=\"$BG\"|g" "$THEME_CONF"

notify-send "SDDM" "✅ Wallpaper & colors updated!"
echo "SDDM theme updated with new wallpaper and pywal colors!"
