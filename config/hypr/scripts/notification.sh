#!/usr/bin/env bash

# Path to the sound files
SOUND_FILE_UPDATE="$HOME/.hyprconf/hypr/sounds/update.wav"
SOUND_FILE_SYSTEM="$HOME/.hyprconf/hypr/sounds/system-startup.wav"
SOUND_FILE_LOGOUT="$HOME/.hyprconf/hypr/sounds/poweroff.mp3"
SOUND_FILE_USB_IN="$HOME/.hyprconf/hypr/sounds/usb-plug.wav"
SOUND_FILE_USB_OUT="$HOME/.hyprconf/hypr/sounds/usb-unplug.wav"

# Fallbacks if custom usb sounds do not exist
if [[ ! -f "$SOUND_FILE_USB_IN" ]]; then
    SOUND_FILE_USB_IN="/usr/share/sounds/freedesktop/stereo/device-added.oga"
fi
if [[ ! -f "$SOUND_FILE_USB_OUT" ]]; then
    SOUND_FILE_USB_OUT="/usr/share/sounds/freedesktop/stereo/device-removed.oga"
fi

# Function to send notification and play sound
notify_with_sound() {
    notify-send "$1"
    paplay "$SOUND_FILE_UPDATE"
}

startup_with_sound() {
    paplay "$SOUND_FILE_SYSTEM"
}

logout_with_sound() {
    paplay "$SOUND_FILE_LOGOUT"
}

usb_in_with_sound() {
    local msg="${1:-USB storage device connected}"
    notify-send -a "USB Notifier" -i drive-removable-media-usb-pendrive "USB Connected" "$msg"
    paplay "$SOUND_FILE_USB_IN"
}

usb_out_with_sound() {
    local msg="${1:-USB storage device removed}"
    notify-send -a "USB Notifier" -i drive-removable-media-usb-pendrive "USB Disconnected" "$msg"
    paplay "$SOUND_FILE_USB_OUT"
}

case $1 in
  sys)
        startup_with_sound
      ;;
  logout)
        logout_with_sound
      ;;
  usb-in)
        usb_in_with_sound "$2"
      ;;
  usb-out)
        usb_out_with_sound "$2"
      ;;
  notify)
      if [ -n "$2" ]; then
          notify_with_sound "$2"
      else
          echo "Please provide a message for the notification."
      fi
      ;;
  *)
      echo "Usage: $0 {sys|logout|notify|usb-in|usb-out} [message]"
      ;;
esac
