#!/usr/bin/env bash
# ==============================================================================
# ide.sh — Detect and launch installed IDE(s)
# - If one IDE is found, launch it directly.
# - If multiple are found, prompt the user with gum to choose one.
# - Bound to Super + C in Hyprland.
# ==============================================================================

set -eo pipefail

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$scripts_dir/colors.sh" ]] && source "$scripts_dir/colors.sh"

primary="${primary:-#ac67e4}"
secondary="${secondary:-#d65cd1}"
surface="${surface:-#201628}"
foreground="${foreground:-#f2f2f3}"

# Check if called in interactive terminal mode
is_interactive=false
if [[ "$1" == "--interactive" ]]; then
    is_interactive=true
    shift
fi

# Supported IDE definitions: "Display Name:binary1,binary2,..."
IDE_DEFS=(
    "VS Code:code,code-insiders,code-oss"
    "VSCodium:codium,vscodium"
    "Antigravity:antigravity-ide,antigravity"
    "Cursor:cursor"
    "Zed:zed,zed-editor,zedit"
    "Windsurf:windsurf"
    "Sublime Text:subl,sublime_text"
    "IntelliJ IDEA:idea"
    "PyCharm:pycharm"
    "WebStorm:webstorm"
    "CLion:clion"
    "Rider:rider"
    "RustRover:rustrover"
    "GoLand:goland"
    "DataGrip:datagrip"
    "PhpStorm:phpstorm"
    "Android Studio:android-studio"
    "Neovide:neovide"
)

declare -A NAME_TO_CMD=()
declare -a INSTALLED_NAMES=()

for entry in "${IDE_DEFS[@]}"; do
    name="${entry%%:*}"
    cmds="${entry#*:}"
    IFS="," read -ra cmd_list <<< "$cmds"
    for cmd in "${cmd_list[@]}"; do
        if command -v "$cmd" &>/dev/null; then
            INSTALLED_NAMES+=("$name")
            NAME_TO_CMD["$name"]="$cmd"
            break
        fi
    done
done

ide_count="${#INSTALLED_NAMES[@]}"

# Detached launcher that survives terminal exit
launch_app() {
    local cmd="$1"
    shift
    local args=("$@")

    # If running inside Hyprland with Lua dispatcher available
    if command -v hyprctl &>/dev/null && [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
        local full_cmd="$cmd"
        if [[ ${#args[@]} -gt 0 ]]; then
            full_cmd="$cmd ${args[*]}"
        fi
        local escaped_cmd="${full_cmd//\\/\\\\}"
        escaped_cmd="${escaped_cmd//\"/\\\"}"
        hyprctl dispatch "hl.dsp.exec_cmd(\"$escaped_cmd\")" >/dev/null 2>&1
        return $?
    fi

    # Fallback to systemd-run if available (uwsm / systemd session)
    if command -v systemd-run &>/dev/null; then
        systemd-run --user --slice=app.slice "$cmd" "${args[@]}" >/dev/null 2>&1
        return $?
    fi

    # Fallback to nohup
    nohup "$cmd" "${args[@]}" >/dev/null 2>&1 &
}

if [[ "$ide_count" -eq 0 ]]; then
    if command -v notify-send &>/dev/null; then
        notify-send -i dialog-error "No IDE Found" "No supported IDE (VS Code, VSCodium, Antigravity, etc.) was found."
    else
        echo "No supported IDE found." >&2
    fi
    exit 1
fi

if [[ "$ide_count" -eq 1 ]]; then
    target_cmd="${NAME_TO_CMD[${INSTALLED_NAMES[0]}]}"
    notify-send -i "$target_cmd" "Opening IDE" "Starting ${INSTALLED_NAMES[0]}..." 2>/dev/null || true
    launch_app "$target_cmd" "$@"
    exit 0
fi

# If more than one IDE is installed and not in a terminal, launch kitty
if [[ ! -t 0 && "$is_interactive" != true ]]; then
    terminal="kitty"
    if ! command -v "$terminal" &>/dev/null; then
        terminal="x-terminal-emulator"
    fi
    exec "$terminal" --title ide sh -c "\"$scripts_dir/ide.sh\" --interactive"
fi

# Interactive mode using gum
choice=""
if command -v gum &>/dev/null; then
    term_width=$(tput cols 2>/dev/null || echo 60)
    box_width=36
    if (( term_width > box_width )); then
        left_margin=$(( (term_width - box_width) / 2 ))
    else
        left_margin=0
        box_width=$term_width
    fi

    cursor_indent=""
    if (( left_margin >= 4 )); then
        cursor_indent=$(printf "%*s" "$(( left_margin + 6 ))" "")
    fi

    gum style \
        --foreground "$primary" --border-foreground "$secondary" --border rounded \
        --align center --width "$box_width" --margin "1 0 1 $left_margin" \
"    ________  ______
    /  _/ __ \/ ____/
   / // / / / __/   
 _/ // /_/ / /___   
/___/_____/_____/  

Select IDE to Launch"

    choice=$(gum choose \
        --header="" \
        --cursor="${cursor_indent}➜ " \
        --cursor.foreground="$primary" \
        --item.foreground="$foreground" \
        --selected.foreground="$primary" \
        --height=10 \
        "${INSTALLED_NAMES[@]}") || true
else
    echo "Select an IDE:"
    select c in "${INSTALLED_NAMES[@]}"; do
        choice="$c"
        [[ -n "$choice" ]] && break
    done
fi

if [[ -n "$choice" && -n "${NAME_TO_CMD[$choice]}" ]]; then
    target_cmd="${NAME_TO_CMD[$choice]}"
    notify-send -i "$target_cmd" "Opening IDE" "Starting $choice..." 2>/dev/null || true
    launch_app "$target_cmd" "$@"
fi
