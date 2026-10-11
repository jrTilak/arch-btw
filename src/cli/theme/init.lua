-- Themes are reusable data packages. The library preserves complete sources;
-- activation copies a package and publishes it through a stable config path.
local files = require("files")
local colors = require("theme.colors")
local M = {}

function M.register(root)
    local parser = root:command("theme", "Manage Luna color themes.")
    parser:require_command(false)
    parser:command_target("theme_command")

    parser:command("list", "List installed themes.")
    parser:command("current", "Show the active theme, or none.")
    parser:command("set", "Validate and activate an installed theme.")
        :argument("name", "Theme identifier, for example tokyo-night.")
    local install = parser:command("install", "Install a complete theme directory.")
    install:argument("path", "Directory containing base.json and optional apps/*.json.")
    install:flag("--force", "Replace an existing installed theme.")

    M.parser = parser
end

local function identifier(name)
    assert(name:match("^[a-z0-9][a-z0-9_-]*$"),
        "Theme names must use lowercase letters, digits, underscores, or hyphens")
    return name
end

local function validate(path)
    assert(files.test("-d", path), "Theme directory not found: " .. path)
    colors.validate(path .. "/base.json", true)
    if files.exists(path .. "/apps") then
        assert(files.test("-d", path .. "/apps"), "apps must be a directory")
        for _, name in ipairs(files.entries(path .. "/apps")) do
            assert(name:match("^[a-z0-9][a-z0-9_-]*%.json$"), "Invalid app override filename: " .. name)
            colors.validate(path .. "/apps/" .. name, false)
        end
    end
end

-- Copy the whole package, including assets and metadata, without executing any
-- of its files. Reject symlinks so installed sources never depend on outside paths.
local function stage(source, parent)
    validate(source)
    local links = files.capture({ "find", source, "-type", "l", "-print", "-quit" })
    assert(links == "", "Theme packages must not contain symlinks: " .. source)
    local directory = files.capture({ "mktemp", "-d", parent .. "/.theme-XXXXXX" })
    local ok, message = pcall(function()
        files.run({ "cp", "-a", "--", source .. "/.", directory })
        validate(directory)
    end)
    if not ok then
        files.run({ "rm", "-rf", "--", directory })
        error(message, 0)
    end
    return directory
end

local function install(source, library, name, force)
    local destination = library .. "/" .. identifier(name)
    assert(force or not files.exists(destination), "Theme already installed: " .. name .. "; use --force to replace it")
    -- A force replacement only touches a library-owned directory, never a link.
    assert(not files.exists(destination) or (files.test("-d", destination)
        and not files.test("-L", destination)), "Installed theme path is not a regular directory")
    local candidate = stage(source, library)
    local previous
    if files.exists(destination) then
        previous = candidate .. "-previous"
        assert(os.rename(destination, previous))
    end
    local ok, message = os.rename(candidate, destination)
    if not ok then
        if previous then assert(os.rename(previous, destination)) end
        files.run({ "rm", "-rf", "--", candidate })
        error(message, 0)
    end
    if previous then files.run({ "rm", "-rf", "--", previous }) end
end

function M.run(arguments, cli_dir)
    local home = assert(os.getenv("HOME"), "HOME is not set")
    -- Luna themes use fixed locations under HOME, regardless of XDG overrides.
    local library = home .. "/.local/share/luna/themes"
    local config = home .. "/.config/luna"
    local repo = files.capture({ "readlink", "-f", "--", cli_dir .. "/../.." })
    files.run({ "mkdir", "-p", "--", library })

    -- Serialize CLI mutations. An interrupted process may leave this lock;
    -- report it rather than risk simultaneous force replacements or activation.
    local lock = library .. "/.lock"
    assert(os.execute(files.command({ "mkdir", "--", lock }) .. " 2>/dev/null") == 0,
        "Theme library is locked; if no Luna command is running, remove " .. lock)
    local ok, message = pcall(function()
        -- Seed bundled themes once. Existing packages, including modified copies,
        -- are preserved; explicit installation with --force is needed to replace.
        for _, name in ipairs(files.entries(repo .. "/themes")) do
            if files.test("-d", repo .. "/themes/" .. name) and not files.exists(library .. "/" .. name) then
                install(repo .. "/themes/" .. name, library, name, false)
            end
        end

        local command = arguments.theme_command
        if command == "list" then
            for _, name in ipairs(files.entries(library)) do
                if name:sub(1, 1) ~= "." and files.test("-f", library .. "/" .. name .. "/base.json") then print(name) end
            end
        elseif command == "current" then
            local name_file = config .. "/theme/.luna-theme-name"
            print(files.test("-f", name_file) and files.read(name_file):gsub("\n$", "") or "none")
        elseif command == "install" then
            local source = files.capture({ "readlink", "-f", "--", arguments.path })
            local name = identifier(assert(source:match("([^/]+)$"), "Cannot identify theme directory"))
            install(source, library, name, arguments.force)
            print("Installed " .. name)
        elseif command == "set" then
            local name = identifier(arguments.name)
            local active = config .. "/theme"
            assert(not files.exists(active) or files.test("-L", active),
                "Active theme path is a directory or file; move it aside first: " .. active)
            validate(library .. "/" .. name)
            files.run({ "mkdir", "-p", "--", config })
            local candidate = stage(library .. "/" .. name, config)
            local published = false
            local activated, reason = pcall(function()
                files.write(candidate .. "/.luna-theme-name", name .. "\n")
                files.run({ "ln", "-s", "--", candidate, candidate .. "-link" })
                -- One rename publishes the complete palette and override snapshot.
                -- Existing snapshots remain intact for readers already using them.
                files.run({ "mv", "-Tf", "--", candidate .. "-link", active })
                published = true
            end)
            if not published then
                files.run({ "rm", "-rf", "--", candidate, candidate .. "-link" })
            end
            assert(activated, reason)
            print("Activated " .. name)
        end
    end)
    files.run({ "rmdir", "--", lock })
    assert(ok, message)
end

return M
