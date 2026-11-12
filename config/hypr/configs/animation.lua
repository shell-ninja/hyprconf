-- animation.lua

hl.config({
    animations = {
        enabled = True,
    },
})

----------------------------------------------------------------------
-- Bezier curves
----------------------------------------------------------------------

hl.curve("fluent_decel", {
    type = "bezier",
    points = {
        { 0.1, 1 },
        { 0, 1 },
    },
})

hl.curve("md3_decel", {
    type = "bezier",
    points = {
        { 0.05, 0.7 },
        { 0.1,  1.0 },
    },
})

hl.curve("md3_accel", {
    type = "bezier",
    points = {
        { 0.3, 0.0 },
        { 0.8, 0.15 },
    },
})

hl.curve("elegant_bounce", {
    type = "bezier",
    points = {
        { 0.03, 1.53 },
        { 0.25, 0.91 },
    },
})

hl.curve("backward", {
    type = "bezier",
    points = {
        { 0.49, 0.09 },
        { 0.38, 1.24 },
    },
})

hl.curve("expo_out", {
    type = "bezier",
    points = {
        { 0.16, 1.0 },
        { 0.3,  1.0 },
    },
})

hl.curve("smooth_pop", {
    type = "bezier",
    points = {
        { 0.22, 1.08 },
        { 0.36, 1.0  },
    },
})

-- Slide & exit curves sculpted specifically for wobble + directional motion blur:
-- slide_glide: Controlled frame-1 launch (no 4.6x snap/ghost-banding) into a silky
-- cushion tail so spring wobble completes one smooth wave on arrival.
hl.curve("slide_glide", {
    type = "bezier",
    points = {
        { 0.22, 0.52 },
        { 0.18, 1.0  },
    },
})

-- slide_move: Balanced glide for scrolling/tiled window reflow (windowsMove).
hl.curve("slide_move", {
    type = "bezier",
    points = {
        { 0.24, 0.48 },
        { 0.18, 1.0  },
    },
})

-- slide_exit: Immediate frame-1 pull-away (no dead pause) ramping smoothly offscreen.
hl.curve("slide_exit", {
    type = "bezier",
    points = {
        { 0.30, 0.28 },
        { 0.46, 1.0  },
    },
})

-- fade_exit: Holds opacity through initial slide pull, dissolving softly near the tail.
hl.curve("fade_exit", {
    type = "bezier",
    points = {
        { 0.35, 0.0  },
        { 0.72, 0.65 },
    },
})

hl.curve("linear", {
    type = "bezier",
    points = {
        { 1, 1 },
        { 1, 1 },
    },
})

----------------------------------------------------------------------
hl.curve("test", {
    type = "bezier",
    points = {
        { 0, 1.75 },
        { 0.44, 1.07 },
    },
})

-- Animations
----------------------------------------------------------------------

-- Windows (adaptive slide + wobble + motion blur tuned in lockstep)
hl.animation({
    leaf = "windowsIn",
    enabled = 1,
    speed = 3.4,
    bezier = "slide_glide",
    style = "slide",
})

hl.animation({
    leaf = "windowsOut",
    enabled = 1,
    speed = 2.5,
    bezier = "slide_exit",
    style = "slide",
})

hl.animation({
    leaf = "windowsMove",
    enabled = 1,
    speed = 3.4,
    bezier = "slide_move",
    style = "slide",
})

-- Borders
hl.animation({
    leaf = "border",
    enabled = 1,
    speed = 3,
    bezier = "md3_decel",
})

hl.animation({
    leaf = "borderangle",
    enabled = 0,  -- Disabled: looping animation burns GPU at idle
    speed = 30,
    bezier = "linear",
    style = "loop",
})

-- Fading (rapid opaque arrival on open so sliding wobble stays crisp; smooth tail dissolve on close)
hl.animation({
    leaf = "fade",
    enabled = 1,
    speed = 2.8,
    bezier = "expo_out",
})

hl.animation({
    leaf = "fadeIn",
    enabled = 1,
    speed = 1.4,
    bezier = "expo_out",
})

hl.animation({
    leaf = "fadeOut",
    enabled = 1,
    speed = 2.5,
    bezier = "fade_exit",
})

-- Workspaces
hl.animation({
    leaf = "workspaces",
    enabled = 1,
    speed = 4.8,
    bezier = "expo_out",
    style = "slidevert",
})

hl.animation({
    leaf = "specialWorkspace",
    enabled = 1,
    speed = 4.5,
    bezier = "expo_out",
    style = "slidefadevert 12%",
})

-- Layers
hl.animation({
    leaf = "layersIn",
    enabled = 1,
    speed = 3.8,
    bezier = "expo_out",
    style = "fade",
})

hl.animation({
    leaf = "layersOut",
    enabled = 1,
    speed = 3.2,
    bezier = "md3_accel",
    style = "fade",
})
