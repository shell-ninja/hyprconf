#!/bin/bash

scripts_dir=$HOME/.config/hypr/scripts

case $1 in
    c) cliphist list | rofi -dmenu -theme-str "entry { placeholder: \" Search Clipboard\";} ${pos} ${r_override}" -theme-str "${fnt_override}" -config ~/.config/rofi/themes/rofi-clipboard.rasi | cliphist decode | wl-copy
        ;;
    w)  if [ "$(echo -e "Yes\nNo" | rofi -dmenu -theme-str "entry { placeholder: \" Clear Clipboard History?\";} ${pos} ${r_override}" -theme-str "${fnt_override}" -config ~/.config/rofi/themes/rofi-clipboard.rasi)" == "Yes" ] ; then
            cliphist wipe
        fi
        ;;
    l)  cliphist list | wc -l
        ;;
    *)  echo -e "cliphist.sh [action]"
        echo "c :  cliphist list and copy selected"
        echo "d :  cliphist list and delete selected"
        echo "w :  cliphist wipe database"
        echo "l :  show the number of items in the clipboard"
        exit 1
        ;;
esac
