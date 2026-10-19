#!/usr/bin/env bash
# qs-island.sh — Toggle or launch Quickshell Dynamic Island

export QS_NO_RELOAD_POPUP=1

# Auto-link ~/.config/quickshell if missing
if [[ ! -e "$HOME/.config/quickshell" && -d "$HOME/.hyprconf/quickshell" ]]; then
    mkdir -p "$HOME/.config"
    ln -sfn "$HOME/.hyprconf/quickshell" "$HOME/.config/quickshell"
fi

# Ensure island has valid relative symlinks to launcher styles
island_dir="$HOME/.hyprconf/quickshell/island"
launcher_dir="$HOME/.hyprconf/quickshell/launcher"
if [[ -d "$island_dir" && -d "$launcher_dir" ]]; then
    for style in Style1.qml Style2.qml; do
        target="$island_dir/$style"
        if [[ ! -e "$target" || ( -L "$target" && "$(readlink "$target")" =~ /home/ ) ]]; then
            ln -sfn "../launcher/$style" "$target"
        fi
    done
fi

# Ensure cava config exists for audio visualizer
cava_conf="$HOME/.hyprconf/hypr/.cache/cava-island.conf"
if [[ ! -f "$cava_conf" ]]; then
    mkdir -p "$HOME/.hyprconf/hypr/.cache"
    cat << 'EOF' > "$cava_conf"
[general]
bars = 16
framerate = 30
autosens = 1

[input]
method = pulse
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
bar_delimiter = 59
frame_delimiter = 10
EOF
fi

if [[ "$1" == "--start" ]]; then
    if ! pgrep -f "qs -c island" >/dev/null 2>&1; then
        exec qs -c island -d
    fi
    exit 0
fi

if [[ "$1" == "--restart" ]]; then
    pkill -f "qs -c island" 2>/dev/null || true
    sleep 0.4
    exec qs -c island -d
fi

if [[ "$1" == "--wallpaper" ]]; then
    if pgrep -f "qs -c island" >/dev/null 2>&1; then
        qs ipc -c island call island openWallpaper
        exit 0
    else
        qs -c island -d
        sleep 0.35
        qs ipc -c island call island openWallpaper
        exit 0
    fi
fi

if [[ "$1" == "--launcher" ]]; then
    if pgrep -f "qs -c island" >/dev/null 2>&1; then
        qs ipc -c island call island toggleLauncher
        exit 0
    else
        qs -c island -d
        sleep 0.35
        qs ipc -c island call island openLauncher
        exit 0
    fi
fi

if [[ "$1" == "--clipboard" ]]; then
    if pgrep -f "qs -c island" >/dev/null 2>&1; then
        qs ipc -c island call island toggleClipboard
        exit 0
    else
        qs -c island -d
        sleep 0.35
        qs ipc -c island call island openClipboard
        exit 0
    fi
fi

if [[ "$1" == "--emoji" ]]; then
    if pgrep -f "qs -c island" >/dev/null 2>&1; then
        qs ipc -c island call island toggleEmoji
        exit 0
    else
        qs -c island -d
        sleep 0.35
        qs ipc -c island call island openEmoji
        exit 0
    fi
fi

if [[ "$1" == "--power" ]]; then
    if pgrep -f "qs -c island" >/dev/null 2>&1; then
        qs ipc -c island call island togglePower
        exit 0
    else
        qs -c island -d
        sleep 0.35
        qs ipc -c island call island openPower
        exit 0
    fi
fi

if pkill -f "qs -c island" 2>/dev/null; then
    exit 0
fi

exec qs -c island -d "$@"
