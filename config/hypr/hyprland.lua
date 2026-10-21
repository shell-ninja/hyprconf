-- -- -- hyprland.lua – Main configuration loader
-- Invalidate module cache on reload
for k in pairs(package.loaded) do
    if k:find("^configs%.") or k == "theme" then
        package.loaded[k] = nil
    end
end

-- -- -- Load all separate Lua files in order

require("configs.configs")
require("configs.environment")
local user_monitor = (os.getenv("HOME") or "") .. "/.local/share/hyprconf/monitor.lua"
if not pcall(dofile, user_monitor) then
    require("configs.monitor")
end
require("configs.settings")
require("configs.decoration")
require("configs.animation")
require("configs.exec")
local user_keybinds = (os.getenv("HOME") or "") .. "/.local/share/hyprconf/keybinds.lua"
if not pcall(dofile, user_keybinds) then
    require("configs.keybinds")
end
require("configs.kaybinds-for-webapps")
require("configs.tags")
require("configs.wrules")

-- Dynamic Obsidian Palette Theme
local status, theme = pcall(require, "theme")
if status and theme.apply_theme then
    theme.apply_theme()
end
