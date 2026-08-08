#!/bin/bash

# Polkit possible paths files to check
polkit=(
    "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
    "/usr/libexec/hyprpolkitagent"
    "/usr/lib/hyprpolkitagent"
    "/usr/lib/hyprpolkitagent/hyprpolkitagent"
    "/usr/lib/polkit-kde-authentication-agent-1"
    "/usr/lib/polkit-gnome-authentication-agent-1"
    "/usr/libexec/polkit-gnome-authentication-agent-1"
    "/usr/libexec/polkit-mate-authentication-agent-1"
    "/usr/lib/x86_64-linux-gnu/libexec/polkit-kde-authentication-agent-1"
    "/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1"
    "/usr/lib/xfce-polkit/xfce-polkit"
    "/usr/libexec/xfce-polkit"
)

# Launch the first polkit agent found; exec replaces this shell process
for file in "${polkit[@]}"; do
    if [[ -x "$file" ]]; then
        exec "$file"
    fi
done

echo "[polkit.sh] Warning: No polkit authentication agent found!" >&2
exit 1
