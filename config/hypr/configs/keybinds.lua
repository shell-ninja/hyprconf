-- keybinds.lua
-- See https://wiki.hypr.land/Configuring/Basics/Binds/

local mainMod         = "SUPER"
local ctrl            = "CTRL"
local alt             = "ALT"
local shift           = "SHIFT"

local scripts_dir     = os.getenv("HOME") .. "/.hyprconf/hypr/scripts"
local sh_dir          = scripts_dir .. "/sh"
local py_dir          = scripts_dir .. "/py"

-- Paths to scripts
local terminal        = "kitty"
local file_man        = "dolphin || thunar"
local term_file_man   = "yazi"
local wallpaper       = sh_dir .. "/Wallpaper.sh"
local help            = sh_dir .. "/keybinds.sh"
local volumeCTRL      = sh_dir .. "/volumecontrol.sh"
local brightnessCTRL  = sh_dir .. "/brightness.sh"
local qsLauncher      = sh_dir .. "/qs-launcher.sh"
local qsLauncherTheme = sh_dir .. "/qs-launcher-theme.sh"
local qsIsland        = sh_dir .. "/qs-island.sh"
local qsScreenshot    = sh_dir .. "/qs-screenshot.sh"
local qsClipboard     = sh_dir .. "/qs-clipboard.sh"
local qsEmoji         = sh_dir .. "/qs-emoji.sh"
local qsReload        = sh_dir .. "/qs-reload.sh"
local inputMethodCTRL = sh_dir .. "/input-method.sh"

-- ── Wallpaper ─────────────────────────────────────────────────────────────────
-- hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(wallpaper))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(qsIsland .. " --wallpaper"))

-- ── Screenshots / Studio ───────────────────────────────────────────────────────
hl.bind("print", hl.dsp.exec_cmd(qsScreenshot))
-- hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(sh_dir .. "/screenshot.sh area"))
-- hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(qsScreenshot))

-- ── Help ──────────────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.exec_cmd(help))

-- ── Terminal & core apps ──────────────────────────────────────────────────────
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal .. " --title main"))
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd(terminal .. " --title floating"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(file_man))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(terminal .. " --title " .. term_file_man .. " -e " .. term_file_man))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(qsClipboard))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + ALT + V", hl.dsp.exec_cmd("hyprctl dispatch workspaceopt allfloat"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(qsLauncher))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(qsLauncher))
hl.bind(mainMod .. " + ALT + D", hl.dsp.exec_cmd(qsLauncherTheme))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd(qsEmoji))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.window.pseudo())

-- ── Logout / lock ─────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd(qsIsland .. " --power"))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd(sh_dir .. "/qs-lock.sh"))

-- ── Browser / apps ───────────────────────────────────────────────────────────
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(sh_dir .. "/ide.sh"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(sh_dir .. "/browser.sh op"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("brave --incognito"))
hl.bind(alt .. " + B", hl.dsp.exec_cmd(sh_dir .. "/default_browser.sh --reset"))

-- ── Layout / config ───────────────────────────────────────────────────────────
hl.bind(ctrl .. " + Escape", hl.dsp.exec_cmd(qsReload))
hl.bind(mainMod .. " + CTRL + W", hl.dsp.exec_cmd(qsIsland .. " --wallpaper"))
hl.bind(mainMod .. " + ALT + B", hl.dsp.exec_cmd(qsReload))
hl.bind(mainMod .. " + SHIFT + comma", hl.dsp.exec_cmd(sh_dir .. "/qs-settings.sh"))
hl.bind(mainMod .. " + CTRL + R", hl.dsp.exec_cmd("hyprctl reload && notify-send 'Done' 'Hyprland reload'"))
hl.bind(ctrl .. " + U", hl.dsp.exec_cmd(py_dir .. "/pkgupdate-gui.py"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(sh_dir .. "/startup.sh &> /dev/null"))
-- hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(py_dir .. "/settings.py"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(sh_dir .. "/qs-settings.sh"))
hl.bind(mainMod .. " + F1", hl.dsp.exec_cmd(sh_dir .. "/animations_toggle.sh"))
hl.bind(mainMod .. " + CTRL + P", hl.dsp.exec_cmd(sh_dir .. "/regenerate-colors.sh"))

-- ── Window switcher / grouping ────────────────────────────────────────────────
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd(qsLauncher))

-- Cycle next window (Corrected: use hl.dsp.window.cycle_next)
hl.bind(alt .. " + Tab", hl.dsp.window.cycle_next())


-- Toggle group (Corrected: use hl.dsp.group.toggle)
hl.bind(mainMod .. " + G", hl.dsp.group.toggle())

-- Set split ratio (Corrected: use hl.dsp.layout with string argument)
hl.bind(mainMod .. " + M", hl.dsp.layout("splitratio 0.3"))

-- ── Input Method / Language Toggle ───────────────────────────────────────────
hl.bind(mainMod .. " + backslash", hl.dsp.exec_cmd(inputMethodCTRL))
hl.bind(mainMod .. " + ALT + space", hl.dsp.exec_cmd(inputMethodCTRL))
hl.bind("CTRL + space", hl.dsp.exec_cmd(inputMethodCTRL))

-- ── Audio ─────────────────────────────────────────────────────────────────────
hl.bind("F9", hl.dsp.exec_cmd(volumeCTRL .. " --toggle"), { locked = true })
hl.bind("F10", hl.dsp.exec_cmd(volumeCTRL .. " --dec"), { locked = true, repeating = true })
hl.bind("F11", hl.dsp.exec_cmd(volumeCTRL .. " --inc"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(volumeCTRL .. " --toggle"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(volumeCTRL .. " --dec"), { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(volumeCTRL .. " --inc"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(volumeCTRL .. " --toggle-mic"), { locked = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- ── Brightness ────────────────────────────────────────────────────────────────
hl.bind("F4", hl.dsp.exec_cmd(brightnessCTRL .. " up"), { locked = true, repeating = true })
hl.bind("F3", hl.dsp.exec_cmd(brightnessCTRL .. " down"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(brightnessCTRL .. " up 5"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(brightnessCTRL .. " down 5"), { locked = true, repeating = true })

-- ── Move focus (HJK + arrow keys) ───────────────────────────────────────────
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
    hl.bind(mainMod .. " + ALT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }))
end

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ── Pyprland ──────────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("pypr toggle term"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("pypr toggle_special minimized"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.workspace.toggle_special("minimized"))
hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.exec_cmd("pypr zoom ++0.5"))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("pypr zoom"))
