#!/bin/bash

config_file="$HOME/.config/hypr/configs/monitor.conf"
auto_generated_setting=$(cat $config_file | grep "monitor=,preferred, auto, 1")

display() {
    # Get terminal width
    local cols=$(tput cols)
    
    # Use a here-document with quoted 'EOF' to treat content as literal text
    # This prevents issues with backticks or quotes inside the ASCII art
    local art
    art=$(cat << 'EOF'
   __  ___          _ __             ____    __          
  /  |/  /__  ___  (_) /____  ____  / __/__ / /___ _____ 
 / /|_/ / _ \/ _ \/ / __/ _ \/ __/ _\ \/ -_) __/ // / _ \
/_/  /_/\___/_//_/_/\__/\___/_/   /___/\__/\__/\_,_/ .__/
                                                  /_/    
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

display
printf "\n"

if [[ "$auto_generated_setting" ]]; then

    gum spin \
        --spinner minidot \
        --spinner.foreground "#bdb0ca" \
        --title.foreground "#bdb0ca" \
        --title "Setting up for your Monitor" -- \
        sleep 2

    monitor_name=$(xrandr | grep "connected" | awk '{print $1}')
    monitor_resolution=$(xrandr | grep "connected" | awk '{print $3}' | cut -d'+' -f1)

    display
    refresh_rate=$(gum choose \
                    --header \
                    "󰍹 Choose the refresh rate for your '$monitor_name' monitor:" \
                    --header.foreground "#bdb0ca" \
                    --selected.foreground "#bdb0ca" \
                    --cursor.foreground "#bdb0ca" \
                    "60Hz" "75Hz" "120Hz" "144Hz" "165Hz" "180Hz" "200Hz" "240Hz"
                )

    case $refresh_rate in
        60Hz)
            settings="monitor=${monitor_name},${monitor_resolution}@60, 0x0, 1"
            ;;
        75Hz)
            settings="monitor=${monitor_name},${monitor_resolution}@75, 0x0, 1"
            ;;
        120Hz)
            settings="monitor=${monitor_name},${monitor_resolution}@120, 0x0, 1"
            ;;
        144Hz)
            settings="monitor=${monitor_name},${monitor_resolution}@144, 0x0, 1"
            ;;
        165Hz)
            settings="monitor=${monitor_name},${monitor_resolution}@165, 0x0, 1"
            ;;
        180Hz)
            settings="monitor=${monitor_name},${monitor_resolution}@165, 0x0, 1"
            ;;
        200Hz)
            settings="monitor=${monitor_name},${monitor_resolution}@200, 0x0, 1"
            ;;
        240Hz)
            settings="monitor=${monitor_name},${monitor_resolution}@240, 0x0, 1"
            ;;
        *)
            echo -e ">< Nothing will be changed. Exiting.."
            exit 0
            ;;
    esac

    sed -i "s/$auto_generated_setting/$settings/" "$config_file"
fi
