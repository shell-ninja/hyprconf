#!/bin/bash

# Advanced Hyprland Installation Script by 
# Shell Ninja ( https://github.com/shell-ninja )

# color defination
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
megenta="\e[1;1;35m"
cyan="\e[1;36m"
orange="\x1b[38;5;214m"
end="\e[1;0m"

# ─── Gum Theme Configuration ───────────────────────────────────────────
export GUM_STYLE_BORDER="rounded"
export GUM_STYLE_BORDER_FOREGROUND="#89b4fa"
export GUM_STYLE_FOREGROUND="#89b4fa"

# Confirm dialogs
export GUM_CONFIRM_PROMPT_FOREGROUND="#89b4fa"
export GUM_CONFIRM_AFFIRMATIVE_BACKGROUND="#89b4fa"
export GUM_CONFIRM_AFFIRMATIVE_FOREGROUND="#11111b"
export GUM_CONFIRM_NEGATIVE_BACKGROUND="#313244"
export GUM_CONFIRM_NEGATIVE_FOREGROUND="#cdd6f4"

# Choose menus
export GUM_CHOOSE_CURSOR=" ➜ "
export GUM_CHOOSE_CURSOR_FOREGROUND="#89b4fa"
export GUM_CHOOSE_SELECTED_FOREGROUND="#a6e3a1"
export GUM_CHOOSE_HEADER_FOREGROUND="#f9e2af"
export GUM_CHOOSE_ITEM_FOREGROUND="#cdd6f4"

# Spinners
export GUM_SPIN_SPINNER="dot"
export GUM_SPIN_SPINNER_FOREGROUND="#89b4fa"
export GUM_SPIN_TITLE_FOREGROUND="#cdd6f4"

# Text inputs
export GUM_INPUT_PROMPT_FOREGROUND="#89b4fa"
export GUM_INPUT_CURSOR_FOREGROUND="#89b4fa"
export GUM_INPUT_WIDTH=60

if command -v gum &> /dev/null; then

display_text() {
    gum style \
        --border rounded \
        --border-foreground "#89b4fa" \
        --foreground "#89b4fa" \
        --align center \
        --width 60 \
        --margin "1" \
        --padding "1" \
'
  __  __        __     __        __ __                            ___
 / / / /__  ___/ /__ _/ /____   / // /_ _____  ___________  ___  / _/
/ /_/ / _ \/ _  / _ `/ __/ -_) / _  / // / _ \/ __/ __/ _ \/ _ \/ _/ 
\____/ .__/\_,_/\_,_/\__/\__/ /_//_/\_, / .__/_/  \__/\___/_//_/_/   
    /_/                            /___/_/                           
'
}

else
display_text() {
    cat << "EOF"
  __  __        __     __        __ __                            ___
 / / / /__  ___/ /__ _/ /____   / // /_ _____  ___________  ___  / _/
/ /_/ / _ \/ _  / _ `/ __/ -_) / _  / // / _ \/ __/ __/ _ \/ _ \/ _/ 
\____/ .__/\_,_/\_,_/\__/\__/ /_//_/\_, / .__/_/  \__/\___/_//_/_/   
    /_/                            /___/_/                             

EOF
}
fi

clear && display_text
printf " \n \n"

###------ Startup ------###

# finding the presend directory and log file
dir="$(dirname "$(realpath "$0")")"
# log directory
log_dir="$dir/Logs"
log="$log_dir"/update-dotfiles.log
mkdir -p "$log_dir"
touch "$log"

sleep 1

printf "${green}=>${end} Cloning hyprconf repository\n"
git clone --depth=1 https://github.com/shell-ninja/hyprconf.git "$HOME/.cache/hyprconf" &> /dev/null

if [[ -d "$HOME/.cache/hyprconf" ]]; then
    cd "$HOME/.cache/hyprconf"
    chmod +x setup.sh
    ./setup.sh
fi


# Removint the cache file
if [[ -d "$HOME/.config/hypr/scripts" ]]; then
    printf "${cyan}::${end} Dotfiles were update successfully. Removing the cache.\n" 2>&1 | tee -a >(sed 's/\x1B\[[0-9;]*[JKmsu]//g' >> "$log")

    rm -rf "$HOME/.cache/hyprconf" &> /dev/null
    exit 0
fi
