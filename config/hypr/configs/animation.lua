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
        { 0.8, 0.91 },
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

-- Windows
hl.animation({
    leaf = "windowsIn",
    enabled = 1,
    speed = 4.2,
    bezier = "expo_out",
    style = "popin 88%",
})

hl.animation({
    leaf = "windowsOut",
    enabled = 1,
    speed = 3.6,
    bezier = "md3_accel",
    style = "popin 92%",
})

hl.animation({
    leaf = "windowsMove",
    enabled = 1,
    speed = 4.5,
    bezier = "expo_out",
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

-- Fading
hl.animation({
    leaf = "fade",
    enabled = 1,
    speed = 3.5,
    bezier = "expo_out",
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
