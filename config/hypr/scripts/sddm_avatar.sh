#!/bin/bash

green='\033[0;32m'
red='\033[0;31m'
cyan='\033[0;36m'
end="\033[0m"

user="$(whoami)"

printf "${green}[ ATTENTION ]${end}\n==> Need your root password to copy image for the avatar.\n"

sleep 2 && clear

printf "${cyan}Provide your Username.${end}\n"
read -p "type: " username


printf "${cyan}Provide your image path.${end}\n"
read -p "type: " img

printf "\n"

if ! id "$username" &> /dev/null; then
    printf "${red}[ ERROR ]${end}\n==> ${username} is not your current user\n"
    exit 1
fi


if [[ -f "/usr/share/sddm/faces/$username.face.icon" ]]; then
    printf "${green}[ ACTION ]${end}\n==>Creating backup for '/usr/share/sddm/faces/$username.face.icon'\n"
    sudo cp -f "/usr/share/sddm/faces/$username.face.icon" "/usr/share/sddm/faces/$username.face.icon.bkp"
fi

sudo cp "$img" "/usr/share/sddm/faces/tmp_face"
# Crop image to square:
sudo mogrify -gravity center -crop 1:1 +repage "/usr/share/sddm/faces/tmp_face"
# Resize face to 256x256:
sudo mogrify -resize 256x256 "/usr/share/sddm/faces/tmp_face"
sudo mv "/usr/share/sddm/faces/tmp_face" "/usr/share/sddm/faces/$username.face.icon"

printf "\n${cyan}[ DONE ]${end}\n==>Avatar updated for user '$username'!\n"
