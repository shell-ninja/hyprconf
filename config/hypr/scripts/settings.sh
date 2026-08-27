#!/usr/bin/env bash
# =============================================================================
#  hypr-settings.sh — Interactive Hyprland settings tuner
#  Compatible with: Hyprland post-Lua-migration configs
#  Depends on: gum, sed, tput
#  Author: Shell Ninja
# =============================================================================

set -euo pipefail

# ─── Dependency guard ────────────────────────────────────────────────────────
_require() {
    local missing=()
    for cmd in "$@"; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if (( ${#missing[@]} > 0 )); then
        printf "\n  [!] Missing required tools: %s\n" "${missing[*]}" >&2
        printf "      Install with: sudo pacman -S %s\n\n" "${missing[*]}" >&2
        exit 1
    fi
}
_require gum sed tput

# ─── Config file paths ───────────────────────────────────────────────────────
HYPR_LUA="$HOME/.config/hypr/configs/configs.lua"
ROFI_VARS="$HOME/.config/rofi/rofi-vars.rasi"
KITTY_CONF="$HOME/.config/kitty/kitty.conf"
GTK3_CSS="$HOME/.config/gtk-3.0/gtk.css"
GTK4_CSS="$HOME/.config/gtk-4.0/gtk.css"

BACKUP_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/hypr-settings/backups"

# ─── Colour palette ──────────────────────────────────────────────────────────
C_ACCENT="#aab0c3"
C_OK="#a6e3a1"
C_WARN="#f9e2af"
C_ERR="#f38ba8"
C_DIM="#585b70"

# ─── Collected values (populated during input phase) ─────────────────────────
declare -A PENDING   # setting-key → value(s), pipe-separated for multi-value

# ─── Helpers ─────────────────────────────────────────────────────────────────

_status() {
    local tag="$1" colour="$2" msg="$3"
    gum style --foreground "$colour" "  [ $tag ]  $msg"
}

_backup() {
    local src="$1"
    [[ -f "$src" ]] || return 0
    local stamp; stamp=$(date +%Y%m%d-%H%M%S)
    local dest="$BACKUP_DIR/$(basename "$src").$stamp.bak"
    mkdir -p "$BACKUP_DIR"
    cp "$src" "$dest"
}

_assert_file() {
    local f="$1" label="$2"
    if [[ ! -f "$f" ]]; then
        _status "!!" "$C_ERR" "$label not found: $f  — skipping."
        return 1
    fi
}

# Lua-aware sed: handles bare, dot-access, and local-var assignment styles
_lua_set() {
    local file="$1" key="$2" value="$3"
    sed -i -E "s|^(\s*${key}\s*=\s*)[0-9]+(\.[0-9]+)?|\1${value}|g"              "$file"
    sed -i -E "s|^(\s*[a-zA-Z_]+\.${key}\s*=\s*)[0-9]+(\.[0-9]+)?|\1${value}|g" "$file"
    sed -i -E "s|^(\s*local ${key}\s*=\s*)[0-9]+(\.[0-9]+)?|\1${value}|g"        "$file"
}

_input_int() {
    local prompt="$1" val
    while true; do
        val=$(gum input \
            --placeholder "$prompt" \
            --cursor.foreground "$C_ACCENT" \
            --prompt.foreground "$C_ACCENT" \
            --prompt "  > ")
        [[ "$val" =~ ^[0-9]+$ ]] && { echo "$val"; return 0; }
        _status "!!" "$C_ERR" "Integer required — got: '${val}'"
    done
}

_input_float() {
    local prompt="$1" val
    while true; do
        val=$(gum input \
            --placeholder "$prompt" \
            --cursor.foreground "$C_ACCENT" \
            --prompt.foreground "$C_ACCENT" \
            --prompt "  > ")
        [[ "$val" =~ ^(0(\.[0-9]+)?|1(\.0+)?)$ ]] && { echo "$val"; return 0; }
        _status "!!" "$C_ERR" "Float between 0.0–1.0 required — got: '${val}'"
    done
}

# ─── ASCII banner ─────────────────────────────────────────────────────────────
_banner() {
    local cols; cols=$(tput cols)
    local art
    art=$(cat << 'ART'
            ╔═╗┬ ┬┌─┐┌┐┌┌─┐┌─┐  ╔═╗┌─┐┌┬┐┌┬┐┬┌┐┌┌─┐┌─┐
            ║  ├─┤├─┤││││ ┬├┤   ╚═╗├┤  │  │ │││││ ┬└─┐
────────────╚═╝┴ ┴┴ ┴┘└┘└─┘└─┘  ╚═╝└─┘ ┴  ┴ ┴┘└┘└─┘└─┘────────────
ART
)
    local max_w=0
    while IFS= read -r line; do
        (( ${#line} > max_w )) && max_w=${#line}
    done <<< "$art"

    local pad=0
    (( cols > max_w )) && pad=$(( (cols - max_w) / 2 ))
    local spaces; spaces=$(printf '%*s' "$pad" '')

    while IFS= read -r line; do
        printf "%s%s\n" "$spaces" "$line"
    done <<< "$art"
    echo
}

# ─── INPUT PHASE — collect values only, no file writes ───────────────────────

_collect_border_size() {
    gum style --foreground "$C_ACCENT" "  Border width (pixels)"
    PENDING[border_size]=$(_input_int "e.g. 2")
}

_collect_roundness() {
    gum style --foreground "$C_ACCENT" "  Corner rounding (pixels)"
    PENDING[roundness]=$(_input_int "e.g. 8")
}

_collect_inner_gap() {
    gum style --foreground "$C_ACCENT" "  Inner gap between tiled windows (pixels)"
    PENDING[inner_gap]=$(_input_int "e.g. 4")
}

_collect_outer_gap() {
    gum style --foreground "$C_ACCENT" "  Outer gap — screen edge padding (pixels)"
    PENDING[outer_gap]=$(_input_int "e.g. 8")
}

_collect_blur() {
    gum style --foreground "$C_ACCENT" "  Blur — size controls spread, passes controls depth"
    gum style --foreground "$C_DIM"    "  Tip: size 2–8, passes 2–4 is a good starting range"
    local bsize bpass
    bsize=$(_input_int "Blur size (e.g. 4)")
    bpass=$(_input_int "Blur passes (e.g. 3)")
    PENDING[blur]="${bsize}|${bpass}"   # pipe-separated pair
}

_collect_opacity() {
    gum style --foreground "$C_ACCENT" "  Window opacity (0.0 = fully transparent, 1.0 = opaque)"
    gum style --foreground "$C_DIM"    "  Applied to: Hyprland active/inactive, Kitty bg, GTK3, GTK4"
    echo
    gum style --foreground "$C_WARN" "  Active window opacity:"
    local act; act=$(_input_float "0.0–1.0  e.g. 0.95")
    gum style --foreground "$C_WARN" "  Inactive window opacity:"
    local deact; deact=$(_input_float "0.0–1.0  e.g. 0.75")
    PENDING[opacity]="${act}|${deact}"
}

_collect_shadow() {
    gum style --foreground "$C_ACCENT" "  Shadow range (0 = no shadow)"
    PENDING[shadow]=$(_input_int "e.g. 12")
}

# ─── APPLY PHASE — write all collected values to disk ────────────────────────

_apply_all() {
    # Back up every file that will be touched — once, before any writes
    local need_hypr=0 need_rofi=0 need_kitty=0 need_gtk=0
    [[ -v PENDING[border_size] || -v PENDING[roundness] || -v PENDING[inner_gap] \
        || -v PENDING[outer_gap] || -v PENDING[blur] || -v PENDING[opacity] \
        || -v PENDING[shadow] ]] && need_hypr=1
    [[ -v PENDING[border_size] || -v PENDING[roundness] ]] && need_rofi=1
    [[ -v PENDING[opacity] ]] && need_kitty=1 need_gtk=1

    (( need_hypr  )) && _backup "$HYPR_LUA"
    (( need_rofi  )) && _backup "$ROFI_VARS"
    (( need_kitty )) && _backup "$KITTY_CONF"
    (( need_gtk   )) && _backup "$GTK3_CSS" && _backup "$GTK4_CSS"

    # ── border size ──────────────────────────────────────────────────────────
    if [[ -v PENDING[border_size] ]]; then
        local val="${PENDING[border_size]}"
        _assert_file "$HYPR_LUA" "Hyprland Lua config" && {
            _lua_set "$HYPR_LUA" "border" "$val"
            sed -i -E "s|^(border\s*=\s*)[0-9]+|\1${val}|g" "$HYPR_LUA"
        }
        [[ -f "$ROFI_VARS" ]] && sed -i "s|border-size:.*|border-size: ${val}px;|g" "$ROFI_VARS"
        _status "ok" "$C_OK" "border-size      → $val"
    fi

    # ── roundness ────────────────────────────────────────────────────────────
    if [[ -v PENDING[roundness] ]]; then
        local val="${PENDING[roundness]}"
        _assert_file "$HYPR_LUA" "Hyprland Lua config" && _lua_set "$HYPR_LUA" "rounding" "$val"
        if [[ -f "$ROFI_VARS" ]]; then
            sed -i "s|radius:.*|radius: ${val}px;|g" "$ROFI_VARS"
            sed -i "s|radius-second:.*|radius-second: $(( val / 2 ))px;|g" "$ROFI_VARS"
        fi
        _status "ok" "$C_OK" "rounding         → $val"
    fi

    # ── inner gap ────────────────────────────────────────────────────────────
    if [[ -v PENDING[inner_gap] ]]; then
        local val="${PENDING[inner_gap]}"
        _assert_file "$HYPR_LUA" "Hyprland Lua config" && _lua_set "$HYPR_LUA" "inner_gap" "$val"
        _status "ok" "$C_OK" "inner-gap        → $val"
    fi

    # ── outer gap ────────────────────────────────────────────────────────────
    if [[ -v PENDING[outer_gap] ]]; then
        local val="${PENDING[outer_gap]}"
        _assert_file "$HYPR_LUA" "Hyprland Lua config" && _lua_set "$HYPR_LUA" "outer_gap" "$val"
        _status "ok" "$C_OK" "outer-gap        → $val"
    fi

    # ── blur ─────────────────────────────────────────────────────────────────
    if [[ -v PENDING[blur] ]]; then
        local bsize="${PENDING[blur]%%|*}"
        local bpass="${PENDING[blur]##*|}"
        _assert_file "$HYPR_LUA" "Hyprland Lua config" && {
            _lua_set "$HYPR_LUA" "blur_size"   "$bsize"
            _lua_set "$HYPR_LUA" "blur_passes" "$bpass"
            sed -i -E "s|^(\s*size\s*=\s*)[0-9]+|\1${bsize}|g"   "$HYPR_LUA"
            sed -i -E "s|^(\s*passes\s*=\s*)[0-9]+|\1${bpass}|g" "$HYPR_LUA"
        }
        _status "ok" "$C_OK" "blur             → size:$bsize  passes:$bpass"
    fi

    # ── opacity ──────────────────────────────────────────────────────────────
    if [[ -v PENDING[opacity] ]]; then
        local act="${PENDING[opacity]%%|*}"
        local deact="${PENDING[opacity]##*|}"
        _assert_file "$HYPR_LUA" "Hyprland Lua config" && {
            _lua_set "$HYPR_LUA" "opacity_act"   "$act"
            _lua_set "$HYPR_LUA" "opacity_deact" "$deact"
            sed -i -E "s|^(\s*active_opacity\s*=\s*)[0-9]+(\.[0-9]+)?|\1${act}|g"    "$HYPR_LUA"
            sed -i -E "s|^(\s*inactive_opacity\s*=\s*)[0-9]+(\.[0-9]+)?|\1${deact}|g" "$HYPR_LUA"
        }
        if [[ -f "$KITTY_CONF" ]]; then
            sed -i -E "s|^(background_opacity\s+)[0-9]+(\.[0-9]+)?|\1${act}|g" "$KITTY_CONF"
            pkill -SIGUSR1 kitty 2>/dev/null || true
        fi
        if [[ -f "$GTK3_CSS" ]]; then
            sed -i -E \
                "s|rgba\(([0-9]+),\s*([0-9]+),\s*([0-9]+),\s*[0-9.]+\)|rgba(\1, \2, \3, ${act})|g" \
                "$GTK3_CSS"
        fi
        if [[ -f "$GTK4_CSS" ]]; then
            sed -i -E \
                "s|alpha\(@[a-zA-Z]+,\s*[0-9.]+\)|alpha(@background, ${act})|g" \
                "$GTK4_CSS"
        fi
        _status "ok" "$C_OK" "opacity-active   → $act"
        _status "ok" "$C_OK" "opacity-inactive → $deact"
    fi

    # ── shadow ───────────────────────────────────────────────────────────────
    if [[ -v PENDING[shadow] ]]; then
        local val="${PENDING[shadow]}"
        _assert_file "$HYPR_LUA" "Hyprland Lua config" && {
            _lua_set "$HYPR_LUA" "shadow_range" "$val"
            sed -i -E "s|^(\s*range\s*=\s*)[0-9]+(\.[0-9]+)?|\1${val}|g" "$HYPR_LUA"
        }
        _status "ok" "$C_OK" "shadow-range     → $val"
    fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    clear
    _banner

    gum style \
        --foreground "$C_DIM" \
        "  x to toggle  ·  Enter to confirm  ·  Esc / 'cancel' to exit"
    echo

    local choices
    choices=$(gum choose \
        --header "  Select settings to change:" \
        --header.foreground "$C_ACCENT" \
        --no-limit \
        --cursor.foreground "$C_ACCENT" \
        "border size" \
        "roundness" \
        "inner gap" \
        "outer gap" \
        "blur" \
        "opacity" \
        "shadow" \
        "cancel" \
    ) || { echo; _status ".." "$C_DIM" "Aborted."; exit 0; }

    [[ -z "$choices" ]]                    && { _status ".." "$C_DIM" "Nothing selected."; exit 0; }
    grep -qx "cancel" <<< "$choices"       && { _status ".." "$C_DIM" "Cancelled.";        exit 0; }

    # ── INPUT PHASE: walk selections in fixed order, collect all values ───────
    local ordered=(
        "border size"
        "roundness"
        "inner gap"
        "outer gap"
        "blur"
        "opacity"
        "shadow"
    )

    for setting in "${ordered[@]}"; do
        grep -qxF "$setting" <<< "$choices" || continue
        clear
        _banner
        gum style \
            --foreground "$C_ACCENT" \
            --bold \
            "  ── $(tr '[:lower:]' '[:upper:]' <<< "${setting:0:1}")${setting:1} ──"
        echo
        case "$setting" in
            "border size") _collect_border_size ;;
            "roundness")   _collect_roundness   ;;
            "inner gap")   _collect_inner_gap   ;;
            "outer gap")   _collect_outer_gap   ;;
            "blur")        _collect_blur        ;;
            "opacity")     _collect_opacity     ;;
            "shadow")      _collect_shadow      ;;
        esac
        echo
    done

    # ── APPLY PHASE: write everything to disk at once ─────────────────────────
    clear
    _banner
    gum style --foreground "$C_ACCENT" --bold "  Applying changes..."
    echo
    _apply_all
    echo
    _status "ok" "$C_OK" "All done. Settings written to disk."
    echo
}

main "$@"
