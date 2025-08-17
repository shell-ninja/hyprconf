#!/bin/bash
# script for updating the hyprconf from the github.


# colors code
color="\x1b[38;2;224;255;255m"
end="\x1b[0m"

# dirs and files
_dir=`pwd`

clear

# fn for the process
_upd() {
   if [[ -d "$HOME/.dotfiles/.git" ]]; then
       cd "$HOME/.dotfiles"

       # Check for uncommitted changes
       if ! git diff --quiet || ! git diff --cached --quiet; then
           echo -e "${color}You have local uncommitted changes.${end}"
           echo -e "${color}Stashing them before pulling...${end}"
           git stash push -m "Auto-stash before pull"
           STASHED=true
       fi

       # Pull latest updates
       git pull origin main

       # If we stashed earlier, apply the stash back
       if [[ "$STASHED" == true ]]; then
           echo -e "${color}Re-applying your local changes...${end}"
           git stash pop
       fi

   else
       gum spin \
           --spinner dot \
           --spinner.foreground "#FF0000" \
           --title.foreground "#FF0000" \
           --title "No github repo found. Exiting..." -- \
           sleep 3
   fi
}

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
