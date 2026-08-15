#!/bin/bash

#-----------------------------------------#
#          Memory Usage Notify            #
#-----------------------------------------#
notified=false
while true; do

    # Parse total and used memory in one single awk call (no double free -m)
    read -r total_mem used_mem < <(free -m | awk 'NR==2 {print $2, $3}')

    eighty_percent=$(( total_mem * 80 / 100 ))

    if [[ "$used_mem" -ge "$eighty_percent" ]]; then
        if [[ "$notified" == false ]]; then
            notify-send -u "critical" -i "$HOME/.hyprconf/hypr/icons/warning.png" \
            "Warning!" "80% of memory used: $used_mem MB in use"
            notified=true
        fi
    else
        notified=false
    fi

    sleep 5
done
