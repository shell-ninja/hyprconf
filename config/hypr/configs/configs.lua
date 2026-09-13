-- configs.lua
-- Shared visual configuration variables.
-- Colors imported from noctalia.lua

local noctalia = require("noctalia")
local colors   = noctalia.colors

opacity_act   = 0.9
opacity_deact = 0.85
blur_size     = 4
blur_pass     = 4
shadow_range  = 0
rounding      = 16
border        = 2
inner_gap     = 4
outer_gap     = 4

-- Border and theme colors from Noctalia
act_border    = colors.primary
inact_border  = colors.surface

-- Noctalia palette table & backward compatibility globals
noctalia_colors = colors
active          = act_border
inactive        = inact_border