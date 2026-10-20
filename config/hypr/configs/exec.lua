-- exec.lua
-- Autostart processes on Hyprland startup.
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

local scripts_dir = os.getenv("HOME") .. "/.hyprconf/hypr/scripts"
local sh_dir = scripts_dir .. "/sh"
local py_dir = scripts_dir .. "/py"

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
    hl.exec_cmd(sh_dir .. "/startup.sh")
    hl.exec_cmd(py_dir .. "/pkgupdate-notifier.py")
    hl.exec_cmd(py_dir .. "/usb-notifier.py")
    hl.exec_cmd(sh_dir .. "/hyprconf.sh --daemon &")
    hl.exec_cmd("blueman-applet &")
    hl.exec_cmd("hypridle &")
    hl.exec_cmd(sh_dir .. "/qs-island.sh --start &")
    hl.exec_cmd(sh_dir .. "/qs-widgets.sh --start &")

    hl.exec_cmd("pypr &")
end)
