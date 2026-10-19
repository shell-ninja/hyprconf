#!/usr/bin/env fish

#==============================================================================
# ███████╗██╗  ██╗███████╗██╗     ██╗     
# ██╔════╝██║  ██║██╔════╝██║     ██║     
# ███████╗███████║█████╗  ██║     ██║     
# ╚════██║██╔══██║██╔══╝  ██║     ██║     
# ███████║██║  ██║███████╗███████╗███████╗
# ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝
#                                         
# ███╗   ██╗██╗███╗   ██╗     ██╗ █████╗  
# ████╗  ██║██║████╗  ██║     ██║██╔══██╗ 
# ██╔██╗ ██║██║██╔██╗ ██║     ██║███████║ 
# ██║╚██╗██║██║██║╚██╗██║██   ██║██╔══██║ 
# ██║ ╚████║██║██║ ╚████║╚█████╔╝██║  ██║ 
# ╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚════╝ ╚═╝  ╚═╝                                                       
#==============================================================================

# change starship style in fish
set -l fish_config "$HOME/.config/fish/config.fish"
set -l starship_dir "$HOME/.hyprconf/starship"
if not test -d "$starship_dir"
    set starship_dir "$HOME/.config/starship"
end

set -l styles
for file in "$starship_dir"/*.toml
    test -f "$file"; or continue
    set -l name (basename "$file" .toml)
    set -a styles "$name"
end

function print_box_header
    printf "\e[1;36m╭────────────────────────────────────────╮\e[0m\n"
    printf "\e[1;36m│ \e[1;37m        Choose a Starship Style        \e[1;36m│\e[0m\n"
    printf "\e[1;36m├────────────────────────────────────────┤\e[0m\n"
end

function print_box_footer
    printf "\e[1;36m╰────────────────────────────────────────╯\e[0m\n"
end

print_box_header
for i in (seq (count $styles))
    printf "\e[1;36m│\e[0m \e[1;33m%2d.\e[0m \e[1;32m%-34s\e[0m \e[1;36m│\e[0m\n" $i "$styles[$i]"
end
print_box_footer

echo
printf "\e[1;35m❯\e[0m \e[1;37mChoose a number (1-%d):\e[0m " (count $styles)
read -l stl

if string match -qr '^[0-9]+$' "$stl"; and test $stl -ge 1 -a $stl -le (count $styles)
    set -l selected "$styles[$stl]"
    set -l prompt_file "$starship_dir/$selected.toml"

    echo
    printf "  \e[1;34m[*]\e[0m Setting prompt to: \e[1;32m%s\e[0m\n" "$selected"

    # Copy selected preset to active starship.toml
    cp "$prompt_file" "$HOME/.config/starship.toml"

    # Re-apply Noctalia palette if available
    set -l noctalia_apply "/usr/share/noctalia/assets/templates/starship/apply.sh"
    if test -x "$noctalia_apply"
        "$noctalia_apply" 2>/dev/null
    end

    # Set in current environment immediately
    set -gx STARSHIP_CONFIG "$HOME/.config/starship.toml"

    # Ensure STARSHIP_CONFIG points to ~/.config/starship.toml in config.fish
    if test -f "$fish_config"
        sed -i -E 's|^([[:space:]]*set -gx STARSHIP_CONFIG).*|\1 "$HOME/.config/starship.toml"|g' "$fish_config"
    end

    # Invalidate cached init script to pick up changes
    rm -f "$HOME/.config/fish/starship_init.fish"

    printf "  \e[1;34m[*]\e[0m Applying changes immediately...\n"
    sleep 1; and clear
    exec fish
else
    echo
    printf "\e[1;31m  [!] Invalid choice. Exiting.\e[0m\n"
end
