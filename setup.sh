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
    satty
    swaync
    systemd
    waybar
    wlogout
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
hypr_config="$HOME/.hyprconf/hypr/configs/configs.lua"

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

# =============================================
#  CHOOSE HYPRLAND CONFIG VARIANT (conf vs lua)
# =============================================
variant_conf="$dir/config/hypr-conf"
variant_lua="$dir/config/hypr-lua"

if [[ -d "$variant_conf" && -d "$variant_lua" ]]; then
    msg act "Two Hyprland configuration variants found. Which one would you like to install?"
    msg nt "hypr-conf : Classic Hyprland config using separate .conf files (keybinds, window rules, etc.)"
    msg nt "hypr-lua  : Modern Lua‑based config with scripting and dynamic reloading capabilities."
    if command -v gum &> /dev/null; then
        chosen_variant=$(gum choose "hypr-conf" "hypr-lua" --header "Choose your configuration style:")
    else
        printf "\n1) hypr-conf  (classic .conf files)\n"
        printf "2) hypr-lua   (Lua configuration)\n"
        read -r -p "$(echo -e '\e[1;32mSelect [1/2]: \e[0m')" choice_num
        case $choice_num in
            1) chosen_variant="hypr-conf";;
            2) chosen_variant="hypr-lua";;
            *) msg err "Invalid choice, defaulting to hypr-conf"; chosen_variant="hypr-conf";;
        esac
    fi
elif [[ -d "$variant_conf" ]]; then
    msg nt "Only hypr-conf variant found. Using it."
    chosen_variant="hypr-conf"
elif [[ -d "$variant_lua" ]]; then
    msg nt "Only hypr-lua variant found. Using it."
    chosen_variant="hypr-lua"
else
    chosen_variant=""
fi

# Copy the whole config tree first
cp -a "$dir/config" "$HOME/.hyprconf"

# Replace hypr directory with the chosen variant and clean up
if [[ -n "$chosen_variant" ]]; then
    rm -rf "$HOME/.hyprconf/hypr"
    mv "$HOME/.hyprconf/$chosen_variant" "$HOME/.hyprconf/hypr"
    # Remove the other variant directory if it exists (unused copy)
    [[ -d "$HOME/.hyprconf/hypr-conf" ]] && rm -rf "$HOME/.hyprconf/hypr-conf"
    [[ -d "$HOME/.hyprconf/hypr-lua" ]] && rm -rf "$HOME/.hyprconf/hypr-lua"
    msg dn "Installed Hyprland configuration: $chosen_variant"
else
    msg att "No variant directories found, using default hypr config if present."
fi

# --- Apply VM / NVIDIA specific adjustments to the final hypr config ---
# Determine file suffix
if [[ "$chosen_variant" == "hypr-lua" ]]; then
    suffix="lua"
else
    suffix="conf"
fi
env_file="$HOME/.hyprconf/hypr/configs/environment.$suffix"
monitor_file="$HOME/.hyprconf/hypr/configs/monitor.$suffix"

# Virtual Machine adjustments
if systemd-detect-virt --quiet; then
    msg att "You are using this script in a Virtual Machine..."
    msg act "Applying VM specific settings..."

    if [[ "$suffix" == "lua" ]]; then
        # Uncomment Lua environment variables
        [[ -f "$env_file" ]] && sed -i '/^-- hl\.env("WLR_NO_HARDWARE_CURSORS"/s/^-- //' "$env_file"
        [[ -f "$env_file" ]] && sed -i '/^-- hl\.env("WLR_RENDERER_ALLOW_SOFTWARE"/s/^-- //' "$env_file"
        # Create monitor.lua with VM default (overwrites existing)
        cat > "$monitor_file" << 'MONITOR_LUA_EOF'
-- Virtual machine monitor
hl.monitor({
    output   = "Virtual-1",
    mode     = "1920x1080@60",
    position = "auto",
    scale    = "auto",
})
MONITOR_LUA_EOF
    else
        # Classic .conf adjustments
        [[ -f "$env_file" ]] && sed -i '/env = WLR_NO_HARDWARE_CURSORS,1/s/^#//' "$env_file"
        [[ -f "$env_file" ]] && sed -i '/env = WLR_RENDERER_ALLOW_SOFTWARE,1/s/^#//' "$env_file"
        echo -e '#Monitor\nmonitor=Virtual-1, 1920x1080@60,auto,1' > "$monitor_file"
    fi
fi

# NVIDIA GPU adjustments
if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
    msg act "Nvidia GPU detected. Setting up proper environment variables..."

    if [[ "$suffix" == "lua" ]]; then
        # Uncomment Lua environment variables for NVIDIA
        [[ -f "$env_file" ]] && sed -i '/^-- hl\.env("LIBVA_DRIVER_NAME"/s/^-- //' "$env_file"
        [[ -f "$env_file" ]] && sed -i '/^-- hl\.env("__GLX_VENDOR_LIBRARY_NAME"/s/^-- //' "$env_file"
        [[ -f "$env_file" ]] && sed -i '/^-- hl\.env("GBM_BACKEND"/s/^-- //' "$env_file"
    else
        # Classic .conf adjustments
        [[ -f "$env_file" ]] && sed -i '/env = WLR_NO_HARDWARE_CURSORS,1/s/^#//' "$env_file"
        [[ -f "$env_file" ]] && sed -i '/env = LIBVA_DRIVER_NAME,nvidia/s/^#//' "$env_file"
        [[ -f "$env_file" ]] && sed -i '/env = __GLX_VENDOR_LIBRARY_NAME,nvidia/s/^# //' "$env_file"
    fi
fi

sleep 1

# Move fastfetch to local share
[[ ! -d "$HOME/.local/share/fastfetch" ]] && mv "$HOME/.hyprconf/fastfetch" "$HOME/.local/share/"

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

if [[ ! -f "$HOME/.local/share/fonts/fonts/Icomoon-Feather.ttf" || ! -f "$HOME/.local/share/fonts/Icomoon-Feather.ttf" ]]; then
    cp -a "$dir/extras/fonts/." "$fonts_dir/"

    msg act "Updating font cache..."
    sudo fc-cache -fv 2>&1 | tee -a "$log" &> /dev/null
fi


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
    sudo mkdir -p $wayland_session_dir 2>&1 | tee -a "$log"
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
        if cp -an "$backup_path" "$original_path"; then
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
    curl -fL "$url" -o "$zip_path"

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

    if [[ -f "$HOME/.hyprconf/hypr/.cache/.wallpaper" ]]; then
        read -r wallName < "$HOME/.hyprconf/hypr/.cache/.wallpaper"
        wallpaper=$(find "$HOME/.hyprconf/hypr/Wallpaper" \
            -type f -name "$wallName.*" | head -n1)

        if [[ -z "$wallpaper" ]]; then
            if [[ -f "$HOME/.hyprconf/hypr/Wallpaper/shell-ninja.png" ]]; then
                wallpaper="$HOME/.hyprconf/hypr/Wallpaper/shell-ninja.png"
                echo "shell-ninja" > "$HOME/.hyprconf/hypr/.cache/.wallpaper"
            fi
        fi
    else
        mkdir -p "$HOME/.hyprconf/hypr/.cache"
        wallCache="$HOME/.hyprconf/hypr/.cache/.wallpaper"

        touch "$wallCache"      

        if [ -f "$HOME/.hyprconf/hypr/Wallpaper/shell-ninja.png" ]; then
            echo "shell-ninja" > "$wallCache"
            wallpaper="$HOME/.hyprconf/hypr/Wallpaper/shell-ninja.png"
        fi
    fi

    # setting the default wallpaper
    if [[ -n "$wallpaper" ]]; then
        ln -sf "$wallpaper" "$HOME/.hyprconf/hypr/.cache/current_wallpaper.png"
    else
        msg att "No valid wallpaper found. Skipping wallpaper symlink."
    fi
fi

# setting up the waybar
ln -sf "$HOME/.hyprconf/waybar/configs/full-top" "$HOME/.hyprconf/waybar/config"
ln -sf "$HOME/.hyprconf/waybar/style/full-top.css" "$HOME/.hyprconf/waybar/style.css"

# setting up hyprlock theme
ln -sf "$HOME/.hyprconf/hypr/lockscreens/hyprlock-1.conf" "$HOME/.hyprconf/hypr/hyprlock.conf"

msg act "Generating colors and other necessary things..."
"$HOME/.hyprconf/hypr/scripts/wallcache.sh" &> /dev/null
"$HOME/.hyprconf/hypr/scripts/pywal.sh" &> /dev/null

# Setting nightlight auto transition
systemctl --user daemon-reload
systemctl --user enable --now hyprnightlight.timer


# setting default themes, icon and cursor
gsettings set org.gnome.desktop.interface gtk-theme "FlatColor"
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"

gsettings set org.gnome.desktop.interface icon-theme 'TokyoNight'
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'

crudini --set ~/.config/Kvantum/kvantum.kvconfig General theme "Dracula"
crudini --set ~/.config/kdeglobals Icons Theme "TokyoNight"


msg dn "Script execution was successful! Now logout and log back in and enjoy your customization..." && sleep 1

# === ___ Script Ends Here ___ === #
