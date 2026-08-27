#!/bin/bash

display() {
    cat << EOF
EOF
}

display() {
    # Get terminal width
    local cols=$(tput cols)
    
    # Use a here-document with quoted 'EOF' to treat content as literal text
    # This prevents issues with backticks or quotes inside the ASCII art
    local art
    art=$(cat << 'EOF'
            ╔═╗┬ ┬┌─┐┌┐┌┌─┐┌─┐  ╔═╗┌─┐┌┬┐┌┬┐┬┌┐┌┌─┐┌─┐            
            ║  ├─┤├─┤││││ ┬├┤   ╚═╗├┤  │  │ │││││ ┬└─┐            
────────────╚═╝┴ ┴┴ ┴┘└┘└─┘└─┘  ╚═╝└─┘ ┴  ┴ ┴┘└┘└─┘└─┘────────────
                                                     
EOF
)

    # Find the width of the widest line
    local max_width=0
    while IFS= read -r line; do
        local len=${#line}
        if (( len > max_width )); then
            max_width=$len
        fi
    done <<< "$art"

    # Calculate padding
    local padding=0
    if (( cols > max_width )); then
        padding=$(( (cols - max_width) / 2 ))
    fi

    # Print with padding
    local spaces=$(printf '%*s' "$padding" '')
    while IFS= read -r line; do
        printf "%s%s\n" "$spaces" "$line"
    done <<< "$art"
}   

# Script for setting window border width and roundness.
setting="$HOME/.config/hypr/configs/configs.lua"
rofiVars="$HOME/.config/rofi/rofi-vars.rasi"
kittyConf="$HOME/.config/kitty/kitty.conf"
gtk3Css="$HOME/.config/gtk-3.0/gtk.css"
gtk4Css="$HOME/.config/gtk-4.0/gtk.css"


# gum function to choose multiple settings
display
printf "\n  => Choose which settings you want to change\n  -> Need to select using the space bar\n"
echo
_hyprland_choice=$(gum choose \
    --header "Select settings:" \
    --header.foreground "#aab0c3" \
    --no-limit \
    --cursor.foreground "#aab0c3" \
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
        sed -i "s/^border[ ]*=.*/border        = $borderSize/g" "$setting"
        sed -i "s/border-size: .*/border-size: ${borderSize}px;/g" "$rofiVars"
        ;;
    "roundness")
        printf "\n[ <> ]\nSetting border roundness...\n\n"
        rounding=$(gum input --placeholder "Type border roundness...")
        while ! [[ "$rounding" =~ ^[0-9]+$ ]]; do
            printf "Invalid input. Please enter a number.\n"
            rounding=$(gum input --placeholder "Type border roundness...")
        done
        sed -i "s/^rounding[ ]*=.*/rounding      = $rounding/g" "$setting"
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
        sed -i "s/^inner_gap[ ]*=.*/inner_gap     = $gaps_in/g" "$setting"
        ;;
    "outer gap")
        printf "\n[ <> ]\nSetting outer gap...\n\n"
        gaps_out=$(gum input --placeholder "Type the outer gap...")
        while ! [[ "$gaps_out" =~ ^[0-9]+$ ]]; do
            printf "Invalid input. Please enter a number.\n"
            gaps_out=$(gum input --placeholder "Type the outer gap...")
        done
        sed -i "s/^outer_gap[ ]*=.*/outer_gap     = $gaps_out/g" "$setting"
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
        sed -i "s/^blur_size[ ]*=.*/blur_size     = $_blur_size/g" "$setting"
        sed -i "s/^blur_pass[ ]*=.*/blur_pass     = $_blur_passes/g" "$setting"
        ;;
    "opacity")
        printf "\n[ <> ]\nSetting opacity...\n"
        printf "   Applied to: Hyprland (active + inactive), kitty bg, GTK3, GTK4.\n\n"
        _opacity=$(gum input --placeholder "Opacity 0.0–1.0 (e.g. 0.85)...")
        while ! [[ "$_opacity" =~ ^(0(\.[0-9]+)?|1(\.0+)?)$ ]]; do
            printf "Invalid input. Enter a value between 0.0 and 1.0.\n"
            _opacity=$(gum input --placeholder "Opacity 0.0–1.0 (e.g. 0.85)...")
        done

        _opacity_deact=$(gum input --placeholder "Opacity 0.0–1.0 (e.g. 0.85)...")
        while ! [[ "$_opacity_deact" =~ ^(0(\.[0-9]+)?|1(\.0+)?)$ ]]; do
            printf "Invalid input. Enter a value between 0.0 and 1.0.\n"
            _opacity_deact=$(gum input --placeholder "Opacity 0.0–1.0 (e.g. 0.85)...")
        done

        # ─ Hyprland compositor opacity (active + inactive)
        sed -i "s/^opacity_act[ ]*=.*/opacity_act   = $_opacity/g" "$setting"
        sed -i "s/^opacity_deact[ ]*=.*/opacity_deact = $_opacity_deact/g" "$setting"

        # ─ Kitty: background_opacity applies per-pixel (bg transparent, text opaque)
        sed -i "s/^background_opacity.*/background_opacity $_opacity/" "$kittyConf"
        # Live-reload all running kitty windows
        pkill -SIGUSR1 kitty 2>/dev/null || true

        # ─ GTK3: rgba() bg — Hyprland blurs behind transparent bg pixels
        sed -i -E "s/rgba\(([0-9]+), ([0-9]+), ([0-9]+), [0-9.]+\)/rgba(\1, \2, \3, $_opacity)/g" "$gtk3Css"

        # ─ GTK4: alpha(@background, X)
        sed -i -E "s/alpha\(@background, [0-9.]+\)/alpha(@background, $_opacity)/g" "$gtk4Css"

        printf "\n[ ok ] Opacity set to %s everywhere.\n" "$_opacity"
        ;;
    "shadow")
        printf "\n[ <> ]\nSetting shadow range ( 0 means no shadow )...\n\n"
        _shd_rng=$(gum input --placeholder "Type the amount of shadow range...")
        while ! [[ "$_shd_rng" =~ ^[0-9]+(\.[0-9]+)?$ ]]; do
            printf "Invalid input. Please enter a number.\n"
            _shd_rng=$(gum input --placeholder "Type the amount of shadow range...")
        done
        sed -i "s/^shadow_range[ ]*=.*/shadow_range  = $_shd_rng/g" "$setting"
        ;;
    *)
        echo "Invalid choice: $user_choice"
        ;;
    esac
done

# Reload Hyprland
printf "\n[ ** ] Reloading Hyprland configuration...\n" && sleep 1
hyprctl reload
