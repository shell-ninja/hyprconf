#!/bin/bash

# Path to your theme.conf file
THEME_CONF="/usr/share/sddm/themes/SilentSDDM/configs/default-left.conf"

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


# Extract colors from pywal
FG=$(jq -r '.special.foreground' < ~/.cache/wal/colors.json)
BG=$(jq -r '.special.background' < ~/.cache/wal/colors.json)

# Backup your theme.conf
sudo cp "$THEME_CONF" "${THEME_CONF}.bak"

# Copy wallpaper to SDDM theme backgrounds
sudo cp "$wallPath" "/usr/share/sddm/themes/SilentSDDM/backgrounds/$wallName"

# Update theme.conf with new wallpaper and colors
sudo sed -i "s|^background =.*|background = \"$wallName\"|g" "$THEME_CONF"
sudo sed -i "s|^active-background-color =.*|active-background-color = \"$FG\"|g" "$THEME_CONF"
sudo sed -i "s|^background-color =.*|background-color = \"$BG\"|g" "$THEME_CONF"
sudo sed -i "s|^color =.*|color = \"$FG\"|g" "$THEME_CONF"
sudo sed -i "s|^active-border-color =.*|active-border-color = \"$FG\"|g" "$THEME_CONF"
sudo sed -i "s|^inactive-border-color =.*|inactive-border-color = \"$FG\"|g" "$THEME_CONF"
sudo sed -i "s|^active-content-color =.*|active-content-color = \"$FG\"|g" "$THEME_CONF"
sudo sed -i "s|^content-color =.*|content-color = \"$FG\"|g" "$THEME_CONF"
sudo sed -i "s|^border-color =.*|border-color = \"$FG\"|g" "$THEME_CONF"

notify-send "SDDM" "✅ Wallpaper & colors updated!"
echo "SDDM theme updated with new wallpaper and pywal colors!"
