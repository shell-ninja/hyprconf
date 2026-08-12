#!/bin/bash

case $1 in
    --poweroff)
        "$HOME/.hyprconf/hypr/scripts/uptime.sh"
        "$HOME/.hyprconf/hypr/scripts/notification.sh" logout
        systemctl poweroff --now
        ;;
    --reboot)
        "$HOME/.hyprconf/hypr/scripts/uptime.sh"
        "$HOME/.hyprconf/hypr/scripts/notification.sh" logout
        systemctl reboot --now
        ;;
    --logout)
        "$HOME/.hyprconf/hypr/scripts/uptime.sh"
        "$HOME/.hyprconf/hypr/scripts/notification.sh" logout
        hyprctl dispatch 'hl.dsp.exit()'
        ;;
    --lock)
        sleep 0.1
        hyprlock
        ;;
esac
