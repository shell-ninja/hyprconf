#!/bin/bash

# _______________________________________________________________ #

# Define directories and files
swww_cache_dir="$HOME/.cache/swww"
hypr_cache_dir="$HOME/.config/hypr/.cache"
engine_file="$hypr_cache_dir/.engine"
current_wallpaper="$hypr_cache_dir/current_wallpaper.png"

engine=$(cat "$engine_file")

if [[ "$engine" = "swww" ]]; then
    echo "$engine"
    # Define the path to the swww cache directory
    cache_dir="$HOME/.cache/swww/"
    # Get a list of monitor outputs
    monitor_outputs=($(ls "$cache_dir"))
    # Initialize a flag to determine if the ln command was executed
    ln_success=false
    # Loop through monitor outputs
    for output in "${monitor_outputs[@]}"; do
        # Construct the full path to the cache file
        cache_file="$cache_dir$output"

        # Check if the cache file exists for the current monitor output
        if [ -f "$cache_file" ]; then
            # Get the wallpaper path from the cache file
            wallpaper_path=$(cat "$cache_file")

            # Copy the wallpaper to the location Rofi can access
            if ln -sf "$wallpaper_path" "$HOME/.config/hypr/.cache/current_wallpaper.png"; then
                ln_success=true  # Set the flag to true upon successful execution
            fi

            break  # Exit the loop after processing the first found monitor output
        fi
    done

    # Check the flag before executing further commands
    if [ "$ln_success" = true ]; then
        wal -i "$wallpaper_path"
    fi
elif [[ "$engine" = "hyprpaper" ]]; then
    echo "$engine"
    current_wallpaper="$HOME/.config/hypr/.cache/current_wallpaper.png"
    if [[ -f "$current_wallpaper" ]]; then
        wal -i "$current_wallpaper"
    else
        echo "No $current_wallpaper found"
    fi
fi

# Function to convert hex color code to rgba
hex_to_rgba() {
    hex=$1
    r=$(printf '%s' ${hex:1:2})
    g=$(printf '%s' ${hex:3:2})
    b=$(printf '%s' ${hex:5:2})
    a=$(printf '%s' ${hex:7:2})

    # rgba="rgba($r$g$b$a)"
    rgba="rgba($r$g$b$a"FF")"
    echo $rgba
}

hex_to_rgba_opacity() {
    hex=$1
    r=$(printf '%s' ${hex:1:2})
    g=$(printf '%s' ${hex:3:2})
    b=$(printf '%s' ${hex:5:2})
    a=$(printf '%s' ${hex:7:2})

    # rgba="rgba($r$g$b$a)"
    rgbo="rgba($r$g$b$a"66")"
    echo $rgbo
}

# Extract colors from colors.json
colors_file=~/.cache/wal/colors.json
if [ -f $colors_file ]; then
    background_color=$(jq -r '.special.background' "$colors_file")
    foreground_color=$(jq -r '.special.foreground' "$colors_file")
    other_color=$(jq -r '.colors.color5' "$colors_file")

  # Usage example
    hex_color="$foreground_color"
    hex_color_other="$other_color"

    rgba_color=$(hex_to_rgba $hex_color)
    rgba_color_other=$(hex_to_rgba $hex_color_other)
    rgba_color_opacity=$(hex_to_rgba_opacity $hex_color)

    # Set Hyprland active border color based on foreground color
    hyprland_config=~/.config/hypr/configs/settings.conf
    hyprlock_config=~/.config/hypr/hyprlock.conf
    sed -i "s/col.active_border .*$/col.active_border = $rgba_color/g" "$hyprland_config"
    sed -i "s/col.inactive_border .*$/col.inactive_border = $rgba_color_other/g" "$hyprland_config"

# for hyprlock
    sed -i "s/outer_color = .*$/outer_color = $rgba_color_opacity/" "$hyprlock_config"
    sed -i "s/inner_color = .*$/inner_color = $rgba_color_opacity/" "$hyprlock_config"
    sed -i "s/border_color = .*$/border_color = $rgba_color_opacity/" "$hyprlock_config"
    sed -i "s/font_color = .*$/font_color = $rgba_color/" "$hyprlock_config"
    sed -i "s/^[c]olor = .*$/color = $rgba_color/" "$hyprlock_config"
    
    # Reload Hyprland configuration (optional)
    hyprctl reload
else
    echo "No file found named colors.json"
fi

# setting rofi theme
mode_file="$HOME/.config/hypr/.cache/.mode"
current_mode=$(cat "$mode_file")
if [ "$current_mode" == "dark" ]; then
    ln -sf ~/.cache/wal/colors-rofi-dark.rasi ~/.config/rofi/themes/rofi-pywal.rasi
else
    ln -sf ~/.cache/wal/colors-rofi-light.rasi ~/.config/rofi/themes/rofi-pywal.rasi
fi

# setting waybar colors
ln -sf ~/.cache/wal/colors-waybar.css ~/.config/waybar/style/theme.css

# setting waybar colors for swaync
ln -sf ~/.cache/wal/colors-waybar.css ~/.config/swaync/colors.css

# ----- Dunst
dunst_file="$HOME/.config/dunst/dunstrc"

# Function to update Dunst colors
update_dunst_colors() {
    frame=$(jq -r '.special.foreground' "$colors_file")
    low_bg=$(jq -r '.colors.color0' "$colors_file")
    low_fg=$(jq -r '.colors.color7' "$colors_file")
    normal_bg=$(jq -r '.special.background' "$colors_file")
    normal_fg=$(jq -r '.special.foreground' "$colors_file")

    echo "$normal_bg"
    echo "$normal_fg"

    # Update Dunst configuration
    sed -i "s/frame_color = .*/frame_color = \"$frame\"/g" "$dunst_file"
    sed -i "/^\[urgency_low\]/,/^\[/ s/^    background = .*/    background = \"$low_bg\"/g" "$dunst_file"
    sed -i "/^\[urgency_low\]/,/^\[/ s/^    foreground = .*/    foreground = \"$low_fg\"/g" "$dunst_file"
    sed -i "/^\[urgency_normal\]/,/^\[/ s/^    background = .*/    background = \"${normal_bg}80\"/g" "$dunst_file"
    sed -i "/^\[urgency_normal\]/,/^\[/ s/^    foreground = .*/    foreground = \"$normal_fg\"/g" "$dunst_file"
    sed -i "/^\[urgency_critical\]/,/^\[/ s/^    foreground = .*/    foreground = \"$normal_fg\"/g" "$dunst_file"
}

update_dunst_colors

# Extract colors from colors.json
colors_file=~/.cache/wal/colors.json

# remove these part if you don't like the colors according to your wallpaper.
if [ -f $colors_file ]; then
    background_color=$(jq -r '.special.background' "$colors_file")
    foreground_color=$(jq -r '.special.foreground' "$colors_file")

    # Update VS Code settings
    vscode_settings_file="$HOME/.config/Code/User/settings.json"
    if [ -f "$vscode_settings_file" ]; then
    cat <<EOF >"$vscode_settings_file"
{
    "editor.mouseWheelZoom": true,
    "workbench.startupEditor": "none",
    "editor.fontSize": 20,
    "editor.fontFamily": "'JetBrainsMono Nerd Font', 'Droid Sans Mono', 'monospace', monospace",
    "editor.fontLigatures": true,
    "window.menuBarVisibility": "toggle",
    "editor.smoothScrolling": true,
    "editor.scrollbar.horizontal": "hidden",
    "editor.mouseWheelScrollSensitivity": 2,
    "editor.wordWrap": "on",
    "editor.cursorBlinking": "expand",
    "terminal.integrated.fontSize": 18,
    "workbench.iconTheme": "catppuccin-mocha",
    "workbench.colorTheme": "Theme Darker",
    "git.enableSmartCommit": true,
    "files.autoSave": "afterDelay",
    // You can remove these part if you don't like the colors according to your wallpaper from the "$HOME/.config/hypr/scripts/pywal.sh" script, from 204-221 lines.
    // or you can totally remove the vs-code themming part from the script if you want to set and use your custom settings. if you don't do that, then your settings will be replaced/over writen by the default config.

    "workbench.colorCustomizations": {
        "editor.background": "$background_color",
        "sideBar.background": "$background_color",
        "sideBar.border": "$background_color",
        "sideBar.foreground": "$foreground_color",
        "editorGroupHeader.tabsBackground": "#191b274b",
        "activityBar.background": "$background_color",
        "activityBar.border": "$background_color",
        "activityBar.foreground": "$foreground_color",
        "tab.activeBackground": "#13151f",
        "tab.activeForeground": "#ffffff",
        "tab.activeBorder": "$background_color",
        "tab.border": "$background_color",
        "tab.inactiveBackground": "$background_color",
        "tab.inactiveForeground": "$foreground_color",
        "terminal.foreground": "$foreground_color",
        "terminal.background": "$background_color"
    },
}
EOF
    fi
fi

# ------------------------
