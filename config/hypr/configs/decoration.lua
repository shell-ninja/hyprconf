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
        rounding_power   = 3.5,

        active_opacity   = opacity_act,
        inactive_opacity = opacity_deact,

        dim_inactive     = true,
        dim_strength     = 0.08,
        dim_special      = 0.25,
        wobble           = {
            enabled          = true,
            mesh             = 14,
            stiffness        = 225.0,
            damping          = 14.0,
            mass             = 1.0,
            intensity        = 0.15,
            value_epsilon    = 0.15,
            velocity_epsilon = 1.2,
        },

        shadow           = {
            enabled        = true,
            range          = shadow_range,
            render_power   = 3,
            color          = "rgba(04050acc)",
            color_inactive = "rgba(04050a66)",
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
            size                      = 4,
            passes                    = 2,
            ignore_opacity            = true,
            new_optimizations         = true,
            xray                      = false,
            noise                     = 0.025,
            contrast                  = 1.04,
            brightness                = 0.96,
            vibrancy                  = 0.22,
            vibrancy_darkness         = 0.25,
            special                   = false,
            popups                    = true,
            popups_ignorealpha        = 0.35,
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
            enabled = true,
            samples = 10,
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
