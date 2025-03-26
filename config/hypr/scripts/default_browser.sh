#!/bin/bash

browser_cache="$HOME/.config/hypr/.cache/.browser"
scripts_dir="$HOME/.config/hypr/scripts"

[[ ! -f "$browser_cache" ]] && touch "$browser_cache"

# List of browsers to check.
chromium_based=$(compgen -c | grep -- '-browser' | grep -E '^(brave|chromium|opera|vivaldi|zen)-browser$' | sed 's/-stable//' | sort -u)
browsers=("firefox" "brave" "google-chrome-stable" "${chromium_based[@]}")

IFS=$'\n' read -rd '' -a browsers <<<"$chromium_based"

if [[ -n "$(command -v firefox)" ]]; then
    echo "firefox" >> "$browser_cache"
fi

if [[ -n "$(command -v brave)" ]]; then
    echo "brave" >> "$browser_cache"
fi

if [[ -n "$(command -v chromium)" ]]; then
    echo "chromium" >> "$browser_cache"
fi

if [[ -n "$(command -v google-chrome-stable)" ]]; then
    echo "google-chrome-stable" >> "$browser_cache"
fi

if [[ -n "$(command -v vivaldi)" ]]; then
    echo "vivaldi" >> "$browser_cache"
fi

# Loop through the list and append found browsers to the cache.
for browser in "${browsers[@]}"; do
    if command -v "$browser" &>/dev/null && ! grep -qx "$browser" "$browser_cache"; then
        echo "Found: $browser"
        echo "$browser" >>"$browser_cache"
    fi
done

browsers_num=$(grep -v -n "default" "$browser_cache" | wc -l)
default=$(grep "default=" "$browser_cache" | awk -F'=' '{print $2}')

if [[ "$browsers_num" -gt 1 && -z "$default" ]]; then
    notify-send "Missing Default Browser" "You need to set a default browser. Opening kitty to set a default browser." && sleep 5
    kitty --title browser sh -c "$scripts_dir/browser.sh ch"
elif [[ "$browsers_num" -eq 1 && -z "$default" ]]; then
    existing=$(grep -v "default=" "$browser_cache")
    notify-send "Default browser" "Setting $existing as your default browser."
    echo "default=$existing" >>"$browser_cache"
fi

case $1 in
--reset)
    rm ~/.config/hypr/.cache/.browser
    notify-send "Reset" "Default browser list has been reset"
    "$HOME/.config/hypr/scripts/default_browser.sh"
    ;;
esac
