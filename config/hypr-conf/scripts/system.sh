#!/bin/bash

#-----------------------------------------#
#          Memory Usage Notify            #
#-----------------------------------------#
notified=false
while true; do

    # memory usage
    total_mem=$(free -m | awk 'NR==2 {print $2}')
    eighty_percent=$(( total_mem * 80 / 100 ))

    used_mem=$(free -m | awk 'NR==2 {print $3}')

    if [[ "$used_mem" -ge "$eighty_percent" ]]; then
        if [[ "$notified" == false ]]; then
            notify-send -u "critical" -i "$HOME/.config/hypr/icons/warning.png" \
            "Warning!" "80% of memory used: $used_mem MB in use"
            notified=true
        fi
    else
        notified=false
    fi

    # Sleep for 60 seconds to reduce CPU usage
    sleep 5
done


