#!/bin/bash

value_file="$HOME/.config/hypr/.cache/.nightlight"
default=6500

# Initialize the value file if it doesn't exist
if [[ ! -f "$value_file" ]]; then
    echo $default > $value_file
fi

value=$(cat $value_file)

if command -v hyprsunset &> /dev/null; then
    fn_change_value() {
        case $1 in
            --value)
                value=5000
                echo "$value" > "$value_file"
                notify-send "Nightlight" "Screen temp set to 5000K"
                hyprsunset -t 5000
            ;;
            --def)
                value=$default
                echo "$value" > "$value_file"
                notify-send "Nightlight" "Screen temp reset to default"
                killall hyprsunset
            ;;
        esac
    }

    fn_change_value "$1"
fi

printf "${value}K"
