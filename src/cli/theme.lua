-- Keep the theme command definitions separate from the top-level entry point.
-- Actual palette discovery and activation will be added in the next step.
local M = {}

function M.register(root)
    local parser = root:command("theme", "Manage Luna color themes (scaffold).")
    parser:require_command(false)
    parser:command_target("theme_command")

    parser:command("list", "List available themes (not implemented yet).")
    parser:command("current", "Show the active theme (not implemented yet).")
    parser:command("set", "Activate a theme (not implemented yet).")
        :argument("name", "Theme identifier, for example tokyo-night.")

    M.parser = parser
end

return M
