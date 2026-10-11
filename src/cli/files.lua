-- Small filesystem helpers keep shell arguments literal and errors readable.
-- Coreutils is already a runtime dependency; no commands execute theme content.
local M = {}

function M.quote(value)
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

function M.command(arguments)
    local parts = {}
    for _, value in ipairs(arguments) do parts[#parts + 1] = M.quote(value) end
    return table.concat(parts, " ")
end

function M.run(arguments)
    assert(os.execute(M.command(arguments)) == 0,
        "Command failed: " .. M.command(arguments))
end

function M.capture(arguments)
    local pipe = assert(io.popen(M.command(arguments), "r"))
    local content = pipe:read("*a")
    assert(pipe:close(), "Command failed: " .. M.command(arguments))
    return content:gsub("\n$", "")
end

function M.test(flag, path)
    return os.execute(M.command({ "test", flag, path })) == 0
end

function M.exists(path)
    return M.test("-e", path) or M.test("-L", path)
end

function M.read(path)
    local file = assert(io.open(path, "r"), "Cannot read " .. path)
    local content = file:read("*a")
    assert(file:close())
    return content
end

function M.write(path, content)
    local file = assert(io.open(path, "w"), "Cannot write " .. path)
    assert(file:write(content))
    assert(file:close())
end

function M.entries(path)
    if not M.test("-d", path) then return {} end
    local content = M.capture({ "find", path, "-mindepth", "1", "-maxdepth", "1",
        "-printf", "%f\\0" })
    local names = {}
    for name in content:gmatch("([^%z]+)%z") do names[#names + 1] = name end
    table.sort(names)
    return names
end

return M
