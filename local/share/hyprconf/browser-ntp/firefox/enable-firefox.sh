#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
COLORS_SRC="$SCRIPT_DIR/colors.css"
NTP_CSS_SRC="$SCRIPT_DIR/hyprconf-ntp.css"
IMPORT_LINE='@import url("hyprconf-ntp.css");'
PREF_LINE='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'

declare -a PROFILE_DIRS=()
declare -a PROFILE_LABELS=()

discover_profiles() {
    local name="$1"
    local base="$2"
    [[ -d "$base" ]] || return 0

    local dir
    while IFS= read -r -d '' dir; do
        PROFILE_DIRS+=("$dir")
        PROFILE_LABELS+=("$name: $(basename "$dir")")
    done < <(find "$base" -mindepth 1 -maxdepth 2 -type f -name "prefs.js" -printf '%h\0' 2>/dev/null | sort -z)
}

discover_profiles "Firefox" "$HOME/.mozilla/firefox"
discover_profiles "Firefox (Flatpak)" "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox"
discover_profiles "LibreWolf" "$HOME/.librewolf"
discover_profiles "Floorp" "$HOME/.floorp"
discover_profiles "Zen" "$HOME/.zen"
discover_profiles "Waterfox" "$HOME/.waterfox"

if [[ ${#PROFILE_DIRS[@]} -eq 0 ]]; then
    echo "No Firefox/Gecko profiles found."
    echo "Manually symlink colors.css and hyprconf-ntp.css into <profile>/chrome/,"
    echo "import hyprconf-ntp.css at the top of userContent.css, and set"
    echo "toolkit.legacyUserProfileCustomizations.stylesheets = true in about:config."
    exit 1
fi

echo "Discovered Firefox / Gecko profiles:"
for i in "${!PROFILE_DIRS[@]}"; do
    printf "  [%d] %s\n" "$((i + 1))" "${PROFILE_LABELS[$i]}"
done
echo "  [a] All profiles"
echo "  [q] Cancel"
echo

read -r -p "Select profile number (or 'a' for all, 'q' to quit): " choice
[[ "$choice" == "q" || "$choice" == "Q" || -z "$choice" ]] && exit 0

declare -a SELECTED=()
if [[ "$choice" == "a" || "$choice" == "A" ]]; then
    SELECTED=("${PROFILE_DIRS[@]}")
elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#PROFILE_DIRS[@]} )); then
    SELECTED=("${PROFILE_DIRS[$((choice - 1))]}")
else
    echo "Invalid selection."
    exit 1
fi

apply_to_profile() {
    local profile="$1"
    local chrome_dir="$profile/chrome"
    mkdir -p "$chrome_dir"

    ln -sfn "$COLORS_SRC" "$chrome_dir/colors.css"
    ln -sfn "$NTP_CSS_SRC" "$chrome_dir/hyprconf-ntp.css"

    local uc="$chrome_dir/userContent.css"
    if [[ ! -e "$uc" && ! -L "$uc" ]]; then
        printf '%s\n' "$IMPORT_LINE" > "$uc"
    elif ! grep -Fq "hyprconf-ntp.css" "$uc" 2>/dev/null; then
        local tmp
        tmp="$(mktemp)"
        {
            printf '%s\n' "$IMPORT_LINE"
            cat "$uc"
        } > "$tmp"
        mv "$tmp" "$uc"
    fi

    local user_js="$profile/user.js"
    if [[ ! -f "$user_js" ]]; then
        printf '%s\n' "$PREF_LINE" > "$user_js"
    elif ! grep -Fq "toolkit.legacyUserProfileCustomizations.stylesheets" "$user_js" 2>/dev/null; then
        printf '\n%s\n' "$PREF_LINE" >> "$user_js"
    fi

    echo "Enabled Hyprconf browser NTP theme in: $profile"
}

for p in "${SELECTED[@]}"; do
    apply_to_profile "$p"
done

echo
echo "Done. Restart the browser so userContent.css takes effect."
