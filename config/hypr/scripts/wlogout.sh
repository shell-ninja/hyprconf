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
# Get the raw float scale (e.g. 1, 1.5, 2) and convert to a fixed *100 integer.
# NOTE: don't strip the decimal point with sed — jq normalizes whole-number
# scales like "1.000000" down to "1", so stripping a nonexistent dot left
# scale=1 instead of 100, blowing up every margin calc by 100x.
scale_raw=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .scale')
scale=$(awk -v s="$scale_raw" 'BEGIN{printf "%d", (s*100)+0.5}')
[ -z "$scale" ] && scale=100

case "$STYLE" in
    *1)
        wlColms=6
        export mgn=$((y_mon * 28 / scale))
        # Hover inset is a fixed fraction of the default inset (always smaller,
        # always safe) rather than an independent percentage — this guarantees
        # hvr < mgn without risking a mismatch between the two.
        export hvr=$((mgn * 80 / 100))
        ;;
    2)
        wlColms=2
        export x_mgn=$((x_mon * 35 / scale))
        export y_mgn=$((y_mon * 25 / scale))
        # Safety clamp: never let a margin exceed the monitor's own dimensions.
        [ "$x_mgn" -gt "$x_mon" ] && x_mgn=$x_mon
        [ "$y_mgn" -gt "$y_mon" ] && y_mgn=$y_mon
        # Hover inset: shrink by 20% of the default inset — enough to visibly
        # grow the button, small enough that it never has to fight the window
        # for space (see win_w/win_h below, which pin the window regardless).
        export x_hvr=$((x_mgn * 80 / 100))
        export y_hvr=$((y_mgn * 80 / 100))
        # Pin the actual window size so it can NEVER auto-resize/recenter
        # between hover states — this is what stops sibling icons from
        # drifting when one button's margin changes. Sized generously above
        # both the mgn- and hvr-driven footprints, with a small buffer.
        export win_w=$((x_mgn * 2 + 40))
        export win_h=$((y_mgn * 2 + 40))
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
    echo "win_w: $win_w | win_h: $win_h"
fi

echo "$wlStyle"
