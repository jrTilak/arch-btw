-- Required dependencies grouped by the source used to install them.
-- Keep setup-only tools and runtime requirements together, with their purpose
-- documented here. This retains the agreed package selection for future work.
-- category selects a focused setup group; omitted categories are all-only.
-- source chooses pacman or the AUR helper. Package names must be unique.
return {
    {
        category = "desktop-runtime",
        source = "pacman",
        packages = {
            -- Shared runtime for the launcher and session authentication agent.
            "quickshell",
        },
    },
    {
        category = "polkit",
        source = "pacman",
        packages = {
            -- Real session authorization; Quickshell provides the minimal UI.
            "polkit",
        },
    },
    {
        category = "hyprland",
        source = "pacman",
        packages = {
            -- Compositor and its first integration tools; no service/config changes.
            "hyprland",
            "xdg-desktop-portal-hyprland",
            "wl-clipboard",
        },
    },
    {
        source = "pacman",
        packages = {
            -- Setup: obtain and build AUR sources on a fresh Arch installation.
            "git",
            "base-devel",

            -- GitHub CLI provides the gh command for repository workflows.
            "github-cli",

            -- Lua runtime and JSON library retained for planned configuration work.
            "luajit",
            "json-c",

            -- Shell helpers and GTK/Qt appearance integration.
            "bash",
            "coreutils",
            "ripgrep",
            "glib2",
            "xdg-desktop-portal",
            "xdg-desktop-portal-gtk",

            -- Selected desktop terminal.
            "kitty",

            -- Additional browser included in the default full setup.
            "chromium",

            -- Zed code editor, installed from Arch's official repositories.
            "zed",
        },
    },
    {
        source = "aur",
        packages = {
            -- Selected Qt 6 appearance provider.
            "hyprqt6engine",

            -- Zen Browser's prebuilt release avoids compiling the browser.
            "zen-browser-bin",
        },
    },
}
