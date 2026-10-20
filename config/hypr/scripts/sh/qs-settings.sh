#!/usr/bin/env bash
# Launch Quickshell QML Settings (single instance)
export QS_NO_RELOAD_POPUP=1

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

pkill -f "qs -c settings" 2>/dev/null
sleep 0.1
exec qs -c settings "$@"
