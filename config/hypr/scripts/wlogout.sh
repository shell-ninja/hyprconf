#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# wlogout.sh — wlogout launcher with monitor-aware layout (clean version)
# ─────────────────────────────────────────────────────────────────────────────

# Toggle: kill if already running
if pgrep -x "wlogout" > /dev/null; then
    pkill -x "wlogout"
    exit 0
fi

CONF_DIR="$HOME/.hyprconf/wlogout"
STYLE="${1:-2}"

wLayout="$CONF_DIR/layout_${STYLE}"
wlTmplt="$CONF_DIR/style_${STYLE}.css"

# Fallback if missing
if [[ ! -f "$wLayout" || ! -f "$wlTmplt" ]]; then
    echo "ERROR: wlogout style $STYLE not found, falling back to style 2"
    STYLE=2
    wLayout="$CONF_DIR/layout_${STYLE}"
    wlTmplt="$CONF_DIR/style_${STYLE}.css"
fi

# ── Monitor resolution (focused) ──────────────────────────────────────────────
MON_JSON=$(hyprctl -j monitors)

x_mon=$(echo "$MON_JSON" | jq -r '.[] | select(.focused==true) | .width' | head -n1)
y_mon=$(echo "$MON_JSON" | jq -r '.[] | select(.focused==true) | .height' | head -n1)

# ── Scaling (better than raw %) ───────────────────────────────────────────────
# scale=$(( y_mon / 1080 ))
scale=$(hyprctl -j monitors | jq '.[] | select (.focused == true) | .scale' | sed 's/\.//')
# [ "$scale" -lt 1 ] && scale=1

case "$STYLE" in
    *1)
        wlColms=6
        export mgn=$((y_mon * 28 / scale))
        export hvr=$((y_mon * 23 / scale))
        ;;
    2)
        wlColms=2
        export x_mgn=$((x_mon * 35 / scale))
        export y_mgn=$((y_mon * 25 / scale))
        export x_hvr=$((x_mon * 32 / scale))
        export y_hvr=$((y_mon * 20 / scale))
        ;;
    *)
        wlColms=2
        ;;
esac

# ── Font size ─────────────────────────────────────────────────────────────────
export fntSize=$((y_mon * 2 / 100))

# ── Border radius from Hyprland ───────────────────────────────────────────────
hypr_border=$(hyprctl getoption "decoration:rounding" 2>/dev/null \
    | awk '/^int:/{print $2}' | head -n1)

hypr_border="${hypr_border:-10}"

export active_rad=$((hypr_border * 5))
export button_rad=$((hypr_border * 8))

# # ── Generate CSS ──────────────────────────────────────────────────────────────
wlStyle="$(cat "$CONF_DIR/colors.css" "$wlTmplt" | envsubst)"

# ── Launch wlogout ────────────────────────────────────────────────────────────
wlogout -b "$wlColms" -c 0 -r 0 -m 0 \
    --layout "$wLayout" \
    --css <(echo "$wlStyle") \
    --protocol layer-shell

# ── Optional debug (enable with DEBUG=1 ./wlogout.sh) ─────────────────────────
if [[ "$DEBUG" == "1" ]]; then
    echo "Resolution: ${x_mon}x${y_mon}"
    echo "Scale: $scale"
    echo "x_mgn: $x_mgn | y_mgn: $y_mgn"
    echo "x_hvr: $x_hvr | y_hvr: $y_hvr"
fi

echo "$wlStyle"
