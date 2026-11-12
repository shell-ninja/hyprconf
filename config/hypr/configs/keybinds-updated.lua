-- keybinds-updated.lua
-- Consolidated reference of all keybindings added or changed since keybinds_v1.0.0.lua.
-- Organized by release so upgrading users can copy new shortcuts directly into:
--   ~/.local/share/hyprconf/keybinds.lua

local mainMod         = "SUPER"
local ctrl            = "CTRL"
local alt             = "ALT"
local shift           = "SHIFT"

local scripts_dir     = os.getenv("HOME") .. "/.hyprconf/hypr/scripts"
local sh_dir          = scripts_dir .. "/sh"

local qsLauncher      = sh_dir .. "/qs-launcher.sh"
local qsWallpaper     = sh_dir .. "/qs-wallpaper.sh"
local qsPower         = sh_dir .. "/qs-power.sh"
local qsScreenshot    = sh_dir .. "/qs-screenshot.sh"
local qsClipboard     = sh_dir .. "/qs-clipboard.sh"
local qsQuickPaste    = sh_dir .. "/qs-quickpaste.sh"
local qsReload        = sh_dir .. "/qs-reload.sh"
local qsBar           = sh_dir .. "/qs-bar.sh"

-- ══ qs-v1.0.1 — Added & Updated Keybinds ════════════════════════════════════
-- Screenshots: added Super+End and Super+Shift+S alongside Print
hl.bind(mainMod .. " + end", hl.dsp.exec_cmd(qsScreenshot))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(qsScreenshot))

-- Clipboard Manager: moved from Super+Shift+C to Super+Alt+C
hl.bind(mainMod .. " + ALT + C", hl.dsp.exec_cmd(qsClipboard))

-- Application Dock: added visibility toggle
hl.bind(mainMod .. " + ALT + SPACE", hl.dsp.exec_cmd(sh_dir .. "/qs-dock.sh --toggle"))

-- Package Updater: migrated from py/pkgupdate-gui.py to native Quickshell updater
hl.bind(ctrl .. " + U", hl.dsp.exec_cmd(sh_dir .. "/qs-updater.sh"))

-- ══ qs-v1.0.2 — New & Updated Keybinds ════════════════════════════════════════
-- Quick Paste Tooltip: cursor-anchored popup of recent text/link clips on Super+V
-- (Window float toggle moved from Super+V to Super+Shift+V)
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(qsQuickPaste))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.window.float({ action = "toggle" }))

-- Spotlight Omnibar: Super+Space opens launcher directly in Spotlight mode
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(qsLauncher .. " --spotlight"))

-- Keybinds Cheatsheet: added Super+/ alias and standardized qs-keybinds launcher
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd(sh_dir .. "/qs-keybinds.sh"))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.exec_cmd(sh_dir .. "/qs-keybinds.sh"))

-- Wallpaper Studio & Power Menu: standalone Quickshell modals replacing Island subviews
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(qsWallpaper))
hl.bind(mainMod .. " + CTRL + W", hl.dsp.exec_cmd(qsWallpaper))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd(qsPower))

-- Top Bar / Dynamic Island Toggle
hl.bind(mainMod .. " + CTRL + B", hl.dsp.exec_cmd(qsBar .. " --toggle"))

-- System & Game Modes
hl.bind(mainMod .. " + ALT + G", hl.dsp.exec_cmd(sh_dir .. "/gamemode.sh --toggle"))
hl.bind(mainMod .. " + ALT + M", hl.dsp.exec_cmd(sh_dir .. "/system-mode.sh --cycle"))

-- 3D Card Tilt Plugin (hyprtilt)
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("hyprctl hyprtilt toggle"))
-- Optional Lua plugin toggle callbacks:
-- hl.bind(mainMod .. " + T", function()
--     if hl.plugin and hl.plugin.hyprtilt and hl.plugin.hyprtilt.toggle then
--         local enabled = hl.plugin.hyprtilt.toggle()
--         local msg = enabled and "3D Perspective Tilt: ON" or "3D Perspective Tilt: OFF"
--         hl.exec_cmd("notify-send -t 1500 'hyprtilt' '" .. msg .. "' -i preferences-desktop-theme")
--     end
-- end)
-- hl.bind(mainMod .. " + ALT + T", function()
--     if hl.plugin and hl.plugin.hyprtilt and hl.plugin.hyprtilt.toggle then
--         local enabled = hl.plugin.hyprtilt.toggle()
--         local msg = enabled and "3D Perspective Tilt: ON" or "3D Perspective Tilt: OFF"
--         hl.exec_cmd("notify-send -t 1500 'hyprtilt' '" .. msg .. "' -i preferences-desktop-theme")
--     end
-- end)
