#!/usr/bin/env bash

set -euo pipefail

# --------------------------------------------------
# Configuration
# --------------------------------------------------

CACHE_DIR="$HOME/.config/hypr/.cache"
CACHE_FILE="$CACHE_DIR/.nightlight"

DEFAULT_TEMP=6500
NIGHT_TEMP=4000

EVENING_START=$((21 * 60))      # 21:00
EVENING_END=$((21 * 60 + 30))   # 21:30

MORNING_START=$((6 * 60))       # 06:00
MORNING_END=$((6 * 60 + 30))    # 06:30

mkdir -p "$CACHE_DIR"

# --------------------------------------------------
# Convert current time to minutes since midnight
# --------------------------------------------------

current_minutes() {
    local h m
    h=$(date +%H)
    m=$(date +%M)
    echo $((10#$h * 60 + 10#$m))
}

# --------------------------------------------------
# Calculate desired temperature
# --------------------------------------------------

compute_temp() {

    local now
    now=$(current_minutes)

    # Evening transition
    if (( now >= EVENING_START && now < EVENING_END )); then

        local elapsed=$((now - EVENING_START))
        local total=$((EVENING_END - EVENING_START))

        awk -v e="$elapsed" \
            -v t="$total" \
            -v d="$DEFAULT_TEMP" \
            -v n="$NIGHT_TEMP" \
            'BEGIN{
                printf "%.0f", d - ((d-n)*e/t)
            }'
        return
    fi

    # Morning transition
    if (( now >= MORNING_START && now < MORNING_END )); then

        local elapsed=$((now - MORNING_START))
        local total=$((MORNING_END - MORNING_START))

        awk -v e="$elapsed" \
            -v t="$total" \
            -v d="$DEFAULT_TEMP" \
            -v n="$NIGHT_TEMP" \
            'BEGIN{
                printf "%.0f", n + ((d-n)*e/t)
            }'
        return
    fi

    # Night
    if (( now >= EVENING_END || now < MORNING_START )); then
        echo "$NIGHT_TEMP"
    else
        echo "$DEFAULT_TEMP"
    fi
}

# --------------------------------------------------
# Main
# --------------------------------------------------

command -v hyprsunset >/dev/null || exit 0

TARGET=$(compute_temp)

LAST=""

if [[ -f "$CACHE_FILE" ]]; then
    LAST=$(<"$CACHE_FILE")
fi

# Nothing changed -> don't restart hyprsunset
if [[ "$LAST" == "$TARGET" ]] && pgrep -x hyprsunset >/dev/null; then
    printf "%sK\n" "$TARGET"
    exit 0
fi

# Restart only when necessary
pkill -x hyprsunset 2>/dev/null || true

# Give Hyprland a moment to release the CTM manager
sleep 0.2

nohup hyprsunset -t "$TARGET" >/dev/null 2>&1 &

echo "$TARGET" > "$CACHE_FILE"

printf "%sK\n" "$TARGET"
