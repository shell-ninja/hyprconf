#!/bin/bash

# Advanced Hyprland Installation Script by 
# Shell Ninja ( https://github.com/shell-ninja )

# color definition
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
magenta="\e[1;1;35m"
megenta="\e[1;1;35m"
cyan="\e[1;36m"
orange="\x1b[38;5;214m"
lavender="\e[1;38;2;203;166;247m"
end="\e[0m"

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

# finding the present directory and log file
if [[ -f "$0" ]]; then
    dir="$(dirname "$(realpath "$0")")"
    log_dir="$dir/Logs"
else
    log_dir="$HOME/.cache/hyprconf-logs"
fi
log="$log_dir/update-dotfiles.log"
mkdir -p "$log_dir"
touch "$log"

sleep 1

# Ensure cache directory is clean
rm -rf "$HOME/.cache/hyprconf" &> /dev/null

printf "${green}=>${end} Cloning hyprconf repository\n"
git clone --depth=1 --branch=noct https://github.com/shell-ninja/hyprconf.git "$HOME/.cache/hyprconf" &> /dev/null

if [[ -d "$HOME/.cache/hyprconf" ]]; then
    cd "$HOME/.cache/hyprconf"
    chmod +x setup.sh
    ./setup.sh
else
    printf "${red}>< Error occurred..${end}\n   Failed to clone the repository.\n" 2>&1 | tee -a >(sed 's/\x1B\[[0-9;]*[JKmsu]//g' >> "$log")
    exit 1
fi

# Removing the cache directory
if [[ -d "$HOME/.config/hypr/scripts" ]]; then
    printf "${cyan}::${end} Dotfiles were updated successfully. Removing the cache.\n" 2>&1 | tee -a >(sed 's/\x1B\[[0-9;]*[JKmsu]//g' >> "$log")

    rm -rf "$HOME/.cache/hyprconf" &> /dev/null

    echo
    printf "Congratulations! The script completes here.\n" && sleep 1
    printf "Need to reboot the system.\n\n"

    reboot="n"
    if command -v gum &> /dev/null; then
        if gum confirm "Would you like to reboot now?" \
            --affirmative "Yes, reboot now" \
            --negative "No, reboot later"; then
            reboot="y"
        fi
    else
        printf "Would you like to reboot now? [ y/n ]\n"
        read -r -p "Select: " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            reboot="y"
        fi
    fi

    if [[ "$reboot" == "y" ]]; then
        # Hide cursor for smooth animation
        tput civis 2>/dev/null || printf "\e[?25l"
        clear

        bold="\e[1m"
        dim="\e[2m"
        white="\e[1;37m"

        anim_frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
        anim_colors="$lavender"

        total_steps=30
        bar_len=28

        for (( step=0; step<=total_steps; step++ )); do
            remaining_sec=$(( (total_steps - step + 9) / 10 ))
            pct=$(( step * 100 / total_steps ))
            fill_len=$(( step * bar_len / total_steps ))
            unfill_len=$(( bar_len - fill_len ))

            spinner_char="${anim_frames[step % ${#anim_frames[@]}]}"
            theme_color="${anim_colors[(step / 6) % ${#anim_colors[@]}]}"

            fill_str=""
            for (( i=0; i<fill_len; i++ )); do fill_str="${fill_str}█"; done
            unfill_str=""
            for (( i=0; i<unfill_len; i++ )); do unfill_str="${unfill_str}░"; done

            printf "\e[H\n"
            printf "  ${theme_color}✦${end} ${bold}SYSTEM REBOOT INITIATED${end}\n\n"
            printf "  ${theme_color}${spinner_char}${end} ${bold}Rebooting in ${theme_color}${remaining_sec}s${end}  ${theme_color}[${fill_str}${dim}${unfill_str}${end}${theme_color}]${end} ${bold}%3d%%${end}\n\n" "$pct"
            printf "  ${dim}Happy to use your new rice! 🚀${end}\n"
            sleep 0.1
        done

        # Restore cursor
        tput cnorm 2>/dev/null || printf "\e[?25h"
        clear
        systemctl reboot --now 2>/dev/null || sudo reboot
    else
        printf "Ok, but make sure to reboot the system.\n" && sleep 1
        printf "Happy to use your new rice!\n"
        exit 0
    fi
fi
