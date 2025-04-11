#!/bin/bash

# Path to your theme.conf file
THEME_CONF="/usr/share/sddm/themes/minimal_sddm/theme.conf"

# Wallpaper settings
if [[ -f "$HOME/.config/hypr/.cache/.theme" ]]; then
    theme=$(cat "$HOME/.config/hypr/.cache/.theme")
    wallDir="$HOME/.config/hypr/Wallpapers/${theme}"

    # Extract colors from pywal
    themeCss="$HOME/.config/waybar/colors/${theme}.css"
    FG=$(grep '@define-color foreground' "$themeCss" | cut -d ' ' -f3 | tr -d ';')
    BG=$(grep '@define-color background' "$themeCss" | cut -d ' ' -f3 | tr -d ';')
else
    wallDir="$HOME/.config/hypr/Wallpaper"

    # Extract colors from pywal
    FG=$(jq -r '.special.foreground' < ~/.cache/wal/colors.json)
    BG=$(jq -r '.special.background' < ~/.cache/wal/colors.json)
fi

currentWall=$(cat "$HOME/.config/hypr/.cache/.wallpaper")
wall="${wallDir}/${currentWall}.*"

wallPath=$(ls $wall 2>/dev/null | head -n 1)
wallName=$(basename "$wallPath")

if [[ -z "$wallPath" || ! -f "$wallPath" ]]; then
    echo "Wallpaper not found: $wallPath"
    notify-send "SDDM" "❌ Wallpaper not found!"
    exit 1
fi

# Create blurred version of wallpaper
blurredWallName="blurred_$wallName"
blurredWallPath="/tmp/$blurredWallName"
convert "$wallPath" -blur 0x12 "$blurredWallPath" &> /dev/null || {
    notify-send "SDDM" "❌ Failed to blur wallpaper!"
    exit 1
}


# Backup your theme.conf
sudo cp "$THEME_CONF" "${THEME_CONF}.bak"

# Copy blurred wallpaper to SDDM theme directory
sudo mv "$blurredWallPath" "/usr/share/sddm/themes/minimal_sddm/backgrounds/${wallName}"
# suod rm -rf "$blurredWallPath"

# Update theme.conf with blurred wallpaper and pywal colors
sed -i "s|Background=.*|Background=\"backgrounds/$wallName\"|g" "$THEME_CONF"
sed -i "s|UserPictureBorderColor=.*|UserPictureBorderColor=\"$FG\"|g" "$THEME_CONF"
sed -i "s|UserPictureColor=.*|UserBorderColor=\"$FG\"|g" "$THEME_CONF"
sed -i "s|TextFieldColor=.*|TextFieldColor=\"$FG\"|g" "$THEME_CONF"
sed -i "s|TextFieldTextColor=.*|TextFieldTextColor=\"$BG\"|g" "$THEME_CONF"
sed -i "s|LoginButtonTextColor=.*|LoginButtonTextColor=\"$BG\"|g" "$THEME_CONF"
sed -i "s|LoginButtonBgColor=.*|LoginButtonBgColor=\"$FG\"|g" "$THEME_CONF"
sed -i "s|PopupBgColor=.*|PopupBgColor=\"$FG\"|g" "$THEME_CONF"
sed -i "s|PopupHighlightColor=.*|PopupHighlightColor=\"$BG\"|g" "$THEME_CONF"
sed -i "s|SessionButtonColor=.*|SessionButtonColor=\"$FG\"|g" "$THEME_CONF"
sed -i "s|SessionIconColor=.*|SessionIconColor=\"$BG\"|g" "$THEME_CONF"
sed -i "s|PowerButtonColor=.*|PowerButtonColor=\"$FG\"|g" "$THEME_CONF"
sed -i "s|PowerIconColor=.*|PowerIconColor=\"$BG\"|g" "$THEME_CONF"
sed -i "s|DateColor=.*|DateColor=\"$FG\"|g" "$THEME_CONF"
sed -i "s|TimeColor=.*|TimeColor=\"$FG\"|g" "$THEME_CONF"

notify-send "SDDM" "✅ Blurred wallpaper & colors updated!"
# echo "SDDM theme updated with blurred wallpaper!"
