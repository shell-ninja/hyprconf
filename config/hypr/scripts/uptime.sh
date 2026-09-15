#!/usr/bin/env bash
# ==============================================================================
# PC Uptime Tracker
# Tracks and stores system uptime sessions in a formatted table.
# Location: ~/.config/hypr/.cache/.uptime
# ==============================================================================

set -eo pipefail

# Determine cache and target file paths
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
HYPRCONF_DIR="$HOME/.hyprconf/hypr"

if [[ -d "$CONFIG_DIR/.cache" ]]; then
    CACHE_DIR="$CONFIG_DIR/.cache"
elif [[ -d "$HYPRCONF_DIR/.cache" ]]; then
    CACHE_DIR="$HYPRCONF_DIR/.cache"
else
    CACHE_DIR="$CONFIG_DIR/.cache"
    mkdir -p "$CACHE_DIR"
fi

UPTIME_FILE="$CACHE_DIR/.uptime"
SCRIPT_NAME=$(basename "$0")

# Color formatting for terminal output
if [[ -t 1 ]]; then
    BOLD="\033[1m"
    DIM="\033[2m"
    GREEN="\033[32m"
    CYAN="\033[36m"
    YELLOW="\033[33m"
    BLUE="\033[34m"
    MAGENTA="\033[35m"
    RESET="\033[0m"
else
    BOLD=""
    DIM=""
    GREEN=""
    CYAN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    RESET=""
fi

# Header format
format_header() {
    printf "%-12s %-15s %-16s %s\n" "Date" "StartupTime" "PowerOfftime" "Usage(HOUR)"
}

# Format a single entry row
format_row() {
    local date_val="$1"
    local start_val="$2"
    local end_val="$3"
    local usage_val="$4"
    printf "%-12s %-15s %-16s %s\n" "$date_val" "$start_val" "$end_val" "$usage_val"
}

# Sync historical boots from systemd journal
sync_history() {
    if ! command -v journalctl &>/dev/null; then
        return 0
    fi

    # Read completed boots (index < 0) from journalctl --list-boots
    journalctl --list-boots 2>/dev/null | awk '
    NR > 1 && $1 ~ /^-[0-9]+$/ {
        d1 = $4; t1_str = $5;
        d2 = $8; t2_str = $9;
        if (d1 != "" && t1_str != "" && t2_str != "") {
            d1_fmt = d1; gsub(/-/, " ", d1_fmt);
            t1_fmt = t1_str; gsub(/:/, " ", t1_fmt);
            d2_fmt = d2; gsub(/-/, " ", d2_fmt);
            t2_fmt = t2_str; gsub(/:/, " ", t2_fmt);
            t1 = mktime(d1_fmt " " t1_fmt);
            t2 = mktime(d2_fmt " " t2_fmt);
            diff = t2 - t1;
            if (diff < 0) diff = 0;
            hrs = diff / 3600.0;
            printf "%-12s %-15s %-16s %.2f\n", d1, t1_str, t2_str, hrs;
        }
    }'
}

# Initialize uptime file if not already present
ensure_uptime_file() {
    if [[ ! -f "$UPTIME_FILE" || ! -s "$UPTIME_FILE" ]]; then
        mkdir -p "$CACHE_DIR"
        format_header > "$UPTIME_FILE"
        # Backfill history if available
        sync_history >> "$UPTIME_FILE" || true
    fi
}

# Gather metrics for current running session
get_session_metrics() {
    # Boot timestamp (YYYY-MM-DD HH:MM:SS)
    local boot_str
    boot_str=$(uptime -s 2>/dev/null || who -b 2>/dev/null | awk '{print $3 " " $4}')
    
    BOOT_DATE=$(echo "$boot_str" | awk '{print $1}')
    STARTUP_TIME=$(echo "$boot_str" | awk '{print $2}')
    if [[ "$STARTUP_TIME" =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
        STARTUP_TIME="${STARTUP_TIME}:00"
    fi

    # Current / Poweroff time
    CURRENT_DATE=$(date +%Y-%m-%d)
    POWEROFF_TIME=$(date +%T)

    # Uptime in seconds
    if [[ -r /proc/uptime ]]; then
        UPTIME_SECONDS=$(awk '{print int($1)}' /proc/uptime)
    else
        local now_ts boot_ts
        now_ts=$(date +%s)
        boot_ts=$(date -d "$boot_str" +%s 2>/dev/null || date +%s)
        UPTIME_SECONDS=$(( now_ts - boot_ts ))
    fi

    if (( UPTIME_SECONDS < 0 )); then
        UPTIME_SECONDS=0
    fi

    # Usage in hours (decimal format, 2 decimal places)
    USAGE_HOURS=$(awk -v s="$UPTIME_SECONDS" 'BEGIN {printf "%.2f", s / 3600}')

    # Human-readable breakdown
    HOURS=$(( UPTIME_SECONDS / 3600 ))
    MINUTES=$(( (UPTIME_SECONDS % 3600) / 60 ))
    SECONDS=$(( UPTIME_SECONDS % 60 ))
}

# Record or update current session in .uptime
record_session() {
    ensure_uptime_file
    get_session_metrics

    local row
    row=$(format_row "$BOOT_DATE" "$STARTUP_TIME" "$POWEROFF_TIME" "$USAGE_HOURS")

    # If an entry with this boot date and startup time already exists, update it in place.
    # Otherwise, append a new entry to the table.
    if grep -q "^${BOOT_DATE}[[:space:]]\+${STARTUP_TIME}" "$UPTIME_FILE" 2>/dev/null; then
        awk -v d="$BOOT_DATE" -v s="$STARTUP_TIME" -v r="$row" '
            $1 == d && $2 == s { print r; next }
            { print }
        ' "$UPTIME_FILE" > "${UPTIME_FILE}.tmp" && mv "${UPTIME_FILE}.tmp" "$UPTIME_FILE"
    else
        echo "$row" >> "$UPTIME_FILE"
    fi
}

# Send desktop notification
send_notify() {
    get_session_metrics
    if command -v notify-send &>/dev/null; then
        local msg="PC Uptime: ${USAGE_HOURS}h (${HOURS}h ${MINUTES}m ${SECONDS}s)\nLogged to ~/.config/hypr/.cache/.uptime"
        notify-send -a "Uptime Tracker" -i preferences-system-time "Session Summary" "$msg" 2>/dev/null || true
    fi
}

# Print summary and table to terminal
show_report() {
    local show_all="$1"
    get_session_metrics

    echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "                   ${BOLD}${GREEN}PC UPTIME & USAGE SUMMARY${RESET}"
    echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════════════${RESET}"
    printf "  ${BOLD}%-16s${RESET} : %s\n" "Session Date" "$BOOT_DATE"
    printf "  ${BOLD}%-16s${RESET} : %s\n" "Startup Time" "$STARTUP_TIME"
    printf "  ${BOLD}%-16s${RESET} : %s\n" "PowerOff Time" "$POWEROFF_TIME (now)"
    printf "  ${BOLD}%-16s${RESET} : ${BOLD}${YELLOW}%s hours${RESET} (%dh %dm %ds)\n" "Total Usage" "$USAGE_HOURS" "$HOURS" "$MINUTES" "$SECONDS"
    printf "  ${BOLD}%-16s${RESET} : ${DIM}%s${RESET}\n" "Log File" "$UPTIME_FILE"
    echo -e "${BOLD}${CYAN}──────────────────────────────────────────────────────────────${RESET}"
    echo -e "${BOLD}${MAGENTA}Table (${UPTIME_FILE}):${RESET}"
    echo ""

    if [[ ! -f "$UPTIME_FILE" ]]; then
        echo -e "${DIM}(No log file yet. Run with recording to create.)${RESET}"
        return
    fi

    # Display table header with styling
    local header
    header=$(head -n 1 "$UPTIME_FILE")
    echo -e "${BOLD}${BLUE}${header}${RESET}"
    echo -e "${DIM}------------------------------------------------------------${RESET}"

    # Print rows
    if [[ "$show_all" == "true" ]]; then
        tail -n +2 "$UPTIME_FILE"
    else
        local total_rows
        total_rows=$(tail -n +2 "$UPTIME_FILE" | wc -l)
        if (( total_rows > 15 )); then
            tail -n 15 "$UPTIME_FILE"
            echo -e "${DIM}... (${total_rows} total sessions. Use -a or --all to view all)${RESET}"
        else
            tail -n +2 "$UPTIME_FILE"
        fi
    fi
    echo ""
}

# Help documentation
show_help() {
    cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Tracks system uptime and records session logs in ~/.config/hypr/.cache/.uptime.

Options:
  (no args)            Record current session and display summary + recent table
  -s, --show           Show uptime summary and recent table without updating
  -a, --all            Show uptime summary and ALL table entries
  -r, --record         Record/update current session silently (for hooks/services)
  -n, --notify         Show desktop notification with current uptime
  -p, --poweroff       Record session, notify, and shut down system
  --reboot             Record session, notify, and reboot system
  --sync-history       Rebuild/backfill past boots from system journal
  -h, --help           Show this help message

File Format in ~/.config/hypr/.cache/.uptime:
  Date        StartupTime    PowerOfftime    Usage(HOUR)
EOF
}

# Action dispatch
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -r|--record)
        record_session
        exit 0
        ;;
    -s|--show)
        ensure_uptime_file
        show_report false
        exit 0
        ;;
    -a|--all)
        record_session
        show_report true
        exit 0
        ;;
    -n|--notify)
        record_session
        send_notify
        show_report false
        exit 0
        ;;
    -p|--poweroff|--shutdown)
        record_session
        send_notify
        show_report false
        echo -e "${YELLOW}Initiating system poweroff...${RESET}"
        systemctl poweroff
        exit 0
        ;;
    --reboot)
        record_session
        send_notify
        show_report false
        echo -e "${YELLOW}Initiating system reboot...${RESET}"
        systemctl reboot
        exit 0
        ;;
    --sync-history)
        mkdir -p "$CACHE_DIR"
        format_header > "$UPTIME_FILE"
        sync_history >> "$UPTIME_FILE"
        record_session
        show_report false
        echo -e "${GREEN}Historical boots synchronized into $UPTIME_FILE!${RESET}"
        exit 0
        ;;
    "")
        record_session
        show_report false
        exit 0
        ;;
    *)
        echo "Unknown option: $1" >&2
        echo "Run '$SCRIPT_NAME --help' for usage." >&2
        exit 1
        ;;
esac
