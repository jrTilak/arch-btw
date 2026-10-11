-- Register the authentication agent once per login, not on config reloads.
-- Its stable command path is independent of the checkout's name or location.
hl.on("hyprland.start", function ()
    local home = os.getenv("HOME")
    hl.exec_cmd("'" .. home:gsub("'", "'\\''") .. "/.local/bin/polkit-agent'")
end)
