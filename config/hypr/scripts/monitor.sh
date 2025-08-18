#!/bin/bash

config_file="$HOME/.config/hypr/configs/monitor.conf"
auto_generated_setting=$(cat $config_file | grep "monitor=,preferred, auto, 1")

display() {
    cat << "EOF"
   __  ___          _ __             ____    __          
  /  |/  /__  ___  (_) /____  ____  / __/__ / /___ _____ 
 / /|_/ / _ \/ _ \/ / __/ _ \/ __/ _\ \/ -_) __/ // / _ \
/_/  /_/\___/_//_/_/\__/\___/_/   /___/\__/\__/\_,_/ .__/
                                                  /_/    
EOF
}

if [[ "$auto_generated_setting" ]]; then

    gum spin \
        --spinner minidot \
        --spinner.foreground "#c3cbd0" \
        --title.foreground "#c3cbd0" \
        --title "Setting up for your Monitor" -- \
        sleep 2

    monitor_name=$(xrandr | grep "connected" | awk '{print $1}')
    monitor_resolution=$(xrandr | grep "connected" | awk '{print $3}' | cut -d'+' -f1)

    display
    refresh_rate=$(gum choose \
                    --header \
                    "󰍹 Choose the refresh rate for your '$monitor_name' monitor:" \
                    --header.foreground "#c3cbd0" \
                    --selected.foreground "#c3cbd0" \
                    --cursor.foreground "#c3cbd0" \
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
