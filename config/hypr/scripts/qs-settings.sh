#!/usr/bin/env bash
# Launch Quickshell QML Settings (single instance)
pkill -f "qs -c settings" 2>/dev/null
sleep 0.1
exec qs -c settings "$@"
