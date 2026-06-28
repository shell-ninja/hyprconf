#!/bin/bash

# Paths and defaults
value_file="$HOME/.config/hypr/.cache/.nightlight"
default=6500
night_temp=4000

mkdir -p "$(dirname "$value_file")"

compute_temp() {
    local now=$(date +%H%M)
    local now_int=$((10#$now))   # force base‑10 to avoid leading zero issues

    # Evening transition: 21:00 – 21:29
    if (( now_int >= 2100 && now_int < 2130 )); then
        local elapsed=$(( now_int - 2100 ))
        local total=$(( 2130 - 2100 ))
        local frac=$(echo "$elapsed / $total" | bc -l)
        local temp=$(echo "$default - ($default - $night_temp) * $frac" | bc -l)
        printf "%.0f" "$temp"
        return
    fi

    # Morning transition: 06:00 – 06:29
    if (( now_int >= 600 && now_int < 630 )); then
        local elapsed=$(( now_int - 600 ))
        local total=$(( 630 - 600 ))
        local frac=$(echo "$elapsed / $total" | bc -l)
        local temp=$(echo "$night_temp + ($default - $night_temp) * $frac" | bc -l)
        printf "%.0f" "$temp"
        return
    fi

    # Night: 21:30 – 05:59 (crosses midnight)
    if (( now_int >= 2130 || now_int < 600 )); then
        printf "%d" "$night_temp"
    else
        printf "%d" "$default"
    fi
}

if command -v hyprsunset &>/dev/null; then
    target=$(compute_temp)

    # Kill existing instance and start a fresh one
    pkill -x hyprsunset 2>/dev/null
    sleep 0.3   # give the compositor time to release the CTM manager

    hyprsunset -t "$target"
    echo "$target" > "$value_file"

    # Optional: notify-send (disabled by default to avoid spam)
    # notify-send "Nightlight" "Temperature set to ${target}K"
fi

# Print current value for status bars (as in your original script)
printf "${target}K"
