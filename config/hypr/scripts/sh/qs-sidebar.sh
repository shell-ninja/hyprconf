#!/usr/bin/env bash
# qs-sidebar.sh - Supervisor and IPC Controller for Quickshell Agent Sidebar
# Manages the 40% sliding Agent Console drawer across Island and Bar modes

SIDEBAR_DIR="$HOME/.hyprconf/quickshell/sidebar"
CONFIG_LINK="$HOME/.config/quickshell/sidebar"

# Ensure config symlink exists
if [[ ! -e "$CONFIG_LINK" && ! -L "$CONFIG_LINK" ]]; then
    mkdir -p "$HOME/.config/quickshell"
    ln -sfn "$SIDEBAR_DIR" "$CONFIG_LINK"
fi

is_daemon_running() {
    pgrep -f "qs.*-c.*sidebar" >/dev/null 2>&1 || pgrep -f "sidebar/shell.qml" >/dev/null 2>&1
}

kill_daemon() {
    pkill -f "qs.*-c.*sidebar" 2>/dev/null || true
    pkill -f "sidebar/shell.qml" 2>/dev/null || true
}

start_daemon() {
    if ! is_daemon_running; then
        qs -c sidebar -d >/dev/null 2>&1 &
        for _ in {1..25}; do
            if qs ipc -c sidebar call sidebar ping >/dev/null 2>&1; then
                break
            fi
            sleep 0.04
        done
    fi
}

case "$1" in
    --start)
        start_daemon
        ;;
    --show|-s|--open)
        start_daemon
        qs ipc -c sidebar call sidebar openSidebar 2>/dev/null
        ;;
    --hide|-h|--close)
        qs ipc -c sidebar call sidebar closeSidebar 2>/dev/null
        ;;
    --toggle|-t|"")
        if is_daemon_running; then
            if ! qs ipc -c sidebar call sidebar toggle 2>/dev/null; then
                kill_daemon
                sleep 0.1
                start_daemon
                qs ipc -c sidebar call sidebar openSidebar 2>/dev/null
            fi
        else
            start_daemon
            qs ipc -c sidebar call sidebar openSidebar 2>/dev/null
        fi
        ;;
    --restart|-r)
        kill_daemon
        sleep 0.2
        start_daemon
        ;;
    --status)
        if is_daemon_running; then
            echo "Running"
        else
            echo "Stopped"
        fi
        ;;
    *)
        echo "Usage: $0 {--start|--toggle|--show|--hide|--restart|--status}"
        exit 1
        ;;
esac
