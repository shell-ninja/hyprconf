# ~/.config/fish/functions/functions.sh

#==============================================================================

# ███████╗██╗  ██╗███████╗██╗         ███╗   ██╗██╗███╗   ██╗     ██╗ █████╗ 
# ██╔════╝██║  ██║██╔════╝██║         ████╗  ██║██║████╗  ██║     ██║██╔══██╗
# ███████╗███████║█████╗  ██║         ██╔██╗ ██║██║██╔██╗ ██║     ██║███████║
# ╚════██║██╔══██║██╔══╝  ██║         ██║╚██╗██║██║██║╚██╗██║██   ██║██╔══██║
# ███████║██║  ██║███████╗███████╗    ██║ ╚████║██║██║ ╚████║╚█████╔╝██║  ██║
# ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚════╝ ╚═╝  ╚═╝
                                                                            
#==============================================================================

ffimg() {
    local preferredDir="$HOME/.local/share/fastfetch/images"

    if [[ ! -d "$preferredDir" ]]; then
        echo "Image directory not found: $preferredDir"
        return 1
    fi

    [[ -n "$ffconfig" ]] || source "$HOME/.config/fish/config.fish"

    if [[ "$ffconfig" != "minimal" ]]; then
        echo "minimal style is not selected."
        return 0
    fi

    local presets=()
    for preset in "$preferredDir"/*; do
        [[ -f "$preset" ]] || continue
        presets+=("$(basename "$preset")")
    done

    if [[ "${#presets[@]}" -eq 0 ]]; then
        echo "No images found in $preferredDir"
        return 1
    fi

    echo "-> Choose Fastfetch image you want:"
    local i=1
    for prst in "${presets[@]}"; do
        echo "$i. $prst"
        ((i++))
    done

    read -p "Select (1-${#presets[@]}): " stl

    if ! [[ "$stl" =~ ^[0-9]+$ ]]; then
        echo "Invalid input. Please enter a number."
        return 1
    fi

    if (( stl >= 1 && stl <= ${#presets[@]} )); then
        local __selected="${presets[$((stl - 1))]}"
        echo "Setting $__selected as fastfetch image..."

        # Escape for sed
        local escaped_path
        escaped_path=$(printf '%s\n' "$__selected" | sed 's/[\/&]/\\&/g')

        # Replace only the filename after fastfetch/images/ and preserve what comes after (like the trailing ",)
        sed -i -E "s|(fastfetch/images/)[^\"/]+|\1$escaped_path|" "$HOME/.local/share/fastfetch/presets/minimal.jsonc"
    else
        echo "Invalid selection."
        return 1
    fi
}

ffimg
