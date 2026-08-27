# Production Migration TODO List: Noctalia Shell Integration

This guide provides a detailed, step-by-step checklist to transfer all Noctalia Shell configurations, bar presets, launcher themes, scripts, and Hyprland modifications from this test setup into your **actual production `hyprconf` repository**.

---

## 📋 Table of Contents
1. [Overview of All Affected Files](#1-overview-of-all-affected-files)
2. [Step 1: Copy Entire Directories & New Files](#step-1-copy-entire-directories--new-files)
3. [Step 2: Symlink Configuration](#step-2-symlink-configuration)
4. [Step 3: Exact Edits for Existing Files](#step-3-exact-edits-for-existing-files)
   - [A. `hypr/configs/wrules.lua`](#a-hyprconfigswruleslua)
   - [B. `hypr/configs/keybinds.lua`](#b-hyprconfigskeybindslua)
   - [C. `hypr/configs/exec.lua`](#c-hyprconfigsexeclua)
   - [D. `hypr/scripts/menu.sh`](#d-hyprscriptsmenush)
   - [E. `hypr/scripts/Wallpaper.sh`](#e-hyprscriptswallpapersh)
   - [F. `hypr/scripts/Refresh.sh`](#f-hyprscriptsrefreshsh)
5. [Step 4: Permissions & Verification Checklist](#step-4-permissions--verification-checklist)

---

## 1. Overview of All Affected Files

### 🆕 New Files & Directories Created:
- `noctalia/` (Full configuration root)
  - `noctalia/00-shell.toml`
  - `noctalia/10-theme.toml`
  - `noctalia/20-bar.toml`
  - `noctalia/30-launcher.toml`
  - `noctalia/40-services.toml`
  - `noctalia/bars/` (`rounded-top.toml`, `dual-tone-top.toml`, `full-top.toml`, `minimal-bottom.toml`, `bar-left.toml`)
  - `noctalia/launchers/` (`spotlight-glass.toml`, `grid.toml`, `compact-list.toml`, `sidebar-attached.toml`)
- `hypr/scripts/noctalia-bar.sh` (Interactive bar switcher)
- `hypr/scripts/noctalia-launcher.sh` (Interactive launcher switcher)
- `hypr/scripts/shell.sh` (Desktop shell switcher)

### ✏️ Modified Existing Files:
- `hypr/configs/wrules.lua` (Added layer & window rules)
- `hypr/configs/keybinds.lua` (Added shortcuts for Noctalia launcher, control center, bar picker, settings)
- `hypr/configs/exec.lua` (Updated autostart to start Noctalia via `shell.sh`)
- `hypr/scripts/menu.sh` (Added Noctalia launcher toggle with fallback)
- `hypr/scripts/Wallpaper.sh` (Added Noctalia wallpaper update hook)
- `hypr/scripts/Refresh.sh` (Prevented duplicate notification daemon spawn when Noctalia runs)

---

## Step 1: Copy Entire Directories & New Files

If your production repository is located at `<PROD_DIR>` (e.g. `/path/to/your/hyprconf`), run the following copy commands:

```bash
# Set your target production hyprconf directory
PROD_HYPRCONF="/path/to/your/actual/hyprconf"

# 1. Copy the entire noctalia directory (configs, bars, and launchers)
cp -r /home/noct-conf/.hyprconf/noctalia "$PROD_HYPRCONF/"

# 2. Copy the new switcher scripts
cp /home/noct-conf/.hyprconf/hypr/scripts/noctalia-bar.sh "$PROD_HYPRCONF/hypr/scripts/"
cp /home/noct-conf/.hyprconf/hypr/scripts/noctalia-launcher.sh "$PROD_HYPRCONF/hypr/scripts/"
cp /home/noct-conf/.hyprconf/hypr/scripts/shell.sh "$PROD_HYPRCONF/hypr/scripts/"

# 3. Make sure scripts have execution permissions
chmod +x "$PROD_HYPRCONF/hypr/scripts/noctalia-bar.sh"
chmod +x "$PROD_HYPRCONF/hypr/scripts/noctalia-launcher.sh"
chmod +x "$PROD_HYPRCONF/hypr/scripts/shell.sh"
```

---

## Step 2: Symlink Configuration

Ensure your system's `~/.config/noctalia` points to your production `noctalia/` folder:

```bash
# Remove any default empty directory and symlink to your dotfiles
rm -rf ~/.config/noctalia
ln -sf "$PROD_HYPRCONF/noctalia" ~/.config/noctalia
```

---

## Step 3: Exact Edits for Existing Files

Below are the exact line additions or replacements for the 6 modified files in your production repo:

---

### A. `hypr/configs/wrules.lua`

Add the Noctalia Settings floating rule and Noctalia Layer rules at the bottom:

```lua
-- Window rule for Noctalia GUI Settings
hl.window_rule({ match = { class = "^(dev\\.noctalia\\.Noctalia)$" }, float = true, size = "monitor_w*0.6 monitor_h*0.75", center = true })

-- Layer rules for Noctalia surfaces (Bar, Launcher, Control Center, OSD, Notifications, Screen Corners)
hl.layer_rule({
    match = { namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher|screen-corner)$" },
    no_anim = true,
    ignore_alpha = 0.5,
    blur = true,
    blur_popups = true,
})
```

---

### B. `hypr/configs/keybinds.lua`

Replace the launcher, bar picker, settings, and window switcher bindings with the following:

```lua
-- Launcher on Super+D and Super+Space
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(scripts_dir .. "/menu.sh || pkill rofi"))
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(scripts_dir .. "/menu.sh"))

-- Launcher Theme Switcher (Noctalia / Rofi fallback)
hl.bind(mainMod .. " + ALT + D", hl.dsp.exec_cmd("if pgrep -x noctalia >/dev/null; then " .. scripts_dir .. "/noctalia-launcher.sh; else " .. scripts_dir .. "/rofi_theme.sh; fi"))

-- Clipboard (Noctalia / cliphist fallback)
hl.bind(mainMod .. " + ALT + C", hl.dsp.exec_cmd("if pgrep -x noctalia >/dev/null; then noctalia msg panel-toggle clipboard; else " .. scripts_dir .. "/cliphist.sh c; fi"))

-- Bar Layout Switcher (Noctalia / Waybar fallback)
hl.bind(mainMod .. " + CTRL + W", hl.dsp.exec_cmd("if pgrep -x noctalia >/dev/null; then " .. scripts_dir .. "/noctalia-bar.sh; else " .. scripts_dir .. "/waybar-layout.sh; fi"))

-- Noctalia GUI Settings & Control Center
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd("noctalia msg settings-toggle"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center"))

-- Desktop Shell Switcher (Toggle Noctalia <-> Waybar + SwayNC)
hl.bind(mainMod .. " + ALT + B", hl.dsp.exec_cmd(scripts_dir .. "/shell.sh"))

-- Window Switcher (Noctalia / Rofi fallback)
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("if pgrep -x noctalia >/dev/null; then noctalia msg window-switcher; else rofi -show window -theme ~/.config/rofi/themes/rofi-window.rasi; fi"))
```

---

### C. `hypr/configs/exec.lua`

Update the autostart section inside `hl.on("hyprland.start", ...)`:

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
    hl.exec_cmd(scripts_dir .. "/startup.sh")
    hl.exec_cmd(scripts_dir .. "/shell.sh --noctalia")
    hl.exec_cmd("hypridle &")
    hl.exec_cmd("blueman-applet &")
    hl.exec_cmd(scripts_dir .. "/polkit.sh")
    hl.exec_cmd("wl-paste --type text  --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("pypr &")
end)
```

---

### D. `hypr/scripts/menu.sh`

Prepend the Noctalia check to trigger Noctalia's launcher when running:

```bash
#!/usr/bin/env bash

if pgrep -x "noctalia" >/dev/null 2>&1; then
    noctalia msg panel-toggle launcher
    exit 0
fi

dir="$HOME/.config/rofi/menu"
theme='style-5'

## Run
rofi \
    -show drun \
    -theme ${dir}/${theme}.rasi
```

---

### E. `hypr/scripts/Wallpaper.sh`

Add the Noctalia wallpaper IPC update right after `set_wallpaper`:

```bash
start_daemon
set_wallpaper "$wallpaper"

# Notify Noctalia shell if active
if pgrep -x "noctalia" >/dev/null 2>&1; then
    noctalia msg wallpaper-set "$wallpaper" &>/dev/null || true
fi

# wallcache.sh is called by pywal.sh — no need to call it here too
"$scripts_dir/pywal.sh"
```

---

### F. `hypr/scripts/Refresh.sh`

Prevent starting conflicting notification daemons if Noctalia is already handling notifications:

```bash
#!/bin/bash
# Refresh.sh — Restart notification daemon and reload Hyprland.

# Kill running daemons
_ps=(dunst swaync rofi)
for _prs in "${_ps[@]}"; do
    pidof "${_prs}" &>/dev/null && pkill -SIGTERM "${_prs}"
done

sleep 0.4

# Start notification daemon if Noctalia is not running
if ! pgrep -x "noctalia" >/dev/null 2>&1; then
    if [[ -n "$(command -v swaync)" ]]; then
        swaync &
    elif [[ -n "$(command -v dunst)" ]]; then
        dunst &
    fi
fi
hyprctl reload

exit 0
```

---

## Step 4: Permissions & Verification Checklist

Once files are copied and edited in your production repository, run these verification checks:

- [ ] **Validate TOML syntax**:
  ```bash
  noctalia config validate "$PROD_HYPRCONF/noctalia"
  ```
  *(Should output: `✓ Config is valid`)*

- [ ] **Check Shell Scripts Syntax**:
  ```bash
  bash -n "$PROD_HYPRCONF/hypr/scripts/noctalia-bar.sh"
  bash -n "$PROD_HYPRCONF/hypr/scripts/noctalia-launcher.sh"
  bash -n "$PROD_HYPRCONF/hypr/scripts/shell.sh"
  bash -n "$PROD_HYPRCONF/hypr/scripts/Wallpaper.sh"
  bash -n "$PROD_HYPRCONF/hypr/scripts/Refresh.sh"
  bash -n "$PROD_HYPRCONF/hypr/scripts/menu.sh"
  ```

- [ ] **Test Symlink**:
  ```bash
  ls -ld ~/.config/noctalia
  ```

- [ ] **Test Interactive Pickers**:
  - Test Bar switcher: `SUPER + CTRL + W`
  - Test Launcher switcher: `SUPER + ALT + D`
  - Test Shell toggle: `SUPER + ALT + B`
  - Test Settings GUI: `SUPER + ,`
