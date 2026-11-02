#!/usr/bin/env bash
# osd-notify.sh — Unified OSD broadcaster for Quickshell Dynamic Island and Bar

TYPE="${1:-volume}"
VAL="${2:-50}"
LABEL="${3:-}"
ICON="${4:-$TYPE}"
SUB="${5:-}"

# Fallback label if empty
if [[ -z "$LABEL" ]]; then
    if [[ "$TYPE" =~ ^(volume|mic|brightness)$ ]]; then
        LABEL="${VAL}%"
    else
        LABEL="$VAL"
    fi
fi

# Dispatch to Bar daemon if running
qs ipc -c bar call bar showOsd "$TYPE" "$VAL" "$LABEL" "$ICON" "$SUB" >/dev/null 2>&1 &

# Dispatch to Dynamic Island daemon if running
qs ipc -c island call island showOsd "$TYPE" "$VAL" "$LABEL" "$ICON" "$SUB" >/dev/null 2>&1 &
