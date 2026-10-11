-- Each step checks current state before performing installation work.
local tools = require("common")
local available, installed = tools.available, tools.installed
local run, command, quote = tools.run, tools.command, tools.quote
local M = {}

-- Step 1: validate all sources and names before any system changes.
function M.load_manifest(path)
    local groups = dofile(path)
    local packages = { pacman = {}, aur = {} }
    local seen = {}

    for _, group in ipairs(groups) do
        assert(packages[group.source], "Unsupported source: " .. tostring(group.source))
        assert(type(group.packages) == "table", "Expected packages list")

        for _, name in ipairs(group.packages) do
            assert(type(name) == "string" and name:match("^[%w@._+%-]+$"), "Invalid package name")
            assert(not seen[name], "Duplicate package: " .. name)
            seen[name] = true
            table.insert(packages[group.source], name)
        end
    end

    return packages
end

-- Report every package skipped and return only the absent requirements.
function M.missing(names)
    local missing = {}
    for _, name in ipairs(names) do
        if installed(name) then
            print("  Skip installed: " .. name)
        else
            print("  Missing: " .. name)
            missing[#missing + 1] = name
        end
    end
    return missing
end

-- Step 2: official installation is a no-op when all packages are present.
-- Refresh with a full upgrade only when installation is actually needed.
function M.official(names)
    print("Step 2: official dependencies")
    local missing = M.missing(names)
    if #missing == 0 then
        return
    end

    run({ "sudo", "-v" })
    local arguments = { "sudo", "pacman", "-Syu", "--needed" }
    for _, name in ipairs(missing) do
        arguments[#arguments + 1] = name
    end
    run(arguments)
end

-- Step 3: reuse an existing helper immediately. A missing helper needs the
-- official build tools first; only yay itself is bootstrapped with makepkg.
function M.helper()
    print("Step 3: AUR helper")
    if available("yay") then
        print("  Skip helper setup: yay available")
        return "yay"
    elseif available("paru") then
        print("  Skip helper setup: paru available")
        return "paru"
    end

    M.official({ "git", "base-devel" })
    assert(available("git") and available("makepkg"), "git and makepkg are required")
    run({ "sudo", "-v" })
    local helper = available("yay") and "yay" or available("paru") and "paru"
    if not helper then
        local pipe = assert(io.popen("mktemp -d", "r"))
        local directory = pipe:read("*l")
        local closed = pipe:close()
        assert(closed and directory and directory ~= "", "Cannot create build directory")

        -- Bootstrap yay from its AUR package as the regular user. makepkg
        -- resolves build dependencies and installs it using configured sudo.
        local ok, message = pcall(function()
            local path = directory .. "/yay"
            run({ "git", "clone", "--", "https://aur.archlinux.org/yay.git", path })
            if os.execute("cd " .. quote(path) .. " && makepkg --syncdeps --install --needed") ~= 0 then
                error("Bootstrapping yay failed", 0)
            end
        end)

        -- Remove temporary sources on success or a handled build failure.
        run({ "rm", "-rf", "--", directory })
        if not ok then
            error(message, 0)
        end

        assert(available("yay"), "yay installation completed but the command is unavailable")
        helper = "yay"
    end
    return helper
end

-- Step 4: do not invoke the helper at all when AUR requirements are present.
function M.aur(names, helper)
    print("Step 4: AUR dependencies")
    local missing = M.missing(names)
    if #missing == 0 then
        return
    end

    run({ "sudo", "-v" })
    local arguments = { helper, "-S", "--needed" }
    for _, name in ipairs(missing) do
        arguments[#arguments + 1] = name
    end
    run(arguments)
end

return M
