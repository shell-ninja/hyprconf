#!/bin/bash

browser_cache="$HOME/.hyprconf/hypr/.cache/.browser"
scripts_dir="$HOME/.hyprconf/hypr/scripts"

[[ ! -f "$browser_cache" ]] && touch "$browser_cache"

# Detect installed browsers and append to cache (no duplicates, no redundant hardcoded checks)
_known_browsers=(
    firefox
    brave
    chromium
    google-chrome-stable
    vivaldi
)

# Also catch any *-browser variants (opera-browser, zen-browser, etc.)
mapfile -t _extra < <(compgen -c | grep -E '^[a-z]+-browser$' | sort -u)

for browser in "${_known_browsers[@]}" "${_extra[@]}"; do
    if command -v "$browser" &>/dev/null && ! grep -qxF "$browser" "$browser_cache"; then
        echo "$browser" >> "$browser_cache"
    fi
done

browsers_num=$(grep -cv "^default=" "$browser_cache" || true)
default=$(grep "^default=" "$browser_cache" | cut -d= -f2)

if [[ "$browsers_num" -gt 1 && -z "$default" ]]; then
    notify-send "Missing Default Browser" "You need to set a default browser. Opening kitty to set a default browser." && sleep 5
    kitty --title browser sh -c "$scripts_dir/browser.sh ch"
elif [[ "$browsers_num" -eq 1 && -z "$default" ]]; then
    existing=$(grep -v "^default=" "$browser_cache" | head -n1)
    notify-send "Default browser" "Setting $existing as your default browser."
    echo "default=$existing" >> "$browser_cache"
fi

case $1 in
    --reset)
        rm "$browser_cache"
        notify-send "Reset" "Default browser list has been reset"
        "$HOME/.hyprconf/hypr/scripts/default_browser.sh"
        ;;
esac
