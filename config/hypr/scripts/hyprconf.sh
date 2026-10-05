#!/usr/bin/env bash
# script for updating the hyprconf from the github.


scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$scripts_dir/colors.sh" ]] && source "$scripts_dir/colors.sh"

primary="${primary:-#ac67e4}"
secondary="${secondary:-#d65cd1}"
surface="${surface:-#201628}"
foreground="${foreground:-#f2f2f3}"
on_secondary="${on_secondary:-#1f1825}"
error="${error:-#fd4663}"

# colors code
color="\x1b[38;2;224;255;255m"
end="\x1b[0m"

clear

repo="https://github.com/shell-ninja/hyprconf/archive/refs/heads/noct.zip"
target_dir="$HOME/.cache/hyrconf"
zip_path="$target_dir.zip"

# fn for the process
_upd() {
   if [[ -d "$_hyprconf" ]]; then
       echo -e ":: hyrconf dir is available in the cache. Removing it"
       echo
       rm -rf "$_hyprconf" && sleep 1
    fi

   echo -e "${color}=>${end} Now cloning the updated repository..."
   curl -L "$repo" -o "$zip_path"

   sleep 1

   if [[ -f "$zip_path" ]]; then
        unzip "$zip_path" "hyprconf-noct/*" -d "$target_dir" > /dev/null
        mv "$target_dir/hyprconf-noct/"* "$target_dir" && rmdir "$target_dir/hyprconf-noct"
        rm "$zip_path"
    fi

   if [[ -d "$HOME/.cache/hyrconf" ]]; then
       echo -e ":: Successfully cloned repo."
        gum spin \
            --spinner dot \
            --title "Now updating in your system locally." -- \
            sleep 2

       cd "$HOME/.cache/hyrconf/"
       chmod +x setup.sh
       ./setup.sh
    else
        echo -e "!! Sorry, could not clone repository..."
    gum spin \
        --spinner dot \
        --spinner.foreground "$error" \
        --title.foreground "$error" \
        --title "Exiting the script" -- \
        sleep 3
   fi
}

# asking user for confirmation
choice=$(
        gum confirm \
        "Would you like to update your current 'hyprconf'?" \
        --prompt.foreground "$foreground" \
        --affirmative "Yes! update" \
        --selected.background "$primary" \
        --selected.foreground "$on_secondary" \
        --unselected.background "$surface" \
        --unselected.foreground "$foreground" \
        --negative "No!, skip"
)

if [[ $? -eq 0 ]]; then
    gum spin \
        --spinner dot \
        --spinner.foreground "$primary" \
        --title.foreground "$foreground" \
        --title "Updating..." -- \
        sleep 2
    _upd
else
    gum spin \
        --spinner dot \
        --spinner.foreground "$error" \
        --title.foreground "$error" \
        --title "Cancelling..." -- \
        sleep 3

    # exit 1
fi

# running the script
case $1 in 
    --hyprconf)
        kitty --title update sh -c "$HOME/.config/hypr/scripts/hyprconf.sh"
        ;;
esac
