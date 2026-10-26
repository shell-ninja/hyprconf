#!/usr/bin/env bash
# Launch Quickshell QML Settings (single instance)
export QS_NO_RELOAD_POPUP=1

# Auto-link ~/.config/quickshell if missing
if [[ ! -e "$HOME/.config/quickshell" && -d "$HOME/.hyprconf/quickshell" ]]; then
    mkdir -p "$HOME/.config"
    ln -sfn "$HOME/.hyprconf/quickshell" "$HOME/.config/quickshell"
fi

# Ensure settings qmldir includes DockSection
settings_dir="$HOME/.hyprconf/quickshell/settings"
if [[ -f "$settings_dir/qmldir" ]] && ! grep -q "DockSection" "$settings_dir/qmldir"; then
    echo "DockSection 1.0 DockSection.qml" >> "$settings_dir/qmldir"
fi

if [ "$1" = "--island" ] || [ "$1" = "-i" ]; then
    export QS_SETTINGS_SECTION="island"
    # Try IPC if settings app is already running
    if pgrep -f "qs -c settings" >/dev/null 2>&1; then
        qs ipc -c settings call settings openIsland 2>/dev/null && exit 0
    fi
    shift
fi

if [ "$1" = "--widgets" ] || [ "$1" = "-w" ]; then
    export QS_SETTINGS_SECTION="widgets"
    # Try IPC if settings app is already running
    if pgrep -f "qs -c settings" >/dev/null 2>&1; then
        qs ipc -c settings call settings openWidgets 2>/dev/null && exit 0
    fi
    shift
fi

if [ "$1" = "--dock" ] || [ "$1" = "-d" ]; then
    export QS_SETTINGS_SECTION="dock"
    # Try IPC if settings app is already running
    if pgrep -f "qs -c settings" >/dev/null 2>&1; then
        qs ipc -c settings call settings openDock 2>/dev/null && exit 0
    fi
    shift
fi

pkill -f "qs -c settings" 2>/dev/null
sleep 0.1
exec qs -c settings "$@"
