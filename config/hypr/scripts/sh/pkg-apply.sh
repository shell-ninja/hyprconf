#!/usr/bin/env bash
# =============================================================================
#  pkg-apply.sh — Streaming package updater runner for Quickshell updater
# =============================================================================
set -u

DO_PACMAN=0
DO_AUR=0
DO_FLATPAK=0

for arg in "$@"; do
    case "$arg" in
        --pacman)  DO_PACMAN=1 ;;
        --aur)     DO_AUR=1 ;;
        --flatpak) DO_FLATPAK=1 ;;
    esac
done

if [ "$DO_PACMAN" -eq 0 ] && [ "$DO_AUR" -eq 0 ] && [ "$DO_FLATPAK" -eq 0 ]; then
    DO_PACMAN=1
    DO_AUR=1
fi

echo ":: System Package Update in progress..."
echo ":: Initiated at $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

OVERALL_STATUS=0

# 1. PACMAN (requires root -> pkexec invokes Quickshell Island Polkit)
if [ "$DO_PACMAN" -eq 1 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  [PACMAN] Updating official repositories..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ":: Requesting administrator authorization via Polkit..."
    
    if command -v pacman >/dev/null 2>&1; then
        pkexec env LANG=C pacman -Syu --noconfirm --color=always
        PAC_STATUS=$?
        if [ "$PAC_STATUS" -eq 0 ]; then
            echo ""
            echo "✓ Pacman repositories updated successfully."
        else
            echo ""
            echo "✗ Pacman update finished with code: $PAC_STATUS"
            OVERALL_STATUS=$PAC_STATUS
        fi
    else
        echo "✗ pacman binary not found on this system."
    fi
    echo ""
fi

# 2. AUR (runs as current user, elevates via pkexec if building/installing packages)
if [ "$DO_AUR" -eq 1 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  [AUR] Updating Arch User Repository packages..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if command -v paru >/dev/null 2>&1; then
        echo ":: Running: paru -Sua --noconfirm --sudo pkexec"
        paru -Sua --noconfirm --sudo pkexec
        AUR_STATUS=$?
        if [ "$AUR_STATUS" -eq 0 ]; then
            echo ""
            echo "✓ AUR packages updated successfully."
        else
            echo ""
            echo "✗ AUR update finished with code: $AUR_STATUS"
            OVERALL_STATUS=$AUR_STATUS
        fi
    elif command -v yay >/dev/null 2>&1; then
        echo ":: Running: yay -Sua --noconfirm --sudo pkexec"
        yay -Sua --noconfirm --sudo pkexec
        AUR_STATUS=$?
        if [ "$AUR_STATUS" -eq 0 ]; then
            echo ""
            echo "✓ AUR packages updated successfully."
        else
            echo ""
            echo "✗ AUR update finished with code: $AUR_STATUS"
            OVERALL_STATUS=$AUR_STATUS
        fi
    else
        echo ":: No AUR helper (paru/yay) found. Skipping AUR."
    fi
    echo ""
fi

# 3. FLATPAK (user or system flatpaks)
if [ "$DO_FLATPAK" -eq 1 ]; then
    if command -v flatpak >/dev/null 2>&1; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  [FLATPAK] Updating Flathub packages..."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        flatpak update -y
        FLAT_STATUS=$?
        if [ "$FLAT_STATUS" -eq 0 ]; then
            echo "✓ Flatpaks updated successfully."
        else
            echo "✗ Flatpak update exited with code: $FLAT_STATUS"
            OVERALL_STATUS=$FLAT_STATUS
        fi
        echo ""
    fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$OVERALL_STATUS" -eq 0 ]; then
    echo "✓ ALL UPDATES COMPLETED SUCCESSFULLY!"
    echo ":: Your system is up to date."
else
    echo "✗ Update sequence completed with errors (code $OVERALL_STATUS)."
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit $OVERALL_STATUS
