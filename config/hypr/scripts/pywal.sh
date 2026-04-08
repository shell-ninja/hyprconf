#!/bin/bash
# pywal.sh — Apply pywal colors and propagate to all apps.

scripts_dir="$HOME/.config/hypr/scripts"
cache_dir="$HOME/.config/hypr/.cache"
current_wallpaper="$cache_dir/current_wallpaper.png"
colors_file="$HOME/.cache/wal/colors.json"
mode_file="$cache_dir/.current_mode"

# ── 1. Generate colors ────────────────────────────────────────────────────────
if [[ -f "$current_wallpaper" ]]; then
    rm -rf "$HOME/.cache/wal/schemes"
    current_mode=$(cat "$mode_file" 2>/dev/null || echo "dark")
    if [[ "$current_mode" == "light" ]]; then
        wal -q -e -l -i "$current_wallpaper"
    else
        wal -q -e -i "$current_wallpaper"
    fi
fi

# Guard: abort if colors weren't generated
[[ ! -f "$colors_file" ]] && echo "Colors file not found!" && exit 1

# ── 2. Parse ALL colors from JSON in a single jq call ─────────────────────────
read -r background_color foreground_color \
         color0 color1 color2 color3 color4 color5 color6 color7 \
    < <(jq -r '[
        .special.background,
        .special.foreground,
        .colors.color0, .colors.color1, .colors.color2, .colors.color3,
        .colors.color4, .colors.color5, .colors.color6, .colors.color7
    ] | @tsv' "$colors_file")

# ── 3. Symlink theme files ────────────────────────────────────────────────────
ln -sf "$HOME/.cache/wal/colors-hyprland.conf"    "$HOME/.config/hypr/configs/"
ln -sf "$HOME/.cache/wal/colors-kitty.conf"       "$HOME/.config/kitty/"
ln -sf "$HOME/.cache/wal/colors-rofi-dark.rasi"  "$HOME/.config/rofi/themes/rofi-colors.rasi"
ln -sf "$HOME/.cache/wal/colors-waybar.css"       "$HOME/.config/waybar/style/theme.css"
ln -sf "$HOME/.cache/wal/colors-waybar.css"       "$HOME/.config/wlogout/colors.css"
[[ -n "$(command -v swaync)" ]] && \
    ln -sf "$HOME/.cache/wal/colors-swaync.css"   "$HOME/.config/swaync/colors.css"

# ── 4. Kitty border colors ────────────────────────────────────────────────────
kitty_colors="$HOME/.cache/wal/colors-kitty.conf"
kitty_conf="$HOME/.config/kitty/kitty.conf"

active_border_color=$(awk '/^foreground/ {print $2; exit}' "$kitty_colors")
inactive_border_color=$(awk '/^color5/ {print $2; exit}' "$kitty_colors")

sed -i \
    -e "s/active_border_color .*$/active_border_color $active_border_color/" \
    -e "s/inactive_border_color .*$/inactive_border_color $inactive_border_color/" \
    "$kitty_conf"

# Reload kitty (only if running)
kitty_pid=$(pidof kitty)
[[ -n "$kitty_pid" ]] && kill -SIGUSR1 $kitty_pid

# ── 5. Gum UI colors (batch sed per script) ───────────────────────────────────
sysupd_script="$scripts_dir/pkgupdate.sh"
monitor_script="$scripts_dir/monitor.sh"
settings_script="$scripts_dir/settings.sh"
avatar_script="$scripts_dir/sddm_avatar.sh"

sed -i \
    -e "s/--prompt.foreground .*/--prompt.foreground \"$foreground_color\" \\\\/" \
    -e "s/--selected.background .*/--selected.background \"$foreground_color\" \\\\/" \
    -e "s/--selected.foreground .*/--selected.foreground \"$background_color\" \\\\/" \
    -e "s/--spinner.foreground .*/--spinner.foreground \"$foreground_color\" \\\\/" \
    "$sysupd_script"

sed -i \
    -e "s/--spinner.foreground .*/--spinner.foreground \"$foreground_color\" \\\\/" \
    -e "s/--title.foreground .*/--title.foreground \"$foreground_color\" \\\\/" \
    -e "s/--header.foreground .*/--header.foreground \"$foreground_color\" \\\\/" \
    -e "s/--selected.foreground .*/--selected.foreground \"$foreground_color\" \\\\/" \
    -e "s/--cursor.foreground .*/--cursor.foreground \"$foreground_color\" \\\\/" \
    "$monitor_script"

sed -i \
    -e "s/--header.foreground .*/--header.foreground \"$foreground_color\" \\\\/" \
    -e "s/--cursor.foreground .*/--cursor.foreground \"$foreground_color\" \\\\/" \
    "$settings_script"

sed -i \
    -e "s/--header.foreground .*/--header.foreground \"$foreground_color\" \\\\/" \
    -e "s/--placeholder.foreground .*/--placeholder.foreground \"$foreground_color\" \\\\/" \
    "$avatar_script"

# ── 6. Dunst colors ───────────────────────────────────────────────────────────
if [[ -n "$(command -v dunst)" ]]; then
    dunst_file="$HOME/.config/dunst/dunstrc"
    if [[ -f "$dunst_file" ]]; then
        sed -i \
            -e "s/frame_color = .*/frame_color = \"$foreground_color\"/" \
            -e "/^\[urgency_low\]/,/^\[/ s/^    background = .*/    background = \"$color0\"/" \
            -e "/^\[urgency_low\]/,/^\[/ s/^    foreground = .*/    foreground = \"$color7\"/" \
            -e "/^\[urgency_normal\]/,/^\[/ s/^    background = .*/    background = \"${background_color}80\"/" \
            -e "/^\[urgency_normal\]/,/^\[/ s/^    foreground = .*/    foreground = \"$foreground_color\"/" \
            -e "/^\[urgency_critical\]/,/^\[/ s/^    foreground = .*/    foreground = \"$foreground_color\"/" \
            "$dunst_file"
    fi
fi

# ── 7. VS Code colors ─────────────────────────────────────────────────────────
if [[ -n "$(command -v code)" ]]; then
    codeOss="$HOME/.config/Code/User/settings.json"
    if [[ -f "$codeOss" ]]; then
        sed -i \
            -e "s/\"editor.background\":\ \".*\"/\"editor.background\": \"$background_color\"/" \
            -e "s/\"sideBar.background\":\ \".*\"/\"sideBar.background\": \"$background_color\"/" \
            -e "s/\"sideBar.border\":\ \".*\"/\"sideBar.border\": \"$background_color\"/" \
            -e "s/\"sideBar.foreground\":\ \".*\"/\"sideBar.foreground\": \"$foreground_color\"/" \
            -e "s/\"editorGroupHeader.tabsBackground\":\ \".*\"/\"editorGroupHeader.tabsBackground\": \"$background_color\"/" \
            -e "s/\"activityBar.background\":\ \".*\"/\"activityBar.background\": \"$background_color\"/" \
            -e "s/\"activityBar.border\":\ \".*\"/\"activityBar.border\": \"$background_color\"/" \
            -e "s/\"activityBar.foreground\":\ \".*\"/\"activityBar.foreground\": \"$foreground_color\"/" \
            -e "s/\"tab.activeBackground\":\ \".*\"/\"tab.activeBackground\": \"$background_color\"/" \
            -e "s/\"tab.activeForeground\":\ \".*\"/\"tab.activeForeground\": \"$foreground_color\"/" \
            -e "s/\"tab.activeBorder\":\ \".*\"/\"tab.activeBorder\": \"$background_color\"/" \
            -e "s/\"tab.border\":\ \".*\"/\"tab.border\": \"$background_color\"/" \
            -e "s/\"tab.inactiveBackground\":\ \".*\"/\"tab.inactiveBackground\": \"$background_color\"/" \
            -e "s/\"tab.inactiveForeground\":\ \".*\"/\"tab.inactiveForeground\": \"$foreground_color\"/" \
            -e "s/\"terminal.foreground\":\ \".*\"/\"terminal.foreground\": \"$foreground_color\"/" \
            -e "s/\"terminal.background\":\ \".*\"/\"terminal.background\": \"$background_color\"/" \
            "$codeOss"
    fi
fi

# ── 8. Reload everything ──────────────────────────────────────────────────────
sleep 0.3
"${scripts_dir}/Refresh.sh"
