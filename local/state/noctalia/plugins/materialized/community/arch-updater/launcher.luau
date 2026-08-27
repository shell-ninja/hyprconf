--!nonstrict
-- arch-updater launcher provider, under the `/arch` prefix.
--
-- Empty query shows the three quick actions. Any other text is fuzzy-matched
-- against the pending packages from the last check, read straight from the
-- shared "arch_state" the engine publishes. Activating a package opens its
-- page, same as the panel's "open" button on a package row.

local STATE_KEY = "arch_state"
local REQUEST_KEY = "arch_request"

local function tr(key, args)
    return noctalia.tr(key, args)
end

local function request(action)
    local prev = noctalia.state.get(REQUEST_KEY)
    local nonce = (type(prev) == "table" and tonumber(prev.nonce) or 0) + 1
    noctalia.state.set(REQUEST_KEY, { nonce = nonce, action = action })
end

local function shellQuote(value)
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function openUrl(url)
    if noctalia.commandExists("xdg-open") then
        noctalia.runAsync("xdg-open " .. shellQuote(url) .. " >/dev/null 2>&1")
    end
end

local SOURCE_GLYPH = { pacman = "package", aur = "box", flatpak = "app-window" }

local function packageUrl(sourceKey, name)
    if sourceKey == "pacman" then
        return "https://archlinux.org/packages/?q=" .. noctalia.string.urlEncode(name)
    elseif sourceKey == "aur" then
        return "https://aur.archlinux.org/packages/" .. noctalia.string.urlEncode(name)
    end
    return "https://flathub.org/apps/" .. noctalia.string.urlEncode(name)
end

local function commandResults()
    return {
        { id = "cmd-check", title = tr("action_check"), subtitle = tr("launcher.check_subtitle"), glyph = "refresh" },
        { id = "cmd-update", title = tr("action_update"), subtitle = tr("launcher.update_subtitle"), glyph = "download" },
        { id = "cmd-news", title = tr("action_open_news"), subtitle = tr("launcher.news_subtitle"), glyph = "news" },
    }
end

local function packageResults(query)
    local state = noctalia.state.get(STATE_KEY)
    if type(state) ~= "table" then
        return {}
    end

    local results = {}
    local sourceList = { { key = "pacman", entry = state.pacman }, { key = "aur", entry = state.aur }, { key = "flatpak", entry = state.flatpak } }
    for _, source in ipairs(sourceList) do
        local items = type(source.entry) == "table" and source.entry.items or nil
        if type(items) == "table" then
            for _, item in ipairs(items) do
                local score = noctalia.fuzzyScore(query, item.name)
                if score ~= nil then
                    local subtitle = (item.from ~= nil and item.from ~= "" and item.to ~= nil and item.to ~= "")
                        and (item.from .. " → " .. item.to)
                        or tr("source." .. source.key)
                    table.insert(results, {
                        id = "pkg-" .. source.key .. "-" .. item.name,
                        title = item.name,
                        subtitle = subtitle,
                        glyph = SOURCE_GLYPH[source.key] or "package",
                        score = score,
                    })
                end
            end
        end
    end
    return results
end

function onQuery(query)
    if query == "" then
        launcher.setResults(query, commandResults())
        return
    end
    launcher.setResults(query, packageResults(query))
end

function onActivate(id)
    if id == "cmd-check" then
        request("check")
    elseif id == "cmd-update" then
        request("update")
    elseif id == "cmd-news" then
        request("open_news")
    else
        local sourceKey, name = id:match("^pkg%-([a-z]+)%-(.+)$")
        if sourceKey ~= nil and name ~= nil then
            openUrl(packageUrl(sourceKey, name))
        end
    end
end
