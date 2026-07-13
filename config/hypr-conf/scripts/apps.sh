#!/bin/bash

# open site
open_site() {
    local site_name=$1
    url="https://${site_name}.com"


    # Define the browsers in the order of preference
    browser_cache="$HOME/.config/hypr/.cache/.browser"
    browser=$(grep "default" "$browser_cache" | awk -F'=' '{print $2}')


    if [[ ! "$browser" == "firefox" ]]; then

        # for chromium based browsers
        "$browser" --app="$url"

    elif [[ "$browser" == "firefox" || "$browser" == "zen-browser" ]]; then
        
        # for firefox and zen browser
        "$browser" --new-window "$url"

    fi
}

open_site $1
