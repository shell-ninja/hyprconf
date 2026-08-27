--!nonstrict
-- arch-updater bar widget: pending-update badge and panel toggle.
--
-- Pure renderer over the "arch_state" the engine (service.luau) publishes.
-- Every bar showing the widget agrees on the count without running any
-- command itself. Actions go back as "arch_request" entries, so one engine
-- owns the checks and the update run no matter how many widgets exist.
--
-- Click mapping:
--   Left click:  open/close the panel
--   Right click: check for updates now
--
-- No middle-click handler: the host already binds it to the widget's own
-- settings, so a callback here would be dead code.

local PANEL_ID = "yuuto/arch-updater:panel"
local REQUEST_KEY = "arch_request"
local STATE_KEY = "arch_state"

local snapshot = nil

local function tr(key, args)
    return noctalia.tr(key, args)
end

local function request(action)
    local prev = noctalia.state.get(REQUEST_KEY)
    local nonce = (type(prev) == "table" and tonumber(prev.nonce) or 0) + 1
    noctalia.state.set(REQUEST_KEY, { nonce = nonce, action = action })
end

local function pending()
    return snapshot ~= nil
        and snapshot.phase == "ready"
        and (snapshot.total or 0) > 0
end

-- "Pacman 12 · AUR (yay) 3 · Flatpak 1": non-zero sources only.
local function breakdown()
    if snapshot == nil then
        return ""
    end
    local parts = {}
    local pacman = snapshot.pacman
    if type(pacman) == "table" and (pacman.n or 0) > 0 then
        table.insert(parts, tr("source.pacman") .. " " .. pacman.n)
    end
    local aur = snapshot.aur
    if type(aur) == "table" and (aur.n or 0) > 0 then
        local label = (aur.helper ~= nil and aur.helper ~= "") and tr("source.aur_named", { helper = aur.helper }) or tr("source.aur")
        table.insert(parts, label .. " " .. aur.n)
    end
    local flatpak = snapshot.flatpak
    if type(flatpak) == "table" and (flatpak.n or 0) > 0 then
        table.insert(parts, tr("source.flatpak") .. " " .. flatpak.n)
    end
    return table.concat(parts, " · ")
end

local function statusLabel()
    if snapshot == nil then
        return tr("status_idle")
    end
    local phase = snapshot.phase
    if phase == "missing" then
        return tr("status_missing")
    elseif phase == "checking" then
        local current = snapshot.step
        if current ~= nil and current ~= "" then
            return tr("status_checking_step", { step = current })
        end
        return tr("status_checking")
    elseif phase == "running" then
        return tr("status_running")
    elseif phase == "error" then
        return snapshot.err or tr("status_error")
    elseif phase == "clean" then
        return tr("status_clean")
    elseif phase == "ready" then
        return noctalia.trp("status_ready", snapshot.total or 0, {})
    end
    return tr("status_idle")
end

local function render()
    barWidget.setGlyph(noctalia.getConfig("glyph"))

    local phase = snapshot ~= nil and snapshot.phase or "idle"
    local reboot = snapshot ~= nil and snapshot.rebootRecommended == true
    if phase == "missing" or phase == "error" then
        barWidget.setGlyphColor("error")
    elseif phase == "checking" or phase == "running" then
        barWidget.setGlyphColor("secondary")
    elseif reboot then
        barWidget.setGlyphColor("warning")
    elseif pending() then
        barWidget.setGlyphColor("primary")
    else
        barWidget.setGlyphColor("on_surface")
    end

    if phase == "running" and snapshot ~= nil and type(snapshot.progress) == "table"
        and (tonumber(snapshot.progress.total) or 0) > 0 then
        -- Live progress replaces the count while the background run is going.
        local done = tonumber(snapshot.progress.done) or 0
        local expect = tonumber(snapshot.progress.total) or 1
        barWidget.setText(tostring(math.min(math.floor(done / expect * 100), 100)) .. "%")
    elseif pending() and noctalia.getConfig("show_count") == true then
        barWidget.setText(tostring(snapshot.total))
    else
        barWidget.setText("")
    end

    local empty = snapshot == nil or (snapshot.total or 0) == 0
    barWidget.setVisible(not (noctalia.getConfig("hide_on_empty") == true and empty and not reboot))

    local rows = { { key = tr("tooltip_status"), value = statusLabel() } }
    local detail = breakdown()
    if detail ~= "" then
        table.insert(rows, { key = tr("tooltip_pending"), value = detail })
    end
    if reboot then
        table.insert(rows, { key = tr("tooltip_reboot_key"), value = tr("tooltip_reboot_value") })
    end
    if snapshot ~= nil and (snapshot.newsUnread or 0) > 0 then
        table.insert(rows, { key = tr("tooltip_news"), value = noctalia.trp("tooltip_news_value", snapshot.newsUnread, {}) })
    end
    if snapshot ~= nil and snapshot.checkedAt ~= nil and snapshot.checkedAt ~= "" then
        table.insert(rows, { key = tr("tooltip_checked"), value = snapshot.checkedAt })
    end
    table.insert(rows, { key = "", value = tr("tooltip_hints") })
    barWidget.setTooltip(rows)
end

noctalia.state.watch(STATE_KEY, function(value)
    if type(value) == "table" then
        snapshot = value
        render()
    end
end)

-- Periodic re-render keeps the glyph/visibility in sync with widget-setting
-- edits, which do not move the engine's state.
function update()
    render()
end

function onClick()
    noctalia.togglePanel(PANEL_ID)
end

function onRightClick()
    request("check")
end

noctalia.setUpdateInterval(1000)
snapshot = noctalia.state.get(STATE_KEY)
render()
