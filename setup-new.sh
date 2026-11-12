#!/usr/bin/env bash

# Advanced Hyprland Installation Script by
# Shell Ninja ( https://github.com/shell-ninja )

# Color definitions
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
magenta="\e[1;35m"
cyan="\e[1;36m"
orange="\x1b[38;5;214m"
end="\e[0m"

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

###------ Startup & Progress Helpers ------###

dir="$(dirname "$(realpath "$0")")"
log_dir="$dir/Logs"
log="$log_dir/dotfiles.log"
mkdir -p "$log_dir"
touch "$log"

log_msg() {
    local text="$1"
    local clean_text
    clean_text="$(echo -e "$text" | sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g')"
    printf "[%s] %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$clean_text" >> "$log"
}

step_num=0
current_step_label=""
step_active=false

is_interactive_tty() {
    [[ -t 1 && -z "${HYPRCONF_TUI:-}" ]]
}

step_start() {
    local label="$1"
    step_num=$((step_num + 1))
    current_step_label="$label"
    step_active=true
    log_msg "[ $step_num ] - $label..."
    if is_interactive_tty; then
        printf "${cyan}[ %d ] - %s...${end}" "$step_num" "$label"
    else
        printf "[ %d ] - %s...\n" "$step_num" "$label"
    fi
}

step_done() {
    local mark="${1:-✓}"
    [[ "$step_active" == "true" ]] || return 0
    step_active=false
    log_msg "[ $step_num ] - $current_step_label... [ $mark ]"
    if is_interactive_tty; then
        printf "\r\033[K${green}[ %d ] - %s... [ %s ]${end}\n" "$step_num" "$current_step_label" "$mark"
    else
        printf "[ %d ] - %s... [ %s ]\n" "$step_num" "$current_step_label" "$mark"
    fi
}

step_fail() {
    local mark="${1:-✗}"
    [[ "$step_active" == "true" ]] || return 0
    step_active=false
    log_msg "[ $step_num ] - $current_step_label... [ $mark ]"
    if is_interactive_tty; then
        printf "\r\033[K${red}[ %d ] - %s... [ %s ]${end}\n" "$step_num" "$current_step_label" "$mark"
    else
        printf "[ %d ] - %s... [ %s ]\n" "$step_num" "$current_step_label" "$mark"
    fi
}

sudo_keepalive_pid=""
cleanup_sudo_keepalive() {
    if [[ -n "$sudo_keepalive_pid" ]]; then
        kill "$sudo_keepalive_pid" 2>/dev/null || true
        sudo_keepalive_pid=""
    fi
}

trap 'cleanup_sudo_keepalive' EXIT
trap 'cleanup_sudo_keepalive; if [[ "$step_active" == "true" ]]; then step_fail "✗"; fi; exit 130' INT TERM

# Keep detailed diagnostic messages in log; show only errors or fallback ask prompts on terminal
msg() {
    local actn=$1
    local text=$2

    log_msg "[$actn] $text"
    case $actn in
        ask) printf "${orange}??${end} %s\n" "$text" ;;
        err)
            if [[ "$step_active" == "true" ]]; then
                step_fail "✗"
            fi
            printf "${red}>< Error: %s${end}\n" "$text" >&2
            ;;
    esac
}

# Directories ----------------------------
hypr_dir="$HOME/.hyprconf/hypr"
scripts_dir="$hypr_dir/scripts"
fonts_dir="$HOME/.local/share/fonts"
applications_dir="$HOME/.local/share/applications"

mkdir -p ~/.config
dirs=(
    btop
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

user_state_dir="$HOME/.local/share/hyprconf"

# Track whether user already has custom configurations prior to installation
had_existing_lockscreen_json=false
had_existing_island_json=false
had_existing_launcher_json=false
had_existing_wallpaper=false
had_hypr_cache=false

[[ -f "$user_state_dir/lockscreen.json" ]] && had_existing_lockscreen_json=true
[[ -f "$user_state_dir/island.json" ]] && had_existing_island_json=true
[[ -f "$user_state_dir/launcher.json" ]] && had_existing_launcher_json=true

for base_dir in "$HOME/.hyprconf" "$HOME/.config"; do
    [[ -d "$base_dir" ]] || continue
    [[ -f "$base_dir/quickshell/lockscreen.json" && ! -L "$base_dir/quickshell/lockscreen.json" ]] && had_existing_lockscreen_json=true
    [[ -f "$base_dir/quickshell/island/config.json" && ! -L "$base_dir/quickshell/island/config.json" ]] && had_existing_island_json=true
    [[ -f "$base_dir/quickshell/launcher/config.json" && ! -L "$base_dir/quickshell/launcher/config.json" ]] && had_existing_launcher_json=true
done

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

# ─── Collect All Required User Inputs Upfront ────────────────────────────
backup_wallpapers_action="n"
prompted_weather_city=""
prompted_weather_country=""
prompted_island_style="prism_blade"
prompted_launcher_style="style-2"

prompt_backup_wallpapers() {
    [[ -d "$wallpapers" ]] || return 0
    if command -v gum &> /dev/null; then
        if gum confirm "Back up your existing wallpaper directory before installation?" \
            --affirmative "Yes, back it up" \
            --negative "No, skip backup"; then
            backup_wallpapers_action="y"
        fi
    elif [[ -t 0 ]]; then
        msg ask "Back up your existing wallpaper directory before installation? [y/N]"
        read -r -p "$(echo -e '\e[1;32mSelect: \e[0m')" choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            backup_wallpapers_action="y"
        fi
    fi
}

prompt_weather_location() {
    [[ "$had_existing_lockscreen_json" == "true" ]] && return 0
    local city=""
    local country=""
    if command -v gum &> /dev/null; then
        city=$(gum input --placeholder "Enter your City (e.g. London, Tokyo, New York)" --header "Weather City / Town (press Enter to skip):" --prompt "  > ")
        if [[ "$city" =~ , ]]; then
            country="$(echo "$city" | cut -d',' -f2- | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
            city="$(echo "$city" | cut -d',' -f1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        fi
        if [[ -n "$city" && -z "$country" ]]; then
            country=$(gum input --placeholder "Enter your Country (e.g. United Kingdom, Japan, USA)" --header "Weather Country:" --prompt "  > ")
        fi
    elif [[ -t 0 ]]; then
        read -r -p "$(echo -e "\e[1;32mEnter your City for weather (leave blank to skip): \e[0m")" city
        if [[ "$city" =~ , ]]; then
            country="$(echo "$city" | cut -d',' -f2- | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
            city="$(echo "$city" | cut -d',' -f1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        fi
        if [[ -n "$city" && -z "$country" ]]; then
            read -r -p "$(echo -e "\e[1;32mEnter your Country: \e[0m")" country
        fi
    fi
    prompted_weather_city="$(echo "$city" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    prompted_weather_country="$(echo "$country" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
}

prompt_island_style() {
    [[ "$had_existing_island_json" == "true" ]] && return 0
    if command -v gum &> /dev/null; then
        local choice
        choice=$(gum choose --selected="Prism Blade: Flagship Tactical HUD (Default)" \
            --header="Select your preferred Dynamic Island style:" \
            "Prism Blade: Flagship Tactical HUD (Default)" \
            "Orbital: Curved Dynamic Notch" \
            "Minimal Rail: Compact Sleek Track")
        case "$choice" in
            *"Orbital"*) prompted_island_style="orbital" ;;
            *"Minimal Rail"*) prompted_island_style="minimal_rail" ;;
            *) prompted_island_style="prism_blade" ;;
        esac
    elif [[ -t 0 ]]; then
        msg ask "Select your preferred Dynamic Island style:"
        PS3="$(echo -e '\e[1;32mEnter Dynamic Island style number: \e[0m')"
        select _ in "Prism Blade (Default)" "Orbital" "Minimal Rail"; do
            case $REPLY in
                2) prompted_island_style="orbital"; break ;;
                3) prompted_island_style="minimal_rail"; break ;;
                *) prompted_island_style="prism_blade"; break ;;
            esac
        done
    fi
}

prompt_launcher_style() {
    [[ "$had_existing_launcher_json" == "true" ]] && return 0
    if command -v gum &> /dev/null; then
        local choice
        choice=$(gum choose --selected="Style 2: Panoramic Grid (Default)" \
            --header="Select your preferred App Launcher style:" \
            "Style 2: Panoramic Grid (Default)" \
            "Style 1: Slanted Split Quad")
        if [[ "$choice" =~ "Style 1" ]]; then
            prompted_launcher_style="style-1"
        else
            prompted_launcher_style="style-2"
        fi
    elif [[ -t 0 ]]; then
        msg ask "Select your preferred App Launcher style:"
        PS3="$(echo -e '\e[1;32mEnter selection number (default Style 2): \e[0m')"
        select _ in "Style 2: Panoramic Grid" "Style 1: Slanted Split Quad"; do
            case $REPLY in
                2) prompted_launcher_style="style-1"; break ;;
                *) prompted_launcher_style="style-2"; break ;;
            esac
        done
    fi
}

# Detect root-requiring tasks before starting progress output
env_updates=""
if [[ -d "/usr/share/openbangla-keyboard" ]]; then
    grep -q "GTK_IM_MODULE=fcitx" /etc/environment 2>/dev/null || env_updates+="GTK_IM_MODULE=fcitx\n"
    grep -q "QT_IM_MODULE=fcitx" /etc/environment 2>/dev/null || env_updates+="QT_IM_MODULE=fcitx\n"
    grep -q "XMODIFIERS=@im=fcitx" /etc/environment 2>/dev/null || env_updates+="XMODIFIERS=@im=fcitx\n"
fi

extras_src=""
[[ -d "$dir/extras" ]] && extras_src="$dir/extras"
[[ -z "$extras_src" && -d "$HOME/.hyprconf/extras" ]] && extras_src="$HOME/.hyprconf/extras"

wayland_session_dir="/usr/share/wayland-sessions"
needs_wayland_session_update() {
    [[ -n "$extras_src" && -f "$extras_src/hyprland.desktop" ]] || return 1
    [[ ! -d "$wayland_session_dir" || ! -f "$wayland_session_dir/hyprland.desktop" ]] && return 0
    ! cmp -s "$extras_src/hyprland.desktop" "$wayland_session_dir/hyprland.desktop" 2>/dev/null
}

ensure_sudo_session() {
    [[ -t 0 && -z "${HYPRCONF_TUI:-}" ]] || return 1
    command -v sudo &> /dev/null || return 1
    if sudo -n true 2>/dev/null; then
        return 0
    fi
    printf "${cyan}:: Administrator access is needed for system configuration:${end}\n"
    if sudo -v; then
        if [[ -z "$sudo_keepalive_pid" ]]; then
            (
                while kill -0 "$$" 2>/dev/null; do
                    sudo -n true 2>/dev/null || exit 0
                    sleep 45
                done
            ) &
            sudo_keepalive_pid=$!
        fi
        return 0
    fi
    return 1
}

needs_sudo=false
[[ -n "$env_updates" ]] && needs_sudo=true
needs_wayland_session_update && needs_sudo=true

if is_interactive_tty; then
    clear && display_text
    printf "\n"
fi

prompt_backup_wallpapers
prompt_weather_location
prompt_island_style
prompt_launcher_style

if [[ "$needs_sudo" == "true" ]]; then
    ensure_sudo_session || log_msg "Sudo authentication unavailable or skipped upfront."
fi

# Clear prompt clutter before running clean numbered progress lines
if is_interactive_tty; then
    clear && display_text
    printf "\n"
fi

log_msg "Setting up the pre-installed Hyprland configuration..."

###------ Execution Steps ------###

mkdir -p "$backup_dir" "$user_state_dir"

# 1. Backup wallpapers (if requested)
if [[ "$backup_wallpapers_action" == "y" && -d "$wallpapers" ]]; then
    step_start "Backing up existing wallpapers"
    mkdir -p "$wallpapers_backup"
    cp -a "$wallpapers/." "$wallpapers_backup/" 2>> "$log" || true
    step_done
fi

[[ -e "$hypr_cache" ]] && cp -r "$hypr_cache" "$backup_dir/" 2>> "$log" || true

# Helper to find existing palette files
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

colors_backup="$backup_dir/existing_colors"
mkdir -p "$colors_backup"

existing_colors_json=$(find_first_existing_file "$user_state_dir/colors.json" "$HOME/.hyprconf/quickshell/colors.json" "$HOME/.config/quickshell/colors.json" || true)
existing_theme_lua=$(find_first_existing_file "$HOME/.hyprconf/hypr/theme.lua" "$HOME/.config/hypr/theme.lua" || true)
existing_colors_sh=$(find_first_existing_file "$HOME/.hyprconf/hypr/scripts/sh/colors.sh" "$HOME/.config/hypr/scripts/sh/colors.sh" || true)
existing_kitty_colors=$(find_first_existing_file "$HOME/.config/kitty/colors-kitty.conf" "$HOME/.hyprconf/kitty/colors-kitty.conf" || true)
existing_qt6ct_colors=$(find_first_existing_file "$HOME/.config/qt6ct/colors/theme.conf" || true)
existing_btop_theme=$(find_first_existing_file "$HOME/.config/btop/themes/noctalia.theme" || true)

# Detect existing fastfetch configuration
existing_fastfetch_config=""
ff_cache_file="$user_state_dir/.cache/ffconfig.fish"
ff_raw_file="$user_state_dir/.cache/ffconfig"
if [[ -f "$ff_cache_file" ]]; then
    detected_cfg=$(grep -E '^\s*set\s+(-[a-zA-Z]+\s+)*ffconfig\s+' "$ff_cache_file" 2>/dev/null | sed -E 's/.*ffconfig\s+([^#[:space:]]+).*/\1/' | head -n 1)
    detected_cfg="${detected_cfg%\"}"
    detected_cfg="${detected_cfg#\"}"
    detected_cfg="${detected_cfg%\'}"
    detected_cfg="${detected_cfg#\'}"
    [[ -n "$detected_cfg" ]] && existing_fastfetch_config="$detected_cfg"
elif [[ -f "$ff_raw_file" ]]; then
    detected_cfg=$(cat "$ff_raw_file" 2>/dev/null | tr -d '[:space:]')
    [[ -n "$detected_cfg" ]] && existing_fastfetch_config="$detected_cfg"
fi

if [[ -z "$existing_fastfetch_config" ]]; then
    for fish_cfg in "$HOME/.hyprconf/fish/config.fish" "$HOME/.config/fish/config.fish"; do
        if [[ -f "$fish_cfg" ]]; then
            detected_cfg=$(grep -E '^\s*set\s+(-[a-zA-Z]+\s+)*ffconfig\s+' "$fish_cfg" 2>/dev/null | sed -E 's/.*ffconfig\s+([^#[:space:]]+).*/\1/' | head -n 1)
            detected_cfg="${detected_cfg%\"}"
            detected_cfg="${detected_cfg#\"}"
            detected_cfg="${detected_cfg%\'}"
            detected_cfg="${detected_cfg#\'}"
            if [[ -n "$detected_cfg" && "$detected_cfg" != "minimal" && "$detected_cfg" != "\$ffconfig" ]]; then
                existing_fastfetch_config="$detected_cfg"
                break
            fi
        fi
    done
fi

if [[ -z "$existing_fastfetch_config" ]]; then
    for fvar in "$HOME/.hyprconf/fish/fish_variables" "$HOME/.config/fish/fish_variables"; do
        if [[ -f "$fvar" ]]; then
            detected_cfg=$(grep -E '^SETUVAR ffconfig:' "$fvar" 2>/dev/null | sed -E 's/^SETUVAR ffconfig://' | head -n 1)
            detected_cfg=$(printf '%b' "${detected_cfg//\\x/\\x}")
            if [[ -n "$detected_cfg" && "$detected_cfg" != "minimal" ]]; then
                existing_fastfetch_config="$detected_cfg"
                break
            fi
        fi
    done
fi

if [[ -z "$existing_fastfetch_config" && -L "$HOME/.config/fastfetch/config.jsonc" ]]; then
    ff_target=$(readlink -f "$HOME/.config/fastfetch/config.jsonc" 2>/dev/null || true)
    if [[ -n "$ff_target" && -f "$ff_target" ]]; then
        detected_cfg=$(basename "$ff_target" .jsonc)
        if [[ -n "$detected_cfg" && "$detected_cfg" != "minimal" ]]; then
            existing_fastfetch_config="$detected_cfg"
        fi
    fi
fi

# Determine whether any existing user configs/colors/dotfiles need backing up
has_config_backup_work=false
[[ -d "$HOME/.backup_hyprconf-${USER}" ]] && has_config_backup_work=true
[[ "$dir" != "$HOME/.hyprconf" && -d "$HOME/.hyprconf" ]] && has_config_backup_work=true
[[ -n "$existing_colors_json$existing_theme_lua$existing_colors_sh$existing_kitty_colors$existing_qt6ct_colors$existing_btop_theme" ]] && has_config_backup_work=true
[[ -f "$ff_cache_file" || -f "$ff_raw_file" ]] && has_config_backup_work=true
[[ -f "$HOME/.config/fastfetch/config.jsonc" && ! -L "$HOME/.config/fastfetch/config.jsonc" ]] && has_config_backup_work=true
for confs in "${dirs[@]}"; do
    if [[ -e "$HOME/.config/$confs" && ! -L "$HOME/.config/$confs" ]]; then
        has_config_backup_work=true
        break
    fi
done

if [[ "$has_config_backup_work" == "true" ]]; then
    step_start "Backing up existing configurations"

    [[ -n "$existing_colors_json" ]] && cp "$existing_colors_json" "$colors_backup/colors.json" 2>> "$log" && cp "$existing_colors_json" "$user_state_dir/colors.json" 2>> "$log"
    [[ -n "$existing_theme_lua" ]] && cp "$existing_theme_lua" "$colors_backup/theme.lua" 2>> "$log"
    [[ -n "$existing_colors_sh" ]] && cp "$existing_colors_sh" "$colors_backup/colors.sh" 2>> "$log"
    [[ -n "$existing_kitty_colors" ]] && cp "$existing_kitty_colors" "$colors_backup/colors-kitty.conf" 2>> "$log"
    [[ -n "$existing_qt6ct_colors" ]] && cp "$existing_qt6ct_colors" "$colors_backup/theme.conf" 2>> "$log"
    [[ -n "$existing_btop_theme" ]] && cp "$existing_btop_theme" "$colors_backup/noctalia.theme" 2>> "$log"

    [[ -f "$ff_cache_file" ]] && cp -f "$ff_cache_file" "$backup_dir/ffconfig.fish" 2>> "$log"
    [[ -f "$ff_raw_file" ]] && cp -f "$ff_raw_file" "$backup_dir/ffconfig" 2>> "$log"
    if [[ -f "$HOME/.config/fastfetch/config.jsonc" && ! -L "$HOME/.config/fastfetch/config.jsonc" ]]; then
        cp -f "$HOME/.config/fastfetch/config.jsonc" "$backup_dir/user_fastfetch_config.jsonc" 2>> "$log"
    fi

    if [[ -d "$HOME/.backup_hyprconf-${USER}" ]]; then
        mkdir -p "$HOME/.archive_hyprconf-${USER}"
        archive_file="$HOME/.archive_hyprconf-${USER}/backup_hyprconf-$(date +%d-%m-%Y_%I-%M-%p)-${USER}.tar.gz"
        tar -czf "$archive_file" -C "$HOME" ".backup_hyprconf-${USER}" &> /dev/null || true
        rm -rf "$HOME/.backup_hyprconf-${USER}"
        log_msg "Archived ~/.backup_hyprconf-${USER} into $archive_file"
    fi

    mkdir -p "$HOME/.backup_hyprconf-${USER}"
    if [[ "$dir" != "$HOME/.hyprconf" && -d "$HOME/.hyprconf" ]]; then
        mv "$HOME/.hyprconf" "$HOME/.backup_hyprconf-${USER}/" 2>> "$log" || true
        log_msg "Moved previous ~/.hyprconf to ~/.backup_hyprconf-${USER}/"
    else
        backed_count=0
        for confs in "${dirs[@]}"; do
            conf_path="$HOME/.config/$confs"
            if [[ -e "$conf_path" && ! -L "$conf_path" ]]; then
                mv "$conf_path" "$HOME/.backup_hyprconf-${USER}/" 2>> "$log" || true
                backed_count=$((backed_count + 1))
            fi
        done
        [[ $backed_count -gt 0 ]] && log_msg "Backed up $backed_count existing configuration directories to ~/.backup_hyprconf-${USER}/"
    fi

    step_done
else
    mkdir -p "$HOME/.backup_hyprconf-${USER}"
fi

# Migrate existing configurations to ~/.local/share/hyprconf if present
migrate_to_state() {
    local src="$1"
    local dest="$2"
    if [[ -e "$src" && ! -f "$dest" ]]; then
        if [[ -L "$src" ]]; then
            local target
            target=$(readlink -f "$src" 2>/dev/null || true)
            if [[ "$target" == "$dest" ]]; then
                return 0
            elif [[ -n "$target" && -f "$target" ]]; then
                cp -f "$target" "$dest"
                return 0
            fi
        fi
        if [[ -f "$src" ]]; then
            cp -f "$src" "$dest"
        fi
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

mkdir -p "$user_state_dir/.cache"

has_migration_work=false
for base_dir in "$HOME/.hyprconf" "$HOME/.config" "$HOME/.backup_hyprconf-${USER}" "$HOME/.backup_hyprconf-${USER}/.hyprconf"; do
    [[ -d "$base_dir" ]] || continue
    for check_pair in \
        "quickshell/lockscreen.json:lockscreen.json" \
        "quickshell/widgets/widgets.json:widgets.json" \
        "quickshell/island/config.json:island.json" \
        "quickshell/launcher/config.json:launcher.json" \
        "quickshell/dock/dock.json:dock.json" \
        "quickshell/bar/config.json:bar.json" \
        "hypr/configs/monitor.lua:monitor.lua" \
        "hypr/configs/keybinds.lua:keybinds.lua" \
        "hypr/.cache/wallpaper_config.json:wallpaper_config.json" \
        "quickshell/colors.json:colors.json"; do
        src_rel="${check_pair%%:*}"
        dst_name="${check_pair##*:}"
        if [[ -e "$base_dir/$src_rel" && ! -f "$user_state_dir/$dst_name" ]]; then
            has_migration_work=true
            break 2
        fi
    done
done
if [[ "$has_migration_work" != "true" ]]; then
    for cdir in "$HOME/.hyprconf/hypr/.cache" "$HOME/.config/hypr/.cache" "$backup_dir/.cache"; do
        [[ -d "$cdir" && ! -L "$cdir" ]] && has_migration_work=true && break
    done
fi

if [[ "$has_migration_work" == "true" ]]; then
    step_start "Migrating user settings & cache"

    for base_dir in "$HOME/.hyprconf" "$HOME/.config" "$HOME/.backup_hyprconf-${USER}" "$HOME/.backup_hyprconf-${USER}/.hyprconf"; do
        [[ -d "$base_dir" ]] || continue
        migrate_to_state "$base_dir/quickshell/lockscreen.json" "$user_state_dir/lockscreen.json"
        migrate_to_state "$base_dir/quickshell/widgets/widgets.json" "$user_state_dir/widgets.json"
        migrate_to_state "$base_dir/quickshell/island/config.json" "$user_state_dir/island.json"
        migrate_to_state "$base_dir/quickshell/launcher/config.json" "$user_state_dir/launcher.json"
        migrate_to_state "$base_dir/quickshell/dock/dock.json" "$user_state_dir/dock.json"
        migrate_to_state "$base_dir/quickshell/bar/config.json" "$user_state_dir/bar.json"
        migrate_to_state "$base_dir/hypr/configs/monitor.lua" "$user_state_dir/monitor.lua"
        migrate_to_state "$base_dir/hypr/configs/keybinds.lua" "$user_state_dir/keybinds.lua"
        migrate_to_state "$base_dir/hypr/.cache/wallpaper_config.json" "$user_state_dir/wallpaper_config.json"
        migrate_to_state "$base_dir/quickshell/colors.json" "$user_state_dir/colors.json"
    done

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
            log_msg "Migrated hypr .cache ($cdir) to $user_state_dir/.cache"
        fi
    done

    step_done
fi

if [[ -e "$user_state_dir/.cache/current_wallpaper.png" || -f "$user_state_dir/.cache/.wallpaper" ]]; then
    had_existing_wallpaper=true
    had_hypr_cache=true
fi

# OpenBangla Keyboard environment configuration
if [[ -n "$env_updates" ]]; then
    openbangla_ok=true
    if ! sudo -n true 2>/dev/null; then
        printf "\n"
        ensure_sudo_session || openbangla_ok=false
    fi
    step_start "Configuring OpenBangla-Keyboard environment"
    if [[ "$openbangla_ok" == "true" ]] && printf "%b" "$env_updates" | sudo -n tee -a /etc/environment > /dev/null 2>> "$log"; then
        step_done
    else
        msg err "Failed to update /etc/environment for OpenBangla-Keyboard"
    fi
fi

# Copy complete configuration tree if installing from external cloned repo
if [[ "$dir" != "$HOME/.hyprconf" ]]; then
    step_start "Installing configuration files"
    mkdir -p "$HOME/.hyprconf"
    install_ok=true
    if [[ -d "$dir/config" ]]; then
        cp -a "$dir/config/." "$HOME/.hyprconf/" 2>> "$log" || install_ok=false
    else
        if command -v rsync &> /dev/null; then
            rsync -a --exclude='.git' --exclude='Logs' "$dir/" "$HOME/.hyprconf/" 2>> "$log" || install_ok=false
        else
            cp -a "$dir/." "$HOME/.hyprconf/" 2>> "$log" || install_ok=false
            rm -rf "$HOME/.hyprconf/.git" "$HOME/.hyprconf/Logs" 2>/dev/null || true
        fi
    fi
    [[ -f "$dir/setup.sh" ]] && cp -f "$dir/setup.sh" "$HOME/.hyprconf/setup.sh" 2>/dev/null || true
    [[ -f "$dir/setup-new.sh" ]] && cp -f "$dir/setup-new.sh" "$HOME/.hyprconf/setup-new.sh" 2>/dev/null || true
    [[ -f "$dir/.version" ]] && cp -f "$dir/.version" "$HOME/.hyprconf/.version" 2>/dev/null || true
    if [[ -d "$dir/extras" ]]; then
        mkdir -p "$HOME/.hyprconf/extras"
        cp -a "$dir/extras/." "$HOME/.hyprconf/extras/" 2>/dev/null || true
    fi
    if [[ -d "$dir/local" ]]; then
        mkdir -p "$HOME/.hyprconf/local"
        cp -a "$dir/local/." "$HOME/.hyprconf/local/" 2>/dev/null || true
    fi
    if [[ "$install_ok" == "true" ]]; then
        step_done
    else
        msg err "Failed copying configuration files from $dir to $HOME/.hyprconf"
    fi
fi

# Restore user color palette and themes if user already had them
if [[ "$had_hypr_cache" == "true" || "$had_existing_wallpaper" == "true" ]]; then
    if [[ -f "$colors_backup/colors.json" || -f "$colors_backup/theme.lua" || -f "$colors_backup/colors.sh" || -f "$colors_backup/colors-kitty.conf" || -f "$colors_backup/theme.conf" || -f "$colors_backup/noctalia.theme" ]]; then
        step_start "Restoring preserved color palette"
        if [[ -f "$colors_backup/colors.json" ]]; then
            cp -f "$colors_backup/colors.json" "$HOME/.hyprconf/quickshell/colors.json"
            cp -f "$colors_backup/colors.json" "$user_state_dir/colors.json" 2>/dev/null || true
        fi
        [[ -f "$colors_backup/theme.lua" ]] && cp -f "$colors_backup/theme.lua" "$HOME/.hyprconf/hypr/theme.lua"
        [[ -f "$colors_backup/colors.sh" ]] && cp -f "$colors_backup/colors.sh" "$HOME/.hyprconf/hypr/scripts/sh/colors.sh"
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
        step_done
    fi
fi

# Quickshell modules, user state symlinks, and ~/.config linking
step_start "Synchronizing Quickshell modules & state symlinks"

island_dir="$HOME/.hyprconf/quickshell/island"
launcher_dir="$HOME/.hyprconf/quickshell/launcher"
launcher_theme_dir="$HOME/.hyprconf/quickshell/launcher-theme"
settings_dir="$HOME/.hyprconf/quickshell/settings"
widgets_dir="$HOME/.hyprconf/quickshell/widgets"
lockscreen_dir="$HOME/.hyprconf/quickshell/lockscreen"
dock_dir="$HOME/.hyprconf/quickshell/dock"
updater_dir="$HOME/.hyprconf/quickshell/updater"
welcome_dir="$HOME/.hyprconf/quickshell/welcome"
bar_dir="$HOME/.hyprconf/quickshell/bar"
sidebar_dir="$HOME/.hyprconf/quickshell/sidebar"

if [[ -d "$island_dir" && -d "$launcher_dir" ]]; then
    for style in Style1.qml Style2.qml; do
        target="$island_dir/$style"
        if [[ ! -e "$target" || ( -L "$target" && "$(readlink "$target")" =~ /home/ ) ]]; then
            ln -sfn "../launcher/$style" "$target"
        fi
    done
fi

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

for sub in "$island_dir" "$launcher_dir" "$launcher_theme_dir" "$settings_dir" "$widgets_dir" "$lockscreen_dir" "$dock_dir" "$bar_dir" "$sidebar_dir" "$updater_dir" "$welcome_dir"; do
    [[ -d "$sub" ]] || continue
    [[ ! -e "$sub/Theme.qml" || ( -L "$sub/Theme.qml" && "$(readlink "$sub/Theme.qml")" =~ /home/ ) ]] && ln -sfn "../Theme.qml" "$sub/Theme.qml"
    [[ ! -e "$sub/colors.json" || ( -L "$sub/colors.json" && "$(readlink "$sub/colors.json")" =~ /home/ ) ]] && ln -sfn "../colors.json" "$sub/colors.json"
done

if [[ -f "$settings_dir/qmldir" ]]; then
    grep -q "DockSection" "$settings_dir/qmldir" || echo "DockSection 1.0 DockSection.qml" >> "$settings_dir/qmldir"
    grep -q "KeybindsSection" "$settings_dir/qmldir" || echo "KeybindsSection 1.0 KeybindsSection.qml" >> "$settings_dir/qmldir"
    if ! grep -q "BarSection" "$settings_dir/qmldir" && [[ -f "$settings_dir/BarSection.qml" ]]; then
        echo "BarSection 1.0 BarSection.qml" >> "$settings_dir/qmldir"
    fi
fi
if [[ -f "$island_dir/qmldir" ]]; then
    grep -q "KeybindsView" "$island_dir/qmldir" || echo "KeybindsView 1.0 KeybindsView.qml" >> "$island_dir/qmldir"
    grep -q "WifiNetworkDialog" "$island_dir/qmldir" || echo "WifiNetworkDialog 1.0 WifiNetworkDialog.qml" >> "$island_dir/qmldir"
    grep -q "IslandBatteryIndicator" "$island_dir/qmldir" || echo "IslandBatteryIndicator 1.0 IslandBatteryIndicator.qml" >> "$island_dir/qmldir"
    grep -q "IslandMediaIndicators" "$island_dir/qmldir" || echo "IslandMediaIndicators 1.0 IslandMediaIndicators.qml" >> "$island_dir/qmldir"
fi

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

mkdir -p "$widgets_dir" "$island_dir" "$launcher_dir" "$lockscreen_dir" "$dock_dir" "$updater_dir" "$welcome_dir" "$bar_dir" "$HOME/.hyprconf/hypr/configs"
ln -sfn "$user_state_dir/lockscreen.json" "$HOME/.hyprconf/quickshell/lockscreen.json"
ln -sfn "$user_state_dir/widgets.json" "$widgets_dir/widgets.json"
ln -sfn "$user_state_dir/island.json" "$island_dir/config.json"
ln -sfn "$user_state_dir/launcher.json" "$launcher_dir/config.json"
ln -sfn "$user_state_dir/dock.json" "$dock_dir/dock.json"
ln -sfn "$user_state_dir/bar.json" "$bar_dir/config.json"
ln -sfn "$user_state_dir/monitor.lua" "$HOME/.hyprconf/hypr/configs/monitor.lua"

if [[ ! -f "$user_state_dir/keybinds.lua" ]]; then
    if [[ -f "$HOME/.hyprconf/hypr/configs/keybinds.lua" && ! -L "$HOME/.hyprconf/hypr/configs/keybinds.lua" ]]; then
        cp -f "$HOME/.hyprconf/hypr/configs/keybinds.lua" "$user_state_dir/keybinds.lua"
    elif [[ -f "$HOME/.config/hypr/configs/keybinds.lua" && ! -L "$HOME/.config/hypr/configs/keybinds.lua" ]]; then
        cp -f "$HOME/.config/hypr/configs/keybinds.lua" "$user_state_dir/keybinds.lua"
    elif [[ -f "$HOME/.backup_hyprconf-${USER}/hypr/configs/keybinds.lua" && ! -L "$HOME/.backup_hyprconf-${USER}/hypr/configs/keybinds.lua" ]]; then
        cp -f "$HOME/.backup_hyprconf-${USER}/hypr/configs/keybinds.lua" "$user_state_dir/keybinds.lua"
    elif [[ -f "$HOME/.backup_hyprconf-${USER}/.hyprconf/hypr/configs/keybinds.lua" && ! -L "$HOME/.backup_hyprconf-${USER}/.hyprconf/hypr/configs/keybinds.lua" ]]; then
        cp -f "$HOME/.backup_hyprconf-${USER}/.hyprconf/hypr/configs/keybinds.lua" "$user_state_dir/keybinds.lua"
    elif [[ -n "$local_hyprconf" && -f "$local_hyprconf/keybinds.lua" ]]; then
        cp -f "$local_hyprconf/keybinds.lua" "$user_state_dir/keybinds.lua"
    elif [[ -f "$dir/local/share/hyprconf/keybinds.lua" ]]; then
        cp -f "$dir/local/share/hyprconf/keybinds.lua" "$user_state_dir/keybinds.lua"
    fi
fi
ln -sfn "$user_state_dir/keybinds.lua" "$HOME/.hyprconf/hypr/configs/keybinds.lua"
ln -sfn "$user_state_dir/welcome-app.json" "$HOME/.hyprconf/hypr/welcome-app.json"

mkdir -p "$user_state_dir/.cache"
rm -rf "$HOME/.hyprconf/hypr/.cache" 2>/dev/null || true
ln -sfn "$user_state_dir/.cache" "$HOME/.hyprconf/hypr/.cache"

if [[ -d "$HOME/.hyprconf/fastfetch" ]]; then
    if [[ ! -d "$HOME/.local/share/fastfetch" ]]; then
        mkdir -p "$HOME/.local/share/fastfetch"
        cp -a "$HOME/.hyprconf/fastfetch/." "$HOME/.local/share/fastfetch/" 2>/dev/null || true
    fi
    rm -rf "$HOME/.hyprconf/fastfetch"
fi

for dotfile in "$HOME/.hyprconf"/*; do
    [[ -e "$dotfile" ]] || continue
    configName=$(basename "$dotfile")
    case "$configName" in
        setup.sh|setup-new.sh|setup-preview.sh|update.sh|README*|LICENSE*|PACKAGES*|UPDATES*|Logs|*.md|extras|local|fastfetch) continue ;;
    esac
    configPath="$HOME/.config/$configName"
    if [[ -d "$configPath" && ! -L "$configPath" ]]; then
        rm -rf "$configPath"
    fi
    ln -sfn "$dotfile" "$configPath"
done

step_done

# Environment file paths
env_file="$HOME/.hyprconf/hypr/configs/environment.lua"
monitor_file="$HOME/.hyprconf/hypr/configs/monitor.lua"

# Virtual Machine adjustments
if command -v systemd-detect-virt &> /dev/null && systemd-detect-virt --quiet; then
    step_start "Applying Virtual Machine configuration"
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
    step_done
fi

# NVIDIA GPU adjustments
if command -v lspci &> /dev/null && lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
    step_start "Configuring NVIDIA GPU environment"
    [[ -f "$env_file" ]] && sed -i '/^-- hl\.env("LIBVA_DRIVER_NAME"/s/^-- //' "$env_file"
    [[ -f "$env_file" ]] && sed -i '/^-- hl\.env("__GLX_VENDOR_LIBRARY_NAME"/s/^-- //' "$env_file"
    [[ -f "$env_file" ]] && sed -i '/^-- hl\.env("GBM_BACKEND"/s/^-- //' "$env_file"
    step_done
fi

# Set permissions for scripts and fish functions
if [[ -d "$scripts_dir" ]]; then
    step_start "Setting executable permissions on scripts"
    chmod +x "$scripts_dir"/* "$scripts_dir/sh"/* "$scripts_dir/py"/* 2>/dev/null || true
    [[ -d "$HOME/.hyprconf/fish/functions" ]] && chmod +x "$HOME/.hyprconf/fish/functions"/* 2>/dev/null || true
    step_done
else
    msg err "Scripts directory not found in $scripts_dir"
fi

# Install Fonts
mkdir -p "$fonts_dir"
font_source=""
[[ -d "$dir/extras/fonts" ]] && font_source="$dir/extras/fonts"
[[ -z "$font_source" && -d "$HOME/.hyprconf/extras/fonts" ]] && font_source="$HOME/.hyprconf/extras/fonts"

if [[ -n "$font_source" && ! -f "$fonts_dir/Icomoon-Feather.ttf" ]]; then
    step_start "Installing fonts & refreshing font cache"
    cp -a "$font_source/." "$fonts_dir/" 2>> "$log" || true
    fc-cache -f "$fonts_dir" >> "$log" 2>&1 || true
    step_done
elif [[ -f "$fonts_dir/Icomoon-Feather.ttf" ]]; then
    log_msg "Fonts already installed; skipping."
fi

# Extra files setup (dolphinstaterc, konsole, fastfetch)
local_src=""
[[ -d "$dir/local" ]] && local_src="$dir/local"
[[ -z "$local_src" && -d "$HOME/.hyprconf/local" ]] && local_src="$HOME/.hyprconf/local"

step_start "Configuring Fastfetch & terminal presets"

if [[ -f "$HOME/.local/state/dolphinstaterc" ]]; then
    rm -f "$HOME/.local/state/dolphinstaterc.back" 2>/dev/null || true
    mv -f "$HOME/.local/state/dolphinstaterc" "$HOME/.local/state/dolphinstaterc.back"
fi

if [[ -d "$HOME/.local/share/konsole" ]]; then
    rm -rf "$HOME/.local/share/konsole.back" 2>/dev/null || true
    mv -f "$HOME/.local/share/konsole" "$HOME/.local/share/konsole.back"
fi

mkdir -p "$HOME/.local/state" "$HOME/.local/share"

if [[ -n "$local_src" ]]; then
    [[ -f "$local_src/state/dolphinstaterc" ]] && cp -f "$local_src/state/dolphinstaterc" "$HOME/.local/state/"
    if [[ -d "$local_src/share/konsole" ]]; then
        mkdir -p "$HOME/.local/share/konsole"
        cp -a "$local_src/share/konsole/." "$HOME/.local/share/konsole/"
    fi
    if [[ ! -d "$HOME/.local/share/fastfetch" && -d "$local_src/share/fastfetch" ]]; then
        mkdir -p "$HOME/.local/share/fastfetch"
        cp -a "$local_src/share/fastfetch/." "$HOME/.local/share/fastfetch/"
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
        if [[ -d "$local_src/share/hyprconf/browser-ntp" ]]; then
            while IFS= read -r -d '' src_file; do
                rel_path="${src_file#"$local_src/share/hyprconf/"}"
                dest_file="$HOME/.local/share/hyprconf/$rel_path"
                mkdir -p "$(dirname "$dest_file")"
                [[ -L "$dest_file" && ! -e "$dest_file" ]] && rm -f "$dest_file"
                if [[ ! -e "$dest_file" && ! -L "$dest_file" ]]; then
                    cp -a "$src_file" "$dest_file"
                fi
            done < <(find "$local_src/share/hyprconf/browser-ntp" -type f -print0)
        fi
    fi
fi

if [[ -d "$HOME/.local/share/fastfetch/presets" ]]; then
    [[ -L "$HOME/.config/fastfetch" ]] && rm -f "$HOME/.config/fastfetch"
    mkdir -p "$HOME/.config/fastfetch"
    [[ -L "$HOME/.config/fastfetch/config.jsonc" && ! -e "$HOME/.config/fastfetch/config.jsonc" ]] && rm -f "$HOME/.config/fastfetch/config.jsonc"

    mkdir -p "$user_state_dir/.cache"
    [[ -f "$backup_dir/ffconfig.fish" && ! -f "$user_state_dir/.cache/ffconfig.fish" ]] && cp -f "$backup_dir/ffconfig.fish" "$user_state_dir/.cache/ffconfig.fish"
    [[ -f "$backup_dir/ffconfig" && ! -f "$user_state_dir/.cache/ffconfig" ]] && cp -f "$backup_dir/ffconfig" "$user_state_dir/.cache/ffconfig"

    if [[ -f "$backup_dir/user_fastfetch_config.jsonc" ]]; then
        cp -f "$backup_dir/user_fastfetch_config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
    elif [[ -n "$existing_fastfetch_config" && -f "$HOME/.local/share/fastfetch/presets/${existing_fastfetch_config}.jsonc" ]]; then
        ln -sf "$HOME/.local/share/fastfetch/presets/${existing_fastfetch_config}.jsonc" "$HOME/.config/fastfetch/config.jsonc"
        echo "set -g ffconfig $existing_fastfetch_config" > "$user_state_dir/.cache/ffconfig.fish"
        echo "$existing_fastfetch_config" > "$user_state_dir/.cache/ffconfig"

        if [[ -f "$HOME/.hyprconf/fish/fish_variables" ]]; then
            encoded_ff=$(printf '%s' "$existing_fastfetch_config" | sed 's/-/\\x2d/g')
            if grep -q '^SETUVAR ffconfig:' "$HOME/.hyprconf/fish/fish_variables"; then
                sed -i "s|^SETUVAR ffconfig:.*|SETUVAR ffconfig:$encoded_ff|" "$HOME/.hyprconf/fish/fish_variables"
            else
                echo "SETUVAR ffconfig:$encoded_ff" >> "$HOME/.hyprconf/fish/fish_variables"
            fi
        fi
        if command -v fish &>/dev/null; then
            fish -c "set -U ffconfig $existing_fastfetch_config" &>/dev/null || true
        fi
    elif [[ ! -e "$HOME/.config/fastfetch/config.jsonc" && -f "$HOME/.local/share/fastfetch/presets/minimal.jsonc" ]]; then
        ln -sf "$HOME/.local/share/fastfetch/presets/minimal.jsonc" "$HOME/.config/fastfetch/config.jsonc"
        echo "set -g ffconfig minimal" > "$user_state_dir/.cache/ffconfig.fish"
        echo "minimal" > "$user_state_dir/.cache/ffconfig"
    fi
fi

step_done

# Wayland session & desktop application entries
if [[ -n "$extras_src" ]]; then
    wayland_sudo_ok=false
    if needs_wayland_session_update; then
        if sudo -n true 2>/dev/null; then
            wayland_sudo_ok=true
        elif [[ -t 0 && -z "${HYPRCONF_TUI:-}" ]]; then
            # Run interactive sudo prompt cleanly on its own lines before printing [ N ] progress
            printf "\n${cyan}:: Root password required to install Wayland session entry:${end}\n"
            if sudo sh -c 'mkdir -p "$1" && cp -f "$2" "$1/"' _ "$wayland_session_dir" "$extras_src/hyprland.desktop"; then
                wayland_sudo_ok=done
            fi
        fi
    fi

    step_start "Installing Wayland session & desktop entries"
    if [[ "$wayland_sudo_ok" == "true" ]]; then
        [[ -d "$wayland_session_dir" ]] || sudo -n mkdir -p "$wayland_session_dir" >> "$log" 2>&1 || true
        sudo -n cp -f "$extras_src/hyprland.desktop" "$wayland_session_dir/" >> "$log" 2>&1 || true
    fi

    mkdir -p "$applications_dir"
    desktop_files=("Hyprconf.desktop" "sysupdate.desktop")
    for file in "${desktop_files[@]}"; do
        if [[ -f "$extras_src/$file" ]]; then
            cp -f "$extras_src/$file" "$applications_dir/"
            sed -i "s|/home/[^/]*|$HOME|g" "$applications_dir/$file"
        fi
    done
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "$applications_dir" >> "$log" 2>&1 || true
    fi
    step_done
fi

# Restore custom wallpapers & cache from backup (non-clobbering)
if [[ -d "$wallpapers_backup" || -e "$hypr_cache_backup" ]]; then
    step_start "Restoring custom wallpapers & cache backup"
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
                restored_wallpapers=$((restored_wallpapers + 1))
            else
                skipped_wallpapers=$((skipped_wallpapers + 1))
            fi
        done
        log_msg "Wallpapers restored: $restored_wallpapers, already present: $skipped_wallpapers"
    fi

    if [[ -e "$hypr_cache_backup" ]]; then
        cp -rn "$hypr_cache_backup/." "$user_state_dir/.cache/" 2>/dev/null || true
        ln -sfn "$user_state_dir/.cache" "$HOME/.hyprconf/hypr/.cache"
    fi
    step_done
fi
rm -rf "$backup_dir"

# ─── Apply User Selections & Defaults ────────────────────────────────────

apply_default_wallpaper() {
    local wall_dir="$HOME/.hyprconf/hypr/Wallpaper"
    mkdir -p "$wall_dir" "$user_state_dir/.cache"
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
        log_msg "Wallpaper set to: $selected_wall"
    fi
}

apply_island_style() {
    local island_cfg="$HOME/.hyprconf/quickshell/island/config.json"
    local chosen_style="${prompted_island_style:-capsule}"
    mkdir -p "$(dirname "$island_cfg")"
    if [[ -f "$island_cfg" ]]; then
        python3 - "$island_cfg" "$chosen_style" >> "$log" 2>&1 << 'PY' || true
import json, sys
p, style = sys.argv[1], sys.argv[2]
try:
    with open(p, 'r') as f:
        data = json.load(f)
    data['style'] = style
    with open(p, 'w') as f:
        json.dump(data, f, indent=2)
except Exception:
    pass
PY
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

apply_launcher_style() {
    local config_file="$HOME/.hyprconf/quickshell/launcher/config.json"
    local selected_launcher="${prompted_launcher_style:-style-2}"
    mkdir -p "$(dirname "$config_file")"
    printf '{\n  "theme": "%s"\n}\n' "$selected_launcher" > "$config_file"
}

apply_weather_location() {
    local lock_json="$HOME/.hyprconf/quickshell/lockscreen.json"
    if [[ -f "$lock_json" ]]; then
        python3 - "$lock_json" "$prompted_weather_city" "$prompted_weather_country" >> "$log" 2>&1 << 'PY' || true
import json, sys
p, city, country = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    with open(p, 'r') as f:
        data = json.load(f)
    data.setdefault('modules', {})
    data['modules']['weather_city'] = city
    data['modules']['weather_country'] = country
    with open(p, 'w') as f:
        json.dump(data, f, indent=4)
except Exception:
    pass
PY
    fi
    local weather_bin="$HOME/.hyprconf/hypr/scripts/py/weather.py"
    if [[ -x "$weather_bin" ]]; then
        "$weather_bin" --force >> "$log" 2>&1 || true
    fi
}

configure_desktop_widgets() {
    local widgets_file="$HOME/.hyprconf/quickshell/widgets/widgets.json"
    if [[ -f "$widgets_file" ]]; then
        python3 - "$widgets_file" >> "$log" 2>&1 << 'PY' || true
import json, sys
p = sys.argv[1]
try:
    with open(p, 'r') as f:
        data = json.load(f)
    data['enabled'] = False
    with open(p, 'w') as f:
        json.dump(data, f, indent=2)
except Exception:
    pass
PY
    fi
}

setup_user_avatar() {
    local cache_dir="$user_state_dir/.cache"
    mkdir -p "$cache_dir"
    local face_target="$cache_dir/.face"
    if [[ ! -f "$face_target" ]]; then
        if [[ -f "$HOME/.face" && ! -L "$HOME/.face" ]]; then
            cp "$HOME/.face" "$face_target"
        elif [[ -f "$wallpaper" ]]; then
            python3 - "$wallpaper" "$face_target" >> "$log" 2>&1 << 'PY' || true
import sys
from PIL import Image
src, dst = sys.argv[1], sys.argv[2]
try:
    im = Image.open(src).convert('RGBA')
    w, h = im.size
    min_d = min(w, h)
    im = im.crop(((w - min_d) // 2, (h - min_d) // 2, (w + min_d) // 2, (h + min_d) // 2)).resize((512, 512), Image.Resampling.LANCZOS)
    im.save(dst, 'PNG')
except Exception:
    pass
PY
        fi
    fi
    if [[ -f "$face_target" ]]; then
        ln -sfn "$face_target" "$HOME/.face"
    fi
}

generate_color_scheme() {
    local colors_bin="$HOME/.hyprconf/hypr/scripts/py/hypr-colors.py"
    if [[ -x "$colors_bin" && -f "$wallpaper" ]]; then
        "$colors_bin" "$wallpaper" >> "$log" 2>&1 || true
    fi
}

# Resolve wallpaper path (preserve existing or apply default)
wallpaper=""
if [[ "$had_hypr_cache" == "true" || "$had_existing_wallpaper" == "true" ]]; then
    if [[ -e "$user_state_dir/.cache/current_wallpaper.png" ]]; then
        wallpaper="$(readlink -f "$user_state_dir/.cache/current_wallpaper.png" 2>/dev/null || echo "$user_state_dir/.cache/current_wallpaper.png")"
    fi
    if [[ ( -z "$wallpaper" || ! -f "$wallpaper" ) && -f "$user_state_dir/.cache/.wallpaper" ]]; then
        saved_name=$(cat "$user_state_dir/.cache/.wallpaper" 2>/dev/null | tr -d '[:space:]')
        if [[ -n "$saved_name" ]]; then
            found_wall=$(find "$HOME/.hyprconf/hypr/Wallpaper" -maxdepth 1 -name "${saved_name}*" 2>/dev/null | head -n 1)
            if [[ -n "$found_wall" && -f "$found_wall" ]]; then
                wallpaper="$found_wall"
                ln -sfn "$wallpaper" "$user_state_dir/.cache/current_wallpaper.png"
            fi
        fi
    fi
    [[ -f "$wallpaper" ]] && log_msg "Preserved existing user wallpaper: $(basename "$wallpaper")"
fi

if [[ -z "$wallpaper" || ! -f "$wallpaper" ]]; then
    step_start "Setting default desktop wallpaper"
    apply_default_wallpaper
    step_done
fi

if [[ "$had_existing_lockscreen_json" != "true" && ( -n "$prompted_weather_city" || -n "$prompted_weather_country" ) ]]; then
    step_start "Configuring weather location"
    apply_weather_location
    step_done
fi

if [[ "$had_existing_island_json" != "true" ]]; then
    step_start "Applying Dynamic Island style ($prompted_island_style)"
    apply_island_style
    step_done
fi

if [[ "$had_existing_launcher_json" != "true" ]]; then
    step_start "Applying App Launcher style ($prompted_launcher_style)"
    apply_launcher_style
    step_done
fi

step_start "Setting up widgets, avatar & cleanup"
configure_desktop_widgets
setup_user_avatar

rm -f "$HOME/.hyprconf/hypr/noctalia.lua" "$HOME/.config/hypr/noctalia.lua" 2>/dev/null || true
for d in "$HOME/.hyprconf/gtk-3.0" "$HOME/.hyprconf/gtk-4.0" "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"; do
    if [[ -d "$d" ]]; then
        rm -f "$d/noctalia.css" "$d/colors.css" 2>/dev/null || true
    fi
done
step_done

if [[ "$had_hypr_cache" != "true" && "$had_existing_wallpaper" != "true" ]]; then
    step_start "Generating dynamic color palette"
    generate_color_scheme
    step_done
fi

# Final system & theme defaults
step_start "Applying GTK, Qt, Kvantum & session defaults"

if command -v systemctl &> /dev/null && systemctl --user is-system-running &> /dev/null; then
    systemctl --user daemon-reload >> "$log" 2>&1 || true
    systemctl --user enable --now pkgupdate-notifier.service >> "$log" 2>&1 || true
fi

if command -v gsettings &> /dev/null; then
    gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3" >> "$log" 2>&1 || true
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" >> "$log" 2>&1 || true
    gsettings set org.gnome.desktop.interface icon-theme "kora" >> "$log" 2>&1 || true
    gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Ice" >> "$log" 2>&1 || true
fi

icons_dir="$HOME/.icons"
mkdir -p "$HOME/.local/share/icons"
[[ -d "$icons_dir/kora" ]] && ln -snf "$icons_dir/kora" "$HOME/.local/share/icons/kora"
for kora_dir in "$icons_dir"/kora*; do
    [[ -d "$kora_dir" ]] && ln -snf "$kora_dir" "$HOME/.local/share/icons/$(basename "$kora_dir")"
done

KWRITECONFIG=""
if command -v kwriteconfig6 &> /dev/null; then
    KWRITECONFIG="kwriteconfig6"
elif command -v kwriteconfig5 &> /dev/null; then
    KWRITECONFIG="kwriteconfig5"
elif command -v kwriteconfig &> /dev/null; then
    KWRITECONFIG="kwriteconfig"
fi

if [[ -n "$KWRITECONFIG" ]]; then
    "$KWRITECONFIG" --file kdeglobals --group Icons --key Theme "kora" >> "$log" 2>&1 || true
elif command -v crudini &> /dev/null; then
    crudini --ini-options=nospace --set "$HOME/.config/kdeglobals" Icons Theme "kora" >> "$log" 2>&1 || true
fi

mkdir -p "$HOME/.config/qt5ct" "$HOME/.config/qt6ct"
for qtconf in "$HOME/.config/qt5ct/qt5ct.conf" "$HOME/.config/qt6ct/qt6ct.conf"; do
    if command -v crudini &> /dev/null; then
        crudini --ini-options=nospace --set "$qtconf" Appearance icon_theme "kora" >> "$log" 2>&1 || true
    elif [[ -n "$KWRITECONFIG" ]]; then
        "$KWRITECONFIG" --file "$qtconf" --group Appearance --key icon_theme "kora" >> "$log" 2>&1 || true
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

mkdir -p "$HOME/.config/Kvantum"
if command -v crudini &> /dev/null; then
    crudini --set ~/.config/Kvantum/kvantum.kvconfig General theme "Dracula" >> "$log" 2>&1 || true
elif [[ -n "$KWRITECONFIG" ]]; then
    "$KWRITECONFIG" --file ~/.config/Kvantum/kvantum.kvconfig --group General --key theme "Dracula" >> "$log" 2>&1 || true
fi

kdeglobals="$HOME/.config/kdeglobals"
mkdir -p "$HOME/.config"
if command -v kwriteconfig6 &> /dev/null; then
    kwriteconfig6 --file kdeglobals --group General --key TerminalApplication "kitty" >> "$log" 2>&1 || true
elif command -v kwriteconfig5 &> /dev/null; then
    kwriteconfig5 --file kdeglobals --group General --key TerminalApplication "kitty" >> "$log" 2>&1 || true
elif command -v crudini &> /dev/null; then
    crudini --set "$kdeglobals" General TerminalApplication "kitty" >> "$log" 2>&1 || true
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

exec_lua="$HOME/.hyprconf/hypr/configs/exec.lua"
if [[ -f "$exec_lua" ]]; then
    grep -q "qs-island.sh --start" "$exec_lua" || sed -i '/hl.on("hyprland.start", function()/a \    hl.exec_cmd(sh_dir .. "/qs-island.sh --start &")' "$exec_lua"
    grep -q "qs-widgets.sh --start" "$exec_lua" || sed -i '/hl.on("hyprland.start", function()/a \    hl.exec_cmd(sh_dir .. "/qs-widgets.sh --start &")' "$exec_lua"
    grep -q "hyprconf.sh --daemon" "$exec_lua" || sed -i '/hl.on("hyprland.start", function()/a \    hl.exec_cmd(sh_dir .. "/hyprconf.sh --daemon &")' "$exec_lua"
fi

chmod +x "$HOME/.hyprconf/hypr/scripts"/* "$HOME/.hyprconf/hypr/scripts/sh"/* "$HOME/.hyprconf/hypr/scripts/py"/* "$dir/setup.sh" "$dir/setup-new.sh" 2>/dev/null || true

step_done

log_msg "Script execution completed successfully."
printf "\n${green}Setup completed! Please log out and log back in to enjoy your setup.${end}\n"

# === ___ Script Ends Here ___ === #
