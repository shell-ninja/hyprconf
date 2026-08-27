--!nonstrict
-- arch-updater update panel. Pure renderer over the shared state: the engine
-- (service.luau) publishes "arch_state" and performs the "arch_request"
-- actions this panel emits, so closing the panel never interrupts a check or
-- a run in progress.
--
-- "Update" follows the update_mode setting: a terminal window (default,
-- like the original plugin) or a non-interactive background run. Either
-- way the package list gives way to a live tail of the update log plus a
-- progress bar while it runs. A failed background run keeps its log on
-- screen and offers a terminal retry where prompts work normally.

local STATE_KEY = "arch_state"
local REQUEST_KEY = "arch_request"

local snapshot = nil
local expanded = {} -- source key -> the package list is open
local hoverKey = nil -- package row currently under the pointer
local hoverText = "" -- what the detail line shows
local listOpen = false -- at least one source is expanded this render
local openedRunAt = nil -- history run whose package list replaces the sources
local armedKey = nil -- rollback button waiting for its confirming second click
local armedAt = 0 -- when it was armed; the confirm auto-disarms after a while
local ARM_TIMEOUT_S = 8
local activityHoverIndex = nil -- activity graph point currently under the pointer
local changelogOpen = false -- changelog view replaces the sources
local changelogAutoOpenPending = false -- set with changelogOpen when a just-finished update opened it, so onOpen() doesn't reset it away unseen

local render

local function tr(key, args)
    return noctalia.tr(key, args)
end

-- CHANGELOG.md, parsed once at load: "## version — date" headers, "- " bullet
-- lines under each. readFile resolves relative to the plugin directory.
local function parseChangelog(text)
    local releases = {}
    local current = nil
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        local version, date = line:match("^##%s+(%S+)%s*(.-)%s*$")
        if version ~= nil then
            -- Strip the "— " (or "- ") separator before the date. Done as a
            -- literal gsub rather than folded into the match pattern above,
            -- since Lua patterns treat a multi-byte UTF-8 dash inside a
            -- character class as a set of individual bytes, not one glyph.
            date = date:gsub("^—%s*", ""):gsub("^%-%s*", "")
            current = { version = version, date = date, lines = {} }
            table.insert(releases, current)
        elseif current ~= nil then
            local bullet = line:match("^%-%s+(.*)$")
            if bullet ~= nil then
                table.insert(current.lines, bullet)
            end
        end
    end
    return releases
end

local changelog = (function()
    local text = noctalia.readFile("CHANGELOG.md")
    if type(text) ~= "string" then
        return {}
    end
    return parseChangelog(text)
end)()

-- extra: a package name string, or a table merged into the request payload
-- (pkg/version/at for the rollback family).
local function request(action, extra)
    local prev = noctalia.state.get(REQUEST_KEY)
    local nonce = (type(prev) == "table" and tonumber(prev.nonce) or 0) + 1
    local payload = { nonce = nonce, action = action }
    if type(extra) == "table" then
        for key, value in pairs(extra) do
            payload[key] = value
        end
    elseif extra ~= nil then
        payload.pkg = extra
    end
    noctalia.state.set(REQUEST_KEY, payload)
end

local function shellQuote(value)
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function openUrl(url)
    if not noctalia.commandExists("xdg-open") then
        noctalia.notifyError(tr("title"), tr("err_no_xdg_open"))
        return
    end
    noctalia.runAsync("xdg-open " .. shellQuote(url) .. " >/dev/null 2>&1")
end

-- Opens a generic Arch package search instead of a per-repo mirror URL, so
-- it stays correct across Arch-based distros.
local function openPackage(sourceKey, name)
    if sourceKey == "pacman" then
        openUrl("https://archlinux.org/packages/?q=" .. noctalia.string.urlEncode(name))
    elseif sourceKey == "aur" then
        openUrl("https://aur.archlinux.org/packages/" .. noctalia.string.urlEncode(name))
    elseif sourceKey == "flatpak" then
        openUrl("https://flathub.org/apps/" .. noctalia.string.urlEncode(name))
    end
end

local function detailFor(item)
    local from = item.from ~= nil and item.from or ""
    local to = item.to ~= nil and item.to or ""
    if to == "" then
        return item.name
    end
    if from == "" then
        return item.name .. "  → " .. to
    end
    return item.name .. "  " .. from .. " → " .. to
end

local function phaseOf()
    return snapshot ~= nil and snapshot.phase or "idle"
end

local function totalOf()
    return snapshot ~= nil and tonumber(snapshot.total) or 0
end

local function busy()
    local phase = phaseOf()
    return phase == "checking" or phase == "running"
end

local function checking()
    return phaseOf() == "checking"
end

local function runFailed()
    return phaseOf() == "error" and snapshot ~= nil and tonumber(snapshot.runExit) ~= nil and tonumber(snapshot.runExit) ~= 0
end

local function logLines()
    if snapshot == nil or type(snapshot.logTail) ~= "table" then
        return {}
    end
    return snapshot.logTail
end

local function headline()
    local phase = phaseOf()
    if phase == "missing" then
        return tr("status_missing"), "error"
    elseif phase == "error" then
        return (snapshot ~= nil and snapshot.err) or tr("status_error"), "error"
    elseif phase == "checking" then
        local step = snapshot.step
        if step ~= nil and step ~= "" then
            return tr("status_checking_step", { step = step }), "secondary"
        end
        return tr("status_checking"), "secondary"
    elseif phase == "running" then
        if snapshot ~= nil and snapshot.runKind == "rollback" then
            return tr("status_rolling_back"), "secondary"
        end
        if snapshot ~= nil and snapshot.runMode == "terminal" then
            return tr("status_running_terminal"), "secondary"
        end
        return tr("status_running"), "secondary"
    elseif phase == "clean" then
        return tr("status_clean"), "on_surface"
    elseif phase == "ready" then
        return noctalia.trp("status_ready", totalOf(), {}), "primary"
    end
    return tr("status_idle"), "on_surface_variant"
end

local VERSION_WIDTH = 78

local function sourceLabel(key, entry)
    if key == "aur" and type(entry.helper) == "string" and entry.helper ~= "" then
        return tr("source.aur_named", { helper = entry.helper })
    end
    return tr("source." .. key)
end

local SOURCE_GLYPHS = { pacman = "package", aur = "cloud", flatpak = "app-window" }

local function sourceGlyph(key)
    return SOURCE_GLYPHS[key] or "package"
end

-- pacman, then the AUR helper, then Flatpak. Only sources with pending
-- packages, biggest first.
local function orderedSources()
    if snapshot == nil then
        return {}
    end
    local candidates = {
        { key = "pacman", entry = snapshot.pacman },
        { key = "aur", entry = snapshot.aur },
        { key = "flatpak", entry = snapshot.flatpak },
    }
    local pending = {}
    for _, candidate in ipairs(candidates) do
        if type(candidate.entry) == "table" and (candidate.entry.n or 0) > 0 then
            table.insert(pending, candidate)
        end
    end
    table.sort(pending, function(a, b)
        return a.entry.n > b.entry.n
    end)
    return pending
end

-- Sources that are installed, enabled and have nothing pending. Flatpak is
-- skipped entirely when it is not on the system, so the panel doesn't brag
-- about a tool that isn't there.
local function cleanSources()
    if snapshot == nil then
        return {}
    end
    local names = {}
    local candidates = { { key = "pacman", entry = snapshot.pacman } }
    if snapshot.flatpakEnabled == true then
        table.insert(candidates, { key = "flatpak", entry = snapshot.flatpak })
    end
    if snapshot.aur ~= nil and (snapshot.aur.n or 0) == 0 and noctalia.getConfig("aur_helper") ~= "off" then
        table.insert(candidates, { key = "aur", entry = snapshot.aur })
    end
    for _, candidate in ipairs(candidates) do
        if type(candidate.entry) == "table" and (candidate.entry.n or 0) == 0 then
            table.insert(names, sourceLabel(candidate.key, candidate.entry))
        end
    end
    return names
end

local function packageRow(sourceKey, index, item)
    local key = "pkg-" .. sourceKey .. "-" .. index
    local children = {
        ui.label({ text = item.name, fontSize = 11, color = "on_surface", flexGrow = 1, maxLines = 1 }),
    }
    local from = item.from ~= nil and item.from or ""
    local to = item.to ~= nil and item.to or ""
    if to ~= "" then
        if from ~= "" then
            table.insert(children, ui.label({
                text = from, fontSize = 11, color = "on_surface_variant", maxWidth = VERSION_WIDTH, maxLines = 1,
            }))
        end
        table.insert(children, ui.label({ text = "→", fontSize = 11, color = "on_surface_variant" }))
        table.insert(children, ui.label({
            text = to, fontSize = 11, color = "primary", fontWeight = "semibold", maxWidth = VERSION_WIDTH, maxLines = 1,
        }))
    end
    table.insert(children, ui.button({
        glyph = "eye-off", variant = "ghost", controlSize = "sm", width = 22, height = 22, glyphSize = 12,
        tooltip = tr("tip_ignore"),
        onClick = function()
            request("ignore", item.name)
        end,
    }))
    table.insert(children, ui.button({
        glyph = "copy", variant = "ghost", controlSize = "sm", width = 22, height = 22, glyphSize = 12,
        tooltip = tr("tip_copy"),
        onClick = function()
            noctalia.copyToClipboard(detailFor(item), "text/plain")
        end,
    }))
    table.insert(children, ui.button({
        glyph = "external-link", variant = "ghost", controlSize = "sm", width = 22, height = 22, glyphSize = 12,
        tooltip = tr("tip_open_page"),
        onClick = function()
            openPackage(sourceKey, item.name)
        end,
    }))
    return ui.row({
        key = key,
        paddingH = 18,
        gap = 4,
        align = "center",
        onHover = function(state)
            if state == "true" then
                hoverKey = key
                hoverText = detailFor(item)
            elseif hoverKey == key then
                hoverKey = nil
                hoverText = ""
            else
                return
            end
            render()
        end,
    }, children)
end

local function sourceRows()
    local rows = {}
    for _, source in ipairs(orderedSources()) do
        local names = type(source.entry.items) == "table" and source.entry.items or {}
        local open = expanded[source.key] == true and #names > 0
        listOpen = listOpen or open
        local header = { gap = 8, align = "center", key = "src-" .. source.key .. (open and "-open" or "") }
        if #names > 0 then
            local sourceKey = source.key
            header.onClick = function()
                expanded[sourceKey] = not expanded[sourceKey]
                hoverKey = nil
                hoverText = ""
                render()
            end
        end
        table.insert(rows, ui.row(header, {
            ui.glyph({ name = #names == 0 and "point" or (open and "chevron-down" or "chevron-right"), size = 12, color = "on_surface_variant" }),
            ui.glyph({ name = sourceGlyph(source.key), size = 13, color = "on_surface_variant" }),
            ui.label({ text = sourceLabel(source.key, source.entry), color = "on_surface", flexGrow = 1 }),
            ui.label({ text = tostring(source.entry.n), color = "primary", fontWeight = "bold" }),
        }))

        if open then
            for index, item in ipairs(names) do
                table.insert(rows, packageRow(source.key, index, item))
            end
            if source.entry.n > #names then
                table.insert(rows, ui.row({ key = "more-" .. source.key, paddingH = 18 }, {
                    ui.label({ text = tr("more_packages", { count = source.entry.n - #names }), fontSize = 11, color = "on_surface_variant" }),
                }))
            end
        end
    end
    return rows
end

-- ── Ignored packages ─────────────────────────────────────────────────────────

-- One display list: packages the last check saw as ignored (with versions),
-- then panel-managed and settings-based ignores with nothing pending.
local function ignoredEntries()
    if snapshot == nil then
        return {}
    end
    local entries = {}
    local seen = {}
    local pending = type(snapshot.ignoredPending) == "table" and snapshot.ignoredPending or {}
    for _, item in ipairs(pending) do
        if type(item) == "table" and item.name ~= nil and not seen[item.name] then
            seen[item.name] = true
            table.insert(entries, item)
        end
    end
    local dynamic = type(snapshot.ignoredDynamic) == "table" and snapshot.ignoredDynamic or {}
    for _, name in ipairs(dynamic) do
        if not seen[name] then
            seen[name] = true
            table.insert(entries, { name = name, source = "plugin" })
        end
    end
    local config = type(snapshot.ignoredConfig) == "table" and snapshot.ignoredConfig or {}
    for _, name in ipairs(config) do
        if not seen[name] then
            seen[name] = true
            table.insert(entries, { name = name, source = "settings" })
        end
    end
    return entries
end

-- Only panel-managed ignores can be lifted from here.
local function isRemovable(name)
    if snapshot == nil or type(snapshot.ignoredDynamic) ~= "table" then
        return false
    end
    for _, entry in ipairs(snapshot.ignoredDynamic) do
        if entry == name then
            return true
        end
    end
    return false
end

local function ignoredRow(index, item)
    local children = {
        ui.label({ text = item.name, fontSize = 11, color = "on_surface_variant", flexGrow = 1, maxLines = 1 }),
    }
    if item.to ~= nil and item.to ~= "" then
        table.insert(children, ui.label({
            text = item.to, fontSize = 11, color = "on_surface_variant", maxWidth = VERSION_WIDTH, maxLines = 1,
        }))
    end
    if item.source ~= "system" and isRemovable(item.name) then
        table.insert(children, ui.button({
            glyph = "eye", variant = "ghost", controlSize = "sm", width = 22, height = 22, glyphSize = 12,
            tooltip = tr("tip_unignore"),
            onClick = function()
                request("unignore", item.name)
            end,
        }))
    elseif item.source == "system" then
        -- IgnorePkg belongs to root; the tag only explains where to lift it.
        table.insert(children, ui.button({
            text = tr("ignored_tag_system"), variant = "ghost", controlSize = "sm",
            tooltip = tr("ignored_tip_system"),
            onClick = function() end,
        }))
    else
        table.insert(children, ui.button({
            text = tr("ignored_tag_settings"), variant = "ghost", controlSize = "sm",
            tooltip = tr("ignored_tip_settings"),
            onClick = function()
                noctalia.runAsync("noctalia msg settings-open-plugin yuuto/arch-updater >/dev/null 2>&1")
            end,
        }))
    end
    return ui.row({ key = "ign-" .. index, paddingH = 18, gap = 6, align = "center" }, children)
end

local function ignoredRows()
    local entries = ignoredEntries()
    if #entries == 0 then
        return {}
    end
    local open = expanded["ignored"] == true
    local rows = {}
    table.insert(rows, ui.row({
        key = "src-ignored" .. (open and "-open" or ""),
        gap = 8,
        align = "center",
        onClick = function()
            expanded["ignored"] = not expanded["ignored"]
            render()
        end,
    }, {
        ui.glyph({ name = open and "chevron-down" or "chevron-right", size = 12, color = "on_surface_variant" }),
        ui.glyph({ name = "eye-off", size = 13, color = "on_surface_variant" }),
        ui.label({ text = tr("ignored_title"), color = "on_surface_variant", flexGrow = 1 }),
        ui.label({ text = tostring(#entries), color = "on_surface_variant", fontWeight = "bold" }),
    }))
    if open then
        for index, item in ipairs(entries) do
            table.insert(rows, ignoredRow(index, item))
        end
    end
    return rows
end

-- ── Activity graph (the upstream feature, opt-in) ───────────────────────────

-- Normalizes the pending-count history to 0..1 for ui.graph, relative to the
-- min/max in the window (not a fixed scale, since pending counts vary wildly
-- between systems). A flat window (min == max, e.g. every check so far found
-- the same count) centers the line at 0.5 instead of pinning it to the top
-- edge, where it would be indistinguishable from the box border.
local function activityValues(history)
    local minN, maxN = tonumber(history[1].n) or 0, tonumber(history[1].n) or 0
    for _, entry in ipairs(history) do
        local n = tonumber(entry.n) or 0
        if n < minN then
            minN = n
        end
        if n > maxN then
            maxN = n
        end
    end
    local range = maxN - minN
    local values = {}
    for _, entry in ipairs(history) do
        local n = tonumber(entry.n) or 0
        table.insert(values, range > 0 and (n - minN) / range or 0.5)
    end
    return values
end

local ACTIVITY_GRAPH_SUBDIVISIONS = 8

local function upsampleLinear(values, subdivisions)
    if #values < 2 or subdivisions <= 1 then
        return values
    end
    local out = {}
    for i = 1, #values - 1 do
        local a, b = values[i], values[i + 1]
        for s = 0, subdivisions - 1 do
            table.insert(out, a + (b - a) * (s / subdivisions))
        end
    end
    table.insert(out, values[#values])
    return out
end

local function padGraphLookbehind(values)
    if #values == 0 then
        return values
    end
    local out = { values[1], values[1] }
    for _, v in ipairs(values) do
        table.insert(out, v)
    end
    return out
end

-- "2 hours ago", "3 days ago", etc. nil for entries migrated from the old
-- history format, which never recorded a timestamp.
local function relativeTime(at)
    local t = tonumber(at)
    if t == nil then
        return nil
    end
    local diff = os.time() - t
    if diff < 60 then
        return tr("activity.just_now")
    elseif diff < 3600 then
        local m = math.floor(diff / 60)
        return noctalia.trp("activity.minutes_ago", m, { count = m })
    elseif diff < 86400 then
        local h = math.floor(diff / 3600)
        return noctalia.trp("activity.hours_ago", h, { count = h })
    else
        local d = math.floor(diff / 86400)
        return noctalia.trp("activity.days_ago", d, { count = d })
    end
end

-- "Updated · 2 hours ago" for the check that verified an update run, else
-- "3 pending updates · 2 hours ago". Shared by the hover tooltip and the
-- top-right caption so both describe a point the same way.
local function describeEntry(entry)
    local n = tonumber(entry.n) or 0
    local text = entry.afterUpdate == true and tr("activity.updated")
        or noctalia.trp("activity.pending_at", n, { count = n })
    local when = relativeTime(entry.at)
    if when ~= nil then
        text = text .. " · " .. when
    end
    return text
end

-- ui.graph takes no pointer props of its own and the framework has no
-- overlay control, so per-point hover cannot live on the line itself: it is
-- a row of hit targets right under it, drawn as an axis of small dots (the
-- hovered one lights up in the accent color) so the interactivity is
-- visible without the ghost-button hover flash.
--
-- Real points sit at (k-1)/(#history-1) of the width (see
-- padGraphLookbehind), i.e. #history-1 equal gaps, not #history equal slots
-- - so this builds one equal-width segment per gap rather than per entry,
-- ending each segment (and its dot) exactly on the point at its right edge.
-- That leaves entry 1 (at the left edge, with no gap before it) without its
-- own hover zone, but keeps every other spike landing right at the end of
-- its segment instead of drifting toward the start of an oversized one.
local function activityHoverRow(history)
    local segments = {}
    for i = 2, #history do
        local hovered = activityHoverIndex == i
        segments[i - 1] = ui.row({
            key = "activity-hit-" .. i .. (hovered and "-on" or ""),
            flexGrow = 1,
            height = 12,
            align = "center",
            justify = "end",
            onHover = function(state)
                if state == "true" then
                    activityHoverIndex = i
                elseif activityHoverIndex == i then
                    activityHoverIndex = nil
                else
                    return
                end
                render()
            end,
        }, {
            ui.box({
                width = hovered and 7 or 5,
                height = hovered and 7 or 5,
                radius = 4,
                fill = hovered and "primary" or "outline/0.6",
            }),
        })
    end
    return ui.row({ key = "activity-hits", gap = 1 }, segments)
end

-- A small trend graph of pending-update counts across recent checks, plus
-- when the last update ran (or, while hovering a point, that point's own
-- description). Off entirely when show_activity_graph is off, and hidden
-- until there is enough history to draw a line.
local function activitySection()
    if snapshot == nil or noctalia.getConfig("show_activity_graph") ~= true then
        return nil
    end
    local history = type(snapshot.activity) == "table" and snapshot.activity or {}
    if #history < 2 then
        return nil
    end

    local hoveredEntry = activityHoverIndex ~= nil and history[activityHoverIndex] or nil
    local caption
    if hoveredEntry ~= nil then
        caption = describeEntry(hoveredEntry)
    else
        local lastUpdateAt = tonumber(snapshot.lastUpdateAt)
        if lastUpdateAt == nil then
            caption = tr("activity.never_updated")
        else
            local days = math.floor((os.time() - lastUpdateAt) / 86400)
            caption = days <= 0 and tr("activity.updated_today")
                or noctalia.trp("activity.updated_days_ago", days, { count = days })
        end
    end

    return ui.column({ key = "activity", gap = 4 }, {
        ui.row({ justify = "space_between", align = "center" }, {
            ui.label({ text = tr("activity.title"), fontSize = 11, fontWeight = "bold", color = "on_surface_variant" }),
            ui.label({ text = caption, fontSize = 10, color = "on_surface_variant" }),
        }),
        ui.graph({
            values = padGraphLookbehind(upsampleLinear(activityValues(history), ACTIVITY_GRAPH_SUBDIVISIONS)),
            color = "primary",
            fillOpacity = 0.15,
            lineWidth = 2,
            height = 36,
        }),
        activityHoverRow(history),
    })
end

-- ── Run history and rollback ─────────────────────────────────────────────────

local function historyRuns()
    if snapshot == nil or type(snapshot.history) ~= "table" then
        return {}
    end
    return snapshot.history -- newest first
end

local function findHistoryRun(at)
    for _, run in ipairs(historyRuns()) do
        if tonumber(run.at) == tonumber(at) then
            return run
        end
    end
    return nil
end

local function describeRun(run)
    local text = os.date("%d.%m %H:%M", tonumber(run.at) or 0)
        .. " · " .. noctalia.trp("run_packages", run.n or 0, { count = run.n or 0 })
    if run.rollback == true then
        text = text .. " · " .. tr("history_rollback_tag")
    end
    return text
end

-- The footer strip: one equal-width segment per recorded run, oldest on the
-- left. Hover describes the run, click opens its package list.
local function historySection()
    local runs = historyRuns()
    if #runs == 0 then
        return nil
    end
    local segments = {}
    for i = #runs, 1, -1 do
        local run = runs[i]
        table.insert(segments, ui.button({
            key = "run-" .. tostring(run.at),
            -- primary: painted in the theme's accent color, so the strip is
            -- visible at rest (ghost would only show on hover)
            variant = "primary",
            flexGrow = 1,
            height = 10,
            tooltip = describeRun(run) .. "\n" .. tr("tip_history_segment"),
            onClick = function()
                openedRunAt = run.at
                armedKey = nil
                request("probe_run", { at = run.at })
                render()
            end,
        }))
    end
    local header = {
        ui.label({ text = tr("history_title"), fontSize = 11, fontWeight = "bold", color = "on_surface_variant", flexGrow = 1 }),
    }
    if snapshot ~= nil and snapshot.checkedAt ~= nil and snapshot.checkedAt ~= "" then
        table.insert(header, ui.label({
            text = tr("caption_checked", { time = snapshot.checkedAt }),
            fontSize = 10,
            color = "on_surface_variant",
        }))
    end
    return ui.column({ key = "history", gap = 3 }, {
        ui.row({ key = "history-head", gap = 6, align = "center" }, header),
        ui.row({ key = "history-segments", gap = 2 }, segments),
    })
end

local function probeFor(run)
    if snapshot ~= nil and type(snapshot.probe) == "table" and tonumber(snapshot.probe.at) == tonumber(run.at) then
        return snapshot.probe.pkgs
    end
    return nil
end

-- Two-click rollback: the first click arms the button (it turns into a
-- confirm label), the second sends the request. Anything else re-renders
-- the armed state away.
local function rollbackButton(key, tooltip, onConfirm)
    if armedKey == key then
        return ui.button({
            key = key .. "-armed",
            text = tr("rollback_confirm"), variant = "primary", controlSize = "sm",
            tooltip = tooltip,
            onClick = function()
                armedKey = nil
                onConfirm()
            end,
        })
    end
    return ui.button({
        key = key,
        glyph = "undo", variant = "ghost", controlSize = "sm", width = 22, height = 22, glyphSize = 12,
        tooltip = tooltip,
        onClick = function()
            armedKey = key
            armedAt = os.time()
            render()
        end,
    })
end

local function rollbackRow(run, index, item, probePkgs)
    local key = "rb-" .. tostring(run.at) .. "-" .. index
    local info = probePkgs ~= nil and probePkgs[item.name] or nil
    local children = {}

    if item.source == "flatpak" then
        table.insert(children, ui.glyph({ name = "app-window", size = 12, color = "on_surface_variant" }))
    elseif info ~= nil and info.cache ~= true then
        table.insert(children, ui.button({
            key = key .. "-miss",
            glyph = "undo", variant = "ghost", controlSize = "sm", width = 22, height = 22, glyphSize = 12,
            enabled = false,
            tooltip = tr("rollback_missing"),
            onClick = function() end,
        }))
    else
        local tooltip = tr("tip_rollback", { version = tostring(item.from or "") })
        if info ~= nil and (info.req or 0) > 0 then
            tooltip = tooltip .. "\n" .. noctalia.trp("rollback_required_by", info.req, { count = info.req })
        end
        table.insert(children, rollbackButton(key, tooltip, function()
            request("rollback", { pkg = item.name, version = item.from, at = run.at })
        end))
    end

    table.insert(children, ui.label({ text = item.name, fontSize = 11, color = "on_surface", flexGrow = 1, maxLines = 1 }))
    if item.from ~= nil and item.from ~= "" then
        table.insert(children, ui.label({
            text = item.from, fontSize = 11, color = "on_surface_variant", maxWidth = VERSION_WIDTH, maxLines = 1,
        }))
    end
    table.insert(children, ui.label({ text = "→", fontSize = 11, color = "on_surface_variant" }))
    table.insert(children, ui.label({
        text = tostring(item.to or ""), fontSize = 11, color = "primary", maxWidth = VERSION_WIDTH, maxLines = 1,
    }))
    return ui.row({ key = key .. "-row", gap = 6, align = "center" }, children)
end

-- The opened run: header with a back button and a whole-run rollback, then
-- one row per package showing the run's from -> to and a rollback control.
local function runViewRows()
    local run = findHistoryRun(openedRunAt)
    if run == nil then
        openedRunAt = nil
        return nil
    end
    local probePkgs = probeFor(run)
    local rows = {}
    local header = {
        ui.button({
            glyph = "chevron-left", variant = "ghost", controlSize = "sm", width = 22, height = 22, glyphSize = 12,
            tooltip = tr("action_back"),
            onClick = function()
                openedRunAt = nil
                armedKey = nil
                render()
            end,
        }),
        ui.label({ text = describeRun(run), fontSize = 12, fontWeight = "bold", color = "on_surface", flexGrow = 1, maxLines = 1 }),
    }
    local rollable = 0
    for _, item in ipairs(run.packages or {}) do
        if item.source ~= "flatpak" then
            rollable += 1
        end
    end
    if rollable > 0 and run.rollback ~= true then
        table.insert(header, rollbackButton("rb-all-" .. tostring(run.at), tr("tip_rollback_run"), function()
            request("rollback_run", { at = run.at })
        end))
    end
    table.insert(rows, ui.row({ key = "run-head", gap = 6, align = "center" }, header))
    for index, item in ipairs(run.packages or {}) do
        table.insert(rows, rollbackRow(run, index, item, probePkgs))
    end
    return rows
end

-- The changelog view: a back button, then one release per entry in
-- CHANGELOG.md with its bullet points underneath.
local function changelogRows()
    local rows = {}
    table.insert(rows, ui.row({ key = "changelog-head", gap = 6, align = "center" }, {
        ui.button({
            glyph = "chevron-left", variant = "ghost", controlSize = "sm", width = 22, height = 22, glyphSize = 12,
            tooltip = tr("action_back"),
            onClick = function()
                changelogOpen = false
                render()
            end,
        }),
        ui.label({ text = tr("changelog_title"), fontSize = 12, fontWeight = "bold", color = "on_surface", flexGrow = 1, maxLines = 1 }),
    }))
    if #changelog == 0 then
        table.insert(rows, ui.row({ key = "changelog-empty", paddingH = 18 }, {
            ui.label({ text = tr("changelog_empty"), fontSize = 11, color = "on_surface_variant" }),
        }))
        return rows
    end
    for ri, release in ipairs(changelog) do
        local heading = "v" .. release.version
        if release.date ~= nil and release.date ~= "" then
            heading = heading .. "  ·  " .. release.date
        end
        table.insert(rows, ui.row({ key = "changelog-v" .. ri, gap = 6, align = "center" }, {
            ui.label({ text = heading, fontSize = 12, fontWeight = "bold", color = "on_surface" }),
        }))
        for li, bullet in ipairs(release.lines) do
            table.insert(rows, ui.row({ key = "changelog-" .. ri .. "-" .. li, paddingH = 10, gap = 6 }, {
                ui.label({ text = "•", fontSize = 11, color = "on_surface_variant" }),
                ui.label({ text = bullet, fontSize = 11, color = "on_surface_variant", flexGrow = 1, maxLines = 3 }),
            }))
        end
    end
    return rows
end

-- Live tail of the update log, with a progress bar while packages are being
-- processed. Shown during a run and kept on screen after a failed one.
local function logSection()
    local children = {}

    local header = {
        ui.label({ text = tr("log_title"), fontSize = 11, fontWeight = "bold", color = "on_surface_variant", flexGrow = 1 }),
    }
    local done = snapshot ~= nil and type(snapshot.progress) == "table" and tonumber(snapshot.progress.done) or 0
    local expect = snapshot ~= nil and type(snapshot.progress) == "table" and tonumber(snapshot.progress.total) or 0
    if phaseOf() == "running" and expect > 0 then
        table.insert(header, ui.label({
            text = tostring(math.min(done, expect)) .. " / " .. tostring(expect),
            fontSize = 11,
            color = "on_surface_variant",
        }))
    end
    table.insert(children, ui.row({ key = "log-head", gap = 6, align = "center" }, header))

    if phaseOf() == "running" and expect > 0 then
        table.insert(children, ui.progress({ key = "log-progress", progress = math.min(done / expect, 1) }))
    end

    local lines = logLines()
    local rows = {}
    if #lines == 0 then
        table.insert(rows, ui.label({
            key = "log-empty", text = tr("log_waiting"), fontSize = 10, color = "on_surface_variant",
        }))
    else
        for index, line in ipairs(lines) do
            table.insert(rows, ui.label({
                key = "log-" .. index,
                text = line,
                fontSize = 10,
                color = "on_surface_variant",
                maxLines = 1,
            }))
        end
    end
    table.insert(children, ui.column({ key = "log-lines", gap = 2, flexGrow = 1 }, rows))

    if snapshot ~= nil and type(snapshot.logPath) == "string" and snapshot.logPath ~= "" then
        table.insert(children, ui.row({ key = "log-actions", gap = 6 }, {
            ui.button({
                text = tr("action_open_log"), variant = "ghost", controlSize = "sm",
                -- Opened by the service in a terminal pager: xdg-open on a
                -- text file dies silently when the default handler is a
                -- terminal editor.
                onClick = function()
                    request("open_log")
                end,
            }),
        }))
    end

    return ui.column({ key = "log", gap = 6, flexGrow = 1 }, children)
end

-- Download size, reboot recommendation and Arch news. Each is its own line,
-- so turning one off in settings just removes that line.
local function extras()
    local lines = {}
    if snapshot == nil then
        return lines
    end

    if type(snapshot.downloadSizeMiB) == "number" then
        local size = snapshot.downloadSizeMiB
        local text = size >= 1024 and tr("size_gib", { value = string.format("%.2f", size / 1024) })
            or tr("size_mib", { value = string.format("%.1f", size) })
        table.insert(lines, ui.row({ key = "size", gap = 6, align = "center" }, {
            ui.glyph({ name = "download", size = 13, color = "on_surface_variant" }),
            ui.label({ text = text, fontSize = 12, color = "on_surface_variant" }),
        }))
    end

    if snapshot.rebootRecommended == true then
        table.insert(lines, ui.row({ key = "reboot", gap = 6, align = "center" }, {
            ui.glyph({ name = "alert-triangle", size = 13, color = "warning" }),
            ui.label({ text = tr("reboot_recommended"), fontSize = 12, color = "warning", flexGrow = 1 }),
        }))
    end

    -- Offered until the polkit keep-authorization rule is installed. Only in
    -- background mode: a terminal run goes through sudo, so the repeated
    -- polkit prompts the rule solves never happen there.
    if
        snapshot.polkitRule == false
        and noctalia.getConfig("update_mode") == "background"
        and phaseOf() ~= "running"
        and noctalia.getConfig("hide_polkit_hint") ~= true
    then
        table.insert(lines, ui.row({ key = "polkit", gap = 6, align = "center" }, {
            ui.glyph({ name = "shield", size = 13, color = "on_surface_variant" }),
            ui.label({
                text = tr("polkit_hint"),
                fontSize = 12,
                color = "on_surface_variant",
                flexGrow = 1,
                maxLines = 2,
            }),
            ui.button({
                text = tr("action_polkit_install"), variant = "ghost", controlSize = "sm",
                tooltip = tr("tip_polkit_install"),
                onClick = function()
                    request("polkit_install")
                end,
            }),
        }))
    end

    if (snapshot.newsUnread or 0) > 0 then
        table.insert(lines, ui.row({ key = "news", gap = 6, align = "center" }, {
            ui.glyph({ name = "news", size = 13, color = "on_surface" }),
            ui.label({
                text = noctalia.trp("news_unread", snapshot.newsUnread, { title = snapshot.newsLatestTitle or "" }),
                fontSize = 12,
                color = "on_surface",
                flexGrow = 1,
                maxLines = 2,
            }),
            ui.button({
                text = tr("action_open_news"), variant = "ghost", controlSize = "sm",
                onClick = function()
                    request("open_news")
                end,
            }),
        }))
    end

    return lines
end

local function body()
    local children = {}

    -- The middle of the panel: the live log while updating (and after a
    -- failure), the changelog, an opened history run, or the package list.
    -- The live log always wins over the changelog: a run in progress is more
    -- urgent than release notes.
    if phaseOf() == "running" or (runFailed() and #logLines() > 0) then
        table.insert(children, logSection())
    elseif changelogOpen then
        table.insert(children, ui.scroll({ key = "changelog-view", flexGrow = 1, gap = 4 }, changelogRows()))
        return children
    else
        local runRows = openedRunAt ~= nil and runViewRows() or nil
        if runRows ~= nil then
            table.insert(children, ui.scroll({ key = "run-view", flexGrow = 1, gap = 4 }, runRows))
            return children
        end
        local rows = sourceRows()
        for _, row in ipairs(ignoredRows()) do
            table.insert(rows, row)
        end
        if #rows > 0 then
            table.insert(children, ui.scroll({ key = "sources", flexGrow = 1, gap = 3 }, rows))
        else
            table.insert(children, ui.spacer({ key = "filler", flexGrow = 1 }))
        end

        if listOpen then
            table.insert(children, ui.label({
                key = "hover-detail",
                text = hoverText ~= "" and hoverText or tr("hover_hint"),
                fontSize = 11,
                color = hoverText ~= "" and "on_surface" or "on_surface_variant",
                maxLines = 1,
            }))
        end
    end

    for _, line in ipairs(extras()) do
        table.insert(children, line)
    end

    if not busy() then
        local clean = cleanSources()
        if #clean > 0 then
            table.insert(children, ui.label({
                text = tr("up_to_date", { sources = table.concat(clean, ", ") }),
                fontSize = 11,
                color = "on_surface_variant",
                maxLines = 2,
            }))
        end
    end

    return children
end

local function footerCaption()
    if snapshot == nil or snapshot.checkedAt == nil or snapshot.checkedAt == "" then
        return nil
    end
    local parts = { tr("caption_checked", { time = snapshot.checkedAt }) }
    local ignored = #ignoredEntries()
    if ignored > 0 then
        table.insert(parts, noctalia.trp("caption_ignored", ignored, {}))
    end
    return table.concat(parts, "  ·  ")
end

render = function()
    listOpen = false

    local text, color = headline()
    local phase = phaseOf()
    local hasUpdates = totalOf() > 0 and phase == "ready"

    local children = {
        ui.row({ gap = 8, align = "center" }, {
            ui.label({ text = tr("title"), fontSize = 16, fontWeight = "bold", color = "on_surface", flexGrow = 1 }),
            ui.button({
                key = "header-check" .. (busy() and "-off" or ""),
                glyph = "refresh",
                variant = "ghost",
                enabled = not busy() and phase ~= "missing",
                tooltip = tr("tip_check"),
                onClick = function()
                    request("check")
                end,
            }),
            ui.button({
                key = "header-changelog" .. (changelogOpen and "-on" or ""),
                glyph = "history",
                variant = changelogOpen and "primary" or "ghost",
                tooltip = tr("tip_changelog"),
                onClick = function()
                    changelogOpen = not changelogOpen
                    armedKey = nil
                    render()
                end,
            }),
            ui.button({
                glyph = "close", variant = "ghost", tooltip = tr("tip_close"),
                onClick = function()
                    panel.close()
                end,
            }),
        }),
        ui.label({ text = text, color = color, maxLines = 2 }),
    }

    for _, node in ipairs(body()) do
        table.insert(children, node)
    end

    -- Both footers hide while a check or run is on screen, so neither ever
    -- competes with the live log for space. The activity graph also hides
    -- while the changelog is open: it plots pending-update counts, which
    -- has nothing to do with release notes.
    local activity = not busy() and not changelogOpen and activitySection() or nil
    local history = not busy() and historySection() or nil
    if activity ~= nil or history ~= nil then
        table.insert(children, ui.separator({}))
        if activity ~= nil then
            table.insert(children, activity)
        end
        if history ~= nil then
            table.insert(children, history)
        end
    else
        local caption = footerCaption()
        if caption ~= nil then
            table.insert(children, ui.separator({}))
            table.insert(children, ui.label({ text = caption, fontSize = 11, color = "on_surface_variant", maxLines = 2 }))
        end
    end

    if phase ~= "missing" then
        local footer = {}
        -- Not offered after a failed rollback: re-running the *update*
        -- command in a terminal is not a retry of the rollback.
        if runFailed() and (snapshot == nil or snapshot.runKind ~= "rollback") then
            table.insert(footer, ui.button({
                key = "retry-terminal",
                glyph = "terminal", text = tr("action_run_terminal"), variant = "ghost", flexGrow = 1,
                tooltip = tr("tip_run_terminal"),
                onClick = function()
                    request("update_terminal")
                end,
            }))
        end
        table.insert(footer, ui.button({
            key = "dismiss" .. (hasUpdates and "" or "-off"),
            text = tr("action_dismiss"), variant = "ghost", enabled = hasUpdates,
            onClick = function()
                request("dismiss")
                panel.close()
            end,
        }))
        local backgroundMode = noctalia.getConfig("update_mode") == "background"
        table.insert(footer, ui.button({
            key = "update" .. (hasUpdates and "" or "-off"),
            glyph = backgroundMode and "download" or "terminal",
            text = tr("action_update"), variant = "primary", enabled = hasUpdates,
            tooltip = backgroundMode and tr("tip_update") or tr("tip_update_terminal"),
            onClick = function()
                request("update")
                if not backgroundMode then
                    -- Terminal mode hands the run off to its own window, so
                    -- the panel has nothing left to show; background mode
                    -- keeps it open since the live log is the only place
                    -- progress is visible.
                    panel.close()
                end
            end,
        }))
        table.insert(children, ui.row({ gap = 8, align = "center", justify = "end" }, footer))
    end

    panel.render(ui.column({ flexGrow = 1, gap = 10, align = "stretch" }, children))
end

function onOpen(_context)
    snapshot = noctalia.state.get(STATE_KEY)
    expanded = {}
    hoverKey = nil
    hoverText = ""
    openedRunAt = nil
    armedKey = nil
    activityHoverIndex = nil
    -- A fresh auto-open from a just-finished update (see the state watcher
    -- below) survives this reset once, so it's not discarded before it's
    -- ever seen; any other reason for opening still defaults to the sources.
    if not changelogAutoOpenPending then
        changelogOpen = false
    end
    changelogAutoOpenPending = false
    render()
end

-- An armed confirm is a one-click trigger for a privileged downgrade: if the
-- confirming click doesn't come soon, put the plain button back.
function update()
    if armedKey ~= nil and os.time() - armedAt >= ARM_TIMEOUT_S then
        armedKey = nil
        render()
    end
end

noctalia.state.watch(STATE_KEY, function(value)
    if type(value) ~= "table" then
        return
    end
    if value.phase == "checking" and (snapshot == nil or snapshot.phase ~= "checking") then
        expanded = {}
        hoverKey = nil
        hoverText = ""
    end
    if value.phase == "running" and (snapshot == nil or snapshot.phase ~= "running") then
        openedRunAt = nil
        armedKey = nil
        changelogOpen = false
    end
    -- lastUpdateAt only moves for a real, successful update run (never a
    -- rollback or a plain check, see recordUpdateRun in service.luau), and it
    -- is bumped the moment the run succeeds, before the auto re-check even
    -- starts - so a change here is an exact, one-shot "an update just
    -- finished" signal.
    local prevUpdateAt = snapshot ~= nil and tonumber(snapshot.lastUpdateAt) or nil
    local newUpdateAt = tonumber(value.lastUpdateAt)
    if
        prevUpdateAt ~= nil
        and newUpdateAt ~= nil
        and newUpdateAt ~= prevUpdateAt
        and noctalia.getConfig("show_changelog_after_update") ~= false
    then
        changelogOpen = true
        changelogAutoOpenPending = true
    end
    snapshot = value
    render()
end)
