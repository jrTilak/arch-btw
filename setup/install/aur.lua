-- AUR helper bootstrap and helper-managed package installation.
local tools = require("commands")
local available, installed = tools.available, tools.installed
local run, command, quote = tools.run, tools.command, tools.quote
local M = {}

-- Step 3: reuse an existing helper immediately. A missing helper needs the
-- official build tools first; only yay itself is bootstrapped with makepkg.
function M.helper()
    print("Step 3: AUR helper")
    -- Existing helpers satisfy this step without sudo, downloads, or builds.
    if available("yay") then
        print("  Skip helper setup: yay available")
        return "yay"
    elseif available("paru") then
        print("  Skip helper setup: paru available")
        return "paru"
    end

    require("packages").official({ "git", "base-devel" })
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
    local missing = require("packages").missing(names)
    if #missing == 0 then
        return
    end

    -- Installation is needed only for the missing names returned above.
    run({ "sudo", "-v" })
    local arguments = { helper, "-S", "--needed" }
    for _, name in ipairs(missing) do
        arguments[#arguments + 1] = name
    end
    run(arguments)

    -- Verify the local package database after the helper reports success.
    for _, name in ipairs(missing) do
        assert(installed(name), "AUR installation did not complete: " .. name)
    end
end

return M
