#!/usr/bin/env bash

if pgrep -x "noctalia" >/dev/null 2>&1; then
    noctalia msg panel-toggle launcher
    exit 0
fi

dir="$HOME/.config/rofi/menu"
theme='style-5'

## Run
rofi \
    -show drun \
    -theme ${dir}/${theme}.rasi

