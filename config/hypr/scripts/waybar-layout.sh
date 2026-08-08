#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

# Define directories
waybar_layouts="$HOME/.config/waybar/configs"
waybar_config="$HOME/.config/waybar/config"
waybar_styles="$HOME/.config/waybar/style"
waybar_style="$HOME/.config/waybar/style.css"
script_dir="$HOME/.config/hypr/scripts"
window_rules="$HOME/.config/hypr/configs/wrules.lua"
rofi_config="$HOME/.config/rofi/themes/rofi-waybar.rasi"
rofi_menu="$HOME/.config/rofi/menu/menu.rasi"
rofi_clipboard="$HOME/.config/rofi/themes/rofi-clipboard.rasi"

# Function to display menu options
menu() {
    options=()
    while IFS= read -r file; do
        options+=("$(basename "$file")")
    done < <(find "$waybar_layouts" -maxdepth 1 -type f -exec basename {} \; | sort)

    printf '%s\n' "${options[@]}"
}

# Apply selected configuration
# Apply selected configuration
apply_config() {
    layout_file="$waybar_layouts/$1"
    style_file="$waybar_styles/$1.css"

    echo "Linking $layout_file to $waybar_config"
    echo "Linking $style_file to $waybar_style"

    ln -sf "$layout_file" "$waybar_config"
    ln -sf "$style_file" "$waybar_style"

    # ---------- Window rule (blur) for Waybar ----------
    if grep -q "hl\.layer_rule" "$window_rules" 2>/dev/null; then
        # --- Lua variant: hl.layer_rule({ match = { namespace = "^waybar$" }, blur = ... }) ---
        if [[ "$1" == "full-top" || "$1" == "rounded-top" ]]; then
            sed -i '/hl\.layer_rule({ match = { namespace = "\^waybar\$" }/ s/blur = false/blur = true/' "$window_rules"
        else
            sed -i '/hl\.layer_rule({ match = { namespace = "\^waybar\$" }/ s/blur = true/blur = false/' "$window_rules"
        fi
    else
        # --- .conf variant: layerrule = match:namespace waybar, blur on ---
        if [[ "$1" == "full-top" || "$1" == "rounded-top" ]]; then
            sed -i "/^#layerrule = match:namespace waybar, blur on$/ s/#//" "$window_rules"
        else
            sed -i "/^layerrule = match:namespace waybar, blur on/ s/^/#/" "$window_rules"
        fi
    fi
    # ---------------------------------------------------------

    # Rofi adjustments (unchanged)
    if [[ "$1" == *"-top"* && ! "$1" == "dual-tone-top" && ! "$1" == "rounded-top" && ! "$1" == "border-top" ]]; then
        sed -i "s/location:.*/location: northWest;/g" "$rofi_menu"
        # ... rest of rofi positioning unchanged ...
    fi

    restart_waybar
}

# Restart Waybar
restart_waybar() {
    killall waybar
    sleep 0.1  # Delay for Waybar to completely terminate
    waybar &
}

# Main function
main() {
    choice=$(menu | rofi -dmenu -config "$rofi_config")

    if [[ -z "$choice" ]]; then
        echo "No option selected. Exiting."
        exit 0
    fi

    case $choice in
        *)
            apply_config "$choice"
            ;;
    esac
}

if pgrep -x "rofi" &> /dev/null; then
    pkill rofi
    exit 0
fi

main

sleep 1
hyprctl reload
