-- Deploy the requested bar after dependencies and Stow. Existing settings stay
-- intact; conflicting command/module files and the main config are backed up.
local tools = require("commands")
local M = {}

local function capture(arguments)
    local pipe = assert(io.popen(tools.command(arguments), "r"))
    local value = pipe:read("*l")
    local ok = pipe:close()
    return ok and value or nil
end

local function exists(path)
    return os.execute("test -e " .. tools.quote(path) .. " || test -L " .. tools.quote(path)) == 0
end

function M.apply(setup_dir)
    print("Top bar: command, settings, and login module")
    local repo = assert(setup_dir:match("^(.*)/setup$"))
    local home = assert(os.getenv("HOME"))
    local config = os.getenv("XDG_CONFIG_HOME")
    if not config or config == "" then config = home .. "/.config" end
    local state = os.getenv("XDG_STATE_HOME")
    if not state or state == "" then state = home .. "/.local/state" end
    local hypr_path = config .. "/hypr/hyprland.lua"
    local file = assert(io.open(hypr_path, "r"), "Create your Hyprland Lua configuration before bar setup")
    local content = file:read("*a")
    assert(file:close())
    assert(exists(home .. "/.local/src/top-bar/shell.qml"), "Stow the sources before bar setup")

    -- Allocate backups only when a destination differs or a loader is appended.
    local backup_dir
    local function backup(path, name, move)
        if not backup_dir then
            local parent = state .. "/luna/backups"
            tools.run({ "mkdir", "-p", "--", parent })
            backup_dir = assert(capture({ "mktemp", "-d", parent .. "/bar-XXXXXX" }))
        end
        tools.run({ move and "mv" or "cp", "--", path, backup_dir .. "/" .. name })
        print("  Backed up " .. path .. " to " .. backup_dir)
    end

    local function link(source, destination, name)
        if capture({ "readlink", "-f", "--", destination }) == source then return end
        if exists(destination) then backup(destination, name, true) end
        tools.run({ "mkdir", "-p", "--", assert(destination:match("^(.*)/[^/]+$")) })
        tools.run({ "ln", "-s", "--", source, destination })
    end
    link(repo .. "/bin/luna-bar", home .. "/.local/bin/luna-bar", "luna-bar")
    link(repo .. "/config/hypr/.config/hypr/bar.lua", config .. "/hypr/bar.lua", "bar.lua")

    -- Copy editable defaults once. Theme switching never touches this file.
    local settings = config .. "/luna/top-bar.json"
    if not exists(settings) then
        tools.run({ "mkdir", "-p", "--", config .. "/luna" })
        tools.run({ "cp", "--", repo .. "/src/top-bar/defaults.json", settings })
    end

    local loader = 'dofile((os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr/bar.lua")'
    if not content:find(loader, 1, true) then
        backup(hypr_path, "hyprland.lua", false)
        file = assert(io.open(hypr_path, "a"))
        assert(file:write("\n-- Luna top bar and quick settings.\n", loader, "\n"))
        assert(file:close())
        if os.getenv("HYPRLAND_INSTANCE_SIGNATURE") then
            tools.run({ "hyprctl", "reload" })
            tools.run({ "hyprctl", "configerrors" })
        end
    end
    print("  Start now: luna-bar serve; quick settings: Super+Ctrl+S")
end

return M
