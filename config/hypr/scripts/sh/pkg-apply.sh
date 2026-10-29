#!/usr/bin/env bash
# =============================================================================
#  pkg-apply.sh — Streaming multi-distro package updater runner for Quickshell
# =============================================================================
set -u

DO_NATIVE=0
DO_PACMAN=0
DO_AUR=0
DO_APT=0
DO_DNF=0
DO_ZYPPER=0
DO_FLATPAK=0

for arg in "$@"; do
    case "$arg" in
        --native)  DO_NATIVE=1 ;;
        --pacman)  DO_PACMAN=1 ;;
        --aur)     DO_AUR=1 ;;
        --apt)     DO_APT=1 ;;
        --dnf|--dnf5) DO_DNF=1 ;;
        --zypper)  DO_ZYPPER=1 ;;
        --flatpak) DO_FLATPAK=1 ;;
    esac
done

# If no specific target given, detect system's native manager
if [ "$DO_NATIVE" -eq 0 ] && [ "$DO_PACMAN" -eq 0 ] && [ "$DO_AUR" -eq 0 ] && [ "$DO_APT" -eq 0 ] && [ "$DO_DNF" -eq 0 ] && [ "$DO_ZYPPER" -eq 0 ] && [ "$DO_FLATPAK" -eq 0 ]; then
    DO_NATIVE=1
    # On Arch systems, default to both native pacman and AUR
    if command -v pacman >/dev/null 2>&1; then
        DO_AUR=1
    fi
fi

# Detect native manager if --native is requested
if [ "$DO_NATIVE" -eq 1 ]; then
    if command -v pacman >/dev/null 2>&1; then
        DO_PACMAN=1
    elif command -v apt-get >/dev/null 2>&1; then
        DO_APT=1
    elif command -v dnf5 >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1; then
        DO_DNF=1
    elif command -v zypper >/dev/null 2>&1; then
        DO_ZYPPER=1
    fi
fi

echo ":: System Package Update in progress..."
echo ":: Initiated at $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

OVERALL_STATUS=0

# 1. PACMAN (Arch / EndeavourOS / Manjaro)
if [ "$DO_PACMAN" -eq 1 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  [PACMAN] Updating official repositories..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ":: Requesting administrator authorization via Polkit..."
    
    if command -v pacman >/dev/null 2>&1; then
        pkexec env LANG=C pacman -Syu --noconfirm --color=always 2>&1 | stdbuf -oL -eL tr '\r' '\n'
        PAC_STATUS="${PIPESTATUS[0]}"
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

# 2. APT (Debian / Ubuntu / Pop!_OS / Mint)
if [ "$DO_APT" -eq 1 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  [APT] Updating Debian/Ubuntu repositories..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ":: Requesting administrator authorization via Polkit..."
    
    if command -v apt-get >/dev/null 2>&1; then
        pkexec env DEBIAN_FRONTEND=noninteractive apt-get update && pkexec env DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y 2>&1 | stdbuf -oL -eL tr '\r' '\n'
        APT_STATUS="${PIPESTATUS[0]}"
        if [ "$APT_STATUS" -eq 0 ]; then
            echo ""
            echo "✓ APT packages updated successfully."
        else
            echo ""
            echo "✗ APT update finished with code: $APT_STATUS"
            OVERALL_STATUS=$APT_STATUS
        fi
    else
        echo "✗ apt-get binary not found on this system."
    fi
    echo ""
fi

# 3. DNF (Fedora / RHEL / Alma / Rocky)
if [ "$DO_DNF" -eq 1 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  [DNF] Updating Fedora/RHEL repositories..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ":: Requesting administrator authorization via Polkit..."
    
    DNF_BIN="dnf"
    if command -v dnf5 >/dev/null 2>&1; then
        DNF_BIN="dnf5"
    fi

    if command -v "$DNF_BIN" >/dev/null 2>&1; then
        pkexec "$DNF_BIN" upgrade -y 2>&1 | stdbuf -oL -eL tr '\r' '\n'
        DNF_STATUS="${PIPESTATUS[0]}"
        if [ "$DNF_STATUS" -eq 0 ]; then
            echo ""
            echo "✓ DNF packages updated successfully."
        else
            echo ""
            echo "✗ DNF update finished with code: $DNF_STATUS"
            OVERALL_STATUS=$DNF_STATUS
        fi
    else
        echo "✗ dnf/dnf5 binary not found on this system."
    fi
    echo ""
fi

# 4. ZYPPER (openSUSE)
if [ "$DO_ZYPPER" -eq 1 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  [ZYPPER] Updating openSUSE repositories..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ":: Requesting administrator authorization via Polkit..."
    
    if command -v zypper >/dev/null 2>&1; then
        pkexec zypper --non-interactive update -y 2>&1 | stdbuf -oL -eL tr '\r' '\n'
        ZYP_STATUS="${PIPESTATUS[0]}"
        if [ "$ZYP_STATUS" -eq 0 ]; then
            echo ""
            echo "✓ Zypper packages updated successfully."
        else
            echo ""
            echo "✗ Zypper update finished with code: $ZYP_STATUS"
            OVERALL_STATUS=$ZYP_STATUS
        fi
    else
        echo "✗ zypper binary not found on this system."
    fi
    echo ""
fi

# 5. AUR (Arch User Repository)
if [ "$DO_AUR" -eq 1 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  [AUR] Updating Arch User Repository packages..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if command -v paru >/dev/null 2>&1; then
        echo ":: Running: paru -Sua --noconfirm --skipreview --sudo pkexec"
        paru -Sua --noconfirm --skipreview --sudo pkexec 2>&1 | stdbuf -oL -eL tr '\r' '\n'
        AUR_STATUS="${PIPESTATUS[0]}"
        if [ "$AUR_STATUS" -eq 0 ]; then
            echo ""
            echo "✓ AUR packages updated successfully."
        else
            echo ""
            echo "✗ AUR update finished with code: $AUR_STATUS"
            OVERALL_STATUS=$AUR_STATUS
        fi
    elif command -v yay >/dev/null 2>&1; then
        echo ":: Running: yay -Sua --noconfirm --answerclean None --answerdiff None --sudo pkexec"
        yay -Sua --noconfirm --answerclean None --answerdiff None --sudo pkexec 2>&1 | stdbuf -oL -eL tr '\r' '\n'
        AUR_STATUS="${PIPESTATUS[0]}"
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

# 6. FLATPAK (Flathub packages)
if [ "$DO_FLATPAK" -eq 1 ]; then
    if command -v flatpak >/dev/null 2>&1; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  [FLATPAK] Updating Flathub packages..."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        flatpak update -y 2>&1 | stdbuf -oL -eL tr '\r' '\n'
        FLAT_STATUS="${PIPESTATUS[0]}"
        if [ "$FLAT_STATUS" -eq 0 ]; then
            echo "✓ Flatpaks updated successfully."
        else
            echo "✗ Flatpak update finished with code: $FLAT_STATUS"
            OVERALL_STATUS=$FLAT_STATUS
        fi
    else
        echo ":: flatpak not found. Skipping Flatpak."
    fi
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$OVERALL_STATUS" -eq 0 ]; then
    echo "✓ All selected package sources updated successfully."
else
    echo "✗ Update process completed with errors (code $OVERALL_STATUS)."
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
exit $OVERALL_STATUS
