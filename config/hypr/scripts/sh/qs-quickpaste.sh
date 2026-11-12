#!/usr/bin/env bash
set -euo pipefail

PY_SCRIPT="$HOME/.hyprconf/hypr/scripts/py/quickpaste.py"
if [[ ! -f "$PY_SCRIPT" ]]; then
    SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
    PY_SCRIPT="$(cd -- "$SCRIPT_DIR/../py" && pwd)/quickpaste.py"
fi

is_alive() {
    qs ipc -c quickpaste call quickpaste ping >/dev/null 2>&1
}

start_daemon() {
    local open_now="${1:-0}"
    if is_alive; then
        return 0
    fi
    if [[ ! -f "$HOME/.local/share/hyprconf/.cache/quickpaste_state.json" ]]; then
        python3 "$PY_SCRIPT" --prepare >/dev/null 2>&1 || true
    fi
    QS_NO_RELOAD_POPUP=1 QS_QUICKPASTE_OPEN="$open_now" \
        nohup qs -c quickpaste -d >/dev/null 2>&1 &
}

stop_daemon() {
    qs ipc -c quickpaste call quickpaste quit >/dev/null 2>&1 || true
    sleep 0.1
    pkill -f '^(qs|quickshell) (-c|-p) .*quickpaste' >/dev/null 2>&1 || true
}

case "${1:-}" in
    --daemon|--start)
        start_daemon 0
        ;;
    --stop)
        stop_daemon
        ;;
    --restart)
        stop_daemon
        sleep 0.15
        start_daemon 0
        ;;
    --close)
        qs ipc -c quickpaste call quickpaste close >/dev/null 2>&1 || true
        ;;
    ""|--toggle)
        python3 "$PY_SCRIPT" --prepare
        if ! qs ipc -c quickpaste call quickpaste toggleAtCursor >/dev/null 2>&1; then
            start_daemon 1
        fi
        ;;
    *)
        echo "Usage: $0 [--daemon|--start|--stop|--restart|--close|--toggle]" >&2
        exit 1
        ;;
esac
