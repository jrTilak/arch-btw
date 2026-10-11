-- This setup step does not back up files or run a Stow dry-run.
-- Deploy the declared checkout packages with GNU Stow; conflicts are rejected.
-- Dependency installation must provide Stow before this step runs.
local tools = require("commands")
local M = {}

function M.apply(setup_dir)
    print("Stow deployment (no backups)")
    local repo = assert(setup_dir:match("^(.*)/setup$"))
    local home = assert(os.getenv("HOME"))
    -- Add explicitly requested package/target pairs here as deployment grows.
    -- Only source packages are deployed today; startup and command links remain
    -- owned by their existing setup steps.
    local deployments = {
        { package = "src", target = home .. "/.local/src" },
    }

    for _, deployment in ipairs(deployments) do
        -- Reject a linked target rather than letting Stow write into another tree.
        assert(os.execute("test ! -L " .. tools.quote(deployment.target)) == 0,
            "Stow target must not be a symlink: " .. deployment.target)
        tools.run({ "mkdir", "-p", "--", deployment.target })

        -- Restow is repeatable within this checkout. Existing conflicting files or
        -- links to another checkout require manual resolution; nothing is adopted.
        tools.run({ "stow", "--dir", repo, "--target", deployment.target,
            "--restow", deployment.package })
    end
end

return M
