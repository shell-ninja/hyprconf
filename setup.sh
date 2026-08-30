#!/usr/bin/env bash

# Advanced Hyprland Installation Script by
# Shell Ninja ( https://github.com/shell-ninja )

# color definition
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
magenta="\e[1;1;35m"
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

# Finding working directory and log file
dir="$(dirname "$(realpath "$0")")"
log_dir="$dir/Logs"
log="$log_dir/dotfiles.log"
mkdir -p "$log_dir"
touch "$log"

# Log message helper (strips ANSI codes for file output)
log_msg() {
    local text="$1"
    local clean_text
    clean_text="$(echo -e "$text" | sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g')"
    printf "[%s] %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$clean_text" >> "$log"
}

# Terminal message output helper
msg() {
    local actn=$1
    local msg=$2

    case $actn in
        act)  printf "${green}=>${end} $msg\n" ;;
        ask)  printf "${orange}??${end} $msg\n" ;;
        dn)   printf "${cyan}::${end} $msg\n\n" ;;
        att)  printf "${yellow}!!${end} $msg\n" ;;
        nt)   printf "${blue}\$\$${end} $msg\n" ;;
        skp)  printf "${magenta}[ SKIP ]${end} $msg\n" ;;
        err)  printf "${red}>< Error occurred..${end}\n   $msg\n" ;;
        *)    printf "$msg\n" ;;
    esac

    log_msg "$msg"
}

# Directories ----------------------------
hypr_dir="$HOME/.hyprconf/hypr"
scripts_dir="$hypr_dir/scripts"
fonts_dir="$HOME/.local/share/fonts"

msg act "Setting up the pre-installed Hyprland configuration..."

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
    noctalia
    nvim
    nwg-look
    pypr
    qt5ct
    qt6ct
    satty
    systemd
    xfce4
    xsettingsd
    yazi
    dolphinrc
    kwalletmanagerrc
    kwalletrc
)

# Paths for temporary backup
backup_dir="$HOME/.temp-back"
wallpapers_backup="$backup_dir/Wallpaper"
hypr_cache_backup="$backup_dir/.cache"
hypr_config_backup="$backup_dir/configs.lua"
wallpapers="$HOME/.hyprconf/hypr/Wallpaper"
hypr_cache="$HOME/.hyprconf/hypr/.cache"
hypr_config="$HOME/.hyprconf/hypr/configs/configs.lua"

mkdir -p "$backup_dir"

# Function to handle pre-installation backup of user configurations
backup_or_restore() {
    local file_path="$1"
    local file_type="$2"

    if [[ -e "$file_path" ]]; then
        echo
        msg att "An existing $file_type was found."
        local action="n"
        if command -v gum &> /dev/null; then
            if gum confirm "Would you like to back up your existing $file_type to restore it after installation?" \
                --affirmative "Yes, back it up" \
                --negative "No, skip backup"; then
                action="y"
            fi
        else
            msg ask "Would you like to back up your existing $file_type to restore it after installation? [y/N]"
            read -r -p "$(echo -e '\e[1;32mSelect: \e[0m')" choice
            if [[ "$choice" =~ ^[Yy]$ ]]; then
                action="y"
            fi
        fi

        if [[ "$action" == "y" ]]; then
            msg act "Backing up existing $file_type to temporary directory..."
            cp -r "$file_path" "$backup_dir/"
        else
            msg skp "Skipped backing up $file_type."
        fi
    fi
}

# Prompt user for backing up custom wallpaper / hypr config
backup_or_restore "$wallpapers" "wallpaper directory"
backup_or_restore "$hypr_config" "hyprland config file"

[[ -e "$hypr_cache" ]] && cp -r "$hypr_cache" "$backup_dir/"

# Archiving old full hyprconf backup directory if it exists
if [[ -d "$HOME/.backup_hyprconf-${USER}" ]]; then
    msg att "An existing .backup_hyprconf-${USER} directory was found. Archiving it..."
    mkdir -p "$HOME/.archive_hyprconf-${USER}"
    archive_file="$HOME/.archive_hyprconf-${USER}/backup_hyprconf-$(date +%d-%m-%Y_%I-%M-%p)-${USER}.tar.gz"
    tar -czf "$archive_file" -C "$HOME" ".backup_hyprconf-${USER}" &> /dev/null
    rm -rf "$HOME/.backup_hyprconf-${USER}"
    msg dn "Archived ~/.backup_hyprconf-${USER} into $archive_file"
fi

mkdir -p "$HOME/.backup_hyprconf-${USER}"
if [[ -d "$HOME/.hyprconf" ]]; then
    mv "$HOME/.hyprconf" "$HOME/.backup_hyprconf-${USER}/"
    msg dn "Moved previous ~/.hyprconf to ~/.backup_hyprconf-${USER}/"
else
    backed_count=0
    for confs in "${dirs[@]}"; do
        conf_path="$HOME/.config/$confs"
        if [[ -e "$conf_path" && ! -L "$conf_path" ]]; then
            mv "$conf_path" "$HOME/.backup_hyprconf-${USER}/"
            ((backed_count++))
        fi
    done
    msg dn "Backed up $backed_count existing configuration directories to ~/.backup_hyprconf-${USER}/"
fi

# OpenBangla Keyboard environment configuration
keyboard_path="/usr/share/openbangla-keyboard"
if [[ -d "$keyboard_path" ]]; then
    msg act "Setting up environment for OpenBangla-Keyboard..."
    env_updates=""
    grep -q "GTK_IM_MODULE=fcitx" /etc/environment 2>/dev/null || env_updates+="GTK_IM_MODULE=fcitx\n"
    grep -q "QT_IM_MODULE=fcitx" /etc/environment 2>/dev/null || env_updates+="QT_IM_MODULE=fcitx\n"
    grep -q "XMODIFIERS=@im=fcitx" /etc/environment 2>/dev/null || env_updates+="XMODIFIERS=@im=fcitx\n"

    if [[ -n "$env_updates" ]]; then
        printf "%b" "$env_updates" | sudo tee -a /etc/environment > /dev/null
        msg dn "Configured fcitx environment variables in /etc/environment"
    fi
fi

# Copy complete configuration tree
cp -a "$dir/config" "$HOME/.hyprconf"

# Dynamically resolve home paths in Noctalia configuration for current user
if [[ -d "$HOME/.hyprconf/noctalia" ]]; then
    find "$HOME/.hyprconf/noctalia" -type f -name "*.toml" -exec sed -i "s|~|$HOME|g; s|/home/[^/]*|$HOME|g" {} + 2>/dev/null || true
fi

# Environment file paths
env_file="$HOME/.hyprconf/hypr/configs/environment.lua"
monitor_file="$HOME/.hyprconf/hypr/configs/monitor.lua"

# Virtual Machine adjustments
if command -v systemd-detect-virt &> /dev/null && systemd-detect-virt --quiet; then
    msg att "Virtual Machine detected..."
    msg act "Applying VM-specific settings..."
    [[ -f "$env_file" ]] && sed -i '/^-- hl\.env("WLR_NO_HARDWARE_CURSORS"/s/^-- //' "$env_file"
    [[ -f "$env_file" ]] && sed -i '/^-- hl\.env("WLR_RENDERER_ALLOW_SOFTWARE"/s/^-- //' "$env_file"
    cat > "$monitor_file" << 'MONITOR_LUA_EOF'
-- Virtual machine monitor
hl.monitor({
    output   = "Virtual-1",
    mode     = "1920x1080@60",
    position = "auto",
    scale    = "auto",
})
MONITOR_LUA_EOF
fi

# NVIDIA GPU adjustments
if command -v lspci &> /dev/null && lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
    msg act "NVIDIA GPU detected. Setting up GPU environment variables..."
    [[ -f "$env_file" ]] && sed -i '/^-- hl\.env("LIBVA_DRIVER_NAME"/s/^-- //' "$env_file"
    [[ -f "$env_file" ]] && sed -i '/^-- hl\.env("__GLX_VENDOR_LIBRARY_NAME"/s/^-- //' "$env_file"
    [[ -f "$env_file" ]] && sed -i '/^-- hl\.env("GBM_BACKEND"/s/^-- //' "$env_file"
fi

# Fastfetch share directory placement
if [[ -d "$HOME/.hyprconf/fastfetch" && ! -d "$HOME/.local/share/fastfetch" ]]; then
    mkdir -p "$HOME/.local/share"
    mv "$HOME/.hyprconf/fastfetch" "$HOME/.local/share/"
fi

# Symlinking configuration directories and files to ~/.config
for dotfile in "$HOME/.hyprconf"/*; do
    [[ -e "$dotfile" ]] || continue
    configName=$(basename "$dotfile")
    [[ "$configName" == "MIGRATION_TODO.md" ]] && continue
    configPath="$HOME/.config/$configName"
    ln -sfn "$dotfile" "$configPath"
done

# Set permissions for scripts and fish functions
if [[ -d "$scripts_dir" ]]; then
    chmod +x "$scripts_dir"/* 2>/dev/null
    [[ -d "$HOME/.hyprconf/fish/functions" ]] && chmod +x "$HOME/.hyprconf/fish/functions"/* 2>/dev/null
    msg dn "Made all helper scripts executable."
else
    msg err "Scripts directory not found in $scripts_dir"
fi

# Install Fonts
msg act "Checking font installation..."
mkdir -p "$fonts_dir"
if [[ ! -f "$fonts_dir/Icomoon-Feather.ttf" ]]; then
    msg act "Installing fonts to $fonts_dir..."
    cp -a "$dir/extras/fonts/." "$fonts_dir/"
    
    msg act "Updating user font cache..."
    if command -v gum &> /dev/null; then
        gum spin --title="Updating font cache..." -- fc-cache -f "$fonts_dir"
    else
        fc-cache -f "$fonts_dir" &> /dev/null
    fi
    msg dn "Fonts installed successfully."
else
    msg skp "Fonts are already installed."
fi

# Extra files setup (dolphinstaterc, konsole, noctalia state)
if [[ -f "$HOME/.local/state/dolphinstaterc" ]]; then
    mv "$HOME/.local/state/dolphinstaterc" "$HOME/.local/state/dolphinstaterc.back"
fi
if [[ -d "$HOME/.local/state/noctalia" ]]; then
    mv "$HOME/.local/state/noctalia" "$HOME/.local/state/noctalia.back"
fi
if [[ -d "$HOME/.local/share/konsole" ]]; then
    mv "$HOME/.local/share/konsole" "$HOME/.local/share/konsole.back"
fi

mkdir -p "$HOME/.local/state" "$HOME/.local/share"
[[ -f "$dir/local/state/dolphinstaterc" ]] && cp -r "$dir/local/state/dolphinstaterc" "$HOME/.local/state/"
if [[ -d "$dir/local/state/noctalia" ]]; then
    cp -r "$dir/local/state/noctalia" "$HOME/.local/state/"
    find "$HOME/.local/state/noctalia" -type f -exec sed -i "s|~|$HOME|g; s|/home/[^/]*|$HOME|g" {} + 2>/dev/null || true
fi
[[ -d "$dir/local/share/konsole" ]] && cp -r "$dir/local/share/konsole" "$HOME/.local/share/"

# Wayland session file installation
wayland_session_dir="/usr/share/wayland-sessions"
if [[ ! -d "$wayland_session_dir" ]]; then
    msg att "$wayland_session_dir directory not found. Creating..."
    sudo mkdir -p "$wayland_session_dir"
fi
if [[ -f "$dir/extras/hyprland.desktop" ]]; then
    sudo cp "$dir/extras/hyprland.desktop" "$wayland_session_dir/"
    msg dn "Hyprland desktop entry copied to $wayland_session_dir"
fi

# Function to restore temporary backups
restore_backup() {
    local backup_path="$1"
    local original_path="$2"
    local file_type="$3"

    if [[ -e "$backup_path" ]]; then
        if [[ -e "$original_path" ]]; then
            mv "$original_path" "${original_path}.backup"
        fi

        if cp -an "$backup_path" "$original_path"; then
            msg dn "Restored previous $file_type to $original_path"
        else
            msg err "Could not restore $file_type"
        fi

        if [[ -e "${original_path}.backup" ]]; then
            rm -rf "${original_path}.backup"
        fi
    fi
}

# Restore pre-installation user backups
restore_backup "$wallpapers_backup" "$wallpapers" "wallpaper directory"
restore_backup "$hypr_config_backup" "$hypr_config" "hyprland config file"

if [[ -e "$hypr_cache_backup" ]]; then
    rm -rf "$hypr_cache"
    cp -r "$hypr_cache_backup" "$hypr_cache"
fi
rm -rf "$backup_dir"

# Download additional wallpapers (Interactive)
dl_wallpaper=false
if command -v gum &> /dev/null; then
    if gum confirm "Would you like to download additional Wallpapers?"; then
        dl_wallpaper=true
    fi
else
    msg ask "Would you like to download additional Wallpapers? [y/N]"
    read -r -p "$(echo -e '\e[1;32mSelect: \e[0m')" wallpaper_choice
    [[ "$wallpaper_choice" =~ ^[Yy]$ ]] && dl_wallpaper=true
fi

if [[ "$dl_wallpaper" == true ]]; then
    url="https://github.com/shell-ninja/Wallpapers/archive/refs/heads/main.zip"
    target_dir="$HOME/.cache/wallpaper-cache"
    zip_path="$target_dir.zip"
    msg act "Downloading extra wallpapers package..."

    mkdir -p "$HOME/.cache"
    if command -v gum &> /dev/null; then
        gum spin --title="Downloading wallpaper archive..." -- curl -s-fL "$url" -o "$zip_path"
    else
        curl -fL "$url" -o "$zip_path"
    fi

    if [[ -f "$zip_path" ]]; then
        mkdir -p "$target_dir"
        unzip -q "$zip_path" "wallpaper-cache-main/*" -d "$target_dir" > /dev/null 2>&1
        if [[ -d "$target_dir/wallpaper-cache-main" ]]; then
            mv "$target_dir/wallpaper-cache-main/"* "$target_dir/" 2>/dev/null
            rmdir "$target_dir/wallpaper-cache-main" 2>/dev/null
        fi
        rm -f "$zip_path"
    fi

    if [[ -d "$target_dir" && $(ls -A "$target_dir" 2>/dev/null) ]]; then
        mkdir -p "$HOME/.hyprconf/hypr/Wallpaper"
        cp -r "$target_dir"/* "$HOME/.hyprconf/hypr/Wallpaper/" 2>/dev/null
        rm -rf "$target_dir"
        msg dn "Extra wallpapers downloaded successfully."
    else
        msg err "Failed to download wallpapers. Continuing with standard wallpapers."
    fi
fi

# Ensure default wallpaper symlink
if [[ -d "$HOME/.hyprconf/hypr/Wallpaper" ]]; then
    wall_cache_file="$HOME/.hyprconf/hypr/.cache/.wallpaper"
    mkdir -p "$HOME/.hyprconf/hypr/.cache"

    if [[ -f "$HOME/.hyprconf/hypr/Wallpaper/shell-ninja.png" ]]; then
        wallpaper="$HOME/.hyprconf/hypr/Wallpaper/shell-ninja.png"
        echo "shell-ninja" > "$wall_cache_file"
    elif [[ -f "$wall_cache_file" ]]; then
        read -r wallName < "$wall_cache_file"
        [[ -n "$wallName" ]] && wallpaper=$(find "$HOME/.hyprconf/hypr/Wallpaper" -maxdepth 1 -type f -name "${wallName}.*" 2>/dev/null | head -n1)
    fi

    # Fallback to any available wallpaper if still empty
    if [[ -z "$wallpaper" ]]; then
        wallpaper=$(find "$HOME/.hyprconf/hypr/Wallpaper" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) 2>/dev/null | head -n1)
        if [[ -n "$wallpaper" ]]; then
            baseName=$(basename "$wallpaper")
            echo "${baseName%.*}" > "$wall_cache_file"
        fi
    fi

    if [[ -n "$wallpaper" ]]; then
        ln -sf "$wallpaper" "$HOME/.hyprconf/hypr/.cache/current_wallpaper.png"
    fi
fi

# Interactive Noctalia Bar Configuration Selection
select_noctalia_bar_config() {
    local bars_dir="$HOME/.hyprconf/noctalia/bars"
    local selected_bar="full-top"

    if [[ -d "$bars_dir" ]]; then
        local bars=()
        for cfg in "$bars_dir"/*.toml; do
            [[ -f "$cfg" ]] && bars+=("$(basename "$cfg" .toml)")
        done

        if [[ ${#bars[@]} -gt 0 ]]; then
            msg ask "Select your preferred Noctalia Bar layout:"
            if command -v gum &> /dev/null; then
                selected_bar=$(gum choose "${bars[@]}" --selected="full-top")
            elif [[ -t 0 ]]; then
                PS3="$(echo -e '\e[1;32mEnter selection number (default full-top): \e[0m')"
                select opt in "${bars[@]}"; do
                    if [[ -n "$opt" ]]; then
                        selected_bar="$opt"
                        break
                    fi
                done
            fi
        fi
    fi

    [[ -z "$selected_bar" ]] && selected_bar="full-top"
    msg act "Applying Noctalia Bar layout: $selected_bar"
    if [[ -f "$bars_dir/${selected_bar}.toml" ]]; then
        cp "$bars_dir/${selected_bar}.toml" "$HOME/.hyprconf/noctalia/20-bar.toml"
    fi
}

# Interactive Noctalia Launcher Style Selection
select_noctalia_launcher_config() {
    local launchers_dir="$HOME/.hyprconf/noctalia/launchers"
    local selected_launcher="spotlight-glass"

    if [[ -d "$launchers_dir" ]]; then
        local launchers=()
        for cfg in "$launchers_dir"/*.toml; do
            [[ -f "$cfg" ]] && launchers+=("$(basename "$cfg" .toml)")
        done

        if [[ ${#launchers[@]} -gt 0 ]]; then
            msg ask "Select your preferred Noctalia Launcher style:"
            if command -v gum &> /dev/null; then
                selected_launcher=$(gum choose "${launchers[@]}" --selected="spotlight-glass")
            elif [[ -t 0 ]]; then
                PS3="$(echo -e '\e[1;32mEnter selection number (default spotlight-glass): \e[0m')"
                select opt in "${launchers[@]}"; do
                    if [[ -n "$opt" ]]; then
                        selected_launcher="$opt"
                        break
                    fi
                done
            fi
        fi
    fi

    [[ -z "$selected_launcher" ]] && selected_launcher="spotlight-glass"
    msg act "Applying Noctalia Launcher style: $selected_launcher"
    if [[ -f "$launchers_dir/${selected_launcher}.toml" ]]; then
        cp "$launchers_dir/${selected_launcher}.toml" "$HOME/.hyprconf/noctalia/30-launcher.toml"
    fi
}

# Interactive Noctalia Lockscreen Layout Selection
select_noctalia_lockscreen_config() {
    local locks_dir="$HOME/.hyprconf/noctalia/lockscreens"
    local selected_lock="glass-card-center"

    if [[ -d "$locks_dir" ]]; then
        local locks=()
        for cfg in "$locks_dir"/*.toml; do
            [[ -f "$cfg" ]] && locks+=("$(basename "$cfg" .toml)")
        done

        if [[ ${#locks[@]} -gt 0 ]]; then
            msg ask "Select your preferred Noctalia Lockscreen layout:"
            if command -v gum &> /dev/null; then
                selected_lock=$(gum choose "${locks[@]}" --selected="glass-card-center")
            elif [[ -t 0 ]]; then
                PS3="$(echo -e '\e[1;32mEnter selection number (default glass-card-center): \e[0m')"
                select opt in "${locks[@]}"; do
                    if [[ -n "$opt" ]]; then
                        selected_lock="$opt"
                        break
                    fi
                done
            fi
        fi
    fi

    [[ -z "$selected_lock" ]] && selected_lock="glass-card-center"
    msg act "Applying Noctalia Lockscreen layout: $selected_lock"
    if [[ -f "$locks_dir/${selected_lock}.toml" ]]; then
        cp "$locks_dir/${selected_lock}.toml" "$HOME/.hyprconf/noctalia/50-lockscreen.toml"
    fi
}

# Ensure default Hyprlock theme symlink
ln -sf "$HOME/.hyprconf/hypr/lockscreens/hyprlock-1.conf" "$HOME/.hyprconf/hypr/hyprlock.conf"

# Run selection menus
select_noctalia_bar_config
select_noctalia_launcher_config
select_noctalia_lockscreen_config

# Generate colors and cache files for default shell-ninja wallpaper
msg act "Generating colors and cache files..."
if command -v gum &> /dev/null; then
    gum spin --title="Generating color scheme & wallpaper cache..." -- bash -c '"$HOME/.hyprconf/hypr/scripts/wallcache.sh" &>/dev/null && "$HOME/.hyprconf/hypr/scripts/noctalia-colors.sh" "'"$wallpaper"'" &>/dev/null'
else
    "$HOME/.hyprconf/hypr/scripts/wallcache.sh" &> /dev/null
    "$HOME/.hyprconf/hypr/scripts/noctalia-colors.sh" "$wallpaper" &> /dev/null
fi

# Enable nightlight service if systemd user daemon is active
if command -v systemctl &> /dev/null && systemctl --user is-system-running &> /dev/null; then
    systemctl --user daemon-reload &> /dev/null
    systemctl --user enable --now hyprnightlight.timer &> /dev/null
fi

# Set default themes, icon, and cursor if tools are available
if command -v gsettings &> /dev/null; then
    gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3" &> /dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" &> /dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "TokyoNight" &> /dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Ice" &> /dev/null || true
fi

if command -v crudini &> /dev/null; then
    mkdir -p ~/.config/Kvantum
    crudini --set ~/.config/Kvantum/kvantum.kvconfig General theme "Dracula" &> /dev/null || true
    crudini --set ~/.config/kdeglobals Icons Theme "TokyoNight" &> /dev/null || true
fi

# Set Dolphin / KDE default terminal to kitty
msg act "Setting Dolphin default terminal to kitty..."
kdeglobals="$HOME/.config/kdeglobals"
mkdir -p "$HOME/.config"

if command -v kwriteconfig6 &> /dev/null; then
    kwriteconfig6 --file kdeglobals --group General --key TerminalApplication "kitty" &> /dev/null || true
elif command -v kwriteconfig5 &> /dev/null; then
    kwriteconfig5 --file kdeglobals --group General --key TerminalApplication "kitty" &> /dev/null || true
elif command -v crudini &> /dev/null; then
    crudini --set "$kdeglobals" General TerminalApplication "kitty" &> /dev/null || true
else
    if [[ ! -f "$kdeglobals" ]]; then
        cat << 'EOF' >> "$kdeglobals"
[General]
TerminalApplication=kitty
EOF
    elif grep -q '^\[General\]' "$kdeglobals"; then
        if grep -q '^TerminalApplication=' "$kdeglobals"; then
            sed -i 's/^TerminalApplication=.*/TerminalApplication=kitty/' "$kdeglobals"
        else
            sed -i '/^\[General\]/a TerminalApplication=kitty' "$kdeglobals"
        fi
    else
        cat << 'EOF' >> "$kdeglobals"

[General]
TerminalApplication=kitty
EOF
    fi
fi

msg dn "Script execution completed successfully! Please log out and log back in to enjoy your setup."

# === ___ Script Ends Here ___ === #

