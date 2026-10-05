#!/usr/bin/env bash

browser_cache="$HOME/.config/hypr/.cache/.browser"
browser_num=$(grep -v -n "default" "$browser_cache" | wc -l)
browsers=($(grep -v "default" "$browser_cache"))
default=$(grep "default=" "$browser_cache" | awk -F'=' '{print $2}')
scripts_dir="$HOME/.config/hypr/scripts"
[[ -f "$scripts_dir/colors.sh" ]] && source "$scripts_dir/colors.sh"
primary="${primary:-#ac67e4}"
secondary="${secondary:-#d65cd1}"
foreground="${foreground:-#f2f2f3}"

choose_default() {
    if [[ "$browser_num" -gt 1 && -z "$default" ]]; then
        printf "[ Missing Default Browser ]\n==> You don't have a default browser. Choose which browser you want to set as default.\n\n"

        choose=("${browsers[@]}" "Reset")
        # Prompt user to choose a browser
        choice=$(gum choose --limit=1 \
            --cursor="➜ " \
            --cursor.foreground="$primary" \
            --item.foreground="$foreground" \
            --selected.foreground="$primary" \
            "${choose[@]}")

        # Check if a valid choice was made
        if [[ "$choice" == "Reset" ]]; then
            sed -i "/^default=/d" "$browser_cache"
            notify-send "Default Browser Reset" "Default browser has been reset"
        elif [[ -n "$choice" ]]; then
            if grep -q "^default=" "$browser_cache"; then
                sed -i "s|^default=.*|default=$choice|" "$browser_cache"
                notify-send "Default Browser Set" "Default browser updated to: $choice"
            else
                echo "default=$choice" >> "$browser_cache"
                notify-send "Default Browser Set" "Default browser set to: $choice"
            fi
        else
            notify-send "Skipped" "No browser selected. Default browser not set."
        fi

    elif [[ "$browser_num" -eq 1 && -z "$default" ]]; then
        echo "default=$browsers" >> "$browser_cache"
    fi
}


open_browser() {
    if [[ "$default" == "" ]]; then
        "$scripts_dir/default_browser.sh"
    elif [[ "$default" == "firefox" ]]; then
        "$default"
    else
        # Chromium-based browser
        "$default" --enable-wayland-ime
    fi
}

case $1 in
    ch)
        choose_default
        ;;
    op)
        open_browser
        ;;
esac

