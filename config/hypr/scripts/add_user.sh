#!/bin/bash

# asking user for the image path
printf "Write the path of the image to show as a User image in Hyprlock\nfor example: path/to/image.jpg\n"
read -r -p "Paste here: " img_path

if convert "$img_path" -resize 50% "$HOME/.config/hypr/.cache/user.png" &> /dev/null; then
    printf "[ * ] - Image added successfully...\n"
else
    printf "[ ! ] - Failed to convert the image. Please check the path and try again.\n"
fi