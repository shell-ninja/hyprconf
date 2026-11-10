-- decoration.lua
-- Applies general, decoration, and layout settings via the hl.config() API.
-- Depends on variables defined in configs.lua (must be loaded first).

-- See https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in          = inner_gap,
        gaps_out         = outer_gap,

        border_size      = border,

        col              = {
            active_border   = act_border,
            inactive_border = inact_border,
        },

        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding         = rounding,
        rounding_power   = 2,

        active_opacity   = opacity_act,
        inactive_opacity = opacity_deact,

        dim_inactive     = false,
        dim_strength     = 0.1,
        dim_special      = 0.2,
        wobble           = {
            enabled          = false,
            mesh             = 5,
            stiffness        = 280.0,
            damping          = 8.5,
            mass             = 1.5,
            intensity        = 0.15,
            value_epsilon    = 0.25,
            velocity_epsilon = 6.6,
        },

        shadow           = {
            enabled        = true,
            range          = shadow_range,
            render_power   = 3,
            color          = act_border,
            color_inactive = inact_border,
        },

        glow             = {
            enabled        = false,
            color          = act_border,
            color_inactive = inact_border,
            range          = 15,
            render_power   = 2,
        },

        blur             = {
            enabled                   = true,
            size                      = 3,
            passes                    = 2,
            ignore_opacity            = true,
            new_optimizations         = true,
            xray                      = false,
            noise                     = 0.12,
            contrast                  = 1.0,
            brightness                = 1.0,
            vibrancy                  = 0.12,
            vibrancy_darkness         = 0.3,
            special                   = false,
            popups                    = false,
            popups_ignorealpha        = 0.5,
            input_methods             = false,
            input_methods_ignorealpha = 0.2,
            proportional              = false,
            variant                   = "kawase",

            acrylic = {
                aberration = 0.025,
                bulb       = 48.0,
                clarity    = 0.82,
                refraction = 24.0,
            },

            aurora = {
                color1    = 0x29F0A0FF,
                color2    = 0x7A4DFFFF,
                intensity = 0.35,
                speed     = 1.0,
            },

            drops = {
                speed = 3.0,
            },

            fluid_jar = {
                color       = 0xCC3399FF,
                distortion  = 8.0,
                fill_amount = 0.5,
                mass        = 1.4,
                precision   = 2.0,
                speed       = 3.7,
                turbulence  = 1.2,
            },

            glass = {
                refraction = 20.0,
                roughness  = 1.0,
                size       = 40.0,
            },

            haze = {
                intensity   = 0.35,
                iridescence = 0.7,
            },

            heat_shimmer = {
                speed = 1.0,
            },

            ripple = {
                duration = 0.45,
                radius   = 400.0,
                strength = 30.0,
                width    = 32.0,
            },

            water = {
                damping  = 0.95,
                duration = 12.0,
                radius   = 20.0,
                speed    = 0.76,
                strength = 32.0,
            },
        },

        motion_blur      = {
            enabled = false,
            samples = 5,
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

-- Scrolling layout
-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
hl.config({
    scrolling = {
        column_width = 0.8,
    },
})
