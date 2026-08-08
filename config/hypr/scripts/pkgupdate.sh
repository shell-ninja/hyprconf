#!/bin/bash

display() {
    # Get terminal width
    local cols=$(tput cols)
    
    # Use a here-document with quoted 'EOF' to treat content as literal text
    # This prevents issues with backticks or quotes inside the ASCII art
    local art
    art=$(cat << 'EOF'
            ┏━┓╻ ╻┏━┓╺┳╸┏━╸┏┳┓ ╻ ╻┏━┓╺┳┓┏━┓╺┳╸┏━╸            
            ┗━┓┗┳┛┗━┓ ┃ ┣╸ ┃┃┃ ┃ ┃┣━┛ ┃┃┣━┫ ┃ ┣╸             
╺━╸╺━╸╺━╸╺━╸┗━┛ ╹ ┗━┛ ╹ ┗━╸╹ ╹ ┗━┛╹  ╺┻┛╹ ╹ ╹ ┗━╸╺━╸╺━╸╺━╸╺━╸
EOF
)

    # Find the width of the widest line
    local max_width=0
    while IFS= read -r line; do
        local len=${#line}
        if (( len > max_width )); then
            max_width=$len
        fi
    done <<< "$art"

    # Calculate padding
    local padding=0
    if (( cols > max_width )); then
        padding=$(( (cols - max_width) / 2 ))
    fi

    # Print with padding
    local spaces=$(printf '%*s' "$padding" '')
    while IFS= read -r line; do
        printf "%s%s\n" "$spaces" "$line"
    done <<< "$art"
}   

display
printf "\n"

# Directly check the exit code of gum confirm without capturing output
if gum confirm "Would you like to," \
        --prompt.foreground "#ccb7b6" \
        --affirmative "Update now!" \
        --selected.background "#ccb7b6" \
        --selected.foreground "#0F0F13" \
        --negative "Skip updating!"; then
    
    # User selected "Update now!" (Exit code 0)
    if [ -n "$(command -v pacman)" ]; then
        aur=$(command -v yay || command -v paru)
        if [ -n "$aur" ]; then
            "$aur" -Syyu --noconfirm
        else
            echo "Warning: pacman found, but no AUR helper (yay/paru) installed."
        fi
    elif [ -n "$(command -v dnf)" ]; then
        sudo dnf update && sudo dnf upgrade -y
    elif [ -n "$(command -v zypper)" ]; then
        sudo zypper up -y
    else
        echo "No supported package manager found."
    fi

    sleep 1
    exit 0
else
    # Capture the specific exit code to distinguish between "No" and "Ctrl+C"
    exit_code=$?
    
    if [ $exit_code -eq 130 ]; then
        echo "Operation cancelled by user (Ctrl+C)."
        exit 130
    fi

    # User selected "Skip updating!" (Exit code 1) or other error
    gum spin \
        --spinner dot \
        --spinner.foreground "#ccb7b6" \
        --title "Skipping updating your system..." -- \
        sleep 2
fi   
