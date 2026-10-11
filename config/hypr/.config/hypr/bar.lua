-- Start the resident bar once at login. Keep existing workspace and multimedia
-- bindings intact; this shortcut opens the grouped quick settings panel.
local home = assert(os.getenv("HOME"))
local command = "'" .. home:gsub("'", "'\\''") .. "/.local/bin/luna-bar'"

hl.on("hyprland.start", function ()
    hl.exec_cmd(command .. " serve")
end)

hl.bind("SUPER + CTRL + S", hl.dsp.exec_cmd(command .. " controls"))
