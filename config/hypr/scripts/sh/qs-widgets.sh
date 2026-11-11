#!/usr/bin/env bash
# ==============================================================================
# qs-widgets.sh — Quickshell Desktop Widgets Manager
# Prefers the embedded DesktopWidgetsLayer inside active island/bar shell;
# falls back cleanly to standalone `qs -c widgets -d` only if neither runs.
# ==============================================================================

export QS_NO_RELOAD_POPUP=1

# Auto-link ~/.config/quickshell if missing
if [[ ! -e "$HOME/.config/quickshell" && -d "$HOME/.hyprconf/quickshell" ]]; then
    mkdir -p "$HOME/.config"
    ln -sfn "$HOME/.hyprconf/quickshell" "$HOME/.config/quickshell"
fi

detect_host_shell() {
    if pgrep -f '(^|/)(qs|quickshell)[[:space:]]+(-c[[:space:]]+island|-p[[:space:]]+.*quickshell/island)' >/dev/null 2>&1; then
        echo "island"
    elif pgrep -f '(^|/)(qs|quickshell)[[:space:]]+(-c[[:space:]]+bar|-p[[:space:]]+.*quickshell/bar)' >/dev/null 2>&1; then
        echo "bar"
    fi
}

kill_standalone() {
    pkill -f "qs.*-c.*widgets|quickshell.*-c.*widgets" 2>/dev/null || true
}

HOST_SHELL="$(detect_host_shell || true)"
ACTION="${1:---start}"

if [[ -n "$HOST_SHELL" ]]; then
    kill_standalone
    case "$ACTION" in
        --toggle)
            qs ipc -c "$HOST_SHELL" call widgets toggle 2>/dev/null || true
            ;;
        --stop)
            qs ipc -c "$HOST_SHELL" call widgets disable 2>/dev/null || true
            ;;
        *)
            qs ipc -c "$HOST_SHELL" call widgets reloadConfig 2>/dev/null || true
            ;;
    esac
    exit 0
fi

# Standalone fallback when neither island nor bar is running
case "$ACTION" in
    --start)
        cfg="$HOME/.local/share/hyprconf/widgets.json"
        [[ ! -f "$cfg" ]] && cfg="$HOME/.hyprconf/quickshell/widgets/widgets.json"
        if [[ -f "$cfg" ]]; then
            enabled=$(python3 -c "import json; print(json.load(open('$cfg')).get('enabled', False))" 2>/dev/null || echo "False")
            if [[ "$enabled" != "True" ]]; then
                exit 0
            fi
        fi
        if ! pgrep -f "qs -c widgets" >/dev/null 2>&1; then
            exec qs -c widgets -d
        fi
        ;;
    --restart)
        kill_standalone
        sleep 0.3
        exec qs -c widgets -d
        ;;
    --stop)
        kill_standalone
        ;;
    --reload)
        if pgrep -f "qs -c widgets" >/dev/null 2>&1; then
            qs ipc -c widgets call widgets reloadConfig 2>/dev/null || true
        else
            exec qs -c widgets -d
        fi
        ;;
    --toggle)
        if pgrep -f "qs -c widgets" >/dev/null 2>&1; then
            qs ipc -c widgets call widgets toggle 2>/dev/null || true
        else
            exec qs -c widgets -d
        fi
        ;;
    *)
        if pgrep -f "qs -c widgets" >/dev/null 2>&1; then
            qs ipc -c widgets call widgets reloadConfig 2>/dev/null || true
        else
            exec qs -c widgets -d
        fi
        ;;
esac
