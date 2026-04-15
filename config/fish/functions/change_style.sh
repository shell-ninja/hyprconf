#!/bin/bash

# change starship style.
fish_config="$HOME/.config/fish/config.fish"
starship_dir="$HOME/.config/fish/starship"
styles=($(ls "$starship_dir" | awk -F '[-.]' '{print $2}'))

style() {
    choose_style() {
        echo -e "=> Choose a style..."
        local i=1
        for style in "${styles[@]}"; do
            echo -e "  $i. $style"
            ((i ++))
        done
    }

    choose_style
    read -p "Choose: " stl

    if [[ "$stl" -gt 0 && "$stl" -le "${#styles[@]}" ]]; then
        __selected="${styles[$((stl - 1))]}"
        __prompt="starship-${__selected}.toml"
        echo -e "-> Setting prompt: $__selected"

        # sed -i "s|starship/starship-[^.]*.toml|starship/$__prompt/g" "$fish_config"
        sed -i "s|starship/starship-[^.]*.toml|starship/$__prompt|g" "$fish_config"

        echo -e "-> Now type 'src'. It will source fish config."
    fi
}

style
