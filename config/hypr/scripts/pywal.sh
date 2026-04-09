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

# ── 8. GTK Themes Setup ─────────────────────────────────────────────────────────
# Force GTK3 schema to FlatColor which natively imports .cache/wal
gsettings set org.gnome.desktop.interface gtk-theme "FlatColor"
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"

# Dynamically map Pywal to Libadwaita for modern GTK4 Apps
mkdir -p "$HOME/.config/gtk-4.0"
cat <<EOF > "$HOME/.config/gtk-4.0/gtk.css"
@import url("file://$HOME/.cache/wal/colors-waybar.css");

@define-color window_bg_color @background;
@define-color window_fg_color @foreground;
@define-color view_bg_color @background;
@define-color view_fg_color @foreground;
@define-color headerbar_bg_color @color0;
@define-color headerbar_fg_color @foreground;
@define-color popover_bg_color @background;
@define-color popover_fg_color @foreground;
@define-color dialog_bg_color @background;
@define-color dialog_fg_color @foreground;
@define-color accent_color @color4;
@define-color accent_bg_color @color4;
@define-color accent_fg_color @background;
EOF

# Dynamically map Pywal to Qt5/Qt6 Palette
mkdir -p "$HOME/.config/qt5ct/colors" "$HOME/.config/qt6ct/colors"
cat <<EOF > "$HOME/.config/qt5ct/colors/Pywal.conf"
[ColorScheme]
active_colors=${foreground_color}, ${background_color}, ${color1}, ${color2}, ${color3}, ${color4}, ${foreground_color}, ${color5}, ${foreground_color}, ${background_color}, ${background_color}, ${color0}, ${color4}, ${background_color}, ${color6}, ${color5}, ${color0}, ${foreground_color}, ${background_color}, ${foreground_color}, ${color8}
inactive_colors=${foreground_color}, ${background_color}, ${color1}, ${color2}, ${color3}, ${color4}, ${foreground_color}, ${color5}, ${foreground_color}, ${background_color}, ${background_color}, ${color0}, ${color4}, ${background_color}, ${color6}, ${color5}, ${color0}, ${foreground_color}, ${background_color}, ${foreground_color}, ${color8}
disabled_colors=${color8}, ${background_color}, ${color1}, ${color2}, ${color3}, ${color4}, ${color8}, ${color8}, ${color8}, ${background_color}, ${background_color}, ${color0}, ${color4}, ${background_color}, ${color6}, ${color5}, ${color0}, ${foreground_color}, ${background_color}, ${color8}, ${color8}
EOF
cp "$HOME/.config/qt5ct/colors/Pywal.conf" "$HOME/.config/qt6ct/colors/Pywal.conf" 2>/dev/null || true

# Hook Pywal.conf to active Qt configs
for qt_conf in "$HOME/.config/qt5ct/qt5ct.conf" "$HOME/.config/qt6ct/qt6ct.conf"; do
    if [[ -f "\$qt_conf" ]]; then
        sed -i "s|^color_scheme_path=.*|color_scheme_path=$HOME/.config/qt5ct/colors/Pywal.conf|g" "\$qt_conf"
    fi
done

# ── 9. Neovim pywal colors ───────────────────────────────────────────────────
nvim_colors="$HOME/.cache/wal/colors-nvim.lua"

# Parse all 16 colors + special from JSON in one jq call
read -r \
    _bg _fg _cur \
    _c0 _c1 _c2 _c3 _c4 _c5 _c6 _c7 \
    _c8 _c9 _c10 _c11 _c12 _c13 _c14 _c15 \
    < <(jq -r '[
        .special.background, .special.foreground, .special.cursor,
        .colors.color0,  .colors.color1,  .colors.color2,  .colors.color3,
        .colors.color4,  .colors.color5,  .colors.color6,  .colors.color7,
        .colors.color8,  .colors.color9,  .colors.color10, .colors.color11,
        .colors.color12, .colors.color13, .colors.color14, .colors.color15
    ] | @tsv' "$colors_file")

# Write the Lua color table that pywal-wal.lua will dofile()
cat > "$nvim_colors" <<LUA
-- Auto-generated by pywal.sh — do not edit manually.
-- Sourced by ~/.config/nvim/lua/shell-ninja/plugins/pywal-wal.lua
return {
  bg  = "$_bg",
  fg  = "$_fg",
  cur = "$_cur",
  c0  = "$_c0",
  c1  = "$_c1",
  c2  = "$_c2",
  c3  = "$_c3",
  c4  = "$_c4",
  c5  = "$_c5",
  c6  = "$_c6",
  c7  = "$_c7",
  c8  = "$_c8",
  c9  = "$_c9",
  c10 = "$_c10",
  c11 = "$_c11",
  c12 = "$_c12",
  c13 = "$_c13",
  c14 = "$_c14",
  c15 = "$_c15",
}
LUA

# Live-reload all running nvim instances via their Unix sockets
for sock in /run/user/$(id -u)/nvim.*.0 /tmp/nvim*/nvim.*.0 "$XDG_RUNTIME_DIR"/nvim.*.0; do
    [[ -S "$sock" ]] && nvim --server "$sock" \
        --remote-send '<Esc>:doautocmd User PywalReload<CR>' 2>/dev/null &
done

# ── 10. Reload everything ─────────────────────────────────────────────────────
sleep 0.3
"${scripts_dir}/Refresh.sh"
