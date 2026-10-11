-- Start the app index hidden once per login; Super+Space toggles it through IPC.
-- The command path is stable and contains no assumption about the checkout.
local home = os.getenv("HOME")
local command = "'" .. home:gsub("'", "'\\''") .. "/.local/bin/app-launcher'"

hl.on("hyprland.start", function ()
    hl.exec_cmd(command .. " serve")
end)

hl.bind("SUPER + SPACE", hl.dsp.exec_cmd(command))
