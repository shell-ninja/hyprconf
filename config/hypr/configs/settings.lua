-- settings.lua
-- Input, gestures, misc, binds, xwayland, and cursor settings.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/

-- Input
hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        repeat_rate         = 40,
        repeat_delay        = 200,
        numlock_by_default  = true,
        left_handed         = false,
        follow_mouse        = 1,
        float_switch_override_focus = false,

        sensitivity = 0, -- -1.0 – 1.0, 0 = no modification

        touchpad = {
            disable_while_typing  = true,
            natural_scroll        = true,
            clickfinger_behavior  = false,
            middle_button_emulation = true,
            tap_to_click          = true,
            drag_lock             = false,
        },
    },
})

-- Three-finger horizontal swipe → switch workspace
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

-- Misc
hl.config({
    misc = {
        force_default_wallpaper = -1,   -- -1 keeps default, 0 or 1 disables anime mascot
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
        vrr                     = 2,
        mouse_move_enables_dpms = true,
        enable_swallow          = true,
        swallow_regex           = "^(kitty)$",
        focus_on_activate       = false,
        initial_workspace_tracking = 0,
        middle_click_paste      = false,
    },
})

-- Binds
hl.config({
    binds = {
        workspace_back_and_forth = true,
        allow_workspace_cycles   = true,
        pass_mouse_when_bound    = false,
    },
})

-- XWayland
hl.config({
    xwayland = {
        enabled           = true,
        force_zero_scaling = true,
    },
})

-- Cursor
hl.config({
    cursor = {
        inactive_timeout        = 30,
        sync_gsettings_theme    = true,
        no_hardware_cursors     = false,
        enable_hyprcursor       = true,
        warp_on_change_workspace = 2,
        no_warps                = true,
    },
})
