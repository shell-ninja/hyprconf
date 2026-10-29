#!/usr/bin/env python3
"""
keybinds_catalog.py — Source of truth catalog for Hyprland & Quickshell keybindings.
Used by KeybindsView.qml (Island view) and keybinds.sh.
"""

import sys
import json

CATALOG = [
    # ── APPS & LAUNCHERS ──────────────────────────────────────────────────────
    {
        "combo": "SUPER + Return",
        "action": "Open Terminal (Kitty)",
        "category": "Apps",
        "icon": "terminal",
        "desc": "Launch Kitty terminal emulator",
    },
    {
        "combo": "SUPER + SHIFT + Return",
        "action": "Open Floating Terminal (Kitty)",
        "category": "Apps",
        "icon": "terminal",
        "desc": "Launch Kitty in floating window mode",
    },
    {
        "combo": "SUPER + E",
        "action": "Open File Manager (Dolphin / Thunar)",
        "category": "Apps",
        "icon": "folder",
        "desc": "Launch primary graphical file manager",
    },
    {
        "combo": "SUPER + SHIFT + E",
        "action": "Open Terminal File Manager (Yazi)",
        "category": "Apps",
        "icon": "folder",
        "desc": "Launch Yazi terminal file manager in Kitty",
    },
    {
        "combo": "SUPER + B",
        "action": "Open Default Browser",
        "category": "Apps",
        "icon": "globe",
        "desc": "Open preferred web browser",
    },
    {
        "combo": "SUPER + SHIFT + B",
        "action": "Open Brave (Incognito)",
        "category": "Apps",
        "icon": "shield",
        "desc": "Launch private browsing session",
    },
    {
        "combo": "SUPER + C",
        "action": "Open IDE (VS Code / Codium / Antigravity)",
        "category": "Apps",
        "icon": "code",
        "desc": "Launch code editor or IDE",
    },
    {
        "combo": "SUPER + Space",
        "action": "Open App Launcher (Quickshell)",
        "category": "Quickshell",
        "icon": "grid",
        "desc": "Expand Dynamic Island application launcher",
    },
    {
        "combo": "SUPER + D",
        "action": "Open App Launcher (Quickshell)",
        "category": "Quickshell",
        "icon": "grid",
        "desc": "Expand Dynamic Island application launcher",
    },
    {
        "combo": "SUPER + ALT + D",
        "action": "Open Launcher Theme Switcher",
        "category": "Quickshell",
        "icon": "palette",
        "desc": "Switch between launcher layouts & styles",
    },
    {
        "combo": "SUPER + SHIFT + D",
        "action": "Open Emoji Picker",
        "category": "Quickshell",
        "icon": "smile",
        "desc": "Open Island emoji studio with auto-paste",
    },
    {
        "combo": "SUPER + SHIFT + C",
        "action": "Open Clipboard Manager",
        "category": "Quickshell",
        "icon": "clipboard",
        "desc": "Open Island clipboard history manager",
    },
    {
        "combo": "SUPER + SHIFT + H",
        "action": "Show Keybinds Cheatsheet",
        "category": "Quickshell",
        "icon": "keyboard",
        "desc": "Open Dynamic Island keybinds launcher & guide",
    },

    # ── WINDOW MANAGEMENT ────────────────────────────────────────────────────
    {
        "combo": "SUPER + Q",
        "action": "Close Active Window",
        "category": "Windows",
        "icon": "x",
        "desc": "Kill or gracefully close focused window",
    },
    {
        "combo": "SUPER + V",
        "action": "Toggle Floating Window",
        "category": "Windows",
        "icon": "layers",
        "desc": "Switch active window between floating and tiled",
    },
    {
        "combo": "SUPER + ALT + V",
        "action": "Toggle All Windows to Float",
        "category": "Windows",
        "icon": "layers",
        "desc": "Make all windows on current workspace float",
    },
    {
        "combo": "SUPER + F",
        "action": "Toggle Fullscreen",
        "category": "Windows",
        "icon": "maximize",
        "desc": "Toggle fullscreen mode for active window",
    },
    {
        "combo": "SUPER + P",
        "action": "Toggle Pseudo-Tiling",
        "category": "Windows",
        "icon": "layout",
        "desc": "Keep window's original aspect ratio while tiled",
    },
    {
        "combo": "SUPER + G",
        "action": "Toggle Window Group",
        "category": "Windows",
        "icon": "folder-plus",
        "desc": "Group multiple tiled windows into tabs",
    },
    {
        "combo": "SUPER + Tab",
        "action": "Window Switcher",
        "category": "Windows",
        "icon": "copy",
        "desc": "Switch between open windows",
    },
    {
        "combo": "ALT + Tab",
        "action": "Cycle Next Window",
        "category": "Windows",
        "icon": "repeat",
        "desc": "Cycle focus to next window in workspace",
    },
    {
        "combo": "SUPER + H / J / K / L",
        "action": "Move Focus (Left / Down / Up / Right)",
        "category": "Windows",
        "icon": "move",
        "desc": "Vim-style window focus movement",
    },
    {
        "combo": "SUPER + Arrow Keys",
        "action": "Move Focus (Left / Down / Up / Right)",
        "category": "Windows",
        "icon": "move",
        "desc": "Directional window focus movement",
    },
    {
        "combo": "SUPER + CTRL + H / J / K / L",
        "action": "Move Window (Left / Down / Up / Right)",
        "category": "Windows",
        "icon": "move",
        "desc": "Swap active window in tiling layout",
    },
    {
        "combo": "SUPER + M",
        "action": "Set Split Ratio (0.3)",
        "category": "Windows",
        "icon": "columns",
        "desc": "Set tiling split proportion to 30%",
    },
    {
        "combo": "SUPER + A",
        "action": "Toggle Scratchpad Terminal (Pyprland)",
        "category": "Windows",
        "icon": "terminal",
        "desc": "Slide-in dropdown scratchpad terminal",
    },
    {
        "combo": "SUPER + N",
        "action": "Toggle Minimized Workspace (Pyprland)",
        "category": "Windows",
        "icon": "eye-off",
        "desc": "Minimize or restore windows to special workspace",
    },
    {
        "combo": "SUPER + Z",
        "action": "Zoom In / Reset Zoom (Pyprland)",
        "category": "Windows",
        "icon": "zoom-in",
        "desc": "Magnify active desktop display",
    },

    # ── WORKSPACES ───────────────────────────────────────────────────────────
    {
        "combo": "SUPER + 1..9, 0",
        "action": "Switch to Workspace 1..10",
        "category": "Workspaces",
        "icon": "hash",
        "desc": "Switch to workspace number",
    },
    {
        "combo": "SUPER + SHIFT + 1..9, 0",
        "action": "Move Window to Workspace 1..10",
        "category": "Workspaces",
        "icon": "arrow-right",
        "desc": "Move focused window to workspace",
    },

    # ── QUICKSHELL & SHELL ───────────────────────────────────────────────────
    {
        "combo": "SUPER + W",
        "action": "Change Wallpaper (Random)",
        "category": "Quickshell",
        "icon": "image",
        "desc": "Pick and apply a random wallpaper",
    },
    {
        "combo": "SUPER + SHIFT + W",
        "action": "Open Dynamic Island Wallpaper Picker",
        "category": "Quickshell",
        "icon": "image",
        "desc": "Browse wallpapers inside Dynamic Island",
    },
    {
        "combo": "SUPER + ALT + W",
        "action": "Open Wallpaper Selector Panel",
        "category": "Quickshell",
        "icon": "image",
        "desc": "Browse wallpapers inside Dynamic Island",
    },
    {
        "combo": "SUPER + SHIFT + ,",
        "action": "Toggle System Settings App",
        "category": "Quickshell",
        "icon": "settings",
        "desc": "Open Unified Quickshell Settings Studio",
    },
    {
        "combo": "SUPER + SHIFT + S",
        "action": "Open Screenshot Studio",
        "category": "Quickshell",
        "icon": "camera",
        "desc": "Island screenshot timer & area selection",
    },
    {
        "combo": "Print",
        "action": "Take Screenshot (Quickshell Studio)",
        "category": "Quickshell",
        "icon": "camera",
        "desc": "Instant screen capture & studio preview",
    },
    {
        "combo": "CTRL + ESC",
        "action": "Reload Island & Entire Quickshell",
        "category": "Quickshell",
        "icon": "refresh",
        "desc": "Restart all quickshell daemons cleanly",
    },
    {
        "combo": "SUPER + ALT + B",
        "action": "Restart Quickshell Desktop Shell",
        "category": "Quickshell",
        "icon": "refresh",
        "desc": "Soft-reload Quickshell processes",
    },
    {
        "combo": "SUPER + ALT + SPACE",
        "action": "Toggle Application Dock",
        "category": "Quickshell",
        "icon": "grid",
        "desc": "Toggle Application Dock visibility",
    },

    # ── AUDIO & MEDIA & HARDWARE ─────────────────────────────────────────────
    {
        "combo": "F4 / XF86MonBrightnessUp",
        "action": "Increase Brightness",
        "category": "Media",
        "icon": "sun",
        "desc": "Increase display brightness (+10%)",
    },
    {
        "combo": "F3 / XF86MonBrightnessDown",
        "action": "Decrease Brightness",
        "category": "Media",
        "icon": "sun",
        "desc": "Decrease display brightness (-10%)",
    },
    {
        "combo": "F11 / XF86AudioRaiseVolume",
        "action": "Increase Volume",
        "category": "Media",
        "icon": "volume-2",
        "desc": "Raise master audio volume (+5%)",
    },
    {
        "combo": "F10 / XF86AudioLowerVolume",
        "action": "Decrease Volume",
        "category": "Media",
        "icon": "volume-1",
        "desc": "Lower master audio volume (-5%)",
    },
    {
        "combo": "F9 / XF86AudioMute",
        "action": "Toggle Audio Mute",
        "category": "Media",
        "icon": "volume-x",
        "desc": "Mute or unmute speaker output",
    },
    {
        "combo": "XF86AudioMicMute",
        "action": "Toggle Microphone Mute",
        "category": "Media",
        "icon": "mic-off",
        "desc": "Mute or unmute microphone input source",
    },
    {
        "combo": "XF86AudioPlay / Pause",
        "action": "Play / Pause Media",
        "category": "Media",
        "icon": "play",
        "desc": "Toggle media playback via playerctl",
    },
    {
        "combo": "XF86AudioNext",
        "action": "Next Media Track",
        "category": "Media",
        "icon": "skip-forward",
        "desc": "Skip to next track via playerctl",
    },
    {
        "combo": "XF86AudioPrev",
        "action": "Previous Media Track",
        "category": "Media",
        "icon": "skip-back",
        "desc": "Go to previous track via playerctl",
    },

    # ── SYSTEM & POWER ───────────────────────────────────────────────────────
    {
        "combo": "SUPER + X",
        "action": "Open Power Menu (Dynamic Island)",
        "category": "System",
        "icon": "power",
        "desc": "Shutdown, reboot, lock, suspend menu",
    },
    {
        "combo": "SUPER + SHIFT + L",
        "action": "Lock Screen",
        "category": "System",
        "icon": "lock",
        "desc": "Launch Quickshell PAM Lockscreen",
    },
    {
        "combo": "SUPER + CTRL + R",
        "action": "Reload Hyprland Configuration",
        "category": "System",
        "icon": "refresh",
        "desc": "hyprctl reload",
    },
    {
        "combo": "SUPER + SHIFT + R",
        "action": "Restart Startup Services",
        "category": "System",
        "icon": "refresh",
        "desc": "Restart system background daemons",
    },
    {
        "combo": "SUPER + S",
        "action": "Open Dotfiles Settings Menu",
        "category": "System",
        "icon": "settings",
        "desc": "Open settings overview",
    },
    {
        "combo": "SUPER + F1",
        "action": "Toggle Window Animations",
        "category": "System",
        "icon": "zap",
        "desc": "Toggle Hyprland animations on / off",
    },
    {
        "combo": "SUPER + CTRL + P",
        "action": "Regenerate Colorscheme",
        "category": "System",
        "icon": "palette",
        "desc": "Regenerate dynamic Noctalia colors from wallpaper",
    },
    {
        "combo": "CTRL + U",
        "action": "Run System Update",
        "category": "System",
        "icon": "download",
        "desc": "Launch system package manager update",
    },
]

def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--json":
        print(json.dumps(CATALOG, indent=2))
    elif len(sys.argv) > 1 and sys.argv[1] == "--list":
        for item in CATALOG:
            print(f"{item['combo']}  󰶻  {item['action']}")
    else:
        print(json.dumps(CATALOG))

if __name__ == "__main__":
    main()
