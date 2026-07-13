#!/bin/bash

animations=$(hyprctl getoption animations:enabled | grep "bool" | awk '{print $2}')
decoration="$HOME/.hyprconf/hypr/configs/decoration.lua"
animationsConf="$HOME/.hyprconf/hypr/configs/animation.lua"
icon="$HOME/.hyprconf/hypr/icons/animation.svg"

notify_off() {
    notify-send "Turned Off" -i "$icon" "Disabled Animations."
}

notify_on() {
    notify-send "Turned On" -i "$icon" "Enabled Animations."
}

if [[ "$animations" == true ]]; then
    notify_off

    sed -i 's|^source *=.*|source = ~/.config/hypr/configs/configs_noanimation.lua|' "$decoration"

    sed -i 's|^\([[:space:]]*enabled *=\).*|\1 0,|' "$animationsConf"

else
    notify_on

    sed -i 's|^source *=.*|source = ~/.config/hypr/configs/configs.lua|' "$decoration"

    sed -i 's|^\([[:space:]]*enabled *=\).*|\1 1,|' "$animationsConf"
fi

hyprctl reload
