#!/usr/bin/env bash
# ==============================================================================
# keybinds.sh — Hyprland & Noctalia Keybinds Viewer and Dispatcher
# Synchronized with hypr/configs/keybinds.lua
# Usage:
#   keybinds.sh              → Open Noctalia launcher at >keybinds (or fallback to Rofi)
#   keybinds.sh --list       → Output keybinds list for dmenu (Key  󰶻  Action)
#   keybinds.sh <selection>  → Execute the selected action directly
# ==============================================================================

set -euo pipefail

scripts_dir="$HOME/.hyprconf/hypr/scripts"

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
SUPER + Space  󰶻  Open Noctalia Launcher
SUPER + D  󰶻  Open Application Menu (Rofi)
SUPER + ALT + C  󰶻  Open Clipboard Manager
SUPER + SHIFT + D  󰶻  Open Emoji Picker
SUPER + P  󰶻  Toggle Pseudo-Tiling
SUPER + SHIFT + P  󰶻  Toggle Pseudo-Tiling
SUPER + X  󰶻  Open Session / Power Menu
SUPER + SHIFT + L  󰶻  Lock Screen
SUPER + C  󰶻  Open Code Editor (VS Code / Codium)
SUPER + B  󰶻  Open Default Browser
SUPER + SHIFT + B  󰶻  Open Brave (Incognito)
ALT + B  󰶻  Reset Default Browser
SUPER + W  󰶻  Change Wallpaper (Random)
SUPER + SHIFT + W  󰶻  Open Wallpaper Selector
SUPER + CTRL + SHIFT + W  󰶻  Open Wallpaper Selector
SUPER + ALT + W  󰶻  Open Video Wallpaper Selector
SUPER + CTRL + W  󰶻  Switch Noctalia Bar Layout
SUPER + ALT + B  󰶻  Switch Desktop Shell (Noctalia / Waybar)
SUPER + SHIFT + ,  󰶻  Toggle Noctalia Settings
SUPER + SHIFT + S  󰶻  Toggle Noctalia Control Center
SUPER + CTRL + R  󰶻  Reload Hyprland Configuration
SUPER + SHIFT + R  󰶻  Restart Startup Services
SUPER + S  󰶻  Open Dotfiles Settings Menu
SUPER + F1  󰶻  Toggle Window Animations
SUPER + CTRL + P  󰶻  Regenerate Colorscheme
CTRL + U  󰶻  Run System Update
Print  󰶻  Take Screenshot (Launcher)
SUPER + SHIFT + H  󰶻  Show Keybinds Help
SUPER + Tab  󰶻  Window Switcher
ALT + Tab  󰶻  Cycle Next Window
SUPER + G  󰶻  Toggle Window Group
SUPER + M  󰶻  Set Split Ratio (0.3)
SUPER + .  󰶻  Move Window Column (+col)
SUPER + ,  󰶻  Swap Window Column (left)
SUPER + H / J / K / L  󰶻  Move Focus (Left / Down / Up / Right)
SUPER + Arrow Keys  󰶻  Move Focus (Left / Down / Up / Right)
SUPER + CTRL + H / J / K / L  󰶻  Move Active Window
SUPER + ALT + H / J / K / L  󰶻  Resize Active Window (Vim keys)
SUPER + Arrow Keys  󰶻  Resize Active Window
SUPER + 1..0  󰶻  Switch to Workspace 1–10
SUPER + SHIFT + 1..0  󰶻  Move Window to Workspace 1–10
SUPER + ALT + 1..0  󰶻  Move Window Silently to Workspace
SUPER + Mouse Scroll  󰶻  Cycle Workspaces
SUPER + Left Mouse Drag  󰶻  Move Window
SUPER + Right Mouse Drag  󰶻  Resize Window
SUPER + A  󰶻  Toggle Scratchpad Terminal (Pyprland)
SUPER + N  󰶻  Toggle Minimized Workspace (Pyprland)
SUPER + SHIFT + N  󰶻  Toggle Minimized Workspace
SUPER + Z  󰶻  Zoom Screen (Pyprland)
SUPER + SHIFT + Z  󰶻  Zoom In ++0.5 (Pyprland)
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
        *"Open Noctalia Launcher"*) noctalia msg panel-open launcher ">" ;;
        *"Open Application Menu (Rofi)"*) "$scripts_dir/menu.sh" || pkill rofi ;;
        *"Open Clipboard Manager"*) noctalia msg panel-toggle clipboard ;;
        *"Open Emoji Picker"*) noctalia msg panel-open launcher ">emo" ;;
        *"Toggle Pseudo-Tiling"*) hyprctl dispatch pseudo ;;
        *"Open Session / Power Menu"*) noctalia msg panel-toggle session ;;
        *"Lock Screen"*) noctalia msg session lock ;;
        *"Open Code Editor (VS Code"*) (code || codium) & ;;
        *"Open Default Browser"*) "$scripts_dir/browser.sh" op & ;;
        *"Open Brave (Incognito)"*) brave --incognito & ;;
        *"Reset Default Browser"*) "$scripts_dir/default_browser.sh" --reset & ;;
        *"Change Wallpaper (Random)"*) "$scripts_dir/Wallpaper.sh" & ;;
        *"Open Wallpaper Selector"*) "$scripts_dir/WallpaperSelect.py" & ;;
        *"Open Video Wallpaper Selector"*) noctalia msg panel-toggle noctalia/mpvpaper:picker ;;
        *"Switch Noctalia Bar Layout"*) "$scripts_dir/noctalia-bar.sh" & ;;
        *"Switch Desktop Shell"*) "$scripts_dir/shell.sh" & ;;
        *"Toggle Noctalia Settings"*) noctalia msg settings-toggle ;;
        *"Toggle Noctalia Control Center"*) noctalia msg panel-toggle control-center ;;
        *"Reload Hyprland Configuration"*) hyprctl reload && notify-send -i preferences-desktop-theme "Done" "Hyprland reload" ;;
        *"Restart Startup Services"*) "$scripts_dir/startup.sh" &>/dev/null & ;;
        *"Open Dotfiles Settings Menu"*) "$scripts_dir/settings.py" & ;;
        *"Toggle Window Animations"*) "$scripts_dir/animations_toggle.sh" & ;;
        *"Regenerate Colorscheme"*) "$scripts_dir/regenerate-colors.sh" & ;;
        *"Run System Update"*) "$scripts_dir/systemupdate.sh" --update & ;;
        *"Take Screenshot"*) noctalia msg panel-open launcher ">screenshot" ;;
        *"Show Keybinds Help"*) noctalia msg panel-open launcher ">keybinds" ;;
        *"Window Switcher"*) if pgrep -x noctalia >/dev/null; then window-switcher; else rofi -show window; fi & ;;
        *"Cycle Next Window"*) hyprctl dispatch cyclenext ;;
        *"Toggle Window Group"*) hyprctl dispatch togglegroup ;;
        *"Set Split Ratio (0.3)"*) hyprctl dispatch splitratio 0.3 ;;
        *"Move Window Column (+col)"*) hyprctl dispatch layoutmsg "move +col" ;;
        *"Swap Window Column (left)"*) hyprctl dispatch layoutmsg "swapcol l" ;;
        *"Toggle Scratchpad Terminal"*) pypr toggle term & ;;
        *"Toggle Minimized Workspace"*) pypr toggle_special minimized & ;;
        *"Zoom In"*) pypr zoom ++0.5 & ;;
        *"Zoom Screen"*|*"Zoom Reset"*) pypr zoom & ;;
        *"Toggle Audio Mute"*) "$scripts_dir/volumecontrol.sh" --toggle & ;;
        *"Decrease Volume"*) "$scripts_dir/volumecontrol.sh" --dec & ;;
        *"Increase Volume"*) "$scripts_dir/volumecontrol.sh" --inc & ;;
        *"Toggle Microphone Mute"*) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle ;;
        *"Play / Pause Media"*) playerctl play-pause ;;
        *"Next Media Track"*) playerctl next ;;
        *"Previous Media Track"*) playerctl previous ;;
        *"Increase Brightness"*) "$scripts_dir/brightness.sh" up & ;;
        *"Decrease Brightness"*) "$scripts_dir/brightness.sh" down & ;;
        *)
            notify-send -t 2500 -i preferences-desktop-keyboard-shortcuts "Keybinding" "$item" || true
            ;;
    esac
}

# ── Mode 1: List keybindings for Noctalia launcher dmenu ──────────────────────
if [[ "${1:-}" == "--list" || "${1:-}" == "-l" ]]; then
    get_keybinds
    exit 0
fi

# ── Mode 2: Handle selection from launcher ────────────────────────────────────
if [[ -n "${1:-}" ]]; then
    execute_action "$1"
    exit 0
fi

# ── Mode 3: Open Noctalia launcher at >keybinds ───────────────────────────────
if pgrep -x "noctalia" > /dev/null 2>&1; then
    noctalia msg panel-open launcher ">keybinds"
    exit 0
fi

# ── Fallback: Rofi launcher ───────────────────────────────────────────────────
if command -v rofi >/dev/null 2>&1; then
    if pidof rofi > /dev/null; then
        pkill rofi
    fi
    selected=$(get_keybinds | rofi -dmenu -i -p "Keybinds")
    if [[ -n "$selected" ]]; then
        execute_action "$selected"
    fi
    exit 0
fi

notify-send "Keybinds" "Noctalia or Rofi required to display keybinds." || true
exit 1
