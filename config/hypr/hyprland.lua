-- -- -- hyprland.lua – Main configuration loader
-- Invalidate module cache on reload
for k in pairs(package.loaded) do
    if k:find("^configs%.") or k == "noctalia" then
        package.loaded[k] = nil
    end
end

-- -- -- Load all separate Lua files in order

require("configs.configs")
require("configs.environment")
require("configs.monitor")
require("configs.settings")
require("configs.decoration")
require("configs.animation")
require("configs.exec")
require("configs.keybinds")
require("configs.kaybinds-for-webapps")
require("configs.tags")
require("configs.wrules")

-- For Noctalia Color templates
require("noctalia").apply_theme()
