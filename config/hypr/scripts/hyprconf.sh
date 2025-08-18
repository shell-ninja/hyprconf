#!/bin/bash
# script for updating the hyprconf from the github.


# colors code
color="\x1b[38;2;224;255;255m"
end="\x1b[0m"

clear

repo="https://github.com/shell-ninja/hyprconf/archive/refs/heads/main.zip"
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
        unzip "$zip_path" "hyprconf-main/*" -d "$target_dir" > /dev/null
        mv "$target_dir/hyprconf-main/"* "$target_dir" && rmdir "$target_dir/hyprconf-main"
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
        --spinner.foreground "#FF0000" \
        --title.foreground "#FF0000" \
        --title "Exiting the script" -- \
        sleep 3
   fi
}

# asking user for confirmation
choice=$(
        gum confirm \
        "Would you like to update your current 'hyprconf'?" \
        --affirmative "Yes! update" \
        --selected.background "#e0ffff" \
        --selected.foreground "#2f4f4f" \
        --unselected.background "#2f4f4f" \
        --unselected.foreground "#e0ffff" \
        --negative "No!, skip"
)

if [[ $? -eq 0 ]]; then
    gum spin \
        --spinner dot \
        --spinner.foreground "#e0ffff" \
        --title.foreground "#e0ffff" \
        --title "Updating..." -- \
        sleep 2
    _upd
else
    gum spin \
        --spinner dot \
        --spinner.foreground "#FF0000" \
        --title.foreground "#FF0000" \
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
