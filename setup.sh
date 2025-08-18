#!/bin/bash

# Advanced Hyprland Installation Script by
# Shell Ninja ( https://github.com/shell-ninja )

# color defination
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
magenta="\e[1;1;35m"
cyan="\e[1;36m"
orange="\x1b[38;5;214m"
end="\e[1;0m"

if command -v gum &> /dev/null; then

display_text() {
    gum style \
        --border rounded \
        --align center \
        --width 60 \
        --margin "1" \
        --padding "1" \
'
   __ __                            ___
  / // /_ _____  ___________  ___  / _/
 / _  / // / _ \/ __/ __/ _ \/ _ \/ _/ 
/_//_/\_, / .__/_/  \__/\___/_//_/_/   
     /___/_/                                
'
}

else
display_text() {
    cat << "EOF"
   __ __                            ___
  / // /_ _____  ___________  ___  / _/
 / _  / // / _ \/ __/ __/ _ \/ _ \/ _/ 
/_//_/\_, / .__/_/  \__/\___/_//_/_/   
     /___/_/                              

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
log="$log_dir"/dotfiles.log
mkdir -p "$log_dir"
touch "$log"

# message prompts
msg() {
    local actn=$1
    local msg=$2

    case $actn in
        act)
            printf "${green}=>${end} $msg\n"
            ;;
        ask)
            printf "${orange}??${end} $msg\n"
            ;;
        dn)
            printf "${cyan}::${end} $msg\n\n"
            ;;
        att)
            printf "${yellow}!!${end} $msg\n"
            ;;
        nt)
            printf "${blue}\$\$${end} $msg\n"
            ;;
        skp)
            printf "${magenta}[ SKIP ]${end} $msg\n"
            ;;
        err)
            printf "${red}>< Ohh sheet! an error..${end}\n   $msg\n"
            sleep 1
            ;;
        *)
            printf "$msg\n"
            ;;
    esac
}


# Directories ----------------------------
hypr_dir="$HOME/.hyprconf/hypr"
scripts_dir="$hypr_dir/scripts"
fonts_dir="$HOME/.local/share/fonts"

msg act "Now setting up the pre installed Hyprland configuration..." && sleep 1

mkdir -p ~/.config
dirs=(
    btop
    dunst
    fastfetch
    fish
    gtk-3.0
    gtk-4.0
    hypr
    kitty
    Kvantum
    menus
    nvim
    nwg-look
    qt5ct
    qt6ct
    rofi
    swaync
    waybar
    xfce4
    xsettingsd
    yazi
    dolphinrc
    kwalletmanagerrc
    kwalletrc
)

# Paths
backup_dir="$HOME/.temp-back"
wallpapers_backup="$backup_dir/Wallpaper"
hypr_cache_backup="$backup_dir/.cache"
hypr_config_backup="$backup_dir/configs.conf"
wallpapers="$HOME/.hyprconf/hypr/Wallpaper"
hypr_cache="$HOME/.hyprconf/hypr/.cache"
hypr_config="$HOME/.hyprconf/hypr/configs/configs.conf"

# Ensure backup directory exists
mkdir -p "$backup_dir"

# Function to handle backup/restore
backup_or_restore() {
    local file_path="$1"
    local file_type="$2"

    if [[ -e "$file_path" ]]; then
        echo
        msg att "A $file_type has been found."
        if command -v gum &> /dev/null; then
            gum confirm "Would you Restore it or put it into the Backup?" \
                --affirmative "Restore it.." \
                --negative "Backup it..."
            echo

            if [[ $? -eq 0 ]]; then
                action="r"
            else
                action="b"
            fi

        else
            msg ask "Would you like to Restore it or put it into the Backup? [ r/b ]"
            read -r -p "$(echo -e '\e[1;32mSelect: \e[0m')" action
        fi

        if [[ "$action" =~ ^[Rr]$ ]]; then
            cp -r "$file_path" "$backup_dir/"
        else
            msg att "$file_type will be backed up..."
        fi
    fi
}

# Backing wallpapers
backup_or_restore "$wallpapers" "wallpaper directory"
backup_or_restore "$hypr_config" "hyprland config file"

[[ -e "$hypr_cache" ]] && cp -r "$hypr_cache" "$backup_dir/"

# if some main directories exists, backing them up.
if [[ -d "$HOME/.backup_hyprconf-${USER}" ]]; then
    msg att "a .backup_hyprconf-${USER} directory was there. Archiving it..."
    cd
    mkdir -p ".archive_hyprconf-${USER}"
    tar -czf ".archive_hyprconf-${USER}/backup_hyprconf-$(date +%d-%m-%Y_%I-%M-%p)-${USER}.tar.gz" ".backup_hyprconf-${USER}" &> /dev/null
    # mv "HyprBackup-${USER}.zip" "HyprArchive-${USER}/"
    rm -rf ".backup_hyprconf-${USER}"
    msg dn "~/.backup_hyprconf-${USER} was archived inside ~/.archive_hyprconf-${USER} directory..." && sleep 1
fi


mkdir -p "$HOME/.backup_hyprconf-${USER}"
if [[ -d "$HOME/.hyprconf" ]]; then

    mv "$HOME/.hyprconf" "$HOME/.backup_hyprconf-${USER}/"

else

    for confs in "${dirs[@]}"; do
        conf_path="$HOME/.config/$confs"

        # If the config exists and is NOT a symlink → backup it
        if [[ -e "$conf_path" && ! -L "$conf_path" ]]; then
            mv "$conf_path" "$HOME/.backup_hyprconf-${USER}/" 2>&1 | tee -a "$log"
        fi
    done
    
    msg dn "Backed up $confs config to ~/.backup_hyprconf-${USER}/"
fi

[[ -d "$HOME/.backup_hyprconf-${USER}/hypr" ]] && msg dn "Everything has been backuped in $HOME/.backup_hyprconf-${USER}..."

sleep 1

####################################################################

#_____ if OpenBangla Keyboard is installed
keyboard_path="/usr/share/openbangla-keyboard"

if [[ -d "$keyboard_path" ]]; then
    msg act "Setting up things for OpenBangla-Keyboard..."

    # Add fcitx5 environment variables to /etc/environment if not already present
    if ! grep -q "GTK_IM_MODULE=fcitx" /etc/environment; then
        printf "\nGTK_IM_MODULE=fcitx\n" | sudo tee -a /etc/environment 2>&1 | tee -a >(sed 's/\x1B\[[0-9;]*[JKmsu]//g' >> "$log") &> /dev/null
    fi

    if ! grep -q "QT_IM_MODULE=fcitx" /etc/environment; then
        printf "QT_IM_MODULE=fcitx\n" | sudo tee -a /etc/environment 2>&1 | tee -a >(sed 's/\x1B\[[0-9;]*[JKmsu]//g' >> "$log") &> /dev/null
    fi

    if ! grep -q "XMODIFIERS=@im=fcitx" /etc/environment; then
        printf "XMODIFIERS=@im=fcitx\n" | sudo tee -a /etc/environment 2>&1 | tee -a >(sed 's/\x1B\[[0-9;]*[JKmsu]//g' >> "$log") &> /dev/null
    fi

fi

####################################################################

#_____ for virtual machine
# Check if the configuration is in a virtual box
if hostnamectl | grep -q 'Chassis: vm'; then
    msg att "You are using this script in a Virtual Machine..."
    msg act "Setting up things for you..." 
    sed -i '/env = WLR_NO_HARDWARE_CURSORS,1/s/^#//' "$dir/config/hypr/configs/environment.conf"
    sed -i '/env = WLR_RENDERER_ALLOW_SOFTWARE,1/s/^#//' "$dir/config/hypr/configs/environment.conf"
    echo -e '#Monitor\nmonitor=Virtual-1, 1920x1080@60,auto,1' > "$dir/config/hypr/configs/monitor.conf"
fi


#_____ for nvidia gpu. I don't know if it's gonna work or not. Because I don't have any gpu.
# uncommenting WLR_NO_HARDWARE_CURSORS if nvidia is detected
if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
  msg act "Nvidia GPU detected. Setting up proper env's" 2>&1 | tee -a >(sed 's/\x1B\[[0-9;]*[JKmsu]//g' >> "$log") || true
  sed -i '/env = WLR_NO_HARDWARE_CURSORS,1/s/^#//' config/hypr/configs/environment.conf
  sed -i '/env = LIBVA_DRIVER_NAME,nvidia/s/^#//' config/hypr/configs/environment.conf
  sed -i '/env = __GLX_VENDOR_LIBRARY_NAME,nvidia/s/^# //' config/hypr/configs/environment.conf
fi

sleep 1


# creating symlinks
cp -a "$dir/config" "$HOME/.hyprconf"
mv "$HOME/.hyprconf/fastfetch" "$HOME/.local/share/"

for dotfilesDir in "$HOME/.hyprconf"/*; do
    configDirName=$(basename "$dotfilesDir")
    configDirPath="$HOME/.config/$configDirName"

    ln -sfn "$dotfilesDir" "$configDirPath"
done

sleep 1

if [[ -d "$scripts_dir" ]]; then
    # make all the scripts executable...
    chmod +x "$scripts_dir"/* 2>&1 | tee -a "$log"
    chmod +x "$HOME/.hyprconf/fish/functions"/* 2>&1 | tee -a "$log"
    msg dn "All the necessary scripts have been executable..."
    sleep 1
else
    msg err "Could not find necessary scripts.."
fi

# Install Fonts
msg act "Installing some fonts..."
if [[ ! -d "$fonts_dir" ]]; then
	mkdir -p "$fonts_dir"
fi

cp -r "$dir/extras/fonts" "$fonts_dir"
msg act "Updating font cache..."
sudo fc-cache -fv 2>&1 | tee -a "$log" &> /dev/null

### Setup extra files and dirs

# dolphinstaterc
if [[ -f "$HOME/.local/state/dolphinstaterc" ]]; then
    mv "$HOME/.local/state/dolphinstaterc" "$HOME/.local/state/dolphinstaterc.back"
fi

# konsole
if [[ -d "$HOME/.local/share/konsole" ]]; then
    mv "$HOME/.local/share/konsole" "$HOME/.local/share/konsole.back"
fi

cp -r "$dir/local/state/dolphinstaterc" "$HOME/.local/state/"
cp -r "$dir/local/share/konsole" "$HOME/.local/share/"


# wayland session dir
wayland_session_dir=/usr/share/wayland-sessions
if [ -d "$wayland_session_dir" ]; then
    msg att "$wayland_session_dir found..."
else
    msg att "$wayland_session_dir NOT found, creating..."
    sudo mkdir $wayland_session_dir 2>&1 | tee -a "$log"
fi
    sudo cp "$dir/extras/hyprland.desktop" /usr/share/wayland-sessions/ 2>&1 | tee -a "$log"


# restore the backuped items into the original location
restore_backup() {
    local backup_path="$1"      # Path to the backup file/directory
    local original_path="$2"    # Original file/directory path
    local file_type="$3"        # Description of the file/directory

    if [[ -e "$backup_path" ]]; then
        # Create a backup of the current file/directory if it exists
        if [[ -e "$original_path" ]]; then
            mv "$original_path" "${original_path}.backup"
        fi

        # Restore the file/directory from the backup
        if cp -r "$backup_path" "$original_path"; then
            msg dn "$file_type restored to its original location: $original_path."
        else
            msg err "Could not restore defaults."
        fi

        if [[ -e "${original_path}.backup" ]]; then
            rm -rf "${original_path}.backup"
        fi
    fi
}

# Restore files
restore_backup "$wallpapers_backup" "$wallpapers" "wallpaper directory"
restore_backup "$hypr_config_backup" "$hypr_config" "hyprland config file"

# restoring hyprland cache
[[ -e "$HOME/.hyprconf/hypr/.cache" ]] && rm -rf "$HOME/.hyprconf/hypr/.cache"
[[ -e "$hypr_cache_backup" ]] && cp -r "$hypr_cache_backup" "$hypr_cache"
rm -rf "$backup_dir"

clear && sleep 1

# Asking if the user wants to download more wallpapers
msg ask "Would you like to add more ${green}Wallpapers${end}? ${blue}[ y/n ]${end}..."
read -r -p "$(echo -e '\e[1;32mSelect: \e[0m')" wallpaper

printf " \n"

# =========  wallpaper section  ========= #

if [[ "$wallpaper" =~ ^[Y|y]$ ]]; then
    url="https://github.com/shell-ninja/Wallpapers/archive/refs/heads/main.zip"

    target_dir="$HOME/.cache/wallpaper-cache"
    zip_path="$target_dir.zip"
    msg act "Downloading some wallpapers..."
    
    # Download the ZIP silently with a progress bar
    curl -L "$url" -o "$zip_path"

    if [[ -f "$zip_path" ]]; then
        mkdir -p "$target_dir"
        unzip "$zip_path" "wallpaper-cache-main/*" -d "$target_dir" > /dev/null
        mv "$target_dir/wallpaper-cache-main/"* "$target_dir" && rmdir "$target_dir/wallpaper-cache-main"
        rm "$zip_path"
    fi

    # copying the wallpaper to the main directory
    if [[ -d "$HOME/.cache/wallpaper-cache" ]]; then
        cp -r "$HOME/.cache/wallpaper-cache"/* ~/.hyprconf/hypr/Wallpaper/ &> /dev/null
        rm -rf "$HOME/.cache/wallpaper-cache" &> /dev/null
        msg dn "Wallpapers were downloaded successfully..." 2>&1 | tee -a >(sed 's/\x1B\[[0-9;]*[JKmsu]//g' >> "$log") & sleep 0.5
    else
        msg err "Sorry, could not download more wallpapers. Going forward with the limited wallpapers..." 2>&1 | tee -a >(sed 's/\x1B\[[0-9;]*[JKmsu]//g' >> "$log") && sleep 0.5
    fi
fi

# =========  wallpaper section  ========= #

if [[ -d "$HOME/.hyprconf/hypr/Wallpaper" ]]; then

    if [[ -d "$HOME/.hyprconf/hypr/.cache" ]]; then
        wallName=$(cat "$HOME/.hyprconf/hypr/.cache/.wallpaper")
        wallpaper=$(find "$HOME/.hyprconf/hypr/Wallpaper" -type f -name "$wallName.*" | head -n 1)
    else
        mkdir -p "$HOME/.hyprconf/hypr/.cache"
        wallCache="$HOME/.hyprconf/hypr/.cache/.wallpaper"

        touch "$wallCache"      

        if [ -f "$HOME/.hyprconf/hypr/Wallpaper/linux.jpg" ]; then
            echo "linux" > "$wallCache"
            wallpaper="$HOME/.hyprconf/hypr/Wallpaper/linux.jpg"
        fi
    fi

    # setting the default wallpaper
    ln -sf "$wallpaper" "$HOME/.hyprconf/hypr/.cache/current_wallpaper.png"
fi

# setting up the waybar
ln -sf "$HOME/.hyprconf/waybar/configs/full-top" "$HOME/.hyprconf/waybar/config"
ln -sf "$HOME/.hyprconf/waybar/style/full-top.css" "$HOME/.hyprconf/waybar/style.css"

# setting up hyprlock theme
ln -sf "$HOME/.hyprconf/hypr/lockscreens/hyprlock-1.conf" "$HOME/.hyprconf/hypr/hyprlock.conf"

msg act "Generating colors and other necessary things..."
"$HOME/.hyprconf/hypr/scripts/wallcache.sh" &> /dev/null
"$HOME/.hyprconf/hypr/scripts/pywal.sh" &> /dev/null


# setting default themes, icon and cursor
gsettings set org.gnome.desktop.interface gtk-theme 'TokyoNight'
gsettings set org.gnome.desktop.interface icon-theme 'TokyoNight'
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'

crudini --set ~/.config/Kvantum/kvantum.kvconfig General theme "Dracula"
crudini --set ~/.config/kdeglobals Icons Theme "TokyoNight"


msg dn "Script execution was successful! Now logout and log back in and enjoy your customization..." && sleep 1

# === ___ Script Ends Here ___ === #
