-- configs.lua
-- Shared visual configuration variables.
-- Colors imported from theme.lua
local status, theme = pcall(require, "theme")
local colors        = theme.colors

opacity_act         = 0.95
opacity_deact       = 0.88
blur_size           = 4
blur_pass           = 2
shadow_range        = 0
rounding            = 14
border              = 2
inner_gap           = 5
outer_gap           = 10

-- Border and theme colors from Noctalia
act_border          = colors.primary
inact_border        = colors.surface

-- Noctalia palette table & backward compatibility globals
noctalia_colors     = colors
active              = act_border
inactive            = inact_border
