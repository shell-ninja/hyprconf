#!/bin/bash

if command -v hyprsunset &> /dev/null; then
    fn_change_value() {
        case $1 in
            --value)
                notify-send "Nightlight" "Screen temp set to 5000K"
                hyprsunset -t 5000
            ;;
            --def)
                notify-send "Nightlight" "Screen temp reset to default"
                killall hyprsunset
            ;;
        esac
    }

    fn_change_value "$1"
fi
