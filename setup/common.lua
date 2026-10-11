-- Shared command helpers for setup steps; no package changes occur on load.

local function quote(value)
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

-- Quote each argument independently so paths and package names stay intact.
local function command(arguments)
    local parts = {}
    for _, value in ipairs(arguments) do
        parts[#parts + 1] = quote(value)
    end
    return table.concat(parts, " ")
end

local function run(arguments)
    if os.execute(command(arguments)) ~= 0 then
        error("Command failed: " .. command(arguments), 0)
    end
end

local function available(name)
    return os.execute("command -v " .. quote(name) .. " >/dev/null 2>&1") == 0
end

-- Check the installed database, not remote versions: setup does not upgrade
-- packages that already satisfy the manifest's presence requirement.
local function installed(name)
    return os.execute(command({ "pacman", "-Q", name }) .. " >/dev/null 2>&1") == 0
end

return { quote = quote, command = command, run = run,
         available = available, installed = installed }
