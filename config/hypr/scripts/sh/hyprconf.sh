#!/usr/bin/env bash
# ==============================================================================
#  hyprconf.sh — Update Manager & Background Notifier for Hyprconf
#
#  Repository: https://github.com/shell-ninja/hyprconf
#
#  Modes:
#     ./hyprconf.sh                   Interactive update with Gum CLI
#     ./hyprconf.sh --update          Interactive update
#     ./hyprconf.sh --daemon          Run background watchdog (checks every 6h)
#     ./hyprconf.sh --check           Check remote repository for updates (exit 1 if update)
#     ./hyprconf.sh --version         Show current installed version
#     ./hyprconf.sh --notify-test     Send a test update notification
#     ./hyprconf.sh --hyprconf        Launch interactive update in Kitty terminal
# ==============================================================================

set -o pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYPRCONF_DIR="${HYPRCONF_DIR:-$HOME/.hyprconf}"
VERSION_FILE="$HYPRCONF_DIR/.version"
REPO_URL="https://github.com/shell-ninja/hyprconf"
CACHE_DIR="$HYPRCONF_DIR/hypr/.cache"
STATE_FILE="$CACHE_DIR/update_state.json"
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/hyprconf_update_daemon.lock"
SOUND_FILE_UPDATE="$HYPRCONF_DIR/hypr/sounds/update.wav"
ICON_FILE="$HYPRCONF_DIR/hypr/icons/pkgupdt.svg"
FALLBACK_ICON="preferences-system-updates"

# 6 hours in seconds: 6 * 3600 = 21600
CHECK_INTERVAL_SECONDS=21600

# Source dynamic theme colors if available
if [[ -f "$SCRIPTS_DIR/colors.sh" ]]; then
    source "$SCRIPTS_DIR/colors.sh"
fi

primary="${primary:-#ac67e4}"
secondary="${secondary:-#d65cd1}"
surface="${surface:-#201628}"
foreground="${foreground:-#f2f2f3}"
on_secondary="${on_secondary:-#1f1825}"
error="${error:-#fd4663}"
accent="${accent:-#bfb78b}"

mkdir -p "$CACHE_DIR"

# ── Local Version Helper ───────────────────────────────────────────────────────
get_local_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        local v
        v="$(tr -d ' \r\n' < "$VERSION_FILE")"
        if [[ -n "$v" ]]; then
            echo "$v"
            return
        fi
    fi
    echo "v1.0.0"
}

# ── Python Semver Checker & Remote Query ──────────────────────────────────────
check_remote_json() {
    local cur_ver
    cur_ver="$(get_local_version)"

    python3 -c '
import urllib.request, json, subprocess, re, sys

local_raw = sys.argv[1].strip() if len(sys.argv) > 1 else "v1.0.0"

def parse_v(v):
    if not v:
        return ()
    v = v.lstrip("vV").strip()
    parts = re.split(r"[-+.]", v)
    nums = []
    for p in parts:
        try:
            nums.append(int(p))
        except ValueError:
            nums.append(0)
    return tuple(nums)

def get_remote_version():
    headers = {
        "User-Agent": "hyprconf-updater",
        "Accept": "application/vnd.github.v3+json"
    }

    # 1. Check latest GitHub Release
    try:
        req = urllib.request.Request("https://api.github.com/repos/shell-ninja/hyprconf/releases/latest", headers=headers)
        with urllib.request.urlopen(req, timeout=6) as resp:
            data = json.loads(resp.read().decode())
            if isinstance(data, dict) and data.get("tag_name"):
                return data["tag_name"]
    except Exception:
        pass

    # 2. Check GitHub Tags API
    try:
        req = urllib.request.Request("https://api.github.com/repos/shell-ninja/hyprconf/tags", headers=headers)
        with urllib.request.urlopen(req, timeout=6) as resp:
            tags = json.loads(resp.read().decode())
            if isinstance(tags, list) and len(tags) > 0 and tags[0].get("name"):
                return tags[0]["name"]
    except Exception:
        pass

    # 3. Fallback to git ls-remote (works even with GitHub API rate limits)
    try:
        res = subprocess.run(
            ["git", "ls-remote", "--tags", "--refs", "https://github.com/shell-ninja/hyprconf.git"],
            capture_output=True, text=True, timeout=8
        )
        if res.returncode == 0 and res.stdout.strip():
            found_tags = []
            for line in res.stdout.strip().splitlines():
                m = re.search(r"refs/tags/(v?[0-9].*)", line)
                if m:
                    found_tags.append(m.group(1))
            if found_tags:
                found_tags.sort(key=parse_v)
                return found_tags[-1]
    except Exception:
        pass

    return None

remote_ver = get_remote_version()
has_update = False
if remote_ver:
    has_update = parse_v(remote_ver) > parse_v(local_raw)

output = {
    "local": local_raw,
    "remote": remote_ver,
    "has_update": bool(has_update),
    "status": "ok" if remote_ver else "no_remote"
}
print(json.dumps(output))
sys.exit(1 if has_update else 0)
' "$cur_ver"
}

# ── Notification Helper ───────────────────────────────────────────────────────
send_notification() {
    local remote_ver="$1"
    local local_ver="$2"
    local title="Hyprconf Update Available"
    local body="A new version (${remote_ver}) is available (current: ${local_ver}). Click to update now."
    local icon="$ICON_FILE"
    [[ -f "$icon" ]] || icon="$FALLBACK_ICON"

    # Play update notification chime if sound file exists
    if [[ -f "$SOUND_FILE_UPDATE" ]] && command -v paplay &>/dev/null; then
        paplay "$SOUND_FILE_UPDATE" 2>/dev/null &
    fi

    if command -v notify-send &>/dev/null; then
        (
            # Send actionable notification (clicking 'Update Now' triggers terminal updater)
            local action
            action=$(notify-send \
                --app-name="Hyprconf Updater" \
                --icon="$icon" \
                --urgency=normal \
                --expire-time=20000 \
                --action="update=Update Now" \
                "$title" "$body" 2>/dev/null || true)

            if [[ "$action" == "update" || "$action" == "0" ]]; then
                launch_terminal_updater
            fi
        ) &
    fi
}

launch_terminal_updater() {
    if command -v kitty &>/dev/null; then
        kitty --title "Hyprconf Update" sh -c "$SCRIPTS_DIR/hyprconf.sh --update" &
    elif command -v foot &>/dev/null; then
        foot --title "Hyprconf Update" sh -c "$SCRIPTS_DIR/hyprconf.sh --update" &
    elif command -v alacritty &>/dev/null; then
        alacritty --title "Hyprconf Update" -e sh -c "$SCRIPTS_DIR/hyprconf.sh --update" &
    else
        x-terminal-emulator -e sh -c "$SCRIPTS_DIR/hyprconf.sh --update" 2>/dev/null &
    fi
}

# ── Daemon Mode (Checks every 6h in background) ───────────────────────────────
run_daemon() {
    # Migrate legacy state if present
    if [[ ! -f "$STATE_FILE" && -f "$HOME/.cache/hyprconf/update_state.json" ]]; then
        mv "$HOME/.cache/hyprconf/update_state.json" "$STATE_FILE" 2>/dev/null || true
        rm -rf "$HOME/.cache/hyprconf" 2>/dev/null || true
    fi

    # Ensure only a single watchdog daemon instance runs
    exec 200>"$LOCK_FILE"
    if ! flock -n 200; then
        echo "[hyprconf-daemon] Another daemon instance is already active. Exiting."
        exit 0
    fi

    echo "[hyprconf-daemon] Background updater started. Checking every 6h."

    while true; do
        local now
        now=$(date +%s)

        local last_check=0
        local last_notified=""

        if [[ -f "$STATE_FILE" ]]; then
            last_check=$(jq -r '.last_check // 0' "$STATE_FILE" 2>/dev/null || echo 0)
            last_notified=$(jq -r '.last_notified // empty' "$STATE_FILE" 2>/dev/null || echo "")
        fi

        # Check if 6 hours (21600 seconds) have elapsed since last check (or first run)
        if (( now - last_check >= CHECK_INTERVAL_SECONDS || last_check == 0 )); then
            local check_res
            check_res=$(check_remote_json 2>/dev/null || echo '{"has_update":false}')
            local has_upd
            has_upd=$(echo "$check_res" | jq -r '.has_update // false' 2>/dev/null || echo "false")
            local rem_ver
            rem_ver=$(echo "$check_res" | jq -r '.remote // empty' 2>/dev/null || echo "")
            local loc_ver
            loc_ver=$(echo "$check_res" | jq -r '.local // "v1.0.0"' 2>/dev/null || echo "v1.0.0")

            if [[ "$has_upd" == "true" && -n "$rem_ver" ]]; then
                # Only notify if we haven'\''t already notified for this exact version recently
                if [[ "$last_notified" != "$rem_ver" ]]; then
                    send_notification "$rem_ver" "$loc_ver"
                    last_notified="$rem_ver"
                fi
            fi

            # Persist state to cache
            cat <<EOF > "$STATE_FILE"
{
  "last_check": $now,
  "last_notified": "$last_notified",
  "local_version": "$loc_ver",
  "remote_version": "$rem_ver",
  "has_update": $has_upd
}
EOF
        fi

        # Sleep in 60s increments to gracefully handle system wake/sleep/hibernation
        sleep 60
    done
}

# ── Interactive Update Execution ──────────────────────────────────────────────
do_update() {
    clear
    local local_ver
    local_ver="$(get_local_version)"

    if command -v gum &>/dev/null; then
        gum style \
            --border rounded \
            --border-foreground "$primary" \
            --foreground "$primary" \
            --align center \
            --width 54 \
            --margin "1" \
            --padding "1" \
"   __ __                            ___
  / // /_ _____  ___________  ___  / _/
 / _  / // / _ \/ __/ __/ _ \/ _ \/ _/ 
/_//_/\_, / .__/_/ /_/  \___/_//_/_/   
     /___/_/                           
      Hyprconf System Update Manager
             Current: ${local_ver}"
    else
        echo "=================================================="
        echo "           Hyprconf Update Manager"
        echo "           Current Version: ${local_ver}"
        echo "=================================================="
    fi

    echo -e "\n:: Checking for new updates from ${REPO_URL}..."

    local check_res
    check_res="$(check_remote_json 2>/dev/null || echo '{"status":"error","has_update":false}')"

    local rem_ver
    rem_ver="$(echo "$check_res" | jq -r '.remote // empty' 2>/dev/null || echo "")"
    local has_upd
    has_upd="$(echo "$check_res" | jq -r '.has_update // false' 2>/dev/null || echo "false")"

    local target_ver=""
    local download_url=""

    if [[ "$has_upd" == "true" && -n "$rem_ver" ]]; then
        echo -e ":: New version available: \033[1;32m${rem_ver}\033[0m (installed: ${local_ver})\n"
        target_ver="$rem_ver"
        download_url="${REPO_URL}/archive/refs/tags/${target_ver}.zip"

        if command -v gum &>/dev/null; then
            gum confirm "Would you like to update your Hyprconf to ${target_ver}?" \
                --affirmative "Yes, update now!" \
                --negative "Cancel" \
                --selected.background "$primary" \
                --selected.foreground "$on_secondary" \
                --unselected.background "$surface" \
                --unselected.foreground "$foreground" || {
                    echo -e "\n:: Update cancelled by user."
                    exit 0
                }
        else
            read -rp "Would you like to update to ${target_ver}? [Y/n] " choice
            [[ "$choice" =~ ^[Nn] ]] && { echo ":: Update cancelled."; exit 0; }
        fi
    else
        echo -e ":: You are currently on the latest version (\033[1;34m${local_ver}\033[0m).\n"
        target_ver="${local_ver}"
        download_url="${REPO_URL}/archive/refs/heads/main.zip"

        if command -v gum &>/dev/null; then
            gum confirm "No newer release found. Reinstall/reapply current configuration from GitHub?" \
                --affirmative "Reapply configuration" \
                --negative "Exit" \
                --selected.background "$primary" \
                --selected.foreground "$on_secondary" \
                --unselected.background "$surface" \
                --unselected.foreground "$foreground" || {
                    echo -e "\n:: Up to date. Exiting."
                    exit 0
                }
        else
            read -rp "Reapply current configuration from GitHub? [y/N] " choice
            [[ ! "$choice" =~ ^[Yy] ]] && { echo ":: Exiting."; exit 0; }
        fi
    fi

    # Prepare download & extraction directory in /tmp
    local update_root="${TMPDIR:-/tmp}/hyprconf_update_$$"
    local zip_file="${TMPDIR:-/tmp}/hyprconf_update_$$.zip"

    rm -rf "$update_root" "$zip_file"
    mkdir -p "$update_root"

    echo -e "\n:: Downloading package from GitHub..."
    if command -v gum &>/dev/null; then
        gum spin --spinner dot --title "Downloading update..." -- \
            curl -f -L "$download_url" -o "$zip_file"
    else
        curl -f -L "$download_url" -o "$zip_file"
    fi

    if [[ ! -s "$zip_file" ]]; then
        # Fallback to main branch archive if tag zip download was not found
        echo -e "!! Tag archive not found. Falling back to default main branch..."
        curl -f -L "${REPO_URL}/archive/refs/heads/main.zip" -o "$zip_file" || {
            echo -e "\n!! Failed to download repository. Please check your internet connection."
            exit 1
        }
    fi

    echo -e ":: Extracting archive..."
    unzip -q "$zip_file" -d "$update_root"
    rm -f "$zip_file"

    local src_extracted
    src_extracted="$(find "$update_root" -mindepth 1 -maxdepth 1 -type d | head -n 1)"

    if [[ -z "$src_extracted" || ! -f "$src_extracted/setup.sh" ]]; then
        echo -e "!! Malformed update package (setup.sh missing). Aborting update."
        rm -rf "$update_root" "$zip_file"
        exit 1
    fi

    # Record the new version tag in the update tree before running setup
    if [[ -n "$target_ver" ]]; then
        echo "$target_ver" > "$src_extracted/.version"
    fi

    echo -e ":: Running setup and applying updates..."
    chmod +x "$src_extracted/setup.sh"
    (
        cd "$src_extracted"
        ./setup.sh
    )

    # Save active version locally
    if [[ -n "$target_ver" ]]; then
        echo "$target_ver" > "$VERSION_FILE"
    fi

    rm -rf "$update_root" "$zip_file"

    echo -e "\n\033[1;32m:: Successfully updated Hyprconf to ${target_ver}!\033[0m\n"

    # Send completion notification
    if command -v notify-send &>/dev/null; then
        local icon="$ICON_FILE"
        [[ -f "$icon" ]] || icon="$FALLBACK_ICON"
        notify-send -a "Hyprconf Updater" -i "$icon" "Hyprconf Updated" "Successfully updated to version ${target_ver}." 2>/dev/null || true
    fi

    if command -v hyprctl &>/dev/null; then
        hyprctl reload 2>/dev/null || true
    fi
}

# ── Argument Router ────────────────────────────────────────────────────────────
case "${1:-}" in
    --daemon|-d|--bg)
        run_daemon
        ;;
    --check|-c)
        check_res="$(check_remote_json)"
        echo "$check_res"
        exit $?
        ;;
    --version|-v)
        get_local_version
        ;;
    --notify-test)
        loc="$(get_local_version)"
        send_notification "v1.1.0" "$loc"
        ;;
    --hyprconf)
        launch_terminal_updater
        ;;
    --update|-u|"")
        do_update
        ;;
    --help|-h)
        cat <<EOF
Usage: hyprconf.sh [OPTIONS]

Options:
  --update, -u       Interactive update with styled terminal UI (default)
  --daemon, -d       Run background update watchdog (checks every 6 hours)
  --check, -c        Check remote GitHub repository for new versions
  --version, -v      Print current installed configuration version
  --notify-test      Trigger a test update desktop notification
  --hyprconf         Launch interactive updater inside Kitty terminal
  --help, -h         Show this help message
EOF
        ;;
    *)
        echo "Unknown option: $1"
        echo "Run '$0 --help' for usage."
        exit 1
        ;;
esac
