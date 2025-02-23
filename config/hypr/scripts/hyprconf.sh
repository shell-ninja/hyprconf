#!/bin/bash
# script for updating the hyprconf from the github.


# colors code
color="\x1b[38;2;224;255;255m"
end="\x1b[0m"

# dirs and files
_dir=`pwd`
_cache="$HOME/.cache"
_hyprconf="$_cache/hyprconf"
_version_file="$HOME/.config/hypr/.cache/.version"
if [[ -f "$_version_file" ]]; then
    _version=$(cat "$_version_file")
else
    echo -e "!! Could not get the version. Please choose one."
fi

clear

# fn for git actions
_git_clone() {
    git clone --depth=1 --branch="$_version" https://github.com/shell-ninja/hyprconf.git ~/.cache/hyprconf &> /dev/null
}

# fn for the process
_upd() {
   if [[ -d "$_hyprconf" ]]; then
       echo -e ":: hyrconf dir is available in the cache. Removing it"
       echo
       rm -rf "$_hyprconf" && sleep 1
    fi

   echo -e "${color}=>${end} Now cloning the updated repository..."
   _git_clone

   if [[ -d "$_hyprconf" ]]; then
       echo -e ":: Successfully cloned repo."
        gum spin \
            --spinner dot \
            --title "Now updating in your system locally." -- \
            sleep 2

       cd "$_hyprconf"
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

    exit 1
fi

# running the script
case $1 in 
    --hyprconf)
        kitty --title update sh -c "$HOME/.config/hypr/scripts/hyprconf.sh"
        ;;
esac
