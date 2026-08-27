--!nonstrict

local inBreak = false
local activeTime = 0
local breakTimer = 0
local breakElapsed = 0
local idleTime = 0
local isSystemIdle = false
local activeDurationMinutes = 20
local breakDurationSeconds = 20

local function formatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", mins, secs)
end

local function render()
    if isSystemIdle then
        barWidget.setGlyph("coffee")
        barWidget.setText(string.format("Idle: %ds", idleTime))
        barWidget.setTooltip("System is idle. Resting eyes...")
        barWidget.setGlyphColor("#26a69a") -- Teal
        barWidget.setColor("#ffffff")
        return
    end

    if inBreak then
        barWidget.setGlyph("hourglass")
        local remaining = math.max(0, breakDurationSeconds - breakTimer)
        barWidget.setText(string.format("Break: %ds", remaining))
        barWidget.setTooltip(string.format("Break in progress! Look 20ft away.\nTime remaining: %ds\nClick to abort early\nRight-click to reset", remaining))
        barWidget.setGlyphColor("#ff5252") -- Soft Red
        barWidget.setColor("#ff5252")
    else
        barWidget.setGlyph("eye")
        local activeLimit = activeDurationMinutes * 60
        local remaining = math.max(0, activeLimit - activeTime)
        barWidget.setText(formatTime(remaining))
        barWidget.setTooltip(string.format("Eye-Care timer active.\nTime remaining: %s\nClick to start break manually\nRight-click to reset", formatTime(remaining)))
        barWidget.setGlyphColor("#00e676") -- Vibrant Green
        barWidget.setColor("#ffffff")
    end
end

-- Watch state updates
noctalia.state.watch("eyecare-in-break", function(val)
    inBreak = val == true
    render()
end)

noctalia.state.watch("eyecare-active-time", function(val)
    activeTime = tonumber(val) or 0
    render()
end)

noctalia.state.watch("eyecare-break-timer", function(val)
    breakTimer = tonumber(val) or 0
    render()
end)

noctalia.state.watch("eyecare-break-elapsed", function(val)
    breakElapsed = tonumber(val) or 0
    render()
end)

noctalia.state.watch("eyecare-idle-time", function(val)
    idleTime = tonumber(val) or 0
    render()
end)

noctalia.state.watch("eyecare-is-system-idle", function(val)
    isSystemIdle = val == true
    render()
end)

noctalia.state.watch("eyecare-active-duration-minutes", function(val)
    activeDurationMinutes = tonumber(val) or 20
    render()
end)

noctalia.state.watch("eyecare-break-duration-seconds", function(val)
    breakDurationSeconds = tonumber(val) or 20
    render()
end)

function onClick()
    if inBreak then
        noctalia.state.set("eyecare-request", "abort-break")
    else
        noctalia.state.set("eyecare-request", "trigger-break")
    end
end

function onRightClick()
    noctalia.state.set("eyecare-request", "reset")
end

-- Initial render
render()
