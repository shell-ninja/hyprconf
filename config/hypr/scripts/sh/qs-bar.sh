#!/usr/bin/env bash
# ==============================================================================
# qs-bar.sh — Supervisor for Quickshell Top Bar
# Usage:
#   qs-bar.sh --start     → Starts the top bar daemon if not running
#   qs-bar.sh --stop      → Stops the top bar daemon
#   qs-bar.sh --restart   → Restarts the top bar daemon
#   qs-bar.sh --toggle    → Toggles between Dynamic Island and Full Top Bar
# ==============================================================================

set -euo pipefail

export QS_NO_RELOAD_POPUP=1

bar_dir="$HOME/.hyprconf/quickshell/bar"
island_dir="$HOME/.hyprconf/quickshell/island"
user_state="$HOME/.local/share/hyprconf/bar.json"
scripts_dir="$HOME/.hyprconf/hypr/scripts/sh"

# Ensure ~/.config/quickshell points to ~/.hyprconf/quickshell
if [[ ! -e "$HOME/.config/quickshell" && -d "$HOME/.hyprconf/quickshell" ]]; then
    mkdir -p "$HOME/.config"
    ln -sfn "$HOME/.hyprconf/quickshell" "$HOME/.config/quickshell"
fi

# Ensure bar has valid symlinks to Theme.qml, colors.json and config.json
if [[ -d "$bar_dir" ]]; then
    [[ ! -e "$bar_dir/Theme.qml" ]] && ln -sfn "../Theme.qml" "$bar_dir/Theme.qml"
    [[ ! -e "$bar_dir/colors.json" ]] && ln -sfn "../colors.json" "$bar_dir/colors.json"
    if [[ -f "$user_state" ]]; then
        [[ ! -e "$bar_dir/config.json" ]] && ln -sfn "$user_state" "$bar_dir/config.json"
    fi
fi

cmd="${1:---start}"

case "$cmd" in
    --start)
        if [[ -f "$user_state" ]] && grep -q '"top_panel":\s*"island"' "$user_state" 2>/dev/null; then
            exit 0
        fi
        pkill -9 -f "qs -c island" 2>/dev/null || true
        pkill -9 -f "quickshell.*island" 2>/dev/null || true
        pkill -9 -f "[a]udio-monitor.py" 2>/dev/null || true
        pkill -9 -f "[n]etwork-speed.py" 2>/dev/null || true
        pkill -x cava 2>/dev/null || true
        if ! pgrep -f "qs -c bar" >/dev/null 2>&1 && ! pgrep -f "quickshell -p .*quickshell/bar" >/dev/null 2>&1; then
            exec qs -c bar -d
        fi
        ;;

    --stop)
        qs ipc -c bar call bar quit 2>/dev/null || true
        pkill -9 -f "qs -c bar" 2>/dev/null || true
        pkill -9 -f "quickshell.*bar" 2>/dev/null || true
        pkill -f "qs -c bar" 2>/dev/null || true
        pkill -f "quickshell -p .*quickshell/bar" 2>/dev/null || true
        ;;

    --restart)
        pkill -9 -f "qs -c island" 2>/dev/null || true
        pkill -9 -f "quickshell.*island" 2>/dev/null || true
        pkill -9 -f "[a]udio-monitor.py" 2>/dev/null || true
        pkill -9 -f "[n]etwork-speed.py" 2>/dev/null || true
        pkill -x cava 2>/dev/null || true
        pkill -9 -f "qs -c bar" 2>/dev/null || true
        pkill -9 -f "quickshell.*bar" 2>/dev/null || true
        pkill -f "qs -c bar" 2>/dev/null || true
        pkill -f "quickshell -p .*quickshell/bar" 2>/dev/null || true
        sleep 0.25
        exec qs -c bar -d
        ;;

    --toggle)
        # Check current mode in bar.json
        current_mode="island"
        if [[ -f "$user_state" ]] && grep -q '"top_panel":\s*"bar"' "$user_state" 2>/dev/null; then
            current_mode="bar"
        fi

        if [[ "$current_mode" == "bar" ]]; then
            # Switch to Island
            python3 -c "import json, os; p='$user_state'; d=json.load(open(p)) if os.path.exists(p) else {}; d['top_panel']='island'; json.dump(d, open(p,'w'), indent=2)"
            pkill -f "qs -c bar" 2>/dev/null || true
            pkill -f "quickshell -p .*quickshell/bar" 2>/dev/null || true
            sleep 0.25
            nohup bash "$scripts_dir/qs-island.sh" --start >/dev/null 2>&1 &
            notify-send -a "Hyprconf" -t 2000 "Interface Switched" "Active top panel: Dynamic Island"
        else
            # Switch to Bar
            python3 -c "import json, os; p='$user_state'; d=json.load(open(p)) if os.path.exists(p) else {}; d['top_panel']='bar'; json.dump(d, open(p,'w'), indent=2)"
            pkill -f "qs -c island" 2>/dev/null || true
            pkill -f "quickshell -p .*quickshell/island" 2>/dev/null || true
            sleep 0.25
            nohup qs -c bar -d >/dev/null 2>&1 &
            notify-send -a "Hyprconf" -t 2000 "Interface Switched" "Active top panel: Full Top Bar"
        fi
        ;;

    *)
        exec qs -c bar -d "$@"
        ;;
esac

