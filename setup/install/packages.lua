-- Manifest validation and official package installation.
local tools = require("commands")
local available, installed = tools.available, tools.installed
local run, command, quote = tools.run, tools.command, tools.quote
local M = {}

-- Step 1: validate all sources and names before any system changes.
function M.load_manifest(path, scope)
    local groups = dofile(path)
    local packages = { pacman = {}, aur = {} }
    -- One package belongs to one source; duplicates across groups are rejected.
    local seen = {}

    for _, group in ipairs(groups) do
        assert(packages[group.source], "Unsupported source: " .. tostring(group.source))
        assert(type(group.packages) == "table", "Expected packages list")

        for _, name in ipairs(group.packages) do
            assert(type(name) == "string" and name:match("^[%w@._+%-]+$"), "Invalid package name")
            assert(not seen[name], "Duplicate package: " .. name)
            seen[name] = true

            -- Unselected entries are validated but never installed. Entries
            -- without a category participate only in the all scope.
            if scope == "all" or group.category == scope
                or (group.category == "desktop-runtime" and (scope == "polkit" or scope == "launcher" or scope == "bar"))
                or (group.category == "stow" and scope == "bar") then
                table.insert(packages[group.source], name)
            end
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

    -- Prompt for privileges only when missing packages require installation.
    run({ "sudo", "-v" })
    local arguments = { "sudo", "pacman", "-Syu", "--needed" }
    for _, name in ipairs(missing) do
        arguments[#arguments + 1] = name
    end
    run(arguments)

    -- Confirm installation before allowing later setup steps to proceed.
    for _, name in ipairs(missing) do
        assert(installed(name), "Package installation did not complete: " .. name)
    end
end

return M
