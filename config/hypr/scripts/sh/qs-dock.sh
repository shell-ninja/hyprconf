#!/usr/bin/env bash
# ==============================================================================
# qs-dock.sh — Quickshell Application Dock Manager
# Prefers the embedded DockLayer inside active island/bar shell; falls back
# cleanly to standalone `qs -c dock -d` only if neither top shell is running.
# ==============================================================================

set -euo pipefail

export QS_NO_RELOAD_POPUP=1

# Auto-link ~/.config/quickshell if missing
if [[ ! -e "$HOME/.config/quickshell" && -d "$HOME/.hyprconf/quickshell" ]]; then
    mkdir -p "$HOME/.config"
    ln -sfn "$HOME/.hyprconf/quickshell" "$HOME/.config/quickshell"
fi

ACTION="${1:---start}"

detect_host_shell() {
    if pgrep -f '(^|/)(qs|quickshell)[[:space:]]+(-c[[:space:]]+island|-p[[:space:]]+.*quickshell/island)' >/dev/null 2>&1; then
        echo "island"
    elif pgrep -f '(^|/)(qs|quickshell)[[:space:]]+(-c[[:space:]]+bar|-p[[:space:]]+.*quickshell/bar)' >/dev/null 2>&1; then
        echo "bar"
    fi
}

is_standalone_running() {
    pgrep -f "qs.*-c.*dock|quickshell.*-c.*dock" >/dev/null 2>&1
}

kill_standalone() {
    pkill -f "qs.*-c.*dock|quickshell.*-c.*dock" 2>/dev/null || true
}

HOST_SHELL="$(detect_host_shell || true)"

case "$ACTION" in
    --start|-s)
        if [[ -n "$HOST_SHELL" ]]; then
            kill_standalone
            qs ipc -c "$HOST_SHELL" call dock reloadConfig 2>/dev/null || true
            exit 0
        fi
        if is_standalone_running; then
            exit 0
        fi
        qs -c dock -d
        ;;

    --stop|-k)
        kill_standalone
        if [[ -n "$HOST_SHELL" ]]; then
            qs ipc -c "$HOST_SHELL" call dock disable 2>/dev/null || true
        fi
        ;;

    --restart|-r|--reload)
        kill_standalone
        if [[ -n "$HOST_SHELL" ]]; then
            qs ipc -c "$HOST_SHELL" call dock reloadConfig 2>/dev/null || true
            exit 0
        fi
        for _ in {1..20}; do
            is_standalone_running || break
            sleep 0.05
        done
        qs -c dock -d
        ;;

    --toggle|-t)
        if [[ -n "$HOST_SHELL" ]]; then
            qs ipc -c "$HOST_SHELL" call dock toggle 2>/dev/null || true
        elif is_standalone_running; then
            qs ipc -c dock call dock toggle 2>/dev/null || kill_standalone
        else
            nohup qs -c dock -d >/dev/null 2>&1 &
        fi
        ;;

    --status)
        if [[ -n "$HOST_SHELL" ]]; then
            enabled="True"
            cfg="$HOME/.local/share/hyprconf/dock.json"
            [[ ! -f "$cfg" ]] && cfg="$HOME/.hyprconf/quickshell/dock/dock.json"
            if [[ -f "$cfg" ]]; then
                enabled=$(python3 -c "import json; print(json.load(open('$cfg')).get('enabled', True))" 2>/dev/null || echo "True")
            fi
            if [[ "$enabled" == "True" ]]; then
                echo "Dock: RUNNING (embedded in $HOST_SHELL)"
                exit 0
            else
                echo "Dock: DISABLED (hosted in $HOST_SHELL)"
                exit 1
            fi
        elif is_standalone_running; then
            echo "Dock: RUNNING (standalone)"
            exit 0
        else
            echo "Dock: STOPPED"
            exit 1
        fi
        ;;

    *)
        echo "Usage: $0 [--start|--stop|--restart|--reload|--toggle|--status]"
        exit 1
        ;;
esac
