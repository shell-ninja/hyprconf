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

# Find pre-existing hypr directory (could be ~/.hyprconf/hypr or ~/.config/hypr)
wallpapers="$HOME/.hyprconf/hypr/Wallpaper"
[[ ! -d "$wallpapers" && -d "$HOME/.config/hypr/Wallpaper" ]] && wallpapers="$HOME/.config/hypr/Wallpaper"

hypr_cache="$HOME/.hyprconf/hypr/.cache"
[[ ! -d "$hypr_cache" && -d "$HOME/.config/hypr/.cache" ]] && hypr_cache="$HOME/.config/hypr/.cache"

mkdir -p "$backup_dir"

# Function to handle pre-installation backup of user wallpaper directory
backup_wallpapers() {
    local wall_path="$1"

    if [[ -d "$wall_path" ]]; then
        echo
        msg att "An existing wallpaper directory was found."
        local action="n"
        if command -v gum &> /dev/null; then
            if gum confirm "Would you like to back up your existing wallpaper directory to restore custom wallpapers after installation?" \
                --affirmative "Yes, back it up" \
                --negative "No, skip backup"; then
                action="y"
            fi
        else
            msg ask "Would you like to back up your existing wallpaper directory to restore custom wallpapers after installation? [y/N]"
            read -r -p "$(echo -e '\e[1;32mSelect: \e[0m')" choice
            if [[ "$choice" =~ ^[Yy]$ ]]; then
                action="y"
            fi
        fi

        if [[ "$action" == "y" ]]; then
            msg act "Backing up existing wallpapers to temporary directory..."
            mkdir -p "$wallpapers_backup"
            cp -a "$wall_path/." "$wallpapers_backup/"
            msg dn "Backed up existing wallpapers."
        else
            msg skp "Skipped backing up wallpaper directory."
        fi
    fi
}

# Prompt user for backing up custom wallpapers
backup_wallpapers "$wallpapers"

[[ -e "$hypr_cache" ]] && cp -r "$hypr_cache" "$backup_dir/"

# Ensure user-mutable state directory exists in ~/.local/share/hyprconf
user_state_dir="$HOME/.local/share/hyprconf"
mkdir -p "$user_state_dir"

# Track whether the user already has custom configurations prior to this installation
had_existing_lockscreen_json=false
had_existing_island_json=false
had_existing_launcher_json=false
had_existing_wallpaper=false
had_hypr_cache=false

[[ -f "$user_state_dir/lockscreen.json" ]] && had_existing_lockscreen_json=true
[[ -f "$user_state_dir/island.json" ]] && had_existing_island_json=true
[[ -f "$user_state_dir/launcher.json" ]] && had_existing_launcher_json=true

# Also check pre-existing ~/.hyprconf and ~/.config before moving/migration
for base_dir in "$HOME/.hyprconf" "$HOME/.config"; do
    [[ -d "$base_dir" ]] || continue
    [[ -f "$base_dir/quickshell/lockscreen.json" && ! -L "$base_dir/quickshell/lockscreen.json" ]] && had_existing_lockscreen_json=true
    [[ -f "$base_dir/quickshell/island/config.json" && ! -L "$base_dir/quickshell/island/config.json" ]] && had_existing_island_json=true
    [[ -f "$base_dir/quickshell/launcher/config.json" && ! -L "$base_dir/quickshell/launcher/config.json" ]] && had_existing_launcher_json=true
done

# Detect if the user already has a .cache directory in hypr/
for check_cache in "$user_state_dir/.cache" "$HOME/.hyprconf/hypr/.cache" "$HOME/.config/hypr/.cache"; do
    if [[ -d "$check_cache" && ( -e "$check_cache/current_wallpaper.png" || -f "$check_cache/.wallpaper" || ( -d "$check_cache" && ! -L "$check_cache" ) ) ]]; then
        had_hypr_cache=true
        break
    fi
done

if [[ "$had_hypr_cache" == "true" ]]; then
    had_existing_wallpaper=true
fi
if [[ -e "$user_state_dir/.cache/current_wallpaper.png" || -f "$user_state_dir/.cache/.wallpaper" ]]; then
    had_existing_wallpaper=true
    had_hypr_cache=true
fi

# Backup existing user color palette & themes before repository files are copied
colors_backup="$backup_dir/existing_colors"
mkdir -p "$colors_backup"

find_first_existing_file() {
    for p in "$@"; do
        if [[ -f "$p" && ! -L "$p" ]]; then
            echo "$p"
            return 0
        fi
    done
    for p in "$@"; do
        if [[ -f "$p" ]]; then
            echo "$p"
            return 0
        fi
    done
    return 1
}

existing_colors_json=$(find_first_existing_file "$user_state_dir/colors.json" "$HOME/.hyprconf/quickshell/colors.json" "$HOME/.config/quickshell/colors.json")
existing_theme_lua=$(find_first_existing_file "$HOME/.hyprconf/hypr/theme.lua" "$HOME/.config/hypr/theme.lua")
existing_colors_sh=$(find_first_existing_file "$HOME/.hyprconf/hypr/scripts/sh/colors.sh" "$HOME/.config/hypr/scripts/sh/colors.sh")
existing_kitty_colors=$(find_first_existing_file "$HOME/.config/kitty/colors-kitty.conf" "$HOME/.hyprconf/kitty/colors-kitty.conf")
existing_qt6ct_colors=$(find_first_existing_file "$HOME/.config/qt6ct/colors/theme.conf")
existing_btop_theme=$(find_first_existing_file "$HOME/.config/btop/themes/noctalia.theme")

[[ -n "$existing_colors_json" ]] && cp "$existing_colors_json" "$colors_backup/colors.json" && cp "$existing_colors_json" "$user_state_dir/colors.json"
[[ -n "$existing_theme_lua" ]] && cp "$existing_theme_lua" "$colors_backup/theme.lua"
[[ -n "$existing_colors_sh" ]] && cp "$existing_colors_sh" "$colors_backup/colors.sh"
[[ -n "$existing_kitty_colors" ]] && cp "$existing_kitty_colors" "$colors_backup/colors-kitty.conf"
[[ -n "$existing_qt6ct_colors" ]] && cp "$existing_qt6ct_colors" "$colors_backup/theme.conf"
[[ -n "$existing_btop_theme" ]] && cp "$existing_btop_theme" "$colors_backup/noctalia.theme"

# Migrate existing configurations to ~/.local/share/hyprconf if present as regular files
migrate_to_state() {
    local src="$1"
    local dest="$2"
    if [[ -f "$src" && ! -L "$src" && ! -f "$dest" ]]; then
        cp "$src" "$dest"
    fi
}

migrate_wallpaper_symlink() {
    local src="$1"
    local dest="$2"
    if [[ -L "$src" ]]; then
        local real_target
        real_target=$(readlink -f "$src" 2>/dev/null || true)
        if [[ -n "$real_target" && -f "$real_target" ]]; then
            ln -sfn "$real_target" "$dest"
        else
            cp -L "$src" "$dest" 2>/dev/null || cp -a "$src" "$dest" 2>/dev/null || true
        fi
    elif [[ -f "$src" ]]; then
        cp -a "$src" "$dest"
    fi
}

# Migrate from both ~/.hyprconf and ~/.config
for base_dir in "$HOME/.hyprconf" "$HOME/.config"; do
    [[ -d "$base_dir" ]] || continue
    migrate_to_state "$base_dir/quickshell/lockscreen.json" "$user_state_dir/lockscreen.json"
    migrate_to_state "$base_dir/quickshell/widgets/widgets.json" "$user_state_dir/widgets.json"
    migrate_to_state "$base_dir/quickshell/island/config.json" "$user_state_dir/island.json"
    migrate_to_state "$base_dir/quickshell/launcher/config.json" "$user_state_dir/launcher.json"
    migrate_to_state "$base_dir/quickshell/dock/dock.json" "$user_state_dir/dock.json"
    migrate_to_state "$base_dir/hypr/configs/monitor.lua" "$user_state_dir/monitor.lua"
    migrate_to_state "$base_dir/hypr/configs/keybinds.lua" "$user_state_dir/keybinds.lua"
    migrate_to_state "$base_dir/hypr/.cache/wallpaper_config.json" "$user_state_dir/wallpaper_config.json"
    migrate_to_state "$base_dir/quickshell/colors.json" "$user_state_dir/colors.json"
done

# Migrate .cache from hypr/ to ~/.local/share/hyprconf/.cache
mkdir -p "$user_state_dir/.cache"
for cdir in "$HOME/.hyprconf/hypr/.cache" "$HOME/.config/hypr/.cache" "$backup_dir/.cache"; do
    if [[ -d "$cdir" && ! -L "$cdir" ]]; then
        for f in "$cdir"/* "$cdir"/.*; do
            [[ -e "$f" || -L "$f" ]] || continue
            cbase=$(basename "$f")
            case "$cbase" in .|..) continue ;; esac
            if [[ "$cbase" == "current_wallpaper.png" ]]; then
                [[ ! -e "$user_state_dir/.cache/current_wallpaper.png" ]] && migrate_wallpaper_symlink "$f" "$user_state_dir/.cache/current_wallpaper.png"
            elif [[ ! -e "$user_state_dir/.cache/$cbase" ]]; then
                cp -a "$f" "$user_state_dir/.cache/$cbase" 2>/dev/null || true
            fi
        done
        msg dn "Migrated hypr .cache ($cdir) to $user_state_dir/.cache"
    fi
done

if [[ -e "$user_state_dir/.cache/current_wallpaper.png" || -f "$user_state_dir/.cache/.wallpaper" ]]; then
    had_existing_wallpaper=true
    had_hypr_cache=true
fi

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
    if [[ -d "$dir/extras" ]]; then
        mkdir -p "$HOME/.hyprconf/extras"
        cp -a "$dir/extras/." "$HOME/.hyprconf/extras/" 2>/dev/null || true
    fi
    if [[ -d "$dir/local" ]]; then
        mkdir -p "$HOME/.hyprconf/local"
        cp -a "$dir/local/." "$HOME/.hyprconf/local/" 2>/dev/null || true
    fi
    msg dn "Configuration tree installed to $HOME/.hyprconf"
fi

# Restore user color palette and themes if user already had them
if [[ "$had_hypr_cache" == "true" || "$had_existing_wallpaper" == "true" ]]; then
    if [[ -f "$colors_backup/colors.json" ]]; then
        cp -f "$colors_backup/colors.json" "$HOME/.hyprconf/quickshell/colors.json"
        cp -f "$colors_backup/colors.json" "$user_state_dir/colors.json" 2>/dev/null || true
    fi
    if [[ -f "$colors_backup/theme.lua" ]]; then
        cp -f "$colors_backup/theme.lua" "$HOME/.hyprconf/hypr/theme.lua"
    fi
    if [[ -f "$colors_backup/colors.sh" ]]; then
        cp -f "$colors_backup/colors.sh" "$HOME/.hyprconf/hypr/scripts/sh/colors.sh"
    fi
    if [[ -f "$colors_backup/colors-kitty.conf" ]]; then
        mkdir -p "$HOME/.config/kitty" "$HOME/.hyprconf/kitty"
        cp -f "$colors_backup/colors-kitty.conf" "$HOME/.config/kitty/colors-kitty.conf"
        cp -f "$colors_backup/colors-kitty.conf" "$HOME/.hyprconf/kitty/colors-kitty.conf"
    fi
    if [[ -f "$colors_backup/theme.conf" ]]; then
        mkdir -p "$HOME/.config/qt6ct/colors" "$HOME/.config/qt5ct/colors"
        cp -f "$colors_backup/theme.conf" "$HOME/.config/qt6ct/colors/theme.conf"
        cp -f "$colors_backup/theme.conf" "$HOME/.config/qt5ct/colors/theme.conf"
    fi
    if [[ -f "$colors_backup/noctalia.theme" ]]; then
        mkdir -p "$HOME/.config/btop/themes"
        cp -f "$colors_backup/noctalia.theme" "$HOME/.config/btop/themes/noctalia.theme"
    fi
    msg dn "Restored user system color palette and theme configuration."
fi

# Ensure Quickshell subprojects have valid relative symlinks & default configs
island_dir="$HOME/.hyprconf/quickshell/island"
launcher_dir="$HOME/.hyprconf/quickshell/launcher"
launcher_theme_dir="$HOME/.hyprconf/quickshell/launcher-theme"
settings_dir="$HOME/.hyprconf/quickshell/settings"
widgets_dir="$HOME/.hyprconf/quickshell/widgets"
lockscreen_dir="$HOME/.hyprconf/quickshell/lockscreen"
dock_dir="$HOME/.hyprconf/quickshell/dock"
updater_dir="$HOME/.hyprconf/quickshell/updater"

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
for sub in "$island_dir" "$launcher_dir" "$launcher_theme_dir" "$settings_dir" "$widgets_dir" "$lockscreen_dir" "$dock_dir"; do
    [[ -d "$sub" ]] || continue
    [[ ! -e "$sub/Theme.qml" || ( -L "$sub/Theme.qml" && "$(readlink "$sub/Theme.qml")" =~ /home/ ) ]] && ln -sfn "../Theme.qml" "$sub/Theme.qml"
    [[ ! -e "$sub/colors.json" || ( -L "$sub/colors.json" && "$(readlink "$sub/colors.json")" =~ /home/ ) ]] && ln -sfn "../colors.json" "$sub/colors.json"
done

# Ensure settings and island qmldir include required components
if [[ -f "$settings_dir/qmldir" ]] && ! grep -q "DockSection" "$settings_dir/qmldir"; then
    echo "DockSection 1.0 DockSection.qml" >> "$settings_dir/qmldir"
fi
if [[ -f "$island_dir/qmldir" ]]; then
    if ! grep -q "KeybindsView" "$island_dir/qmldir"; then
        echo "KeybindsView 1.0 KeybindsView.qml" >> "$island_dir/qmldir"
    fi
    if ! grep -q "WifiNetworkDialog" "$island_dir/qmldir"; then
        echo "WifiNetworkDialog 1.0 WifiNetworkDialog.qml" >> "$island_dir/qmldir"
    fi
fi

# 4. Bootstrap user settings and sync symlinks into ~/.hyprconf
local_hyprconf=""
[[ -d "$dir/local/share/hyprconf" ]] && local_hyprconf="$dir/local/share/hyprconf"
[[ -z "$local_hyprconf" && -d "$HOME/.hyprconf/local/share/hyprconf" ]] && local_hyprconf="$HOME/.hyprconf/local/share/hyprconf"

if [[ -n "$local_hyprconf" && -d "$local_hyprconf" ]]; then
    for tmpl in "$local_hyprconf"/*; do
        [[ -f "$tmpl" ]] || continue
        base=$(basename "$tmpl")
        [[ -L "$user_state_dir/$base" && ! -e "$user_state_dir/$base" ]] && rm -f "$user_state_dir/$base"
        if [[ ! -e "$user_state_dir/$base" ]]; then
            cp -f "$tmpl" "$user_state_dir/$base"
        fi
    done
    if [[ -d "$local_hyprconf/.cache" ]]; then
        mkdir -p "$user_state_dir/.cache"
        for cf in "$local_hyprconf/.cache"/* "$local_hyprconf/.cache"/.*; do
            [[ -e "$cf" ]] || continue
            cbase=$(basename "$cf")
            case "$cbase" in .|..) continue ;; esac
            [[ -L "$user_state_dir/.cache/$cbase" && ! -e "$user_state_dir/.cache/$cbase" ]] && rm -f "$user_state_dir/.cache/$cbase"
            if [[ ! -e "$user_state_dir/.cache/$cbase" ]]; then
                cp -a "$cf" "$user_state_dir/.cache/$cbase"
            fi
        done
    fi
fi

mkdir -p "$widgets_dir" "$island_dir" "$launcher_dir" "$lockscreen_dir" "$dock_dir" "$updater_dir" "$HOME/.hyprconf/hypr/configs"
ln -sfn "$user_state_dir/lockscreen.json" "$HOME/.hyprconf/quickshell/lockscreen.json"
ln -sfn "$user_state_dir/widgets.json" "$widgets_dir/widgets.json"
ln -sfn "$user_state_dir/island.json" "$island_dir/config.json"
ln -sfn "$user_state_dir/launcher.json" "$launcher_dir/config.json"
ln -sfn "$user_state_dir/dock.json" "$dock_dir/dock.json"
ln -sfn "$user_state_dir/monitor.lua" "$HOME/.hyprconf/hypr/configs/monitor.lua"
ln -sfn "$user_state_dir/keybinds.lua" "$HOME/.hyprconf/hypr/configs/keybinds.lua"
# Symlink ~/.hyprconf/hypr/.cache -> ~/.local/share/hyprconf/.cache
mkdir -p "$user_state_dir/.cache"
rm -rf "$HOME/.hyprconf/hypr/.cache" 2>/dev/null || true
ln -sfn "$user_state_dir/.cache" "$HOME/.hyprconf/hypr/.cache"
msg dn "Synchronized user settings and .cache with ~/.local/share/hyprconf"

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

# Fastfetch cleanup from ~/.hyprconf if present from legacy installs
if [[ -d "$HOME/.hyprconf/fastfetch" ]]; then
    mkdir -p "$HOME/.local/share/fastfetch"
    cp -a "$HOME/.hyprconf/fastfetch/." "$HOME/.local/share/fastfetch/" 2>/dev/null || true
    rm -rf "$HOME/.hyprconf/fastfetch"
fi

# Symlinking configuration directories and files to ~/.config
for dotfile in "$HOME/.hyprconf"/*; do
    [[ -e "$dotfile" ]] || continue
    configName=$(basename "$dotfile")
    case "$configName" in
        setup.sh|update.sh|README*|LICENSE*|PACKAGES*|UPDATES*|Logs|*.md|extras|local|fastfetch) continue ;;
    esac
    configPath="$HOME/.config/$configName"
    if [[ -d "$configPath" && ! -L "$configPath" ]]; then
        rm -rf "$configPath"
    fi
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

# Extra files setup (dolphinstaterc, konsole, fastfetch)
if [[ -f "$HOME/.local/state/dolphinstaterc" ]]; then
    rm -f "$HOME/.local/state/dolphinstaterc.back" 2>/dev/null || true
    mv -f "$HOME/.local/state/dolphinstaterc" "$HOME/.local/state/dolphinstaterc.back"
fi

if [[ -d "$HOME/.local/share/konsole" ]]; then
    rm -rf "$HOME/.local/share/konsole.back" 2>/dev/null || true
    mv -f "$HOME/.local/share/konsole" "$HOME/.local/share/konsole.back"
fi

mkdir -p "$HOME/.local/state" "$HOME/.local/share"
local_src=""
[[ -d "$dir/local" ]] && local_src="$dir/local"
[[ -z "$local_src" && -d "$HOME/.hyprconf/local" ]] && local_src="$HOME/.hyprconf/local"

if [[ -n "$local_src" ]]; then
    [[ -f "$local_src/state/dolphinstaterc" ]] && cp -f "$local_src/state/dolphinstaterc" "$HOME/.local/state/"
    if [[ -d "$local_src/share/konsole" ]]; then
        mkdir -p "$HOME/.local/share/konsole"
        cp -a "$local_src/share/konsole/." "$HOME/.local/share/konsole/"
    fi
    if [[ -d "$local_src/share/fastfetch" ]]; then
        mkdir -p "$HOME/.local/share/fastfetch"
        cp -a "$local_src/share/fastfetch/." "$HOME/.local/share/fastfetch/"
        msg dn "Installed fastfetch presets and assets to $HOME/.local/share/fastfetch"
    fi
    if [[ -d "$local_src/share/hyprconf" ]]; then
        mkdir -p "$HOME/.local/share/hyprconf"
        for f in "$local_src/share/hyprconf"/*; do
            [[ -f "$f" ]] || continue
            fname=$(basename "$f")
            [[ -L "$HOME/.local/share/hyprconf/$fname" && ! -e "$HOME/.local/share/hyprconf/$fname" ]] && rm -f "$HOME/.local/share/hyprconf/$fname"
            if [[ ! -e "$HOME/.local/share/hyprconf/$fname" ]]; then
                cp -f "$f" "$HOME/.local/share/hyprconf/$fname"
            fi
        done
        if [[ -d "$local_src/share/hyprconf/.cache" ]]; then
            mkdir -p "$HOME/.local/share/hyprconf/.cache"
            for f in "$local_src/share/hyprconf/.cache"/* "$local_src/share/hyprconf/.cache"/.*; do
                [[ -e "$f" ]] || continue
                fname=$(basename "$f")
                case "$fname" in .|..) continue ;; esac
                [[ -L "$HOME/.local/share/hyprconf/.cache/$fname" && ! -e "$HOME/.local/share/hyprconf/.cache/$fname" ]] && rm -f "$HOME/.local/share/hyprconf/.cache/$fname"
                if [[ ! -e "$HOME/.local/share/hyprconf/.cache/$fname" ]]; then
                    cp -a "$f" "$HOME/.local/share/hyprconf/.cache/$fname"
                fi
            done
        fi
        msg dn "Synchronized user configuration templates to $HOME/.local/share/hyprconf"
    fi
fi

# Initialize default fastfetch configuration symlink if not present
if [[ -d "$HOME/.local/share/fastfetch/presets" ]]; then
    [[ -L "$HOME/.config/fastfetch" ]] && rm -f "$HOME/.config/fastfetch"
    mkdir -p "$HOME/.config/fastfetch"
    if [[ ! -e "$HOME/.config/fastfetch/config.jsonc" && -f "$HOME/.local/share/fastfetch/presets/minimal.jsonc" ]]; then
        ln -sf "$HOME/.local/share/fastfetch/presets/minimal.jsonc" "$HOME/.config/fastfetch/config.jsonc"
    fi
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
        sudo cp -f "$extras_src/hyprland.desktop" "$wayland_session_dir/"
        msg dn "Hyprland desktop entry copied to $wayland_session_dir"
    fi

    # Desktop application entries setup
    msg act "Installing application desktop entries..."
    mkdir -p "$applications_dir"
    desktop_files=("Hyprconf.desktop" "sysupdate.desktop")
    for file in "${desktop_files[@]}"; do
        if [[ -f "$extras_src/$file" ]]; then
            cp -f "$extras_src/$file" "$applications_dir/"
            sed -i "s|/home/shell-ninja|$HOME|g; s|/home/[^/]*|$HOME|g" "$applications_dir/$file"
            msg dn "Installed $file to $applications_dir"
        fi
    done
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "$applications_dir" &> /dev/null || true
    fi
fi

# Restore custom wallpapers from backup (only copying wallpapers that do NOT exist in the new config)
if [[ -d "$wallpapers_backup" ]]; then
    target_wallpapers="$HOME/.hyprconf/hypr/Wallpaper"
    mkdir -p "$target_wallpapers"
    restored_wallpapers=0
    skipped_wallpapers=0

    for wall_entry in "$wallpapers_backup"/*; do
        [[ -e "$wall_entry" ]] || continue
        wall_name=$(basename "$wall_entry")
        if [[ ! -e "$target_wallpapers/$wall_name" && ! -L "$target_wallpapers/$wall_name" ]]; then
            cp -a "$wall_entry" "$target_wallpapers/"
            ((restored_wallpapers++))
        else
            ((skipped_wallpapers++))
        fi
    done

    if [[ $restored_wallpapers -gt 0 ]]; then
        msg dn "Restored $restored_wallpapers custom wallpaper(s) from backup to $target_wallpapers (preserved new configuration wallpapers)."
    else
        msg dn "Wallpaper backup checked; all wallpapers already exist in the newly installed configuration."
    fi
fi

if [[ -e "$hypr_cache_backup" ]]; then
    cp -rn "$hypr_cache_backup/." "$user_state_dir/.cache/" 2>/dev/null || true
    ln -sfn "$user_state_dir/.cache" "$HOME/.hyprconf/hypr/.cache"
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
    mkdir -p "$user_state_dir/.cache"
    local wall_cache_file="$user_state_dir/.cache/.wallpaper"

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
        ln -sfn "$wallpaper" "$user_state_dir/.cache/current_wallpaper.png"
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
    local cache_dir="$user_state_dir/.cache"
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

# Run interactive user selection menus or preserve existing configurations

# 1. Desktop Wallpaper
if [[ "$had_hypr_cache" == "true" || "$had_existing_wallpaper" == "true" ]]; then
    if [[ -e "$user_state_dir/.cache/current_wallpaper.png" ]]; then
        wallpaper="$(readlink -f "$user_state_dir/.cache/current_wallpaper.png" 2>/dev/null || echo "$user_state_dir/.cache/current_wallpaper.png")"
        if [[ -f "$wallpaper" ]]; then
            msg dn "Preserved existing user wallpaper: $(basename "$wallpaper")"
        fi
    fi
    if [[ -z "$wallpaper" || ! -f "$wallpaper" ]]; then
        if [[ -f "$user_state_dir/.cache/.wallpaper" ]]; then
            saved_name=$(cat "$user_state_dir/.cache/.wallpaper" 2>/dev/null | tr -d '[:space:]')
            if [[ -n "$saved_name" ]]; then
                found_wall=$(find "$HOME/.hyprconf/hypr/Wallpaper" -maxdepth 1 -name "${saved_name}*" 2>/dev/null | head -n 1)
                if [[ -n "$found_wall" && -f "$found_wall" ]]; then
                    wallpaper="$found_wall"
                    ln -sfn "$wallpaper" "$user_state_dir/.cache/current_wallpaper.png"
                    msg dn "Preserved existing user wallpaper: $(basename "$wallpaper")"
                fi
            fi
        fi
    fi
fi

if [[ -z "$wallpaper" || ! -f "$wallpaper" ]]; then
    select_wallpaper
fi

# 2. Weather Location
if [[ "$had_existing_lockscreen_json" == "true" ]]; then
    msg dn "Preserved existing weather & lockscreen configuration from ~/.local/share/hyprconf/lockscreen.json"
else
    configure_weather_location
fi

# 3. Dynamic Island Style
if [[ "$had_existing_island_json" == "true" ]]; then
    msg dn "Preserved existing Dynamic Island style from ~/.local/share/hyprconf/island.json"
else
    select_island_style
fi

# 4. App Launcher Style
if [[ "$had_existing_launcher_json" == "true" ]]; then
    msg dn "Preserved existing App Launcher style from ~/.local/share/hyprconf/launcher.json"
else
    select_quickshell_launcher_config
fi

configure_desktop_widgets
setup_user_avatar

# Clean up legacy noctalia files from Hyprland and GTK configurations
rm -f "$HOME/.hyprconf/hypr/noctalia.lua" "$HOME/.config/hypr/noctalia.lua" 2>/dev/null || true
for d in "$HOME/.hyprconf/gtk-3.0" "$HOME/.hyprconf/gtk-4.0" "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"; do
    if [[ -d "$d" ]]; then
        rm -f "$d/noctalia.css" "$d/colors.css" 2>/dev/null || true
    fi
done

# Generate colors and cache files for wallpaper (Quickshell, Hyprland, Kitty, Qt, Btop, Neovim, GTK)
# If user already had their wallpaper and custom palette, preserve it without overwriting
if [[ "$had_hypr_cache" == "true" || "$had_existing_wallpaper" == "true" ]]; then
    msg dn "Preserved existing system theme palette and colors."
else
    msg act "Generating colors and system theme cache..."
    local colors_bin="$HOME/.hyprconf/hypr/scripts/py/hypr-colors.py"
    [[ ! -x "$colors_bin" ]] && colors_bin="$HOME/.hyprconf/hypr/scripts/py/hypr-colors.py"
    if command -v gum &> /dev/null; then
        gum spin --title="Generating color scheme & system theme palette..." -- bash -c "'$colors_bin' '$wallpaper' &>/dev/null"
    else
        "$colors_bin" "$wallpaper" &> /dev/null
    fi
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

