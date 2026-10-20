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
export GUM_CONFIRM_SELECTED_FOREGROUND="#11111b"
export GUM_CONFIRM_SELECTED_BACKGROUND="#89b4fa"
export GUM_CONFIRM_UNSELECTED_FOREGROUND="#cdd6f4"
export GUM_CONFIRM_UNSELECTED_BACKGROUND="#313244"

# Choose menus
export GUM_CHOOSE_CURSOR=" > "
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
export GUM_INPUT_HEADER_FOREGROUND="#f9e2af"
export GUM_INPUT_PLACEHOLDER_FOREGROUND="#6c7086"
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

# Verify no command-line flags are required
if [[ $# -gt 0 ]]; then
    printf "${yellow}!!${end} setup.sh is an interactive installation script (no flags required).\n"
    printf "${blue}\$\$${end} Proceeding with interactive gum prompts...\n\n"
    sleep 1
fi

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
applications_dir="$HOME/.local/share/applications"

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
    quickshell
    nvim
    nwg-look
    pypr
    qt5ct
    qt6ct
    satty
    starship
    systemd
    xfce4
    xsettingsd
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
if [[ "$dir" != "$HOME/.hyprconf" && -d "$HOME/.hyprconf" ]]; then
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
    [[ $backed_count -gt 0 ]] && msg dn "Backed up $backed_count existing configuration directories to ~/.backup_hyprconf-${USER}/"
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

# Copy complete configuration tree if installing from external cloned repo
if [[ "$dir" != "$HOME/.hyprconf" ]]; then
    msg act "Installing configuration files from external source ($dir) to $HOME/.hyprconf..."
    mkdir -p "$HOME/.hyprconf"
    if [[ -d "$dir/config" ]]; then
        cp -a "$dir/config/." "$HOME/.hyprconf/"
    else
        if command -v rsync &> /dev/null; then
            rsync -a --exclude='.git' --exclude='Logs' "$dir/" "$HOME/.hyprconf/"
        else
            cp -a "$dir/." "$HOME/.hyprconf/"
            rm -rf "$HOME/.hyprconf/.git" "$HOME/.hyprconf/Logs" 2>/dev/null || true
        fi
    fi
    # Also copy setup.sh, .version, extras, and local if present in root of repo
    [[ -f "$dir/setup.sh" ]] && cp -f "$dir/setup.sh" "$HOME/.hyprconf/setup.sh" 2>/dev/null || true
    [[ -f "$dir/.version" ]] && cp -f "$dir/.version" "$HOME/.hyprconf/.version" 2>/dev/null || true
    [[ -d "$dir/extras" ]] && cp -a "$dir/extras" "$HOME/.hyprconf/" 2>/dev/null || true
    [[ -d "$dir/local" ]] && cp -a "$dir/local" "$HOME/.hyprconf/" 2>/dev/null || true
    msg dn "Configuration tree installed to $HOME/.hyprconf"
fi

# Ensure Quickshell subprojects have valid relative symlinks & default configs
island_dir="$HOME/.hyprconf/quickshell/island"
launcher_dir="$HOME/.hyprconf/quickshell/launcher"
launcher_theme_dir="$HOME/.hyprconf/quickshell/launcher-theme"
settings_dir="$HOME/.hyprconf/quickshell/settings"
widgets_dir="$HOME/.hyprconf/quickshell/widgets"
lockscreen_dir="$HOME/.hyprconf/quickshell/lockscreen"

# 1. Dynamic Island launcher morphing styles
if [[ -d "$island_dir" && -d "$launcher_dir" ]]; then
    for style in Style1.qml Style2.qml; do
        target="$island_dir/$style"
        if [[ ! -e "$target" || ( -L "$target" && "$(readlink "$target")" =~ /home/ ) ]]; then
            ln -sfn "../launcher/$style" "$target"
        fi
    done
fi

# 2. Settings desktop & lockscreen widget preview symlinks
if [[ -d "$settings_dir" && -d "$widgets_dir" ]]; then
    for w in DesktopClock.qml DesktopVisualizer.qml DesktopSystemMonitor.qml DesktopAudioPlayer.qml DesktopWeather.qml; do
        target="$settings_dir/$w"
        if [[ ! -e "$target" || ( -L "$target" && "$(readlink "$target")" =~ /home/ ) ]]; then
            ln -sfn "../widgets/$w" "$target"
        fi
    done
fi
if [[ -d "$settings_dir" && -d "$lockscreen_dir" ]]; then
    for l in LockscreenSystemGraph.qml LockscreenAudioVisualizer.qml; do
        target="$settings_dir/$l"
        if [[ ! -e "$target" || ( -L "$target" && "$(readlink "$target")" =~ /home/ ) ]]; then
            ln -sfn "../lockscreen/$l" "$target"
        fi
    done
fi

# 3. Ensure Theme.qml & colors.json relative symlinks exist in all subprojects
for sub in "$island_dir" "$launcher_dir" "$launcher_theme_dir" "$settings_dir" "$widgets_dir" "$lockscreen_dir"; do
    [[ -d "$sub" ]] || continue
    [[ ! -e "$sub/Theme.qml" || ( -L "$sub/Theme.qml" && "$(readlink "$sub/Theme.qml")" =~ /home/ ) ]] && ln -sfn "../Theme.qml" "$sub/Theme.qml"
    [[ ! -e "$sub/colors.json" || ( -L "$sub/colors.json" && "$(readlink "$sub/colors.json")" =~ /home/ ) ]] && ln -sfn "../colors.json" "$sub/colors.json"
done

# 4. Ensure desktop widgets default configuration
widgets_json="$widgets_dir/widgets.json"
if [[ -d "$widgets_dir" && ! -f "$widgets_json" ]]; then
    cat > "$widgets_json" << 'WIDGETS_JSON_EOF'
{
  "enabled": false,
  "global_glass_opacity": 0.65,
  "widgets": {
    "clock": {
      "id": "clock",
      "type": "clock",
      "title": "Desktop Clock",
      "enabled": true,
      "x": 0.5,
      "y": 0.28,
      "width": 360,
      "height": 130,
      "scale": 1,
      "format_24h": false,
      "show_seconds": false,
      "show_date": true,
      "show_greeting": true,
      "glass_opacity": 0.65
    },
    "visualizer": {
      "id": "visualizer",
      "type": "visualizer",
      "title": "Audio Visualizer",
      "enabled": true,
      "x": 0.5,
      "y": 0.74,
      "width": 520,
      "height": 90,
      "scale": 1,
      "bar_count": 28,
      "style": "bars",
      "glass_opacity": 0.55
    },
    "system_monitor": {
      "id": "system_monitor",
      "type": "system_monitor",
      "title": "System Monitor",
      "enabled": true,
      "x": 0.84,
      "y": 0.34,
      "width": 280,
      "height": 230,
      "scale": 1,
      "show_cpu": true,
      "show_ram": true,
      "show_disk": true,
      "show_temp": true,
      "glass_opacity": 0.65
    },
    "audio_player": {
      "id": "audio_player",
      "type": "audio_player",
      "title": "Audio Player",
      "enabled": true,
      "x": 0.16,
      "y": 0.34,
      "width": 340,
      "height": 150,
      "scale": 1,
      "compact": false,
      "glass_opacity": 0.65
    },
    "weather": {
      "id": "weather",
      "type": "weather",
      "title": "Weather Forecast",
      "enabled": true,
      "x": 0.16,
      "y": 0.55,
      "width": 320,
      "height": 125,
      "scale": 1,
      "unit": "C",
      "show_location": true,
      "show_details": true,
      "show_background": false,
      "glass_opacity": 0.65
    }
  }
}
WIDGETS_JSON_EOF
    msg dn "Initialized default Desktop Widgets configuration in $widgets_json"
fi

# 5. Ensure Launcher configuration exists
launcher_cfg="$launcher_dir/config.json"
if [[ -d "$launcher_dir" && ! -f "$launcher_cfg" ]]; then
    printf '{\n  "theme": "style-2"\n}\n' > "$launcher_cfg"
fi

# 6. Ensure Dynamic Island configuration exists
island_cfg="$island_dir/config.json"
if [[ -d "$island_dir" && ! -f "$island_cfg" ]]; then
    cat > "$island_cfg" << 'ISLAND_CFG_EOF'
{
  "position": "top",
  "auto_hide": false,
  "style": "capsule",
  "matrix_stream": false,
  "visualizer": {
    "enabled": true,
    "bar_count": 8,
    "style": "wave",
    "move_to_bottom_on_hover": true
  }
}
ISLAND_CFG_EOF
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
    case "$configName" in
        setup.sh|update.sh|README*|LICENSE*|PACKAGES*|UPDATES*|Logs|*.md|extras|local) continue ;;
    esac
    configPath="$HOME/.config/$configName"
    ln -sfn "$dotfile" "$configPath"
done

# Set permissions for scripts and fish functions
if [[ -d "$scripts_dir" ]]; then
    chmod +x "$scripts_dir"/* "$scripts_dir/sh"/* "$scripts_dir/py"/* 2>/dev/null || true
    [[ -d "$HOME/.hyprconf/fish/functions" ]] && chmod +x "$HOME/.hyprconf/fish/functions"/* 2>/dev/null
    msg dn "Made all helper scripts executable."
else
    msg err "Scripts directory not found in $scripts_dir"
fi

# Install Fonts
msg act "Checking font installation..."
mkdir -p "$fonts_dir"
font_source=""
[[ -d "$dir/extras/fonts" ]] && font_source="$dir/extras/fonts"
[[ -z "$font_source" && -d "$HOME/.hyprconf/extras/fonts" ]] && font_source="$HOME/.hyprconf/extras/fonts"

if [[ -n "$font_source" && ! -f "$fonts_dir/Icomoon-Feather.ttf" ]]; then
    msg act "Installing fonts to $fonts_dir..."
    cp -a "$font_source/." "$fonts_dir/"
    
    msg act "Updating user font cache..."
    if command -v gum &> /dev/null; then
        gum spin --title="Updating font cache..." -- fc-cache -f "$fonts_dir"
    else
        fc-cache -f "$fonts_dir" &> /dev/null
    fi
    msg dn "Fonts installed successfully."
elif [[ -f "$fonts_dir/Icomoon-Feather.ttf" ]]; then
    msg skp "Fonts are already installed."
fi

# Extra files setup (dolphinstaterc, konsole)
if [[ -f "$HOME/.local/state/dolphinstaterc" ]]; then
    mv "$HOME/.local/state/dolphinstaterc" "$HOME/.local/state/dolphinstaterc.back"
fi

if [[ -d "$HOME/.local/share/konsole" ]]; then
    mv "$HOME/.local/share/konsole" "$HOME/.local/share/konsole.back"
fi

mkdir -p "$HOME/.local/state" "$HOME/.local/share"
local_src=""
[[ -d "$dir/local" ]] && local_src="$dir/local"
[[ -z "$local_src" && -d "$HOME/.hyprconf/local" ]] && local_src="$HOME/.hyprconf/local"

if [[ -n "$local_src" ]]; then
    [[ -f "$local_src/state/dolphinstaterc" ]] && cp -r "$local_src/state/dolphinstaterc" "$HOME/.local/state/"
    [[ -d "$local_src/share/konsole" ]] && cp -r "$local_src/share/konsole" "$HOME/.local/share/"
fi

# Wayland session & desktop application entries
extras_src=""
[[ -d "$dir/extras" ]] && extras_src="$dir/extras"
[[ -z "$extras_src" && -d "$HOME/.hyprconf/extras" ]] && extras_src="$HOME/.hyprconf/extras"

if [[ -n "$extras_src" ]]; then
    wayland_session_dir="/usr/share/wayland-sessions"
    if [[ ! -d "$wayland_session_dir" ]]; then
        msg att "$wayland_session_dir directory not found. Creating..."
        sudo mkdir -p "$wayland_session_dir"
    fi
    if [[ -f "$extras_src/hyprland.desktop" ]]; then
        sudo cp "$extras_src/hyprland.desktop" "$wayland_session_dir/"
        msg dn "Hyprland desktop entry copied to $wayland_session_dir"
    fi

    # Desktop application entries setup
    msg act "Installing application desktop entries..."
    mkdir -p "$applications_dir"
    desktop_files=("Hyprconf.desktop" "sysupdate.desktop")
    for file in "${desktop_files[@]}"; do
        if [[ -f "$extras_src/$file" ]]; then
            cp "$extras_src/$file" "$applications_dir/"
            sed -i "s|/home/shell-ninja|$HOME|g; s|/home/[^/]*|$HOME|g" "$applications_dir/$file"
            msg dn "Installed $file to $applications_dir"
        fi
    done
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "$applications_dir" &> /dev/null || true
    fi
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

# ─── Interactive Configuration Prompts (via Gum) ─────────────────────────

# 1. Desktop Wallpaper Setup
select_wallpaper() {
    echo
    if command -v gum &> /dev/null; then
        gum style --border rounded --margin "0 0" --padding "0 1" --border-foreground "#89b4fa" --foreground "#89b4fa" --bold "Desktop Wallpaper Setup"
    else
        msg act "Desktop Wallpaper Setup..."
    fi

    local wall_dir="$HOME/.hyprconf/hypr/Wallpaper"
    mkdir -p "$wall_dir"
    mkdir -p "$HOME/.hyprconf/hypr/.cache"
    local wall_cache_file="$HOME/.hyprconf/hypr/.cache/.wallpaper"

    local selected_wall="shell-ninja.png"
    wallpaper="$wall_dir/$selected_wall"
    if [[ ! -f "$wallpaper" ]]; then
        local found_wall
        found_wall=$(find "$wall_dir" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null | head -n 1)
        if [[ -n "$found_wall" ]]; then
            wallpaper="$found_wall"
            selected_wall=$(basename "$found_wall")
        fi
    fi

    if [[ -f "$wallpaper" ]]; then
        local baseName="${selected_wall%.*}"
        echo "$baseName" > "$wall_cache_file"
        ln -sf "$wallpaper" "$HOME/.hyprconf/hypr/.cache/current_wallpaper.png"
        msg dn "Wallpaper set to: $selected_wall"
    fi
}

# 2. Dynamic Island Style Selection
select_island_style() {
    echo
    if command -v gum &> /dev/null; then
        gum style --border rounded --margin "0 0" --padding "0 1" --border-foreground "#89b4fa" --foreground "#89b4fa" --bold "Dynamic Island Style"
    fi

    local island_cfg="$HOME/.hyprconf/quickshell/island/config.json"
    local chosen_style="capsule"

    if command -v gum &> /dev/null; then
        local choice
        choice=$(gum choose --selected="Capsule: Floating Organic Pill (Default)" \
            --header="Select your preferred Dynamic Island style:" \
            "Capsule: Floating Organic Pill (Default)" \
            "Orbital: Curved Dynamic Notch" \
            "Split Wings: Twin Segmented Bar" \
            "Minimal Rail: Compact Sleek Track")
        case "$choice" in
            *"Orbital"*) chosen_style="orbital" ;;
            *"Split Wings"*) chosen_style="split_wings" ;;
            *"Minimal Rail"*) chosen_style="minimal_rail" ;;
            *) chosen_style="capsule" ;;
        esac
    elif [[ -t 0 ]]; then
        msg ask "Select your preferred Dynamic Island style:"
        PS3="$(echo -e '\e[1;32mEnter Dynamic Island style number: \e[0m')"
        select opt in "Capsule (Default)" "Orbital" "Split Wings" "Minimal Rail"; do
            case $REPLY in
                2) chosen_style="orbital"; break ;;
                3) chosen_style="split_wings"; break ;;
                4) chosen_style="minimal_rail"; break ;;
                *) chosen_style="capsule"; break ;;
            esac
        done
    fi

    [[ -z "$chosen_style" ]] && chosen_style="capsule"
    msg act "Applying Dynamic Island style: $chosen_style"
    mkdir -p "$(dirname "$island_cfg")"
    if [[ -f "$island_cfg" ]]; then
        python3 -c "
import json
p = '$island_cfg'
try:
    with open(p, 'r') as f: data = json.load(f)
    data['style'] = '$chosen_style'
    with open(p, 'w') as f: json.dump(data, f, indent=2)
except Exception: pass
" 2>/dev/null || true
    else
        cat > "$island_cfg" << ISLAND_JSON_EOF
{
  "position": "top",
  "auto_hide": false,
  "style": "$chosen_style",
  "matrix_stream": false,
  "visualizer": {
    "enabled": true,
    "bar_count": 8,
    "style": "wave",
    "move_to_bottom_on_hover": true
  }
}
ISLAND_JSON_EOF
    fi
}

# 3. Quickshell App Launcher Style Selection
select_quickshell_launcher_config() {
    echo
    if command -v gum &> /dev/null; then
        gum style --border rounded --margin "0 0" --padding "0 1" --border-foreground "#89b4fa" --foreground "#89b4fa" --bold "App Launcher Theme (Island Notch Expansion)"
    fi

    local config_file="$HOME/.hyprconf/quickshell/launcher/config.json"
    local selected_launcher="style-2"

    if command -v gum &> /dev/null; then
        local choice
        choice=$(gum choose --selected="Style 2: Panoramic Grid (Default)" \
            --header="Select your preferred App Launcher style:" \
            "Style 2: Panoramic Grid (Default)" \
            "Style 1: Slanted Split Quad")
        if [[ "$choice" =~ "Style 1" ]]; then
            selected_launcher="style-1"
        else
            selected_launcher="style-2"
        fi
    elif [[ -t 0 ]]; then
        msg ask "Select your preferred App Launcher style:"
        PS3="$(echo -e '\e[1;32mEnter selection number (default Style 2): \e[0m')"
        select opt in "Style 2: Panoramic Grid" "Style 1: Slanted Split Quad"; do
            case $REPLY in
                2) selected_launcher="style-1"; break ;;
                *) selected_launcher="style-2"; break ;;
            esac
        done
    fi

    [[ -z "$selected_launcher" ]] && selected_launcher="style-2"
    msg act "Applying App Launcher style: $selected_launcher"
    mkdir -p "$(dirname "$config_file")"
    printf '{\n  \"theme\": \"%s\"\n}\n' "$selected_launcher" > "$config_file"
}

# 4. Desktop Widgets Configuration
configure_desktop_widgets() {
    local widgets_file="$HOME/.hyprconf/quickshell/widgets/widgets.json"

    # Turn off by default without user prompt
    if [[ -f "$widgets_file" ]]; then
        python3 -c "
import json
p = '$widgets_file'
try:
    with open(p, 'r') as f: data = json.load(f)
    data['enabled'] = False
    with open(p, 'w') as f: json.dump(data, f, indent=2)
except Exception: pass
" 2>/dev/null || true
    fi
    msg dn "Desktop Widgets layer turned off by default (can be enabled anytime in Settings app)."
}

# 5. Interactive Weather Location Configuration
configure_weather_location() {
    echo
    if command -v gum &> /dev/null; then
        gum style --border rounded --margin "0 0" --padding "0 1" --border-foreground "#89b4fa" --foreground "#89b4fa" --bold "Weather Forecast & Location Setup"
    else
        msg ask "Set your location for weather forecast:"
    fi

    local city=""
    local country=""
    if command -v gum &> /dev/null; then
        city=$(gum input --placeholder "Enter your City (e.g. London, Tokyo, New York)" --header "City / Town (press Enter to skip):" --prompt "  > ")
        if [[ "$city" =~ , ]]; then
            country="$(echo "$city" | cut -d',' -f2- | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
            city="$(echo "$city" | cut -d',' -f1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        fi
        if [[ -n "$city" && -z "$country" ]]; then
            country=$(gum input --placeholder "Enter your Country (e.g. United Kingdom, Japan, USA)" --header "Country:" --prompt "  > ")
        fi
    elif [[ -t 0 ]]; then
        read -r -p "$(echo -e "\e[1;32mEnter your City (leave blank to skip): \e[0m")" input_city
        city="$input_city"
        if [[ "$city" =~ , ]]; then
            country="$(echo "$city" | cut -d',' -f2- | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
            city="$(echo "$city" | cut -d',' -f1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        fi
        if [[ -n "$city" && -z "$country" ]]; then
            read -r -p "$(echo -e "\e[1;32mEnter your Country: \e[0m")" input_country
            country="$input_country"
        fi
    fi

    city="$(echo "$city" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    country="$(echo "$country" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    if [[ -n "$city" || -n "$country" ]]; then
        msg act "Setting weather location: $city, $country"
        local lock_json="$HOME/.hyprconf/quickshell/lockscreen.json"
        if [[ -f "$lock_json" ]]; then
            python3 -c "
import json
p = '$lock_json'
try:
    with open(p, 'r') as f: data = json.load(f)
    if 'modules' not in data: data['modules'] = {}
    data['modules']['weather_city'] = '$city'
    data['modules']['weather_country'] = '$country'
    with open(p, 'w') as f: json.dump(data, f, indent=4)
except Exception: pass
" 2>/dev/null || true
        fi
        # Prime the weather cache
        local weather_bin="$HOME/.hyprconf/hypr/scripts/py/weather.py"
        [[ ! -x "$weather_bin" ]] && weather_bin="$HOME/.hyprconf/hypr/scripts/py/weather.py"
        if [[ -x "$weather_bin" ]]; then
            "$weather_bin" --force &>/dev/null || true
        fi
        msg dn "Weather location updated successfully ($city, $country)."
    else
        msg skp "Location left blank. Skipped setting weather location."
    fi
}

# 6. Automatic User Face Avatar setup
setup_user_avatar() {
    msg act "Setting up user face avatar..."
    local cache_dir="$HOME/.hyprconf/hypr/.cache"
    mkdir -p "$cache_dir"
    local face_target="$cache_dir/.face"
    if [[ ! -f "$face_target" ]]; then
        if [[ -f "$HOME/.face" && ! -L "$HOME/.face" ]]; then
            cp "$HOME/.face" "$face_target"
        elif [[ -f "$wallpaper" ]]; then
            python3 -c "
from PIL import Image
try:
    im = Image.open('$wallpaper').convert('RGBA')
    w, h = im.size
    min_d = min(w, h)
    im = im.crop(((w-min_d)//2, (h-min_d)//2, (w+min_d)//2, (h+min_d)//2)).resize((512, 512), Image.Resampling.LANCZOS)
    im.save('$face_target', 'PNG')
except Exception: pass
" 2>/dev/null || true
        fi
    fi
    if [[ -f "$face_target" ]]; then
        ln -sfn "$face_target" "$HOME/.face"
        msg dn "Avatar successfully linked to ~/.face"
    fi
}

# Run interactive user selection menus
select_wallpaper
configure_weather_location
select_island_style
select_quickshell_launcher_config
configure_desktop_widgets
setup_user_avatar

# Clean up legacy noctalia files from GTK configurations
for d in "$HOME/.hyprconf/gtk-3.0" "$HOME/.hyprconf/gtk-4.0" "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"; do
    if [[ -d "$d" ]]; then
        rm -f "$d/noctalia.css" "$d/colors.css" 2>/dev/null || true
    fi
done

# Generate colors and cache files for wallpaper (Quickshell, Hyprland, Kitty, Qt, Btop, Neovim, GTK)
msg act "Generating colors and system theme cache..."
local colors_bin="$HOME/.hyprconf/hypr/scripts/py/hypr-colors.py"
[[ ! -x "$colors_bin" ]] && colors_bin="$HOME/.hyprconf/hypr/scripts/py/hypr-colors.py"
if command -v gum &> /dev/null; then
    gum spin --title="Generating color scheme & system theme palette..." -- bash -c "'$colors_bin' '$wallpaper' &>/dev/null"
else
    "$colors_bin" "$wallpaper" &> /dev/null
fi

# Enable pkgupdate-notifier service if systemd user daemon is active
if command -v systemctl &> /dev/null && systemctl --user is-system-running &> /dev/null; then
    systemctl --user daemon-reload &> /dev/null
    systemctl --user enable --now pkgupdate-notifier.service &> /dev/null
fi

# Set default themes, icon, and cursor if tools are available
if command -v gsettings &> /dev/null; then
    gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3" &> /dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" &> /dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "kora" &> /dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Ice" &> /dev/null || true
fi

# Ensure XDG Directory Discovery for Qt/KDE
icons_dir="$HOME/.icons"
mkdir -p "$HOME/.local/share/icons"
if [[ -d "$icons_dir/kora" ]]; then
    ln -snf "$icons_dir/kora" "$HOME/.local/share/icons/kora"
fi
for kora_dir in "$icons_dir"/kora*; do
    if [[ -d "$kora_dir" ]]; then
        ln -snf "$kora_dir" "$HOME/.local/share/icons/$(basename "$kora_dir")"
    fi
done

# 1. Detect KDE configuration tool for kdeglobals
if command -v kwriteconfig6 &> /dev/null; then
    KWRITECONFIG="kwriteconfig6"
elif command -v kwriteconfig5 &> /dev/null; then
    KWRITECONFIG="kwriteconfig5"
elif command -v kwriteconfig &> /dev/null; then
    KWRITECONFIG="kwriteconfig"
fi

# 2. Set KDE Icon Theme (kdeglobals)
if [ -n "$KWRITECONFIG" ]; then
    "$KWRITECONFIG" --file kdeglobals --group Icons --key Theme "kora"
elif command -v crudini &> /dev/null; then
    crudini --ini-options=nospace --set "$HOME/.config/kdeglobals" Icons Theme "kora"
fi

# 3. Set Qt Platform Theme (qt5ct / qt6ct) Icon Theme
mkdir -p "$HOME/.config/qt5ct" "$HOME/.config/qt6ct"
for qtconf in "$HOME/.config/qt5ct/qt5ct.conf" "$HOME/.config/qt6ct/qt6ct.conf"; do
    if command -v crudini &> /dev/null; then
        crudini --ini-options=nospace --set "$qtconf" Appearance icon_theme "kora"
    elif [ -n "$KWRITECONFIG" ]; then
        "$KWRITECONFIG" --file "$qtconf" --group Appearance --key icon_theme "kora"
    else
        if [[ -f "$qtconf" ]]; then
            if grep -q "^\[Appearance\]" "$qtconf"; then
                if grep -q "^icon_theme=" "$qtconf"; then
                    sed -i 's/^icon_theme=.*/icon_theme=kora/' "$qtconf"
                else
                    sed -i '/^\[Appearance\]/a icon_theme=kora' "$qtconf"
                fi
            else
                printf "\n[Appearance]\nicon_theme=kora\n" >> "$qtconf"
            fi
        else
            printf "[Appearance]\nicon_theme=kora\n" > "$qtconf"
        fi
    fi
done

# 4. Set Kvantum Theme (crudini works here, or fallback to kwriteconfig)
mkdir -p "$HOME/.config/Kvantum"
if command -v crudini &> /dev/null; then
    crudini --set ~/.config/Kvantum/kvantum.kvconfig General theme "Dracula"
elif [ -n "$KWRITECONFIG" ]; then
    "$KWRITECONFIG" --file ~/.config/Kvantum/kvantum.kvconfig --group General --key theme "Dracula"
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

# Verify and ensure Hyprland autostart commands in exec.lua
exec_lua="$HOME/.hyprconf/hypr/configs/exec.lua"
if [[ -f "$exec_lua" ]]; then
    if ! grep -q "qs-island.sh --start" "$exec_lua"; then
        sed -i '/hl.on("hyprland.start", function()/a \    hl.exec_cmd(sh_dir .. "/qs-island.sh --start &")' "$exec_lua"
    fi
    if ! grep -q "qs-widgets.sh --start" "$exec_lua"; then
        sed -i '/hl.on("hyprland.start", function()/a \    hl.exec_cmd(sh_dir .. "/qs-widgets.sh --start &")' "$exec_lua"
    fi
    if ! grep -q "hyprconf.sh --daemon" "$exec_lua"; then
        sed -i '/hl.on("hyprland.start", function()/a \    hl.exec_cmd(sh_dir .. "/hyprconf.sh --daemon &")' "$exec_lua"
    fi
    msg dn "Verified Dynamic Island, Desktop Widgets & Hyprconf update daemons in exec.lua"
fi

# Ensure all helper scripts and setup script are executable
chmod +x "$HOME/.hyprconf/hypr/scripts"/* "$HOME/.hyprconf/hypr/scripts/sh"/* "$HOME/.hyprconf/hypr/scripts/py"/* "$dir/setup.sh" 2>/dev/null || true

msg dn "Script execution completed successfully! Please log out and log back in to enjoy your setup."

# === ___ Script Ends Here ___ === #

