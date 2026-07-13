#!/bin/bash

config_file="$HOME/.config/hypr/configs/monitor.conf"
auto_generated_setting=$(grep '^monitor=,preferred, auto, 1' "$config_file" 2>/dev/null)

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

# Only run if the default auto-generated monitor line exists
[[ -z "$auto_generated_setting" ]] && exit 0

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
    --spinner.foreground "#bdb0ca" \
    --title.foreground "#bdb0ca" \
    --title "Setting up your Monitor" -- \
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
            --header.foreground "#bdb0ca" \
            --selected.foreground "#bdb0ca" \
            --cursor.foreground "#bdb0ca"
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

refresh_rate=$(
    gum choose \
        --header "󰍹 Choose refresh rate for '$monitor_name' (Current: ${current_refresh}Hz)" \
        --header.foreground "#bdb0ca" \
        --selected.foreground "#bdb0ca" \
        --cursor.foreground "#bdb0ca" \
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

scale=$(
    gum choose \
        --header "󰍹 Choose display scaling:" \
        --header.foreground "#bdb0ca" \
        --selected.foreground "#bdb0ca" \
        --cursor.foreground "#bdb0ca" \
        "1" \
        "1.25" \
        "1.5" \
        "1.75" \
        "2"
)

hz="${refresh_rate%Hz}"

settings="monitor=${monitor_name},${monitor_resolution}@${hz}, auto, ${scale}"

sed -i \
    "s|${auto_generated_setting}|${settings}|" \
    "$config_file"

clear
display
printf "\n"

echo "✓ Monitor configuration updated successfully."
echo
echo "Monitor : $monitor_name"
echo "Mode    : ${monitor_resolution}@${hz}"
echo "Scale   : $scale"
echo
echo "Reload Hyprland to apply changes:"
echo "  hyprctl reload"
