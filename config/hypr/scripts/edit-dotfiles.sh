#!/bin/bash
# Rofi menu for Quick Edit / View of Settings (SUPER E)

hypr_dir="$HOME/.config/hypr"
hypr_configs="$hypr_dir/configs"
scripts="$hypr_dir/scripts"
rofi="$HOME/.config/rofi"
swaync="$HOME/.config/swaync"
waybar="$HOME/.config/waybar"
kitty="$HOME/.config/kitty"

menu(){
  printf "Hyprland\n"
  printf "Scripts\n"
  printf "Kitty\n"
  printf "Waybar\n"
  printf "Rofi\n"
  printf "Swaync\n"
}

notify() {
    if [ -n "$(command -v code)" ]; then
        notify-send "Opening with VS Code" "$1"
        editor="code"
    elif [ -n "$(command -v nvim)" ]; then
        notify-send "Opening with Neovim" "$1"
        editor="nvim"
    else
        notify-send "Opening with Nano" "$1"
        editor="nano"  # Default to nano if neither VS Code nor Neovim is found
    fi
}

main() {
    choice=$(menu | rofi -dmenu -config ~/.config/rofi/themes/rofi-edit-dots.rasi)

    case $choice in
        "Hyprland")
            notify "Hyprland (settings, keybinds and all)"
            $editor $hypr_configs
            ;;
        "Scripts")
            notify "Scripts (necessary scripts)"
            $editor $scripts
            ;;
        "Kitty")
            notify "Kitty (kitty terminal)"
            $editor $kitty
            ;;
        "Waybar")
            notify "Waybar (the top bar)"
            $editor $waybar
            ;;
        "Rofi")
            notify "Rofi (the app launcher)"
            $editor $rofi
            ;;
        "Swaync")
            notify "Swaync (sway notification center)"
            $editor $swaync
            ;;
        *)
            ;;
    esac
}

main
