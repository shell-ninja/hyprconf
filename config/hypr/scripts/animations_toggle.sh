#!/bin/bash

animations=$(hyprctl getoption animations:enabled | awk 'NR==1 {print $2}')
decoration="$HOME/.config/hypr/configs/decoration.conf"
animationsConf="$HOME/.config/hypr/configs/animation.conf"

if [[ "$animations" == 1 ]]; then
    sed -i 's|^source *=.*|source = ~/.config/hypr/configs/configs_noanimation.conf|' "$decoration"

    sed -i 's|^\([[:space:]]*enabled *=\).*|\1 0|' "$animationsConf"

else
    sed -i 's|^source *=.*|source = ~/.config/hypr/configs/configs.conf|' "$decoration"

    sed -i 's|^\([[:space:]]*enabled *=\).*|\1 1|' "$animationsConf"
fi

hyprctl reload
