-- exec.lua
-- Autostart processes on Hyprland startup.
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

local scripts_dir = os.getenv("HOME") .. "/.hyprconf/hypr/scripts"

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
    hl.exec_cmd(scripts_dir .. "/startup.sh")
    hl.exec_cmd("waybar & swaync & hypridle")
    hl.exec_cmd("blueman-applet &")
    hl.exec_cmd(scripts_dir .. "/polkit.sh")
    hl.exec_cmd("wl-paste --type text  --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("pypr &")
end)
