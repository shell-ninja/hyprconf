#!/bin/bash

swww_cache="$HOME/.cache/swww"
scripts_dir="$HOME/.config/hypr/scripts"
themes_dir="$HOME/.config/hypr/.cache/colors"
engine_file="$HOME/.config/hypr/.cache/.engine"
current_wallpaper="$HOME/.config/hypr/.cache/current_wallpaper.png"

[[ ! -d "$themes_dir" ]] && mkdir -p "$themes_dir"

wallName="$(cat "$HOME/.config/hypr/.cache/.wallpaper")"
engine=$(cat "$engine_file")

if [[ ! -d "${themes_dir}/${wallName}-colors" ]]; then
        current_wallpaper="$HOME/.config/hypr/.cache/current_wallpaper.png"
        if [[ -f "$current_wallpaper" ]]; then
            wal -e -q -i "$current_wallpaper"
        fi
    [[ -d "$HOME/.cache/wal" ]] && cp -r "$HOME/.cache/wal" "${themes_dir}/${wallName}-colors"
fi

# Extract colors from colors.json
colors_file="${themes_dir}/${wallName}-colors/colors.json"

# hyprland colors.
hyprcolor="$HOME/.config/hypr/configs/colors-hyprland.conf"
ln -sf "${themes_dir}/${wallName}-colors/colors-hyprland.conf" "$HOME/.config/hypr/configs/colors.conf"

# setting kitty colors 
kitty_colors="${themes_dir}/${wallName}-colors/colors-kitty.conf"
kitty="$HOME/.config/kitty/kitty.conf"

# Define a function to extract a specific color
extract_color() {
  color_keyword="$1"
  grep "^${color_keyword}" $kitty_colors | awk '{print $2}'
}

# Extract background and foreground colors
active_border_color=$(extract_color "foreground")
inactive_border_color=$(extract_color "color5")

# kitty colors
sed -i "s/active_border_color .*$/active_border_color $active_border_color/g" "$kitty"
sed -i "s/inactive_border_color .*$/inactive_border_color $inactive_border_color/g" "$kitty"

[[ -f "$HOME/.config/kitty/colors-kitty.conf" ]] && rm "$HOME/.config/kitty/colors-kitty.conf"
cp "${themes_dir}/${wallName}-colors/colors-kitty.conf" "$HOME/.config/kitty/"
kitty @ set-color -a "$kitty"

# setting rofi theme
[[ -f "$HOME/.config/rofi/themes/rofi-colors.rasi" ]] && rm "$HOME/.config/rofi/themes/rofi-colors.rasi"
cp "${themes_dir}/${wallName}-colors/colors-rofi-dark.rasi" "$HOME/.config/rofi/themes/rofi-colors.rasi"

# setting waybar colors
[[ -f "$HOME/.config/waybar/style/theme.css" ]] && rm "$HOME/.config/waybar/style/theme.css"
cp "${themes_dir}/${wallName}-colors/colors-waybar.css" "$HOME/.config/waybar/style/theme.css"

# setting swaync colors
[[ -f "$HOME/.config/swaync/colors.css" ]] && rm "$HOME/.config/swaync/colors.css"
cp "${themes_dir}/${wallName}-colors/colors-waybar.css" "$HOME/.config/swaync/colors.css"

# ----- Dunst
dunst_file="$HOME/.config/dunst/dunstrc"

# Function to update Dunst colors
update_dunst_colors() {
    frame=$(jq -r '.special.foreground' "$colors_file")
    low_bg=$(jq -r '.colors.color0' "$colors_file")
    low_fg=$(jq -r '.colors.color7' "$colors_file")
    normal_bg=$(jq -r '.special.background' "$colors_file")
    normal_fg=$(jq -r '.special.foreground' "$colors_file")

    # Update Dunst configuration
    sed -i "s/frame_color = .*/frame_color = \"$frame\"/g" "$dunst_file"
    sed -i "/^\[urgency_low\]/,/^\[/ s/^    background = .*/    background = \"$low_bg\"/g" "$dunst_file"
    sed -i "/^\[urgency_low\]/,/^\[/ s/^    foreground = .*/    foreground = \"$low_fg\"/g" "$dunst_file"
    sed -i "/^\[urgency_normal\]/,/^\[/ s/^    background = .*/    background = \"${normal_bg}80\"/g" "$dunst_file"
    sed -i "/^\[urgency_normal\]/,/^\[/ s/^    foreground = .*/    foreground = \"$normal_fg\"/g" "$dunst_file"
    sed -i "/^\[urgency_critical\]/,/^\[/ s/^    foreground = .*/    foreground = \"$normal_fg\"/g" "$dunst_file"
}

update_dunst_colors


# updated system update gum colors.
sysupd_script="$scripts_dir/pkgupdate.sh"
monitor_setup_script="$scripts_dir/monitor.sh"
settings_script="$scripts_dir/settings.sh"

background_color=$(jq -r '.special.background' "$colors_file")
foreground_color=$(jq -r '.special.foreground' "$colors_file")

sed -i "s/--prompt.foreground .*/--prompt.foreground \"$foreground_color\" \\\/g" "$sysupd_script"
sed -i "s/--selected.background .*/--selected.background \"$foreground_color\" \\\/g" "$sysupd_script"
sed -i "s/--selected.foreground .*/--selected.foreground \"$background_color\" \\\/g" "$sysupd_script"
sed -i "s/--spinner.foreground .*/--spinner.foreground \"$foreground_color\" \\\/g" "$sysupd_script"
sed -i "s/--spinner.foreground .*/--spinner.foreground \"$foreground_color\" \\\/g" "$monitor_setup_script"
sed -i "s/--title.foreground .*/--title.foreground \"$foreground_color\" \\\/g" "$monitor_setup_script"
sed -i "s/--header.foreground .*/--header.foreground \"$foreground_color\" \\\/g" "$monitor_setup_script"
sed -i "s/--selected.foreground .*/--selected.foreground \"$foreground_color\" \\\/g" "$monitor_setup_script"
sed -i "s/--cursor.foreground .*/--cursor.foreground \"$foreground_color\" \\\/g" "$monitor_setup_script"
sed -i "s/--header.foreground .*/--header.foreground \"$foreground_color\" \\\/g" "$settings_script"
sed -i "s/--cursor.foreground .*/--cursor.foreground \"$foreground_color\" \\\/g" "$settings_script"


# remove these part if you don't like the colors according to your wallpaper.
if [ -f $colors_file ]; then
    background_color=$(jq -r '.special.background' "$colors_file")
    foreground_color=$(jq -r '.special.foreground' "$colors_file")

    # Update VS Code settings
    vscode_settings_file="$HOME/.config/Code/User/settings.json"
    if [[ -f "$vscode_settings_file" ]]; then
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
else
    exit 0
fi

# Refresh the scripts
sleep 0.5
"${scripts_dir}/Refresh.sh"

# ------------------------
