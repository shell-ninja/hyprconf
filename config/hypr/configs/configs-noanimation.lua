-- configs-noanimation.lua
-- Overrides for performance mode (no visual effects).
-- Swap this file in place of configs.lua for a lightweight session.

local noctalia = require("noctalia")
local colors   = noctalia.colors

opacity_act   = 1.0
opacity_deact = 1.0
blur_size     = 0
blur_pass     = 0
shadow_range  = 0
rounding      = 0
border        = 0
inner_gap     = 5
outer_gap     = 10

-- Border and theme colors from Noctalia
act_border    = colors.primary
inact_border  = colors.surface

-- Noctalia palette table & backward compatibility globals
noctalia_colors = colors
active          = act_border
inactive        = inact_border

