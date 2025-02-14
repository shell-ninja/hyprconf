#!/bin/bash

display() {
    cat << EOF
            ╔═╗┬ ┬┌─┐┌┐┌┌─┐┌─┐  ╔═╗┌─┐┌┬┐┌┬┐┬┌┐┌┌─┐┌─┐            
            ║  ├─┤├─┤││││ ┬├┤   ╚═╗├┤  │  │ │││││ ┬└─┐            
────────────╚═╝┴ ┴┴ ┴┘└┘└─┘└─┘  ╚═╝└─┘ ┴  ┴ ┴┘└┘└─┘└─┘────────────
EOF
}

# Script for setting window border width and roundness.
setting="$HOME/.config/hypr/configs/configs.conf"
dunst="$HOME/.config/dunst/dunstrc"
rofiVars="$HOME/.config/rofi/rofi-vars.rasi"


# gum function to choose multiple settings
display
printf "\n  => Choose which settings you want to change\n  -> Need to select using the space bar\n"
echo
_hyprland_choice=$(gum choose \
    --header "Select settings:" \
    --header.foreground "#c3cbd0" \
    --no-limit \
    --cursor.foreground "#c3cbd0" \
    "border size" \
    "roundness" \
    "inner gap" \
    "outer gap" \
    "blur" \
    "opacity" \
    "shadow" \
    "cancel"
)

# Convert the newline-separated string into an array
IFS=$'\n' read -rd '' -a primary_choice <<<"$_hyprland_choice"

# Exit if "cancel" is chosen
if [[ -n "$_hyprland_choice" && "${primary_choice[*]}" =~ "cancel" ]]; then
    exit 0
fi

# Loop through each chosen setting
for user_choice in "${primary_choice[@]}"; do
    clear
    case "$user_choice" in
    "border size")
        printf "\n[ <> ]\nSetting border size...\n\n"
        borderSize=$(gum input --placeholder "Type border width...")
        while ! [[ "$borderSize" =~ ^[0-9]+$ ]]; do
            printf "Invalid input. Please enter a number.\n"
            borderSize=$(gum input --placeholder "Type border width...")
        done
        sed -i "s/\$border = .*/\\\$border = $borderSize/g" "$setting"
        sed -i "s/frame_width = .*/frame_width = $borderSize/g" "$dunst"
        sed -i "s/border-size: .*/border-size: ${borderSize}px;/g" "$rofiVars"
        ;;
    "roundness")
        printf "\n[ <> ]\nSetting border roundness...\n\n"
        rounding=$(gum input --placeholder "Type border roundness...")
        while ! [[ "$rounding" =~ ^[0-9]+$ ]]; do
            printf "Invalid input. Please enter a number.\n"
            rounding=$(gum input --placeholder "Type border roundness...")
        done
        sed -i 's/\$rounding = .*/$rounding = '"$rounding"'/g' "$setting"
        sed -i "s/^[[:space:]]*corner_radius[[:space:]]*= .*/corner_radius = $((rounding / 2))/g" "$dunst"
        sed -i "s/radius: .*/radius: ${rounding}px;/g" "$rofiVars"
        sed -i "s/radius-second: .*/radius-second: $((rounding / 2))px;/g" "$rofiVars"
        ;;
    "inner gap")
        printf "\n[ <> ]\nSetting inner gap...\n\n"
        gaps_in=$(gum input --placeholder "Type the inner gap...")
        while ! [[ "$gaps_in" =~ ^[0-9]+$ ]]; do
            printf "Invalid input. Please enter a number.\n"
            gaps_in=$(gum input --placeholder "Type the inner gap...")
        done
        sed -i "s/\$inner_gap = .*/\\\$inner_gap = $gaps_in/g" "$setting"
        ;;
    "outer gap")
        printf "\n[ <> ]\nSetting outer gap...\n\n"
        gaps_out=$(gum input --placeholder "Type the outer gap...")
        while ! [[ "$gaps_out" =~ ^[0-9]+$ ]]; do
            printf "Invalid input. Please enter a number.\n"
            gaps_out=$(gum input --placeholder "Type the outer gap...")
        done
        sed -i "s/\$outer_gap = .*/\\\$outer_gap = $gaps_out/g" "$setting"
        ;;
    "blur")
        printf "\n[ <> ]\nSetting blur...\n\n"
        _blur_size=$(gum input --placeholder "Type the amount of blur size...")
        while ! [[ "$_blur_size" =~ ^[0-9]+$ ]]; do
            printf "Invalid input. Please enter a number.\n"
            _blur_size=$(gum input --placeholder "Type the amount of blur size...")
        done
            _blur_passes=$(gum input --placeholder "Type the amount of blur passes...")
        while ! [[ "$_blur_passes" =~ ^[0-9]+$ ]]; do
            printf "Invalid input. Please enter a number.\n"
            _blur_passes=$(gum input --placeholder "Type the amount of blur passes...")
        done
        sed -i "s/\$blur_size = .*/\\\$blur_size = $_blur_size/g" "$setting"
        sed -i "s/\$blur_passes = .*/\\\$blur_passes = $_blur_passes/g" "$setting"
        ;;
    "opacity")
        printf "\n[ <> ]\nSetting opacity...\n\n"
        _act_op=$(gum input --placeholder "Type the amount of active opacity (ex: 0.9)...")
        while ! [[ "$_act_op" =~ ^[0-9]+(\.[0-9]+)?$ ]]; do
            printf "Invalid input. Please enter a number.\n"
            _act_op=$(gum input --placeholder "Type the amount of active opacity (ex: 0.9)...")
        done
            _inact_op=$(gum input --placeholder "Type the amount of inactive opacity (ex: 0.9)...")
        while ! [[ "$_inact_op" =~ ^[0-9]+(\.[0-9]+)?$ ]]; do
            printf "Invalid input. Please enter a number.\n"
            _inact_op=$(gum input --placeholder "Type the amount of inactive opacity (ex: 0.9)...")
        done
        sed -i "s/\$opacity_act = .*/\\\$opacity_act = $_act_op/g" "$setting"
        sed -i "s/\$opacity_deact = .*/\\\$opacity_deact = $_inact_op/g" "$setting"
        ;;
    "shadow")
        printf "\n[ <> ]\nSetting shadow range ( 0 means no shadow )...\n\n"
        _shd_rng=$(gum input --placeholder "Type the amount of shadow range...")
        while ! [[ "$_shd_rng" =~ ^[0-9]+(\.[0-9]+)?$ ]]; do
            printf "Invalid input. Please enter a number.\n"
            _shd_rng=$(gum input --placeholder "Type the amount of shadow range...")
        done
        sed -i "s/\$shadow_range = .*/\\\$shadow_range = $_shd_rng/g" "$setting"
        ;;
    *)
        echo "Invalid choice: $user_choice"
        ;;
    esac
done

# Reload Hyprland
printf "\n[ ** ] Reloading Hyprland configuration...\n" && sleep 1
killall dunst
hyprctl reload
