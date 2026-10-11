-- dkjson handles JSON parsing; these checks describe the theme color schema.
local json = require("dkjson")
local files = require("files")
local M = {}
local required = {
    "background", "surface", "foreground", "muted", "accent", "onAccent",
    "border", "success", "warning", "error",
}

function M.validate(path, base)
    local content = files.read(path)
    assert(#content <= 1024 * 1024, "Color file exceeds 1 MiB: " .. path)
    -- dkjson accepts comments, but palette files contain only names and hex
    -- colors, so comment markers are never valid content in this format.
    assert(not content:find("//", 1, true) and not content:find("/*", 1, true),
        "Comments are not allowed in color JSON: " .. path)
    local palette, position, message = json.decode(content, 1, json.null)
    assert(not message and content:sub(position):match("^%s*$"),
        "Invalid JSON: " .. path .. (message and (": " .. message) or ""))
    assert(type(palette) == "table" and getmetatable(palette).__jsontype == "object",
        "Expected a color object: " .. path)

    for token, color in pairs(palette) do
        assert(token:match("^[%a_][%w_]*$"), "Invalid color token: " .. token)
        assert(type(color) == "string" and color:match("^#%x%x%x%x%x%x$"),
            "Expected #RRGGBB for " .. token)
    end

    -- Extra roles belong to app overrides; the shared base has a fixed contract.
    if base then
        for _, token in ipairs(required) do
            assert(palette[token], "Missing base color: " .. token)
            palette[token] = nil
        end
        assert(next(palette) == nil, "Extra colors belong in apps/*.json: " .. path)
    end
end

return M
