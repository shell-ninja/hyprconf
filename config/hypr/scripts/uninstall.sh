#!/bin/bash

# Color definitions
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
magenta="\e[1;35m"
cyan="\e[1;36m"
orange="\x1b[38;5;214m"
end="\e[0m"

# Gum banner or fallback ASCII
display_text() {
    gum style \
        --border rounded \
        --align center \
        --width 60 \
        --margin "1" \
        --padding "1" \
'
  __  __     _          __       ____
 / / / /__  (_)__  ___ / /____ _/ / /
/ /_/ / _ \/ / _ \(_-</ __/ _ `/ / / 
\____/_//_/_/_//_/___/\__/\_,_/_/_/  
                                     
'
}

# Message printing function
msg() {
    local actn=$1
    local msg=$2
    case $actn in
        act) printf "\n${green}=>${end} $msg\n" ;;
        ask) printf "\n${orange} ${end} $msg\n" ;;
        alrt)printf "\n${yellow} ${end} $msg\n" ;;
        dn)  printf "\n${cyan}󱗼 ${end} $msg\n\n" ;;
        att) printf "\n${yellow}!!${end} $msg\n" ;;
        nt)  printf "\n${blue}󱞁 ${end} $msg\n" ;;
        wrn) printf "${red}[ WARNING ]${end}\n $msg\n" ;;
        skp) printf "${magenta}[ SKIP ]${end} $msg\n" ;;
        err) printf "\n${red}>< Ohh sheet! an error..${end}\n   $msg\n"; sleep 1 ;;
        *)   printf "$msg\n" ;;
    esac
}

clear && display_text

msg alrt "Starting the uninstallation process..."
sleep 2 && clear

# search for hyprland packages
if [[ -n "$(command -v pacman)" ]] &> /dev/null; then
    aur=$(command -v yay || command -v paru)

    hypr_pkgs=($(pacman -Qq | grep '^hypr'))
    grmblst=($(pacman -Qq | grep '^grimblast'))
    rofi=($(pacman -Qq | grep '^rofi'))
elif [[ -n "$(command -v dnf)" ]] &> /dev/null; then
    hypr_pkgs=($(rpm -q --qf "%{NAME}\n" | grep '^hypr'))
    grmblst=($(rpm -q --qf "%{NAME}\n" | grep '^grimblast'))
    rofi=($(rpm -q --qf "%{NAME}\n" | grep '^rofi'))
fi

others=(
    pyprland
    cliphist
    wl-clipboard
    xdg-desktop-portal-hyprland
    hyprland
    hyprcursor
    hypridle
    hyprlock
    waybar
    # kitty
    # nwg-look
    swaync
)

# Config directories to remove/backup
# DOTFILES=(
#     btop
#     dunst
#     fastfetch
#     fish
#     gtk-3.0
#     gtk-4.0
#     hypr
#     kitty
#     Kvantum
#     nvim
#     nwg-look
#     qt5ct
#     qt6ct
#     rofi
#     waybar
#     xsettingsd
#     yazi
# )

BACKUP_DIR="$HOME/.hyprconf-backup-$(date +%d-%m-%Y)"
WALLPAPER_DIR="$HOME/.dotfiles/config/hypr/Wallpaper"

current_session="${XDG_CURRENT_DESKTOP:- $DESKTOP_SESSION}"

if [[ "$current_session" == "Hyprland" ]]; then
    msg wrn "You are currently using Hyprland. After finishing the sctipt and rebooting the system, you will no longer be able to log into hyprland."
    echo
fi


# package uninstallation function
uninstallation() {
    if [[ -n "$(command -v pacman)" ]] &> /dev/null; then
        for pkg in "${grmblst[@]}" "${others[@]}" "${rofi[@]}" "${hypr_pkgs[@]}"; do
            if "$aur" -Qq "$pkg" &> /dev/null; then
                msg act "Removing $pkg.."
                "$aur" -Rns "$pkg" --noconfirm

                if "$aur" -Qq "$pkg" &> /dev/null; then
                    msg err "Could not remove $pkg"
                else
                    msg dn "Removed $pkg successfully!"
                fi
            fi
        done
    elif [[ -n "$(command -v dnf)" ]] &> /dev/null; then
        for pkg in "${grmblst[@]}" "${others[@]}" "${rofi[@]}" "${hypr_pkgs[@]}"; do
            if rpm -q "$pkg" &> /dev/null; then
                msg act "Removing $pkg.."
                sudo dnf remove "$pkg" -y

                if rpm -q "$pkg" &> /dev/null; then
                    msg err "Could not remove $pkg"
                else
                    msg dn "Removed $pkg successfully!"
                fi
            fi
        done
    fi
}

# print the list of packages
pkg_print() {
    for pkg in "${others[@]}" "${grmblst[@]}" "${rofi[@]}"; do
        if "$aur" -Qq "$pkg" &> /dev/null;then
    cat << EOF
$pkg
EOF
        fi
done
}

echo -e "${yellow}<> --------- <>${orange}"
pkg_print
echo -e "${yellow}<> --------- <>${end}"

echo

msg att "These packages will be removed from your system"

echo

# Ask for uninstallation confirmation
if ! gum confirm "Would you like to continue?" \
    --prompt.foreground "#e1a5cf" \
    --affirmative "Continue" \
    --selected.background "#e1a5cf" \
    --selected.foreground "#070415" \
    --negative "Skip"
then
    gum spin \
        --spinner dot \
        --spinner.foreground "#e1a5cf" \
        --title "Skipping the uninstallation process..." -- \
        sleep 2
    exit 0
fi

# Ask about wallpaper backup
msg ask "Would you like to backup your ${cyan}Wallpapers${end}?"
if gum confirm "Choose" \
    --prompt.foreground "#e1a5cf" \
    --affirmative "BackUp" \
    --selected.background "#e1a5cf" \
    --selected.foreground "#070415" \
    --negative "Remove"
then
    mkdir -p "$HOME/Wallpapers-Backup"
    mv "$WALLPAPER_DIR" "$HOME/Wallpapers-Backup/"
    msg dn "Wallpapers have been backed up into $HOME/Wallpapers-Backup directory"
fi

sleep 1 && clear

msg act "Uninstalling packages..."
msg att "Some 'Hyprland' related package might not be uninstalled due to dependency issues. Uninstall them menually." && sleep 1
echo
uninstallation

sleep 1 && clear

# Backup and remove dotfiles
msg act "Removing dotfiles..."

mkdir -p "$BACKUP_DIR" &> /dev/null

for dir in "$HOME/.dotfiles/config"/*; do
    name=$(basename "$dir")
    if [[ -L "$HOME/.config/$name" ]]; then
        unlink "$HOME/.config/$name"
        echo "Unlinked $HOME/.config/$name"
    fi
done

mv "$HOME/.dotfiles" "$BACKUP_DIR/"

# Compress backup
CACHE_DIR="$HOME/.cache"

if [[ -d "$BACKUP_DIR/.dotfiles" ]]; then
    ARCHIVE_NAME="$(basename "$BACKUP_DIR").tar.gz"
    tar -czf "$CACHE_DIR/$ARCHIVE_NAME" -C "$(dirname "$BACKUP_DIR")" "$(basename "$BACKUP_DIR")" &> /dev/null
fi

msg dn "Uninstallation complete! Need to reboot the system..."

sleep 1 && clear

for sec in {5..1}; do
    msg act "Rebooting the system in $sec seconds..." && sleep 1 && clear
done

systemctl reboot --now
