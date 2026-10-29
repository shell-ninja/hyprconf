#!/usr/bin/env bash
# test-battery.sh — Helper to test battery indicator across all percentage & color stages
# Stages:
#   100-70%  = Green (Clean fill, no bolt)
#   30-69%   = Blue/Cyan (Clean fill, no bolt)
#   15-29%   = Yellow (Clean fill, no bolt)
#   Below 15 = Red (Critical alert warning pulse, no bolt)
#   Charging = Emerald Green (Voltage bolt inside battery + glowing pulse)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BAT_PY="$SCRIPT_DIR/../py/island-battery.py"

ARG="$1"
VAL="$2"

# If first argument is a number (e.g. ./test-battery.sh 85)
if [[ "$ARG" =~ ^[0-9]+$ ]]; then
    python3 "$BAT_PY" --mock-discharging "$ARG"
elif [[ "$ARG" == "green" ]]; then
    python3 "$BAT_PY" --mock-discharging "${VAL:-85}"
elif [[ "$ARG" == "cyan" || "$ARG" == "blue" ]]; then
    python3 "$BAT_PY" --mock-discharging "${VAL:-50}"
elif [[ "$ARG" == "yellow" ]]; then
    python3 "$BAT_PY" --mock-discharging "${VAL:-22}"
elif [[ "$ARG" == "red" || "$ARG" == "critical" ]]; then
    python3 "$BAT_PY" --mock-critical "${VAL:-10}"
elif [[ "$ARG" == "charging" || "$ARG" == "charge" || "$ARG" == "-c" ]]; then
    python3 "$BAT_PY" --mock-charging "${VAL:-88}"
elif [[ "$ARG" == "discharging" || "$ARG" == "discharge" || "$ARG" == "-d" ]]; then
    python3 "$BAT_PY" --mock-discharging "${VAL:-50}"
elif [[ "$ARG" == "off" || "$ARG" == "clear" || "$ARG" == "clean" || "$ARG" == "-x" ]]; then
    python3 "$BAT_PY" --mock-clear
else
    echo "Usage: test-battery.sh [charging | green | cyan | yellow | red | off | <number 0-100>]"
    echo ""
    echo "Examples:"
    echo "  test-battery.sh charging 88   # Emerald green, voltage bolt, charging pulse"
    echo "  test-battery.sh 85            # 100-70%: Green, proportional fill, no bolt"
    echo "  test-battery.sh 50            # 30-69%: Blue/Cyan, proportional fill, no bolt"
    echo "  test-battery.sh 22            # 15-29%: Yellow, proportional fill, no bolt"
    echo "  test-battery.sh 10            # Below 15%: Red, critical alert pulse, no bolt"
    echo "  test-battery.sh off           # Clear mock and return to real desktop mode"
    exit 1
fi

# Restart the island so change renders immediately
bash "$SCRIPT_DIR/qs-island.sh" --restart >/dev/null 2>&1 &
