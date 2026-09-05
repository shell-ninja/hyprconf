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
set -l starship_dir "$HOME/.config/fish/starship"

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

    # Set in current environment immediately
    set -gx STARSHIP_CONFIG "$prompt_file"

    # Safely replace the line setting STARSHIP_CONFIG in config.fish
    if test -f "$fish_config"
        sed -i -E "s|^([[:space:]]*set -gx STARSHIP_CONFIG).*|\1 \"$prompt_file\"|g" "$fish_config"
    end

    printf "  \e[1;34m[*]\e[0m Applying changes immediately...\n"
    sleep 1; and clear
    exec fish
else
    echo
    printf "\e[1;31m  [!] Invalid choice. Exiting.\e[0m\n"
end
