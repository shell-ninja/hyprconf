#!/bin/bash

green='\033[0;32m'
red='\033[0;31m'
cyan='\033[0;36m'
end="\033[0m"

actSign="${green}->${end}"
doneSign="${cyan}!!${end}"

username="$(whoami)"

clear

printf "${actSign} Setting up user avatar...\n" && sleep 1
echo 
img=$(gum input \
    --header "Image path:" \
    --header.foreground "#c3cbd0" \
    --placeholder.foreground "#c3cbd0" \
    --placeholder "Paste the image path"
)

printf "\n"

if [[ -f "/usr/share/sddm/faces/$username.face.icon" ]]; then
    printf "${actSign} Creating backup for '/usr/share/sddm/faces/$username.face.icon'\n"
    sudo cp -f "/usr/share/sddm/faces/$username.face.icon" "/usr/share/sddm/faces/$username.face.icon.bkp"
fi

sudo cp "$img" "/usr/share/sddm/faces/tmp_face"
# Crop image to square:
sudo mogrify -gravity center -crop 1:1 +repage "/usr/share/sddm/faces/tmp_face"
# Resize face to 256x256:
sudo mogrify -resize 256x256 "/usr/share/sddm/faces/tmp_face"
sudo mv "/usr/share/sddm/faces/tmp_face" "/usr/share/sddm/faces/$username.face.icon"

printf "\n${doneSign} Avatar updated successfully for '$username'!\n"

exit 0
