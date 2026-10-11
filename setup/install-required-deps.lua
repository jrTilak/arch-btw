-- Coordinate setup steps; dependency definitions and step logic stay adjacent.
-- Run setup.sh on a fresh Arch installation to bootstrap the Lua runtime.
local function install()
    assert(#arg == 0, "This installer takes no arguments")

    -- Resolve symlinks and quoted paths without depending on the checkout name.
    local quoted = "'" .. arg[0]:gsub("'", "'\\''") .. "'"
    local pipe = assert(io.popen("readlink -f -- " .. quoted, "r"))
    local path = pipe:read("*l")
    assert(pipe:close() and path, "Cannot resolve setup script location")
    local directory = assert(path:match("^(.*)/[^/]+$"))
    package.path = directory .. "/?.lua;" .. package.path

    local tools = require("common")
    local steps = require("steps")
    assert(tools.available("pacman"), "Arch Linux is required")
    assert(os.execute('[ "$(id -u)" -ne 0 ]') == 0, "Run as your normal user")

    print("Step 1: validate dependency manifest")
    local packages = steps.load_manifest(directory .. "/dependencies.lua")

    steps.official(packages.pacman)
    if #packages.aur > 0 then
        local helper = steps.helper()
        steps.aur(packages.aur, helper)
    end

    print("Setup complete. Existing dependencies were preserved; configuration was not migrated.")
end

-- Fail with a clear message and a nonzero status, stopping later steps.
local ok, message = pcall(install)
if not ok then
    io.stderr:write(tostring(message), "\n")
    os.exit(1)
end
