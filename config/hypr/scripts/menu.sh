#!/usr/bin/env bash

dir="$HOME/.config/rofi/menu"
theme='style-8'

## Run
rofi \
    -show drun \
    -theme ${dir}/${theme}.rasi
