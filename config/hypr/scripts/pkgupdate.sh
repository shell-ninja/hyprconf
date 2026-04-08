#!/bin/bash

display() {
    cat << "EOF"
   ____         __              __  __        __     __     
  / __/_ _____ / /____ __ _    / / / /__  ___/ /__ _/ /____ 
 _\ \/ // (_-</ __/ -_)  ' \  / /_/ / _ \/ _  / _ `/ __/ -_)
/___/\_, /___/\__/\__/_/_/_/  \____/ .__/\_,_/\_,_/\__/\__/ 
    /___/                         /_/                       
                                                     
EOF
}

display
printf "\n"

# asking for confirmation.
choice=$(gum confirm "Would you like to," \
        --prompt.foreground "#c5c1c4" \
        --affirmative "Update now!" \
        --selected.background "#c5c1c4" \
        --selected.foreground "#0e0b0c" \
        --negative "Skip updating!"
        )

if [ $? -eq 0 ]; then
    # updating the system
    if [ -n "$(command -v pacman)" ]; then
        aur=$(command -v yay || command -v paru)
        "$aur" -Syyu --noconfirm
    elif [ -n "$(command -v dnf)" ]; then
        sudo dnf update && sudo dnf upgrade -y
    elif [ -n "$(command -v zypper)" ]; then
        sudo zypper up -y
    fi

    sleep 1

    printf "\n\n<> Please press ENTER to close "
    read
else
    gum spin \
        --spinner dot \
        --spinner.foreground "#c5c1c4" \
        --title "Skipping updating your system..." -- \
        sleep 2
fi
