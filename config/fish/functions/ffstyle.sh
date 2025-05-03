#!/usr/bin/env bash

# change fastfetch style

ffstyle() {
    preferredDir="$HOME/.local/share/fastfetch/presets"

    if [[ ! -d "$preferredDir" ]]; then
        exit 0
    fi

    presets=()

    for preset in "$preferredDir"/*.jsonc; do
        [[ -f "$preset" ]] || continue  # Skip if no matching file
        presets+=("${preset##*/}")  # Extract filename
    done

    # Remove .jsonc extension from all entries
    presets=("${presets[@]%.jsonc}")

    echo "-> Choose Fastfetch style you want"

    local i=1
    for prst in "${presets[@]}"; do
        echo -e "$i. $prst"
        ((i++))
    done

    read -p "Select: " stl

    if [[ "$stl" -gt 0 && "$stl" -le "${#presets[@]}" ]]; then
        __selected="${presets[$((stl - 1))]}"
        echo "Setting $__selected as fastfetch style..."
        sed -i "s|ffconfig .*$|ffconfig $__selected|g" "$HOME/.config/fish/config.fish"
    fi
    
}

ffstyle
