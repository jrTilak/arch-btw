-- Shared command helpers for setup steps; no package changes occur on load.

-- Preserve shell metacharacters literally; embedded apostrophes close the
-- quoted string briefly and are escaped before quoting resumes.
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

-- LuaJIT returns numeric process status; stop the current step on failure.
local function run(arguments)
    if os.execute(command(arguments)) ~= 0 then
        error("Command failed: " .. command(arguments), 0)
    end
end

-- Check PATH availability rather than assuming package ownership of a command.
local function available(name)
    return os.execute("command -v " .. quote(name) .. " >/dev/null 2>&1") == 0
end

-- Check the installed database, not remote versions: setup does not upgrade
-- packages that already satisfy the manifest's presence requirement. A later
-- pacman -Syu transaction can still upgrade them when installing missing packages.
local function installed(name)
    return os.execute(command({ "pacman", "-Q", name }) .. " >/dev/null 2>&1") == 0
end

return { quote = quote, command = command, run = run,
         available = available, installed = installed }
