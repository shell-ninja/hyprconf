-- kaybinds-for-webapps.lua
-- Quick-launch bindings for web apps via a helper script.

local apps = os.getenv("HOME") .. "/.hyprconf/hypr/scripts/apps.sh"

hl.bind("ALT + A",       hl.dsp.exec_cmd(apps .. " chatgpt"))
hl.bind("CTRL + ALT + A", hl.dsp.exec_cmd(apps .. " gemini.google"))
hl.bind("CTRL + ALT + G", hl.dsp.exec_cmd(apps .. " grok"))
hl.bind("ALT + F",       hl.dsp.exec_cmd(apps .. " facebook"))
hl.bind("ALT + Y",       hl.dsp.exec_cmd(apps .. " youtube"))
hl.bind("ALT + W",       hl.dsp.exec_cmd(apps .. " web.whatsapp"))
hl.bind("ALT + I",       hl.dsp.exec_cmd(apps .. " instagram"))
hl.bind("ALT + G",       hl.dsp.exec_cmd(apps .. " github"))
hl.bind("ALT + R",       hl.dsp.exec_cmd(apps .. " reddit"))
