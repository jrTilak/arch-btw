-- Required dependencies grouped by the source used to install them.
-- Keep setup-only tools and runtime requirements together, with their purpose
-- documented here. This retains the agreed package selection for future work.
return {
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
            "hyprland",
            "xdg-desktop-portal",
            "xdg-desktop-portal-gtk",

            -- Toolkit selected for future desktop apps.
            "quickshell",

            -- Selected desktop terminal.
            "kitty",
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
