-- keybinds.lua
-- See https://wiki.hypr.land/Configuring/Basics/Binds/

local mainMod         = "SUPER"
local ctrl            = "CTRL"
local alt             = "ALT"
local shift           = "SHIFT"

local scripts_dir     = os.getenv("HOME") .. "/.hyprconf/hypr/scripts"

-- Paths to scripts
local terminal        = "kitty"
local file_man        = "dolphin || thunar"
local term_file_man   = "yazi"
local wallpaper       = scripts_dir .. "/Wallpaper.sh"
local wallpaperSelect = scripts_dir .. "/WallpaperSelect.sh"
local rofi_emoji      = scripts_dir .. "/rofi-emoji.sh"
local help            = scripts_dir .. "/keybinds.sh"
local volumeCTRL      = scripts_dir .. "/volumecontrol.sh"
local brightnessCTRL  = scripts_dir .. "/brightness.sh"

-- ── Wallpaper ─────────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(wallpaper))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(wallpaperSelect .. " thm1"))
hl.bind(mainMod .. " + CTRL + SHIFT + W", hl.dsp.exec_cmd(wallpaperSelect .. " thm2"))

-- ── Screenshots / Secure mode ─────────────────────────────────────────────────
hl.bind("print", hl.dsp.exec_cmd(scripts_dir .. "/screenshot.sh"))
hl.bind("F8", hl.dsp.exec_cmd(scripts_dir .. "/secure_mode.sh"))

-- ── Help ──────────────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.exec_cmd(help))

-- ── Terminal & core apps ──────────────────────────────────────────────────────
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal .. " --title main"))
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd(terminal .. " --title floating"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(file_man))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(terminal .. " --title " .. term_file_man .. " -e " .. term_file_man))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + ALT + V", hl.dsp.exec_cmd("hyprctl dispatch workspaceopt allfloat"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(scripts_dir .. "/menu.sh || pkill rofi"))
hl.bind(mainMod .. " + ALT + D", hl.dsp.exec_cmd(scripts_dir .. "/rofi_theme.sh"))
hl.bind(mainMod .. " + ALT + C", hl.dsp.exec_cmd(scripts_dir .. "/cliphist.sh c"))
hl.bind(mainMod .. " + ALT + W", hl.dsp.exec_cmd(scripts_dir .. "/cliphist.sh w"))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd(rofi_emoji))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.window.pseudo())

-- ── Logout / lock ─────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd(scripts_dir .. "/wlogout.sh 2"))
hl.bind(mainMod .. " + ALT + X", hl.dsp.exec_cmd(scripts_dir .. "/wlogout.sh 1"))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.exec_cmd(scripts_dir .. "/hyprlock.sh"))

-- ── Browser / apps ───────────────────────────────────────────────────────────
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("code || codium"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(scripts_dir .. "/browser.sh op"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("brave --incognito"))
hl.bind(alt .. " + B", hl.dsp.exec_cmd(scripts_dir .. "/default_browser.sh --reset"))

-- ── Waybar ────────────────────────────────────────────────────────────────────
hl.bind(ctrl .. " + ESCAPE", hl.dsp.exec_cmd(scripts_dir .. "/waybar-reload.sh --reload"))
hl.bind(ctrl .. " + ALT + ESCAPE", hl.dsp.exec_cmd(scripts_dir .. "/waybar-reload.sh --toggle"))

-- ── Layout / config ───────────────────────────────────────────────────────────
hl.bind(mainMod .. " + CTRL + W", hl.dsp.exec_cmd(scripts_dir .. "/waybar-layout.sh"))
hl.bind(mainMod .. " + CTRL + E", hl.dsp.exec_cmd(scripts_dir .. "/edit-dotfiles.sh"))
hl.bind(mainMod .. " + ALT + B", hl.dsp.exec_cmd(scripts_dir .. "/shell.sh"))
hl.bind(mainMod .. " + CTRL + R", hl.dsp.exec_cmd("hyprctl reload && notify-send 'Done' 'Hyprland reload'"))
hl.bind(ctrl .. " + U", hl.dsp.exec_cmd(scripts_dir .. "/systemupdate.sh --update"))
hl.bind(mainMod .. " + CTRL + U", hl.dsp.exec_cmd("kitty --title browser sh -c '" .. scripts_dir .. "/hyprconf.sh'"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(scripts_dir .. "/startup.sh &> /dev/null"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("kitty --title browser sh -c '" .. scripts_dir .. "/settings.sh'"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(scripts_dir .. "/dark_light.sh"))
hl.bind(mainMod .. " + ALT + U", hl.dsp.exec_cmd("kitty sh -c '" .. scripts_dir .. "/uninstall.sh'"))
hl.bind(mainMod .. " + F1", hl.dsp.exec_cmd(scripts_dir .. "/animations_toggle.sh"))
hl.bind(mainMod .. " + CTRL + P", hl.dsp.exec_cmd(scripts_dir .. "/regenerate-colors.sh"))

-- ── Window switcher / grouping ────────────────────────────────────────────────
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("rofi -show window -theme ~/.config/rofi/themes/rofi-window.rasi"))

-- Cycle next window (Corrected: use hl.dsp.window.cycle_next)
hl.bind(alt .. " + Tab", hl.dsp.window.cycle_next())

-- Toggle group (Corrected: use hl.dsp.group.toggle)
hl.bind(mainMod .. " + G", hl.dsp.group.toggle())

-- Set split ratio (Corrected: use hl.dsp.layout with string argument)
hl.bind(mainMod .. " + M", hl.dsp.layout("splitratio 0.3"))

-- ── Audio ─────────────────────────────────────────────────────────────────────
hl.bind("F9", hl.dsp.exec_cmd(volumeCTRL .. " --toggle"), { locked = true })
hl.bind("F10", hl.dsp.exec_cmd(volumeCTRL .. " --dec"), { locked = true, repeating = true })
hl.bind("F11", hl.dsp.exec_cmd(volumeCTRL .. " --inc"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(volumeCTRL .. " --toggle"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(volumeCTRL .. " --dec"), { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(volumeCTRL .. " --inc"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- ── Brightness ────────────────────────────────────────────────────────────────
hl.bind("F4", hl.dsp.exec_cmd(brightnessCTRL .. " up"), { locked = true, repeating = true })
hl.bind("F3", hl.dsp.exec_cmd(brightnessCTRL .. " down"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- ── Move focus (HJKL + arrow keys) ───────────────────────────────────────────
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- ── Move windows ─────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.move({ direction = "down" }))

-- ── Resize windows (arrow keys) ───────────────────────────────────────────────
hl.bind(mainMod .. " + left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }))
hl.bind(mainMod .. " + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }))
hl.bind(mainMod .. " + up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }))
hl.bind(mainMod .. " + down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }))

-- ── Resize windows (vim keys) ───────────────────────────────────────────────
hl.bind(mainMod .. " + ALT + h", hl.dsp.window.resize({ x = -50, y = 0, relative = true }))
hl.bind(mainMod .. " + ALT + l", hl.dsp.window.resize({ x = 50, y = 0, relative = true }))
hl.bind(mainMod .. " + ALT + k", hl.dsp.window.resize({ x = 0, y = -50, relative = true }))
hl.bind(mainMod .. " + ALT + j", hl.dsp.window.resize({ x = 0, y = 50, relative = true }))

-- ── Workspaces 1–10 ──────────────────────────────────────────────────────────
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
    hl.bind(mainMod .. " + ALT + " .. key, hl.dsp.window.move({ workspace = i, silent = true }))
end

-- Scroll through workspaces with mouse wheel
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- ── Mouse move / resize windows ──────────────────────────────────────────────
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ── Pyprland ──────────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("pypr toggle term"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("pypr toggle_special minimized"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.workspace.toggle_special("minimized"))
hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.exec_cmd("pypr zoom ++0.5"))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("pypr zoom"))
