-- Deploy only the authentication agent and its Hyprland login hook.
-- Back up conflicting user files; repeated setup leaves matching links intact.
local tools = require("commands")
local M = {}

local function read(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*a")
    file:close()
    return content
end

local function capture(arguments)
    local pipe = assert(io.popen(tools.command(arguments), "r"))
    local value = pipe:read("*l")
    local ok = pipe:close()
    return ok and value or nil
end

function M.apply(setup_dir)
    print("Step 5: Polkit authentication agent")
    assert(tools.available("quickshell"), "Install Quickshell before deploying the agent")
    local repo = assert(setup_dir:match("^(.*)/setup$"))
    local home = assert(os.getenv("HOME"))
    local config = os.getenv("XDG_CONFIG_HOME")
    if not config or config == "" then config = home .. "/.config" end
    local state = os.getenv("XDG_STATE_HOME")
    if not state or state == "" then state = home .. "/.local/state" end
    local hypr_config = config .. "/hypr/hyprland.lua"
    local content = assert(read(hypr_config), "Create your Hyprland Lua configuration before agent setup")

    -- Lazily allocate a unique backup directory only if a user file conflicts.
    -- Old links/files are preserved by rename; the main config is copied.
    local backup_dir
    local function backup(path, label, move)
        if not backup_dir then
            local parent = state .. "/desktop-customization/backups"
            tools.run({ "mkdir", "-p", "--", parent })
            backup_dir = assert(capture({ "mktemp", "-d", parent .. "/polkit-XXXXXX" }))
        end
        tools.run({ move and "mv" or "cp", "--", path, backup_dir .. "/" .. label })
        print("  Backed up " .. path .. " to " .. backup_dir)
    end

    local function link(source, destination, label)
        local resolved = capture({ "readlink", "-f", "--", destination })
        if resolved == source then
            print("  Skip matching link: " .. destination)
            return
        end

        -- -L also detects a dangling link, which must not be overwritten silently.
        if os.execute("test -e " .. tools.quote(destination) .. " || test -L " .. tools.quote(destination)) == 0 then
            backup(destination, label, true)
        end
        tools.run({ "mkdir", "-p", "--", assert(destination:match("^(.*)/[^/]+$")) })
        tools.run({ "ln", "-s", "--", source, destination })
    end

    link(repo .. "/src/polkit-agent", config .. "/quickshell/polkit-agent", "agent-config")
    link(repo .. "/bin/polkit-agent", home .. "/.local/bin/polkit-agent", "agent-command")
    link(repo .. "/config/hypr/.config/hypr/polkit.lua", config .. "/hypr/polkit.lua", "login-module")

    -- Append a single stable loader without replacing the rest of the user's
    -- configuration. Hook execution belongs to login, not configuration reloads.
    local loader = 'dofile((os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr/polkit.lua")'
    if content:find(loader, 1, true) then
        print("  Skip existing Hyprland login loader")
    else
        backup(hypr_config, "hyprland.lua", false)
        local file = assert(io.open(hypr_config, "a"))
        assert(file:write("\n-- Session Polkit authentication agent.\n", loader, "\n"))
        assert(file:close())
        if os.getenv("HYPRLAND_INSTANCE_SIGNATURE") then
            tools.run({ "hyprctl", "reload" })
            tools.run({ "hyprctl", "configerrors" })
        end
    end

    print("  Agent deployed; starts at your next Hyprland login")
end

return M
