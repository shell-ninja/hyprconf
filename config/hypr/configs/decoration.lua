-- decoration.lua
-- Applies general, decoration, and layout settings via the hl.config() API.
-- Depends on variables defined in configs.lua (must be loaded first).

-- See https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = inner_gap,
        gaps_out = outer_gap,

        border_size = border,

        col = {
            active_border   = act_border,
            inactive_border = inact_border,
        },

        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = rounding,
        rounding_power = 2,

        active_opacity   = opacity_act,
        inactive_opacity = opacity_deact,

        dim_inactive = false,
        dim_strength = 0.1,
        dim_special  = 0.2,

        shadow = {
            enabled      = true,
            range        = shadow_range,
            render_power = 4,
            color        = act_border,
            color_inactive = inact_border,
        },

        blur = {
            enabled            = true,
            size               = blur_size,
            passes             = blur_pass,
            ignore_opacity     = true,
            noise              = 0.01,
            contrast           = 1.0,
            vibrancy           = 0.1696,
            popups             = true,
            popups_ignorealpha = 0.5,
        },
    },
})

-- Dwindle layout
-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
hl.config({
    dwindle = {
        preserve_split = true,
    },
})

-- Master layout
-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/
hl.config({
    master = {
        new_status = "master",
    },
})
