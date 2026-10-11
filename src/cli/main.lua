-- The Bash entry point supplies an absolute path after resolving symlinks.
-- Resolve our modules relative to this file; argparse uses LuaJIT's normal
-- module search path and is installed through the dependency manifest.
local directory = assert(arg[0]:match("^(.*)/[^/]+$"), "Cannot locate Luna CLI")
package.path = directory .. "/?.lua;" .. directory .. "/?/init.lua;" .. package.path

local argparse = require("argparse")
local theme = require("theme")
local parser = argparse("luna", "Luna desktop command-line interface.")
parser:require_command(false)
theme.register(parser)

-- Completion is generated on demand; it does not modify shell configuration.
parser:add_complete_command("completion")

local arguments = parser:parse()
if arguments.theme then
    if not arguments.theme_command then
        print(theme.parser:get_help())
        return
    end

    -- Report operational failures without Lua stack traces or success messages.
    local ok, message = pcall(theme.run, arguments, directory)
    if not ok then
        io.stderr:write("luna: ", tostring(message), "\n")
        os.exit(1)
    end
    return
end

print(parser:get_help())
