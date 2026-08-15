-- wrules.lua
-- Depends on variables from configs.lua (must be loaded first).
-- See https://wiki.hypr.land/Configuring/Window-Rules/

local function float_center(class)
    hl.window_rule({
        match = { class = class },
        float = true,
        center = true,
    })
end

float_center("org.kde.polkit-kde-authentication-agent-1")
float_center("xfce-polkit")
float_center("pavucontrol")
float_center("org.pulseaudio.pavucontrol")
float_center("nwg-look")
float_center("qt5ct")
float_center("qt6ct")
float_center("file-roller")
float_center("org.gnome.FileRoller")
float_center("[Kk]vantummanager")
float_center("[Ll]xappearance")
float_center("eog")
float_center("[Tt]hunar")
float_center("[Gg]nome-disks")
float_center("com.obsproject.Studio")
float_center("org.kde.kcalc")
float_center("org.telegram.desktop")
float_center("org.kde.partitionmanager")
float_center("org.kde.gwenview")
float_center("localsend")
float_center("com.gabm.satty")
float_center("org.gnome.Nautilus")
float_center("codium")
float_center("codium-url-handler")
float_center("VSCodium")
float_center("com.heroicgameslauncher.hgl")
float_center("[Ss]team")
float_center("xdg-desktop-portal-gtk")
float_center("electron")

-- Specific titles
hl.window_rule({ match = { title = "^(Authentication Required)$" }, float = true, center = true })

-- File manager progress dialogs
hl.window_rule({ match = { class = "^([Tt]hunar)$", title = "^(File Operation Progress)$" }, float = true, center = true })
hl.window_rule({ match = { class = "^([Tt]hunar)$", title = "^(Confirm to replace files)$" }, float = true, center = true })

-- Kitty titles
hl.window_rule({ match = { class = "^(kitty)$", title = "^(update|floating|yazi|monitor|browser)$" }, float = true })
hl.window_rule({ match = { class = "^(kitty)$", title = "^(yazi|update|browser)$" }, center = true })

-- Size rules
hl.window_rule({ match = { class = "^([Kk]vantummanager)$" }, size = "monitor_w*0.55 monitor_h*0.75" })
hl.window_rule({ match = { class = "^([Ll]xappearance)$" }, size = "monitor_w*0.55 monitor_h*0.75" })
hl.window_rule({ match = { class = "^(nwg-look)$" }, size = "monitor_w*0.55 monitor_h*0.75" })
hl.window_rule({ match = { class = "^(eog)$" }, size = "monitor_w*0.55 monitor_h*0.75" })
hl.window_rule({ match = { class = "^([Tt]hunar)$" }, size = "monitor_w*0.55 monitor_h*0.75" })
hl.window_rule({ match = { class = "^(xdg-desktop-portal-gtk)$" }, size = "monitor_w*0.7 monitor_h*0.7" })
hl.window_rule({ match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol)$" }, size = "monitor_w*0.6 monitor_h*0.7" })
hl.window_rule({ match = { class = "^(kitty)$", title = "^(update)$" }, size = "monitor_w*0.7 monitor_h*0.8" })
hl.window_rule({ match = { class = "^(kitty)$", title = "^(yazi)$" }, size = "monitor_w*0.6 monitor_h*0.6" })
hl.window_rule({ match = { class = "^(kitty)$", title = "^(monitor)$" }, size = "monitor_w*0.5 monitor_h*0.55" })
hl.window_rule({ match = { class = "^(kitty)$", title = "^(browser)$" }, size = "monitor_w*0.5 monitor_h*0.6" })
hl.window_rule({ match = { class = "^(kitty)$", title = "^(floating)$" }, size = "monitor_w*0.55 monitor_h*0.75" })
hl.window_rule({ match = { class = "^(com.obsproject.Studio)$" }, size = "monitor_w*0.5 monitor_h*0.7" })
hl.window_rule({ match = { class = "^(org.telegram.desktop)$" }, size = "monitor_w*0.6 monitor_h*0.8" })
hl.window_rule({ match = { class = "^(org.kde.gwenview)$" }, size = "monitor_w*0.6 monitor_h*0.8" })
hl.window_rule({ match = { class = "^(org.kde.partitionmanager)$" }, size = "monitor_w*0.5 monitor_h*0.6" })
hl.window_rule({ match = { class = "^(org.kde.kcalc)$" }, size = "monitor_w*0.3 monitor_h*0.55" })
hl.window_rule({ match = { class = "^(xfce-polkit)$" }, size = "monitor_w*0.3 monitor_h*0.2" })
hl.window_rule({ match = { class = "^(localsend)$" }, size = "monitor_w*0.4 monitor_h*0.4" })
hl.window_rule({ match = { class = "^(com.gabm.satty)$" }, size = "monitor_w*0.6 monitor_h*0.6" })

-- ── Opacity Rules ─────────────────────────────────────────────────────────────
-- Syntax: opacity = "active inactive [fullscreen]"
-- Use "override" to force absolute values instead of multipliers

hl.window_rule({
    match = { tag = "file-manager" },
    opacity = string.format("%.1f %.1f", opacity_act, opacity_deact)
})

hl.window_rule({
    match = { tag = "browser" },
    opacity = string.format("1.0 %.1f", opacity_deact)
})

-- Workspace assignment
hl.window_rule({ match = { class = "^(kitty)$", title = "^(main)$" }, workspace = "1" })
hl.window_rule({ match = { tag = "browser" }, workspace = "2" })
hl.window_rule({ match = { tag = "ide" }, workspace = "3" })
hl.window_rule({ match = { class = "^(com.obsproject.Studio)$" }, workspace = "3" })

-- Special workspace exposed
hl.workspace_rule({
    workspace = "special:exposed",
    gaps_out = 60,
    gaps_in = 30,
    border_size = 5,
    no_border = false, -- Correct: Use no_border (false means keep borders)
    no_shadow = true,  -- Correct: Use no_shadow (true means disable shadows)
    -- decorate = true,  -- Optional: Explicitly enable decorations if disabled globally
})

-- Layer rules
hl.layer_rule({ match = { namespace = "^rofi$" }, blur = true })
hl.layer_rule({ match = { namespace = "^notifications$" }, blur = true })
hl.layer_rule({ match = { namespace = "^gtk-layer-shell$" }, blur = true })
hl.layer_rule({ match = { namespace = "^waybar$" }, blur = true })
