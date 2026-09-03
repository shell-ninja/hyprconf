#!/bin/bash

# Exit cleanly when the reader (e.g. waybar) closes the pipe
trap 'exit 0' SIGPIPE

SOUND_FILE_UPDATE="$HOME/.config/hypr/sounds/update.wav"
SOUND_FILE_ERROR="$HOME/.config/hypr/sounds/error.wav"
update_sign="$HOME/.config/hypr/icons/update.png"
done_sign="$HOME/.config/hypr/icons/done.png"
warning_sign="$HOME/.config/hypr/icons/warning.png"
error_sign="$HOME/.config/hypr/icons/error.png"
upd_script="$HOME/.config/hypr/scripts/pkgupdate.sh"

# notification functions
update_notification() {
    notify-send -i "$1" "$2" "$3"
    paplay "$SOUND_FILE_UPDATE"
}

error_notification() {
    notify-send -i "$1" "$2" "$3"
    paplay "$SOUND_FILE_ERROR"
}

scripts_dir="$HOME/.config/hypr/scripts"

# Notify user when more than 10 packages are pending (no auto-dismiss, no auto-removal warning)
large_update_notification() {
    local upd="$1"
    local body="$2"
    notify-send \
        --urgency=critical \
        --expire-time=0 \
        --icon="$update_sign" \
        "⚠ Large Update: $upd packages pending" \
        "${body}"$'\n\n'"Press CTRL + U to update packages."
}

# function to check the package manager
check_update() {
    if [ -n "$(command -v pacman)" ]; then
        # Detect AUR helper
        aurhlpr=$(command -v yay || command -v paru)

        check_for_updates() {
            aur=$(${aurhlpr} -Qua | wc -l)
            ofc=$(checkupdates | wc -l)
            echo $(( ofc + aur ))
        }

        aur=$(${aurhlpr} -Qua | wc -l)
        ofc=$(checkupdates | wc -l)
        upd=$(check_for_updates)

        if [ "$upd" -eq 0 ]; then
            echo "{\"text\":\"$upd\", \"tooltip\":\"  Packages are up to date\"}"
        else
            echo "{\"text\":\"$upd\", \"tooltip\":\"󱓽 Official $ofc\n󱓾 AUR $aur\n\nPress CTRL + U to update\"}"
            # Notify if more than 10 packages are pending
            if [ "$upd" -gt 10 ]; then
                large_update_notification "$upd" \
                    "Official: $ofc  |  AUR: $aur"$'\n'"Note: No packages will be auto-removed."
            fi
        fi

    elif [ -n "$(command -v dnf)" ]; then
        upd=$(dnf check-update -q | grep -vE 'Last metadata expiration|^$' | wc -l)

        if [ "$upd" -eq 0 ]; then
            echo "{\"text\":\"$upd\", \"tooltip\":\"  Packages are up to date\"}"
        else
            echo "{\"text\":\"$upd\", \"tooltip\":\"󱓽 Updates Available: $upd\n\npress ctrl + u to update\"}"
            if [ "$upd" -gt 10 ]; then
                large_update_notification "$upd" \
                    "DNF: $upd packages pending."$'\n'"Note: No packages will be auto-removed."
            fi
        fi

    elif [ -n "$(command -v zypper)" ]; then
        ofc=$(zypper lu --best-effort | grep -c 'v  |')
        upd=$(( ofc ))

        if [ "$upd" -eq 0 ]; then
            echo "{\"text\":\"$upd\", \"tooltip\":\"  Packages are up to date\"}"
        else
            echo "{\"text\":\"$upd\", \"tooltip\":\"󱓽 Updates Available: $upd\n\nPress CTRL + U to update\"}"
            if [ "$upd" -gt 10 ]; then
                large_update_notification "$upd" \
                    "Zypper: $upd packages pending."$'\n'"Note: No packages will be auto-removed."
            fi
        fi
    fi
}

package_update() {
    if [ -n "$(command -v pacman)" ]; then
        aurhlpr=$(command -v yay || command -v paru)
        
        kitty --title update sh -c "${upd_script}"
        check_for_updates() {
            aur=$(${aurhlpr} -Qua | wc -l)
            ofc=$(checkupdates | wc -l)

            # Calculate total available updates
            upd=$(( ofc + aur ))

            echo "$upd"
        }

        # tooltip in waybar
        aur=$(${aurhlpr} -Qua | wc -l)
        ofc=$(checkupdates | wc -l)

        # Initial check for updates
        upd=$(check_for_updates)

        sleep 1

        if [ $upd -eq 0 ]; then
            update_notification "$done_sign" "Done" "Packages have been updated"
        elif [ $upd -gt 0 ]; then
            error_notification "$warning_sign" "Warning!" "Some packages may have skipped"
        else
            error_notification "$error_sign" "Error!" "Sorry, could not update packages"
        fi
    elif [ -n "$(command -v dnf)" ]; then
        # Run the update command and capture the return code
        kitty --title update sh -c "${upd_script}"
        
        # Calculate total available updates fedora
        upd=$(dnf check-update -q | grep -vE 'Last metadata expiration|^$' | wc -l)

        sleep 1

        if [ $upd -eq 0 ]; then
            update_notification "$done_sign" "Done" "Packages have been updated"
        elif [ $upd -gt 0 ]; then
            error_notification "$warning_sign" "Warning!" "Some packages may have skipped"
        else
            error_notification "$error_sign" "Error!" "Sorry, could not update packages"
        fi

    elif [ -n "$(command -v zypper)" ]; then
        kitty --title update sh -c "${upd_script}"

        # count the number of available updates
        ofc=$(zypper lu --best-effort | grep -c 'v  |')

        # Calculate total available updates
        upd=$(( ofc ))

        sleep 1

        if [ $upd -eq 0 ]; then
            update_notification "$done_sign" "Done" "Packages have been updated"
        elif [ $upd -gt 0 ]; then
            error_notification "$warning_sign" "Warning!" "Some packages may have skipped"
        else
            error_notification "$error_sign" "Error!" "Sorry, could not update packages"
        fi
    fi

}

case $1 in
    --check)
        check_update  # Check for available updates
        ;;
    --update)
        package_update  # Perform package update
        ;;
    *)
        echo "Invalid option. Use 'cu' to check for updates or 'up' to update packages."
        ;;
esac
