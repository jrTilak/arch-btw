-- Coordinate setup steps; dependency definitions and step logic stay adjacent.
-- Run setup.sh on a fresh Arch installation to bootstrap the Lua runtime.
local function install()
    -- Install the complete manifest by default; an optional scope selects a group.
    local scope = arg[1] or "all"
    assert(#arg <= 1 and (scope == "hyprland" or scope == "polkit" or scope == "launcher" or scope == "bar" or scope == "stow" or scope == "all"),
        "Usage: setup.sh [hyprland|polkit|launcher|bar|stow|all]")

    -- Resolve symlinks and quoted paths without depending on the checkout name.
    local quoted = "'" .. arg[0]:gsub("'", "'\\''") .. "'"
    local pipe = assert(io.popen("readlink -f -- " .. quoted, "r"))
    local path = pipe:read("*l")
    assert(pipe:close() and path, "Cannot resolve setup script location")
    local directory = assert(path:match("^(.*)/install/[^/]+$"))
    package.path = directory .. "/helpers/?.lua;" .. directory .. "/install/?.lua;" .. package.path

    -- Resolve modules beside the checkout; importing them does not install anything.
    local tools = require("commands")
    local package_steps = require("packages")
    local aur_steps = require("aur")
    assert(tools.available("pacman"), "Arch Linux is required")
    assert(os.execute('[ "$(id -u)" -ne 0 ]') == 0, "Run as your normal user")

    -- Validate deferred entries too, then select only the requested group.
    print("Step 1: validate dependency manifest")
    local packages = package_steps.load_manifest(directory .. "/dependencies.lua", scope)

    -- Official dependencies precede AUR builds. Hyprland-only has no AUR
    -- packages, so it skips helper setup entirely.
    package_steps.official(packages.pacman)
    if #packages.aur > 0 then
        local helper = aur_steps.helper()
        aur_steps.aur(packages.aur, helper)
    end

    if scope == "all" or scope == "stow" or scope == "bar" then
        require("stow").apply(directory)
    end

    -- The agent is an explicitly integrated component. Other app configuration
    -- remains outside setup; the focused scope installs only agent dependencies.
    if scope == "all" or scope == "polkit" then
        require("polkit").apply(directory)
    end

    if scope == "all" or scope == "launcher" then
        require("launcher").apply(directory)
    end

    if scope == "all" or scope == "bar" then
        require("bar").apply(directory)
    end

    print("Setup complete. Existing matching dependencies and agent links were preserved.")
end

-- Fail with a clear message and a nonzero status, stopping later steps.
local ok, message = pcall(install)
if not ok then
    io.stderr:write(tostring(message), "\n")
    os.exit(1)
end
