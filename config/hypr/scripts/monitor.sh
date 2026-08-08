#!/bin/bash

config_file="$HOME/.hyprconf/hypr/configs/monitor.lua"

# Only proceed if the Lua catch-all monitor is present
if [[ ! -f "$config_file" ]] || ! grep -q 'output[[:space:]]*=[[:space:]]*""' "$config_file"; then
    echo "No default Lua monitor configuration found. Nothing to do."
    exit 1
fi

display() {
    local cols
    cols=$(tput cols 2>/dev/null || echo 80)

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
        (( ${#line} > max_width )) && max_width=${#line}
    done <<< "$art"

    local padding=0
    (( cols > max_width )) && padding=$(( (cols - max_width) / 2 ))

    local spaces
    spaces=$(printf '%*s' "$padding" '')

    while IFS= read -r line; do
        printf "%s%s\n" "$spaces" "$line"
    done <<< "$art"
}

# Dependency check
for cmd in hyprctl jq gum; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: '$cmd' is not installed."
        exit 1
    fi
done

clear
display
printf "\n"

gum spin \
    --spinner minidot \
    --spinner.foreground "#cce8f0" \
    --title.foreground "#cce8f0" \
    --title "Setting up your monitor..." -- \
    sleep 2

# Get monitor list
mapfile -t monitors < <(
    hyprctl monitors -j |
    jq -r '.[] | "\(.name) (\(.width)x\(.height) @ \(.refreshRate|floor)Hz)"'
)

if [[ ${#monitors[@]} -eq 0 ]]; then
    echo "No monitors detected."
    exit 1
fi

clear
display
printf "\n"

# Monitor selection
if [[ ${#monitors[@]} -eq 1 ]]; then
    selected_monitor="${monitors[0]}"
else
    selected_monitor=$(
        printf '%s\n' "${monitors[@]}" | gum choose \
            --header "󰍹 Select a monitor:" \
            --header.foreground "#cce8f0" \
            --selected.foreground "#cce8f0" \
            --cursor.foreground "#cce8f0" \
    )
fi

monitor_name="${selected_monitor%% (*}"

monitor_resolution=$(
    hyprctl monitors -j |
    jq -r --arg name "$monitor_name" \
        '.[] | select(.name == $name) | "\(.width)x\(.height)"'
)

current_refresh=$(
    hyprctl monitors -j |
    jq -r --arg name "$monitor_name" \
        '.[] | select(.name == $name) | (.refreshRate|floor)'
)

clear
display
printf "\n"

# Refresh-rate selection
refresh_rate=$(
    gum choose \
        --header "󰍹 Choose the refresh rate for '$monitor_name' (Current: ${current_refresh}Hz)" \
        --header.foreground "#cce8f0" \
        --selected.foreground "#cce8f0" \
        --cursor.foreground "#cce8f0" \
        "60Hz" \
        "75Hz" \
        "120Hz" \
        "144Hz" \
        "165Hz" \
        "180Hz" \
        "200Hz" \
        "240Hz"
)

clear
display
printf "\n"

# Scale selection
scale_choice=$(
    gum choose \
        --header "󰍹 Choose display scaling for '$monitor_name':" \
        --header.foreground "#cce8f0" \
        --selected.foreground "#cce8f0" \
        --cursor.foreground "#cce8f0" \
        "1" \
        "1.25" \
        "1.5" \
        "1.75" \
        "2" \
        "Auto"
)

if [[ "$scale_choice" == "Auto" ]]; then
    scale_value='"auto"'
else
    scale_value="$scale_choice"
fi

hz="${refresh_rate%Hz}"
mode="${monitor_resolution}@${hz}"

# Write monitor.lua
cat > "$config_file" <<EOF
-- Monitor: $monitor_name
hl.monitor({
    output   = "$monitor_name",
    mode     = "$mode",
    position = "auto",
    scale    = $scale_value,
})
EOF

clear
display
printf "\n"

echo "✓ Monitor configuration updated successfully."
echo
echo "Monitor : $monitor_name"
echo "Mode    : $mode"
echo "Scale   : $scale_choice"
echo
echo "Reload Hyprland to apply changes:"
echo "  hyprctl reload"

