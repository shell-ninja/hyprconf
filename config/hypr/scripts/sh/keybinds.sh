#!/usr/bin/env bash
# ==============================================================================
# keybinds.sh — Hyprland & Quickshell Keybinds Viewer and Dispatcher
# Synchronized with hypr/configs/keybinds.lua
# Usage:
#   keybinds.sh              → View keybindings
#   keybinds.sh --list       → Output keybinds list for dmenu (Key  󰶻  Action)
#   keybinds.sh <selection>  → Execute the selected action directly
# ==============================================================================

set -euo pipefail

scripts_dir="$HOME/.hyprconf/hypr/scripts"
sh_dir="$scripts_dir/sh"
py_dir="$scripts_dir/py"

get_keybinds() {
    cat << 'EOF'
SUPER + Return  󰶻  Open Terminal (Kitty)
SUPER + SHIFT + Return  󰶻  Open Floating Terminal (Kitty)
SUPER + Q  󰶻  Close Active Window
SUPER + E  󰶻  Open File Manager (Dolphin / Thunar)
SUPER + SHIFT + E  󰶻  Open Terminal File Manager (Yazi)
SUPER + V  󰶻  Toggle Floating Window
SUPER + ALT + V  󰶻  Toggle All Windows to Float
SUPER + F  󰶻  Toggle Fullscreen
SUPER + Space  󰶻  Open App Launcher (Quickshell)
SUPER + D  󰶻  Open App Launcher (Quickshell)
SUPER + ALT + D  󰶻  Open Launcher Theme Switcher
SUPER + P  󰶻  Toggle Pseudo-Tiling
SUPER + SHIFT + P  󰶻  Toggle Pseudo-Tiling
SUPER + X  󰶻  Open Power Menu (Dynamic Island)
SUPER + SHIFT + L  󰶻  Lock Screen
SUPER + C  󰶻  Open IDE (VS Code / Codium / Antigravity)
SUPER + B  󰶻  Open Default Browser
SUPER + SHIFT + B  󰶻  Open Brave (Incognito)
ALT + B  󰶻  Reset Default Browser
SUPER + W  󰶻  Change Wallpaper (Random)
SUPER + SHIFT + W  󰶻  Open Dynamic Island Wallpaper Picker
SUPER + CTRL + SHIFT + W  󰶻  Open Dynamic Island Wallpaper Picker
SUPER + ALT + W  󰶻  Open Wallpaper Selector Panel
SUPER + CTRL + W  󰶻  Open Dynamic Island Wallpaper Picker
CTRL + ESC  󰶻  Reload Island & Entire Quickshell
SUPER + ALT + B  󰶻  Restart Quickshell Desktop Shell
SUPER + SHIFT + ,  󰶻  Toggle System Settings App
SUPER + SHIFT + S  󰶻  Open Screenshot Studio
SUPER + CTRL + R  󰶻  Reload Hyprland Configuration
SUPER + SHIFT + R  󰶻  Restart Startup Services
SUPER + S  󰶻  Open Dotfiles Settings Menu
SUPER + F1  󰶻  Toggle Window Animations
SUPER + CTRL + P  󰶻  Regenerate Colorscheme
CTRL + U  󰶻  Run System Update
Print  󰶻  Take Screenshot (Quickshell Studio)
SUPER + SHIFT + H  󰶻  Show Keybinds Help
SUPER + Tab  󰶻  Window Switcher
ALT + Tab  󰶻  Cycle Next Window
SUPER + G  󰶻  Toggle Window Group
SUPER + M  󰶻  Set Split Ratio (0.3)
SUPER + H / J / K / L  󰶻  Move Focus (Left / Down / Up / Right)
SUPER + Arrow Keys  󰶻  Move Focus (Left / Down / Up / Right)
SUPER + CTRL + H / J / K / L  󰶻  Move Window (Left / Down / Up / Right)
SUPER + 1..9, 0  󰶻  Switch to Workspace 1..10
SUPER + SHIFT + 1..9, 0  󰶻  Move Window to Workspace 1..10
SUPER + A  󰶻  Toggle Scratchpad Terminal (Pyprland)
SUPER + N  󰶻  Toggle Minimized Workspace (Pyprland)
SUPER + Z  󰶻  Zoom In / Reset Zoom (Pyprland)
F9 / XF86AudioMute  󰶻  Toggle Audio Mute
F10 / XF86AudioLowerVolume  󰶻  Decrease Volume
F11 / XF86AudioRaiseVolume  󰶻  Increase Volume
XF86AudioMicMute  󰶻  Toggle Microphone Mute
XF86AudioPlay / Pause  󰶻  Play / Pause Media
XF86AudioNext  󰶻  Next Media Track
XF86AudioPrev  󰶻  Previous Media Track
F4 / XF86MonBrightnessUp  󰶻  Increase Brightness
F3 / XF86MonBrightnessDown  󰶻  Decrease Brightness
EOF
}

execute_action() {
    local item="$1"

    case "$item" in
        *"Open Terminal (Kitty)"*) kitty --title main & ;;
        *"Open Floating Terminal (Kitty)"*) kitty --title floating & ;;
        *"Close Active Window"*) hyprctl dispatch killactive ;;
        *"Open File Manager (Dolphin"*) (dolphin || thunar) & ;;
        *"Open Terminal File Manager (Yazi)"*) kitty --title yazi -e yazi & ;;
        *"Toggle Floating Window"*) hyprctl dispatch togglefloating ;;
        *"Toggle All Windows to Float"*) hyprctl dispatch workspaceopt allfloat ;;
        *"Toggle Fullscreen"*) hyprctl dispatch fullscreen ;;
        *"Open App Launcher"*|*"Open Application Menu"*) "$sh_dir/qs-launcher.sh" & ;;
        *"Open Launcher Theme Switcher"*) "$sh_dir/qs-launcher-theme.sh" & ;;
        *"Toggle Pseudo-Tiling"*) hyprctl dispatch pseudo ;;
        *"Open Power Menu"*) "$sh_dir/qs-island.sh" --power & ;;
        *"Lock Screen"*) qs -c lockscreen & ;;
        *"Open IDE ("*|*"Open Code Editor ("*) "$sh_dir/ide.sh" & ;;
        *"Open Default Browser"*) "$sh_dir/browser.sh" op & ;;
        *"Open Brave (Incognito)"*) brave --incognito & ;;
        *"Reset Default Browser"*) "$sh_dir/default_browser.sh" --reset & ;;
        *"Change Wallpaper (Random)"*) "$sh_dir/Wallpaper.sh" & ;;
        *"Open Dynamic Island Wallpaper Picker"*|*"Open Wallpaper Selector Panel"*) "$sh_dir/qs-island.sh" --wallpaper & ;;
        *"Reload Island & Entire Quickshell"*|*"Restart Quickshell Desktop Shell"*) "$sh_dir/qs-reload.sh" & ;;
        *"Toggle System Settings App"*|*"Open Dotfiles Settings Menu"*) "$sh_dir/qs-settings.sh" & ;;
        *"Toggle Window Animations"*) "$sh_dir/animations_toggle.sh" & ;;
        *"Regenerate Colorscheme"*) "$sh_dir/regenerate-colors.sh" & ;;
        *"Take Screenshot"*|*"Open Screenshot Studio"*) "$sh_dir/qs-screenshot.sh" & ;;
        *"Window Switcher"*) "$sh_dir/qs-launcher.sh" & ;;
        *"Cycle Next Window"*) hyprctl dispatch cyclenext ;;
        *"Toggle Window Group"*) hyprctl dispatch togglegroup ;;
        *"Set Split Ratio (0.3)"*) hyprctl dispatch splitratio 0.3 ;;
        *"Toggle Scratchpad Terminal"*) pypr toggle term & ;;
        *"Toggle Minimized Workspace"*) pypr toggle_special minimized & ;;
        *"Zoom In"*) pypr zoom ++0.5 & ;;
        *"Zoom Screen"*|*"Zoom Reset"*) pypr zoom & ;;
        *"Toggle Audio Mute"*) "$sh_dir/volumecontrol.sh" --toggle & ;;
        *"Decrease Volume"*) "$sh_dir/volumecontrol.sh" --dec & ;;
        *"Increase Volume"*) "$sh_dir/volumecontrol.sh" --inc & ;;
        *"Toggle Microphone Mute"*) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle ;;
        *"Play / Pause Media"*) playerctl play-pause ;;
        *"Next Media Track"*) playerctl next ;;
        *"Previous Media Track"*) playerctl previous ;;
        *"Increase Brightness"*) "$sh_dir/brightness.sh" up & ;;
        *"Decrease Brightness"*) "$sh_dir/brightness.sh" down & ;;
        *)
            notify-send -t 2500 -i preferences-desktop-keyboard-shortcuts "Keybinding" "$item" || true
            ;;
    esac
}

# ── Mode 1: List keybindings (JSON or plain text) ─────────────────────────────
if [[ "${1:-}" == "--json" || "${1:-}" == "-j" ]]; then
    python3 "$py_dir/keybinds_catalog.py" --json
    exit 0
fi

if [[ "${1:-}" == "--list" || "${1:-}" == "-l" ]]; then
    get_keybinds
    exit 0
fi

# ── Mode 2: Handle selection ─────────────────────────────────────────────────
if [[ -n "${1:-}" ]]; then
    execute_action "$1"
    exit 0
fi

# ── Mode 3: Display keybinds summary ─────────────────────────────────────────
# Default to Quickshell Dynamic Island Keybinds launcher
exec "$sh_dir/qs-island.sh" --keybinds

