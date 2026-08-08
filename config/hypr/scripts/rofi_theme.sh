#!/usr/bin/env sh

rofiConf="$HOME/.config/rofi/themes/rofi-select_theme.rasi"
rofiStyleDir="$HOME/.config/rofi/menu"
rofiAssetDir="$HOME/.config/rofi/assets"
menu_select_script="$HOME/.config/hypr/scripts/menu.sh"

# Set rofi scaling
[[ "${rofiScale}" =~ ^[0-9]+$ ]] || rofiScale=10
r_scale="configuration {font: \"JetBrainsMono Nerd Font ${rofiScale}\";}"
elem_border=$(( hypr_border * 5 ))
icon_border=$(( elem_border - 5 ))

# Scale for monitor
mon_x_res=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .width')
mon_scale=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .scale' | sed "s/\.//")
mon_x_res=$(( mon_x_res * 100 / mon_scale ))

# Generate config
elm_width=$(( (20 + 12 + 16 ) * rofiScale ))
max_avail=$(( mon_x_res - (4 * rofiScale) ))
col_count=$(( max_avail / elm_width ))
[[ "${col_count}" -gt 5 ]] && col_count=5
r_override="window{width:100%;} listview{columns:${col_count};} element{orientation:vertical;border-radius:${elem_border}px;} element-icon{border-radius:${icon_border}px;size:20em;} element-text{enabled:false;}"

# List available styles and present in rofi menu with icons
style_files=($(ls "$rofiAssetDir"/*.png))

# Extract only the file names for display
style_names=("${style_files[@]##*/}")

# Prepare the list for rofi with icons
rofi_list=""
for style_name in "${style_names[@]}"; do
    style_num=$(echo "$style_name" | awk -F '-' '{print $2}' | awk -F '.' '{print $1}')
    rofi_list+="${style_name}\x00icon\x1f${rofiAssetDir}/${style_name}\n"
done

# Present the list of styles using rofi and get the selected style
selected_style=$(echo -e "$rofi_list" | rofi -dmenu -markup-rows -theme-str "$r_override" -config "$rofiConf" -p "Select Rofi theme")
echo "selected style: $selected_style"

# If a selection was made, apply the new style
if [ -n "$selected_style" ]; then
    selected_style_number=$(echo "$selected_style" | awk -F '-' '{print $2}' | awk -F '.' '{print $1}')
    selected_style_path=$(ls ${rofiStyleDir}/style-${selected_style_number}.rasi)

    notify-send -t 2000 -i "$HOME/.config/rofi/assets/style-${selected_style_number}.png" "Theme applied"

    # Update the menu_select.sh script with the selected theme
    sed -i "s|^theme=.*|theme='style-${selected_style_number}'|" "$menu_select_script"
fi
