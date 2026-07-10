#!/bin/bash

config_file="$HOME/.config/hypr/configs/monitor.lua"

# Only proceed if the Lua catch-all monitor is present
if [[ ! -f "$config_file" ]] || ! grep -q 'output[[:space:]]*=[[:space:]]*""' "$config_file"; then
    echo "No default Lua monitor configuration found. Nothing to do."
    exit 1
fi

display() {
    local cols=$(tput cols)
    local art
    art=$(cat << 'EOF'
   __  ___          _ __             ____    __          
  /  |/  /__  ___  (_) /____  ____  / __/__ / /___ _____ 
 / /|_/ / _ \/ _ \/ / __/ _ \/ __/ _\ \/ -_) __/ // / _ \
/_/  /_/\___/_//_/_/\__/\___/_/   /___/\__/\__/\_,_/ .__/
                                                  /_/    
EOF
)
    local max_width=0
    while IFS= read -r line; do
        local len=${#line}
        (( len > max_width )) && max_width=$len
    done <<< "$art"
    local padding=0
    (( cols > max_width )) && padding=$(( (cols - max_width) / 2 ))
    local spaces=$(printf '%*s' "$padding" '')
    while IFS= read -r line; do
        printf "%s%s\n" "$spaces" "$line"
    done <<< "$art"
}

display
printf "\n"

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

# Extract numeric part (e.g. "60" from "60Hz")
hz="${refresh_rate%Hz}"
mode="${monitor_resolution}@${hz}"

# Write the new hl.monitor block
cat > "$config_file" << LUA_EOF
-- Monitor: $monitor_name
hl.monitor({
    output   = "$monitor_name",
    mode     = "$mode",
    position = "auto",
    scale    = "auto",
})
LUA_EOF

echo "Monitor configuration updated successfully."
